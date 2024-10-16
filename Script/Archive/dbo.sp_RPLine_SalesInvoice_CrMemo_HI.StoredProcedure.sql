USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPLine_SalesInvoice_CrMemo_HI]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 16.06.2016
-- Description:	Rechnungszeilen für Debitor-Rechnung
--   
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
/*
Beispiel Rechnung
DECLARE @ReNr			VARCHAR(20)     ='R10017513'
      , @Company		VARCHAR(30)		='HRS Holidays'
	  , @DocumentTyp	INT				= 02
EXEC [dbo].[sp_RPLine_SalesInvoice_CrMemo_HI] @ReNr, @Company, @DocumentTyp 

Beispiel Gutschrift
DECLARE @ReNr			VARCHAR(20)     ='020148'
      , @Company		VARCHAR(30)		='HRS Holidays'
	  , @DocumentTyp	INT				= 03
EXEC [dbo].[sp_RPLine_SalesInvoice_CrMemo_HI] @ReNr, @Company, @DocumentTyp 
*/
-- ============================================= 
create PROCEDURE [dbo].[sp_RPLine_SalesInvoice_CrMemo_HI] 
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
	  , [Amount]							DECIMAL(38,20)
	  , [Amount Including VAT]				DECIMAL(38,20)
	  , [Currency Code]						VARCHAR(20)
	  , [VAT Identifier]					VARCHAR(20)
	)
	
	SET @SQLStatement = 
'   INSERT INTO #RESULTS
    SELECT [SIL].[Document No_]
         , [SIL].[Line No_]
		 , [SIL].[Description]
		 , [SIL].[Description 2]
		 , [SIL].[Quantity]
		 , [SIL].[Unit of Measure]
		 , [SIL].[Amount]
		 , [SIL].[Amount Including VAT]
		 , CASE WHEN [SIH].[Currency Code] = '''' THEN ''EUR'' ELSE [SIH].[Currency Code] END	[Currency Code]
		 , [SIL].[VAT Identifier]
      FROM [' + @Company + CASE WHEN @DocumentTyp = 2 
								THEN + '$Sales Invoice Line]'
								ELSE + '$Sales Cr_Memo Line]'
						   END + ' AS [SIL] WITH (READUNCOMMITTED) 
	  JOIN [' + @Company + CASE WHEN @DocumentTyp = 2 
								THEN + '$Sales Invoice Header]'
								ELSE + '$Sales Cr_Memo Header]'
						   END + '	AS [SIH] WITH (READUNCOMMITTED) 
	    ON [SIL].[Document No_] = [SIH].[No_] 
     WHERE ([Document No_] = ''' + @ReNr + ''')
       '
	PRINT(@SQLStatement)  
  EXECUTE(@SQLStatement)       

   SELECT * FROM #RESULTS
END


GO
