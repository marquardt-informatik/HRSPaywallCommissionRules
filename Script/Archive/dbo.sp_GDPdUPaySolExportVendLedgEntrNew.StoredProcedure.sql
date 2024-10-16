USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUPaySolExportVendLedgEntrNew]    Script Date: 10.04.2024 14:31:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Kreditorenposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUPaySolExportVendLedgEntrNew]
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

	WITH DVLE_Rem_Amount AS
	(
		SELECT VLE.[Entry No_] [Kreditorenposten Nr.]
			 , REPLACE(CAST(CAST(SUM(DVLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Restbetrag (MW)]
		FROM [HRS PaySol$Vendor Ledger Entry] VLE WITH (NOLOCK)
		JOIN [HRS PaySol$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK)
		ON VLE.[Entry No_] = DVLE.[Vendor Ledger Entry No_]
		WHERE VLE.[Posting Date] <= @EndDateTime
		GROUP BY VLE.[Entry No_]
	), DVLE_Amount AS
	(
	    SELECT VLE.[Entry No_] [Kreditorenposten Nr.]
		     , REPLACE(CAST(CAST(SUM(DVLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag (MW)]
		FROM [HRS PaySol$Vendor Ledger Entry] VLE WITH (NOLOCK)
		JOIN [HRS PaySol$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK)
		ON VLE.[Entry No_] = DVLE.[Vendor Ledger Entry No_]
		WHERE 1=1--(VLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DVLE.[Entry Type] IN (1, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17)) 
		GROUP BY VLE.[Entry No_]
	), DVLE_Ini_Amount AS
	(
	    SELECT VLE.[Entry No_] [Kreditorenposten Nr.]
		     , REPLACE(CAST(CAST(SUM(DVLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Ursprungsbetrag (MW)]
		FROM [HRS PaySol$Vendor Ledger Entry] VLE WITH (NOLOCK)
		JOIN [HRS PaySol$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK)
		ON VLE.[Entry No_] = DVLE.[Vendor Ledger Entry No_]
		WHERE (VLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DVLE.[Entry Type] = 1) --DVLE.[Entry Type] = Urspr. Posten
		GROUP BY VLE.[Entry No_]
	), DVLE_Deb_Cre_Amount AS
	(
	    SELECT VLE.[Entry No_] [Kreditorenposten Nr.]
			 , REPLACE(CAST(CAST(SUM(DVLE.[Debit Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Sollbetrag (MW)]
			 , REPLACE(CAST(CAST(SUM(DVLE.[Credit Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Habenbetrag (MW)]
		FROM [HRS PaySol$Vendor Ledger Entry] VLE WITH (NOLOCK)
		JOIN [HRS PaySol$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK)
		ON VLE.[Entry No_] = DVLE.[Vendor Ledger Entry No_]
		WHERE 1=1--(VLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DVLE.[Entry Type] != 2) --DVLE.[Entry Type] != Ausgleich
		GROUP BY VLE.[Entry No_]
	)

	SELECT VLE.[Entry No_] [Lfd. Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Vendor No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Kreditorennr.]
		 , CONVERT(varchar(10), VLE.[Posting Date], 104) [Buchungsdatum]
		 , '"' + CASE 
					WHEN VLE.[Document Type] = 0 THEN ' '
					WHEN VLE.[Document Type] = 1 THEN 'Zahlung'
					WHEN VLE.[Document Type] = 2 THEN 'Rechnung'
					WHEN VLE.[Document Type] = 3 THEN 'Gutschrift'
					WHEN VLE.[Document Type] = 4 THEN 'Zinsrechnung'
					WHEN VLE.[Document Type] = 5 THEN 'Mahnung'
					WHEN VLE.[Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Belegart]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Belegnr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Description], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Beschreibung]
		 , COALESCE(DVLE_Rem_Amount.[Restbetrag (MW)], '0,00') [Restbetrag (MW)]
		 , COALESCE(DVLE_Amount.[Betrag (MW)], '0,00') [Betrag (MW)]
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Global Dimension 1 Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Globaler Dimensionscode 1]
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Global Dimension 2 Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Globaler Dimensionscode 2]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[User ID], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Benutzer-ID]
		 , CONVERT(varchar(10), VLE.[Due Date], 104) [Fälligkeitsdatum]		 
		 --, COALESCE(DVLE_Ini_Amount.[Ursprungsbetrag (MW)], '0,00') [Ursprungsbetrag (MW)]
		 , CONVERT(varchar(10), VLE.[Closed at Date], 104) [Geschlossen am]
		 , '"' + CASE 
					WHEN VLE.[Bal_ Account Type] = 0 THEN 'Sachkonto'
					WHEN VLE.[Bal_ Account Type] = 1 THEN 'Debitor'
					WHEN VLE.[Bal_ Account Type] = 2 THEN 'Kreditor'
					WHEN VLE.[Bal_ Account Type] = 3 THEN 'Bankkonto'
					WHEN VLE.[Bal_ Account Type] = 4 THEN 'Anlage'
				 END + '"' [Gegenkontoart]
 	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Bal_ Account No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Gegenkontonr.]
		 , VLE.[Transaction No_] [Transaktionsnr.]
		 , COALESCE(DVLE_Deb_Cre_Amount.[Sollbetrag (MW)], '0,00') [Sollbetrag (MW)]
		 , COALESCE(DVLE_Deb_Cre_Amount.[Habenbetrag (MW)], '0,00') [Habenbetrag (MW)]
		 , CONVERT(varchar(10), VLE.[Document Date], 104) [Belegdatum]	
	FROM [HRS PaySol$Vendor Ledger Entry] VLE WITH (NOLOCK)
	LEFT JOIN DVLE_Rem_Amount ON VLE.[Entry No_] = DVLE_Rem_Amount.[Kreditorenposten Nr.]
	LEFT JOIN DVLE_Amount ON VLE.[Entry No_] = DVLE_Amount.[Kreditorenposten Nr.]
	LEFT JOIN DVLE_Ini_Amount ON VLE.[Entry No_] = DVLE_Ini_Amount.[Kreditorenposten Nr.]
	LEFT JOIN DVLE_Deb_Cre_Amount ON VLE.[Entry No_] = DVLE_Deb_Cre_Amount.[Kreditorenposten Nr.]
	WHERE VLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY VLE.[Entry No_]
END
GO
