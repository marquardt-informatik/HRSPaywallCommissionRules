USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_HRS Payment$TAF Report CB_Not Posted]    Script Date: 10.04.2024 14:31:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_HRS Payment$TAF Report CB_Not Posted] AS BEGIN
	select * from [dbo].[vw_HRS Payment$TAF Report CB_No Posted Sales Invoice Line]
END
GO
