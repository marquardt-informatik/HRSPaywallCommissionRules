USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportCurrencyExchRate]    Script Date: 10.04.2024 14:31:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Dennis Juhr (DJU)
-- Create date: 23.01.2018
-- Description:	GDPdU Export - Währungswechselkursee
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportCurrencyExchRate]
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

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CER.[Currency Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Währungscode]
		 , CONVERT(varchar(10), CER.[Starting Date], 104) [Startdatum]
		 , REPLACE(CAST(CAST(CER.[Exchange Rate Amount]	AS DECIMAL(38,2)) AS varchar(40)), '.', ',') [Wechselkursbetrag]
	FROM [HRS$Currency Exchange Rate] CER WITH (NOLOCK)
	WHERE CER.[Starting Date] between @StartDateTime AND @EndDateTime

END
GO
