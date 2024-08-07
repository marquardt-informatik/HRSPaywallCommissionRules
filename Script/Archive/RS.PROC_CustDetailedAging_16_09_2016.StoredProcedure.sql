USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustDetailedAging_16_09_2016]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Ralph Prangenberg
-- Create date: 06.06.2011
-- Description:	Nav Report 50136
--				Debitor - Fällige Posten
--				In der Requestform können die Parameter @EndDate, @MindestsaldoMW und @MaximalSaldoMW angegeben werden.
--				Wenn @MindestsaldoMW oder @MaximalSaldoMW einen Wert beinhalten wird Customer_BalanceDueLCY_Check_ erzeugt und mit JOIN eingebunden.
-- 23.01.12 RP1 Befüllen einer mandantenübergreifender Tabelle für den Excelexport
--				aus NAV
-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50136
		, @EndDate					DATETIME		= '06.05.2015'
		, @MindestsaldoMW			VARCHAR(20)		= 0
		, @MaximalSaldoMW			VARCHAR(20)		= 0
		, @OnlyOpen					INT				= 0	
EXEC [RS].[PROC_CustDetailedAging] @UserId, @CompanyName, @ReportId, @EndDate, @MindestsaldoMW, @MaximalSaldoMW, @OnlyOpen
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustDetailedAging_16_09_2016] 
(
	  @UserId					VARCHAR(20)
	, @CompanyName			VARCHAR(30)
	, @ReportId					INT
	, @EndDate					DATETIME
	, @MindestsaldoMW			VARCHAR(20) 
	, @MaximalSaldoMW			VARCHAR(20) 
	, @OnlyOpen					INT
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
		, @EndDateVAR				VARCHAR(10)	
		, @Filter_GloDim1			VARCHAR(MAX)		
		, @Filter_GloDim2			VARCHAR(MAX)
		, @Filter_Currency			VARCHAR(MAX)
		, @TableIDs					[RS].[TableIDs]
		, @TableID2					[RS].[TableIDs]

--BEGIN Filter aus den FlowFilter
SET @DateFilterStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 0, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 55), '01.01.1753'), 104);

SET @DateFilterEnd = CONVERT(VARCHAR(10), COALESCE(						 
	(SELECT SUBSTRING([Filter Value], 13, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 55), '31.12.2999'), 104);

--für den Check
SET @EndDateVAR = CONVERT( VARCHAR(10), COALESCE(@EndDate, '31.12.2999'), 104);						 
--Stimmt das wirklich?
SET @DateFilterEnd = @EndDateVAR

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
	, [Customer_Name2]						VARCHAR(70)
	, [Customer_PostCode]					VARCHAR(20)
	, [Customer_City]						VARCHAR(70)
	, [Customer_Address]					VARCHAR(130)
	, [Customer_FaxNo]						VARCHAR(30)
	, [CustLedgerEntry_EntryNo]				int
	, [CustLedgerEntry_PostingDate]			DATETIME
	, [CustLedgerEntry_DocumentNo]			VARCHAR(50)
	, [CustLedgerEntry_Description]			VARCHAR(70)
	, [CustLedgerEntry_DueDate]				DATETIME
	, [OverDueMonth]						INT
	, [CustLedgerEntry_CurrencyCode]		VARCHAR(10)
	, [RemAmount]							DEC(38,20)
	, [RemAmountLCY]						DEC(38,20)	
	, [Sort_Customer_No]					VARCHAR(20)
-->>RP1	
	, [Brand]								VARCHAR(10)	
	, [Chain]								VARCHAR(10)		
	, [Country_Code]						VARCHAR(10)
	, [Country_Name]						VARCHAR(50)
	, [Contract_Status]						VARCHAR(50)
--<<RP1
)
--1ter Teile
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES (18, 'Customer')
     , (21, 'Cust_ Ledger Entry')
	 , (379,'Detailed Cust_ Ledg_ Entry')

