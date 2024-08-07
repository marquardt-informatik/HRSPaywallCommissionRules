USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[ZHRS_MIG_LookupWAERS]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROC [MIGRATION].[ZHRS_MIG_LookupWAERS] AS
BEGIN
  SELECT VM.[Source Value] [WAERS]
       , VM.[Destination Value] [lkpWAERS]
    FROM [HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 4
     AND VM.[Mapping validated by] <> ''
END
GO
