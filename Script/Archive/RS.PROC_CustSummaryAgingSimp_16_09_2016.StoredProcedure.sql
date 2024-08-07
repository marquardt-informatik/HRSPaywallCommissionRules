USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustSummaryAgingSimp_16_09_2016]    Script Date: 10.04.2024 14:31:58 ******/
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
-- 31.01.13 JH  Feld Hotel Status hinzugefügt und dadurch bedingt alle Spalten verschoben
-- 
-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TCH01'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50139
		, @StartDate				DATETIME		= '05.03.2014'
		, @PrintAmountsInLCY		INT				= 1
EXEC [RS].[PROC_CustSummaryAgingSimp] @UserId, @CompanyName, @ReportId, @StartDate, @PrintAmountsInLCY
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustSummaryAgingSimp_16_09_2016] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
	, @StartDate					DATETIME
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
		, @BalanceMinimum           DECIMAL(37,20)
		, @BalanceMaximum           DECIMAL(37,20)

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
	    
SET @BalanceMinimum = 
    (SELECT CAST(REPLACE([Filter Value],',','.') AS DECIMAL(37,20))
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 3)
SET @BalanceMaximum = 
    (SELECT CAST(REPLACE([Filter Value],',','.') AS DECIMAL(37,20))
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 4)
--Ship-to-Filter nicht beachtet!	        	   
--ENDE Filter aus FlowFilter

