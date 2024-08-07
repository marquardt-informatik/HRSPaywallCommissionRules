USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustSummaryAgingSimp_Test]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Ralph Prangenberg
-- Create date: 13.07.2011
-- Description:	Nav Report 50139
--				Debitor - Altersvert.-Saldo
-- 19.01.12 RP1 Befüllen einer mandantenübergreifender Tabelle für den Excelexport
--				aus NAV

-- 
/*
SET Language German
DECLARE   @StartDate				DATETIME		= '01.12.2011'
		, @Periods					INT				= 12
EXEC [RS].[PROC_CustSummaryAgingSimp_Test] @StartDate, @Periods
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustSummaryAgingSimp_Test] 
(
	  @StartDate					DATETIME 
	, @Periods						INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @PeriodCounter			INT = 1

DECLARE
	@Date1End			DATETIME
  , @Date2Start			DATETIME
  , @Date2End			DATETIME
  , @Date3Start			DATETIME
  , @Date3End			DATETIME
  , @Date4Start			DATETIME
  , @Date4End			DATETIME
  , @Date5Start			DATETIME
  ,	@Date1EndVAR		VARCHAR(10)
  , @Date2StartVAR		VARCHAR(10)
  , @Date2EndVAR		VARCHAR(10)
  , @Date3StartVAR		VARCHAR(10)
  , @Date3EndVAR		VARCHAR(10)
  , @Date4StartVAR		VARCHAR(10)
  , @Date4EndVAR		VARCHAR(10)
  , @Date5StartVAR		VARCHAR(10)
  
CREATE TABLE #RESULTS_CompanyName 
(
	    [CompanyName]			VARCHAR(30)
	  , [RowNumber]				INT
)  
INSERT INTO #RESULTS_CompanyName
SELECT 'HRS',1 UNION SELECT 'HRS-CN',2

WHILE (@PeriodCounter<=@Periods)
BEGIN   
DELETE 
  FROM STAT.HOTEL_OPEN_RECEIVABLES 
 WHERE [Period] = DATEADD(mm,-@PeriodCounter+1,@StartDate)

--BEGIN Perioden in Variablen eintragen 
SET @Date5Start = DATEADD(mm,-@PeriodCounter+1,@StartDate)
SET @Date4Start = DATEADD(dd, -30, @Date5Start) 
SET @Date4End   = DATEADD(dd,  -1, @Date5Start) 
SET @Date3Start = DATEADD(dd, -30, @Date4Start) 
SET @Date3End   = DATEADD(dd,  -1, @Date4Start)
SET @Date2Start = DATEADD(dd, -30, @Date3Start) 
SET @Date2End   = DATEADD(dd,  -1, @Date3Start)
SET @Date1End   = DATEADD(dd,  -1, @Date2Start)

SET @Date1EndVAR   = CONVERT(VARCHAR(10), @Date1End, 104)
SET @Date2EndVAR   = CONVERT(VARCHAR(10), @Date2End, 104)
SET @Date3EndVAR   = CONVERT(VARCHAR(10), @Date3End, 104)
SET @Date4EndVAR   = CONVERT(VARCHAR(10), @Date4End, 104)
SET @Date2StartVAR = CONVERT(VARCHAR(10), @Date2Start, 104)
SET @Date3StartVAR = CONVERT(VARCHAR(10), @Date3Start, 104)
SET @Date4StartVAR = CONVERT(VARCHAR(10), @Date4Start, 104)
SET @Date5StartVAR = CONVERT(VARCHAR(10), @Date5Start, 104)
--ENDE Perioden in Variablen eintragen 

--BEGIN Rückgabetabelle
SELECT @Stmt = ''
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' WITH _R AS( ' ELSE ' 
UNION ALL ' END)	
+'	 
	SELECT '''+@Date5StartVAR+''' [StartDate]
	     , ['+[CompanyName]+'$Customer].[No_] [Customer_No]
		 , ['+[CompanyName]+'$Customer].[Name] [Customer_Name]
		 , ['+[CompanyName]+'$Customer].[Brand] [Brand]
		 , ['+[CompanyName]+'$Customer].[Chain] [Chain]
		 , COALESCE(['+[CompanyName]+'$Country_Region].[Name],''no Country'') [Country_Name]
		 , COALESCE(['+[CompanyName]+'$Contact].[City],['+[CompanyName]+'$Customer].[City]) [City]
		 , COALESCE(['+[CompanyName]+'$Dimension Value].[Name],''No-Contract'') [Contract_Status]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5] -- nicht fällig
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4]  -- 0-30 Tage
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3] -- 30-60 Tage
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2] -- 60-90 Tage
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1] -- > 90 Tage	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)
		 + SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)
		 + SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END) [CustDue] 
		 , CASE WHEN SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)
		 + SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END)
		 + SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)]
					 ELSE 0
				END) < 0 THEN 1 ELSE 0 END [HasCredit] 
		, COALESCE(['+[CompanyName]+'$Currency].[Code],'''') [CurrencyCode]		 									
		, REPLACE(SPACE(20-LEN(['+[CompanyName]+'$Customer].[No_])), '''+' '+''' , '''+'0'+''') + LTRIM(['+[CompanyName]+'$Customer].[No_]) [Sort_Customer_No]
	  FROM ['+[CompanyName]+'$Customer]
 LEFT JOIN ['+[CompanyName]+'$Contact]
		ON ['+[CompanyName]+'$Contact].[No_] = ['+[CompanyName]+'$Customer].[No_] 	
 LEFT JOIN ['+[CompanyName]+'$Country_Region]
		ON ['+[CompanyName]+'$Country_Region].[Code] = ['+[CompanyName]+'$Contact].[Country_Region Code] 	
	  JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3]
		ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_] = ['+[CompanyName]+'$Customer].[No_] 	
 LEFT JOIN ['+[CompanyName]+'$Dimension Value]
        ON ['+[CompanyName]+'$Dimension Value].[Dimension Code] = ''CONTRACT STATUS''
       AND ['+[CompanyName]+'$Dimension Value].[Code] = ['+[CompanyName]+'$Customer].[Contract Status] 										 
 LEFT JOIN ['+[CompanyName]+'$Currency]
		ON ['+[CompanyName]+'$Currency].[Code] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Currency Code]
 	 WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Posting Date] <= '''+@Date5StartVAR+'''	
  GROUP BY ['+[CompanyName]+'$Customer].[No_]
		 , ['+[CompanyName]+'$Customer].[Name]
		 , COALESCE(['+[CompanyName]+'$Country_Region].[Name],''no Country'')
		 , COALESCE(['+[CompanyName]+'$Contact].[City],['+[CompanyName]+'$Customer].[City])
		 , ['+[CompanyName]+'$Customer].[Brand]
		 , ['+[CompanyName]+'$Customer].[Chain]
		 , COALESCE(['+[CompanyName]+'$Dimension Value].[Name],''no Contract Code'')
		 , COALESCE(['+[CompanyName]+'$Currency].[Code],'''')'
FROM #RESULTS_CompanyName
ORDER BY RowNumber 
SELECT @Stmt = @Stmt + ')
  INSERT INTO STAT.HOTEL_OPEN_RECEIVABLES
  SELECT [StartDate]
	   , [Customer_No]
	   , MAX([Customer_Name]) [Customer_Name]
	   , MAX([Brand]) [Brand]
	   , MAX([Chain]) [Chain]
	   , MAX([Country_Name]) [Country_Name]
	   , MAX([City]) [City]
	   , MAX([Contract_Status]) [Contract_Status]
	   , SUM(COALESCE([CustBalanceDueLCY1],0))
	   , SUM(COALESCE([CustBalanceDueLCY2],0))
	   , SUM(COALESCE([CustBalanceDueLCY3],0))
	   , SUM(COALESCE([CustBalanceDueLCY4],0))
	   , SUM(COALESCE([CustBalanceDueLCY5],0))
	   , SUM(COALESCE([CustDue],0))
	   , CASE WHEN SUM(COALESCE([CustDue],0))<0 THEN 1 ELSE 0 END [HasCredit]
	   , MAX([CurrencyCode]) [CurrencyCode]
	   , MAX([Sort_Customer_No]) [Sort_Customer_No]
    FROM _R
	GROUP BY [StartDate]
	   , [Customer_No]
HAVING SUM(COALESCE([CustBalanceDueLCY1],0)) <> 0
	OR SUM(COALESCE([CustBalanceDueLCY2],0)) <> 0
	OR SUM(COALESCE([CustBalanceDueLCY3],0)) <> 0
	OR SUM(COALESCE([CustBalanceDueLCY4],0)) <> 0
	OR SUM(COALESCE([CustBalanceDueLCY5],0)) <> 0
'

--PRINT	SUBSTRING(@Stmt,1,8000)
--PRINT	SUBSTRING(@Stmt,8001,16000)
--PRINT	SUBSTRING(@Stmt,16001,24000)
EXEC   (@Stmt)

SET @PeriodCounter = @PeriodCounter + 1
END
--ENDE Rückgabetabelle	

DROP TABLE #RESULTS_CompanyName
END
GO
