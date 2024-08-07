USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceHeader_HRS-BR]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 16.04.2014
-- Description:	

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 22.02.20 HRS001   ACS-1991 DJU   Added TAF
--
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'K000000009'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader_HRS-BR] @ReNr

SELECT * FROM [HRS-BR$Agency Display Header] AH WHERE AH.[Posted Invoice No_] = @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceHeader_HRS-BR]
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr

    -- Insert statements for procedure here
    ;WITH SH AS
    (
    SELECT AH.[Bill-to Customer No_]
         , AH.[Posting Date]
         , AH.[Creation Date]                  [Document Date]
         , AH.[Currency Code]
         , [dbo].[CurrencyExchangeBR](
               'BRL'  
             , AH.[Currency Code]
             , 1
             , AH.[Posting Date]
           )                                   [Currency Factor]
         , AH.[Language Code]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name]          ELSE P1.[Content]       END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name 2]        ELSE P2.[Content]       END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address]       ELSE P3.[Content]       END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address 2]     ELSE P4.[Content]       END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to City]          ELSE P5.[Content]       END [Sell-to City]
         , AH.[Bill-to Post Code]           AS [Sell-to Post Code]
         , AH.[Bill-to Country_Region Code] AS [Sell-to Country Code]
         , CU.[VAT Registration No_]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , AH.[VAT Bus_ Posting Group]
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                    ELSE P6.[Content]       END Name
         , CO.[EU Country_Region Code][EU Ländercode]
         , SP.[Fax Extension]                                   [Durchwahl Fax]
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]                                            [Bank Name]
         , BA.[IBAN]                                            [IBAN]
         , LA.[ISO Code]                                        [ISO_Code]
         , 0.0 [VAT]
         , [dbo].[CurrencyExchangeBR](
               AH.[Currency Code]  
             , 'BRL'
             , SUM(ROUND(AL.[Line Amount],2))
             , AH.[Posting Date]
           )                                                    [Amount]
         , SUM(ROUND(AL.[Line Amount],2))                       [Amount (LCY)]
         , 0.0 [Mwst]
         , 0                                                    [Total]
         , MAX(CAST(JO.[Contract Status] AS int))               [Vertrag Status]
         , COALESCE(DA.[Hide Amount],0)                         [Hide Amount]
         , MAX(CO.Continent)                                    Continent
         , MAX(CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END) SEPA
		 -- 22.02.20 DJU >>>>>>>>>>>>>>>>>>>> HRS001
		 , SUM(ROUND(AL.[Line Amount],2)) - SUM(ROUND(AL.[TAF Line Amount],2)) [Commission Amount]
		 , SUM(ROUND(AL.[TAF Line Amount],2)) [TAF Amount]
		 -- 22.02.20 DJU <<<<<<<<<<<<<<<<<<<< HRS001
      FROM [HRS-BR$Agency Display Header]        AH WITH (READUNCOMMITTED)
      JOIN [HRS-BR$Agency Display Line]          AL WITH (READUNCOMMITTED)
        ON AL.[Display Case No_] = AH.[Case No_]
       AND AL.[Action] <> 3
      JOIN [HRS-BR$Customer]                     CU WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = CU.[No_] 
      JOIN [HRS-BR$Country_Region]               CO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Country_Region Code] = CO.Code
 LEFT JOIN [HRS-BR$Language]                     LA WITH (READUNCOMMITTED)
        ON AH.[Language Code]               = LA.Code 
 LEFT JOIN [HRS-BR$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS-BR$Job]                          JO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS-BR$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS-BR$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
 LEFT JOIN [HRS-BR$Document Type Assignment] DA WITH (READUNCOMMITTED)
        ON DA.[Brand Code]                  = AH.[Brand Code]
       AND DA.[Muse ID]                     = AH.[MuseID]
       AND DA.[Document Type]               = AH.[Document Type]
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = AH.[Bill-to Customer No_]
     WHERE AH.[Posted Invoice No_] = @ReNr2
        OR AH.[Case No_] = @ReNr2
  GROUP BY AH.[Bill-to Customer No_]
         , AH.[Posting Date]
         , AH.[Creation Date]
         , AH.[Currency Code]
         , AH.[Currency Factor]
         , AH.[Language Code]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name]          ELSE P1.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name 2]        ELSE P2.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address]       ELSE P3.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address 2]     ELSE P4.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to City]          ELSE P5.[Content]       END
         , AH.[Bill-to Post Code]
         , AH.[Bill-to Country_Region Code]
         , AH.[VAT Bus_ Posting Group]
         , CU.[VAT Registration No_]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                    ELSE P6.[Content]       END
         , CO.[EU Country_Region Code]
         , SP.[Fax Extension] 
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]
         , BA.[IBAN] 
         , COALESCE(DA.[Hide Amount],0)         
         , LA.[ISO Code]
    ), L AS
    (
    SELECT MAX(Limit) [Limit]
      FROM [HRS-BR$VAT Posting Setup Brasil] PS
      JOIN SH 
        ON SH.[VAT Bus_ Posting Group] = PS.[VAT Bus_ Posting Group]
       AND [Limit] <= SH.[Amount]
       
    ), V AS
    (
    SELECT ROUND(SH.[Amount] * (100 + CASE WHEN BS.[Withholding]<>0 THEN -BS.[Withholding] ELSE PS.[VAT %]END) / 100,2) [Invoiced Amount]
         , ROUND(SH.[Amount] / (100 - (CASE WHEN BS.[Withholding]<>0 THEN 0 ELSE [ISS %] + [PIS %] + [CONFIS %] + [CSLL %] END)) * 100,2) [Invoiced Bruto Amount]
         , CASE WHEN [Sales IRRF Account]=''   THEN 0 ELSE [IRRF %]   END [IRRF %]
         , ROUND(SH.[Amount] / (100 - (
                                                 - CASE WHEN [Sales IRRF Account]=''   THEN 0 ELSE [IRRF %]   END 
                                                 + CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END 
                                                 + CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END
                                                 + CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END
                                                 + CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END
                                       ))        * CASE WHEN [Sales IRRF Account]=''   THEN 0 ELSE [IRRF %]   END,2) [IRRF Amount]
         , CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END [ISS %]
         , ROUND(SH.[Amount] / (100 - (            CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END 
                                                 + CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END
                                                 + CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END
                                                 + CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END
                                       ))        * CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END,2) [ISS Amount]
         , CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END [PIS %]
         , ROUND(SH.[Amount] / (100 - (            CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END 
                                                 + CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END
                                                 + CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END
                                                 + CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END
                                       ))        * CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END,2) [PIS Amount]
         , CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END [CONFIS %]
         , ROUND(SH.[Amount] / (100 - (            CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END 
                                                 + CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END
                                                 + CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END
                                                 + CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END
                                      ))         * CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END,2) [CONFIS Amount]
         , CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END [CSLL %]
         , ROUND(SH.[Amount] / (100 - (            CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END 
                                                 + CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END
                                                 + CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END
                                                 + CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END
                                      ))         * CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END,2) [CSLL Amount]
         , CASE 
             WHEN BS.[Withholding] <> 0 THEN BS.[Withholding] 
             WHEN CASE WHEN [Sales ISS Account]=''    THEN 0 ELSE [ISS %]    END 
                + CASE WHEN [Sales PIS Account]=''    THEN 0 ELSE [PIS %]    END
                + CASE WHEN [Sales CONFIS Account]='' THEN 0 ELSE [CONFIS %] END
                + CASE WHEN [Sales CSLL Account]=''   THEN 0 ELSE [CSLL %]   END
                =0 THEN 1
             ELSE BS.[Withholding]
           END [Withholding]
      FROM [HRS-BR$VAT Posting Setup Brasil] BS
      JOIN [HRS-BR$VAT Posting Setup] PS
        ON BS.[VAT Bus_ Posting Group] = PS.[VAT Bus_ Posting Group]
       AND BS.[VAT Prod_ Posting Group]= PS.[VAT Prod_ Posting Group]
      JOIN SH 
        ON SH.[VAT Bus_ Posting Group] = BS.[VAT Bus_ Posting Group]
      JOIN L ON L.[Limit] = BS.[Limit]
    )
    SELECT TOP 1 * FROM SH, V
END
GO
