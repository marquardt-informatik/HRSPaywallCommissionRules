USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceHeader_ACS-2407]    Script Date: 10.04.2024 14:31:48 ******/
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
-- 08.04.16 HRS005    -----  TM     Fax 6447 nur bei Land 30 EMail accountingFax@hrs.cn nur bei Land 29|30|57|92 
-- 22.07.16 HRS006    NAV-134  TM   New Fields: [Multisourced], [Treat hotel as multisource]
-- 13.10.16 HRS007    NAV-342  TM   Wrong Service Daterange on Report when [Posting Date] <> [Creation Date]
-- 12.06.17 HRS008			  RPR	2 NEW Fields: [CU].[HPP Webportal enabled], [CU].[HPP Webportal registered]
-- 10.10.17 HRS009    -----   TM    Rounding precision on column [Commission Amount] let to wrong displayed value -> change to sum on [Line Amount]
-- 28.11.17 HRS010    ACS-107 RPR   New Field [CU].[VAT Registration No_]

-- 23.01.19 HRS012   ACS-1443 SAL   Edit VAT calculation for Russian (Country_Region 202) Invoices
-- 12.02.19 HRS013   ACS-1488 DJU   New Field [Hide Details]
-- 05.11.19 HRS014   ACS-1991 DJU   Added TAF
-- 25.06.20 HRS015   ACS-2301 SAL   Handle temporary reduction of German VAT rates
-- 07.07.20 HRS016   ACS-2301 TM    Handle temporary reduction of German VAT rates
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'V008650008'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader] @ReNr
 SELECT @ReNr = 'V008540087'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader] @ReNr

exec sp_RPKommSalesInvoiceHeader_SIK @ReNr=N'20002590'
SELECT * FROM [HRS$Agency Display Header] AH WHERE AH.[Posted Invoice No_] = @ReNr
*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceHeader_ACS-2407] 
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
		  
  --IF EXISTS (SELECT * FROM [HRS$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr) AND CR.[Invoicing in local currency]=1) 
  --  PRINT 'Invoicing in local currency'
		  
  IF EXISTS (SELECT * FROM [HRS$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE (AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr) AND CR.[Invoicing in local currency]=1) 
  BEGIN
	;WITH 
	   AH AS	(SELECT AH.[Posting Date], AH.[Currency Code], CR.[Invoicing in local currency], CR.[Currency Code] [Currency Code Country] FROM [HRS$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = AH.[Bill-to Country_Region Code] WHERE AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr)
    --, _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date] UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM AH,[HRS$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= AH.[Posting Date])
    --, ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
	SELECT @ExchangeRateInvoice = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code] THEN ER.[Exchange Rate Amount] ELSE 0 END)
	     , @ExchangeRateCountry = MAX(CASE WHEN ER.[Currency Code] = AH.[Currency Code Country] THEN ER.[Exchange Rate Amount] ELSE 0 END)
		 , @CurrencyCodeCountry = MAX(AH.[Currency Code Country])
		 , @CurrencyCodeinvoice = MAX(AH.[Currency Code])
		 , @InvoicingInLocalCurrency = MAX(AH.[Invoicing in local currency])
	  FROM AH
	 -- JOIN ExchangeRate ER
	 --   ON ER.[Currency Code] = AH.[Currency Code]
		--OR ER.[Currency Code] = AH.[Currency Code Country]
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
  --PRINT '@CurrencyCodeCountry=' + @CurrencyCodeCountry
  --PRINT '@ExchangeRateCountry=' + CAST(@ExchangeRateCountry AS varchar(max))
  --PRINT '@CurrencyCodeinvoice=' + @CurrencyCodeinvoice
  --PRINT '@ExchangeRateInvoice=' + CAST(@ExchangeRateInvoice AS varchar(max))
 -- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004

-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
DECLARE @Date1 date, @Date2 date
      , @NetAmount16 DEC(38,20)
	  , @NetAmount19 DEC(38,20)
      , @Amount16 DEC(38,20)
	  , @Amount19 DEC(38,20)
      , @VATAmount16 DEC(38,20)
	  , @VATAmount19 DEC(38,20)
	  , @VATRate16 DEC(38,20) = 0.16
	  , @VATRate19 DEC(38,20) = 0.19
	  , @GenBusPostingGroup varchar(20)

SELECT @Date1 = [VAT Change From Date]-1, @Date2 = [VAT Change To Date]
  FROM [HRS$VAT Rate Change Setup]

