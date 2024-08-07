USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustClaimStatusReportDetailedV2]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 14.01.2013
-- Description:	Nav Report 50145
--				Debitor - Außenstandsbericht

-- 19.02.2019 HRS001 SAL	Bugfix Filter Customer.Testhotel 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50145
		, @StartDate				DATETIME		= '13.01.2016'
EXEC [RS].[PROC_CustClaimStatusReportDetailedV2] @UserId, @CompanyName, @ReportId, @StartDate
EXEC [RS].[PROC_CustClaimStatusReportDetailedV2] 'TMA04', 'HRS', 50145, 2016-01-14
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustClaimStatusReportDetailedV2] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
	, @StartDate					DATETIME
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @Filter					VARCHAR(MAX) = ''
		, @PEGVisible				VARCHAR(MAX) = ''
		, @FSVisible				VARCHAR(MAX) = ''
		, @SUMVisible				VARCHAR(MAX) = ''
		, @CRSFromUser				VARCHAR(MAX) = ''
		, @DCUser					VARCHAR(MAX) = ''
		, @Filter_Salesperson		VARCHAR(MAX) = ''
		, @Filter_Country			VARCHAR(MAX) = ''
		, @Filter_Continent			VARCHAR(MAX) = ''
		, @CRSUserList				VARCHAR(MAX) = ''
		, @TableIDs					[RS].[TableIDs]

--BEGIN Filter aus den FlowFilter
SET @PEGVisible = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 2)	
SET @FSVisible = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 3)	
SET @SUMVisible = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 4)	
SET @CRSFromUser = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 5)	
SET @Filter_Salesperson = 
	(SELECT CASE WHEN [Filter Value] = '' THEN '' ELSE '|'+RTRIM([Filter Value])+'|' END
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1)
SET @Filter_Country = 
	(SELECT CASE WHEN [Filter Value] = '' THEN '' ELSE '|'+RTRIM([Filter Value])+'|' END
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 35)	
SET @Filter_Continent = 
	(SELECT CASE WHEN [Filter Value] = '' THEN '' ELSE '|'+RTRIM([Filter Value])+'|' END
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 9
	    AND [Field ID]  = 51100)	
SELECT @DCUser = [Debit Coll_ Salesperson Code] FROM [HRS$Sales & Receivables Setup]

SET @CRSUserList = ''
SELECT @CRSUserList = @CRSUserList + CASE WHEN @CRSUserList='' THEN ''''+[Salesperson Code]+'''' ELSE @CRSUserList + ','''+[Salesperson Code]+'''' END
  FROM (SELECT DISTINCT [Salesperson Code] FROM [Chain]) X
SELECT @CRSUserList = @CRSUserList + CASE WHEN @CRSUserList='' THEN ''''+[Salesperson Code]+'''' ELSE @CRSUserList + ','''+[Salesperson Code]+'''' END
  FROM (SELECT DISTINCT [Salesperson Code] FROM [Brand]) X


SET @Filter_Salesperson = COALESCE(@Filter_Salesperson,'')
SET @Filter_Country = COALESCE(@Filter_Country,'')
SET @Filter_Continent = COALESCE(@Filter_Continent,'')
PRINT '@Filter_Salesperson = ' + @Filter_Salesperson
PRINT '@Filter_Country = ' + @Filter_Country
PRINT '@Filter_Continent = ' + @Filter_Continent
PRINT '@DCUser = ' + @DCUser
--Ship-to-Filter nicht beachtet!	        	   
--ENDE Filter aus FlowFilter

--ENDE Länderauswahl

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
  , @Date45End			DATETIME
  , @Date45Start		DATETIME
  ,	@Date1EndVAR		VARCHAR(10)
  , @Date2StartVAR		VARCHAR(10)
  , @Date2EndVAR		VARCHAR(10)
  , @Date3StartVAR		VARCHAR(10)
  , @Date3EndVAR		VARCHAR(10)
  , @Date4StartVAR		VARCHAR(10)
  , @Date4EndVAR		VARCHAR(10)
  , @Date45StartVAR		VARCHAR(10)
  , @Date45EndVAR		VARCHAR(10)
  , @Date5StartVAR		VARCHAR(10)
SET @Date5Start = @StartDate 
SET @Date45Start= DATEADD(dd, -45, @Date5Start) 
SET @Date45End  = DATEADD(dd,  -1, @Date5Start) 
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
SET @Date45EndVAR  = CONVERT(VARCHAR(10), @Date45End, 104)
SET @Date2StartVAR = CONVERT(VARCHAR(10), @Date2Start, 104)
SET @Date3StartVAR = CONVERT(VARCHAR(10), @Date3Start, 104)
SET @Date4StartVAR = CONVERT(VARCHAR(10), @Date4Start, 104)
SET @Date45StartVAR= CONVERT(VARCHAR(10), @Date45Start, 104)
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
SELECT REPLACE([Name] ,''.'',''_'')
	 , ROW_NUMBER() OVER (ORDER BY [Name])
  FROM [Company] 
WHERE (1=1) AND [Name] IN (''HRS'',''HRS-CN'',''HRS-BR'')
'--+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

SET @StmtCompanyName = @StmtCompanyName + @Stmt
--PRINT	@StmtCompanyName
EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl

--BEGIN Rückgabetabelle 
CREATE TABLE #RESULTS 
(	  [CompanyName]							VARCHAR(30)
	, [Salesperson_Code]					VARCHAR(10)
	, [Freesale]							INT
	, [CountryGroup]                        INT
	, [ResponsibiliyCenter]					VARCHAR(10)
	, [OriginalSalespersonCode]				VARCHAR(10)
    , [Country]								VARCHAR(10)
	, [Continent]							VARCHAR(10)
	, [CustBalanceDueLCY1]					DEC(38,20)
	, [CustBalanceDueLCY2]					DEC(38,20)
	, [CustBalanceDueLCY3]					DEC(38,20)
	, [CustBalanceDueLCY4]					DEC(38,20)
	, [CustBalanceDueLCY5]					DEC(38,20)
	, [CustBalanceDueLCY45]					DEC(38,20)
	, [CustBalanceDueLCY45GT]				DEC(38,20)
	, [CustBalanceDueLCY1CNY]				DEC(38,20)
	, [CustBalanceDueLCY2CNY]				DEC(38,20)
	, [CustBalanceDueLCY3CNY]				DEC(38,20)
	, [CustBalanceDueLCY4CNY]				DEC(38,20)
	, [CustBalanceDueLCY5CNY]				DEC(38,20)
	, [CustBalanceDueLCY45CNY]				DEC(38,20)
	, [CustBalanceDueLCY45GTCNY]			DEC(38,20)
	, [CustBalanceDueLCY1NB]				DEC(38,20)
	, [CustBalanceDueLCY2NB]				DEC(38,20)
	, [CustBalanceDueLCY3NB]				DEC(38,20)
	, [CustBalanceDueLCY4NB]				DEC(38,20)
	, [CustBalanceDueLCY5NB]				DEC(38,20)
	, [CustBalanceDueLCY45NB]				DEC(38,20)
	, [CustBalanceDueLCY45GTNB]				DEC(38,20)
	, [CustBalanceDueLCY1DC]				DEC(38,20)
	, [CustBalanceDueLCY2DC]				DEC(38,20)
	, [CustBalanceDueLCY3DC]				DEC(38,20)
	, [CustBalanceDueLCY4DC]				DEC(38,20)
	, [CustBalanceDueLCY5DC]				DEC(38,20)
	, [CustBalanceDueLCY45DC]				DEC(38,20)
	, [CustBalanceDueLCY45GTDC]				DEC(38,20)
)
  
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN 'WITH CR AS
(
   SELECT CU.[No_], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Country_Region Code]
     FROM [HRS$Customer] CU WITH (NOLOCK)
