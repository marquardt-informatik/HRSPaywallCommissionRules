USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPLine_SalesInvoice_CrMemo_BR]    Script Date: 10.04.2024 14:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sascha Altgeld
-- Create date: 20.09.2017
-- Description:	Gutschriftszeilen für Debitor-Rechnung
--   
-- Datum     Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 17.04.18  HRS001  ACS-355  SAL    Edit Amout calculation for Sales Header  
--
/*
Beispiel Gutschrift ungebucht
DECLARE @ReNr			VARCHAR(20)     ='BR1035608/CR'
      , @Company		VARCHAR(30)		='HRS-BR'
	  , @DocumentTyp	INT				= 03
EXEC [dbo].[sp_RPLine_SalesInvoice_CrMemo_BR] @ReNr, @Company, @DocumentTyp 

Beispiel Gutschrift
DECLARE @ReNr			VARCHAR(20)     ='11802134/CR'
      , @Company		VARCHAR(30)		='HRS'
	  , @DocumentTyp	INT				= 03
EXEC [dbo].[sp_RPLine_SalesInvoice_CrMemo] @ReNr, @Company, @DocumentTyp 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPLine_SalesInvoice_CrMemo_BR] 
    @ReNr			VARCHAR(20)
  , @Company		VARCHAR(30)
  , @DocumentTyp	INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
  
	CREATE TABLE #RESULTS 
	( 
		[Document No_]						VARCHAR(20)
      , [Line No_]							INT
	  , [Description]						VARCHAR(250)
	  , [Description 2]						VARCHAR(250)
	  , [Quantity]							DECIMAL(38,20)
	  , [Unit of Measure]					VARCHAR(250)	
	  , [Nettobetrag]    					DECIMAL(38,20)
	  , [Rechnungsbetrag]    				DECIMAL(38,20)
	  , [Currency Code]						VARCHAR(20)
	  , [VAT Identifier]					VARCHAR(20)
	  , [Umsatz]							DECIMAL(38,20)
	  , [Rabatt]							DECIMAL(38,20)
	  , [Rabattbetrag]						DECIMAL(38,20)
	  , [MwSt]								DECIMAL(38,20)
	)
	
	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Cr_Memo Header] WHERE [No_] = ''' + @ReNr + ''')   
    INSERT INTO #RESULTS
    SELECT [SIL].[Document No_]
         , MIN([SIL].[Line No_])
		 , MIN([SIL].[Description])
		 , MIN([SIL].[Description 2])
		 , SUM([SIL].[Quantity])
		 , MAX([SIL].[Unit of Measure])
		 , SUM([SIL].[Amount]) [Nettobetrag] 
		 , SUM([SIL].[Amount Including VAT]) [Rechnungsbetrag]
		 , CASE WHEN [SIH].[Currency Code] = '''' THEN ''EUR'' ELSE [SIH].[Currency Code] END	[Currency Code]
		 , [SIL].[VAT Identifier]
		 , SUM([SIL].[Amount]) [Umsatz]
         , MAX([SIL].[Line Discount %]) [Rabatt]
         , SUM([SIL].[Line Discount Amount]) [Rabattbetrag]
		 , MAX(ROUND([SIL].[VAT %],2)) [MwSt]
      FROM [' + @Company + CASE WHEN @DocumentTyp = 2 
								THEN + '$Sales Invoice Line]'
								ELSE + '$Sales Cr_Memo Line]'
						   END + ' AS [SIL] WITH (READUNCOMMITTED) 
	  JOIN [' + @Company + CASE WHEN @DocumentTyp = 2 
								THEN + '$Sales Invoice Header]'
								ELSE + '$Sales Cr_Memo Header]'
						   END + '	AS [SIH] WITH (READUNCOMMITTED) 
	    ON [SIL].[Document No_] = [SIH].[No_] 
     WHERE ([SIL].[Document No_] = ''' + @ReNr + ''') AND ([SIL].[Type] <> 0)
	 GROUP BY [SIL].[Document No_]
	     --, [SIL].[Line No_]
		 --, [SIL].[Description]
		 --, [SIL].[Description 2]
		 --, SUM([SIL].[Quantity])
		 --, [SIL].[Unit of Measure]
		 --, SUM([SIL].[Amount]) [Nettobetrag] 
		 --, SUM([SIL].[Amount Including VAT]) [Rechnungsbetrag]
		 , [SIH].[Currency Code]
		 , [SIL].[VAT Identifier]
		 --, SUM([SIL].[Unit Price]) [Umsatz]
         --, [SIL].[Line Discount %] [Rabatt]
         --, SUM([SIL].[Line Discount Amount]) [Rabattbetrag]
		 --, [SIL].[VAT %]
       '
	PRINT(@SQLStatement)  
  EXECUTE(@SQLStatement)     
    
  SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE ([No_] = ''' + @ReNr + ''') AND ([Document Type] = 3))  
    INSERT INTO #RESULTS
    SELECT [SIL].[Document No_]
         , MIN([SIL].[Line No_])
		 , MIN([SIL].[Description])
		 , MIN([SIL].[Description 2])
		 , SUM([SIL].[Quantity])
		 , MAX([SIL].[Unit of Measure])
		 , CASE
               WHEN SUM([SIL].[Amount]) <> 0 THEN SUM([SIL].[Amount]) 
			   ELSE SUM([SIL].[Unit Price] * [SIL].[Quantity])
		   END [Nettobetrag] 
		 , CASE
				WHEN SUM([SIL].[Amount Including VAT]) <> 0 THEN SUM([SIL].[Amount Including VAT])
				ELSE SUM((1 + ROUND([SIL].[VAT %],2) / 100) * [SIL].[Unit Price] * [SIL].[Quantity]) 
		   END [Rechnungsbetrag]
		 , CASE WHEN [SIH].[Currency Code] = '''' THEN ''EUR'' ELSE [SIH].[Currency Code] END	[Currency Code]
		 , [SIL].[VAT Identifier]
		 , CASE
               WHEN SUM([SIL].[Amount]) <> 0 THEN SUM([SIL].[Amount]) 
			   ELSE SUM([SIL].[Unit Price] * [SIL].[Quantity])
		   END [Umsatz]
         , MAX([SIL].[Line Discount %]) [Rabatt]
         , SUM([SIL].[Line Discount Amount]) [Rabattbetrag]
		 , MAX(ROUND([SIL].[VAT %],2)) [MwSt]
      FROM [' + @Company + '$Sales Line] AS [SIL] WITH (READUNCOMMITTED) 
	  JOIN [' + @Company + '$Sales Header] AS [SIH] WITH (READUNCOMMITTED) 
	    ON [SIL].[Document No_] = [SIH].[No_] AND [SIL].[Document Type] = [SIH].[Document Type]  
     WHERE ([SIL].[Document No_] = ''' + @ReNr + ''') AND ([SIL].[Document Type] = 3) AND ([SIL].[Type] <> 0)
	 GROUP BY [SIL].[Document No_]
		 , [SIH].[Currency Code]
		 , [SIL].[VAT Identifier]		 
       '
	PRINT(@SQLStatement)  
  EXECUTE(@SQLStatement)       

   SELECT * FROM #RESULTS
END


GO
