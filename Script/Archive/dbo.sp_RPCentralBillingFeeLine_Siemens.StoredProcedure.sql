USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeLine_Siemens]    Script Date: 10.04.2024 14:31:46 ******/
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
-- 06.06.19             ACS-1823  SAK	 Orange Problematik
-- 11.06.19				ACS-1801  SAL    Additional field for foreign currency amount
-- 01.08.19   HRS008    ACS-1925  DJU    Prevent division by zero
-- 20.08.19   HRS009  INC0023045  SAL    Extend editation from 01.08.19 HRS008
-- 28.04.22   HRS010    ACS-3694  TMA    work with Temp Table to prevent requeries by the Report-Server when using as DataSet
/*
EXEC [dbo].[sp_RPCentralBillingFeeLine_Siemens] 'R000025724'
*/
-- ============================================= 52092780

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeLine_Siemens] 
    @ReNr varchar(25)
AS
BEGIN

-- 28.04.22   HRS010    ACS-3694  TMA +++
IF OBJECT_ID (N'tempdb..#CB') IS NOT NULL
  DROP TABLE #CB
CREATE TABLE #CB (
[Position] bigint,
[No_] varchar(20) NOT NULL,
[Sell-to Customer No_] varchar(20) NOT NULL,
[Sell-to Country_Region Code] varchar(10) NOT NULL,
[Posting Description] varchar(50) NOT NULL,
[Document Date] datetime2(3) NOT NULL,
[VAT] decimal(38,20) NOT NULL,
[Amount] decimal(38,20),
[Mwst] decimal(38,20),
[Total] decimal(38,20) NOT NULL,
[Language Code] varchar(10) NOT NULL,
[Process No_] int NOT NULL,
[Hotel No_] int,
[Currency Code] varchar(10) NOT NULL,
[Vendor No_] int,
[Customer No_] int NOT NULL,
[Arrival Date] date,
[Departure Date] date,
[Hotel Name] varchar(201) NOT NULL,
[Country] varchar(50) NOT NULL,
[Guest] varchar(120),
[EMail New] varchar(150),
[Hotel City] varchar(70) NOT NULL,
[DBI_PK] varchar(2000),
[DBI_KS] varchar(2000),
[DBI_AK] varchar(2000),
[DBI_RZ] varchar(2000),
[DBI_DS] varchar(2000),
[DBI_AU] varchar(2000),
[DBI_AE] varchar(2000),
[DBI_PR] varchar(2000),
[DBI_BD] varchar(2000),
[DBI_IK] varchar(2000),
[Reservation Date] date,
[Customer Posting Group] varchar(10) NOT NULL,
[Hotel Invoice No_] varchar(64),
[UATP Card Number] varchar(20),
[UATP Card Valid Until] varchar(5),
[UATP Card Holder] varchar(200),
[PAYMENT_CONFIGURATION_ID] varchar(36),
[Hotel Invoice] int NOT NULL,
[VAT Base Amount] decimal(38,6),
[VAT Amount] decimal(38,6),
[Hotel Amount] decimal(38,6),
[VAT Base Amount Breakfast] decimal(38,6),
[VAT Rate Breakfast] float,
[VAT Amount Breakfast] decimal(38,6),
[Hotel Amount Breakfast] decimal(38,6),
[VAT Base Amount F & B] decimal(38,6),
[VAT Rate F & B] float,
[VAT Amount F & B] decimal(38,6),
[Hotel Amount F & B] decimal(38,6),
[VAT Base Amount Logis] decimal(38,6),
[VAT Rate Logis] float,
[VAT Amount Logis] decimal(38,6),
[Hotel Amount Logis] decimal(38,6),
[VAT Base Amount Local Tax] decimal(38,6),
[VAT Rate Local Tax] float,
[VAT Amount Local Tax] decimal(38,6),
[Hotel Amount Local Tax] decimal(38,6),
[VAT Base Amount NoShow] decimal(38,6),
[VAT Rate NoShow] float,
[VAT Amount NoShow] decimal(38,6),
[Hotel Amount NoShow] decimal(38,6),
[VAT Base Amount Parking] decimal(38,6),
[VAT Rate Parking] float,
[VAT Amount Parking] decimal(38,6),
[Hotel Amount Parking] decimal(38,6),
[VAT Base Amount Misc] decimal(38,6),
[VAT Rate Misc] float,
[VAT Amount Misc] decimal(38,6),
[Hotel Amount Misc] decimal(38,6),
[Cust_ Posting Date] datetime2(3),
[Hotel Amount (FCY)] decimal(38,6),
[VAT Base Amount (FCY)] decimal(38,12),
[VAT Amount (FCY)] decimal(38,12)
)
-- 28.04.22   HRS010    ACS-3694  TMA ---
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

