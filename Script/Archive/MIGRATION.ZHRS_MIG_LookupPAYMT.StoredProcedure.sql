USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[ZHRS_MIG_LookupPAYMT]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [MIGRATION].[ZHRS_MIG_LookupPAYMT] AS
BEGIN
  SELECT VM.[Source Value] [PAYMT]
       , VM.[Destination Value] [lkpPAYMT]
    FROM [HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 3
     AND VM.[Mapping validated by] <> ''
END
GO
