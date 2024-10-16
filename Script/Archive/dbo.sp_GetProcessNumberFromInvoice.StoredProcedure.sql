USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetProcessNumberFromInvoice]    Script Date: 10.04.2024 14:31:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 11.05.20
-- Description:	Liefert alle Itelya Rechnungs-IDs zu einer angegebenen Nachbelastung
-- EXEC sp_GetPaymentInvoiceIDsFromInvoice 'NB035986'
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetProcessNumberFromInvoice]
	@InvoiceNo varchar(20)=''
AS
BEGIN
  SELECT INV.BOOKING_PROCESS_ID_VALUE
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK) 
    JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
    JOIN HRSDB.CIA_PS_INVOICE INV WITH (NOLOCK)
      ON DL.[ProcessNumber] = INV.BOOKING_PROCESS_ID_VALUE
    --JOIN HRSDB.CIA_PS_INVOICE_PDF PDF
    --  ON PDF.INVOICE_ID_VALUE = INV.INVOICE_ID_VALUE
    -- AND PDF.NO_PDF=0
   WHERE [Document Type] = '15'
     AND (DH.[Posted Invoice No_] = @InvoiceNo OR DH.[Case No_] = @InvoiceNo)
	 AND DL.[Action]<>3
GROUP BY INV.BOOKING_PROCESS_ID_VALUE
UNION
  SELECT INV.BOOKING_PROCESS_ID_VALUE
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK) 
    JOIN [HRS-CN$Agency Display Header] DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
    JOIN HRSDB.CIA_PS_INVOICE INV WITH (NOLOCK)
      ON DL.[ProcessNumber] = INV.BOOKING_PROCESS_ID_VALUE
    --JOIN HRSDB.CIA_PS_INVOICE_PDF PDF
    --  ON PDF.INVOICE_ID_VALUE = INV.INVOICE_ID_VALUE
    -- AND PDF.NO_PDF=0
   WHERE [Document Type] = '15'
     AND (DH.[Posted Invoice No_] = @InvoiceNo OR DH.[Case No_] = @InvoiceNo)
	 AND DL.[Action]<>3
GROUP BY INV.BOOKING_PROCESS_ID_VALUE
UNION
  SELECT INV.BOOKING_PROCESS_ID_VALUE
    FROM [HRS-BR$Agency Display Line] DL WITH (NOLOCK) 
    JOIN [HRS-BR$Agency Display Header] DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
    JOIN HRSDB.CIA_PS_INVOICE INV WITH (NOLOCK)
      ON DL.[ProcessNumber] = INV.BOOKING_PROCESS_ID_VALUE
    --JOIN HRSDB.CIA_PS_INVOICE_PDF PDF
    --  ON PDF.INVOICE_ID_VALUE = INV.INVOICE_ID_VALUE
    -- AND PDF.NO_PDF=0
   WHERE [Document Type] = '15'
     AND (DH.[Posted Invoice No_] = @InvoiceNo OR DH.[Case No_] = @InvoiceNo)
	 AND DL.[Action]<>3
GROUP BY INV.BOOKING_PROCESS_ID_VALUE
END
GO
