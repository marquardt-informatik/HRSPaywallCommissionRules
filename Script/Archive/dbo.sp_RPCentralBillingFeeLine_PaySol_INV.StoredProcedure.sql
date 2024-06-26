USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeLine_PaySol_INV]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 10.01.23
-- Description:	Attachment of Collective Central Billing Invoice
--
-- Example :
-- IF OBJECT_ID(N'tempdb..#INV') IS NOT NULL
--    DROP TABLE #INV
--   CREATE TABLE #INV ([No_] varchar(20), [Sell-to Customer No_] varchar(20), [Sell-to Customer Name] varchar(200), [Sell-to Address] varchar(200), VAT dec(38,20), Amount dec(38,20), Mwst dec(38,20), Total dec(38,20), [Language Code] varchar(10), [Process No_] int, [Hotel No_] int, [Vendor No_] varchar(20), [Customer No_] varchar(20), [Arrival Date] date, [Departure Date] date, [Hotel Name] varchar(200), [Hotel Address] varchar(200), [Hotel VAT No_] varchar(50), [Country] varchar(50), [Guest] varchar(200), [EMail New] varchar(200), [Hotel City] varchar(100), DBI_PK varchar(100), DBI_KS varchar(100), DBI_AK varchar(100), DBI_RZ varchar(100), DBI_DS varchar(100), DBI_AU varchar(100), DBI_AE varchar(100), DBI_PR varchar(100), DBI_BD varchar(100), DBI_IK varchar(100), [Reservation Date] date, [Customer Posting Group] varchar(10), [Invoice GUID] varchar(36), [Invoice Position GUID] varchar(36), [Service Date] date, [Service Code] varchar(10), [Service Description] varchar(50), [VAT Rate] dec(38,20), [VAT Base Amount (LCY)] dec(38,20), [VAT Amount (LCY)] dec(38,20), [Hotel Amount (LCY)] dec(38,20), [VAT Base Amount (FCY)] dec(38,20), [VAT Amount (FCY)] dec(38,20), [Hotel Amount (FCY)] dec(38,20), [Hotel Invoice No_] varchar(100), [Cust_ Posting Date] date, [Vendor Posting Date] date, [Currency Code] varchar(10), [Currency Factor] dec(38,20), [UATP Card Number] varchar(20), [UATP Card Valid Until] varchar(5), [UATP Card Holder] varchar(200), PAYMENT_CONFIGURATION_ID varchar(36))
--
-- INSERT INTO #INV
-- EXEC [dbo].[sp_RPCentralBillingFeeLine_PaySol_INV] 'R000005627'

-- Datum    Version     RFC       Sign.  Beschreibung
-- ------------------------------------------------------------------
-- 10.01.23 HRS001      ACS-4182  TMA    Common usable performant Query replaces parts of sp_RPCentralBillingFeeLine_PaySol_Breakfast, sp_RPCentralBillingFeeLine_PaySol_Lines, sp_RPCentralBillingFeeLine_PaySol_Siemens
/*
EXEC [dbo].[sp_RPCentralBillingFeeLine_PaySol_INV] 'R000005627'
*/
-- ============================================= 

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeLine_PaySol_INV] 
    @ReNr varchar(25)
AS
BEGIN
IF OBJECT_ID(N'tempdb..#RC') IS NOT NULL
    DROP TABLE #RC
CREATE TABLE #RC ([Process No_] int primary key, VAT_Amount dec(38,20))
INSERT INTO #RC
      SELECT INV.[Process No_]
	       , SUM(IL.[Sales VAT Amount]) VAT_Amount
	    FROM [HRS PaySol$Paym_ Solution Invoice]      INV WITH (NOLOCK)
        JOIN [HRS PaySol$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID]                       = INV.[Invoice GUID]
		JOIN [HRS PaySol$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
	  	 AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]	    
	WHERE CC.[Document No_] = @ReNr
	GROUP BY INV.[Process No_]

IF OBJECT_ID(N'tempdb..#BP') IS NOT NULL
    DROP TABLE #BP
CREATE TABLE #BP ([Process No_] int primary key, [B_KEY] int, [Guest] varchar(120), [Company No_] int, [Hotel No_] int, [Arrival Date] date, [Departure Date] date, [Reservation Date] date, [EMail New] varchar(150), DBI_PK varchar(250), DBI_KS varchar(250), DBI_AK varchar(250), DBI_RZ varchar(250), DBI_DS varchar(250), DBI_AU varchar(250), DBI_AE varchar(250), DBI_PR varchar(250), DBI_BD varchar(250), DBI_IK varchar(250), [UATP Card Number] varchar(20), [UATP Card Valid Until] varchar(5), [UATP Card Holder] varchar(200), PAYMENT_CONFIGURATION_ID varchar(36))