IF OBJECT_ID (N'tempdb..#DBI') IS NOT NULL
  DROP TABLE #DBI
  CREATE TABLE #DBI ([ATTRIBUTE_NUMBER] int, [ATTRIBUTE_NAME] varchar(20))
  INSERT INTO #DBI
  SELECT [ATTRIBUTE_NUMBER], [ATTRIBUTE_NAME] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] where [ATTRIBUTE_NAME] IN ('DBI_PK','DBI_KS','DBI_AK','DBI_RZ','DBI_DS','DBI_AU','DBI_PR','DBI_BD','DBI_IK')

IF OBJECT_ID (N'tempdb..#RC') IS NOT NULL
  DROP TABLE #RC
CREATE TABLE #RC ([Process No_] int, B_KEY int, VAT_Amount decimal(38,20), primary key (B_KEY))
;WITH RC AS
(
 	SELECT INV.[Process No_]
	     , SUM(IL.[Sales VAT Amount]) VAT_Amount
	  FROM [HRS Payment$Paym_ Solution Invoice]      INV WITH (NOLOCK)
      JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
        ON IL.[Invoice GUID]                       = INV.[Invoice GUID]
      JOIN [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	    ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
	   AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]	          
	 WHERE CC.[Document No_] = @ReNr
  GROUP BY INV.[Process No_]
), BP AS
(
   SELECT BU.BP_KEY
        , MAX(BU.B_KEY) B_KEY
     FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
     JOIN RC ON RC.[Process No_]=BU.BP_KEY
 GROUP BY BU.BP_KEY
)
  INSERT INTO #RC ([Process No_],B_KEY, VAT_Amount)
  SELECT BP.BP_KEY, BP.B_KEY, RC.VAT_Amount
    FROM RC
    JOIN BP ON RC.[Process No_]=BP.BP_KEY

	IF @Count=0
	BEGIN
