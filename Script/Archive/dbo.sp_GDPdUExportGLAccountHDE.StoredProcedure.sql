USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportGLAccountHDE]    Script Date: 10.04.2024 14:31:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Dennis Juhr (DJU)
-- Create date: 23.01.2018
-- Description:	GDPdU Export - Sachkonten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportGLAccountHDE]
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

	WITH GLE AS
	(
		SELECT GLE.[G_L Account No_] [Sachkonto Nr.]
		     , REPLACE(CAST(CAST(SUM(GLE.Amount) AS DECIMAL(11,2)) AS varchar(40)), '.', ',') [Bewegung]
		FROM [hotel_de$G_L Entry] GLE WITH (NOLOCK)
		GROUP BY GLE.[G_L Account No_]
	  UNION
		SELECT GLA.No_ [Sachkonto Nr.]
			 , REPLACE(CAST(CAST(SUM(GLE_Totaling.Amount) AS DECIMAL(15,2)) AS varchar(40)), '.', ',') [Bewegung]
		FROM 
			( SELECT No_
				   , LEFT(Totaling, PATINDEX('%..%', Totaling) -1) [From No_]
				   , RIGHT(Totaling, PATINDEX('%..%', Totaling) -1) [To No_]
			  FROM [hotel_de$G_L Account] WITH (NOLOCK)
			  WHERE Totaling LIKE '%..%'
			) GLA
		JOIN [hotel_de$G_L Entry] GLE_Totaling WITH (NOLOCK)
		ON GLE_Totaling.[G_L Account No_] BETWEEN GLA.[From No_] AND GLA.[To No_]
		GROUP BY GLA.No_
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLA.[No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Nr.]
	     , '"' + CASE WHEN GLA.Income_Balance = 0 THEN 'GuV' ELSE 'Bilanz' END + '"' [GuV/Bilanz]
		 , COALESCE(GLE.[Bewegung], '0,00') [Bewegung]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLA.Name, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLA.[Search Name], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Suchbegriff]

	FROM [hotel_de$G_L Account] GLA WITH (NOLOCK)
	LEFT JOIN GLE 
	ON GLA.[No_] = GLE.[Sachkonto Nr.]
	ORDER BY GLA.No_
END
GO
