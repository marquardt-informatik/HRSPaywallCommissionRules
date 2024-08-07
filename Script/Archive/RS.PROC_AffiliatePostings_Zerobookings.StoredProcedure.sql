USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_AffiliatePostings_Zerobookings]    Script Date: 10.04.2024 14:31:57 ******/
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
-- 24.09.19 HRS001 ACS-1963 Added Segment
-- 14.10.19 HRS002 ACS-1963 Added Roomnights
-- 15.10.19 HRS003 ACS-1963 Added Chain and Brand
-- 12.12.19 HRS004 ACS-2096 Added Muse ID
-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50141
EXEC [RS].[PROC_AffiliatePostings_Zerobookings] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_AffiliatePostings_Zerobookings] 
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
	, [ArivalDate]						DATETIME
	, [DepartureDate]						DATETIME
	, [ReservationDate]						DATETIME
	, [ReservationSource]					INT
	, [ReservationSourceName]				VARCHAR(120)
	, [ReservationSourceInterface]			VARCHAR(120)
	, [HotelNo]								int
	, [Source Country]                      VARCHAR(100)
	, [Destination Country]                 VARCHAR(100)
	-- HRS001 >>
	, [Segment]								VARCHAR(50)
	-- HRS001 <<
	-- HRS002 >>
	, [RoomNights]							DEC(37,20)
    , [RoomNights_corr]						DEC(37,20)
	-- HRS002 <<
	-- HRS003 >>
	, [Chain]								VARCHAR(20)
    , [Brand]								VARCHAR(20)
	-- HRS003 <<
	-- HRS004 >>
	, [MuseID]								VARCHAR(20)
	-- HRS004 <<
)
--1ter Teile
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(60031, 'Affiliate Postings');
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
       , MIN(ReservationDate) ReservationDate
       , [ReservationSource]
       , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	   , CASE
	       WHEN Segment = 0 THEN ''''
	       WHEN Segment = 1 THEN ''Corporate unmanaged''
	       WHEN Segment = 2 THEN ''Leisure''
	       WHEN Segment = 3 THEN ''Corporate managed commissionable''
	       WHEN Segment = 4 THEN ''Corporate managed net''
	       WHEN Segment = 5 THEN ''MICE''
		 END [Segment]
		, SUM(RoomNights) RoomNights
		, SUM(RoomNights_corr) RoomNights_corr
		, [Chain]
		, [Brand]
		, [MuseID]
    FROM ['+[CompanyName]+'$Affiliate Postings] WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = ['+[CompanyName]+'$Affiliate Postings].[AffiliatePartnerNo]
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = ['+[CompanyName]+'$Affiliate Postings].[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = ['+[CompanyName]+'$Affiliate Postings].[ReservationSource]
    JOIN dbo.Split(''HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,'','','') I
      ON I.[Index] = [HRS$Booking Source].Interface
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
     AND CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (Turnover_LCY_corr<>0 AND ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END=1  
GROUP BY InvoiceNo
       , ReservationNo
       , ProcessNumber
       , CommissionType_corr
       , CommissionRateProz_corr
       , AffiliatePartnerNo
       , [ReservationSource]
       , [HRS$Booking Source].[Name]
       , I.[String]
       , [HotelNo]
	   , SC.[Name]
	   , DC.[Name]
	   , CASE
	       WHEN Segment = 0 THEN ''''
	       WHEN Segment = 1 THEN ''Corporate unmanaged''
	       WHEN Segment = 2 THEN ''Leisure''
	       WHEN Segment = 3 THEN ''Corporate managed commissionable''
	       WHEN Segment = 4 THEN ''Corporate managed net''
	       WHEN Segment = 5 THEN ''MICE''
		 END
       , [Chain]
	   , [Brand]
	   , [MuseID]
--HAVING SUM(Amount_LCY_corr) = 0       
)
'   	   
FROM #RESULTS_CompanyName
ORDER BY RowNumber 	


--2ter Teil					   
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' 
UNION ' END)	
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


SELECT * FROM #RESULTS ORDER BY [ReservationNo]

--SELECT SUM([Turnover_LCY_corr]) FROM #RESULTS WHERE [ReservationSource]=383

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
