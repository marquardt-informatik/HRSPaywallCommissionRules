USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingInvoiceTax_LCY]    Script Date: 10.04.2024 14:31:47 ******/
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
-- 27.11.17                  RPR    Copy of [sp_RPCentralBillingInvoiceLine]. Here are all values in LCY -> EURO
-- 
-- 
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '50915876'
EXEC [dbo].[sp_RPCentralBillingInvoiceTax_LCY] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingInvoiceTax_LCY] 
    @ReNr varchar(36)
AS
BEGIN
  DECLARE @ProcessNo int

  SELECT @ProcessNo = CASE WHEN ISNUMERIC(@ReNr)=0 THEN 0 ELSE CAST(@ReNr AS INT) END
	
	IF LEN(@ReNr)=36 
	BEGIN
    ;WITH IP AS
    (
      SELECT IP.[Process No_]
	       , IP.[Invoice GUID]
           , SUM(IL.[VAT Base Amount (LCY)]) [VAT Base Amount] --RPR SUM(IL.[VAT Base Amount]) [VAT Base Amount]
           , IL.[VAT Rate]
           , SUM(IL.[VAT Amount (LCY)])      [VAT Amount] --RPR SUM(IL.[VAT Amount])      [VAT Amount]
           , SUM(IL.[Amount (LCY)])          [Amount] --RPR SUM(IL.[Amount])          [Amount]
           , 'EUR' [Currency Code] --RPR CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
    GROUP BY IP.[Process No_]
	       , IP.[Invoice GUID]
           , IL.[VAT Rate]
           --RPR , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END
       UNION
       
      SELECT IP.[Process No_]
	       , IP.[Invoice GUID]
           , SUM(IL.[VAT Base Amount (LCY)]) [VAT Base Amount] --RPR SUM(IL.[VAT Base Amount]) [VAT Base Amount]
           , IL.[VAT Rate]
           , SUM(IL.[VAT Amount (LCY)])      [VAT Amount] --RPR SUM(IL.[VAT Amount])      [VAT Amount]
           , SUM(IL.[Amount (LCY)])          [Amount] --RPR SUM(IL.[Amount])          [Amount]
           , 'EUR' [Currency Code] --RPR CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
    GROUP BY IP.[Process No_]
	       , IP.[Invoice GUID]
           , IL.[VAT Rate]
           --RPR , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END
    )
      SELECT ROW_NUMBER() OVER(ORDER BY IP.[Process No_],IP.[Currency Code], IP.[VAT Rate]) [Row Number]
           , IP.*
        FROM IP
       WHERE IP.[Invoice GUID] = @ReNr
	END
	ELSE
	BEGIN
    ;WITH IP AS
    (
      SELECT IP.[Process No_]
           , SUM(IL.[VAT Base Amount (LCY)]) [VAT Base Amount] --RPR SUM(IL.[VAT Base Amount]) [VAT Base Amount]
           , IL.[VAT Rate]
           , SUM(IL.[VAT Amount (LCY)])      [VAT Amount] --RPR SUM(IL.[VAT Amount])      [VAT Amount]
           , SUM(IL.[Amount (LCY)])          [Amount] --RPR SUM(IL.[Amount])          [Amount]
           , 'EUR' [Currency Code] --RPR CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
    GROUP BY IP.[Process No_]
           , IL.[VAT Rate]
           --RPR , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END
       UNION
       
      SELECT IP.[Process No_]
           , SUM(IL.[VAT Base Amount (LCY)]) [VAT Base Amount] --RPR SUM(IL.[VAT Base Amount]) [VAT Base Amount]
           , IL.[VAT Rate]
           , SUM(IL.[VAT Amount (LCY)])      [VAT Amount] --RPR SUM(IL.[VAT Amount])      [VAT Amount]
           , SUM(IL.[Amount (LCY)])          [Amount] --RPR SUM(IL.[Amount])          [Amount]
           , 'EUR' [Currency Code] --RPR CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END [Currency Code]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
    GROUP BY IP.[Process No_]
           , IL.[VAT Rate]
           --RPR , CASE WHEN IL.[Currency Code]='' THEN 'EUR' ELSE IL.[Currency Code] END
    )
      SELECT ROW_NUMBER() OVER(ORDER BY IP.[Process No_],IP.[Currency Code], IP.[VAT Rate]) [Row Number]
           , IP.*
        FROM IP
       WHERE IP.[Process No_] = @ProcessNo
  END
END

GO
