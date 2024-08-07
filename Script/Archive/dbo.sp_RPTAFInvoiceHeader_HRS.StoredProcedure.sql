USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPTAFInvoiceHeader_HRS]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 02.07.20
-- Description:	Rechnungskopf der Transaction Fee für HRS
-- Datum    Version   RFC    Sign.  Description
-- ----------------------------------------------
/*
EXEC [dbo].[sp_RPTAFInvoiceHeader_HRS] '15472074'
EXEC [dbo].[sp_RPTAFInvoiceHeader_HRS] 'TAF0033295'
*/
CREATE PROCEDURE [dbo].[sp_RPTAFInvoiceHeader_HRS] 
    @ReNr varchar(20)
AS
BEGIN
DECLARE @TAFDisplayCaseNo varchar(20)
	  , @CurrencyCodeCountry varchar(10) = 'EUR'
      , @CurrencyCodeinvoice varchar(10) = 'EUR'
	  , @ExchangeRateInvoice decimal(37,20) = 1.0
      , @ExchangeRateCountry decimal(37,20) = 1.0
      , @InvoicingInLocalCurrency int = 0
	  , @PostingDate date
	  , @DocumentDate date
	  , @IsPosted int=2
	  , @VATRate decimal(38,20)
	  , @TotalRate decimal(38,20)
	  , @PostedInvoiceNo varchar(20)

;WITH TH AS
(
SELECT 0 [Posted], TH.[No_], TH.[Display Case No_], TH.[Currency Code], TH.[Currency Factor], TH.[Posting Date], TH.[Document Date], '' [Posted Invoice No_] FROM [HRS$TAF Header] TH WITH (NOLOCK) WHERE TH.No_ = @ReNr UNION
SELECT 1 [Posted], TH.[No_], TH.[Display Case No_], TH.[Currency Code], TH.[Currency Factor], TH.[Posting Date], TH.[Document Date], TH.[Posted Sales Invoice No_] FROM [HRS$TAF Invoice Header] TH WITH (NOLOCK) WHERE  @ReNr IN (TH.No_,TH.[Posted Sales Invoice No_])
)
SELECT @TAFDisplayCaseNo = [Display Case No_] 
     , @InvoicingInLocalCurrency = CR.[Invoicing in local currency]
	 , @CurrencyCodeCountry = CR.[Currency Code]
	 , @CurrencyCodeinvoice = TH.[Currency Code]
	 , @ExchangeRateInvoice = TH.[Currency Factor]
	 , @PostingDate = TH.[Posting Date]
	 , @DocumentDate = TH.[Document Date]
	 , @IsPosted = [Posted]
	 , @PostedInvoiceNo = TH.[Posted Invoice No_]
	 , @ReNr = TH.[No_]
  FROM TH
  JOIN [HRS$Agency Display Header] AH WITH (NOLOCK)
    ON AH.[Case No_] = TH.[Display Case No_]
  JOIN [HRS$Country_Region] CR WITH (NOLOCK)
    ON CR.[Code] = AH.[Bill-to Country_Region Code]

SET @VATRate = CASE WHEN @DocumentDate BETWEEN '2020-07-01' AND '2020-12-31' THEN 0.16 ELSE 0.19 END
SET @TotalRate = 1 + @VATRate

DECLARE @PGFaxExtension varchar(30)
      , @SEFaxExtension varchar(30)
      , @CRFaxExtension varchar(30)
      , @LTFaxExtension varchar(30)
      , @ACFaxExtension varchar(30)

SELECT @PGFaxExtension = [Fax Extension] FROM [HRS$Printer Group] WHERE [Code] = 'PEGASUS'
SELECT @SEFaxExtension = [Fax Extension] FROM [HRS$Printer Group] WHERE [Code] = 'SEPA'
SELECT @CRFaxExtension = [Fax Extension] FROM [HRS$Printer Group] WHERE [Code] = 'CORE'
SELECT @LTFaxExtension = [Fax Extension] FROM [HRS$Printer Group] WHERE [Code] = 'LAST'
SELECT @ACFaxExtension = [Fax Extension] FROM [HRS$Printer Group] WHERE [Code] = 'AUTO_CC'

