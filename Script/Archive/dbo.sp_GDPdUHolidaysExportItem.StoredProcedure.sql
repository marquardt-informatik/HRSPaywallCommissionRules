USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUHolidaysExportItem]    Script Date: 10.04.2024 14:31:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Dennis Juhr (EXTDJU02)
-- Create date: 27.09.2021
-- Description:	GDPdU Export - Artikel
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUHolidaysExportItem]
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

	WITH ILE_NetChange AS
	(
		SELECT ILE.[Item No_] [Artikelnr.]
			 , REPLACE(CAST(CAST(SUM(ILE.[Quantity]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Menge]
		FROM [HRS Holidays$Item Ledger Entry] ILE WITH (NOLOCK)
		WHERE ILE.[Posting Date] <= @EndDateTime
		GROUP BY ILE.[Item No_]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I.[No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I.[Description], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Beschreibung]
		 , COALESCE(ILE_NetChange.[Menge], '0,00') [Bewegung]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I.[VAT Bus_ Posting Gr_ (Price)], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [MwSt.-Geschäftsbuch.-G.(Preis)]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I.[VAT Prod_ Posting Group], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [MwSt.-Produktbuchungsgruppe]
	FROM [HRS Holidays$Item] I WITH (NOLOCK)
	LEFT JOIN ILE_NetChange ON I.No_ = ILE_NetChange.[Artikelnr.]
	ORDER BY I.[No_]
END
GO
