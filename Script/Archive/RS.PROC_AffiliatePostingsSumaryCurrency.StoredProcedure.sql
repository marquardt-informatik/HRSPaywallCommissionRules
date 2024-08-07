USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_AffiliatePostingsSumaryCurrency]    Script Date: 10.04.2024 14:31:57 ******/
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
EXEC [RS].[PROC_AffiliatePostingsSumaryCurrency] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_AffiliatePostingsSumaryCurrency] 
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
'+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

SET @StmtCompanyName = @StmtCompanyName + @Stmt
PRINT	@StmtCompanyName
EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl


--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
(	  [InvoiceNo]							VARCHAR(20)
	, [ReservationNo]						int
	, [ProcessNo]							int
	, [Turnover_LCY]						DEC(38,20)
	, [Amount_LCY]							DEC(38,20)
	, [CommissionType]						VARCHAR(50)
	, [CommissionRateProz]					DEC(38,20)
	, [Turnover_LCY_corr]					DEC(38,20)
	, [Amount_LCY_corr]						DEC(38,20)
	, [AffiliatePartnerNo]					VARCHAR(50)
	, [ArivalDate]							DATETIME
	, [DepartureDate]						DATETIME
	, [ReservationSource]					INT
	, [ReservationSourceName]				VARCHAR(120)
	, [ReservationSourceInterface]			VARCHAR(120)
	, [Turnover]							DEC(38,20)
	, [Amount]								DEC(38,20)
	, [CurrencyFactor]						DEC(38,20)
	, [CurrencyCode]						VARCHAR(10)
	, [Turnover_corr]						DEC(38,20)
	, [Amount_corr]							DEC(38,20)
	, [CurrencyFactor_corr]					DEC(38,20)
	, [CurrencyCode_corr]					VARCHAR(10)
	, [ReferenceNumber]						VARCHAR(50)
	, [HotelNo]								int
	, [Source Country]                      VARCHAR(100)
	, [Destination Country]                 VARCHAR(100)
)
--1ter Teile
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(60031, 'Affiliate Postings'),(64013, 'Booking Source')
;
DELETE FROM @TableIDs2
INSERT INTO @TableIDs2 
VALUES (50142, 'Rebate Agreement Header');
--	  , (379, 'Detailed Cust_ Ledg_ Entry')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN '; WITH 'ELSE ' , ' END)
+'
[_'+[CompanyName]+'_AP] AS (
  SELECT InvoiceNo
       , ReservationNo
       , ProcessNumber
       , SUM(Turnover_LCY) Turnover_LCY
       , SUM([Amount_LCY]-[TAF Amount (LCY)]) Amount_LCY
       , CommissionType_corr CommissionType
       , CommissionRateProz_corr CommissionRateProz
       , SUM(Turnover_LCY_corr) Turnover_LCY_corr
       , SUM([Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]) Amount_LCY_corr
       , AffiliatePartnerNo
       , MIN(ArivalDate) ArivalDate
       , MAX(DepartureDate) DepartureDate
       , [ReservationSource]
       , ['+[CompanyName]+'$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , SUM(Turnover) Turnover
       , SUM(Amount) Amount
       , MAX(CurrencyFaktor) CurrencyFactor
       , MAX(CurrencyCode) CurrencyCode
       , SUM(Turnover_corr) Turnover_corr
       , SUM(Amount_corr) Amount_corr
       , MAX(CurrencyFaktor_corr) CurrencyFactor_corr
       , MAX(CurrencyCode_corr) CurrencyCode_corr
       , MAX(B_PASSWORD) ReferenceNumber
       , [HotelNo]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
    FROM ['+[CompanyName]+'$Affiliate Postings] WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = ['+[CompanyName]+'$Affiliate Postings].[AffiliatePartnerNo]
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = ['+[CompanyName]+'$Affiliate Postings].[CountryCode]
    JOIN ['+[CompanyName]+'$Booking Source] WITH (NOLOCK)
      ON ['+[CompanyName]+'$Booking Source].[No_] = ['+[CompanyName]+'$Affiliate Postings].[ReservationSource]
    JOIN dbo.Split(''HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,'','','') I
      ON I.[Index] = ['+[CompanyName]+'$Booking Source].Interface
LEFT JOIN [HRSDB].[BUCHUNG] BU ON BU.[B_KEY] = ['+[CompanyName]+'$Affiliate Postings].ReservationNo
   WHERE (1=1)'+ [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3) +' 
    --AND [Travelagency No_] NOT IN (SELECT [Travelagency No_] FROM [HRS$Vendor Travelagency])
    --AND AffiliatePartnerNo NOT IN (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor])
	'+ CASE WHEN [RS].[Nav2SqlString](@UserId, REPLACE(@CompanyName,'.','_'), @ReportId, @TableIDs2, 2)<>'' THEN '
     AND AffiliatePartnerNo IN 
         (
            SELECT ['+REPLACE(@CompanyName,'.','_')+'$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM ['+REPLACE(@CompanyName,'.','_')+'$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN ['+REPLACE(@CompanyName,'.','_')+'$Rebate Agreement Header] WITH (NOLOCK)
                ON ['+REPLACE(@CompanyName,'.','_')+'$Rebate Agreement Header].[Rebate-to Vendor No_] = ['+REPLACE(@CompanyName,'.','_')+'$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)'+ [RS].[Nav2SqlString](@UserId, REPLACE(@CompanyName,'.','_'), @ReportId, @TableIDs2, 2) +' 
         )' ELSE '' END +'
GROUP BY InvoiceNo
       , ReservationNo
       , ProcessNumber
       , CommissionType_corr
       , CommissionRateProz_corr
       , AffiliatePartnerNo
       , [ReservationSource]
       , ['+[CompanyName]+'$Booking Source].[Name]
       , I.[String]
       , [HotelNo]
	   , SC.[Name]
	   , DC.[Name]
)
'   	   
FROM #RESULTS_CompanyName
ORDER BY RowNumber 	


--2ter Teil					   
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' 
UNION ALL ' END)	
+'	 
	SELECT *
	  FROM [_'+[CompanyName]+'_AP]
'	  
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
PRINT	SUBSTRING(@Stmt,16001,24000)
EXEC   (@Stmt)
--ENDE Rückgabetabelle	


SELECT * FROM #RESULTS 
ORDER BY [ReservationNo]

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END
GO
