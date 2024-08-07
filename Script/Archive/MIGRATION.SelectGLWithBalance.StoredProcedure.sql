USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[SelectGLWithBalance]    Script Date: 10.04.2024 14:31:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [MIGRATION].[SelectGLWithBalance]
AS
BEGIN
DECLARE @SQL varchar(max)='', @SQLWith varchar(20)=''
DECLARE @DateFrom date, @DateTo date, @Yesterday date

SET @Yesterday = GETDATE()
SET @DateFrom = CAST(CONVERT(varchar(4),GETDATE(),120)+'-01-01' AS date)
SET @DateTo = DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE())

PRINT @Yesterday
PRINT @DateFrom
PRINT @DateTo

;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('HRS','Codenet','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','Trade','Venturecube')
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN '
CREATE TABLE #V ([BUKRS] varchar(4), [Mandant] varchar(35), [Account No_] varchar(20), [Derscription] varchar(100), [Balance (LCY)] dec(38,20), [GuV/Bilanz] varchar(6))
' ELSE '
' END
     + ';WITH GLE AS (
  SELECT GLE.[G_L Account No_], SUM(GLE.[Amount]) [Balance] FROM DynNavHRS.dbo.['+BUKRS+'$G_L Entry] GLE WITH (NOLOCK) JOIN DynNavHRS.dbo.['+BUKRS+'$G_L Account] V WITH (NOLOCK) ON V.[No_]=GLE.[G_L Account No_] WHERE GLE.[Posting Date] <= '''+CONVERT(varchar(10),@DateTo,120)+''' AND V.[Income_Balance]=1 AND GLE.[Posted at]<='''+CONVERT(varchar(10),@Yesterday,120)+''' GROUP BY GLE.[G_L Account No_] HAVING SUM(GLE.[Amount])<>0
  UNION
  SELECT GLE.[G_L Account No_], SUM(GLE.[Amount]) [Balance] FROM DynNavHRS.dbo.['+BUKRS+'$G_L Entry] GLE WITH (NOLOCK) JOIN DynNavHRS.dbo.['+BUKRS+'$G_L Account] V WITH (NOLOCK) ON V.[No_]=GLE.[G_L Account No_] WHERE GLE.[Posting Date] BETWEEN '''+CONVERT(varchar(10),@DateFrom,120)+''' AND '''+CONVERT(varchar(10),@DateTo,120)+''' AND V.[Income_Balance]=0 GROUP BY GLE.[G_L Account No_] HAVING SUM(GLE.[Amount])<>0
)
INSERT INTO #V
SELECT '''+lkpBUKRS+''' [BUKRS]
     , '''+BUKRS+''' [Mandant]
	 , [No_] [Account No_]
	 , [Name]
	 , [Balance]
	 , CASE WHEN V.[Income_Balance]=0 THEN ''GuV'' ELSE ''Bilanz'' END
  FROM DynNavHRS.dbo.['+BUKRS+'$G_L Account] V WITH (NOLOCK) JOIN GLE ON V.[No_]=GLE.[G_L Account No_]
'
FROM Q

SET @SQL = @SQL + '
SELECT * FROM #V
'
EXEC DebugPrint @SQL
EXEC(@SQL)
END
GO
