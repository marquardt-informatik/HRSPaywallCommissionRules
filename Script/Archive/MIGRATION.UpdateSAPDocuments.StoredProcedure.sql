USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[UpdateSAPDocuments]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[UpdateSAPDocuments] AS BEGIN
SEt NOCOUNT ON

IF OBJECT_ID(N'tempdb..#SD') IS NOT NULL 
  DROP TABLE #SD
CREATE TABLE #SD(
	[timestamp] [timestamp] NOT NULL,
	[Company] [varchar](30) COLLATE Latin1_General_CS_AS NOT NULL ,
	[Document No_] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,
	[Posting Date] [datetime] NOT NULL,
	[Document Type] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,
	[Description] [varchar](100) COLLATE Latin1_General_CS_AS NOT NULL,
	[Comment] [varchar](100) COLLATE Latin1_General_CS_AS NOT NULL,
	[Cost Center] [varchar](10) COLLATE Latin1_General_CS_AS NOT NULL,
	[VAT Prod_ Posting Group] [varchar](2) COLLATE Latin1_General_CS_AS NOT NULL,
	[Posted at] [datetime] NOT NULL,
	[Posted] [tinyint] NOT NULL,
	[Entry No_] [int] NOT NULL,
	[SAP Company] [varchar](4) COLLATE Latin1_General_CS_AS NOT NULL,
	[Last Error] [varchar](250) COLLATE Latin1_General_CS_AS NOT NULL,
	[Error Class] [varchar](50) COLLATE Latin1_General_CS_AS NOT NULL,
	[Last Import] [datetime] NOT NULL,
	[Last Entry No_] [int] NOT NULL,
	[G_L Description] [varchar](250) COLLATE Latin1_General_CS_AS NOT NULL,
	[Balance Error] [tinyint] NOT NULL,
	[To be corrected] [tinyint] NOT NULL,
    PRIMARY KEY CLUSTERED ([Company] ASC,[Document No_] ASC)
)
ALTER TABLE #SD ADD  CONSTRAINT [SD_To be corrected6]  DEFAULT ((0)) FOR [To be corrected]

DECLARE @SQL varchar(max) =''
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
CREATE TABLE #ImportLog (BUKRS varchar(4) COLLATE Latin1_General_CS_AS, [Entry No_] int, [Status] int, [Start Date_Time] datetime,[Document No_] varchar(20) COLLATE Latin1_General_CS_AS, [Error Text] varchar(250), [Error Class] varchar(50),PRIMARY KEY CLUSTERED (BUKRS,[Document No_]))
INSERT INTO #ImportLog
EXEC [MIGRATION].[ShowJobQueEntry4SAPDocumentImport] 

