USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_ChainDebit]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Jens Högg
-- Create date: 12.03.2013
-- Description:	Nav Report 50297; RFC-45240
--				Diese Procedure wird in dem Report CustDebitTrend und CustTurnoverTrend verwendet.
-- 
/*
EXEC [RS].[PROC_ChainDebit] 'TMA04','HRS',50224,'2016-10-12'
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_ChainDebit] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
	, @CheckDate                    DATETIME
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
		, @Filter_GloDim1			VARCHAR(MAX)		
		, @Filter_GloDim2			VARCHAR(MAX)
		, @Filter_Currency			VARCHAR(MAX)
		, @TableIDs					[RS].[TableIDs]
		, @AliasIDs					[RS].[TableIDs]		
		, @HRS						VARCHAR(20) = 'HRS'
		, @LastMonthDate            VARCHAR(10)
		, @LastYearDate             VARCHAR(10)
		, @Last2YearDate            VARCHAR(10) 

--BEGIN Datum berechnen
SET @LastMonthDate = CONVERT(VARCHAR(10), DATEADD(ms,-3,DATEADD(mm, DATEDIFF(m,0,DATEADD(month,-1,@CheckDate)  )+1, 0)), 104)
SET @LastYearDate = DATEADD(ms,-3,DATEADD(yy, DATEDIFF(yy,0,DATEADD(YEAR,-1,@CheckDate)  )+1, 0))
SET @Last2YearDate = DATEADD(ms,-3,DATEADD(yy, DATEDIFF(yy,0,DATEADD(YEAR,-2,@CheckDate)  )+1, 0))

--BEGIN Filter aus den FlowFilter
SET @DateFilterStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 0, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
		AND [Field ID]  = 55), '01.01.1753'),104);	    

SET @DateFilterEnd = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 13, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 55), '31.12.2999'), 104);	   

SET @Filter_GloDim1 = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 56)	  

SET @Filter_GloDim2 = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 57)

SET @Filter_Currency = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 111)	
--Ship-to-Filter nicht beachtet!	        	   
--ENDE Filter aus FlowFilter

--BEGIN Parameter aus RS-Execution
DECLARE   @DateStart					DATETIME
		, @DateEnd						DATETIME		
		, @MonthUltimo					BIT
		
SET @DateFilterStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1), '01.01.1753'), 104);	
SET @DateFilterEnd = CONVERT(VARCHAR(10), COALESCE(
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
SELECT REPLACE([Name],''.'',''_'')
	 , ROW_NUMBER() OVER (ORDER BY [Name])
  FROM [Company] 
WHERE (1=1)
'+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

SET @StmtCompanyName = @StmtCompanyName + @Stmt
PRINT	@StmtCompanyName
EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl

--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
(			  
	        [Chain Code]             VARCHAR(100)
		  , [Chain]   		         VARCHAR(100)
		  , [CRS]                    INT
		  , [Balance (Current)]		 DEC(38,20)
		  , [Balance (last month)]	 DEC(38,20)
		  , [Outstanding current]	 DEC(38,20)
		  , [Outstanding last month] DEC(38,20)
		  , [Outstanding Year-1]	 DEC(38,20)
		  , [Outstanding Year-2]	 DEC(38,20)
		  , [Outstanding Year<2]	 DEC(38,20)
		  , [Salesperson Code]		 VARCHAR(10)		  
)

DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES(    9, 'Country/Region')
	, (   18, 'Customer')

DELETE FROM @AliasIDs 
INSERT INTO @AliasIDs
VALUES(349, 'Chain')
	, (349, 'Brand')

--BEGIN WITH (Mandantenabhängig)
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' WITH 'ELSE ' , ' END)
+'
[CustLedgerEntry_SUM_'+[CompanyName]+'] AS 
('+'
 SELECT CASE WHEN C.Code = ''99999'' AND B.Code <> ''99999'' THEN B.Code ELSE C.Code END [Chain Code]
       , CASE WHEN C.Code = ''99999'' AND B.Code <> ''99999'' THEN RTRIM(B.[Description]) + '' (#'' + CONVERT(VARCHAR(20),B.Code) + '')'' ELSE RTRIM(C.[Description]) + '' (#'' + CONVERT(VARCHAR(20),C.Code) + '')'' END [Chain]
       , [' + [CompanyName] + '$Customer].[No_] [Customer No_]
       , CASE WHEN [' + [CompanyName] + '$Customer].[Contract Status] IN (''10'',''11'') THEN 1 ELSE 0 END [CRS]
       , SUM(DL.[Amount (LCY)]) [Balance (Current)]
       , SUM(CASE WHEN [Posted At Date] <= ''' + @LastMonthDate + ''' THEN DL.[Amount (LCY)] ELSE 0 END) [Balance (last month)]
       , SUM(CASE WHEN DATEDIFF(day,''' + CONVERT(VARCHAR(10),@CheckDate,104) + ''',[Due Date]) < -60 THEN DL.[Amount (LCY)] ELSE 0 END) [Outstanding current]
       , SUM(CASE WHEN DATEDIFF(day,''' + @LastMonthDate + ''',[Due Date]) < -60 AND [Posted At Date] <= ''' + @LastMonthDate + ''' THEN DL.[Amount (LCY)] ELSE 0 END) [Outstanding last month]
       , SUM(CASE WHEN (YEAR(''' + CONVERT(VARCHAR(10),@CheckDate,104) + ''')-1) = YEAR([Due Date]) THEN DL.[Amount (LCY)] ELSE 0 END) [Outstanding Year-1]
       , SUM(CASE WHEN (YEAR(''' + CONVERT(VARCHAR(10),@CheckDate,104) + ''')-2) = YEAR([Due Date]) THEN DL.[Amount (LCY)] ELSE 0 END) [Outstanding Year-2]               
       , SUM(CASE WHEN (YEAR(''' + CONVERT(VARCHAR(10),@CheckDate,104) + ''')-3) >= YEAR([Due Date]) THEN DL.[Amount (LCY)] ELSE 0 END) [Outstanding Year<2]                                           
       , CASE WHEN C.Code = ''99999'' AND B.Code <> ''99999'' THEN B.[Salesperson Code] ELSE C.[Salesperson Code] END [Salesperson Code]
    FROM [' + [CompanyName] + '$Customer] WITH (NOLOCK)
    JOIN [Chain] C WITH (NOLOCK)
      ON [' + [CompanyName] + '$Customer].[Chain] = C.[Code]
    JOIN [Brand] B WITH (NOLOCK)
      ON [' + [CompanyName] + '$Customer].[Brand] = B.[Code]
    JOIN [' + [CompanyName] + '$Cust_ Ledger Entry] CL WITH (NOLOCK)
      ON [' + [CompanyName] + '$Customer].[No_] = CL.[Customer No_]
    JOIN [' + [CompanyName] + '$Detailed Cust_ Ledg_ Entry] DL WITH (NOLOCK)
      ON CL.[Entry No_] = DL.[Cust_ Ledger Entry No_]
   WHERE 1 = 1
     AND [' + [CompanyName] + '$Customer].[Chain] <> ''''
'+ [RS].[Nav2SqlString](@UserId, [CompanyName], @ReportId, @TableIDs, 3)
 + [RS].[Nav2SqlString](@UserId, @HRS, @ReportId, @AliasIDs, 1)+'
GROUP BY CASE WHEN C.Code = ''99999'' AND B.Code <> ''99999'' THEN B.Code ELSE C.Code END
       , [' + [CompanyName] + '$Customer].[No_]
       , CASE WHEN [dbo].[' + [CompanyName] + '$Customer].[Contract Status] IN (''10'',''11'') THEN 1 ELSE 0 END
       , CASE WHEN C.Code = ''99999'' AND B.Code <> ''99999'' THEN RTRIM(B.[Description]) + '' (#'' + CONVERT(VARCHAR(20),B.Code) + '')'' ELSE RTRIM(C.[Description]) + '' (#'' + CONVERT(VARCHAR(20),C.Code) + '')'' END 
       , CASE WHEN C.Code = ''99999'' AND B.Code <> ''99999'' THEN B.[Salesperson Code] ELSE C.[Salesperson Code] END
)'
FROM #RESULTS_CompanyName
ORDER BY RowNumber

--2ter Teil					   
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' UNION ALL ' END)	
+'	  
  SELECT [Chain] [Chain]
       , [Chain Code] [Chain Code]
	   , [CRS]
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Balance (Current)] END)      [Balance (Current)]
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Balance (last month)] END)   [Balance (Last month)]
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Outstanding current] END)    [Outstanding current]
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Outstanding last month] END) [Oustanding last month]
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Outstanding Year-1] END)     [Outstanding Year-1]
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Outstanding Year-2] END)     [Outstanding Year-2] 	
       , SUM(CASE WHEN [Balance (Current)]  >= 0 THEN [Outstanding Year<2] END)     [Outstanding Year<2]          
       , [Salesperson Code] [Salesperson Code]
    FROM [CustLedgerEntry_SUM_'+[CompanyName]+'] S1    
   WHERE [Chain Code] <> ''99999''
GROUP BY [Chain Code]
       , [Chain]
 	   , [CRS]
       , [Salesperson Code]		
'   
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,8000)
PRINT	SUBSTRING(@Stmt,16001,8000)
PRINT	SUBSTRING(@Stmt,24001,8000)
EXEC   (@Stmt)

;WITH S AS (SELECT [Chain Code],SUM([Balance (Current)]) [Balance] FROM #RESULTS GROUP BY [Chain Code])
SELECT [Chain]                       [Chain]
     , S.[Chain Code]                  [Chain Code]
	 , CRS
     , SUM([Balance (Current)])      [Balance (Current)]
     , SUM([Balance (last month)])   [Balance (Last month)]
     , SUM([Outstanding current])    [Outstanding current]
     , SUM([Outstanding last month]) [Oustanding last month]
     , SUM([Outstanding Year-1])     [Outstanding Year-1]
     , SUM([Outstanding Year-2])     [Outstanding Year-2] 	
     , SUM([Outstanding Year<2])     [Outstanding Year older 2]          
     , [Salesperson Code]            [Salesperson Code]
	 , MAX(S.Balance) Balance
FROM #RESULTS
JOIN S On S.[Chain Code] = #RESULTS.[Chain Code]
GROUP BY S.[Chain Code]
       , [Chain]
	   , [CRS]
       , [Salesperson Code]	      
ORDER BY 12 DESC, CRS

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
