USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeHeader_DJU]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 12.12.2014
-- Description:	Rechnungskopf der Transaction Fee
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 04.01.18 HRS001			 SAL	Optimization in case condition for Country/Region JOIN and SH.Bill-to Country/Region Code
-- 19.07.18 HRS002   ACS-694 DJU    Added field [Central Billing Fee Type]
--                                  + corrected VAT Amount and Amount
-- 27.06.19 HRS003  ACS-1847 DJU    Added field [Salesperson Code]
-- 14.02.20 HRS004  ACS-1796 SAL    Addes fields [PO No_ Paym_ TAF], [Note for Paym_ TAF]
-- 24.11.20 HRS005  ACS-2505 SPF    Add Country specific Currency Excjange Rate
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = 'R009583904', @Company = 'HRS Payment'
EXEC [dbo].[sp_RPCentralBillingFeeHeader]  @ReNr, @Company 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeHeader_DJU] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
  

-- 24.11.20 SPF01 >>>>>>>>>>>>>>>>>>>> HRS005
    DECLARE @ExchangeRateInvoice decimal(37,20) = 1.0
	      , @ExchangeRateCountry decimal(37,20) = 1.0
		  , @CurrencyCodeCountry varchar(10) = 'EUR'
		  , @CurrencyCodeinvoice varchar(10) = 'EUR'
		  , @InvoicingInLocalCurrency int = 0
