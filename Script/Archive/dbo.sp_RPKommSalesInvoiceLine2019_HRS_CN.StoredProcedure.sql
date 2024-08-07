USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceLine2019_HRS_CN]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 25.01.14
-- Description:	Wird verwendet für SSRS Kommissionsrechnung2012_Part2
--
-- 30.03.15 HRS001    90903  TM     new Fields
-- 18.05.15 HRS002    94220  ZM     New Field "Booking Rating"
-- 08.04.16 HRS003    -----  TM     Fax 6447 nur bei Land 30 EMail accountingFax@hrs.cn nur bei Land 29|30|57|92 
-- 22.07.16 HRS005    NAV-135  TM   New Field: Multisourced
-- 10.01.18 HRS006   ACS-114 DJU    new Field: Segment
-- 05.02.18 HRS007   ACS-292 RPR    Problem with new AH1.[VAT Bus_ Posting Group] N19 
-- 29.03.19 HRS008   ACS-1741 TM    new field "Calculate Breakfast Commission"
/*
DECLARE @ReNr VARCHAR(20)
 SELECT @ReNr = 'V006377260'
EXECUTE [dbo].[sp_RPKommSalesInvoiceLine2014] @ReNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceLine2019_HRS_CN] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
  -- HRS008 <<
  DECLARE @BreakfastCommission TINYINT = 0
  SELECT @BreakfastCommission = [Calculate Breakfast Commission] FROM [HRS-CN$Agency Setup]
  -- HRS008 >>

  DECLARE @ReNr2 varchar(25)
  SET @ReNr2 = @ReNr
  SELECT @ReNr2 = [Case No_] FROM [HRS-CN$Agency Display Header] DH WITH (NOLOCK) WHERE DH.[Posted Invoice No_] = @ReNr OR DH.[Case No_] = @ReNr
   ;WITH _AC AS
    (
      SELECT AC.[No_] [Reservation No_]
           , AC.[Line No_]
	       , 1 [Order No_]
	       , CAST(AC.[Comment] AS varchar(max)) [Comment]
        FROM [HRS-CN$Agency Comment Line] AC WITH (NOLOCK)
       WHERE AC.[Table Name] = 12
	     AND AC.[Document No_] = @ReNr2
       UNION ALL
      SELECT AC1.[Reservation No_]
           , AC2.[Line No_]
	       , AC1.[Order No_] + 1
   	       , AC1.[Comment] + ' ' + AC2.[Comment]
        FROM _AC AC1
        JOIN [HRS-CN$Agency Comment Line] AC2 WITH (NOLOCK)
          ON AC1.[Reservation No_] = AC2.No_
         AND AC1.[Line No_] < AC2.[Line No_]
       WHERE AC2.[Table Name] = 12
	     AND AC2.[Document No_] = @ReNr2
   ), _ALLC AS
   (
     SELECT [Reservation No_], MAX([Order No_]) [Order No_] FROM _AC GROUP BY [Reservation No_]
   ), Comment AS
   (
      SELECT _AC.* 
        FROM _AC
		JOIN _ALLC ON _AC.[Reservation No_] = _ALLC.[Reservation No_] AND _AC.[Order No_] = _ALLC.[Order No_]

   ), AC AS
   (
      SELECT AL1.[Reservation No_]
           , MAX(COALESCE(SO.[Description],''))      [Searchorder Description]
           , MAX(COALESCE(CASE 
             WHEN 
               SO.[Date of Reference Filter]=1 AND
               SO.[Category Filter]         =1 AND
               SO.[Contract Status Filter]  =1 AND
               SO.[Country Filter]          =1 THEN
               1
             ELSE
               1
             END,0))                                 [AGB2012]
           , MAX(COALESCE(SO.[Hotel Filter],0))      [Special Agreement]
           , MAX(CASE WHEN LE.[Reservierungsnr_] IS NOT NULL THEN 
               LE.[Kunde Gastname 1] 
             ELSE 
               AL1.[Client Guestname 1] 
             END)                                            [Kunde Gastname 1]
           , MAX(CASE WHEN LE.[Reservierungsnr_] IS NOT NULL THEN
               LE.[Kunde Gastname 2] 
             ELSE 
               AL1.[Client Guestname 2] 
             END)                                            [Kunde Gastname 2]
           , MAX(AL1.[Reservation Date])                     [Reservation Date]
           , MAX(CASE WHEN AL1.Action = 3 THEN 1 ELSE 0 END) [hasDeleted]
        FROM [HRS-CN$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
        JOIN [HRS-CN$Agency Display Header] AH1 WITH (READUNCOMMITTED)
          ON AH1.[Case No_] = AL1.[Display Case No_]
   LEFT JOIN ReservationUnicodeFields     LE WITH (READUNCOMMITTED) 
          ON AL1.[Reservation No_] = LE.[Reservierungsnr_] 
   LEFT JOIN [HRS-CN$Job Contract Mapping]  JCM WITH (READUNCOMMITTED) 
          ON JCM.[Contract Code] = AL1.[Calculated with Contract Code]
         AND JCM.[Job No_]       = AH1.[Bill-to Customer No_]
   LEFT JOIN [HRS-CN$Agency Bus_ Rules Searchorder] SO  WITH (READUNCOMMITTED) 
          ON SO.[No_] = JCM.[Searchoder No_]
       WHERE (AH1.[Posted Invoice No_] = @ReNr OR AH1.[Case No_] = @ReNr)
    GROUP BY AL1.[Reservation No_]       
   )
   SELECT AL1.[Reservation No_]                           [Reservierungsnr_]
        , CASE WHEN (COALESCE(AP.[Distribution Channel ID],0) IN (0, 1, 3, 4, 5, 6, 8) OR AL1.[Reservation Source]=383) AND NOT AH1.MuseID LIKE 'MEETAGO%' THEN 
            ''
          ELSE 
            AL1.[Client Company] 
          END                                             [Kunde Firma]
        , CONVERT(nvarchar,AL1.[Reservation Date from],4) [Anreisedatum]
        , CONVERT(nvarchar,AL1.[Reservation Date to],4)   [Abreisedatum]
        , AL1.[ProcessNumber]                             [ProcessNumber]
        , AL1.[Reservation Source]                        [Reservierungsquelle]	   
        , AH1.[Posted Invoice No_]                        [Document No_]
        , CAST(AL1.[Position No_] as int)                 [Line No_]
        , CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[Number of Nights] END [Quantity]
        , AL1.[Room Type]                                 [Zimmertyp]
        , AL1.[Room Price]                                [Zimmerpreis]
        , AL1.[Rate Description]                          [Rate Bezeichnung]
        , AL1.[Breakfast Price]                           [Frühstückspreis]
        , CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[Line Amount] END [Line Amount]    
         
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>> Line amount * Tax %19  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Zmo02 15/5/2015
        , CASE WHEN AL1.Action = 3 THEN 0 
               -->>HRS007 RPR 20180205
			   --WHEN AH1.[VAT Bus_ Posting Group]='INLAND' and [VAT Prod_ Posting Group]=19 THEN (AL1.[Line Amount]+AL1.[Line Amount]*0.19) 
               WHEN AH1.[VAT Bus_ Posting Group]='INLAND' THEN (AL1.[Line Amount]+AL1.[Line Amount]*0.19) 
			   --<<HRS007 RPR 20180205
               ELSE AL1.[Line Amount] END as [Line Amount Including VAT]
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<< Line amount * Tax %19  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< Zmo02 15/5/2015  

        , AL1.[Hotel sales incl_ VAT]                     [Amount Including VAT]
        , AL1.[Commission Rate]                           [Kommissionssatz %]
        , AL1.[Number of Person]                          [Anzahl Personen]
        , AL1.[Number of Rooms]                           [Anzahl Zimmer]
        , AL1.[Commission Base Amount]                    [Umsatz]
        , AL1.[Booking Quality]                           [Booking Quality]
        , AL1.[Ranking Booster]
        , AL1.[Booking Code]                              [Buchungscode]
        , AC.[Kunde Gastname 1]
        , AC.[Kunde Gastname 2]
        , AC.[Searchorder Description]
        , AC.[AGB2012]
        , AC.[Special Agreement]
        , AC.[Reservation Date]
        , AL1.[Quality at]
        , AL1.[Quality by User]
--        , AL1.[Hotel sales incl_ VAT] * AL1.[Number of Nights] [Total Amount Including VAT]
        , CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[Commission Base Amount] * AL1.[Number of Nights] END [Total Amount Including VAT]
        , AL1.Action
        , CU.[Payment Method Code]
         , CASE 
             WHEN AH1.[Salesperson Code] IN ('AFR03','FBE02')THEN
               CASE
                 WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND AH1.[Chain Code] = '13' THEN SP.[Fax Extension]
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(CC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 ELSE SP.[Fax Extension]
               END
             WHEN CU.[Contract Status] IN('10','11') 
              --AND AH.MuseID<>'HRS' 
              --AND CU.[Payment Method Code] <> 'SEPA'
              --AND NOT CU.[Payment Method Code] LIKE 'LAST%'
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' THEN SP.[Fax Extension]
             WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
             WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(CC.[Fax Extension],SP.[Fax Extension])
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
             WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
             ELSE COALESCE(RC.[Fax No_],'') 
           END [Durchwahl Fax]
         , CASE 
             WHEN AH1.[Document Type] = '15' THEN '392@hrs.de'             
             WHEN AH1.[Document Type] = '18' THEN COALESCE(DP.[Fax Extension], SP.[Fax Extension]) + '@hrs.de'             
             WHEN (CU.[Payment Method Code] IN ('CORE','SEPA','CC_AUTO') OR LEFT(CU.[Payment Method Code],4) = 'LAST') AND AH1.[Chain Code] = '13' THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN CU.[Payment Method Code] = 'CORE'         THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'SEPA'         THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
             WHEN CU.[Payment Method Code] = 'CC_AUTO'      THEN COALESCE(CC.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'   
             WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension]) + '@hrs.de'
             WHEN CU.[Contract Status] IN('10','11') 
              --AND AH.MuseID<>'HRS' 
              --AND CU.[Payment Method Code] <> 'SEPA'
              --AND CU.[Payment Method Code] <> 'CORE'
              --AND CU.[Payment Method Code] <> 'CC_AUTO'
              --AND NOT CU.[Payment Method Code] LIKE 'LAST%'
              AND COALESCE(PG.[Salesperson E-Mail],'')<>'' 
              THEN SP.[Fax Extension]  + '@hrs.de'
             WHEN ',29,57,92,30,' LIKE '%,'+AH1.[Bill-to Country_Region Code]+',%' THEN 
               'accounting_fax@hrs.cn'
             ELSE 
               CASE 
                 WHEN CU.[Payment Method Code] = 'CORE' THEN COALESCE(CR.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'SEPA' THEN COALESCE(SE.[Fax Extension],SP.[Fax Extension])
                 WHEN CU.[Payment Method Code] = 'CC_AUTO' THEN COALESCE(CC.[Fax Extension],SP.[Fax Extension])
                 WHEN LEFT(CU.[Payment Method Code],4) = 'LAST' THEN COALESCE(LT.[Fax Extension],SP.[Fax Extension])
                 WHEN COALESCE(RC.[Fax No_],'') = '' THEN SP.[Fax Extension]
                 ELSE COALESCE(RC.[Fax No_],'') 
               END 
             + '@hrs.de'
           END [Special E-Mail]
         , (
           CASE 
             WHEN AH1.[Document Type] = '18' THEN 'Fax +49 (0) 221 2077-' + COALESCE(DP.[Fax Extension], SP.[Fax Extension])             
             WHEN CU.[Contract Status] = '10' OR CU.[Contract Status] = '11' THEN
               ''
             ELSE
               CASE 
                 WHEN ',29,57,92,' LIKE '%,'+AH1.[Bill-to Country_Region Code]+',%' THEN
                   '+86 (0) 21 5197 6441'
                 WHEN ',30,67,' LIKE '%,'+AH1.[Bill-to Country_Region Code]+',%' THEN
                   '+86 (0) 21 5197 6447'
                 ELSE
                   ''
               END    
           END) [Special Fax]
         , AH1.[Bill-to Country_Region Code] AS [Sell-to Country Code]
         , AH1.[Bill-to Customer No_]
         , CASE WHEN AH1.[Language Code]=''  THEN CO.[Primary Language Code] ELSE AH1.[Language Code] END [Language Code]
-- 30.03.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
		 , AL1.[Deduction Type]
		 , AL1.[Deductible Amount]
		 , AL1.[Commission Roomnight Base Amnt] [Commission Base Amount]
		 , AH1.[Currency Code] [Invoice Currency Code]
-- 30.03.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
        , AC.hasDeleted
		, Comment.Comment [Subsequent Debit Comment]
		, AH1.MuseID
-- 30.03.15 TM >>>>>>>>>>>>>>>>>>>> HRS005
		 , AL1.[Multisourced]
-- 30.03.15 TM <<<<<<<<<<<<<<<<<<<< HRS005
-- 10.01.18 DJU >>>>>>>>>>>>>>>>>>> HRS006
		, AL1.Segment
-- 10.01.18 DJU <<<<<<<<<<<<<<<<<<< HRS006
        , CASE WHEN AL1.[Calculated with Function ID]='11' THEN [Commission Amount] ELSE NULL END [Fix Amount]
-- 29.03.19 TMA <<<<<<<<<<<<<<<<<<< HRS008
        , @BreakfastCommission [Breakfast Commission]
-- 29.03.19 TMA >>>>>>>>>>>>>>>>>>> HRS008
     FROM AC
     JOIN [HRS-CN$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
       ON AC.[Reservation No_] = AL1.[Reservation No_]
     JOIN [HRS-CN$Agency Display Header] AH1 WITH (READUNCOMMITTED)
       ON AH1.[Case No_] = AL1.[Display Case No_]
     JOIN [HRS-CN$Customer]                     CU WITH (READUNCOMMITTED)
       ON AH1.[Bill-to Customer No_]        = CU.[No_] 
     JOIN [HRS-CN$Country_Region]               CO WITH (READUNCOMMITTED)
       ON CU.[Country_Region Code] = CO.Code
     JOIN [HRS-CN$Printer Group]                SP WITH (READUNCOMMITTED)
       ON SP.[Code]                        = CU.[Salesperson Code]
LEFT JOIN [HRS-CN$Printer Group]                DP WITH (READUNCOMMITTED)
       ON DP.[Code]                        = AH1.[Salesperson Code]
LEFT JOIN [HRS-CN$Printer Group]                PG WITH (READUNCOMMITTED)
       ON PG.[Code]                        = 'PEGASUS'
LEFT JOIN [HRS-CN$Printer Group]                SE WITH (READUNCOMMITTED)
       ON SE.[Code]                        = 'SEPA'
LEFT JOIN [HRS-CN$Printer Group]                CR WITH (READUNCOMMITTED)
       ON CR.[Code]                        = 'CORE'
LEFT JOIN [HRS-CN$Printer Group]                LT WITH (READUNCOMMITTED)
       ON LT.[Code]                        = 'LAST'
LEFT JOIN [HRS-CN$Printer Group]                CC WITH (READUNCOMMITTED)
       ON CC.[Code]                        = 'AUTO_CC'
LEFT JOIN [HRS-CN$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [Affiliate Partner]          AP WITH (READUNCOMMITTED)
       ON AP.[No_] = AL1.[Client No_]
LEFT JOIN Comment
       ON Comment.[Reservation No_] = AL1.[Reservation No_]
    WHERE (AH1.[Posted Invoice No_] = @ReNr2 OR AH1.[Case No_] = @ReNr2)
      AND AL1.Action <> 3
 ORDER BY CONVERT(nvarchar,AL1.[Reservation Date from],120)
        , AL1.[Reservation No_]
END
GO