LEFT JOIN [HRS$Contact] CO WITH (NOLOCK)
       ON CO.[No_] = CU.[No_]
), DC_USER AS
(
  SELECT [Debit Coll_ Salesperson Code]
    FROM ['+[CompanyName]+'$Sales & Receivables Setup]
), _CU_BALANCE AS
( ' ELSE ' 
UNION ALL ' END)	
+'	 
	SELECT ['+[CompanyName]+'$Customer].[No_]
		 , ['+[CompanyName]+'$Customer].[Salesperson Code]' + CASE WHEN @CRSFromUser = '0' THEN '
		 , CASE WHEN ['+[CompanyName]+'$Customer].[Contract Status] IN (''10'',''11'') THEN 0 ELSE 1 END [Freesale]' ELSE '
		 , CASE WHEN ['+[CompanyName]+'$Customer].[Salesperson Code] IN ('+@CRSUserList+') THEN 0 ELSE 1 END [Freesale]' END + '
		 , CASE 
		     WHEN CR.[Country_Region Code] = ''33''  AND NOT ['+[CompanyName]+'$Customer].[Contract Status] IN (''10'',''11'') THEN 1
		     WHEN CR.[Country_Region Code] = ''114'' AND NOT ['+[CompanyName]+'$Customer].[Contract Status] IN (''10'',''11'') THEN 2
		     ELSE 0
		   END [Country Group]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1]	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date45StartVAR+''' AND '''+@Date45EndVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] < '''+@Date45StartVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45GT]
				
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
		              AND ['+[CompanyName]+'$Customer].[Country_Region Code] = ''29'' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1CNY]	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Country_Region Code] = ''29'' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2CNY]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Country_Region Code] = ''29'' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3CNY]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Country_Region Code] = ''29'' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4CNY]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Country_Region Code] = ''29'' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5CNY]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date45StartVAR+''' AND '''+@Date45EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Country_Region Code] = ''29'' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45CNY]
				
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] < '''+@Date45StartVAR+''' 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45GTCNY]
				
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1NB]	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2NB]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3NB]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4NB]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5NB]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date45StartVAR+''' AND '''+@Date45EndVAR+''' 
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45NB]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] < '''+@Date45StartVAR+'''  
		              AND (['+[CompanyName]+'$Customer].[No_] BETWEEN 900000 AND 900100 OR ['+[CompanyName]+'$Customer].[No_] BETWEEN 9900000 AND 9900100) 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45GTNB]
				
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] <= '''+@Date1EndVAR+'''
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1DC]	  		 
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date2StartVAR+''' AND '''+@Date2EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2DC]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date3StartVAR+''' AND '''+@Date3EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3DC]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date4StartVAR+''' AND '''+@Date4EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4DC]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] >= '''+@Date5StartVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5DC]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] BETWEEN '''+@Date45StartVAR+''' AND '''+@Date45EndVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45DC]
		 , SUM (CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Initial Entry Due Date] < '''+@Date45StartVAR+''' 
		              AND ['+[CompanyName]+'$Customer].[Salesperson Code] = [Debit Coll_ Salesperson Code] 
					 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[SUM$Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY45GTDC]
	  FROM ['+[CompanyName]+'$Customer]
	  JOIN DC_USER ON 1=1
	  JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At]
		ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Customer No_] = ['+[CompanyName]+'$Customer].[No_] 	
	  JOIN CR
		ON CR.[No_] = ['+[CompanyName]+'$Customer].[No_] 
 LEFT JOIN ['+[CompanyName]+'$Currency]
		ON ['+[CompanyName]+'$Currency].[Code] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Currency Code]
 	 WHERE ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$Posted At].[Posting Date] <= '''+@Date5StartVAR+'''
 	   AND ['+[CompanyName]+'$Customer].[Testhotel] = ''''
-- 	   AND ''|''+['+[CompanyName]+'$Customer].[Salesperson Code]+''|'' LIKE ''' + '%' +  @Filter_Salesperson + '%'' 
  GROUP BY ['+[CompanyName]+'$Customer].[No_]
		 , ['+[CompanyName]+'$Customer].[Salesperson Code]
		 , CASE WHEN ['+[CompanyName]+'$Customer].[Contract Status] IN (''10'',''11'') THEN 0 ELSE 1 END
		 , CASE 
		     WHEN CR.[Country_Region Code] = ''33''  AND NOT ['+[CompanyName]+'$Customer].[Contract Status] IN (''10'',''11'') THEN 1
		     WHEN CR.[Country_Region Code] = ''114'' AND NOT ['+[CompanyName]+'$Customer].[Contract Status] IN (''10'',''11'') THEN 2
		     ELSE 0
		   END'
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

SELECT @Stmt = @Stmt + ')
INSERT INTO #RESULTS
   SELECT [No_]
		, CASE WHEN [No_] BETWEEN 900000 AND 900100 THEN ''BUCH'' ELSE [Salesperson Code] END [Salesperson Code]
		, [Freesale]
		, [Country Group]
		, CASE WHEN [No_] = 900025 THEN ''IC-CRS'' WHEN [No_] BETWEEN 900000 AND 900100 THEN ''IC-FS'' ELSE '''' END [ResponsibiliyCenter]
		, '''' [OriginalSalespersonCode]
		, '''' [Country]
		, '''' [Continent]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY1] ELSE 0 END) [CustBalanceDueLCY1]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY2] ELSE 0 END) [CustBalanceDueLCY2]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY3] ELSE 0 END) [CustBalanceDueLCY3]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY4] ELSE 0 END) [CustBalanceDueLCY4]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY5] ELSE 0 END) [CustBalanceDueLCY5]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY45] ELSE 0 END) [CustBalanceDueLCY45]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY45GT] ELSE 0 END) [CustBalanceDueLCY45GT]
		
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY1CNY] ELSE 0 END) [CustBalanceDueLCY1CNY]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY2CNY] ELSE 0 END) [CustBalanceDueLCY2CNY]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY3CNY] ELSE 0 END) [CustBalanceDueLCY3CNY]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY4CNY] ELSE 0 END) [CustBalanceDueLCY4CNY]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY5CNY] ELSE 0 END) [CustBalanceDueLCY5CNY]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY45CNY] ELSE 0 END) [CustBalanceDueLCY45CNY]
		, SUM(CASE WHEN [Salesperson Code]<>''BUCH'' AND NOT [No_] BETWEEN 900000 AND 900100 THEN [CustBalanceDueLCY45GTCNY] ELSE 0 END) [CustBalanceDueLCY45GTCNY]
		
		, SUM([CustBalanceDueLCY1NB]) [CustBalanceDueLCY1NB]
		, SUM([CustBalanceDueLCY2NB]) [CustBalanceDueLCY2NB]
		, SUM([CustBalanceDueLCY3NB]) [CustBalanceDueLCY3NB]
		, SUM([CustBalanceDueLCY4NB]) [CustBalanceDueLCY4NB]
		, SUM([CustBalanceDueLCY5NB]) [CustBalanceDueLCY5NB]
		, SUM([CustBalanceDueLCY45NB]) [CustBalanceDueLCY45NB]
		, SUM([CustBalanceDueLCY45GTNB]) [CustBalanceDueLCY45GTNB]
		
		, SUM([CustBalanceDueLCY1DC]) [CustBalanceDueLCY1DC]
		, SUM([CustBalanceDueLCY2DC]) [CustBalanceDueLCY2DC]
		, SUM([CustBalanceDueLCY3DC]) [CustBalanceDueLCY3DC]
		, SUM([CustBalanceDueLCY4DC]) [CustBalanceDueLCY4DC]
		, SUM([CustBalanceDueLCY5DC]) [CustBalanceDueLCY5DC]
		, SUM([CustBalanceDueLCY45DC]) [CustBalanceDueLCY45DC]
		, SUM([CustBalanceDueLCY45GTDC]) [CustBalanceDueLCY45GTDC]
     FROM _CU_BALANCE
 GROUP BY [No_]
		, [Salesperson Code] 
		, [Freesale]   
		, [Country Group]
   HAVING (
          SUM([CustBalanceDueLCY1])
        + SUM([CustBalanceDueLCY2])
        + SUM([CustBalanceDueLCY3])
        + SUM([CustBalanceDueLCY4])
        + SUM([CustBalanceDueLCY5]) 
          ) >= 0          
       OR (
          SUM([CustBalanceDueLCY1NB])
        + SUM([CustBalanceDueLCY2NB])
        + SUM([CustBalanceDueLCY3NB])
        + SUM([CustBalanceDueLCY4NB])
        + SUM([CustBalanceDueLCY5NB])
          ) <> 0
       OR (
          SUM([CustBalanceDueLCY1DC])
        + SUM([CustBalanceDueLCY2DC])
        + SUM([CustBalanceDueLCY3DC])
        + SUM([CustBalanceDueLCY4DC])
        + SUM([CustBalanceDueLCY5DC])
          ) <> 0
 ORDER BY 1'

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,8000)
PRINT	SUBSTRING(@Stmt,16001,8000)
PRINT	SUBSTRING(@Stmt,24001,8000)
PRINT	SUBSTRING(@Stmt,32001,8000)
PRINT	SUBSTRING(@Stmt,40001,8000)
PRINT	SUBSTRING(@Stmt,48001,8000)
PRINT	SUBSTRING(@Stmt,56001,8000)
PRINT	SUBSTRING(@Stmt,64001,8000)
PRINT	SUBSTRING(@Stmt,72001,8000)
PRINT	SUBSTRING(@Stmt,80001,8000)
PRINT	SUBSTRING(@Stmt,88001,8000)
PRINT	SUBSTRING(@Stmt,96001,8000)
PRINT	SUBSTRING(@Stmt,104001,8000)

