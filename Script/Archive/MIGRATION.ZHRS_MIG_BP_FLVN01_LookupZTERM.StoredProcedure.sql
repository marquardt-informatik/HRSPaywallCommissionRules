USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[ZHRS_MIG_BP_FLVN01_LookupZTERM]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [MIGRATION].[ZHRS_MIG_BP_FLVN01_LookupZTERM] AS
BEGIN
  SELECT VM.[Source Value] [ZTERM]
       , VM.[Destination Value] [lkpZTERM]
    FROM [HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 3
     --AND VM.[Mapping validated by] <> ''
UNION SELECT '',''
END
GO
