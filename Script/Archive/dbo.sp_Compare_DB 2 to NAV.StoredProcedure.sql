USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Compare_DB/2 to NAV]    Script Date: 10.04.2024 14:31:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_Compare_DB/2 to NAV] (
--DECLARE
    @DateFrom date = '2022-01-01'
  , @DateTo   date = '2022-06-30'
  , @ReservationNo varchar(20) = null--'266133140'
  , @Debug    int  = 0
)
AS BEGIN

DECLARE @RecreateZZ int=1

IF @RecreateZZ=1 
  IF OBJECT_ID('tempdb..#ZZ') IS NOT NULL
    DROP TABLE #ZZ

IF OBJECT_ID('tempdb..#ZZ') IS NULL
BEGIN
  CREATE TABLE #ZZ ([Reservierungsnummer] varchar(20) COLLATE Latin1_General_CS_AS primary key, [Cancel] tinyint, [Arrival Date] date, [Departure Date] date )
  INSERT INTO #ZZ
  SELECT ZZ.[Reservierungsnummer]
       , MAX(CASE WHEN (COALESCE([Buch_ Description],'') LIKE '%/Cancellation%' OR COALESCE([Action Code],'') = 'CXLD' OR COALESCE([Buch_ Description],'') LIKE '%/NoShow%' OR COALESCE([Action Code],'') = 'NSHW') THEN 1 ELSE 0 END) [Cancel]
       , MIN(CASE WHEN ISDATE(LEFT(ZZ.ArrivalDate,4)+'-'+SUBSTRING(ZZ.ArrivalDate,5,2)+'-'+SUBSTRING(ZZ.ArrivalDate,7,2))=0 THEN '1753-01-01' ELSE CAST(LEFT(ZZ.ArrivalDate,4)+'-'+SUBSTRING(ZZ.ArrivalDate,5,2)+'-'+SUBSTRING(ZZ.ArrivalDate,7,2) AS date) END) [Arrival Date]
       , MAX(CASE WHEN ISDATE(LEFT(ZZ.DepartureDate,4)+'-'+SUBSTRING(ZZ.DepartureDate,5,2)+'-'+SUBSTRING(ZZ.DepartureDate,7,2))=0 THEN '1753-01-01' ELSE CAST(LEFT(ZZ.DepartureDate,4)+'-'+SUBSTRING(ZZ.DepartureDate,5,2)+'-'+SUBSTRING(ZZ.DepartureDate,7,2) AS date) END) [Departure Date] 
    FROM DynNavHRS.dbo.[HRS$CDG Import Zahlungszentralen] ZZ WITH (NOLOCK)
   WHERE ZZ.DepartureDate<>''
     AND ([Reservierungsnummer]=@ReservationNo OR @ReservationNo IS NULL)
GROUP BY [Reservierungsnummer]       
END

DECLARE @RecreateResult int=1

IF @RecreateResult=1 
  IF OBJECT_ID('tempdb..#CP') IS NOT NULL
    DROP TABLE #CP

IF OBJECT_ID('tempdb..#CP') IS NULL
BEGIN
  CREATE TABLE #CP (
      [Reservation No_] varchar(20) COLLATE Latin1_General_CS_AS primary key
    , [DB/2 Net Turnover (LCY)] dec(38,2)
    , [DB/2 Gross Turnover (LCY)] dec(38,2)
    , [NAV pre c. Agency Amount (LCY)] dec(38,2)
    , [NAV pre c. TAF Amount (LCY)] dec(38,2)
    , [NAV pre c. Amount (LCY)] dec(38,2)
    , [NAV pre c. Turnover (LCY)] dec(38,2)
    , [NAV pre c. Gross Turnover (LCY)] dec(38,2)
    , [NAV post c. Agency Amount (LCY)] dec(38,2)
    , [NAV post c. TAF Amount (LCY)] dec(38,2)
    , [NAV post c. Amount (LCY)] dec(38,2)
    , [NAV post c. Turnover (LCY)] dec(38,2)
    , [NAV post c. Gross Turnover (LCY)] dec(38,2)
    , [Cancel] int
    , [DB/2 Arrival Date] date
    , [DB/2 Departure Date] date
    , [DB/2 Nights] dec(38,2)
    , [NAV pre c. Arrival Date] date
    , [NAV pre c. Departure Date] date
    , [NAV pre c. Nights] dec(38,2)
    , [NAV post c. Arrival Date] date
    , [NAV post c. Departure Date] date
    , [NAV post c. Nights] dec(38,2)
    , [DB/2 Exchange Rate] dec(38,5)
    , [NAV pre c. Exchange Rate] dec(38,5)
    , [NAV post c. Exchange Rate] dec(38,5)
    , [DB/2 Net Turnover (FCY)] dec(38,2)
    , [DB/2 Gross Turnover (FCY)] dec(38,2)
    , [NAV pre c. Gross Turnover (FCY)] dec(38,2)
    , [NAV post c. Gross Turnover (FCY)] dec(38,2)
	, [Muse ID] varchar(20)
	, [NAV pre c. Breakfast exclusive] tinyint
	, [NAV post c. Breakfast exclusive] tinyint
	, [NAV commissionable] tinyint
	, [Reservation Source] int
  )
