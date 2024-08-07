USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeLine_PaySol_Lines_SIK ACS-4182]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 01.05.2015
-- Description:	Attachment of Collective Central Billing Invoice
--

-- Datum    Version     RFC       Sign.  Beschreibung
-- ------------------------------------------------------------------
-- 01.05.15   HRS001    -----     TM     Created
-- 15.02.17	            NAV-520   SAK 
-- 26.04.17             NAV-379   SAK	
-- 13.09.17             NAV-709   SAL    Dynamic calculation of DBI fields instead of static values in where clause
-- 03.09.18             ACS-432   SAK    Central Billing Sammelrechnung - Fehler bei Abreise Datum
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'R000005627'
EXEC [dbo].[sp_RPCentralBillingFeeLine_PaySol_Lines] @ReNr
*/
-- ============================================= 52092780

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeLine_PaySol_Lines_SIK ACS-4182] 
    @ReNr varchar(25)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @Count int=0
     SELECT @Count = COALESCE(COUNT(1),0)
	   FROM [HRS PaySol$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS PaySol$Sales Line] SL WITH (NOLOCK)
         ON SL.[Document No_] = CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	   JOIN [HRS PaySol$Sales Header] SH WITH (NOLOCK)
	     ON SH.[No_] = SL.[Document No_] 
	  WHERE SH.[No_] = @ReNr

    IF @Count=0
	BEGIN
     SELECT @Count = COALESCE(COUNT(1),0)
	   FROM [HRS PaySol$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS PaySol$Cust_ CC Invoice Header] CH WITH (NOLOCK)
	     ON CC.[CC Invoice Entry No_] = CH.[Entry No_]
	   JOIN [HRS PaySol$Sales Invoice Header] SH WITH (NOLOCK)
	     ON SH.[Pre-Assigned No_] = CC.[Document No_] 
	   JOIN [HRS PaySol$Sales Invoice Line] SL WITH (NOLOCK)
         ON SH.[Pre-Assigned No_]= CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	  WHERE @ReNr In (SH.[No_], SH.[Pre-Assigned No_])
	END
	
	IF @Count=0
	BEGIN

    ;WITH BU AS
    (
      SELECT BU.BP_KEY [Process No_]
	       , MAX(BU.B_KEY) [B_KEY]
           , MAX(BU.B_GAST1) [Guest]
           , MAX(BU.K_KEY) [Company No_]
           , MAX(BU.H_KEY) [Hotel No_]
           , MIN(BU.B_AN_DATUM) [Arrival Date]
           , MAX(BU.B_AB_DATUM) [Departure Date]
		   , MAX(BU.B_DATUM) [Reservation Date]
		   , MAX(BU.B_EMAIL_NEW) [EMail New]
           , MAX(CASE WHEN BA01.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_PK
           , MAX(CASE WHEN BA02.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_KS
		   , MAX(CASE WHEN BA03.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_AK
		   , MAX(CASE WHEN BA04.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_RZ
		   , MAX(CASE WHEN BA05.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_DS
		   , MAX(CASE WHEN BA06.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_AU
		   , MAX(CASE WHEN BA07.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_AE
		   , MAX(CASE WHEN BA08.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_PR
		   , MAX(CASE WHEN BA09.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_BD
		   , MAX(CASE WHEN BA10.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_IK
        FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D WITH (NOLOCK)
          ON D.B_KEY = BU.B_KEY
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA01 WITH (NOLOCK) ON D.BP_GROUP_ID=BA01.ATTRIBUTE_NUMBER AND BA01.[ATTRIBUTE_NAME] = 'DBI_PK'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA02 WITH (NOLOCK) ON D.BP_GROUP_ID=BA02.ATTRIBUTE_NUMBER AND BA02.[ATTRIBUTE_NAME] = 'DBI_KS'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA03 WITH (NOLOCK) ON D.BP_GROUP_ID=BA03.ATTRIBUTE_NUMBER AND BA03.[ATTRIBUTE_NAME] = 'DBI_AK'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA04 WITH (NOLOCK) ON D.BP_GROUP_ID=BA04.ATTRIBUTE_NUMBER AND BA04.[ATTRIBUTE_NAME] = 'DBI_RZ'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA05 WITH (NOLOCK) ON D.BP_GROUP_ID=BA05.ATTRIBUTE_NUMBER AND BA05.[ATTRIBUTE_NAME] = 'DBI_DS'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA06 WITH (NOLOCK) ON D.BP_GROUP_ID=BA06.ATTRIBUTE_NUMBER AND BA06.[ATTRIBUTE_NAME] = 'DBI_AU'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA07 WITH (NOLOCK) ON D.BP_GROUP_ID=BA07.ATTRIBUTE_NUMBER AND BA07.[ATTRIBUTE_NAME] = 'DBI_AE'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA08 WITH (NOLOCK) ON D.BP_GROUP_ID=BA08.ATTRIBUTE_NUMBER AND BA08.[ATTRIBUTE_NAME] = 'DBI_PR'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA09 WITH (NOLOCK) ON D.BP_GROUP_ID=BA09.ATTRIBUTE_NUMBER AND BA09.[ATTRIBUTE_NAME] = 'DBI_BD'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA10 WITH (NOLOCK) ON D.BP_GROUP_ID=BA10.ATTRIBUTE_NUMBER AND BA10.[ATTRIBUTE_NAME] = 'DBI_IK'
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
           , BUCHUNG.B_AB_DATUM [Departure Date]
		   , BU.[Reservation Date]		   
           , CO.[Name] + ' ' + CO.[Name 2] [Hotel Name]
           , CO.[City] [Hotel City]
           , CR.[Name] [Country]
           , BU.[Guest]
		   , BU.[EMail New]
           , BU.DBI_PK
           , BU.DBI_KS
		   , BU.DBI_AK
		   , BU.DBI_RZ
		   , BU.DBI_DS
		   , BU.DBI_AU
		   , BU.DBI_AE
		   , BU.DBI_PR
		   , BU.DBI_BD
		   , BU.DBI_IK
        FROM [HRS PaySol$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
		JOIN HRSDB.BUCHUNG BUCHUNG WITH (NOLOCK) ON BUCHUNG.B_KEY = BU.B_KEY
        JOIN [HRS PaySol$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
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
		 , IP.[EMail New]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.DBI_AK
		 , IP.DBI_RZ
		 , IP.DBI_DS
		 , IP.DBI_AU
		 , IP.DBI_AE
		 , IP.DBI_PR
		 , IP.DBI_BD
		 , IP.DBI_IK
		 , IP.[Reservation Date]
		 , SL.[Description] [Invoice No_]
      FROM [HRS PaySol$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS PaySol$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS PaySol$Country_Region] AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS PaySol$Sales Line] AS SL WITH (READUNCOMMITTED) 
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
		 , IP.[EMail New]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.DBI_AK
		 , IP.DBI_RZ
		 , IP.DBI_DS
		 , IP.DBI_AU
		 , IP.DBI_AE
		 , IP.DBI_PR
		 , IP.DBI_BD
		 , IP.DBI_IK
		 , IP.[Reservation Date]
		 , SL.[Description] [Invoice No_]
      FROM [HRS PaySol$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS PaySol$Customer]             AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_]           = CU.[No_]
      JOIN [HRS PaySol$Country_Region]       AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS PaySol$Sales Invoice Line]   AS SL WITH (READUNCOMMITTED) 
        ON SH.No_                              = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Line No_]
     WHERE (SH.No_ = @ReNr)
     ), IPL AS
     (
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)] ELSE PP.[AMOUNT_BEFORE_TAX] END [VAT Base Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Rate] ELSE PP.[TAX_RATE] END [VAT Rate]
	     , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Amount (LCY)] ELSE PP.[TAX_AMOUNT] END [VAT Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount (LCY)] ELSE PP.[AMOUNT_AFTER_TAX] END [Hotel Amount]
         , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , IP.[Currency Factor]
      FROM [HRS PaySol$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
      JOIN [HRS PaySol$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS PaySol$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 WHERE IP.[Invoice No_] <> '2115I0075986'
     UNION ALL
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
         , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)] ELSE PP.[AMOUNT_BEFORE_TAX] END [VAT Base Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Rate] ELSE PP.[TAX_RATE] END [VAT Rate]
	     , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Amount (LCY)] ELSE PP.[TAX_AMOUNT] END [VAT Amount]
		 , CASE WHEN IL.[Sales VAT Base Amount]<>0 THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount] ELSE PP.[AMOUNT_AFTER_TAX] END [Hotel Amount]
		 , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , IP.[Currency Factor]
      FROM [HRS PaySol$Paym_ Solution Invoice]      IP WITH (NOLOCK)
      JOIN [HRS PaySol$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS PaySol$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 WHERE IP.[Invoice No_] <> '2115I0075986'
  	   AND IP.[Cancel] = 0
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
	     , ROW_NUMBER() OVER(PARTITION BY INV.[Process No_] ORDER BY INV.[Process No_]) [Invoice Position]
	     , [Cust_ Posting Date]
		 , INV.[Hotel No_]
		 , INV.[Hotel Name]
		 , INV.[Hotel City]
		 , [Hotel Invoice No_]
	     , INV.[Process No_]
		 , INV.Guest
		 , INV.[Reservation Date]
		 , INV.[Arrival Date]
		 , INV.[Departure Date]
		 , IPL.[VAT Base Amount]
		 , IPL.[Currency Code]
		 , IPL.[Service Code]
		 , IPL.[Service Description]
		 , IPL.[VAT Rate]
		 , IPL.[VAT Amount]
		 , IPL.[Hotel Amount]	
		 , INV.[EMail New]
		 , INV.DBI_PK
		 , INV.DBI_KS
		 , INV.DBI_AK
		 , INV.DBI_RZ
		 , INV.DBI_DS
		 , INV.DBI_AU
		 , INV.DBI_AE
		 , INV.DBI_PR
		 , INV.DBI_BD
		 , INV.DBI_IK
		 , INV.[Invoice No_]
      FROM INV
 LEFT JOIN IPL 
        ON IPL.[Process No_]               = INV.[Process No_]
 LEFT JOIN CC
        ON CC.[Process No_]                 = INV.[Process No_]
  END

  IF @Count>0
  BEGIN
    ;WITH BU AS
    (
      SELECT BU.BP_KEY [Process No_]
	       , MAX(BU.B_KEY) [B_KEY]
           , MAX(BU.B_GAST1) [Guest]
           , MAX(BU.K_KEY) [Company No_]
           , MAX(BU.H_KEY) [Hotel No_]
           , MIN(BU.B_AN_DATUM) [Arrival Date]
           , MAX(BU.B_AB_DATUM) [Departure Date]
		   , MAX(BU.B_DATUM) [Reservation Date]
		   , MAX(BU.B_EMAIL_NEW) [EMail New]
           , MAX(CASE WHEN BA01.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_PK
           , MAX(CASE WHEN BA02.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_KS
		   , MAX(CASE WHEN BA03.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_AK
		   , MAX(CASE WHEN BA04.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_RZ
		   , MAX(CASE WHEN BA05.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_DS
		   , MAX(CASE WHEN BA06.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_AU
		   , MAX(CASE WHEN BA07.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_AE
		   , MAX(CASE WHEN BA08.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_PR
		   , MAX(CASE WHEN BA09.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_BD
		   , MAX(CASE WHEN BA10.ATTRIBUTE_NUMBER IS NULL THEN '' ELSE D.BCDT_VALUE END)  DBI_IK
        FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA D WITH (NOLOCK)
          ON D.B_KEY = BU.B_KEY
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA01 WITH (NOLOCK) ON D.BP_GROUP_ID=BA01.ATTRIBUTE_NUMBER AND BA01.[ATTRIBUTE_NAME] = 'DBI_PK'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA02 WITH (NOLOCK) ON D.BP_GROUP_ID=BA02.ATTRIBUTE_NUMBER AND BA02.[ATTRIBUTE_NAME] = 'DBI_KS'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA03 WITH (NOLOCK) ON D.BP_GROUP_ID=BA03.ATTRIBUTE_NUMBER AND BA03.[ATTRIBUTE_NAME] = 'DBI_AK'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA04 WITH (NOLOCK) ON D.BP_GROUP_ID=BA04.ATTRIBUTE_NUMBER AND BA04.[ATTRIBUTE_NAME] = 'DBI_RZ'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA05 WITH (NOLOCK) ON D.BP_GROUP_ID=BA05.ATTRIBUTE_NUMBER AND BA05.[ATTRIBUTE_NAME] = 'DBI_DS'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA06 WITH (NOLOCK) ON D.BP_GROUP_ID=BA06.ATTRIBUTE_NUMBER AND BA06.[ATTRIBUTE_NAME] = 'DBI_AU'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA07 WITH (NOLOCK) ON D.BP_GROUP_ID=BA07.ATTRIBUTE_NUMBER AND BA07.[ATTRIBUTE_NAME] = 'DBI_AE'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA08 WITH (NOLOCK) ON D.BP_GROUP_ID=BA08.ATTRIBUTE_NUMBER AND BA08.[ATTRIBUTE_NAME] = 'DBI_PR'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA09 WITH (NOLOCK) ON D.BP_GROUP_ID=BA09.ATTRIBUTE_NUMBER AND BA09.[ATTRIBUTE_NAME] = 'DBI_BD'
   LEFT JOIN [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] BA10 WITH (NOLOCK) ON D.BP_GROUP_ID=BA10.ATTRIBUTE_NUMBER AND BA10.[ATTRIBUTE_NAME] = 'DBI_IK'
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
           , BUCHUNG.B_AB_DATUM [Departure Date]
		   , BU.[Reservation Date]
           , CO.[Name] + ' ' + CO.[Name 2] [Hotel Name]
		   , CO.[Address] + ' ' + CO.[Address 2] [Hotel Address]
		   , CO.[VAT Registration No_] [Hotel VAT No_]
           , CO.[City] [Hotel City]
           , CR.[Name] [Country]
           , BU.[Guest]
		   , BU.[EMail New]
           , BU.DBI_PK
           , BU.DBI_KS
		   , BU.DBI_AK
		   , BU.DBI_RZ
		   , BU.DBI_DS
		   , BU.DBI_AU
		   , BU.DBI_AE
		   , BU.DBI_PR
		   , BU.DBI_BD
		   , BU.DBI_IK
        FROM [HRS PaySol$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
		JOIN HRSDB.BUCHUNG BUCHUNG WITH (NOLOCK) ON BUCHUNG.B_KEY = BU.B_KEY
        JOIN [HRS PaySol$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
          ON VA.[Company No_] = BU.[Company No_]
        JOIN [HRS$Contact]                              CO WITH (NOLOCK)
          ON CO.[No_] = BU.[Hotel No_]
        JOIN [HRS$Country_Region]                       CR WITH (NOLOCK)
          ON CR.[Code] = CO.[Country_Region Code]
    ), INV AS
    (
    SELECT DISTINCT SH.[No_]
         , SH.[Sell-to Customer No_]
		 , SH.[Sell-to Customer Name] + ' ' + SH.[Sell-to Customer Name 2] [Sell-to Customer Name]
		 , SH.[Sell-to Address] + ' ' + SH.[Sell-to Address 2] [Sell-to Address]
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
		 , IP.[Hotel Address]
		 , IP.[Hotel VAT No_]
         , IP.[Country]
         , IP.[Guest]
		 , IP.[EMail New]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.DBI_AK
		 , IP.DBI_RZ
		 , IP.DBI_DS
		 , IP.DBI_AU
		 , IP.DBI_AE
		 , IP.DBI_PR
		 , IP.DBI_BD
		 , IP.DBI_IK
		 , IP.[Reservation Date]
		 , SL.[Description] [Invoice No_]
      FROM [HRS PaySol$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS PaySol$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS PaySol$Country_Region] AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS PaySol$Sales Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
      JOIN IP ON IP.[Process No_] = SL.[Reservation No_]
     WHERE (SH.No_ = @ReNr)
UNION ALL
    SELECT DISTINCT SH.[No_]
         , SH.[Sell-to Customer No_]
		 , SH.[Sell-to Customer Name] + ' ' + SH.[Sell-to Customer Name 2] [Sell-to Customer Name]
		 , SH.[Sell-to Address] + ' ' + SH.[Sell-to Address 2] [Sell-to Address]
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
		 , IP.[Hotel Address]
		 , IP.[Hotel VAT No_]
         , IP.[Country]
         , IP.[Guest]
		 , IP.[EMail New]
         , IP.[Hotel City]
         , IP.DBI_PK
         , IP.DBI_KS
		 , IP.DBI_AK
		 , IP.DBI_RZ
		 , IP.DBI_DS
		 , IP.DBI_AU
		 , IP.DBI_AE
		 , IP.DBI_PR
		 , IP.DBI_BD
		 , IP.DBI_IK
		 , IP.[Reservation Date]
		 , SL.[Description] [Invoice No_]
      FROM [HRS PaySol$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [HRS PaySol$Customer]             AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_]           = CU.[No_]
      JOIN [HRS PaySol$Country_Region]       AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS PaySol$Sales Invoice Line]   AS SL WITH (READUNCOMMITTED) 
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
  --    FROM [HRS PaySol$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
  --    JOIN [HRS PaySol$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
  --      ON IL.[Invoice GUID] = IP.[Invoice GUID]
	 -- JOIN [HRS PaySol$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	 --   ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	 -- JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	 --   ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	 --WHERE IP.[Invoice No_] <> '2115I0075986'
  --   UNION ALL
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
	       , CASE WHEN IL.[Sales VAT Amount]<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' THEN CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) * 100 ELSE IL.[Sales VAT Base Amount (LCY)] END [VAT Base Amount]
	       , IL.[Sales VAT Rate] [VAT Rate]
	       , CASE WHEN IL.[Sales VAT Amount]<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' THEN IL.[Sales VAT Rate]*CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) ELSE IL.[Sales VAT Amount (LCY)]  END [VAT Amount]
	       , CASE WHEN IL.[Sales VAT Amount]<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' THEN CC.[Gross Amount (BC)] ELSE IL.[Sales VAT Base Amount (LCY)] END [Hotel Amount]
  		   , IP.[Invoice No_]       [Hotel Invoice No_]
           , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , CL.[Posting Date]      [Cust_ Posting Date]
		   --, (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] [Currency Factor]
		   , CASE WHEN CC.[Gross Amount (BC)] > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END [Currency Factor]
		   , IP.[Invoice GUID]
        FROM [HRS PaySol$Sales Header] SH
		JOIN [HRS PaySol$Paym_ Solution Invoice]      IP WITH (NOLOCK) ON 1=1
        JOIN [HRS PaySol$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
	    JOIN [HRS PaySol$Cust_ CC Invoice Line] CC WITH (NOLOCK)
  	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
	     AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]
		 AND CC.[Document No_]                       = SH.[No_]
	    JOIN [HRS PaySol$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
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
	       , CASE WHEN IL.[Sales VAT Amount]<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' THEN CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) * 100 ELSE IL.[Sales VAT Base Amount (LCY)] END [VAT Base Amount]
	       , IL.[Sales VAT Rate] [VAT Rate]
	       , CASE WHEN IL.[Sales VAT Amount]<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' THEN IL.[Sales VAT Rate]*CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) ELSE IL.[Sales VAT Amount (LCY)]  END [VAT Amount]
	       , CASE WHEN IL.[Sales VAT Amount]<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' THEN CC.[Gross Amount (BC)] ELSE IL.[Sales VAT Base Amount (LCY)] END [Hotel Amount]
  		   , IP.[Invoice No_]       [Hotel Invoice No_]
           , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , CL.[Posting Date]      [Cust_ Posting Date]
		   --, (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] [Currency Factor]
		   ,CASE WHEN CC.[Gross Amount (BC)] > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END [Currency Factor]
		   , IP.[Invoice GUID]
        FROM [HRS PaySol$Sales Invoice Header] SH
		JOIN [HRS PaySol$Paym_ Solution Invoice]      IP WITH (NOLOCK) ON 1=1
        JOIN [HRS PaySol$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
	    JOIN [HRS PaySol$Cust_ CC Invoice Line] CC WITH (NOLOCK)
  	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
	     AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]
		 AND CC.[Document No_]                       = SH.[Pre-Assigned No_]
	    JOIN [HRS PaySol$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	      ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	    JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	      ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	   WHERE IP.[Invoice No_] <> '2115I0075986'
  	     AND IP.[Cancel] = 0
		 AND (SH.[Pre-Assigned No_] = @ReNr OR SH.[No_] = @ReNr)
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
	     , ROW_NUMBER() OVER(PARTITION BY INV.[Process No_] ORDER BY INV.[Process No_]) [Invoice Position]
	     , [Cust_ Posting Date]
		 , INV.[Hotel No_]
		 , INV.[Hotel Name]
		 , INV.[Hotel City]
		 , INV.[Hotel Address]
		 , INV.[Hotel VAT No_]
		 , INV.[Sell-to Customer Name]
		 , INV.[Sell-to Address]
		 , [Hotel Invoice No_]
	     , INV.[Process No_]
		 , INV.Guest
		 , INV.[Reservation Date]
		 , INV.[Arrival Date]
		 , INV.[Departure Date]
		 , IPL.[VAT Base Amount]
		 , IPL.[Currency Code]
		 , IPL.[Service Code]
		 , IPL.[Service Description]
		 , IPL.[VAT Rate]
		 , IPL.[VAT Amount]
		 , IPL.[Hotel Amount]	
		 , INV.[EMail New]
		 , INV.DBI_PK
		 , INV.DBI_KS
		 , INV.DBI_AK
		 , INV.DBI_RZ
		 , INV.DBI_DS
		 , INV.DBI_AU
		 , INV.DBI_AE
		 , INV.DBI_PR
		 , INV.DBI_BD
		 , INV.DBI_IK 
		 , INV.[Invoice No_]
      FROM INV
 LEFT JOIN IPL 
        ON IPL.[Process No_]               = INV.[Process No_]
	   AND IPL.[Invoice GUID]              = INV.[Invoice No_]
 LEFT JOIN CC
        ON CC.[Process No_]                 = INV.[Process No_]
  END
END


GO
