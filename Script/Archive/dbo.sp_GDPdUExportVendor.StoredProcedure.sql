USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportVendor]    Script Date: 10.04.2024 14:31:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Dennis Juhr (DJU)
-- Create date: 23.01.2018
-- Description:	GDPdU Export - Kreditoren
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportVendor]
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

	WITH DVLE AS
	(
		SELECT DVLE.[Vendor No_]																		[Kreditor Nr.]
		     , REPLACE(CAST(CAST(SUM(DVLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',')	[Bewegung (MW)]
		FROM [HRS$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK)
		WHERE DVLE.[Posting Date] between @StartDateTime AND @EndDateTime
		GROUP BY DVLE.[Vendor No_]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(VE.[No_] AS VARCHAR), CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VE.Name, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VE.[Name 2], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name 2]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VE.[Post Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [PLZ-Code]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VE.City, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Ort]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VE.[Country_Region Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Länder-/Regionscode]
	     , COALESCE(DVLE.[Bewegung (MW)], '0,00') [Bewegung (MW)]
	     , '"' + CASE 				
					WHEN VE.Blocked = 0 THEN ' '
					WHEN VE.Blocked = 1 THEN 'Zahlung'
					WHEN VE.Blocked = 2 THEN 'Alle'
				 END + '"' [Gesperrt]
	FROM [HRS$Vendor] VE WITH (NOLOCK)
	LEFT JOIN DVLE
	ON VE.No_ = DVLE.[Kreditor Nr.]
	ORDER BY VE.No_
END
GO