;WITH _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [HRS$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [HRS$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate)
    , ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
SELECT @ExchangeRateCountry = ER.[Exchange Rate Amount]
  FROM ExchangeRate ER
 WHERE ER.[Currency Code] = @CurrencyCodeCountry

IF @ExchangeRateInvoice=0
SET @ExchangeRateInvoice = 1
IF @ExchangeRateCountry=0
SET @ExchangeRateCountry = 1


DECLARE @VAT decimal(38,20)
      , @VAT16 decimal(38,20)
      , @Amount decimal (38,20)
      , @Amount16 decimal (38,20)
	  , @Mwst decimal(38,20)
	  , @Mwst16 decimal(38,20)
	  , @Total decimal(38,20)
	  , @Total16 decimal(38,20)
	  , @Quantity decimal(38,20)
	  , @Quantity16 decimal(38,20)
	  , @UnitPrice DEC(38,20)

IF @IsPosted=1
BEGIN
;WITH SL AS
(
    SELECT SL.[Document No_]
         , SL.[VAT %]/100.0 VAT
         , SUM(SL.Amount)                   AS Amount
         , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) AS Mwst
         , SUM(SL.[Amount Including VAT])   AS Total
		 , SUM(SL.[Quantity]) [Quantity]
		 , MAX(SL.[Unit Price]) UnitPrice
      FROM [HRS$Sales Invoice Line] SL WITH (NOLOCK)
     WHERE SL.[Document No_] = @PostedInvoiceNo
  GROUP BY SL.[Document No_]
         , SL.[VAT %]
)
    SELECT @VAT = MAX(CASE WHEN VAT=0.16 THEN 0 ELSE VAT END)
         , @VAT16 = MAX(CASE WHEN VAT=0.16 THEN VAT ELSE 0 END)
         , @Amount = MAX(CASE WHEN VAT=0.16 THEN 0 ELSE Amount END)
         , @Amount16 = MAX(CASE WHEN VAT<>0.16 THEN 0 ELSE Amount END)
         , @Mwst = MAX(CASE WHEN VAT=0.16 THEN 0 ELSE Mwst END)
         , @Mwst16 = MAX(CASE WHEN VAT<>0.16 THEN 0 ELSE Mwst END)
         , @Total = MAX(CASE WHEN VAT=0.16 THEN 0 ELSE Total END)
         , @Total16 = MAX(CASE WHEN VAT<>0.16 THEN 0 ELSE Total END)
         , @Quantity = MAX(CASE WHEN VAT=0.16 THEN 0 ELSE Quantity END) 
         , @Quantity16 = MAX(CASE WHEN VAT<>0.16 THEN 0 ELSE Quantity END) 
		 , @UnitPrice = MAX(UnitPrice)

      FROM SL

END

IF @IsPosted=0
BEGIN
;WITH USL AS
(
    SELECT SL.[TAF No_] [Document No_]
         , MAX(CASE WHEN SH.[Bill-to Country_Region Code] = '33' THEN 19 ELSE 0 END)  VAT 
         , SUM(SL.Amount)                   AS Amount
         , SUM(SL.Amount * CASE WHEN SH.[Bill-to Country_Region Code] = '33' THEN @VATRate ELSE 0 END)    AS Mwst
         , SUM(SL.Amount * CASE WHEN SH.[Bill-to Country_Region Code] = '33' THEN @TotalRate ELSE 0 END)   AS Total
		 , COUNT(1) [Quantity]
		 , MAX(SL.Amount) [UnitPrice]
      FROM [HRS$TAF Line] SL WITH (NOLOCK)
	  JOIN [HRS$TAF Header] SH WITH (NOLOCK)
	    ON SH.[No_] = SL.[TAF No_]
     WHERE SL.[TAF No_] = @ReNr
  GROUP BY SL.[TAF No_]
)
SELECT @VAT = VAT, @Amount =Amount, @Mwst = Mwst, @Total = Total, @Quantity = Quantity FROM USL

-- 17.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
DECLARE @Date1 date, @Date2 date
      , @NetAmount16 DEC(38,20)
	  , @NetAmount19 DEC(38,20)
      , @Quantity19 DEC(38,20)
	  , @Amount19 DEC(38,20)
      , @VATAmount16 DEC(38,20)
	  , @VATAmount19 DEC(38,20)
	  , @VATRate16 DEC(38,20) = 0.16
	  , @VATRate19 DEC(38,20) = 0.19
	  , @GenBusPostingGroup varchar(20)

SELECT @Date1 = [VAT Change From Date]-1, @Date2 = [VAT Change To Date]
  FROM [HRS$VAT Rate Change Setup]

