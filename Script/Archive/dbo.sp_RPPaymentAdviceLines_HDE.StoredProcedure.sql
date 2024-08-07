USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPPaymentAdviceLines_HDE]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.01.15
-- Description:	Returns Informations of a Payment Proposal
--
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 27.01.15 HRS001    92494  TM     created
-- 20.03.18 HRS002   ACS-475 DJU    copied for HDE
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'ZV001242Z280000'
EXEC [dbo].[sp_RPPaymentAdviceLines_HDE] 'ZV000175Z110000'

*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPPaymentAdviceLines_HDE] 
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
  DECLARE @JournalBatchName varchar(20)
        , @GenJournalLine   int
        
  SET @JournalBatchName = SUBSTRING(@ReNr,1,CHARINDEX('Z',@ReNr,2))
  SET @GenJournalLine   = CAST(SUBSTRING(@ReNr,CHARINDEX('Z',@ReNr,2)+1,100) AS int)
  
  --PRINT @JournalBatchName
  --PRINT @GenJournalLine
  SELECT PL.[Line No_]
       , PL.[Applies-to Doc_ Type]
       , PL.[Applies-to Doc_ No_]
       , PL.[External Document No_]
       , - PL.[Original Remaining Amount] [Original Remaining Amount]
       , - PL.[Posting Payment Discount]  [Posting Payment Discount]
       , - PL.[Posting Applied Amount]    [Posting Applied Amount]
       , PL.[Payment Text]
    FROM [hotel_de$Payment Proposal Line]    PL WITH (NOLOCK)      
   WHERE PL.[Journal Batch Name]      = @JournalBatchName
     AND PL.[Journal Line No_]        = @GenJournalLine
     AND PL.[Journal Template Name]   = 'ZA-ERW'
END
GO