EXEC   (@Stmt)

-- Update Customer-Informations
;WITH CR AS
(
   SELECT CU.[No_], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Country_Region Code], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Code], CR.[Continent] FROM [HRS$Customer]    CU WITH (NOLOCK) LEFT JOIN [HRS$Contact]    CO WITH (NOLOCK) ON CO.[No_] = CU.[No_] JOIN [HRS$Country_Region]    CR WITH (NOLOCK) ON CR.[Code] = COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) UNION
   SELECT CU.[No_], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Country_Region Code], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Code], CR.[Continent] FROM [HRS-CN$Customer] CU WITH (NOLOCK) LEFT JOIN [HRS-CN$Contact] CO WITH (NOLOCK) ON CO.[No_] = CU.[No_] JOIN [HRS-CN$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) UNION
   SELECT CU.[No_], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Country_Region Code], COALESCE(CO.[Country_Region Code], CU.[Country_Region Code]) [Code], CR.[Continent] FROM [HRS-BR$Customer] CU WITH (NOLOCK) LEFT JOIN [HRS-BR$Contact] CO WITH (NOLOCK) ON CO.[No_] = CU.[No_] JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = COALESCE(CO.[Country_Region Code], CU.[Country_Region Code])
), MDC AS
(
   SELECT 'HRS'    [Company], [Hotel No_], MAX([Collection Case No_]) [Collection Case No_] FROM [HRS$Debit Collection Case]    DC WITH (NOLOCK) GROUP BY [Hotel No_] UNION
   SELECT 'HRS-CN' [Company], [Hotel No_], MAX([Collection Case No_]) [Collection Case No_] FROM [HRS-CN$Debit Collection Case] DC WITH (NOLOCK) GROUP BY [Hotel No_] UNION
   SELECT 'HRS-BR' [Company], [Hotel No_], MAX([Collection Case No_]) [Collection Case No_] FROM [HRS-BR$Debit Collection Case] DC WITH (NOLOCK) GROUP BY [Hotel No_]
), DC AS
(
   SELECT DC.[Hotel No_], DC.[Salesperson Code] FROM [HRS$Debit Collection Case]    DC WITH (NOLOCK) JOIN MDC ON MDC.[Hotel No_] = DC.[Hotel No_] AND MDC.[Collection Case No_] = DC.[Collection Case No_] AND MDC.[Company] = 'HRS'    UNION
   SELECT DC.[Hotel No_], DC.[Salesperson Code] FROM [HRS-BR$Debit Collection Case] DC WITH (NOLOCK) JOIN MDC ON MDC.[Hotel No_] = DC.[Hotel No_] AND MDC.[Collection Case No_] = DC.[Collection Case No_] AND MDC.[Company] = 'HRS-BR' UNION
   SELECT DC.[Hotel No_], DC.[Salesperson Code] FROM [HRS-CN$Debit Collection Case] DC WITH (NOLOCK) JOIN MDC ON MDC.[Hotel No_] = DC.[Hotel No_] AND MDC.[Collection Case No_] = DC.[Collection Case No_] AND MDC.[Company] = 'HRS-CN'
), CU AS
(
    SELECT CU.[No_]
	     , CU.[Salesperson Code]
	     , CU.[Salesperson Code] [Original Salesperson Code]
		 , CU.[Responsibility Center]
		 , CR.[Continent]
		 , CR.[Country_Region Code]
      FROM [HRS$Customer] CU WITH (NOLOCK)
	  JOIN CR
	    ON CR.[No_] = CU.[No_]
 LEFT JOIN DC
        ON DC.[Hotel No_] = CU.[No_]
)
   UPDATE R SET
          R.OriginalSalespersonCode = COALESCE(CU.[Original Salesperson Code],CU.[Salesperson Code])
	    --, R.ResponsibiliyCenter     = CASE WHEN ResponsibiliyCenter='' THEN COALESCE(CU.[Responsibility Center],'IC-CGN') ELSE ResponsibiliyCenter END
	    , R.Continent               = CR.[Continent]
	    , R.Country                 = CR.[Country_Region Code]
     FROM #RESULTS R
	 JOIN CR
	   ON CR.[No_] = R.CompanyName
LEFT JOIN CU
       ON CU.No_ = R.CompanyName

--IF @Filter_Salesperson<>''
--BEGIN
--  DELETE FROM #RESULTS 
--   WHERE [Salesperson_Code] = @DCUser 
--     AND NOT @Filter_Salesperson LIKE '%|'+[OriginalSalespersonCode]+'|%'
--END

--SELECT * FROM #RESULTS WHERE  [Salesperson_Code] = @DCUser 

   UPDATE #RESULTS SET 
          [Salesperson_Code]        = CASE WHEN [Salesperson_Code]='BUCH' AND [ResponsibiliyCenter] <> '' THEN [ResponsibiliyCenter] ELSE [Salesperson_Code] END
        , [OriginalSalespersonCode] = CASE WHEN [Salesperson_Code]='BUCH' AND [ResponsibiliyCenter] <> '' THEN [ResponsibiliyCenter] ELSE [Salesperson_Code] END

