USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustDebitChainV9a_New]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- ================================================
-- Author:		Ralph Prangenberg
-- Create date: 24.11.2011
-- Description:	Nav Report 50140; RFC-52420
--				Diese Procedure wird in dem Report CustDebitChainV9.rdl
--				Die Struktur wird nur aus dem HRS Mandanten ermittelt
--
-- 15.06.16   HRS001   TM 

-- HRS$Detailed Cust_ Ledg_ Entry,$10 aktualisiert
-- IX_HRS$Detailed Cust_ Ledg_ Entry_Posting Date um eingeschlossene Spalte [Entry Type] erweitert
-- [IX_HRS$Cust_ Ledger Entry_Reservierungsnr_] neu erstellt
       
-- 05.09.16   NAV-254  SAK
-- 24.11.16   NAV-358  TMA04 [Arrival Date], [Departure Date] instead of [Reservation Date from], [Reservation Date to]
-- 23.04.20 INC0036339 DJU   Replace ';' in [Buchungscode], [Guestname 1] and [Guestname 2]
-- 15.02.20   HRS001   DJU ACS-2201 Added TAF Amount
--
/*
SET Language German
DECLARE   @UserId						VARCHAR(20)		= 'THA04'
		, @CompanyName					VARCHAR(30)		= 'HRS'
		, @ReportId						INT				= 50140
		, @Debug                        INT             = 1
EXEC [RS].[PROC_CustDebitChainV9a] @UserId, @CompanyName, @ReportId, @Debug 
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CustDebitChainV9a_New] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
	, @Debug                        INT = 0
) WITH RECOMPILE
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @Filter					VARCHAR(MAX) = ''
		, @DateFilterStart			VARCHAR(10)
		, @DateFilterEnd			VARCHAR(10)				
		, @Filter_GloDim1			VARCHAR(MAX)		
		, @Filter_GloDim2			VARCHAR(MAX)
		, @Filter_Currency			VARCHAR(MAX)
		, @TableIDs					[RS].[TableIDs]
		, @AliasIDs					[RS].[TableIDs]			

--BEGIN Filter aus den FlowFilter
SET @DateFilterStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 0, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
		AND [Field ID]  = 55), '01.01.1753'),104);	    

SET @DateFilterEnd = CONVERT(VARCHAR(10), COALESCE(
	(SELECT SUBSTRING([Filter Value], 13, 
			CASE WHEN CHARINDEX('..', [Filter Value]) > 0 THEN 11 ELSE 250 END)
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 18
	    AND [Field ID]  = 55), '31.12.2999'), 104);	   

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

--BEGIN Parameter aus RS-Execution
DECLARE   @BallanceFromAllPostings	VARCHAR(1)
		, @VALUEFROM				DECIMAL(38,20) = 0
		, @VALUETO					DECIMAL(38,20) = 0		
SET @BallanceFromAllPostings = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1);	
SET @VALUEFROM = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 2);   
SET @VALUETO = 
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 3);  	    	    
--END Parameter aus RS-Execution	

--BEGIN Mandantenauswahl	
CREATE TABLE #RESULTS_CompanyName 
(
	    [CompanyName]			VARCHAR(30)
	  , [CompanyName2]			VARCHAR(30)
	  , [RowNumber]				INT
)  

DELETE FROM @TableIDs
INSERT INTO @TableIDs 
SELECT 2000000006, 'Company'

SET @StmtCompanyName = '
INSERT INTO #RESULTS_CompanyName
SELECT REPLACE([Name],''.'',''_'') 
     , REPLACE(REPLACE(REPLACE([Name],''.'',''_''),''-'',''_''),'' '',''_'') 
	 , ROW_NUMBER() OVER (ORDER BY [Name])
  FROM [Company] 
WHERE (1=1)
'+ [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @TableIDs, 0)

SET @StmtCompanyName = @StmtCompanyName + @Stmt
PRINT @StmtCompanyName
EXEC   (@StmtCompanyName)
SET @Stmt = ''
--ENDE Mandantenauswahl

--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
	( [Customer No_]											VARCHAR(20)
	, [Entry No_]												INT
	, [Document No_]											VARCHAR(30)
	, [Document Type]											INT
	, [Rg__Gs_-Art]												INT
	, [Open]													TINYINT
	, [Sell-to Customer No_]									VARCHAR(20)
	, [Belegart]												VARCHAR(20)
	, [Description]												VARCHAR(70)
	, [Currency Code]											VARCHAR(10)
	, [Transaction No_]											INT
	, [Document Date]											DATETIME
	, [Country]													VARCHAR(10)
	, [HotelNo]													VARCHAR(20)
	, [Hotel]													VARCHAR(130)
	, [Hotel city]												VARCHAR(70)
	, [Salesperson Code]										VARCHAR(10)
	, [HotelPropID]												VARCHAR(30)
	, [VertragStatus]											VARCHAR(30)
	, [Country Name]											VARCHAR(50)
	, [Kette]													VARCHAR(10)
	, [Kette Description]										VARCHAR(50)
	, [Connect]													VARCHAR(20)
	, [Reservierungsnr_]										INT --PRIMARY KEY --VARCHAR(20)
	, [Guestname 1]												VARCHAR(120)
	, [Guestname 2]												VARCHAR(120)
	, [Arrival]													DATETIME
	, [Departure]												DATETIME
	, [VAT]														DEC(38,20)
	, [Buchungscode]											VARCHAR(80)
	, [Rate Typ]												INT
	, [Rate Bezeichnung]										VARCHAR(100)
	, [User]													VARCHAR(30)
	, [Amount of Debits]										MONEY
	, [Saldo]													DEC(38,20)
	, [CustSaldo]												DEC(38,20)
	, [Restbetrag]												DEC(38,20)
	, [Orgbetrag]												DEC(38,20)
	, [MWbetrag]												DEC(38,20)
	, [KettenSaldo]												DEC(38,20)
	, [LandKettenSaldo]											DEC(38,20)
	, [Unknown_R]												DEC(38,20)
	, [Initial Entry_R]											DEC(38,20)
	, [Application_R]											DEC(38,20)
	, [Unrealized Loss_R]										DEC(38,20)
	, [Unrealized Gain_R]										DEC(38,20)
	, [Realized Loss_R]											DEC(38,20)
	, [Realized Gain_R]											DEC(38,20)
	, [Payment Discount_Payment_R]								DEC(38,20)
	, [Payment Discount (VAT Excl.)_Payment_R]					DEC(38,20)
	, [Payment Discount (VAT Adjustment)_Payment_R]				DEC(38,20)
	, [ppln. Rounding_Payment_R]								DEC(38,20)
	, [Correction of Remaining Amount_Payment_R]				DEC(38,20)
	, [Payment Tolerance_Payment_R]								DEC(38,20)
	, [Payment Discount Tolerance_Payment_R]					DEC(38,20)
	, [Payment Tolerance (VAT Excl.)_Payment_R]					DEC(38,20)
	, [Payment Tolerance (VAT Adjustment)_Payment_R]			DEC(38,20)
	, [Payment Discount Tolerance (VAT Excl.)_Payment_R]		DEC(38,20)
	, [Payment Discount Tolerance (VAT Adjustment)_Payment_R]	DEC(38,20)
	, [Team]													VARCHAR(10)	
	-- HRS001 >>
	, [Commission Amount]										DEC(38,20)
	, [TAF Amount]												DEC(38,20)
	-- HRS001 <<
	, [Difference]												DEC(38,20)
)

-- 1. Teil
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES(18, 'Customer')

CREATE TABLE #CS (Company VARCHAR(30) COLLATE Latin1_General_CS_AS,ChainCode VARCHAR(10) COLLATE Latin1_General_CS_AS, ChainSaldo DECIMAL(37,20),PRIMARY KEY (Company,ChainCode))
CREATE TABLE #CCS (Company VARCHAR(30) COLLATE Latin1_General_CS_AS,CountryCode varchar(20) COLLATE Latin1_General_CS_AS, ChainCode VARCHAR(10) COLLATE Latin1_General_CS_AS, CountryChainSaldo DECIMAL(37,20), PRIMARY KEY (Company,CountryCode, ChainCode))
CREATE TABLE #CUS (Company VARCHAR(30) COLLATE Latin1_General_CS_AS,Customer varchar(20) COLLATE Latin1_General_CS_AS, Saldo DECIMAL(37,20), CustSaldo DECIMAL(37,20), PRIMARY KEY (Company,Customer))

  SELECT @Stmt = @Stmt
--       +            'DECLARE @CS_'+[CompanyName2]+' TABLE (ChainCode VARCHAR(10) PRIMARY KEY, ChainSaldo DECIMAL(37,20))' 
	   + CHAR(13) + '; WITH [_ChainSaldo_'+[CompanyName]+'] AS'
	   + CHAR(13) + '('
	   + CHAR(13) + '   SELECT '''+[CompanyName]+''' AS Company'
	   + CHAR(13) + '        , ['+[CompanyName]+'$Customer].[Chain] 											AS ChainCode'
	   + CHAR(13) + '        , COALESCE(SUM(CLE.[SUM$Amount (LCY)]), 0)	AS ChainSaldo'
	   + CHAR(13) + '     FROM ['+[CompanyName]+'$Customer]                                WITH (READUNCOMMITTED)'
	   + CHAR(13) + 'LEFT JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$13] CLE WITH (READUNCOMMITTED)'
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Customer].[No_] = CLE.[Customer No_]'
	   + CHAR(13) + 'LEFT JOIN ['+[CompanyName]+'$Cust_ Ledger Entry]                      WITH (READUNCOMMITTED)'  
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_] = CLE.[Entry No_] '
	   + CHAR(13) + '       AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''	    
	   + CHAR(13) + '    WHERE (1=1) --CLE.[Posting Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''
	   + CHAR(13) + ''+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)
	   + CHAR(13) + ' GROUP BY ['+[CompanyName]+'$Customer].[Chain]'
	   + CHAR(13) + ')'
--	   + CHAR(13) + 'INSERT INTO @CS_'+[CompanyName2]
	   + CHAR(13) + 'INSERT INTO #CS'
	   + CHAR(13) + 'SELECT * FROM [_ChainSaldo_'+[CompanyName]+']'
	   + CHAR(13) + ''
--	   + CHAR(13) + 'DECLARE @CCS_'+[CompanyName2]+' TABLE (CountryCode varchar(20), ChainCode VARCHAR(10), CountryChainSaldo DECIMAL(37,20), PRIMARY KEY (CountryCode, ChainCode))'
	   + CHAR(13) + ';WITH [_CountryChainSaldo_'+[CompanyName]+'] AS'
	   + CHAR(13) + '('
	   + CHAR(13) + '   SELECT '''+[CompanyName]+''' AS Company'
	   + CHAR(13) + '        , ['+[CompanyName]+'$Customer].[Country_Region Code]     AS CountryCode'
	   + CHAR(13) + '        , ['+[CompanyName]+'$Customer].[Chain]                   AS ChainCode'
	   + CHAR(13) + '        , COALESCE(SUM(CLE.[SUM$Amount (LCY)]), 0) AS CountryChainSaldo'
	   + CHAR(13) + '     FROM ['+[CompanyName]+'$Customer]                                WITH (READUNCOMMITTED)'
	   + CHAR(13) + 'LEFT JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$13] CLE WITH (READUNCOMMITTED)'
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Customer].[No_] = CLE.[Customer No_]'
	   + CHAR(13) + 'LEFT JOIN ['+[CompanyName]+'$Cust_ Ledger Entry]                      WITH (READUNCOMMITTED)'  
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_] = CLE.[Entry No_] '
	   + CHAR(13) + '       AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''	    	   
	   + CHAR(13) + '    WHERE (1=1) --CLE.[Posting Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''
	   + CHAR(13) + ''+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)
	   + CHAR(13) + ' GROUP BY ['+[CompanyName]+'$Customer].[Country_Region Code]'
	   + CHAR(13) + '        , ['+[CompanyName]+'$Customer].[Chain] '
	   + CHAR(13) + ')'
--	   + CHAR(13) + 'INSERT INTO @CCS_'+[CompanyName2]
	   + CHAR(13) + 'INSERT INTO #CCS'
	   + CHAR(13) + 'SELECT * FROM [_CountryChainSaldo_'+[CompanyName]+']'
	   + CHAR(13) + ''
--	   + CHAR(13) + 'DECLARE @CUS_'+[CompanyName2]+' TABLE (Customer varchar(20), Saldo DECIMAL(37,20), CustSaldo DECIMAL(37,20), PRIMARY KEY (Customer))'
	   + CHAR(13) + ';WITH [_CustomerSaldo_'+[CompanyName]+'] AS'
	   + CHAR(13) + '('
	   + CHAR(13) + '   SELECT '''+[CompanyName]+''' AS Company'
	   + CHAR(13) + '        , ['+[CompanyName]+'$Customer].[No_]                     AS Customer'
	   + CHAR(13) + '        , COALESCE(SUM(CLE.[SUM$Amount (LCY)]), 0) AS Saldo'
	   + CHAR(13) + '        , COALESCE(SUM(CLE.[SUM$Amount]), 0)       AS CustSaldo'
	   + CHAR(13) + '     FROM ['+[CompanyName]+'$Customer]                                WITH (READUNCOMMITTED)'
	   + CHAR(13) + 'LEFT JOIN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry$VSIFT$13] CLE WITH (READUNCOMMITTED)'
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Customer].[No_] = CLE.[Customer No_]'
	   + CHAR(13) + 'LEFT JOIN ['+[CompanyName]+'$Cust_ Ledger Entry]                      WITH (READUNCOMMITTED)'  
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_] = CLE.[Entry No_] '
	   + CHAR(13) + '       AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''	    	   
	   + CHAR(13) + '    WHERE (1=1) --CLE.[Posting Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''
	   + CHAR(13) + ''+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)
	   + CHAR(13) + ' GROUP BY ['+[CompanyName]+'$Customer].[No_]'
	   + CHAR(13) + ')'
--	   + CHAR(13) + 'INSERT INTO @CUS_'+[CompanyName2]
	   + CHAR(13) + 'INSERT INTO #CUS'
	   + CHAR(13) + 'SELECT * FROM [_CustomerSaldo_'+[CompanyName]+']'
	   + CHAR(13) + ''
    FROM #RESULTS_CompanyName
ORDER BY RowNumber
PRINT @Stmt

--1ter Teile
--BEGIN WITH Teil (Mandantenabhängig)
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES(18, 'Customer')
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN '; WITH 'ELSE ' , ' END)
	   + CHAR(13) + '[_BookingSums_'+[CompanyName]+'] AS'
	   + CHAR(13) + '('
	   + CHAR(13) + '   SELECT ['+[CompanyName]+'$Cust_ Ledger Entry].[Reservierungsnr_]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  0 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Unknown_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  1 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Initial Entry_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  2 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Application_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  3 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Unrealized Loss_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  4 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Unrealized Gain_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  5 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Realized Loss_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  6 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Realized Gain_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  7 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Discount_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  8 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Discount (VAT Excl.)_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] =  9 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Discount (VAT Adjustment)_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 10 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [ppln. Rounding_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 11 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Correction of Remaining Amount_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 12 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Tolerance_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 13 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Discount Tolerance_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 14 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Tolerance (VAT Excl.)_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 15 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Tolerance (VAT Adjustment)_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 16 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Discount Tolerance (VAT Excl.)_Payment_R]'
	   + CHAR(13) + '        , SUM(CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] = 17 THEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount (LCY)] ELSE 0 END) AS [Payment Discount Tolerance (VAT Adjustment)_Payment_R]'
	   + CHAR(13) + '     FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry] WITH (READUNCOMMITTED)'
	   + CHAR(13) + '     JOIN ['+[CompanyName]+'$Cust_ Ledger Entry]         WITH (READUNCOMMITTED)'  
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Cust_ Ledger Entry No_]=['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]'
	   + CHAR(13) + '	  JOIN ['+[CompanyName]+'$Customer]' 
	   + CHAR(13) + '	    ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_]'
	   + CHAR(13) + '    WHERE ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''
	   + CHAR(13) + ''+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)
	   + CHAR(13) + ' GROUP BY [Reservierungsnr_]'
	   + CHAR(13) + '),'
	   + CHAR(13) + '[_DebPostenRestbetragErmitteln_'+[CompanyName]+'] AS'
	   + CHAR(13) + '('
	   + CHAR(13) + '   SELECT [Cust_ Ledger Entry No_]                         AS DebPostenNr'
	   + CHAR(13) + '        , SUM([Amount (LCY)])                              AS [Restbetrag (LCY)]'
	   + CHAR(13) + '        , SUM(['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Amount])   AS [Betrag]'
	   + CHAR(13) + '        , SUM('
	   + CHAR(13) + '		  CASE WHEN ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Entry Type] <> 2 '
	   + CHAR(13) + '		    THEN [Amount (LCY)] '
	   + CHAR(13) + '			ELSE 0 '
	   + CHAR(13) + '          END)                                             AS [MWBetrag]'
	   + CHAR(13) + '     FROM ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry] WITH (READUNCOMMITTED)'
	   + CHAR(13) + '     JOIN ['+[CompanyName]+'$Cust_ Ledger Entry]         WITH (READUNCOMMITTED)'  
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Cust_ Ledger Entry No_]=['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]'	   
	   + CHAR(13) + '     JOIN ['+[CompanyName]+'$Customer] '
	   + CHAR(13) + '       ON ['+[CompanyName]+'$Customer].[No_] = ['+[CompanyName]+'$Detailed Cust_ Ledg_ Entry].[Customer No_]'
	   + CHAR(13) + '    WHERE ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+''''
	   + CHAR(13) + ''+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)
	   + CHAR(13) + ' GROUP BY [Cust_ Ledger Entry No_]'
	   + CHAR(13) + '),'
+'
          [_PaymentUser_'+[CompanyName]+'] AS
          (
            SELECT I.[Reservierungsnummer] AS [Reservierungsnr_]
                 , MAX(I.[User]) AS [User]
              FROM ['+[CompanyName]+'$CDG Import Zahlungszentralen] I WITH (READUNCOMMITTED)
          GROUP BY [Reservierungsnummer]
          )
          , [_AgencyHeader_'+[CompanyName]+'] AS
          (
            SELECT AH.[Posted Invoice No_] 
                 , AL.[MuseID]
                 , AL.[Reservation No_]
                 , AL.[Client Guestname 1]     AS [Guestname 1]
                 , AL.[Client Guestname 2]     AS [Guestname 2]
                 , MIN(AL.[Arrival Date]) AS Arrival
                 , MAX(AL.[Departure Date])   AS Departure
-- NAV-358: 24.11.16 TMA04 Reservierung 147925257 zeigt falsches Datum
--                 , MIN(AL.[Reservation Date from]) AS Arrival
--                 , MAX(AL.[Reservation Date to])   AS Departure
                 , AL.[Booking Code]           AS Buchungscode
                 , AL.[Rate Type]              AS [Rate Typ]
                 , AL.[Rate Description]       AS [Rate Bezeichnung]
                 , SUM(AL.[Line Amount] 
                 / AL.[Currency Faktor])       AS [Amount of Debits]
				 , SUM(AL.[Line Amount]
				 - AL.[TAF Line Amount])       AS [Commission Amount]
				 , SUM(AL.[TAF Line Amount])   AS [TAF Amount]
              FROM ['+[CompanyName]+'$Agency Display Line]   AL WITH (NOLOCK)
              JOIN ['+[CompanyName]+'$Agency Display Header] AH WITH (NOLOCK)
                ON AH.[Case No_] = AL.[Display Case No_]
               AND AL.[Action] <> 3
              JOIN ['+[CompanyName]+'$Customer]                 WITH (NOLOCK)
                ON ['+[CompanyName]+'$Customer].[No_] = AH.[Bill-to Customer No_]
             WHERE (1=1) ' +[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)+ '
          GROUP BY AH.[Posted Invoice No_] 
                 , AL.[MuseID]
                 , AL.[Reservation No_]
                 , AL.[Client Guestname 1]
                 , AL.[Client Guestname 2]
                 , AL.[Booking Code]
                 , AL.[Rate Type]
                 , AL.[Rate Description]              
          )
          , [_Result_'+[CompanyName]+'] AS
          (
     SELECT ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Document No_]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Rg__Gs_-Art]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Open]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Sell-to Customer No_]
          , CASE ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type] 
              WHEN 0 THEN ''Booking'' 
              WHEN 1 THEN ''Payment'' 
              WHEN 2 THEN ''Invoice'' 
              WHEN 3 THEN ''Credit Memo''
              ELSE ''unknown'' 
            END																		AS Belegart
          , ['+[CompanyName]+'$Cust_ Ledger Entry].Description
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Currency Code]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Transaction No_]
          , ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date]
          , ['+[CompanyName]+'$Customer].[Country_Region Code]                      AS Country
          , ['+[CompanyName]+'$Customer].No_                                        AS HotelNo
          , ['+[CompanyName]+'$Customer].Name                                       AS Hotel
          , ['+[CompanyName]+'$Customer].City                                       AS [Hotel city]
          , ['+[CompanyName]+'$Customer].[Salesperson Code]                         AS [Salesperson Code]
          , ['+[CompanyName]+'$Customer].AccorHotelCode                             AS HotelPropID
          , CASE ['+[CompanyName]+'$Customer].[Contract Status] --Gibt es [Job Contract Status] am Custonmer???????
              WHEN  0 THEN ''NO_CONTRACT''
              WHEN  1 THEN ''FREE_SALE''
              WHEN  2 THEN ''FREE_SALE_CHAIN''
              WHEN  3 THEN ''REQUEST_HOTEL''
              WHEN  4 THEN ''REQUEST_CHAIN''
              WHEN  5 THEN ''REQUEST_WITHOUT_CONTRACT''
              WHEN  6 THEN ''CONTRACT_HAS_ERRORS''
              WHEN  7 THEN ''REFUSAL''
              WHEN  8 THEN ''COMPANY_RATE_TO_HOTEL''
              WHEN  9 THEN ''COMPANY_RATE_TO_CHAIN''
              WHEN 10 THEN ''CRS''
              WHEN 11 THEN ''NON_HRS_WITHOUT_CONTRACT''
              WHEN 12 THEN ''UNVERIFIED''
              ELSE ''unknown'' 
            END																		AS VertragStatus
          , ['+[CompanyName]+'$Country_Region].[Name]                               AS [Country Name]
          , ['+[CompanyName]+'$Customer].[Chain]                                    AS Kette
          , ['+[CompanyName]+'$Dimension Value].[Name]                              AS [Kette Description]
          , [_AgencyHeader_'+[CompanyName]+'].MuseID			  					AS Connect
          , [_AgencyHeader_'+[CompanyName]+'].[Reservation No_]
          , REPLACE([_AgencyHeader_'+[CompanyName]+'].[Guestname 1], '';'', '','')  AS [Guestname 1]
          , REPLACE([_AgencyHeader_'+[CompanyName]+'].[Guestname 2], '';'', '','')  AS [Guestname 2]
          , [_AgencyHeader_'+[CompanyName]+'].Arrival
          , [_AgencyHeader_'+[CompanyName]+'].Departure
          , CASE WHEN ['+[CompanyName]+'$Sales Invoice Header].[VAT Bus_ Posting Group]=''INLAND'' THEN 19 ELSE 0 END AS VAT
          , REPLACE([_AgencyHeader_'+[CompanyName]+'].Buchungscode, '';'', '','')   AS Buchungscode
          , [_AgencyHeader_'+[CompanyName]+'].[Rate Typ]
          , [_AgencyHeader_'+[CompanyName]+'].[Rate Bezeichnung]
          , [PaymentUser].[User]													AS [User]
          , ROUND([_AgencyHeader_'+[CompanyName]+'].[Amount of Debits] * CASE WHEN ['+[CompanyName]+'$Sales Invoice Header].[VAT Bus_ Posting Group]=''INLAND'' THEN 1.19 ELSE 1 END, 2) AS [Amount of Debits]
          , ISNULL(CustomerSaldo.Saldo,0)											AS Saldo
          , ISNULL(CustomerSaldo.CustSaldo,0)										AS CustSaldo
          , ISNULL(DebPostenRestbetragErmitteln.[Restbetrag (LCY)],0)				AS Restbetrag
          , ISNULL(DebPostenRestbetragErmitteln.[Betrag],0)							AS Orgbetrag
          , ISNULL(DebPostenRestbetragErmitteln.[MWBetrag],0)						AS MWbetrag
          , ChainSaldo AS KettenSaldo
          , CountryChainSaldo AS LandKettenSaldo
          , [Unknown_R]
          , [Initial Entry_R]
          , [Application_R]
          , [Unrealized Loss_R]
          , [Unrealized Gain_R]
          , [Realized Loss_R]
          , [Realized Gain_R]
          , [Payment Discount_Payment_R]
          , [Payment Discount (VAT Excl.)_Payment_R]
          , [Payment Discount (VAT Adjustment)_Payment_R]
          , [ppln. Rounding_Payment_R]
          , [Correction of Remaining Amount_Payment_R]
          , [Payment Tolerance_Payment_R]
          , [Payment Discount Tolerance_Payment_R]
          , [Payment Tolerance (VAT Excl.)_Payment_R]
          , [Payment Tolerance (VAT Adjustment)_Payment_R]
          , [Payment Discount Tolerance (VAT Excl.)_Payment_R]
          , [Payment Discount Tolerance (VAT Adjustment)_Payment_R]
          , ['+[CompanyName]+'$Customer].[Responsibility Center]			AS Team
		  , [_AgencyHeader_'+[CompanyName]+'].[Commission Amount]
		  , [_AgencyHeader_'+[CompanyName]+'].[TAF Amount]
       FROM ['+[CompanyName]+'$Cust_ Ledger Entry] WITH (READUNCOMMITTED)
       JOIN ['+[CompanyName]+'$Customer]           WITH (READUNCOMMITTED)          
         ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_]      = ['+[CompanyName]+'$Customer].[No_] 
	   JOIN ['+[CompanyName]+'$Dimension Value] WITH (READUNCOMMITTED)				
         ON ['+[CompanyName]+'$Dimension Value].Code = ['+[CompanyName]+'$Customer].[Chain]
        AND ['+[CompanyName]+'$Dimension Value].[Dimension Code] = '''+'CHAIN'+'''
--       JOIN @CS_'+[CompanyName2]+' [ChainSaldo]             
       JOIN #CS [ChainSaldo]             
         ON ['+[CompanyName]+'$Customer].[Chain]          = [ChainSaldo].[ChainCode] 
        AND [ChainSaldo].[Company]='''+[CompanyName]+'''
       JOIN ['+[CompanyName]+'$Country_Region]            WITH (READUNCOMMITTED)
         ON ['+[CompanyName]+'$Customer].[Country_Region Code]         = ['+[CompanyName]+'$Country_Region].[Code] 
--       JOIN @CCS_'+[CompanyName2]+' [CountryChainSaldo] 
       JOIN #CCS [CountryChainSaldo] 
         ON ['+[CompanyName]+'$Customer].[Country_Region Code]                = [CountryChainSaldo].[CountryCode] 
        AND ['+[CompanyName]+'$Customer].[Chain]         = [CountryChainSaldo].[ChainCode]
        AND [CountryChainSaldo].[Company]='''+[CompanyName]+'''
       JOIN [_DebPostenRestbetragErmitteln_'+[CompanyName]+']				[DebPostenRestbetragErmitteln] 
         ON [DebPostenRestbetragErmitteln].[DebPostenNr] = ['+[CompanyName]+'$Cust_ Ledger Entry].[Entry No_]
--       JOIN @CUS_'+[CompanyName2]+' [CustomerSaldo] 	
       JOIN #CUS [CustomerSaldo] 	
         ON [CustomerSaldo].[Customer]                   = ['+[CompanyName]+'$Cust_ Ledger Entry].[Customer No_] 
        AND [CustomerSaldo].[Company]='''+[CompanyName]+'''
  LEFT JOIN ['+[CompanyName]+'$Sales Invoice Header] WITH (READUNCOMMITTED)
         ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Document No_]      = ['+[CompanyName]+'$Sales Invoice Header].[No_] 
		AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type]     = 2 
        AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Rg__Gs_-Art]       IN (0,1) --= 1
  LEFT JOIN [_AgencyHeader_'+[CompanyName]+']   WITH (READUNCOMMITTED)
         ON ['+[CompanyName]+'$Cust_ Ledger Entry].[Document No_]      = [_AgencyHeader_'+[CompanyName]+'].[Posted Invoice No_] 
        AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Type]     = 2 
        AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Rg__Gs_-Art]       IN (0,1) --= 1  
  LEFT JOIN [_BookingSums_'+[CompanyName]+'] [BookingSums]
         ON [BookingSums].[Reservierungsnr_]             = [_AgencyHeader_'+[CompanyName]+'].[Reservation No_] 
  LEFT JOIN [_PaymentUser_'+[CompanyName]+']								[PaymentUser]
         ON [PaymentUser].[Reservierungsnr_]             = [_AgencyHeader_'+[CompanyName]+'].[Reservation No_] 
      WHERE ['+[CompanyName]+'$Cust_ Ledger Entry].[Open]              = 1
        AND ['+[CompanyName]+'$Cust_ Ledger Entry].[Document Date] BETWEEN '''+@DateFilterStart+''' AND '''+@DateFilterEnd+'''
		    '+[RS].[Nav2SqlString](@UserId, #RESULTS_CompanyName.[CompanyName], @ReportId, @TableIDs, 3)+'
          )
          , [_ResultSum_'+[CompanyName]+'] AS
          (
               SELECT [Document No_]
                    , SUM(COALESCE([Amount of Debits],0.0) - COALESCE([Application_R],0.0)) [Difference]
                 FROM [_Result_'+[CompanyName]+']
             GROUP BY [Document No_]
          )'
FROM #RESULTS_CompanyName
ORDER BY RowNumber

--2ter Teil	
DELETE FROM @TableIDs
INSERT INTO @TableIDs 
VALUES	(18, 'Customer')		   
SELECT @Stmt = @Stmt
+(SELECT CASE WHEN RowNumber = 1 THEN ' INSERT INTO #RESULTS ' ELSE ' UNION ALL ' END)	
+'
     SELECT [_Result_'+[CompanyName]+'].*,[Difference]-Restbetrag [Difference]
       FROM [_Result_'+[CompanyName]+']
       JOIN [_ResultSum_'+[CompanyName]+'] ON [_ResultSum_'+[CompanyName]+'].[Document No_] = [_Result_'+[CompanyName]+'].[Document No_]
      WHERE (1 = 1)
        '  
         +CASE WHEN @VALUEFROM	<> 0  THEN +' AND Saldo >= '+CAST(@VALUEFROM AS VARCHAR) ELSE '' END
         +CASE WHEN @VALUETO	<> 0  THEN +' AND Saldo <= '+CAST(@VALUETO AS VARCHAR)  ELSE '' END+
        '
        AND ((COALESCE([Amount of Debits],0.0) - COALESCE([Application_R],0.0) <> 0.0) OR Belegart<>''Invoice'')
        AND Saldo <> 0.0' 
	FROM #RESULTS_CompanyName
ORDER BY RowNumber 

SELECT @Stmt = @Stmt + ' OPTION (MAXDOP 2)'
IF @Debug=1
BEGIN
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
PRINT	SUBSTRING(@Stmt,80001,8000)
PRINT	SUBSTRING(@Stmt,88001,8000)
END

IF @Debug=0
  EXEC   (@Stmt)
--ENDE Rückgabetabelle

  SELECT R.*
       , BU.EXTERNAL_BOOKING_SEGMENT [IATA] 
    FROM #RESULTS R 
LEFT JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY =R.[Reservierungsnr_]
ORDER BY [Document Date]--WHERE [Reservierungsnr_] = 48282863
--ORDER BY [Sort_Customer_No], [CompanyName], [CustLedgerEntry_PostingDate] 	

DROP TABLE #RESULTS
DROP TABLE #RESULTS_CompanyName
END


GO
