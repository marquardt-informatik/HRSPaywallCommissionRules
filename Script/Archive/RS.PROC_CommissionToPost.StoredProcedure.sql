USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CommissionToPost]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 20.09.2011
-- Description:	Nav Report 50298; RFC-49556

-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS'
		, @ReportId					INT				= 50298
EXEC [RS].[PROC_CommissionToPost] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CommissionToPost] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @Filter					VARCHAR(MAX) = ''
		, @DateFilterStart			VARCHAR(10)
		, @DateFilterEnd			VARCHAR(10)				
		, @TableIDs					[RS].[TableIDs]
		, @AliasIDs					[RS].[TableIDs]
		, @HRS						VARCHAR(20) = 'HRS'
		, @UseAllChains             bit
		, @UseAllCountries          bit	

--BEGIN Filter aus den FlowFilter
SET @DateFilterStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 0, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 50024
		AND [Field ID]  = 10004), '01.01.1753'),104);	    

SET @DateFilterEnd = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 13, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 50024
	    AND [Field ID]  = 10004), '31.12.2999'), 104);	   
--Ship-to-Filter nicht beachtet!	        	   
--ENDE Filter aus FlowFilter

SET @UseAllChains = 1
IF EXISTS (SELECT * FROM [RS-Report Execution] WHERE UserID = @UserId AND [Report ID] = @ReportId AND [Table ID] = 50009 AND [Field ID] = 4)
  SET @UseAllChains = 0

SET @UseAllCountries = 1
IF EXISTS (SELECT * FROM [RS-Report Execution] WHERE UserID = @UserId AND [Report ID] = @ReportId AND [Table ID] = 18 AND [Field ID] = 35)
  SET @UseAllCountries = 0

--BEGIN Parameter aus RS-Execution
DECLARE   @DateStart					DATETIME
		, @DateEnd						DATETIME		
		, @MonthUltimo					BIT
		
SET @DateStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1), '01.01.1753'), 104);	
SET @DateEnd = CONVERT(VARCHAR(10), COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 2), '31.12.2999'), 104);
SET @MonthUltimo = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 3);	    
--END Parameter aus RS-Execution	

--BEGIN Mandantenauswahl	
CREATE TABLE #RESULTS_CompanyName 
(
	    [CompanyName]			VARCHAR(30)
	  , [RowNumber]				INT
)  

DELETE FROM @TableIDs
INSERT INTO @TableIDs 
SELECT 2000000006, 'Company'

SET @StmtCompanyName = '
INSERT INTO #RESULTS_CompanyName
SELECT [Name] 
	 , ROW_NUMBER() OVER (ORDER BY [Name])
  FROM [Company] 
WHERE (1=1)
'+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

SET @StmtCompanyName = @StmtCompanyName + @Stmt
EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl

--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
	( [PostingPeriodEnd]					DATETIME
	, [Debit]								DEC(38,20)
	, [Payment]								DEC(38,20)
	, [OpenDebit]							DEC(38,20)
	, [Balance]								DEC(38,20)
	, [Country]								VARCHAR(10)
	, [CountryName]							VARCHAR(50)
	, [Chain]								VARCHAR(20)
	, [ChainName]							VARCHAR(50)	
)

--BEGIN WITH Teil 2 (Mandantenabhängig)
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES (50024, 'Agency Dislpay Header')
--2ter Teil					   
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN '' ELSE ' UNION ALL ' END)	
+'	  
SELECT '''+[CompanyName]+''' [Company]
     , MAX(['+[CompanyName]+'$Agency Display Header].[Case No_]) [Case No_]
     , MAX(CAST(['+[CompanyName]+'$Agency Display Header].[Bill-to Customer No_] AS varchar)) [Bill-to Customer No_]   
     , MAX(['+[CompanyName]+'$Agency Display Header].[MuseID]) [MuseID]   
     , COUNT(DISTINCT [Line].[Reservation No_]) [Qty_ Postings]
     , ROUND(SUM(Line.[Line Amount]) / (SELECT TOP 1 Rate.[Exchange Rate Amount]
        FROM ['+[CompanyName]+'$Currency Exchange Rate] AS [Rate] WITH (READUNCOMMITTED)
        WHERE MAX(['+[CompanyName]+'$Agency Display Header].[Posting Date]) >= [Rate].[Starting Date] AND
              MAX(['+[CompanyName]+'$Agency Display Header].[Currency Code]) = [Rate].[Currency Code]
        ORDER BY [Rate].[Starting Date] DESC),2) [Line Amount (LCY)]        
     , (ROUND(SUM(Line.[Line Amount]) / (SELECT TOP 1 Rate.[Exchange Rate Amount]
        FROM ['+[CompanyName]+'$Currency Exchange Rate] AS [Rate] WITH (READUNCOMMITTED)
        WHERE MAX(['+[CompanyName]+'$Agency Display Header].[Posting Date]) >= [Rate].[Starting Date] AND
              MAX(['+[CompanyName]+'$Agency Display Header].[Currency Code]) = [Rate].[Currency Code]
        ORDER BY [Rate].[Starting Date] DESC),2) / COUNT(DISTINCT [Line].[Reservation No_])) [Avg_ Line Amount (LCY)]
FROM ['+[CompanyName]+'$Agency Display Header] WITH (READUNCOMMITTED)
LEFT JOIN ['+[CompanyName]+'$Agency Display Line] AS [Line] WITH (READUNCOMMITTED)
ON ['+[CompanyName]+'$Agency Display Header].[Case No_] = [Line].[Display Case No_] AND
   ['+[CompanyName]+'$Agency Display Header].[Status] = 0 AND
   ['+[CompanyName]+'$Agency Display Header].[Posting Date] >= '''+ @DateFilterStart+''' AND
   ['+[CompanyName]+'$Agency Display Header].[Posting Date] <= '''+ @DateFilterEnd+'''
WHERE [Line].[Line Amount] IS NOT NULL AND
      ['+[CompanyName]+'$Agency Display Header].[Currency Code] <> '''' AND
      ['+[CompanyName]+'$Agency Display Header].[Status] = 0
'+ [RS].[Nav2SqlString](@UserId, @HRS, @ReportId, @TableIDs, 3)+
' GROUP BY ['+[CompanyName]+'$Agency Display Header].[Case No_] '
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
PRINT	SUBSTRING(@Stmt,16001,24000)
EXEC   (@Stmt)

DROP TABLE #RESULTS_CompanyName
END
GO
