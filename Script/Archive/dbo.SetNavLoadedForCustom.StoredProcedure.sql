USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SetNavLoadedForCustom]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SetNavLoadedForCustom]  
	-- Add the parameters for the stored procedure here
	@CustomName varchar(50) 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	WITH Loaded AS
(
SELECT [Invoice GUID], [Cust_ Posting Date], [Status]  FROM [HRS Payment$Paym_ Solution Inv_ Imp] 
UNION
SELECT [Invoice GUID], [Cust_ Posting Date], [Status] FROM [HRS Payment$Paym_ Solution Invoice] 
)
   UPDATE IH SET 
          IH.NAV_LOADED 
  = CASE 
      WHEN COALESCE(LD.[Invoice GUID],'') = '' THEN 0
   WHEN (LD.[Status] <> IH.INVOICE_STATUS) THEN 0    
      WHEN COALESCE(LD.[Cust_ Posting Date],'1753-01-01') = '1753-01-01' AND BU.B_ZAHL_ART 
	   IN (select [PaymentType] from [HRSDB].[PaymentTypeListForCustomer] where [Mandant]  = @CustomName ) THEN 0 
      ELSE 1 
    END 
     FROM HRSDB.CIA_PS_INVOICE IH
  JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
    ON BU.BP_KEY = IH.BOOKING_PROCESS_ID_VALUE
LEFT JOIN Loaded LD ON LD.[Invoice GUID] = UPPER(IH.INVOICE_ID_VALUE)
    WHERE IH.NAV_LOADED 
    <> CASE 
         WHEN COALESCE(LD.[Invoice GUID],'') = '' THEN 0
   WHEN (LD.[Status] <> IH.INVOICE_STATUS) THEN 0
      WHEN COALESCE(LD.[Cust_ Posting Date],'1753-01-01') = '1753-01-01' AND BU.B_ZAHL_ART 
		IN (select [PaymentType] from [HRSDB].[PaymentTypeListForCustomer] where [Mandant] = @CustomName  ) THEN 0 
   ELSE 1 
    END

    

END
GO