SELECT @ReNr=AH.[Case No_], @ReNr2 = AH.[Case No_], @GenBusPostingGroup = CU.[Gen_ Bus_ Posting Group] FROM [HRS$Agency Display Header] AH WITH (NOLOCK) JOIN [HRS$Customer] CU WITH (NOLOCK) ON CU.[No_]=AH.[Bill-to Customer No_] WHERE (AH.[Case No_] = @ReNr OR AH.[Posted Invoice No_] = @ReNr)
PRINT @ReNr
SELECT @NetAmount19 = SUM(ROUND(CASE
         WHEN DH.[Bill-to Country_Region Code]<>'33' THEN NULL
	     WHEN DL.[Reservation Date from]<@Date1 AND DL.[Reservation Date to]>@Date1 THEN DATEDIFF(dd,DL.[Reservation Date from],@Date1)*1.0/DATEDIFF(dd,DL.[Reservation Date from],DL.[Reservation Date to])
	     WHEN DL.[Reservation Date from]<@Date2 AND DL.[Reservation Date to]>@Date2 THEN 1-DATEDIFF(dd,DL.[Reservation Date to],@Date2)*1.0/DATEDIFF(dd,DL.[Reservation Date from],DL.[Reservation Date to])
	     WHEN (DL.[Reservation Date from]<@Date1 AND DL.[Reservation Date to]<=@Date1) OR (DL.[Reservation Date from]>=@Date2 AND DL.[Reservation Date to]>@Date2) THEN 1.0
	     WHEN (DL.[Reservation Date from]>=@Date1 AND DL.[Reservation Date to]>@Date1) AND (DL.[Reservation Date from]<@Date2 AND DL.[Reservation Date to]<=@Date2) THEN 0.0
	   END
     * (DL.[Line Amount]),2)) 
	 , @NetAmount16 = SUM(ROUND((1- CASE
         WHEN DH.[Bill-to Country_Region Code]<>'33' THEN NULL
	     WHEN DL.[Reservation Date from]<@Date1 AND DL.[Reservation Date to]>@Date1 THEN DATEDIFF(dd,DL.[Reservation Date from],@Date1)*1.0/DATEDIFF(dd,DL.[Reservation Date from],DL.[Reservation Date to])
	     WHEN DL.[Reservation Date from]<@Date2 AND DL.[Reservation Date to]>@Date2 THEN 1-DATEDIFF(dd,DL.[Reservation Date to],@Date2)*1.0/DATEDIFF(dd,DL.[Reservation Date from],DL.[Reservation Date to])
	     WHEN (DL.[Reservation Date from]<@Date1 AND DL.[Reservation Date to]<=@Date1) OR (DL.[Reservation Date from]>=@Date2 AND DL.[Reservation Date to]>@Date2) THEN 1.0
	     WHEN (DL.[Reservation Date from]>=@Date1 AND DL.[Reservation Date to]>@Date1) AND (DL.[Reservation Date from]<@Date2 AND DL.[Reservation Date to]<=@Date2) THEN 0.0
	   END)
     * (DL.[Line Amount]),2)) 
  FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
  JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
    ON DH.[Case No_] = DL.[Display Case No_]
  JOIN [HRS$Customer] CU WITH (NOLOCK)
    ON CU.[No_] = DH.[Bill-to Customer No_]
 WHERE [Display Case No_]=@ReNr 
   AND DL.[Action]<>3

SET @VATAmount16=0.0
SET @VATAmount19=0.0
SET @NetAmount16=ROUND(@NetAmount16,2)
SET @NetAmount19=ROUND(@NetAmount19,2)
IF @GenBusPostingGroup='INLAND' 
BEGIN
  SET @VATAmount16 = ROUND(@NetAmount16 * @VATRate16,2)
  SET @VATAmount19 = ROUND(@NetAmount19 * @VATRate19,2)
END

SET @Amount16 = ROUND(@NetAmount16 + @VATAmount16,2)
SET @Amount19 = ROUND(@NetAmount19 + @VATAmount19,2)
IF (@NetAmount19 IS NULL) AND (@NetAmount16 IS NULL)
BEGIN
  SET @VATRate16 = NULL
  SET @VATRate19 = NULL
