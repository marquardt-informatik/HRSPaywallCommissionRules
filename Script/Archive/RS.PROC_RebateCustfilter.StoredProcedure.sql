USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_RebateCustfilter]    Script Date: 10.04.2024 14:31:58 ******/
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
		, @ReportId					INT				= 50132
EXEC [RS].[PROC_RebateCustfilter] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_RebateCustfilter] 
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
		  , @TableIDs					[RS].[TableIDs]

  CREATE TABLE #RESULTS 
  (	  
        [Rebate Agreement No_]				VARCHAR(20)
	  , [Rebate-to Vendor No_]				VARCHAR(20)
	  , [Rebate-to Country_Region Code]		VARCHAR(10)
	  , [Rebate-to Country_Region Name]		VARCHAR(50)
	  , [Description]						VARCHAR(250)
	  , [Customer Filter]					VARCHAR(max)
	  , [Partner Type]                      VARCHAR(20)
	  , [Company Filter]                    VARCHAR(max)
	  , [CIBT Filter]                       VARCHAR(max)
	  , [Import Shelf Code]					VARCHAR(20)
	  , [Element Type]						VARCHAR(max)
	  , [Matrix _ Vector Code]				VARCHAR(20)
	  , [VAT Registration No_]              VARCHAR(max)
	  , [E-Mail]                            VARCHAR(max)
	  , [Address]                           VARCHAR(max)
	  , [County]                            VARCHAR(max)
	  , [Post Code]                         VARCHAR(max)
	  , [City]								VARCHAR(100) -- 17.06.20 SAL
-- 24.06.19 SAL >>>
	  , [Salutation Code]					VARCHAR(10)     
	  , [First Name]						VARCHAR(100)
	  , [Last Name]							VARCHAR(100)
	  , [Language]							VARCHAR(10)
	  , [Phone]								VARCHAR(50)
	  , [Fax]								VARCHAR(50)
	  , [Tax Registration No_]				VARCHAR(50)
	  , [Vendor Name]						VARCHAR(150)
	  , [Bank Name]							VARCHAR(50)
	  , [Bank Account No_]					VARCHAR(50)
	  , [IBAN]								VARCHAR(100)
	  , [BIC]								VARCHAR(50)
-- 24.06.19 SAL <<<  
  )

  DELETE FROM @TableIDs
  INSERT INTO @TableIDs 
  VALUES	(50142, 'Rebate Agreement Header')
  SELECT @Stmt = 
'INSERT INTO #RESULTS
SELECT ['+@CompanyName+'$Rebate Agreement Header].[No_]
     , ['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Vendor No_]
     , ['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Country_Region Code]
     , ['+@CompanyName+'$Country_Region].[Name] [Rebate-to Country_Region Name]
     , ['+@CompanyName+'$Rebate Agreement Header].[Description]
     , [dbo].[GetAffiliatePartnerFilter' + CASE WHEN @CompanyName='hotel.de' THEN '_HDE' ELSE '' END + '](['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Vendor No_])
     , CASE ['+@CompanyName+'$Rebate Agreement Header].[Partner Type] WHEN 1 THEN ''Incentive'' WHEN 2 THEN ''Affiliate'' WHEN 3 THEN ''strategic Partner'' WHEN 4 THEN ''Metasearcher'' WHEN 5 THEN ''Mobile'' ELSE '''' END
     , [dbo].[GetCompanyFilter' + CASE WHEN @CompanyName='hotel.de' THEN '_HDE' ELSE '' END + '](['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Vendor No_])
     , [dbo].[GetCIBTFilter' + CASE WHEN @CompanyName='hotel.de' THEN '_HDE' ELSE '' END + '](['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Vendor No_])
     , ['+@CompanyName+'$Rebate Agreement Header].[Import Shelf Code]
     , S.String [Element Type]
     , ['+@CompanyName+'$Rebate Agreement Header].[Matrix _ Vector Code]
	 , ['+@CompanyName+'$Vendor].[VAT Registration No_]
	 , ['+@CompanyName+'$Vendor].[E-Mail]
	 , ['+@CompanyName+'$Vendor].[Address]+'' ''+['+@CompanyName+'$Vendor].[Address 2] [Address]
	 , ['+@CompanyName+'$Vendor].[County]
	 , ['+@CompanyName+'$Vendor].[Post Code]
	 , ['+@CompanyName+'$Vendor].[City]
	 , ['+@CompanyName+'$Rebate Agreement Header].[Salutation Code]
	 , ['+@CompanyName+'$Rebate Agreement Header].[First Name]
	 , ['+@CompanyName+'$Rebate Agreement Header].[Surname]
	 , ['+@CompanyName+'$Language].[ISO Code]
	 , ['+@CompanyName+'$Vendor].[Phone No_]
	 , ['+@CompanyName+'$Vendor].[Fax No_]
	 , ['+@CompanyName+'$Vendor].[Registration No_]
	 , ['+@CompanyName+'$Vendor].[Name] + '' ''+['+@CompanyName+'$Vendor].[Name 2]
	 , ['+@CompanyName+'$Vendor Bank Account].[Name]
	 , ['+@CompanyName+'$Vendor Bank Account].[Bank Account No_]
	 , ['+@CompanyName+'$Vendor Bank Account].[IBAN]
	 , ['+@CompanyName+'$Vendor Bank Account].[SWIFT Code]
  FROM ['+@CompanyName+'$Rebate Agreement Header] WITH (NOLOCK)
  JOIN ['+@CompanyName+'$Country_Region] WITH (NOLOCK)
    ON ['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Country_Region Code] = ['+@CompanyName+'$Country_Region].[Code]
  JOIN ['+@CompanyName+'$Vendor] WITH (NOLOCK)
    ON ['+@CompanyName+'$Vendor].[No_] = ['+@CompanyName+'$Rebate Agreement Header].[Rebate-to Vendor No_]
  JOIN [DynNavHRS].[dbo].[Split] (''Addition,Subtraction,Multiplication,Division,Vector,Matrix,=,<>,<,<=,>,>='','','') S
    ON S.[Index] = ['+@CompanyName+'$Rebate Agreement Header].[Partner Type]+1
LEFT JOIN ['+@CompanyName+'$Language] WITH (NOLOCK) 
    ON ['+@CompanyName+'$Language].[Code] = ['+@CompanyName+'$Vendor].[Language Code]
LEFT JOIN ['+@CompanyName+'$Vendor Bank Account] WITH (NOLOCK) 
    ON ['+@CompanyName+'$Vendor Bank Account].[Vendor No_] = ['+@CompanyName+'$Vendor].[No_] AND ['+@CompanyName+'$Vendor Bank Account].Clearing = 1
 WHERE [Rebate-to Vendor No_] <> '''' '+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 2)+ 'ORDER BY 1'

  PRINT (@Stmt)
  EXEC  (@Stmt)
	
  SELECT * FROM #RESULTS 

  DROP TABLE #RESULTS
END
GO
