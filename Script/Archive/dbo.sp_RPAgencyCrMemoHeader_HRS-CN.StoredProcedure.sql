USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPAgencyCrMemoHeader_HRS-CN]    Script Date: 10.04.2024 14:31:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 10.10.2016
-- Description:	Get Content for Cr. Memo Document
--

-- Date     Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 10.10.16 HRS001    -----  TM     Copy of sp_RPKommSalesInvoiceHeader
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'VG000003297'
EXEC [dbo].[sp_RPAgencyCrMemoHeader_HRS-CN] @ReNr

*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPAgencyCrMemoHeader_HRS-CN] 
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr

-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
    DECLARE @ExchangeRateInvoice decimal(37,20) = 1.0
	      , @ExchangeRateCountry decimal(37,20) = 1.0
		  , @CurrencyCodeCountry varchar(10) = 'EUR'
		  , @CurrencyCodeinvoice varchar(10) = 'EUR'
		  , @InvoicingInLocalCurrency int = 0
  IF EXISTS (SELECT * FROM [HRS-CN$Agency Cr_ Memo Header] AH WITH (NOLOCK) JOIN [HRS-CN$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[No_] = @ReNr OR AH.[Posted Cr_ Memo No_] = @ReNr) AND CR.[Invoicing in local currency]=1) 
  BEGIN
	;WITH 
	   AH AS	(SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS-CN$Agency Cr_ Memo Header] AH WITH (NOLOCK) JOIN [HRS-CN$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[No_] = @ReNr OR AH.[Posted Cr_ Memo No_] = @ReNr)
    --, _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS-CN$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date] UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS-CN$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date])
    --, ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
	SELECT @ExchangeRateInvoice = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code] THEN ER.[Exchange Rate Amount] ELSE 1 END)
	     , @ExchangeRateCountry = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code Country] THEN ER.[Exchange Rate Amount] ELSE 1 END)
		 , @CurrencyCodeCountry = MAX(AH.[Currency Code Country])
		 , @CurrencyCodeinvoice = MAX(AH.[Currency Code])
		 , @InvoicingInLocalCurrency = MAX(AH.[Invoicing in local currency])
	  FROM AH
	 -- JOIN ExchangeRate ER
	 --   ON ER.[Currency Code] = AH.[Currency Code]
		--OR ER.[Currency Code] = AH.[Currency Code Country]
	  JOIN [HRS-CN$OANDA_Currency Exchange Rate] ER
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
  END
  PRINT '@CurrencyCodeCountry=' + @CurrencyCodeCountry
  PRINT '@ExchangeRateCountry=' + CAST(@ExchangeRateCountry AS varchar(max))
  PRINT '@CurrencyCodeinvoice=' + @CurrencyCodeinvoice
  PRINT '@ExchangeRateInvoice=' + CAST(@ExchangeRateInvoice AS varchar(max))
 -- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004

    -- Insert statements for procedure here
    ;WITH AL AS
	(
	SELECT AL.[Document No_]
	     , AH.[Bill-to Customer No_]
	     , SUM(ROUND(AL.[Line Amount Diff_ (LCY)],20)) [Line Amount]
	     , ROUND(SUM(ROUND(AL.[Line Amount Diff_ (LCY)],20))*1.19,2) [Total Amount incl_ VAT]
	     , ROUND(SUM(ROUND(AL.[Line Amount Diff_ (LCY)],20))*0.19,2) [VAT]
		 , MAX(CASE WHEN AL.[Calculated with Function ID] IN ('8','9','10') THEN 1 ELSE 0 END) [Net Based]
	  FROM [HRS-CN$Agency Cr_ Memo Line] AL WITH (NOLOCK)
	  JOIN [HRS-CN$Agency Cr_ Memo Header] AH WITH (NOLOCK)
	    ON AH.[No_] = AL.[Document No_]
     WHERE (AH.[Posted Cr_ Memo No_] = @ReNr OR AH.[No_] = @ReNr2)
	   AND AL.[Action] IN ('Refund','apply')
	   AND AL.[Source] IN ('CI','CCR','MICE','HOTEL.DE','TMC','DEALS')
  GROUP BY AL.[Document No_]
	     , AH.[Bill-to Customer No_]
	), EP AS
	(
	SELECT AL.[Bill-to Customer No_]
	     , MAX(CASE WHEN [FieldID] = 2 THEN EP.[Content] ELSE NULL END) [Bill-to Name]
	     , MAX(CASE WHEN [FieldID] = 4 THEN EP.[Content] ELSE NULL END) [Bill-to Name 2]
	     , MAX(CASE WHEN [FieldID] = 5 THEN EP.[Content] ELSE NULL END) [Bill-to Address]
	     , MAX(CASE WHEN [FieldID] = 6 THEN EP.[Content] ELSE NULL END) [Bill-to Address 2]
	     , MAX(CASE WHEN [FieldID] = 7 THEN EP.[Content] ELSE NULL END) [Bill-to City]
	     , MAX(CASE WHEN [FieldID] = 50012 THEN EP.[Content] ELSE '' END) [Country Name]
	  FROM AL
 LEFT JOIN [ExtendedProperties] EP WITH (NOLOCK) 
        ON AL.[Bill-to Customer No_] = EP.KeyField1Value
	   AND EP.[TableID] = 18
	   AND EP.[FieldID] IN (2,4,5,6,7,50012)
  GROUP BY AL.[Bill-to Customer No_]
	)