END
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
        FROM [HRS$Bank Regulation] BR WITH (READUNCOMMITTED)
        --JOIN [HRS$Bank Account]    BA WITH (READUNCOMMITTED)
        --  ON BR.[Bank No_] = BA.[No_]
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
--       WHERE BR.[Country Code] IN ('15','114','43')
    ), AL AS
	(
	SELECT AL.[Display Case No_]
	     , AH.[Bill-to Customer No_]
	     , SUM(AL.[Line Amount]) [Line Amount] -- HRS009: SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],2)) [Line Amount]
	     -- 23.01.19 SAL >>>>>>>>>>>>>>>>>>>> HRS012 
		 --, ROUND(SUM(ROUND(AL.[Line Amount],2))*1.19,2) [Line Amount incl_ VAT] -- HRS009: ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],2))*1.19,2) [Line Amount incl_ VAT]
	     --, ROUND(SUM(ROUND(AL.[Line Amount],2))*0.19,2) [VAT] -- HRS009: ROUND(SUM(ROUND(AL.[Commission Amount]*AL.[Number of Nights],2))*0.19,2) [VAT]
		  -- 25.06.20 SAL HRS015 - last edit
		 , ROUND(SUM(
		    ROUND(AL.[Line Amount],2)*(1 + ISNULL(VATSetup.[VAT %],0) / 100) 
			),2) [Line Amount incl_ VAT]
		 , ROUND(SUM(		  
			ROUND(AL.[Line Amount],2)*(ISNULL(VATSetup.[VAT %],0) / 100) 			
			),2) [VAT] 
		 -- 23.01.19 SAL <<<<<<<<<<<<<<<<<<<< HRS012
		 , MAX(CASE WHEN AL.[Calculated with Function ID] IN ('8','9','10') THEN 1 ELSE 0 END) [Net Based]
		 -- 22.07.16 TM >>>>>>>>>>>>>>>>>>>> HRS006
		 , MAX(AL.Multisourced) Multisourced
		 -- 22.07.16 TM <<<<<<<<<<<<<<<<<<<< HRS006
		 -- 13.10.16 TM >>>>>>>>>>>>>>>>>>>> HRS007
		 , MAX(DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1-DATEPART(dd,AL.[Departure Date]),AL.[Departure Date])))) [Posting Date]
		 -- 13.10.16 TM <<<<<<<<<<<<<<<<<<<< HRS007
		 -- 05.11.19 DJU >>>>>>>>>>>>>>>>>>>> HRS014
		 , SUM(ROUND(AL.[Line Amount]-AL.[TAF Line Amount],2)) [Agency Line Amount]
		 , SUM(ROUND(AL.[TAF Line Amount],2)) [TAF Line Amount]
		 -- 05.11.19 DJU <<<<<<<<<<<<<<<<<<<< HRS014
	  FROM [HRS$Agency Display Line] AL WITH (NOLOCK)
	  JOIN [HRS$Agency Display Header] AH WITH (NOLOCK)
	    ON AH.[Case No_] = AL.[Display Case No_]
-- 25.02.19 SAL >>>>>>>>>>>>>>>>>>>> HRS012 
	  LEFT JOIN [HRS$VAT Posting Setup] VATSetup
		     ON VATSetup.[VAT Bus_ Posting Group] = AH.[VAT Bus_ Posting Group]
		    AND VATSetup.[VAT Prod_ Posting Group] = AH.[VAT Prod_ Posting Group]
		    AND VATSetup.[VAT Calculation Type] = 0
-- 25.02.19 SAL <<<<<<<<<<<<<<<<<<<< HRS012 
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
		 -- 13.10.16 TM >>>>>>>>>>>>>>>>>>>> HRS007
         , AL.[Posting Date]
         -- Original : , AH.[Posting Date]
		 -- 13.10.16 TM <<<<<<<<<<<<<<<<<<<< HRS007
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
         , RTRIM(COALESCE(BA.[Bank Branch No_],'')) [Bank Branch No_]
         , RTRIM(COALESCE(BA.[Bank Account No_],'')) [Bank Account No_]
         , RTRIM(COALESCE(BA.[Name],''))                                     [Bank Name]
         , RTRIM(COALESCE(BA.[IBAN],''))                                     [IBAN]
         , RTRIM(COALESCE(BA.[SWIFT Code],''))                               [BIC]
         , LA.[ISO Code]                                        [ISO_Code]
-- 23.01.19 SAL >>>>>>>>>>>>>>>>>>>> HRS012         
		 --, CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 19   ELSE 0 END [VAT]
         , CASE 
			WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 19   
			WHEN AH.[Bill-to Country_Region Code] = '202' AND AH.[VAT Bus_ Posting Group] = 'RUSSLAND' AND AH.[Posting Date] >= '2019-01-01' THEN VATSetup.[VAT %]
			ELSE 0 END [VAT]
-- 23.01.19 SAL <<<<<<<<<<<<<<<<<<<< HRS012      
-- 05.11.19 DJU >>>>>>>>>>>>>>>>>>>> HRS014
		 , AL.[Line Amount] - AL.[TAF Line Amount] [Commission Amount]
		 , AL.[TAF Line Amount] [TAF Amount]
-- 05.11.19 DJU <<<<<<<<<<<<<<<<<<<< HRS014
         , AL.[Line Amount]                                     [Amount]
