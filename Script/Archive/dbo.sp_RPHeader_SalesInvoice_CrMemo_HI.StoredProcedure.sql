USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPHeader_SalesInvoice_CrMemo_HI]    Script Date: 10.04.2024 14:31:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 16.06.2016
-- Description:	Rechnungskopf für Debitor-Rechnung
--              Kopie von [sp_RPMarketingSalesInvoiceHeader_HI] 
--
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
/*
Beispiel Rechnung
DECLARE @ReNr			VARCHAR(20)     ='R10017343'
      , @Company		VARCHAR(30)		='HRS Holidays'
	  , @DocumentTyp	INT				= 02
EXEC [dbo].[sp_RPHeader_SalesInvoice_CrMemo_HI] @ReNr, @Company, @DocumentTyp 

Beispiel Gutschrift
DECLARE @ReNr			VARCHAR(20)     ='020148'
      , @Company		VARCHAR(30)		='HRS Holidays'
	  , @DocumentTyp	INT				= 03
EXEC [dbo].[sp_RPHeader_SalesInvoice_CrMemo_HI] @ReNr, @Company, @DocumentTyp 
*/
-- ============================================= 
create PROCEDURE [dbo].[sp_RPHeader_SalesInvoice_CrMemo_HI] 
    @ReNr			VARCHAR(20)
  , @Company		VARCHAR(30)
  , @DocumentTyp	INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
  
	CREATE TABLE #RESULTS 
	( 
		[No_]								VARCHAR(250)
	  , [Sell-to Customer No_]				VARCHAR(250)
	  , [Sell-to Contact]					VARCHAR(250)
	  , [Sell-to Customer Name]				VARCHAR(250)
	  , [Sell-to Customer Name 2]			VARCHAR(250)
	  , [Sell-to Address]					VARCHAR(250)
	  , [Sell-to Address 2]					VARCHAR(250)
	  , [Sell-to City]						VARCHAR(250)
	  , [Sell-to Post Code]					VARCHAR(250)
	  , [Sell-to Country Code]              VARCHAR(250)
	  , [Bill-to Customer No_]				VARCHAR(250)
	  , [Posting Date]                      DATETIME
	  , [Payment Method Code]				VARCHAR(250)
	  , [EU Ländercode]						VARCHAR(250)
	  , [ISO_Code]							VARCHAR(250)
	  , [Durchwahl Fax]						VARCHAR(250)
	  , [Durchwahl Telefon]					VARCHAR(250)
	  , [Name]								VARCHAR(250)
	  , [Document Date]						DATETIME
	  , [Posting Description]				VARCHAR(250)
	  , [Currency Code]						VARCHAR(20)
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
	  , [SEPA]								TINYINT
	  , [Vertrag Status]					TINYINT
	  , [VAT Registration No_]				VARCHAR(20)
	)
	
	SET @SQLStatement = 
'   INSERT INTO #RESULTS
    SELECT SH.[Pre-Assigned No_]							[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
         , CASE WHEN SH.[Bill-to Country_Region Code] = '''' THEN ''33'' ELSE	SH.[Bill-to Country_Region Code] END [Bill-to Country Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]													[EU Ländercode]
         , CASE WHEN (SH.[Language Code] = '''') OR (SH.[Language Code] = ''DE'') THEN 0 ELSE SH.[Language Code] END		[ISO_Code]
         , SP.[Fax Extension]															[Durchwahl Fax]
         , SP.[Phone Extension]															[Durchwahl Telefon]
         , CO.[Name]																	[Name]
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END	[Currency Code]
         , SH.[Currency Factor]
         , MAX(SL.[VAT %])																[VAT]
         , SUM(SL.Amount)																[Amount]
         , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount)								[Mwst]
         , SUM(SL.[Amount Including VAT])												[Total]
         , RTRIM(BA.[Bank Branch No_])													[Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])													[Bank Account No_]
         , RTRIM(BA.[Name])																[Bank Name]
         , RTRIM(BA.[IBAN])																[IBAN]
         , RTRIM(BA.[SWIFT Code])														[BIC]
         , CASE WHEN SH.[Language Code] = '''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , MAX(CASE WHEN CO.[Bank Country Code] <> '''' THEN 1 ELSE 0 END)				[SEPA]
         , MAX(CAST(CU.[Contract Status] AS int))										[Vertrag Status]
		 , SH.[VAT Registration No_]	
      FROM [' + @Company + CASE WHEN @DocumentTyp = 2 
								THEN + '$Sales Invoice Header]'
								ELSE + '$Sales Cr_Memo Header]'
						   END + ' AS SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]  
      JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
        ON CASE WHEN (SH.[Bill-to Country_Region Code] = ''0'') OR (SH.[Bill-to Country_Region Code] = '''')
				THEN ''33'' 
				ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN [' + @Company + CASE WHEN @DocumentTyp = 2 
								THEN + '$Sales Invoice Line]'
								ELSE + '$Sales Cr_Memo Line]'
						   END + ' AS SL WITH (READUNCOMMITTED) 
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
     WHERE (SH.No_ = ''' + @ReNr + ''')
  GROUP BY SH.[Pre-Assigned No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END 
         , SH.[Sell-to Post Code]
         , CASE WHEN SH.[Bill-to Country_Region Code] = '''' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , CASE WHEN (SH.[Language Code] = '''') OR (SH.[Language Code] = ''DE'') THEN 0 ELSE SH.[Language Code] END                  
         , SP.[Fax Extension]              
         , SP.[Phone Extension]            
         , CO.[Name] 
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
         , SH.[Currency Factor]
         , RTRIM(BA.[Bank Branch No_])
         , RTRIM(BA.[Bank Account No_])
         , RTRIM(BA.[Name])
         , RTRIM(BA.[IBAN])
         , RTRIM(BA.[SWIFT Code])
         , CASE WHEN SH.[Language Code] = '''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
		 , SH.[VAT Registration No_]	
       '
	PRINT(@SQLStatement)  
	EXECUTE(@SQLStatement)       

	SELECT * FROM #RESULTS
END


GO
