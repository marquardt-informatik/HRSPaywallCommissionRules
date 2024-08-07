USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_AffiliatePostingsSumaryWithAssignment]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ================================================
-- Author:		Dennis Juhr
-- Create date: 23.05.2019
-- Description:	Copy of [RS].[PROC_AffiliatePostingsSumaryWithName]

-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'EXTDJU02'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50154
EXEC [RS].[PROC_AffiliatePostingsSumaryWithAssignment] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_AffiliatePostingsSumaryWithAssignment] 
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
	, [ReservationPartNo]					int
	, [ProcessNo]							int
	, [Turnover_LCY]						DEC(38,20)
	, [Amount_LCY]							DEC(38,20)
	, [CommissionType]						VARCHAR(250)
	, [CommissionRateProz]					DEC(38,20)
	, [Turnover_LCY_corr]					DEC(38,20)
	, [Amount_LCY_corr]						DEC(38,20)
	, [AffiliatePartnerNo]					VARCHAR(250)
	, [ArivalDate]							DATETIME
	, [DepartureDate]						DATETIME
	, [ReservationDate]						DATETIME
	, [ReservationSource]					INT
	, [ReservationSourceName]				VARCHAR(250)
	, [ReservationSourceInterface]			VARCHAR(250)
	, [HotelNo]								int
	, [Description]                         VARCHAR(250)
	, [TopBonusID]                          VARCHAR(250)
	, [Source Country]                      VARCHAR(250)
	, [Destination Country]                 VARCHAR(250)
	, [BookingCode]                         VARCHAR(250)
	, [NonComm]								int
	, [Assignment]							int
	, [VendorNo]							VARCHAR(20)
	, [VendorName]							VARCHAR(250)
	, [KKeyName]							VARCHAR(250)
	, [FKey]								VARCHAR(250)
	, [FKeyName]							VARCHAR(250)
	, [CompanyID]							VARCHAR(250)
	, [MasterAccountName]					VARCHAR(250)
	, [ChainTAF_LCY]                        DEC(38,20)
	, [ChainTAF_LCY_corr]                   DEC(38,20) 
	, [PFP_LCY]                             DEC(38,20) 
	, [PFP_LCY_corr]                        DEC(38,20)
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
  SELECT P.InvoiceNo
       , P.ReservationNo
	   , P.ReservationPartNo
       , P.ProcessNumber
       , P.Turnover_LCY
       , P.[Amount_LCY]-P.[TAF Amount (LCY)] Amount_LCY
       , P.CommissionType_corr CommissionType
       , P.CommissionRateProz_corr CommissionRateProz
       , P.Turnover_LCY_corr
       , P.[Amount_LCY_corr]-P.[TAF Amount (LCY) (corr_)] Amount_LCY_corr
       , P.AffiliatePartnerNo
       , P.ArivalDate
       , P.DepartureDate
       , P.ReservationDate
       , P.[ReservationSource]
       , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , P.[HotelNo]
	   , P.[Description]
	   , P.[TopBonusID]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	   , P.BookingCode
	   , CASE WHEN P.Amount_LCY_corr = 0 THEN 1 ELSE 0 END [NonComm]
	   , CASE WHEN APV.[Vendor No_] IS NULL THEN 0 ELSE 1 END [Assignment]
	   , APV.[Vendor No_]
	   , V.[Name]
	   , AP.[Company-Name]
	   , AP.[Company-No_]
	   , AP.[Customer Name]
	   , AP.[Company-ID]
	   , AP.[Master Account Name]
--------------------------------------------------------------------------------------------
	   , AAP2.[Amount_LCY] [ChainTAF_LCY] 
	   , AAP2.[Amount_LCY_corr] [ChainTAF_LCY_corr]
	   , AAP3.[Amount_LCY]  [PFP_LCY] 
	   , AAP3.[Amount_LCY_corr]  [PFP_LCY_corr]
--------------------------------------------------------------------------------------------
    FROM ['+[CompanyName]+'$Affiliate Postings] P WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = P.[AffiliatePartnerNo]
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = P.[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = P.[ReservationSource]
    JOIN dbo.Split(''HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,'','','') I
      ON I.[Index] = [HRS$Booking Source].Interface
LEFT JOIN [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK) 
      ON P.AffiliatePartnerNo = APV.[Affiliate Partner No_]
LEFT JOIN [HRS$Vendor] V WITH (NOLOCK)
	  ON APV.[Vendor No_] = V.[No_]
--------------------------------------------------------------------------------------------
LEFT JOIN [' + [CompanyName] + '$Additional Affiliate Postings] AAP2 WITH (NOLOCK) ON AAP2.ReservationNo = P.ReservationNo AND AAP2.ReservationPartNo = P.ReservationPartNo
    AND AAP2.[Product] =2
LEFT JOIN [' + [CompanyName] + '$Additional Affiliate Postings] AAP3 WITH (NOLOCK) ON AAP3.ReservationNo = P.ReservationNo AND AAP3.ReservationPartNo = P.ReservationPartNo
    AND AAP3.[Product] =5
--------------------------------------------------------------------------------------------
   WHERE (1=1)'+ 
   
   CASE
   WHEN CHARINDEX('['+[CompanyName] +'$Affiliate Postings]',[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3))>0 
   THEN REPLACE([RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3),'['+[CompanyName] +'$Affiliate Postings]','P')
   ELSE
   [RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)
   END
   
   +' 
    --AND [Travelagency No_] NOT IN (SELECT [Travelagency No_] FROM [HRS$Vendor Travelagency])
    --AND AffiliatePartnerNo NOT IN (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor])
	'+ CASE WHEN [RS].[Nav2SqlString](@UserId, REPLACE(@CompanyName,'.','_'), @ReportId, @TableIDs2, 2)<>'' THEN '
     AND P.AffiliatePartnerNo IN 
         (
            SELECT ['+REPLACE(@CompanyName,'.','_')+'$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM ['+REPLACE(@CompanyName,'.','_')+'$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN ['+REPLACE(@CompanyName,'.','_')+'$Rebate Agreement Header] WITH (NOLOCK)
                ON ['+REPLACE(@CompanyName,'.','_')+'$Rebate Agreement Header].[Rebate-to Vendor No_] = ['+REPLACE(@CompanyName,'.','_')+'$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)'+ [RS].[Nav2SqlString](@UserId, REPLACE(@CompanyName,'.','_'), @ReportId, @TableIDs2, 2) +' 
         )' ELSE '' END +'
)
'   	   
FROM #RESULTS_CompanyName
ORDER BY RowNumber 	


--2ter Teil		
--SELECT @Stmt = @Stmt + ' INSERT INTO #RESULTS 
--	SELECT *
--	  FROM [_HRS-CN_AP]
--	UNION ALL
--	SELECT *
--	  FROM [_HRS_AP]
--'	  
			   
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
