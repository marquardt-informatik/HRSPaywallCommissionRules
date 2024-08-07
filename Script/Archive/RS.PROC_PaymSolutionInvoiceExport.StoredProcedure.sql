USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_PaymSolutionInvoiceExport]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Dennis Juhr
-- Create date: 03.09.2019
-- Description:	Copy of [RS].[PROC_AffiliatePostingsSumaryWithName]

-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'EXTDJU02'
		, @CompanyName				VARCHAR(30)		= 'HRS Payment' 
		, @ReportId					INT				= 50122
EXEC [RS].[PROC_PaymSolutionInvoiceExport] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_PaymSolutionInvoiceExport] 
(
	  @UserId					VARCHAR(20)
	, @CompanyName			VARCHAR(30)
	, @ReportId					INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @TableIDs					[RS].[TableIDs]


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
	 , ROW_NUMBER() OVER (ORDER BY [Name] DESC)
  FROM [Company] 
WHERE (1=1)
'
-- Erstmal nur Payment
+ 'AND [Company].[Name] = ''HRS Payment'''
-- + [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

PRINT	@StmtCompanyName
EXEC   (@StmtCompanyName)
--ENDE Mandantenauswahl


--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
(	  [Prozess Nummer]					INT 
	, [Nicht kommissionierbar]			VARCHAR(4) 
	, [Debitor Nr.]						VARCHAR(20) 
	, [Angelegt am]						DATETIME 
	, [Debitor Buchungsdatum]			DATETIME 
	, [Kreditor Buchungsdatum]			DATETIME 
	, [Payment Type]					VARCHAR(30) 
	, [Betrag (MW)]						DECIMAL(38, 20) 
	, [MwSt.-Bemessungsgrundlage (MW)]	DECIMAL(38, 20) 
	, [Steuer Betrag (MW)]				DECIMAL(38, 20) 
	, [Angelegt am 2]					DATETIME 
)
--1ter Teile
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(50157, 'Paym. Solution Invoice');

SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' 
UNION ALL ' END)	
+'
SELECT [Process No_] [Prozess Nummer]
     , CASE WHEN [No Kommission] = 1 THEN ''Ja'' ELSE ''Nein'' END [Nicht kommissionierbar]
     , [Customer No_] [Debitor Nr.]
     , [Inserted at] [Angelegt am]
     , [Cust_ Posting Date] [Debitor Buchungsdatum]
     , [Vendor Posting Date] [Kreditor Buchungsdatum]
     , CASE
         WHEN [Payment Type] = 13 THEN ''airPlus VCC''
         WHEN [Payment Type] = 14 THEN ''airPlus Händler ist Hotel''
         WHEN [Payment Type] = 15 THEN ''airPlus Händler is HRS''
         ELSE ''''
       END [Payment Type]
     , [Amount (LCY)] [Betrag (MW)]
     , [VAT Base Amount (LCY)] [MwSt.-Bemessungsgrundlage (MW)]
     , [VAT Amount (LCY)] [Steuer Betrag (MW)]
     , [Inserted at] [Angelegt am 2]
FROM DynNavHRS.dbo.['+[CompanyName]+'$Paym_ Solution Invoice] WITH (NOLOCK)
WHERE (1=1)'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3) +' 
'   	   
FROM #RESULTS_CompanyName
ORDER BY RowNumber 	


PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
PRINT	SUBSTRING(@Stmt,16001,24000)
EXEC   (@Stmt)
--ENDE Rückgabetabelle	


SELECT * FROM #RESULTS 

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
