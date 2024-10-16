USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[ZHRS_MIG_BP_FLVN01_LookupCOUNTRY]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[ZHRS_MIG_BP_FLVN01_LookupCOUNTRY] AS
BEGIN
  SELECT VM.[Source Value] [COUNTRY]
       , VM.[Destination Value] [lkpCOUNTRY]
    FROM [HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 9
     AND VM.[Mapping validated by] <> ''
UNION SELECT '', 'DE'
UNION SELECT '0', 'DE'
END
GO
