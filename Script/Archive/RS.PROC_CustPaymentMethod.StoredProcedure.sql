USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustPaymentMethod]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 04.08.2014
-- Description:	Nav Report 50136
--				Debitor - Elektronische Zahlungformen
--				In der Requestform können die Parameter @EndDate, @MindestsaldoMW und @MaximalSaldoMW angegeben werden.
--				Wenn @MindestsaldoMW oder @MaximalSaldoMW einen Wert beinhalten wird Customer_BalanceDueLCY_Check_ erzeugt und mit JOIN eingebunden.
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 23.01.12                         RP1 Befüllen einer mandantenübergreifender Tabelle für den Excelexport aus NAV
-- 05.02.15 HRS001    93391   ZD    Security level added to report, each user should see his data expect user with special role '00-03-02-EPAYMENT'  
-- 20.02.15 HRS002    93391   TM    All lines will come now from HRS, HRS-CN and HRS-BR 
-- NAV-489  SAK						Testhotel Spalte verursacht Performance Probleme
-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50150
		, @Country					INT				= 1
		, @ContractCode				VARCHAR(250)	= '|01|02|'
EXEC [RS].[PROC_CustPaymentMethod] @UserId, @CompanyName, @ReportId, @Country, @ContractCode
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustPaymentMethod]
(
	  @UserId					VARCHAR(20)
	, @CompanyName				VARCHAR(30)
	, @ReportId					INT
	, @Country					INT
	, @ContractCode				VARCHAR(250)
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE 
          @SQL varchar(max)
--// 05.02.15  ZD >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>           
        , @Filter                     VARCHAR(MAX) = ''    
        , @Filter_Salesperson         VARCHAR(MAX)         
        , @StmtCompanyName            VARCHAR(MAX)         
        , @Stmt                       VARCHAR(MAX)         
		, @TableIDs					  [RS].[TableIDs]      

-- GET USER ID          
SET @Filter_Salesperson =																	
      (SELECT CASE WHEN [Filter Value] = '' THEN '' ELSE RTRIM([Filter Value]) END			
         FROM [RS-Report Execution]															
       WHERE  [Start Company] =  @CompanyName													
          AND [UserID]    =     @UserId											            
          AND [Report ID] =     @ReportId                                                   
          AND [Table ID]  = 0															    
          AND [Field ID]  = 1)																
          PRINT   @Filter_Salesperson														

-- Get Company-Filter
CREATE TABLE #RESULTS_CompanyName 
(
          [CompanyName]             VARCHAR(30)
        , [RowNumber]                     INT
)
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
SELECT 2000000006, 'Company'
SET @StmtCompanyName = '
INSERT INTO #RESULTS_CompanyName
SELECT REPLACE([Name] ,''.'',''_'')
	 , ROW_NUMBER() OVER (ORDER BY [Name])
  FROM [Company] 
WHERE (1=1) 
'+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

SET @StmtCompanyName =@StmtCompanyName 
PRINT	@StmtCompanyName
EXEC   (@StmtCompanyName)

SET @Stmt = ''
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN 'WITH CU AS
( ' ELSE ' 
UNION 
' END)	
+ 'SELECT CU.[No_]
        , CU.[Salesperson Code]
        , CU.[Payment Method Code]
        , CR.[Name] [Country Name]
        , CR.[Continent]
     FROM ['+[CompanyName]+'$Customer] CU WITH (NOLOCK)
     JOIN ['+[CompanyName]+'$Country_Region] CR WITH (NOLOCK)
       ON CR.[Code] = CU.[Country_Region Code]     
    WHERE [Testhotel]<> ''TESTHOTEL''
      AND ''' + @ContractCode + ''' LIKE ''%|''+CU.[Contract Status]+''|%'''     
FROM #RESULTS_CompanyName

SELECT @Stmt = @Stmt
+'), PM AS(
  SELECT CU.[Salesperson Code]' + CASE WHEN @Country = 1 THEN '
       , CU.[Country Name]
       , CU.[Continent]' ELSE '' END + '
       , CASE CU.[Payment Method Code]
           WHEN ''SEPA''       THEN ''SEPA-B2B''
           WHEN ''CORE''       THEN ''CORE-B2C''
           WHEN ''CC_AUTO''    THEN ''CC_AUTO''
           WHEN ''LAST-ES''    THEN ''nat. Lastschriften''
           WHEN ''LAST-FR''    THEN ''nat. Lastschriften''
           WHEN ''LAST-UK''    THEN ''nat. Lastschriften''
           WHEN ''LASTSCHRIF'' THEN ''nat. Lastschriften''
           WHEN ''LAST-IHG''   THEN ''nat. Lastschriften''
           WHEN ''LAST-IT''    THEN ''nat. Lastschriften''
           WHEN ''LAST-AT''    THEN ''nat. Lastschriften''
           WHEN ''HOC''        THEN ''HOC''  
         END [Payment Group]
       , COUNT(1) [Count All Customer]
       , SUM(CASE WHEN CU.[Payment Method Code] IN (''SEPA'',''CORE'',''CC_AUTO'',''LAST-ES'',''LAST-FR'',''LAST-UK'',''LASTSCHRIF'',''LAST-IHG'',''LAST-IT'',''LAST-AT'',''LAST-RID'',''HOC'') THEN 1 ELSE 0 END) [Count Customer]
    FROM CU   
      '+CASE WHEN @Filter_Salesperson = '' THEN '' ELSE 'WHERE ''|'+@Filter_Salesperson+'|'' LIKE ''%|''+CU.[Salesperson Code]+ ''|%'' 'END + '
GROUP BY CU.[Salesperson Code]' + CASE WHEN @Country = 1 THEN '
       , CU.[Country Name]
       , CU.[Continent]' ELSE '' END + ' 
       , CASE CU.[Payment Method Code]
           WHEN ''SEPA''       THEN ''SEPA-B2B''
           WHEN ''CORE''       THEN ''CORE-B2C''
           WHEN ''CC_AUTO''    THEN ''CC_AUTO''
           WHEN ''LAST-ES''    THEN ''nat. Lastschriften''
           WHEN ''LAST-FR''    THEN ''nat. Lastschriften''
           WHEN ''LAST-UK''    THEN ''nat. Lastschriften''
           WHEN ''LASTSCHRIF'' THEN ''nat. Lastschriften''
           WHEN ''LAST-IHG''   THEN ''nat. Lastschriften''
           WHEN ''LAST-IT''    THEN ''nat. Lastschriften''
           WHEN ''LAST-AT''    THEN ''nat. Lastschriften''
           WHEN ''HOC''        THEN ''HOC''
         END 
)
  SELECT ' + CASE WHEN @Country = 1 THEN '
         [Country Name]
       , [Continent]' ELSE '[Salesperson Code]' END + '
       , SUM(CASE WHEN [Payment Group] = ''SEPA-B2B''           THEN [Count Customer] ELSE 0 END) [SEPA-B2B]
       , SUM(CASE WHEN [Payment Group] = ''CORE-B2C''           THEN [Count Customer] ELSE 0 END) [CORE-B2C]
       , SUM(CASE WHEN [Payment Group] = ''CC_AUTO''            THEN [Count Customer] ELSE 0 END) [CC_AUTO]
       , SUM(CASE WHEN [Payment Group] = ''nat. Lastschriften'' THEN [Count Customer] ELSE 0 END) [nat. Lastschriften]
       , SUM(CASE WHEN [Payment Group] = ''HOC''                THEN [Count Customer] ELSE 0 END) [HOC]
       , SUM([Count Customer]) [Total]
       , SUM([Count Customer])*1./SUM([Count All Customer]) [Ratio %]
    FROM PM 
GROUP BY ' + CASE WHEN @Country = 1 THEN '
         [Country Name]
       , [Continent]' ELSE '[Salesperson Code]' END + '
ORDER BY ' + CASE WHEN @Country = 1 THEN 'SUM([Count Customer]) DESC' ELSE '[Salesperson Code]' END        
PRINT(SUBSTRING(@Stmt,1,8000))
PRINT(SUBSTRING(@Stmt,8001,8000))
EXEC (@Stmt)
END
-- // 05.02.15 ZD <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--**********************************************************************************************************
------------------------------ ZD:Original Code From Thomas before 05.02.15 --------------------------------
--**********************************************************************************************************
--SET @SQL = 
--'WITH PM AS
--(
--  SELECT CU.[Salesperson Code]' + CASE WHEN @Country = 1 THEN '
--       , CR.[Name] [Country Name]
--       , CR.[Continent]' ELSE '' END + '
--       , CASE CU.[Payment Method Code]
--           WHEN ''SEPA''       THEN ''SEPA-B2B''
--           WHEN ''CORE''       THEN ''CORE-B2C''
--           WHEN ''CC_AUTO''    THEN ''CC_Auto''
--           WHEN ''LAST-ES''    THEN ''nat. Lastschriften''
--           WHEN ''LAST-FR''    THEN ''nat. Lastschriften''
--           WHEN ''LAST-UK''    THEN ''nat. Lastschriften''
--           WHEN ''LASTSCHRIF'' THEN ''nat. Lastschriften''
--           WHEN ''LAST-IHG''   THEN ''nat. Lastschriften''
--           WHEN ''LAST-IT''    THEN ''nat. Lastschriften''
--           WHEN ''LAST-AT''    THEN ''nat. Lastschriften''
--           WHEN ''HOC''        THEN ''HOC''  
--         END [Payment Group]
--       , COUNT(1) [Count All Customer]
--       , SUM(CASE WHEN CU.[Payment Method Code] IN (''SEPA'',''CORE'',''CC_AUTO'',''LAST-ES'',''LAST-FR'',''LAST-UK'',''LASTSCHRIF'',''LAST-IHG'',''LAST-IT'',''LAST-AT'',''LAST-RID'',''HOC'') THEN 1 ELSE 0 END) [Count Customer]
--    FROM ['+@CompanyName+'$Customer] CU WITH (NOLOCK)
--    JOIN ['+@CompanyName+'$Country_Region] CR WITH (NOLOCK)
--      ON CR.[Code] = CU.[Country_Region Code]
--   WHERE [Testhotel]= 0
--     AND ''' + @ContractCode + ''' LIKE ''%|''+CU.[Contract Status]+''|%''
--GROUP BY CU.[Salesperson Code]' + CASE WHEN @Country = 1 THEN '
--       , CR.[Name]
--       , CR.[Continent]' ELSE '' END + ' 
--       , CASE CU.[Payment Method Code]
--           WHEN ''SEPA''       THEN ''SEPA-B2B''
--           WHEN ''CORE''       THEN ''CORE-B2C''
--           WHEN ''CC_AUTO''    THEN ''CC_Auto''
--           WHEN ''LAST-ES''    THEN ''nat. Lastschriften''
--           WHEN ''LAST-FR''    THEN ''nat. Lastschriften''
--           WHEN ''LAST-UK''    THEN ''nat. Lastschriften''
--           WHEN ''LASTSCHRIF'' THEN ''nat. Lastschriften''
--           WHEN ''LAST-IHG''   THEN ''nat. Lastschriften''
--           WHEN ''LAST-IT''    THEN ''nat. Lastschriften''
--           WHEN ''LAST-AT''    THEN ''nat. Lastschriften''
--           WHEN ''HOC''        THEN ''HOC''
--         END 
--)
--  SELECT ' + CASE WHEN @Country = 1 THEN '
--         [Country Name]
--       , [Continent]' ELSE '[Salesperson Code]' END + '
--       , SUM(CASE WHEN [Payment Group] = ''SEPA-B2B''           THEN [Count Customer] ELSE 0 END) [SEPA-B2B]
--       , SUM(CASE WHEN [Payment Group] = ''CORE-B2C''           THEN [Count Customer] ELSE 0 END) [CORE-B2C]
--       , SUM(CASE WHEN [Payment Group] = ''CC_Auto''            THEN [Count Customer] ELSE 0 END) [CC_Auto]
--       , SUM(CASE WHEN [Payment Group] = ''nat. Lastschriften'' THEN [Count Customer] ELSE 0 END) [nat. Lastschriften]
--       , SUM(CASE WHEN [Payment Group] = ''HOC''                THEN [Count Customer] ELSE 0 END) [HOC]
--       , SUM([Count Customer]) [Total]
--       , SUM([Count Customer])*1./SUM([Count All Customer]) [Ratio %]
--    FROM PM 
--GROUP BY ' + CASE WHEN @Country = 1 THEN '
--         [Country Name]
--       , [Continent]' ELSE '[Salesperson Code]' END + '
--ORDER BY ' + CASE WHEN @Country = 1 THEN 'SUM([Count Customer]) DESC' ELSE '[Salesperson Code]' END        
--PRINT(@SQL) 
--EXEC(@SQL)
--END

GO
