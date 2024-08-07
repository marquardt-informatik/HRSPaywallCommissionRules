USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustSummaryAgingIndividualValueAdjustment]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 18.07.2012
-- Description:	Altersverteilung gemäß Einzelwertberichtigung hotel.de
-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50143
		, @PeriodStartDate			DATETIME		= '31.12.2011'
		, @PrintAmountsInLCY		INT				= 0	
EXEC [RS].[PROC_CustSummaryAgingIndividualValueAdjustment] @UserId, @CompanyName, @ReportId, @PeriodStartDate, @PrintAmountsInLCY
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustSummaryAgingIndividualValueAdjustment] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName				VARCHAR(30)
	, @ReportId						INT
	, @PeriodStartDate				DATETIME
	, @PrintAmountsInLCY			INT
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

--BEGIN Perioden in Variablen eintragen
DECLARE
	@Date1End		DATETIME
  , @Date2Start		DATETIME
  , @Date2End		DATETIME
  , @Date3Start		DATETIME
  , @Date3End		DATETIME
  , @Date4Start		DATETIME
  , @Date4End		DATETIME
  , @Date5Start		DATETIME
  , @Date5End		DATETIME
  , @Date6Start		DATETIME
  , @Date6End		DATETIME
  , @Date7Start		DATETIME
  , @Date7End		DATETIME
  ,	@Date1EndVAR	VARCHAR(10)
  , @Date2StartVAR	VARCHAR(10)
  , @Date2EndVAR	VARCHAR(10)
  , @Date3StartVAR	VARCHAR(10)
  , @Date3EndVAR	VARCHAR(10)
  , @Date4StartVAR	VARCHAR(10)
  , @Date4EndVAR	VARCHAR(10)
  , @Date5StartVAR	VARCHAR(10)
  , @Date5EndVAR	VARCHAR(10)
  , @Date6StartVAR	VARCHAR(10)
  , @Date6EndVAR	VARCHAR(10)
  , @Date7StartVAR	VARCHAR(10)
  , @Date7EndVAR	VARCHAR(10)
SET @Date7End = @PeriodStartDate
SET @Date7Start = DATEADD(dd, -30, @Date7End) 
SET @Date6End   = DATEADD(dd,  -1, @Date7Start) 
SET @Date6Start = DATEADD(dd, -60, @Date7Start) 
SET @Date5End   = DATEADD(dd,  -1, @Date6Start) 
SET @Date5Start = DATEADD(dd, -90, @Date6Start) 
SET @Date4End   = DATEADD(dd,  -1, @Date5Start) 
SET @Date4Start = DATEADD(dd, -90, @Date5Start) 
SET @Date3End   = DATEADD(dd,  -1, @Date4Start) 
SET @Date3Start = DATEADD(dd, -90, @Date4Start) 
SET @Date2End   = DATEADD(dd,  -1, @Date3Start) 
SET @Date2Start = DATEADD(dd,-720, @Date3Start) 
SET @Date1End   = DATEADD(dd,  -1, @Date2Start)
SET @Date1EndVAR = CONVERT(VARCHAR(10), @Date1End, 104)
SET @Date2EndVAR = CONVERT(VARCHAR(10), @Date2End, 104)
SET @Date3EndVAR = CONVERT(VARCHAR(10), @Date3End, 104)
SET @Date4EndVAR = CONVERT(VARCHAR(10), @Date4End, 104)
SET @Date5EndVAR = CONVERT(VARCHAR(10), @Date5End, 104)
SET @Date6EndVAR = CONVERT(VARCHAR(10), @Date6End, 104)
SET @Date7EndVAR = CONVERT(VARCHAR(10), @Date7End, 104)
SET @Date2StartVAR = CONVERT(VARCHAR(10), @Date2Start, 104)
SET @Date3StartVAR = CONVERT(VARCHAR(10), @Date3Start, 104)
SET @Date4StartVAR = CONVERT(VARCHAR(10), @Date4Start, 104)
SET @Date5StartVAR = CONVERT(VARCHAR(10), @Date5Start, 104)
SET @Date6StartVAR = CONVERT(VARCHAR(10), @Date6Start, 104)
SET @Date7StartVAR = CONVERT(VARCHAR(10), @Date7Start, 104)
--ENDE Perioden in Variablen eintragen 

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
PRINT	@StmtCompanyName
EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl


--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
(	  [CompanyName]							VARCHAR(30)
	, [Customer_No]							VARCHAR(20)
	, [Customer_Name]						VARCHAR(130)
	, [Customer_Name_2]						VARCHAR(130)
	, [CustBalanceDueLCY1]					DEC(38,20)
	, [CustBalanceDueLCY2]					DEC(38,20)
	, [CustBalanceDueLCY3]					DEC(38,20)
	, [CustBalanceDueLCY4]					DEC(38,20)
	, [CustBalanceDueLCY5]					DEC(38,20)
	, [CustBalanceDueLCY6]					DEC(38,20)
	, [CustBalanceDueLCY7]					DEC(38,20)
	, [Sort_Customer_No]					VARCHAR(20)
)
				   
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' 
UNION ALL ' END)	
+'	 
	SELECT '''+[CompanyName]+'''
		 , ['+[CompanyName]+'$Customer].[No_]
		 , ['+[CompanyName]+'$Customer].[Name] 
		 , ['+[CompanyName]+'$Customer].[Name 2]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1]	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date5StartVAR+''' AND '''+@Date5EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date6StartVAR+''' AND '''+@Date6EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY6]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date7StartVAR+''' AND '''+@Date7EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY7]
		, REPLACE(SPACE(20-LEN(['+[CompanyName]+'$Customer].[No_])), '''+' '+''' , '''+'0'+''') + LTRIM(['+[CompanyName]+'$Customer].[No_])			   
	  FROM ['+[CompanyName]+'$Customer]
	  JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry]
	    ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Customer No_] =  ['+[CompanyName]+'$Customer].[No_]		    
 LEFT JOIN ['+[CompanyName]+'$Currency]
		ON ['+[CompanyName]+'$Currency].[Code] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Currency Code]	    	
 	 WHERE (1=1)
 	 '+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 2)	 		 	 
+'GROUP BY ['+[CompanyName]+'$Customer].[No_], ['+[CompanyName]+'$Customer].[Name], ['+[CompanyName]+'$Customer].[Name 2]'
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
EXEC   (@Stmt)
--ENDE Rückgabetabelle	

SELECT * FROM #RESULTS 
WHERE  CustBalanceDueLCY1 <> 0
	OR CustBalanceDueLCY2 <> 0
	OR CustBalanceDueLCY3 <> 0
	OR CustBalanceDueLCY4 <> 0
	OR CustBalanceDueLCY5 <> 0
	OR CustBalanceDueLCY6 <> 0
	OR CustBalanceDueLCY7 <> 0
ORDER BY [Sort_Customer_No], [CompanyName]

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
