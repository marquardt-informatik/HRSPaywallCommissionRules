USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUHDEExportCustLedgEntr]    Script Date: 10.04.2024 14:31:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Dennis Juhr (DJU)
-- Create date: 23.01.2018
-- Description:	GDPdU Export - Debitorenposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUHDEExportCustLedgEntr]
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
		FROM [hotel_de$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [hotel_de$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE CLE.[Posting Date] between @StartDateTime AND @EndDateTime
		GROUP BY CLE.[Entry No_]
	), DCLE_Amount AS
	(
		SELECT CLE.[Entry No_] [Debitorenposten Nr.]
			 , REPLACE(CAST(CAST(SUM(DCLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag (MW)]
		FROM [hotel_de$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [hotel_de$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE (CLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DCLE.[Entry Type] IN (1, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17))
		GROUP BY CLE.[Entry No_]
	), DCLE_Deb_Cre_Amount AS
	(
		SELECT CLE.[Entry No_] [Debitorenposten Nr.]
			 , REPLACE(CAST(CAST(SUM(DCLE.[Debit Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Sollbetrag (MW)]
			 , REPLACE(CAST(CAST(SUM(DCLE.[Credit Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Habenbetrag (MW)]
		FROM [hotel_de$Cust_ Ledger Entry] CLE WITH (NOLOCK)
		JOIN [hotel_de$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
		WHERE (CLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		  AND (DCLE.[Entry Type] != 2) --DCLE.[Entry Type] != Ausgleich
		GROUP BY CLE.[Entry No_]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Customer No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Debitorennr.]
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
	     , CONVERT(varchar(10), CLE.[Due Date], 104) [Fälligkeitsdatum]
	     , CONVERT(varchar(10), CLE.[Document Date], 104) [Belegdatum]
		 , COALESCE(DCLE_Deb_Cre_Amount.[Sollbetrag (MW)], '0,00') [Sollbetrag (MW)]
		 , COALESCE(DCLE_Deb_Cre_Amount.[Habenbetrag (MW)], '0,00') [Habenbetrag (MW)]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[User ID], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Benutzer-ID]
	     , '"' + CASE WHEN CLE.[Open] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Offen]
	FROM [hotel_de$Cust_ Ledger Entry] CLE WITH (NOLOCK)
	LEFT JOIN DCLE_Rem_Amount ON CLE.[Entry No_] = DCLE_Rem_Amount.[Debitorenposten Nr.]
	LEFT JOIN DCLE_Amount ON CLE.[Entry No_] = DCLE_Amount.[Debitorenposten Nr.]
	LEFT JOIN DCLE_Deb_Cre_Amount ON CLE.[Entry No_] = DCLE_Deb_Cre_Amount.[Debitorenposten Nr.]
	WHERE CLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY CLE.[Customer No_], CLE.[Entry No_]
END

GO
