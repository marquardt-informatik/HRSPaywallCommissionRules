USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPSourcingFeeSalesInvoiceLine]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sascha Altgeld
-- Create date: 19.10.2017
-- Description:	Rechnungszeilen der Sourcing Fee Rechnung
-- Datum      Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 06.02.19   HRS001  ACS-1353 SAL    Use "SELECT [..." instead of "SELECT TOP 1 [..." to be able to print several lines of an invoice
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = 'MA152125', @Company = 'HRS'
EXEC [dbo].[sp_RPSourcingFeeSalesInvoiceLine] @ReNr, @Company
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPSourcingFeeSalesInvoiceLine]
    @ReNr varchar(25)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #RESULTS 
	( 
		[Document No_]						VARCHAR(20)
	  , [Leistungsart]						VARCHAR(50)
	  , [Bannerziel]						VARCHAR(50)
	  , [Umsatz]							DECIMAL(38,20)
	  , [Rabatt]							DECIMAL(38,20)
	  , [Rabattbetrag]						DECIMAL(38,20)
	  , [Nettobetrag]						DECIMAL(38,20)
	  , [Rechnungsbetrag]					DECIMAL(38,20)
	  , [MwSt]								DECIMAL(38,20)
	  , [Currency Code]						VARCHAR(10)
	  , [Menge]							    DECIMAL(38,20)
	)
	
	DECLARE @SQLStatement VARCHAR(max)

    SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
	  INSERT INTO #RESULTS
      SELECT [Document No_]
           , COALESCE(A.Translation,[Description]) [Leistungsart]
           , [Description 2] [Bannerziel]
           , [Unit Price] [Umsatz]
           , [Line Discount %] [Rabatt]
           , [Line Discount Amount] [Rabattbetrag]
           , [Amount] [Nettobetrag]
           , [Amount Including VAT] [Rechnungsbetrag]
           , ROUND([VAT %],2) [MwSt]
           , SH.[Currency Code]
		   , [Quantity]
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
           , COALESCE(A.Translation,[Description]) [Leistungsart]
           , [Description 2] [Bannerziel]
           , [Unit Price] [Umsatz]
           , [Line Discount %] [Rabatt]
           , [Line Discount Amount] [Rabattbetrag]
           , ([Unit Price] - [Line Discount Amount]) * [Quantity] [Nettobetrag]
           , [Outstanding Amount] [Rechnungsbetrag]
           , ROUND([VAT %],2) [MwSt]
           , SH.[Currency Code]
		   , [Quantity]
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
