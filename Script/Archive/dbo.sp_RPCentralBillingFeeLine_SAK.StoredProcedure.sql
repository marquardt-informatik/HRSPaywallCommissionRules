USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeLine_SAK]    Script Date: 10.04.2024 14:31:46 ******/
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
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'R000000480'
EXEC [dbo].[sp_RPCentralBillingFeeLine_SAK] @ReNr
*/
-- ============================================= 52092780

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeLine_SAK] 
    @ReNr varchar(25)
AS
BEGIN
	SET NOCOUNT ON;
	
    DECLARE @Count int=0
     SELECT @Count = COALESCE(COUNT(1),0)
	   FROM [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS Payment$Sales Line] SL WITH (NOLOCK)
         ON SL.[Document No_] = CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	   JOIN [HRS Payment$Sales Header] SH WITH (NOLOCK)
	     ON SH.[No_] = SL.[Document No_] 
	  WHERE SH.[No_] = @ReNr

    IF @Count=0
	BEGIN
     SELECT @Count = COALESCE(COUNT(1),0)
	   FROM [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS Payment$Cust_ CC Invoice Header] CH WITH (NOLOCK)
	     ON CC.[CC Invoice Entry No_] = CH.[Entry No_]
	   JOIN [HRS Payment$Sales Invoice Header] SH WITH (NOLOCK)
	     ON SH.[Pre-Assigned No_] = CC.[Document No_] 
	   JOIN [HRS Payment$Sales Invoice Line] SL WITH (NOLOCK)
         ON SH.[Pre-Assigned No_]= CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	  WHERE @ReNr In (SH.[No_], SH.[Pre-Assigned No_])
	END
	
	IF @Count=0
	BEGIN

    ;WITH BU AS
    (
      SELECT BU.BP_KEY [Process No_]
           , MAX(BU.B_GAST1) [Guest]
           , MAX(BU.K_KEY) [Company No_]
           , MAX(BU.H_KEY) [Hotel No_]
           , MIN(BU.B_AN_DATUM) [Arrival Date]
           , MAX(BU.B_AB_DATUM) [Departure Date]
		   , MAX(BU.B_DATUM) [Reservation Date]
           , MAX(COALESCE(D1.BCDT_VALUE,'')) DBI_PK
           , MAX(COALESCE(D2.BCDT_VALUE,'')) DBI_KS
        FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D1 WITH (NOLOCK)
          ON D1.B_KEY = BU.B_KEY
         AND D1.BP_GROUP_ID in( 7144, 8742)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D2 WITH (NOLOCK)
          ON D2.B_KEY = BU.B_KEY
         AND D2.BP_GROUP_ID in( 7182)
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
           , CO.[City] [Hotel City]
           , CR.[Name] [Country]
           , BU.[Guest]
           , BU.DBI_PK
           , BU.DBI_KS
        FROM [HRS Payment$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
        JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
          ON VA.[Company No_] = BU.[Company No_]
        JOIN [HRS$Contact]                              CO WITH (NOLOCK)
          ON CO.[No_] = BU.[Hotel No_]
        JOIN [HRS$Country_Region]                       CR WITH (NOLOCK)
          ON CR.[Code] = CO.[Country_Region Code]
    ), INV AS
    (
    SELECT SH.[No_]
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
         , IP.[Guest]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.[Reservation Date]
      FROM [HRS Payment$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS Payment$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS Payment$Country_Region] AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS Payment$Sales Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Line No_]
     WHERE (SH.No_ = @ReNr)
UNION ALL
    SELECT SH.[No_]
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
         , IP.[Guest]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.[Reservation Date]
      FROM [HRS Payment$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS Payment$Customer]             AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_]           = CU.[No_]
      JOIN [HRS Payment$Country_Region]       AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS Payment$Sales Invoice Line]   AS SL WITH (READUNCOMMITTED) 
        ON SH.No_                              = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Line No_]
     WHERE (SH.No_ = @ReNr)
     ), IPL AS
     (
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount] ELSE PP.[AMOUNT_BEFORE_TAX] END [VAT Base Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Rate] ELSE PP.[TAX_RATE] END [VAT Rate]
	     , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Amount] ELSE PP.[TAX_AMOUNT] END [VAT Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount] ELSE PP.[AMOUNT_AFTER_TAX] END [Hotel Amount]
         , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , IP.[Currency Factor]
      FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
      JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 WHERE IP.[Invoice No_] <> '2115I0075986'
     UNION ALL
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
         , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount] ELSE PP.[AMOUNT_BEFORE_TAX] END [VAT Base Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Rate] ELSE PP.[TAX_RATE] END [VAT Rate]
	     , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Amount] ELSE PP.[TAX_AMOUNT] END [VAT Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount] ELSE PP.[AMOUNT_AFTER_TAX] END [Hotel Amount]
		 , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , IP.[Currency Factor]
      FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
      JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 WHERE IP.[Invoice No_] <> '2115I0075986'
  	   AND IP.[Cancel] = 0
     ), IPLS AS
	 (
	SELECT [Process No_]
	     , MIN([Hotel Invoice No_]) [Hotel Invoice No_]
         ,MIN([Cust_ Posting Date]) [Cust_ Posting Date]
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
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Misc]
		 , MAX(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Misc]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Misc]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Misc]
      FROM IPL
  GROUP BY [Process No_]
	     --, [Hotel Invoice No_]
      --   , [Cust_ Posting Date]
	 ), CC AS
	 (
	SELECT BP.BP_KEY                                            [Process No_]
         , MIN(CC.UATP_CARD_NUMBER)                                  [UATP Card Number]
         , MIN(CC.UATP_CARD_VALID_UNTIL)                             [UATP Card Valid Until]
         , MIN(CC.UATP_CARD_HOLDER)                                  [UATP Card Holder]
         , MIN(CI.PAYMENT_CONFIGURATION_ID) PAYMENT_CONFIGURATION_ID
		 , COUNT(1)                                             [Bookings]
      FROM HRSDB.BKG_PROCESS_LIST_ALL_DA      BP WITH (NOLOCK)
 LEFT JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
 LEFT JOIN HRSDB.BKG_CI_DATA_DA               CI WITH (NOLOCK)
        ON CI.B_KEY                         = BU.B_KEY
 LEFT JOIN HRSDB.CUS_CI_PAYMENT_CONFIGURATION CC WITH (NOLOCK)
        ON CC.ID_VALUE                      = CI.PAYMENT_CONFIGURATION_ID
  GROUP BY BP.BP_KEY
         --, CC.UATP_CARD_NUMBER
         --, CC.UATP_CARD_VALID_UNTIL
         --, CC.UATP_CARD_HOLDER
         --, CI.PAYMENT_CONFIGURATION_ID
	 )
    SELECT ROW_NUMBER() OVER(ORDER BY INV.[Process No_]) [Position]
	     , INV.*
         , [Hotel Invoice No_]
         , CC.[UATP Card Number]
         , CC.[UATP Card Valid Until]
         , CC.[UATP Card Holder]
         , CC.PAYMENT_CONFIGURATION_ID
         , CASE WHEN IPLS.[Process No_] IS NULL THEN 0 ELSE 1 END [Hotel Invoice]
		 , [VAT Base Amount Breakfast]
		   + [VAT Base Amount Logis]
		   + [VAT Base Amount Local Tax]
  		   + [VAT Base Amount NoShow]
		   + [VAT Base Amount Parking]
		   + [VAT Base Amount Misc] [VAT Base Amount]
		 , [VAT Amount Breakfast]
		   + [VAT Amount Logis]
		   + [VAT Amount Local Tax]
  		   + [VAT Amount NoShow]
		   + [VAT Amount Parking]
		   + [VAT Amount Misc] [VAT Amount]
		 , [Hotel Amount Breakfast]
		   + [Hotel Amount Logis]
		   + [Hotel Amount Local Tax]
  		   + [Hotel Amount NoShow]
		   + [Hotel Amount Parking]
		   + [Hotel Amount Misc] [Hotel Amount]
		 , [VAT Base Amount Breakfast]
		 , [VAT Rate Breakfast]
		 , [VAT Amount Breakfast]
		 , [Hotel Amount Breakfast]
		 , [VAT Base Amount Logis]
		 , [VAT Rate Logis]
		 , [VAT Amount Logis]
		 , [Hotel Amount Logis]
		 , [VAT Base Amount Local Tax]
		 , [VAT Rate Local Tax]
		 , [VAT Amount Local Tax]
		 , [Hotel Amount Local Tax]
		 , [VAT Base Amount NoShow]
		 , [VAT Rate NoShow]
		 , [VAT Amount NoShow]
		 , [Hotel Amount NoShow]
		 , [VAT Base Amount Parking]
		 , [VAT Rate Parking]
		 , [VAT Amount Parking]
		 , [Hotel Amount Parking]
		 , [VAT Base Amount Misc]
		 , [VAT Rate Misc]
		 , [VAT Amount Misc]
		 , [Hotel Amount Misc]
		 , [Cust_ Posting Date]
      FROM INV
 LEFT JOIN IPLS 
        ON IPLS.[Process No_]               = INV.[Process No_]
 LEFT JOIN CC
        ON CC.[Process No_]                 = INV.[Process No_]
  END

  IF @Count>0
  BEGIN
    ;WITH BU AS
    (
      SELECT BU.BP_KEY [Process No_]
           , MAX(BU.B_GAST1) [Guest]
           , MAX(BU.K_KEY) [Company No_]
           , MAX(BU.H_KEY) [Hotel No_]
           , MIN(BU.B_AN_DATUM) [Arrival Date]
           , MAX(BU.B_AB_DATUM) [Departure Date]
		   , MAX(BU.B_DATUM) [Reservation Date]
           , MAX(COALESCE(D1.BCDT_VALUE,'')) DBI_PK
           , MAX(COALESCE(D2.BCDT_VALUE,'')) DBI_KS
        FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D1 WITH (NOLOCK)
          ON D1.B_KEY = BU.B_KEY
         AND D1.BP_GROUP_ID in( 7144, 8742)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D2 WITH (NOLOCK)
          ON D2.B_KEY = BU.B_KEY
         AND D2.BP_GROUP_ID in ( 7182)
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
           , CO.[City] [Hotel City]
           , CR.[Name] [Country]
           , BU.[Guest]
           , BU.DBI_PK
           , BU.DBI_KS
        FROM [HRS Payment$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
        JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
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
         , IP.[Guest]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.[Reservation Date]
      FROM [HRS Payment$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS Payment$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS Payment$Country_Region] AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS Payment$Sales Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Reservation No_]
     WHERE (SH.No_ = @ReNr)
UNION ALL
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
         , IP.[Guest]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.[Reservation Date]
      FROM [HRS Payment$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS Payment$Customer]             AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_]           = CU.[No_]
      JOIN [HRS Payment$Country_Region]       AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS Payment$Sales Invoice Line]   AS SL WITH (READUNCOMMITTED) 
        ON SH.No_                              = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Reservation No_]
     WHERE (SH.No_ = @ReNr)
     ), IPL AS
     (
  --  SELECT IP.[Process No_]
  --       , IL.[Service Date]
  --       , IL.[Service Code]
  --       , IL.[Service Description]
  --       , PP.[AMOUNT_BEFORE_TAX] [VAT Base Amount]
  --       , PP.[TAX_RATE]          [VAT Rate]
  --       , PP.[TAX_AMOUNT]        [VAT Amount]
  --       , PP.[AMOUNT_AFTER_TAX]  [Hotel Amount]
		-- , IP.[Invoice No_]       [Hotel Invoice No_]
  --       , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		-- , CL.[Posting Date]      [Cust_ Posting Date]
		-- , IP.[Currency Factor]
  --    FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
  --    JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
  --      ON IL.[Invoice GUID] = IP.[Invoice GUID]
	 -- JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	 --   ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	 -- JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	 --   ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 --WHERE IP.[Invoice No_] <> '2115I0075986'
  --   UNION ALL
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
	       , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount] ELSE CC.[Net Amount (SC)] END [VAT Base Amount]
		   , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Rate] ELSE CC.[VAT Rate] END [VAT Rate]
	       , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Amount] ELSE CC.[Tax(SC)] END [VAT Amount]
		   , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount] ELSE CC.[Net Amount (SC)] + CC.[Tax(SC)] END [Hotel Amount]
  		   , IP.[Invoice No_]       [Hotel Invoice No_]
           , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , CL.[Posting Date]      [Cust_ Posting Date]
		   , (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] [Currency Factor]
        FROM [HRS Payment$Sales Header] SH
		JOIN [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK) ON 1=1
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
	    JOIN [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
  	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
	     AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]
		 AND CC.[Document No_]                       = SH.[No_]
	    JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	      ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	    JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	      ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	   WHERE IP.[Invoice No_] <> '2115I0075986'
  	     AND IP.[Cancel] = 0
		 AND SH.[No_] = @ReNr
       UNION ALL
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
	       , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount] ELSE CC.[Net Amount (SC)] END [VAT Base Amount]
		   , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Rate] ELSE CC.[VAT Rate] END [VAT Rate]
	       , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Amount] ELSE CC.[Tax(SC)] END [VAT Amount]
		   , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount] ELSE CC.[Net Amount (SC)] + CC.[Tax(SC)] END [Hotel Amount]
  		   , IP.[Invoice No_]       [Hotel Invoice No_]
           , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , CL.[Posting Date]      [Cust_ Posting Date]
		   , (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] [Currency Factor]
        FROM [HRS Payment$Sales Invoice Header] SH
		JOIN [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK) ON 1=1
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
	    JOIN [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
  	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
	     AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]
		 AND CC.[Document No_]                       = SH.[Pre-Assigned No_]
	    JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	      ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	    JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	      ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	   WHERE IP.[Invoice No_] <> '2115I0075986'
  	     AND IP.[Cancel] = 0
		 AND (SH.[Pre-Assigned No_] = @ReNr OR SH.[No_] = @ReNr)
     ), IPLS AS
	 (
	SELECT [Process No_]
	     , MIN([Hotel Invoice No_]) [Hotel Invoice No_]
         ,MIN([Cust_ Posting Date]) [Cust_ Posting Date]
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
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Misc]
		 , MAX(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Misc]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Misc]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Misc]
      FROM IPL
  GROUP BY [Process No_]
	     --, [Hotel Invoice No_]
      --   , [Cust_ Posting Date]
	 ), CC AS
	 (
	SELECT BP.BP_KEY                                            [Process No_]
         , MIN(CC.UATP_CARD_NUMBER)                                  [UATP Card Number]
         , MIN(CC.UATP_CARD_VALID_UNTIL)                             [UATP Card Valid Until]
         , MIN(CC.UATP_CARD_HOLDER)                                  [UATP Card Holder]
         , MIN(CI.PAYMENT_CONFIGURATION_ID) PAYMENT_CONFIGURATION_ID
		 , COUNT(1)                                             [Bookings]
      FROM HRSDB.BKG_PROCESS_LIST_ALL_DA      BP WITH (NOLOCK)
 LEFT JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
 LEFT JOIN HRSDB.BKG_CI_DATA_DA               CI WITH (NOLOCK)
        ON CI.B_KEY                         = BU.B_KEY
 LEFT JOIN HRSDB.CUS_CI_PAYMENT_CONFIGURATION CC WITH (NOLOCK)
        ON CC.ID_VALUE                      = CI.PAYMENT_CONFIGURATION_ID
  GROUP BY BP.BP_KEY
         --, CC.UATP_CARD_NUMBER
         --, CC.UATP_CARD_VALID_UNTIL
         --, CC.UATP_CARD_HOLDER
         --, CI.PAYMENT_CONFIGURATION_ID
	 )
	 --SELECT * FROM IPL
    SELECT ROW_NUMBER() OVER(ORDER BY INV.[Process No_]) [Position]
	     , INV.*
         , [Hotel Invoice No_]
         , CC.[UATP Card Number]
         , CC.[UATP Card Valid Until]
         , CC.[UATP Card Holder]
         , CC.PAYMENT_CONFIGURATION_ID
         , CASE WHEN IPLS.[Process No_] IS NULL THEN 0 ELSE 1 END [Hotel Invoice]
		 , [VAT Base Amount Breakfast]
		   + [VAT Base Amount Logis]
		   + [VAT Base Amount Local Tax]
  		   + [VAT Base Amount NoShow]
		   + [VAT Base Amount Parking]
		   + [VAT Base Amount Misc] [VAT Base Amount]
		 , [VAT Amount Breakfast]
		   + [VAT Amount Logis]
		   + [VAT Amount Local Tax]
  		   + [VAT Amount NoShow]
		   + [VAT Amount Parking]
		   + [VAT Amount Misc] [VAT Amount]
		 , [Hotel Amount Breakfast]
		   + [Hotel Amount Logis]
		   + [Hotel Amount Local Tax]
  		   + [Hotel Amount NoShow]
		   + [Hotel Amount Parking]
		   + [Hotel Amount Misc] [Hotel Amount]
		 , [VAT Base Amount Breakfast]
		 , [VAT Rate Breakfast]
		 , [VAT Amount Breakfast]
		 , [Hotel Amount Breakfast]
		 , [VAT Base Amount Logis]
		 , [VAT Rate Logis]
		 , [VAT Amount Logis]
		 , [Hotel Amount Logis]
		 , [VAT Base Amount Local Tax]
		 , [VAT Rate Local Tax]
		 , [VAT Amount Local Tax]
		 , [Hotel Amount Local Tax]
		 , [VAT Base Amount NoShow]
		 , [VAT Rate NoShow]
		 , [VAT Amount NoShow]
		 , [Hotel Amount NoShow]
		 , [VAT Base Amount Parking]
		 , [VAT Rate Parking]
		 , [VAT Amount Parking]
		 , [Hotel Amount Parking]
		 , [VAT Base Amount Misc]
		 , [VAT Rate Misc]
		 , [VAT Amount Misc]
		 , [Hotel Amount Misc]
		 , [Cust_ Posting Date]
      FROM INV
 LEFT JOIN IPLS 
        ON IPLS.[Process No_]               = INV.[Process No_]
 LEFT JOIN CC
        ON CC.[Process No_]                 = INV.[Process No_]
  END
END



GO
