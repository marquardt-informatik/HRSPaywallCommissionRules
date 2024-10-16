USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCollectionCostLine_CN]    Script Date: 10.04.2024 14:31:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 09.07.2012
-- Description:	Rechnungskopf der Marketingrechnung
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = 'FEE-1-004', @Company = 'HRS-CN'
EXEC [dbo].[sp_RPCollectionCostLine_CN] @ReNr, @Company
*/
-- ============================================= 
Create PROCEDURE [dbo].[sp_RPCollectionCostLine_CN]
    @ReNr varchar(25)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #RESULTS 
	( 
		[Document No_]                   VARCHAR(20)
	  , [Debit Coll_ Amount]             decimal(37,20)
	  , [Debit Coll_ Amount incl_ VAT]   decimal(37,20)
	  , [Debit Coll_ Amount (LCY)]       decimal(37,20)
	  , [Debit Coll_ A_ incl_ VAT (LCY)] decimal(37,20)
	  , [Debit Coll_ Description]        VARCHAR(100)
	  , [Currency Code]                  VARCHAR(10)
	)
	
	DECLARE @SQLStatement VARCHAR(max)

    SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
	  INSERT INTO #RESULTS
      SELECT [Document No_]
           , [Debit Coll_ Amount]
           , [Debit Coll_ Amount incl_ VAT]
           , [Debit Coll_ Amount (LCY)]
           , [Debit Coll_ A_ incl_ VAT (LCY)]
           , [Debit Coll_ Description]
           , SH.[Currency Code]
        FROM [' + @Company + '$Sales Invoice Line] SL WITH (READUNCOMMITTED)
   LEFT JOIN [' + @Company + '$Sales Invoice Header] SH WITH (READUNCOMMITTED)
          ON SH.[No_] = SL.[Document No_]
       WHERE [Document No_] = ''' + @ReNr + ''''
	EXECUTE(@SQLStatement)       

    SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
	  INSERT INTO #RESULTS
      SELECT [Document No_]
           , [Debit Coll_ Amount]
           , [Debit Coll_ Amount incl_ VAT]
           , [Debit Coll_ Amount (LCY)]
           , [Debit Coll_ A_ incl_ VAT (LCY)]
           , [Debit Coll_ Description]
           , SH.[Currency Code]
        FROM [' + @Company + '$Sales Line] SL WITH (READUNCOMMITTED)
   LEFT JOIN [' + @Company + '$Sales Header] SH WITH (READUNCOMMITTED)
          ON SH.[No_] = SL.[Document No_]
       WHERE [Document No_] = ''' + @ReNr + ''''      
	EXECUTE(@SQLStatement)
	SELECT * FROM #RESULTS      
END

GO
