USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingInvoiceHeader_MEET_Invoice]    Script Date: 10.04.2024 14:31:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 28.11.2014
-- Description:	
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 05.10.23 HRS001  ACS-4516 TMA    Copy of sp_RPCentralBillingInvoiceHeader
-- 
-- 
-- 
/*
DECLARE @ReNr varchar(36)
 SELECT @ReNr = '8B8D311D-BC2A-4C9B-BE54-281E177B844A'
EXEC [dbo].[sp_RPCentralBillingInvoiceHeader_MEET_Invoice] @ReNr
 SELECT @ReNr = '78638548'
EXEC [dbo].[sp_RPCentralBillingInvoiceHeader_MEET_Invoice] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingInvoiceHeader_MEET_Invoice] 
    @ReNr varchar(36)
AS
BEGIN
  DECLARE @ProcessNo int
  DECLARE @IP TABLE ([Process No_] int , [Vendor Posting No_] varchar(20), [Hotel No_] varchar(20), [Currency Code] varchar(10), [Vendor Posting Date] date, [Invoice GUID] varchar(36), [Vendor No_] int, [Customer No_] int, [Arrival Date] date, [Departure Date] date, [Cust_ Ledger Entry No_] int, [Invoice No_] varchar(100), [Cust_ Posting Date] date PRIMARY KEY ([Process No_], [Invoice GUID]))
  DECLARE @GuestName1 varchar(max) = '', @GuestName2 varchar(max) = '', @GuestName varchar(max) = ''

  SELECT @ProcessNo = CASE WHEN ISNUMERIC(@ReNr)=0 THEN 0 ELSE CAST(@ReNr AS INT) END
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    ;WITH IP AS
    (
      SELECT IP.[Process No_]
           , IP.[Vendor Posting No_]
           , IP.[Hotel No_]
           , IP.[Currency Code]
           , IP.[Vendor Posting Date]
		   , IP.[Invoice GUID]
           , CASE 
               WHEN CR.[Customer Template Code] = 1 THEN VA.[Vendor No_ Domestic]
               WHEN CR.[EU affiliation]         = 1 THEN VA.[Vendor No_ EU]
               WHEN CR.[EU affiliation]         = 1 THEN VA.[Vendor No_ Other]
             END [Vendor No_]
           , VA.[Customer No_]
           , IP.[Arrival Date]
           , IP.[Departure Date]
           , IP.[Cust_ Ledger Entry No_]
           , SUBSTRING(LE.[Description], CHARINDEX(' PD',LE.[Description])+1,100) [Invoice No_]
           , IP.[Cust_ Posting Date]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
          ON VA.[Company No_] = IP.[Company No_]
        JOIN [HRS$Contact]                              CO WITH (NOLOCK)
          ON CO.[No_] = IP.[Hotel No_]
        JOIN [HRS$Country_Region]                       CR WITH (NOLOCK)
          ON CR.[Code] = CO.[Country_Region Code]
   LEFT JOIN [HRS Payment$Cust_ Ledger Entry]                   LE WITH (NOLOCK)
          ON LE.[Entry No_] = IP.[Cust_ Ledger Entry No_]
       WHERE NOT EXISTS(SELECT * FROM [HRS Payment$Paym_ Solution Invoice] WHERE [Invoice GUID] = @ReNr)

       UNION
       
      SELECT IP.[Process No_]
           , IP.[Vendor Posting No_]
           , IP.[Hotel No_]
           , IP.[Currency Code]
           , IP.[Vendor Posting Date]
		   , IP.[Invoice GUID]
           , CASE 
               WHEN CR.[Customer Template Code] = 1 THEN VA.[Vendor No_ Domestic]
               WHEN CR.[EU affiliation]         = 1 THEN VA.[Vendor No_ EU]
               WHEN CR.[EU affiliation]         = 1 THEN VA.[Vendor No_ Other]
             END [Vendor No_]
           , VA.[Customer No_]
           , IP.[Arrival Date]
           , IP.[Departure Date]
           , IP.[Cust_ Ledger Entry No_]
           , SUBSTRING(LE.[Description], CHARINDEX(' PD',LE.[Description])+1,100) [Invoice No_]
           , IP.[Cust_ Posting Date]
        FROM [HRS Payment$Paym_ Solution Invoice]       IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
          ON VA.[Company No_] = IP.[Company No_]
        JOIN [HRS$Contact]                              CO WITH (NOLOCK)
          ON CO.[No_] = IP.[Hotel No_]
        JOIN [HRS$Country_Region]                       CR WITH (NOLOCK)
          ON CR.[Code] = CO.[Country_Region Code]
        JOIN [HRS Payment$Cust_ Ledger Entry]                   LE WITH (NOLOCK)
          ON LE.[Entry No_] = IP.[Cust_ Ledger Entry No_]
    )
	INSERT INTO @IP
	SELECT * 
	  FROM IP
     WHERE IP.[Invoice GUID] = @ReNr

    ;WITH BU AS
	(
	  SELECT DISTINCT BP.BP_KEY, COALESCE(BU.B_GAST1,'') B_GAST
	    FROM @IP IP
        JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA      BP WITH (NOLOCK)
          ON BP.BP_KEY                        = IP.[Process No_]
        JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
          ON BU.B_KEY                         = BP.B_KEY
       UNION 
	  SELECT DISTINCT BP.BP_KEY, COALESCE(BU.B_GAST2,'') B_GAST
	    FROM @IP IP
        JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA      BP WITH (NOLOCK)
          ON BP.BP_KEY                        = IP.[Process No_]
        JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
          ON BU.B_KEY                         = BP.B_KEY
	)
	SELECT @GuestName 
	     = CASE 
		     WHEN @GuestName             ='' THEN COALESCE(BU.B_GAST,'')
			 WHEN COALESCE(BU.B_GAST,'') ='' THEN @GuestName
			 ELSE @GuestName + ';' + COALESCE(BU.B_GAST,'')
           END
	  FROM BU

	;WITH BP AS (SELECT BP_KEY,MAX(B_KEY) B_KEY FROm HRSDB.BKG_PROCESS_LIST_ALL_DA WITH (NOLOCK) GROUP BY BP_KEY)
    , BANK AS
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
    SELECT IP.[Customer No_]
         , IP.[Vendor Posting Date]            [Posting Date]
         , IP.[Process No_]
         , IP.[Vendor Posting No_]             [Posting No_]
         , IP.[Currency Code]
         , CASE WHEN H1.[Content] IS NULL   THEN HT.[Name]          ELSE H1.[Content]       END [Hotel Name]
         , CASE WHEN H1.[Content] IS NULL   THEN HT.[City]          ELSE H5.[Content]       END [Hotel City]
         , CASE WHEN H1.[Content] IS NULL   THEN HR.Name            ELSE H6.[Content]       END [Hotel Country]
         , CASE WHEN CU.[Language Code]=''  THEN COALESCE(CR.[Primary Language Code],'1') ELSE CU.[Language Code] END [Language Code]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Name]          ELSE P1.[Content]       END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Name 2]        ELSE P2.[Content]       END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Address]       ELSE P3.[Content]       END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[Address 2]     ELSE P4.[Content]       END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN CU.[City]          ELSE P5.[Content]       END [Sell-to City]
         , CU.[Post Code]                   AS [Sell-to Post Code]
         , CU.[Country_Region Code] AS [Sell-to Country Code]
         , CU.[Contact]             AS [Sell-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CASE WHEN P1.[Content] IS NULL   THEN CR.Name                    ELSE P6.[Content]       END Name
         , CR.[EU Country_Region Code][EU Ländercode]
         , SP.[Fax Extension]
         , SP.[Phone Extension]
         , RTRIM(BA.[Bank Branch No_])                          [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])                         [Bank Account No_]
         , RTRIM(BA.[Name])                                     [Bank Name]
         , RTRIM(BA.[IBAN])                                     [IBAN]
         , RTRIM(BA.[SWIFT Code])                               [BIC]
         , LA.[ISO Code]                                        [ISO_Code]
         , COALESCE(B1.[Description],'')                        [Bank_1_Descrption]
         , COALESCE(B1.[Account],'')                            [Bank_1_Account]
         , COALESCE(B1.[BLZ],'')                                [Bank_1_BLZ]
         , COALESCE(B1.[Swift],'')                              [Bank_1_Swift]
         , COALESCE(B1.[IBAN],'')                               [Bank_1_IBAN]
         , COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),'')     [Bank_1_BankTxt]
         , COALESCE(B2.[Description],'')                        [Bank_2_Descrption]
         , COALESCE(B2.[Account],'')                            [Bank_2_Account]
         , COALESCE(B2.[BLZ],'')                                [Bank_2_BLZ]
         , COALESCE(B2.[Swift],'')                              [Bank_2_Swift]
         , COALESCE(B2.[IBAN],'')                               [Bank_2_IBAN]
         , COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),'')     [Bank_2_BankTxt]
         , COALESCE(B3.[Description],'')                        [Bank_3_Descrption]
         , COALESCE(B3.[Account],'')                            [Bank_3_Account]
         , COALESCE(B3.[BLZ],'')                                [Bank_3_BLZ]
         , COALESCE(B3.[Swift],'')                              [Bank_3_Swift]
         , COALESCE(B3.[IBAN],'')                               [Bank_3_IBAN]
         , COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),'')     [Bank_3_BankTxt]
         , IP.[Arrival Date]
         , IP.[Departure Date]
         , @GuestName                                           [Guest 1]
         , ''                                                   [Guest 2]
         , IP.[Invoice No_]
         , IP.[Cust_ Ledger Entry No_]
         , HR.[Code] [Hotel Country Code]
         , IP.[Cust_ Posting Date]
         , CASE WHEN LEN(CC.UATP_CARD_NUMBER)>'' THEN SUBSTRING(CC.UATP_CARD_NUMBER,1,4) + ' xxxx xxxx ' + RIGHT(CC.UATP_CARD_NUMBER,4) ELSE '' END [UATP Card Number]
         , CC.UATP_CARD_VALID_UNTIL                             [UATP Card Valid Until]
         , CC.UATP_CARD_HOLDER                                  [UATP Card Holder]
		 , COALESCE(VI.[VAT Identifier], VI2.[VAT Identifier] ) [VAT Identifier]
      FROM @IP IP
 LEFT JOIN [HRS Payment$Customer]             CU WITH (READUNCOMMITTED)
        ON IP.[Customer No_]                = CU.[No_] 
 LEFT JOIN [HRS$Country_Region]               CR WITH (READUNCOMMITTED)
        ON CU.[Country_Region Code]         = CR.Code
 LEFT JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON CU.[Language Code]               = LA.Code 
 LEFT JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Contact]                      HT WITH (READUNCOMMITTED)
        ON IP.[Hotel No_]                   = HT.[No_] 
 LEFT JOIN [HRS Payment$VAT Identifier Assignement] VA WITH (NOLOCK)
        ON VA.[Customer Country_Region Code]      = CU.[Country_Region Code]
       AND VA.[Hotel Country_Region Code]         = HT.[Country_Region Code]
 LEFT JOIN [HRS Payment$VAT Identifier]             VI WITH (NOLOCK)
        ON VI.[VAT Identifier Code]               = VA.[VAT Identifier Code]
 LEFT JOIN [HRS$Country_Region]               HR WITH (READUNCOMMITTED)
        ON HT.[Country_Region Code]         = HR.Code
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON IP.[Customer No_]                = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
 LEFT JOIN [ExtendedProperties]               H1 WITH (NOLOCK)
        ON H1.[TableID]                     = 18
       AND H1.[FieldID]                     = 2
       AND H1.[KeyField1Value]              = HT.[No_]
 LEFT JOIN [ExtendedProperties]               H5 WITH (NOLOCK)
        ON H5.[TableID]                     = 18
       AND H5.[FieldID]                     = 7
       AND H5.[KeyField1Value]              = HT.[No_]
 LEFT JOIN [ExtendedProperties]               H6 WITH (NOLOCK)
        ON H6.[TableID]                     = 18
       AND H6.[FieldID]                     = 50012
       AND H6.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = IP.[Customer No_]
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = CU.[Country_Region Code]    
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = CU.[Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = CU.[Country_Region Code]
 LEFT JOIN BP 
        ON BP.BP_KEY                        = IP.[Process No_]
 LEFT JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
 LEFT JOIN HRSDB.BKG_CI_DATA_DA               CI WITH (NOLOCK)
        ON CI.B_KEY                         = BU.B_KEY
 LEFT JOIN HRSDB.CUS_CI_PAYMENT_CONFIGURATION CC WITH (NOLOCK)
        ON CC.ID_VALUE                      = CI.PAYMENT_CONFIGURATION_ID
 LEFT JOIN [HRS Payment$VAT Identifier]       VI2 WITH (NOLOCK)
        ON VI2.[VAT Identifier Code]        = 'ROW' 
END
GO
