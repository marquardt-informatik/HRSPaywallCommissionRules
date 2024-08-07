USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_CheckCommissionValues]    Script Date: 10.04.2024 14:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_CheckCommissionValues]
(
  @DocumentDate date = NULL
, @Product int = 0
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @DocumentType varchar(100) = ',10,11,12,'

IF @Product=1 
BEGIN
  SET @DocumentType = ',37,'
END

DECLARE @DC TABLE ([Company] varchar(30),[Year] int, [Invoices] int, PRIMARY KEY  ([Company],[Year]))
DECLARE @Result TABLE ([Entry No_] int, [Group] int, [Sum] int, [GroupSum] int, [Area] varchar(50), [Company] varchar(30), [Year] int, [Invoices] int DEFAULT 0, [Amount (LCY)] decimal(37,20) DEFAULT 0, [% Avg. Commission Rate] decimal(37,20) DEFAULT 0, [Turnover (LCY)] decimal(37,20) DEFAULT 0, [Bookings] int DEFAULT 0, [RN] int, [Trend Amount (LCY)] decimal(37,20) DEFAULT 0, [Trend Bookings] decimal(37,20), [Trend RN] decimal(37,20), [TAF Amount (LCY)] decimal(37,20), [Agency Amount (LCY)] decimal(37,20), PRIMARY KEY ([Entry No_])) 
DECLARE @Companies TABLE ([Company] varchar(30),[Year] int,[Month] int, [Category] varchar(20), [Invoices] int DEFAULT 0, [Amount (LCY)] decimal(37,20) DEFAULT 0, [% Avg. Commission Rate] decimal(37,20) DEFAULT 0, [Bookings] int DEFAULT 0, [RN] int DEFAULT 0, [TAF Amount (LCY)] decimal(37,20) DEFAULT 0, [Agency Amount (LCY)] decimal(37,20) DEFAULT 0 , PRIMARY KEY ([Company],[Year],[Category])) 

IF NOT @DocumentDate = '2017-04-04' 
BEGIN

IF DATEPART(dd,GETDATE())<5 BEGIN SELECT @DocumentDate = COALESCE(@DocumentDate,CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE()),120),10) AS DATETIME)) END
IF DATEPART(dd,GETDATE())>=5 BEGIN SELECT @DocumentDate = COALESCE(@DocumentDate,CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1-DATEPART(dd,GETDATE()),GETDATE()))),120),10) AS DATETIME)) END

DECLARE @StartDate date = DATEADD(mm,-1,DATEADD(dd,1,@DocumentDate))

DECLARE @PreviousDate date
SET @PreviousDate = DATEADD(dd,-1,DATEADD(yy,-1,DATEADD(dd,1,@DocumentDate)))

INSERT INTO @DC SELECT 'HRS'    , YEAR(@DocumentDate), COUNT(1) FROM DynNavHRS.dbo.[HRS$Agency Display Header]     AH WITH (NOLOCK) WHERE AH.[Creation Date] = @DocumentDate AND AH.[Correction from] = '' AND AH.[Status]=0 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'HRS-BR' , YEAR(@DocumentDate), COUNT(1) FROM DynNavHRS.dbo.[HRS-BR$Agency Display Header]  AH WITH (NOLOCK) WHERE AH.[Creation Date] = @DocumentDate AND AH.[Correction from] = '' AND AH.[Status]=0 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'HRS-CN' , YEAR(@DocumentDate), COUNT(1) FROM DynNavHRS.dbo.[HRS-CN$Agency Display Header]  AH WITH (NOLOCK) WHERE AH.[Creation Date] = @DocumentDate AND AH.[Correction from] = '' AND AH.[Status]=0 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'Partner', YEAR(@DocumentDate), COALESCE(COUNT(1),0) FROM DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) WHERE AH.[Creation Date] = @DocumentDate AND AH.[Correction from] = '' AND AH.[Status]=0 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'HRS'    , YEAR(@PreviousDate), COUNT(1) FROM DynNavHRS.dbo.[HRS$Agency Display Header]     AH WITH (NOLOCK) WHERE AH.[Creation Date] = @PreviousDate AND AH.[Correction from] = '' AND AH.[Status]=1 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'HRS-BR' , YEAR(@PreviousDate), COUNT(1) FROM DynNavHRS.dbo.[HRS-BR$Agency Display Header]  AH WITH (NOLOCK) WHERE AH.[Creation Date] = @PreviousDate AND AH.[Correction from] = '' AND AH.[Status]=1 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'HRS-CN' , YEAR(@PreviousDate), COUNT(1) FROM DynNavHRS.dbo.[HRS-CN$Agency Display Header]  AH WITH (NOLOCK) WHERE AH.[Creation Date] = @PreviousDate AND AH.[Correction from] = '' AND AH.[Status]=1 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
INSERT INTO @DC SELECT 'Partner', YEAR(@PreviousDate), COALESCE(COUNT(1),0) FROM DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) WHERE AH.[Creation Date] = @PreviousDate AND AH.[Correction from] = '' AND AH.[Status]=1 AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'
--SELECT * FROM @DC

