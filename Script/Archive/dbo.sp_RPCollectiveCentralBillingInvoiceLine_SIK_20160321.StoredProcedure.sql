USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCollectiveCentralBillingInvoiceLine_SIK_20160321]    Script Date: 10.04.2024 14:31:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 13.05.2015
-- Description:	
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
-- 
-- 
-- 
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'R000000353'
EXEC [dbo].[sp_RPCollectiveCentralBillingInvoiceLine] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCollectiveCentralBillingInvoiceLine_SIK_20160321] 
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

    ;WITH BP AS
	(
	SELECT BP.BP_KEY
	     , MAX(BU.B_KEY) B_KEY
      FROM HRSDB.BKG_PROCESS_LIST_ALL_DA      BP WITH (NOLOCK)
      JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
  GROUP BY BP.BP_KEY
	), IP AS
    (
      SELECT IP.[Process No_], IP.[Invoice No_], IP.[Company No_], LE.[Posting Date] [Posting Date], CS.[Service Description], IP.[Hotel No_], IP.[Arrival Date], IP.[Departure Date], HT.[Name] [Hotel Name], HT.[City] [Hotel City], HR.[Name] [Hotel Country], SUBSTRING(LE.[Description], CHARINDEX(' PD',LE.[Description])+1,100) [Customer Posting No_], IL.[Service Date], IL.[Service Code]
	       , IL.[VAT Base Amount] / IP.[Currency Factor] [VAT Base Amount]
		   , IL.[VAT Rate]
	       , IL.[VAT Amount] / IP.[Currency Factor] [VAT Amount]
		   , IL.[Amount]  / IP.[Currency Factor] [Amount]
	       , IL.[VAT Base Amount] [VAT Base Amount Currency]
	       , IL.[VAT Amount] [VAT Amount Currency]
		   , IL.[Amount] [Amount Currency]
		   , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID]                       = IP.[Invoice GUID]
	    JOIN [HRS Payment$Sales Line]                  AL WITH (NOLOCK)
		  ON IP.[Process No_]                        = AL.[Line No_]
	    JOIN [HRS Payment$Sales Header]                AH WITH (NOLOCK)
	      ON AH.[No_]                                = AL.[Document No_]
        JOIN [HRS Payment$Cust_ Ledger Entry]          LE WITH (NOLOCK)
          ON LE.[Entry No_]                          = IP.[Cust_ Ledger Entry No_]
        JOIN [HRS$Contact]                             HT WITH (NOLOCK)
          ON IP.[Hotel No_]                          = HT.[No_] 
        JOIN [HRS$Country_Region]                      HR WITH (NOLOCK)
          ON HT.[Country_Region Code]                = HR.Code
		JOIN [HRS Payment$Paym_ Service Code]          CS WITH (NOLOCK)
		  ON CS.[Service Code] = IL.[Service Code]
		 AND CS.[Company No_]  = IP.[Company No_]
       WHERE (AH.[No_] = @ReNr)
	     AND IP.[Invoice No_] <> '2115I0075986'
		 AND IP.[Cancel] = 0
       UNION ALL
      SELECT IP.[Process No_], IP.[Invoice No_], IP.[Company No_], LE.[Posting Date] [Posting Date], CS.[Service Description], IP.[Hotel No_], IP.[Arrival Date], IP.[Departure Date], HT.[Name] [Hotel Name], HT.[City] [Hotel City], HR.[Name] [Hotel Country], SUBSTRING(LE.[Description], CHARINDEX(' PD',LE.[Description])+1,100) [Customer Posting No_], IL.[Service Date], IL.[Service Code]
	       , IL.[VAT Base Amount] / IP.[Currency Factor] [VAT Base Amount]
		   , IL.[VAT Rate]
	       , IL.[VAT Amount] / IP.[Currency Factor] [VAT Amount]
		   , IL.[Amount]  / IP.[Currency Factor] [Amount]
	       , IL.[VAT Base Amount] [VAT Base Amount Currency]
	       , IL.[VAT Amount] [VAT Amount Currency]
		   , IL.[Amount] [Amount Currency]
		   , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID]                       = IP.[Invoice GUID]
	    JOIN [HRS Payment$Sales Invoice Line]          AL WITH (NOLOCK)
		  ON IP.[Process No_]                        = AL.[Line No_]
	    JOIN [HRS Payment$Sales Invoice Header]        AH WITH (NOLOCK)
	      ON AH.[No_]                                = AL.[Document No_]
        JOIN [HRS Payment$Cust_ Ledger Entry]          LE WITH (NOLOCK)
          ON LE.[Entry No_]                          = IP.[Cust_ Ledger Entry No_]
        JOIN [HRS$Contact]                             HT WITH (READUNCOMMITTED)
          ON IP.[Hotel No_]                          = HT.[No_] 
        JOIN [HRS$Country_Region]                      HR WITH (READUNCOMMITTED)
          ON HT.[Country_Region Code]                = HR.Code
		JOIN [HRS Payment$Paym_ Service Code]          CS WITH (NOLOCK)
		  ON CS.[Service Code] = IL.[Service Code]
		 AND CS.[Company No_]  = IP.[Company No_]
       WHERE (AH.[No_] = @ReNr OR AH.[Pre-Assigned No_] = @ReNr)
	     AND IP.[Invoice No_] <> '2115I0075986'
		 AND IP.[Cancel] = 0
    )
    SELECT ROW_NUMBER() OVER(ORDER BY [Posting Date], IP.[Process No_], IP.[Invoice No_], IP.[Service Date],IP.[Amount] DESC) [Row Number]
	     , DENSE_RANK() OVER(ORDER BY [Posting Date], IP.[Process No_], IP.[Invoice No_]) [Position Number]
         , IP.*
         , BU.B_GAST1                              [Guest 1]
         , BU.B_GAST2                              [Guest 2]
		 , CASE WHEN IP.[Hotel Country]='France' THEN 1 ELSE 0 END [French Hotel]
      FROM IP
      JOIN                                    BP
        ON BP.BP_KEY                        = IP.[Process No_]
      JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
