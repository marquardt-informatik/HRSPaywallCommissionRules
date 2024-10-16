USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceLineSubDetail]    Script Date: 10.04.2024 14:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.06.2011
-- Description:	Kopie der SP vom P-NAV-MSSQL-1
-- 21.11.11 HRS001           TM     Ausblender der als gelöscht gekennzeichneten Zeilen
/*
DECLARE @ReNr varchar(25),@ResNr varchar(25)
 SELECT @ReNr = 'V000032099', @ResNr = '62108426'
EXEC [dbo].[sp_RPKommSalesInvoiceLineSubDetail] @ReNr, @ResNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceLineSubDetail] 
  @ReNr varchar(25),@ResNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
	DECLARE @ReNr2 varchar(25),@ResNr2 varchar(25)
	SET @ReNr2 = @ReNr
	SET @ResNr2 = @ResNr

  SELECT DISTINCT 
         TB.[Reservierungsnr_]
       , MIN([Kunde Gastname 1]) AS [Kunde Gastname 1]
       , MIN([Kunde Gastname 2]) AS [Kunde Gastname 2]
       , MAX([Kunde Firma]) AS [Kunde Firma]
       , [Anreisedatum]
       , [Document No_]
       , MIN([Line No_]) AS [Line No_]
       , MIN([ProcessNumber]) AS [ProcessNumber]
       , MIN([Reservierungsquelle]) AS [Reservierungsquelle]
       , MAX([Searchorder Description]) AS [Searchorder Description]
       , MAX([AGB2012]) AS [AGB2012]
       , MAX([Special Agreement]) AS [Special Agreement]
       , MAX([Reservation Date])  AS [Reservation Date]
    FROM (
		  SELECT AL1.[Reservation No_] [Reservierungsnr_]
               , CASE WHEN LE.[Reservierungsnr_] IS NOT NULL THEN 
                   LE.[Kunde Gastname 1] 
                 ELSE 
                   AL1.[Client Guestname 1] 
                 END                                              [Kunde Gastname 1]
               , CASE WHEN LE.[Reservierungsnr_] IS NOT NULL THEN 
                   LE.[Kunde Gastname 2] 
                 ELSE 
                   AL1.[Client Guestname 2] 
                 END                                              [Kunde Gastname 2]
               , AL1.[Client Company]                             [Kunde Firma]
               , AL1.[Arrival Date]                               [Anreisedatum]
               , AH1.[Posted Invoice No_]                         [Document No_]
               , CAST(AL1.[Reservation No_] as int)               [Line No_]
               , AL1.[ProcessNumber]                              [ProcessNumber]
               , AL1.[Reservation Source]                         [Reservierungsquelle]
               , COALESCE(SO.[Description],'')                    [Searchorder Description]
               , COALESCE(CASE 
                   WHEN SO.[Date of Reference Filter]=1 AND
                        SO.[Category Filter]         =1 AND
                        SO.[Contract Status Filter]  =1 AND
                        SO.[Country Filter]          =1 THEN
                     1
                   ELSE
                     0
                 END,0)                                           [AGB2012]
               , COALESCE(SO.[Hotel Filter],0)                    [Special Agreement]
               , AL1.[Reservation Date]
            FROM [HRS$Agency Display Line]   AL1 WITH (READUNCOMMITTED) 
            JOIN [HRS$Agency Display Header] AH1 WITH (READUNCOMMITTED) 
              ON AH1.[Case No_] = AL1.[Display Case No_]
       LEFT JOIN ReservationUnicodeFields     LE WITH (READUNCOMMITTED) 
              ON AL1.[Reservation No_] = LE.[Reservierungsnr_] 
             AND LE.[Positionsnr_] = 0
       LEFT JOIN [HRS$Job Contract Mapping]  JCM WITH (READUNCOMMITTED) 
              ON JCM.[Contract Code] = AL1.[Calculated with Contract Code]
             AND JCM.[Job No_]       = AH1.[Bill-to Customer No_]
       LEFT JOIN [HRS$Agency Bus_ Rules Searchorder] SO  WITH (READUNCOMMITTED) 
              ON SO.[No_] = JCM.[Searchoder No_]
           WHERE AL1.[Reservation No_]=@ResNr2 
             AND (AH1.[Posted Invoice No_]=@ReNr2 OR AH1.[Case No_] = @ReNr2)
-- 21.11.11 TM >>>>>>>>>>>>>>>>>>>>>> HRS001
             AND AL1.[Action]             <> 3
-- 21.11.11 TM <<<<<<<<<<<<<<<<<<<<<< HRS001       
		     ) TB
GROUP BY TB.[Anreisedatum]
       , TB.[Reservierungsnr_]
       , TB.[Document No_]	
END
GO
