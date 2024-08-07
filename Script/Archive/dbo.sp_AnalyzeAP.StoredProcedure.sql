USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_AnalyzeAP]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_AnalyzeAP] AS
BEGIN
DECLARE @RecreateZZ int=0

IF @RecreateZZ=1 
  IF OBJECT_ID('tempdb..#ZZ') IS NOT NULL
    DROP TABLE #ZZ

IF OBJECT_ID('tempdb..#ZZ') IS NULL
BEGIN
  CREATE TABLE #ZZ ([Reservierungsnummer] varchar(20) COLLATE Latin1_General_CS_AS primary key, [Cancel] tinyint)
  INSERT INTO #ZZ
  SELECT ZZ.[Reservierungsnummer],MAX(CASE WHEN (COALESCE([Buch_ Description],'') LIKE '%/Cancellation%' OR COALESCE([Action Code],'') = 'CXLD' OR COALESCE([Buch_ Description],'') LIKE '%/NoShow%' OR COALESCE([Action Code],'') = 'NSHW') THEN 1 ELSE 0 END) [Cancel] FROM DynNavHRS.dbo.[HRS$CDG Import Zahlungszentralen] ZZ WITH (NOLOCK) GROUP BY [Reservierungsnummer]
END

;WITH AP AS (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK) WHERE [Vendor No_] = '5591')
, ZZ AS (SELECT ZZ.[Reservierungsnummer],MAX(CASE WHEN (COALESCE([Buch_ Description],'') LIKE '%/Cancellation%' OR COALESCE([Action Code],'') = 'CXLD' OR COALESCE([Buch_ Description],'') LIKE '%/NoShow%' OR COALESCE([Action Code],'') = 'NSHW') THEN 1 ELSE 0 END) [Cancel] FROM DynNavHRS.dbo.[HRS$CDG Import Zahlungszentralen] ZZ WITH (NOLOCK) GROUP BY [Reservierungsnummer])
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
), DL AS
(
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Line Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) [Turnover (LCY)]
        , MAX([Cancel]) [Cancel]
     FROM DynNavHRS.dbo.[HRS$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
LEFT JOIN #ZZ ZZ WITH (NOLOCK) 
       ON ZZ.[Reservierungsnummer] = ADL.[Reservation No_]
    WHERE ADL.[Departure Date] BETWEEN '2020-01-01' AND '2020-01-31'
      AND ADH.[Correction from] = ''
	  AND ADL.[Action]<>3
	  AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND ADH.[Case No_] LIKE 'V%'
 GROUP BY ADL.[Reservation No_]
UNION
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Line Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) [Turnover (LCY)]
        , 0 [Cancel]
     FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
    WHERE ADL.[Departure Date] BETWEEN '2020-01-01' AND '2020-01-31'
      AND ADH.[Correction from] = ''
	  AND ADL.[Action]<>3
	  AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND ADH.[Case No_] LIKE 'V%'
 GROUP BY ADL.[Reservation No_]
