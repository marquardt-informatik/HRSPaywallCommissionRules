USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[DataSet_Trace_Distinct_DatabaseNames]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DataSet_Trace_Distinct_DatabaseNames] AS 
SELECT '<All>' AS DatabaseName
UNION ALL
SELECT DISTINCT DatabaseName FROM DistinctBatches
GO