IF @Company='HRS Payment'		  
BEGIN
  IF EXISTS (SELECT 1 FROM [HRS Payment$Sales Header] AH WITH (NOLOCK) JOIN [HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[No_] = @ReNr) AND CR.[Invoicing in local currency]=1 UNION SELECT 1 FROM [HRS Payment$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[No_] = @ReNr) AND CR.[Invoicing in local currency]=1) 
  BEGIN
	;WITH 
	   AH AS	(SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS Payment$Sales Header] AH WITH (NOLOCK) JOIN [HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr UNION SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS Payment$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr)
	SELECT @ExchangeRateInvoice = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code] THEN ER.[Exchange Rate Amount] ELSE 0 END)
	     , @ExchangeRateCountry = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code Country] THEN ER.[Exchange Rate Amount] ELSE 0 END)
		 , @CurrencyCodeCountry = MAX(AH.[Currency Code Country])
		 , @CurrencyCodeinvoice = MAX(AH.[Currency Code])
		 , @InvoicingInLocalCurrency = MAX(AH.[Invoicing in local currency])
	  FROM AH
	  JOIN [HRS Payment$OANDA_Currency Exchange Rate] ER
	    ON (ER.[Currency Code] = AH.[Currency Code] OR ER.[Currency Code] = AH.[Currency Code Country])
	   AND ER.[Starting Date] = AH.[Posting Date]
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
END
IF @Company='HRS'		  
BEGIN
  IF EXISTS (SELECT 1 FROM [HRS$Sales Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[No_] = @ReNr) AND CR.[Invoicing in local currency]=1 UNION SELECT 1 FROM [HRS$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[No_] = @ReNr) AND CR.[Invoicing in local currency]=1) 
  BEGIN
	;WITH 
	   AH AS	(SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS$Sales Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr UNION SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr)
	SELECT @ExchangeRateInvoice = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code] THEN ER.[Exchange Rate Amount] ELSE 0 END)
	     , @ExchangeRateCountry = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code Country] THEN ER.[Exchange Rate Amount] ELSE 0 END)
		 , @CurrencyCodeCountry = MAX(AH.[Currency Code Country])
		 , @CurrencyCodeinvoice = MAX(AH.[Currency Code])
		 , @InvoicingInLocalCurrency = MAX(AH.[Invoicing in local currency])
	  FROM AH
	  JOIN [HRS$OANDA_Currency Exchange Rate] ER
	    ON (ER.[Currency Code] = AH.[Currency Code] OR ER.[Currency Code] = AH.[Currency Code Country])
	   AND ER.[Starting Date] = AH.[Posting Date]
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
END

  PRINT '@CurrencyCodeCountry=' + @CurrencyCodeCountry
  PRINT '@ExchangeRateCountry=' + CAST(@ExchangeRateCountry AS varchar(max))
  PRINT '@CurrencyCodeinvoice=' + @CurrencyCodeinvoice
  PRINT '@ExchangeRateInvoice=' + CAST(@ExchangeRateInvoice AS varchar(max))
 -- 24.11.20 SPF01 <<<<<<<<<<<<<<<<<<<< HRS005


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
        FROM [HRS$Bank Regulation] BR WITH (READUNCOMMITTED)
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
    ),
	SL_SUM AS (
	  SELECT SL.[Document No_]
		   , MAX(SL.[VAT %]) [VAT %]
           , SUM(SL.Amount) [Amount]
           , SUM(SL.[Amount Including VAT]) [Amount Including VAT]
		   , SUM(SL.[Quantity]) [Quantity]
	    FROM [' + @Company + '$Sales Invoice Line] AS SL WITH (READUNCOMMITTED) 
	   WHERE SL.[Document No_] = ''' + @ReNr + '''
	GROUP BY SL.[Document No_]
	)
    SELECT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
         , CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END AS [Sell-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Fax Extension]
         , SP.[Phone Extension]             AS [Phone Extension]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END [Currency Code]
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END [Currency Factor]
         , SL.[VAT %]                  AS VAT
         , SL.Amount                   AS Amount
         , SL.[Amount Including VAT] - SL.Amount AS Mwst
         , SL.[Amount Including VAT]   AS Total
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END SEPA
         , COALESCE(B1.[Description],'''')                        [Bank_1_Descrption]
         , COALESCE(B1.[Account],'''')                            [Bank_1_Account]
         , COALESCE(B1.[BLZ],'''')                                [Bank_1_BLZ]
         , COALESCE(B1.[Swift],'''')                              [Bank_1_Swift]
         , COALESCE(B1.[IBAN],'''')                               [Bank_1_IBAN]
         , COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),'''')     [Bank_1_BankTxt]
         , COALESCE(B2.[Description],'''')                        [Bank_2_Descrption]
         , COALESCE(B2.[Account],'''')                            [Bank_2_Account]
         , COALESCE(B2.[BLZ],'''')                                [Bank_2_BLZ]
         , COALESCE(B2.[Swift],'''')                              [Bank_2_Swift]
         , COALESCE(B2.[IBAN],'''')                               [Bank_2_IBAN]
         , COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),'''')     [Bank_2_BankTxt]
         , COALESCE(B3.[Description],'''')                        [Bank_3_Descrption]
         , COALESCE(B3.[Account],'''')                            [Bank_3_Account]
         , COALESCE(B3.[BLZ],'''')                                [Bank_3_BLZ]
         , COALESCE(B3.[Swift],'''')                              [Bank_3_Swift]
         , COALESCE(B3.[IBAN],'''')                               [Bank_3_IBAN]
         , COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),'''')     [Bank_3_BankTxt]
         , SL.[Quantity]                                          [Quantity]
         , CU.[VAT Registration No_]                              [Customer VAT Registration No_]
		 , SH.[Central Billing Fee Type]                               [Central Billing Fee Type]
		 , SH.[Order Type]											   [Order Type]
		 -- HRS003 >>
		 , SH.[Salesperson Code]
		 -- HRS003 <<
		 -- HRS004 >>
		 , CU.[PO No_ Paym_ TAF]
		 , CU.[Note for Paym_ TAF]
		 -- HRS004 <<
		 -- HRS005 >>
		 , '+ CAST(@InvoicingInLocalCurrency as varchar(10)) +' [Invoicing in local currency]
		 , '+ CAST(@ExchangeRateCountry AS varchar(max)) + ' [Exchange Rate Country]
		 -- HRS005
		 , CI.[Culture Name]
		 , CI.[Short Date Pattern]
		 '
	SET @SQLStatement = @SQLStatement + 
'
      FROM [' + @Company + '$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
        -- // 04.01.18 SAL HRS001 >>
		--ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
		ON CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
        -- // 04.01.18 SAL HRS001 <<
 LEFT JOIN [Culture Info]                     CI WITH (NOLOCK)
        ON (CI.[Windows Language ID] = CO.[Windows Language ID]) OR (CO.[Windows Language ID]=0 AND CI.[Windows Language ID]=1031)
	  JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN SL_SUM AS SL WITH (READUNCOMMITTED) 
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
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]   
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
   WHERE (SH.No_ = ''' + @ReNr + ''')
'	PRINT (SUBSTRING(@SQLStatement  ,1,8000))
	PRINT (SUBSTRING(@SQLStatement  ,8001,8000))
	EXECUTE(@SQLStatement)       

	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
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
        FROM [HRS Payment$Bank Regulation] BR WITH (READUNCOMMITTED)
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
    ),
	SL_SUM AS (
	  SELECT SL.[Document No_]
		   , MAX(SL.[VAT %]) [VAT %]
           , SUM(SL.Amount) [Amount]
           , SUM(SL.[Amount Including VAT]) [Amount Including VAT]
		   , SUM(SL.[Quantity]) [Quantity]
	    FROM [' + @Company + '$Sales Line] AS SL WITH (READUNCOMMITTED) 
	   WHERE SL.[Document No_] = ''' + @ReNr + '''
	GROUP BY SL.[Document No_]
	)
    SELECT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
         , CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END AS [Sell-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Fax Extension]
         , SP.[Phone Extension]             AS [Phone Extension]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END [Currency Code]
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END [Currency Factor]
         , SL.[VAT %]                  AS VAT
         , SL.Amount                   AS Amount
         , SL.[Amount Including VAT] - SL.Amount AS Mwst
         , SL.[Amount Including VAT]   AS Total
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END SEPA
         , COALESCE(B1.[Description],'''')                        [Bank_1_Descrption]
         , COALESCE(B1.[Account],'''')                            [Bank_1_Account]
         , COALESCE(B1.[BLZ],'''')                                [Bank_1_BLZ]
         , COALESCE(B1.[Swift],'''')                              [Bank_1_Swift]
         , COALESCE(B1.[IBAN],'''')                               [Bank_1_IBAN]
         , COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),'''')     [Bank_1_BankTxt]
         , COALESCE(B2.[Description],'''')                        [Bank_2_Descrption]
         , COALESCE(B2.[Account],'''')                            [Bank_2_Account]
         , COALESCE(B2.[BLZ],'''')                                [Bank_2_BLZ]
         , COALESCE(B2.[Swift],'''')                              [Bank_2_Swift]
         , COALESCE(B2.[IBAN],'''')                               [Bank_2_IBAN]
         , COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),'''')     [Bank_2_BankTxt]
         , COALESCE(B3.[Description],'''')                        [Bank_3_Descrption]
         , COALESCE(B3.[Account],'''')                            [Bank_3_Account]
         , COALESCE(B3.[BLZ],'''')                                [Bank_3_BLZ]
         , COALESCE(B3.[Swift],'''')                              [Bank_3_Swift]
         , COALESCE(B3.[IBAN],'''')                               [Bank_3_IBAN]
         , COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),'''')     [Bank_3_BankTxt]
         , SL.[Quantity]                                          [Quantity]
         , CU.[VAT Registration No_]                              [Customer VAT Registration No_]
		 , SH.[Central Billing Fee Type]                               [Central Billing Fee Type]
		 , SH.[Order Type]											   [Order Type]
		 -- HRS003 >>
		 , SH.[Salesperson Code]
		 -- HRS003 <<
		 -- HRS004 >>
		 , CU.[PO No_ Paym_ TAF]
		 , CU.[Note for Paym_ TAF]
		 -- HRS004 <<
		 -- HRS005 >>
		 , '+ CAST(@InvoicingInLocalCurrency as varchar(10)) +' [Invoicing in local currency]
		 , '+ CAST(@ExchangeRateCountry AS varchar(max)) + ' [Exchange Rate Country]
		 -- HRS005
		 , CI.[Culture Name]
		 , CI.[Short Date Pattern]
		 '
	SET @SQLStatement = @SQLStatement + 
'
      FROM [' + @Company + '$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
      -- // 04.01.18 SAL HRS001 >>
		--ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
		ON CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      -- // 04.01.18 SAL HRS001 <<
 LEFT JOIN [Culture Info]                     CI WITH (NOLOCK)
        ON (CI.[Windows Language ID] = CO.[Windows Language ID]) OR (CO.[Windows Language ID]=0 AND CI.[Windows Language ID]=1031)
	  JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN SL_SUM AS SL WITH (READUNCOMMITTED) 
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
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]   
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
     WHERE (SH.No_ = ''' + @ReNr + ''')
'
	PRINT (SUBSTRING(@SQLStatement  ,1,8000))
	PRINT (SUBSTRING(@SQLStatement  ,8001,8000))
	PRINT (SUBSTRING(@SQLStatement  ,16001,8000))
	EXECUTE(@SQLStatement)  
END
GO
