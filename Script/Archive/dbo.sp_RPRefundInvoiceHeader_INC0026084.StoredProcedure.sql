USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPRefundInvoiceHeader_INC0026084]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jens Högg
-- Create date: 14.03.13
-- Description:	Rechnungskopf der Refundrechung
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 14.03.13 HRS001    66653  JHÖ    Neue Stored Procedure
/*
EXEC [dbo].[sp_RPRefundInvoiceHeader] 'WB2016-6185', 'HRS-CN'
*/
-- 
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPRefundInvoiceHeader_INC0026084] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)= ''
  
	CREATE TABLE #RESULTS 
	( 
		[No_]								VARCHAR(20)
	  , [Sell-to Customer No_]				NVARCHAR(20)
	  , [Sell-to Customer Name]				NVARCHAR(130)
	  , [Sell-to Customer Name 2]			NVARCHAR(70)
	  , [Sell-to Address]					NVARCHAR(130)
	  , [Sell-to Address 2]					NVARCHAR(70)
	  , [Sell-to Post Code]					NVARCHAR(70)
	  , [Sell-to City]						NVARCHAR(70)
	  , [Bill-to Country Code]              NVARCHAR(10)
	  , [Sell-to Country Code]              NVARCHAR(10)
	  , [Bill-to Customer No_]				NVARCHAR(20)
	  , [Sell-to Contact]                   NVARCHAR(80)
	  , [Posting Date]                      DATETIME
	  , [Payment Method Code]				VARCHAR(10)
	  , [EU Ländercode]						VARCHAR(10)
	  , [ISO_Code]							VARCHAR(10)
	  , [Language Code]						VARCHAR(10)
	  , [Durchwahl Fax]						VARCHAR(30)
	  , [Durchwahl Telefon]					VARCHAR(30)
	  , [Name]								VARCHAR(50)
	  , [Document Date]						DATETIME
	  , [Posting Description]				VARCHAR(4000)
	  , [Currency Code]						VARCHAR(10)
	  , [VAT]								DECIMAL(38,20)
	  , [Amount]							DECIMAL(38,20)
	  , [Mwst]								DECIMAL(38,20)
	  , [Total]								DECIMAL(38,20)
	  , [Currency Factor]                   DECIMAL(38,20)
	  , [Customer Currency Code]            VARCHAR(10)
      , [Hotel Contact Name]				VARCHAR(250)
      , [Guest Name]						VARCHAR(250)
      , [Arrival Date]						DATE
      , [Process Number]					INT
      , [Booking Code]                      VARCHAR(80)
      , [Description]						VARCHAR(4000)
      , [Bank Branch No_]					VARCHAR(20)
      , [Bank Account No_]					VARCHAR(34)
      , [Bank Name]							VARCHAR(100)
      , [IBAN]								VARCHAR(50)
      , [BIC]								VARCHAR(20)
	  , [SEPA]								tinyint
	  , [Vertrag Status]					tinyint
	  , [Special Fax]						VARCHAR(4000)
	  , [Special E-Mail]					VARCHAR(4000)
	  , [Hotel No_]							VARCHAR(20)
	  , [Invoicing in local currency]       INT
	  , [Currency Code Country]             VARCHAR(10)
	  , [Exchange Rate Invoice]             DECIMAL(38,20)
	  , [Exchange Rate Country]             DECIMAL(38,20)
	  , [Exchange Rate]                     DECIMAL(38,20)
	  , [Amount Country]					DECIMAL(38,20)
	  , [Mwst Country]						DECIMAL(38,20)
	  , [Total Country]						DECIMAL(38,20)
	)

	-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004	
    DECLARE @ExchangeRateInvoice decimal(37,20)
	      , @ExchangeRateCountry decimal(37,20)
		  , @CurrencyCodeCountry varchar(10)
		  , @CurrencyCodeinvoice varchar(10)
		  , @InvoicingInLocalCurrency int
	;WITH 
	   AH AS	
	   (
	     SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS-CN$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS-CN$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr UNION
	     SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS-BR$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr UNION
	     SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS$Sales Invoice Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr
	   )
    , _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date] UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date])
    , ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
	SELECT @ExchangeRateInvoice = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code]         THEN ER.[Exchange Rate Amount] ELSE 0 END)
	     , @ExchangeRateCountry = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code Country] THEN ER.[Exchange Rate Amount] ELSE 0 END)
		 , @CurrencyCodeCountry = MAX(AH.[Currency Code Country])
		 , @CurrencyCodeinvoice = MAX(AH.[Currency Code])
		 , @InvoicingInLocalCurrency = MAX(AH.[Invoicing in local currency])
	  FROM AH
	  JOIN ExchangeRate ER
	    ON ER.[Currency Code] = AH.[Currency Code]
		OR ER.[Currency Code] = AH.[Currency Code Country]

