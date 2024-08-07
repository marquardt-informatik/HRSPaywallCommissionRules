USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_SABRE_InsertRebateImport]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 14.11.13
-- Description:	Übertragung der AMADEUS Bonuszeilen ohne Webservice
-- 03.08.2018 HRS001 TMA  ACS-896 Bei Zuordnung auch die Vertragslaufzeit berücksichtigen
/*
TRUNCATE TABLE [HRS$Rebate Import]
EXEC [dbo].[sp_SABRE_InsertRebateImport]
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_SABRE_InsertRebateImport]
  @VendorNo varchar(20) = ''
AS
BEGIN

DECLARE @StartDate date = '2023-01-01'
      , @Year int
	  , @Month int
	  
    SET @Year = YEAR(@StartDate)  

-- #AF ++++++++++
IF OBJECT_ID('tempdb..#AF') IS NOT NULL
    DROP TABLE #AF

  CREATE TABLE #AF ([No_] int PRIMARY KEY)
  INSERT 
    INTO #AF ([No_])
  SELECT AF.[No_]
    FROM DynNavHRS.dbo.[Affiliate Partner] AF WITH (NOLOCK)
   WHERE NOT AF.[No_] IN (SELECT [Affiliate Partner No_] FROM [hotel_de$Affiliate Partner Vendor] WITH (NOLOCK))
ORDER BY 1
-- #AF ----------

-- #TA ++++++++++
IF OBJECT_ID('tempdb..#TA') IS NOT NULL
    DROP TABLE #TA

  CREATE TABLE #TA ([Travelagency No_] int PRIMARY KEY, [IATA] VARCHAR(20) COLLATE Latin1_General_CS_AS)
  INSERT 
    INTO #TA ([IATA],[Travelagency No_])
  SELECT TA.[IATA], MAX(TA.No_) [Travelagency No_]
    FROM DynNavHRS.dbo.[Travelagency]                   TA WITH (NOLOCK)
   WHERE ISNUMERIC([IATA])>0
GROUP BY TA.[IATA]
ORDER BY 2
-- #TA ----------

-- #VATTable ++++++++++
IF OBJECT_ID('tempdb..#VATTable') IS NOT NULL
    DROP TABLE #VATTable
  CREATE TABLE #VATTable ([Country] INT PRIMARY KEY, [VATFactor] decimal(37,8))
  INSERT 
    INTO #VATTable ([Country],[VATFactor])
  SELECT Country, 100./(100+[VAT in %]) VATFactor 
    FROM [HRS$Foreign Tax]
-- #VATTable ----------

-- #AI ++++++++++
IF OBJECT_ID('tempdb..#AI') IS NOT NULL
    DROP TABLE #AI

  CREATE TABLE #AI ([Process No_] int PRIMARY KEY, [Travelagency No_] int, [IATA] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Source] varchar(10) COLLATE Latin1_General_CS_AS)
  INSERT 
    INTO #AI ([Process No_], [Travelagency No_], [IATA], [Source])
   SELECT BU.BP_KEY [Process No_], MAX(AI.[Travelagency No_]), MAX(AI.[IATA Code]), 'AMADEUS' [Source]
     FROM DynNavHRS.dbo.[HRS$Amadeus Import Line]        AI WITH (NOLOCK)
     JOIN DynNavHRS.HRSDB.BUCHUNG                        BU WITH (NOLOCK)
       ON BU.BP_KEY = AI.[Process No_]
    WHERE NOT BU.BP_KEY IS NULL
	  AND AI.[Departure Date] >= @StartDate
 GROUP BY BU.BP_KEY
 ORDER BY 1

  INSERT 
    INTO #AI ([Process No_], [Travelagency No_], [IATA], [Source])
    SELECT SI.[Process No_], MAX(COALESCE(TA.[Travelagency No_],0)), MAX(SI.[IATA]) [IATA Code], 'SABRE' [Source]
     FROM DynNavHRS.dbo.[SABRE Import Line] SI WITH (NOLOCK)
     JOIN #TA TA ON TA.[IATA] = SI.[IATA]
LEFT JOIN #AI AI
       ON AI.[Process No_] = SI.[Process No_]
    WHERE AI.[Process No_] IS NULL
	  AND SI.[Load Year] >= @Year
 GROUP BY SI.[Process No_]
-- #AI ----------

-- #RL ++++++++++
IF OBJECT_ID('tempdb..#RL') IS NOT NULL
     DROP TABLE #RL
   CREATE TABLE #RL ([Reservation No_] int, [Reservation Part No_] int, [CountRL] int,CONSTRAINT [TMP_RL] PRIMARY KEY CLUSTERED ([Reservation No_] ASC, [Reservation Part No_] ASC))
   INSERT
     INTO #RL ([Reservation No_] , [Reservation Part No_], [CountRL]) SELECT RL.[Reservation No_], RL.[Reservation Part No_], COUNT(1)
	 FROM [HRS$Rebate Line] RL WITH (NOLOCK) WHERE RL.[Departure Date] >= @StartDate GROUP BY RL.[Reservation No_], RL.[Reservation Part No_]
   INSERT
     INTO #RL ([Reservation No_] , [Reservation Part No_], [CountRL]) SELECT RL.[Reservation No_], RL.[Reservation Part No_], COUNT(1)
	 FROM [HRS$Posted Rebate Line] RL WITH (NOLOCK) LEFT JOIN #RL ON #RL.[Reservation No_] = RL.[Reservation No_] AND #RL.[Reservation Part No_] = RL.[Reservation Part No_] WHERE #RL.[Reservation No_] IS NULL AND RL.[Departure Date] >= @StartDate AND RL.[Cancels]=0 GROUP BY RL.[Reservation No_] , RL.[Reservation Part No_]
  -- INSERT
  --   INTO #RL ([Reservation No_] , [Reservation Part No_], [CountRL]) SELECT RL.[Reservation No_], RL.[Reservation Part No_], COUNT(1)
	 --FROM [hotel_de$Rebate Line] RL WITH (NOLOCK) LEFT JOIN #RL ON #RL.[Reservation No_] = RL.[Reservation No_] AND #RL.[Reservation Part No_] = RL.[Reservation Part No_] WHERE #RL.[Reservation No_] IS NULL AND RL.[Departure Date] >= @StartDate GROUP BY RL.[Reservation No_] , RL.[Reservation Part No_]
  -- INSERT
  --   INTO #RL ([Reservation No_] , [Reservation Part No_], [CountRL]) SELECT RL.[Reservation No_], RL.[Reservation Part No_], COUNT(1)
	 --FROM [hotel_de$Posted Rebate Line] RL WITH (NOLOCK) LEFT JOIN #RL ON #RL.[Reservation No_] = RL.[Reservation No_] AND #RL.[Reservation Part No_] = RL.[Reservation Part No_] WHERE #RL.[Reservation No_] IS NULL AND RL.[Departure Date] >= @StartDate AND RL.[Cancels]=0 GROUP BY RL.[Reservation No_] , RL.[Reservation Part No_]
-- #RL ----------


;WITH VT AS
(
  SELECT VT.[Travelagency No_] 
  -- 03.08.2018 HRS001 TMA >>>>>>>>>>
       , CASE WHEN RAH.[Valid to]='1753-01-01' THEN '2999-12-31' ELSE RAH.[Valid to] END [Valid to]
  -- 03.08.2018 HRS001 TMA <<<<<<<<<<
    FROM [HRS$Vendor Travelagency] VT WITH (NOLOCK) 
	JOIN [HRS$Rebate Agreement Header] RAH WITH (NOLOCK)
	  ON RAH.[Rebate-to Vendor No_] = VT.[Vendor No_]
	 AND RAH.[Active] = 1
   WHERE NOT (VT.[Vendor No_] IN ('2628' /*AMEX*/, '9357' /* SABRE*/))
), AP_TA AS
(
   SELECT AP.*, TA.[Travelagency Code] TA_CODE, TA.[No_] TA_NO
     FROM DynNavHRS.dbo.[HRS$Affiliate Postings]         AP WITH (NOLOCK)
     JOIN #AF AF
       ON AF.[No_] = AP.[AffiliatePartnerNo]
     JOIN DynNavHRS.dbo.[Travelagency]                   TA WITH (NOLOCK)
       ON TA.[No_] = AP.[Travelagency No_]
LEFT JOIN VT 
       ON VT.[Travelagency No_] = AP.[Travelagency No_]
  -- 03.08.2018 HRS001 TMA >>>>>>>>>>
      AND VT.[Valid to] > AP.[DepartureDate]
  -- 03.08.2018 HRS001 TMA <<<<<<<<<<
LEFT JOIN #RL RL
       ON RL.[Reservation No_]         = AP.ReservationNo
      AND RL.[Reservation Part No_]    = AP.ReservationPartNo
    WHERE 1=1 
      AND RL.[Reservation No_] IS NULL
	  AND VT.[Travelagency No_] IS NULL
	  AND AP.[DepartureDate] >= @StartDate
	  AND AP.[ReservationSource] IN (663)
UNION
   SELECT AP.*, TA.[Travelagency Code] TA_CODE, TA.[No_] TA_NO
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings]         AP WITH (NOLOCK)
     JOIN #AF AF
       ON AF.[No_] = AP.[AffiliatePartnerNo]
     JOIN DynNavHRS.dbo.[Travelagency]                   TA WITH (NOLOCK)
       ON TA.[No_] = AP.[Travelagency No_]
