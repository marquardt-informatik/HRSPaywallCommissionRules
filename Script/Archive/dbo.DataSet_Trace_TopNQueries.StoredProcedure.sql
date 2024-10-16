USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[DataSet_Trace_TopNQueries]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DataSet_Trace_TopNQueries] @StartTime datetime = '19000101', @EndTime datetime = '29990101', 
  @ApplicationName nvarchar(256) = NULL, @DatabaseName nvarchar(256) = NULL, @DatabaseID varchar(30) = NULL, @ServerName nvarchar(256) = NULL 
AS 
--DECLARE @StartTime datetime
--DECLARE @EndTime datetime
DECLARE @IntervalSec int
IF @StartTime IS NULL OR @StartTime = '19000101' SELECT @StartTime = MIN (EndTime) FROM BatchExecs (NOLOCK) 
IF @EndTime IS NULL OR @EndTime = '29990101' SELECT @EndTime = MAX (EndTime) FROM BatchExecs (NOLOCK) 
-- RS will truncate the milliseconds portion of a date, meaning that we will inadvertently filter out the final second of trace data
SET @EndTime = DATEADD (s, 1, @EndTime)
SET @IntervalSec = DATEDIFF (s, @StartTime, @EndTime)

SELECT b.ApplicationName, b.DatabaseName, 
  REPLACE (REPLACE (SUBSTRING (b.OrigText, 1, 300), CHAR(10), ' '), CHAR(13), ' ') + CASE WHEN LEN (SUBSTRING (b.OrigText, 1, 400)) >= 300 THEN '...' ELSE '' END AS Query, 
  t.* 
FROM ( 
  SELECT s.[Hash], 
    COUNT(*) AS Executions, COUNT_BIG(*) * 60 / @IntervalSec AS avg_exec_per_min, 
    SUM (s.CPU) AS total_cpu, SUM (s.CPU)/@IntervalSec AS avg_cpu_per_sec, MAX (s.CPU) AS max_cpu, 
    SUM (s.Reads) AS total_reads, SUM (s.Reads)/@IntervalSec AS avg_reads_per_sec, MAX (s.Reads) AS max_reads, 
    SUM (s.Writes) AS total_writes, SUM (s.Writes)/@IntervalSec AS avg_writes_per_sec, MAX (s.Writes) AS max_writes, 
    SUM (s.Duration/1000) AS total_duration, SUM (s.Duration/1000)/@IntervalSec AS avg_duration_per_sec, MAX (s.Duration/1000) AS max_duration,  
     ROW_NUMBER() OVER (ORDER BY SUM (s.CPU) DESC) AS RN_CPU, 
     ROW_NUMBER() OVER (ORDER BY SUM (s.Reads) DESC) AS RN_Reads, 
     ROW_NUMBER() OVER (ORDER BY SUM (s.Writes) DESC) AS RN_Writes, 
     ROW_NUMBER() OVER (ORDER BY SUM (s.Duration/1000) DESC) AS RN_Duration 
  FROM BatchExecs (NOLOCK) s 
  INNER JOIN DistinctBatches b ON b.[Hash] = s.[Hash]
    AND (@ApplicationName = '<All>' OR @ApplicationName = '' OR @ApplicationName IS NULL OR b.ApplicationName = @ApplicationName)
    AND (@DatabaseName = '<All>' OR @DatabaseName = '' OR @DatabaseName IS NULL OR b.DatabaseName = @DatabaseName)
    AND (@DatabaseID = '<All>' OR @DatabaseID = '' OR @DatabaseID IS NULL OR CONVERT (varchar(30), b.DatabaseID) = @DatabaseID)
    AND (@ServerName = '<All>' OR @ServerName = '' OR @ServerName IS NULL OR b.ServerName = @ServerName)
  WHERE s.EndTime BETWEEN @StartTime AND @EndTime
  GROUP BY s.[Hash]
) t
INNER JOIN DistinctBatches (NOLOCK) b ON b.[Hash] = t.[Hash]
WHERE RN_CPU <= 20
  OR RN_Reads <= 20
  OR RN_Writes <= 20
  OR RN_Duration <= 20
ORDER BY RN_CPU DESC
GO
