USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUPaySolExportGLAccountNew]    Script Date: 10.04.2024 14:31:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Sachkonten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUPaySolExportGLAccountNew]
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
		     , REPLACE(CAST(CAST(SUM(GLE.Amount) AS DECIMAL(38,2)) AS varchar(40)), '.', ',') [Bewegung]
		FROM [HRS PaySol$G_L Entry] GLE WITH (NOLOCK)
		WHERE (GLE.[Posting Date] between @StartDateTime AND @EndDateTime)
		GROUP BY GLE.[G_L Account No_]
	  UNION
		SELECT GLA.No_ [Sachkonto Nr.]
			 , REPLACE(CAST(CAST(SUM(GLE_Totaling.Amount) AS DECIMAL(38,2)) AS varchar(40)), '.', ',') [Bewegung]
		FROM 
			( SELECT No_
				   , LEFT(Totaling, PATINDEX('%..%', Totaling) -1) [From No_]
				   , RIGHT(Totaling, PATINDEX('%..%', Totaling) -1) [To No_]
			  FROM [HRS PaySol$G_L Account] WITH (NOLOCK)
			  WHERE Totaling != ''
			) GLA
		JOIN [HRS PaySol$G_L Entry] GLE_Totaling WITH (NOLOCK)
		ON GLE_Totaling.[G_L Account No_] BETWEEN GLA.[From No_] AND GLA.[To No_]
		AND (GLE_Totaling.[Posting Date] between @StartDateTime AND @EndDateTime)
		GROUP BY GLA.No_
	), GLE2 AS
	(
		SELECT GLE2.[G_L Account No_] [Sachkonto Nr.]
		     , REPLACE(CAST(CAST(SUM(GLE2.Amount) AS DECIMAL(38,2)) AS varchar(40)), '.', ',') [Saldo bis Datum]
		FROM [HRS PaySol$G_L Entry] GLE2 WITH (NOLOCK)
		WHERE (GLE2.[Posting Date] <=  @EndDateTime)
		GROUP BY GLE2.[G_L Account No_]
    )

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLA.[No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Nr.]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLA.Name, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name]
		  , '"' + CASE 
					WHEN GLA.[Account Type] = 0 THEN 'Konto'
					WHEN GLA.[Account Type] = 1 THEN 'Ueberschrift'
					WHEN GLA.[Account Type] = 2 THEN 'Summe'
					WHEN GLA.[Account Type] = 3 THEN 'Von-Summe'
					WHEN GLA.[Account Type] = 4 THEN 'Bis-Summe'
				 END + '"' [Kontoart]	     
		 , '"' + CASE WHEN GLA.Income_Balance = 0 THEN 'GuV' ELSE 'Bilanz' END + '"' [GuV/Bilanz]
		 , '"' + CASE WHEN GLA.[Direct Posting] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Direkt]
		 , COALESCE(GLE2.[Saldo bis Datum], '0,00') [Saldo bis Datum]		
		 , COALESCE(GLE.[Bewegung], '0,00') [Bewegung]
		-- , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLA.[Search Name], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Suchbegriff]

	FROM [HRS PaySol$G_L Account] GLA WITH (NOLOCK)
	LEFT JOIN GLE 
	ON GLA.[No_] = GLE.[Sachkonto Nr.]
	LEFT JOIN GLE2 
	ON GLA.[No_] = GLE2.[Sachkonto Nr.]
	ORDER BY GLA.No_
END
GO
