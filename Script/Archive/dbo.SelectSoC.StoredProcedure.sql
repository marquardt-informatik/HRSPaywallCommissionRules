USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectSoC]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectSoC]
AS BEGIN
;WITH BU AS
(
  SELECT B_KEY
       , MUSE_ID
	   , ROUND(CAST(B_TOTAL_RATE_INCLUSIVE as dec(38,20)) * W_KURS / 100000 / 100,2) [HTO]
	   , B_AB_DATUM [Departure Date]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
), AP AS
(
  SELECT CASE [Company-No_]
           WHEN '31702' THEN 'Covid'
		   WHEN '31750' THEN 'Harvest'
		   WHEN '31751' THEN 'Fire'
		   WHEN '31743' THEN 'Hope'
         END [Project]
       , AP.HotelNo [Hotel No.]
       , AP.Chain [Chain]
	   , AP.ReservationNo [Reservation No.]
	   , AP.ProcessNumber
	   , SUM(AP.Turnover_LCY) [Commissionable HTO]
	   , SUM(CASE WHEN AP.Amount_LCY_corr-[TAF Amount (LCY) (corr_)]>0 AND AP.Turnover_LCY_corr=0 THEN Turnover_LCY ELSE AP.Turnover_LCY_corr END) [Commissionable HTO post correction]
	   , SUM(AP.[Agency Amount (LCY)]) [Commission]
	   , ROUND(SUM(AP.Amount_LCY_corr-[TAF Amount (LCY) (corr_)]),2) [Commission post correction]
	   , SUM(AP.[TAF Amount (LCY)]) [Hotel TAF]
	   , ROUND(SUM(AP.[TAF Amount (LCY) (corr_)]),2) [Hotel TAF post correction]
    FROM DynNavHRS.dbo.[HRS$Affiliate Postings] AP WITH (NOLOCK)
    JOIN DynNavHRS.dbo.[Affiliate Partner] PA WITH (NOLOCK)
      ON PA.[No_] = AP.AffiliatePartnerNo
   WHERE PA.[Company-No_]  IN ('31750','31751','31702','31743')
GROUP BY CASE [Company-No_]
           WHEN '31702' THEN 'Covid'
		   WHEN '31750' THEN 'Harvest'
		   WHEN '31751' THEN 'Fire'
		   WHEN '31743' THEN 'Hope'
         END 
       , AP.HotelNo 
       , AP.Chain 
	   , AP.ReservationNo 
	   , AP.ProcessNumber
),DM AS
(
  SELECT DL.[Reservation No_]
       , MAX(REPLACE(DL.[Display Case No_],'V','A'))[Display Case No_]
    FROM DynNavHRS.dbo.[HRS$Agency Display Line] DL WITH (NOLOCK)
    JOIN DynNavHRS.dbo.[HRS$Agency Display Header] DH WITH (NOLOCK) ON DH.[Case No_]=DL.[Display Case No_]
   WHERE DH.[Document Type]='37'
GROUP BY DL.[Reservation No_]
), TT AS
(
  SELECT DL.[Reservation No_] 
       , SUM(DL.[TAF Line Amount (LCY)]) [Company TAF]
       , SUM(DL.[TAF Line Amount (LCY)]) [Company TAF post correction]
    FROM DynNavHRS.dbo.[HRS$Agency Display Line] DL WITH (NOLOCK)
	JOIN DM ON DM.[Display Case No_]=DL.[Display Case No_] AND DM.[Reservation No_]=DL.[Reservation No_]
GROUP BY DL.[Reservation No_]
), PY AS
(
SELECT SL.[Line No_] [Process No.]
     , SL.[Line Amount] / CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END [Payment TAF]
  FROM DynNavHRS.dbo.[HRS$Sales Invoice Line] SL WITH (NOLOCK)
  JOIN DynNavHRS.dbo.[HRS$Sales Invoice Header] SH WITH (NOLOCK) ON SL.[Document No_] = SH.[No_] AND SH.[Central Billing Fee]=1
)
--SELECT 
   SELECT AP.*
        , TT.[Company TAF]
        , TT.[Company TAF post correction]
		, PY.[Payment TAF]
		, BU.[Departure Date]
        , BU.HTO
	    , ROUND(CASE WHEN [Commissionable HTO]=0 THEN BU.HTO ELSE AP.[Commissionable HTO post correction]/[Commissionable HTO]*BU.HTO END,2) [HTO post correction]
		, BU.MUSE_ID [Muse ID]
     FROM AP
     JOIN BU ON BU.B_KEY=AP.[Reservation No.]
LEFT JOIN TT ON TT.[Reservation No_]=CAST(AP.[Reservation No.] AS varchar(20))
LEFT JOIN PY ON PY.[Process No.]=AP.ProcessNumber
    WHERE [Commissionable HTO]<>0


END
GO
