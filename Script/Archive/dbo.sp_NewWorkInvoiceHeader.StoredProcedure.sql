USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_NewWorkInvoiceHeader]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Khaled Mamdouh
-- Create date: 19.09.2022
-- Description:	NewWork Fee Invoice
-- Source: sp_RPMarketplaceFeeSalesInvoiceHeader
-- Datum     Version  RFC      Sign.  Beschreibung
-- ------------------------------------------------------------
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = '15823706', @Company = 'HRS'
EXEC [dbo].[sp_RPMarketplaceFeeSalesInvoiceHeader] @ReNr, @Company 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_NewWorkInvoiceHeader] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
  
	CREATE TABLE #RESULTS 
	( 
		[Pre-Assigned No_]					VARCHAR(250)
      , [No_]								VARCHAR(250)
	  , [Sell-to Customer No_]				VARCHAR(250)
	  , [Sell-to Contact]					VARCHAR(250)
	  , [Sell-to Customer Name]				NVARCHAR(250)
	  , [Sell-to Customer Name 2]			NVARCHAR(250)
	  , [Sell-to Address]					NVARCHAR(250)
	  , [Sell-to Address 2]					NVARCHAR(250)
	  , [Sell-to Post Code]					NVARCHAR(250)
	  , [Sell-to City]						NVARCHAR(250)
	  , [Sell-to Country Code]              VARCHAR(250)
	  , [Bill-to Customer No_]				VARCHAR(250)
	  , [Posting Date]                      DATETIME
	  , [Payment Method Code]				VARCHAR(250)
	  , [EU Ländercode]						VARCHAR(250)
	  , [ISO_Code]							VARCHAR(250)
	  , [Durchwahl Fax]						VARCHAR(250)
	  , [Durchwahl Telefon]					VARCHAR(250)
	  , [Name]								NVARCHAR(250)
	  , [Document Date]						DATETIME
	  , [Posting Description]				VARCHAR(250)
	  , [Currency Code]						VARCHAR(250)
	  , [Currency Factor]					DECIMAL(38,20)
	  , [VAT]								DECIMAL(38,20)
	  , [Amount]							DECIMAL(38,20)
	  , [Mwst]								DECIMAL(38,20)
	  , [Total]								DECIMAL(38,20)
      , [Bank Branch No_]                   VARCHAR(250)
      , [Bank Account No_]                  VARCHAR(250)
      , [Bank Name]                         VARCHAR(250)
      , [IBAN]                              VARCHAR(250)
      , [BIC]                               VARCHAR(250)
	  , [Language Code]						NVARCHAR(250)
	  , [SEPA]								tinyint
	  , [Vertrag Status]					tinyint
	  , [Period Begin]						DATE
	  , [Period End]						DATE
	  , [VAT Registration No_]				VARCHAR(250)
	  , [Bill-to Contact]					VARCHAR(250)
	  , [Bill-to Name]						NVARCHAR(250)
	  , [Bill-to Name 2]					NVARCHAR(250)
	  , [Bill-to Address]					NVARCHAR(250)
	  , [Bill-to Address 2]					NVARCHAR(250)
	  , [Bill-to Post Code]					NVARCHAR(250)
	  , [Bill-to City]						NVARCHAR(250)
	  , [Bill-to Country Code]              VARCHAR(250)
      , [Payment Reference]                 VARCHAR(80)
      , [Payment Provider]                  VARCHAR(30)
	)
	
	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
  INSERT INTO #RESULTS
  SELECT SH.[Pre-Assigned No_]
       , SH.[No_]
       , SH.[Sell-to Customer No_]
       , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , SH.[Sell-to Post Code]
		 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Country_Region Code] AS [Sell-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Durchwahl Fax]
         , SP.[Phone Extension]             AS [Durchwahl Telefon]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
       , SH.[Document Date]
       , SH.[Posting Description]       
       , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END [Currency Code]
       , SH.[Currency Factor]
       , MAX(SL.[VAT %])                  AS VAT
       , SUM(SL.Amount)                   AS Amount
       , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) AS Mwst
       , SUM(SL.[Amount Including VAT])   AS Total
       , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
       , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
       , RTRIM(BA.[Name])                    [Bank Name]
       , RTRIM(BA.[IBAN])                    [IBAN]
       , RTRIM(BA.[SWIFT Code])              [BIC]
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
       , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
       , MAX(CAST(CU.[Contract Status] AS int))               [Vertrag Status]
	   , SH.[Vertragsbeginn]				 [Period Begin]
	   , SH.[Vertragsende]				     [Period End]	
	   , SH.[VAT Registration No_]
       , SH.[Bill-to Contact]					
	   , SH.[Bill-to Name]				
	   , SH.[Bill-to Name 2]			
	   , SH.[Bill-to Address]					
	   , SH.[Bill-to Address 2]					
	   , SH.[Bill-to Post Code]					
	   , SH.[Bill-to City]						
	   , SH.[Bill-to Country_Region Code] AS [Bill-to Country Code]              	
       , COALESCE(NW.[Payment Reference],'''') [Payment Reference]
       , COALESCE(NW.[Payment Provider],'''') [Payment Provider]
    FROM [' + @Company + '$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
LEFT JOIN [' + @Company + '$NewWork Fee] AS NW WITH (READUNCOMMITTED) ON CASE WHEN CHARINDEX(''/'',SH.[No_])>0 THEN LEFT(SH.[No_],CHARINDEX(''/'',SH.[No_])-1) ELSE SH.[No_] END = NW.[Posted Invoice No_]
    JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
      ON SH.[Sell-to Customer No_] = CU.[No_]
    JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
      ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
    JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
      ON SH.[Salesperson Code] = SP.Code 
    JOIN [' + @Company + '$Sales Invoice Line] AS SL WITH (READUNCOMMITTED) 
      ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [' + @Company + '$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = SH.[Sell-to Customer No_]
   WHERE (SH.No_ = ''' + @ReNr + ''')
GROUP BY SH.[Pre-Assigned No_]
       , SH.[No_]
       , SH.[Sell-to Customer No_]
       , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END 
         , SH.[Sell-to Post Code]
         , SH.[Sell-to Country_Region Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , SH.[Language Code]                  
         , SP.[Fax Extension]              
         , SP.[Phone Extension]            
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
       , SH.[Document Date]
       , SH.[Posting Description]       
       , SH.[Currency Code]
       , SH.[Currency Factor]
       , RTRIM(BA.[Bank Branch No_])
       , RTRIM(BA.[Bank Account No_])
       , RTRIM(BA.[Name])
       , RTRIM(BA.[IBAN])
       , RTRIM(BA.[SWIFT Code])
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
	   , SH.[Vertragsbeginn]				 
	   , SH.[Vertragsende]	
	   , SH.[VAT Registration No_]	
	   , SH.[Bill-to Contact]					
	   , SH.[Bill-to Name]				
	   , SH.[Bill-to Name 2]			
	   , SH.[Bill-to Address]					
	   , SH.[Bill-to Address 2]					
	   , SH.[Bill-to Post Code]					
	   , SH.[Bill-to City]						
	   , SH.[Bill-to Country_Region Code]		 	
       , COALESCE(NW.[Payment Reference],'''')
       , COALESCE(NW.[Payment Provider],'''')
       '
	PRINT(@SQLStatement)  
	EXECUTE(@SQLStatement)       

	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
  INSERT INTO #RESULTS
  SELECT SH.[No_]
       , SH.[No_]
       , SH.[Sell-to Customer No_]
       , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , SH.[Sell-to Post Code]
		 , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Country_Region Code] AS [Sell-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Durchwahl Fax]
         , SP.[Phone Extension]             AS [Durchwahl Telefon]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
       , SH.[Document Date]
       , SH.[Posting Description]       
       , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END [Currency Code]
       , SH.[Currency Factor]
       , MAX(SL.[VAT %])                  AS VAT
       , SUM(SL.[Unit Price])-SUM([Line Discount Amount]) AS Amount
       , SUM(SL.[Outstanding Amount]) - (SUM(SL.[Unit Price])-SUM([Line Discount Amount])) AS Mwst
       , SUM(SL.[Outstanding Amount])   AS Total
       , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
       , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
       , RTRIM(BA.[Name])                    [Bank Name]
       , RTRIM(BA.[IBAN])                    [IBAN]
       , RTRIM(BA.[SWIFT Code])              [BIC]
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
       , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
       , MAX(CAST(CU.[Contract Status] AS int))               [Vertrag Status]
	   , SH.[Vertragsbeginn]				 [Period Begin]
	   , SH.[Vertragsende]				 [Period End]	
	   , SH.[VAT Registration No_]
	   , SH.[Bill-to Contact]					
	   , SH.[Bill-to Name]				
	   , SH.[Bill-to Name 2]			
	   , SH.[Bill-to Address]					
	   , SH.[Bill-to Address 2]					
	   , SH.[Bill-to Post Code]					
	   , SH.[Bill-to City]						
	   , SH.[Bill-to Country_Region Code] AS [Bill-to Country Code] 
       , COALESCE(NW.[Payment Reference],'''') [Payment Reference]
       , COALESCE(NW.[Payment Provider],'''') [Payment Provider]
    FROM [' + @Company + '$Sales Header] AS SH WITH (READUNCOMMITTED)
LEFT JOIN [' + @Company + '$NewWork Fee] AS NW WITH (READUNCOMMITTED) ON CASE WHEN CHARINDEX(''/'',SH.[No_])>0 THEN LEFT(SH.[No_],CHARINDEX(''/'',SH.[No_])-1) ELSE SH.[No_] END = NW.[Unposted Invoice No_]
    JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
      ON SH.[Sell-to Customer No_] = CU.[No_]
    JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
      ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
    JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
      ON SH.[Salesperson Code] = SP.Code 
    JOIN [' + @Company + '$Sales Line] AS SL WITH (READUNCOMMITTED) 
      ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [' + @Company + '$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = SH.[Sell-to Customer No_]
   WHERE (SH.No_ = ''' + @ReNr + ''')
GROUP BY SH.[No_]
       , SH.[No_]
       , SH.[Sell-to Customer No_]
       , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END 
         , SH.[Sell-to Post Code]
         , SH.[Sell-to Country_Region Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , SH.[Language Code]                  
         , SP.[Fax Extension]              
         , SP.[Phone Extension]            
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
       , SH.[Document Date]
       , SH.[Posting Description]       
       , SH.[Currency Code]
       , SH.[Currency Factor]
       , RTRIM(BA.[Bank Branch No_])
       , RTRIM(BA.[Bank Account No_])
       , RTRIM(BA.[Name])
       , RTRIM(BA.[IBAN])
       , RTRIM(BA.[SWIFT Code])
       , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
	   , SH.[Vertragsbeginn]				
	   , SH.[Vertragsende]
	   , SH.[VAT Registration No_]	
	   , SH.[Bill-to Contact]					
	   , SH.[Bill-to Name]				
	   , SH.[Bill-to Name 2]			
	   , SH.[Bill-to Address]					
	   , SH.[Bill-to Address 2]					
	   , SH.[Bill-to Post Code]					
	   , SH.[Bill-to City]						
	   , SH.[Bill-to Country_Region Code]	 
       , COALESCE(NW.[Payment Reference],'''')
       , COALESCE(NW.[Payment Provider],'''')
       '
	PRINT (@SQLStatement)  
	EXECUTE(@SQLStatement)  
	SELECT * FROM #RESULTS
END
GO
