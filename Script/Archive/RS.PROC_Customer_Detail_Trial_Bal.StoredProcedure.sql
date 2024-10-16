USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_Customer_Detail_Trial_Bal]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Ralph Prangenberg
-- Create date: 06.06.2011
-- Description:	Nav Report 104
--				Debitor - Kontoblatt


-- 
/*CONVERT(datetime, '+@DATE+', 103))
DECLARE   @UserId				VARCHAR(20)			= 'RALPH'
		, @StartCompanyName		VARCHAR(30)			= 'CRONUS AG' 
		, @ReportId				INT					= 50134
		, @ExcludeBalanceOnly	INT					= 0
		, @ContractStatusFilter		VARCHAR(250)	= ''
		, @ContractChainFilter		VARCHAR(250)	= ''
		, @ContractBrandFilter		VARCHAR(250)	= ''
		, @BlockedforfurtherpFilter	VARCHAR(250)	= ''
EXEC [RS].[PROC_Customer_Detail_Trial_Bal] @UserId, @StartCompanyName, @ReportId, @ExcludeBalanceOnly, @ContractStatusFilter
						, @ContractChainFilter, @ContractBrandFilter, @BlockedforfurtherpFilter  
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_Customer_Detail_Trial_Bal] 
(
	  @UserId					VARCHAR(20)
	, @StartCompanyName			VARCHAR(30)
	, @ReportId					INT
	, @ExcludeBalanceOnly		INT
	, @ContractStatusFilter		VARCHAR(250)
	, @ContractChainFilter		VARCHAR(250)
	, @ContractBrandFilter		VARCHAR(250)
	, @BlockedforfurtherpFilter	VARCHAR(250)
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE   @Stmt					VARCHAR(MAX) = '' 
		, @StmtCompanyName		VARCHAR(MAX) = ''
		, @Filter				VARCHAR(MAX) = ''
		, @StartDate			DATETIME
		, @EndDate				DATETIME
		, @Filter_GloDim1		VARCHAR(MAX)		
		, @Filter_GloDim2		VARCHAR(MAX)
		, @Filter_Currency		VARCHAR(MAX)
		, @TableIDs					[RS].[TableIDs]

--BEGIN Filter aus den FlowFilter
SET @StartDate = CONVERT(date,COALESCE(
	(SELECT SUBSTRING([Filter Value], 0, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @StartCompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
		AND [Field ID]  = 55), '01.01.1753'), 104);	    

SET @EndDate = CONVERT(date,COALESCE(
	(SELECT SUBSTRING([Filter Value], 13, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @StartCompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 55), '31.12.2999'), 104);	    

SET @Filter_GloDim1 = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @StartCompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 56)	  

SET @Filter_GloDim2 = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @StartCompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 57)

SET @Filter_Currency = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @StartCompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 111)	
--Ship-to-Filter nicht beachtet!	        	   
--ENDE Filter aus FlowFilter
PRINT @Filter_GloDim1

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
WHERE (1=1)' 
+ [RS].[Nav2SqlString](@UserId, @StartCompanyName, @ReportId, @TableIDs, 0)

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
	, [Customer_PhoneNo]					VARCHAR(30)
	, [CustLedgerEntry_EntryNo]				int
	, [CustLedgerEntry_PostingDate]			DATETIME
	, [CustLedgerEntry_DocumentType]		INT
	, [CustLedgerEntry_DocumentTypeName]	VARCHAR(20)
	, [CustLedgerEntry_DocumentNo]			VARCHAR(50)
	, [CustLedgerEntry_Description]			VARCHAR(70)
	, [CustLedgerEntry_CurrencyCode]		VARCHAR(10)
	, [Amount]								DEC(38,20)		--CustAmount
	, [AmountLCY]							DEC(38,20)		--CustAmount
	, [RemAmount]							DEC(38,20)		--CustRemainAmount
	, [RemAmountLCY]						DEC(38,20)		--CustRemainAmount
	, [CustBalanceLCY]						DEC(38,20)		--Ist der Saldo(MW)
	, [Customer_StartBalanceLCY]			DEC(38,20)		--StartBalanceLCY; Summe pro Customer
	, [Customer_StartBalAdjLCY]				DEC(38,20)		--StartBalAdjLCY; Summe pro Customer
	, [DetailedCustLedgEntry_Correction]	DEC(38,20)		--Entry Type 11
	, [DetailedCustLedgEntry_ApplRounding]	DEC(38,20)		--Entry Type 10
	, [CustLedgerEntry_AppliesToDocNo]		VARCHAR(20)
	, [CustLedgerEntry_DueDate]				DATETIME		--CustEntryDueDate
)
--1ter Teile
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')
--	  , (379, 'Detailed Cust_ Ledg_ Entry')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN '; WITH 'ELSE ' , ' END)
+'
[Customer_StartBalanceLCY_'+[CompanyName]+'] AS (SELECT [Customer No_]
														, SUM([SUM$Amount (LCY)]) [SUM$Amount (LCY)]
													 FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3]
													 JOIN ['+[CompanyName]+'$Customer] 
													   ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_]
--													WHERE [Posting Date] < '''+CAST(@StartDate AS VARCHAR)+'''
													WHERE [Posting Date] < '''+CONVERT(VARCHAR, @StartDate,120)+'''
														'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 1) +'
												 GROUP BY [Customer No_])'
/*
+', [Customer_StartBalAdjLCY_'+[CompanyName]+'] AS 
		(SELECT ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_]
		      , SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)])
		      - SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$4].[SUM$Amount (LCY)])
		      - SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[SUM$Amount (LCY)])  [SUM$Amount (LCY)]
		   FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3]
	  LEFT JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$4]
		     ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$4].[Customer No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_]
	      WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Posting Date] BETWEEN '''+CAST(@StartDate AS VARCHAR)+''' AND '''+CAST(@EndDate AS VARCHAR)+'''	
	        AND ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$4].[Entry Type] IN (1,3,4,5,6,7,8,9,12,13,14,15,16,17)
	   GROUP BY ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$3].[Customer No_])'												 
*/	   
--neue Idee nur die Postenart 2 Application = Ausgleich beachten!!!!!
+' 
, [Customer_StartBalAdjLCY_'+[CompanyName]+'] AS (SELECT [Customer No_]
													     , SUM([SUM$Amount (LCY)])  [SUM$Amount (LCY)]
													  FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$4]
													 JOIN ['+[CompanyName]+'$Customer] 
													   ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$4].[Customer No_]													  