--BEGIN Perioden in Variablen eintragen
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
SET @Date5Start = @StartDate 
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
'+ CASE WHEN [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)='' THEN
     ' AND ([Company].[Name] = ''' + @CompanyName + ''')'
   ELSE
     [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)
   END

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
	, [Chain]								VARCHAR(10)
	, [Brand]								VARCHAR(10)
	-- HRS001>>>>
	, [Hotel_Status]                        INT
	-- <<<< HRS001
	, [Country_Name]                        VARCHAR(250)
	, [City]								VARCHAR(250)
	, [Information]							VARCHAR(max)
	, [Salesperson_Code]					VARCHAR(10)
	, [CustBalanceDue1]						DEC(38,20)
	, [CustBalanceDue2]						DEC(38,20)
	, [CustBalanceDue3]						DEC(38,20)
	, [CustBalanceDue4]						DEC(38,20)
	, [CustBalanceDue5]						DEC(38,20)
	, [CustBalanceDueLCY1]					DEC(38,20)
	, [CustBalanceDueLCY2]					DEC(38,20)
	, [CustBalanceDueLCY3]					DEC(38,20)
	, [CustBalanceDueLCY4]					DEC(38,20)
	, [CustBalanceDueLCY5]					DEC(38,20)
	, [CurrencyCode]						VARCHAR(20)		
	, [Sort_Customer_No]					VARCHAR(20)
)
				   
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')
INSERT INTO @TableIDs 
VALUES	(21, 'Cust. Ledger Entry')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' 
UNION ALL ' END)	
+'	 
	SELECT '''+[CompanyName]+'''
		 , ['+[CompanyName]+'$Customer].[No_]
		 , ['+[CompanyName]+'$Customer].[Name]
		 , ['+[CompanyName]+'$Customer].[Chain]
		 , ['+[CompanyName]+'$Customer].[Brand]
		 , ['+[CompanyName]+'$Customer].[Hotel Status]
		 , ['+[CompanyName]+'$Country_Region].[Name] [Country_Region_Name]
		 , ['+[CompanyName]+'$Contact].[City]
		 , ['+[CompanyName]+'$Customer].[Information]
		 , ['+[CompanyName]+'$Customer].[Salesperson Code]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'
						   END)+'		
					 ELSE 0
				END)	[CustBalanceDue1]	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'
						   END)+'	
					 ELSE 0
				END)	[CustBalanceDue2]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'
						   END)+'
					 ELSE 0
				END)	[CustBalanceDue3]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'
						   END)+'
					 ELSE 0
				END)	[CustBalanceDue4]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'								
						   END)+'
					 ELSE 0
				END)	[CustBalanceDue5]
--Summen werden immer in LCY dargestellt
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
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5]
		, '+(CASE WHEN @PrintAmountsInLCY = 0 
			   THEN '['+[CompanyName]+'$Currency].[Code]'
			   ELSE ''''''
			END)+'									
		, REPLACE(SPACE(20-LEN(['+[CompanyName]+'$Customer].[No_])), '''+' '+''' , '''+'0'+''') + LTRIM(['+[CompanyName]+'$Customer].[No_])			   
	  FROM ['+[CompanyName]+'$Customer]
	  JOIN ['+[CompanyName]+'$Contact]
		ON ['+[CompanyName]+'$Contact].[No_] = ['+[CompanyName]+'$Customer].[No_] 	
	  JOIN ['+[CompanyName]+'$Country_Region]
		ON ['+[CompanyName]+'$Country_Region].[Code] = ['+[CompanyName]+'$Contact].[Country_Region Code] 	
	  JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry]
		ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Customer No_] = ['+[CompanyName]+'$Customer].[No_] 	
	  JOIN ['+[CompanyName]+'$Cust_ Ledger Entry] 
		ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Cust_ Ledger Entry No_] 	
 LEFT JOIN ['+[CompanyName]+'$Currency]
		ON ['+[CompanyName]+'$Currency].[Code] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Currency Code]
 	 WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Posting Date] <= '''+@Date5StartVAR+'''	
 	   AND ['+[CompanyName]+'$Customer].[Testhotel] = 0
 	 '+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 2)	 		 	 
+'
 GROUP BY ['+[CompanyName]+'$Customer].[No_], ['+[CompanyName]+'$Customer].[Name]
		, ['+[CompanyName]+'$Customer].[Chain]
		, ['+[CompanyName]+'$Customer].[Brand]'
 + CASE WHEN @PrintAmountsInLCY = 0 THEN ', ['+[CompanyName]+'$Currency].[Code]' ELSE '' END
 + ', ['+[CompanyName]+'$Customer].[Hotel Status], ['+[CompanyName]+'$Country_Region].[Name], ['+[CompanyName]+'$Contact].[City], ['+[CompanyName]+'$Customer].[Information], ['+[CompanyName]+'$Customer].[Salesperson Code]'
 + CASE WHEN (@BalanceMaximum<>0.0) OR (@BalanceMinimum <> 0.0) THEN
       ' HAVING '
     + CASE WHEN (@BalanceMaximum<>0.0) THEN 
         'SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] <= '''+@Date5StartVAR+'''
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'
						   END)+'		
					 ELSE 0
				END) > ' + CAST(@BalanceMaximum AS varchar)
       ELSE '' END
     + CASE WHEN (@BalanceMinimum <> 0.0) THEN 
         'SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Due Date] <= '''+@Date5StartVAR+'''
					 THEN '+(CASE WHEN @PrintAmountsInLCY = 0 
								THEN '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]'
								ELSE '['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]'
						   END)+'		
					 ELSE 0
				END) < ' + CAST(@BalanceMinimum AS varchar)
       ELSE '' END
   ELSE
     ''
   END
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
EXEC   (@Stmt)
--ENDE Rückgabetabelle	

-->>RP1
-->>[Excelbuffer 4S SRS] füllen 
DECLARE	  @ExcelExportOption	INT
		, @ConnectionID			INT
		, @CountCompany			INT
		
SET @ExcelExportOption = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1); 
	    
SET @ConnectionID = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 2); 
	    	    
SET @CountCompany = (SELECT COUNT(1) FROM #RESULTS_CompanyName)	    

IF @ExcelExportOption > 0
BEGIN

CREATE TABLE #RESULTS_EXCEL
(	  [_ROW_NUMBER]							INT 
	, [Customer_No]							VARCHAR(20)
	, [Customer_Name]						VARCHAR(130)
	, [Chain]								VARCHAR(10)
	, [Brand]								VARCHAR(10)
	, [Hotel_Status]                        INT
	, [Country_Name]						VARCHAR(250)
	, [City]								VARCHAR(250)
	, [Information]							VARCHAR(250)
	, [Salesperson_Code]					VARCHAR(10)
	, [SUMDue1]								DEC(38,20)
	, [SUMDue2]								DEC(38,20)
	, [SUMDue3]								DEC(38,20)
	, [SUMDue4]								DEC(38,20)
	, [SUMDue5]								DEC(38,20)
	--Mandant 1
	, [Company1Due1]						DEC(38,20)
	, [Company1Due2]						DEC(38,20)	
	, [Company1Due3]						DEC(38,20)
	, [Company1Due4]						DEC(38,20)
	, [Company1Due5]						DEC(38,20)
	--Mandant 2
	, [Company2Due1]						DEC(38,20)
	, [Company2Due2]						DEC(38,20)
	, [Company2Due3]						DEC(38,20)
	, [Company2Due4]						DEC(38,20)
	, [Company2Due5]						DEC(38,20)
	--Mandant 3
	, [Company3Due1]						DEC(38,20)
	, [Company3Due2]						DEC(38,20)
	, [Company3Due3]						DEC(38,20)
	, [Company3Due4]						DEC(38,20)
	, [Company3Due5]						DEC(38,20)
	--Mandant 4
	, [Company4Due1]						DEC(38,20)
	, [Company4Due2]						DEC(38,20)
	, [Company4Due3]						DEC(38,20)
	, [Company4Due4]						DEC(38,20)
	, [Company4Due5]						DEC(38,20)
)

--Grundstruktur mit Gesamtsummen	
INSERT INTO #RESULTS_EXCEL
SELECT  ROW_NUMBER() OVER (ORDER BY #RESULTS.[Customer_No])
	  , [Customer_No]
	  , [Customer_Name]
	  , [Chain]
	  , [Brand]
	  , [Hotel_Status]
	  , [Country_Name]
	  , [City]
	  , [Information]
	  , [Salesperson_Code]
	  , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue1] ELSE [CustBalanceDueLCY1] END)	
	  , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue2] ELSE [CustBalanceDueLCY2] END)	
	  , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue3] ELSE [CustBalanceDueLCY3] END)	
	  , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue4] ELSE [CustBalanceDueLCY4] END)	
	  , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue5] ELSE [CustBalanceDueLCY5] END)
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL	  	  	  
  FROM #RESULTS 
 WHERE  CustBalanceDue1 <> 0
	OR CustBalanceDue2 <> 0
	OR CustBalanceDue3 <> 0
	OR CustBalanceDue4 <> 0
	OR CustBalanceDue5 <> 0
GROUP BY [Customer_No], [Customer_Name], [Chain], [Brand], [Hotel_Status], [Country_Name], [City], [Information], [Salesperson_Code]
	
--Update Mandant 1	
UPDATE UPDATE_RESULTS_EXCEL1
   SET [Company1Due1] = _C1D1
	 , [Company1Due2] = _C1D2
	 , [Company1Due3] = _C1D3
	 , [Company1Due4] = _C1D4
	 , [Company1Due5] = _C1D5
  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL1
  JOIN (SELECT [Customer_No]																				AS _Customer_No
			 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue1] ELSE [CustBalanceDueLCY1] END)	AS _C1D1
			 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue2] ELSE [CustBalanceDueLCY2] END)	AS _C1D2
			 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue3] ELSE [CustBalanceDueLCY3] END)	AS _C1D3
			 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue4] ELSE [CustBalanceDueLCY4] END)	AS _C1D4
			 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue5] ELSE [CustBalanceDueLCY5] END)	AS _C1D5
		  FROM #RESULTS
		  JOIN #RESULTS_CompanyName
			ON #RESULTS.[CompanyName] = #RESULTS_CompanyName.[CompanyName]
		 WHERE #RESULTS_CompanyName.[RowNumber] = 1
	  GROUP BY [Customer_No]) RESULT_SUM
	ON RESULT_SUM._Customer_No = UPDATE_RESULTS_EXCEL1.Customer_No

--Update Mandant 2
IF @CountCompany >= 2  
BEGIN	
	UPDATE UPDATE_RESULTS_EXCEL2
	   SET [Company2Due1] = _C2D1
		 , [Company2Due2] = _C2D2
		 , [Company2Due3] = _C2D3
		 , [Company2Due4] = _C2D4
		 , [Company2Due5] = _C2D5
	  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL2
	  JOIN (SELECT [Customer_No]																				AS _Customer_No
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue1] ELSE [CustBalanceDueLCY1] END)	AS _C2D1
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue2] ELSE [CustBalanceDueLCY2] END)	AS _C2D2
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue3] ELSE [CustBalanceDueLCY3] END)	AS _C2D3
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue4] ELSE [CustBalanceDueLCY4] END)	AS _C2D4
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue5] ELSE [CustBalanceDueLCY5] END)	AS _C2D5
			  FROM #RESULTS
			  JOIN #RESULTS_CompanyName
				ON #RESULTS.[CompanyName] = #RESULTS_CompanyName.[CompanyName]
			 WHERE #RESULTS_CompanyName.[RowNumber] = 2
		  GROUP BY [Customer_No]) RESULT_SUM
		ON RESULT_SUM._Customer_No = UPDATE_RESULTS_EXCEL2.Customer_No	
END

--Update Mandant 3
IF @CountCompany >= 3  
BEGIN	
	UPDATE UPDATE_RESULTS_EXCEL3
	   SET [Company3Due1] = _C3D1
		 , [Company3Due2] = _C3D2
		 , [Company3Due3] = _C3D3
		 , [Company3Due4] = _C3D4
		 , [Company3Due5] = _C3D5
	  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL3
	  JOIN (SELECT [Customer_No]																				AS _Customer_No
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue1] ELSE [CustBalanceDueLCY1] END)	AS _C3D1
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue2] ELSE [CustBalanceDueLCY2] END)	AS _C3D2
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue3] ELSE [CustBalanceDueLCY3] END)	AS _C3D3
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue4] ELSE [CustBalanceDueLCY4] END)	AS _C3D4
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue5] ELSE [CustBalanceDueLCY5] END)	AS _C3D5
			  FROM #RESULTS
			  JOIN #RESULTS_CompanyName
				ON #RESULTS.[CompanyName] = #RESULTS_CompanyName.[CompanyName]
			 WHERE #RESULTS_CompanyName.[RowNumber] = 3
		  GROUP BY [Customer_No]) RESULT_SUM
		ON RESULT_SUM._Customer_No = UPDATE_RESULTS_EXCEL3.Customer_No
END
--Update Mandant 4
IF @CountCompany >= 4  
BEGIN	
	UPDATE UPDATE_RESULTS_EXCEL4
	   SET [Company4Due1] = _C4D1
		 , [Company4Due2] = _C4D2
		 , [Company4Due3] = _C4D3
		 , [Company4Due4] = _C4D4
		 , [Company4Due5] = _C4D5
	  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL4
	  JOIN (SELECT [Customer_No]																				AS _Customer_No
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue1] ELSE [CustBalanceDueLCY1] END)	AS _C4D1
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue2] ELSE [CustBalanceDueLCY2] END)	AS _C4D2
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue3] ELSE [CustBalanceDueLCY3] END)	AS _C4D3
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue4] ELSE [CustBalanceDueLCY4] END)	AS _C4D4
				 , SUM(CASE WHEN @PrintAmountsInLCY = 0 THEN [CustBalanceDue5] ELSE [CustBalanceDueLCY5] END)	AS _C4D5
			  FROM #RESULTS
			  JOIN #RESULTS_CompanyName
				ON #RESULTS.[CompanyName] = #RESULTS_CompanyName.[CompanyName]
			 WHERE #RESULTS_CompanyName.[RowNumber] = 4
		  GROUP BY [Customer_No]) RESULT_SUM
		ON RESULT_SUM._Customer_No = UPDATE_RESULTS_EXCEL4.Customer_No			
END		   					    
--[Excel Buffer 4 SSRS] vorbereiten

DELETE 
  FROM [Excel Buffer 4 SSRS]
 WHERE [Report ID]		= @ReportId
   AND [ConnectionID]	= @ConnectionID
   AND [USERID]			= @UserId


--[Excel Buffer 4 SSRS] füllen
--Überschriften
INSERT INTO [Excel Buffer 4 SSRS]
  VALUES
  (NULL, 2,  1 , @ReportId, @ConnectionID, @UserId, '2', 'A', 'Kunden Nr.'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  2 , @ReportId, @ConnectionID, @UserId, '2', 'B', 'Kunden Name'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  3 , @ReportId, @ConnectionID, @UserId, '2', 'C', 'Chain'			, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  4 , @ReportId, @ConnectionID, @UserId, '2', 'D', 'Brand'			, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  5 , @ReportId, @ConnectionID, @UserId, '2', 'E', 'Hotel Status'	, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  6 , @ReportId, @ConnectionID, @UserId, '2', 'F', 'Land'	        , '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  7 , @ReportId, @ConnectionID, @UserId, '2', 'G', 'Stadt'			, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  8 , @ReportId, @ConnectionID, @UserId, '2', 'H', 'Information'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2,  9 , @ReportId, @ConnectionID, @UserId, '2', 'I', 'Verkäufer'		, '', '', 1, 0, 0, '', '', '', '')
--Gesamt
, (NULL, 1, 10 , @ReportId, @ConnectionID, @UserId, '1', 'J', 'Gesamtsumme'		, '', '', 1, 0, 0, '', '', '', '') 
, (NULL, 2, 10 , @ReportId, @ConnectionID, @UserId, '2', 'J', 'nicht fällig'	, '', '', 1, 0, 0, '', '', '', '')  
, (NULL, 2, 11 , @ReportId, @ConnectionID, @UserId, '2', 'K', '0-30 Tage'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 12 , @ReportId, @ConnectionID, @UserId, '2', 'L', '31-60 Tage'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 13 , @ReportId, @ConnectionID, @UserId, '2', 'M', '61-90 Tage'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 14 , @ReportId, @ConnectionID, @UserId, '2', 'N', 'über 90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
--Mandant 1
, (NULL, 1, 15 , @ReportId, @ConnectionID, @UserId, '1', 'O', 'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																		  WHERE #RESULTS_CompanyName.[RowNumber] = 1)	, '', '', 1, 0, 0, '', '', '', '') 
, (NULL, 2, 15 , @ReportId, @ConnectionID, @UserId, '2', 'O', 'nicht fällig'	, '', '', 1, 0, 0, '', '', '', '')  
, (NULL, 2, 16 , @ReportId, @ConnectionID, @UserId, '2', 'P', '0-30 Tage'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 17 , @ReportId, @ConnectionID, @UserId, '2', 'Q', '31-60 Tage'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 18 , @ReportId, @ConnectionID, @UserId, '2', 'R', '61-90 Tage'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 19 , @ReportId, @ConnectionID, @UserId, '2', 'S', 'über 90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
--Mandant 2
IF @CountCompany >= 2  
BEGIN
	INSERT INTO [Excel Buffer 4 SSRS]
	  VALUES
	  (NULL, 1, 20, @ReportId, @ConnectionID, @UserId, '1', 'T',  'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																			   WHERE #RESULTS_CompanyName.[RowNumber] = 2)	, '', '', 1, 0, 0, '', '', '', '') 
	, (NULL, 2, 20, @ReportId, @ConnectionID, @UserId, '2', 'T', 'nicht fällig'	, '', '', 1, 0, 0, '', '', '', '')  
	, (NULL, 2, 21, @ReportId, @ConnectionID, @UserId, '2', 'U', '0-30 Tage'	, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 22, @ReportId, @ConnectionID, @UserId, '2', 'V', '31-60 Tage'	, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 23, @ReportId, @ConnectionID, @UserId, '2', 'W', '61-90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 24, @ReportId, @ConnectionID, @UserId, '2', 'X', 'über 90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
END
--Mandant 3
IF @CountCompany >= 3  
BEGIN
	INSERT INTO [Excel Buffer 4 SSRS]
	  VALUES
	  (NULL, 1, 25, @ReportId, @ConnectionID, @UserId, '1', 'Y',  'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																			   WHERE #RESULTS_CompanyName.[RowNumber] = 3)	, '', '', 1, 0, 0, '', '', '', '') 
	, (NULL, 2, 25, @ReportId, @ConnectionID, @UserId, '2', 'Y', 'nicht fällig'		, '', '', 1, 0, 0, '', '', '', '')  
	, (NULL, 2, 26, @ReportId, @ConnectionID, @UserId, '2', 'Z', '0-30 Tage'		, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 27, @ReportId, @ConnectionID, @UserId, '2', 'AA', '31-60 Tage'		, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 28, @ReportId, @ConnectionID, @UserId, '2', 'AB', '61-90 Tage'		, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 29, @ReportId, @ConnectionID, @UserId, '2', 'AC', 'über 90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
END
--Mandant 4
IF @CountCompany >= 4   
BEGIN
	INSERT INTO [Excel Buffer 4 SSRS]
	  VALUES
	  (NULL, 1, 30, @ReportId, @ConnectionID, @UserId, '1', 'AD',  'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																			   WHERE #RESULTS_CompanyName.[RowNumber] = 4)	, '', '', 1, 0, 0, '', '', '', '') 
	, (NULL, 2, 30, @ReportId, @ConnectionID, @UserId, '2', 'AD', 'nicht fällig'	, '', '', 1, 0, 0, '', '', '', '')  
	, (NULL, 2, 31, @ReportId, @ConnectionID, @UserId, '2', 'AE', '0-30 Tage'	, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 32, @ReportId, @ConnectionID, @UserId, '2', 'AF', '31-60 Tage'	, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 33, @ReportId, @ConnectionID, @UserId, '2', 'AG', '61-90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
	, (NULL, 2, 34, @ReportId, @ConnectionID, @UserId, '2', 'AH','über 90 Tage'	, '', '', 1, 0, 0, '', '', '', '')
END

--Spalte 1: Kunden Nr.  
INSERT INTO [Excel Buffer 4 SSRS]
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 1
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2	
	, xlColID					= 'A'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Customer_No]
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL 

	
--Spalte 2: Kunden Name
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 2
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'B'	
	, [Cell Value as Text]		= SUBSTRING(#RESULTS_EXCEL.[Customer_Name],1,250)
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 3: Chain
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 3
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'C'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Chain]
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 4: Brand
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 4
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'D'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Brand]
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 5: Hotel Status
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 5
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'E'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Hotel_Status]
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 6: Land
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 6
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'F'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Country_Name]
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 7: Stadt
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 7
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'G'	
	, [Cell Value as Text]		= SUBSTRING(#RESULTS_EXCEL.[City],1,250)
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 8: Stadt
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 8
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'H'	
	, [Cell Value as Text]		= SUBSTRING(#RESULTS_EXCEL.[Information],1,250)
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 9: Information
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 9
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'I'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Salesperson_Code]
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= ''
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 10: SUMME 1 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 10
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'J'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[SUMDue5],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMDue5],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMDue1]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 11: SUMME 2 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 11
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'K'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[SUMDue4],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMDue4],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMDue2]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 12: SUMME 3 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 12
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'L'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[SUMDue3],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMDue3],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMDue3]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 13: SUMME 4 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 13
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'M'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[SUMDue2],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMDue2],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMDue4]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 14: SUMME 5 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 14
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'N'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[SUMDue1],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMDue1],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMDue5]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 15: SUMME 1 Mandant1
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 15
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'O'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company1Due5],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1Due5] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1Due1]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 16: SUMME 2 Mandant1
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 16
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'P'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company1Due4],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1Due4] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1Due2]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 17: SUMME 3 Mandant1
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 17
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'Q'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company1Due3],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1Due3] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1Due3]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 18: SUMME 4 Mandant1
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 18
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'R'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company1Due2],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1Due2] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1Due4]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

--Spalte 19: SUMME 5 Mandant1
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 19
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'S'
	, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company1Due1],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1Due1] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1Due5]) + 2),'.',','), '0')
	, Comment					= ''	
	, Formula					= ''	
	, Bold						= 0
	, Italic					= 0
	, Underline					= 0
	, NumberFormat				= '#.##0,00'
	, Formula2					= ''
	, Formula3					= ''
	, Formula4					= ''
FROM #RESULTS_EXCEL

IF @CountCompany >= 2   
BEGIN
	--Spalte 20: SUMME 1 Mandant2
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 20
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'T'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company2Due5],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2Due5] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2Due1]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 21: SUMME 2 Mandant 2
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 21
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'U'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company2Due4],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2Due4] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2Due2]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 22: SUMME 3 Mandant 2
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 22
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'V'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company2Due3],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2Due3] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2Due3]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 23: SUMME 4 Mandant 2
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 23
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'W'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company2Due2],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2Due2] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2Due4]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 24: SUMME 5 Mandant 2
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 24
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'X'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company2Due1],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2Due1] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2Due5]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
FROM #RESULTS_EXCEL
END

IF @CountCompany >= 3   
BEGIN
	--Spalte 25: SUMME 1 Mandant 3
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 25
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'Y'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company3Due5],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3Due5] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3Due1]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 26: SUMME 2 Mandant 3
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 26
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'Z'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company3Due4],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3Due4] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3Due2]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 27: SUMME 3 Mandant 3
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 27
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AA'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company3Due3],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3Due3] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3Due3]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 28: SUMME 4 Mandant 3
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 28
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AB'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company3Due2],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3Due2] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3Due4]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 29: SUMME 5 Mandant 3
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 29
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AC'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company3Due1],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3Due1] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3Due5]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL
END

IF @CountCompany >= 4   
BEGIN
	--Spalte 30: SUMME 1 Mandant 4
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 30
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AD'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company4Due5],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4Due5] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4Due1]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 31: SUMME 2 Mandant 4
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 31
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AE'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company4Due4],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4Due4] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4Due2]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 32: SUMME 3 Mandant 4
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 32
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AF'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company4Due3],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4Due3] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4Due3]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 33: SUMME 4 Mandant 4
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 33
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AG'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company4Due2],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4Due2] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4Due4]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL

	--Spalte 34: SUMME 5 Mandant 4
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 34
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'AH'
		, [Cell Value as Text]		= REPLACE(CAST(COALESCE(#RESULTS_EXCEL.[Company4Due1],0) AS VARCHAR(250)),'.',',') --COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4Due1] ,2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4Due5]) + 2),'.',','), '0')
		, Comment					= ''	
		, Formula					= ''	
		, Bold						= 0
		, Italic					= 0
		, Underline					= 0
		, NumberFormat				= '#.##0,00'
		, Formula2					= ''
		, Formula3					= ''
		, Formula4					= ''
	FROM #RESULTS_EXCEL
END

DROP TABLE #RESULTS_EXCEL

END --Excelausgabe
--<<RP1

SELECT * FROM #RESULTS 
WHERE  CustBalanceDue1 <> 0
	OR CustBalanceDue2 <> 0
	OR CustBalanceDue3 <> 0
	OR CustBalanceDue4 <> 0
	OR CustBalanceDue5 <> 0
ORDER BY [Sort_Customer_No], [CompanyName]

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
