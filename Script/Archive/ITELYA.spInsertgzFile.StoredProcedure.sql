USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [ITELYA].[spInsertgzFile]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 02.07.20
-- Description:	Filled by ItelyaInvoice.dtsx
-- =============================================
CREATE PROCEDURE [ITELYA].[spInsertgzFile]
	@fileName varchar(250)
AS
BEGIN
  IF NOT EXISTS(SELECT * FROM ITELYA.gzFile WHERE [fileName] = @fileName)
    INSERT INTO ITELYA.gzFile ([fileName],[imported]) VALUES (@fileName,0)
END
GO
