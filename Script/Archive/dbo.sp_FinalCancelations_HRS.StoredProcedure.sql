USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_FinalCancelations_HRS]    Script Date: 10.04.2024 14:31:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 19.11.2015
-- Description:	Populates [HRS$Cancellation Statistics] with statistics of final bookview cancellations
--
-- 20.04.20 ACS-2229 TMA Mark all final cancelled Reservations with Inquiry Sent = TRUE and Inquiry Set at = Invoce Date of Itelya Invoice
/*
  EXECUTE [dbo].[sp_FinalCancellations_HRS] '2022-01-01', '2022-01-31'

*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_FinalCancelations_HRS] 
--DECLARE
    @DateFrom datetime = NULL
  , @DateTo   datetime = NULL
AS
BEGIN
----------------------------------------------------------------------------------------------
-- Start 0. : Deklaration + Initialisierung
----------------------------------------------------------------------------------------------
  DECLARE @PostingDate DATETIME
  DECLARE @SortorderNo INTEGER, @ReservationNo VARCHAR(20), @PositionNo INTEGER, @BusinessRuleCode VARCHAR(10), @ContractGroupCode VARCHAR(10), @ContractCode VARCHAR(10), @Description VARCHAR(100), @ContractCalcFunctionCode VARCHAR(10), @NumberofRooms DECIMAL(37,20), @NumberofPerson DECIMAL(37,20), @RoomPrice DECIMAL(37,20), @BreakfastPrice DECIMAL(37,20), @BreakfastType INTEGER, @RateType INTEGER, @PriceType INTEGER, @CommissionRate DECIMAL(37,20), @CommissionFix DECIMAL(37,20), @ExchangeRate DECIMAL(37,20), @ForeignTaxPercent DECIMAL(37,20), @NumberofNights DECIMAL(37,20), @CommissionBaseAmountOUT DECIMAL(37,20), @CommissionAmountOUT DECIMAL(37,20), @LineAmountOUT DECIMAL(37,20), @HotelsalesinclVATOUT DECIMAL(37,20), @ForeignTaxAmountOUT DECIMAL(37,20), @CommissionFixOUT DECIMAL(37,20), @CommissionRateOUT DECIMAL(37,20), @ForeignTaxBaseAmountOUT DECIMAL(37,20), @ReservationStatus INTEGER, @ReservationDatefrom DATETIME, @ReservationDateto DATETIME, @RoomType INTEGER, @RateDescription VARCHAR(100), @RoomNumber INTEGER, @ActivityCode VARCHAR(40), @CommissionTaxType INTEGER, @timestampSource DATETIME, @ProcessNumber INTEGER, @InsertedbyUser VARCHAR(20), @Insertedat DATETIME, @ModifiedbyUser VARCHAR(20), @Modifiedat DATETIME, @LoyalityRewardsAccountNo VARCHAR(100), @CommissionType INTEGER, @RateKey INTEGER, @CurrencyCode VARCHAR(10), @HotelNo VARCHAR(20), @Chain VARCHAR(20), @Brand VARCHAR(20), @ClientNo INTEGER, @CountryRegionCode VARCHAR(10)
  DECLARE @Result      TABLE ([Sortorder No_] INTEGER, [Reservation No_] VARCHAR(20), [Position No_] INTEGER, [Business Rule Code] VARCHAR(20), [Contract Grp_ Code] VARCHAR(20), [Contract Code] VARCHAR(20), [Description] VARCHAR(250), [Contract Calc_ Func_ Code] VARCHAR(20), [Number of Rooms] INTEGER, [Number of Person] INTEGER, [Number of Nights] INTEGER, [Room Price] DECIMAL(37,20), [Breakfast Price] DECIMAL(37,20), [Breakfast Type] INTEGER, [Rate Type] INTEGER, [Price Type] INTEGER, [Commission Rate] DECIMAL(37,20), [Commission Fix] DECIMAL(37,20), [Exchange Rate Amout] DECIMAL(37,20), [Foreign Tax %] DECIMAL(37,20), [Reservation Status] INTEGER, [Reservation Date from] DATETIME, [Reservation Date to] DATETIME, [Room Type] INTEGER, [Rate Description] VARCHAR(250), [Room Number] INTEGER, [Activity Code] VARCHAR(250), [Commission Tax Type] INTEGER, [timestamp Source] DATETIME, [Process Number] INTEGER, [Inserted by User] VARCHAR(20), [Inserted at] DATETIME, [Modified by User] VARCHAR(20), [Modified at] DATETIME, [Loyality Rewards Account No_] VARCHAR(250), [Commission Type] INTEGER, [Rate Key] INTEGER, [Currency Code] VARCHAR(20), [Hotel No_] VARCHAR(20), [Chain] VARCHAR(20), [Brand] VARCHAR(20), [Client No_] INTEGER, [Country_Region Code] VARCHAR(20))
  DECLARE @AgencyLine  TABLE ([Reservation No_] VARCHAR(20), [Position No_] INTEGER, [Reservation Status] INTEGER, [Reservation Date from] DATETIME, [Reservation Date to] DATETIME, [Number of Rooms] INTEGER, [Room Type] INTEGER, [Rate Description] VARCHAR(100), [Room Price] DECIMAL(37,20), [Breakfast Type] INTEGER, [Breakfast Price] DECIMAL(37,20), [Commission Type] INTEGER, [Commission Rate] DECIMAL(37,20), [Commission Fix] DECIMAL(37,20), [Rate Type] INTEGER, [Rate Key] INTEGER, [Currency Code] VARCHAR(3), [Currency Faktor] DECIMAL(37,20), [Room Number] INTEGER, [Activity Code] VARCHAR(40), [Number of Person] INTEGER, [Hotel No_] VARCHAR(20), [Commission Tax Type] INTEGER, [timestamp Source] DATETIME, [Price Type] INTEGER, [Process Number] INTEGER, [Inserted by User] VARCHAR(20), [Inserted at] DATETIME, [Modified by User] VARCHAR(20), [Modified at] DATETIME, [Number of Nights] DECIMAL(37,20), [Commission Base Amount] DECIMAL(37,20), [Commission Amount] DECIMAL(37,20), [Commission Base Amount (LCY)] DECIMAL(37,20), [Commission Amount (LCY)] DECIMAL(37,20), [Foreign Tax %] DECIMAL(37,20), [Foreign Tax Amount] DECIMAL(37,20), [Line Amount] DECIMAL(37,20), [Line Amount (LCY)] DECIMAL(37,20), [Foreign Tax Base Amount] DECIMAL(37,20), [Hotel sales incl_ VAT] DECIMAL(37,20), [Calculated with Contract Code] VARCHAR(20), [Calculated with Function ID] VARCHAR(20), [Calculated with Function Desc_] VARCHAR(100), [Loyality Rewards Account No_] VARCHAR(100), [Chain] VARCHAR(20), [Brand] VARCHAR(20), [Client No_] INTEGER, [Country_Region Code] VARCHAR(10), [Contract Grp_ Code] VARCHAR(20), [Business Rule Code] VARCHAR(20), [Sortorder No_] INTEGER, PRIMARY KEY ([Reservation No_], [Position No_]))
  DECLARE @JobContrMap TABLE ([Job No_] VARCHAR(20), [Date of Reference] INTEGER, [Category] INTEGER, [Valid from] DATETIME, [Valid to] DATETIME, [Contract Code] VARCHAR(20), [Client No_] VARCHAR(20), [Agency Business Rule] VARCHAR(10), [Searchoder No_] INTEGER, [Inserted by User] VARCHAR(20), [Inserted at] DATETIME, [Modified by User] VARCHAR(20), [Modified at] DATETIME)
  
   SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE()),120),10) AS DATETIME)
   SELECT @DateTo = COALESCE(@DateTo,@PostingDate)
        , @DateFrom = COALESCE(@DateFrom,DATEADD(dd,1,DATEADD(mm,-1,@PostingDate)))
----------------------------------------------------------------------------------------------
-- Ende 0. : Deklaration + Initialisierung
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Start 1. : Update B_CANCELLATION in BUCHUNG 
----------------------------------------------------------------------------------------------
;WITH _History AS
(
SELECT AH.B_KEY     [Reservation No_]
     , AH.B_KEY_ALT [Parent Reservation No_]
     , AH.B_STATUS  [Reservation State] 
     , AH.MA_USER
  FROM DynNavHRS.HRSDB.BUCHUNG AH WITH (NOLOCK) 
  JOIN DynNavHRS.HRSDB.BUCHUNG AP ON AP.B_KEY = AH.B_KEY_ALT 
 WHERE AH.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
)
   UPDATE BU SET
          BU.B_CANCELLATION = 
          CASE WHEN H2.[Parent Reservation No_] IS NULL 
                AND H1.[Reservation State] = 10000 
                AND COALESCE(B_CANCELLATION,0)=0
                AND H1.MA_USER = 'BOOKVIEW'
               THEN 1
               ELSE 0
          END
     FROM _History H1
     JOIN DynNavHRS.HRSDB.BUCHUNG BU
       ON BU.B_KEY = H1.[Reservation No_]
LEFT JOIN _History H2 
       ON H2.[Parent Reservation No_] = H1.[Reservation No_]
    WHERE COALESCE(B_CANCELLATION,0) <>
          CASE WHEN COALESCE(H2.[Parent Reservation No_],0) = 0 
                AND H1.[Reservation State] = 10000 
                AND H1.MA_USER = 'BOOKVIEW'
               THEN 1
               ELSE 0
          END
----------------------------------------------------------------------------------------------
-- Ende 1. : Update B_CANCELLATION in BUCHUNG 
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Start 2. : Update [Final Cancellation] in [xxx$Correction Agency Header] 
----------------------------------------------------------------------------------------------
   UPDATE AH SET
          AH.[Final Cancellation] = BU.B_CANCELLATION
     FROM [HRS$Correction Agency Header] AH
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON CAST(BU.B_KEY AS varchar(20)) = AH.[Reservation No_]
    WHERE AH.[Final Cancellation] <> BU.B_CANCELLATION
   UPDATE AL SET
          AL.[Final Cancellation] = BU.B_CANCELLATION
     FROM [HRS$Correction Agency Line] AL
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON CAST(BU.B_KEY AS varchar(20)) = AL.[Reservation No_]
    WHERE AL.[Final Cancellation] <> BU.B_CANCELLATION

   UPDATE AH SET
          AH.[Final Cancellation] = BU.B_CANCELLATION
     FROM [HRS-CN$Correction Agency Header] AH
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON CAST(BU.B_KEY AS varchar(20)) = AH.[Reservation No_]
    WHERE AH.[Final Cancellation] <> BU.B_CANCELLATION
   UPDATE AL SET
          AL.[Final Cancellation] = BU.B_CANCELLATION
     FROM [HRS-CN$Correction Agency Line] AL
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON CAST(BU.B_KEY AS varchar(20)) = AL.[Reservation No_]
    WHERE AL.[Final Cancellation] <> BU.B_CANCELLATION

   UPDATE AH SET
          AH.[Final Cancellation] = BU.B_CANCELLATION
     FROM [HRS-BR$Correction Agency Header] AH
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = AH.[Reservation No_]
    WHERE AH.[Final Cancellation] <> BU.B_CANCELLATION
   UPDATE AL SET
          AL.[Final Cancellation] = BU.B_CANCELLATION
     FROM [HRS-BR$Correction Agency Line] AL
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON CAST(BU.B_KEY AS varchar(20)) = AL.[Reservation No_]
    WHERE AL.[Final Cancellation] <> BU.B_CANCELLATION
----------------------------------------------------------------------------------------------
-- Ende 2. : Update [Final Cancellation] in [xxx$Correction Agency Header] 
----------------------------------------------------------------------------------------------
   UPDATE AH SET AH.[Company No_] = AP.[Company-No_]
     FROM [HRS$Correction Agency Header]  AH WITH (NOLOCK)
     JOIN [Affiliate Partner]  AP WITH (NOLOCK)
       ON AP.[No_] = AH.[Client No_]
    WHERE AP.[Company-No_]<>''
      AND AH.[Company No_] <> AP.[Company-No_]
   UPDATE AH SET AH.[Company No_] = AP.[Company-No_]
     FROM [HRS-CN$Correction Agency Header]  AH WITH (NOLOCK)
     JOIN [Affiliate Partner]  AP WITH (NOLOCK)
       ON AP.[No_] = AH.[Client No_]
    WHERE AP.[Company-No_]<>''
      AND AH.[Company No_] <> AP.[Company-No_]
   UPDATE AH SET AH.[Company No_] = AP.[Company-No_]
     FROM [HRS-BR$Correction Agency Header]  AH WITH (NOLOCK)
     JOIN [Affiliate Partner]  AP WITH (NOLOCK)
       ON AP.[No_] = AH.[Client No_]
    WHERE AP.[Company-No_]<>''
      AND AH.[Company No_] <> AP.[Company-No_]

 UPDATE AL SET AL.ProcessNumber = P.BP_KEY
  FROM [HRS$Correction Agency Header] AL
  JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA P
    ON CAST(P.B_KEY AS varchar(20)) = AL.[Reservation No_]
 WHERE AL.ProcessNumber <> P.BP_KEY
 UPDATE AL SET AL.[Process Number] = P.BP_KEY
  FROM [HRS$Correction Agency Line] AL
  JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA P
    ON CAST(P.B_KEY AS varchar(20)) = AL.[Reservation No_]
 WHERE AL.[Process Number] <> P.BP_KEY
 
UPDATE AL SET AL.ProcessNumber = P.BP_KEY
  FROM [HRS$Agency Header] AL
  JOIN DynNavHRS.HRSDB.BUCHUNG P
    ON CAST(P.B_KEY AS varchar(20)) = AL.[Reservation No_]
 WHERE AL.ProcessNumber = 0 AND P.BP_KEY <> 0
UPDATE AL SET AL.[Process Number] = P.BP_KEY
  FROM [HRS$Agency Line] AL
  JOIN DynNavHRS.HRSDB.BUCHUNG P
    ON CAST(P.B_KEY AS varchar(20)) = AL.[Reservation No_]
 WHERE AL.[Process Number] = 0 AND P.BP_KEY <> 0
----------------------------------------------------------------------------------------------
-- Start 4. : Update [Inquiry Sent] in [xxx$Correction Agency Header] 
----------------------------------------------------------------------------------------------
UPDATE CH SET 
       CH.[Inquiry Sent]=1
     , CH.[Inquiry Sent At] = COALESCE(IV.INVOICE_DATE,'1753-01-01')
	 , CH.[Quality by User] = 'ITELYA'
	 , CH.[Quality at]      = COALESCE(IV.INVOICE_DATE,'1753-01-01')
  FROM [HRS$Correction Agency Header] CH
  JOIN DynNavHRS.HRSDB.CIA_PS_INVOICE IV WITH (NOLOCK)
    ON IV.BOOKING_PROCESS_ID_VALUE = CH.[ProcessNumber]
 WHERE CH.[Inquiry Sent]<>1
    OR CH.[Inquiry Sent At] <> COALESCE(IV.INVOICE_DATE,'1753-01-01')
	OR CH.[Quality by User] <> 'ITELYA'
	OR CH.[Quality at]      <> COALESCE(IV.INVOICE_DATE,'1753-01-01')

UPDATE CH SET 
       CH.[Inquiry Sent]=1
     , CH.[Inquiry Sent At] = COALESCE(IV.INVOICE_DATE,'1753-01-01')
	 , CH.[Quality by User] = 'ITELYA'
	 , CH.[Quality at]      = COALESCE(IV.INVOICE_DATE,'1753-01-01')
  FROM [HRS-CN$Correction Agency Header] CH
  JOIN DynNavHRS.HRSDB.CIA_PS_INVOICE IV WITH (NOLOCK)
    ON IV.BOOKING_PROCESS_ID_VALUE = CH.[ProcessNumber]
 WHERE CH.[Inquiry Sent]<>1
    OR CH.[Inquiry Sent At] <> COALESCE(IV.INVOICE_DATE,'1753-01-01')
	OR CH.[Quality by User] <> 'ITELYA'
	OR CH.[Quality at]      <> COALESCE(IV.INVOICE_DATE,'1753-01-01')

UPDATE CH SET 
       CH.[Inquiry Sent]=1
     , CH.[Inquiry Sent At] = COALESCE(IV.INVOICE_DATE,'1753-01-01')
	 , CH.[Quality by User] = 'ITELYA'
	 , CH.[Quality at]      = COALESCE(IV.INVOICE_DATE,'1753-01-01')
  FROM [HRS-BR$Correction Agency Header] CH
  JOIN DynNavHRS.HRSDB.CIA_PS_INVOICE IV WITH (NOLOCK)
    ON IV.BOOKING_PROCESS_ID_VALUE = CH.[ProcessNumber]
 WHERE CH.[Inquiry Sent]<>1
    OR CH.[Inquiry Sent At] <> COALESCE(IV.INVOICE_DATE,'1753-01-01')
	OR CH.[Quality by User] <> 'ITELYA'
	OR CH.[Quality at]      <> COALESCE(IV.INVOICE_DATE,'1753-01-01')
----------------------------------------------------------------------------------------------
-- Ende 4. : Update [Inquiry Sent] in [xxx$Correction Agency Header] 
----------------------------------------------------------------------------------------------
-- DECLARE @DateFrom date='2021-03-01', @DateTo date='2021-03-31'
PRINT 'EXEC [sp_UpdateCancelationStatistics] @DateFrom, @DateTo'
EXEC [sp_UpdateCancelationStatistics] @DateFrom, @DateTo

PRINT 'EXEC [sp_UpdateBOOKVIEWChanges]  @DateFrom, @DateTo'
EXEC [sp_UpdateBOOKVIEWChanges]  @DateFrom, @DateTo

----------------------------------------------------------------------------------------------
-- Start : BOOKVIEW - Änderungen in die Statistik-Tabelle schreiben 
----------------------------------------------------------------------------------------------
;WITH BVL_SUM AS
(
  SELECT BU.H_KEY [Hotel No_]
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE*1. - BL.B_TOTAL_RATE_INCLUSIVE*1.)/100.) [B_DEDUCTION]
       , SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) B_TOTAL_RATE_INCLUSIVE
       , ROUND(SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.)
       / SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.)*100.,0) [Reduction Rate %]
       , SUM(CASE WHEN BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE = 0 THEN 0 ELSE 1 END)[Reduced Bookings]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM))) [Assigned Posting Date]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND BF.B_TOTAL_RATE_INCLUSIVE > BL.B_TOTAL_RATE_INCLUSIVE
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM)))
)
UPDATE CS SET 
       CS.[Reduced Bookings] = CAST(BV.[Reduced Bookings] AS integer)
     , CS.[Reduction Rate %] = CAST(BV.[Reduction Rate %] AS integer)
  FROM [HRS$Cancellation Statistics] CS
  JOIN BVL_SUM BV ON BV.[Hotel No_] = CS.[Hotel No_] AND BV.[Assigned Posting Date] = CS.[Assigned Posting Date]
 WHERE CS.[Reduced Bookings] <> BV.[Reduced Bookings]
    OR CS.[Reduction Rate %] <> BV.[Reduction Rate %]
  
;WITH BVL_SUM AS
(
  SELECT BU.H_KEY [Hotel No_]
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE*1. - BL.B_TOTAL_RATE_INCLUSIVE*1.)/100.) [B_DEDUCTION]
       , SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) B_TOTAL_RATE_INCLUSIVE
       , ROUND(SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.)
       / SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.)*100.,0) [Reduction Rate %]
       , SUM(CASE WHEN BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE = 0 THEN 0 ELSE 1 END)[Reduced Bookings]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM))) [Assigned Posting Date]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND BF.B_TOTAL_RATE_INCLUSIVE > BL.B_TOTAL_RATE_INCLUSIVE
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM)))
)
UPDATE CS SET 
       CS.[Reduced Bookings] = CAST(BV.[Reduced Bookings] AS integer)
     , CS.[Reduction Rate %] = CAST(BV.[Reduction Rate %] AS integer)
  FROM [HRS-CN$Cancellation Statistics] CS
  JOIN BVL_SUM BV ON BV.[Hotel No_] = CS.[Hotel No_] AND BV.[Assigned Posting Date] = CS.[Assigned Posting Date]  
 WHERE CS.[Reduced Bookings] <> BV.[Reduced Bookings]
    OR CS.[Reduction Rate %] <> BV.[Reduction Rate %]

;WITH BVL_SUM AS
(
  SELECT BU.H_KEY [Hotel No_]
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE*1. - BL.B_TOTAL_RATE_INCLUSIVE*1.)/100.) [B_DEDUCTION]
       , SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) B_TOTAL_RATE_INCLUSIVE
       , ROUND(SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.)
       / SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.)*100.,0) [Reduction Rate %]
       , SUM(CASE WHEN BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE = 0 THEN 0 ELSE 1 END)[Reduced Bookings]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM))) [Assigned Posting Date]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND BF.B_TOTAL_RATE_INCLUSIVE > BL.B_TOTAL_RATE_INCLUSIVE
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM)))
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / DL.[Currency Faktor]) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction])
   SELECT B.[Hotel No_]
        , 0 [Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , 0 [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , 0 [Canceled Hotel Turnover (LCY)]
        , 0 [Inquiry Sent]
        , B.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , COALESCE(C.[Reduced Bookings],0)
        , COALESCE(C.[Reduction Rate %],0)
        , 0 [Roomnights]
        , 0 [Reduced Roomnights]
        , 0 [Roomnights Reduction Rate %]
        , 0 [Bookings with RN Reduction]
        , 0 [Breakfast Reduction Rate %]
        , 0 [Bookings with BF Reduction]
     FROM B 
LEFT JOIN BVL_SUM C ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]      
LEFT JOIN [HRS$Cancellation Statistics] CS WITH (NOLOCK)
       ON C.[Hotel No_] = CS.[Hotel No_] AND C.[Assigned Posting Date] = CS.[Assigned Posting Date]
    WHERE CS.[Hotel No_] IS NULL

;WITH BVL_SUM AS
(
  SELECT BU.H_KEY [Hotel No_]
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.) [B_DEDUCTION]
       , SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) B_TOTAL_RATE_INCLUSIVE
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.)
       / SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) [Reduction Rate %]
       , SUM(CASE WHEN BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE = 0 THEN 0 ELSE 1 END)[Reduced Bookings]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM))) [Assigned Posting Date]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND BF.B_TOTAL_RATE_INCLUSIVE > BL.B_TOTAL_RATE_INCLUSIVE
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM)))
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / DL.[Currency Faktor]) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-CN$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS-CN$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction])
   SELECT B.[Hotel No_]
        , 0 [Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , 0 [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , 0 [Canceled Hotel Turnover (LCY)]
        , 0 [Inquiry Sent]
        , B.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , COALESCE(C.[Reduced Bookings],0)
        , COALESCE(C.[Reduction Rate %],0)
        , 0 [Roomnights]
        , 0 [Reduced Roomnights]
        , 0 [Roomnights Reduction Rate %]
        , 0 [Bookings with RN Reduction]
        , 0 [Breakfast Reduction Rate %]
        , 0 [Bookings with BF Reduction]
     FROM B 
LEFT JOIN BVL_SUM C ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]      
LEFT JOIN [HRS-CN$Cancellation Statistics] CS WITH (NOLOCK)
       ON C.[Hotel No_] = CS.[Hotel No_] AND C.[Assigned Posting Date] = CS.[Assigned Posting Date]
    WHERE CS.[Hotel No_] IS NULL

;WITH BVL_SUM AS
(
  SELECT BU.H_KEY [Hotel No_]
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.) [B_DEDUCTION]
       , SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) B_TOTAL_RATE_INCLUSIVE
       , SUM((BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE)/100.)
       / SUM(BF.B_TOTAL_RATE_INCLUSIVE/100.) [Reduction Rate %]
       , SUM(CASE WHEN BF.B_TOTAL_RATE_INCLUSIVE - BL.B_TOTAL_RATE_INCLUSIVE = 0 THEN 0 ELSE 1 END)[Reduced Bookings]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM))) [Assigned Posting Date]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND BF.B_TOTAL_RATE_INCLUSIVE > BL.B_TOTAL_RATE_INCLUSIVE
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BU.B_AB_DATUM)+1, BU.B_AB_DATUM)))
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / DL.[Currency Faktor]) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS-BR$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-BR$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS-CN$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction])
   SELECT B.[Hotel No_]
        , 0 [Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , 0 [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , 0 [Canceled Hotel Turnover (LCY)]
        , 0 [Inquiry Sent]
        , B.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , COALESCE(C.[Reduced Bookings],0)
        , COALESCE(C.[Reduction Rate %],0)
        , 0 [Roomnights]
        , 0 [Reduced Roomnights]
        , 0 [Roomnights Reduction Rate %]
        , 0 [Bookings with RN Reduction]
        , 0 [Breakfast Reduction Rate %]
        , 0 [Bookings with BF Reduction]
     FROM B 
LEFT JOIN BVL_SUM C ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]      
LEFT JOIN [HRS-BR$Cancellation Statistics] CS WITH (NOLOCK)
       ON C.[Hotel No_] = CS.[Hotel No_] AND C.[Assigned Posting Date] = CS.[Assigned Posting Date]
    WHERE CS.[Hotel No_] IS NULL
--
-- Roomnights-Korrekturen
--
DECLARE @Roomnights TABLE([Hotel No_] int, [Assigned Posting Date] date, [Roomnights] int, [Reduced Roomnights] int, [Roomnights Reduction Rate %] int, [Bookings with RN Reduction] int, PRIMARY KEY ([Hotel No_], [Assigned Posting Date]))
;WITH BT AS
(
  SELECT BT.B_KEY
       , SUM(
         CASE WHEN (BT_RATE_TYP < 30000) AND (BT_ANZAHL*BT_PREIS) > 0 THEN 
           BT_ANZAHL * CASE WHEN BT_VON=BT_BIS THEN 1 ELSE DATEDIFF(dd,BT_VON,BT_BIS) END
         ELSE
           0
         END
         ) BT_RN
    FROM DynNavHRS.HRSDB.BUCHTEIL BT WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK) ON BT.B_KEY = BU.B_KEY
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BT.B_STATUS <> 19998
GROUP BY BT.B_KEY   
), RN AS
(
  SELECT BU.H_KEY [Hotel No_]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BL.B_AB_DATUM)+1, BL.B_AB_DATUM))) [Assigned Posting Date]
       , SUM(TF.BT_RN) [Roomnights]
       , SUM(TL.BT_RN) [Reduced Roomnights]
       , COUNT(TF.BT_RN) [Bookings with RN Reduction]
       , CAST(ROUND((SUM(TF.BT_RN) - SUM(TL.BT_RN)) *100. / SUM(TF.BT_RN),0) AS int) [Roomnights Reduction Rate %]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
    JOIN BT TF ON TF.B_KEY = BF.B_KEY
    JOIN BT TL ON TL.B_KEY = BL.B_KEY
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND TF.BT_RN <> TL.BT_RN
     AND TL.BT_RN > 0
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BL.B_AB_DATUM)+1, BL.B_AB_DATUM)))
)
  INSERT INTO @Roomnights
  SELECT [Hotel No_], [Assigned Posting Date], [Roomnights], [Reduced Roomnights], [Roomnights Reduction Rate %], [Bookings with RN Reduction]
    FROM RN
UPDATE [HRS$Cancellation Statistics] SET 
       [Roomnights]                   = 0
     , [Reduced Roomnights]           = 0
     , [Roomnights Reduction Rate %]  = 0
     , [Bookings with RN Reduction]   = 0
 WHERE [Roomnights]                  <> 0
    OR [Reduced Roomnights]          <> 0
    OR [Roomnights Reduction Rate %] <> 0
    OR [Bookings with RN Reduction]  <> 0
    
UPDATE [HRS-CN$Cancellation Statistics] SET 
       [Roomnights]                   = 0
     , [Reduced Roomnights]           = 0
     , [Roomnights Reduction Rate %]  = 0
     , [Bookings with RN Reduction]   = 0
 WHERE [Roomnights]                  <> 0
    OR [Reduced Roomnights]          <> 0
    OR [Roomnights Reduction Rate %] <> 0
    OR [Bookings with RN Reduction]  <> 0
     
UPDATE CS SET
       CS.[Roomnights]                   = RN.[Roomnights]
     , CS.[Reduced Roomnights]           = RN.[Reduced Roomnights]
     , CS.[Roomnights Reduction Rate %]  = RN.[Roomnights Reduction Rate %]
     , CS.[Bookings with RN Reduction]   = RN.[Bookings with RN Reduction]
  FROM [HRS$Cancellation Statistics] CS
  JOIN @Roomnights RN 
    ON RN.[Hotel No_]                    = CS.[Hotel No_]
   AND RN.[Assigned Posting Date]        = CS.[Assigned Posting Date]
 WHERE CS.[Roomnights]                  <> RN.[Roomnights]
    OR CS.[Reduced Roomnights]          <> RN.[Reduced Roomnights]
    OR CS.[Roomnights Reduction Rate %] <> RN.[Roomnights Reduction Rate %]
    OR CS.[Bookings with RN Reduction]  <> RN.[Bookings with RN Reduction]
    
UPDATE CS SET
       CS.[Roomnights]                   = RN.[Roomnights]
     , CS.[Reduced Roomnights]           = RN.[Reduced Roomnights]
     , CS.[Roomnights Reduction Rate %]  = RN.[Roomnights Reduction Rate %]
     , CS.[Bookings with RN Reduction]   = RN.[Bookings with RN Reduction]
  FROM [HRS-CN$Cancellation Statistics] CS
  JOIN @Roomnights RN 
    ON RN.[Hotel No_]                    = CS.[Hotel No_]
   AND RN.[Assigned Posting Date]        = CS.[Assigned Posting Date]
 WHERE CS.[Roomnights]                  <> RN.[Roomnights]
    OR CS.[Reduced Roomnights]          <> RN.[Reduced Roomnights]
    OR CS.[Roomnights Reduction Rate %] <> RN.[Roomnights Reduction Rate %]
    OR CS.[Bookings with RN Reduction]  <> RN.[Bookings with RN Reduction]
--
-- Frühstück-Korrekturen
--
DECLARE @Breakfast TABLE([Hotel No_] int, [Assigned Posting Date] date, [Breakfast Reduction Rate %] int, [Bookings with BF Reduction] int, PRIMARY KEY ([Hotel No_], [Assigned Posting Date]))
;WITH BT AS
(
  SELECT BT.B_KEY
       , SUM(
         CASE WHEN (BT_FRSTCK = 1) AND (BT_ANZAHL*BT_PAX_COUNT*BT_FRST_PREIS) > 0 THEN 
           BT_ANZAHL * BT_PAX_COUNT * BT_FRST_PREIS * CASE WHEN BT_VON=BT_BIS THEN 1 ELSE DATEDIFF(dd,BT_VON,BT_BIS) END
         ELSE
           0
         END
         ) BT_FRST_PREIS
    FROM DynNavHRS.HRSDB.BUCHTEIL BT WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK) ON BT.B_KEY = BU.B_KEY
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BT.B_STATUS <> 19998
GROUP BY BT.B_KEY   
), BF AS
(

  SELECT BU.H_KEY [Hotel No_]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BL.B_AB_DATUM)+1, BL.B_AB_DATUM))) [Assigned Posting Date]
       , COUNT(TF.BT_FRST_PREIS) [Bookings with BF Reduction]
       , CAST(ROUND((SUM(TF.BT_FRST_PREIS) - SUM(TL.BT_FRST_PREIS)) *100. 
       / SUM(TF.BT_FRST_PREIS),0) AS int) [Breakfast Reduction Rate %]
    FROM DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN DynNavHRS.HRSDB.BUCHUNG BF WITH (NOLOCK) ON BF.B_KEY = BU.B_KEY_LAST_NBVL
    JOIN DynNavHRS.HRSDB.BUCHUNG BL WITH (NOLOCK) ON BL.B_KEY = BU.B_KEY_LAST_BVL
    JOIN BT TF ON TF.B_KEY = BF.B_KEY
    JOIN BT TL ON TL.B_KEY = BL.B_KEY
   WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
     AND BL.B_STATUS < 10000
     AND TF.BT_FRST_PREIS <> TL.BT_FRST_PREIS
     AND TL.BT_FRST_PREIS > 0
GROUP BY BU.H_KEY
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,BL.B_AB_DATUM)+1, BL.B_AB_DATUM)))
)
  --INSERT INTO @Breakfast
  SELECT [Hotel No_], [Assigned Posting Date], [Breakfast Reduction Rate %], [Bookings with BF Reduction]
    FROM BF
UPDATE [HRS$Cancellation Statistics] SET 
       [Breakfast Reduction Rate %]     = 0
     , [Bookings with BF Reduction]     = 0
 WHERE [Breakfast Reduction Rate %]    <> 0
    OR [Bookings with BF Reduction]    <> 0
    
UPDATE [HRS-CN$Cancellation Statistics] SET 
       [Breakfast Reduction Rate %]     = 0
     , [Reduced Roomnights]             = 0
 WHERE [Breakfast Reduction Rate %]    <> 0
    OR [Bookings with BF Reduction]    <> 0
UPDATE CS SET
       CS.[Breakfast Reduction Rate %]  = RN.[Breakfast Reduction Rate %]
     , CS.[Bookings with BF Reduction]  = RN.[Bookings with BF Reduction]
  FROM [HRS$Cancellation Statistics] CS
  JOIN @Breakfast RN 
    ON RN.[Hotel No_]                   = CS.[Hotel No_]
   AND RN.[Assigned Posting Date]       = CS.[Assigned Posting Date]
 WHERE CS.[Breakfast Reduction Rate %] <> RN.[Breakfast Reduction Rate %]
    OR CS.[Bookings with BF Reduction] <> RN.[Bookings with BF Reduction]
    
UPDATE CS SET
       CS.[Breakfast Reduction Rate %]  = RN.[Breakfast Reduction Rate %]
     , CS.[Bookings with BF Reduction]  = RN.[Bookings with BF Reduction]
  FROM [HRS-CN$Cancellation Statistics] CS
  JOIN @Breakfast RN 
    ON RN.[Hotel No_]                   = CS.[Hotel No_]
   AND RN.[Assigned Posting Date]       = CS.[Assigned Posting Date]
 WHERE CS.[Breakfast Reduction Rate %] <> RN.[Breakfast Reduction Rate %]
    OR CS.[Bookings with BF Reduction] <> RN.[Bookings with BF Reduction]
----------------------------------------------------------------------------------------------
-- Ende : BOOKVIEW - Änderungen in die Statistik-Tabelle schreiben 
----------------------------------------------------------------------------------------------
END
GO
