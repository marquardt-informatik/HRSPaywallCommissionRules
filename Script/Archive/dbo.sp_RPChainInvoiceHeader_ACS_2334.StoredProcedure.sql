USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPChainInvoiceHeader_ACS_2334]    Script Date: 10.04.2024 14:31:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 07.08.2014
-- Description:	Ketten-Rechnung
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 07.08.11 HRS001    90207  TM     Erstellt
-- 10.05.19 HRS002 INC0017304 DJU   Filter deleted lines
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '1417_2014-07-31'
EXEC [dbo].[sp_RPChainInvoiceHeader] @ReNr

*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPChainInvoiceHeader_ACS_2334] 
    @ReNr varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ChainNo     varchar(20)
	      , @PostingDate date
	SET @ChainNo     = LEFT(@ReNr,CHARINDEX('_',@ReNr)-1)
	SET @PostingDate = CAST(RIGHT(@ReNr,LEN(@ReNr)-CHARINDEX('_',@ReNr)) AS date)
	
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
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
       )
    , Sums         AS
    (
    SELECT @ChainNo [Chain Code]
         , SUM(
             DL.[Commission Amount (LCY)] 
           * DL.[Number of Nights]
           ) [Commission Amount]
      FROM [HRS$Agency Display Line]   DL WITH (NOLOCK)
      JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
        ON DH.[Case No_] = DL.[Display Case No_]
      JOIN [Chain]                     CH WITH (NOLOCK)
        ON CH.[Code]            = DH.[Chain Code]
     WHERE DH.[Posting Date]    = @PostingDate
       AND DH.[Correction from] = ''
       AND DH.[Case No_]     LIKE 'V%'
       AND DH.[Chain Code]      = @ChainNo
       AND ('|'+CH.[Country Filter]+'|' LIKE '%|'+DH.[Bill-to Country_Region Code]+'|%' OR CH.[Country Filter]='')
	   -- HRS002 >>
	   AND DL.[Action] <> 3
	   -- HRS002 <<
    )
    , _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [HRS$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [HRS$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate)
    , ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
	SELECT CH.[Bill-to Customer No_]
	     , @PostingDate                AS [Posting Date]
	     , CU.[Currency Code]
	     , ER.[Exchange Rate Amount]   AS [Currency Factor]
	     , CASE WHEN CU.[Language Code]=''  THEN CR.[Primary Language Code] ELSE CU.[Language Code] END AS [Language Code]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Name]                  ELSE P1.[Content]       END AS [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Name 2]                ELSE P2.[Content]       END AS [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Address]               ELSE P3.[Content]       END AS [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Address 2]             ELSE P4.[Content]       END AS [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[City]                  ELSE P5.[Content]       END AS [Sell-to City]
         , CU.[Post Code]                                                                               AS [Sell-to Post Code]
         , CU.[Country_Region Code]                                                                     AS [Sell-to Country Code]
         , CU.[Contact]                                                                                 AS [Sell-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CASE WHEN P1.[Content] IS NULL   THEN CR.Name                    ELSE P6.[Content]       END AS [Name]
         , CR.[EU Country_Region Code]                                                                  AS [EU Ländercode]
         , CASE 
             WHEN CU.[Contract Status] IN('10','11') 
              --AND AH.MuseID<>'HRS' 
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN SP.[Fax Extension]
             WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CE.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END                                                                                          AS [Durchwahl Fax]
         , RTRIM(BA.[Bank Branch No_])                                                                  AS [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])                                                                 AS [Bank Account No_]
         , RTRIM(BA.[Name])                                                                             AS [Bank Name]
         , RTRIM(BA.[IBAN])                                                                             AS [IBAN]
         , RTRIM(BA.[SWIFT Code])                                                                       AS [BIC]
         , LA.[ISO Code]                                                                                AS [ISO_Code]
         , [Commission Amount]                                                                          * ER.[Exchange Rate Amount] AS [Amount]
         , CASE WHEN (CU.[VAT Bus_ Posting Group] = 'INLAND') AND CR.[Code] = '33' THEN 19   ELSE 0 END AS [VAT]
         , CASE WHEN (CU.[VAT Bus_ Posting Group] = 'INLAND') AND CR.[Code] = '33' THEN 0.19 ELSE 0 END 
           * [Commission Amount] * ER.[Exchange Rate Amount]                                            AS [Mwst]
         , CASE WHEN (CU.[VAT Bus_ Posting Group] = 'INLAND') AND CR.[Code] = '33' THEN 1.19 ELSE 1 END 
           * [Commission Amount] * ER.[Exchange Rate Amount]                                            AS [Total]
         , CAST(CU.[Contract Status] AS int)                                                            AS [Vertrag Status]
         , CR.[Continent]                                                                               AS [Continent]
         , CASE WHEN CR.[Bank Country Code]<>'' THEN 1 ELSE 0 END                                       AS [SEPA]
         , CASE 
             WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
               ''
             ELSE
               CASE 
                 WHEN ',29,57,92,' LIKE '%,'+CR.[Code]+',%' THEN
                   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441'
                 WHEN ',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+CR.[Code]+',%' THEN
                   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447'
                 ELSE
                   ''
               END    
           END [Special Fax]
         , CASE 
             WHEN CU.[Contract Status] IN('10','11') 
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' 
              THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN ',29,57,92,10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+CR.[Code]+',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'') 
               END 
             + '@hrs.de'
           END [Special E-Mail]
         , CU.[Contract Status]
         , COALESCE(B1.[Description],'')  [Bank_1_Descrption]
         , COALESCE(B1.[Account],'')      [Bank_1_Account]
         , COALESCE(B1.[BLZ],'')          [Bank_1_BLZ]
         , COALESCE(B1.[Swift],'')        [Bank_1_Swift]
         , COALESCE(B1.[IBAN],'')         [Bank_1_IBAN]
         , COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),'')          [Bank_1_BankTxt]
         , COALESCE(B2.[Description],'')  [Bank_2_Descrption]
         , COALESCE(B2.[Account],'')      [Bank_2_Account]
         , COALESCE(B2.[BLZ],'')          [Bank_2_BLZ]
         , COALESCE(B2.[Swift],'')        [Bank_2_Swift]
         , COALESCE(B2.[IBAN],'')         [Bank_2_IBAN]
         , COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),'')          [Bank_2_BankTxt]
         , COALESCE(B3.[Description],'')  [Bank_3_Descrption]
         , COALESCE(B3.[Account],'')      [Bank_3_Account]
         , COALESCE(B3.[BLZ],'')          [Bank_3_BLZ]
         , COALESCE(B3.[Swift],'')        [Bank_3_Swift]
         , COALESCE(B3.[IBAN],'')         [Bank_3_IBAN]
         , COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),'')          [Bank_3_BankTxt]
	  FROM [Chain]                            CH WITH (NOLOCK)
	  JOIN [Sums]                             SU
	    ON SU.[Chain Code]                  = CH.[Code]
	  JOIN [HRS$Customer]                     CU WITH (NOLOCK)
	    ON CU.[No_]                         = CH.[Bill-to Customer No_]
	  JOIN ExchangeRate ER
	    ON ER.[Currency Code]               = CU.[Currency Code]
      JOIN [HRS$Country_Region]               CR WITH (NOLOCK)
        ON CU.[Country_Region Code]         = CR.Code
      JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON CU.[Language Code]               = LA.Code 
      JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                PG WITH (READUNCOMMITTED)
        ON PG.[Code]                        = 'PEGASUS'
 LEFT JOIN [HRS$Printer Group]                SE WITH (READUNCOMMITTED)
        ON SE.[Code]                        = 'SEPA'
 LEFT JOIN [HRS$Printer Group]                CE WITH (READUNCOMMITTED)
        ON CE.[Code]                        = 'CORE'
 LEFT JOIN [HRS$Printer Group]                LT WITH (READUNCOMMITTED)
        ON LT.[Code]                        = 'LAST'
 LEFT JOIN [HRS$Printer Group]                AC WITH (READUNCOMMITTED)
        ON AC.[Code]                        = 'AUTO_CC'
 LEFT JOIN [HRS$Responsibility Center]        RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center]       = RC.Code
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON CU.[No_]                         = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = CH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = CH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = CH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = CH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = CH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = CH.[Bill-to Customer No_]
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = CR.[Code]       
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = CR.[Code]       
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = CR.[Code]   
	 WHERE CH.[Code]=@ChainNo 
	
END
GO