--												     WHERE [Posting Date] < '''+CAST(@StartDate AS VARCHAR)+'''
													 WHERE [Posting Date] < '''+CONVERT(VARCHAR, @StartDate,120)+'''	
													   AND [Entry Type] = 2
														'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 1) +'													   
												  GROUP BY [Customer No_])'
												  
+'
, [DetailedCustLedgEntry_Amount_SUM_'+[CompanyName]+'] AS (SELECT [Cust_ Ledger Entry No_]
														, SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]) [Amount]
														, SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]) [Amount (LCY)]
													 FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry]
													 JOIN ['+[CompanyName]+'$Customer] 
													   ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Customer No_]													 
													WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] IN (1,3,4,5,6,7,8,9,12,13,14,15,16,17) 
--											  	      AND ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Posting Date] BETWEEN '''+CAST(@StartDate AS VARCHAR)+''' AND '''+CAST(@EndDate AS VARCHAR)+'''
												      AND ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Posting Date] BETWEEN '''+CONVERT(VARCHAR, @StartDate,120)+''' AND '''+CONVERT(VARCHAR, @EndDate,120)+'''
														'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 1) +'
												 GROUP BY [Cust_ Ledger Entry No_])'												  	
+'
, [DetailedCustLedgEntry_RemAmount_SUM_'+[CompanyName]+'] AS (SELECT [Cust_ Ledger Entry No_]
														, SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount]) [Rem Amount]
														, SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)]) [Rem Amount (LCY)]
													 FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry]
													 JOIN ['+[CompanyName]+'$Customer] 
													   ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Customer No_]													 
--											  	      AND ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Posting Date] BETWEEN '''+CAST(@StartDate AS VARCHAR)+''' AND '''+CAST(@EndDate AS VARCHAR)+'''
												      AND ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Posting Date] BETWEEN '''+CONVERT(VARCHAR, @StartDate,120)+''' AND '''+CONVERT(VARCHAR, @EndDate,120)+'''
														'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 1) +'
												 GROUP BY [Cust_ Ledger Entry No_])'
FROM #RESULTS_CompanyName
ORDER BY RowNumber 	


--2ter Teil					   
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')
	  , (21, 'Cust_ Ledger Entry')
	  , (379, 'Detailed Cust_ Ledg_ Entry')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' UNION ALL ' END)	
