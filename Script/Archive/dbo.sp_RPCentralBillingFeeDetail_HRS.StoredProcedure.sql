USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeDetail_HRS]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 01.05.2015
-- Description:	Attachment of Collective Central Billing Invoice
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 01.05.15 HRS001    -----  TM     Created
-- 09.11.17 HRS002   ACS-80  SAL    Consolidate Guestnames, Serveral new fields added (DBI, Address, Post Code ...) 
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'PD00219162'
EXEC [dbo].[sp_RPCentralBillingFeeDetail] @ReNr
*/
-- ============================================= 52092780

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeDetail_HRS]
    @ReNr varchar(25)
AS
BEGIN
    ;WITH BU AS
    (
      SELECT BU.BP_KEY [Process No_]
	       ---09.11.17 SAL--- HRS002 >>
           --, MAX(BU.B_GAST1) [Guest]
		   	 , LEFT((SELECT DISTINCT B_GAST1 + '; ' + (CASE WHEN B_GAST2 IS NOT NULL then B_GAST2 + '; ' else '' end) AS 'data()' FROM [DynNavHRS].[HRSDB].[BUCHUNG] WHERE BP_KEY = BU.BP_KEY FOR XML PATH('')),
	       LEN((SELECT DISTINCT B_GAST1 + '; ' + (CASE WHEN B_GAST2 IS NOT NULL then B_GAST2 + '; ' else '' end) AS 'data()' FROM [DynNavHRS].[HRSDB].[BUCHUNG] WHERE BP_KEY = BU.BP_KEY FOR XML PATH(''))) - 1) [Guestnames]
           ---09.11.17 SAL--- HRS002 << 
		   , MAX(BU.K_KEY) [Company No_]
           , MAX(BU.H_KEY) [Hotel No_]
           , MIN(BU.B_AN_DATUM) [Arrival Date]
           , MAX(BU.B_AB_DATUM) [Departure Date]
		   , MAX(BU.B_DATUM) [Reservation Date]
		   , count(distinct BU.B_GAST1) + count(distinct BU.B_GAST2) [Number of Travelers]
           , MAX(COALESCE(D1.BCDT_VALUE,'')) DBI_PK
           , MAX(COALESCE(D2.BCDT_VALUE,'')) DBI_KS
		   ---09.11.17 SAL--- HRS002 >>
		   , MAX(COALESCE(D3.BCDT_VALUE,''))  DBI_AK
		   , MAX(COALESCE(D4.BCDT_VALUE,''))  DBI_RZ
		   , MAX(COALESCE(D5.BCDT_VALUE,''))  DBI_DS
		   , MAX(COALESCE(D6.BCDT_VALUE,''))  DBI_AU
		   , MAX(COALESCE(D7.BCDT_VALUE,''))  DBI_AE
		   , MAX(COALESCE(D8.BCDT_VALUE,''))  DBI_PR
		   , MAX(COALESCE(D9.BCDT_VALUE,''))  DBI_BD
		   , MAX(COALESCE(D10.BCDT_VALUE,'')) DBI_IK
		   ---09.11.17 SAL--- HRS002 << 
        FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D1 WITH (NOLOCK)
          ON D1.B_KEY = BU.B_KEY
         ---09.11.17 SAL--- HRS002 >>
		 --AND D1.BP_GROUP_ID IN (7144,6162)
		 AND D1.BP_GROUP_ID IN (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_PK' GROUP BY [ATTRIBUTE_NUMBER])	  
         ---09.11.17 SAL--- HRS002 << 
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D2 WITH (NOLOCK)
          ON D2.B_KEY = BU.B_KEY
		  ---09.11.17 SAL--- HRS002 >>
          --AND D2.BP_GROUP_ID IN (7182,6164)
		 AND D2.BP_GROUP_ID IN (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_KS' GROUP BY [ATTRIBUTE_NUMBER])
         ---09.11.17 SAL--- HRS002 << 
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D3 WITH (NOLOCK)
          ON D3.B_KEY = BU.B_KEY
         AND D3.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_AK' GROUP BY [ATTRIBUTE_NUMBER]) 
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D4 WITH (NOLOCK)
          ON D4.B_KEY = BU.B_KEY
         AND D4.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_RZ' GROUP BY [ATTRIBUTE_NUMBER]) 
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D5 WITH (NOLOCK)
          ON D5.B_KEY = BU.B_KEY
         AND D5.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_DS' GROUP BY [ATTRIBUTE_NUMBER]) 
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D6 WITH (NOLOCK)
          ON D6.B_KEY = BU.B_KEY
         AND D6.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_AU' GROUP BY [ATTRIBUTE_NUMBER]) 
	LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D7 WITH (NOLOCK)
          ON D7.B_KEY = BU.B_KEY
         AND D7.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_AE' GROUP BY [ATTRIBUTE_NUMBER]) 
	LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D8 WITH (NOLOCK)
          ON D8.B_KEY = BU.B_KEY
         AND D8.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_PR' GROUP BY [ATTRIBUTE_NUMBER]) 
	LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D9 WITH (NOLOCK)
          ON D9.B_KEY = BU.B_KEY
         AND D9.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_BD' GROUP BY [ATTRIBUTE_NUMBER]) 
	LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D10 WITH (NOLOCK)
          ON D10.B_KEY = BU.B_KEY
         AND D10.BP_GROUP_ID in (select [ATTRIBUTE_NUMBER] from [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WITH (NOLOCK) where [ATTRIBUTE_NAME] = 'DBI_IK' GROUP BY [ATTRIBUTE_NUMBER]) 
	GROUP BY BP_KEY
    ), IP AS
    (
      SELECT IP.[Process No_]
           , BU.[Hotel No_]
           , IP.[Currency Code (Ag)] [Currency Code]
           , CASE 
               WHEN CR.[Customer Template Code] = 1 THEN VA.[Vendor No_ Domestic]
               WHEN CR.[EU affiliation]         = 1 THEN VA.[Vendor No_ EU]
               WHEN CR.[EU affiliation]         = 1 THEN VA.[Vendor No_ Other]
             END [Vendor No_]
           , VA.[Customer No_]
           , BU.[Arrival Date]
           , BU.[Departure Date]
		   , BU.[Reservation Date]
           , CO.[Name] + ' ' + CO.[Name 2] [Hotel Name]
		   ---09.11.17 SAL--- HRS002 >>
           , CO.[Address] + ' ' + CO.[Address 2] [Street]
		   , CO.[Post Code] [Zipcode]
		   ---09.11.17 SAL--- HRS002 << 
           , CO.[City] [Hotel City]
           , CR.[Name] [Country]
           , BU.[Guestnames]
		   , BU.[Number of Travelers] --09.11.17 SAL HRS002
           , BU.DBI_PK
           , BU.DBI_KS
		   	---09.11.17 SAL--- HRS002 >>
		   , BU.DBI_AK
		   , BU.DBI_RZ
		   , BU.DBI_DS
		   , BU.DBI_AU
		   , BU.DBI_AE
		   , BU.DBI_PR
		   , BU.DBI_BD
		   , BU.DBI_IK
		   ---09.11.17 SAL--- HRS002 << 
        FROM [HRS$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
        JOIN [HRS$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
          ON VA.[Company No_] = BU.[Company No_]
        JOIN [HRS$Contact]                              CO WITH (NOLOCK)
          ON CO.[No_] = BU.[Hotel No_]
        JOIN [HRS$Country_Region]                       CR WITH (NOLOCK)
          ON CR.[Code] = CO.[Country_Region Code]
    ), INV AS
    (
    SELECT DISTINCT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SL.[VAT %]                  AS VAT
         , SL.[Unit Price]-SL.[Line Discount Amount] AS Amount
         , SL.[Outstanding Amount] - (SL.[Unit Price] - SL.[Line Discount Amount]) AS Mwst
         , SL.[Outstanding Amount]   AS Total
         , CASE WHEN SH.[Language Code]='' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , IP.[Process No_]
         , IP.[Hotel No_]
         , IP.[Currency Code]
         , IP.[Vendor No_]
         , IP.[Customer No_]
         , IP.[Arrival Date]
         , IP.[Departure Date]
         , IP.[Hotel Name]
         , IP.[Country]
         , IP.[Guestnames]
         ---09.11.17 SAL--- HRS002 >>                           
		 , IP.[Street]
		 , IP.[Zipcode]
		 ---09.11.17 SAL--- HRS002 << 
		 , IP.[Hotel City]
		 , IP.[Number of Travelers] --09.11.17 SAL HRS002
         , IP.DBI_PK
         , IP.DBI_KS
		 ---09.11.17 SAL--- HRS002 >>
		 , IP.DBI_AK
		 , IP.DBI_RZ
		 , IP.DBI_DS
		 , IP.DBI_AU
		 , IP.DBI_AE
		 , IP.DBI_PR
		 , IP.DBI_BD
		 , IP.DBI_IK
		 ---09.11.17 SAL--- HRS002 << 
		 , IP.[Reservation Date]
      FROM [HRS$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS$Country_Region] AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] IN ('0', '') THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code -- 09.11.17 SAL HRS002 - CASE condition edited
      JOIN [HRS$Sales Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Line No_]
     WHERE (SH.No_ = @ReNr)
UNION     
    SELECT DISTINCT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SL.[VAT %]                                  [VAT]
         , SL.[Unit Price] - SL.[Line Discount Amount] [Amount]
         , SL.[Amount Including VAT] - SL.Amount       [Mwst]
         , SL.[Amount Including VAT]                   [Total]
         , CASE WHEN SH.[Language Code]='' THEN 
             CO.[Primary Language Code] 
           ELSE 
             SH.[Language Code] 
           END                                         [Language Code]
         , IP.[Process No_]
         , IP.[Hotel No_]
         , IP.[Currency Code]
         , IP.[Vendor No_]
         , IP.[Customer No_]
         , IP.[Arrival Date]
         , IP.[Departure Date]
         , IP.[Hotel Name]
         , IP.[Country]
         , IP.[Guestnames]
		 ---09.11.17 SAL--- HRS002 >>                           
		 , IP.[Street]
		 , IP.[Zipcode]
		 ---09.11.17 SAL--- HRS002 << 
         , IP.[Hotel City]
		 , IP.[Number of Travelers] --09.11.17 SAL HRS002
         , IP.DBI_PK
         , IP.DBI_KS
		 ---09.11.17 SAL--- HRS002 >>
		 , IP.DBI_AK
		 , IP.DBI_RZ
		 , IP.DBI_DS
		 , IP.DBI_AU
		 , IP.DBI_AE
		 , IP.DBI_PR
		 , IP.DBI_BD
		 , IP.DBI_IK
		 ---09.11.17 SAL--- HRS002 << 
		 , IP.[Reservation Date]
      FROM [HRS$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS$Customer]             AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_]           = CU.[No_]
      JOIN [HRS$Country_Region]       AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] IN ('0', '') THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code -- 09.11.17 SAL HRS002 - CASE condition edited
      JOIN [HRS$Sales Invoice Line]   AS SL WITH (READUNCOMMITTED) 
        ON SH.No_                              = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Line No_]
     WHERE (SH.No_ = @ReNr)
     ), IPL AS
     (
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
         , PP.[AMOUNT_BEFORE_TAX] [VAT Base Amount]
         , PP.[TAX_RATE]          [VAT Rate]
         , PP.[TAX_AMOUNT]        [VAT Amount]
         , PP.[AMOUNT_AFTER_TAX]  [Hotel Amount]
		 , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , IP.[Currency Factor]
      FROM [HRS$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
      JOIN [HRS$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 WHERE IP.[Invoice No_] <> '2115I0075986'
     UNION
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
         , PP.[AMOUNT_BEFORE_TAX] [VAT Base Amount]
         , PP.[TAX_RATE]          [VAT Rate]
         , PP.[TAX_AMOUNT]        [VAT Amount]
         , PP.[AMOUNT_AFTER_TAX]  [Hotel Amount]
		 , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , IP.[Currency Factor]
      FROM [HRS$Paym_ Solution Invoice]      IP WITH (NOLOCK)
      JOIN [HRS$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 WHERE IP.[Invoice No_] <> '2115I0075986'
     ), IPLS AS
	 (
	SELECT [Process No_]
	     , [Hotel Invoice No_]
         , [Cust_ Posting Date]
		 , SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Breakfast]
		 , MAX(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('LOG')       THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Logis]
		 , MAX(CASE WHEN [Service Code] IN ('LOG')       THEN [VAT Rate]        ELSE 0 END) [VAT Rate Logis]
		 , SUM(CASE WHEN [Service Code] IN ('LOG')       THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Logis]
		 , SUM(CASE WHEN [Service Code] IN ('LOG')       THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Logis]
		 , SUM(CASE WHEN [Service Code] IN ('LTA')       THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Local Tax]
		 , MAX(CASE WHEN [Service Code] IN ('LTA')       THEN [VAT Rate]        ELSE 0 END) [VAT Rate Local Tax]
		 , SUM(CASE WHEN [Service Code] IN ('LTA')       THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Local Tax]
		 , SUM(CASE WHEN [Service Code] IN ('LTA')       THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Local Tax]
		 , SUM(CASE WHEN [Service Code] IN ('NOS')       THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount NoShow]
		 , MAX(CASE WHEN [Service Code] IN ('NOS')       THEN [VAT Rate]        ELSE 0 END) [VAT Rate NoShow]
		 , SUM(CASE WHEN [Service Code] IN ('NOS')       THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount NoShow]
		 , SUM(CASE WHEN [Service Code] IN ('NOS')       THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount NoShow]
		 , SUM(CASE WHEN [Service Code] IN ('PAR')       THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Parking]
		 , MAX(CASE WHEN [Service Code] IN ('PAR')       THEN [VAT Rate]        ELSE 0 END) [VAT Rate Parking]
		 , SUM(CASE WHEN [Service Code] IN ('PAR')       THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Parking]
		 , SUM(CASE WHEN [Service Code] IN ('PAR')       THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Parking]
		 , SUM(CASE WHEN [Service Code] IN ('SON','TRA') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Misc]
		 , MAX(CASE WHEN [Service Code] IN ('SON','TRA') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Misc]
		 , SUM(CASE WHEN [Service Code] IN ('SON','TRA') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Misc]
		 , SUM(CASE WHEN [Service Code] IN ('SON','TRA') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Misc]
      FROM IPL
  GROUP BY [Process No_]
	     , [Hotel Invoice No_]
         , [Cust_ Posting Date]
	 )
    SELECT ROW_NUMBER() OVER(ORDER BY INV.[Process No_]) [Position]
	     , INV.*
      FROM INV
END
GO
