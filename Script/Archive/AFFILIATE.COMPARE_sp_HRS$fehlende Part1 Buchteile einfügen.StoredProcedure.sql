USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[COMPARE_sp_HRS$fehlende Part1 Buchteile einfügen]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [AFFILIATE].[COMPARE_sp_HRS$fehlende Part1 Buchteile einfügen]
AS
BEGIN
EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$fehlende Part1 Buchteile einfügen', 'INSERT', 'Start'
;WITH A AS
(
   SELECT AP1.[ReservationNo] [Reservation No_]
        , MIN(AP1.[ReservationPartNo]) [Part No_]
     FROM [DynNavHRS].[dbo].[COMPARE_HRS$Affiliate Postings] AP1
LEFT JOIN [DynNavHRS].[dbo].[COMPARE_HRS$Affiliate Postings] AP2
       ON AP1.[ReservationNo] = AP2.[ReservationNo]
      AND AP2.[ReservationPartNo] = 1
    WHERE AP2.[ReservationNo] IS NULL
 GROUP BY AP1.[ReservationNo]
)
INSERT INTO [DynNavHRS].[dbo].[COMPARE_HRS$Affiliate Postings]
           ([PostingDate]
           ,[DocumentDate]
           ,[Description]
           ,[Description2]
           ,[ReservationNo]
           ,[ReservationPartNo]
           ,[InvoiceNo]
           ,[Amount_LCY]
           ,[Turnover_LCY]
           ,[CommissionType]
           ,[CommissionRateProz]
           ,[RoomNights]
           ,[IsNetRate]
           ,[Amount_LCY_corr]
           ,[Turnover_LCY_corr]
           ,[CommissionType_corr]
           ,[CommissionRateProz_corr]
           ,[RoomNights_corr]
           ,[IsNetRate_corr]
           ,[DepartureDate]
           ,[AffiliatePartnerNo]
           ,[HotelNo]
           ,[NAVCompanyName]
           ,[CustomerNo]
           ,[CountryCode]
           ,[Chain]
           ,[Brand]
           ,[MuseID]
           ,[TopBonusID]
           ,[Max Entry No_]
           ,[IsNoShow]
           ,[IsCanceled]
           ,[ContractStatus]
           ,[ClientCompany]
           ,[Handbooking]
           ,[BookingUser]
           ,[ReservationSource]
           ,[NavTransCommType]
           ,[PaymentNONCommisionableStay]
           ,[PaymentCancelation]
           ,[PaymentNoShow]
           ,[ArivalDate]
           ,[ReservationDate]
           ,[AffiliateReference1]
           ,[AffiliateReference2]
           ,[ProcessNumber]
           ,[BookingCode]
           ,[Orderer]
           ,[Turnover_Breakfast_LCY]
           ,[Turnover_Breakfast_LCY_corr]
           ,[Amount]
           ,[Turnover]
           ,[CurrencyFaktor]
           ,[CurrencyCode]
           ,[Amount_corr]
           ,[Turnover_corr]
           ,[CurrencyFaktor_corr]
           ,[CurrencyCode_corr]
           ,[PostAffiliatePartnerNo]
           ,[ConfirmedReservationNo]
           ,[Travelagency Code]
           ,[Travelagency No_]
           ,[ReservationHeader])
SELECT [PostingDate]
      ,[DocumentDate]
      ,[Description]
      ,[Description2]
      ,[ReservationNo]
      ,1 [ReservationPartNo]
      ,[InvoiceNo]
      ,0.0 [Amount_LCY]
      ,0.0 [Turnover_LCY]
      ,[CommissionType]
      ,[CommissionRateProz]
      ,0 [RoomNights]
      ,[IsNetRate]
      ,0.0 [Amount_LCY_corr]
      ,0.0 [Turnover_LCY_corr]
      ,[CommissionType_corr]
      ,[CommissionRateProz_corr]
      ,0[RoomNights_corr]
      ,[IsNetRate_corr]
      ,[DepartureDate]
      ,[AffiliatePartnerNo]
      ,[HotelNo]
      ,[NAVCompanyName]
      ,[CustomerNo]
      ,[CountryCode]
      ,[Chain]
      ,[Brand]
      ,[MuseID]
      ,[TopBonusID]
      ,[Max Entry No_]
      ,[IsNoShow]
      ,[IsCanceled]
      ,[ContractStatus]
      ,[ClientCompany]
      ,[Handbooking]
      ,[BookingUser]
      ,[ReservationSource]
      ,[NavTransCommType]
      ,[PaymentNONCommisionableStay]
      ,[PaymentCancelation]
      ,[PaymentNoShow]
      ,[ArivalDate]
      ,[ReservationDate]
      ,[AffiliateReference1]
      ,[AffiliateReference2]
      ,[ProcessNumber]
      ,[BookingCode]
      ,[Orderer]
      ,0.0[Turnover_Breakfast_LCY]
      ,0.0[Turnover_Breakfast_LCY_corr]
      ,0.0[Amount]
      ,0.0[Turnover]
      ,[CurrencyFaktor]
      ,[CurrencyCode]
      ,0.0[Amount_corr]
      ,0.0[Turnover_corr]
      ,[CurrencyFaktor_corr]
      ,[CurrencyCode_corr]
      ,[PostAffiliatePartnerNo]
      ,[ConfirmedReservationNo]
      ,[Travelagency Code]
      ,[Travelagency No_]
      ,[ReservationHeader]
  FROM [DynNavHRS].[dbo].[COMPARE_HRS$Affiliate Postings] AP
  JOIN A ON 
       A.[Reservation No_] = AP.[ReservationNo]
   AND A.[Part No_]        = AP.[ReservationPartNo]
EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$fehlende Part1 Buchteile einfügen', 'INSERT', 'Ende'

EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$fehlende Part1 Buchteile einfügen', 'UPDATE', 'Start'
;WITH AP AS
(
  SELECT [ReservationNo]
       , AP.[MuseID]
       , SUM(CASE WHEN [ReservationPartNo]=1 THEN [Turnover_LCY_corr] ELSE 0 END) [Turnover Part 1]
       , SUM(CASE WHEN [ReservationPartNo]<>1 THEN [Turnover_LCY_corr] ELSE 0 END) [Turnover Part x]
    FROM [COMPARE_HRS$Affiliate Postings] AP WITH (NOLOCK)
GROUP BY [ReservationNo]
       , AP.[MuseID]
)
UPDATE AP1 SET
       AP1.[Turnover_LCY_corr] = 0.001
	 , AP1.[Turnover_corr] = 0.001
  FROM AP
  JOIN [COMPARE_HRS$Affiliate Postings] AP1
    ON AP1.ReservationNo = AP.ReservationNo
   AND AP1.ReservationPartNo = 1
 WHERE [Turnover Part 1] = 0
   AND [Turnover Part x] <> 0
   AND AP1.[Turnover_LCY_corr] = 0
EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$fehlende Part1 Buchteile einfügen', 'UPDATE', 'Ende'
END   
GO
