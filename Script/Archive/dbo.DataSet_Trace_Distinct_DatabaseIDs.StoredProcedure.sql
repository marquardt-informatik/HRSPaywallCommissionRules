USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[DataSet_Trace_Distinct_DatabaseIDs]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DataSet_Trace_Distinct_DatabaseIDs] AS 
SELECT '<All>' AS DatabaseID
UNION ALL
SELECT DISTINCT CONVERT (varchar(30), DatabaseID) FROM DistinctBatches
GO
