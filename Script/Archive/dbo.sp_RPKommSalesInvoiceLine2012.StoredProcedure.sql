USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceLine2012]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 28.04.2012
-- Description:	Wird verwendet für SSRS Kommissionsrechnung2012
--
-- 02.04.2014 HRS001 *S soll nicht mehr bei Special Agreements-Hotels angezeigt werden
/*
DECLARE @ReNr VARCHAR(20)
 SELECT @ReNr = 8759826
EXECUTE [dbo].[sp_RPKommSalesInvoiceLine2012] @ReNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceLine2012] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
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
           , /* HRS001 MAX(COALESCE(SO.[Hotel Filter],0)) */ 0      [Special Agreement]
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
        FROM [HRS$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
        JOIN [HRS$Agency Display Header] AH1 WITH (READUNCOMMITTED)
          ON AH1.[Case No_] = AL1.[Display Case No_]
   LEFT JOIN ReservationUnicodeFields     LE WITH (READUNCOMMITTED) 
          ON AL1.[Reservation No_] = LE.[Reservierungsnr_] 
   LEFT JOIN [HRS$Job Contract Mapping]  JCM WITH (READUNCOMMITTED) 
          ON JCM.[Contract Code] = AL1.[Calculated with Contract Code]
         AND JCM.[Job No_]       = AH1.[Bill-to Customer No_]
   LEFT JOIN [HRS$Agency Bus_ Rules Searchorder] SO  WITH (READUNCOMMITTED) 
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
        , AL1.[Number of Nights]                          [Quantity]
        , AL1.[Room Type]                                 [Zimmertyp]
        , AL1.[Room Price]                                [Zimmerpreis]
        , AL1.[Rate Description]                          [Rate Bezeichnung]
        , AL1.[Breakfast Price]                           [Frühstückspreis]
        , AL1.[Line Amount]                               [Line Amount]
        , AL1.[Hotel sales incl_ VAT]                     [Amount Including VAT]
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
--        , AL1.[Hotel sales incl_ VAT] * AL1.[Number of Nights] [Total Amount Including VAT]
        , AL1.[Commission Base Amount] * AL1.[Number of Nights]  [Total Amount Including VAT]
     FROM AC
     JOIN [HRS$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
       ON AC.[Reservation No_] = AL1.[Reservation No_]
     JOIN [HRS$Agency Display Header] AH1 WITH (READUNCOMMITTED)
       ON AH1.[Case No_] = AL1.[Display Case No_]
LEFT JOIN [Affiliate Partner]          AP WITH (READUNCOMMITTED)
       ON AP.[No_] = AL1.[Client No_]
    WHERE (AH1.[Posted Invoice No_] = @ReNr2 OR AH1.[Case No_] = @ReNr2)
      AND AL1.Action <> 3
 ORDER BY CONVERT(nvarchar,AL1.[Reservation Date from],120)
        , AL1.[Reservation No_]
END


GO
