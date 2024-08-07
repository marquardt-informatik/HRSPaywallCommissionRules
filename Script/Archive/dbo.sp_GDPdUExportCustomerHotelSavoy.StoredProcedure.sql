USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportCustomerHotelSavoy]    Script Date: 10.04.2024 14:31:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Debitoren
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportCustomerHotelSavoy]
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

	WITH DCLE AS
	(
		SELECT DCLE.[Customer No_]																		[Debitor Nr.]
		     , REPLACE(CAST(CAST(SUM(DCLE.[Amount (LCY)]) AS DECIMAL(38,2)) AS varchar(40)), '.', ',')	[Bewegung (MW)]
		FROM [Hotel Savoy$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		WHERE DCLE.[Posting Date] between @StartDateTime AND @EndDateTime
		GROUP BY DCLE.[Customer No_]
	), DCLE2 AS
	(	
		SELECT DCLE2.[Customer No_]																		[Debitor Nr.]
		     , REPLACE(CAST(CAST(SUM(DCLE2.[Debit Amount (LCY)]) AS DECIMAL(38,2)) AS varchar(40)), '.', ',')	[Sollbetrag (MW)]
			 , REPLACE(CAST(CAST(SUM(DCLE2.[Credit Amount (LCY)]) AS DECIMAL(38,2)) AS varchar(40)), '.', ',')	[Habenbetrag (MW)]
		FROM [Hotel Savoy$Detailed Cust_ Ledg_ Entry] DCLE2 WITH (NOLOCK)
		WHERE DCLE2.[Posting Date] <= @EndDateTime
		GROUP BY DCLE2.[Customer No_]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(CE.[No_] AS VARCHAR), CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.Name, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[Name 2], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name 2]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.Address, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Adresse]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[Address 2], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Adresse 2]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.City, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Ort]	
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[Country_Region Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Länder-/Regionscode]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[Bill-to Customer No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Rech. an Deb.-Nr.]    
	     , COALESCE(DCLE.[Bewegung (MW)], '0,00') [Bewegung (MW)]
         , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[VAT Registration No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [USt-IdNr.]
         , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[Post Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [PLZ-Code]
	     , COALESCE(DCLE2.[Sollbetrag (MW)], '0,00') [Sollbetrag (MW)]
	     , COALESCE(DCLE2.[Habenbetrag (MW)], '0,00') [Habenbetrag (MW)]
         , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CE.[Tax Area Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Stuergebietscode]	
	FROM [Hotel Savoy$Customer] CE WITH (NOLOCK)
	LEFT JOIN DCLE
	ON CE.No_ = DCLE.[Debitor Nr.]
	LEFT JOIN DCLE2
	ON CE.No_ = DCLE2.[Debitor Nr.]	
	ORDER BY CE.No_
END
GO
