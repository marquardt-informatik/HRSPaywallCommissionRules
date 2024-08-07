USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BC].[InsertUpdateSalesCrMemoLine]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [BC].[InsertUpdateSalesCrMemoLine]
	@DocumentNo [nvarchar] (20)
  , @LineNo int
  , @BookingNo [nvarchar] (50)
  , @TransactionID [nvarchar] (50)
  , @Amount decimal(38,20)
  , @AmountIncludingVAT decimal(38,20)
AS
BEGIN
    IF EXISTS(SELECT * FROM BC.SalesCrMemoLine WHERE [Document No_]=@DocumentNo AND [Line No_]=@LineNo)
        UPDATE BC.SalesCrMemoLine SET 
               [Booking No_]=@BookingNo
             , [Transaction ID]=@TransactionID
             , [Amount]=@Amount
             , [Amount incl_ VAT]=@AmountIncludingVAT
         WHERE [Document No_]=@DocumentNo AND [Line No_]=@LineNo
    ELSE
        INSERT INTO BC.SalesCrMemoLine ([Document No_],[Line No_],[Booking No_],[Transaction ID],[Amount],[Amount incl_ VAT])
        SELECT @DocumentNo, @LineNo, @BookingNo, @TransactionID, @Amount, @AmountIncludingVAT
END
GO