-- 23.01.19 SAL >>>>>>>>>>>>>>>>>>>> HRS012
		--, CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN AL.[VAT] ELSE 0 END [Mwst]
		 , CASE	
			WHEN ((COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11'))
			 OR (AH.[Bill-to Country_Region Code] = '202' AND AH.[VAT Bus_ Posting Group] = 'RUSSLAND' AND AH.[Posting Date] >= '2019-01-01')				
			THEN AL.[VAT] 			
			ELSE 0 END [Mwst]     
		 --, CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN AL.[Line Amount incl_ VAT] ELSE AL.[Line Amount] END [Total]
		 , CASE 
			WHEN ((COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11'))
			 OR (AH.[Bill-to Country_Region Code] = '202' AND AH.[VAT Bus_ Posting Group] = 'RUSSLAND' AND AH.[Posting Date] >= '2019-01-01')	
			THEN AL.[Line Amount incl_ VAT] 
			ELSE AL.[Line Amount] END [Total]
-- 23.01.19 SAL <<<<<<<<<<<<<<<<<<<< HRS012	
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
                 WHEN ',30,67,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
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
             WHEN ',29,57,92,30,67,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN 
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
         * CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 0.19 ELSE 0 END 
		  * @ExchangeRateCountry / @ExchangeRateInvoice                                    [Mwst Country]
         , (ROUND(AL.[Line Amount],2)) 
         * CASE WHEN (COALESCE(AH.[VAT Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' AND NOT (AH.[MuseID] = 'IHG' AND AH.[Document Type]='11') THEN 1.19 ELSE 1 END 
		  * @ExchangeRateCountry / @ExchangeRateInvoice                                    [Total Country]
		 , CO.[Name] [Sell-to Country Name]
-- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
-- 22.07.16 TM >>>>>>>>>>>>>>>>>>>> HRS006
		 , AL.Multisourced
		 , CU.[Treat Hotel as multisource]
-- 22.07.16 TM <<<<<<<<<<<<<<<<<<<< HRS006
		 -->>20170612 RPR HRS008
		 , [CU].[HPP Webportal enabled]
		 , [CU].[HPP Webportal registered]
		 --<<20170612 RPR HRS008
		 -- 12.02.18 DJU >>>>>>>>>>>>>>>>>>>> HRS013
		 , CASE 
		     WHEN ([CU].[HPP Webportal enabled] = 1) 
			  AND ([CU].[HPP Webportal registered] = 0)
			  AND ([CU].[HPP Refused] = 0)
			  AND (([CU].[Contract Status] = '01') OR ([CU].[Contract Status] = '02'))
			  AND (AH.[Creation Date] >= '2019-03-31')
			  AND (([CU].[Reminder Terms Code] = 'AT&DE_PEND') OR ([CU].[Reminder Terms Code] = 'STANDARD'))
		     THEN 1 ELSE 0 END [Hide Details]
		 -- 12.02.18 DJU <<<<<<<<<<<<<<<<<<<< HRS013
		 , [CU].[VAT Registration No_]	--HRS010 RPR 20171128
		 , @NetAmount16 [NetAmount16]
		 , @NetAmount19 [NetAmount19]
		 , @Amount16 [Amount16]
		 , @Amount19 [Amount19]
		 , @VATAmount16 [VATAmount16]
		 , @VATAmount19 [VATAmount19]
		 , @VATRate16 [VATRate16]
		 , @VATRate19 [VATRate19]

      FROM [HRS$Agency Display Header]        AH WITH (READUNCOMMITTED)
      JOIN AL
        ON AL.[Display Case No_]            = AH.[Case No_]
      JOIN EP
        ON EP.[Bill-to Customer No_]        = AH.[Bill-to Customer No_]
      JOIN [HRS$Customer]                     CU WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = CU.[No_] 
      JOIN [HRS$Country_Region]               CO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Country_Region Code] = CO.Code
      JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON AH.[Language Code]               = LA.Code 
      JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = AH.[Salesperson Code]
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
        ON AH.[Bill-to Customer No_]        = JO.[No_] 
 --LEFT JOIN [HRS$Sales Invoice Header]         SH WITH (READUNCOMMITTED)
 --       ON SH.[No_] = AH.[Posted Invoice No_]
 LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
 LEFT JOIN [HRS$Document Type Assignment] DA WITH (READUNCOMMITTED)
        ON DA.[Brand Code]                  = AH.[Brand Code]
       AND DA.[Muse ID]                     = AH.[MuseID]
       AND DA.[Document Type]               = AH.[Document Type]
-- 25.02.19 SAL >>>>>>>>>>>>>>>>>>>> HRS012 
LEFT JOIN [HRS$VAT Posting Setup] VATSetup
		ON VATSetup.[VAT Bus_ Posting Group] = AH.[VAT Bus_ Posting Group]
	   AND VATSetup.[VAT Prod_ Posting Group] = AH.[VAT Prod_ Posting Group]
	   AND VATSetup.[VAT Calculation Type] = 0
-- 25.02.19 SAL <<<<<<<<<<<<<<<<<<<< HRS012 
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = AH.[Bill-to Country_Region Code]       
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = AH.[Bill-to Country_Region Code]       
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = AH.[Bill-to Country_Region Code]       
END

GO
