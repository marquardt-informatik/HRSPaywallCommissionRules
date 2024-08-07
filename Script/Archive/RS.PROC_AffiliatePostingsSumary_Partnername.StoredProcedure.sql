USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_AffiliatePostingsSumary_Partnername]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 25.01.2012
-- Description:	Nav Report 50141
--				Export an Dataport 50130 angelehnt. Es wird hier eine Zeile je Buchung und nicht je Buchteil ausgegeben.

-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS-CN' 
		, @ReportId					INT				= 50141
EXEC [RS].[PROC_AffiliatePostingsSumary_Partnername] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_AffiliatePostingsSumary_Partnername] 
(
	  @UserId					VARCHAR(20)
	, @CompanyName				VARCHAR(30)
	, @ReportId					INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @Filter					VARCHAR(MAX) = ''
		, @Filter_GloDim1			VARCHAR(MAX)		
		, @Filter_GloDim2			VARCHAR(MAX)
		, @Filter_Currency			VARCHAR(MAX)
		, @TableIDs					[RS].[TableIDs]
		, @TableIDs2				[RS].[TableIDs]

--BEGIN Filter aus den FlowFilter
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
	    [CompanyName]			VARCHAR(160)
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
(	  
	  [Company-Name]						VARCHAR(160)
)
--1ter Teile
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES (50142, 'Rebate Agreement Header')
	  , (60031, 'Affiliate Postings');
SELECT @Stmt = '; WITH [_AP] AS (
            SELECT COALESCE([HRS$Rebate Agreement Header].[Description],[Affiliate Partner].[Company-Name]) [Company-Name]
              FROM [Affiliate Partner] WITH (NOLOCK)
              JOIN [HRS$Affiliate Postings] WITH (NOLOCK)
                ON [Affiliate Partner].[No_] = [HRS$Affiliate Postings].[AffiliatePartnerNo]
         LEFT JOIN [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
                ON [Affiliate Partner].[No_] = [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
         LEFT JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)'+ [RS].[Nav2SqlString](@UserId, 'HRS', @ReportId, @TableIDs, 2) +' 
) 
INSERT INTO #RESULTS
SELECT DISTINCT [Company-Name] FROM _AP
'   	   

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
PRINT	SUBSTRING(@Stmt,16001,24000)
EXEC   (@Stmt)
--ENDE Rückgabetabelle	


SELECT * FROM #RESULTS 
ORDER BY [Company-Name]

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END
GO
