USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPPaymentTermTranslation]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sascha Altgeld
-- Create date: 06.11.2017
-- Description:	Zlg.-Bedingungsübersetzungen 
-- Datum     Version  RFC      Sign.  Beschreibung
-- ------------------------------------------------------------
/*
DECLARE @PaymentTermsCode varchar(20), @LanguageCode varchar(30), @Company varchar(30)
SELECT @PaymentTermsCode = 'NETTO0', @LanguageCode = '0', @Company = 'HRS'
EXEC [dbo].[sp_RPPaymentTermTranslation] @PaymentTermsCode, @LanguageCode, @Company 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPPaymentTermTranslation] 
    @PaymentTermsCode varchar(20)
  , @LanguageCode varchar(30)
  , @Company      varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
  
	CREATE TABLE #RESULTS 
	( 
		[Payment Terms Code]				VARCHAR(250),
		[Language Code]						VARCHAR(250),
		[Translation]						VARCHAR(250)
	)
	
	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Payment Term Translation] WHERE [Payment Term] = ''' + @PaymentTermsCode + ''' AND [Language Code] = ''' + @LanguageCode + ''')
 BEGIN 
   INSERT INTO #RESULTS
   SELECT [Payment Term]
	    , [Language Code]
	    , [Description]
	 FROM [' + @Company + '$Payment Term Translation]	   
     WHERE [Payment Term] = ''' + @PaymentTermsCode + ''' 
	  AND  [Language Code] = ''' + @LanguageCode + ''' 
 END 
 ELSE
 BEGIN
   INSERT INTO #RESULTS
  SELECT [Payment Term]
	   , [Language Code]
	   , [Description]
	FROM [' + @Company + '$Payment Term Translation]	   
    WHERE [Payment Term] = ''' + @PaymentTermsCode + ''' 
	 AND  [Language Code] = ''1''  	
 END	
 
 IF (NOT EXISTS(SELECT * FROM #RESULTS)) AND (''' + @LanguageCode + ''' = 0)
 BEGIN
   INSERT INTO #RESULTS
  SELECT [Code] AS [Payment Term]
	   , ''' + @LanguageCode + ''' AS [Language Code]
	   , ''Zahlungsziel: '' + [Description] AS [Description]
	FROM [' + @Company + '$Payment Terms]	   
    WHERE [Code] = ''' + @PaymentTermsCode + ''' 	 
 END  
	   '
	PRINT(@SQLStatement)  
	EXECUTE(@SQLStatement)   

	SELECT * FROM #RESULTS
END
GO
