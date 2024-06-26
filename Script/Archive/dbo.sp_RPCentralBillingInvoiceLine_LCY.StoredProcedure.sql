USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingInvoiceLine_LCY]    Script Date: 10.04.2024 14:31:47 ******/
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
-- 27.11.17 HRS001           RPR    Copy of [sp_RPCentralBillingInvoiceLine]. Here are all values in LCY -> EURO
-- 30.11.17 HRS002  ACS-133  RPR    UNION shows not all lines. Maybe "UNION ALL" OR a unique field -> [Invoice Position GUID] only for [IP]
-- 13.04.18 HRS003  ACS-481  DJU    Fields added
-- ------------------------------------------------------------
-- 
-- 
-- 
-- 
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '98880360'
EXEC [dbo].[sp_RPCentralBillingInvoiceLine_LCY] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingInvoiceLine_LCY] 
    @ReNr varchar(36)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @ProcessNo int

  SELECT @ProcessNo = CASE WHEN ISNUMERIC(@ReNr)=0 THEN 0 ELSE CAST(@ReNr AS INT) END
	
	IF LEN(@ReNr)=36 
	BEGIN
    ;WITH _IH AS
	(
	  SELECT IP.[Process No_]
	       , IP.[Invoice No_]
		   , IP.[Invoice GUID]
	    FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
       WHERE IP.[Invoice GUID] = @ReNr
       UNION
	  SELECT IP.[Process No_]
	       , IP.[Invoice No_]
		   , IP.[Invoice GUID]
	    FROM [HRS Payment$Paym_ Solution Invoice]       IP WITH (NOLOCK)
       WHERE IP.[Invoice GUID] = @ReNr
	), IH AS
	(
	  SELECT _IH.[Invoice GUID], COUNT(1) [Invoices] FROM _IH GROUP BY _IH.[Invoice GUID]
	), IP AS
    (
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
           , IL.[VAT Base Amount (LCY)] [VAT Base Amount]--RPR HRS001 IL.[VAT Base Amount]
           , IL.[VAT Rate]
           , IL.[VAT Amount (LCY)] [VAT Amount]--RPR HRS001 IL.[VAT Amount]
           , IL.[Amount (LCY)] [Amount]--RPR HRS001 IL.[Amount]
		   --HRS003 >>
		   , IL.[Cust_ VAT Bus_ Posting Group]
		   , IL.[Cust_ VAT Prod_ Posting Group]
		   --HRS003 <<
		   , IP.[Invoice No_]
		   , IP.[Invoice GUID]
           , 'EUR' [Currency Code] --RPR HRS001 CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , IH.Invoices
		   , IL.[Invoice Position GUID]	--RPR HRS002
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
        JOIN IH ON IH.[Invoice GUID] = IP.[Invoice GUID]

       UNION
       
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
           , IL.[VAT Base Amount (LCY)] [VAT Base Amount]--RPR HRS001 IL.[VAT Base Amount]
           , IL.[VAT Rate]
           , IL.[VAT Amount (LCY)] [VAT Amount]--RPR HRS001 IL.[VAT Amount]
           , IL.[Amount (LCY)] [Amount]--RPR HRS001 IL.[Amount]
		   --HRS003 >>
		   , IL.[Cust_ VAT Bus_ Posting Group]
		   , IL.[Cust_ VAT Prod_ Posting Group]
		   --HRS003 <<
		   , IP.[Invoice No_]
		   , IP.[Invoice GUID]
           , 'EUR' [Currency Code] --RPR HRS001 CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , IH.Invoices
		   , IL.[Invoice Position GUID]	--RPR HRS002
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
        JOIN IH ON IH.[Invoice GUID] = IP.[Invoice GUID]
    )
      SELECT ROW_NUMBER() OVER(ORDER BY IP.[Process No_],IP.[Service Date],IP.[Amount] DESC) [Row Number]
           , IP.*
        FROM IP
       WHERE IP.[Invoice GUID] = @ReNr
	END
	ELSE
	BEGIN
    -- Insert statements for procedure here
    ;WITH _IH AS
	(
	  SELECT IP.[Process No_]
	       , IP.[Invoice No_]
	    FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
       WHERE IP.[Process No_] = @ReNr
       UNION
	  SELECT IP.[Process No_]
	       , IP.[Invoice No_]
	    FROM [HRS Payment$Paym_ Solution Invoice]       IP WITH (NOLOCK)
       WHERE IP.[Process No_] = @ReNr
	), IH AS
	(
	  SELECT _IH.[Process No_], COUNT(1) [Invoices] FROM _IH GROUP BY _IH.[Process No_]
	), IP AS
    (
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
           , IL.[VAT Base Amount (LCY)] [VAT Base Amount]--RPR IL.[VAT Base Amount]
           , IL.[VAT Rate]
           , IL.[VAT Amount (LCY)] [VAT Amount]--RPR HRS001 IL.[VAT Amount]
           , IL.[Amount (LCY)] [Amount]--RPR HRS001 IL.[Amount]
		   --HRS003 >>
		   , IL.[Cust_ VAT Bus_ Posting Group]
		   , IL.[Cust_ VAT Prod_ Posting Group]
		   --HRS003 <<
		   , IP.[Invoice No_]
           , 'EUR' [Currency Code] --RPR HRS001 CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , IH.Invoices
		   , IL.[Invoice Position GUID]	--RPR HRS002
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
        JOIN IH ON IH.[Process No_] = IP.[Process No_]

       UNION
       
      SELECT IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
           , IL.[VAT Base Amount (LCY)] [VAT Base Amount]--RPR HRS001 IL.[VAT Base Amount]
           , IL.[VAT Rate]
           , IL.[VAT Amount (LCY)] [VAT Amount]--RPR HRS001 IL.[VAT Amount]
           , IL.[Amount (LCY)] [Amount]--RPR HRS001 IL.[Amount]
		   --HRS003 >>
		   , IL.[Cust_ VAT Bus_ Posting Group]
		   , IL.[Cust_ VAT Prod_ Posting Group]
		   --HRS003 <<
		   , IP.[Invoice No_]
           , 'EUR' [Currency Code] --RPR HRS001 CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
		   , IH.Invoices
		   , IL.[Invoice Position GUID]	--RPR HRS002
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
        JOIN IH ON IH.[Process No_] = IP.[Process No_]
    )
      SELECT ROW_NUMBER() OVER(ORDER BY IP.[Process No_],IP.[Service Date],IP.[Amount] DESC) [Row Number]
           -->>HRS002, IP.*
		   , [IP].[Process No_]
		   , [IP].[Service Date]
		   , [IP].[Service Code]
		   , [IP].[Service Description]
		   , [IP].[VAT Base Amount]
		   , [IP].[VAT Rate]
		   , [IP].[VAT Amount]
		   , [IP].[Amount]
		   , [IP].[Invoice No_]
		   , [IP].[Currency Code]
		   , [IP].[Invoices]
		   	--HRS003 >>
		   , [IP].[Cust_ VAT Bus_ Posting Group]
		   , [IP].[Cust_ VAT Prod_ Posting Group]
		   --HRS003 <<
		   --<<HRS002
        FROM IP
       WHERE IP.[Process No_] = @ProcessNo
  END
END
									
GO
