USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Recalculate_TISCOVER]    Script Date: 10.04.2024 14:31:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 04.09.2012
-- Description:	Berechnet alle Regeln des letzten Monats
/*
  EXECUTE [dbo].[sp_Recalculate_TISCOVER] '2012-09-01', '2012-09-30'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_Recalculate_TISCOVER] 
    @DateFrom datetime = NULL
  , @DateTo   datetime = NULL
WITH RECOMPILE
AS
BEGIN
INSERT INTO [TISCOVER$Tax Group]([Code],[Description],[Use Hotelstamm]) SELECT CU.[No_], LEFT(CU.[Name],30), 0 FROM [TISCOVER$Customer] CU WITH (NOLOCK)LEFT JOIN [TISCOVER$Tax Group] TG WITH (NOLOCK) ON TG.[Code] = CU.[No_] WHERE TG.[Code] IS NULL

DECLARE @PostingDate DATETIME

IF DATEPART(dd,GETDATE())<3
BEGIN
  SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE()),120),10) AS DATETIME)
END

IF DATEPART(dd,GETDATE())>=3
BEGIN
  SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1-DATEPART(dd,GETDATE()),GETDATE()))),120),10) AS DATETIME)
END

 SELECT @DateTo = COALESCE(@DateTo,@PostingDate)
      , @DateFrom = COALESCE(@DateFrom,DATEADD(dd,1,DATEADD(mm,-1,@PostingDate)))
 
DECLARE @SortorderNo INTEGER, @ReservationNo VARCHAR(20), @PositionNo INTEGER, @BusinessRuleCode VARCHAR(10), @ContractGroupCode VARCHAR(10), @ContractCode VARCHAR(10), @Description VARCHAR(100), @ContractCalcFunctionCode VARCHAR(10), @NumberofRooms DECIMAL(37,20), @NumberofPerson DECIMAL(37,20), @RoomPrice DECIMAL(37,20), @BreakfastPrice DECIMAL(37,20), @BreakfastType INTEGER, @RateType INTEGER, @PriceType INTEGER, @CommissionRate DECIMAL(37,20), @CommissionFix DECIMAL(37,20), @ExchangeRate DECIMAL(37,20), @ForeignTaxPercent DECIMAL(37,20), @NumberofNights DECIMAL(37,20), @CommissionBaseAmountOUT DECIMAL(37,20), @CommissionAmountOUT DECIMAL(37,20), @LineAmountOUT DECIMAL(37,20), @HotelsalesinclVATOUT DECIMAL(37,20), @ForeignTaxAmountOUT DECIMAL(37,20), @CommissionFixOUT DECIMAL(37,20), @CommissionRateOUT DECIMAL(37,20), @ForeignTaxBaseAmountOUT DECIMAL(37,20), @ReservationStatus INTEGER, @ReservationDatefrom DATETIME, @ReservationDateto DATETIME, @RoomType INTEGER, @RateDescription VARCHAR(100), @RoomNumber INTEGER, @ActivityCode VARCHAR(40), @CommissionTaxType INTEGER, @timestampSource DATETIME, @ProcessNumber INTEGER, @InsertedbyUser VARCHAR(20), @Insertedat DATETIME, @ModifiedbyUser VARCHAR(20), @Modifiedat DATETIME, @LoyalityRewardsAccountNo VARCHAR(100), @CommissionType INTEGER, @RateKey INTEGER, @CurrencyCode VARCHAR(10), @HotelNo VARCHAR(20), @Chain VARCHAR(20), @Brand VARCHAR(20), @ClientNo INTEGER, @CountryRegionCode VARCHAR(10)
DECLARE @Result      TABLE ([Sortorder No_] INTEGER, [Reservation No_] VARCHAR(20), [Position No_] INTEGER, [Business Rule Code] VARCHAR(20), [Contract Grp_ Code] VARCHAR(20), [Contract Code] VARCHAR(20), [Description] VARCHAR(250), [Contract Calc_ Func_ Code] VARCHAR(20), [Number of Rooms] INTEGER, [Number of Person] INTEGER, [Number of Nights] INTEGER, [Room Price] DECIMAL(37,20), [Breakfast Price] DECIMAL(37,20), [Breakfast Type] INTEGER, [Rate Type] INTEGER, [Price Type] INTEGER, [Commission Rate] DECIMAL(37,20), [Commission Fix] DECIMAL(37,20), [Exchange Rate Amout] DECIMAL(37,20), [Foreign Tax %] DECIMAL(37,20), [Reservation Status] INTEGER, [Reservation Date from] DATETIME, [Reservation Date to] DATETIME, [Room Type] INTEGER, [Rate Description] VARCHAR(250), [Room Number] INTEGER, [Activity Code] VARCHAR(250), [Commission Tax Type] INTEGER, [timestamp Source] DATETIME, [Process Number] INTEGER, [Inserted by User] VARCHAR(20), [Inserted at] DATETIME, [Modified by User] VARCHAR(20), [Modified at] DATETIME, [Loyality Rewards Account No_] VARCHAR(250), [Commission Type] INTEGER, [Rate Key] INTEGER, [Currency Code] VARCHAR(20), [Hotel No_] VARCHAR(20), [Chain] VARCHAR(20), [Brand] VARCHAR(20), [Client No_] INTEGER, [Country_Region Code] VARCHAR(20))
DECLARE @AgencyLine  TABLE ([Reservation No_] VARCHAR(20), [Position No_] INTEGER, [Reservation Status] INTEGER, [Reservation Date from] DATETIME, [Reservation Date to] DATETIME, [Number of Rooms] INTEGER, [Room Type] INTEGER, [Rate Description] VARCHAR(100), [Room Price] DECIMAL(37,20), [Breakfast Type] INTEGER, [Breakfast Price] DECIMAL(37,20), [Commission Type] INTEGER, [Commission Rate] DECIMAL(37,20), [Commission Fix] DECIMAL(37,20), [Rate Type] INTEGER, [Rate Key] INTEGER, [Currency Code] VARCHAR(3), [Currency Faktor] DECIMAL(37,20), [Room Number] INTEGER, [Activity Code] VARCHAR(40), [Number of Person] INTEGER, [Hotel No_] VARCHAR(20), [Commission Tax Type] INTEGER, [timestamp Source] DATETIME, [Price Type] INTEGER, [Process Number] INTEGER, [Inserted by User] VARCHAR(20), [Inserted at] DATETIME, [Modified by User] VARCHAR(20), [Modified at] DATETIME, [Number of Nights] DECIMAL(37,20), [Commission Base Amount] DECIMAL(37,20), [Commission Amount] DECIMAL(37,20), [Commission Base Amount (LCY)] DECIMAL(37,20), [Commission Amount (LCY)] DECIMAL(37,20), [Foreign Tax %] DECIMAL(37,20), [Foreign Tax Amount] DECIMAL(37,20), [Line Amount] DECIMAL(37,20), [Line Amount (LCY)] DECIMAL(37,20), [Foreign Tax Base Amount] DECIMAL(37,20), [Hotel sales incl_ VAT] DECIMAL(37,20), [Calculated with Contract Code] VARCHAR(20), [Calculated with Function ID] VARCHAR(20), [Calculated with Function Desc_] VARCHAR(100), [Loyality Rewards Account No_] VARCHAR(100), [Chain] VARCHAR(20), [Brand] VARCHAR(20), [Client No_] INTEGER, [Country_Region Code] VARCHAR(10), [Contract Grp_ Code] VARCHAR(20), [Business Rule Code] VARCHAR(20), [Sortorder No_] INTEGER)
DECLARE @JobContrMap TABLE ([Job No_] VARCHAR(20), [Date of Reference] INTEGER, [Category] INTEGER, [Valid from] DATETIME, [Valid to] DATETIME, [Contract Code] VARCHAR(20), [Client No_] VARCHAR(20), [Agency Business Rule] VARCHAR(10), [Searchoder No_] INTEGER, [Inserted by User] VARCHAR(20), [Inserted at] DATETIME, [Modified by User] VARCHAR(20), [Modified at] DATETIME)

 ----------------------------------------------------------------------------------------------
 -- 1. Start : Reservierungsdatum korrigieren
 ----------------------------------------------------------------------------------------------

;WITH _History AS
(
SELECT AH.[Reservation No_],AH.[Parent Reservation No_],AH.[Reservation Date],AH.[Reservation Time] FROM [TISCOVER$Agency Header] AH WITH (NOLOCK) JOIN [TISCOVER$Agency Header] AP ON AP.[Reservation No_] = AH.[Parent Reservation No_] WHERE AH.[Departure Date] BETWEEN @DateFrom AND @DateTo UNION
SELECT AH.[Reservation No_],AH.[Parent Reservation No_],AH.[Reservation Date],AH.[Reservation Time] FROM [TISCOVER$Agency Header] AH WITH (NOLOCK) JOIN [TISCOVER$Correction Agency Header] AP ON AP.[Reservation No_] = AH.[Parent Reservation No_] WHERE AH.[Departure Date] BETWEEN @DateFrom AND @DateTo UNION 
SELECT AH.[Reservation No_],AH.[Parent Reservation No_],AH.[Reservation Date],AH.[Reservation Time] FROM [TISCOVER$Correction Agency Header] AH WITH (NOLOCK) JOIN [TISCOVER$Correction Agency Header] AP WITH (NOLOCK)ON AP.[Reservation No_] = AH.[Parent Reservation No_] WHERE AH.[Departure Date] BETWEEN @DateFrom AND @DateTo UNION 
SELECT AH.[Reservation No_],AH.[Parent Reservation No_],AH.[Reservation Date],AH.[Reservation Time] FROM [TISCOVER$Correction Agency Header] AH WITH (NOLOCK) WHERE [Parent Reservation No_] = '' AND AH.[Departure Date] BETWEEN @DateFrom AND @DateTo
), History AS
(
SELECT CAST([Reservation No_] AS VARCHAR(MAX)) [Path],20 Depth,[Reservation Date] [Date],[Reservation Time] [Time],[Reservation Date] [Date Actual],[Reservation Time] [Time Actual],[Reservation No_],[Reservation No_] [Root Reservation No_],[Parent Reservation No_] FROM _History WHERE [Parent Reservation No_] = '' UNION ALL 
SELECT _History.[Reservation No_]+'.'+History.[Path],History.Depth - 1,History.[Date],History.[Time],[Reservation Date] [Date Actual],[Reservation Time] [Time Actual],_History.[Reservation No_],History.[Root Reservation No_],_History.[Parent Reservation No_] FROM _History JOIN History ON History.[Reservation No_] = _History.[Parent Reservation No_] WHERE _History.[Parent Reservation No_] <> '' AND History.Depth>0 
)
, Fold AS (SELECT [Root Reservation No_],MIN(Depth) Depth FROM History WHERE [Parent Reservation No_] <> '' GROUP BY [Root Reservation No_])
UPDATE AH SET AH.[Reservation Date] = History.[Date]
  FROM History
  JOIN Fold ON Fold.[Root Reservation No_] = History.[Root Reservation No_] AND Fold.Depth = History.Depth
  JOIN [TISCOVER$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = History.[Reservation No_]
 WHERE AH.[Reservation Date] <> History.[Date]

-- ----------------------------------------------------------------------------------------------
-- 1. Ende : Reservierungsdatum korrigieren
-- ----------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------------------
-- 2. Start : Aktualisiere Dimensionen
-- ----------------------------------------------------------------------------------------------

INSERT INTO [TISCOVER$Agency Dimension] ([Contact Code],[Dimension Code],[Dimension Value Code],[Value Posting],[Parameter_Dimension])  
SELECT CO.[No_],'BRAND',CO.[Brand],1,1 FROM [TISCOVER$Contact] CO WITH (NOLOCK) LEFT JOIN [TISCOVER$Agency Dimension] D1 WITH (NOLOCK)ON D1.[Contact Code] = CO.[No_]AND D1.[Dimension Code] = 'BRAND' WHERE D1.[Contact Code] IS NULL

INSERT INTO [TISCOVER$Agency Dimension] ([Contact Code],[Dimension Code],[Dimension Value Code],[Value Posting],[Parameter_Dimension])  
SELECT CO.[No_],'CHAIN',CO.[Chain],1,1 FROM [TISCOVER$Contact] CO WITH (NOLOCK) LEFT JOIN [TISCOVER$Agency Dimension] D1 WITH (NOLOCK) ON D1.[Contact Code] = CO.[No_] AND D1.[Dimension Code] = 'CHAIN' WHERE D1.[Contact Code] IS NULL

INSERT INTO [TISCOVER$Agency Dimension] ([Contact Code],[Dimension Code],[Dimension Value Code],[Value Posting],[Parameter_Dimension])  
SELECT CO.[No_],'CONTRACT STATUS',CO.[Contract Status],1,1 FROM [TISCOVER$Contact] CO WITH (NOLOCK) LEFT JOIN [TISCOVER$Agency Dimension] D1 WITH (NOLOCK) ON D1.[Contact Code] = CO.[No_] AND D1.[Dimension Code] = 'CONTRACT STATUS' WHERE D1.[Contact Code] IS NULL

UPDATE AD SET AD.[Dimension Value Code] = CO.[Brand] FROM [TISCOVER$Contact] CO WITH (NOLOCK) LEFT JOIN [TISCOVER$Agency Dimension] AD WITH (NOLOCK)ON AD.[Contact Code] = CO.[No_]AND AD.[Dimension Code] = 'BRAND' WHERE AD.[Dimension Value Code] <> CO.[Brand]
UPDATE AD SET AD.[Dimension Value Code] = CO.[Chain] FROM [TISCOVER$Contact] CO WITH (NOLOCK) LEFT JOIN [TISCOVER$Agency Dimension] AD WITH (NOLOCK)ON AD.[Contact Code] = CO.[No_]AND AD.[Dimension Code] = 'CHAIN' WHERE AD.[Dimension Value Code] <> CO.[Chain]
UPDATE AD SET AD.[Dimension Value Code] = CO.[Contract Status] FROM [TISCOVER$Contact] CO WITH (NOLOCK) LEFT JOIN [TISCOVER$Agency Dimension] AD WITH (NOLOCK)ON AD.[Contact Code] = CO.[No_]AND AD.[Dimension Code] = 'CONTRACT STATUS' WHERE AD.[Dimension Value Code] <> CO.[Contract Status]

INSERT INTO [TISCOVER$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 18,CU.[No_],'BRAND',CU.[Brand],1,0 FROM [TISCOVER$Customer] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD ON DD.[Dimension Code] = 'BRAND' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 18 WHERE DD.[Table ID] IS NULL

INSERT INTO [TISCOVER$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 18,CU.[No_],'CHAIN',CU.[Chain],1,0 FROM [TISCOVER$Customer] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD ON DD.[Dimension Code] = 'CHAIN' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 18 WHERE DD.[Table ID] IS NULL

INSERT INTO [TISCOVER$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 18,CU.[No_],'CONTRACT STATUS',CU.[Contract Status],1,0 FROM [TISCOVER$Customer] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD ON DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 18 WHERE DD.[Table ID] IS NULL

UPDATE DD SET DD.[Dimension Value Code] = CU.[Brand] FROM [TISCOVER$Customer] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'BRAND' AND DD.[Table ID] = 18 WHERE DD.[Dimension Value Code] <> CU.[Brand]
UPDATE DD SET DD.[Dimension Value Code] = CU.[Chain] FROM [TISCOVER$Customer] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CHAIN' AND DD.[Table ID] = 18 WHERE DD.[Dimension Value Code] <> CU.[Chain]
UPDATE DD SET DD.[Dimension Value Code] = CU.[Contract Status] FROM [TISCOVER$Customer] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[Table ID] = 18 WHERE DD.[Dimension Value Code] <> CU.[Contract Status]

INSERT INTO [TISCOVER$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 167,CU.[No_],'BRAND',CU.[Brand],1,0 FROM [TISCOVER$Job] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD ON DD.[Dimension Code] = 'BRAND' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 167 WHERE DD.[Table ID] IS NULL

INSERT INTO [TISCOVER$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 167,CU.[No_],'CHAIN',CU.[Chain],1,0 FROM [TISCOVER$Job] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD ON DD.[Dimension Code] = 'CHAIN' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 167 WHERE DD.[Table ID] IS NULL

INSERT INTO [TISCOVER$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 167,CU.[No_],'CONTRACT STATUS',CU.[Contract Status],1,0 FROM [TISCOVER$Job] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD ON DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 167 WHERE DD.[Table ID] IS NULL

UPDATE DD SET DD.[Dimension Value Code] = CU.[Brand] FROM [TISCOVER$Job] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'BRAND' AND DD.[Table ID] = 167 WHERE DD.[Dimension Value Code] <> CU.[Brand]
UPDATE DD SET DD.[Dimension Value Code] = CU.[Chain] FROM [TISCOVER$Job] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CHAIN' AND DD.[Table ID] = 167 WHERE DD.[Dimension Value Code] <> CU.[Chain]
UPDATE DD SET DD.[Dimension Value Code] = CU.[Contract Status] FROM [TISCOVER$Job] CU WITH (NOLOCK) LEFT JOIN [TISCOVER$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[Table ID] = 167 WHERE DD.[Dimension Value Code] <> CU.[Contract Status]

-- ----------------------------------------------------------------------------------------------
-- 2. Ende : Aktualisiere Dimensionen
-- ----------------------------------------------------------------------------------------------

-- ----------------------------------------------------------------------------------------------
-- Start : Buchungszeilnen berechnen
-- ----------------------------------------------------------------------------------------------
;WITH 
  _AC AS (SELECT AC.[Contract Calc_ Func_ Code] , CASE WHEN AC.[Contract Calc_ Func_ Code] IN (11,12,2) THEN 0 ELSE AC.[Value %] END [Commission Rate], CASE WHEN AC.[Contract Calc_ Func_ Code] IN (1,10,12,4,9,8) THEN 0 ELSE AC.[Value Total (LCY)] END [Commission Fix], MAX(AC.[Code]) [Contract Code] FROM [TISCOVER$Agency Contract] AC WITH (NOLOCK) WHERE AC.Locked = 0 AND AC.[Contract Calc_ Func_ Code]<>'' GROUP BY AC.[Contract Calc_ Func_ Code], CASE WHEN AC.[Contract Calc_ Func_ Code] IN (11,12,2) THEN 0 ELSE AC.[Value %] END, CASE WHEN AC.[Contract Calc_ Func_ Code] IN (1,10,12,4,9,8) THEN 0 ELSE AC.[Value Total (LCY)] END)
,  AC AS (SELECT _AC.*, AC.[Description] FROM [TISCOVER$Agency Contract] AC WITH (NOLOCK) JOIN _AC ON _AC.[Contract Code] = AC.[Code])
, Corrections AS
(
   SELECT DL.[Reservation No_]
     FROM [TISCOVER$Agency Display Line] DL WITH (NOLOCK)
     JOIN [TISCOVER$Agency Display Header] DH WITH (NOLOCK)
       ON DH.[Case No_] = DL.[Display Case No_]
    WHERE DH.[Status] = 2
--UNION    
--   SELECT DL.[Reservation No_]
--     FROM [TISCOVER$Agency Display Line] DL WITH (NOLOCK)
--     JOIN [TISCOVER$Agency Display Header] DH WITH (NOLOCK)
--       ON DH.[Case No_] = DL.[Display Case No_]
--    WHERE DH.[Status] = 0
--UNION    
--   SELECT DL.[Reservation No_]
--     FROM [TISCOVER$Agency Display Line] DL WITH (NOLOCK)
--     JOIN [TISCOVER$Agency Display Header] DH WITH (NOLOCK)
--       ON DH.[Case No_] = DL.[Display Case No_]
--    WHERE DH.[Posting Date] = '2012-05-31'
), _AgencyLines AS
(
   SELECT AH.[Reservation No_], AL.[Position No_]
        , CASE WHEN ((AH.[MuseID] <> 'HRS' OR BS.[Category]=2) AND AL.[Commission Type]<>13) OR (AL.[Rate Description] LIKE 'Ratecode: IA0%' AND CY.Code<>'165') THEN 12 ELSE AL.[Commission Type] END [Commission Type]
        , CASE CASE WHEN ((AH.[MuseID] <> 'HRS' OR BS.[Category]=2) AND AL.[Commission Type]<>13) OR (AL.[Rate Description] LIKE 'Ratecode: IA0%' AND CY.Code<>'165') THEN 12 ELSE AL.[Commission Type] END WHEN  0 THEN 1 WHEN  1 THEN 2 WHEN  2 THEN 3 WHEN  3 THEN 4 WHEN  4 THEN 5 WHEN  5 THEN 6 WHEN  6 THEN 7 WHEN  7 THEN 8 WHEN  8 THEN 9 WHEN  9 THEN 10 WHEN 10 THEN 1 WHEN 11 THEN 11 WHEN 12 THEN 0 WHEN 13 THEN 12 END [Contract Calc_ Func_ Code]
        , AL.[Commission Fix], AL.[Commission Rate], AH.[Parent Reservation No_], AH.[Reservation Date], AH.[Departure Date], BS.[Category], AH.[Client No_], AH.[Hotel No_], CASE WHEN CO.[Contract Status] IN ('01','02') THEN '01' ELSE CO.[Contract Status] END [Contract Status]
        , CO.[Brand]
        , AH.[MuseID]
        , AH.[Currency Code]
        , CO.[Chain]
        , CO.[Country_Region Code]
        , CY.[Continent]
        , AL.[Number of Rooms]
        , AL.[Number of Person]
        , CASE WHEN DATEDIFF(dd,AL.[Reservation Date from],AL.[Reservation Date to])<1 THEN 1 ELSE DATEDIFF(dd,AL.[Reservation Date from],AL.[Reservation Date to]) END [Number of Nights]
        , AL.[Room Price]
        , AL.[Breakfast Price]
        , AL.[Breakfast Type]
        , AL.[Rate Type]
        , AL.[Price Type]
        , AL.[Room Type], AL.[Reservation Status], AL.[Reservation Date from], AL.[Reservation Date to], AL.[Rate Description], AL.[Room Number], AL.[Activity Code], AL.[Commission Tax Type], AL.[timestamp Source], AL.[Process Number], AL.[Inserted by User], AL.[Inserted at], AL.[Modified by User], AL.[Modified at], AL.[Loyality Rewards Account No_], AL.[Rate Key]
     FROM [TISCOVER$Agency Line]    AL WITH (NOLOCK)
     JOIN [TISCOVER$Agency Header]  AH WITH (NOLOCK)
       ON AH.[Reservation No_] = AL.[Reservation No_]
     JOIN [TISCOVER$Booking Source] BS WITH (NOLOCK)
       ON BS.[No_]             = AH.[Reservation Source]
     JOIN [TISCOVER$Contact]        CO WITH (NOLOCK)
       ON CO.[No_]             = AH.[Hotel No_]
     JOIN [TISCOVER$Country_Region] CY WITH (NOLOCK)
       ON CY.[Code]            = CO.[Country_Region Code]
LEFT JOIN Corrections C
       ON C.[Reservation No_] = AL.[Reservation No_]
    WHERE AH.[Booking Status]  >= 0
      AND AH.[Departure Date] BETWEEN @DateFrom AND @DateTo
      AND C.[Reservation No_] IS NULL
      --AND AH.[Chain ID] = 550
      --AND AH.[Brand ID] = 1460
      --AND AH.[Hotel No_] = 154339
      --AND AH.MuseID <> 'HRS'
      --AND AL.[Reservation No_] = 67587735
      --AND AH.ProcessNumber IN (28324497,28324499,28324495)
), AgencyLines AS
(
  SELECT 99 [Sortorder No_], AL.*, '' [Code], AC.[Contract Code], '' [Contract Grp_ Code] FROM _AgencyLines AL JOIN AC ON AC.[Contract Calc_ Func_ Code] = AL.[Contract Calc_ Func_ Code] AND AC.[Commission Fix] = AL.[Commission Fix] AND AC.[Commission Rate] = AL.[Commission Rate] UNION ALL
  SELECT  2 /*AGB 2012 */ [Sortorder No_], AL.*, R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code] FROM _AgencyLines AL JOIN [TISCOVER$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Date of Reference] = 1 AND R2.[Category] = AL.[Category] AND R2.[Partner No_] = '' AND R2.[Hotel No_] = '' AND R2.[Contract Status] = '' AND R2.[Brand] = '' AND R2.[Chain] = '' AND R2.[MuseID] = '' AND R2.[Country Code] = '' AND R2.[Continent] = '' AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND AL.[Reservation Date] BETWEEN R2.[Valid from] AND R2.[Valid to] AND AL.[Commission Type] = 12 UNION ALL 
  SELECT  1 /*Default  */ [Sortorder No_], AL.*, R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code] FROM _AgencyLines AL JOIN [TISCOVER$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Date of Reference] = 0 AND R2.[Category] = 0             AND R2.[Partner No_] = '' AND R2.[Hotel No_] = '' AND R2.[Contract Status] = '' AND R2.[Brand] = '' AND R2.[Chain] = '' AND R2.[MuseID] = '' AND R2.[Country Code] = '' AND R2.[Continent] = '' AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND AL.[Departure Date]   BETWEEN R2.[Valid from] AND R2.[Valid to] AND AL.[Commission Type] = 12 
)
, MaxSortorder AS (SELECT AL.[Reservation No_], AL.[Position No_], MAX(AL.[Sortorder No_]) [Sortorder No_] FROM AgencyLines AL GROUP BY AL.[Reservation No_], AL.[Position No_])
, _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [TISCOVER$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [TISCOVER$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate)
, ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
, TDMAX        AS (SELECT TD.[Tax Group Code], TD.[Tax Jurisdiction Code], MAX(TD.[Effective Date])[Effective Date] FROM [TISCOVER$Tax Detail] TD WITH (NOLOCK) GROUP BY TD.[Tax Group Code], TD.[Tax Jurisdiction Code])
, TDSELECT     AS (SELECT TM.[Tax Group Code], TM.[Tax Jurisdiction Code], TD.[Tax Below Maximum] FROM TDMAX TM JOIN [TISCOVER$Tax Detail] TD WITH (NOLOCK) ON TD.[Tax Group Code] = TM.[Tax Group Code] AND TD.[Tax Jurisdiction Code] = TM.[Tax Jurisdiction Code] AND TD.[Effective Date] = TM.[Effective Date])
, TaxDetail    AS (SELECT CO.[No_] [Hotel No_], CASE WHEN FT.[Use Hotelstamm] = 0 AND COALESCE(TG.[Use Hotelstamm],0) = 0 THEN FT.[VAT in %] ELSE COALESCE(T1.[Tax Below Maximum] ,0) END [VAT], CASE WHEN FT.[Use Hotelstamm] = 0 AND COALESCE(TG.[Use Hotelstamm],0) = 0 THEN FT.[Service Tax] ELSE COALESCE(T2.[Tax Below Maximum],0) END [SERVICETAX] FROM [TISCOVER$Contact] CO WITH (NOLOCK) JOIN [TISCOVER$Job] JO WITH (NOLOCK) ON JO.[Bill-to Contact No_] = CO.[No_] JOIN [TISCOVER$Foreign Tax] FT WITH (NOLOCK) ON FT.[Country] = CO.[Country_Region Code] LEFT JOIN [TISCOVER$Tax Group] TG WITH (NOLOCK) ON TG.[Code] = CO.[No_] LEFT JOIN TDSELECT T1 WITH (NOLOCK) ON T1.[Tax Group Code] = CO.[No_] AND T1.[Tax Jurisdiction Code] = 'VAT' LEFT JOIN TDSELECT T2 WITH (NOLOCK) ON T2.[Tax Group Code] = CO.[No_] AND T2.[Tax Jurisdiction Code] = 'SERVICETAX')
--SELECT * FROM _AgencyLines
INSERT INTO @Result
SELECT AL.[Sortorder No_], AL.[Reservation No_], AL.[Position No_], AL.[Code], AL.[Contract Grp_ Code], AL.[Contract Code], FU.[Description], AC.[Contract Calc_ Func_ Code], AL.[Number of Rooms], AL.[Number of Person], AL.[Number of Nights], AL.[Room Price], AL.[Breakfast Price], AL.[Breakfast Type], AL.[Rate Type], AL.[Price Type], AC.[Value %] [Commission Rate], AC.[Value Total (LCY)] [Commission Fix], ER.[Exchange Rate Amount], COALESCE(TD.SERVICETAX + TD.VAT,0), AL.[Reservation Status], AL.[Reservation Date from], AL.[Reservation Date to], AL.[Room Type], AL.[Rate Description], AL.[Room Number], AL.[Activity Code], AL.[Commission Tax Type], AL.[timestamp Source], AL.[Process Number], AL.[Inserted by User], AL.[Inserted at], AL.[Modified by User], AL.[Modified at], AL.[Loyality Rewards Account No_], AL.[Commission Type], AL.[Rate Key], AL.[Currency Code], AL.[Hotel No_], AL.[Chain], AL.[Brand], AL.[Client No_], AL.[Country_Region Code]
  FROM AgencyLines               AL
  JOIN MaxSortorder              MS
    ON MS.[Reservation No_]      = AL.[Reservation No_]
   AND MS.[Position No_]         = AL.[Position No_]
   AND MS.[Sortorder No_]        = AL.[Sortorder No_]
  JOIN ExchangeRate              ER
    ON ER.[Currency Code]        = AL.[Currency Code]
LEFT JOIN TaxDetail                 TD
    ON TD.[Hotel No_]            = AL.[Hotel No_]
  JOIN [TISCOVER$Agency Contract]     AC WITH (NOLOCK)
    ON AC.[Code]                 = AL.[Contract Code]
  JOIN [TISCOVER$Agency Contract Calc_ Function] FU WITH (NOLOCK)
    ON FU.[Code]                 = AC.[Contract Calc_ Func_ Code]
    
DECLARE @DEBUG int
 SELECT @DEBUG = 0 -- alle temporär berechneten Buchungszeilen anzeigen
 SELECT @DEBUG = 1 -- komplett neu berechnen
 --SELECT @DEBUG = 2 -- unterschiedliche zeigen
 --SELECT @DEBUG = 3 -- unterschiedliche für Daily Commission zurücksetzen
 --SELECT @DEBUG = 4 -- nur unterschiedliche angleichen
 --SELECT @DEBUG = 99 -- JobContractMapping aktualisieren
 
IF @DEBUG = 0
  SELECT * FROM @Result    

IF @DEBUG>0
BEGIN
  DECLARE cur CURSOR FOR
  SELECT * FROM @Result

  OPEN cur

  FETCH NEXT FROM cur INTO @SortorderNo, @ReservationNo, @PositionNo, @BusinessRuleCode, @ContractGroupCode, @ContractCode, @Description, @ContractCalcFunctionCode, @NumberofRooms, @NumberofPerson, @NumberofNights, @RoomPrice, @BreakfastPrice, @BreakfastType, @RateType, @PriceType, @CommissionRate, @CommissionFix, @ExchangeRate, @ForeignTaxPercent, @ReservationStatus, @ReservationDatefrom, @ReservationDateto, @RoomType, @RateDescription, @RoomNumber, @ActivityCode, @CommissionTaxType, @timestampSource, @ProcessNumber, @InsertedbyUser, @Insertedat, @ModifiedbyUser, @Modifiedat, @LoyalityRewardsAccountNo, @CommissionType, @RateKey, @CurrencyCode, @HotelNo, @Chain, @Brand, @ClientNo, @CountryRegionCode

  WHILE @@FETCH_STATUS=0
  BEGIN
    EXEC dbo.usp_CalcCommission 
      @ContractCalcFunctionCode 
    , @ForeignTaxPercent
    , @NumberofNights
    , @NumberofRooms
    , @NumberofPerson
    , @RoomPrice
    , @BreakfastPrice
    , @ExchangeRate
    , @RateType
    , @PriceType
    , @BreakfastType 
    , @ForeignTaxBaseAmountOUT OUTPUT
    , @CommissionRate          OUTPUT
    , @CommissionFix           OUTPUT
    , @ForeignTaxAmountOUT     OUTPUT
    , @CommissionBaseAmountOUT OUTPUT
    , @CommissionAmountOUT     OUTPUT
    , @LineAmountOUT           OUTPUT
    , @HotelsalesinclVATOUT    OUTPUT
 
    INSERT INTO @AgencyLine 
    SELECT @ReservationNo, @PositionNo, @ReservationStatus, @ReservationDatefrom, @ReservationDateto, @NumberofRooms, @RoomType, @RateDescription, @RoomPrice, @BreakfastType, @BreakfastPrice, @CommissionType, @CommissionRate, @CommissionFix, @RateType, @RateKey, @CurrencyCode, @ExchangeRate, @RoomNumber, @ActivityCode, @NumberofPerson, @HotelNo, @CommissionTaxType, @timestampSource, @PriceType, @ProcessNumber, @InsertedbyUser, @Insertedat, @ModifiedbyUser, @Modifiedat, @NumberofNights, @CommissionBaseAmountOUT, @CommissionAmountOUT, ROUND(@CommissionBaseAmountOUT / @ExchangeRate,2), ROUND(@CommissionAmountOUT / @ExchangeRate,2), @ForeignTaxPercent, @ForeignTaxAmountOUT, @LineAmountOUT, ROUND(@LineAmountOUT / @ExchangeRate,2), @ForeignTaxBaseAmountOUT, @HotelsalesinclVATOUT, @ContractCode, @ContractCalcFunctionCode, @Description, @LoyalityRewardsAccountNo, @Chain, @Brand, @ClientNo, @CountryRegionCode, @ContractGroupCode, @BusinessRuleCode, @SortorderNo

    FETCH NEXT FROM cur INTO @SortorderNo, @ReservationNo, @PositionNo, @BusinessRuleCode, @ContractGroupCode, @ContractCode, @Description, @ContractCalcFunctionCode, @NumberofRooms, @NumberofPerson, @NumberofNights, @RoomPrice, @BreakfastPrice, @BreakfastType, @RateType, @PriceType, @CommissionRate, @CommissionFix, @ExchangeRate, @ForeignTaxPercent, @ReservationStatus, @ReservationDatefrom, @ReservationDateto, @RoomType, @RateDescription, @RoomNumber, @ActivityCode, @CommissionTaxType, @timestampSource, @ProcessNumber, @InsertedbyUser, @Insertedat, @ModifiedbyUser, @Modifiedat, @LoyalityRewardsAccountNo, @CommissionType, @RateKey, @CurrencyCode, @HotelNo, @Chain, @Brand, @ClientNo, @CountryRegionCode
  END

  CLOSE cur
  DEALLOCATE cur
  
  IF @DEBUG = 99
  BEGIN
  
  INSERT INTO @JobContrMap
  SELECT AL.[Hotel No_], BR.[Date of Reference], BR.[Category], BR.[Valid from], MAX(BR.[Valid to]), MAX(BR.[Contract Code]), MAX(BR.[Partner No_]), MAX(BR.[Code]), MAX(SO.[No_]), MAX(AL.[Inserted by User]), MAX(AL.[Inserted at]), MAX(AL.[Modified by User]), MAX(AL.[Modified at])
    FROM @AgencyLine AL
    JOIN [TISCOVER$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
      ON SO.[Sortorder No_]                   = AL.[Sortorder No_]
    JOIN [TISCOVER$Agency Business Rules]         BR WITH (NOLOCK)
      ON BR.[Code]                            = AL.[Business Rule Code]
GROUP BY AL.[Hotel No_]
       , BR.[Date of Reference]
       , BR.[Category]
       , BR.[Valid from]      

TRUNCATE TABLE [TISCOVER$Job Contract Mapping]       
  INSERT INTO [TISCOVER$Job Contract Mapping]([Job No_], [Date of Reference], [Category], [Valid from], [Valid to], [Contract Code], [Client No_], [Agency Business Rule], [Inserted by User], [Inserted at], [Modified by User], [Modified at], [Searchoder No_])
  SELECT AL.[Job No_], AL.[Date of Reference], AL.[Category], AL.[Valid from], AL.[Valid to], AL.[Contract Code], AL.[Client No_], AL.[Agency Business Rule], AL.[Inserted by User], AL.[Inserted at], AL.[Modified by User], AL.[Modified at], AL.[Searchoder No_]
    FROM @JobContrMap                        AL

  END -- @DEBUG=99

  
  IF @DEBUG=1
  BEGIN  
  UPDATE L2 SET
         L2.[Commission Type]               = L1.[Commission Type]
       , L2.[Commission Rate]               = L1.[Commission Rate]
       , L2.[Commission Fix]                = L1.[Commission Fix]
       , L2.[Currency Code]                 = L1.[Currency Code]
       , L2.[Currency Faktor]               = L1.[Currency Faktor]
       , L2.[Number of Nights]              = L1.[Number of Nights]
       , L2.[Commission Base Amount]        = L1.[Commission Base Amount]
       , L2.[Commission Amount]             = L1.[Commission Amount]
       , L2.[Commission Base Amount (LCY)]  = L1.[Commission Base Amount (LCY)]
       , L2.[Commission Amount (LCY)]       = L1.[Commission Amount (LCY)]
       , L2.[Foreign Tax %]                 = L1.[Foreign Tax %]
       , L2.[Foreign Tax Amount]            = L1.[Foreign Tax Amount]
       , L2.[Line Amount]                   = L1.[Line Amount]
       , L2.[Line Amount (LCY)]             = L1.[Line Amount (LCY)]
       , L2.[Foreign Tax Base Amount]       = L1.[Foreign Tax Base Amount]
       , L2.[Hotel sales incl_ VAT]         = L1.[Hotel sales incl_ VAT]
       , L2.[Calculated with Contract Code] = L1.[Calculated with Contract Code]
       , L2.[Calculated with Function ID]   = L1.[Calculated with Function ID]
       , L2.[Calculated with Function Desc_]= L1.[Calculated with Function Desc_]
       , L2.[Chain]                         = L1.[Chain]
       , L2.[Brand]                         = L1.[Brand]
       , L2.[Client No_]                    = L1.[Client No_]
       , L2.[Country_Region Code]           = L1.[Country_Region Code]     
    FROM @AgencyLine L1
    JOIN [TISCOVER$Agency Line] L2
      ON L2.[Reservation No_] = L1.[Reservation No_] 
     AND L2.[Position No_]    = L1.[Position No_]
   
  UPDATE L2 SET
         L2.[Commission Type]               = L1.[Commission Type]
       , L2.[Commission Rate]               = L1.[Commission Rate]
       , L2.[Commission Fix]                = L1.[Commission Fix]
       , L2.[Currency Code]                 = L1.[Currency Code]
       , L2.[Currency Faktor]               = L1.[Currency Faktor]
       , L2.[Number of Nights]              = L1.[Number of Nights]
       , L2.[Commission Base Amount]        = L1.[Commission Base Amount]
       , L2.[Commission Amount]             = L1.[Commission Amount]
       , L2.[Commission Base Amount (LCY)]  = L1.[Commission Base Amount (LCY)]
       , L2.[Commission Amount (LCY)]       = L1.[Commission Amount (LCY)]
       , L2.[Foreign Tax %]                 = L1.[Foreign Tax %]
       , L2.[Foreign Tax Amount]            = L1.[Foreign Tax Amount]
       , L2.[Line Amount]                   = L1.[Line Amount]
       , L2.[Line Amount (LCY)]             = L1.[Line Amount (LCY)]
       , L2.[Foreign Tax Base Amount]       = L1.[Foreign Tax Base Amount]
       , L2.[Hotel sales incl_ VAT]         = L1.[Hotel sales incl_ VAT]
       , L2.[Calculated with Contract Code] = L1.[Calculated with Contract Code]
       , L2.[Calculated with Function ID]   = L1.[Calculated with Function ID]
       , L2.[Calculated with Function Desc_]= L1.[Calculated with Function Desc_]
       , L2.[Client No_]                    = L1.[Client No_]
    FROM @AgencyLine L1
    JOIN [TISCOVER$Agency Display Line] L2
      ON L2.[Reservation No_] = L1.[Reservation No_] 
     AND L2.[Position No_]    = L1.[Position No_]
    JOIN [TISCOVER$Agency Display Header] H
      ON H.[Case No_] = L2.[Display Case No_]
     AND H.[Posting Date] = @PostingDate
     AND H.[Posted Invoice No_] = ''
     AND H.[Correction from] = ''
     AND L2.Action = 0

  UPDATE AH SET
         AH.[Booking Status]             = 1
       , AH.[Contract Code]              = AL.[Calculated with Contract Code]
       , AH.[Contract Group Code]        = AL.[Contract Grp_ Code]
       , AH.[Agency Business Rules Code] = AL.[Business Rule Code]
       , AH.[Chain ID]                   = AL.[Chain]
       , AH.[Brand ID]                   = AL.[Brand]
    FROM [TISCOVER$Agency Header] AH
    JOIN @AgencyLine AL
      ON AL.[Reservation No_] = AH.[Reservation No_]

  INSERT INTO @JobContrMap
  SELECT AL.[Hotel No_], BR.[Date of Reference], BR.[Category], BR.[Valid from], MAX(BR.[Valid to]), MAX(BR.[Contract Code]), MAX(BR.[Partner No_]), MAX(BR.[Code]), MAX(SO.[No_]), MAX(AL.[Inserted by User]), MAX(AL.[Inserted at]), MAX(AL.[Modified by User]), MAX(AL.[Modified at])
    FROM @AgencyLine AL
    JOIN [TISCOVER$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
      ON SO.[Sortorder No_]                   = AL.[Sortorder No_]
    JOIN [TISCOVER$Agency Business Rules]         BR WITH (NOLOCK)
      ON BR.[Code]                            = AL.[Business Rule Code]
GROUP BY AL.[Hotel No_]
       , BR.[Date of Reference]
       , BR.[Category]
       , BR.[Valid from]      

TRUNCATE TABLE [TISCOVER$Job Contract Mapping]       
  INSERT INTO [TISCOVER$Job Contract Mapping]([Job No_], [Date of Reference], [Category], [Valid from], [Valid to], [Contract Code], [Client No_], [Agency Business Rule], [Inserted by User], [Inserted at], [Modified by User], [Modified at], [Searchoder No_])
  SELECT AL.[Job No_], AL.[Date of Reference], AL.[Category], AL.[Valid from], AL.[Valid to], AL.[Contract Code], AL.[Client No_], AL.[Agency Business Rule], AL.[Inserted by User], AL.[Inserted at], AL.[Modified by User], AL.[Modified at], AL.[Searchoder No_]
    FROM @JobContrMap                        AL
  END -- @DEBUG=1     

  IF @DEBUG=2
  BEGIN  
  SELECT L2.[Reservation No_], L2.[Position No_]
       , L2.[Commission Type]               , L1.[Commission Type]
       , L2.[Commission Rate]               , L1.[Commission Rate]
       , L2.[Commission Fix]                , L1.[Commission Fix]
       , L2.[Commission Base Amount]        , L1.[Commission Base Amount]
       , L2.[Commission Amount]             , L1.[Commission Amount]
       , L2.[Foreign Tax %]                 , L1.[Foreign Tax %]
       , L2.[Line Amount]                   , L1.[Line Amount]
       , L2.[Foreign Tax Base Amount]       , L1.[Foreign Tax Base Amount]
       , L2.[Hotel sales incl_ VAT]         , L1.[Hotel sales incl_ VAT]
       , L2.[Calculated with Contract Code] , L1.[Calculated with Contract Code]
       , L2.[Calculated with Function ID]   , L1.[Calculated with Function ID]
       , L2.[Calculated with Function Desc_], L1.[Calculated with Function Desc_]
       , L1.*
    FROM @AgencyLine L1
    JOIN [TISCOVER$Agency Line] L2
      ON L2.[Reservation No_] = L1.[Reservation No_] 
     AND L2.[Position No_]    = L1.[Position No_]
     AND L2.[Calculated with Contract Code] <> ''
   WHERE ABS(L2.[Commission Base Amount]-L1.[Commission Base Amount]) > 1
      OR ABS(L2.[Commission Amount]-L1.[Commission Amount]) > 1
      OR L2.[Foreign Tax %]                 <> L1.[Foreign Tax %]
      OR ABS(L2.[Line Amount]-L1.[Line Amount]) > 1
      OR ABS(L2.[Foreign Tax Base Amount]-L1.[Foreign Tax Base Amount]) > 1
      OR L2.[Calculated with Function ID]   <> L1.[Calculated with Function ID]
      OR L2.[Calculated with Function Desc_]<> L1.[Calculated with Function Desc_]
  END -- @DEBUG=2

  IF @DEBUG=3
  BEGIN  
  UPDATE H2 SET
         H2.[Contract Code] = ''
       , H2.[Contract Group Code] = ''
       , H2.[Agency Business Rules Code] = ''
       , H2.[Booking Status] = 0
    FROM @AgencyLine L1
    JOIN [TISCOVER$Agency Line] L2
      ON L2.[Reservation No_] = L1.[Reservation No_] 
     AND L2.[Position No_]    = L1.[Position No_]
     AND L2.[Calculated with Contract Code] <> ''
    JOIN [TISCOVER$Agency Header] H2
      ON H2.[Reservation No_] = L1.[Reservation No_] 
   WHERE ABS(L2.[Commission Base Amount]-L1.[Commission Base Amount]) > 1
      OR ABS(L2.[Commission Amount]-L1.[Commission Amount]) > 1
      OR L2.[Foreign Tax %]                 <> L1.[Foreign Tax %]
      OR ABS(L2.[Line Amount]-L1.[Line Amount]) > 1
      OR ABS(L2.[Foreign Tax Base Amount]-L1.[Foreign Tax Base Amount]) > 1
      OR L2.[Calculated with Function ID]   <> L1.[Calculated with Function ID]
      OR L2.[Calculated with Function Desc_]<> L1.[Calculated with Function Desc_]
      
  UPDATE L2 SET
         L2.[Calculated with Function ID] = ''
       , L2.[Calculated with Function Desc_] = ''
       , L2.[Calculated with Contract Code] = ''
    FROM @AgencyLine L1
    JOIN [TISCOVER$Agency Line] L2
      ON L2.[Reservation No_] = L1.[Reservation No_] 
     AND L2.[Position No_]    = L1.[Position No_]
     AND L2.[Calculated with Contract Code] <> ''
    JOIN [TISCOVER$Agency Header] H2
      ON H2.[Reservation No_] = L1.[Reservation No_] 
   WHERE ABS(L2.[Commission Base Amount]-L1.[Commission Base Amount]) > 1
      OR ABS(L2.[Commission Amount]-L1.[Commission Amount]) > 1
      OR L2.[Foreign Tax %]                 <> L1.[Foreign Tax %]
      OR ABS(L2.[Line Amount]-L1.[Line Amount]) > 1
      OR ABS(L2.[Foreign Tax Base Amount]-L1.[Foreign Tax Base Amount]) > 1
      OR L2.[Calculated with Function ID]   <> L1.[Calculated with Function ID]
      OR L2.[Calculated with Function Desc_]<> L1.[Calculated with Function Desc_]
  END -- @DEBUG=3

  IF @DEBUG=4
  BEGIN  
  UPDATE L2 SET
         L2.[Commission Type]               = L1.[Commission Type]
       , L2.[Commission Rate]               = L1.[Commission Rate]
       , L2.[Commission Fix]                = L1.[Commission Fix]
       , L2.[Currency Code]                 = L1.[Currency Code]
       , L2.[Currency Faktor]               = L1.[Currency Faktor]
       , L2.[Number of Nights]              = L1.[Number of Nights]
       , L2.[Commission Base Amount]        = L1.[Commission Base Amount]
       , L2.[Commission Amount]             = L1.[Commission Amount]
       , L2.[Commission Base Amount (LCY)]  = L1.[Commission Base Amount (LCY)]
       , L2.[Commission Amount (LCY)]       = L1.[Commission Amount (LCY)]
       , L2.[Foreign Tax %]                 = L1.[Foreign Tax %]
       , L2.[Foreign Tax Amount]            = L1.[Foreign Tax Amount]
       , L2.[Line Amount]                   = L1.[Line Amount]
       , L2.[Line Amount (LCY)]             = L1.[Line Amount (LCY)]
       , L2.[Foreign Tax Base Amount]       = L1.[Foreign Tax Base Amount]
       , L2.[Hotel sales incl_ VAT]         = L1.[Hotel sales incl_ VAT]
       , L2.[Calculated with Contract Code] = L1.[Calculated with Contract Code]
       , L2.[Calculated with Function ID]   = L1.[Calculated with Function ID]
       , L2.[Calculated with Function Desc_]= L1.[Calculated with Function Desc_]
       , L2.[Chain]                         = L1.[Chain]
       , L2.[Brand]                         = L1.[Brand]
       , L2.[Client No_]                    = L1.[Client No_]
       , L2.[Country_Region Code]           = L1.[Country_Region Code]     
    FROM @AgencyLine L1
    JOIN [TISCOVER$Agency Line] L2
      ON L2.[Reservation No_] = L1.[Reservation No_] 
     AND L2.[Position No_]    = L1.[Position No_]
   WHERE ABS(L2.[Commission Base Amount]-L1.[Commission Base Amount]) > 1
      OR ABS(L2.[Commission Amount]-L1.[Commission Amount]) > 1
      OR L2.[Foreign Tax %]                 <> L1.[Foreign Tax %]
      OR ABS(L2.[Line Amount]-L1.[Line Amount]) > 1
      OR ABS(L2.[Foreign Tax Base Amount]-L1.[Foreign Tax Base Amount]) > 1
      OR L2.[Calculated with Function ID]   <> L1.[Calculated with Function ID]
      OR L2.[Calculated with Function Desc_]<> L1.[Calculated with Function Desc_]
   
  UPDATE AH SET
         AH.[Booking Status]             = 1
       , AH.[Contract Code]              = AL.[Calculated with Contract Code]
       , AH.[Contract Group Code]        = AL.[Contract Grp_ Code]
       , AH.[Agency Business Rules Code] = AL.[Business Rule Code]
    FROM [TISCOVER$Agency Header] AH
    JOIN @AgencyLine AL
      ON AL.[Reservation No_] = AH.[Reservation No_]
   WHERE AH.[Booking Status]             = 0

  INSERT INTO @JobContrMap
  SELECT AL.[Hotel No_], BR.[Date of Reference], BR.[Category], BR.[Valid from], MAX(BR.[Valid to]), MAX(BR.[Contract Code]), MAX(BR.[Partner No_]), MAX(BR.[Code]), MAX(SO.[No_]), MAX(AL.[Inserted by User]), MAX(AL.[Inserted at]), MAX(AL.[Modified by User]), MAX(AL.[Modified at])
    FROM @AgencyLine AL
    JOIN [TISCOVER$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
      ON SO.[Sortorder No_]                   = AL.[Sortorder No_]
    JOIN [TISCOVER$Agency Business Rules]         BR WITH (NOLOCK)
      ON BR.[Code]                            = AL.[Business Rule Code]
GROUP BY AL.[Hotel No_]
       , BR.[Date of Reference]
       , BR.[Category]
       , BR.[Valid from]      

TRUNCATE TABLE [TISCOVER$Job Contract Mapping]       
  INSERT INTO [TISCOVER$Job Contract Mapping]([Job No_], [Date of Reference], [Category], [Valid from], [Valid to], [Contract Code], [Client No_], [Agency Business Rule], [Inserted by User], [Inserted at], [Modified by User], [Modified at], [Searchoder No_])
  SELECT AL.[Job No_], AL.[Date of Reference], AL.[Category], AL.[Valid from], AL.[Valid to], AL.[Contract Code], AL.[Client No_], AL.[Agency Business Rule], AL.[Inserted by User], AL.[Inserted at], AL.[Modified by User], AL.[Modified at], AL.[Searchoder No_]
    FROM @JobContrMap                        AL
  END -- @DEBUG=1     

END

-- ----------------------------------------------------------------------------------------------
-- Ende : Buchungszeilnen berechnen
-- ----------------------------------------------------------------------------------------------
END
GO