SELECT @ReNr=AH.[No_], @GenBusPostingGroup = CU.[Gen_ Bus_ Posting Group] FROM [HRS$TAF Header] AH WITH (NOLOCK) JOIN [HRS$Customer] CU WITH (NOLOCK) ON CU.[No_]=AH.[Bill-to Customer No_] WHERE (AH.[No_] = @ReNr)
PRINT @ReNr
SELECT @Quantity19 = SUM(ROUND(CASE
         WHEN DH.[Bill-to Country_Region Code]<>'33' THEN NULL
	     WHEN DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]>@Date1 THEN DATEDIFF(dd,DL.[Reservation Date From],@Date1)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]>@Date2 THEN 1-DATEDIFF(dd,DL.[Reservation Date To],@Date2)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN (DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]<=@Date1) OR (DL.[Reservation Date From]>=@Date2 AND DL.[Reservation Date To]>@Date2) THEN 1.0
	     WHEN (DL.[Reservation Date From]>=@Date1 AND DL.[Reservation Date To]>@Date1) AND (DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]<=@Date2) THEN 0.0
	   END
     ,10)) 
	 , @Quantity16 = SUM(ROUND((1- CASE
         WHEN DH.[Bill-to Country_Region Code]<>'33' THEN NULL
	     WHEN DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]>@Date1 THEN DATEDIFF(dd,DL.[Reservation Date From],@Date1)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]>@Date2 THEN 1-DATEDIFF(dd,DL.[Reservation Date To],@Date2)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN (DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]<=@Date1) OR (DL.[Reservation Date From]>=@Date2 AND DL.[Reservation Date To]>@Date2) THEN 1.0
	     WHEN (DL.[Reservation Date From]>=@Date1 AND DL.[Reservation Date To]>@Date1) AND (DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]<=@Date2) THEN 0.0
	   END)
     ,10)) 
	 , @NetAmount19 = SUM(ROUND(CASE
         WHEN DH.[Bill-to Country_Region Code]<>'33' THEN NULL
	     WHEN DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]>@Date1 THEN DATEDIFF(dd,DL.[Reservation Date From],@Date1)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]>@Date2 THEN 1-DATEDIFF(dd,DL.[Reservation Date To],@Date2)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN (DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]<=@Date1) OR (DL.[Reservation Date From]>=@Date2 AND DL.[Reservation Date To]>@Date2) THEN 1.0
	     WHEN (DL.[Reservation Date From]>=@Date1 AND DL.[Reservation Date To]>@Date1) AND (DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]<=@Date2) THEN 0.0
	   END
     * (DL.[Amount]),2)) 
	 , @NetAmount16 = SUM(ROUND((1- CASE
         WHEN DH.[Bill-to Country_Region Code]<>'33' THEN NULL
	     WHEN DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]>@Date1 THEN DATEDIFF(dd,DL.[Reservation Date From],@Date1)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]>@Date2 THEN 1-DATEDIFF(dd,DL.[Reservation Date To],@Date2)*1.0/DATEDIFF(dd,DL.[Reservation Date From],DL.[Reservation Date To])
	     WHEN (DL.[Reservation Date From]<@Date1 AND DL.[Reservation Date To]<=@Date1) OR (DL.[Reservation Date From]>=@Date2 AND DL.[Reservation Date To]>@Date2) THEN 1.0
	     WHEN (DL.[Reservation Date From]>=@Date1 AND DL.[Reservation Date To]>@Date1) AND (DL.[Reservation Date From]<@Date2 AND DL.[Reservation Date To]<=@Date2) THEN 0.0
	   END)
     * (DL.[Amount]),2))
     , @UnitPrice = MAX(DL.Amount)	 
  FROM [HRS$TAF Line] DL WITH (NOLOCK)
  JOIN [HRS$TAF Header] DH WITH (NOLOCK)
    ON DH.[No_] = DL.[TAF No_]
  JOIN [HRS$Customer] CU WITH (NOLOCK)
    ON CU.[No_] = DH.[Bill-to Customer No_]
 WHERE DH.[No_]=@ReNr 

SET @NetAmount16 = @UnitPrice * @Quantity16
SET @NetAmount19 = @UnitPrice * @Quantity19

SET @Mwst16=0.0
SET @Mwst=0.0
SET @NetAmount16=ROUND(@NetAmount16,2)
SET @NetAmount19=ROUND(@NetAmount19,2)
IF @GenBusPostingGroup='INLAND' 
BEGIN
  SET @Mwst16 = ROUND(@NetAmount16 * @VATRate16,2)
  SET @Mwst = ROUND(@NetAmount19 * @VATRate19,2)
