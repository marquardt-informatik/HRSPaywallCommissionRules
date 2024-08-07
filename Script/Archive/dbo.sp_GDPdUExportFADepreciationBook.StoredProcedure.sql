USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportFADepreciationBook]    Script Date: 10.04.2024 14:31:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Dennis Juhr (EXTDJU02)
-- Create date: 27.09.2021
-- Description:	GDPdU Export - Anlagen-AfA-Buch
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportFADepreciationBook]
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

	WITH FALE_AcquisitionCost AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 1
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_Depreciation AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 2
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_BookValue AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[Part of Book Value] = 1
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_ProceedsOnDisposal AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 7
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_GainLoss AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 9
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_WriteDown AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 3
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_Appreciation AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 4
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_Custom1 AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 5
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_Custom2 AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 6
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_DepreciableBasis AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @StartDateTime
		  AND FALE.[Part of Depreciable Basis] = 1
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_SalvageValue AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 0
		  AND FALE.[FA Posting Type] = 8
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	), FALE_BookValueOnDisposal AS
	(
		SELECT FALE.[FA No_] [Anlagennr.]
		     , FALE.[Depreciation Book Code] [AfA Buchcode]
			 , REPLACE(CAST(CAST(SUM(FALE.[Amount]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
		FROM [HRS$FA Ledger Entry] FALE WITH (NOLOCK)
		WHERE FALE.[FA Posting Date] <= @EndDateTime
		  AND FALE.[FA Posting Category] = 1
		  AND FALE.[FA Posting Type] = 10
		GROUP BY FALE.[FA No_], FALE.[Depreciation Book Code]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FADB.[FA No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Anlagennr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FADB.[Depreciation Book Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [AfA Buchcode]
		 , '"' + CASE 
		     WHEN FADB.[Depreciation Method] = 0 THEN 'Linear'
		     WHEN FADB.[Depreciation Method] = 1 THEN 'Degressiv 1'
		     WHEN FADB.[Depreciation Method] = 2 THEN 'Degressiv 2'
		     WHEN FADB.[Depreciation Method] = 3 THEN 'Degr1/Linear'
		     WHEN FADB.[Depreciation Method] = 4 THEN 'Degr2/Linear'
		     WHEN FADB.[Depreciation Method] = 5 THEN 'Tabelle'
		     WHEN FADB.[Depreciation Method] = 6 THEN 'Manuell'
		   END + '"' [AfA-Methode]
		 , CONVERT(varchar(10), FADB.[Depreciation Starting Date], 104) [Startdatum Normal-AfA]
		 , coalesce(REPLACE(CAST(CAST(FADB.[Straight-Line %] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Lineare AfA %]
		 , coalesce(REPLACE(CAST(CAST(FADB.[No_ of Depreciation Years] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Nutzungsdauer i. Jahren]
		 , coalesce(REPLACE(CAST(CAST(FADB.[No_ of Depreciation Months] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Nutzungsdauer i. Monaten]
		 , coalesce(REPLACE(CAST(CAST(FADB.[Fixed Depr_ Amount] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Fester AfA-Betrag]
		 , coalesce(REPLACE(CAST(CAST(FADB.[Declining-Balance %] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Degressive AfA %]
		 , coalesce(REPLACE(CAST(CAST(FADB.[Final Rounding Amount] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Nullgrenze]
		 , coalesce(REPLACE(CAST(CAST(FADB.[Ending Book Value] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Erinnerungswert]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FADB.[FA Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Anlagenbuchungsgruppe]
		 , COALESCE(FALE_AcquisitionCost.[Betrag], '0,00') [Anschaffungskosten]
		 , COALESCE(FALE_Depreciation.[Betrag], '0,00') [Normal-AfA]
		 , COALESCE(FALE_BookValue.[Betrag], '0,00') [Buchwert]
		 , COALESCE(FALE_ProceedsOnDisposal.[Betrag], '0,00') [Verkaufspreis]
		 , COALESCE(FALE_GainLoss.[Betrag], '0,00') [Gewinn/Verlust]
		 , COALESCE(FALE_WriteDown.[Betrag], '0,00') [Erhöhte AfA]
		 , COALESCE(FALE_Appreciation.[Betrag], '0,00') [Zuschreibung]
		 , COALESCE(FALE_Custom1.[Betrag], '0,00') [Sonder-AfA]
		 , COALESCE(FALE_Custom2.[Betrag], '0,00') [Benutzerdef. AfA]
		 , COALESCE(FALE_DepreciableBasis.[Betrag], '0,00') [Grundlage für AfA]
		 , COALESCE(FALE_SalvageValue.[Betrag], '0,00') [Restwert]
		 , COALESCE(FALE_BookValueOnDisposal.[Betrag], '0,00') [Buchwert bei Verkauf]
		 , CONVERT(varchar(10), FADB.[Acquisition Date], 104) [Anschaffungsdatum]
		 , CONVERT(varchar(10), FADB.[G_L Acquisition Date], 104) [Fibu-Anschaffungsdatum]
		 , CONVERT(varchar(10), FADB.[Disposal Date], 104) [Verkaufsdatum]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FADB.[Description], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Beschreibung]
		 , '"' + CASE 
		     WHEN FADB.[Main Asset_Component] = 0 THEN ' '
		     WHEN FADB.[Main Asset_Component] = 1 THEN 'Hauptanlage'
		     WHEN FADB.[Main Asset_Component] = 2 THEN 'Unteranlage'
		   END + '"' [Hauptanlage/Unteranlage]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FADB.[Component of Main Asset], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Hauptanl.-Nr.]
	FROM [HRS$FA Depreciation Book] FADB WITH (NOLOCK)
	LEFT JOIN FALE_AcquisitionCost ON FADB.[FA No_] = FALE_AcquisitionCost.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_AcquisitionCost.[AfA Buchcode]
	LEFT JOIN FALE_Depreciation ON FADB.[FA No_] = FALE_Depreciation.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_Depreciation.[AfA Buchcode]
	LEFT JOIN FALE_BookValue ON FADB.[FA No_] = FALE_BookValue.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_BookValue.[AfA Buchcode]
	LEFT JOIN FALE_ProceedsOnDisposal ON FADB.[FA No_] = FALE_ProceedsOnDisposal.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_ProceedsOnDisposal.[AfA Buchcode]
	LEFT JOIN FALE_GainLoss ON FADB.[FA No_] = FALE_GainLoss.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_GainLoss.[AfA Buchcode]
	LEFT JOIN FALE_WriteDown ON FADB.[FA No_] = FALE_WriteDown.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_WriteDown.[AfA Buchcode]
	LEFT JOIN FALE_Appreciation ON FADB.[FA No_] = FALE_Appreciation.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_Appreciation.[AfA Buchcode]
	LEFT JOIN FALE_Custom1 ON FADB.[FA No_] = FALE_Custom1.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_Custom1.[AfA Buchcode]
	LEFT JOIN FALE_Custom2 ON FADB.[FA No_] = FALE_Custom2.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_Custom2.[AfA Buchcode]
	LEFT JOIN FALE_DepreciableBasis ON FADB.[FA No_] = FALE_DepreciableBasis.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_DepreciableBasis.[AfA Buchcode]
	LEFT JOIN FALE_SalvageValue ON FADB.[FA No_] = FALE_SalvageValue.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_SalvageValue.[AfA Buchcode]
	LEFT JOIN FALE_BookValueOnDisposal ON FADB.[FA No_] = FALE_BookValueOnDisposal.[Anlagennr.] AND FADB.[Depreciation Book Code] = FALE_BookValueOnDisposal.[AfA Buchcode]
	ORDER BY FADB.[FA No_], FADB.[Depreciation Book Code]
END
GO