--ENDE Rückgabetabelle	
;WITH _RES AS
(
  SELECT [Salesperson_Code]
       , [CountryGroup]
       , SUM([CustBalanceDueLCY1]) [CustBalanceDueLCY1FS]
       , SUM([CustBalanceDueLCY2]) [CustBalanceDueLCY2FS]
       , SUM([CustBalanceDueLCY3]) [CustBalanceDueLCY3FS]
       , SUM([CustBalanceDueLCY4]) [CustBalanceDueLCY4FS]
       , SUM([CustBalanceDueLCY5]) [CustBalanceDueLCY5FS]
       , SUM([CustBalanceDueLCY45]) [CustBalanceDueLCY45FS]
       , SUM([CustBalanceDueLCY45GT]) [CustBalanceDueLCY45GTFS]
       , 0 [CustBalanceDueLCY1PEG]
       , 0 [CustBalanceDueLCY2PEG]
       , 0 [CustBalanceDueLCY3PEG]
       , 0 [CustBalanceDueLCY4PEG]
       , 0 [CustBalanceDueLCY5PEG]
       , 0 [CustBalanceDueLCY45PEG]
       , 0 [CustBalanceDueLCY45GTPEG]
       , SUM([CustBalanceDueLCY1CNY]) [CustBalanceDueLCY1FSCNY]
       , SUM([CustBalanceDueLCY2CNY]) [CustBalanceDueLCY2FSCNY]
       , SUM([CustBalanceDueLCY3CNY]) [CustBalanceDueLCY3FSCNY]
       , SUM([CustBalanceDueLCY4CNY]) [CustBalanceDueLCY4FSCNY]
       , SUM([CustBalanceDueLCY5CNY]) [CustBalanceDueLCY5FSCNY]
       , SUM([CustBalanceDueLCY45CNY]) [CustBalanceDueLCY45FSCNY]
       , SUM([CustBalanceDueLCY45GTCNY]) [CustBalanceDueLCY45GTFSCNY]
       , 0 [CustBalanceDueLCY1PEGCNY]
       , 0 [CustBalanceDueLCY2PEGCNY]
       , 0 [CustBalanceDueLCY3PEGCNY]
       , 0 [CustBalanceDueLCY4PEGCNY]
       , 0 [CustBalanceDueLCY5PEGCNY]
       , 0 [CustBalanceDueLCY45PEGCNY]
       , 0 [CustBalanceDueLCY45GTPEGCNY]
       , SUM([CustBalanceDueLCY1NB])    [CustBalanceDueLCY1FSNB]
       , SUM([CustBalanceDueLCY2NB])    [CustBalanceDueLCY2FSNB]
       , SUM([CustBalanceDueLCY3NB])    [CustBalanceDueLCY3FSNB]
       , SUM([CustBalanceDueLCY4NB])    [CustBalanceDueLCY4FSNB]
       , SUM([CustBalanceDueLCY5NB])    [CustBalanceDueLCY5FSNB]
       , SUM([CustBalanceDueLCY45NB])   [CustBalanceDueLCY45FSNB]
       , SUM([CustBalanceDueLCY45GTNB]) [CustBalanceDueLCY45GTFSNB]
       , 0 [CustBalanceDueLCY1PEGNB]
       , 0 [CustBalanceDueLCY2PEGNB]
       , 0 [CustBalanceDueLCY3PEGNB]
       , 0 [CustBalanceDueLCY4PEGNB]
       , 0 [CustBalanceDueLCY5PEGNB]
       , 0 [CustBalanceDueLCY45PEGNB]
       , 0 [CustBalanceDueLCY45GTPEGNB]
       , SUM([CustBalanceDueLCY1DC])    [CustBalanceDueLCY1FSDC]
       , SUM([CustBalanceDueLCY2DC])    [CustBalanceDueLCY2FSDC]
       , SUM([CustBalanceDueLCY3DC])    [CustBalanceDueLCY3FSDC]
       , SUM([CustBalanceDueLCY4DC])    [CustBalanceDueLCY4FSDC]
       , SUM([CustBalanceDueLCY5DC])    [CustBalanceDueLCY5FSDC]
       , SUM([CustBalanceDueLCY45DC])   [CustBalanceDueLCY45FSDC]
       , SUM([CustBalanceDueLCY45GTDC]) [CustBalanceDueLCY45GTFSDC]
       , 0 [CustBalanceDueLCY1PEGDC]
       , 0 [CustBalanceDueLCY2PEGDC]
       , 0 [CustBalanceDueLCY3PEGDC]
       , 0 [CustBalanceDueLCY4PEGDC]
       , 0 [CustBalanceDueLCY5PEGDC]
       , 0 [CustBalanceDueLCY45PEGDC]
       , 0 [CustBalanceDueLCY45GTPEGDC]
    FROM #RESULTS R
   WHERE [Freesale] = 1 AND [Salesperson_Code] <> ''
     AND (@Filter_Salesperson='' OR NOT(NOT @Filter_Salesperson LIKE '%|'+R.[OriginalSalespersonCode]+'|%' AND [Salesperson_Code] = @DCUser))
	 AND (@Filter_Country=''     OR (@Filter_Country     LIKE '%|'+R.[Country]                +'|%'))
	 AND (@Filter_Continent=''   OR (@Filter_Continent   LIKE '%|'+R.[Continent]              +'|%'))
GROUP BY [Salesperson_Code]
       , [CountryGroup]
UNION
  SELECT [Salesperson_Code]
       , [CountryGroup]
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , SUM([CustBalanceDueLCY1]) 
       , SUM([CustBalanceDueLCY2]) 
       , SUM([CustBalanceDueLCY3]) 
       , SUM([CustBalanceDueLCY4]) 
       , SUM([CustBalanceDueLCY5]) 
       , SUM([CustBalanceDueLCY45]) 
       , SUM([CustBalanceDueLCY45GT]) 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , SUM([CustBalanceDueLCY1CNY]) 
       , SUM([CustBalanceDueLCY2CNY]) 
       , SUM([CustBalanceDueLCY3CNY]) 
       , SUM([CustBalanceDueLCY4CNY]) 
       , SUM([CustBalanceDueLCY5CNY]) 
       , SUM([CustBalanceDueLCY45CNY]) 
       , SUM([CustBalanceDueLCY45GTCNY]) 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , SUM([CustBalanceDueLCY1NB]) 
       , SUM([CustBalanceDueLCY2NB]) 
       , SUM([CustBalanceDueLCY3NB]) 
       , SUM([CustBalanceDueLCY4NB]) 
       , SUM([CustBalanceDueLCY5NB]) 
       , SUM([CustBalanceDueLCY45NB]) 
       , SUM([CustBalanceDueLCY45GTNB]) 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , 0 
       , SUM([CustBalanceDueLCY1DC]) 
       , SUM([CustBalanceDueLCY2DC]) 
       , SUM([CustBalanceDueLCY3DC]) 
       , SUM([CustBalanceDueLCY4DC]) 
       , SUM([CustBalanceDueLCY5DC]) 
       , SUM([CustBalanceDueLCY45DC]) 
       , SUM([CustBalanceDueLCY45GTDC]) 
    FROM #RESULTS R
   WHERE [Freesale] = 0 AND [Salesperson_Code] <> ''
     AND (@Filter_Salesperson='' OR NOT(NOT @Filter_Salesperson LIKE '%|'+R.[OriginalSalespersonCode]+'|%' AND [Salesperson_Code] = @DCUser))
	 AND (@Filter_Country=''     OR (@Filter_Country     LIKE '%|'+R.[Country]                +'|%'))
	 AND (@Filter_Continent=''   OR (@Filter_Continent   LIKE '%|'+R.[Continent]              +'|%'))
GROUP BY [Salesperson_Code]
       , [CountryGroup]
), _CA AS
(
    SELECT [Salesperson Code]
       , MAX(CASE WHEN [Country_Region Code] IN ('33','114') THEN 1 ELSE 0 END) [Differ]
    FROM [HRS$Contact] CO WITH (NOLOCK)
GROUP BY [Salesperson Code] 
UNION
    SELECT [Salesperson Code]
       , MAX(CASE WHEN [Country_Region Code] IN ('33','114') THEN 1 ELSE 0 END) [Differ]
    FROM [HRS-BR$Contact] CO WITH (NOLOCK)
GROUP BY [Salesperson Code] 
UNION
    SELECT [Salesperson Code]
       , MAX(CASE WHEN [Country_Region Code] IN ('33','114') THEN 1 ELSE 0 END) [Differ]
    FROM [HRS-CN$Contact] CO WITH (NOLOCK)
GROUP BY [Salesperson Code] 
), CA AS
(
  SELECT [Salesperson Code]
       , MAX([Differ]) [Differ]
    FROM _CA
GROUP BY [Salesperson Code] 
)
  SELECT [Salesperson_Code]
       , [CountryGroup]
       , (DENSE_RANK() OVER(ORDER BY CASE WHEN (@Filter_Salesperson LIKE '%' + RTRIM([Salesperson_Code]) + '%') OR @Filter_Salesperson = '' THEN 1 ELSE 0 END
	   , CASE WHEN [Salesperson_Code]='BUCH' THEN 'ZZZZ' WHEN [Salesperson_Code] LIKE 'IC-%' THEN 'ZZZZ'+[Salesperson_Code] ELSE [Salesperson_Code] END )) [RowNumber]
       , COALESCE(CA.Differ,0) [Differ]
       , SUM([CustBalanceDueLCY1FS]) [CustBalanceDueLCY1FS]
       , SUM([CustBalanceDueLCY2FS]) [CustBalanceDueLCY2FS]
       , SUM([CustBalanceDueLCY3FS]) [CustBalanceDueLCY3FS]
       , SUM([CustBalanceDueLCY4FS]) [CustBalanceDueLCY4FS]
       , SUM([CustBalanceDueLCY5FS]) [CustBalanceDueLCY5FS]
       , SUM([CustBalanceDueLCY45FS]) [CustBalanceDueLCY45FS]
       , SUM([CustBalanceDueLCY45GTFS]) [CustBalanceDueLCY45GTFS]
       , SUM([CustBalanceDueLCY1PEG]) [CustBalanceDueLCY1PEG]
       , SUM([CustBalanceDueLCY2PEG]) [CustBalanceDueLCY2PEG]
       , SUM([CustBalanceDueLCY3PEG]) [CustBalanceDueLCY3PEG]
       , SUM([CustBalanceDueLCY4PEG]) [CustBalanceDueLCY4PEG]
       , SUM([CustBalanceDueLCY5PEG]) [CustBalanceDueLCY5PEG]
       , SUM([CustBalanceDueLCY45PEG]) [CustBalanceDueLCY45PEG]
       , SUM([CustBalanceDueLCY45GTPEG]) [CustBalanceDueLCY45GTPEG]

       , SUM([CustBalanceDueLCY1FSCNY]) [CustBalanceDueLCY1FSCNY]
       , SUM([CustBalanceDueLCY2FSCNY]) [CustBalanceDueLCY2FSCNY]
       , SUM([CustBalanceDueLCY3FSCNY]) [CustBalanceDueLCY3FSCNY]
       , SUM([CustBalanceDueLCY4FSCNY]) [CustBalanceDueLCY4FSCNY]
       , SUM([CustBalanceDueLCY5FSCNY]) [CustBalanceDueLCY5FSCNY]
       , SUM([CustBalanceDueLCY45FSCNY]) [CustBalanceDueLCY45FSCNY]
       , SUM([CustBalanceDueLCY45GTFSCNY]) [CustBalanceDueLCY45GTFSCNY]
       , SUM([CustBalanceDueLCY1PEGCNY]) [CustBalanceDueLCY1PEGCNY]
       , SUM([CustBalanceDueLCY2PEGCNY]) [CustBalanceDueLCY2PEGCNY]
       , SUM([CustBalanceDueLCY3PEGCNY]) [CustBalanceDueLCY3PEGCNY]
       , SUM([CustBalanceDueLCY4PEGCNY]) [CustBalanceDueLCY4PEGCNY]
       , SUM([CustBalanceDueLCY5PEGCNY]) [CustBalanceDueLCY5PEGCNY]
       , SUM([CustBalanceDueLCY45PEGCNY]) [CustBalanceDueLCY45PEGCNY]
       , SUM([CustBalanceDueLCY45GTPEGCNY]) [CustBalanceDueLCY45GTPEGCNY]

       , SUM([CustBalanceDueLCY5FS])  + SUM([CustBalanceDueLCY4FS])  [less than 30FS]
       , SUM([CustBalanceDueLCY5PEG]) + SUM([CustBalanceDueLCY4PEG]) [less than 30PEG]
       , SUM([CustBalanceDueLCY5FS])  + SUM([CustBalanceDueLCY4FS]) 
       + SUM([CustBalanceDueLCY5PEG]) + SUM([CustBalanceDueLCY4PEG]) [less than 30]

       , SUM([CustBalanceDueLCY2FS])  + SUM([CustBalanceDueLCY1FS])  [greater 60FS]
       , SUM([CustBalanceDueLCY2PEG]) + SUM([CustBalanceDueLCY1PEG]) [greater 60PEG]
       , SUM([CustBalanceDueLCY2FS])  + SUM([CustBalanceDueLCY1FS]) 
       + SUM([CustBalanceDueLCY2PEG]) + SUM([CustBalanceDueLCY1PEG]) [greater 60]
       
       , SUM([CustBalanceDueLCY5FS])  + SUM([CustBalanceDueLCY4FS])  + SUM([CustBalanceDueLCY3FS])  [less than 60FS]
       , SUM([CustBalanceDueLCY5PEG]) + SUM([CustBalanceDueLCY4PEG]) + SUM([CustBalanceDueLCY3PEG]) [less than 60PEG]
       , SUM([CustBalanceDueLCY5FS])  + SUM([CustBalanceDueLCY4FS])  + SUM([CustBalanceDueLCY3FS])
       + SUM([CustBalanceDueLCY5PEG]) + SUM([CustBalanceDueLCY4PEG]) + SUM([CustBalanceDueLCY3PEG]) [less than 60]
       
       , SUM([CustBalanceDueLCY5FSCNY])  + SUM([CustBalanceDueLCY4FSCNY])  [less than 30FSCNY]
       , SUM([CustBalanceDueLCY5PEGCNY]) + SUM([CustBalanceDueLCY4PEGCNY]) [less than 30PEGCNY]
       , SUM([CustBalanceDueLCY5FSCNY])  + SUM([CustBalanceDueLCY4FSCNY]) 
       + SUM([CustBalanceDueLCY5PEGCNY]) + SUM([CustBalanceDueLCY4PEGCNY]) [less than 30CNY]

       , SUM([CustBalanceDueLCY2FSCNY])  + SUM([CustBalanceDueLCY1FSCNY])  [greater 60FSCNY]
       , SUM([CustBalanceDueLCY2PEGCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) [greater 60PEGCNY]
       , SUM([CustBalanceDueLCY2FSCNY])  + SUM([CustBalanceDueLCY1FSCNY]) 
       + SUM([CustBalanceDueLCY2PEGCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) [greater 60CNY]
       
       , SUM([CustBalanceDueLCY5FSCNY])  + SUM([CustBalanceDueLCY4FSCNY])  + SUM([CustBalanceDueLCY3FSCNY])  [less than 60FSCNY]
       , SUM([CustBalanceDueLCY5PEGCNY]) + SUM([CustBalanceDueLCY4PEGCNY]) + SUM([CustBalanceDueLCY3PEGCNY]) [less than 60PEGCNY]
       , SUM([CustBalanceDueLCY5FSCNY])  + SUM([CustBalanceDueLCY4FSCNY])  + SUM([CustBalanceDueLCY3FSCNY])
       + SUM([CustBalanceDueLCY5PEGCNY]) + SUM([CustBalanceDueLCY4PEGCNY]) + SUM([CustBalanceDueLCY3PEGCNY]) [less than 60CNY]

       , (
         SUM([CustBalanceDueLCY5FS]) 
       + SUM([CustBalanceDueLCY4FS]) 
       + SUM([CustBalanceDueLCY3FS]) 
       + SUM([CustBalanceDueLCY2FS]) 
       + SUM([CustBalanceDueLCY1FS]) 
         ) [TotalFS]
       , (
         SUM([CustBalanceDueLCY5PEG]) 
       + SUM([CustBalanceDueLCY4PEG]) 
       + SUM([CustBalanceDueLCY3PEG]) 
       + SUM([CustBalanceDueLCY2PEG]) 
       + SUM([CustBalanceDueLCY1PEG]) 
         ) [TotalPEG]
       , (
         SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG]) 
       + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
       + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
       + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
       + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
         ) [Total]
       , (
         SUM([CustBalanceDueLCY5FSCNY]) 
       + SUM([CustBalanceDueLCY4FSCNY]) 
       + SUM([CustBalanceDueLCY3FSCNY]) 
       + SUM([CustBalanceDueLCY2FSCNY]) 
       + SUM([CustBalanceDueLCY1FSCNY]) 
         ) [TotalFSCNY]
       , (
         SUM([CustBalanceDueLCY5PEGCNY]) 
       + SUM([CustBalanceDueLCY4PEGCNY]) 
       + SUM([CustBalanceDueLCY3PEGCNY]) 
       + SUM([CustBalanceDueLCY2PEGCNY]) 
       + SUM([CustBalanceDueLCY1PEGCNY]) 
         ) [TotalPEGCNY]
       , (
         SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY]) 
       + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
       + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
       + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
       + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
         ) [TotalCNY]
