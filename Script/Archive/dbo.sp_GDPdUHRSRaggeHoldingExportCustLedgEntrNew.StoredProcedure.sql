USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUHRSRaggeHoldingExportCustLedgEntrNew]    Script Date: 10.04.2024 14:31:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Debitorenposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUHRSRaggeHoldingExportCustLedgEntrNew]
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

	WITH DCLE_Rem_Amount AS
	(
		SELECT CLE.[Entry No_] [Debitorenposten Nr.]
			 , REPLACE(CAST(CAST(SUM(DCLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Restbetrag (MW)]
		FROM [HRS Ragge Holding$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [HRS Ragge Holding$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE CLE.[Posting Date] <= @EndDateTime
		GROUP BY CLE.[Entry No_]
	), DCLE_Amount AS
	(
	    SELECT CLE.[Entry No_] [Debitorenposten Nr.]
		     , REPLACE(CAST(CAST(SUM(DCLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag (MW)]
		FROM [HRS Ragge Holding$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [HRS Ragge Holding$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE 1=1--(CLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DCLE.[Entry Type] IN (1, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17)) 
		GROUP BY CLE.[Entry No_]
	), DCLE_Ini_Amount AS
	(
	    SELECT CLE.[Entry No_] [Debitorenposten Nr.]
		     , REPLACE(CAST(CAST(SUM(DCLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Ursprungsbetrag (MW)]
		FROM [HRS Ragge Holding$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [HRS Ragge Holding$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE (CLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DCLE.[Entry Type] = 1) --DCLE.[Entry Type] = Urspr. Posten
		GROUP BY CLE.[Entry No_]
	), DCLE_Deb_Cre_Amount AS
	(
	    SELECT CLE.[Entry No_] [Debitorenposten Nr.]
			 , REPLACE(CAST(CAST(SUM(DCLE.[Debit Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Sollbetrag (MW)]
			 , REPLACE(CAST(CAST(SUM(DCLE.[Credit Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Habenbetrag (MW)]
		FROM [HRS Ragge Holding$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [HRS Ragge Holding$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE 1=1--(CLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DCLE.[Entry Type] != 2) --DCLE.[Entry Type] != Ausgleich
		GROUP BY CLE.[Entry No_]
	)

	SELECT CLE.[Entry No_] [Lfd. Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Customer No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Debitorennr.]
		 , CONVERT(varchar(10), CLE.[Posting Date], 104) [Buchungsdatum]
		 , '"' + CASE 
					WHEN CLE.[Document Type] = 0 THEN ' '
					WHEN CLE.[Document Type] = 1 THEN 'Zahlung'
					WHEN CLE.[Document Type] = 2 THEN 'Rechnung'
					WHEN CLE.[Document Type] = 3 THEN 'Gutschrift'
					WHEN CLE.[Document Type] = 4 THEN 'Zinsrechnung'
					WHEN CLE.[Document Type] = 5 THEN 'Mahnung'
					WHEN CLE.[Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Belegart]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Belegnr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Description], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Beschreibung]
		 , COALESCE(DCLE_Rem_Amount.[Restbetrag (MW)], '0,00') [Restbetrag (MW)]
		 , COALESCE(DCLE_Amount.[Betrag (MW)], '0,00') [Betrag (MW)]
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Global Dimension 1 Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Globaler Dimensionscode 1]
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Global Dimension 2 Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Globaler Dimensionscode 2]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[User ID], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Benutzer-ID]
		 , CONVERT(varchar(10), CLE.[Due Date], 104) [Fälligkeitsdatum]		 
		 --, COALESCE(DCLE_Ini_Amount.[Ursprungsbetrag (MW)], '0,00') [Ursprungsbetrag (MW)]
		 , CONVERT(varchar(10), CLE.[Closed at Date], 104) [Geschlossen am]
		 , '"' + CASE 
					WHEN CLE.[Bal_ Account Type] = 0 THEN 'Sachkonto'
					WHEN CLE.[Bal_ Account Type] = 1 THEN 'Debitor'
					WHEN CLE.[Bal_ Account Type] = 2 THEN 'Kreditor'
					WHEN CLE.[Bal_ Account Type] = 3 THEN 'Bankkonto'
					WHEN CLE.[Bal_ Account Type] = 4 THEN 'Anlage'
				 END + '"' [Gegenkontoart]
 	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Bal_ Account No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Gegenkontonr.]
		 , CLE.[Transaction No_] [Transaktionsnr.]
		 , COALESCE(DCLE_Deb_Cre_Amount.[Sollbetrag (MW)], '0,00') [Sollbetrag (MW)]
		 , COALESCE(DCLE_Deb_Cre_Amount.[Habenbetrag (MW)], '0,00') [Habenbetrag (MW)]
		 , CONVERT(varchar(10), CLE.[Document Date], 104) [Belegdatum]	
	FROM [HRS Ragge Holding$Cust_ Ledger Entry] CLE WITH (NOLOCK)
	LEFT JOIN DCLE_Rem_Amount ON CLE.[Entry No_] = DCLE_Rem_Amount.[Debitorenposten Nr.]
	LEFT JOIN DCLE_Amount ON CLE.[Entry No_] = DCLE_Amount.[Debitorenposten Nr.]
	LEFT JOIN DCLE_Ini_Amount ON CLE.[Entry No_] = DCLE_Ini_Amount.[Debitorenposten Nr.]
	LEFT JOIN DCLE_Deb_Cre_Amount ON CLE.[Entry No_] = DCLE_Deb_Cre_Amount.[Debitorenposten Nr.]
	WHERE CLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY CLE.[Entry No_]
END
GO