LEFT JOIN VT 
       ON VT.[Travelagency No_] = AP.[Travelagency No_]
  -- 03.08.2018 HRS001 TMA >>>>>>>>>>
      AND VT.[Valid to] > AP.[DepartureDate]
  -- 03.08.2018 HRS001 TMA <<<<<<<<<<
LEFT JOIN #RL RL
       ON RL.[Reservation No_]         = AP.ReservationNo
      AND RL.[Reservation Part No_]    = AP.ReservationPartNo
    WHERE 1=1 
      AND RL.[Reservation No_] IS NULL
	  AND VT.[Travelagency No_] IS NULL
	  AND AP.[DepartureDate] >= @StartDate
	  AND AP.[ReservationSource] IN (663)
UNION
   SELECT AP.*, TA.[Travelagency Code] TA_CODE, TA.[No_] TA_NO
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings]         AP WITH (NOLOCK)
     JOIN #AF AF
       ON AF.[No_] = AP.[AffiliatePartnerNo]
     JOIN DynNavHRS.dbo.[Travelagency]                   TA WITH (NOLOCK)
       ON TA.[No_] = AP.[Travelagency No_]
LEFT JOIN VT 
       ON VT.[Travelagency No_] = AP.[Travelagency No_]
  -- 03.08.2018 HRS001 TMA >>>>>>>>>>
      AND VT.[Valid to] > AP.[DepartureDate]
  -- 03.08.2018 HRS001 TMA <<<<<<<<<<