-- ********************************************************
-- * <45, >45 Anteil       
-- ********************************************************
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) = 0 
           THEN 0 ELSE 
                   SUM([CustBalanceDueLCY45GTFS]) 
                 / (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS])
                   ) 
         END [greater 45 FS Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG]) = 0 
           THEN 0 ELSE 
                   SUM([CustBalanceDueLCY45GTPEG]) 
                 / (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [greater 45 PEG Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45GTFS]) + SUM([CustBalanceDueLCY45GTPEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [greater 45 Rate]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45FS]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS])
                   ) 
         END [less than 45 FS Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45PEG]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [less than 45 PEG Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45FS]) + SUM([CustBalanceDueLCY45PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [less than 45 Rate]

-- ********************************************************
-- * <45, >45 Anteil CNY
-- ********************************************************
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) = 0 
           THEN 0 ELSE 
                   SUM([CustBalanceDueLCY45GTFSCNY]) 
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY])
                   ) 
         END [greater 45 FS RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY]) = 0 
           THEN 0 ELSE 
                   SUM([CustBalanceDueLCY45GTPEGCNY]) 
                 / (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [greater 45 PEG RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45GTFSCNY]) + SUM([CustBalanceDueLCY45GTPEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [greater 45 RateCNY]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45FSCNY]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY])
                   ) 
         END [less than 45 FS RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45PEGCNY]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [less than 45 PEG RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY45FSCNY]) + SUM([CustBalanceDueLCY45PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [less than 45 RateCNY]

-- ********************************************************
-- * <60, >60 Anteil       
-- ********************************************************
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS])
                   ) 
         END [greater 60 FS Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [greater 60 PEG Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [greater 60 Rate]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS])
                   ) 
         END [less than 60 FS Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [less than 60 PEG Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [less than 60 Rate]
         
-- ********************************************************
-- * <60, >60 Anteil CNY     
-- ********************************************************
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY])
                   ) 
         END [greater 60 FS RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [greater 60 PEG RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [greater 60 RateCNY]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY])
                   ) 
         END [less than 60 FS RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [less than 60 PEG RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [less than 60 RateCNY]
         
-- ********************************************************
-- * <90, >90 Anteil       
-- ********************************************************
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FS]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS])
                   ) 
         END [greater 90 FS Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [greater 90 PEG Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [greater 90 Rate]
         
       , (
         SUM([CustBalanceDueLCY5FS]) 
       + SUM([CustBalanceDueLCY4FS]) 
       + SUM([CustBalanceDueLCY3FS]) 
       + SUM([CustBalanceDueLCY2FS]) 
         ) [less than 90 FS]
       , (
         SUM([CustBalanceDueLCY5PEG]) 
       + SUM([CustBalanceDueLCY4PEG]) 
       + SUM([CustBalanceDueLCY3PEG]) 
       + SUM([CustBalanceDueLCY2PEG]) 
         ) [less than 90 PEG]
       , (
         SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG]) 
       + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
       + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
       + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
         ) [less than 90]       
         
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FS]) 
                 + SUM([CustBalanceDueLCY4FS]) 
                 + SUM([CustBalanceDueLCY3FS]) 
                 + SUM([CustBalanceDueLCY2FS]) 
                 + SUM([CustBalanceDueLCY1FS])
                   ) 
         END [less than 90 FS Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEG]) 
                 + SUM([CustBalanceDueLCY4PEG]) 
                 + SUM([CustBalanceDueLCY3PEG]) 
                 + SUM([CustBalanceDueLCY2PEG]) 
                 + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [less than 90 PEG Rate]
       , CASE WHEN SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FS]) + SUM([CustBalanceDueLCY5PEG])
                 + SUM([CustBalanceDueLCY4FS]) + SUM([CustBalanceDueLCY4PEG])
                 + SUM([CustBalanceDueLCY3FS]) + SUM([CustBalanceDueLCY3PEG])
                 + SUM([CustBalanceDueLCY2FS]) + SUM([CustBalanceDueLCY2PEG])
                 + SUM([CustBalanceDueLCY1FS]) + SUM([CustBalanceDueLCY1PEG])
                   ) 
         END [less than 90 Rate]