--SELECT * FROM @TableIDs

PRINT [RS].[Nav2SqlString](@UserId, 'HRS', @ReportId, @TableIDs, 2)

SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN '; WITH 'ELSE ' , ' END)
+'
[DetailedCustLedgEntry_RemAmount_SUM_'+[CompanyName]+'] AS (
	SELECT [Cust_ Ledger Entry No_]
		 , SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]) [Rem Amount]
		 , SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]) [Rem Amount (LCY)]
	  FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry]
	  JOIN ['+[CompanyName]+'$Customer] 
		ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Customer No_]													 
	  JOIN ['+[CompanyName]+'$Cust_ Ledger Entry] 			
		ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_] = ['+[CompanyName]+'$Customer].[No_]
	   AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Cust_ Ledger Entry No_]
	   AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Due Date] <= '''+@EndDateVAR+'''											  	   
	 WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Posting Date] <= '''+@EndDateVAR+'''
		   '+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 2) +'
      '		+CASE WHEN ((@Filter_GloDim1 IS NOT NULL) AND (@Filter_GloDim1 != '')) 
				  THEN +' AND '+[RS].[Nav2SqlFiltersSimple]('['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Global Dim_ 1]', @Filter_GloDim1, 1)
				  ELSE '' 
			 END
			+CASE WHEN ((@Filter_GloDim2 IS NOT NULL) AND (@Filter_GloDim2 != '')) 
				  THEN +' AND '+[RS].[Nav2SqlFiltersSimple]('['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Initial Entry Global Dim_ 2]', @Filter_GloDim2, 1) 
				  ELSE '' 
			 END
			 +CASE WHEN ((@Filter_Currency IS NOT NULL) AND (@Filter_Currency != '')) 
				  THEN +' AND '+[RS].[Nav2SqlFiltersSimple]('['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Currency Code]', @Filter_Currency, 1) 
				  ELSE '' 
			 END
			+'												 
   GROUP BY [Cust_ Ledger Entry No_])'

	   
+(CASE WHEN (@MindestsaldoMW <> 0) OR (@MaximalSaldoMW <> 0)
	   THEN
			'
			, [Customer_BalanceDueLCY_Check_'+[CompanyName]+'] AS 
					(SELECT X1.[Customer No_]
						, (CASE WHEN (((X1.[BalanceDueLCY] > '+@MindestsaldoMW+') AND ('+@MindestsaldoMW+' <> 0))
								  OR  ((X1.[BalanceDueLCY] < '+@MaximalSaldoMW+') AND ('+@MaximalSaldoMW+' <> 0)))
								THEN X1.[BalanceDueLCY] 
								ELSE 0
						   END)  [BalanceDueLCY]
					  FROM (			
					
					(SELECT ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_]			[Customer No_]
						  , SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)])	[BalanceDueLCY]	 				  
					   FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3]
					   JOIN ['+[CompanyName]+'$Customer] 
						 ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_]
					  WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Posting Date] <= '''+@EndDateVAR+'''  	
							'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 2) +'													   
				   		'	 +CASE WHEN ((@Filter_Currency IS NOT NULL) AND (@Filter_Currency != '')) 
								   THEN +' AND '+[RS].[Nav2SqlFiltersSimple]('['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Currency Code]', @Filter_Currency, 1) 
								   ELSE '' 
							  END
							+'
				   GROUP BY [Customer No_])) X1)'
	   ELSE ''
  END)	   

	   	   
FROM #RESULTS_CompanyName
ORDER BY RowNumber 	