CREATE TABLE #BP (BP_KEY int primary key, MA_USER int)
;WITH BP AS 
(
  SELECT BP.BP_KEY
       , MAX(CASE WHEN BP.MA_USER = 'HDE-SBI' THEN 1 ELSE 0 END) MA_USER
	FROM DynNavHRS.HRSDB.BKG_PROCESS_LIST_ALL_DA BP WITH (NOLOCK) 
	JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
	  ON BU.B_KEY = BP.B_KEY 
   WHERE BU.B_AB_DATUM BETWEEN DATEADD(mm,-3,@DocumentDate) AND @DocumentDate
     AND BU.B_QUELLE = 383
GROUP BY BP.BP_KEY
)
INSERT INTO #BP
SELECT BP_KEY, MA_USER FROM BP

CREATE TABLE #BPP (BP_KEY int primary key, MA_USER int)
;WITH BP AS 
(
  SELECT BP.BP_KEY
       , MAX(CASE WHEN BP.MA_USER = 'HDE-SBI' THEN 1 ELSE 0 END) MA_USER
	FROM DynNavHRS.HRSDB.BKG_PROCESS_LIST_ALL_DA BP WITH (NOLOCK) 
	JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
	  ON BU.B_KEY = BP.B_KEY 
   WHERE BU.B_AB_DATUM BETWEEN DATEADD(mm,-3,@PreviousDate) AND @PreviousDate
     AND BU.B_QUELLE = 383
GROUP BY BP.BP_KEY
)
INSERT INTO #BPP
SELECT BP_KEY, MA_USER FROM BP