-- ********************************************************
-- * <90, >90 Anteil CNY
-- ********************************************************
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FSCNY]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY])
                   ) 
         END [greater 90 FS RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [greater 90 PEG RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [greater 90 RateCNY]
         
       , (
         SUM([CustBalanceDueLCY5FSCNY]) 
       + SUM([CustBalanceDueLCY4FSCNY]) 
       + SUM([CustBalanceDueLCY3FSCNY]) 
       + SUM([CustBalanceDueLCY2FSCNY]) 
         ) [less than 90 FSCNY]
       , (
         SUM([CustBalanceDueLCY5PEGCNY]) 
       + SUM([CustBalanceDueLCY4PEGCNY]) 
       + SUM([CustBalanceDueLCY3PEGCNY]) 
       + SUM([CustBalanceDueLCY2PEGCNY]) 
         ) [less than 90 PEGCNY]
       , (
         SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY]) 
       + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
       + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
       + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
         ) [less than 90CNY]       
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) 
                 + SUM([CustBalanceDueLCY4FSCNY]) 
                 + SUM([CustBalanceDueLCY3FSCNY]) 
                 + SUM([CustBalanceDueLCY2FSCNY]) 
                 + SUM([CustBalanceDueLCY1FSCNY])
                   ) 
         END [less than 90 FS RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGCNY]) 
                 + SUM([CustBalanceDueLCY4PEGCNY]) 
                 + SUM([CustBalanceDueLCY3PEGCNY]) 
                 + SUM([CustBalanceDueLCY2PEGCNY]) 
                 + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [less than 90 PEG RateCNY]
       , CASE WHEN SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSCNY]) + SUM([CustBalanceDueLCY5PEGCNY])
                 + SUM([CustBalanceDueLCY4FSCNY]) + SUM([CustBalanceDueLCY4PEGCNY])
                 + SUM([CustBalanceDueLCY3FSCNY]) + SUM([CustBalanceDueLCY3PEGCNY])
                 + SUM([CustBalanceDueLCY2FSCNY]) + SUM([CustBalanceDueLCY2PEGCNY])
                 + SUM([CustBalanceDueLCY1FSCNY]) + SUM([CustBalanceDueLCY1PEGCNY])
                   ) 
         END [less than 90 RateCNY]