INSERT INTO #BP ([Process No_],[B_KEY],[Guest],[Company No_],[Hotel No_],[Arrival Date],[Departure Date],[Reservation Date],[EMail New]) 
     SELECT [Process No_] 
          , MAX(BU.B_KEY) [B_KEY]
          , MAX(BU.B_GAST1) [Guest]
          , MAX(BU.K_KEY) [Company No_]
          , MAX(BU.H_KEY) [Hotel No_]
          , MIN(BU.B_AN_DATUM) [Arrival Date]
          , MAX(BU.B_AB_DATUM) [Departure Date]
		  , MAX(BU.B_DATUM) [Reservation Date]
		  , MAX(BU.B_EMAIL_NEW) [EMail New]
       FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
       JOIN #RC BP WITH (NOLOCK) ON BP.[Process No_]=BU.BP_KEY
   GROUP BY [Process No_]

   ;WITH BA AS
   (
      SELECT BP.[Process No_]
           , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_PK' THEN D.BCDT_VALUE ELSE '' END)  DBI_PK
           , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_KS' THEN D.BCDT_VALUE ELSE '' END)  DBI_KS
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_AK' THEN D.BCDT_VALUE ELSE '' END)  DBI_AK
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_RZ' THEN D.BCDT_VALUE ELSE '' END)  DBI_RZ
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_DS' THEN D.BCDT_VALUE ELSE '' END)  DBI_DS
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_AU' THEN D.BCDT_VALUE ELSE '' END)  DBI_AU
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_AE' THEN D.BCDT_VALUE ELSE '' END)  DBI_AE
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_PR' THEN D.BCDT_VALUE ELSE '' END)  DBI_PR
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_BD' THEN D.BCDT_VALUE ELSE '' END)  DBI_BD
		   , MAX(CASE WHEN BA.[ATTRIBUTE_NAME] = 'DBI_IK' THEN D.BCDT_VALUE ELSE '' END)  DBI_IK
           , MIN(CC.UATP_CARD_NUMBER)                                  [UATP Card Number]
           , MIN(CC.UATP_CARD_VALID_UNTIL)                             [UATP Card Valid Until]
           , MIN(CC.UATP_CARD_HOLDER)                                  [UATP Card Holder]
           , MIN(CI.PAYMENT_CONFIGURATION_ID) PAYMENT_CONFIGURATION_ID
        FROM HRSDB.BKG_CI_DATA_TEXT_DA D WITH (NOLOCK)
        JOIN #BP BP ON BP.B_KEY=D.B_KEY
        JOIN HRSDB.CUS_CI_CUSTOM_BOOKING_ATTRIBUTE BA WITH (NOLOCK) ON BA.ATTRIBUTE_NUMBER=D.BP_GROUP_ID
   LEFT JOIN HRSDB.BKG_CI_DATA_DA CI WITH (NOLOCK) ON CI.B_KEY = BP.B_KEY
   LEFT JOIN HRSDB.CUS_CI_PAYMENT_CONFIGURATION CC WITH (NOLOCK) ON CC.ID_VALUE = CI.PAYMENT_CONFIGURATION_ID
    GROUP BY BP.[Process No_]
    )
    UPDATE BP SET
           BP.DBI_PK=BA.DBI_PK
         , BP.DBI_KS=BA.DBI_KS
         , BP.DBI_AK=BA.DBI_AK
         , BP.DBI_RZ=BA.DBI_RZ
         , BP.DBI_DS=BA.DBI_DS
         , BP.DBI_AU=BA.DBI_AU
         , BP.DBI_AE=BA.DBI_AE
         , BP.DBI_PR=BA.DBI_PR
         , BP.DBI_BD=BA.DBI_BD
         , BP.DBI_IK=BA.DBI_IK
         , BP.[UATP Card Holder]=BA.[UATP Card Holder]
         , BP.[UATP Card Number]=BA.[UATP Card Number]
         , BP.[UATP Card Valid Until]=BA.[UATP Card Valid Until]
         , BP.PAYMENT_CONFIGURATION_ID=BA.PAYMENT_CONFIGURATION_ID
      FROM #BP BP
      JOIN BA ON BA.[Process No_]=BP.[Process No_]

    ;WITH IP AS
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
		   , CO.[Address] + ' ' + CO.[Address 2] [Hotel Address]
		   , CU.[VAT Registration No_] [Hotel VAT No_]
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
           , BU.[UATP Card Holder]
           , BU.[UATP Card Number]
           , BU.[UATP Card Valid Until]
           , BU.PAYMENT_CONFIGURATION_ID
        FROM [HRS PaySol$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN #BP BU ON BU.[Process No_] = IP.[Process No_]
        JOIN [HRS PaySol$Paym_ Cust _ Vend Assignment] VA WITH (NOLOCK)
          ON VA.[Company No_] = BU.[Company No_]
        JOIN [HRS$Contact]                              CO WITH (NOLOCK)
          ON CO.[No_] = BU.[Hotel No_]
		JOIN [HRS$Customer]								CU WITH (NOLOCK)
		  ON CO.[No_] = CU.[No_]
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
         --, IP.[Currency Code]
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
		 , CU.[Customer Posting Group]	-- 11.06.19 SAL
         , SL.[Description]
         , SL.[Description 2]

         , IL.[Service Date]
         , IL.[Service Code]
         , CASE IL.[Service Code] 
             WHEN 'BRE' THEN 'Breakfast'
             WHEN 'FAB' THEN 'F&B'
             WHEN 'LOG' THEN 'Logis'
             WHEN 'LTA' THEN 'Local Tax/Fee'
             WHEN 'NOS' THEN 'NoShow'
             WHEN 'PAR' THEN 'Parking'
             ELSE 'Miscellaneous'
           END [Service Description]
	     , IL.[Sales VAT Rate] [VAT Rate]
	     , IL.[Sales VAT Base Amount (LCY)] [VAT Base Amount (LCY)]
	     , IL.[Sales VAT Amount (LCY)]  [VAT Amount (LCY)]
	     , IL.[Sales VAT Base Amount (LCY)]+[Sales VAT Amount (LCY)] [Hotel Amount (LCY)]
	     , IL.[Sales VAT Base Amount] [VAT Base Amount (FCY)]
	     , IL.[Sales VAT Amount]  [VAT Amount (FCY)]
  		 , IL.[Sales VAT Base Amount]+[Sales VAT Amount] [Hotel Amount (FCY)]	-- 11.06.2019 SAL
		 , I2.[Invoice No_]       [Hotel Invoice No_]
         --, CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , I2.[Vendor Posting Date]
		 --, CASE WHEN CC.[Gross Amount (BC)] > 0 THEN CASE WHEN ((CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)]) > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END ELSE 1 END [Currency Factor]
         , I2.[Currency Code]
         , I2.[Currency Factor]
         , IP.[UATP Card Holder]
         , IP.[UATP Card Number]
         , IP.[UATP Card Valid Until]
         , IP.PAYMENT_CONFIGURATION_ID
      FROM [HRS PaySol$Sales Header]                SH WITH (NOLOCK)
      JOIN [HRS PaySol$Customer]                    CU WITH (NOLOCK) ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS PaySol$Country_Region]              CO WITH (NOLOCK) ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS PaySol$Sales Line]                  SL WITH (NOLOCK) ON SH.No_ = SL.[Document No_] 
      JOIN IP                                                        ON IP.[Process No_] = SL.[Reservation No_]
      JOIN [HRS PaySol$Paym_ Solution Invoice Line] IL WITH (NOLOCK) ON IL.[Invoice GUID] = SL.[Description] AND IL.[Invoice Position GUID]= SL.[Description 2]
      JOIN [HRS PaySol$Paym_ Solution Invoice]      I2 WITH (NOLOCK) ON I2.[Invoice GUID] = IL.[Invoice GUID]
      JOIN #RC                                      RC               ON RC.[Process No_] = IP.[Process No_]
      JOIN [HRS PaySol$Cust_ CC Invoice Line]       CC WITH (NOLOCK) ON CC.[Invoice GUID] = IL.[Invoice GUID] AND CC.[Invoice Position GUID] = IL.[Invoice Position GUID] AND CC.[Document No_] = SH.[No_]
      JOIN [HRS PaySol$Cust_ Ledger Entry]          CL WITH (NOLOCK) ON CL.[Entry No_] = I2.[Cust_ Ledger Entry No_]
     WHERE (SH.No_ = @ReNr)
     UNION
    SELECT DISTINCT SH.[No_]
         , SH.[Sell-to Customer No_]
		 , SH.[Sell-to Customer Name] + ' ' + SH.[Sell-to Customer Name 2] [Sell-to Customer Name]
		 , SH.[Sell-to Address] + ' ' + SH.[Sell-to Address 2] [Sell-to Address]
         , SL.[VAT %]                  AS VAT
         , SL.[Amount] AS Amount
         , SL.[Amount Including VAT] - SL.[Amount] AS Mwst
         , SL.[Amount Including VAT]   AS Total
         , CASE WHEN SH.[Language Code]='' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , IP.[Process No_]
         , IP.[Hotel No_]
         --, IP.[Currency Code]
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
		 , CU.[Customer Posting Group]	-- 11.06.19 SAL
         , SL.[Description]
         , SL.[Description 2]

         , IL.[Service Date]
         , IL.[Service Code]
         , CASE IL.[Service Code] 
             WHEN 'BRE' THEN 'Breakfast'
             WHEN 'FAB' THEN 'F&B'
             WHEN 'LOG' THEN 'Logis'
             WHEN 'LTA' THEN 'Local Tax/Fee'
             WHEN 'NOS' THEN 'NoShow'
             WHEN 'PAR' THEN 'Parking'
             ELSE 'Miscellaneous'
           END [Service Description]
	     , IL.[Sales VAT Rate] [VAT Rate]
	     , IL.[Sales VAT Base Amount (LCY)] [VAT Base Amount (LCY)]
	     , IL.[Sales VAT Amount (LCY)]  [VAT Amount (LCY)]
	     , IL.[Sales VAT Base Amount (LCY)]+[Sales VAT Amount (LCY)] [Hotel Amount (LCY)]
	     , IL.[Sales VAT Base Amount] [VAT Base Amount (FCY)]
	     , IL.[Sales VAT Amount]  [VAT Amount (FCY)]
  		 , IL.[Sales VAT Base Amount]+[Sales VAT Amount] [Hotel Amount (FCY)]	-- 11.06.2019 SAL
		 , I2.[Invoice No_]       [Hotel Invoice No_]
         --, CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , I2.[Vendor Posting Date]
		 --, CASE WHEN CC.[Gross Amount (BC)] > 0 THEN CASE WHEN ((CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)]) > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END ELSE 1 END [Currency Factor]
         , I2.[Currency Code]
         , I2.[Currency Factor]
         , IP.[UATP Card Holder]
         , IP.[UATP Card Number]
         , IP.[UATP Card Valid Until]
         , IP.PAYMENT_CONFIGURATION_ID
      FROM [HRS PaySol$Sales Invoice Header]                SH WITH (NOLOCK)
      JOIN [HRS PaySol$Customer]                    CU WITH (NOLOCK) ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [HRS PaySol$Country_Region]              CO WITH (NOLOCK) ON CASE WHEN SH.[Bill-to Country_Region Code] = '0' THEN '33' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [HRS PaySol$Sales Invoice Line]          SL WITH (NOLOCK) ON SH.No_ = SL.[Document No_] 
      JOIN IP                                                        ON IP.[Process No_] = SL.[Reservation No_]
      JOIN [HRS PaySol$Paym_ Solution Invoice Line] IL WITH (NOLOCK) ON IL.[Invoice GUID] = SL.[Description] AND IL.[Invoice Position GUID]= SL.[Description 2]
      JOIN [HRS PaySol$Paym_ Solution Invoice]      I2 WITH (NOLOCK) ON I2.[Invoice GUID] = IL.[Invoice GUID]
      JOIN #RC                                      RC               ON RC.[Process No_] = IP.[Process No_]
      JOIN [HRS PaySol$Cust_ CC Invoice Line]       CC WITH (NOLOCK) ON CC.[Invoice GUID] = IL.[Invoice GUID] AND CC.[Invoice Position GUID] = IL.[Invoice Position GUID] AND CC.[Document No_] = SH.[No_]
      JOIN [HRS PaySol$Cust_ Ledger Entry]          CL WITH (NOLOCK) ON CL.[Entry No_] = I2.[Cust_ Ledger Entry No_]
     WHERE (SH.No_ = @ReNr)
	 )
     SELECT * FROM INV
END
GO
