USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[RebateUpdateIncentive]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 24.02.20
-- Description:	Aktualisiert einen RevShare Jahres-Vertrag
/*
DECLARE
    @VendorNo varchar(20) = '5591'
  , @DateFrom date = '2019-03-01'
  , @DateTo date = '2020-02-29'
EXEC [dbo].[RebateUpdateIncentive] @VendorNo, @DateFrom, @DateTo
*/
-- =============================================
CREATE PROC [dbo].[RebateUpdateIncentive] 
    @VendorNo varchar(20) = '56021'
  , @DateFrom date = '2019-01-01'
  , @DateTo date = '2019-12-31'
AS
BEGIN
SET NOCOUNT ON
DECLARE @DocumentNo varchar(20)
DECLARE @MaxLineNo int
DECLARE @RebateAgreementNo varchar(20)

SELECT @DocumentNo = [No_], @RebateAgreementNo = [Rebate Agreement No_]
  FROM [HRS$Rebate Header] RH WITH (NOLOCK)
 WHERE RH.[Rebate-to Vendor No_] = @VendorNo
   AND RH.[Interval Start Date] = @DateFrom
   AND RH.[Interval End Date] = @DateTo

SELECT @MaxLineNo = MAX([Line No_])
  FROM [HRS$Rebate Line] RL WITH (NOLOCK)
 WHERE RL.[Document No_] = @DocumentNo

-- +++++++++++++++++++++++++++++++++++++++++++++++++ --
-- Create Reservation Source to Source Class Mapping --
-- +++++++++++++++++++++++++++++++++++++++++++++++++ --
DECLARE @RebuildBS int = 0
DECLARE @CountBS int = 0

IF @RebuildBS=1
  IF OBJECT_ID('tempdb..#BS') IS NOT NULL
    DROP TABLE #BS
IF OBJECT_ID('tempdb..#BS') IS NULL
  CREATE TABLE #BS([Reservation Source] int not null PRIMARY KEY, [Source Class] int not null)
SELECT @CountBS=COUNT(1) FROM #BS

IF @CountBS=0
WITH 
  BSS AS (SELECT RAH.[No_] [Rebate No_], RAH.[Rebate-to Vendor No_], BS_OFF.[No_], 1 [Source Class] FROM [HRS$Rebate Agreement Header] RAH WITH (NOLOCK) JOIN [HRS$Booking Source] BS_OFF WITH (NOLOCK) ON '|'+[Offline Reservation Source]+'|' LIKE '%|'+CAST(BS_OFF.[No_] AS varchar(10))+'|%' WHERE RAH.[Rebate-to Vendor No_] = @VendorNo AND RAH.Active = 1 UNION SELECT RAH.[No_] [Rebate No_], RAH.[Rebate-to Vendor No_], BS_API.[No_], 4 [Source Class] FROM [HRS$Rebate Agreement Header] RAH WITH (NOLOCK) JOIN [HRS$Booking Source] BS_API WITH (NOLOCK) ON '|'+[API Fee-Source]+'|' LIKE '%|'+CAST(BS_API.[No_] AS varchar(10))+'|%' WHERE RAH.[Rebate-to Vendor No_] = @VendorNo AND RAH.Active = 1 UNION SELECT RAH.[No_] [Rebate No_], RAH.[Rebate-to Vendor No_], BS_OBE.[No_], 5 [Source Class] FROM [HRS$Rebate Agreement Header] RAH WITH (NOLOCK) JOIN [HRS$Booking Source] BS_OBE WITH (NOLOCK) ON '|'+[OBE Fee-Source]+'|' LIKE '%|'+CAST(BS_OBE.[No_] AS varchar(10))+'|%' WHERE RAH.[Rebate-to Vendor No_] = @VendorNo AND RAH.Active = 1 UNION SELECT RAH.[No_] [Rebate No_], RAH.[Rebate-to Vendor No_], BS_GDS.[No_], 3 [Source Class] FROM [HRS$Rebate Agreement Header] RAH WITH (NOLOCK) JOIN [HRS$Booking Source] BS_GDS WITH (NOLOCK) ON '|'+[GDS Fee-Source]+'|' LIKE '%|'+CAST(BS_GDS.[No_] AS varchar(10))+'|%' WHERE RAH.[Rebate-to Vendor No_] = @VendorNo AND RAH.Active = 1)
