USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_NewWorkFeeInvoiceLine]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Khaled Mamdouh
-- Create date: 19.09.2022
-- Description:	NewWork Fee Invoice
-- Source: sp_RPMarketplaceFeeSalesInvoiceLine

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = 'R008951557', @Company = 'HRS'
EXEC [dbo].[sp_RPMarketplaceFeeSalesInvoiceLine] @ReNr, @Company
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_NewWorkFeeInvoiceLine]
    @ReNr varchar(25)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #RESULTS 
	( 
		[Document No_]						VARCHAR(20)
	  , [Line No_]							INT
	  , [Leistungsart]						VARCHAR(50)
	  , [Nettobetrag]						DECIMAL(38,20)
	  , [Rechnungsbetrag]					DECIMAL(38,20)
	  , [MwSt]								DECIMAL(38,20)
	  , [MwSt Betrag]						DECIMAL(38,20)
	  , [Currency Code]						VARCHAR(10)
	)
	
	DECLARE @SQLStatement VARCHAR(max)

    SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
	  INSERT INTO #RESULTS
      SELECT [Document No_]
	       , [Line No_]
           , COALESCE(A.Translation,[Description]) [Leistungsart]
           , [Amount] [Nettobetrag]
           , [Amount Including VAT] [Rechnungsbetrag]
           , ROUND([VAT %],2) [MwSt]
		   , [Amount Including VAT] - [Amount] [MwSt Betrag]
           , SH.[Currency Code]
        FROM [' + @Company + '$Sales Invoice Line] SL WITH (READUNCOMMITTED)
   LEFT JOIN [' + @Company + '$Sales Invoice Header] SH WITH (READUNCOMMITTED)
          ON SH.[No_] = SL.[Document No_]
   LEFT JOIN Advertise A
          ON A.Term = SL.Description
         AND A.LanguageID = SH.[Language Code]
       WHERE SL.[Type] <> 0 AND [Document No_] = ''' + @ReNr + ''''
	EXECUTE(@SQLStatement)       

    SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
	  INSERT INTO #RESULTS
      SELECT [Document No_]
	       , [Line No_]
           , COALESCE(A.Translation,[Description]) [Leistungsart]
           , [Line Amount] [Nettobetrag]
           , [Outstanding Amount] [Rechnungsbetrag]
           , ROUND([VAT %],2) [MwSt]
		   , [Outstanding Amount] - [Line Amount] [MwSt Betrag]
           , SH.[Currency Code]
        FROM [' + @Company + '$Sales Line] SL WITH (READUNCOMMITTED)
   LEFT JOIN [' + @Company + '$Sales Header] SH WITH (READUNCOMMITTED)
          ON SH.[No_] = SL.[Document No_]
   LEFT JOIN Advertise A
          ON A.Term = SL.Description
         AND A.LanguageID = SH.[Language Code]
       WHERE SL.[Type] <> 0 AND [Document No_] = ''' + @ReNr + ''''      
	EXECUTE(@SQLStatement)
	SELECT * FROM #RESULTS      
END
GO
