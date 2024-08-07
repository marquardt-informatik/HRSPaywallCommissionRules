USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceLine2014_HRS-BR]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 16.04.2014
-- Description:	
--
-- 30.03.15 HRS004    90903  TM     new Fields
-- 29.03.19 HRS005   ACS-1741 TM    new field "Calculate Breakfast Commission"
-- 22.02.20 HRS006   ACS-1991 DJU   new fields "TAF Line Amount", "Commission Amount"
/*
DECLARE @ReNr VARCHAR(20)
 SELECT @ReNr = 'V000000012'
EXECUTE [dbo].[sp_RPKommSalesInvoiceLine2014_HRS-BR] @ReNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceLine2014_HRS-BR] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
  -- HRS005 <<
  DECLARE @BreakfastCommission TINYINT = 0
  SELECT @BreakfastCommission = [Calculate Breakfast Commission] FROM [HRS-BR$Agency Setup]
  -- HRS005 >>
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr
   ;WITH AC AS
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
        FROM [HRS-BR$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
        JOIN [HRS-BR$Agency Display Header] AH1 WITH (READUNCOMMITTED)
          ON AH1.[Case No_] = AL1.[Display Case No_]
   LEFT JOIN ReservationUnicodeFields     LE WITH (READUNCOMMITTED) 
          ON AL1.[Reservation No_] = LE.[Reservierungsnr_] 
   LEFT JOIN [HRS-BR$Job Contract Mapping]  JCM WITH (READUNCOMMITTED) 
          ON JCM.[Contract Code] = AL1.[Calculated with Contract Code]
         AND JCM.[Job No_]       = AH1.[Bill-to Customer No_]
   LEFT JOIN [HRS-BR$Agency Bus_ Rules Searchorder] SO  WITH (READUNCOMMITTED) 
          ON SO.[No_] = JCM.[Searchoder No_]
       WHERE (AH1.[Posted Invoice No_] = @ReNr2 OR AH1.[Case No_] = @ReNr2)
    GROUP BY AL1.[Reservation No_]       
   )
   SELECT AL1.[Reservation No_]                           [Reservierungsnr_]
        , CASE WHEN COALESCE(AP.[Distribution Channel ID],0) IN (0, 1, 3, 4, 5, 6, 8) OR AL1.[Reservation Source]=383 THEN 
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
        , CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[Hotel sales incl_ VAT] END [Amount Including VAT]
        , AL1.[Commission Rate]                           [Kommissionssatz %]
        , AL1.[Number of Person]                          [Anzahl Personen]
        , AL1.[Number of Rooms]                           [Anzahl Zimmer]
        , AL1.[Commission Base Amount]                    [Umsatz]
        , AL1.[Booking Quality]                           [Booking Quality]
        , AL1.[Booking Code]                              [Buchungscode]
        , AC.[Kunde Gastname 1]
        , AC.[Kunde Gastname 2]
        , AC.[Searchorder Description]
        , AC.[AGB2012]
        , AC.[Special Agreement]
        , AC.[Reservation Date]
        , AL1.[Quality at]
        , AL1.[Quality by User]
        , AL1.[Ranking Booster]
--        , AL1.[Hotel sales incl_ VAT] * AL1.[Number of Nights] [Total Amount Including VAT]
        , CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[Commission Base Amount] * AL1.[Number of Nights] END [Total Amount Including VAT]
        , AL1.Action
-- 30.03.15 TM >>>>>>>>>>>>>>>>>>>> HRS004
		 , AL1.[Deduction Type]
		 , AL1.[Deductible Amount]
		 , AL1.[Commission Roomnight Base Amnt] [Commission Base Amount]
		 , AH1.[Currency Code] [Invoice Currency Code]
-- 30.03.15 TM <<<<<<<<<<<<<<<<<<<< HRS004
        , AC.hasDeleted
-- 29.03.19 TMA <<<<<<<<<<<<<<<<<<< HRS005
        , @BreakfastCommission [Breakfast Commission]
-- 29.03.19 TMA >>>>>>>>>>>>>>>>>>> HRS005
-- 22.02.20 DJU >>>>>>>>>>>>>>>>>>>> HRS006
        , CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[TAF Line Amount] END [TAF Line Amount]
		, CASE WHEN AL1.Action = 3 THEN 0 ELSE AL1.[Line Amount] - AL1.[TAF Line Amount] END [Commission Amount]
-- 22.02.20 DJU <<<<<<<<<<<<<<<<<<<< HRS006
     FROM AC
     JOIN [HRS-BR$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
       ON AC.[Reservation No_] = AL1.[Reservation No_]
     JOIN [HRS-BR$Agency Display Header] AH1 WITH (READUNCOMMITTED)
       ON AH1.[Case No_] = AL1.[Display Case No_]
LEFT JOIN [Affiliate Partner]          AP WITH (READUNCOMMITTED)
       ON AP.[No_] = AL1.[Client No_]
    WHERE (AH1.[Posted Invoice No_] = @ReNr2 OR AH1.[Case No_] = @ReNr2)
      AND AL1.Action <> 3
 ORDER BY CONVERT(nvarchar,AL1.[Reservation Date from],120)
        , AL1.[Reservation No_]
END

GO
