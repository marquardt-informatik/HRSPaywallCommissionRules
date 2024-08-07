USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_DeleteCorrectionInvoice]    Script Date: 10.04.2024 14:31:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 12.03.19
-- Description:	Delete a unposted correction commission invoice
-- =============================================
CREATE PROCEDURE [dbo].[sp_DeleteCorrectionInvoice] 
  @ImportEntryNo int
AS
BEGIN
  DECLARE @CorrectionCaseNo varchar(20)
  SELECT TOP 1 @CorrectionCaseNo = PIL.[Correction Case No_]
    FROM [HRS$Partner Import Line] PIL
   WHERE PIL.[Correction Case No_]<>''
     AND PIL.[Import Entry No_] = @ImportEntryNo
     
   PRINT @CorrectionCaseNo 
  /*
  IF EXISTS(SELECT * FROM [HRS$Agency Display Header] WHERE [Case No_]=@CorrectionCaseNo AND [Status]=2)
  BEGIN
    BEGIN TRAN
    DELETE FROM [HRS$Agency Display Header] WHERE [Case No_]=@CorrectionCaseNo AND [Status]=2
    DELETE FROM [HRS$Agency Display Line] WHERE [Display Case No_]=@CorrectionCaseNo 
    UPDATE [HRS$Partner Import Line] SET [Correction Case No_]='' WHERE [Import Entry No_] = @ImportEntryNo
    COMMIT
  END
  */
END
GO