--- HRS ---
PRINT '1 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS', YEAR(@DocumentDate), MONTH(@DocumentDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '2 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS', YEAR(@PreviousDate), MONTH(@PreviousDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '3 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS', YEAR(@DocumentDate), MONTH(@DocumentDate), 'Tiscover', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] = 222
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '4 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS', YEAR(@PreviousDate), MONTH(@PreviousDate), 'Tiscover', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @PreviousDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] = 222
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '5 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS', YEAR(@DocumentDate), MONTH(@DocumentDate), 'Surprice', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Client No_] = 1042998001
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '6 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS', YEAR(@PreviousDate), MONTH(@PreviousDate), 'Surprice', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @PreviousDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Client No_] = 1042998001
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-CN ---
PRINT '7 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS-CN', YEAR(@DocumentDate), MONTH(@DocumentDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '8 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS-CN', YEAR(@PreviousDate), MONTH(@PreviousDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-BR ---
PRINT '9 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS-BR', YEAR(@DocumentDate), MONTH(@DocumentDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '10 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'HRS-BR', YEAR(@PreviousDate), MONTH(@PreviousDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-BR ---
PRINT '11 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'Partner', YEAR(@DocumentDate), MONTH(@DocumentDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[Partner$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AL.[Departure Date] BETWEEN @StartDate AND @DocumentDate
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '12 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies 
SELECT 'Partner', YEAR(@PreviousDate), MONTH(@PreviousDate), '', 0, SUM(AL.[Line Amount (LCY)]), CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END, SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END), CAST(SUM(AL.[Number of Nights] * AL.[Number of Rooms]) AS int), SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[Partner$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
 WHERE AH.[Creation Date] = @PreviousDate 
   --AND AL.[Departure Date] BETWEEN @StartDate AND @DocumentDate
   AND AH.[Correction from] = '' 
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND AL.[Reservation Source] <> 383
   AND AL.[Reservation Source] <> 222
   AND NOT AL.[Client No_] IN (1042998001,1016845087,1032506001,6013) 
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS (CS) ---
PRINT '13 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS', YEAR(@DocumentDate), MONTH(@DocumentDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '14 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS', YEAR(@PreviousDate), MONTH(@PreviousDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @PreviousDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS (1X) ---
PRINT '15 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS', YEAR(@DocumentDate), MONTH(@DocumentDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '16 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS', YEAR(@PreviousDate), MONTH(@PreviousDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-CN (CS) ---
PRINT '17 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-CN', YEAR(@DocumentDate), MONTH(@DocumentDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '18 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-CN', YEAR(@PreviousDate), MONTH(@PreviousDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @PreviousDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-CN (1X) ---
PRINT '19 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-CN', YEAR(@DocumentDate), MONTH(@DocumentDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '20 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-CN', YEAR(@PreviousDate), MONTH(@PreviousDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-BR (CS) ---
PRINT '21 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-BR', YEAR(@DocumentDate), MONTH(@DocumentDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '22 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-BR', YEAR(@PreviousDate), MONTH(@PreviousDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @PreviousDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS-BR (1X) ---
PRINT '23 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-BR', YEAR(@DocumentDate), MONTH(@DocumentDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '24 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'HRS-BR', YEAR(@PreviousDate), MONTH(@PreviousDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- Partner (CS) ---
PRINT '25 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'Partner', YEAR(@DocumentDate), MONTH(@DocumentDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[Partner$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0 
 WHERE AH.[Creation Date] = @DocumentDate
   AND AL.[Departure Date] BETWEEN @StartDate AND @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '26 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'Partner', YEAR(@PreviousDate), MONTH(@PreviousDate), 'CS', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate], SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings], SUM(AL.[Number of Nights] * AL.[Number of Rooms])[RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[Partner$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=0
 WHERE AH.[Creation Date] = @PreviousDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

--- HRS (1X) ---
PRINT '27 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'Partner', YEAR(@DocumentDate), MONTH(@DocumentDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[Partner$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @DocumentDate 
   AND AL.[Departure Date] BETWEEN @StartDate AND @DocumentDate
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '28 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Companies
SELECT 'Partner', YEAR(@PreviousDate), MONTH(@PreviousDate), '1X', 0, SUM(AL.[Line Amount (LCY)]) [Amount (LCY)], CASE WHEN SUM(AL.[Commission Base Amount (LCY)])=0 THEN 0 ELSE SUM(AL.[Commission Amount (LCY)]) / SUM(AL.[Commission Base Amount (LCY)]) * 100. END [% Avg. Commission Rate] , SUM(CASE WHEN AL.[Position No_] = 1 THEN 1 ELSE 0 END) [Bookings] , SUM(AL.[Number of Nights] * AL.[Number of Rooms]) [RN] , SUM(AL.[TAF Line Amount (LCY)]), SUM(AL.[Line Amount (LCY)]-AL.[TAF Line Amount (LCY)])
  FROM DynNavHRS.dbo.[Partner$Agency Display Line] AL WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.[Partner$Agency Display Header] AH WITH (NOLOCK) ON AH.[Case No_] = AL.[Display Case No_] 
  JOIN #BPP BP ON BP.BP_KEY = AL.[ProcessNumber] AND BP.MA_USER=1 
 WHERE AH.[Creation Date] = @PreviousDate 
   AND AH.[Correction from] = ''
   AND AL.[Action] <> 3
   AND AH.[Case No_] LIKE 'V%'
   AND (AL.[Reservation Source] = 383 OR AL.[Client No_] IN (1016845087,1032506001,6013))
   AND @DocumentType LIKE '%,'+AH.[Document Type]+',%'

PRINT '29 '+CAST(GETDATE() AS varchar(20))
UPDATE CO SET
       CO.[Invoices] = DC.[Invoices]
  FROM @Companies CO
  JOIN @DC DC
    ON DC.[Company] = CO.[Company]
   AND DC.[Year]    = CO.[Year]
 WHERE CO.[Category] = ''

--SELECT * FROM @Companies

PRINT '30 '+CAST(GETDATE() AS varchar(20))
INSERT INTO @Result
SELECT ROW_NUMBER() OVER(ORDER BY CO.[Company], CO.[Year] desc, CO.[Category])
     , 1,0,0
     , CO.[Company] 
	 + CASE WHEN CO.[Year]=YEAR(@DocumentDate) THEN '' ELSE ' '+ CAST(CO.[Year] AS varchar(4)) END
	 + CASE WHEN CO.[Category] ='' THEN '' ELSE ' ('+CO.[Category]+')' END
	 , CO.[Company]
	 , CO.[Year]
	 , CO.[Invoices]
	 , COALESCE(CO.[Amount (LCY)],0)
	 , COALESCE(CO.[% Avg. Commission Rate],0)
	 , COALESCE(CASE WHEN CO.[% Avg. Commission Rate]=0 THEN 0 ELSE CO.[Amount (LCY)] / CO.[% Avg. Commission Rate] * 100 END,0)
	 , COALESCE(CO.[Bookings],0)
	 , COALESCE(CO.[RN],0)
	 , 0
	 , 0
	 , 0
	 , COALESCE(CO.[TAF Amount (LCY)],0)
	 , COALESCE(CO.[Agency Amount (LCY)],0)
  FROM @Companies CO
ORDER BY CO.[Company]
       , CO.[Year] desc
	   , CO.[Category]

DECLARE @MaxRow int
SELECT @MaxRow = MAX([Entry No_])+1 FROM @Result

PRINT '31 '+CAST(GETDATE() AS varchar(20))
  INSERT INTO @Result
  SELECT @MaxRow + YEAR(@DocumentDate) - CO.[Year]
       , 0, 1, 0
	   , 'Summe ' + CAST(CO.[Year] AS varchar(4))
       , 'Total'
       , CO.[Year]
	   , SUM(COALESCE([Invoices],0))
	   , SUM(COALESCE(CO.[Amount (LCY)],0))
	   , CASE WHEN SUM(COALESCE(CO.[Amount (LCY)],0))=0 THEN 0 ELSE SUM(CASE WHEN COALESCE(CO.[% Avg. Commission Rate],0) = 0 THEN 0 ELSE COALESCE(CO.[Amount (LCY)],0) / COALESCE(CO.[% Avg. Commission Rate],0) * 100 END) / SUM(COALESCE(CO.[Amount (LCY)],0)) END
	   , SUM(CASE WHEN COALESCE(CO.[% Avg. Commission Rate],0)=0 THEN 0 ELSE COALESCE(CO.[Amount (LCY)],0) / COALESCE(CO.[% Avg. Commission Rate],0) * 100 END)
	   , SUM(COALESCE(CO.[Bookings],0))
	   , SUM(COALESCE(CO.[RN],0))
	   , 0
	   , 0
	   , 0
	   , SUM(COALESCE(CO.[TAF Amount (LCY)],0))
	   , SUM(COALESCE(CO.[Agency Amount (LCY)],0))
    FROM @Companies CO
--   WHERE CO.[Category] = ''
GROUP BY CO.[Year]

SELECT @MaxRow = MAX([Entry No_])+1 FROM @Result

PRINT '32 '+CAST(GETDATE() AS varchar(20))
  INSERT INTO @Result
  SELECT @MaxRow + ROW_NUMBER() OVER(ORDER BY CO.[Company], CO.[Year] desc	)
       , 0, 0, 1
	   , 'Summe ' + CO.[Company] + '  ' + CAST(CO.[Year] AS varchar(4))
       , CO.[Company]
       , CO.[Year]
	   , SUM(COALESCE([Invoices],0))
	   , SUM(COALESCE(CO.[Amount (LCY)],0))
	   , CASE 
           WHEN SUM(COALESCE(CO.[Amount (LCY)],0))=0 THEN 0 
		   ELSE SUM(CASE WHEN COALESCE(CO.[% Avg. Commission Rate],0) = 0 THEN 0 ELSE COALESCE(CO.[Amount (LCY)],0) / COALESCE(CO.[% Avg. Commission Rate],0) * 100 END) / SUM(COALESCE(CO.[Amount (LCY)],0)) END
	   , SUM(CASE WHEN COALESCE(CO.[% Avg. Commission Rate],0)=0 THEN 0 ELSE COALESCE(CO.[Amount (LCY)],0) / COALESCE(CO.[% Avg. Commission Rate],0) * 100 END)
	   , SUM(COALESCE(CO.[Bookings],0))
	   , SUM(COALESCE(CO.[RN],0))
	   , 0
	   , 0
	   , 0
	   , SUM(COALESCE(CO.[TAF Amount (LCY)],0))
	   , SUM(COALESCE(CO.[Agency Amount (LCY)],0))
    FROM @Companies CO
   WHERE 1=1 --CO.[Company] = ''
GROUP BY CO.[Year]
       , CO.[Company]

;WITH Trend AS
(
  SELECT [Company]
       , SUM(CASE WHEN [Year] = YEAR(@PreviousDate) THEN R.[Amount (LCY)] ELSE 0 END) [Previous Year Amount (LCY)]
       , SUM(CASE WHEN [Year] = YEAR(@DocumentDate) THEN R.[Amount (LCY)] ELSE 0 END) [Actual Year Amount (LCY)]
       , SUM(CASE WHEN [Year] = YEAR(@PreviousDate) THEN R.[Bookings] ELSE 0 END) [Previous Year Bookings]
       , SUM(CASE WHEN [Year] = YEAR(@DocumentDate) THEN R.[Bookings] ELSE 0 END) [Actual Year Bookings]
       , SUM(CASE WHEN [Year] = YEAR(@PreviousDate) THEN R.[RN] ELSE 0 END) [Previous Year RN]
       , SUM(CASE WHEN [Year] = YEAR(@DocumentDate) THEN R.[RN] ELSE 0 END) [Actual Year RN]
    FROM @Result R
GROUP BY [Company]
)
--SELECT * FROM Trend
UPDATE R SET 
       R.[Trend Amount (LCY)] = CASE WHEN [Previous Year Amount (LCY)]=0 THEN 100 ELSE ([Actual Year Amount (LCY)] - [Previous Year Amount (LCY)]) * 100. / [Previous Year Amount (LCY)]  END 
     , R.[Trend Bookings]     = CASE WHEN [Previous Year Bookings]=0     THEN 100 ELSE ([Actual Year Bookings]     - [Previous Year Bookings])     * 100. / [Previous Year Bookings]      END 
     , R.[Trend RN]           = CASE WHEN [Previous Year RN]=0           THEN 100 ELSE ([Actual Year RN]           - [Previous Year RN])           * 100. / [Previous Year RN]            END 
  FROM @Result R
  JOIN Trend T
    ON T.[Company] = R.[Company]	
 WHERE R.[Year] = YEAR(@DocumentDate)
   AND R.[Invoices] <> 0
END

IF @DocumentDate = '2017-04-04' 
BEGIN
  INSERT INTO @Result
  SELECT * FROM tab_CheckCommissionValues WHERE NOT [Entry No_] IS NULL
END

SELECT * FROM @Result ORDER BY [Entry No_]

END
GO
