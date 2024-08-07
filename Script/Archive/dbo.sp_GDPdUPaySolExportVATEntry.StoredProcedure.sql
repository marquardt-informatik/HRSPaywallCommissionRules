USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUPaySolExportVATEntry]    Script Date: 10.04.2024 14:31:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 15.10.2018
-- Description:	GDPdU Export - MwSt.-Posten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUPaySolExportVATEntry]
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
		

	SELECT [Entry No_] [Lfd. Nr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Gen_ Bus_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Geschaeftsbuchungsgruppe]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Gen_ Prod_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Produktbuchungsgruppe]
	     , CONVERT(varchar(10), [Posting Date], 104) [Buchungsdatum]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Document No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Belegnr.]
		 , '"' + CASE 
					WHEN [Document Type] = 0 THEN ' '
					WHEN [Document Type] = 1 THEN 'Zahlung'
					WHEN [Document Type] = 2 THEN 'Rechnung'
					WHEN [Document Type] = 3 THEN 'Gutschrift'
					WHEN [Document Type] = 4 THEN 'Zinsrechnung'
					WHEN [Document Type] = 5 THEN 'Mahnung'
					WHEN [Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Belegart]
	      , '"' + CASE 
					WHEN [Document Type] = 0 THEN ' '
					WHEN [Document Type] = 1 THEN 'Einkauf'
					WHEN [Document Type] = 2 THEN 'Verkauf'
					WHEN [Document Type] = 3 THEN 'Ausgleich'
				 END + '"' [Art]		
	     , COALESCE([Base], '0,00') [Bemessungsgrundlage]
		 , COALESCE([Amount], '0,00') [Betrag]
		 , '"' + CASE 
					WHEN [VAT Calculation Type] = 0 THEN 'Normale MwSt.'
					WHEN [VAT Calculation Type] = 1 THEN 'Erwerbsbesteuerung'
					WHEN [VAT Calculation Type] = 2 THEN 'Nur MwSt.'
					WHEN [VAT Calculation Type] = 3 THEN 'Verkaufsteuer'
				 END + '"' [MwSt.-Berechnungsart]		 
     	 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Bill-to_Pay-to No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Rech. an/Zahlung an Nr.]
	     , '"' + CASE WHEN [EU 3-Party Trade] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [EU-Dreiecksgeschäft]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Source Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Herkunftscode]
	     , [Closed by Entry No_] [Geschlossen Lfd. Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Country_Region Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Länder-/Regionscode]
		 , [Transaction No_] [Transaktionsnr.]
	      , '"' + CASE 
					WHEN [Tax Type] = 0 THEN 'Verkaufssteuer'
					WHEN [Tax Type] = 1 THEN 'Indirekte Steuer'
				 END + '"' [Steuerart]		
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([VAT Bus_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [MwSt.-Geschaefsbuchungsgruppe]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([VAT Prod_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [MwSt.-Produktbuchungsgruppe]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([VAT Registration No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [USt.-IdNr.]
	FROM [HRS PaySol$VAT Entry] WITH (NOLOCK)
	WHERE [Posting Date] between @StartDateTime AND @EndDateTime
	--ORDER BY CLE.[Customer No_], CLE.[Entry No_]
END
GO
