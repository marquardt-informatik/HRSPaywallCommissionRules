USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPTAFInvoiceHeaderNew_SIK_after_ACS-2301]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 06.11.18
-- Description:	Rechnungskopf der Transaction Fee
-- Datum    Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 06.11.18 HRS001	ACS-846	  TM	Optimization in case condition for Country/Region JOIN and SH.Bill-to Country/Region Code
-- 29.11.18 HRS002  ACS-1307  SAL   Extension to select Dataset from unposted TAF by using @SQLStatement2 and @SQLGroupBy2
-- 13.12.18 HRS003  ACS-1299  DJU   Changed VARCHAR to NVARCHAR in BankInfos
-- 04.02.19 HRS004  ACS-1443  SAL   Handle VAT calculation for Russian customers
-- 19.02.19 HRS005  ACS-1532  DJU   Get Bill-to Address from TAF Invoice Header
-- 14.06.19 HRS006 INC0019272 DJU   Get Bank from Company Table
-- 30.08.19 HRS007 INC0023653 SAL   Changed Address Fields from VARCHAR to NVARCHAR
-- 25.06.20 HRS008  ACS-2301  SAL   Handle temporary reduction of German VAT rates
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = '14174112/03', @Company = 'HRS'			---'14174118'
EXEC [dbo].[sp_RPTAFInvoiceHeaderNew] @ReNr, @Company 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPTAFInvoiceHeaderNew_SIK_after_ACS-2301] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(MAX)
	DECLARE @SQLGroupBy  VARCHAR(MAX)

	--HRS002 >>
	DECLARE @SQLStatement2 VARCHAR(MAX)
	DECLARE @SQLGroupBy2  VARCHAR(MAX)
  
    DECLARE @TAFDisplayCaseNo varchar(50)
	SET @TAFDisplayCaseNo = (SELECT [Display Case No_] FROM [HRS$TAF Header] WITH (NOLOCK) WHERE No_ = @ReNr)
	--HRS002 <<

	CREATE TABLE #RESULTS 
	( 
		[No_]								VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Customer No_]				VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Contact]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Customer Name]				NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Customer Name 2]			NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Address]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Address 2]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to City]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Post Code]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Sell-to Country Code]              VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bill-to Customer No_]				VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Posting Date]                      DATETIME
	  , [Payment Method Code]				VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [EU Ländercode]						VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [ISO_Code]							VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Fax Extension]						VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Phone Extension]					VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Name]								NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Document Date]						DATETIME
	  , [Posting Description]				VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Currency Code]						VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Currency Factor]					DECIMAL(38,20)
	  , [VAT]								DECIMAL(38,20)
	  , [Amount]							DECIMAL(38,20)
	  , [Mwst]								DECIMAL(38,20)
	  , [Total]								DECIMAL(38,20)
      , [Bank Branch No_]                   VARCHAR(250) COLLATE Latin1_General_CS_AS
      , [Bank Account No_]                  VARCHAR(250) COLLATE Latin1_General_CS_AS
      , [Bank Name]                         VARCHAR(250) COLLATE Latin1_General_CS_AS
      , [IBAN]                              VARCHAR(250) COLLATE Latin1_General_CS_AS
      , [BIC]                               VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Language Code]						VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [SEPA]								tinyint
	  --HRS003 >>
	  , [Bank_1_Descrption]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_1_Account]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_1_BLZ]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_1_Swift]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_1_IBAN]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_1_BankTxt]					NVARCHAR(max)
	  , [Bank_2_Descrption]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_2_Account]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_2_BLZ]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_2_Swift]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_2_IBAN]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_2_BankTxt]					NVARCHAR(max)
	  , [Bank_3_Descrption]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_3_Account]					NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_3_BLZ]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_3_Swift]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_3_IBAN]						NVARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Bank_3_BankTxt]					NVARCHAR(max)
	  --HRS003 <<
	  , [Quantity]                          int
	  , [Customer VAT Registration No_]     VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Central Billing Fee Type]			int
	  , [Order Type]						int
	  , [EMail]                             VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Invoicing in local currency]       int
	  , [Currency Code Country]             VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Exchange Rate Invoice]             DECIMAL(38,20)
	  , [Exchange Rate Country]             DECIMAL(38,20)
	  , [Exchange Rate]                     DECIMAL(38,20)
	  , [Amount Country]                    DECIMAL(38,20)
	  , [Mwst Country]                      DECIMAL(38,20)
	  , [Total Country]                     DECIMAL(38,20)
	  , [VAT Bus_ Posting Group]            VARCHAR(250) COLLATE Latin1_General_CS_AS
	)
	SET @SQLGroupBy = 
