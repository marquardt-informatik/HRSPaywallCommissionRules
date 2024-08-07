USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPAgencyCrMemoLine_HRS-CN]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 25.01.14
-- Description:	Wird verwendet für SSRS Kommissionsrechnung2012_Part2

-- Date     Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 10.10.16 HRS001    ----   TM   Copy of sp_RPKommSalesInvoiceLine2014

/*
DECLARE @ReNr VARCHAR(20)
 SELECT @ReNr = 'VG000000003'
EXECUTE [dbo].[sp_RPAgencyCrMemoLine_HRS-CN] @ReNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPAgencyCrMemoLine_HRS-CN] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
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
           , MAX(CASE WHEN LE.[Reservierungsnr_] IS NOT NULL THEN 
               LE.[Kunde Gastname 1] 
             ELSE 
               BU.B_GAST1 
             END)                                            [Kunde Gastname 1]
           , MAX(CASE WHEN LE.[Reservierungsnr_] IS NOT NULL THEN
               LE.[Kunde Gastname 2] 
             ELSE 
               BU.B_GAST2 
             END)                                            [Kunde Gastname 2]
           , MAX(BU.B_DATUM)                     [Reservation Date]
        FROM [HRS-CN$Agency Cr_ Memo Line]   AL1 WITH (READUNCOMMITTED) 
        JOIN [HRS-CN$Agency Cr_ Memo Header] AH1 WITH (READUNCOMMITTED)
          ON AH1.[No_] = AL1.[Document No_]
		JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
		  ON BU.B_KEY = AL1.[Reservation No_]
   LEFT JOIN ReservationUnicodeFields     LE WITH (READUNCOMMITTED) 
          ON AL1.[Reservation No_] = LE.[Reservierungsnr_] 
       WHERE (AH1.[Posted Cr_ Memo No_] = @ReNr OR AH1.[No_] = @ReNr)
    GROUP BY AL1.[Reservation No_]       
   )
   SELECT AL1.[Reservation No_]                           [Reservation No_]
        , CONVERT(nvarchar,BU.B_AN_DATUM,4)               [Anreisedatum]
        , CONVERT(nvarchar,BU.B_AB_DATUM,4)               [Abreisedatum]
        , AL1.[Process Number]                            [ProcessNumber]
        , AH1.[Posted Cr_ Memo No_]                       [Document No_]
        , CAST(AL1.[Position No_] as int)                 [Line No_]
        , AL1.[Number of Nights]                          [Quantity]
        , AL1.[Room Type]                                 [Zimmertyp]
        , AL1.[Room Price]                                [Zimmerpreis]
        , AL1.[Rate Description]                          [Rate Bezeichnung]
        , AL1.[Breakfast Price]                           [Frühstückspreis]
        , AL1.[Hotel sales incl_ VAT]                     [Amount Including VAT]
        , AL1.[Commission Rate]                           [Kommissionssatz %]
        , AL1.[Number of Person]                          [Anzahl Personen]
        , AL1.[Number of Rooms]                           [Anzahl Zimmer]
        , AL1.[Commission Base Amount]                    [Umsatz]

		, DL.[Line Amount]                                [Old Line Amount]
		, AL1.[New Line Amount]
        , AL1.[Line Amount Diff_]                   
		, AL1.[Currency Code]

		, DL.[Line Amount (LCY)]                          [Old Line Amount (LCY)]
		, AL1.[New Line Amount (LCY)]
        , AL1.[Line Amount Diff_ (LCY)]   
		                
        , AL1.[Ranking Booster]
        , AC.[Kunde Gastname 1]
        , AC.[Kunde Gastname 2]
        , AC.[Reservation Date]
        , AL1.Action
         , CASE 
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
         , 'spezial@hrs.de' [Special E-Mail]
         , (
           CASE 
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
		, AH1.MuseID
     FROM AC
     JOIN [HRS-CN$Agency Cr_ Memo Line]   AL1 WITH (READUNCOMMITTED) 
       ON AC.[Reservation No_] = AL1.[Reservation No_]
     JOIN [HRS-CN$Agency Cr_ Memo Header] AH1 WITH (READUNCOMMITTED)
       ON AH1.[No_] = AL1.[Document No_]
	 JOIN [HRS-CN$Agency Display Line]          DL WITH (NOLOCK)
	   ON DL.[Reservation No_]             = AL1.[Reservation No_]
	  AND DL.[Position No_]                = AL1.[Position No_]
	  AND DL.[Display Case No_]            = AL1.[Case No_]
     JOIN [HRS-CN$Customer]                     CU WITH (READUNCOMMITTED)
       ON AH1.[Bill-to Customer No_]       = CU.[No_] 
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
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = AL1.[Reservation No_]
    WHERE (AH1.[Posted Cr_ Memo No_] = @ReNr2 OR AH1.[No_] = @ReNr2)
 ORDER BY CONVERT(nvarchar,AL1.[Reservation Date from],120)
        , AL1.[Reservation No_]
END
GO