--	 WHERE [Currency Code] = 'EUR'
  ORDER BY [Posting Date]
  END
  IF @Count>0
  BEGIN
    ;WITH BP AS
	(
	SELECT BP.BP_KEY
	     , MAX(BU.B_KEY) B_KEY
      FROM HRSDB.BKG_PROCESS_LIST_ALL_DA      BP WITH (NOLOCK)
      JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
  GROUP BY BP.BP_KEY
	), IP AS
    (
      SELECT IP.[Process No_], IP.[Invoice No_], IP.[Company No_], LE.[Posting Date] [Posting Date], CS.[Service Description], IP.[Hotel No_], IP.[Arrival Date], IP.[Departure Date], HT.[Name] [Hotel Name], HT.[City] [Hotel City], HR.[Name] [Hotel Country], SUBSTRING(LE.[Description], CHARINDEX(' PD',LE.[Description])+1,100) [Customer Posting No_], IL.[Service Date], IL.[Service Code]
	       , CC.[Net Amount (SC)] [VAT Base Amount]
		   , CC.[VAT Rate]
	       , CC.[Tax(SC)] [VAT Amount]
		   , CC.[Net Amount (SC)] + CC.[Tax(SC)] [Amount]
	       , CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Net Amount (SC)] [VAT Base Amount Currency]
	       , CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Tax(SC)] [VAT Amount Currency]
		   , CC.[Gross Amount] [Amount Currency]
		   , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID]                       = IP.[Invoice GUID]
	    JOIN [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
		 AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]
	    JOIN [HRS Payment$Sales Header]                AH WITH (NOLOCK)
	      ON AH.[No_]                                = CC.[Document No_]
        JOIN [HRS Payment$Cust_ Ledger Entry]          LE WITH (NOLOCK)
          ON LE.[Entry No_]                          = IP.[Cust_ Ledger Entry No_]
        JOIN [HRS$Contact]                             HT WITH (NOLOCK)
          ON IP.[Hotel No_]                          = HT.[No_] 
        JOIN [HRS$Country_Region]                      HR WITH (NOLOCK)
          ON HT.[Country_Region Code]                = HR.Code
		JOIN [HRS Payment$Paym_ Service Code]          CS WITH (NOLOCK)
		  ON CS.[Service Code] = IL.[Service Code]
		 AND CS.[Company No_]  = IP.[Company No_]
       WHERE (AH.[No_] = @ReNr)
	     AND IP.[Invoice No_] <> '2115I0075986'
		 AND IP.[Cancel] = 0
       UNION ALL
      SELECT IP.[Process No_], IP.[Invoice No_], IP.[Company No_], LE.[Posting Date] [Posting Date], CS.[Service Description], IP.[Hotel No_], IP.[Arrival Date], IP.[Departure Date], HT.[Name] [Hotel Name], HT.[City] [Hotel City], HR.[Name] [Hotel Country], SUBSTRING(LE.[Description], CHARINDEX(' PD',LE.[Description])+1,100) [Customer Posting No_], IL.[Service Date], IL.[Service Code]
	       , CC.[Net Amount (SC)] [VAT Base Amount]
		   , CC.[VAT Rate]
	       , CC.[Tax(SC)] [VAT Amount]
		   , CC.[Net Amount (SC)] + CC.[Tax(SC)] [Amount]
	       , CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Net Amount (SC)] [VAT Base Amount Currency]
	       , CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Tax(SC)] [VAT Amount Currency]
		   , CC.[Gross Amount] [Amount Currency]
		   , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID]                       = IP.[Invoice GUID]
	    JOIN [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	      ON CC.[Invoice GUID]                       = IL.[Invoice GUID]
		 AND CC.[Invoice Position GUID]              = IL.[Invoice Position GUID]
	    JOIN [HRS Payment$Sales Invoice Header]        AH WITH (NOLOCK)
	      ON AH.[Pre-Assigned No_]                   = CC.[Document No_]
        JOIN [HRS Payment$Cust_ Ledger Entry]          LE WITH (NOLOCK)
          ON LE.[Entry No_]                          = IP.[Cust_ Ledger Entry No_]
        JOIN [HRS$Contact]                             HT WITH (READUNCOMMITTED)
          ON IP.[Hotel No_]                          = HT.[No_] 
        JOIN [HRS$Country_Region]                      HR WITH (READUNCOMMITTED)
          ON HT.[Country_Region Code]                = HR.Code
		JOIN [HRS Payment$Paym_ Service Code]          CS WITH (NOLOCK)
		  ON CS.[Service Code] = IL.[Service Code]
		 AND CS.[Company No_]  = IP.[Company No_]
       WHERE (AH.[No_] = @ReNr OR AH.[Pre-Assigned No_] = @ReNr)
	     AND IP.[Invoice No_] <> '2115I0075986'
		 AND IP.[Cancel] = 0
    )
    SELECT ROW_NUMBER() OVER(ORDER BY [Posting Date], IP.[Process No_], IP.[Invoice No_], IP.[Service Date],IP.[Amount] DESC) [Row Number]
	     , DENSE_RANK() OVER(ORDER BY [Posting Date], IP.[Process No_], IP.[Invoice No_]) [Position Number]
         , IP.*
         , BU.B_GAST1                              [Guest 1]
         , BU.B_GAST2                              [Guest 2]
		 , CASE WHEN IP.[Hotel Country]='France' THEN 1 ELSE 0 END [French Hotel]
      FROM IP
      JOIN                                    BP
        ON BP.BP_KEY                        = IP.[Process No_]
      JOIN HRSDB.BUCHUNG                      BU WITH (NOLOCK)
        ON BU.B_KEY                         = BP.B_KEY 
--	 WHERE [Currency Code] = 'EUR'
  ORDER BY [Posting Date]
  END

  END
GO