;WITH AP AS (SELECT DISTINCT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK) WHERE [Vendor No_] = '5591')
, PIL AS
(
SELECT PIL.[Reservation No_]
     , PIL.[Net Turnover Trans_ Curr_] 
	 , PIL.[Comm_ Amount Paym_ Curr_]
	 , PIH.[Payment Exchange Rate]
	 , PIL.[Import Line No_]
  FROM [HRS$Partner Import Line] PIL WITH (NOLOCK)
  JOIN [HRS$Partner Import Header] PIH WITH (NOLOCK)
    ON PIH.[Entry No_] = PIL.[Import Entry No_]
 WHERE PIH.[MuseID] = 'EAN'
   AND PIH.[Payment Exchange Rate] <> 0		-- 05.02.2020 SAL - Filter added
   AND PIH.[Entry No_]<>45				   
   AND PIL.[Departure Date] >= '2018-01-01'
   AND ISNUMERIC(PIL.[Reservation No_])>0
), _PIL AS (SELECT [Reservation No_], MAX([Import Line No_]) [Import Line No_], SUM([Comm_ Amount Paym_ Curr_]) [Comm_ Amount Paym_ Curr_] FROM PIL GROUP BY [Reservation No_])
, PIC AS
(
SELECT _PIL.*, PIL.[Net Turnover Trans_ Curr_], PIL.[Payment Exchange Rate]
     , PIL.[Comm_ Amount Paym_ Curr_] / PIL.[Payment Exchange Rate] [Comm_ Amount Paym_ Curr_LCY]
     , PIL.[Net Turnover Trans_ Curr_] / PIL.[Payment Exchange Rate] [Net Turnover Trans_ Curr_LCY]
  FROM PIL
  JOIN _PIL ON _PIL.[Reservation No_] = PIL.[Reservation No_] AND _PIL.[Import Line No_] = PIL.[Import Line No_]
), _DL AS
(
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Line Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) [Turnover (LCY)]
		, SUM(
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END		   
		) / MAX(ADL.[Currency Faktor]) [Gross Turnover (LCY)]
		, SUM(
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		  ) [Gross Turnover (FCY)]
        , MAX(COALESCE(ZZ.[Cancel],0)) [Cancel]
		, CAST(MIN(ADL.[Reservation Date from]) AS date) [Arrival Date]
		, CAST(MAX(ADL.[Reservation Date to]) AS date) [Departure Date]
        , DATEDIFF(dd,MIN(ADL.[Reservation Date from]),MAX(ADL.[Reservation Date to])) [Nights]
		, MAX(ADL.[Currency Faktor]) [Exchange Rate]
		, MAX(ADL.[Breakfast Type]) [Breakfast exclusive]
		, MAX(ADL.[Reservation Source]) [Reservation Source]
     FROM DynNavHRS.dbo.[HRS$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
LEFT JOIN #ZZ ZZ WITH (NOLOCK) 
       ON ZZ.[Reservierungsnummer] = ADL.[Reservation No_]
    WHERE ADL.[Departure Date] BETWEEN @DateFrom AND @DateTo
      AND ADH.[Correction from] = ''
	  AND ADL.[Action]<>3
	  --AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  --AND ADH.[Case No_] LIKE 'V%'
	  AND (ADL.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
      AND ADH.[Document Type] IN ('10','11','12','9')
 GROUP BY ADL.[Reservation No_]
UNION ALL
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Line Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) [Turnover (LCY)]
		, SUM(
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END		   
		) / MAX(ADL.[Currency Faktor]) [Gross Turnover (LCY)]
		, SUM(
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		  ) [Gross Turnover (FCY)]
        , 0 [Cancel]
		, CAST(MIN(ADL.[Reservation Date from]) AS date) [Arrival Date]
		, CAST(MAX(ADL.[Reservation Date to]) AS date) [Departure Date]
        , DATEDIFF(dd,MIN(ADL.[Reservation Date from]),MAX(ADL.[Reservation Date to])) [Nights]
		, MAX(ADL.[Currency Faktor]) [Exchange Rate]
		, MAX(ADL.[Breakfast Type]) [Breakfast exclusive]
		, MAX(ADL.[Reservation Source]) [Reservation Source]
     FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
    WHERE ADL.[Departure Date] BETWEEN @DateFrom AND @DateTo
      AND ADH.[Correction from] = ''
	  AND ADL.[Action]<>3
	  --AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND ADH.[Case No_] LIKE 'V%'
	  AND (ADL.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
      AND ADH.[Document Type] IN ('10','11','12','9')
 GROUP BY ADL.[Reservation No_]
UNION ALL
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Line Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) [Turnover (LCY)]
		, SUM(
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END		   
		) / MAX(ADL.[Currency Faktor]) [Gross Turnover (LCY)]
		, SUM(
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		  ) [Gross Turnover (FCY)]
        , 0 [Cancel]
		, CAST(MIN(ADL.[Reservation Date from]) AS date) [Arrival Date]
		, CAST(MAX(ADL.[Reservation Date to]) AS date) [Departure Date]
        , DATEDIFF(dd,MIN(ADL.[Reservation Date from]),MAX(ADL.[Reservation Date to])) [Nights]
		, MAX(ADL.[Currency Faktor]) [Exchange Rate]
		, MAX(ADL.[Breakfast Type]) [Breakfast exclusive]
		, MAX(ADL.[Reservation Source]) [Reservation Source]
     FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
    WHERE ADL.[Departure Date] BETWEEN @DateFrom AND @DateTo
      AND ADH.[Correction from] = ''
	  AND ADL.[Action]<>3
	  --AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND ADH.[Case No_] LIKE 'V%'
	  AND (ADL.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
      AND ADH.[Document Type] IN ('10','11','12','9')
 GROUP BY ADL.[Reservation No_]
), DL AS
(
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Amount (LCY)]) [Agency Amount (LCY)]
        , SUM([Turnover (LCY)]) [Turnover (LCY)]
		, SUM([Gross Turnover (LCY)]) [Gross Turnover (LCY)]
		, SUM([Gross Turnover (FCY)]) [Gross Turnover (FCY)]
        , MAX([Cancel]) [Cancel]
		, MIN(ADL.[Arrival Date]) [Arrival Date]
		, MAX(ADL.[Departure Date]) [Departure Date]
        , MAX([Nights]) [Nights]
		, MAX(ADL.[Exchange Rate]) [Exchange Rate]
		, MAX(ADL.[Breakfast exclusive]) [Breakfast exclusive]
		, MAX(ADL.[Reservation Source]) [Reservation Source]
     FROM _DL ADL
 GROUP BY ADL.[Reservation No_]
), _AF AS
(
   SELECT AF.[ReservationNo] [Reservation No_]
        , SUM(AF.[Amount_LCY]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(AF.[Amount_LCY_corr]) [Amount (LCY) (corr_)]
		, SUM(AF.[TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
		, SUM(AF.[Agency Amount (LCY) (corr_)]) [Agency Amount (LCY) (corr_)]
		, SUM(AF.[Turnover_LCY]) [Turnover (LCY)]
		, SUM(AF.[Turnover_LCY_corr]) [Turnover (LCY) (corr_)]
		, MAX(CASE WHEN AF.[IsNoShow]=1 OR AF.[IsCanceled]=1 THEN 1 ELSE 0 END) [Cancel]
     FROM DynNavHRS.dbo.[HRS$Affiliate Postings] AF
	 JOIN AP ON AP.[Affiliate Partner No_] = AF.[AffiliatePartnerNo]
    WHERE AF.[DepartureDate] BETWEEN @DateFrom AND @DateTo
	  AND (CAST(AF.[ReservationNo] AS VARCHAR(20))=@ReservationNo OR @ReservationNo IS NULL)
 GROUP BY AF.[ReservationNo]
UNION
   SELECT AF.[ReservationNo] [Reservation No_]
        , SUM(AF.[Amount_LCY]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(AF.[Amount_LCY_corr]) [Amount (LCY) (corr_)]
		, SUM(AF.[TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
		, SUM(AF.[Agency Amount (LCY) (corr_)]) [Agency Amount (LCY) (corr_)]
		, SUM(AF.[Turnover_LCY]) [Turnover (LCY)]
		, SUM(AF.[Turnover_LCY_corr]) [Turnover (LCY) (corr_)]
		, MAX(CASE WHEN AF.[IsNoShow]=1 OR AF.[IsCanceled]=1 THEN 1 ELSE 0 END) [Cancel]
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AF
	 JOIN AP ON AP.[Affiliate Partner No_] = AF.[AffiliatePartnerNo]
    WHERE AF.[DepartureDate] BETWEEN @DateFrom AND @DateTo
	  AND (CAST(AF.[ReservationNo] AS VARCHAR(20))=@ReservationNo OR @ReservationNo IS NULL)
 GROUP BY AF.[ReservationNo]
UNION
   SELECT AF.[ReservationNo] [Reservation No_]
        , SUM(AF.[Amount_LCY]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(AF.[Amount_LCY_corr]) [Amount (LCY) (corr_)]
		, SUM(AF.[TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
		, SUM(AF.[Agency Amount (LCY) (corr_)]) [Agency Amount (LCY) (corr_)]
		, SUM(AF.[Turnover_LCY]) [Turnover (LCY)]
		, SUM(AF.[Turnover_LCY_corr]) [Turnover (LCY) (corr_)]
		, MAX(CASE WHEN AF.[IsNoShow]=1 OR AF.[IsCanceled]=1 THEN 1 ELSE 0 END) [Cancel]
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AF
	 JOIN AP ON AP.[Affiliate Partner No_] = AF.[AffiliatePartnerNo]
    WHERE AF.[DepartureDate] BETWEEN @DateFrom AND @DateTo
	  AND (CAST(AF.[ReservationNo] AS VARCHAR(20))=@ReservationNo OR @ReservationNo IS NULL)
 GROUP BY AF.[ReservationNo]
), AF AS
(
   SELECT AF.[Reservation No_]
        , SUM(AF.[Amount (LCY)]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(AF.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
		, SUM(AF.[TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
		, SUM(AF.[Agency Amount (LCY) (corr_)]) [Agency Amount (LCY) (corr_)]
		, SUM(AF.[Turnover (LCY)]) [Turnover (LCY)]
		, SUM(AF.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
		, MAX([Cancel]) [Cancel]
     FROM _AF AF
 GROUP BY AF.[Reservation No_]
), ST AS
(
   SELECT ST.[Reservation No_]
        , ST.[Position No_]
        , SUM(ST.[Amount (LCY)]) [Amount (LCY)]
        , SUM(ST.[Turnover (LCY)]) [Turnover (LCY)]
     FROM [HRS-CN$Sales Trend New] ST WITH (NOLOCK)
	WHERE (ST.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
GROUP BY ST.[Reservation No_]
       , ST.[Position No_]
UNION
  SELECT ST.[Reservation No_]
       , ST.[Position No_]
    , SUM(ST.[Amount (LCY)]) [Amount (LCY)]
    , SUM(ST.[Turnover (LCY)]) [Turnover (LCY)]
    FROM [HRS-BR$Sales Trend New] ST WITH (NOLOCK)
	WHERE (ST.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
GROUP BY ST.[Reservation No_]
       , ST.[Position No_]
), _SI AS
(
   SELECT ADL.[Reservation No_]
        , SUM(CASE WHEN COALESCE([Cancel],0)=1 OR SC.[Is Canceled]=1 THEN 0 ELSE CASE WHEN ADL.[Position No_]<>1 THEN ADL.[Line Amount (LCY)] ELSE COALESCE(PIC.[Comm_ Amount Paym_ Curr_LCY],ADL.[Line Amount (LCY)]) END END) [Amount (LCY) (corr_)]
        , SUM(CASE WHEN COALESCE([Cancel],0)=1 OR SC.[Is Canceled]=1 THEN 0 ELSE ADL.[TAF Line Amount (LCY)] END) [TAF Amount (LCY) (corr_)]
        , SUM(CASE WHEN COALESCE([Cancel],0)=1 OR SC.[Is Canceled]=1 THEN 0 ELSE CASE WHEN ADL.[Position No_]<>1 THEN ADL.[Agency Line Amount (LCY)] ELSE COALESCE(PIC.[Comm_ Amount Paym_ Curr_LCY],ADL.[Agency Line Amount (LCY)]) END END) [Agency Amount (LCY) (corr_)]
        , SUM(CASE WHEN COALESCE([Cancel],0)=1 OR SC.[Is Canceled]=1 THEN 0 ELSE CASE WHEN ADL.[Position No_]<>1 THEN ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights] ELSE COALESCE(PIC.[Net Turnover Trans_ Curr_LCY],ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) END END) [Turnover (LCY) (corr_)]
		, SUM(CASE WHEN SC.[Is Canceled]=1 THEN 0 ELSE 
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END		   
		END) / MAX(ADL.[Currency Faktor]) [Gross Turnover (LCY) (corr_)]
		, SUM(CASE WHEN SC.[Is Canceled]=1 THEN 0 ELSE 
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		  END) [Gross Turnover (FCY) (corr_)]
        , MAX(CASE WHEN COALESCE([Cancel],0)=1 OR SC.[Is Canceled]=1 THEN 1 ELSE 0 END) [Cancel]
		, CAST(MIN(ADL.[Reservation Date from]) AS date) [Arrival Date]
		, CAST(MAX(ADL.[Reservation Date to]) AS date) [Departure Date]
        , DATEDIFF(dd,MIN(ADL.[Reservation Date from]),MAX(ADL.[Reservation Date to])) [Nights]
		, MAX(ADL.[Currency Faktor]) [Exchange Rate]
		, MAX(ADL.[Breakfast Type]) [Breakfast exclusive]
     FROM DynNavHRS.dbo.[HRS$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN DynNavHRS.dbo.[HRS$Sales Invoice Corrections] SC WITH (NOLOCK)
	   ON ADH.[Posted Invoice No_] = SC.[Max Document No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
LEFT JOIN #ZZ ZZ WITH (NOLOCK) 
       ON ZZ.[Reservierungsnummer] = ADL.[Reservation No_]
LEFT JOIN PIC
       ON PIC.[Reservation No_] = ADL.[Reservation No_]
    WHERE ADL.[Departure Date] BETWEEN @DateFrom AND @DateTo
	  AND ADL.[Action]<>3
	  --AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
 	  AND (ADL.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
      AND ADH.[Document Type] IN ('10','11','12','9')
GROUP BY ADL.[Reservation No_]
UNION
   SELECT ADL.[Reservation No_]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] END) [Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ADL.[TAF Line Amount (LCY)] END) [TAF Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] - ADL.[TAF Line Amount (LCY)] END) [Agency Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Turnover (LCY)] END) [Turnover (LCY) (corr_)]
		, SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE 
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END		   
		END) / MAX(ADL.[Currency Faktor]) [Gross Turnover (LCY) (corr_)]
		, SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE 
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		  END) [Gross Turnover (FCY) (corr_)]
        , MAX(SC.[Is Canceled]) [Cancel]
		, CAST(MIN(ADL.[Reservation Date from]) AS date) [Arrival Date]
		, CAST(MAX(ADL.[Reservation Date to]) AS date) [Departure Date]
        , DATEDIFF(dd,MIN(ADL.[Reservation Date from]),MAX(ADL.[Reservation Date to])) [Nights]
		, MAX(ADL.[Currency Faktor]) [Exchange Rate]
		, MAX(ADL.[Breakfast Type]) [Breakfast exclusive]
     FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN ST
	   ON CAST(ST.[Reservation No_] AS varchar(20)) = ADL.[Reservation No_]
      AND ST.[Position No_] = ADL.[Position No_]
	 JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN DynNavHRS.dbo.[HRS-CN$Sales Invoice Corrections] SC WITH (NOLOCK)
	   ON ADH.[Posted Invoice No_] = SC.[Max Document No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
    WHERE ADL.[Departure Date] BETWEEN @DateFrom AND @DateTo
	  AND ADL.[Action]<>3
	  --AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND (ADL.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
      AND ADH.[Document Type] IN ('10','11','12','9')
 GROUP BY ADL.[Reservation No_]
UNION
   SELECT ADL.[Reservation No_]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] END) [Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ADL.[TAF Line Amount (LCY)] END) [TAF Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] - ADL.[TAF Line Amount (LCY)] END) [Agency Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Turnover (LCY)] END) [Turnover (LCY) (corr_)]
		, SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE 
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END		   
		END) / MAX(ADL.[Currency Faktor]) [Gross Turnover (LCY) (corr_)]
		, SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE 
		  CASE WHEN ADL.[Rate Type]<30000 THEN ADL.[Room Price] * ADL.[Number of Rooms] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		+ CASE WHEN ADL.[Breakfast Type]=1 THEN ADL.[Number of Rooms] * ADL.[Number of Person] * ADL.[Breakfast Price] ELSE 0 END
		* CASE WHEN ADL.[Price Type]=2 AND ADL.[Rate Type] IN (20025,25021,25022,25023,25024) THEN 1 ELSE ADL.[Number of Nights] END
		  END) [Gross Turnover (FCY) (corr_)]
        , MAX(SC.[Is Canceled]) [Cancel]
		, CAST(MIN(ADL.[Reservation Date from]) AS date) [Arrival Date]
		, CAST(MAX(ADL.[Reservation Date to]) AS date) [Departure Date]
        , DATEDIFF(dd,MIN(ADL.[Reservation Date from]),MAX(ADL.[Reservation Date to])) [Nights]
		, MAX(ADL.[Currency Faktor]) [Exchange Rate]
		, MAX(ADL.[Breakfast Type]) [Breakfast exclusive]
     FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN ST
	   ON CAST(ST.[Reservation No_] AS varchar(20)) = ADL.[Reservation No_]
      AND ST.[Position No_] = ADL.[Position No_]
	 JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN DynNavHRS.dbo.[HRS-BR$Sales Invoice Corrections] SC WITH (NOLOCK)
	   ON ADH.[Posted Invoice No_] = SC.[Max Document No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
    WHERE ADL.[Departure Date] BETWEEN @DateFrom AND @DateTo
	  AND ADL.[Action]<>3
	  --AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND (ADL.[Reservation No_]=@ReservationNo OR @ReservationNo IS NULL)
      AND ADH.[Document Type] IN ('10','11','12','9')
 GROUP BY ADL.[Reservation No_]
), SI AS
(
   SELECT ADL.[Reservation No_]
        , SUM([Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
        , SUM([TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
        , SUM([Agency Amount (LCY) (corr_)]) [Agency Amount (LCY) (corr_)]
        , SUM([Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
		, SUM([Gross Turnover (LCY) (corr_)]) [Gross Turnover (LCY) (corr_)]
		, SUM([Gross Turnover (FCY) (corr_)]) [Gross Turnover (FCY) (corr_)]
        , MAX([Cancel]) [Cancel]
		, MIN([Arrival Date]) [Arrival Date]
		, MAX([Departure Date]) [Departure Date]
        , MAX([Nights]) [Nights]
		, MAX([Exchange Rate]) [Exchange Rate]
		, MAX([Breakfast exclusive]) [Breakfast exclusive]
     FROM _SI ADL 
GROUP BY ADL.[Reservation No_]
), BU AS
(
   SELECT BU.B_KEY [Reservation No_]
        , CASE WHEN BU.B_STATUS=10000 THEN 0 ELSE BU.B_TOTAL_RATE * 1.0 * BU.W_KURS / 10000000.0 END [Net Turnover (LCY)]
		, CASE WHEN BU.B_STATUS=10000 THEN 0 ELSE BU.B_TOTAL_RATE_INCLUSIVE * 1.0 * BU.W_KURS / 10000000.0 END [Gross Turnover (LCY)]
        , CASE WHEN BU.B_STATUS=10000 THEN 0 ELSE BU.B_TOTAL_RATE / 100.0 END [Net Turnover (FCY)]
		, CASE WHEN BU.B_STATUS=10000 THEN 0 ELSE BU.B_TOTAL_RATE_INCLUSIVE / 100.0 END [Gross Turnover (FCY)]
		, BU.B_AN_DATUM [Arrival Date]
		, BU.B_AB_DATUM [Departure Date]
		, CASE WHEN BU.B_STATUS=10000 THEN 0 ELSE DATEDIFF(dd,BU.B_AN_DATUM,BU.B_AB_DATUM) END [Nights]
		, 100000.0 / BU.W_KURS [Exchange Rate]
		, COALESCE(BU.MUSE_ID,'HRS') [Muse ID]
     FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
    WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
      --AND BU.B_STATUS<10000
	  AND (CAST(BU.B_KEY AS varchar(20))=@ReservationNo OR @ReservationNo IS NULL)
), Result AS
(
   SELECT DL.[Reservation No_]
		, COALESCE(BU.[Net Turnover (LCY)],0)          [DB/2 Net Turnover (LCY)]
		, COALESCE(BU.[Gross Turnover (LCY)],0)        [DB/2 Gross Turnover (LCY)]

        , DL.[Agency Amount (LCY)]                     [NAV pre correction Agency Amount (LCY)]
		, DL.[TAF Amount (LCY)]                        [NAV pre correction TAF Amount (LCY)]
		, DL.[Amount (LCY)]                            [NAV pre correction Amount (LCY)]
		, DL.[Turnover (LCY)]                          [NAV pre correction Turnover (LCY)]
		, DL.[Gross Turnover (LCY)]                    [NAV pre correction Gross Turnover (LCY)]

		, COALESCE(AF.[Agency Amount (LCY) (corr_)],0) [NAV post correction Agency Amount (LCY)]
		, COALESCE(AF.[TAF Amount (LCY) (corr_)],0)    [NAV post correction TAF Amount (LCY)]
		, CASE WHEN COALESCE(AF.[TAF Amount (LCY) (corr_)],0) = COALESCE(AF.[Amount (LCY) (corr_)],0) THEN 0 ELSE COALESCE(AF.[Amount (LCY) (corr_)],0) END [NAV post correction Amount (LCY)]
		, COALESCE(SI.[Turnover (LCY) (corr_)],0)      [NAV post correction Turnover (LCY)]
		, COALESCE(SI.[Gross Turnover (LCY) (corr_)],0)[NAV post correction Gross Turnover (LCY)]

		--, AF.[Turnover (LCY)]              [Affiliate Postings - Turnover (LCY) pre correction]
		--, AF.[Turnover (LCY) (corr_)]      [Affiliate Postings - Turnover (LCY) post correction]
		, COALESCE(SI.Cancel,1)                        [Cancel]

		, BU.[Arrival Date]                            [DB/2 Arrival Date]
		, BU.[Departure Date]                          [DB/2 Departure Date]
		, COALESCE(BU.[Nights],0)                      [DB/2 Nights]
		, DL.[Arrival Date]                            [NAV pre correction Arrival Date]
		, DL.[Departure Date]                          [NAV pre correction Departure Date]
		, DL.[Nights]                                  [NAV pre correction Nights]
		, SI.[Arrival Date]                            [NAV post correction Arrival Date]
		, SI.[Departure Date]                          [NAV post correction Departure Date]
		, COALESCE(SI.[Nights],0)                      [NAV post correction Nights]

		, BU.[Exchange Rate]                           [DB/2 Exchange Rate]
		, DL.[Exchange Rate]                           [NAV pre correction Exchange Rate]
		, SI.[Exchange Rate]                           [NAV post correction Exchange Rate]

		, COALESCE(BU.[Net Turnover (FCY)],0)          [DB/2 Net Turnover (FCY)]
		, COALESCE(BU.[Gross Turnover (FCY)],0)        [DB/2 Gross Turnover (FCY)]
		, DL.[Gross Turnover (FCY)]                    [NAV pre correction Gross Turnover (FCY)]
		, SI.[Gross Turnover (FCY) (corr_)]            [NAV post correction Gross Turnover (FCY)]
		, COALESCE(BU.[Muse ID],'')                    [Muse ID]
		, DL.[Breakfast exclusive]                     [NAV pre c. Breakfast exclusive]
		, COALESCE(SI.[Breakfast exclusive],DL.[Breakfast exclusive]) [NAV post c. Breakfast exclusive]
		, CASE WHEN COALESCE(AF.[Amount (LCY) (corr_)],0)=COALESCE(AF.[TAF Amount (LCY) (corr_)],0) AND COALESCE(SI.[Turnover (LCY) (corr_)],0)<>0 THEN 0 ELSE 1 END [NAV commissionable]
		, DL.[Reservation Source]
     FROM DL
     JOIN AF ON AF.[Reservation No_]=DL.[Reservation No_]
	 LEFT JOIN SI ON SI.[Reservation No_]=DL.[Reservation No_]
	 LEFT JOIN BU ON BU.[Reservation No_]=DL.[Reservation No_]
    --WHERE ABS(SI.[Turnover (LCY) (corr_)] - AF.[Turnover (LCY) (corr_)])>1
)
INSERT INTO #CP
SELECT * 
  FROM Result
END

IF NOT @ReservationNo IS NULL
  SELECT * FROM #CP

;WITH R1 AS
(
SELECT [Reservation No_]
     , [DB/2 Gross Turnover (LCY)]
	 , [NAV pre c. Turnover (LCY)]
	 , [NAV post c. Turnover (LCY)]
     , CASE 
         WHEN ABS([DB/2 Gross Turnover (LCY)]-[NAV post c. Turnover (LCY)]) <=0.01 THEN 'equal' 
		 ELSE '' 
       END 
	 + CASE 
         WHEN ABS([DB/2 Gross Turnover (LCY)] - [NAV post c. Turnover (LCY)] - ([DB/2 Gross Turnover (FCY)] / [DB/2 Exchange Rate] - [DB/2 Gross Turnover (FCY)] / [NAV post c. Exchange Rate]))>0.01 AND ([NAV post c. Turnover (LCY)]<>0) AND ([Muse ID]<>'EAN') AND ([DB/2 Gross Turnover (LCY)]>0) AND ([NAV post c. Gross Turnover (LCY)]<>[NAV post c. Turnover (LCY)]) AND ([DB/2 Gross Turnover (LCY)]<>[DB/2 Net Turnover (LCY)]) THEN ','+'net Based' 
		 ELSE ''
       END
	 + CASE 
         WHEN ABS([DB/2 Gross Turnover (FCY)] / [DB/2 Exchange Rate] - [DB/2 Gross Turnover (FCY)] / [NAV post c. Exchange Rate]) >0.01 AND ([Muse ID]<>'EAN') AND ([NAV post c. Turnover (LCY)]<>0)THEN ','+'currency' 
		 ELSE ''
       END
     + CASE
		 WHEN [NAV post c. Turnover (LCY)]=0 THEN ','+'cacellation'
		 ELSE ''
       END
     + CASE
		 WHEN [DB/2 Gross Turnover (LCY)]=0 THEN ','+'uncancelled'
		 ELSE ''
       END
     + CASE
		 WHEN ([Muse ID]='EAN') AND ([NAV post c. Turnover (LCY)]<>0) THEN ','+'external source'
		 ELSE ''
       END
     + CASE
		 WHEN ([NAV post c. Nights]<[DB/2 Nights]) THEN ','+'shorter stay'
		 --WHEN CASE WHEN ABS([DB/2 Gross Turnover (LCY)] - [NAV post c. Turnover (LCY)]) < ABS([DB/2 Gross Turnover (LCY)] * CASE WHEN [DB/2 Nights]=0 THEN 0 ELSE ([NAV post c. Nights]-[DB/2 Nights]) / [DB/2 Nights] END) THEN 0 ELSE ([DB/2 Gross Turnover (LCY)] * CASE WHEN [DB/2 Nights]=0 THEN 0 ELSE ([NAV post c. Nights]-[DB/2 Nights]) / [DB/2 Nights] END) END<>0 AND ([NAV post c. Turnover (LCY)]<>0)THEN ','+'shorter stay'
		 ELSE ''
       END
	   [Compare]
	 , [NAV post c. Turnover (LCY)] - [DB/2 Gross Turnover (LCY)] [Total Deviation]
     , CASE WHEN ([Muse ID]<>'EAN') AND ([NAV post c. Turnover (LCY)]<>0) THEN CASE WHEN ABS(([NAV post c. Turnover (LCY)] - [DB/2 Gross Turnover (LCY)])-ROUND([DB/2 Gross Turnover (FCY)] / [NAV post c. Exchange Rate] - [DB/2 Gross Turnover (FCY)] / [DB/2 Exchange Rate],2))>0.01 THEN [DB/2 Gross Turnover (FCY)] / [NAV post c. Exchange Rate] - [DB/2 Gross Turnover (FCY)] / [DB/2 Exchange Rate] ELSE [NAV post c. Turnover (LCY)] - [DB/2 Gross Turnover (LCY)] END ELSE 0 END [Currency Deviation]
	 , CASE WHEN ([Muse ID]<>'EAN') THEN CASE WHEN ABS([DB/2 Gross Turnover (LCY)] - [NAV post c. Turnover (LCY)]) < ABS([DB/2 Gross Turnover (LCY)] * CASE WHEN [DB/2 Nights]=0 THEN 0 ELSE ([NAV post c. Nights]-[DB/2 Nights]) / [DB/2 Nights] END) OR ([NAV post c. Turnover (LCY)]=0) THEN 0 ELSE ([DB/2 Gross Turnover (LCY)] * CASE WHEN [DB/2 Nights]=0 THEN 0 ELSE ROUND(([NAV post c. Nights]-[DB/2 Nights]) / [DB/2 Nights],2) END) END ELSE 0 END [Shorter Stay Deviation]
	 , CASE WHEN ([Muse ID]<>'EAN') AND ([DB/2 Gross Turnover (LCY)]>0) AND ([NAV post c. Gross Turnover (LCY)]<>[NAV post c. Turnover (LCY)]) AND ([DB/2 Gross Turnover (LCY)]<>[DB/2 Net Turnover (LCY)]) THEN CASE WHEN (ABS([DB/2 Gross Turnover (LCY)] - [NAV post c. Turnover (LCY)] - ([DB/2 Gross Turnover (FCY)] / [DB/2 Exchange Rate] - [DB/2 Gross Turnover (FCY)] / [NAV post c. Exchange Rate]))<=0.01) OR ([NAV post c. Turnover (LCY)]=0) THEN 0 ELSE [NAV post c. Turnover (LCY)] - [DB/2 Gross Turnover (LCY)] + ([DB/2 Gross Turnover (FCY)] / [DB/2 Exchange Rate] - [DB/2 Gross Turnover (FCY)] / [NAV post c. Exchange Rate]) - CASE WHEN ABS([DB/2 Gross Turnover (LCY)] - [NAV post c. Turnover (LCY)]) < ABS([DB/2 Gross Turnover (LCY)] * CASE WHEN [DB/2 Nights]=0 THEN 0 ELSE ([NAV post c. Nights]-[DB/2 Nights]) / [DB/2 Nights] END) THEN 0 ELSE ([DB/2 Gross Turnover (LCY)] * CASE WHEN [DB/2 Nights]=0 THEN 0 ELSE ([NAV post c. Nights]-[DB/2 Nights]) / [DB/2 Nights] END) END END ELSE 0 END [net Based Deviation]
	 , CASE WHEN [NAV post c. Turnover (LCY)]=0 THEN [NAV post c. Turnover (LCY)] - [DB/2 Gross Turnover (LCY)] ELSE 0 END [Cancellation Deviation]
	 , CASE WHEN ([Muse ID]<>'EAN') OR ([NAV post c. Turnover (LCY)]=0) THEN 0 ELSE [NAV post c. Turnover (LCY)] - [DB/2 Gross Turnover (LCY)] END [External Source Deviation]
	 , CASE WHEN [DB/2 Gross Turnover (LCY)]=0 AND ([Muse ID]<>'EAN') THEN [NAV post c. Turnover (LCY)] ELSE 0 END [Uncancelled Deviation]
	 , CASE WHEN [NAV pre c. Turnover (LCY)]<[NAV post c. Turnover (LCY)] AND [NAV post c. Breakfast exclusive]=1 THEN [NAV post c. Turnover (LCY)]-[NAV pre c. Turnover (LCY)] ELSE 0 END [Breakfast taken Deviation]
	 , [NAV pre c. Breakfast exclusive] 
	 , [NAV post c. Breakfast exclusive] 
	 , [NAV post c. Amount (LCY)]
	 , [NAV commissionable]
	 , CP.[DB/2 Departure Date] [Departure Date]
     , CP.[Reservation Source]
  FROM #CP CP
 --WHERE [NAV post c. Turnover (LCY)]=0
), R2 AS
(
SELECT [Reservation No_]
     , [DB/2 Gross Turnover (LCY)]
	 , [NAV pre c. Turnover (LCY)]
	 , [NAV post c. Turnover (LCY)]
	 , [Compare]
	 , [Total Deviation]
     , [Currency Deviation]
	 , CASE 
	     WHEN ABS([Currency Deviation]+[net Based Deviation]+[Cancellation Deviation]+[External Source Deviation]+[Uncancelled Deviation])<=0.01 THEN [Total Deviation] 
		 WHEN [Currency Deviation]<>0 AND ABS([net Based Deviation]+[Cancellation Deviation]+[External Source Deviation]+[Uncancelled Deviation])<=0.01 THEN [Total Deviation] - [Currency Deviation]
		 ELSE [Shorter Stay Deviation] 
       END [Shorter Stay Deviation]
	 , [net Based Deviation]
	 , [Cancellation Deviation]
	 , [External Source Deviation]
	 , [Uncancelled Deviation]
	 , [Breakfast taken Deviation] 
	 , [NAV post c. Amount (LCY)]
	 , [NAV commissionable]
	 , [Departure Date]
     , [Reservation Source]
  FROM R1
), R3 AS
(
SELECT [Reservation No_]
     , [DB/2 Gross Turnover (LCY)]
	 , [NAV post c. Turnover (LCY)]
	 , [Total Deviation]
     , [Currency Deviation]
	 , [Shorter Stay Deviation]
	 , [net Based Deviation]
	 , [Cancellation Deviation]
	 , [External Source Deviation]
	 , [Uncancelled Deviation]
	 , CASE WHEN [Breakfast taken Deviation]>0 THEN [Total Deviation]-[Currency Deviation]-[Shorter Stay Deviation]-[net Based Deviation]-[Cancellation Deviation]-[External Source Deviation]-[Uncancelled Deviation] ELSE 0 END [Breakfast taken Deviation]
	 , [NAV post c. Amount (LCY)]
	 , [NAV commissionable]
	 , [Departure Date]
     , [Reservation Source]
  FROM R2
), R4 AS
(
SELECT [Reservation No_]
     , CASE
	     WHEN ABS([Currency Deviation])>ABS([Shorter Stay Deviation]) 
          AND ABS([Currency Deviation])>ABS([net Based Deviation])
          AND ABS([Currency Deviation])>ABS([Cancellation Deviation]) 
          AND ABS([Currency Deviation])>ABS([External Source Deviation])
          AND ABS([Currency Deviation])>ABS([Uncancelled Deviation])
          AND ABS([Currency Deviation])>ABS([Breakfast taken Deviation]) THEN 'exchange rate'
         WHEN ABS([Shorter Stay Deviation])>ABS([net Based Deviation])
          AND ABS([Shorter Stay Deviation])>ABS([Cancellation Deviation]) 
          AND ABS([Shorter Stay Deviation])>ABS([External Source Deviation])
          AND ABS([Shorter Stay Deviation])>ABS([Uncancelled Deviation])
          AND ABS([Shorter Stay Deviation])>ABS([Breakfast taken Deviation]) THEN 'shorter stay'
         WHEN ABS([net Based Deviation])>ABS([Cancellation Deviation]) 
          AND ABS([net Based Deviation])>ABS([External Source Deviation])
          AND ABS([net Based Deviation])>ABS([Uncancelled Deviation])
          AND ABS([net Based Deviation])>ABS([Breakfast taken Deviation]) THEN 'HTO net based'
         WHEN ABS([Cancellation Deviation])>ABS([External Source Deviation])
          AND ABS([Cancellation Deviation])>ABS([Uncancelled Deviation])
          AND ABS([Cancellation Deviation])>ABS([Breakfast taken Deviation]) THEN 'cancellation'
         WHEN ABS([External Source Deviation])>ABS([Uncancelled Deviation])
          AND ABS([External Source Deviation])>ABS([Breakfast taken Deviation]) THEN 'external source'
         WHEN ABS([Uncancelled Deviation])>ABS([Breakfast taken Deviation]) THEN 'external source'
         WHEN ABS([Breakfast taken Deviation])>0 THEN 'external source'
		 ELSE 'no difference'
       END [Main Deviation Reason]   
     , [DB/2 Gross Turnover (LCY)]
	 , [NAV post c. Turnover (LCY)]
	 , [Total Deviation]
     , [Currency Deviation]
	 , [Shorter Stay Deviation]
	 , [net Based Deviation]
	 , [Cancellation Deviation]
	 , [External Source Deviation]
	 , [Uncancelled Deviation]
	 , [Breakfast taken Deviation]
	 , [NAV post c. Amount (LCY)]
	 , CASE WHEN ([NAV post c. Amount (LCY)]=0 AND [NAV post c. Turnover (LCY)] >0) OR [NAV post c. Turnover (LCY)]=0 THEN 0 ELSE 1 END [NAV commissionable]
	 , [Departure Date]
     , [Reservation Source]
  FROM R3
)
SELECT * FROM R4 ORDER BY [Reservation No_]
END
GO