;WITH BA AS
(
   SELECT RC.[Process No_]
        , RC.B_KEY
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_PK' THEN DA.BCDT_VALUE ELSE '' END) DBI_PK
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_KS' THEN DA.BCDT_VALUE ELSE '' END) DBI_KS
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_AK' THEN DA.BCDT_VALUE ELSE '' END) DBI_AK
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_RZ' THEN DA.BCDT_VALUE ELSE '' END) DBI_RZ
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_DS' THEN DA.BCDT_VALUE ELSE '' END) DBI_DS
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_AU' THEN DA.BCDT_VALUE ELSE '' END) DBI_AU
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_AE' THEN DA.BCDT_VALUE ELSE '' END) DBI_AE
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_PR' THEN DA.BCDT_VALUE ELSE '' END) DBI_PR
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_BD' THEN DA.BCDT_VALUE ELSE '' END) DBI_BD
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_IK' THEN DA.BCDT_VALUE ELSE '' END) DBI_IK
     FROM #RC RC 
LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA DA WITH (NOLOCK) ON RC.B_KEY=DA.B_KEY
LEFT JOIN #DBI DBI ON DBI.ATTRIBUTE_NUMBER=DA.BP_GROUP_ID
 GROUP BY RC.[Process No_]
        , RC.B_KEY
), BU AS
(
   SELECT B.BP_KEY [Process No_]
	    , B.B_KEY [B_KEY]
        , B.B_GAST1 [Guest]
        , B.K_KEY [Company No_]
        , B.H_KEY [Hotel No_]
        , B.B_AN_DATUM [Arrival Date]
	    , B.B_DATUM [Reservation Date]
		, B.B_EMAIL_NEW [EMail New]
        , BA.DBI_PK
        , BA.DBI_KS
        , BA.DBI_AK
        , BA.DBI_RZ
        , BA.DBI_DS
        , BA.DBI_AU
        , BA.DBI_AE
        , BA.DBI_PR
        , BA.DBI_BD
        , BA.DBI_IK
     FROM HRSDB.BUCHUNG B WITH (NOLOCK)
     JOIN BA ON BA.B_KEY=B.B_KEY
),
	IP AS
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
        FROM [HRS Payment$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
		JOIN HRSDB.BUCHUNG BUCHUNG WITH (NOLOCK) ON BUCHUNG.B_KEY = BU.B_KEY
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
		 , SH.[Sell-to Country_Region Code]
		 , SH.[Posting Description]
		 , SH.[Document Date]
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
		 , CU.[Customer Posting Group]	-- 11.06.19 SAL
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
		 , SH.[Sell-to Country_Region Code]
		 , SH.[Posting Description]
		 , SH.[Document Date]
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
		 , CU.[Customer Posting Group]	-- 11.06.19 SAL      
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
		 , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800')  THEN IL.[Sales VAT Base Amount (LCY)] ELSE PP.[AMOUNT_BEFORE_TAX] END [VAT Base Amount]
		 , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Rate] ELSE PP.[TAX_RATE] END [VAT Rate]
	     , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Amount (LCY)] ELSE PP.[TAX_AMOUNT] END [VAT Amount]
		 , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount (LCY)] ELSE PP.[AMOUNT_AFTER_TAX] END [Hotel Amount]
         , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , CASE WHEN IP.[Currency Factor] = 0 THEN 1 ELSE IP.[Currency Factor] END [Currency Factor] -- 20.08.19 SAL HRS009 -- IP.[Currency Factor]
  		 , IL.[Sales VAT Base Amount] [Hotel Amount (FCY)]	-- 11.06.2019 SAL
      FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
      JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	  JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	    ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	  JOIN #RC RC ON RC.[Process No_] = IP.[Process No_]
	 WHERE IP.[Invoice No_] <> '2115I0075986'
     /*
	 UNION ALL
    SELECT IP.[Process No_]
         , IL.[Service Date]
         , IL.[Service Code]
         , IL.[Service Description]
         , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Base Amount (LCY)] ELSE PP.[AMOUNT_BEFORE_TAX] END [VAT Base Amount]
		 , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Rate] ELSE PP.[TAX_RATE] END [VAT Rate]
	     , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Amount (LCY)] ELSE PP.[TAX_AMOUNT] END [VAT Amount]
		 , CASE WHEN RC.VAT_Amount<>0 OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Base Amount (LCY)]+IL.[Sales VAT Amount] ELSE PP.[AMOUNT_AFTER_TAX] END [Hotel Amount]
		 , IP.[Invoice No_]       [Hotel Invoice No_]
         , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		 , CL.[Posting Date]      [Cust_ Posting Date]
		 , CASE WHEN IP.[Currency Factor] = 0 THEN 1 ELSE IP.[Currency Factor] END [Currency Factor] -- 20.08.19 SAL HRS009 -- IP.[Currency Factor]
      FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
      JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
        ON IL.[Invoice GUID] = IP.[Invoice GUID]
	  JOIN [HRS Payment$Cust_ Ledger Entry]                   CL WITH (NOLOCK)
	    ON CL.[Entry No_] = IP.[Cust_ Ledger Entry No_]
	 -- JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	  --  ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
	  JOIN RC ON RC.[Process No_] = IP.[Process No_]
	 WHERE IP.[Invoice No_] <> '2115I0075986'
  	   AND IP.[Cancel] = 0
     */
	 ), IPLS AS
	 (
	SELECT [Process No_]
	     , MIN([Hotel Invoice No_]) [Hotel Invoice No_]
         ,MIN([Cust_ Posting Date]) [Cust_ Posting Date]
		 -- 11.06.19 SAL >>
		 --, SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Breakfast]
		 --, MAX(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Breakfast]
		 --, SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Breakfast]
		 --, SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Breakfast]
		 , MAX(CASE WHEN [Service Code] IN ('BRE') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('FAB') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount F & B]
		 , MAX(CASE WHEN [Service Code] IN ('FAB') THEN [VAT Rate]        ELSE 0 END) [VAT Rate F & B]
		 , SUM(CASE WHEN [Service Code] IN ('FAB') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount F & B]
		 , SUM(CASE WHEN [Service Code] IN ('FAB') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount F & B]
		 -- 11.06.19 SAL <<
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
		 , SUM([VAT Base Amount]) [VAT Base Amount (FCY)]
		 , SUM([VAT Amount]) [VAT Amount (FCY)]
		 , SUM([Hotel Amount (FCY)]) [Hotel Amount (FCY)] -- 11.06.19 SAL
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
     INSERT INTO #CB -- 28.04.22   HRS010    ACS-3694  TMA
    SELECT ROW_NUMBER() OVER(ORDER BY INV.[Process No_]) [Position]
	     , INV.*
         , [Hotel Invoice No_]
         , CC.[UATP Card Number]
         , CC.[UATP Card Valid Until]
         , CC.[UATP Card Holder]
         , CC.PAYMENT_CONFIGURATION_ID
         , CASE WHEN IPLS.[Process No_] IS NULL THEN 0 ELSE 1 END [Hotel Invoice]
		 , [VAT Base Amount Breakfast]
		   + [VAT Base Amount F & B] -- 11.06.19 SAL
		   + [VAT Base Amount Logis]
		   + [VAT Base Amount Local Tax]
  		   + [VAT Base Amount NoShow]
		   + [VAT Base Amount Parking]
		   + [VAT Base Amount Misc] [VAT Base Amount]
		 , [VAT Amount Breakfast]
		   + [VAT Amount F & B] -- 11.06.19 SAL
		   + [VAT Amount Logis]
		   + [VAT Amount Local Tax]
  		   + [VAT Amount NoShow]
		   + [VAT Amount Parking]
		   + [VAT Amount Misc] [VAT Amount]
		 , [Hotel Amount Breakfast]
		   + [Hotel Amount F & B] -- 11.06.19 SAL
		   + [Hotel Amount Logis]
		   + [Hotel Amount Local Tax]
  		   + [Hotel Amount NoShow]
		   + [Hotel Amount Parking]
		   + [Hotel Amount Misc] [Hotel Amount]
		 , [VAT Base Amount Breakfast]
		 , [VAT Rate Breakfast]
		 , [VAT Amount Breakfast]
		 , [Hotel Amount Breakfast]
		 -- 11.06.19 SAL >> 
		 , [VAT Base Amount F & B]
		 , [VAT Rate F & B]
		 , [VAT Amount F & B]
		 , [Hotel Amount F & B]
		 -- 11.06.19 SAL <<
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
		 , IPLS.[Hotel Amount (FCY)] -- 11.06.19 SAL
		 , IPLS.[VAT Base Amount (FCY)]
		 , IPLS.[VAT Amount (FCY)]
      FROM INV
 LEFT JOIN IPLS 
        ON IPLS.[Process No_]               = INV.[Process No_]
 LEFT JOIN CC
        ON CC.[Process No_]                 = INV.[Process No_]
  END

  IF @Count>0
  BEGIN