, BSN AS (SELECT RAH.[No_] [Rebate No_], RAH.[Rebate-to Vendor No_], BS.[No_], BS.[Source Class] FROM [HRS$Rebate Agreement Header] RAH WITH (NOLOCK) , [HRS$Booking Source] BS WITH (NOLOCK) WHERE RAH.[Rebate-to Vendor No_] = @VendorNo AND RAH.Active = 1)
   INSERT INTO #BS
   SELECT BSN.[No_]
		, COALESCE(BSS.[Source Class],BSN.[Source Class]) [Source Class]
     FROM BSN
LEFT JOIN BSS
       ON BSS.[Rebate No_] = BSN.[Rebate No_]
      AND BSS.[No_]        = BSN.[No_]
-- ------------------------------------------------- --
-- Create Reservation Source to Source Class Mapping --
-- ------------------------------------------------- --

DECLARE @RebuildRL int = 1
DECLARE @CountRL int = 0

IF @RebuildRL=1
  IF OBJECT_ID('tempdb..#RL') IS NOT NULL
    DROP TABLE #RL
IF OBJECT_ID('tempdb..#RL') IS NULL
  CREATE TABLE #RL([Document No_] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Line No_] [int] NOT NULL,[Type] [int] NOT NULL,[Rebate Amount Line] [int] NOT NULL,[No Print] [tinyint] NOT NULL,[No_] [varchar](20) NOT NULL,[Rebate Agreement No_] [varchar](20) NOT NULL,[Posting Date (Import)] [datetime] NOT NULL,[Document Date (Import)] [datetime] NOT NULL,[Description] [varchar](120) NOT NULL,[Description 2] [varchar](120) NOT NULL,[Reservation No_] [int] NOT NULL,[Reservation Part No_] [int] NOT NULL,[Value Type] [int] NOT NULL,[Value] [varchar](250) NOT NULL,[Value Text] [varchar](250) NOT NULL,[Value Decimal] [decimal](38, 20) NOT NULL,[Value Boolean] [tinyint] NOT NULL,[Value Date] [datetime] NOT NULL,[Invoice No_] [varchar](20) NOT NULL,[Amount (LCY)] [decimal](38, 20) NOT NULL,[Turnover (LCY)] [decimal](38, 20) NOT NULL,[Commission Type] [int] NOT NULL,[Commission Rate %] [decimal](38, 20) NOT NULL,[Amount (LCY) (corr_)] [decimal](38, 20) NOT NULL,[Turnover (LCY) (corr_)] [decimal](38, 20) NOT NULL,[Commission Type (corr_)] [int] NOT NULL,[Commission Rate % (corr_)] [decimal](38, 20) NOT NULL,[Departure Date] [datetime] NOT NULL,[Affiliate Partner No_] [int] NOT NULL,[Hotel No_] [varchar](20) NOT NULL,[Room Nights] [decimal](38, 20) NOT NULL,[Is Net Rate] [tinyint] NOT NULL,[Room Nights Post Corection] [decimal](38, 20) NOT NULL,[Is Net Rate Post Corection] [tinyint] NOT NULL,[Max Entry No_] [int] NOT NULL,[Is No Show] [tinyint] NOT NULL,[Top Bonus ID] [varchar](50) NOT NULL,[MuseID] [varchar](20) NOT NULL,[Correction Kennung] [int] NOT NULL,[Company Name] [varchar](30) NOT NULL,[Customer No_] [varchar](20) NOT NULL,[Country Code] [int] NOT NULL,[Chain] [varchar](20) NOT NULL,[Brand] [varchar](20) NOT NULL,[Rebate-to Vendor No_] [varchar](20) NOT NULL,[Handbooking] [tinyint] NOT NULL,[Booking User] [varchar](120) NOT NULL,[Group contract Code] [varchar](10) NOT NULL,[Net Turnover (LCY)] [decimal](38, 20) NOT NULL,[Net Turnover (LCY) (corr_)] [decimal](38, 20) NOT NULL,[Arival Date] [datetime] NOT NULL,[Reservation Date] [datetime] NOT NULL,[Post Affiliate Partner No_] [varchar](20) NOT NULL,[Loyality Rewards Account 1 No_] [varchar](100) NOT NULL,[Loyality Rewards Account 2 No_] [varchar](100) NOT NULL,[Reservation Source] [int] NOT NULL,[Turnover Breakfast (LCY)] [decimal](38, 20) NOT NULL,[Turnover Breakfast (LCY) (c_)] [decimal](38, 20) NOT NULL,[Amount] [decimal](38, 20) NOT NULL,[Turnover] [decimal](38, 20) NOT NULL,[Net Turnover] [decimal](38, 20) NOT NULL,[Currency Faktor] [decimal](38, 20) NOT NULL,[Currency Code] [varchar](10) NOT NULL,[Amount (corr_)] [decimal](38, 20) NOT NULL,[Turnover (corr_)] [decimal](38, 20) NOT NULL,[Net Turnover (corr_)] [decimal](38, 20) NOT NULL,[Currency Faktor (corr_)] [decimal](38, 20) NOT NULL,[Currency Code (corr_)] [varchar](10) NOT NULL,[Process Number] [int] NOT NULL,[Travelagency No_] [int] NOT NULL,[Eligible RevShare] [tinyint] NOT NULL,[Booking Code] [varchar](80) NOT NULL,[Threshold Value Index] [int] NOT NULL,[Originating Country Code] [int] NOT NULL,[Source Class] [int] NOT NULL,[Record Type] int, CONSTRAINT [HRS$Rebate Line$0] PRIMARY KEY CLUSTERED ([Document No_] ASC,[Line No_] ASC))