--	SELECT * FROM EP
    SELECT AH.[Bill-to Customer No_]
         , AH.[Posting Date]
         , AH.[Document Date]                  [Document Date]
         , AH.[Currency Code]
         , CASE WHEN AH.[Currency Factor]=0 THEN 1 ELSE AH.[Currency Factor] END [Currency Factor]
         , CASE WHEN AH.[Language Code]=''  THEN CO.[Primary Language Code] ELSE AH.[Language Code] END [Language Code]
         , CASE WHEN EP.[Bill-to Name] IS NULL      THEN AH.[Bill-to Name]          ELSE EP.[Bill-to Name]       END [Sell-to Customer Name]
         , CASE WHEN EP.[Bill-to Name 2] IS NULL    THEN AH.[Bill-to Name 2]        ELSE EP.[Bill-to Name 2]       END [Sell-to Customer Name 2]
         , CASE WHEN EP.[Bill-to Address] IS NULL   THEN AH.[Bill-to Address]       ELSE EP.[Bill-to Address]       END [Sell-to Address]
         , CASE WHEN EP.[Bill-to Address 2] IS NULL THEN AH.[Bill-to Address 2]     ELSE EP.[Bill-to Address 2]       END [Sell-to Address 2]
         , CASE WHEN EP.[Bill-to City] IS NULL      THEN AH.[Bill-to City]          ELSE EP.[Bill-to City]       END [Sell-to City]
         , AH.[Bill-to Post Code]           AS [Sell-to Post Code]
         , AH.[Bill-to Country_Region Code] AS [Sell-to Country Code]
         , AH.[Bill-to Contact]             AS [Sell-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CASE WHEN EP.[Bill-to Name] IS NULL   THEN CO.Name                    ELSE EP.[Country Name]       END Name
         , CO.[EU Country_Region Code][EU Ländercode]
         , CASE 
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN SP.[Fax Extension]
             WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END [Durchwahl Fax]
         , CASE WHEN COALESCE(SP.[Team Phone Extension],'')='' THEN '800' ELSE COALESCE(SP.[Team Phone Extension],'800') END [Phone Extension]
         , RTRIM(COALESCE(BA.[Bank Branch No_],'')) [Bank Branch No_]
         , RTRIM(COALESCE(BA.[Bank Account No_],'')) [Bank Account No_]
         , RTRIM(COALESCE(BA.[Name],''))                                     [Bank Name]
         , RTRIM(COALESCE(BA.[IBAN],''))                                     [IBAN]
         , RTRIM(COALESCE(BA.[SWIFT Code],''))                               [BIC]
         , LA.[ISO Code]                                        [ISO_Code]

         , CASE WHEN (COALESCE(AH.[Gen_ Bus_ Posting Group],'INLAND') = 'INLAND') THEN 19   ELSE 0 END [VAT]
         , AL.[Line Amount] * 1.00 * AH.[Currency Factor]                                             [Amount]
         , AL.[Line Amount] * 0.02 * AH.[Currency Factor]                                             [Interest Amount]
         , CASE WHEN (COALESCE(AH.[Gen_ Bus_ Posting Group],'INLAND') = 'INLAND') THEN 0.19 ELSE 0 END 
		 * AL.[Line Amount] * 1.02 * AH.[Currency Factor]                                             [Mwst]
         , CASE WHEN (COALESCE(AH.[Gen_ Bus_ Posting Group],'INLAND') = 'INLAND') THEN 1.19 ELSE 1 END 
		 * AL.[Line Amount] * 1.02 * AH.[Currency Factor]                                             [Total]

         , (CAST(JO.[Contract Status] AS int))               [Vertrag Status]
         , (CO.Continent)                                    Continent
         , (CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END) SEPA
         , [Posted Cr_ Memo No_]
         , (
           CASE 
             WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
               ''
             ELSE
               CASE 
                 WHEN ',29,57,92,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
                   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441'
                 WHEN ',30,67,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
                   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447'
                 ELSE
                   ''
               END    
           END) [Special Fax]
         , 'spezial@hrs.de' [Special E-Mail]
         , AH.MuseID
         , CU.[Contract Status]
-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004	
         , CASE WHEN @InvoicingInLocalCurrency=1 AND @CurrencyCodeCountry<>@CurrencyCodeinvoice THEN 1 ELSE 0 END [Invoicing in local currency]
		 , CASE WHEN @InvoicingInLocalCurrency = 1 THEN @CurrencyCodeCountry ELSE NULL END [Currency Code Country]
		 , @ExchangeRateInvoice                                                            [Exchange Rate Invoice]
		 , @ExchangeRateCountry                                                            [Exchange Rate Country]
		 , @ExchangeRateCountry / @ExchangeRateInvoice                                     [Exchange Rate]
		 , CO.[Name] [Sell-to Country Name]
-- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
      FROM [HRS-CN$Agency Cr_ Memo Header]       AH WITH (READUNCOMMITTED)
      JOIN AL
        ON AL.[Document No_]                = AH.[No_]
      JOIN EP
        ON EP.[Bill-to Customer No_]        = AH.[Bill-to Customer No_]
      JOIN [HRS-CN$Customer]                     CU WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = CU.[No_] 
      JOIN [HRS-CN$Country_Region]               CO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Country_Region Code] = CO.Code
      JOIN [HRS-CN$Language]                     LA WITH (READUNCOMMITTED)
        ON AH.[Language Code]               = LA.Code 
      JOIN [HRS-CN$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS-CN$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = AH.[Salesperson Code]
 LEFT JOIN [HRS-CN$Printer Group]                PG WITH (READUNCOMMITTED)
        ON PG.[Code]                        = 'PEGASUS'
 LEFT JOIN [HRS-CN$Printer Group]                SE WITH (READUNCOMMITTED)
        ON SE.[Code]                        = 'SEPA'
 LEFT JOIN [HRS-CN$Printer Group]                CR WITH (READUNCOMMITTED)
        ON CR.[Code]                        = 'CORE'
 LEFT JOIN [HRS-CN$Printer Group]                LT WITH (READUNCOMMITTED)
        ON LT.[Code]                        = 'LAST'
 LEFT JOIN [HRS-CN$Printer Group]                AC WITH (READUNCOMMITTED)
        ON AC.[Code]                        = 'AUTO_CC'
      JOIN [HRS-CN$Customer]                          JO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS-CN$Responsibility Center]        RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center]       = RC.Code
 LEFT JOIN [HRS-CN$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = BA.[Customer No_]
       AND BA.Clearing                      = 1 
 LEFT JOIN [HRS-CN$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
END
GO