;WITH BA AS
(
   SELECT RC.[Process No_]
        , RC.B_KEY
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_PK' THEN DA.BCDT_VALUE ELSE '' END) DBI_PK
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_KS' THEN DA.BCDT_VALUE ELSE '' END) DBI_KS
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_AK' THEN DA.BCDT_VALUE ELSE '' END) DBI_AK
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_RZ' THEN DA.BCDT_VALUE ELSE '' END) DBI_RZ
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_DS' THEN DA.BCDT_VALUE ELSE '' END) DBI_DS
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_AU' THEN DA.BCDT_VALUE ELSE '' END) DBI_AU
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_AE' THEN DA.BCDT_VALUE ELSE '' END) DBI_AE
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_PR' THEN DA.BCDT_VALUE ELSE '' END) DBI_PR
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_BD' THEN DA.BCDT_VALUE ELSE '' END) DBI_BD
        , MAX(CASE WHEN COALESCE(DBI.[ATTRIBUTE_NAME],'')='DBI_IK' THEN DA.BCDT_VALUE ELSE '' END) DBI_IK
     FROM #RC RC 
LEFT JOIN HRSDB.BKG_CI_DATA_TEXT_DA DA WITH (NOLOCK) ON RC.B_KEY=DA.B_KEY
LEFT JOIN #DBI DBI ON DBI.ATTRIBUTE_NUMBER=DA.BP_GROUP_ID
 GROUP BY RC.[Process No_]
        , RC.B_KEY
), BU AS
(
   SELECT B.BP_KEY [Process No_]
	    , B.B_KEY [B_KEY]
        , B.B_GAST1 [Guest]
        , B.K_KEY [Company No_]
        , B.H_KEY [Hotel No_]
        , B.B_AN_DATUM [Arrival Date]
	    , B.B_DATUM [Reservation Date]
		, B.B_EMAIL_NEW [EMail New]
        , BA.DBI_PK
        , BA.DBI_KS
        , BA.DBI_AK
        , BA.DBI_RZ
        , BA.DBI_DS
        , BA.DBI_AU
        , BA.DBI_AE
        , BA.DBI_PR
        , BA.DBI_BD
        , BA.DBI_IK
     FROM HRSDB.BUCHUNG B WITH (NOLOCK)
     JOIN BA ON BA.B_KEY=B.B_KEY
), 
	IP AS
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
        FROM [HRS Payment$Paym_ Solution Case]          IP WITH (NOLOCK)
        JOIN BU ON BU.[Process No_] = IP.[Process No_]
		JOIN HRSDB.BUCHUNG BUCHUNG WITH (NOLOCK) ON BUCHUNG.B_KEY = BU.B_KEY
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
		 , SH.[Sell-to Country_Region Code]
		 , SH.[Posting Description]
		 , SH.[Document Date]
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
		 , CU.[Customer Posting Group]	-- 11.06.19 SAL
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
		 , SH.[Sell-to Country_Region Code]
		 , SH.[Posting Description]
		 , SH.[Document Date]
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
		 , CU.[Customer Posting Group]	-- 11.06.19 SAL
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
	       , CASE WHEN RC.VAT_Amount<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' OR IP.[Customer No_] IN ('70998800') THEN CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) * 100 ELSE IL.[Sales VAT Base Amount (LCY)] END [VAT Base Amount]
	       , IL.[Sales VAT Rate] [VAT Rate]
	       , CASE WHEN RC.VAT_Amount<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Rate]*CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) ELSE IL.[Sales VAT Amount (LCY)]  END [VAT Amount]
	       , CASE WHEN RC.VAT_Amount<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' OR IP.[Customer No_] IN ('70998800') THEN CC.[Gross Amount (BC)] ELSE IL.[Sales VAT Base Amount (LCY)] END [Hotel Amount]
  		   , IL.[Sales VAT Base Amount] [Hotel Amount (FCY)]	-- 11.06.2019 SAL
		   , IP.[Invoice No_]       [Hotel Invoice No_]
           , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , CL.[Posting Date]      [Cust_ Posting Date]
		   --, (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] [Currency Factor]
		   -- HRS008 >>
		   --,CASE WHEN CC.[Gross Amount (BC)] > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END [Currency Factor]
		   ,CASE WHEN CC.[Gross Amount (BC)] > 0 
		         THEN CASE WHEN ((CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)]) > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END 
				 ELSE 1 
			END [Currency Factor]
		   -- HRS008 <<
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
	--    JOIN [HRSDB].[CIA_PS_INVOICE_POSITION]          PP WITH (NOLOCK)
	 --     ON PP.[INVOICE_POSITION_ID_VALUE] = LOWER(IL.[Invoice Position GUID])
		JOIN #RC RC ON RC.[Process No_] = IP.[Process No_]
	   WHERE IP.[Invoice No_] <> '2115I0075986'
  	     AND IP.[Cancel] = 0
		 AND SH.[No_] = @ReNr
       UNION ALL
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
	       , CASE WHEN RC.VAT_Amount<>0 OR  SH.[VAT Bus_ Posting Group]='AUSLAND' OR IP.[Customer No_] IN ('70998800') THEN CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) * 100 ELSE IL.[Sales VAT Base Amount (LCY)] END [VAT Base Amount]
	       , IL.[Sales VAT Rate] [VAT Rate]
	       , CASE WHEN RC.VAT_Amount<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' OR IP.[Customer No_] IN ('70998800') THEN IL.[Sales VAT Rate]*CC.[Gross Amount (BC)]/(100+IL.[Sales VAT Rate]) ELSE IL.[Sales VAT Amount (LCY)]  END [VAT Amount]
	       , CASE WHEN RC.VAT_Amount<>0 OR SH.[VAT Bus_ Posting Group]='AUSLAND' OR IP.[Customer No_] IN ('70998800') THEN CC.[Gross Amount (BC)] ELSE IL.[Sales VAT Base Amount (LCY)] END [Hotel Amount]
  		   , IL.[Sales VAT Base Amount] [Hotel Amount (FCY)]	-- 11.06.2019 SAL
		   , IP.[Invoice No_]       [Hotel Invoice No_]
           , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , CL.[Posting Date]      [Cust_ Posting Date]
		   --, (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] [Currency Factor]
		   -- HRS008 >>
		   --,CASE WHEN CC.[Gross Amount (BC)] > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END [Currency Factor]
		   ,CASE WHEN CC.[Gross Amount (BC)] > 0 
		         THEN CASE WHEN ((CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)]) > 0 THEN (CC.[Net Amount (SC)] + CC.[Tax(SC)])/CC.[Gross Amount (BC)] ELSE 1 END 
				 ELSE 1 
			END [Currency Factor]
		   -- HRS008 <<
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
		JOIN #RC RC ON RC.[Process No_] = IP.[Process No_]
	   WHERE IP.[Invoice No_] <> '2115I0075986'
  	     AND IP.[Cancel] = 0
		 AND (SH.[Pre-Assigned No_] = @ReNr OR SH.[No_] = @ReNr)
     ), IPLS AS
	 (
	SELECT [Process No_]
	     , MIN([Hotel Invoice No_]) [Hotel Invoice No_]
         ,MIN([Cust_ Posting Date]) [Cust_ Posting Date]
		 -- 11.06.19 SAL >>
		 --, SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Breakfast]
		 --, MAX(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Breakfast]
		 --, SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Breakfast]
		 --, SUM(CASE WHEN [Service Code] IN ('BRE','FAB') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount Breakfast]
		 , MAX(CASE WHEN [Service Code] IN ('BRE') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('FAB') THEN [VAT Base Amount]/[Currency Factor] ELSE 0 END) [VAT Base Amount F & B]
		 , MAX(CASE WHEN [Service Code] IN ('FAB') THEN [VAT Rate]        ELSE 0 END) [VAT Rate F & B]
		 , SUM(CASE WHEN [Service Code] IN ('FAB') THEN [VAT Amount]/[Currency Factor]      ELSE 0 END) [VAT Amount F & B]
		 , SUM(CASE WHEN [Service Code] IN ('FAB') THEN [Hotel Amount]/[Currency Factor]    ELSE 0 END) [Hotel Amount F & B]
		 -- 11.06.19 SAL <<
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
		 , SUM([Hotel Amount (FCY)]) [Hotel Amount (FCY)] -- 11.06.19 SAL
		 , SUM([VAT Base Amount]) [VAT Base Amount (FCY)]
		 , SUM([VAT Amount]) [VAT Amount (FCY)]
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
     INSERT INTO #CB -- 28.04.22   HRS010    ACS-3694  TMA
    SELECT ROW_NUMBER() OVER(ORDER BY INV.[Process No_]) [Position]
	     , INV.*
         , [Hotel Invoice No_]
         , CC.[UATP Card Number]
         , CC.[UATP Card Valid Until]
         , CC.[UATP Card Holder]
         , CC.PAYMENT_CONFIGURATION_ID
         , CASE WHEN IPLS.[Process No_] IS NULL THEN 0 ELSE 1 END [Hotel Invoice]
		 , [VAT Base Amount Breakfast]
		   + [VAT Base Amount F & B] -- 11.06.19 SAL
		   + [VAT Base Amount Logis]
		   + [VAT Base Amount Local Tax]
  		   + [VAT Base Amount NoShow]
		   + [VAT Base Amount Parking]
		   + [VAT Base Amount Misc] [VAT Base Amount]
		 , [VAT Amount Breakfast]
		   + [VAT Amount F & B] -- 11.06.19 SAL
		   + [VAT Amount Logis]
		   + [VAT Amount Local Tax]
  		   + [VAT Amount NoShow]
		   + [VAT Amount Parking]
		   + [VAT Amount Misc] [VAT Amount]
		 , [Hotel Amount Breakfast]
		   + [Hotel Amount F & B] -- 11.06.19 SAL
		   + [Hotel Amount Logis]
		   + [Hotel Amount Local Tax]
  		   + [Hotel Amount NoShow]
		   + [Hotel Amount Parking]
		   + [Hotel Amount Misc] [Hotel Amount]
		 , [VAT Base Amount Breakfast]
		 , [VAT Rate Breakfast]
		 , [VAT Amount Breakfast]
		 , [Hotel Amount Breakfast]
		 -- 11.06.19 SAL >> 
		 , [VAT Base Amount F & B]
		 , [VAT Rate F & B]
		 , [VAT Amount F & B]
		 , [Hotel Amount F & B]
		 -- 11.06.19 SAL <<
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
		 , IPLS.[Hotel Amount (FCY)] -- 11.06.19 SAL
		 , IPLS.[VAT Base Amount (FCY)]
		 , IPLS.[VAT Amount (FCY)]
      FROM INV
 LEFT JOIN IPLS 
        ON IPLS.[Process No_]               = INV.[Process No_]
 LEFT JOIN CC
        ON CC.[Process No_]                 = INV.[Process No_]
  END

  SELECT * FROM #CB
END
GO
