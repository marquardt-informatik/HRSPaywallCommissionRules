USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUHRSRaggeHoldingExportItemLedgerEntry]    Script Date: 10.04.2024 14:31:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Dennis Juhr (EXTDJU02)
-- Create date: 27.09.2021
-- Description:	GDPdU Export - Artikelposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUHRSRaggeHoldingExportItemLedgerEntry]
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

	WITH VE_SalesAmountActual AS
	(
		SELECT VE.[Item Ledger Entry No_] [Artikelposten Lfd. Nr.]
			 , REPLACE(CAST(CAST(SUM(VE.[Sales Amount (Actual)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Verkaufsbetrag (tatsächl.)]
		FROM [HRS Ragge Holding$Value Entry] VE WITH (NOLOCK)
		GROUP BY VE.[Item Ledger Entry No_]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ILE.[Item No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Artikelnr.]
	     , CONVERT(varchar(10), ILE.[Posting Date], 104) [Buchungsdatum]	
		 , '"' + CASE 
					WHEN ILE.[Entry Type] = 0 THEN 'Einkauf'
					WHEN ILE.[Entry Type] = 1 THEN 'Verkauf'
					WHEN ILE.[Entry Type] = 2 THEN 'Zugang'
					WHEN ILE.[Entry Type] = 3 THEN 'Abgang'
					WHEN ILE.[Entry Type] = 4 THEN 'Umlagerung'
					WHEN ILE.[Entry Type] = 5 THEN 'Verbrauch'
					WHEN ILE.[Entry Type] = 6 THEN 'Istmeldung'
				 END + '"' [Postenart]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ILE.[Source No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Herkunftsnr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ILE.[Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Belegnr.]
		 , COALESCE(ILE.[Quantity], '0,00') [Menge]
		 , '"' + CASE 
					WHEN ILE.[Source Type] = 0 THEN ' '
					WHEN ILE.[Source Type] = 1 THEN 'Debitor'
					WHEN ILE.[Source Type] = 2 THEN 'Kreditor'
					WHEN ILE.[Source Type] = 3 THEN 'Artikel'
				 END + '"' [Herkunftsart]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ILE.[Country_Region Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Länder-/Regionscode]
		 , CONVERT(varchar(10), ILE.[Document Date], 104) [Belegdatum]
		 , COALESCE(VE_SalesAmountActual.[Verkaufsbetrag (tatsächl.)], '0,00') [Verkaufsbetrag (tatsächl.)]
	FROM [HRS Ragge Holding$Item Ledger Entry] ILE WITH (NOLOCK)
	LEFT JOIN VE_SalesAmountActual ON ILE.[Entry No_] = VE_SalesAmountActual.[Artikelposten Lfd. Nr.]
	WHERE ILE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY ILE.[Entry No_]
END
GO
