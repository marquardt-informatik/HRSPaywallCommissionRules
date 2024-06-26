USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceHeader_HI]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 17.06.2011
-- Description:	Kopie der SP vom P-NAV-MSSQL-1
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 07.07.11 HRS001    27148  JH bss Um die Servicegebühr im Beleg darzustellen wurde die Berechnung für Mwst und Amount geändert. Außerdem das
--                                  Feld Service Amount hinzugefügt.
-- 21.09.11 HRS002    49724  TM     [Hide Amount] eingefügt zur Steuerung der Ausgabe der Betragswerte
-- 27.09.13 HRS003    80866  TM     Für Deutschland <Fax-Nummer>@hrs.de statt accounting@hrs.de
-- 17.04.15 HRS004    93269  TM     Display Country Currency if configured
-- 12.07.15 HRS005			 RPR	Different Selects
-- 07.10.15 HRS006			 RPR    Change Exist with ELSE; [SIH].[Language Code] with Value 'DE' (old Invoices)
-- 09.03.16 HRS007			 RPR    Round [Line Amount], [Line Amount incl. Vat], [Vat] for better values
-- 10.01.18 HRS008           RPR    Problem with Customer 3029 by Reportlayout -> If SIH exist then use the secound part of this procedure
/*

Normale geb. VK-Rechnung
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'R10021416'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader_HI] @ReNr

geb. Kommissionsrechnung
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'V000000522'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader_HI] @ReNr


exec sp_RPKommSalesInvoiceHeader_SIK @ReNr=N'20002590'
SELECT * FROM [HRS Holidays$Agency Display Header] AH WHERE AH.[Posted Invoice No_] = @ReNr
*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceHeader_HI] 
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr

	-->> HRS005 RPR
	IF EXISTS (SELECT * FROM [HRS Holidays$Agency Display Header] AH WITH (NOLOCK)
				-->>RPR HRS008 20180110 
				--WHERE (AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr))
				WHERE (AH.[Case No_] = @ReNr AND AH.[Posted Invoice No_] IS NULL))
				--<<RPR HRS008 20180110 
	BEGIN
	--<< HRS005 RPR
	-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
		DECLARE @ExchangeRateInvoice decimal(37,20) = 1.0
			  , @ExchangeRateCountry decimal(37,20) = 1.0
			  , @CurrencyCodeCountry varchar(10) = 'EUR'
			  , @CurrencyCodeinvoice varchar(10) = 'EUR'
			  , @InvoicingInLocalCurrency int = 0
	  IF EXISTS (SELECT * FROM [HRS Holidays$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS Holidays$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr) AND CR.[Invoicing in local currency]=1) 
	  BEGIN
		;WITH 
		   AH AS	(SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS Holidays$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS Holidays$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr)
		--, _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS Holidays$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date] UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS Holidays$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date])
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
		  JOIN [HRS Holidays$OANDA_Currency Exchange Rate] ER
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
		;WITH BANK AS
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
			FROM [HRS Holidays$Bank Regulation] BR WITH (READUNCOMMITTED)
			--JOIN [HRS Holidays$Bank Account]    BA WITH (READUNCOMMITTED)
			--  ON BR.[Bank No_] = BA.[No_]
			JOIN [Bank] BK WITH (READUNCOMMITTED)
			  ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
	--       WHERE BR.[Country Code] IN ('15','114','43')
		), AL AS
		(
		SELECT AL.[Display Case No_]
			 , AH.[Bill-to Customer No_]
			 -->> HRS007 RPR 
			 -- Auf die 3te Nachkommastelle geschaut und dementsprechend Brutto minus Netto oder Brutto minus Steuer gerechnet
			 , SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],2)) [Line Amount]							
			 , ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],2))*1.19,2) [Line Amount incl_ VAT]	
			 , ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],2))*0.19,2) [VAT]					
			 --, CASE WHEN SUBSTRING(CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,3) AS varchar),CHARINDEX('.', CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,3) AS varchar)) + 3, 1) > 5
				--    THEN CASE WHEN SUBSTRING(CAST(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)) AS varchar),CHARINDEX('.', CAST(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)) AS varchar)) + 3, 1) > SUBSTRING(CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3) AS varchar),CHARINDEX('.', CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3) AS varchar)) + 3, 1)
				--			  THEN ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)), 2)
				--			  ELSE ROUND(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,3), 2) - ROUND(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3), 2)
				--			  END
				--    ELSE ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)), 2)
			 --  END									[Line Amount]
			 --, ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,2) [Line Amount incl_ VAT]
			 --, CASE WHEN SUBSTRING(CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,3) AS varchar),CHARINDEX('.', CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,3) AS varchar)) + 3, 1) > 5
				--    THEN CASE WHEN SUBSTRING(CAST(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)) AS varchar),CHARINDEX('.', CAST(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)) AS varchar)) + 3, 1) > SUBSTRING(CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3) AS varchar),CHARINDEX('.', CAST(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3) AS varchar)) + 3, 1)
				--			  THEN ROUND(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*1.19,3), 2) - ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3)), 2)
				--			  ELSE ROUND(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3), 2)
				--			  END
				--    ELSE ROUND(ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],3))*0.19,3), 2)
			 --  END									[VAT]
			 --<< HRS007 RPR
			 , MAX(CASE WHEN AL.[Calculated with Function ID] IN ('8','9','10') THEN 1 ELSE 0 END) [Net Based]
		  FROM [HRS Holidays$Agency Display Line] AL WITH (NOLOCK)
		  JOIN [HRS Holidays$Agency Display Header] AH WITH (NOLOCK)
			ON AH.[Case No_] = AL.[Display Case No_]
		 WHERE (AH.[Posted Invoice No_] = @ReNr OR AH.[Case No_] = @ReNr2)
		   AND AL.[Action] <> 3
	  GROUP BY AL.[Display Case No_]
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
			 , AH.[Creation Date]                  [Document Date]
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
				 WHEN AH.[Salesperson Code] IN ('AFR03','FBE02')THEN
				   CASE
					 WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND AH.[Chain Code] = '13' THEN SP.[Fax Extension]
					 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
					 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
					 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
					 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
					 ELSE SP.[Fax Extension]
				   END
				 WHEN CU.[Contract Status] IN('10','11') 
				  --AND AH.MuseID<>'HRS' 
				  --AND CU.[Payment Method Code] <> 'SEPA'
				  --AND NOT CU.[Payment Method Code] LIKE 'LAST%'
				  AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN SP.[Fax Extension]
				 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
				 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
				 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
				 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
				 WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
				 ELSE COALESCE(RC.[Fax No_],'') 
			   END [Durchwahl Fax]
			 , CASE WHEN COALESCE(SP.[Team Phone Extension],'')='' THEN '800' ELSE COALESCE(SP.[Team Phone Extension],'800') END [Phone Extension]
			 , RTRIM(BA.[Bank Branch No_]) [Bank Branch No_]
			 , RTRIM(BA.[Bank Account No_]) [Bank Account No_]
			 , RTRIM(BA.[Name])                                     [Bank Name]
			 , RTRIM(BA.[IBAN])                                     [IBAN]
			 , RTRIM(BA.[SWIFT Code])                               [BIC]
			 , LA.[ISO Code]                                        [ISO_Code]
			 , CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'IN') = 'IN' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 19   ELSE 0 END [VAT]
			 , AL.[Line Amount]                                     [Amount]
			 , CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'IN') = 'IN' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN AL.[VAT] ELSE 0 END [Mwst]
			 , CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'IN') = 'IN' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN AL.[Line Amount incl_ VAT] ELSE AL.[Line Amount] END [Total]
			 , (CAST(JO.[Contract Status] AS int))               [Vertrag Status]
			 , COALESCE(DA.[Hide Amount],0)                         [Hide Amount]
			 , (CO.Continent)                                    Continent
			 , (CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END) SEPA
			 , CASE WHEN [Posted Invoice No_]='' THEN AH.[Unposted Invoice No_] ELSE [Posted Invoice No_] END [Posted Invoice No_]
			 , (
			   CASE 
				 WHEN AH.[Document Type] = '18' THEN 'Tel. +49 (0) 221 2077-3198 - Fax +49 (0) 221 2077-' + COALESCE(DP.[Fax Extension], SP.[Fax Extension])             
				 WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
				   ''
				 ELSE
				   CASE 
					 WHEN ',29,57,92,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
					   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441'
					 WHEN ',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
					   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447'
					 ELSE
					   ''
				   END    
			   END) [Special Fax]
			 , CASE 
				 WHEN AH.[Document Type] = '15' THEN '392@hrs.de'             
				 WHEN AH.[Document Type] = '18' THEN COALESCE(DP.[Fax Extension], SP.[Fax Extension]) + '@hrs.de'             
				 WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND AH.[Chain Code] = '13' THEN SP.[Fax Extension]  + '@hrs.de'
				 WHEN CU.[Payment Method Code] = 'CORE'         THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
				 WHEN CU.[Payment Method Code] = 'SEPA'         THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
				 WHEN CU.[Payment Method Code] = 'CC_AUTO'      THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
				 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'
				 WHEN CU.[Contract Status] IN('10','11') 
				  --AND AH.MuseID<>'HRS' 
				  --AND CU.[Payment Method Code] <> 'SEPA'
				  --AND CU.[Payment Method Code] <> 'CORE'
				  --AND CU.[Payment Method Code] <> 'CC_AUTO'
				  --AND NOT CU.[Payment Method Code] LIKE 'LAST%'
				  AND COALESCE(PG.[Salesperson E-Mail],'')<>'' 
				  THEN SP.[Fax Extension]  + '@hrs.de'
				 WHEN ',29,57,92,10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN 
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
			   END [Special E-Mail]
			 , AH.MuseID
			 , CU.[Contract Status]
			 , AH.[Document Type]
			 , AH.[Loyality Rewards Account No_] [Special Text]
			 , AL.[Net Based]
			 , (COALESCE(B1.[Description],'')) [Bank_1_Descrption]
			 , (COALESCE(B1.[Account],''))     [Bank_1_Account]
			 , (COALESCE(B1.[BLZ],''))         [Bank_1_BLZ]
			 , (COALESCE(B1.[Swift],''))       [Bank_1_Swift]
			 , (COALESCE(B1.[IBAN],''))        [Bank_1_IBAN]
			 , COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),'')          [Bank_1_BankTxt]
			 , (COALESCE(B2.[Description],'')) [Bank_2_Descrption]
			 , (COALESCE(B2.[Account],''))     [Bank_2_Account]
			 , (COALESCE(B2.[BLZ],''))         [Bank_2_BLZ]
			 , (COALESCE(B2.[Swift],''))       [Bank_2_Swift]
			 , (COALESCE(B2.[IBAN],''))        [Bank_2_IBAN]
			 , COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),'')          [Bank_2_BankTxt]
			 , (COALESCE(B3.[Description],'')) [Bank_3_Descrption]
			 , (COALESCE(B3.[Account],''))     [Bank_3_Account]
			 , (COALESCE(B3.[BLZ],''))         [Bank_3_BLZ]
			 , (COALESCE(B3.[Swift],''))       [Bank_3_Swift]
			 , (COALESCE(B3.[IBAN],''))        [Bank_3_IBAN]
			 , COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),'')          [Bank_3_BankTxt]
	-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004	
			 , CASE WHEN @InvoicingInLocalCurrency=1 AND @CurrencyCodeCountry<>@CurrencyCodeinvoice THEN 1 ELSE 0 END [Invoicing in local currency]
			 , CASE WHEN @InvoicingInLocalCurrency = 1 THEN @CurrencyCodeCountry ELSE NULL END [Currency Code Country]
			 , @ExchangeRateInvoice                                                            [Exchange Rate Invoice]
			 , @ExchangeRateCountry                                                            [Exchange Rate Country]
			 , @ExchangeRateCountry / @ExchangeRateInvoice                                     [Exchange Rate]
			 , (ROUND(AL.[Line Amount],2)) * @ExchangeRateCountry / @ExchangeRateInvoice    [Amount Country]
			 , (ROUND(AL.[Line Amount],2)) 
			 * CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'IN') = 'IN' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 0.19 ELSE 0 END 
			  * @ExchangeRateCountry / @ExchangeRateInvoice                                    [Mwst Country]
			 , (ROUND(AL.[Line Amount],2)) 
			 * CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'IN') = 'IN' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 1.19 ELSE 1 END 
			  * @ExchangeRateCountry / @ExchangeRateInvoice                                    [Total Country]
			 , CO.[Name] [Sell-to Country Name]
	-- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
			 -->> HRS005 RPR
			 , [CU].[VAT Registration No_]
			 , 'ADH'													[Origin]
			 --<< HRS005 RPR
		  FROM [HRS Holidays$Agency Display Header]        AH WITH (READUNCOMMITTED)
		  JOIN AL
			ON AL.[Display Case No_]            = AH.[Case No_]
		  JOIN EP
			ON EP.[Bill-to Customer No_]        = AH.[Bill-to Customer No_]
		  JOIN [HRS Holidays$Customer]                     CU WITH (READUNCOMMITTED)
			ON AH.[Bill-to Customer No_]        = CU.[No_] 
		  JOIN [HRS Holidays$Country_Region]               CO WITH (READUNCOMMITTED)
			ON AH.[Bill-to Country_Region Code] = CO.Code
		  JOIN [HRS Holidays$Language]                     LA WITH (READUNCOMMITTED)
			ON AH.[Language Code]               = LA.Code 
		  JOIN [HRS Holidays$Printer Group]                SP WITH (READUNCOMMITTED)
			ON SP.[Code]                        = CU.[Salesperson Code]
	 LEFT JOIN [HRS Holidays$Printer Group]                DP WITH (READUNCOMMITTED)
			ON DP.[Code]                        = AH.[Salesperson Code]
	 LEFT JOIN [HRS Holidays$Printer Group]                PG WITH (READUNCOMMITTED)
			ON PG.[Code]                        = 'PEGASUS'
	 LEFT JOIN [HRS Holidays$Printer Group]                SE WITH (READUNCOMMITTED)
			ON SE.[Code]                        = 'SEPA'
	 LEFT JOIN [HRS Holidays$Printer Group]                CR WITH (READUNCOMMITTED)
			ON CR.[Code]                        = 'CORE'
	 LEFT JOIN [HRS Holidays$Printer Group]                LT WITH (READUNCOMMITTED)
			ON LT.[Code]                        = 'LAST'
	 LEFT JOIN [HRS Holidays$Printer Group]                AC WITH (READUNCOMMITTED)
			ON AC.[Code]                        = 'AUTO_CC'
		  JOIN [HRS Holidays$Customer]                          JO WITH (READUNCOMMITTED)
			ON AH.[Bill-to Customer No_]        = JO.[No_] 
	 --LEFT JOIN [HRS Holidays$Sales Invoice Header]         SH WITH (READUNCOMMITTED)
	 --       ON SH.[No_] = AH.[Posted Invoice No_]
	 LEFT JOIN [HRS Holidays$Responsibility Center]  RC WITH (READUNCOMMITTED)
			ON CU.[Responsibility Center] = RC.Code
	 LEFT JOIN [HRS Holidays$Customer Bank Account]        BA WITH (READUNCOMMITTED)
			ON AH.[Bill-to Customer No_] = BA.[Customer No_]
		   AND BA.Clearing =1 
	 LEFT JOIN [HRS Holidays$Bank Branch No_]              BB WITH (READUNCOMMITTED)
			ON BA.[Bank Branch No_]             = BB.Code
	 LEFT JOIN [HRS Holidays$Document Type Assignment] DA WITH (READUNCOMMITTED)
			ON DA.[Brand Code]                  = AH.[Brand Code]
		   AND DA.[Muse ID]                     = AH.[MuseID]
		   AND DA.[Document Type]               = AH.[Document Type]
	 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = AH.[Bill-to Country_Region Code]       
	 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = AH.[Bill-to Country_Region Code]       
	 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = AH.[Bill-to Country_Region Code] 
 
	-->> HRS005 RPR
	END  
	-->> HRS006 RPR
	--IF EXISTS (SELECT * FROM [HRS Holidays$Sales Invoice Header] [SIH] WITH (NOLOCK)
	--			WHERE [SIH].[No_] = @ReNr)
	ELSE
	--<< HRS006 RPR
	BEGIN
		--Normale geb. VK-Rechnung
		;WITH [SIH] AS	
		(
			SELECT [SIH].[Posting Date], [SIH].[Currency Code], [CR].[Invoicing in local currency], [CR].[Currency Code] [Currency Code Country] 
			  FROM [HRS Holidays$Sales Invoice Header]			[SIH]	WITH (NOLOCK) 
			  JOIN [HRS Holidays$Country_Region]				[CR]	WITH (NOLOCK) 
				--ON [SIH].[Bill-to Country_Region Code] = [CR].[Code]
				ON (CASE WHEN [SIH].[Bill-to Country_Region Code] = ''
					     THEN '33' 
					     ELSE [SIH].[Bill-to Country_Region Code] 
					END) = [CR].[Code]
			 WHERE [SIH].[No_] = @ReNr
		)

		SELECT @ExchangeRateInvoice = MAX(CASE WHEN [ER].[Currency Code] = [SIH].[Currency Code] THEN [ER].[Exchange Rate Amount] ELSE 1 END)
			 , @ExchangeRateCountry = MAX(CASE WHEN [ER].[Currency Code] = [SIH].[Currency Code Country] THEN [ER].[Exchange Rate Amount] ELSE 1 END)
			 , @CurrencyCodeCountry = MAX([SIH].[Currency Code Country])
			 , @CurrencyCodeinvoice = MAX([SIH].[Currency Code])
			 , @InvoicingInLocalCurrency = MAX([SIH].[Invoicing in local currency])
			FROM [SIH]												WITH (NOLOCK)
			JOIN [HRS Holidays$OANDA_Currency Exchange Rate] [ER]	WITH (NOLOCK)
			  ON ([ER].[Currency Code] = [SIH].[Currency Code] OR ER.[Currency Code] = [SIH].[Currency Code Country])
			 AND [ER].[Starting Date] = [SIH].[Posting Date]

			IF @CurrencyCodeCountry IS NULL 
			BEGIN
				SET @ExchangeRateInvoice = 1.0
				SET @ExchangeRateCountry = 1.0
				SET @CurrencyCodeCountry = 'EUR'
				SET @CurrencyCodeinvoice = 'EUR'
				SET @InvoicingInLocalCurrency = 0
			END;

		PRINT '@CurrencyCodeCountry=' + @CurrencyCodeCountry
		PRINT '@ExchangeRateCountry=' + CAST(@ExchangeRateCountry AS varchar(max))
		PRINT '@CurrencyCodeinvoice=' + @CurrencyCodeinvoice
		PRINT '@ExchangeRateInvoice=' + CAST(@ExchangeRateInvoice AS varchar(max))

		;WITH [BANK] AS
			(
			  SELECT [BR].[Sequences]
				   , [BR].[Country Code]
				   , [BK].[BankTxt]
				   , [BK].[BLZ]
				   , [BK].[Swift]
				   , [BK].[IBAN]
				   , [BK].[Account]
				   , [BK].[Description]
				   , [BR].[Sequences]    [Reihenfolgen]
				FROM [HRS Holidays$Bank Regulation]		[BR] WITH (NOLOCK)
				JOIN [Bank]								[BK] WITH (NOLOCK)
				  ON [BR].[Bank No_] = [BK].[BankCode] COLLATE Latin1_General_CI_AS
			), [SIL] AS
			(
			SELECT [SIL].[Document No_] 
				 , MAX([SIL].[Display Case No_])												[Display Case No_]
				 , [SIH].[Bill-to Customer No_]
				 , SUM(ROUND([SIL].[Amount],2))													[Line Amount]
				 , SUM(ROUND([SIL].[Amount Including VAT],2))									[Line Amount incl_ VAT]
				 , SUM(ROUND([SIL].[Amount Including VAT],2)) - SUM(ROUND([SIL].[Amount],2))	[VAT]
				 , 0																			[Net Based] --Feld nicht vorhanden!
			  FROM [HRS Holidays$Sales Invoice Line]	[SIL]	WITH (NOLOCK)
			  JOIN [HRS Holidays$Sales Invoice Header]	[SIH]	WITH (NOLOCK)
				ON [SIL].[Document No_] = [SIH].[No_]
			 WHERE [SIH].[No_] = @ReNr
		  GROUP BY [SIL].[Document No_] 
				 , [SIH].[Bill-to Customer No_]
			)

		SELECT [SIH].[Bill-to Customer No_]					[Bill-to Customer No_]
			 , [SIH].[Posting Date]							[Posting Date]
			 , [SIH].[Document Date]						[Document Date]
			 , CASE WHEN [SIH].[Currency Code] = '' THEN 'EUR' ELSE [SIH].[Currency Code] END							[Currency Code]
			 , CASE WHEN [SIH].[Currency Factor] = 0 THEN 1 ELSE [SIH].[Currency Factor] END							[Currency Factor]
			 -->>RPR 006
			 --, CASE WHEN [SIH].[Language Code] = '' 
			 --  THEN [CR].[Primary Language Code] 
			 , CASE WHEN ([SIH].[Language Code] = '' OR [SIH].[Language Code] = 'DE')  
			 --<<RPR006
				    THEN 0
					ELSE [SIH].[Language Code] 
			   END [Language Code] 	
			 , [SIH].[Sell-to Customer Name]				[Sell-to Customer Name]
			 , [SIH].[Sell-to Customer Name 2]				[Sell-to Customer Name 2]
			 , [SIH].[Sell-to Address]						[Sell-to Address]
			 , [SIH].[Sell-to Address 2]					[Sell-to Address 2]
			 , [SIH].[Sell-to City]							[Sell-to City]
			 , [SIH].[Sell-to Post Code]					[Sell-to Post Code]
			 , [SIH].[Sell-to Country_Region Code]			[Sell-to Country Code]
			 , [SIH].[Sell-to Contact]						[Sell-to Contact]
			 , [SIH].[Payment Method Code]					[Payment Method Code]
			 , [SIH].[Responsibility Center]				[Responsibility Center]
			 , [CR].[Name]									[Name]
			 , [CR].[EU Country_Region Code]				[EU Ländercode]
			 , [PG].[Fax Extension]							[Durchwahl Fax]
			 , CASE WHEN COALESCE([PG].[Team Phone Extension],'')='' THEN '800' ELSE COALESCE([PG].[Team Phone Extension],'800') END [Phone Extension]
			 , RTRIM([CBA].[Bank Branch No_])				[Bank Branch No_]
			 , RTRIM([CBA].[Bank Account No_])				[Bank Account No_]
			 , RTRIM([CBA].[Name])							[Bank Name]
			 , RTRIM([CBA].[IBAN])							[IBAN]
			 , RTRIM([CBA].[SWIFT Code])					[BIC]
			 , [LA].[ISO Code]								[ISO_Code]
			 , CASE WHEN COALESCE([SIH].[VAT Bus_ Posting Group],'IN') = 'IN' AND [SIH].[Bill-to Country_Region Code] = '33' THEN 19   ELSE 0 END [VAT]
			 , [SIL].[Line Amount]							[Amount]
			 , CASE WHEN COALESCE([SIH].[VAT Bus_ Posting Group],'IN') = 'IN' AND [SIH].[Bill-to Country_Region Code] = '33' THEN [SIL].[VAT] ELSE 0 END [Mwst]
			 , CASE WHEN COALESCE([SIH].[VAT Bus_ Posting Group],'IN') = 'IN'  AND [SIH].[Bill-to Country_Region Code] = '33' THEN [SIL].[Line Amount incl_ VAT] ELSE [SIL].[Line Amount] END [Total]
			 , (CAST([C].[Contract Status] AS int))			[Vertrag Status]
			 , 0											[Hide Amount] --Feld nicht vorhanden!
			 , [CR].[Continent]								[Continent]
			 , CASE WHEN [CR].[Bank Country Code] <> '' THEN 1 ELSE 0 END	[SEPA]
			 , [SIH].[No_]									[Posted Invoice No_]
			 , [PG].[Fax Extension]							[Special Fax]
			 , [PG].[Salesperson E-Mail]					[Special E-Mail] --Vielleicht wieder prüfen!!!
			 , '?'											[MuseID] --Feld nicht vorhanden!
			 , [C].[Contract Status]						[Contract Status]
			 , '?'											[Document Type] --Feld nicht vorhanden!
			 , '?'											[Special Text] --Feld nicht vorhanden!
			 , [SIL].[Net Based]							[Net Based]
			 , (COALESCE([B1].[Description],''))			[Bank_1_Descrption]
			 , (COALESCE([B1].[Account],''))				[Bank_1_Account]
			 , (COALESCE([B1].[BLZ],''))					[Bank_1_BLZ]
			 , (COALESCE([B1].[Swift],''))					[Bank_1_Swift]
			 , (COALESCE([B1].[IBAN],''))					[Bank_1_IBAN]
			 , COALESCE(CAST([B1].[BankTxt] AS NVARCHAR(max)),'')          [Bank_1_BankTxt]
			 , (COALESCE([B2].[Description],''))			[Bank_2_Descrption]
			 , (COALESCE([B2].[Account],''))				[Bank_2_Account]
			 , (COALESCE([B2].[BLZ],''))					[Bank_2_BLZ]
			 , (COALESCE([B2].[Swift],''))					[Bank_2_Swift]
			 , (COALESCE([B2].[IBAN],''))					[Bank_2_IBAN]
			 , COALESCE(CAST([B2].[BankTxt] AS NVARCHAR(max)),'')          [Bank_2_BankTxt]
			 , (COALESCE([B3].[Description],''))			[Bank_3_Descrption]
			 , (COALESCE([B3].[Account],''))				[Bank_3_Account]
			 , (COALESCE([B3].[BLZ],''))					[Bank_3_BLZ]
			 , (COALESCE([B3].[Swift],''))					[Bank_3_Swift]
			 , (COALESCE([B3].[IBAN],''))					[Bank_3_IBAN]
			 , COALESCE(CAST([B3].[BankTxt] AS NVARCHAR(max)),'')          [Bank_3_BankTxt]
		
			 , CASE WHEN @InvoicingInLocalCurrency=1 AND @CurrencyCodeCountry<>@CurrencyCodeinvoice THEN 1 ELSE 0 END [Invoicing in local currency]
			 , CASE WHEN @InvoicingInLocalCurrency = 1 THEN @CurrencyCodeCountry ELSE NULL END [Currency Code Country]
			 , @ExchangeRateInvoice                                                            [Exchange Rate Invoice]
			 , @ExchangeRateCountry                                                            [Exchange Rate Country]
			 , @ExchangeRateCountry / @ExchangeRateInvoice                                     [Exchange Rate]
			 , (ROUND([SIL].[Line Amount],2)) * @ExchangeRateCountry / @ExchangeRateInvoice    [Amount Country]
			 , (ROUND([SIL].[Line Amount],2)) 
				* CASE WHEN COALESCE([SIH].[VAT Bus_ Posting Group],'IN') = 'IN' AND [SIH].[Bill-to Country_Region Code] = '33' THEN 0.19 ELSE 0 END 
				* @ExchangeRateCountry / @ExchangeRateInvoice                                    [Mwst Country]
			 , (ROUND([SIL].[Line Amount],2)) 
				* CASE WHEN COALESCE([SIH].[VAT Bus_ Posting Group],'IN') = 'IN' AND [SIH].[Bill-to Country_Region Code] = '33' THEN 1.19 ELSE 1 END 
				* @ExchangeRateCountry / @ExchangeRateInvoice                                    [Total Country]
			 , [CR].[Name] [Sell-to Country Name]
			 , [C].[VAT Registration No_]	
			 , 'SIH'													[Origin]
		  FROM [HRS Holidays$Sales Invoice Header]			[SIH]	WITH (NOLOCK)
		  JOIN [SIL]
			ON [SIH].[No_] = [SIL].[Document No_] 
		  JOIN [HRS Holidays$Language]						[LA]	WITH (NOLOCK)
		    -->>RPR 006
			--ON COALESCE([SIH].[Language Code], 0) = [LA].[Code] 		
			ON CASE WHEN ([SIH].[Language Code] = '' OR [SIH].[Language Code] = 'DE')  
				    THEN 0 
					ELSE [SIH].[Language Code] 
			END = [LA].[Code]
			 --<<RPR006
		  JOIN [HRS Holidays$Printer Group]					[PG]	WITH (NOLOCK)
			ON [SIH].[Salesperson Code]			= [PG].[Code]
		  JOIN [HRS Holidays$Customer]						[C]		WITH (NOLOCK)
			ON [SIH].[Bill-to Customer No_]		= [C].[No_] 
		  JOIN [HRS Holidays$Country_Region]				[CR]	WITH (NOLOCK)
			ON (CASE WHEN [SIH].[Bill-to Country_Region Code] = ''
					 THEN '33' 
					 ELSE [SIH].[Bill-to Country_Region Code] 
				END) = [CR].[Code]
	 LEFT JOIN [HRS Holidays$Customer Bank Account]			[CBA] WITH (NOLOCK)
			ON [SIH].[Bill-to Customer No_]		= [CBA].[Customer No_]
		   AND [CBA].[Clearing] = 1
	 LEFT JOIN [BANK] [B1] ON [B1].[Sequences] = 0 AND [B1].[Country Code] = [SIH].[Bill-to Country_Region Code]       
	 LEFT JOIN [BANK] [B2] ON [B2].[Sequences] = 1 AND [B2].[Country Code] = [SIH].[Bill-to Country_Region Code]       
	 LEFT JOIN [BANK] [B3] ON [B3].[Sequences] = 2 AND [B3].[Country Code] = [SIH].[Bill-to Country_Region Code] 
		 WHERE [SIH].[No_] = @ReNr
	END 
	--<< HRS005 RPR  
END
GO
