USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdURoRaFamilienHoldingExportGLEntryNew]    Script Date: 10.04.2024 14:31:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Sachposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdURoRaFamilienHoldingExportGLEntryNew]
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

	SELECT GLE.[Entry No_] [Lfd. Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[G_L Account No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Sachkontonr.]
	     --, FORMAT(GLE.[Posting Date], 'dd.MM.yyy') [Buchungsdatum]
		 , CONVERT(varchar(10), GLE.[Posting Date], 104) [Buchungsdatum]
		 , '"' + CASE 
					WHEN GLE.[Document Type] = 0 THEN ' '
					WHEN GLE.[Document Type] = 1 THEN 'Zahlung'
					WHEN GLE.[Document Type] = 2 THEN 'Rechnung'
					WHEN GLE.[Document Type] = 3 THEN 'Gutschrift'
					WHEN GLE.[Document Type] = 4 THEN 'Zinsrechnung'
					WHEN GLE.[Document Type] = 5 THEN 'Mahnung'
					WHEN GLE.[Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Belegart]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Belegnr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.Description, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Beschreibung]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[Bal_ Account No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Gegenkontonr.]
	     , REPLACE(CAST(CAST(GLE.Amount AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Betrag]
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[Global Dimension 1 Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Globaler Dimensionscode 1]
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[Global Dimension 2 Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Globaler Dimensionscode 2]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[User ID], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Benutzer-ID]
	     , '"' + CASE WHEN GLE.[System-Created Entry] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Systembuchung]
	     , REPLACE(CAST(CAST(GLE.[VAT Amount] AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [MwSt.-Betrag]
		 , '"' + CASE 
					WHEN GLE.[Gen_ Posting Type] = 0 THEN ' '
					WHEN GLE.[Gen_ Posting Type] = 1 THEN 'Einkauf'
					WHEN GLE.[Gen_ Posting Type] = 2 THEN 'Verkauf'
					WHEN GLE.[Gen_ Posting Type] = 3 THEN 'Ausgleich'
				 END + '"' [Buchungsart]
		 , '"' + CASE 
					WHEN GLE.[Bal_ Account Type] = 0 THEN 'Sachkonto'
					WHEN GLE.[Bal_ Account Type] = 1 THEN 'Debitor'
					WHEN GLE.[Bal_ Account Type] = 2 THEN 'Kreditor'
					WHEN GLE.[Bal_ Account Type] = 3 THEN 'Bankkonto'
					WHEN GLE.[Bal_ Account Type] = 4 THEN 'Anlage'
				 END + '"' [Gegenkontoart]				 	     
		 , GLE.[Transaction No_] [Transaktionsnr.]
	     , REPLACE(CAST(CAST(GLE.[Debit Amount] AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Sollbetrag]
	     , REPLACE(CAST(CAST(GLE.[Credit Amount] AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Habenbetrag]
	     , CONVERT(varchar(10), GLE.[Document Date], 104) [Belegdatum]
 	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[External Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Externe Belegnummer]
		 , '"' + CASE 
					WHEN GLE.[Source Type] = 0 THEN ' '
					WHEN GLE.[Source Type] = 1 THEN 'Debitor'
					WHEN GLE.[Source Type] = 2 THEN 'Kreditor'
					WHEN GLE.[Source Type] = 3 THEN 'Bankkonto'
					WHEN GLE.[Source Type] = 4 THEN 'Anlage'
				 END + '"' [Herkunftsart]	
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[Source No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Herkunftsnr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[VAT Bus_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [MwSt.-Geschaefsbuchungsgruppe]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[VAT Prod_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [MwSt.Produktbuchungsgruppe]
	
	--     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[User ID], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Benutzer-ID]
   	--     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLE.[IC Partner Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [IC-Partnercode]
	FROM [RoRa Familien Holding$G_L Entry] GLE WITH (NOLOCK)
	WHERE GLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY GLE.[G_L Account No_], GLE.[Entry No_]

END
GO
