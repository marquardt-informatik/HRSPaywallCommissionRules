USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPPaymentAdviceHeader_HDE]    Script Date: 10.04.2024 14:31:51 ******/
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
EXEC [dbo].[sp_RPPaymentAdviceHeader_HDE] 'ZV000175Z110000'

*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPPaymentAdviceHeader_HDE] 
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
  SELECT PH.[Account No_] 
       , PH.[Name]
       , PH.[Name 2]
       , PH.[Address]
       , PH.[Address 2]
       , PH.[Post Code]
       , PH.[City]
       , PH.[Country_Region Code]
       , CR.[Name] [Country_Region Name]
       , PH.[Posting Date]
       , PH.[Our Account No_]
       , PH.[Orderer Bank Name]
       , PH.[Orderer Bank Branch No_]
       , PH.[Orderer Bank Account No_]
       , PH.[Orderer Bank BIC Code]
       , PH.[Orderer Bank IBAN Code]
       , PH.[Bank Name]
       , PH.[Bank Branch No_]
       , PH.[Bank Account No_]
       , PH.[Bank BIC Code]
       , PH.[Bank IBAN Code]
       , PH.[E-Mail]
       , PH.[Phone No_]
       , PH.[Fax No_]
       , CASE WHEN PH.[Language Code] = '' THEN '0' ELSE PH.[Language Code] END [Language Code]
	   , CASE WHEN PH.[Account Type] = 2 THEN 0 ELSE 1 END [Document Level]
	   , PP.[Execution Date]
    FROM [hotel_de$Payment Proposal Head]    PH WITH (NOLOCK)
	JOIN [hotel_de$Payment Proposal]         PP WITH (NOLOCK)
	  ON PP.[Journal Batch Name]      = PH.[Gen_ Journal Batch] 
	 AND PP.[Journal Template Name]   = PH.[Gen_ Journal Template]
    JOIN [hotel_de$Country_Region]           CR WITH (NOLOCK)
      ON CR.[Code]                    = PH.[Country_Region Code]
   WHERE PH.[Gen_ Journal Batch]      = @JournalBatchName
     AND PH.[Gen_ Journal Line]       = @GenJournalLine
     AND PH.[Gen_ Journal Template]   = 'ZA-ERW'
END
GO