+'	 
	SELECT '''+[CompanyName]+''' 
		 , ['+[CompanyName]+'$Customer].[No_]
		 , ['+[CompanyName]+'$Customer].[Name] 
		 , ['+[CompanyName]+'$Customer].[Phone No_] 	 
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Posting Date]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type]
		 , (CASE WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] = 1 THEN ''Zahlung''
				 WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] = 2 THEN ''Rechnung''
				 WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] = 3 THEN ''Gutschrift''
				 WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] = 4 THEN ''Zinsrechnung''
				 WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] = 5 THEN ''Mahnung''
				 WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] = 6 THEN ''Erstattung''
			END)
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Document No_]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Description]
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Currency Code]
		 , [DetailedCustLedgEntry_Amount_SUM].[Amount]			
		 , [DetailedCustLedgEntry_Amount_SUM].[Amount (LCY)]
		 , [DetailedCustLedgEntry_RemAmount_SUM].[Rem Amount]
		 , [DetailedCustLedgEntry_RemAmount_SUM].[Rem Amount (LCY)]
		 , 0
		 , [Customer_StartBalanceLCY_'+[CompanyName]+'].[SUM$Amount (LCY)]
		 , [Customer_StartBalAdjLCY_'+[CompanyName]+'].[SUM$Amount (LCY)]
		 , (CASE WHEN [DetailedCustLedgEntry_Corr_AppRou].[Entry Type] = 11
					THEN [DetailedCustLedgEntry_Corr_AppRou].[Amount (LCY)] END)
		 , (CASE WHEN [DetailedCustLedgEntry_Corr_AppRou].[Entry Type] = 10
					THEN [DetailedCustLedgEntry_Corr_AppRou].[Amount (LCY)] END)
		 , ['+[CompanyName]+'$Cust_ Ledger Entry].[Applies-to Doc_ No_]
		 , (CASE WHEN ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] IN (1,6) THEN NULL ELSE ['+[CompanyName]+'$Cust_ Ledger Entry].[Due Date] END)
	  FROM ['+[CompanyName]+'$Customer]					
	  '+
 CASE WHEN @ExcludeBalanceOnly = 0 THEN  ' LEFT ' ELSE '' END	  
	+'JOIN ['+[CompanyName]+'$Cust_ Ledger Entry] 			
	    ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_] = ['+[CompanyName]+'$Customer].[No_]
--	   AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Posting Date] BETWEEN '''+CAST(@StartDate AS VARCHAR)+''' AND '''+CAST(@EndDate AS VARCHAR)+'''
	   AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Posting Date] BETWEEN '''+CONVERT(VARCHAR, @StartDate,120)+''' AND '''+CONVERT(VARCHAR, @EndDate,120)+'''
 LEFT JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry] [DetailedCustLedgEntry_Corr_AppRou]
		ON [DetailedCustLedgEntry_Corr_AppRou].[Cust_ Ledger Entry No_] = ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]   
       AND [DetailedCustLedgEntry_Corr_AppRou].[Entry Type]			    IN (10,11)

 LEFT JOIN [DetailedCustLedgEntry_Amount_SUM_'+[CompanyName]+'] [DetailedCustLedgEntry_Amount_SUM]
	    ON [DetailedCustLedgEntry_Amount_SUM].[Cust_ Ledger Entry No_] = ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]
 
 LEFT JOIN [DetailedCustLedgEntry_RemAmount_SUM_'+[CompanyName]+'] [DetailedCustLedgEntry_RemAmount_SUM]
	    ON [DetailedCustLedgEntry_RemAmount_SUM].[Cust_ Ledger Entry No_] = ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]
        
 LEFT JOIN [Customer_StartBalanceLCY_'+[CompanyName]+']
	    ON [Customer_StartBalanceLCY_'+[CompanyName]+'].[Customer No_] = ['+[CompanyName]+'$Customer].[No_]

 LEFT JOIN [Customer_StartBalAdjLCY_'+[CompanyName]+']
 	    ON [Customer_StartBalAdjLCY_'+[CompanyName]+'].[Customer No_] = ['+[CompanyName]+'$Customer].[No_]

WHERE (1=1)'
+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 1)	 		 	 

FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
EXEC   (@Stmt)
--ENDE Rückgabetabelle	


SELECT * FROM #RESULTS 
ORDER BY [Customer_No], [CompanyName], [CustLedgerEntry_PostingDate] 

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
