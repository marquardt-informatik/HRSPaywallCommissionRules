USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_KommissionslaufProtokollierung]    Script Date: 10.04.2024 14:31:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		DJU Dennis Juhr
-- Create date: 03.08.2018
-- Description:	Protokollierung des Kommissionslaufs
-- =============================================
CREATE PROCEDURE [dbo].[sp_KommissionslaufProtokollierung]
	@DateInserted DATETIME = '2018-09-03 00:00:00'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [Kommissionslauf - Protokoll]
	SELECT CURRENT_TIMESTAMP [Zeit], [Freigegeben], [Gebucht], [Versendet]
	FROM( SELECT COUNT(*) [Freigegeben]
		  FROM [HRS$Batch Posting Log Entry] WITH (NOLOCK)
		  WHERE [Attempts] <= 1
			AND [Inserted at] >= @DateInserted
			AND [State] = 1) [Freigegeben]
	JOIN( SELECT COUNT(*) [Gebucht]
		  FROM [HRS$Batch Posting Log Entry] WITH (NOLOCK)
		  WHERE [Attempts] <= 1
			AND [Inserted at] >= @DateInserted
			AND ([State] = 2 OR [State] = 3)) [Gebucht] ON 1=1
	JOIN( SELECT COUNT(*) [Versendet]
		  FROM [HRS$Batch Posting Log Entry] WITH (NOLOCK)
		  WHERE [Attempts] <= 1
			AND [Inserted at] >= @DateInserted
			AND [State] = 3) [Versendet] ON 1=1
END


SELECT *from [Kommissionslauf - Protokoll]
GO