-- nicht zuigeordnete Zahlungen         
       , SUM([CustBalanceDueLCY1FSNB]) [CustBalanceDueLCY1FSNB]
       , SUM([CustBalanceDueLCY2FSNB]) [CustBalanceDueLCY2FSNB]
       , SUM([CustBalanceDueLCY3FSNB]) [CustBalanceDueLCY3FSNB]
       , SUM([CustBalanceDueLCY4FSNB]) [CustBalanceDueLCY4FSNB]
       , SUM([CustBalanceDueLCY5FSNB]) [CustBalanceDueLCY5FSNB]
       , SUM([CustBalanceDueLCY45FSNB]) [CustBalanceDueLCY45FSNB]
       , SUM([CustBalanceDueLCY45GTFSNB]) [CustBalanceDueLCY45GTFSNB]
       , SUM([CustBalanceDueLCY1PEGNB]) [CustBalanceDueLCY1PEGNB]
       , SUM([CustBalanceDueLCY2PEGNB]) [CustBalanceDueLCY2PEGNB]
       , SUM([CustBalanceDueLCY3PEGNB]) [CustBalanceDueLCY3PEGNB]
       , SUM([CustBalanceDueLCY4PEGNB]) [CustBalanceDueLCY4PEGNB]
       , SUM([CustBalanceDueLCY5PEGNB]) [CustBalanceDueLCY5PEGNB]
       , SUM([CustBalanceDueLCY45PEGNB]) [CustBalanceDueLCY45PEGNB]
       , SUM([CustBalanceDueLCY45GTPEGNB]) [CustBalanceDueLCY45GTPEGNB]
       , SUM([CustBalanceDueLCY5FSNB])  + SUM([CustBalanceDueLCY4FSNB])  [less than 30FSNB]
       , SUM([CustBalanceDueLCY5PEGNB]) + SUM([CustBalanceDueLCY4PEGNB]) [less than 30PEGNB]
       , SUM([CustBalanceDueLCY5FSNB])  + SUM([CustBalanceDueLCY4FSNB]) 
       + SUM([CustBalanceDueLCY5PEGNB]) + SUM([CustBalanceDueLCY4PEGNB]) [less than 30NB]

       , SUM([CustBalanceDueLCY2FSNB])  + SUM([CustBalanceDueLCY1FSNB])  [greater 60FSNB]
       , SUM([CustBalanceDueLCY2PEGNB]) + SUM([CustBalanceDueLCY1PEGNB]) [greater 60PEGNB]
       , SUM([CustBalanceDueLCY2FSNB])  + SUM([CustBalanceDueLCY1FSNB]) 
       + SUM([CustBalanceDueLCY2PEGNB]) + SUM([CustBalanceDueLCY1PEGNB]) [greater 60NB]
       
       , SUM([CustBalanceDueLCY5FSNB])  + SUM([CustBalanceDueLCY4FSNB])  + SUM([CustBalanceDueLCY3FSNB])  [less than 60FSNB]
       , SUM([CustBalanceDueLCY5PEGNB]) + SUM([CustBalanceDueLCY4PEGNB]) + SUM([CustBalanceDueLCY3PEGNB]) [less than 60PEGNB]
       , SUM([CustBalanceDueLCY5FSNB])  + SUM([CustBalanceDueLCY4FSNB])  + SUM([CustBalanceDueLCY3FSNB])
       + SUM([CustBalanceDueLCY5PEGNB]) + SUM([CustBalanceDueLCY4PEGNB]) + SUM([CustBalanceDueLCY3PEGNB]) [less than 60NB]
       
       , (
         SUM([CustBalanceDueLCY5FSNB]) 
       + SUM([CustBalanceDueLCY4FSNB]) 
       + SUM([CustBalanceDueLCY3FSNB]) 
       + SUM([CustBalanceDueLCY2FSNB]) 
       + SUM([CustBalanceDueLCY1FSNB]) 
         ) [TotalFSNB]
       , (
         SUM([CustBalanceDueLCY5PEGNB]) 
       + SUM([CustBalanceDueLCY4PEGNB]) 
       + SUM([CustBalanceDueLCY3PEGNB]) 
       + SUM([CustBalanceDueLCY2PEGNB]) 
       + SUM([CustBalanceDueLCY1PEGNB]) 
         ) [TotalPEGNB]
       , (
         SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB]) 
       + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
       + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
       + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
       + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
         ) [TotalNB]
       
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB])
                   ) 
         END [greater 60 FS RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [greater 60 PEG RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [greater 60 RateNB]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB])
                   ) 
         END [less than 60 FS RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [less than 60 PEG RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [less than 60 RateNB]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FSNB]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB])
                   ) 
         END [greater 90 FS RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1PEGNB])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [greater 90 PEG RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [greater 90 RateNB]
         
       , (
         SUM([CustBalanceDueLCY5FSNB]) 
       + SUM([CustBalanceDueLCY4FSNB]) 
       + SUM([CustBalanceDueLCY3FSNB]) 
       + SUM([CustBalanceDueLCY2FSNB]) 
         ) [less than 90 FSNB]
       , (
         SUM([CustBalanceDueLCY5PEGNB]) 
       + SUM([CustBalanceDueLCY4PEGNB]) 
       + SUM([CustBalanceDueLCY3PEGNB]) 
       + SUM([CustBalanceDueLCY2PEGNB]) 
         ) [less than 90 PEGNB]
       , (
         SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB]) 
       + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
       + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
       + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
         ) [less than 90NB]       
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) 
                 + SUM([CustBalanceDueLCY4FSNB]) 
                 + SUM([CustBalanceDueLCY3FSNB]) 
                 + SUM([CustBalanceDueLCY2FSNB]) 
                 + SUM([CustBalanceDueLCY1FSNB])
                   ) 
         END [less than 90 FS RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGNB]) 
                 + SUM([CustBalanceDueLCY4PEGNB]) 
                 + SUM([CustBalanceDueLCY3PEGNB]) 
                 + SUM([CustBalanceDueLCY2PEGNB]) 
                 + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [less than 90 PEG RateNB]
       , CASE WHEN SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSNB]) + SUM([CustBalanceDueLCY5PEGNB])
                 + SUM([CustBalanceDueLCY4FSNB]) + SUM([CustBalanceDueLCY4PEGNB])
                 + SUM([CustBalanceDueLCY3FSNB]) + SUM([CustBalanceDueLCY3PEGNB])
                 + SUM([CustBalanceDueLCY2FSNB]) + SUM([CustBalanceDueLCY2PEGNB])
                 + SUM([CustBalanceDueLCY1FSNB]) + SUM([CustBalanceDueLCY1PEGNB])
                   ) 
         END [less than 90 RateNB]
         