--TRUNCATE TABLE [SAP Documents]
;WITH SD AS
(
  SELECT [SAP Company] [BUKRS]
       , SUBSTRING([Document No_],1,14) [Document No_]
       , [Document Type]
       , MAX([Description]) [Description]
       , MAX([Posting Date]) [Posting Date]
	   , MAX([Shortcut Dimension 1 Code]) [Cost Center]
       , MAX([VAT Prod_ Posting Group]) [VAT Prod. Posting Group]
	   , MAX(CASE WHEN [Line No_]=1 THEN [Entry No_] ELSE 0 END) [Last Entry No_]
       , MIN(CASE WHEN [Document Type]=''AA'' AND [AWKEY]='''' THEN 0 WHEN [Document Type]=''AA'' AND [AWKEY]<>'''' AND [Posting Group]<>'''' THEN 1 ELSE 0 END)  [Posted]
    FROM [SAP Document Details]
   --WHERE SUBSTRING([Document No_],1,4)>''2020''
   --  AND NOT SUBSTRING([Document No_],5,14) IN (''20210001000000'',''20210001000001'')
GROUP BY [SAP Company]
       , SUBSTRING([Document No_],1,14)
	   , [Document Type]
), ND AS
(
' ELSE '
UNION
' END
     + 'SELECT '''+[lkpBUKRS]+''' [BUKRS], [Document No_], MAX(GE.[Description]) [Description], MAX(GE.[Entry No_]) [Entry No_] FROM ['+BUKRS+'$G_L Entry] GE WITH (NOLOCK) WHERE GE.[Source Code]=''SAP'' AND [Reversed]=0 AND [Posting Date]>''2019-12-31'' GROUP BY [Document No_]
UNION
SELECT '''+[lkpBUKRS]+''' [BUKRS], [No_] [Document No_],'''',0 FROM ['+BUKRS+'$Purch_ Inv_ Header] WHERE [Purchaser Code]=''SAP'' AND NOT [No_] IN (SELECT [Document No_] FROM ['+BUKRS+'$G_L Entry] GE WITH (NOLOCK) WHERE GE.[Source Code]=''SAP'')'
FROM Q

SET @SQL = @SQL + '
), BK AS
(
  SELECT VM.[Source Value] Company
       , VM.[Destination Value] [BUKRS]
    FROM [HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''''
)
INSERT INTO #SD ([Company],[SAP Company],[Posting Date],[Document No_],[Document Type],[Description],[Comment],[Cost Center],[VAT Prod_ Posting Group],[Posted],[Posted at],[Entry No_],[Last Error],[Error Class],[Last Import],[Last Entry No_],[G_L Description],[Balance Error])
   SELECT BK.[Company]
        , BK.[BUKRS]
        , SD.[Posting Date]
        , SD.[Document No_]
        , SD.[Document Type]
        , SD.[Description]
        , ''''
		, SD.[Cost Center]
        , SD.[VAT Prod. Posting Group]
		, CASE WHEN SD.[Posted]=1 THEN 1 WHEN ND.[Document No_] IS NULL THEN 0 ELSE 1 END [Posted]
		, ''1753-01-01''
		, COALESCE(ND.[Entry No_],0)
		, CASE WHEN ND.[Document No_] IS NULL THEN COALESCE(IL.[Error Text],'''') ELSE '''' END
		, CASE WHEN ND.[Document No_] IS NULL THEN COALESCE(IL.[Error Class],'''') ELSE '''' END
		, COALESCE(IL.[Start Date_Time],''1753-01-01'')
		, SD.[Last Entry No_]
		, COALESCE(ND.[Description],'''')
        , 0
     FROM SD
     JOIN BK ON BK.BUKRS=SD.BUKRS
LEFT JOIN ND ON ND.BUKRS=SD.BUKRS AND ND.[Document No_]=SD.[Document No_]
LEFT JOIN #ImportLog IL ON IL.BUKRS=SD.BUKRS AND IL.[Document No_]=SD.[Document No_]
 --   WHERE CASE WHEN ND.[Document No_] IS NULL THEN COALESCE(IL.[Error Text],'''') ELSE '''' END NOT IN 
	--      (
	--	    ''Import GLLines failed : G/L Account No. ''''0000900000'''' does not exist.''
	--	  )
 --ORDER BY 1,3
'
EXEC DebugPrint @SQL
EXEC(@SQL)

 --UPDATE #SD SET [Comment]='' WHERE [Posted]=1 AND [Last Error]<>''''

DECLARE @SQL900000 varchar(max)=''
SELECT @SQL900000 = @SQL900000 +
'
 UPDATE #SD SET [Posted]=1, [Comment]=''Falschbuchungen auf SAP Kto 900000 und 900003'' WHERE [SAP Company]='''+[SAP Company]+''' AND [Document No_] IN('''+[Document No_]+''') -- 900000/900003'
  FROM [SAP Document Details] GL 
WHERE [Account No_] IN ('0000900000','0000900003') OR [Bal_ Account No_] IN ('0000900000','0000900003')

EXEC DebugPrint @SQL900000
EXEC(@SQL900000)

UPDATE SD SET 
       SD.[Posted]=#SD.[Posted]
     , SD.[Posted at]=#SD.[Posted at]
     , SD.[Last Error]=#SD.[Last Error]
     , SD.[Comment]=CASE WHEN #SD.[Comment]<>'' THEN #SD.[Comment] ELSE SD.[Comment] END
     , SD.[Error Class]=#SD.[Error Class]
     , SD.[Entry No_]=#SD.[Entry No_]
     , SD.[Last Entry No_]=#SD.[Last Entry No_]
     , SD.[Last Import]=#SD.[Last Import]
  FROM [SAP Documents] SD 
  JOIN #SD 
    ON #SD.Company=SD.Company
   AND #SD.[Document No_]=SD.[Document No_]
 WHERE SD.[Posted]<>#SD.[Posted]
    OR SD.[Posted at]<>#SD.[Posted at]
    OR SD.[Last Error]<>#SD.[Last Error]
    OR SD.[Error Class]<>#SD.[Error Class]
    OR SD.[Entry No_]<>#SD.[Entry No_]
    OR SD.[Last Entry No_]<>#SD.[Last Entry No_]
    OR SD.[Last Import]<>#SD.[Last Import]

EXEC MIGRATION.UpdatePostedColumn

INSERT INTO [dbo].[SAP Documents] ([Company],[Document No_],[Posting Date],[Document Type],[Description],[Cost Center],[VAT Prod_ Posting Group],[Posted at],[Posted],[Entry No_],[SAP Company],[Last Error],[Error Class],[Last Import],[Last Entry No_],[G_L Description],[Balance Error],[To be corrected])
SELECT [Company],[Document No_],[Posting Date],[Document Type],[Description],[Cost Center],[VAT Prod_ Posting Group],[Posted at],[Posted],[Entry No_],[SAP Company],[Last Error],[Error Class],[Last Import],[Last Entry No_],[G_L Description],[Balance Error],0[To be corrected]
  FROM #SD
 WHERE NOT [Company]+[Document No_] IN (SELECT [Company]+[Document No_] FROM [SAP Documents])

EXEC MIGRATION.UpdateSAPDocumentBalance

;WITH D AS (SELECT [SAP Company],[Document No_], MAX([Difference]) [Difference] FROM [SAP Document Balance] GROUP BY [SAP Company],[Document No_])
UPDATE S SET S.[Balance Error]=CASE WHEN S.[Approved]=1 THEN 0 ELSE D.[Difference] END
  FROM [SAP Documents] S
  JOIN D ON S.[SAP Company]=D.[SAP Company] AND S.[Document No_]=D.[Document No_]
 WHERE S.[Balance Error]<>CASE WHEN S.[Approved]=1 THEN 0 ELSE D.[Difference] END

UPDATE S SET S.[To be corrected]=0
  FROM [SAP Documents] S
 WHERE S.[To be corrected]=1 AND S.[Posted]=1

UPDATE SB SET SB.[NAV Balance]=SB.[SAP Balance], SB.[Difference]=0, SB.[Error]=0
  FROM [SAP Document Balance] SB
  JOIN [SAP Documents] SD ON SD.[SAP Company]=SB.[SAP Company] AND SD.[Document No_]=SB.[Document No_]
 WHERE SD.[Approved]=1
   AND SB.[Difference]=1

UPDATE [SAP Documents] SET [Approved at]='1753-01-01' WHERE [Approved by]=''

DROP TABLE #SD 
EXEC MIGRATION.UpdatePostedColumn
END
GO