PRINT '@ExchangeRateInvoice = ' + CAST(@ExchangeRateInvoice AS varchar(max))
-- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004

	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
  INSERT INTO #RESULTS
  SELECT SH.[No_] [No_]
       , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
       , SH.[Bill-to Country_Region Code] AS [Bill-to Country Code]
       , SH.[Bill-to Country_Region Code]
       , SH.[Bill-to Customer No_]
       , SH.[Bill-to Contact]            
       , SH.[Posting Date]
       , SH.[Payment Method Code]
       , CO.[EU Country_Region Code]      AS [EU Ländercode]
       , SH.[Language Code]               AS [ISO_Code]
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
       , SP.[Fax Extension]               AS [Durchwahl Fax]
	   , CASE WHEN COALESCE(SP.[Team Phone Extension],'''')='''' THEN ''800'' ELSE COALESCE(SP.[Team Phone Extension],''800'') END [Durchwahl Telefon]
       , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
       , SH.[Document Date]
       , SH.[Posting Description]       
       , SH.[Currency Code]
       , MAX(SL.[VAT %])                  AS VAT
       , SUM(SL.Amount)                   AS Amount
       , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) AS Mwst
       , SUM(SL.[Amount Including VAT])   AS Total
       , SH.[Currency Factor]
       , CU.[Currency Code] [Customer Currency Code]
       , RJ.[Hotel Contact Name]
       , RJ.[Guest Name]
       , RJ.[Arrival Date]
       , RJ.[Process Number]
       , RJ.[Booking Code]
       , RJ.[Description]
       , RTRIM(BA.[Bank Branch No_]) [Bank Branch No_]
       , RTRIM(BA.[Bank Account No_]) [Bank Account No_]
       , RTRIM(BA.[Name])                                     [Bank Name]
       , RTRIM(BA.[IBAN])                                     [IBAN]
       , RTRIM(BA.[SWIFT Code])                               [BIC]
       , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
       , MAX(CAST(CU.[Contract Status] AS int))               [Vertrag Status]
       , MAX(CASE WHEN CU.[Contract Status] = ''10'' OR CU.[Contract Status] = ''11'' THEN
           ''''
         ELSE
           CASE 
             WHEN '',29,57,92,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
               ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441''
             WHEN '',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
               ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447''
             ELSE
               ''''
           END    
         END) [Special Fax]
       , CASE 
           WHEN '',29,57,92,10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN 
             ''accounting_fax@hrs.cn''
           ELSE 
             SP.[Fax Extension] + ''@hrs.de''
         END  [Special E-Mail]
       , RJ.[Hotel No_]
-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004	
         , ' + CASE WHEN @InvoicingInLocalCurrency=1 AND @CurrencyCodeCountry<>@CurrencyCodeinvoice THEN '1' ELSE '0' END + ' [Invoicing in local currency]
         , ' + CASE WHEN @InvoicingInLocalCurrency= 1 THEN ''''+@CurrencyCodeCountry+'''' ELSE 'NULL' END + '           [Currency Code Country]
         , ' + CAST(@ExchangeRateInvoice AS varchar(max)) + '                                                                     [Exchange Rate Invoice]
         , ' + CAST(@ExchangeRateCountry AS varchar(max)) + '                                                                      [Exchange Rate Country]
         , ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '                                               [Exchange Rate]
         , SUM(ROUND(SL.[Amount],2)) * ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '                   [Amount Country]
         , SUM(ROUND(SL.[Amount Including VAT],2)) - SUM(ROUND(SL.[Amount],2)) 
         * ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '                                               [Mwst Country]
         , SUM(ROUND(SL.[Amount Including VAT],2)) * ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '     [Total Country]
-- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
    FROM [' + @Company + '$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
    JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
      ON SH.[Sell-to Customer No_] = CU.[No_]
    JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
      ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
    JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
      ON SH.[Salesperson Code] = SP.Code 
    JOIN [' + @Company + '$Sales Invoice Line] AS SL WITH (READUNCOMMITTED) 
      ON SH.No_ = SL.[Document No_] 
    JOIN [' + @Company + '$Refund Journal] RJ WITH (NOLOCK)
      ON RJ.[HRS Invoice Number] = SH.[External Document No_]
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
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
   WHERE (SH.No_ = ''' + @ReNr + ''')
GROUP BY SH.[No_]
       , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END
       , SH.[Sell-to Post Code]
       , SH.[Bill-to Country_Region Code]
       , SH.[Bill-to Customer No_]
       , SH.[Bill-to Contact]            
       , SH.[Posting Date]
       , SH.[Payment Method Code]
       , CO.[EU Country_Region Code]     
       , SH.[Language Code]                  
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
       , SP.[Fax Extension]              
       , CASE WHEN COALESCE(SP.[Team Phone Extension],'''')='''' THEN ''800'' ELSE COALESCE(SP.[Team Phone Extension],''800'') END            
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
       , SH.[Document Date]
       , SH.[Posting Description]       
       , SH.[Currency Code]
       , SH.[Currency Factor]
       , CU.[Currency Code]
       , RJ.[Hotel Contact Name]
       , RJ.[Guest Name]
       , RJ.[Arrival Date]
       , RJ.[Process Number]
       , RJ.[Booking Code]
       , RJ.[Description]
       , BA.[Bank Branch No_]
       , BA.[Bank Account No_]
       , BA.[Name]
       , BA.[IBAN] 
       , BA.[SWIFT Code]
       , RJ.[Hotel No_]
       '
	EXECUTE(@SQLStatement)  
	PRINT(@SQLStatement)       

	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
  INSERT INTO #RESULTS
  SELECT SH.[No_]
       , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
       , SH.[Bill-to Country_Region Code] AS [Bill-to Country Code]
       , SH.[Bill-to Country_Region Code]
       , SH.[Bill-to Customer No_]
       , SH.[Bill-to Contact]            
       , SH.[Posting Date]
       , SH.[Payment Method Code]
       , CO.[EU Country_Region Code]      AS [EU Ländercode]
       , SH.[Language Code]               AS [ISO_Code]
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
       , SP.[Fax Extension]               AS [Durchwahl Fax]
	   , CASE WHEN COALESCE(SP.[Team Phone Extension],'''')='''' THEN ''800'' ELSE COALESCE(SP.[Team Phone Extension],''800'') END [Durchwahl Telefon]
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
       , SH.[Document Date]
       , SH.[Posting Description]       
       , SH.[Currency Code]
       , MAX(SL.[VAT %])                  AS VAT
       , SUM(SL.[Line Amount])            AS Amount
       , SUM(SL.[Line Amount])*MAX(SL.[VAT %])/100 AS Mwst
       , SUM(SL.[Line Amount])*(1+MAX(SL.[VAT %])/100)   AS Total
       , SH.[Currency Factor]
       , CU.[Currency Code] [Customer Currency Code]
       , RJ.[Hotel Contact Name]
       , RJ.[Guest Name]
       , RJ.[Arrival Date]
       , RJ.[Process Number]
       , RJ.[Booking Code]
       , RJ.[Description]
       , RTRIM(BA.[Bank Branch No_]) [Bank Branch No_]
       , RTRIM(BA.[Bank Account No_]) [Bank Account No_]
       , RTRIM(BA.[Name])                                     [Bank Name]
       , RTRIM(BA.[IBAN])                                     [IBAN]
       , RTRIM(BA.[SWIFT Code])                               [BIC]
       , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
       , MAX(CAST(CU.[Contract Status] AS int))               [Vertrag Status]
       , MAX(CASE WHEN CU.[Contract Status] = ''10'' OR CU.[Contract Status] = ''11'' THEN
           ''''
         ELSE
           CASE 
             WHEN '',29,57,92,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
               ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441''
             WHEN '',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
               ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447''
             ELSE
               ''''
           END    
         END) [Special Fax]
       , CASE 
           WHEN '',29,57,92,10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN 
             ''accounting_fax@hrs.cn''
           ELSE 
             SP.[Fax Extension] + ''@hrs.de''
         END [Special E-Mail]
       , RJ.[Hotel No_]
-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004	
         , ' + CASE WHEN @InvoicingInLocalCurrency=1 AND @CurrencyCodeCountry<>@CurrencyCodeinvoice THEN '1' ELSE '0' END + ' [Invoicing in local currency]
         , ' + CASE WHEN @InvoicingInLocalCurrency= 1 THEN ''''+@CurrencyCodeCountry+'''' ELSE 'NULL' END + '           [Currency Code Country]
         , ' + CAST(@ExchangeRateInvoice AS varchar(max)) + '                                                                     [Exchange Rate Invoice]
         , ' + CAST(@ExchangeRateCountry AS varchar(max)) + '                                                                      [Exchange Rate Country]
         , ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '                                               [Exchange Rate]
         , SUM(ROUND(SL.[Amount],2)) * ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '                   [Amount Country]
         , SUM(ROUND(SL.[Amount Including VAT],2)) - SUM(ROUND(SL.[Amount],2)) 
         * ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '                                               [Mwst Country]
         , SUM(ROUND(SL.[Amount Including VAT],2)) * ' + CAST(@ExchangeRateCountry / @ExchangeRateInvoice AS varchar(max)) + '     [Total Country]
-- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
    FROM [' + @Company + '$Sales Header] AS SH WITH (READUNCOMMITTED)
    JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
      ON SH.[Sell-to Customer No_] = CU.[No_]
    JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
      ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
    JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
      ON SH.[Salesperson Code] = SP.Code 
    JOIN [' + @Company + '$Sales Line] AS SL WITH (READUNCOMMITTED) 
      ON SH.No_ = SL.[Document No_] 
    JOIN [' + @Company + '$Refund Journal] RJ WITH (NOLOCK)
      ON RJ.[Document No_ (NAV)] = SH.[No_]
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
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
   WHERE (SH.No_ = ''' + @ReNr + ''')
GROUP BY SH.[No_]
       , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END
       , SH.[Sell-to Post Code]
       , SH.[Bill-to Country_Region Code]
       , SH.[Bill-to Customer No_]
       , SH.[Bill-to Contact]            
       , SH.[Posting Date]
       , SH.[Payment Method Code]
       , CO.[EU Country_Region Code]     
       , SH.[Language Code]                  
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
       , SP.[Fax Extension]              
       , CASE WHEN COALESCE(SP.[Team Phone Extension],'''')='''' THEN ''800'' ELSE COALESCE(SP.[Team Phone Extension],''800'') END            
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
       , SH.[Document Date]
       , SH.[Posting Description]       
       , SH.[Currency Code]
       , SH.[Currency Factor]
       , CU.[Currency Code]
       , RJ.[Hotel Contact Name]
       , RJ.[Guest Name]
       , RJ.[Arrival Date]
       , RJ.[Process Number]
       , RJ.[Booking Code]
       , RJ.[Description]
       , BA.[Bank Branch No_]
       , BA.[Bank Account No_]
       , BA.[Name]
       , BA.[IBAN] 
       , BA.[SWIFT Code]
       , RJ.[Hotel No_]
       '
	EXECUTE(@SQLStatement) 
	PRINT(@SQLStatement) 
	SELECT * FROM #RESULTS
END

GO