--2ter Teil					   
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' 
UNION ALL ' END)	
+'	 
	SELECT '''+[CompanyName]+'''
		 , COALESCE(['+[CompanyName]+'$Contact].[No_],['+[CompanyName]+'$Customer].[No_]) [No_]
		 , COALESCE(['+[CompanyName]+'$Contact].[Name],['+[CompanyName]+'$Customer].[Name]) [Name]
		 , COALESCE(['+[CompanyName]+'$Contact].[Name 2],['+[CompanyName]+'$Customer].[Name 2]) [Name 2]
		 , COALESCE(['+[CompanyName]+'$Contact].[Post Code],['+[CompanyName]+'$Customer].[Post Code]) [Post Code]
		 , COALESCE(['+[CompanyName]+'$Contact].[City],['+[CompanyName]+'$Customer].[City]) [City]
		 , COALESCE(['+[CompanyName]+'$Contact].[Address],['+[CompanyName]+'$Customer].[Address]) [Address]
		 , COALESCE(['+[CompanyName]+'$Customer].[Fax No_],['+[CompanyName]+'$Customer].[Fax No_]) [Fax No_]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Posting Date]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Document No_]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Description]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Due Date]
		 , (CASE WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Due Date] <> '''+'01.01.1753'+''' 
				 THEN DATEDIFF(mm, ['+[CompanyName]+'$Cust_ Ledger Entry].[Due Date], '''+@EndDateVAR+''')
		   END)
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Currency Code]
		 , [DetailedCustLedgEntry_RemAmount_SUM].[Rem Amount]
		 , [DetailedCustLedgEntry_RemAmount_SUM].[Rem Amount (LCY)]		 
		 , REPLACE(SPACE(20-LEN(['+[CompanyName]+'$Customer].[No_])), '''+' '+''' , '''+'0'+''') + LTRIM(['+[CompanyName]+'$Customer].[No_])			   		 
		 , ['+[CompanyName]+'$Customer].[Brand]
		 , ['+[CompanyName]+'$Customer].[Chain]
		 , ['+[CompanyName]+'$Country_Region].[Code] [Country_Code]
		 , ['+[CompanyName]+'$Country_Region].[Name] [Country_Name]
		 , COALESCE(['+[CompanyName]+'$Dimension Value].[Name],'''') [Contract_Status]
	  FROM ['+[CompanyName]+'$Customer]
 LEFT JOIN ['+[CompanyName]+'$Contact] 	
	    ON ['+[CompanyName]+'$Contact].[No_] = ['+[CompanyName]+'$Customer].[No_]
	  JOIN ['+[CompanyName]+'$Country_Region] 	
	    ON ['+[CompanyName]+'$Country_Region].[Code] = COALESCE(['+[CompanyName]+'$Contact].[Country_Region Code],['+[CompanyName]+'$Customer].[Country_Region Code])
	  JOIN ['+[CompanyName]+'$Cust_ Ledger Entry] 			
	    ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_] = ['+[CompanyName]+'$Customer].[No_]
 LEFT JOIN ['+[CompanyName]+'$Dimension Value]
        ON ['+[CompanyName]+'$Dimension Value].[Dimension Code] = ''CONTRACT STATUS''
       AND ['+[CompanyName]+'$Dimension Value].[Code] = ['+[CompanyName]+'$Customer].[Contract Status] 										 
      JOIN [DetailedCustLedgEntry_RemAmount_SUM_'+[CompanyName]+'] [DetailedCustLedgEntry_RemAmount_SUM]
	    ON [DetailedCustLedgEntry_RemAmount_SUM].[Cust_ Ledger Entry No_] = ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]		
	   AND [DetailedCustLedgEntry_RemAmount_SUM].[Rem Amount] <> 0 												 
			'+(CASE WHEN (@MindestsaldoMW <> 0) OR (@MaximalSaldoMW <> 0)
				    THEN ' JOIN [Customer_BalanceDueLCY_Check_'+[CompanyName]+']
							 ON [Customer_BalanceDueLCY_Check_'+[CompanyName]+'].[Customer No_] = ['+[CompanyName]+'$Customer].[No_]
							AND [Customer_BalanceDueLCY_Check_'+[CompanyName]+'].[BalanceDueLCY] <> 0'
					ELSE ''		 
			   END)+'	   
 	 WHERE (1=1)
	   AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Due Date] <= '''+@EndDateVAR+'''
	   AND (('+CAST(@OnlyOpen AS VARCHAR)+' = 0) OR (['+[CompanyName]+'$Cust_ Ledger Entry].[Open] = 1)) 	 
 	 '+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 2)	 		 	 
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
PRINT	SUBSTRING(@Stmt,16001,24000)
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
	, [Brand]								VARCHAR(10)
	, [Chain]								VARCHAR(10)
	, [Country_Code]						VARCHAR(10)
	, [Country_Name]						VARCHAR(50)
	, [Customer_City]						VARCHAR(70)
	, [Contract_Status]						VARCHAR(50)
	, [SUMRemAmount]						DEC(38,20)
	, [SUMRemAmountLCY]						DEC(38,20)		
	--Mandant 1
	, [Company1RemAmount]					DEC(38,20)
	, [Company1RemAmountLCY]				DEC(38,20)		
	--Mandant 2
	, [Company2RemAmount]					DEC(38,20)
	, [Company2RemAmountLCY]				DEC(38,20)		
	--Mandant 3
	, [Company3RemAmount]					DEC(38,20)
	, [Company3RemAmountLCY]				DEC(38,20)		
	--Mandant 4
	, [Company4RemAmount]					DEC(38,20)
	, [Company4RemAmountLCY]				DEC(38,20)	
)
--Grundstruktur mit Gesamtsummen	
INSERT INTO #RESULTS_EXCEL
SELECT  ROW_NUMBER() OVER (ORDER BY #RESULTS.[Customer_No])
	  , [Customer_No]
	  , [Customer_Name]
	  , [Brand]
	  , [Chain]
	  , [Country_Code]
	  , [Country_Name]
	  , [Customer_City]
	  , [Contract_Status]
	  , SUM([RemAmount]	)
	  , SUM([RemAmountLCY])	
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
	  , NULL
  FROM #RESULTS 
GROUP BY [Customer_No], [Customer_Name], [Brand], [Chain], [Country_Code], [Country_Name], [Customer_City], [Contract_Status]	

--Update Mandant 1	
UPDATE UPDATE_RESULTS_EXCEL1
   SET [Company1RemAmount]		= _C1RA
	 , [Company1RemAmountLCY]	= _C1RALCY
  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL1
  JOIN (SELECT [Customer_No]		AS _Customer_No
			 , SUM([RemAmount])		AS _C1RA
			 , SUM([RemAmountLCY])	AS _C1RALCY
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
	   SET [Company2RemAmount]		= _C2RA
		 , [Company2RemAmountLCY]	= _C2RALCY
	  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL2
	  JOIN (SELECT [Customer_No]	AS _Customer_No
			 , SUM([RemAmount])		AS _C2RA
			 , SUM([RemAmountLCY])	AS _C2RALCY			  
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
	   SET [Company3RemAmount]		= _C3RA
		 , [Company3RemAmountLCY]	= _C3RALCY
	  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL3
	  JOIN (SELECT [Customer_No]	AS _Customer_No
			 , SUM([RemAmount])		AS _C3RA
			 , SUM([RemAmountLCY])	AS _C3RALCY			  
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
	   SET [Company4RemAmount]		= _C4RA
		 , [Company4RemAmountLCY]	= _C4RALCY
	  FROM #RESULTS_EXCEL UPDATE_RESULTS_EXCEL4
	  JOIN (SELECT [Customer_No]	AS _Customer_No
			 , SUM([RemAmount])		AS _C4RA
			 , SUM([RemAmountLCY])	AS _C4RALCY			  
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
  (NULL, 2, 1 , @ReportId, @ConnectionID, @UserId, '2', 'A', 'Kunden Nr.'	, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 2 , @ReportId, @ConnectionID, @UserId, '2', 'B', 'Kunden Name'	, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 3 , @ReportId, @ConnectionID, @UserId, '2', 'C', 'Brand'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 4 , @ReportId, @ConnectionID, @UserId, '2', 'D', 'Chain'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 5 , @ReportId, @ConnectionID, @UserId, '2', 'E', 'Country'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 6 , @ReportId, @ConnectionID, @UserId, '2', 'F', 'City'	         , '', '', 1, 0, 0, '', '', '', '')
, (NULL, 2, 7 , @ReportId, @ConnectionID, @UserId, '2', 'G', 'Vertragsstatus', '', '', 1, 0, 0, '', '', '', '')
--Gesamt
, (NULL, 1, 8 , @ReportId, @ConnectionID, @UserId, '1', 'H', 'Gesamtsumme'	, '', '', 1, 0, 0, '', '', '', '') 
, (NULL, 2, 8 , @ReportId, @ConnectionID, @UserId, '2', 'H', 'Restbetrag'	, '', '', 1, 0, 0, '', '', '', '')  
, (NULL, 2, 9 , @ReportId, @ConnectionID, @UserId, '2', 'I', 'Restbetrag (MW)', '', '', 1, 0, 0, '', '', '', '')
--Mandant 1
, (NULL, 1, 10 , @ReportId, @ConnectionID, @UserId, '1', 'J', 'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																		  WHERE #RESULTS_CompanyName.[RowNumber] = 1)	, '', '', 1, 0, 0, '', '', '', '') 
, (NULL, 2, 10 , @ReportId, @ConnectionID, @UserId, '2', 'J', 'Restbetrag'	  , '', '', 1, 0, 0, '', '', '', '')  
, (NULL, 2, 11 , @ReportId, @ConnectionID, @UserId, '2', 'K', 'Restbetrag (MW)', '', '', 1, 0, 0, '', '', '', '')
--Mandant 2
IF @CountCompany >= 2  
BEGIN
	INSERT INTO [Excel Buffer 4 SSRS]
	  VALUES
	  (NULL, 1, 12, @ReportId, @ConnectionID, @UserId, '1', 'L',  'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																			  WHERE #RESULTS_CompanyName.[RowNumber] = 2)	, '', '', 1, 0, 0, '', '', '', '') 
	, (NULL, 2, 12, @ReportId, @ConnectionID, @UserId, '2', 'L', 'Restbetrag'	  , '', '', 1, 0, 0, '', '', '', '')  
	, (NULL, 2, 13, @ReportId, @ConnectionID, @UserId, '2', 'M', 'Restbetrag (MW)', '', '', 1, 0, 0, '', '', '', '')
END
--Mandant 3
IF @CountCompany >= 3  
BEGIN
	INSERT INTO [Excel Buffer 4 SSRS]
	  VALUES
	  (NULL, 1, 14, @ReportId, @ConnectionID, @UserId, '1', 'N',  'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																			   WHERE #RESULTS_CompanyName.[RowNumber] = 3)	, '', '', 1, 0, 0, '', '', '', '') 
	, (NULL, 2, 14, @ReportId, @ConnectionID, @UserId, '2', 'N', 'Restbetrag'	  , '', '', 1, 0, 0, '', '', '', '')  
	, (NULL, 2, 15, @ReportId, @ConnectionID, @UserId, '2', 'O', 'Restbetrag (MW)', '', '', 1, 0, 0, '', '', '', '')
END
--Mandant 4
IF @CountCompany >= 4   
BEGIN
	INSERT INTO [Excel Buffer 4 SSRS]
	  VALUES
	  (NULL, 1, 16, @ReportId, @ConnectionID, @UserId, '1', 'P',  'Summe ' + (SELECT #RESULTS_CompanyName.CompanyName FROM #RESULTS_CompanyName
																			   WHERE #RESULTS_CompanyName.[RowNumber] = 4)	, '', '', 1, 0, 0, '', '', '', '') 
	, (NULL, 2, 16, @ReportId, @ConnectionID, @UserId, '2', 'P', 'Restbetrag'	  , '', '', 1, 0, 0, '', '', '', '')  
	, (NULL, 2, 17, @ReportId, @ConnectionID, @UserId, '2', 'Q', 'Restbetrag (MW)', '', '', 1, 0, 0, '', '', '', '')
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
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Customer_Name]
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

--Spalte 3: Brand
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 3
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'C'	
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

--Spalte 4: Chain
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 4
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'D'	
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

--Spalte 5: Contry_Code
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 5
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'E'	
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

--Spalte 6: Country_Name
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 6
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'F'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Customer_City] 
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

--Spalte 7: Contract_Status
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 7
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'G'	
	, [Cell Value as Text]		= #RESULTS_EXCEL.[Contract_Status] 
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

--Spalte 8: SUMME 1 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 8
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'H'
	, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMRemAmount],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMRemAmount]) + 2),'.',','), '0')
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

--Spalte 9: SUMME 2 über alle Mandanten
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 9
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'I'
	, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[SUMRemAmountLCY],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[SUMRemAmountLCY]) + 2),'.',','), '0')
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

--Spalte 10: Mandant 1 [Company1RemAmount]
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 10
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'J'
	, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1RemAmount],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1RemAmount]) + 2),'.',','), '0')
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

--Spalte 11: Mandant 1 [Company1RemAmountLCY]
INSERT INTO [Excel Buffer 4 SSRS] 
SELECT [timestamp]				= NULL
	, [Row No_]					= _ROW_NUMBER + 2
	, [Column No_]				= 11
	, [Report ID]				= @ReportId		
	, [ConnectionID]			= @ConnectionID
	, [USERID]					= @UserId	
	, xlRowID					= _ROW_NUMBER + 2
	, xlColID					= 'K'
	, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company1RemAmountLCY],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company1RemAmountLCY]) + 2),'.',','), '0')
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

IF @CountCompany >= 2   
BEGIN
	--Spalte 12: Mandant 2 [Company2RemAmount]
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 12
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'L'
		, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2RemAmount],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2RemAmount]) + 2),'.',','), '0')
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

	--Spalte 13: Mandant 2 [Company2RemAmountLCY]
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 13
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'M'
		, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company2RemAmountLCY],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company2RemAmountLCY]) + 2),'.',','), '0')
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
END	

IF @CountCompany >= 3   
BEGIN
	--Spalte 14: Mandant 3 [Company3RemAmount]
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 14
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'N'
		, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3RemAmount],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3RemAmount]) + 2),'.',','), '0')
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

	--Spalte 15: Mandant 3 [Company3RemAmountLCY]
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 15
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'O'
		, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company3RemAmountLCY],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company3RemAmountLCY]) + 2),'.',','), '0')
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
END	

IF @CountCompany >= 4   
BEGIN
	--Spalte 16: Mandant 4 [Company4RemAmount]
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 16
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'P'
		, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4RemAmount],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4RemAmount]) + 2),'.',','), '0')
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

	--Spalte 17: Mandant 4 [Company4RemAmountLCY]
	INSERT INTO [Excel Buffer 4 SSRS] 
	SELECT [timestamp]				= NULL
		, [Row No_]					= _ROW_NUMBER + 2
		, [Column No_]				= 17
		, [Report ID]				= @ReportId		
		, [ConnectionID]			= @ConnectionID
		, [USERID]					= @UserId	
		, xlRowID					= _ROW_NUMBER + 2
		, xlColID					= 'Q'
		, [Cell Value as Text]		= COALESCE(REPLACE(SUBSTRING(CAST(ROUND(#RESULTS_EXCEL.[Company4RemAmountLCY],2) AS VARCHAR),1,CHARINDEX('.',#RESULTS_EXCEL.[Company4RemAmountLCY]) + 2),'.',','), '0')
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
END	

DROP TABLE #RESULTS_EXCEL
END --Excelausgabe
--<<RP1

SELECT * FROM #RESULTS 
ORDER BY [Sort_Customer_No], [CompanyName]

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
