USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceHeader_HRS002]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 17.06.2011
-- Description:	Kopie der SP vom P-NAV-MSSQL-1
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 07.07.11 HRS001    27148  JH bss Um die Servicegebühr im Beleg darzustellen wurde die Berechnung für Mwst und Amount geändert. Außerdem das
--                                  Feld Service Amount hinzugefügt.
-- 21.09.11 HRS002    49724  TM     [Hide Amount] eingefügt zur Steuerung der Ausgabe der Betragswerte
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'V000987279'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader] @ReNr

SELECT * FROM [HRS$Agency Display Header] AH WHERE AH.[Posted Invoice No_] = @ReNr
*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceHeader_HRS002] 
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr

    -- Insert statements for procedure here
    SELECT AH.[Bill-to Customer No_]
         , AH.[Posting Date]
         , AH.[Creation Date]                  [Document Date]
         , AH.[Currency Code]
         , CASE WHEN AH.[Currency Factor]=0 THEN 1 ELSE AH.[Currency Factor] END [Currency Factor]
         , CASE WHEN AH.[Language Code]='' THEN CO.[Primary Language Code] ELSE AH.[Language Code] END [Language Code]
         , AH.[Bill-to Name]                AS [Sell-to Customer Name]
         , AH.[Bill-to Name 2]              AS [Sell-to Customer Name 2]
         , AH.[Bill-to Address]             AS [Sell-to Address]
         , AH.[Bill-to Address 2]           AS [Sell-to Address 2]
         , AH.[Bill-to City]                AS [Sell-to City]
         , AH.[Bill-to Post Code]           AS [Sell-to Post Code]
         , AH.[Bill-to Country_Region Code] AS [Sell-to Country Code]
         , AH.[Bill-to Contact]             AS [Sell-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CO.Name
         , CO.[EU Country_Region Code][EU Ländercode]
         , CASE 
             --WHEN CU.[Contract Status] IN('10','11') 
             -- AND AH.MuseID<>'HRS' 
             -- AND CU.[Payment Method Code] <> 'SEPA'
             -- AND NOT CU.[Payment Method Code] LIKE 'LAST%'
             -- AND COALESCE(PG.[Fax Extension],'')<>'' THEN PG.[Fax Extension] 
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END [Durchwahl Fax]
         , RTRIM(BA.[Bank Branch No_]) [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_]) [Bank Account No_]
         , RTRIM(BA.[Name])                                     [Bank Name]
         , RTRIM(BA.[IBAN])                                     [IBAN]
         , RTRIM(BA.[SWIFT Code])                               [BIC]
         , LA.[ISO Code]                                        [ISO_Code]
         , CASE WHEN (COALESCE(SH.[Gen_ Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' THEN 19   ELSE 0 END [VAT]
         , SUM(ROUND(AL.[Line Amount],2))                                [Amount]
         , SUM(ROUND(AL.[Line Amount],2)) 
         * CASE WHEN (COALESCE(SH.[Gen_ Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' THEN 0.19 ELSE 0 END [Mwst]
         , SUM(ROUND(AL.[Line Amount],2)) 
         * CASE WHEN (COALESCE(SH.[Gen_ Bus_ Posting Group],'INLAND') = 'INLAND' OR AH.[Posted Invoice No_] = '' ) AND AH.[Bill-to Country_Region Code] = '33' THEN 1.19 ELSE 1 END [Total]
         , MAX(CAST(JO.[Contract Status] AS int))               [Vertrag Status]
         , COALESCE(DA.[Hide Amount],0)                         [Hide Amount]
         , MAX(CO.Continent)                                    Continent
         , MAX(CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END) SEPA
         , CASE WHEN [Posted Invoice No_]='' THEN AH.[Unposted Invoice No_] ELSE [Posted Invoice No_] END [Posted Invoice No_]
         , MAX(
           CASE 
             WHEN AH.[Document Type] = '18' THEN 'Tel. +49 (0) 221 2077-3198 - Fax +49 (0) 221 2077-' + COALESCE(DP.[Fax Extension], SP.[Fax Extension])             
             WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
               ''
             ELSE
               CASE 
                 WHEN ',29,57,92,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
                   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6441'
                 WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN
                   'Tel +86 (0) 21 5197 6705 - Fax +86 (0) 21 5197 6447'
                 ELSE
                   ''
               END    
           END) [Special Fax]
         , CASE 
             WHEN AH.[Document Type] = '18' THEN COALESCE(DP.[Salesperson E-Mail], SP.[Salesperson E-Mail])             
             WHEN CU.[Contract Status] IN('10','11') 
              AND AH.MuseID<>'HRS' 
              AND CU.[Payment Method Code] <> 'SEPA'
              AND NOT CU.[Payment Method Code] LIKE 'LAST%'
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN PG.[Salesperson E-Mail] 
             WHEN ',29,57,92,10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 'accounting@hrs.de'
           END [Special E-Mail]
         , AH.MuseID
         , CU.[Contract Status]
         , AH.[Document Type]
         , AH.[Loyality Rewards Account No_] [Special Text]
      FROM [HRS$Agency Display Header]        AH WITH (READUNCOMMITTED)
      JOIN [HRS$Agency Display Line]          AL WITH (READUNCOMMITTED)
        ON AL.[Display Case No_] = AH.[Case No_]
       AND AL.[Action] <> 3
      JOIN [HRS$Customer]                     CU WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = CU.[No_] 
      JOIN [HRS$Country_Region]               CO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Country_Region Code] = CO.Code
      JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON AH.[Language Code]               = LA.Code 
      JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                DP WITH (READUNCOMMITTED)
        ON DP.[Code]                        = AH.[Salesperson Code]
 LEFT JOIN [HRS$Printer Group]                PG WITH (READUNCOMMITTED)
        ON PG.[Code]                        = 'PEGASUS'
 LEFT JOIN [HRS$Printer Group]                SE WITH (READUNCOMMITTED)
        ON SE.[Code]                        = 'SEPA'
      JOIN [HRS$Customer]                          JO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS$Sales Invoice Header]         SH WITH (READUNCOMMITTED)
        ON SH.[No_] = AH.[Posted Invoice No_]
 LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
        ON CU.[Responsibility Center] = RC.Code
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
 LEFT JOIN [HRS$Document Type Assignment] DA WITH (READUNCOMMITTED)
        ON DA.[Brand Code]                  = AH.[Brand Code]
       AND DA.[Muse ID]                     = AH.[MuseID]
       AND DA.[Document Type]               = AH.[Document Type]
     WHERE AH.[Posted Invoice No_] = @ReNr2
        OR AH.[Case No_] = @ReNr2
  GROUP BY AH.[Bill-to Customer No_]
         , COALESCE(SH.[Gen_ Bus_ Posting Group],'INLAND')
         , AH.[Posting Date]
         , AH.[Creation Date]
         , AH.[Currency Code]
         , AH.[Currency Factor]
         , CASE WHEN AH.[Language Code]='' THEN CO.[Primary Language Code] ELSE AH.[Language Code] END
         , AH.[Bill-to Name]
         , AH.[Bill-to Name 2]
         , AH.[Bill-to Address]
         , AH.[Bill-to Address 2]
         , AH.[Bill-to City]
         , AH.[Bill-to Post Code]
         , AH.[Bill-to Country_Region Code]
         , AH.[Bill-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CO.Name
         , CO.[EU Country_Region Code]
         , CASE 
             --WHEN CU.[Contract Status] IN('10','11') 
             -- AND AH.MuseID<>'HRS' 
             -- AND CU.[Payment Method Code] <> 'SEPA'
             -- AND NOT CU.[Payment Method Code] LIKE 'LAST%'
             -- AND COALESCE(PG.[Fax Extension],'')<>'' THEN PG.[Fax Extension] 
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END 
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]
         , BA.[IBAN] 
         , BA.[SWIFT Code]
         , COALESCE(DA.[Hide Amount],0)         
         , LA.[ISO Code]
         , CASE WHEN [Posted Invoice No_]='' THEN AH.[Unposted Invoice No_] ELSE [Posted Invoice No_] END
         , CASE 
             WHEN AH.[Document Type] = '18' THEN COALESCE(DP.[Salesperson E-Mail], SP.[Salesperson E-Mail])             
             WHEN CU.[Contract Status] IN('10','11') 
              AND AH.MuseID<>'HRS' 
              AND CU.[Payment Method Code] <> 'SEPA'
              AND NOT CU.[Payment Method Code] LIKE 'LAST%'
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN PG.[Salesperson E-Mail] 
             WHEN ',29,57,92,10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+AH.[Bill-to Country_Region Code]+',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 'accounting@hrs.de'
           END 
         , AH.MuseID
         , AH.[Posted Invoice No_]
         , CU.[Contract Status]
         , AH.[Document Type]
         , AH.[Loyality Rewards Account No_]
END
GO