LEFT JOIN #RL RL
       ON RL.[Reservation No_]         = AP.ReservationNo
      AND RL.[Reservation Part No_]    = AP.ReservationPartNo
    WHERE 1=1
      AND RL.[Reservation No_] IS NULL
	  AND VT.[Travelagency No_] IS NULL
	  AND AP.[DepartureDate] >= @StartDate
	  AND AP.[ReservationSource] IN (663)
UNION
   SELECT AP.*, TA.[Travelagency Code] TA_CODE, TA.[No_] TA_NO
     FROM DynNavHRS.dbo.[TISCOVER$Affiliate Postings]         AP WITH (NOLOCK)
     JOIN #AF AF
       ON AF.[No_] = AP.[AffiliatePartnerNo]
     JOIN DynNavHRS.dbo.[Travelagency]                   TA WITH (NOLOCK)
       ON TA.[No_] = AP.[Travelagency No_]
LEFT JOIN VT 
       ON VT.[Travelagency No_] = AP.[Travelagency No_]
  -- 03.08.2018 HRS001 TMA >>>>>>>>>>
      AND VT.[Valid to] > AP.[DepartureDate]
  -- 03.08.2018 HRS001 TMA <<<<<<<<<<
LEFT JOIN #RL RL
       ON RL.[Reservation No_]         = AP.ReservationNo
      AND RL.[Reservation Part No_]    = AP.ReservationPartNo
    WHERE 1=1 
      AND RL.[Reservation No_] IS NULL
	  AND VT.[Travelagency No_] IS NULL
	  AND AP.[DepartureDate] >= @StartDate
	  AND AP.[ReservationSource] IN (663)
)
INSERT INTO [HRS$Rebate Import]([Posting Date],[Document Date],[Description],[Description 2],[Reservation No_],[Reservation Part No_],[Invoice No_],[Amount (LCY)],[Turnover (LCY)],[Net Turnover (LCY)],[Commission Type],[Commission Rate %],[Amount (LCY) (corr_)],[Turnover (LCY) (corr_)],[Net Turnover (LCY) (corr_)],[Commission Type (corr_)],[Commission Rate % (corr_)],[Departure Date],[Affiliate Partner No_],[Post Affiliate Partner No_],[Hotel No_],[Company Name],[Customer No_],[Country Code],[Chain],[Brand],[Rebate-to Vendor No_],[Rebate Agreement No_],[Interval],[Interval Start Date],[Interval End Date],[DatenOK],[Error Text],[Room Nights],[Is Net Rate],[Room Nights Post Corection],[Is Net Rate Post Corection],[Max Entry No_],[Is No Show],[Top Bonus ID],[MuseID],[Correction Kennung],[Date Interval Coordination],[K-Amount (LCY)],[K-Turnover (LCY)],[K-Amount (LCY) (corr_)],[K-Turnover (LCY) (corr_)],[K-Room Nights],[K-Room Nights Post Corection],[Handbooking],[Reservation Source],[Booking User],[Booking Code],[Loyality Rewards Account 1 No_],[Loyality Rewards Account 2 No_],[Process Number],[Arival Date],[Reservation Date],[Turnover Breakfast (LCY)],[Turnover Breakfast (LCY) (c_)],[Amount],[Turnover],[Net Turnover],[Currency Faktor],[Currency Code],[Amount (corr_)],[Turnover (corr_)],[Net Turnover (corr_)],[Currency Code (corr_)],[Currency Faktor (corr_)],[K-Net Turnover (LCY)], [K-Net Turnover (LCY) (corr_)], [K-Net Turnover], [K-Net Turnover (corr_)], [Travelagency No_], [Eligible RevShare])
    SELECT  
 [PostingDate]                                             [Posting Date]
