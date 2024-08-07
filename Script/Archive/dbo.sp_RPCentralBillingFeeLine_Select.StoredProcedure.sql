USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeLine_Select]    Script Date: 10.04.2024 14:31:46 ******/
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
-- 23.07.19 HRS001      ACS-1843  DJU    Created
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'R000004075'
EXEC [dbo].[sp_RPCentralBillingFeeLine_Select] @ReNr
*/
-- ============================================= 52092780

CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeLine_Select] 
    @ReNr varchar(25)
AS
BEGIN
	SET NOCOUNT ON;

	-- get customer
	DECLARE @Cust VARCHAR(20)
    SELECT @Cust = SH.[Sell-to Customer No_]
	FROM [HRS Payment$Sales Header] SH WITH (NOLOCK)
	WHERE SH.No_ = @ReNr

	-- get export format from customer
	DECLARE @ExportFormat VARCHAR(20)
	SELECT @ExportFormat = MAX(CVA.[Coll_ Inv_ Export Format]) 
	FROM [HRS Payment$Paym_ Cust _ Vend Assignment] CVA WITH (NOLOCK)
	WHERE CVA.[Customer No_] = @Cust
	GROUP BY CVA.[Customer No_]

	IF @ExportFormat = '' BEGIN
		SELECT @ExportFormat = MAX([Code])
		FROM [HRS Payment$Paym_ Coll_ Inv_ Export Format] EF WITH (NOLOCK)
		WHERE [Default] = 1
	END
	

	SELECT @ExportFormat [Coll_ Inv_ Export Format]
END


GO
