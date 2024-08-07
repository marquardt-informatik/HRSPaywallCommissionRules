USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeLine_PaySol]    Script Date: 10.04.2024 14:31:46 ******/
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
/*
EXEC [dbo].[sp_RPCentralBillingFeeLine_PaySol] 'R000005627'
*/
-- ============================================= 52092780

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeLine_PaySol] 
    @ReNr varchar(25)
AS
BEGIN
  IF OBJECT_ID(N'tempdb..#INV') IS NOT NULL
    DROP TABLE #INV
  CREATE TABLE #INV ([No_] varchar(20), [Sell-to Customer No_] varchar(20), [Sell-to Customer Name] varchar(200), [Sell-to Address] varchar(200), VAT dec(38,20), Amount dec(38,20), Mwst dec(38,20), Total dec(38,20), [Language Code] varchar(10), [Process No_] int, [Hotel No_] int, [Vendor No_] varchar(20), [Customer No_] varchar(20), [Arrival Date] date, [Departure Date] date, [Hotel Name] varchar(200), [Hotel Address] varchar(200), [Hotel VAT No_] varchar(50), [Country] varchar(50), [Guest] varchar(200), [EMail New] varchar(200), [Hotel City] varchar(100), DBI_PK varchar(100), DBI_KS varchar(100), DBI_AK varchar(100), DBI_RZ varchar(100), DBI_DS varchar(100), DBI_AU varchar(100), DBI_AE varchar(100), DBI_PR varchar(100), DBI_BD varchar(100), DBI_IK varchar(100), [Reservation Date] date, [Customer Posting Group] varchar(10), [Invoice GUID] varchar(36), [Invoice Position GUID] varchar(36), [Service Date] date, [Service Code] varchar(10), [Service Description] varchar(50), [VAT Rate] dec(38,20), [VAT Base Amount (LCY)] dec(38,20), [VAT Amount (LCY)] dec(38,20), [Hotel Amount (LCY)] dec(38,20), [VAT Base Amount (FCY)] dec(38,20), [VAT Amount (FCY)] dec(38,20), [Hotel Amount (FCY)] dec(38,20), [Hotel Invoice No_] varchar(100), [Cust_ Posting Date] date, [Vendor Posting Date] date, [Currency Code] varchar(10), [Currency Factor] dec(38,20), [UATP Card Number] varchar(20), [UATP Card Valid Until] varchar(5), [UATP Card Holder] varchar(200), PAYMENT_CONFIGURATION_ID varchar(36))

  INSERT INTO #INV
  EXEC [dbo].[sp_RPCentralBillingFeeLine_PaySol_INV] @ReNr

	 ;WITH IPLS AS
	 (
	SELECT [Process No_]
	     , MIN([Hotel Invoice No_]) [Hotel Invoice No_]
         ,MIN([Cust_ Posting Date]) [Cust_ Posting Date]
		 , SUM(CASE WHEN [Service Code] IN ('BRE')                   THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount Breakfast]
		 , MAX(CASE WHEN [Service Code] IN ('BRE')                   THEN [VAT Rate]                           ELSE 0 END) [VAT Rate Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE')                   THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('BRE')                   THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount Breakfast]
		 , SUM(CASE WHEN [Service Code] IN ('FAB')                   THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount F & B]
		 , MAX(CASE WHEN [Service Code] IN ('FAB')                   THEN [VAT Rate]                           ELSE 0 END) [VAT Rate F & B]
		 , SUM(CASE WHEN [Service Code] IN ('FAB')                   THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount F & B]
		 , SUM(CASE WHEN [Service Code] IN ('FAB')                   THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount F & B]
		 , SUM(CASE WHEN [Service Code] IN ('LOG')                   THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount Logis]
		 , MAX(CASE WHEN [Service Code] IN ('LOG')                   THEN [VAT Rate]        ELSE 0 END) [VAT Rate Logis]
		 , SUM(CASE WHEN [Service Code] IN ('LOG')                   THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount Logis]
		 , SUM(CASE WHEN [Service Code] IN ('LOG')                   THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount Logis]
		 , SUM(CASE WHEN [Service Code] IN ('LTA')                   THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount Local Tax]
		 , MAX(CASE WHEN [Service Code] IN ('LTA')                   THEN [VAT Rate]        ELSE 0 END) [VAT Rate Local Tax]
		 , SUM(CASE WHEN [Service Code] IN ('LTA')                   THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount Local Tax]
		 , SUM(CASE WHEN [Service Code] IN ('LTA')                   THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount Local Tax]
		 , SUM(CASE WHEN [Service Code] IN ('NOS')                   THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount NoShow]
		 , MAX(CASE WHEN [Service Code] IN ('NOS')                   THEN [VAT Rate]        ELSE 0 END) [VAT Rate NoShow]
		 , SUM(CASE WHEN [Service Code] IN ('NOS')                   THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount NoShow]
		 , SUM(CASE WHEN [Service Code] IN ('NOS')                   THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount NoShow]
		 , SUM(CASE WHEN [Service Code] IN ('PAR')                   THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount Parking]
		 , MAX(CASE WHEN [Service Code] IN ('PAR')                   THEN [VAT Rate]        ELSE 0 END) [VAT Rate Parking]
		 , SUM(CASE WHEN [Service Code] IN ('PAR')                   THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount Parking]
		 , SUM(CASE WHEN [Service Code] IN ('PAR')                   THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount Parking]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Base Amount (LCY)]  ELSE 0 END) [VAT Base Amount Misc]
		 , MAX(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Rate]        ELSE 0 END) [VAT Rate Misc]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [VAT Amount (LCY)]       ELSE 0 END) [VAT Amount Misc]
		 , SUM(CASE WHEN NOT [Service Code] IN ('BRE','FAB','LOG','LTA','NOS','PAR') THEN [Hotel Amount (LCY)]     ELSE 0 END) [Hotel Amount Misc]
		 , SUM([Hotel Amount (FCY)]) [Hotel Amount (FCY)] -- 11.06.19 SAL
		 , MAX([Vendor Posting Date]) [Hotel Invoice Date]
      FROM #INV IPL
  GROUP BY [Process No_]
	     --, [Hotel Invoice No_]
      --   , [Cust_ Posting Date]
	 ), INV AS
  (
    SELECT DISTINCT 
           [No_]
         , [Sell-to Customer No_]
		 , [Sell-to Customer Name]
		 , [Sell-to Address]
         , VAT
         , Amount
         , Mwst
         , Total
         , [Language Code]
         , [Process No_]
         , [Hotel No_]
         , [Currency Code]
         , [Vendor No_]
         , [Customer No_]
         , [Arrival Date]
         , [Departure Date]
         , [Hotel Name]
		 , [Hotel Address]
		 , [Hotel VAT No_]
         , [Country]
         , [Guest]
		 , [EMail New]
         , [Hotel City]
         , DBI_PK
         , DBI_KS
		 , DBI_AK
		 , DBI_RZ
		 , DBI_DS
		 , DBI_AU
		 , DBI_AE
		 , DBI_PR
		 , DBI_BD
		 , DBI_IK
		 , [Reservation Date]
		 , [Customer Posting Group]	-- 11.06.19 SAL
         , [UATP Card Number]
         , [UATP Card Valid Until]
         , [UATP Card Holder]
         , PAYMENT_CONFIGURATION_ID
      FROM #INV INV
  )
    SELECT ROW_NUMBER() OVER(ORDER BY INV.[Process No_]) [Position]
	     , INV.*
         , IPLS.[Hotel Invoice No_]
         , [UATP Card Number]
         , [UATP Card Valid Until]
         , [UATP Card Holder]
         , PAYMENT_CONFIGURATION_ID
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
		 , IPLS.[Cust_ Posting Date]
		 , IPLS.[Hotel Amount (FCY)] -- 11.06.19 SAL
		 , [Hotel Invoice Date]
      FROM INV
 LEFT JOIN IPLS 
        ON IPLS.[Process No_]               = INV.[Process No_]
  
END


GO
