USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPAccountOverviewHeader]    Script Date: 10.04.2024 14:31:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 22.05.2013
-- Description:	Account Overview
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 10.03.20 HRS001  ACS-2202 DJU    Change Tel., E-Mail and Fax for country 67 
--
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '3002053903'
EXEC [dbo].[sp_RPAccountOverviewHeader] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPAccountOverviewHeader] 
    @ReNr varchar(25)
AS
BEGIN
  DECLARE @YearList VARCHAR(max)
   SELECT @YearList = ''
  ;WITH _YEARS AS
  (
   SELECT YEAR(DL.[Departure Date]) [Departure Year]
        , COUNT(1) [Bookings]
     FROM [HRS$Issued Reminder Line]  RL WITH (NOLOCK)
     JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
       ON DH.[Posted Invoice No_] = RL.[Document No_]
     JOIN [HRS$Agency Display Line]   DL WITH (NOLOCK)
       ON DL.[Display Case No_] = DH.[Case No_]
    WHERE ([Reminder No_] = @ReNr) 
      AND [Type] = 2
 GROUP BY YEAR(DL.[Departure Date])   
UNION         
   SELECT YEAR(DL.[Departure Date]) [Departure Year]
        , COUNT(1) [Bookings]
     FROM [HRS$Reminder Line]         RL WITH (NOLOCK)
     JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
       ON DH.[Posted Invoice No_] = RL.[Document No_]
     JOIN [HRS$Agency Display Line]   DL WITH (NOLOCK)
       ON DL.[Display Case No_] = DH.[Case No_]
    WHERE ([Reminder No_] = @ReNr) 
      AND [Type] = 2
 GROUP BY YEAR(DL.[Departure Date])   
  )
   SELECT @YearList = @YearList + CASE WHEN @YearList = '' THEN '' ELSE ', ' END + CAST([Departure Year] AS VARCHAR)
     FROM _YEARS

  DECLARE @CurrencyCode VARCHAR(10), @CurrencyFactor DECIMAL(38,20)
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS$Issued Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  IF @CurrencyCode IS NULL  
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS$Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  SET NOCOUNT ON;
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
        , RH.[Reminder Level]
        , RH.[Country_Region Code]
        , RH.[Language Code]
        , [Reminder Commission Amount].[Commission Amount] * @CurrencyFactor [Commission Amount]
        , [Reminder Interest Amount].[Interest Amount]                       [Interest Amount]
        , [Reminder Fee Amount].[Fee Amount]                                 [Fee Amount]
        , [Reminder Remaining Amount].[Remaining Amount]                     [Remaining Amount]
        , [Reminder VAT Amount].[VAT Amount]               * @CurrencyFactor [VAT Amount]
        , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                    ELSE P6.[Content]       END [Countryname]
        , CASE 
        --    WHEN RH.[Document Type] = '16'           THEN COALESCE(PEG.[Fax Extension for Reminder],'392')
        --    WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
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
			  -- HRS001 >>
              -- WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
			  WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
			  -- HRS001 <<
                'Tel： +86 (0) 21 5197 6705 Fax: +86(0)21 5197 6448'
			  -- HRS001 >>
			  WHEN '67' = RH.[Country_Region Code] THEN
                'Tel： +86 (0) 21 5197 6448 Fax: +86(0)21 5197 6447'
			  -- HRS001 <<
              ELSE
                ''
            END    
          END [Special Fax]
        --, CASE 
        --    WHEN RH.[Document Type] = '16' THEN 
        --      COALESCE(PEG.[Salesperson E-Mail],'')
        --    WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
        --      ''
        --    ELSE
        --      CASE 
        --        WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
        --          'email: accounting_fax@hrs.cn'
        --        WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
        --          'email: accounting_fax@hrs.cn'
        --        ELSE
        --          ''
        --      END    
        --  END [Special E-Mail]
        , CASE 
			-- HRS001 >>
			WHEN '67' = RH.[Country_Region Code] THEN
			  'accounting_fax@hrs.cn'
			-- HRS001 <<
            WHEN COALESCE(RC.[Fax No_],'') = ''                             THEN 
              COALESCE(PG.[Fax Extension for Reminder],'392') + '@hrs.de' 
            ELSE 
              COALESCE(RC.[Fax No_] + '@hrs.de','') 
          END [Special E-Mail]
        , @YearList [Year List]
		-- HRS001 >>
		, CASE 
			WHEN '67' = RH.[Country_Region Code] THEN
			  '+86 (0) 21 5197 6448'
            ELSE 
              '+49 221 2077 8015'
          END [Special Tel_ No_]
		-- HRS001 <<
     FROM [HRS$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN [HRS$Country_Region]         CO WITH (READUNCOMMITTED)
       ON CO.[Code] = RH.[Country_Region Code]
     JOIN [HRS$Customer]               CU WITH (READUNCOMMITTED)
       ON CU.[No_]  = RH.[Customer No_]
LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
LEFT JOIN [HRS$Printer Group]          PEG WITH (READUNCOMMITTED)
       ON PEG.[Code]                  = 'PEGASUS'
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Commission Amount]
               FROM [HRS$Issued Reminder Line] RL WITH (READUNCOMMITTED)
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
               FROM [HRS$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Interest Amount] ON RH.[No_] = [Reminder Interest Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Fee Amount]
               FROM [HRS$Issued Reminder Line] RL WITH (READUNCOMMITTED)
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
               FROM [HRS$Issued Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Remaining Amount] ON RH.[No_] = [Reminder Remaining Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[VAT Amount]) AS [VAT Amount]
               FROM [HRS$Issued Reminder Line] RL WITH (READUNCOMMITTED)
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
        , RH.[Reminder Level]
        , RH.[Country_Region Code]
        , RH.[Language Code]
        , [Reminder Commission Amount].[Commission Amount] * @CurrencyFactor [Commission Amount]
        , [Reminder Interest Amount].[Interest Amount]                       [Interest Amount]
        , [Reminder Fee Amount].[Fee Amount]                                 [Fee Amount]
        , [Reminder Remaining Amount].[Remaining Amount]                     [Remaining Amount]
        , [Reminder VAT Amount].[VAT Amount]               * @CurrencyFactor [VAT Amount]
        , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                    ELSE P6.[Content]       END [Countryname]
        , CASE 
            --WHEN RH.[Document Type] = '16'           THEN COALESCE(PEG.[Fax Extension for Reminder],'392')
            --WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
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
              -- HRS001 >>
              -- WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
			  WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
			  -- HRS001 <<
                'Tel： +86 (0) 21 5197 6705 Fax: +86(0)21 5197 6448'
			  -- HRS001 >>
			  WHEN '67' = RH.[Country_Region Code] THEN
                'Tel： +86 (0) 21 5197 6448 Fax: +86(0)21 5197 6447'
			  -- HRS001 <<
              ELSE
                ''
            END    
          END [Special Fax]
        --, CASE 
        --    WHEN RH.[Document Type] = '16' THEN 
        --      COALESCE(PEG.[Salesperson E-Mail],'')
        --    WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
        --      ''
        --    ELSE
        --      CASE 
        --        WHEN ',29,57,92,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
        --          'email: accounting_fax@hrs.cn'
        --        WHEN ',10,103,106,107,118,121,126,128,137,139,151,153,166,170,186,191,20,233,235,238,24,242,251,253,257,258,259,265,266,268,270,30,41,59,67,74,83,86,95,96,' LIKE '%,'+RH.[Country_Region Code]+',%' THEN
        --          'email: accounting_fax@hrs.cn'
        --        ELSE
        --          ''
        --      END    
        --  END [Special E-Mail]
        , CASE 
            -- HRS001 >>
			WHEN '67' = RH.[Country_Region Code] THEN
			  'accounting_fax@hrs.cn'
			-- HRS001 <<
            WHEN COALESCE(RC.[Fax No_],'') = ''                             THEN 
              COALESCE(PG.[Fax Extension for Reminder],'392') + '@hrs.de' 
            ELSE 
              COALESCE(RC.[Fax No_] + '@hrs.de','') 
          END [Special E-Mail]
		-- HRS001 >>
		, CASE 
			WHEN '67' = RH.[Country_Region Code] THEN
			  '+86 (0) 21 5197 6448'
            ELSE 
              '+49 221 2077 8015'
          END [Special Tel_ No_]
		-- HRS001 <<
        , @YearList [Year List]
     FROM [HRS$Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN [HRS$Country_Region]         CO WITH (READUNCOMMITTED)
       ON CO.[Code] = RH.[Country_Region Code]
     JOIN [HRS$Customer]               CU WITH (READUNCOMMITTED)
       ON CU.[No_]  = RH.[Customer No_]
LEFT JOIN [HRS$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
LEFT JOIN [HRS$Printer Group]          PEG WITH (READUNCOMMITTED)
       ON PEG.[Code]                  = 'PEGASUS'
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Commission Amount]
               FROM [HRS$Reminder Line] RL WITH (READUNCOMMITTED)
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
               FROM [HRS$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Interest Amount] ON RH.[No_] = [Reminder Interest Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[Amount]) AS [Fee Amount]
               FROM [HRS$Reminder Line] RL WITH (READUNCOMMITTED)
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
               FROM [HRS$Reminder Line] RL WITH (READUNCOMMITTED)
              WHERE RL.[Type] = 2
                AND RL.[Reminder No_] = @ReNr
           GROUP BY RL.[Reminder No_]
          ) AS [Reminder Remaining Amount] ON RH.[No_] = [Reminder Remaining Amount].[Reminder No_]
LEFT JOIN (
             SELECT RL.[Reminder No_]
                  , SUM(RL.[VAT Amount]) AS [VAT Amount]
               FROM [HRS$Reminder Line] RL WITH (READUNCOMMITTED)
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