SELECT @CountRL = COUNT(1) FROM #RL


-- ++++++++++++++++++++++++++++++++++++++++ --
-- Works only if a document allready exists --
-- ++++++++++++++++++++++++++++++++++++++++ --
IF @DocumentNo IS NULL
  PRINT 'In dieser Version wird ein Kontoauszug aktualisiert und nicht angelegt.'

IF NOT @DocumentNo IS NULL
BEGIN  

IF @CountRL=0
WITH 
   APV AS (SELECT C.Name [Company Name], [Affiliate Partner No_], AH.[Enable retroactive correction], COUNT(1) CountAPV, AH.[No_] [Rebate Agreement No_], APV.[Vendor No_] FROM [Company] C, [HRS$Rebate Agreement Header] AH WITH (NOLOCK), [HRS$Affiliate Partner Vendor] APV  WITH (NOLOCK) WHERE C.Name IN ('HRS','HRS-CN','HRS-BR') AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_] AND (APV.[Vendor No_] = @VendorNo OR @VendorNo = '') AND AH.[Active] = 1 GROUP BY C.Name, APV.[Affiliate Partner No_], AH.[Enable retroactive correction], AH.[No_], APV.[Vendor No_])
,  APT AS (SELECT C.Name [Company Name], APV.[Travelagency No_], AH.[Enable retroactive correction], COUNT(1) CountAPV, AH.[No_] [Rebate Agreement No_], APV.[Vendor No_] FROM [Company] C, [HRS$Rebate Agreement Header] AH WITH (NOLOCK), [HRS$Vendor Travelagency] APV  WITH (NOLOCK) WHERE C.Name IN ('HRS','HRS-CN','HRS-BR') AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_] AND (APV.[Vendor No_] = @VendorNo OR @VendorNo = '') AND AH.[Active] = 1 GROUP BY C.Name, APV.[Travelagency No_], AH.[Enable retroactive correction], AH.[No_], APV.[Vendor No_])
, _APV AS 
(      SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [HRS$Affiliate Postings]      AP WITH (NOLOCK) JOIN APV L ON AP.[AffiliatePartnerNo] = L.[Affiliate Partner No_] AND L.[Company Name] = 'HRS'      WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
 UNION SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [HRS-CN$Affiliate Postings]   AP WITH (NOLOCK) JOIN APV L ON AP.[AffiliatePartnerNo] = L.[Affiliate Partner No_] AND L.[Company Name] = 'HRS-CN'   WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
 UNION SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [HRS-BR$Affiliate Postings]   AP WITH (NOLOCK) JOIN APV L ON AP.[AffiliatePartnerNo] = L.[Affiliate Partner No_] AND L.[Company Name] = 'HRS-BR'   WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
 UNION SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK) JOIN APV L ON AP.[AffiliatePartnerNo] = L.[Affiliate Partner No_] AND L.[Company Name] = 'TISCOVER' WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
 UNION SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [Partner$Affiliate Postings]  AP WITH (NOLOCK) JOIN APV L ON AP.[AffiliatePartnerNo] = L.[Affiliate Partner No_] AND L.[Company Name] = 'Partner'  WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo)
 , _APT AS
