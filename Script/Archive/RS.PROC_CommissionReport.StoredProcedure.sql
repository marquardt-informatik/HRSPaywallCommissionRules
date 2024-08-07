USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CommissionReport]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 25.03.2014
-- Description:	Kommissionsumsatzbericht

-- NAV-411 Wegen Mandant Namen REPLACE hinzugefügt.
-- Es gibt keine Hinweiss zu Posting Date

/*
EXEC [RS].[PROC_CommissionReport] 'TMA04','HRS',50226
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CommissionReport] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
	, @GroupType					INT = 0
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @TableIDs					[RS].[TableIDs]
		, @AliasIDs					[RS].[TableIDs]	
		, @GroupColumn			    VARCHAR(MAX) = '' 

--BEGIN Parameter aus RS-Execution
 SELECT @GroupColumn =
        CASE @GroupType
          WHEN 0 THEN '''Total'''
          WHEN 1 THEN 'CO.[No_]'
          WHEN 2 THEN 'CO.[Chain]'
          WHEN 3 THEN 'CO.[Brand]'
          WHEN 4 THEN 'CO.[Country_Region Code]'
          WHEN 5 THEN 'CONVERT(VARCHAR(10),DATEADD(dd,-DATEPART(dd,[Affiliate Postings].[DepartureDate])+1,[Affiliate Postings].[DepartureDate]),4)'
        END

--END Parameter aus RS-Execution	



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
SELECT REPLACE([Name], ''.'', ''_'') 
	 , ROW_NUMBER() OVER (ORDER BY [Name])
  FROM [Company] 
WHERE (1=1)
'+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl

--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
(			  
    [Row Header]                        VARCHAR(100)
  , [Turnover_LCY]                      DEC(38,20)
  , [Turnover_LCY_corr]                 DEC(38,20)
  , [Turnover_LCY_corr_ratio]           DEC(38,20)
  , [Turnover_LCY_companyrate]          DEC(38,20)
  , [Turnover_LCY_companyrate_ratio]    DEC(38,20)
  , [Amount_LCY]                        DEC(38,20)
  , [Amount_LCY_corr]                   DEC(38,20)
  , [Amount_LCY_corr_ratio]             DEC(38,20)
  , [Avg_Commission_Rate]               DEC(38,20)
  , [RoomNights]                        DEC(38,20)
  , [RoomNights_corr]                   DEC(38,20)
  , [RoomNights_corr_ratio]             DEC(38,20)
  , [RoomNights_companyrate]            DEC(38,20)
  , [RoomNights_companyrate_ratio]      DEC(38,20)
  , [Turnover_Breakfast_LCY]            DEC(38,20)
  , [Turnover_Breakfast_LCY_corr]       DEC(38,20)
  , [Turnover_Breakfast_LCY_corr_ratio] DEC(38,20)
  , [Net_Turnover_LCY]                  DEC(38,20)
  , [Net_Turnover_LCY_corr]             DEC(38,20)
)

DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES(60031, 'Affiliate Postings')


--BEGIN WITH (Mandantenabhängig)
SELECT @Stmt = 'WITH HRS AS (
'
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ''ELSE '
 UNION ALL 
' END)
+'
  SELECT '+@GroupColumn+' [Row Header]
       , SUM([Affiliate Postings].[Turnover_LCY])/1000 [Turnover_LCY]
       , SUM([Affiliate Postings].[Turnover_LCY_corr])/1000 [Turnover_LCY_corr]
       , CASE WHEN SUM([Affiliate Postings].[Turnover_LCY]) = 0 THEN 1 ELSE 1-SUM([Affiliate Postings].[Turnover_LCY_corr])/SUM([Affiliate Postings].[Turnover_LCY]) END [Turnover_LCY_corr_ratio]
       , SUM(CASE WHEN [Affiliate Postings].[CommissionType] = ''Company rate'' THEN [Affiliate Postings].[Turnover_LCY_corr] ELSE 0 END) [Turnover_LCY_companyrate]
       , CASE WHEN SUM([Affiliate Postings].[Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM(CASE WHEN [Affiliate Postings].[CommissionType] = ''Company rate'' THEN [Affiliate Postings].[Turnover_LCY_corr] ELSE 0 END) / SUM([Affiliate Postings].[Turnover_LCY_corr]) END [Turnover_LCY_companyrate_ratio]
       , SUM([Affiliate Postings].[Amount_LCY]) [Amount_LCY]
       , SUM([Affiliate Postings].[Amount_LCY_corr]) [Amount_LCY_corr]
       , CASE WHEN SUM([Affiliate Postings].[Amount_LCY]) = 0 THEN 1 ELSE 1-SUM([Affiliate Postings].[Amount_LCY_corr])/SUM([Affiliate Postings].[Amount_LCY]) END [Amount_LCY_corr_ratio]
       , CASE WHEN SUM([Affiliate Postings].[Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM([Affiliate Postings].[Amount_LCY_corr]) / SUM([Affiliate Postings].[Turnover_LCY_corr]) END [Avg_Commission_Rate]
       , SUM([Affiliate Postings].[RoomNights]) [RoomNights]
       , SUM([Affiliate Postings].[RoomNights_corr]) [RoomNights_corr]
       , CASE WHEN SUM([Affiliate Postings].[RoomNights]) = 0 THEN 1 ELSE 1-SUM([Affiliate Postings].[RoomNights_corr])/SUM([Affiliate Postings].[RoomNights]) END [RoomNights_corr_ratio]
       , SUM(CASE WHEN [Affiliate Postings].[CommissionType] = ''Company rate'' THEN [Affiliate Postings].[RoomNights_corr] ELSE 0 END) [RoomNights_companyrate]
       , CASE WHEN SUM([Affiliate Postings].[RoomNights_corr]) = 0 THEN 1 ELSE SUM(CASE WHEN [Affiliate Postings].[CommissionType] = ''Company rate'' THEN [Affiliate Postings].[RoomNights_corr] ELSE 0 END) / SUM([Affiliate Postings].[RoomNights_corr]) END [RoomNights_companyrate_ratio]
       , SUM([Affiliate Postings].[Turnover_Breakfast_LCY]) [Turnover_Breakfast_LCY]
       , SUM([Affiliate Postings].[Turnover_Breakfast_LCY_corr]) [Turnover_Breakfast_LCY_corr]
       , CASE WHEN SUM([Affiliate Postings].[Turnover_Breakfast_LCY]) = 0 THEN 1 ELSE 1-SUM([Affiliate Postings].[Turnover_Breakfast_LCY_corr])/SUM([Affiliate Postings].[Turnover_Breakfast_LCY]) END [Turnover_Breakfast_LCY_corr_ratio]
       , SUM([Affiliate Postings].[Turnover_LCY] * COALESCE(1.0/(1.0+(FT.[VAT in %]+FT.[Service Tax])/100.),1)) /1000. [Net_Turnover_LCY]
       , SUM([Affiliate Postings].[Turnover_LCY_corr] * COALESCE(1.0/(1.0+(FT.[VAT in %]+FT.[Service Tax])/100.),1)) /1000. [Net_Turnover_LCY_corr]
    FROM [' + [CompanyName] + '$Affiliate Postings] [Affiliate Postings] WITH (NOLOCK)
    JOIN [' + [CompanyName] + '$Contact] CO WITH (NOLOCK) ON CO.No_ = [Affiliate Postings].HotelNo
    JOIN [HRS$Foreign Tax] FT WITH (NOLOCK) ON FT.Country = CO.[Country_Region Code]
   WHERE 1 = 1 '+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 0)
+CASE WHEN @GroupColumn='''Total''' THEN '' ELSE '
GROUP BY ' + @GroupColumn END 
FROM #RESULTS_CompanyName
ORDER BY RowNumber

--2ter Teil					   
SELECT @Stmt = @Stmt
+'  )
  INSERT INTO #RESULTS
  SELECT [Row Header]
       , SUM([Turnover_LCY]) [Turnover_LCY]
       , SUM([Turnover_LCY_corr]) [Turnover_LCY_corr]
       , CASE WHEN SUM([Turnover_LCY]) = 0 THEN 1 ELSE 1-SUM([Turnover_LCY_corr])/SUM([Turnover_LCY]) END [Turnover_LCY_corr_ratio]
       , SUM([Turnover_LCY_companyrate]) [Turnover_LCY_companyrate]
       , CASE WHEN SUM([Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM([Turnover_LCY_companyrate]) / SUM([Turnover_LCY_corr]*1000.) END [Turnover_LCY_companyrate_ratio]
       , SUM([Amount_LCY]) [Amount_LCY]
       , SUM([Amount_LCY_corr]) [Amount_LCY_corr]
       , CASE WHEN SUM([Amount_LCY]) = 0 THEN 1 ELSE 1-SUM([Amount_LCY_corr])/SUM([Amount_LCY]) END [Amount_LCY_corr_ratio]
       , CASE WHEN SUM([Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM([Amount_LCY_corr]) / SUM([Turnover_LCY_corr]*1000.) END [Avg_Commission_Rate]
       , SUM([RoomNights]) [RoomNights]
       , SUM([RoomNights_corr]) [RoomNights_corr]
       , CASE WHEN SUM([RoomNights]) = 0 THEN 1 ELSE 1-SUM([RoomNights_corr])/SUM([RoomNights]) END [RoomNights_corr_ratio]
       , SUM([RoomNights_companyrate]) [RoomNights_companyrate]
       , CASE WHEN SUM([RoomNights_corr]) = 0 THEN 1 ELSE SUM([RoomNights_companyrate]) / SUM([RoomNights_corr]) END [RoomNights_companyrate_ratio]
       , SUM([Turnover_Breakfast_LCY]) [Turnover_Breakfast_LCY]
       , SUM([Turnover_Breakfast_LCY_corr]) [Turnover_Breakfast_LCY_corr]
       , CASE WHEN SUM([Turnover_Breakfast_LCY]) = 0 THEN 1 ELSE 1-SUM([Turnover_Breakfast_LCY_corr])/SUM([Turnover_Breakfast_LCY]) END [Turnover_Breakfast_LCY_corr_ratio]
       , SUM([Net_Turnover_LCY]) [Net_Turnover_LCY]
       , SUM([Net_Turnover_LCY_corr]) [Net_Turnover_LCY_corr]
    FROM HRS       
GROUP BY [Row Header]
ORDER BY [Row Header]
'

PRINT	SUBSTRING(@Stmt,1,8000)
PRINT	SUBSTRING(@Stmt,8001,16000)
PRINT	SUBSTRING(@Stmt,16001,24000)
EXEC   (@Stmt)

SELECT *
  FROM #RESULTS

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END

GO
