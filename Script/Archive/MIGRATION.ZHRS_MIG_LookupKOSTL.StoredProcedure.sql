USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[ZHRS_MIG_LookupKOSTL]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC [MIGRATION].[ZHRS_MIG_LookupKOSTL] 0
*/
CREATE PROC [MIGRATION].[ZHRS_MIG_LookupKOSTL] 
(
  @ReturnDataset tinyint = 1
)

AS
BEGIN
DECLARE @Template as varchar(max)
      , @Template2 as varchar(max)
      , @Opening as varchar(max) = ';WITH %ALIAS% AS 
('
      , @Ending as varchar(max) = '), %ALIAS2% AS (SELECT Q.* FROM (VALUES'
      , @Ending2 as varchar(max) = ') AS Q ([BUKRS],[KOSTL],[lkpKOSTL],[Reverse])
),U AS
(
SELECT * FROM %ALIAS% UNION SELECT * FROM %ALIAS2%
)
INSERT INTO KOSTL ([BUKRS],[KOSTL],[lkpKOSTL],[Reverse])
SELECT [BUKRS],[KOSTL],[lkpKOSTL],MAX([Reverse]) [Reverse] FROM U GROUP BY [BUKRS],[KOSTL],[lkpKOSTL]'
      , @Alias as varchar(max) = 'KO1'
      , @Alias2 as varchar(max) = 'KO2'
      , @Union as varchar(max) = 'UNION
'
      , @Union2 as varchar(max) = ','
      , @SQL as varchar(max)=''
      , @SQL2 as varchar(max)=''

SET @Template = 
'  SELECT ''%COMPANY%'' [BUKRS], VM.[Source Value] [KOSTL], VM.[Destination Value] [lkpKOSTL], CASE WHEN VM.[Export Structure Entry No_]<>0 THEN 1 ELSE 0 END [Reverse]
    FROM [%COMPANY%$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Filter Value] = ''KOSTENSTELLE'' AND VM.[Source Table No_] = 349 AND VM.[Export Structure Entry No_] IN (0,23) AND VM.[Source Value] <> '''' AND VM.[Mapping validated by] <> ''''
'
SET @Template2 = '(''%COMPANY%'','''',''ZZ9000%BUKRS%'',0)'
SET @Opening = REPLACE(@Opening,'%ALIAS%',@Alias)


IF OBJECT_ID(N'tempdb..#Company') IS NOT NULL
  DROP TABLE #Company
CREATE TABLE #Company ([Company] varchar(35) COLLATE Latin1_General_CS_AS, [BUKRS] varchar(35) COLLATE Latin1_General_CS_AS)
INSERT INTO #Company ([Company],[BUKRS]) EXEC [MIGRATION].[ZHRS_MIG_LookupBUKRS]

UPDATE #Company SET [Company] = REPLACE([Company],'.','_')

SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN @Opening ELSE @Union END + REPLACE(@Template,'%COMPANY%',C.[Company]) FROM #Company C
SELECT @SQL2 = @SQL2 + CASE WHEN @SQL2='' THEN @Ending ELSE @Union2 END + REPLACE(REPLACE(@Template2,'%COMPANY%',C.[Company]),'%BUKRS%',C.[BUKRS]) FROM #Company C
SET @SQL2 = @SQL2 + @Ending2

SET @SQL = @SQL+@SQL2
SET @SQL = REPLACE(REPLACE(@SQL,'%ALIAS%',@Alias),'%ALIAS2%',@Alias2)


IF @ReturnDataset=1
BEGIN
  SET @SQL=REPLACE(@SQL,'INSERT INTO ','--INSERT INTO ')
  EXEC(@SQL)
END
IF @ReturnDataset<>1
BEGIN
  IF OBJECT_ID(N'KOSTL') IS NOT NULL
    DROP TABLE KOSTL
  CREATE TABLE KOSTL ([BUKRS] varchar(35) COLLATE Latin1_General_CS_AS, [KOSTL] varchar(20) COLLATE Latin1_General_CS_AS, [lkpKOSTL] varchar(20) COLLATE Latin1_General_CS_AS, [Reverse] tinyint,PRIMARY KEY CLUSTERED ([BUKRS],[KOSTL]))
  
  EXEC(@SQL)
  ;WITH KO AS
  (
    SELECT BUKRS,lkpKOSTL,COUNT(1) CountKOSTL
      FROM KOSTL K
  GROUP BY BUKRS,lkpKOSTL
  HAVING COUNT(1)=1
  )
  UPDATE K SET K.[Reverse]=1
    FROM KOSTL K
    JOIN KO ON KO.lkpKOSTL=K.lkpKOSTL
   WHERE K.[Reverse]=9
END

END
GO