UNION
   SELECT ADL.[Reservation No_]
        , SUM(ADL.[Line Amount (LCY)]) [Amount (LCY)]
        , SUM(ADL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(ADL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) [Turnover (LCY)]
        , 0 [Cancel]
     FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] ADL WITH (NOLOCK)
	 JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] ADH WITH (NOLOCK)
       ON ADL.[Display Case No_] = ADH.[Case No_]
	 JOIN AP
	   ON AP.[Affiliate Partner No_] = ADL.[Client No_]
    WHERE ADL.[Departure Date] BETWEEN '2020-01-01' AND '2020-01-31'
      AND ADH.[Correction from] = ''
	  AND ADL.[Action]<>3
	  AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
	  AND ADH.[Case No_] LIKE 'V%'
 GROUP BY ADL.[Reservation No_]
), AF AS
(
   SELECT AF.[ReservationNo] [Reservation No_]
        , SUM(AF.[Amount_LCY]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
		, SUM(AF.[Turnover_LCY]) [Turnover (LCY)]
		, SUM(AF.[Turnover_LCY_corr]) [Turnover (LCY) (corr_)]
		, MAX(CASE WHEN AF.[IsNoShow]=1 OR AF.[IsCanceled]=1 THEN 1 ELSE 0 END) [Cancel]
     FROM DynNavHRS.dbo.[HRS$Affiliate Postings] AF
	 JOIN AP ON AP.[Affiliate Partner No_] = AF.[AffiliatePartnerNo]
    WHERE AF.[DepartureDate] BETWEEN '2020-01-01' AND '2020-01-31'
 GROUP BY AF.[ReservationNo]
UNION
   SELECT AF.[ReservationNo] [Reservation No_]
        , SUM(AF.[Amount_LCY]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
		, SUM(AF.[Turnover_LCY]) [Turnover (LCY)]
		, SUM(AF.[Turnover_LCY_corr]) [Turnover (LCY) (corr_)]
		, MAX(CASE WHEN AF.[IsNoShow]=1 OR AF.[IsCanceled]=1 THEN 1 ELSE 0 END) [Cancel]
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AF
	 JOIN AP ON AP.[Affiliate Partner No_] = AF.[AffiliatePartnerNo]
    WHERE AF.[DepartureDate] BETWEEN '2020-01-01' AND '2020-01-31'
 GROUP BY AF.[ReservationNo]
UNION
   SELECT AF.[ReservationNo] [Reservation No_]
        , SUM(AF.[Amount_LCY]) [Amount (LCY)]
		, SUM(AF.[TAF Amount (LCY)]) [TAF Amount (LCY)]
		, SUM(AF.[Agency Amount (LCY)]) [Agency Amount (LCY)]
		, SUM(AF.[Turnover_LCY]) [Turnover (LCY)]
		, SUM(AF.[Turnover_LCY_corr]) [Turnover (LCY) (corr_)]
		, MAX(CASE WHEN AF.[IsNoShow]=1 OR AF.[IsCanceled]=1 THEN 1 ELSE 0 END) [Cancel]
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AF
	 JOIN AP ON AP.[Affiliate Partner No_] = AF.[AffiliatePartnerNo]
    WHERE AF.[DepartureDate] BETWEEN '2020-01-01' AND '2020-01-31'
 GROUP BY AF.[ReservationNo]
),ST AS
(
  SELECT ST.[Reservation No_]
       , ST.[Position No_]
    , SUM(ST.[Amount (LCY)]) [Amount (LCY)]
    , SUM(ST.[Turnover (LCY)]) [Turnover (LCY)]
    FROM [HRS-CN$Sales Trend New] ST WITH (NOLOCK)
GROUP BY ST.[Reservation No_]
       , ST.[Position No_]
UNION
  SELECT ST.[Reservation No_]
       , ST.[Position No_]
    , SUM(ST.[Amount (LCY)]) [Amount (LCY)]
    , SUM(ST.[Turnover (LCY)]) [Turnover (LCY)]
    FROM [HRS-BR$Sales Trend New] ST WITH (NOLOCK)
GROUP BY ST.[Reservation No_]
       , ST.[Position No_]
), SI AS
(
   SELECT ADL.[Reservation No_]
        , SUM(CASE WHEN [Cancel]=1 OR SC.[Is Canceled]=1 THEN 0 ELSE CASE WHEN ADL.[Position No_]<>1 THEN ADL.[Line Amount (LCY)] ELSE COALESCE(PIC.[Comm_ Amount Paym_ Curr_LCY],ADL.[Line Amount (LCY)]) END END) [Amount (LCY) (corr_)]
        , SUM(CASE WHEN [Cancel]=1 OR SC.[Is Canceled]=1 THEN 0 ELSE ADL.[TAF Line Amount (LCY)] END) [TAF Amount (LCY) (corr_)]
        , SUM(CASE WHEN [Cancel]=1 OR SC.[Is Canceled]=1 THEN 0 ELSE CASE WHEN ADL.[Position No_]<>1 THEN ADL.[Agency Line Amount (LCY)] ELSE COALESCE(PIC.[Comm_ Amount Paym_ Curr_LCY],ADL.[Agency Line Amount (LCY)]) END END) [Agency Amount (LCY) (corr_)]
        , SUM(CASE WHEN [Cancel]=1 OR SC.[Is Canceled]=1 THEN 0 ELSE CASE WHEN ADL.[Position No_]<>1 THEN ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights] ELSE COALESCE(PIC.[Net Turnover Trans_ Curr_LCY],ADL.[Commission Base Amount (LCY)] * ADL.[Number of Nights]) END END) [Turnover (LCY) (corr_)]
        , MAX(CASE WHEN [Cancel]=1 OR SC.[Is Canceled]=1 THEN 1 ELSE 0 END) [Cancel]
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
    WHERE ADL.[Departure Date] BETWEEN '2020-01-01' AND '2020-01-31'
	  AND ADL.[Action]<>3
	  AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
 GROUP BY ADL.[Reservation No_]
UNION
   SELECT ADL.[Reservation No_]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] END) [Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ADL.[TAF Line Amount (LCY)] END) [TAF Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] - ADL.[TAF Line Amount (LCY)] END) [Agency Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Turnover (LCY)] END) [Turnover (LCY) (corr_)]
        , MAX(SC.[Is Canceled]) [Cancel]
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
    WHERE ADL.[Departure Date] BETWEEN '2020-01-01' AND '2020-01-31'
	  AND ADL.[Action]<>3
	  AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
 GROUP BY ADL.[Reservation No_]
