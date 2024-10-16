USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdURoRaFamilienHoldingExportCustomer]    Script Date: 10.04.2024 14:31:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Dennis Juhr (DJU)
-- Create date: 23.01.2018
-- Description:	GDPdU Export - Debitoren
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdURoRaFamilienHoldingExportCustomer]
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
		     , REPLACE(CAST(CAST(SUM(DCLE.[Amount (LCY)]) AS DECIMAL(11,2)) AS varchar(40)), '.', ',')	[Bewegung (MW)]
		FROM [HRS$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK)
		WHERE DCLE.[Posting Date] between @StartDateTime AND @EndDateTime
		GROUP BY DCLE.[Customer No_]
	)

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(CU.[No_] AS VARCHAR), CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Nr.]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.Name, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.[Name 2], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Name 2]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.[Post Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [PLZ-Code]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.City, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Ort]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.[Country_Region Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Länder-/Regionscode]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.[VAT Registration No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [USt-IdNr.]
	     , COALESCE(DCLE.[Bewegung (MW)], '0,00') [Bewegung (MW)]
	     , '"' + CASE 				
					WHEN CU.Blocked = 0 THEN ' '
					WHEN CU.Blocked = 1 THEN 'Liefern'
					WHEN CU.Blocked = 2 THEN 'Fakturieren'
					WHEN CU.Blocked = 3 THEN 'Alle'
				 END + '"' [Gesperrt]
	     , '"' + CASE WHEN CU.[Blocked for further postings] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Gesperrt für weitere Buchungen]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.[Contract Status], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Contract Status]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CU.Testhotel, CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Testhotel]
	     , CU.[Hotel Status] [Hotel Status]
	     , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE([HRS$Hotel Status].Description, ''), CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Hotel Status Name]
	     , '"' + CASE WHEN CU.[Keine Korrekturen] = 0 THEN 'Nein' ELSE 'Ja' END + '"' [Keine Korrekturen]
	FROM [HRS$Customer] CU WITH (NOLOCK)
	LEFT JOIN DCLE
	ON CU.No_ = DCLE.[Debitor Nr.]
	LEFT JOIN [HRS$Hotel Status]  WITH (NOLOCK)
	ON CU.[Hotel Status] = [HRS$Hotel Status].Status
	ORDER BY CU.No_
END

GO
