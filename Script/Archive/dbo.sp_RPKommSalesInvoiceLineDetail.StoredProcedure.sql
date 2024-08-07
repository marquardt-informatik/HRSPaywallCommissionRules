USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceLineDetail]    Script Date: 10.04.2024 14:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.06.2011
-- Description:	Kopie der SP vom P-NAV-MSSQL-1
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 21.09.11 HRS001    49724  TM     [Hide Amount] eingefügt zur Steuerung der Ausgabe der Betragswerte
-- 21.11.11 HRS002           TM     Ausblender der als gelöscht gekennzeichneten Zeilen
/*
DECLARE @ReNr varchar(20), @ResNr varchar(25)
 SELECT @ReNr = '3101048', @ResNr = '48325919'
EXEC [dbo].[sp_RPKommSalesInvoiceLineDetail]  @ReNr,@ResNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceLineDetail] 
    @ReNr varchar(25),@ResNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @ReNr2 varchar(25),@ResNr2 varchar(25)
  SET @ReNr2 = @ReNr
  SET @ResNr2 = @ResNr
-- 21.09.11 TM >>>>>>>>>>>>>>>>>>>>>> HRS001
   DECLARE @HideAmount bit
    SELECT @HideAmount = COALESCE(DA.[Hide Amount],0)
      FROM [HRS$Agency Display Header] AH WITH (READUNCOMMITTED)
 LEFT JOIN [HRS$Document Type Assignment] DA WITH (READUNCOMMITTED)
        ON DA.[Brand Code]            = AH.[Brand Code]
       AND DA.[Muse ID]               = AH.[MuseID]
       AND DA.[Document Type]         = AH.[Document Type]
     WHERE AH.[Posted Invoice No_]    = @ReNr2
-- 21.09.11 TM <<<<<<<<<<<<<<<<<<<<<< HRS001       

  SELECT AH1.[Posted Invoice No_]                         AS [Document No_]
       , AL1.[Reservation No_]                            AS [Line No_]
       , CONVERT(nvarchar,AL1.[Reservation Date from] ,4) AS [Anreisedatum]
       , CONVERT(nvarchar,AL1.[Reservation Date to],4)    AS [Abreisedatum]
       , AL1.[Number of Nights]                           AS [Quantity]
       , AL1.[Room Type]                                  AS [Zimmertyp]
       , AL1.[Room Price]                                 AS [Zimmerpreis]
       , AL1.[Rate Description]                           AS [Rate Bezeichnung]
       , AL1.[Breakfast Price]                            AS [Frühstückspreis]
       , AL1.[Line Amount]                                AS [Line Amount]
       , AL1.[Hotel sales incl_ VAT]                      AS [Amount Including VAT]
       , AL1.[Reservation No_]                            AS [Reservierungsnr_]
       , AL1.[Commission Rate]                            AS [Kommissionssatz %]
       , AL1.[Number of Person]                           AS [Anzahl Personen]
       , AL1.[Number of Rooms]                            AS [Anzahl Zimmer]
       , AL1.[Commission Base Amount]                     AS [Umsatz]
       --, CASE WHEN AL1.[Rate Type] = 20025 AND AL1.[Price Type]=2 THEN 
       --    AL1.[Hotel sales incl_ VAT] / AL1.[Number of Nights]
       --  ELSE
       --    AL1.[Hotel sales incl_ VAT]
       --  END                                              AS [Umsatz]
       , AL1.[Booking Quality]
       , AL1.[Booking Code]                               AS [Buchungscode] 
       , AH1.[VAT Bus_ Posting Group]
-- 21.09.11 TM >>>>>>>>>>>>>>>>>>>>>> HRS001
       , @HideAmount [Hide Amount]
-- 21.09.11 TM <<<<<<<<<<<<<<<<<<<<<< HRS001       
    FROM [HRS$Agency Display Line]   AL1 WITH (READUNCOMMITTED)
    JOIN [HRS$Agency Display Header] AH1 WITH (READUNCOMMITTED)
      ON AH1.[Case No_] = AL1.[Display Case No_]
    JOIN [HRS$Customer]               CU WITH (READUNCOMMITTED)              
      ON CU.[No_] = AH1.[Bill-to Customer No_]
   WHERE (AH1.[Posted Invoice No_] = @ReNr2 OR AH1.[Case No_] = @ReNr2)
     AND AL1.[Reservation No_]    = @ResNr2
-- 21.11.11 TM >>>>>>>>>>>>>>>>>>>>>> HRS002
     AND AL1.[Action]             <> 3
-- 21.11.11 TM <<<<<<<<<<<<<<<<<<<<<< HRS002       
ORDER BY [Reservation No_]
END

GO
