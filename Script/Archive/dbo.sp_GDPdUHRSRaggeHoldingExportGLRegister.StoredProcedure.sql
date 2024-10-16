USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUHRSRaggeHoldingExportGLRegister]    Script Date: 10.04.2024 14:31:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Dennis Juhr (DJU)
-- Create date: 23.01.2018
-- Description:	GDPdU Export - Fibujournale
-- =============================================
-- 16.10.18  HRS001	 SAL  [Source Code] (Herkunfscode) auskommentiert
--
CREATE PROCEDURE [dbo].[sp_GDPdUHRSRaggeHoldingExportGLRegister]
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

	
	SELECT @MinEntryNo = MIN([Entry No_])
		 , @MaxEntryNo = MAX([Entry No_])
	FROM [HRS Ragge Holding$G_L Entry] WITH (NOLOCK)
	WHERE [Posting Date] BETWEEN @StartDateTime AND @EndDateTime

	PRINT '@MinEntryNo=' + CAST(@MinEntryNo AS VARCHAR)
    PRINT '@MaxEntryNo=' + CAST(@MaxEntryNo AS VARCHAR)

	SELECT GLR.[From Entry No_] [Von Lfd. Nr.]
	     , GLR.[To Entry No_] [Bis Lfd. Nr.]
		 , CONVERT(varchar(10), GLR.[Creation Date], 104) [Errichtungsdatum]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLR.[User ID], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Benutzer-ID]
		-- , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GLR.[Source Code], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Herkunftscode]
	FROM [HRS Ragge Holding$G_L Register] GLR WITH (NOLOCK)
	WHERE (GLR.[From Entry No_] BETWEEN @MinEntryNo AND @MaxEntryNo)
	   OR (GLR.[To Entry No_] BETWEEN @MinEntryNo AND @MaxEntryNo)
END
GO
