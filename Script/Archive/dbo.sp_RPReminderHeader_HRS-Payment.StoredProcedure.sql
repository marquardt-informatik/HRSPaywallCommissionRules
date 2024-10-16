USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPReminderHeader_HRS-Payment]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.07.2012
-- Description:	Mahnungszeilen
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 27.09.13 HRS001    80866  TM     Für Deutschland <Fax-Nummer>@hrs.de statt accounting@hrs.de
-- 17.11.14 HRS002    XXXXX  ZD     Last issue remainder date "field"
-- 17.11.14 HRS003    XXXXX  ZD     Adding Bank Info
-- 12.10.17 HRS004    ACS-60        SAK BUG Neue Mahnstufen
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '3001532778'
EXEC [dbo].[sp_RPReminderHeader_2014] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPReminderHeader_HRS-Payment] 
    @ReNr varchar(25)
AS
BEGIN
  DECLARE @CurrencyCode VARCHAR(10), @CurrencyFactor DECIMAL(38,20)
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS Payment$Issued Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  IF @CurrencyCode IS NULL  
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS Payment$Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  SET NOCOUNT ON; 
  
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HRS002  Last issue remainder date "field"
 DECLARE @IssuedReminder varchar(20), @MaxDocumentDate DATETIME, @CustomerNo VARCHAR(20), @CountryCode varchar(10) 
   ;WITH RH AS
   (
     SELECT RH.[Customer No_]
          , RH.[Document Date]
          , RH.[Document Type]
       FROM [HRS Payment$Issued Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
    UNION
     SELECT RH.[Customer No_]
          , RH.[Document Date]
          , RH.[Document Type]
       FROM [HRS Payment$Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
   ), RH_MAX AS
   (
     SELECT RH.[Customer No_]
          , MAX(IH.[Document Date]) [Document Date]
       FROM RH
       JOIN [HRS Payment$Issued Reminder Header] IH WITH (READUNCOMMITTED)
         ON IH.[Customer No_] = RH.[Customer No_]
      WHERE (
            RH.[Document Date] > IH.[Document Date]
       -- AND IH.[Document Type] <> '20'
        --AND IH.[Document Type] <> '21'
        --AND RH.[Document Type] <> '25'
        --AND RH.[Document Type] <> '26'
        --    )
       --  OR (
        --    IH.[Document Type] = '25' 
       -- AND RH.[Document Type] = '26'
            )
   GROUP BY RH.[Customer No_]
   )
   SELECT @IssuedReminder = RH.[No_]
        , @MaxDocumentDate = RH_MAX.[Document Date]
        , @CustomerNo = RH_MAX.[Customer No_]
		, @CountryCode = RH.[Country_Region Code]
     FROM [HRS Payment$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN RH_MAX
       ON RH_MAX.[Customer No_] = RH.[Customer No_]
      AND RH_MAX.[Document Date] = RH.[Document Date]
      --AND RH.[Document Type] <> '20'
      --AND RH.[Document Type] <> '21'

PRINT @MaxDocumentDate 
PRINT @CustomerNo
       
   SELECT RH.[No_]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Name 2],CHAR(10),'')    ELSE P2.[Content]       END [Name 2]
        , RH.[Customer No_]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Name],CHAR(10),'')      ELSE P1.[Content]       END [Name]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Address],CHAR(10),'')   ELSE P3.[Content]       END [Address]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Address 2],CHAR(10),'') ELSE P4.[Content]       END [Address 2]
        , RH.[Post Code]
        , CASE WHEN P1.[Content] IS NULL   THEN RH.[City]                           ELSE P5.[Content]       END [City]
        , RH.[Document Date]
        , RH.[Posting Date]
        , DATEADD(dd,14,RH.[Document Date]) [Due Date]
        , CU.[Currency Code] [Customer Currency Code]
        , @CurrencyCode [Currency Code]
        , @CurrencyFactor [Currency Factor]
        , CASE WHEN COALESCE(RH.[Reminder Level], '1') > 1 THEN '1' ELSE '0' END [Reminder Level]
        , RH.[Country_Region Code]
        , CASE WHEN COALESCE(RH.[Language Code], '') = '' THEN '0' ELSE RH.[Language Code] END [Language Code]
        , [Reminder Commission Amount].[Commission Amount] * @CurrencyFactor [Commission Amount]
        , [Reminder Interest Amount].[Interest Amount]                       [Interest Amount]
        , [Reminder Fee Amount].[Fee Amount]                                 [Fee Amount]
        , [Reminder Remaining Amount].[Remaining Amount]                     [Remaining Amount]
        , [Reminder VAT Amount].[VAT Amount]               * @CurrencyFactor [VAT Amount]
        , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                             ELSE P6.[Content]       END [Countryname]
        , CASE 
            WHEN RH.[Document Type] = '16'           THEN COALESCE(PEG.[Fax Extension for Reminder],'392')
            WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
            WHEN COALESCE(RC.[Fax No_],'') = ''      THEN COALESCE(PG.[Fax Extension for Reminder],'392') 
            ELSE COALESCE(RC.[Fax No_],'') 
          END [Fax Extension]
        , CASE WHEN COALESCE(PG.[Team Phone Extension],'')='' THEN '800' ELSE COALESCE(PG.[Team Phone Extension],'800') END [Phone Extension]
        , CO.[Continent]
        , CU.[Payment Method Code]
        , CASE WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
            ''
          ELSE
            CASE 
              WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 6705 Fax: +86(0)21 5197 6449'
              WHEN ',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 6705 Fax: +86(0)21 5197 6448'
              ELSE
                ''
            END    
          END [Special Fax]
        --, CASE 
        --    WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%'       THEN
        --      'email: accounting_fax@hrs.cn'
        --    WHEN ',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
        --      'email: accounting_fax@hrs.cn'
        --    WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN 
        --      '3634@hrs.de'
        --    WHEN RH.[Document Type] = '16'                                  THEN 
        --      COALESCE(PEG.[Fax Extension for Reminder],'392') + '@hrs.de'
        --    WHEN COALESCE(RC.[Fax No_],'') = ''                             THEN 
        --      COALESCE(PG.[Fax Extension for Reminder],'392') + '@hrs.de' 
        --    ELSE 
        --      COALESCE(RC.[Fax No_] + '@hrs.de','') 
        --  END [Special E-Mail]     
		, [Special E-Mail] = ''
        , [Reminder Remaining Amount].[Min_ Document Date]
        , [Reminder Remaining Amount].[Max_ Document Date]
        , [Service].[Hotel Turnover]
        , RH.[Contact]
        , PG.[Description] [Salesperson]
        , CU.[Salesperson Code]
        , @IssuedReminder [Last Issue Reminder]
        , @MaxDocumentDate [Last Issued Reminder Date]
        , CU.[Hotel Status]
        , CU.[Reason Code]
     FROM [HRS Payment$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN [HRS Payment$Country_Region]         CO WITH (READUNCOMMITTED)
       ON CO.[Code] = RH.[Country_Region Code]
     JOIN [HRS Payment$Customer]               CU WITH (READUNCOMMITTED)
       ON CU.[No_]  = RH.[Customer No_]
 --LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = RH.[Country_Region Code]    
 --LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = RH.[Country_Region Code]      
 --LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = RH.[Country_Region Code]       
LEFT JOIN [HRS Payment$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS Payment$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
LEFT JOIN [HRS Payment$Printer Group]          PEG WITH (READUNCOMMITTED)
       ON PEG.[Code]                  = 'PEGASUS'
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Commission Amount]
               FROM [HRS Payment$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 3
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Commission Amount] 
       ON RH.[No_] = [Reminder Commission Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(
                    CASE WHEN @CurrencyCode = 'EUR' THEN RL.[Amount] ELSE RL.[Amount] * @CurrencyFactor END
                    ) AS [Interest Amount]
               FROM [HRS Payment$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Interest Amount] ON RH.[No_] = [Reminder Interest Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Fee Amount]
               FROM [HRS Payment$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 1
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Fee Amount] ON RH.[No_] = [Reminder Fee Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , MIN(RL.[Document Date]) AS [Min_ Document Date]
                  , MAX(RL.[Document Date]) AS [Max_ Document Date]
                  , SUM(
                    CASE WHEN @CurrencyCode = 'EUR' THEN RL.[Remaining Amount] ELSE 
                      CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE
                        RL.[Remaining Amount] * @CurrencyFactor
                      END
                    END
                    ) AS [Remaining Amount]
               FROM [HRS Payment$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Remaining Amount] ON RH.[No_] = [Reminder Remaining Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(DL.[Commission Base Amount] * DL.[Number of Nights])  [Hotel Turnover]
               FROM [HRS Payment$Issued Reminder Line]  RL WITH (NOLOCK )
               JOIN [HRS Payment$Agency Display Header] DH WITH (NOLOCK)
                 ON DH.[Posted Invoice No_] = RL.[Document No_]
               JOIN [HRS Payment$Agency Display Line]   DL WITH (NOLOCK) 
                 ON DL.[Display Case No_] = DH.[Case No_]              
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
                AND DL.Action <> 3
           GROUP BY RL.[Reminder No_]
          ) AS [Service] ON RH.[No_] = [Service].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[VAT Amount]) AS [VAT Amount]
               FROM [HRS Payment$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder VAT Amount] ON RH.[No_] = [Reminder VAT Amount].[Reminder No_]					
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = RH.[Customer No_]
    WHERE RH.[No_] = @ReNr
UNION    
   SELECT RH.[No_]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Name 2],CHAR(10),'')    ELSE P2.[Content]       END [Name 2]
        , RH.[Customer No_]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Name],CHAR(10),'')      ELSE P1.[Content]       END [Name]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Address],CHAR(10),'')   ELSE P3.[Content]       END [Address]
        , CASE WHEN P1.[Content] IS NULL   THEN REPLACE(RH.[Address 2],CHAR(10),'') ELSE P4.[Content]       END [Address 2]
        , RH.[Post Code]
        , CASE WHEN P1.[Content] IS NULL   THEN RH.[City]                           ELSE P5.[Content]       END [City]
        , RH.[Document Date]
        , RH.[Posting Date]
        , DATEADD(dd,14,RH.[Document Date]) [Due Date]
        , CU.[Currency Code] [Customer Currency Code]
        , @CurrencyCode [Currency Code]
        , @CurrencyFactor [Currency Factor]
        , CASE WHEN COALESCE(RH.[Reminder Level], '1') > 1 THEN '1' ELSE '0' END [Reminder Level]
        , RH.[Country_Region Code]
		, CASE WHEN COALESCE(RH.[Language Code], '') = '' THEN '0' ELSE RH.[Language Code] END [Language Code]
        , [Reminder Commission Amount].[Commission Amount] * @CurrencyFactor [Commission Amount]
        , [Reminder Interest Amount].[Interest Amount]                       [Interest Amount]
        , [Reminder Fee Amount].[Fee Amount]                                 [Fee Amount]
        , [Reminder Remaining Amount].[Remaining Amount]                     [Remaining Amount]
        , [Reminder VAT Amount].[VAT Amount]               * @CurrencyFactor [VAT Amount]
        , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                             ELSE P6.[Content]       END [Countryname]
        , CASE 
            WHEN RH.[Document Type] = '16'           THEN COALESCE(PEG.[Fax Extension for Reminder],'392')
            WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
            WHEN COALESCE(RC.[Fax No_],'') = ''      THEN COALESCE(PG.[Fax Extension for Reminder],'392') 
            ELSE COALESCE(RC.[Fax No_],'') 
          END [Fax Extension]
        , CASE WHEN COALESCE(PG.[Team Phone Extension],'')='' THEN '800' ELSE COALESCE(PG.[Team Phone Extension],'800') END [Phone Extension]
        , CO.[Continent]
        , CU.[Payment Method Code]
        , CASE WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
            ''
          ELSE
            CASE 
              WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 6705 Fax: +86(0)21 5197 6449'
              WHEN ',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
                'Tel： +86 (0) 21 5197 6705 Fax: +86(0)21 5197 6448'
              ELSE
                ''
            END    
          END [Special Fax]
        --, CASE 
        --    WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%'       THEN
        --      'email: accounting_fax@hrs.cn'
        --    WHEN ',10,103,106,107,118,121,126,128,139,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
        --      'email: accounting_fax@hrs.cn'
        --    WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN 
        --      '3634@hrs.de'
        --    WHEN RH.[Document Type] = '16'                                  THEN 
        --      COALESCE(PEG.[Fax Extension for Reminder],'392') + '@hrs.de'
        --    WHEN COALESCE(RC.[Fax No_],'') = ''                             THEN 
        --      COALESCE(PG.[Fax Extension for Reminder],'392') + '@hrs.de' 
        --    ELSE 
        --      COALESCE(RC.[Fax No_] + '@hrs.de','') 
        --  END [Special E-Mail]     
		, [Special E-Mail] = ''      
        , [Reminder Remaining Amount].[Min_ Document Date]
        , [Reminder Remaining Amount].[Max_ Document Date]
        , [Service].[Hotel Turnover]
        , RH.[Contact]
        , PG.[Description] [Salesperson]
        , CU.[Salesperson Code]
        , @IssuedReminder [Last Issue Reminder]
        , @MaxDocumentDate [Last Issued Reminder Date]
        , CU.[Hotel Status]
        , CU.[Reason Code]
     FROM [HRS Payment$Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN [HRS Payment$Country_Region]         CO WITH (READUNCOMMITTED)
       ON CO.[Code] = RH.[Country_Region Code]
     JOIN [HRS Payment$Customer]               CU WITH (READUNCOMMITTED)
       ON CU.[No_]  = RH.[Customer No_]
 --LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = RH.[Country_Region Code]       
 --LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = RH.[Country_Region Code]      
 --LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = RH.[Country_Region Code]    
LEFT JOIN [HRS Payment$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS Payment$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
LEFT JOIN [HRS Payment$Printer Group]          PEG WITH (READUNCOMMITTED)
       ON PEG.[Code]                  = 'PEGASUS'
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Commission Amount]
               FROM [HRS Payment$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 3
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Commission Amount] 
       ON RH.[No_] = [Reminder Commission Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(
                    CASE WHEN @CurrencyCode = 'EUR' THEN RL.[Amount] ELSE RL.[Amount] * @CurrencyFactor END
                    ) AS [Interest Amount]
               FROM [HRS Payment$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Interest Amount] ON RH.[No_] = [Reminder Interest Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Fee Amount]
               FROM [HRS Payment$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 1
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Fee Amount] ON RH.[No_] = [Reminder Fee Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(
                    CASE WHEN @CurrencyCode = 'EUR' THEN RL.[Remaining Amount] ELSE 
                      CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE
                        RL.[Remaining Amount] * @CurrencyFactor
                      END
                    END
                    ) AS [Remaining Amount]
                  , MIN(RL.[Document Date]) AS [Min_ Document Date]
                  , MAX(RL.[Document Date]) AS [Max_ Document Date]
               FROM [HRS Payment$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Remaining Amount] ON RH.[No_] = [Reminder Remaining Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(DL.[Commission Base Amount] * DL.[Number of Nights])  [Hotel Turnover]
               FROM [HRS Payment$Reminder Line]  RL WITH (NOLOCK )
               JOIN [HRS Payment$Agency Display Header] DH WITH (NOLOCK)
                 ON DH.[Posted Invoice No_] = RL.[Document No_]
               JOIN [HRS Payment$Agency Display Line]   DL WITH (NOLOCK) 
                 ON DL.[Display Case No_] = DH.[Case No_]              
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Service] ON RH.[No_] = [Service].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[VAT Amount]) AS [VAT Amount]
               FROM [HRS Payment$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder VAT Amount] ON RH.[No_] = [Reminder VAT Amount].[Reminder No_]					
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = RH.[Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = RH.[Customer No_]
    WHERE RH.[No_] = @ReNr
END

GO