,[DocumentDate]                                            [Document Date]
,[Description]                                             [Description]
,COALESCE([Description2],'')                               [Description 2]
,[ReservationNo]                                           [Reservation No_]
,[ReservationPartNo]                                       [Reservation Part No_]
,[InvoiceNo]                                               [Invoice No_]
,AP.[Amount_LCY]-AP.[TAF Amount (LCY)]                                              [Amount (LCY)]
,[Turnover_LCY]                                            [Turnover (LCY)]
,[Turnover_LCY] * COALESCE(VT.VATFactor,1)                 [Net Turnover (LCY)]
,CASE [CommissionType]
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
            END                                            [Commission Type]
,[CommissionRateProz]                                      [Commission Rate %]
,AP.[Amount_LCY_corr]-AP.[TAF Amount (LCY) (corr_)]                                         [Amount (LCY) (corr_)]
,[Turnover_LCY_corr]                                       [Turnover (LCY) (corr_)]
,[Turnover_LCY_corr] * COALESCE(VT.VATFactor,1)            [Net Turnover (LCY) (corr_)]
,CASE [CommissionType_corr]                                
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
            END                                            [Commission Type (corr_)]
,[CommissionRateProz_corr]                                 [Commission Rate % (corr_)]
,[DepartureDate]                                           [Departure Date]
,[AffiliatePartnerNo]                                      [Affiliate Partner No_]
,[PostAffiliatePartnerNo]                                  [Post Affiliate Partner No_]
,[HotelNo]                                                 [Hotel No_]
,[NAVCompanyName]                                          [Company Name]
,[CustomerNo]                                              [Customer No_]
,[CountryCode]                                             [Country Code]
,COALESCE([Chain],'')                                      [Chain]
,COALESCE([Brand],'')                                      [Brand]
,'9357'                                                    [Rebate-to Vendor No_]
,'V0000007706'                                             [Rebate Agreement No_]
,0 [Interval]
,DATEADD(month,DATEDIFF(month,0,[DepartureDate]),0) [Interval Start Date]
,DATEADD(month,DATEDIFF(month,-1,[DepartureDate]),-1) [Interval End Date]
,1                                                         [DatenOK]
,''                                                        [Error Text]
,[RoomNights]                                              [Room Nights]
,[IsNetRate]                                               [Is Net Rate]
,[RoomNights_corr]                                         [Room Nights Post Corection]
,[IsNetRate_corr]                                          [Is Net Rate Post Corection]
,[Max Entry No_]                                           [Max Entry No_]
,[IsNoShow]                                                [Is No Show]
,[TopBonusID]                                              [Top Bonus ID]
,[MuseID]                                                  [MuseID]
,0                                                         [Correction Kennung]
,'1753-01-01'                                              [Date Interval Coordination]
,0.0                                                       [K-Amount (LCY)]
,0.0                                                       [K-Turnover (LCY)]
,0.0                                                       [K-Amount (LCY) (corr_)]
,0.0                                                       [K-Turnover (LCY) (corr_)]
,0.0                                                       [K-Room Nights]
,0.0                                                       [K-Room Nights Post Corection]
,[Handbooking]                                             [Handbooking]
,[ReservationSource]                                       [Reservation Source]
,[BookingUser]                                             [Booking User]
,[BookingCode]                                             [Booking Code]
,AP.AffiliateReference1                                    [Loyality Rewards Account 1 No_]
,COALESCE(AP.AffiliateReference2,'')                       [Loyality Rewards Account 2 No_]
,AP.ProcessNumber                                          [Process Number]
,AP.[ArivalDate]                                           [Arival Date]
,AP.[ReservationDate]                                      [Reservation Date]
,AP.[Turnover_Breakfast_LCY_corr]                          [Turnover Breakfast (LCY)]
,AP.[Turnover_Breakfast_LCY_corr]                          [Turnover Breakfast (LCY) (c_)]
,AP.[Amount]                                               [Amount]
,AP.[Turnover]                                             [Turnover]
,AP.[Turnover] * COALESCE(VT.VATFactor,1)                  [Net Turnover]
,AP.[CurrencyFaktor]                                       [Currency Faktor]
,AP.[CurrencyCode]                                         [Currency Code]
,AP.[Amount_corr]                                          [Amount (corr_)]
,AP.[Turnover_corr]                                        [Turnover (corr_)]
,AP.[Turnover_corr] * COALESCE(VT.VATFactor,1)             [Net Turnover (corr_)]
,AP.[CurrencyCode_corr]                                    [Currency Code (corr_)]
,AP.[CurrencyFaktor_corr]                                  [Currency Faktor (corr_)]
, 0.0                                                      [K-Net Turnover (LCY)]
, 0.0                                                      [K-Net Turnover (LCY) (corr_)]
, 0.0                                                      [K-Net Turnover]
, 0.0                                                      [K-Net Turnover (corr_)]
, AP.TA_NO                                                 [Travelagency No_]
, 1                                                        [Eligible RevShare]
       FROM AP_TA AP 
  LEFT JOIN #VATTable VT
         ON VT.Country = AP.CountryCode 
   --   WHERE NOT AP.[AffiliatePartnerNo] IN 
	  --      (
	  --        SELECT APV.[Affiliate Partner No_] 
			--    FROM [hotel_de$Affiliate Partner Vendor] APV WITH (NOLOCK)
			--	JOIN [hotel_de$Rebate Agreement Header] RAH WITH (NOLOCK)
			--	  ON RAH.[Rebate-to Vendor No_] = APV.[Vendor No_]
   --            WHERE RAH.[Active] = 1
			--)
END

GO
