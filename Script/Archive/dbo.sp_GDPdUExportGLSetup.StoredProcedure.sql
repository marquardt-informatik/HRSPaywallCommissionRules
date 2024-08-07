USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportGLSetup]    Script Date: 10.04.2024 14:31:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Fibu Einrichtung
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportGLSetup]
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
	DECLARE @MinEntryNo int, @MaxEntryNo int;

	SELECT '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([LCY Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Mandantenwährungscode]
	FROM [HRS$General Ledger Setup] WITH (NOLOCK)
END
GO
