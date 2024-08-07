USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCollectionCostHeader_CN]    Script Date: 10.04.2024 14:31:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 09.07.2012
-- Description:	Rechnungskopf der Inkassorechnung + Individuellen Rechnung
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 02.08.18 HRS001   ACS-856 DJU    added [VAT Registration No_]
-- 19.12.18 HRS001   ACS-1349 SAL    added Bill-to Customer Information and [Payment Terms Code]
-- 28.06.19 HRS002   ACS-1554 GCE    create for HRS-CN
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = 'FEE-1-004', @Company = 'HRS-CN'
EXEC [dbo].[sp_RPCollectionCostHeader] @ReNr, @Company 
*/
-- ============================================= 
Create PROCEDURE [dbo].[sp_RPCollectionCostHeader_CN] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
  
	CREATE TABLE #RESULTS 
	( 
		[No_]								VARCHAR(20)
	  , [Sell-to Customer No_]				VARCHAR(20)
	  , [Sell-to Customer Name]				NVARCHAR(130)
	  , [Sell-to Customer Name 2]			NVARCHAR(70)
	  , [Sell-to Address]					NVARCHAR(130)
	  , [Sell-to Address 2]					NVARCHAR(70)
	  , [Sell-to Post Code]					VARCHAR(20)
	  , [Sell-to City]						NVARCHAR(70)
	  , [Sell-to Country Code]              VARCHAR(10)
	  , [Bill-to Customer No_]				VARCHAR(20)
	  , [Posting Date]                      DATETIME
	  , [Payment Method Code]				VARCHAR(10)
	  , [EU Ländercode]						VARCHAR(10)
	  , [ISO_Code]							VARCHAR(10)
	  , [Fax Extension]						VARCHAR(30)
	  , [Phone Extension]					VARCHAR(30)
	  , [Name]								VARCHAR(50)
	  , [Document Date]						DATETIME
	  , [Posting Description]				VARCHAR(50)
	  , [Currency Code]						VARCHAR(10)
	  , [Currency Factor]					DECIMAL(38,20)
	  , [VAT]								DECIMAL(38,20)
	  , [Amount]							DECIMAL(38,20)
	  , [Mwst]								DECIMAL(38,20)
	  , [Total]								DECIMAL(38,20)
      , [Bank Branch No_]					VARCHAR(20)
      , [Bank Account No_]					VARCHAR(34)
      , [Bank Name]							VARCHAR(50)
      , [IBAN]								VARCHAR(50)
      , [BIC]								VARCHAR(20)
	  , [Language Code]						VARCHAR(10)
	  , [SEPA]								tinyint
	  , [Vertrag Status]					tinyint
	  , [Special Fax]                       varchar(100)
	  , [Special E-Mail]                    varchar(100)
	  -- 02.08.18 DJU >>>>>>>>>>>>>>>>>>> HRS001
	  , [VAT Registration No_]				varchar(20)
	  -- 02.08.18 DJU <<<<<<<<<<<<<<<<<<< HRS001
	  -- 19.12.18 SAL >>>>>>>>>>>>>>>>>>> HRS002
	  , [Bill-to Name]						NVARCHAR(130)
	  , [Bill-to Name 2]					NVARCHAR(70)
	  , [Bill-to Address]					NVARCHAR(130)
	  , [Bill-to Address 2]					NVARCHAR(70)
	  , [Bill-to Post Code]					VARCHAR(20)
	  , [Bill-to City]						NVARCHAR(70)
	  , [Payment Terms Code]				VARCHAR(20)
	  -- 19.12.18 SAL <<<<<<<<<<<<<<<<<<< HRS002
	)
	
	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
  INSERT INTO #RESULTS
    SELECT SH.[Pre-Assigned No_] [No_]
         , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content]       END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content]       END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content]       END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content]       END [Sell-to Address 2]
         , SH.[Sell-to Post Code]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content]       END [Sell-to City]
         , SH.[Bill-to Country_Region Code] [Bill-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      [EU Ländercode]
         , SH.[Language Code]               [ISO_Code]
         , SP.[Fax Extension]               [Durchwahl Fax]
         , SP.[Phone Extension]             [Durchwahl Telefon]
         , CO.Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , SH.[Currency Code]
         , SH.[Currency Factor]
         , MAX(SL.[VAT %])                  VAT
         , SUM(SL.Amount)                   Amount
         , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) Mwst
         , SUM(SL.[Amount Including VAT])   Total
         , RTRIM(BA.[Bank Branch No_]) [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_]) [Bank Account No_]
         , RTRIM(BA.[Name])                                     [Bank Name]
         , RTRIM(BA.[IBAN])                                     [IBAN]
         , RTRIM(BA.[SWIFT Code])                               [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
         , MAX(CAST(CU.[Contract Status] AS int))               [Vertrag Status]
         , MAX(
           CASE 
             WHEN CU.[Contract Status] IN(''10'',''11'') THEN
               ''''
             ELSE
               CASE 
                 WHEN '',29,57,92,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
                   ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441''
                 WHEN '',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
                   ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447''
                 ELSE
                   ''''
               END    
           END) [Special Fax]
         , MAX(
           CASE 
             WHEN CU.[Contract Status] IN(''10'',''11'') 
              AND CU.[Payment Method Code] <> ''SEPA''
              AND NOT CU.[Payment Method Code] LIKE ''LAST%'' THEN SP.[Fax Extension]  + ''@hrs.de''
             WHEN '',29,57,92,10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN 
               ''accounting_fax@hrs.cn''
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = ''CORE'' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = ''SEPA'' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = ''CC_AUTO'' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = ''LAST'' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'''') = '''' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'''') 
               END 
             + ''@hrs.de''
           END) [Special E-Mail]
		 , CU.[VAT Registration No_]
	     , SH.[Bill-to Name]				
	     , SH.[Bill-to Name 2]			
	     , SH.[Bill-to Address]					
	     , SH.[Bill-to Address 2]					
	     , SH.[Bill-to Post Code]					
	     , SH.[Bill-to City]	
		 , SH.[Payment Terms Code]	
      FROM [' + @Company + '$Sales Invoice Header] SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
 LEFT JOIN [' + @Company + '$Responsibility Center] RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code
 LEFT JOIN [' + @Company + '$Printer Group] AC WITH (READUNCOMMITTED)
        ON AC.[Code]                        = ''AUTO_CC''
 LEFT JOIN [' + @Company + '$Printer Group] SE WITH (READUNCOMMITTED)
        ON SE.[Code]                        = ''SEPA''
 LEFT JOIN [' + @Company + '$Printer Group] CR WITH (READUNCOMMITTED)
        ON CR.[Code]                        = ''CORE''
 LEFT JOIN [' + @Company + '$Printer Group] LT WITH (READUNCOMMITTED)
        ON LT.[Code]                        = ''LAST''
      JOIN [' + @Company + '$Country_Region] CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [' + @Company + '$Printer Group] SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN [' + @Company + '$Sales Invoice Line] SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [HRS-CN$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Bill-to Customer No_]
     WHERE (SH.No_ = ''' + @ReNr + ''')'
SET @SQLStatement = @SQLStatement + '
  GROUP BY SH.[Pre-Assigned No_]
         , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content]       END
         , SH.[Sell-to Post Code]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content]       END
         , SH.[Bill-to Country_Region Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , SH.[Language Code]                  
         , SP.[Fax Extension]              
         , SP.[Phone Extension]            
         , CO.Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , SH.[Currency Code]
         , SH.[Currency Factor]
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]
         , BA.[IBAN] 
         , BA.[SWIFT Code]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
		 , CU.[VAT Registration No_]
		 , SH.[Bill-to Name]				
	     , SH.[Bill-to Name 2]			
	     , SH.[Bill-to Address]					
	     , SH.[Bill-to Address 2]					
	     , SH.[Bill-to Post Code]					
	     , SH.[Bill-to City]	
		 , SH.[Payment Terms Code]
         '
	PRINT SUBSTRING(@SQLStatement,1,8000)  
	PRINT SUBSTRING(@SQLStatement,8000,8000)  
	EXECUTE(@SQLStatement)       

	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
  INSERT INTO #RESULTS
    SELECT SH.[No_]
         , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content]       END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content]       END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content]       END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content]       END [Sell-to Address 2]
         , SH.[Sell-to Post Code]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content]       END [Sell-to City]
         , SH.[Bill-to Country_Region Code] [Bill-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      [EU Ländercode]
         , SH.[Language Code]               [ISO_Code]
         , SP.[Fax Extension]               [Durchwahl Fax]
         , SP.[Phone Extension]             [Durchwahl Telefon]
         , CO.Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , SH.[Currency Code]
         , SH.[Currency Factor]
         , MAX(SL.[VAT %])                  VAT
         , SUM(SL.Amount)                   Amount
         , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) Mwst
         , SUM(SL.[Amount Including VAT])   Total
         , RTRIM(BA.[Bank Branch No_]) [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_]) [Bank Account No_]
         , RTRIM(BA.[Name])                                     [Bank Name]
         , RTRIM(BA.[IBAN])                                     [IBAN]
         , RTRIM(BA.[SWIFT Code])                               [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
         , MAX(CAST(CU.[Contract Status] AS int))               [Vertrag Status]
         , MAX(
           CASE 
             WHEN CU.[Contract Status] IN(''10'',''11'') THEN
               ''''
             ELSE
               CASE 
                 WHEN '',29,57,92,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
                   ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441''
                 WHEN '',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN
                   ''Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447''
                 ELSE
                   ''''
               END    
           END) [Special Fax]
         , MAX(
           CASE 
             WHEN CU.[Contract Status] IN(''10'',''11'') 
              AND CU.[Payment Method Code] <> ''SEPA''
              AND NOT CU.[Payment Method Code] LIKE ''LAST%'' THEN SP.[Fax Extension]  + ''@hrs.de''
             WHEN '',29,57,92,10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,'' LIKE ''%,''+SH.[Bill-to Country_Region Code]+'',%'' THEN 
               ''accounting_fax@hrs.cn''
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = ''CORE'' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = ''SEPA'' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = ''CC_AUTO'' THEN COALESCE(AC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = ''LAST'' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'''') = '''' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'''') 
               END 
             + ''@hrs.de''
           END) [Special E-Mail]
		 , CU.[VAT Registration No_]
		 , SH.[Bill-to Name]				
	     , SH.[Bill-to Name 2]			
	     , SH.[Bill-to Address]					
	     , SH.[Bill-to Address 2]					
	     , SH.[Bill-to Post Code]					
	     , SH.[Bill-to City]		
		 , SH.[Payment Terms Code]	
      FROM [' + @Company + '$Sales Header] SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
 LEFT JOIN [' + @Company + '$Responsibility Center] RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code
 LEFT JOIN [' + @Company + '$Printer Group] AC WITH (READUNCOMMITTED)
        ON AC.[Code]                        = ''AUTO_CC''
 LEFT JOIN [' + @Company + '$Printer Group] SE WITH (READUNCOMMITTED)
        ON SE.[Code]                        = ''SEPA''
 LEFT JOIN [' + @Company + '$Printer Group] CR WITH (READUNCOMMITTED)
        ON CR.[Code]                        = ''CORE''
 LEFT JOIN [' + @Company + '$Printer Group] LT WITH (READUNCOMMITTED)
        ON LT.[Code]                        = ''LAST''
      JOIN [' + @Company + '$Country_Region] CO WITH (READUNCOMMITTED) 
        ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [' + @Company + '$Printer Group] SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN [' + @Company + '$Sales Line] SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [HRS-CN$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Bill-to Customer No_]
     WHERE (SH.No_ = ''' + @ReNr + ''')'
SET @SQLStatement = @SQLStatement + '
  GROUP BY SH.[No_]
         , SH.[Sell-to Customer No_]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content]       END
         , SH.[Sell-to Post Code]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content]       END
         , SH.[Bill-to Country_Region Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , SH.[Language Code]                   
         , SP.[Fax Extension]              
         , SP.[Phone Extension]
         , CO.Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , SH.[Currency Code]
         , SH.[Currency Factor]
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]
         , BA.[IBAN] 
         , BA.[SWIFT Code]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
		 , CU.[VAT Registration No_]
		 , SH.[Bill-to Name]				
	     , SH.[Bill-to Name 2]			
	     , SH.[Bill-to Address]					
	     , SH.[Bill-to Address 2]					
	     , SH.[Bill-to Post Code]					
	     , SH.[Bill-to City]	
		 , SH.[Payment Terms Code]
       '
	PRINT (@SQLStatement)  
	EXECUTE(@SQLStatement)  
	SELECT * FROM #RESULTS
END

GO