UNION
   SELECT ADL.[Reservation No_]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] END) [Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ADL.[TAF Line Amount (LCY)] END) [TAF Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Amount (LCY)] - ADL.[TAF Line Amount (LCY)] END) [Agency Amount (LCY) (corr_)]
        , SUM(CASE WHEN SC.[Is Canceled]=1 OR ST.[Turnover (LCY)]=0 THEN 0 ELSE ST.[Turnover (LCY)] END) [Turnover (LCY) (corr_)]
        , MAX(SC.[Is Canceled]) [Cancel]
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
    WHERE ADL.[Departure Date] BETWEEN '2020-01-01' AND '2020-01-31'
	  AND ADL.[Action]<>3
	  AND ADL.[Reservation Source] IN (0,2,4,5,8,13,81,173,320,354,383,535,536,540,544,565,618,663,665,799,894,927,952)
 GROUP BY ADL.[Reservation No_]
)
   SELECT DL.[Reservation No_]
        , SI.[Turnover (LCY) (corr_)] - AF.[Turnover (LCY) (corr_)] [Diff]
        , DL.[Agency Amount (LCY)]         [Agency Amount (LCY) pre correction]
		, DL.[TAF Amount (LCY)]            [TAF Amount (LCY) pre correction]
		, DL.[Amount (LCY)]                [Amount (LCY) pre correction]
		, DL.[Turnover (LCY)]              [Turnover (LCY) pre correction]
		, SI.[Agency Amount (LCY) (corr_)] [Agency Amount (LCY) post correction]
		, SI.[TAF Amount (LCY) (corr_)]    [TAF Amount (LCY) (corr_)]
		, SI.[Amount (LCY) (corr_)]        [Amount (LCY) (corr_)]
		, SI.[Turnover (LCY) (corr_)]      [Turnover (LCY) post correction]
		, AF.[Turnover (LCY)]              [Affiliate Postings - Turnover (LCY) pre correction]
		, AF.[Turnover (LCY) (corr_)]      [Affiliate Postings - Turnover (LCY) post correction]
		, DL.Cancel
     FROM DL
     JOIN AF ON AF.[Reservation No_]=DL.[Reservation No_]
	 JOIN SI ON SI.[Reservation No_]=DL.[Reservation No_]
    --WHERE ABS(SI.[Turnover (LCY) (corr_)] - AF.[Turnover (LCY) (corr_)])>1
END
GO