(      SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [HRS$Affiliate Postings]      AP WITH (NOLOCK) JOIN APT L ON AP.[Travelagency No_]   = L.[Travelagency No_]      AND L.[Company Name] = 'HRS'      WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION  SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [HRS-CN$Affiliate Postings]   AP WITH (NOLOCK) JOIN APT L ON AP.[Travelagency No_]   = L.[Travelagency No_]      AND L.[Company Name] = 'HRS-CN'   WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION  SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [HRS-BR$Affiliate Postings]   AP WITH (NOLOCK) JOIN APT L ON AP.[Travelagency No_]   = L.[Travelagency No_]      AND L.[Company Name] = 'HRS-BR'   WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION  SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK) JOIN APT L ON AP.[Travelagency No_]   = L.[Travelagency No_]      AND L.[Company Name] = 'TISCOVER' WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION  SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name] FROM [Partner$Affiliate Postings]  AP WITH (NOLOCK) JOIN APT L ON AP.[Travelagency No_]   = L.[Travelagency No_]      AND L.[Company Name] = 'Partner'  WHERE AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo)
, _AP AS (SELECT * FROM _APV UNION SELECT * FROM _APT)
, AP AS
(
  SELECT AP.ReservationNo                         [Reservation No_]
     ,AP.ReservationPartNo                     [Reservation Part No_]
     ,MAX(COALESCE(AP.IsNoShow,0))             [Is No Show]
     ,MAX(COALESCE(AP.ProcessNumber,0))        [Process Number]
     ,MAX([Company Name])                      [Company Name]
     ,MAX(AP.PostingDate)                      [Posting Date]
     ,MAX(AP.DocumentDate)                     [Document Date]
     ,MAX(COALESCE([Travelagency Code],''))    [Travelagency Code]
     ,MAX(COALESCE([Travelagency No_],0))      [Travelagency No_]
     ,MIN(AP.[Rebate Agreement No_])           [Rebate Agreement No_]
     ,MIN(AP.InvoiceNo)                        [Invoice No_]
     ,MAX(COALESCE([Description],''))          [Description]
     ,MAX(COALESCE([Description2],''))         [Description 2]
     ,SUM(CASE WHEN [TAF Amount (LCY)]=0 THEN AP.[Amount_LCY] ELSE AP.[Amount_LCY]-AP.[TAF Amount (LCY)] END) [Amount (LCY)]
     ,SUM(AP.Turnover_LCY)                     [Turnover (LCY)]
     ,SUM(AP.Amount)                           [Amount]
     ,SUM(AP.Turnover)                         [Turnover]
     ,SUM(CASE WHEN [TAF Amount (LCY) (corr_)]=0 THEN AP.[Amount_LCY_corr] ELSE AP.[Amount_LCY_corr]-AP.[TAF Amount (LCY) (corr_)] END) [Amount (LCY) (corr_)]
     ,SUM(AP.Turnover_LCY_corr)                [Turnover (LCY) (corr_)]
     ,SUM(AP.Amount_corr)                      [Amount (corr_)]
     ,SUM(AP.Turnover_corr)                    [Turnover (corr_)]
     ,SUM(AP.RoomNights)                       [Room Nights]
     ,SUM(AP.RoomNights_corr)                  [Room Nights (corr_)]
     ,MAX(COALESCE(AP.IsNetRate,0))            [Is Net Rate]
     ,MAX(COALESCE(AP.IsNetRate_corr,0))       [Is Net Rate (corr_)]
     ,MAX(
            CASE AP.[CommissionType]
              WHEN 'Prozent' THEN 0
              WHEN 'Fix' THEN 1
              WHEN 'Prozent+Fix' THEN 2
              WHEN 'Prozent ohne Frstk' THEN 3
              WHEN 'Prozent ohne Frstk+Fix' THEN 4
              WHEN 'Online' THEN 5
              WHEN 'Zusatzprovision' THEN 6
              WHEN '% netto Logis' THEN 7
              WHEN '% netto Logis + Frstk' THEN 8
              WHEN '% Nettoumsatz' THEN 9
              WHEN 'keine Angaben' THEN 10
              WHEN 'Fix pro RN' THEN 11
              WHEN 'Default' THEN 12
              WHEN 'Company Rate' THEN 13
              ELSE 13
            END
          )                                       [Commission Type]
     ,MAX(AP.CommissionRateProz)               [Commission Rate %]
     ,MAX(
            CASE AP.[CommissionType_corr]
              WHEN 'Prozent' THEN 0
              WHEN 'Fix' THEN 1
              WHEN 'Prozent+Fix' THEN 2
              WHEN 'Prozent ohne Frstk' THEN 3
              WHEN 'Prozent ohne Frstk+Fix' THEN 4
              WHEN 'Online' THEN 5
              WHEN 'Zusatzprovision' THEN 6
              WHEN '% netto Logis' THEN 7
              WHEN '% netto Logis + Frstk' THEN 8
              WHEN '% Nettoumsatz' THEN 9
              WHEN 'keine Angaben' THEN 10
              WHEN 'Fix pro RN' THEN 11
              WHEN 'Default' THEN 12
              WHEN 'Company Rate' THEN 13
              ELSE 13
            END
          )                                       [Commission Type (corr_)]
     ,MAX(AP.CommissionRateProz_corr)          [Commission Rate % (corr_)]
     ,MAX(AP.ReservationDate)                  [Reservation Date]
     ,MAX(AP.ArivalDate)                       [Arrival Date]
     ,MAX(AP.DepartureDate)                    [Departure Date]
     ,MAX(AP.AffiliatePartnerNo)               [Affiliate Partner No_]
     ,MAX(AP.HotelNo)                          [Hotel No_]
     ,MAX(CASE WHEN ISNUMERIC(COALESCE(AP.CountryCode,''))=0 THEN '' ELSE AP.CountryCode END) [Country Code] -- 09.12.19 HRS003 TMA für die Fälle, dass in der Kommissionsrechnung kein numerischer Schlüssel für das Land eingetragen wurde 
     ,MAX(COALESCE(AP.Chain,''))               [Chain]
     ,MAX(COALESCE(AP.Brand,''))               [Brand]
     ,MAX(COALESCE(AP.MuseID,''))              [MuseID]
     ,MAX(COALESCE(AP.TopBonusID,''))          [Top Bonus ID]
     ,MAX(COALESCE(AP.AffiliateReference1,'')) [Loyality Rewards Account 1 No_]
     ,MAX(COALESCE(AP.AffiliateReference2,'')) [Loyality Rewards Account 2 No_]
     ,MAX(COALESCE(AP.ReservationSource,0))    [Reservation Source]
     ,MAX(COALESCE(AP.Orderer,''))             [Booking User]
     ,MAX(COALESCE(AP.BookingCode,''))         [Booking Code]
     ,SUM(AP.Turnover_Breakfast_LCY)           [Turnover Breakfast (LCY)]
     ,SUM(AP.Turnover_Breakfast_LCY_corr)      [Turnover Breakfast (LCY) (corr_)]
     ,MAX(AP.CurrencyFaktor)                   [Currency Factor]
     ,MAX(AP.CurrencyFaktor_corr)              [Currency Factor (corr_)]
     ,MAX(AP.CurrencyCode)                     [Currency Code]
     ,MAX(AP.CurrencyCode_corr)                [Currency Code (corr_)]
	 ,MAX(AP.[Max Entry No_]) [Max Entry No_]
	 ,MAX(AP.Handbooking) Handbooking
	 ,MAX(AP.PostAffiliatePartnerNo) [Post Affiliate Partner No_]
	 ,SUM(AP.Turnover_Breakfast_LCY_corr) [Turnover Breakfast (LCY) (c_)]
	 ,MAX(AP.CurrencyFaktor) [Currency Faktor]
	 ,MAX(AP.CurrencyFaktor_corr) [Currency Faktor (corr_)]
    FROM _AP AP
GROUP BY AP.ReservationNo
     ,AP.ReservationPartNo    
)
, RL AS
(
   SELECT RL.[Reservation No_]
        , RL.[Reservation Part No_]
		, SUM(RL.[Amount (LCY)]) [Amount (LCY)]
		, SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
	    , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
	    , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
	    , COUNT(1) PartCount
     FROM [HRS$Rebate Line] RL WITH (NOLOCK)
    WHERE RL.[Document No_] = @DocumentNo
      AND RL.[Type]=5
 GROUP BY RL.[Reservation No_]
        , RL.[Reservation Part No_]
)
   INSERT INTO #RL ([Document No_],[Line No_],[Type],[Rebate Amount Line],[No Print],[No_],[Rebate Agreement No_],[Posting Date (Import)],[Document Date (Import)],[Description],[Description 2],[Reservation No_],[Reservation Part No_],[Value Type],[Value],[Value Text],[Value Decimal],[Value Boolean],[Value Date],[Invoice No_],[Amount (LCY)],[Turnover (LCY)],[Commission Type],[Commission Rate %],[Amount (LCY) (corr_)],[Turnover (LCY) (corr_)],[Commission Type (corr_)],[Commission Rate % (corr_)],[Departure Date],[Affiliate Partner No_],[Hotel No_],[Room Nights],[Is Net Rate],[Room Nights Post Corection],[Is Net Rate Post Corection],[Max Entry No_],[Is No Show],[Top Bonus ID],[MuseID],[Correction Kennung],[Company Name],[Customer No_],[Country Code],[Chain],[Brand],[Rebate-to Vendor No_],[Handbooking],[Booking User],[Group contract Code],[Net Turnover (LCY)],[Net Turnover (LCY) (corr_)],[Arival Date],[Reservation Date],[Post Affiliate Partner No_],[Loyality Rewards Account 1 No_],[Loyality Rewards Account 2 No_],[Reservation Source],[Turnover Breakfast (LCY)],[Turnover Breakfast (LCY) (c_)],[Amount],[Turnover],[Net Turnover],[Currency Faktor],[Currency Code],[Amount (corr_)],[Turnover (corr_)],[Net Turnover (corr_)],[Currency Faktor (corr_)],[Currency Code (corr_)],[Process Number],[Travelagency No_],[Eligible RevShare],[Booking Code],[Threshold Value Index],[Originating Country Code],[Source Class],[Record Type])
   SELECT @DocumentNo
        , @MaxLineNo + (ROW_NUMBER() OVER(ORDER BY AP.[Reservation No_],AP.[Reservation Part No_])) 
		, 5 -- [Type]
		, 0 -- [Rebate Amount Line]
		, 0 -- [No Print]
		, '' -- [No_]
		, @RebateAgreementNo -- [Rebate Agreement No_]
		, AP.[Posting Date] -- [Posting Date (Import)]
        , AP.[Document Date] -- [Document Date (Import)]
        , AP.[Description]
        , AP.[Description 2]
        , AP.[Reservation No_]
        , AP.[Reservation Part No_]
        , 0 [Value Type]
        , '' -- [Value]
        , '' -- [Value Text]
        , 0.0 -- [Value Decimal]
        , 0 -- [Value Boolean]
        , '1753-01-01' -- [Value Date]
        , AP.[Invoice No_]
        , AP.[Amount (LCY)]
        , AP.[Turnover (LCY)]
        , AP.[Commission Type]
        , AP.[Commission Rate %]
        , AP.[Amount (LCY) (corr_)]
        , AP.[Turnover (LCY) (corr_)]
        , AP.[Commission Type (corr_)]
        , AP.[Commission Rate % (corr_)]
        , AP.[Departure Date]
        , AP.[Affiliate Partner No_]
        , AP.[Hotel No_]
        , AP.[Room Nights]
        , AP.[Is Net Rate]
        , AP.[Room Nights]
        , AP.[Room Nights (corr_)]
        , AP.[Max Entry No_]
		, AP.[Is No Show]
        , AP.[Top Bonus ID]
        , AP.[MuseID]
        , 0 [Correction Kennung]
        , AP.[Company Name]
        , AP.[Affiliate Partner No_]
        , AP.[Country Code]
        , AP.[Chain]
        , AP.[Brand]
        , @VendorNo [Rebate-to Vendor No_]
        , AP.[Handbooking]
        , AP.[Booking User]
        , '' [Group contract Code]
        , 0.0 [Net Turnover (LCY)]
        , 0.0 [Net Turnover (LCY) (corr_)]
        , AP.[Arrival Date]
        , AP.[Reservation Date]
        , AP.[Post Affiliate Partner No_]
        , AP.[Loyality Rewards Account 1 No_]
        , AP.[Loyality Rewards Account 2 No_]
        , AP.[Reservation Source]
        , AP.[Turnover Breakfast (LCY)]
        , AP.[Turnover Breakfast (LCY) (c_)]
        , AP.[Amount]
        , AP.[Turnover]
        , 0.0 [Net Turnover]
        , AP.[Currency Faktor]
        , AP.[Currency Code]
        , AP.[Amount (corr_)]
        , AP.[Turnover (corr_)]
        , 0.0 [Net Turnover (corr_)]
        , AP.[Currency Faktor (corr_)]
        , AP.[Currency Code (corr_)]
        , AP.[Process Number]
        , AP.[Travelagency No_]
        , 0 [Eligible RevShare]
        , AP.[Booking Code]
        , 0 [Threshold Value Index]
        , COALESCE(APA.[Country Code],'') [Originating Country Code]
        , BS.[Source Class] [Source Class]
		, CASE WHEN RL.[Reservation No_] IS NULL THEN 1 ELSE 2 END [Record Type]
     FROM AP