END

SET @Total16 = ROUND(@NetAmount16 + @Mwst16,2)
SET @Total = ROUND(@NetAmount19 + @Mwst,2)
IF (@NetAmount19 IS NULL) AND (@NetAmount16 IS NULL)
BEGIN
  SET @VATRate16 = NULL
  SET @VATRate19 = NULL
END

    SELECT @VAT = @VATRate19
         , @VAT16 = @VATRate16
         , @Quantity = @Quantity19 
         , @Quantity16 = @Quantity16
         , @Amount = @NetAmount19
         , @Amount16 = @NetAmount16
		 PRINT @Quantity16
		 PRINT @Quantity


 -- 17.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS004

END

IF @IsPosted=1
BEGIN
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
		FROM [HRS$Bank Regulation] BR WITH (NOLOCK)
        JOIN [Bank] BK WITH (NOLOCK)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
) 
    SELECT SH.[No_] [No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
		 , CASE WHEN P1.[Content] IS NULL   THEN   TH.[Bill-to Name]         ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN   TH.[Bill-to Name 2]       ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN   TH.[Bill-to Address]      ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN   TH.[Bill-to Address 2]    ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN   TH.[Bill-to City]         ELSE P5.[Content] END [Sell-to City]
         , TH.[Bill-to Post Code]                          [Sell-to Post Code]
		 , CASE WHEN TH.[Bill-to Country_Region Code] IN ('0', '') THEN '33' ELSE TH.[Bill-to Country_Region Code] END [Sell-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , CASE 
             WHEN CU.[Salesperson Code] IN ('AFR03','FBE02')THEN
               CASE
                 WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND CU.[Chain] = '13' THEN SP.[Fax Extension]
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(@CRFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(@SEFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(@ACFaxExtension,SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension])
                 ELSE SP.[Fax Extension]
               END
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(@PGFaxExtension,'')<>'' THEN @CRFaxExtension
             WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(@CRFaxExtension,SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(@SEFaxExtension,SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(@ACFaxExtension,SP.[Fax Extension])
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END [Fax Extension] 
         , SP.[Phone Extension]             AS [Phone Extension]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                     ELSE P6.[Content] END Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '' THEN 'EUR' ELSE SH.[Currency Code] END [Currency Code]
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END [Currency Factor]
         , @VAT [VAT]
         , @Amount [Amount]
         , @Mwst [Mwst]
         , @Total [Total]
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN SH.[Language Code]='' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END SEPA
         , (COALESCE(B1.[Description],''))                        [Bank_1_Descrption]
         , (COALESCE(B1.[Account],''))                            [Bank_1_Account]
         , (COALESCE(B1.[BLZ],''))                                [Bank_1_BLZ]
         , (COALESCE(B1.[Swift],''))                              [Bank_1_Swift]
         , (COALESCE(B1.[IBAN],''))                               [Bank_1_IBAN]
         , (COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),''))     [Bank_1_BankTxt]
         , (COALESCE(B2.[Description],''))                        [Bank_2_Descrption]
         , (COALESCE(B2.[Account],''))                            [Bank_2_Account]
         , (COALESCE(B2.[BLZ],''))                                [Bank_2_BLZ]
         , (COALESCE(B2.[Swift],''))                              [Bank_2_Swift]
         , (COALESCE(B2.[IBAN],''))                               [Bank_2_IBAN]
         , (COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),''))     [Bank_2_BankTxt]
         , (COALESCE(B3.[Description],'') )                       [Bank_3_Descrption]
         , (COALESCE(B3.[Account],''))                            [Bank_3_Account]
         , (COALESCE(B3.[BLZ],''))                                [Bank_3_BLZ]
         , (COALESCE(B3.[Swift],''))                              [Bank_3_Swift]
         , (COALESCE(B3.[IBAN],''))                               [Bank_3_IBAN]
         , (COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),''))     [Bank_3_BankTxt]
         , @Quantity [Quantity]
         , (CU.[VAT Registration No_])                            [VAT Registration No_]
		 , SH.[Central Billing Fee Type]                               [Central Billing Fee Type]
		 , SH.[Order Type]											   [Order Type]
		 , CASE 
             WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND CU.[Chain] = '13' THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN CU.[Payment Method Code] = 'CORE'         THEN COALESCE(@CRFaxExtension,SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'SEPA'         THEN COALESCE(@SEFaxExtension,SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'CC_AUTO'      THEN COALESCE(@ACFaxExtension,SP.[Fax Extension]) + '@hrs.de'   
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension]) + '@hrs.de'
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(@PGFaxExtension,'')<>'' 
              THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN ',29,57,92,30,67,' LIKE '%,'+SH.[Sell-to Country_Region Code] +',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(@CRFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(@SEFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(@ACFaxExtension,SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'') 
               END 
             + '@hrs.de'
           END [EMail]
		 , CO.[Invoicing in local currency] [Invoicing in local currency] 
		 , CO.[Currency Code] [Currency Code Country]
		 , @ExchangeRateInvoice [Exchange Rate Invoice]
		 , @ExchangeRateCountry [Exchange Rate Country]
		 , @ExchangeRateCountry / @ExchangeRateInvoice [Exchange Rate]
		 , ROUND(@Amount,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Amount Country]
		 , ROUND(@Mwst,2) * @ExchangeRateCountry / @ExchangeRateInvoice  [Mwst Country]
		 , ROUND(@Total,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Total Country]
		 , SH.[VAT Bus_ Posting Group]
         , @VAT16 [VAT 2]
         , @Quantity16 [Quantity 2]
		 , ROUND(@Amount16,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Amount Country 2]
		 , ROUND(@Mwst16,2) * @ExchangeRateCountry / @ExchangeRateInvoice  [Mwst Country 2]
		 , ROUND(@Total16,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Total Country 2]
         , @Amount16 [Amount 2]
         , @Mwst16 [Mwst 2]
         , @Total16 [Total 2]
		 , @UnitPrice [UnitPrice]
      FROM [HRS$TAF Invoice Header] TH WITH (NOLOCK)
      JOIN [HRS$Sales Invoice Header] SH WITH (NOLOCK)
        ON TH.[Posted Sales Invoice No_] = SH.[No_]
      JOIN [HRS$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = TH.[Bill-to Country_Region Code]  
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = TH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = TH.[Bill-to Country_Region Code]
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
      JOIN [HRS$Country_Region] AS CO WITH (READUNCOMMITTED) 
		ON CASE WHEN TH.[Bill-to Country_Region Code] IN ('0', '') THEN '33' ELSE TH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
 LEFT JOIN [HRS$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = CU.[Salesperson Code]
      JOIN [HRS$Customer]                          JO WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code
     WHERE TH.[No_]=@ReNr
END

IF @IsPosted=0
BEGIN
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
		FROM [HRS$Bank Regulation] BR WITH (NOLOCK)
        JOIN [Bank] BK WITH (NOLOCK)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
) 
    SELECT SH.[No_] [No_]
         , SH.[Bill-to Customer No_]  [Sell-to Customer No_]
         , SH.[Bill-to Contact]  [Sell-to Contact]
		 , CASE WHEN P1.[Content] IS NULL   THEN   SH.[Bill-to Name]         ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN   SH.[Bill-to Name 2]       ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN   SH.[Bill-to Address]      ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN   SH.[Bill-to Address 2]    ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN   SH.[Bill-to City]         ELSE P5.[Content] END [Sell-to City]
         , SH.[Bill-to Post Code]                          [Sell-to Post Code]
		 , CASE WHEN SH.[Bill-to Country_Region Code] IN ('0', '') THEN '33' ELSE SH.[Bill-to Country_Region Code] END [Sell-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , CU.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , CU.[Language Code]               AS [ISO_Code]
         , CASE 
             WHEN CU.[Salesperson Code] IN ('AFR03','FBE02')THEN
               CASE
                 WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND CU.[Chain] = '13' THEN SP.[Fax Extension]
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(@CRFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(@SEFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(@ACFaxExtension,SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension])
                 ELSE SP.[Fax Extension]
               END
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(@PGFaxExtension,'')<>'' THEN @CRFaxExtension
             WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(@CRFaxExtension,SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(@SEFaxExtension,SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(@ACFaxExtension,SP.[Fax Extension])
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END [Fax Extension] 
         , SP.[Phone Extension]             AS [Phone Extension]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                     ELSE P6.[Content] END Name
         , SH.[Document Date]
         , '' [Posting Description]       
         , CASE WHEN SH.[Currency Code] = '' THEN 'EUR' ELSE SH.[Currency Code] END [Currency Code]
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END [Currency Factor]
         , @VAT [VAT]
         , @Amount [Amount]
         , @Mwst [Mwst]
         , @Total [Total]
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN CU.[Language Code]='' THEN CO.[Primary Language Code] ELSE CU.[Language Code] END [Language Code]
         , CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END SEPA
         , (COALESCE(B1.[Description],''))                        [Bank_1_Descrption]
         , (COALESCE(B1.[Account],''))                            [Bank_1_Account]
         , (COALESCE(B1.[BLZ],''))                                [Bank_1_BLZ]
         , (COALESCE(B1.[Swift],''))                              [Bank_1_Swift]
         , (COALESCE(B1.[IBAN],''))                               [Bank_1_IBAN]
         , (COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),''))     [Bank_1_BankTxt]
         , (COALESCE(B2.[Description],''))                        [Bank_2_Descrption]
         , (COALESCE(B2.[Account],''))                            [Bank_2_Account]
         , (COALESCE(B2.[BLZ],''))                                [Bank_2_BLZ]
         , (COALESCE(B2.[Swift],''))                              [Bank_2_Swift]
         , (COALESCE(B2.[IBAN],''))                               [Bank_2_IBAN]
         , (COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),''))     [Bank_2_BankTxt]
         , (COALESCE(B3.[Description],'') )                       [Bank_3_Descrption]
         , (COALESCE(B3.[Account],''))                            [Bank_3_Account]
         , (COALESCE(B3.[BLZ],''))                                [Bank_3_BLZ]
         , (COALESCE(B3.[Swift],''))                              [Bank_3_Swift]
         , (COALESCE(B3.[IBAN],''))                               [Bank_3_IBAN]
         , (COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),''))     [Bank_3_BankTxt]
         , @Quantity [Quantity]
         , (CU.[VAT Registration No_])                            [VAT Registration No_]
		 , 0                               [Central Billing Fee Type]
		 , 0											   [Order Type]
		 , CASE 
             WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND CU.[Chain] = '13' THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN CU.[Payment Method Code] = 'CORE'         THEN COALESCE(@CRFaxExtension,SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'SEPA'         THEN COALESCE(@SEFaxExtension,SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'CC_AUTO'      THEN COALESCE(@ACFaxExtension,SP.[Fax Extension]) + '@hrs.de'   
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension]) + '@hrs.de'
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(@PGFaxExtension,'')<>'' 
              THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN ',29,57,92,30,67,' LIKE '%,'+SH.[Bill-to Country_Region Code] +',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(@CRFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(@SEFaxExtension,SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(@ACFaxExtension,SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(@LTFaxExtension,SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'') 
               END 
             + '@hrs.de'
           END [EMail]
		 , CO.[Invoicing in local currency] [Invoicing in local currency] 
		 , CO.[Currency Code] [Currency Code Country]
		 , @ExchangeRateInvoice [Exchange Rate Invoice]
		 , @ExchangeRateCountry [Exchange Rate Country]
		 , @ExchangeRateCountry / @ExchangeRateInvoice [Exchange Rate]
		 , ROUND(@Amount,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Amount Country]
		 , ROUND(@Mwst,2) * @ExchangeRateCountry / @ExchangeRateInvoice  [Mwst Country]
		 , ROUND(@Total,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Total Country]
		 , CU.[VAT Bus_ Posting Group]
         , @VAT16 [VAT 2]
         , @Quantity16 [Quantity 2]
		 , ROUND(@NetAmount16,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Amount Country 2]
		 , ROUND(@Mwst16,2) * @ExchangeRateCountry / @ExchangeRateInvoice  [Mwst Country 2]
		 , ROUND(@Total16,2) * @ExchangeRateCountry / @ExchangeRateInvoice [Total Country 2]
         , @NetAmount16 [Amount 2]
         , @Mwst16 [Mwst 2]
         , @Total16 [Total 2]
		 , @UnitPrice [UnitPrice]
      FROM [HRS$TAF Header] SH WITH (NOLOCK)
      JOIN [HRS$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Bill-to Customer No_] = CU.[No_]
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]  
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
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
      JOIN [HRS$Country_Region] AS CO WITH (READUNCOMMITTED) 
		ON CASE WHEN SH.[Bill-to Country_Region Code] IN ('0', '') THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
 LEFT JOIN [HRS$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = CU.[Salesperson Code]
      JOIN [HRS$Customer]                          JO WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code
     WHERE SH.[No_]=@ReNr
END
END
GO