-- Debit Case
       , SUM([CustBalanceDueLCY1FSDC]) [CustBalanceDueLCY1FSDC]
       , SUM([CustBalanceDueLCY2FSDC]) [CustBalanceDueLCY2FSDC]
       , SUM([CustBalanceDueLCY3FSDC]) [CustBalanceDueLCY3FSDC]
       , SUM([CustBalanceDueLCY4FSDC]) [CustBalanceDueLCY4FSDC]
       , SUM([CustBalanceDueLCY5FSDC]) [CustBalanceDueLCY5FSDC]
       , SUM([CustBalanceDueLCY45FSDC]) [CustBalanceDueLCY45FSDC]
       , SUM([CustBalanceDueLCY45GTFSDC]) [CustBalanceDueLCY45GTFSDC]
       , SUM([CustBalanceDueLCY1PEGDC]) [CustBalanceDueLCY1PEGDC]
       , SUM([CustBalanceDueLCY2PEGDC]) [CustBalanceDueLCY2PEGDC]
       , SUM([CustBalanceDueLCY3PEGDC]) [CustBalanceDueLCY3PEGDC]
       , SUM([CustBalanceDueLCY4PEGDC]) [CustBalanceDueLCY4PEGDC]
       , SUM([CustBalanceDueLCY5PEGDC]) [CustBalanceDueLCY5PEGDC]
       , SUM([CustBalanceDueLCY45PEGDC]) [CustBalanceDueLCY45PEGDC]
       , SUM([CustBalanceDueLCY45GTPEGDC]) [CustBalanceDueLCY45GTPEGDC]
       , SUM([CustBalanceDueLCY5FSDC])  + SUM([CustBalanceDueLCY4FSDC])  [less than 30FSDC]
       , SUM([CustBalanceDueLCY5PEGDC]) + SUM([CustBalanceDueLCY4PEGDC]) [less than 30PEGDC]
       , SUM([CustBalanceDueLCY5FSDC])  + SUM([CustBalanceDueLCY4FSDC]) 
       + SUM([CustBalanceDueLCY5PEGDC]) + SUM([CustBalanceDueLCY4PEGDC]) [less than 30DC]

       , SUM([CustBalanceDueLCY2FSDC])  + SUM([CustBalanceDueLCY1FSDC])  [greater 60FSDC]
       , SUM([CustBalanceDueLCY2PEGDC]) + SUM([CustBalanceDueLCY1PEGDC]) [greater 60PEGDC]
       , SUM([CustBalanceDueLCY2FSDC])  + SUM([CustBalanceDueLCY1FSDC]) 
       + SUM([CustBalanceDueLCY2PEGDC]) + SUM([CustBalanceDueLCY1PEGDC]) [greater 60DC]
       
       , SUM([CustBalanceDueLCY5FSDC])  + SUM([CustBalanceDueLCY4FSDC])  + SUM([CustBalanceDueLCY3FSDC])  [less than 60FSDC]
       , SUM([CustBalanceDueLCY5PEGDC]) + SUM([CustBalanceDueLCY4PEGDC]) + SUM([CustBalanceDueLCY3PEGDC]) [less than 60PEGDC]
       , SUM([CustBalanceDueLCY5FSDC])  + SUM([CustBalanceDueLCY4FSDC])  + SUM([CustBalanceDueLCY3FSDC])
       + SUM([CustBalanceDueLCY5PEGDC]) + SUM([CustBalanceDueLCY4PEGDC]) + SUM([CustBalanceDueLCY3PEGDC]) [less than 60DC]
       
       , (
         SUM([CustBalanceDueLCY5FSDC]) 
       + SUM([CustBalanceDueLCY4FSDC]) 
       + SUM([CustBalanceDueLCY3FSDC]) 
       + SUM([CustBalanceDueLCY2FSDC]) 
       + SUM([CustBalanceDueLCY1FSDC]) 
         ) [TotalFSDC]
       , (
         SUM([CustBalanceDueLCY5PEGDC]) 
       + SUM([CustBalanceDueLCY4PEGDC]) 
       + SUM([CustBalanceDueLCY3PEGDC]) 
       + SUM([CustBalanceDueLCY2PEGDC]) 
       + SUM([CustBalanceDueLCY1PEGDC]) 
         ) [TotalPEGDC]
       , (
         SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC]) 
       + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
       + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
       + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
       + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
         ) [TotalDC]
       
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC])
                   ) 
         END [greater 60 FS RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [greater 60 PEG RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [greater 60 RateDC]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC])
                   ) 
         END [less than 60 FS RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [less than 60 PEG RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [less than 60 RateDC]
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FSDC]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC])
                   ) 
         END [greater 90 FS RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1PEGDC])
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [greater 90 PEG RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [greater 90 RateDC]
         
       , (
         SUM([CustBalanceDueLCY5FSDC]) 
       + SUM([CustBalanceDueLCY4FSDC]) 
       + SUM([CustBalanceDueLCY3FSDC]) 
       + SUM([CustBalanceDueLCY2FSDC]) 
         ) [less than 90 FSDC]
       , (
         SUM([CustBalanceDueLCY5PEGDC]) 
       + SUM([CustBalanceDueLCY4PEGDC]) 
       + SUM([CustBalanceDueLCY3PEGDC]) 
       + SUM([CustBalanceDueLCY2PEGDC]) 
         ) [less than 90 PEGDC]
       , (
         SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC]) 
       + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
       + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
       + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
         ) [less than 90DC]       
         
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                   ) 
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) 
                 + SUM([CustBalanceDueLCY4FSDC]) 
                 + SUM([CustBalanceDueLCY3FSDC]) 
                 + SUM([CustBalanceDueLCY2FSDC]) 
                 + SUM([CustBalanceDueLCY1FSDC])
                   ) 
         END [less than 90 FS RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC]) = 0 
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                   )
                 / (
                   SUM([CustBalanceDueLCY5PEGDC]) 
                 + SUM([CustBalanceDueLCY4PEGDC]) 
                 + SUM([CustBalanceDueLCY3PEGDC]) 
                 + SUM([CustBalanceDueLCY2PEGDC]) 
                 + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [less than 90 PEG RateDC]
       , CASE WHEN SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC]) = 0
           THEN 0 ELSE 
                   (
                   SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                   )
                 / (
                   SUM([CustBalanceDueLCY5FSDC]) + SUM([CustBalanceDueLCY5PEGDC])
                 + SUM([CustBalanceDueLCY4FSDC]) + SUM([CustBalanceDueLCY4PEGDC])
                 + SUM([CustBalanceDueLCY3FSDC]) + SUM([CustBalanceDueLCY3PEGDC])
                 + SUM([CustBalanceDueLCY2FSDC]) + SUM([CustBalanceDueLCY2PEGDC])
                 + SUM([CustBalanceDueLCY1FSDC]) + SUM([CustBalanceDueLCY1PEGDC])
                   ) 
         END [less than 90 RateDC]
         
       , @PEGVisible [PEGVisible]
       , @FSVisible  [FSVisible]
       , @SUMVisible [SUMVisible]
       , CASE WHEN ((@Filter_Salesperson LIKE '%' + RTRIM([Salesperson_Code]) + '%') OR @Filter_Salesperson = '') AND NOT [Salesperson_Code] LIKE 'IC-%'  THEN
           '1'
         ELSE
           '0'
         END [SPVisible]
    FROM _RES
LEFT JOIN CA ON CA.[Salesperson Code] = _RES.Salesperson_Code COLLATE Latin1_General_CI_AS
GROUP BY [Salesperson_Code]
       , [CountryGroup]
       , COALESCE(CA.Differ,0)
ORDER BY [RowNumber]
       , [CountryGroup]  

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