LEFT JOIN [Affiliate Partner] APA WITH (NOLOCK)
       ON APA.[No_] = AP.[Affiliate Partner No_]
LEFT JOIN #BS BS WITH (NOLOCK)
       ON BS.[Reservation Source] = AP.[Reservation Source]
LEFT JOIN RL 
       ON RL.[Reservation No_] = AP.[Reservation No_]
      AND RL.[Reservation Part No_] = AP.[Reservation Part No_]
    WHERE RL.[Reservation No_] IS NULL
	   OR COALESCE(RL.[Amount (LCY)],0)<>AP.[Amount (LCY)]
	   OR COALESCE(RL.[Amount (LCY) (corr_)],0)<>AP.[Amount (LCY) (corr_)]
	   OR COALESCE(RL.[Turnover (LCY)],0)<>AP.[Turnover (LCY)]
	   OR COALESCE(RL.[Turnover (LCY) (corr_)],0)<>AP.[Turnover (LCY) (corr_)]

INSERT INTO [HRS$Rebate Line] ([Document No_],[Line No_],[Type],[Rebate Amount Line],[No Print],[No_],[Rebate Agreement No_],[Posting Date (Import)],[Document Date (Import)],[Description],[Description 2],[Reservation No_],[Reservation Part No_],[Value Type],[Value],[Value Text],[Value Decimal],[Value Boolean],[Value Date],[Invoice No_],[Amount (LCY)],[Turnover (LCY)],[Commission Type],[Commission Rate %],[Amount (LCY) (corr_)],[Turnover (LCY) (corr_)],[Commission Type (corr_)],[Commission Rate % (corr_)],[Departure Date],[Affiliate Partner No_],[Hotel No_],[Room Nights],[Is Net Rate],[Room Nights Post Corection],[Is Net Rate Post Corection],[Max Entry No_],[Is No Show],[Top Bonus ID],[MuseID],[Correction Kennung],[Company Name],[Customer No_],[Country Code],[Chain],[Brand],[Rebate-to Vendor No_],[Handbooking],[Booking User],[Group contract Code],[Net Turnover (LCY)],[Net Turnover (LCY) (corr_)],[Arival Date],[Reservation Date],[Post Affiliate Partner No_],[Loyality Rewards Account 1 No_],[Loyality Rewards Account 2 No_],[Reservation Source],[Turnover Breakfast (LCY)],[Turnover Breakfast (LCY) (c_)],[Amount],[Turnover],[Net Turnover],[Currency Faktor],[Currency Code],[Amount (corr_)],[Turnover (corr_)],[Net Turnover (corr_)],[Currency Faktor (corr_)],[Currency Code (corr_)],[Process Number],[Travelagency No_],[Eligible RevShare],[Booking Code],[Threshold Value Index],[Originating Country Code],[Source Class])
SELECT [Document No_],[Line No_],[Type],[Rebate Amount Line],[No Print],[No_],[Rebate Agreement No_],[Posting Date (Import)],[Document Date (Import)],[Description],[Description 2],[Reservation No_],[Reservation Part No_],[Value Type],[Value],[Value Text],[Value Decimal],[Value Boolean],[Value Date],[Invoice No_],[Amount (LCY)],[Turnover (LCY)],[Commission Type],[Commission Rate %],[Amount (LCY) (corr_)],[Turnover (LCY) (corr_)],[Commission Type (corr_)],[Commission Rate % (corr_)],[Departure Date],[Affiliate Partner No_],[Hotel No_],[Room Nights],[Is Net Rate],[Room Nights Post Corection],[Is Net Rate Post Corection],[Max Entry No_],[Is No Show],[Top Bonus ID],[MuseID],[Correction Kennung],[Company Name],[Customer No_],[Country Code],[Chain],[Brand],[Rebate-to Vendor No_],[Handbooking],[Booking User],[Group contract Code],[Net Turnover (LCY)],[Net Turnover (LCY) (corr_)],[Arival Date],[Reservation Date],[Post Affiliate Partner No_],[Loyality Rewards Account 1 No_],[Loyality Rewards Account 2 No_],[Reservation Source],[Turnover Breakfast (LCY)],[Turnover Breakfast (LCY) (c_)],[Amount],[Turnover],[Net Turnover],[Currency Faktor],[Currency Code],[Amount (corr_)],[Turnover (corr_)],[Net Turnover (corr_)],[Currency Faktor (corr_)],[Currency Code (corr_)],[Process Number],[Travelagency No_],[Eligible RevShare],[Booking Code],[Threshold Value Index],[Originating Country Code],[Source Class]
  FROM #RL RL
 WHERE RL.[Record Type] = 1

UPDATE RL SET 
       RL.[Amount (LCY)] = #RL.[Amount (LCY)]
     , RL.[Amount (LCY) (corr_)] = #RL.[Amount (LCY) (corr_)]
	 , RL.[Turnover (LCY)] = #RL.[Turnover (LCY) (corr_)]
	 , RL.[Turnover (LCY) (corr_)] = #RL.[Turnover (LCY) (corr_)]
     , RL.[Amount] = #RL.[Amount]
     , RL.[Amount (corr_)] = #RL.[Amount (corr_)]
	 , RL.[Turnover] = #RL.[Turnover]
	 , RL.[Turnover (corr_)] = #RL.[Turnover (corr_)]
  FROM [HRS$Rebate Line] RL
  JOIN #RL 
    ON #RL.[Reservation No_] = RL.[Reservation No_]
   AND #RL.[Reservation Part No_] = RL.[Reservation Part No_]
   AND #RL.[Document No_] = RL.[Document No_]
 WHERE #RL.[Record Type] = 2

END
-- ---------------------------------------- --
-- Works only if a document allready exists --
-- ---------------------------------------- --
END
GO
