USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[ZHRS_MIG_LookupPRCTR]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC [MIGRATION].[ZHRS_MIG_LookupPRCTR] 1
*/
CREATE PROC [MIGRATION].[ZHRS_MIG_LookupPRCTR]
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
      , @Ending2 as varchar(max) = ') AS Q ([BUKRS],[PRCTR],[lkpPRCTR])
),U AS
(
SELECT * FROM %ALIAS% UNION SELECT * FROM %ALIAS2%
)
INSERT INTO PRCTR ([BUKRS],[PRCTR],[lkpPRCTR])
SELECT DISTINCT [BUKRS],[PRCTR],[lkpPRCTR] FROM U'

      , @Alias as varchar(max) = 'P1'
      , @Alias2 as varchar(max) = 'P2'
      , @Union as varchar(max) = 'UNION
'
      , @Union2 as varchar(max) = ','
      , @SQL as varchar(max)=''
      , @SQL2 as varchar(max)=''

SET @Template = 
'  SELECT ''%COMPANY%'' [BUKRS], VM.[Source Value] [PRCTR], CASE WHEN VM.[Destination Value] = '''' THEN ''ZZMIGR%BUKRS%'' ELSE VM.[Destination Value] END [lkpPRCTR]
    FROM [%COMPANY%$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Filter Value] = ''KOSTENTRÄGER'' AND VM.[Source Table No_] = 349 AND VM.[Export Structure Entry No_] = 0 AND VM.[Source Value] <> ''''
'
SET @Template2 = '(''%COMPANY%'','''',''ZZMIGR%BUKRS%'')'
SET @Opening = REPLACE(@Opening,'%ALIAS%',@Alias)


IF OBJECT_ID(N'tempdb..#Company') IS NOT NULL
  DROP TABLE #Company
CREATE TABLE #Company ([Company] varchar(35) COLLATE Latin1_General_CS_AS, [BUKRS] varchar(35) COLLATE Latin1_General_CS_AS)
INSERT INTO #Company ([Company],[BUKRS]) EXEC [MIGRATION].[ZHRS_MIG_LookupBUKRS]

UPDATE #Company SET [Company] = REPLACE([Company],'.','_')

SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN @Opening ELSE @Union END + REPLACE(REPLACE(@Template,'%COMPANY%',C.[Company]),'%BUKRS%',C.[BUKRS]) FROM #Company C
SELECT @SQL2 = @SQL2 + CASE WHEN @SQL2='' THEN @Ending ELSE @Union2 END + REPLACE(REPLACE(@Template2,'%COMPANY%',C.[Company]),'%BUKRS%',C.[BUKRS]) FROM #Company C
SET @SQL2 = @SQL2 + @Ending2

SET @SQL = @SQL+@SQL2
SET @SQL = REPLACE(REPLACE(@SQL,'%ALIAS%',@Alias),'%ALIAS2%',@Alias2)

IF OBJECT_ID(N'PRCTR') IS NOT NULL
  DROP TABLE PRCTR
CREATE TABLE PRCTR ([BUKRS] varchar(35) COLLATE Latin1_General_CS_AS, [PRCTR] varchar(20) COLLATE Latin1_General_CS_AS, [lkpPRCTR] varchar(20) COLLATE Latin1_General_CS_AS,PRIMARY KEY CLUSTERED ([BUKRS],[PRCTR]))

EXEC(@SQL)
IF @ReturnDataset=1
  SELECT * FROM PRCTR
END
GO