'  GROUP BY SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
		 -- 19.02.2019 DJU HRS005 >>
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END
		 -- , CASE WHEN P1.[Content] IS NULL THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END
		 -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END 
         -- , SH.[Sell-to Post Code]
		 -- , SH.[Bill-to Country_Region Code]
		 , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Name] IS NULL        THEN SH.[Sell-to Customer Name]   ELSE TAF.[Bill-to Name] END        ELSE P1.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Name 2] IS NULL      THEN SH.[Sell-to Customer Name 2] ELSE TAF.[Bill-to Name 2] END      ELSE P2.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Address] IS NULL     THEN SH.[Sell-to Address]         ELSE TAF.[Bill-to Address] END     ELSE P3.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Address 2] IS NULL   THEN SH.[Sell-to Address 2]       ELSE TAF.[Bill-to Address 2] END   ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to City] IS NULL        THEN SH.[Sell-to City]            ELSE TAF.[Bill-to City] END        ELSE P5.[Content] END
         ,                                         CASE WHEN TAF.[Bill-to Post Code] IS NULL   THEN SH.[Sell-to Post Code]       ELSE TAF.[Bill-to Post Code] END
         , CASE WHEN CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END IN (''0'', '''') THEN ''33'' ELSE CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END END
		 -- 19.02.2019 DJU HRS005 <<
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , SH.[Language Code]                  
         , SP.[Fax Extension]              
         , SP.[Phone Extension]            
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
         , RTRIM(BA.[Bank Branch No_])
         , RTRIM(BA.[Bank Account No_])
         , RTRIM(BA.[Name])
         , RTRIM(BA.[IBAN])
         , RTRIM(BA.[SWIFT Code])
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
		 , SH.[Central Billing Fee Type]
		 , SH.[Order Type]
		 , SH.[VAT Bus_ Posting Group]
       '
	
	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
    WITH BANK AS
    (
      SELECT BR.[Sequences]
           , BR.[Country Code]
           , BK.[BankTxt]
           , BK.[BLZ]
           , BK.[Swift]
           , BK.[IBAN]
           , BK.[Account]
           , BK.[Description]
           , BR.[Sequences]    [Reihenfolgen]
		-- HRS006 >>
        --FROM [HRS$Bank Regulation] BR WITH (READUNCOMMITTED)
		FROM [' + @Company + '$Bank Regulation] BR WITH (READUNCOMMITTED)
		-- HRS006 <<
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
    ) ' 
	
	SET @SQLStatement = @SQLStatement + 
	
    'INSERT INTO #RESULTS
    SELECT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
		 -- 19.02.2019 DJU HRS005 >>
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         -- , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         -- , SH.[Sell-to Post Code]
		 -- , CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END AS [Bill-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added]
		 , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Name] IS NULL        THEN SH.[Sell-to Customer Name]   ELSE TAF.[Bill-to Name] END        ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Name 2] IS NULL      THEN SH.[Sell-to Customer Name 2] ELSE TAF.[Bill-to Name 2] END      ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Address] IS NULL     THEN SH.[Sell-to Address]         ELSE TAF.[Bill-to Address] END     ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to Address 2] IS NULL   THEN SH.[Sell-to Address 2]       ELSE TAF.[Bill-to Address 2] END   ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN   CASE WHEN TAF.[Bill-to City] IS NULL        THEN SH.[Sell-to City]            ELSE TAF.[Bill-to City] END        ELSE P5.[Content] END [Sell-to City]
         ,                                         CASE WHEN TAF.[Bill-to Post Code] IS NULL   THEN SH.[Sell-to Post Code]       ELSE TAF.[Bill-to Post Code] END                         [Sell-to Post Code]
		 , CASE WHEN CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END IN (''0'', '''') THEN ''33'' ELSE CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END END AS [Bill-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added]
		 -- 19.02.2019 DJU HRS005 <<
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Durchwahl Fax]
         , SP.[Phone Extension]             AS [Durchwahl Telefon]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
         , MAX(SL.[VAT %])                  AS VAT
         , SUM(SL.Amount)                   AS Amount
         , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) AS Mwst
         , SUM(SL.[Amount Including VAT])   AS Total
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
         , MAX(COALESCE(B1.[Description],''''))                        [Bank_1_Descrption]
         , MAX(COALESCE(B1.[Account],''''))                            [Bank_1_Account]
         , MAX(COALESCE(B1.[BLZ],''''))                                [Bank_1_BLZ]
         , MAX(COALESCE(B1.[Swift],''''))                              [Bank_1_Swift]
         , MAX(COALESCE(B1.[IBAN],''''))                               [Bank_1_IBAN]
         , MAX(COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_1_BankTxt]
         , MAX(COALESCE(B2.[Description],''''))                        [Bank_2_Descrption]
         , MAX(COALESCE(B2.[Account],''''))                            [Bank_2_Account]
         , MAX(COALESCE(B2.[BLZ],''''))                                [Bank_2_BLZ]
         , MAX(COALESCE(B2.[Swift],''''))                              [Bank_2_Swift]
         , MAX(COALESCE(B2.[IBAN],''''))                               [Bank_2_IBAN]
         , MAX(COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_2_BankTxt]
         , MAX(COALESCE(B3.[Description],'''') )                       [Bank_3_Descrption]
         , MAX(COALESCE(B3.[Account],''''))                            [Bank_3_Account]
         , MAX(COALESCE(B3.[BLZ],''''))                                [Bank_3_BLZ]
         , MAX(COALESCE(B3.[Swift],''''))                              [Bank_3_Swift]
         , MAX(COALESCE(B3.[IBAN],''''))                               [Bank_3_IBAN]
         , MAX(COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_3_BankTxt]
         , SUM(SL.[Quantity])                                          [Quantity]
         , MAX(CU.[VAT Registration No_])                              [VAT Registration No_]
		 , SH.[Central Billing Fee Type]                               [Central Billing Fee Type]
		 , SH.[Order Type]											   [Order Type]
		 , '''' [E-Mail]
		 , 0 [Invoicing in local currency] 
		 , '''' [Currency Code Country]
		 , 0 [Exchange Rate Invoice]
		 , 0 [Exchange Rate Country]
		 , 0 [Exchange Rate]
		 , 0 [Amount Country]
		 , 0 [Mwst Country]
		 , 0 [Total Country]
		 , SH.[VAT Bus_ Posting Group]
'
	SET @SQLStatement = @SQLStatement + ' 
      FROM [' + @Company + '$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
	    -- 19.02.2019 DJU HRS005 >>
 LEFT JOIN [' + @Company + '$TAF Invoice Header] TAF WITH (NOLOCK) ON SH.No_ = TAF.[Posted Sales Invoice No_]
        -- 19.02.2019 DJU HRS005 <<
      JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
        -- // 04.01.18 SAL HRS001 >>
		--ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
		-- 19.02.2019 DJU HRS005 >>
		-- ON CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
		ON CASE WHEN CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END IN (''0'', '''') THEN ''33'' ELSE CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END END = CO.Code 
		-- 19.02.2019 DJU HRS005 <<
        -- // 04.01.18 SAL HRS001 <<
	  JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN [' + @Company + '$Sales Invoice Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [' + @Company + '$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = SH.[Sell-to Customer No_]
 -- 19.02.2019 DJU HRS005 >>
 -- LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]   
 -- LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
 -- LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END 
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = CASE WHEN TAF.[Bill-to Country_Region Code] IS NULL THEN SH.[Bill-to Country_Region Code] ELSE TAF.[Bill-to Country_Region Code] END
 -- 19.02.2019 DJU HRS005 <<
   WHERE (SH.No_ = ''' + @ReNr + ''')
'	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,1,8000))
	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,8001,8000))
	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,16001,8000))
	EXECUTE(@SQLStatement+@SQLGroupBy)
	 
	PRINT (CONVERT(varchar, SYSDATETIME(), 121) + ' 1. Execute')
	
	--HRS002 >>
	
	IF (SELECT COUNT(1) FROM #RESULTS) = 0 --NOT EXISTS(SELECT * FROM #RESULTS) 
	BEGIN
		SET @SQLGroupBy2 = 
      '  LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]   
		 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
		 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
		 WHERE (SH.No_ = ''' + @ReNr + ''') 
		 GROUP BY SH.[No_]
			 , SH.[Bill-to Customer No_]
			 , SH.[Bill-to Contact]
			 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Name]   ELSE P1.[Content] END 
			 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Name 2] ELSE P2.[Content] END 
			 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Address]         ELSE P3.[Content] END 
			 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Address 2]       ELSE P4.[Content] END
			 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to City]            ELSE P5.[Content] END
			 , SH.[Bill-to Post Code]
			 , SH.[Bill-to Country_Region Code] 
			 , SH.[Bill-to Customer No_]
			 , SH.[Posting Date]
			 , CU.[Payment Method Code]
			 , CO.[EU Country_Region Code]     
			 , CASE WHEN CU.[Language Code]='''' THEN CO.[Primary Language Code] ELSE CU.[Language Code] END                 
			 , SP.[Fax Extension]              
			 , SP.[Phone Extension]            
			 , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
			 , SH.[Document Date]
			 , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
			 , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
			 , RTRIM(BA.[Bank Branch No_])
			 , RTRIM(BA.[Bank Account No_])
			 , RTRIM(BA.[Name])
			 , RTRIM(BA.[IBAN])
			 , RTRIM(BA.[SWIFT Code])
			 , CU.[Language Code] 
			 , CU.[VAT Bus_ Posting Group]
		'

		SET @SQLStatement2 = 
		' IF EXISTS(SELECT * FROM [' + @Company + '$TAF Header] WHERE [No_] = ''' + @ReNr + ''')
				WITH BANK AS
					(
					  SELECT BR.[Sequences]
						   , BR.[Country Code]
						   , BK.[BankTxt]
						   , BK.[BLZ]
						   , BK.[Swift]
						   , BK.[IBAN]
						   , BK.[Account]
						   , BK.[Description]
						   , BR.[Sequences]    [Reihenfolgen]
						-- HRS006 >>
						--FROM [HRS$Bank Regulation] BR WITH (READUNCOMMITTED)
						FROM [' + @Company + '$Bank Regulation] BR WITH (READUNCOMMITTED)
						-- HRS006 <<
						JOIN [Bank] BK WITH (READUNCOMMITTED)
						  ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
					) ' 
		SET @SQLStatement2 = @SQLStatement2 + 

					'INSERT INTO #RESULTS
		
					SELECT SH.[No_]
						 , SH.[Bill-to Customer No_]
						 , SH.[Bill-to Contact]
						 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Name]   ELSE P1.[Content] END [Sell-to Customer Name]
						 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
						 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Address]         ELSE P3.[Content] END [Sell-to Address]
						 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
						 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Bill-to City]            ELSE P5.[Content] END [Sell-to City]
						 , SH.[Bill-to Post Code]
						 , CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END AS [Bill-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added]
						 , SH.[Bill-to Customer No_]
						 , SH.[Posting Date]
						 , CU.[Payment Method Code]
						 , CO.[EU Country_Region Code]      AS [EU Ländercode]
						 , CU.[Language Code]               AS [ISO_Code]
						 , SP.[Fax Extension]               AS [Durchwahl Fax]
						 , SP.[Phone Extension]             AS [Durchwahl Telefon]
						 , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
						 , SH.[Document Date]
						 , ''''								[Posting Description]       
						 , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
						 , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
						 , MAX(
							-- 25.06.20 SAL HRS008 -- CASE WHEN CU.[Country_Region Code] = ''33'' THEN 19 							
							-- 25.06.20 SAL HRS008 >>
							CASE WHEN CU.[Country_Region Code] = ''33'' AND (SH.[Posting Date] < ''2020-07-01'' OR SH.[Posting Date] >= ''2021-01-01'') THEN 19
							WHEN CU.[Country_Region Code] = ''33'' AND (SH.[Posting Date] >= ''2020-07-01'' AND SH.[Posting Date] < ''2021-01-01'') THEN 16 
							-- 25.06.20 SAL HRS008 <<
							WHEN SH.[Bill-to Country_Region Code] = ''202'' AND SH.[Posting Date] >= ''2019-01-01'' THEN 16.67		-- 04.02.19 SAL HRS004
							ELSE 0 END)             AS VAT
						 , SUM(SL.Amount)                   AS Amount
						 , SUM(SL. Amount * (
						   -- 25.06.20 SAL HRS008 -- CASE	WHEN CU.[Country_Region Code] = ''33'' THEN 1.19 						
							-- 25.06.20 SAL HRS008 >>
							CASE WHEN CU.[Country_Region Code] = ''33'' AND (SH.[Posting Date] < ''2020-07-01'' OR SH.[Posting Date] >= ''2021-01-01'') THEN 1.19
							WHEN CU.[Country_Region Code] = ''33'' AND (SH.[Posting Date] >= ''2020-07-01'' AND SH.[Posting Date] < ''2021-01-01'') THEN 1.16 
							-- 25.06.20 SAL HRS008 <<
							WHEN SH.[Bill-to Country_Region Code] = ''202'' AND SH.[Posting Date] >= ''2019-01-01'' THEN 1.1667		-- 04.02.19 SAL HRS004 
							ELSE 1 END)) - SUM(SL.Amount) AS Mwst
						 , SUM(SL. Amount * (
						    -- 25.06.20 SAL HRS008 -- CASE WHEN CU.[Country_Region Code] = ''33'' THEN 1.19 	
							-- 25.06.20 SAL HRS008 >>
							CASE WHEN CU.[Country_Region Code] = ''33'' AND (SH.[Posting Date] < ''2020-07-01'' OR SH.[Posting Date] >= ''2021-01-01'') THEN 1.19
							WHEN CU.[Country_Region Code] = ''33'' AND (SH.[Posting Date] >= ''2020-07-01'' AND SH.[Posting Date] < ''2021-01-01'') THEN 1.16 
							-- 25.06.20 SAL HRS008 <<						
							WHEN SH.[Bill-to Country_Region Code] = ''202'' AND SH.[Posting Date] >= ''2019-01-01'' THEN 1.1667		-- 04.02.19 SAL HRS004
							ELSE 1 END))   AS Total
						 , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
						 , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
						 , RTRIM(BA.[Name])                    [Bank Name]
						 , RTRIM(BA.[IBAN])                    [IBAN]
						 , RTRIM(BA.[SWIFT Code])              [BIC]
						 , CASE WHEN CU.[Language Code]='''' THEN CO.[Primary Language Code] ELSE CU.[Language Code] END [Language Code]
						 , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
						 , MAX(COALESCE(B1.[Description],''''))                        [Bank_1_Descrption]
						 , MAX(COALESCE(B1.[Account],''''))                            [Bank_1_Account]
						 , MAX(COALESCE(B1.[BLZ],''''))                                [Bank_1_BLZ]
						 , MAX(COALESCE(B1.[Swift],''''))                              [Bank_1_Swift]
						 , MAX(COALESCE(B1.[IBAN],''''))                               [Bank_1_IBAN]
						 , MAX(COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_1_BankTxt]
						 , MAX(COALESCE(B2.[Description],''''))                        [Bank_2_Descrption]
						 , MAX(COALESCE(B2.[Account],''''))                            [Bank_2_Account]
						 , MAX(COALESCE(B2.[BLZ],''''))                                [Bank_2_BLZ]
						 , MAX(COALESCE(B2.[Swift],''''))                              [Bank_2_Swift]
						 , MAX(COALESCE(B2.[IBAN],''''))                               [Bank_2_IBAN]
						 , MAX(COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_2_BankTxt]
						 , MAX(COALESCE(B3.[Description],'''') )                       [Bank_3_Descrption]
						 , MAX(COALESCE(B3.[Account],''''))                            [Bank_3_Account]
						 , MAX(COALESCE(B3.[BLZ],''''))                                [Bank_3_BLZ]
						 , MAX(COALESCE(B3.[Swift],''''))                              [Bank_3_Swift]
						 , MAX(COALESCE(B3.[IBAN],''''))                               [Bank_3_IBAN]
						 , MAX(COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_3_BankTxt]
						 , COUNT(SL.[Process No_])                                     [Quantity]
						 , MAX(CU.[VAT Registration No_])                              [VAT Registration No_]
						 , 0							                               [Central Billing Fee Type]
						 , 7														   [Order Type]
						 , '''' [E-Mail]
						 , 0 [Invoicing in local currency] 
						 , '''' [Currency Code Country]
						 , 0 [Exchange Rate Invoice]
						 , 0 [Exchange Rate Country]
						 , 0 [Exchange Rate]
						 , 0 [Amount Country]
						 , 0 [Mwst Country]
						 , 0 [Total Country]
						 , CU.[VAT Bus_ Posting Group]
					  FROM [' + @Company + '$TAF Header] AS SH WITH (READUNCOMMITTED)
					  JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
						ON SH.[Bill-to Customer No_] = CU.[No_]
					  JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
						-- // 04.01.18 SAL HRS001 >>
						--ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
						ON CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
						-- // 04.01.18 SAL HRS001 <<
					  JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
						ON SH.[Salesperson Code] = SP.Code 
					  JOIN [' + @Company + '$TAF Line] AS SL WITH (READUNCOMMITTED) 
						ON SH.No_ = SL.[TAF No_] 
				 LEFT JOIN [' + @Company + '$Customer Bank Account]        BA WITH (READUNCOMMITTED)
						ON SH.[Bill-to Customer No_] = BA.[Customer No_]
					   AND BA.Clearing =1 
				 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
						ON P1.[TableID]                     = 18
					   AND P1.[FieldID]                     = 2
					   AND P1.[KeyField1Value]              = SH.[Bill-to Customer No_]
				 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
						ON P2.[TableID]                     = 18
					   AND P2.[FieldID]                     = 4
					   AND P2.[KeyField1Value]              = SH.[Bill-to Customer No_]
				 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
						ON P3.[TableID]                     = 18
					   AND P3.[FieldID]                     = 5
					   AND P3.[KeyField1Value]              = SH.[Bill-to Customer No_]
				 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
						ON P4.[TableID]                     = 18
					   AND P4.[FieldID]                     = 6
					   AND P4.[KeyField1Value]              = SH.[Bill-to Customer No_]
				 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
						ON P5.[TableID]                     = 18
					   AND P5.[FieldID]                     = 7
					   AND P5.[KeyField1Value]              = SH.[Bill-to Customer No_]
				 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
						ON P6.[TableID]                     = 18
					   AND P6.[FieldID]                     = 50012
					   AND P6.[KeyField1Value]              = SH.[Bill-to Customer No_]
		'
		PRINT (SUBSTRING(@SQLStatement2+@SQLGroupBy2  ,1,8000))
		PRINT (SUBSTRING(@SQLStatement2+@SQLGroupBy2  ,8001,8000))
		EXECUTE(@SQLStatement2+@SQLGroupBy2) 
	END

	PRINT (CONVERT(varchar, SYSDATETIME(), 121) + ' 2. Nach IF TAF Header')
	--HRS002 <<

	UPDATE R SET 
	       R.[Fax Extension]
		 = CASE 
             WHEN CU.[Salesperson Code] IN ('AFR03','FBE02')THEN
               CASE
                 WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND CU.[Chain] = '13' THEN SP.[Fax Extension]
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 ELSE SP.[Fax Extension]
               END
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN SP.[Fax Extension]
             WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END 
         , R.[EMail]
         = CASE 
             WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND CU.[Chain] = '13' THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN CU.[Payment Method Code] = 'CORE'         THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'SEPA'         THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'CC_AUTO'      THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' 
              THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN ',29,57,92,30,67,' LIKE '%,'+R.[Sell-to Country Code]+',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'') 
               END 
             + '@hrs.de'
           END 
         , R.[Invoicing in local currency] = CO.[Invoicing in local currency]
		 , R.[Currency Code Country] = CO.[Currency Code]
	  FROM #RESULTS R
      JOIN [HRS$Customer]                     CU WITH (READUNCOMMITTED)
        ON R.[Bill-to Customer No_]        = CU.[No_] 
      JOIN [HRS$Country_Region]               CO WITH (READUNCOMMITTED)
        ON R.[Sell-to Country Code] = CO.Code
      JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON R.[Language Code]               = LA.Code 
      JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                PG WITH (READUNCOMMITTED)
        ON PG.[Code]                        = 'PEGASUS'
 LEFT JOIN [HRS$Printer Group]                SE WITH (READUNCOMMITTED)
        ON SE.[Code]                        = 'SEPA'
 LEFT JOIN [HRS$Printer Group]                CR WITH (READUNCOMMITTED)
        ON CR.[Code]                        = 'CORE'
 LEFT JOIN [HRS$Printer Group]                LT WITH (READUNCOMMITTED)
        ON LT.[Code]                        = 'LAST'
 LEFT JOIN [HRS$Printer Group]                AC WITH (READUNCOMMITTED)
        ON AC.[Code]                        = 'AUTO_CC'
      JOIN [HRS$Customer]                          JO WITH (READUNCOMMITTED)
        ON R.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code

	-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
    DECLARE @ExchangeRateInvoice decimal(37,20) = 1.0
	      , @ExchangeRateCountry decimal(37,20) = 1.0
		  , @CurrencyCodeCountry varchar(10) = 'EUR'
		  , @CurrencyCodeinvoice varchar(10) = 'EUR'
		  , @InvoicingInLocalCurrency int = 0

PRINT (CONVERT(varchar, SYSDATETIME(), 121) + ' 2. Vor IF Agency Display Header')

  IF EXISTS (SELECT * FROM [HRS$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] 
    WHERE (AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr OR AH.[Case No_] = @TAFDisplayCaseNo) AND CR.[Invoicing in local currency]=1) 
  BEGIN
	;WITH 
	   AH AS	(SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr)
    --, _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date] UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date])
    --, ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
	SELECT @ExchangeRateInvoice = MAX(CASE WHEN ER.[Currency Code] = R.[Currency Code] THEN ER.[Exchange Rate Amount] ELSE 0 END)
	     , @ExchangeRateCountry = MAX(CASE WHEN ER.[Currency Code] = R.[Currency Code Country] THEN ER.[Exchange Rate Amount] ELSE 0 END)
		 , @CurrencyCodeCountry = MAX(R.[Currency Code Country])
		 , @CurrencyCodeinvoice = MAX(R.[Currency Code])
		 , @InvoicingInLocalCurrency = MAX(R.[Invoicing in local currency])
	  FROM #RESULTS R
	 -- JOIN ExchangeRate ER
	 --   ON ER.[Currency Code] = AH.[Currency Code]
		--OR ER.[Currency Code] = AH.[Currency Code Country]
	  JOIN [HRS$OANDA_Currency Exchange Rate] ER
	    ON (ER.[Currency Code] = R.[Currency Code] OR ER.[Currency Code] = R.[Currency Code Country])
	   AND ER.[Starting Date] = R.[Posting Date]
	  IF @CurrencyCodeCountry IS NULL 
	  BEGIN
			SET @ExchangeRateInvoice = 1.0
			SET @ExchangeRateCountry = 1.0
			SET @CurrencyCodeCountry = 'EUR'
			SET @CurrencyCodeinvoice = 'EUR'
			SET @InvoicingInLocalCurrency = 0
	  END;
	  IF @ExchangeRateInvoice=0
	    SET @ExchangeRateInvoice = 1
      IF @ExchangeRateCountry=0
	    SET @ExchangeRateCountry = 1
  END
  PRINT '@CurrencyCodeCountry=' + @CurrencyCodeCountry
  PRINT '@ExchangeRateCountry=' + CAST(@ExchangeRateCountry AS varchar(max))
  PRINT '@CurrencyCodeinvoice=' + @CurrencyCodeinvoice
  PRINT '@ExchangeRateInvoice=' + CAST(@ExchangeRateInvoice AS varchar(max))
 -- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004      

 UPDATE R SET
        R.[Invoicing in local currency] = CASE WHEN @InvoicingInLocalCurrency=1 AND @CurrencyCodeCountry<>@CurrencyCodeinvoice THEN 1 ELSE 0 END
      , R.[Currency Code Country] = CASE WHEN @InvoicingInLocalCurrency = 1 THEN @CurrencyCodeCountry ELSE R.[Currency Code] END 
      , R.[Exchange Rate Invoice] = @ExchangeRateInvoice                                                            
      , R.[Exchange Rate Country] = @ExchangeRateCountry                                                            
      , R.[Exchange Rate] = @ExchangeRateCountry / @ExchangeRateInvoice                                     
      , R.[Amount Country] = (ROUND(R.[Amount],2)) * @ExchangeRateCountry / @ExchangeRateInvoice    
      , R.[Mwst Country] = (ROUND(R.[Amount],2)) 
      * CASE WHEN (COALESCE(R.[VAT Bus_ Posting Group],'INLAND') = 'INLAND') AND R.[Sell-to Country Code] = '33' THEN 0.19 ELSE 0 END 
      * @ExchangeRateCountry / @ExchangeRateInvoice                                    
      , R.[Total Country] = (ROUND(R.[Amount],2)) 
      * CASE WHEN (COALESCE(R.[VAT Bus_ Posting Group],'INLAND') = 'INLAND') AND R.[Sell-to Country Code] = '33' THEN 1.19 ELSE 1 END 
      * @ExchangeRateCountry / @ExchangeRateInvoice  
  FROM #RESULTS R                                  

 SELECT * FROM #RESULTS	

 PRINT (CONVERT(varchar, SYSDATETIME(), 121) + ' End')
END
GO
