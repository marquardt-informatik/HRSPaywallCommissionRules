USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectNAVChainTemp]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectNAVChainTemp]
AS
BEGIN
       select top 10 Description from dbo.[Chain] c  
END
GO
