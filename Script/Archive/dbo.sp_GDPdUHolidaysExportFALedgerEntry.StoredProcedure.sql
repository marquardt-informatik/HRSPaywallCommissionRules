USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUHolidaysExportFALedgerEntry]    Script Date: 10.04.2024 14:31:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Dennis Juhr (EXTDJU02)
-- Create date: 27.09.2021
-- Description:	GDPdU Export - Anlagenposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUHolidaysExportFALedgerEntry]
	@StartDate varchar(15),
	@EndDate varchar(15),
	@WithUltimo BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @StartDateTime datetime = cast(@StartDate as datetime);
	DECLARE @EndDateTime datetime = CASE WHEN @WithUltimo = 0 THEN cast(@EndDate as datetime) ELSE cast(@EndDate as datetime) + cast('23:59:59' as datetime) END;

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FLE.[FA No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Anlagennr.]
	     , CONVERT(varchar(10), FLE.[FA Posting Date], 104) [Anlagedatum]
		 , CONVERT(varchar(10), FLE.[Posting Date], 104) [Buchungsdatum]
		 , '"' + CASE 
		     WHEN FLE.[Document Type] = 0 THEN ' '
		     WHEN FLE.[Document Type] = 1 THEN 'Zahlung'
		     WHEN FLE.[Document Type] = 2 THEN 'Rechnung'
		     WHEN FLE.[Document Type] = 3 THEN 'Gutschrift'
		     WHEN FLE.[Document Type] = 4 THEN 'Zinsrechnung'
		     WHEN FLE.[Document Type] = 5 THEN 'Mahnung'
		     WHEN FLE.[Document Type] = 6 THEN 'Erstattung'
		   END + '"' [Belegart]
	     , CONVERT(varchar(10), FLE.[Document Date], 104) [Belegdatum]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FLE.[Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Belegnr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FLE.[External Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Externe Belegnummer]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FLE.[Description], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Beschreibung]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FLE.[Depreciation Book Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [AfA Buchcode]
		 , '"' + CASE 
		     WHEN FLE.[FA Posting Type] = 0 THEN 'Anschaffungskosten'
		     WHEN FLE.[FA Posting Type] = 1 THEN 'Normal-AfA'
		     WHEN FLE.[FA Posting Type] = 2 THEN 'Erhöhte AfA'
		     WHEN FLE.[FA Posting Type] = 3 THEN 'Zuschreibung'
		     WHEN FLE.[FA Posting Type] = 4 THEN 'Sonder-AfA'
		     WHEN FLE.[FA Posting Type] = 5 THEN 'Benutzerdef. AfA'
		     WHEN FLE.[FA Posting Type] = 6 THEN 'Verkaufspreis'
			 WHEN FLE.[FA Posting Type] = 7 THEN 'Restbetrag'
			 WHEN FLE.[FA Posting Type] = 8 THEN 'Gewinn/Verlust'
			 WHEN FLE.[FA Posting Type] = 9 THEN 'Buchwert bei Verkauf'
		   END + '"' [Anlagenbuchungsart]
		 , coalesce(REPLACE(CAST(CAST(FLE.Amount AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Betrag]
		 , coalesce(REPLACE(CAST(CAST(FLE.[Debit Amount] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Sollbetrag]
		 , coalesce(REPLACE(CAST(CAST(FLE.[Credit Amount] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Habenbetrag]
		 , '"' + CASE WHEN FLE.[Reclassification Entry] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Umbuchungsposten]
		 , '"' + CASE WHEN FLE.[Part of Book Value] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Teil d. Buchwerts]
		 , '"' + CASE WHEN FLE.[Part of Depreciable Basis] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Teil d. AfA-Grundlage]
		 , '"' + CASE 
		     WHEN FLE.[Disposal Calculation Method] = 0 THEN ' '
		     WHEN FLE.[Disposal Calculation Method] = 1 THEN 'Netto'
		     WHEN FLE.[Disposal Calculation Method] = 2 THEN 'Brutto'
		   END + '"' [Abgangsmethode]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FLE.[FA Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Anlagenbuchungsgruppe]
		 , '"' + CASE 
		     WHEN FLE.[Depreciation Method] = 0 THEN 'Linear'
		     WHEN FLE.[Depreciation Method] = 1 THEN 'Degressiv 1'
		     WHEN FLE.[Depreciation Method] = 2 THEN 'Degressiv 2'
		     WHEN FLE.[Depreciation Method] = 3 THEN 'Degr1/Linear'
		     WHEN FLE.[Depreciation Method] = 4 THEN 'Degr2/Linear'
		     WHEN FLE.[Depreciation Method] = 5 THEN 'Tabelle'
		     WHEN FLE.[Depreciation Method] = 6 THEN 'Manuell'
		   END + '"' [AfA-Methode]
		 , CONVERT(varchar(10), FLE.[Depreciation Starting Date], 104) [Startdatum Normal-AfA]
		 , coalesce(REPLACE(CAST(CAST(FLE.[Straight-Line %] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Lineare AfA %]
		 , coalesce(REPLACE(CAST(CAST(FLE.[No_ of Depreciation Years] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Nutzungsdauer i. Jahren]
		 , coalesce(REPLACE(CAST(CAST(FLE.[Declining-Balance %] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Degressive AfA %]
		 , '"' + CASE 
		     WHEN FLE.[Result on Disposal] = 0 THEN ' '
		     WHEN FLE.[Result on Disposal] = 1 THEN 'Gewinn'
		     WHEN FLE.[Result on Disposal] = 2 THEN 'Verlust'
		   END + '"' [Ergebnis bei Verkauf]
	FROM [HRS Holidays$FA Ledger Entry] FLE WITH (NOLOCK)
	WHERE FLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY FLE.[Entry No_]
END
GO
