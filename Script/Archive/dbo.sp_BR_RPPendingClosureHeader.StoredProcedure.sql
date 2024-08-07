USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_BR_RPPendingClosureHeader]    Script Date: 10.04.2024 14:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Mohamed Zayed
-- Create date: 24.02.2014
-- Description:	Mahnungskopf für Pending Closure/Closure   CN
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 24.02.14 HRS001    82778  ZM     Objekt erstellt für Pending Closure/Closure
-- 
--
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'BR1000000002'
EXEC [dbo].[sp_BR_RPPendingClosureHeader] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_BR_RPPendingClosureHeader] 
    @ReNr varchar(25)
AS
BEGIN
  DECLARE @IssuedReminder varchar(20), @MaxDocumentDate DATETIME 
   ;WITH RH AS
   (
     SELECT RH.[Customer No_]
          , RH.[Document Date]
       FROM [HRS-BR$Issued Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
    UNION
     SELECT RH.[Customer No_]
          , RH.[Document Date]
       FROM [HRS-BR$Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
   ), RH_MAX AS
   (
     SELECT RH.[Customer No_]
          , MAX(IH.[Document Date]) [Document Date]
       FROM RH
       JOIN [HRS-BR$Issued Reminder Header] IH WITH (READUNCOMMITTED)
         ON IH.[Customer No_] = RH.[Customer No_]
      WHERE RH.[Document Date] > IH.[Document Date]
        AND IH.[Document Type] <> '20'
        AND IH.[Document Type] <> '21'
   GROUP BY RH.[Customer No_]
   )
   SELECT @IssuedReminder = RH.[No_]
        , @MaxDocumentDate = RH_MAX.[Document Date]
     FROM [HRS-BR$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN RH_MAX
       ON RH_MAX.[Customer No_] = RH.[Customer No_]
      AND RH_MAX.[Document Date] = RH.[Document Date]
      AND RH.[Document Type] <> '20'
      AND RH.[Document Type] <> '20'

PRINT @MaxDocumentDate 
     
  DECLARE @CurrencyCode VARCHAR(10), @CurrencyFactor DECIMAL(38,20)
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS-BR$Issued Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  IF @CurrencyCode IS NULL  
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS-BR$Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  SET NOCOUNT ON;
   SELECT RH.[No_]
        , REPLACE(RH.[Name 2],CHAR(10),'') [Name 2]
        , RH.[Customer No_]
        , REPLACE(RH.[Name],CHAR(10),'') [Name]
        , REPLACE(RH.[Address],CHAR(10),'') [Address]
        , REPLACE(RH.[Address 2],CHAR(10),'') [Address 2]
        , RH.[Post Code]
        , RH.[City]
        , RH.[Document Date]
        , RH.[Posting Date]
        , RH.[Due Date]
        , CU.[Currency Code] [Customer Currency Code]
        , @CurrencyCode [Currency Code]
        , @CurrencyFactor [Currency Factor]
        , RH.[Reminder Level]
        , RH.[Country_Region Code]
        , RH.[Language Code]   
        , CO.[Name] [Countryname]
        , CASE 
            WHEN RH.[Document Type] = '16'           THEN COALESCE(PEG.[Fax Extension for Reminder],'392')
            WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
            WHEN COALESCE(RC.[Fax No_],'') = ''      THEN COALESCE(PG.[Fax Extension for Reminder],'392') 
            ELSE COALESCE(RC.[Fax No_],'') 
          END [Fax Extension]
        , CASE 
            WHEN COALESCE(RC.[Phone No_],'') = '' THEN COALESCE(PG.[Phone Extension],'800') 
            ELSE COALESCE(RC.[Phone No_],'') 
          END [Phone Extension]
        , CO.[Continent]
        , CU.[Payment Method Code]
        , CASE WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
            ''
          ELSE
            CASE 
              WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 ' + COALESCE(PG.[Phone Extension],'800') + ' Fax: +86(0)21 5197 6449'
              WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 ' + COALESCE(PG.[Phone Extension],'800') + ' Fax: +86(0)21 5197 6448'
              ELSE
                ''
            END    
          END [Special Fax]
        , CASE 
            WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%'       THEN
              'email: accounting_fax@hrs.cn'
            WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
              'email: accounting_fax@hrs.cn'
            WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN 
              '3634@hrs.de'
            WHEN RH.[Document Type] = '16'                                  THEN 
              COALESCE(PEG.[Fax Extension for Reminder],'392') + '@hrs.de'
            WHEN COALESCE(RC.[Fax No_],'') = ''                             THEN 
              COALESCE(PG.[Fax Extension for Reminder],'392') + '@hrs.de' 
            ELSE 
              COALESCE(RC.[Fax No_] + '@hrs.de','') 
          END [Special E-Mail]
        , @IssuedReminder [Last Issued Reminder No_]
     FROM [HRS-BR$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN [HRS-BR$Country_Region]         CO WITH (READUNCOMMITTED)
       ON CO.[Code] = RH.[Country_Region Code]
     JOIN [HRS-BR$Customer]               CU WITH (READUNCOMMITTED)
       ON CU.[No_]  = RH.[Customer No_] 
LEFT JOIN [HRS-BR$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS-BR$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
LEFT JOIN [HRS-BR$Printer Group]          PEG WITH (READUNCOMMITTED)
       ON PEG.[Code]                  = 'PEGASUS'				
    WHERE RH.[No_] = @ReNr
UNION    
   SELECT RH.[No_]
        , REPLACE(RH.[Name 2],CHAR(10),'') [Name 2]
        , RH.[Customer No_]
        , REPLACE(RH.[Name],CHAR(10),'') [Name]
        , REPLACE(RH.[Address],CHAR(10),'') [Address]
        , REPLACE(RH.[Address 2],CHAR(10),'') [Address 2]
        , RH.[Post Code]
        , RH.[City]
        , RH.[Document Date]
        , RH.[Posting Date]
        , RH.[Due Date]
        , CU.[Currency Code] [Customer Currency Code]
        , @CurrencyCode [Currency Code]
        , @CurrencyFactor [Currency Factor]
        , RH.[Reminder Level]
        , RH.[Country_Region Code]
        , RH.[Language Code]       
        , CO.[Name] [Countryname]
        , CASE 
            WHEN RH.[Document Type] = '16'           THEN COALESCE(PEG.[Fax Extension for Reminder],'392')
            WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
            WHEN COALESCE(RC.[Fax No_],'') = ''      THEN COALESCE(PG.[Fax Extension for Reminder],'392') 
            ELSE COALESCE(RC.[Fax No_],'') 
          END [Fax Extension]
        , CASE WHEN COALESCE(RC.[Phone No_],'') = '' THEN COALESCE(PG.[Phone Extension],'800') 
          ELSE COALESCE(RC.[Phone No_],'') END [Phone Extension]
        , CO.[Continent]
        , CU.[Payment Method Code]
        , CASE WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
            ''
          ELSE
            CASE 
              WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 ' + COALESCE(PG.[Phone Extension],'800') + ' Fax: +86(0)21 5197 6449'
              WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 ' + COALESCE(PG.[Phone Extension],'800') + ' Fax: +86(0)21 5197 6448'
              ELSE
                ''
            END    
          END [Special Fax]
        , CASE 
            WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%'       THEN
              'email: accounting_fax@hrs.cn'
            WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
              'email: accounting_fax@hrs.cn'
            WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN 
              '3634@hrs.de'
            WHEN RH.[Document Type] = '16'                                  THEN 
              COALESCE(PEG.[Fax Extension for Reminder],'392') + '@hrs.de'
            WHEN COALESCE(RC.[Fax No_],'') = ''                             THEN 
              COALESCE(PG.[Fax Extension for Reminder],'392') + '@hrs.de' 
            ELSE 
              COALESCE(RC.[Fax No_] + '@hrs.de','') 
          END [Special E-Mail]
        , @IssuedReminder
     FROM [HRS-BR$Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN [HRS-BR$Country_Region]         CO WITH (READUNCOMMITTED)
       ON CO.[Code] = RH.[Country_Region Code]
     JOIN [HRS-BR$Customer]               CU WITH (READUNCOMMITTED)
       ON CU.[No_]  = RH.[Customer No_]
LEFT JOIN [HRS-BR$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS-BR$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
LEFT JOIN [HRS-BR$Printer Group]          PEG WITH (READUNCOMMITTED)
       ON PEG.[Code]                  = 'PEGASUS'				
    WHERE RH.[No_] = @ReNr
END




GO
