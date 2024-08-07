USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Affiliate_ADAC]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 16.12.14
-- Description:	ADAC Bonuspunkte-Export
/*
EXEC [dbo].[sp_Affiliate_ADAC] '2016-12-01', '2016-12-31'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_Affiliate_ADAC] 
    @DateFrom date = '2014-11-01'
  , @DateTo date = '2014-11-30'
AS
BEGIN
SET NOCOUNT ON 
DECLARE @Result TABLE
(
    [ProcessNumber]        bigint
  , [AffiliatePartnerNo]   bigint
  , [Company-Name]         varchar(100)
  , [ArivalDate]           date
  , [DepartureDate]        date
  , [ReservationNo]        bigint
  , [ReservationDate]      date
  , [Guest1]               varchar(100)
  , [Guest2]               varchar(100)
  , [MuseID]               varchar(100)
  , [successfull]          bit
  , [Commission (corr.)]   decimal(37,20)
  , [Turnover (corr.)]     decimal(37,20)
  , [HotelName]            varchar(200)
  , [City]                 varchar(2000)
  , [HotelNo]              int
  , [ADAC Mitgliedsnummer] varchar(2000)
  , [Nachname]             varchar(2000)
  , [Vorname]              varchar(2000)
  , [Adresszusatz]         varchar(2000)
  , [Straße]               varchar(2000)
  , [Hausnummer]           varchar(2000)
  , [PLZ]                  varchar(2000)
  , [Ort]                  varchar(2000)
  , [Land]                 varchar(2000)
  , [Anrede]               varchar(2000)
  , [Status]               int
  , [ReservationSource]     int
  , [ReservationSourceName] varchar(200)
  , [Email]                varchar(2000)
)      
--ORT	ADAC MITGLIEDNUMMER	Anrede	Nachname	Vorname	Adresszusatz 	Straße	Hausnummer	PLZ	Ort	Land
;WITH BKG AS
(
  SELECT [B_KEY] [ReservationNo]
       , MAX(CASE WHEN [BP_GROUP_ID] = 1649 THEN [BCDT_VALUE] ELSE '' END) [ADAC Mitgliedsnummer]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7027 THEN [BCDT_VALUE] ELSE '' END) [Nachname]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7028 THEN [BCDT_VALUE] ELSE '' END) [Vorname]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7029 THEN [BCDT_VALUE] ELSE '' END) [Adresszusatz]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7030 THEN [BCDT_VALUE] ELSE '' END) [Straße]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7031 THEN [BCDT_VALUE] ELSE '' END) [Hausnummer]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7032 THEN [BCDT_VALUE] ELSE '' END) [PLZ]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7033 THEN [BCDT_VALUE] ELSE '' END) [Ort]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7034 THEN [BCDT_VALUE] ELSE '' END) [Land]
       , MAX(CASE WHEN [BP_GROUP_ID] = 7107 THEN [BCDT_VALUE] ELSE '' END) [Anrede]
	   , MAX(CASE WHEN [BP_GROUP_ID] = 10304 THEN [BCDT_VALUE] ELSE '' END) [Email]
    FROM [HRSDB].[BKG_CI_DATA_TEXT_DA] WITH (NOLOCK)
GROUP BY [B_KEY]  
), AP AS
(
  SELECT AP.[ProcessNumber]
       , AP.[AffiliatePartnerNo]
       , AP.[ArivalDate]
       , AP.[DepartureDate]
       , AP.[ReservationNo]
       , AP.[ReservationPartNo]
       , AP.[ReservationDate]
       , AP.[Description]
       , AP.[Description2]
       , AP.[MuseID]
       , AP.[Amount_corr]
       , AP.[Amount_LCY_corr]
       , AP.[Turnover_LCY_corr]
       , AP.[HotelNo]
       , AP.[ReservationSource]
       , BS.[Name] [ReservationSourceName]
    FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
    JOIN [HRS$Booking Source] BS WITH (NOLOCK)
      ON BS.[No_] = AP.[ReservationSource]
   WHERE AP.[AffiliatePartnerNo] IN (424316685,424316682,424316684)
     AND AP.[ReservationDate] BETWEEN '2014-12-01' AND @DateTo
     AND AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION   
  SELECT AP.[ProcessNumber]
       , AP.[AffiliatePartnerNo]
       , AP.[ArivalDate]
       , AP.[DepartureDate]
       , AP.[ReservationNo]
       , AP.[ReservationPartNo]
       , AP.[ReservationDate]
       , AP.[Description]
       , AP.[Description2]
       , AP.[MuseID]
       , AP.[Amount_corr]
       , AP.[Amount_LCY_corr]
       , AP.[Turnover_LCY_corr]
       , AP.[HotelNo]
       , AP.[ReservationSource]
       , BS.[Name] [ReservationSourceName]
    FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
    JOIN [HRS$Booking Source] BS WITH (NOLOCK)
      ON BS.[No_] = AP.[ReservationSource]
   WHERE AP.[AffiliatePartnerNo] IN (424316685,424316682,424316684)
     AND AP.[ReservationDate] BETWEEN '2014-12-01' AND @DateTo
     AND AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION   
  SELECT AP.[ProcessNumber]
       , AP.[AffiliatePartnerNo]
       , AP.[ArivalDate]
       , AP.[DepartureDate]
       , AP.[ReservationNo]
       , AP.[ReservationPartNo]
       , AP.[ReservationDate]
       , AP.[Description]
       , AP.[Description2]
       , AP.[MuseID]
       , AP.[Amount_corr]
       , AP.[Amount_LCY_corr]
       , AP.[Turnover_LCY_corr]
       , AP.[HotelNo]
       , AP.[ReservationSource]
       , BS.[Name] [ReservationSourceName]
    FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
    JOIN [HRS$Booking Source] BS WITH (NOLOCK)
      ON BS.[No_] = AP.[ReservationSource]
   WHERE AP.[AffiliatePartnerNo] IN (424316685,424316682,424316684)
     AND AP.[ReservationDate] BETWEEN '2014-12-01' AND @DateTo
     AND AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
UNION   
  SELECT AP.[ProcessNumber]
       , AP.[AffiliatePartnerNo]
       , AP.[ArivalDate]
       , AP.[DepartureDate]
       , AP.[ReservationNo]
       , AP.[ReservationPartNo]
       , AP.[ReservationDate]
       , AP.[Description]
       , AP.[Description2]
       , AP.[MuseID]
       , AP.[Amount_corr]
       , AP.[Amount_LCY_corr]
       , AP.[Turnover_LCY_corr]
       , AP.[HotelNo]
       , AP.[ReservationSource]
       , BS.[Name] [ReservationSourceName]
    FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
    JOIN [HRS$Booking Source] BS WITH (NOLOCK)
      ON BS.[No_] = AP.[ReservationSource]
   WHERE AP.[AffiliatePartnerNo] IN (424316685,424316682,424316684)
     AND AP.[ReservationDate] BETWEEN '2014-12-01' AND @DateTo
     AND AP.[DepartureDate] BETWEEN @DateFrom AND @DateTo
)
  INSERT INTO @Result
  SELECT AP.[ProcessNumber]
       , AP.[AffiliatePartnerNo]
       , CU.[Company-Name]
       , MIN(AP.[ArivalDate]) [ArivalDate]
       , MAX(AP.[DepartureDate]) [DepartureDate]
       , AP.[ReservationNo]
       , AP.[ReservationDate]
       , REPLACE(AP.[Description],'','') [Description]  --VORSICHT SONDERZEICHEN IN ''
       , REPLACE(AP.[Description2],'','') [Description2] --VORSICHT SONDERZEICHEN IN ''
       , AP.[MuseID]
       , CASE WHEN SUM(AP.[Amount_LCY_corr]) > 0 THEN 1 ELSE 0 END [successfull]
       , SUM(AP.[Amount_LCY_corr])
       , SUM(AP.[Turnover_LCY_corr])
       , CO.[Name] + ' ' + CO.[Name 2]
       , CO.[City]
       , CO.[No_]
       , BKG.[ADAC Mitgliedsnummer]
       , REPLACE(BKG.[Nachname],'','') [Nachname] --VORSICHT SONDERZEICHEN IN ''
       , REPLACE(BKG.[Vorname],'','') [Vorname] --VORSICHT SONDERZEICHEN IN ''
       , BKG.[Adresszusatz]
       , BKG.[Straße]
       , BKG.[Hausnummer]
       , BKG.[PLZ]
       , BKG.[Ort]
       , BKG.[Land]
       , BKG.[Anrede]
       , 0
       , AP.[ReservationSource]
       , AP.[ReservationSourceName]
	   , BKG.[Email]
    FROM AP
    JOIN [Affiliate Partner]      CU WITH (NOLOCK)
      ON CU.[No_]               = AP.[AffiliatePartnerNo]
    JOIN [HRS$Contact]            CO WITH (NOLOCK)
      ON CO.[No_]               = AP.[HotelNo]
    JOIN BKG 
      ON BKG.[ReservationNo]    = AP.[ReservationNo]
GROUP BY AP.[ProcessNumber]
       , AP.[AffiliatePartnerNo]
       , CU.[Company-Name]
       , AP.[ReservationNo]
       , AP.[ReservationDate]
       , AP.[Description]
       , AP.[Description2]
       , AP.[MuseID]
       , CO.[Name] + ' ' + CO.[Name 2]
       , CO.[City]
       , CO.[No_]
       , BKG.[ADAC Mitgliedsnummer]
       , BKG.[Nachname]
       , BKG.[Vorname]
       , BKG.[Adresszusatz]
       , BKG.[Straße]
       , BKG.[Hausnummer]
       , BKG.[PLZ]
       , BKG.[Ort]
       , BKG.[Land]
       , BKG.[Anrede]
       , AP.[ReservationSource]
       , AP.[ReservationSourceName]
	   , BKG.[Email]
OPTION (MAXDOP 1)  

-- State = 1 (green) if more than one booking exists for one process no. 
;WITH RN AS
(
  SELECT [ProcessNumber]
       , COUNT(1) [Count]
    FROM @Result
GROUP BY [ProcessNumber]  
  HAVING COUNT(1) > 1
)
UPDATE R SET R.[Status]=1
  FROM @Result R
  JOIN RN ON R.[ProcessNumber] = RN.[ProcessNumber]


-- State = 2 (red) if reservation tempor in one hotel
  UPDATE R2 SET R2.[Status] = 2
    FROM @Result R1
    JOIN @Result R2 
      ON R1.[ADAC Mitgliedsnummer]  = R2.[ADAC Mitgliedsnummer] 
     AND R1.[HotelNo]               = R2.[HotelNo]
     AND DATEDIFF(dd, R1.[DepartureDate], R2.[ArivalDate]) = 0
     
  UPDATE R1 SET R1.[Status] = 2
    FROM @Result R1
    JOIN @Result R2 
      ON R1.[ADAC Mitgliedsnummer]  = R2.[ADAC Mitgliedsnummer] 
     AND R1.[HotelNo]               = R2.[HotelNo]
     AND DATEDIFF(dd, R1.[DepartureDate], R2.[ArivalDate]) = 0

-- State = 3 (yellow) if successfull=false 
UPDATE @Result SET [Status] = 3 WHERE [successfull] = 0

-- State = 4 (lila) if reservation tempor in one hotel
  UPDATE R2 SET R2.[Status] = 4
    FROM @Result R1
    JOIN @Result R2 
      ON R1.[ADAC Mitgliedsnummer]  = R2.[ADAC Mitgliedsnummer] 
     AND R1.[HotelNo]               = R2.[HotelNo]
     AND DATEDIFF(dd, R1.[DepartureDate], R2.[DepartureDate]) = 0
     AND R1.[ReservationNo]        <> R2.[ReservationNo]

SELECT * FROM @Result ORDER BY [ADAC Mitgliedsnummer], [HotelName], [ArivalDate]
END
GO
