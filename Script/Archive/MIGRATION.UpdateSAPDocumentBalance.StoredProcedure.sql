USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[UpdateSAPDocumentBalance]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[UpdateSAPDocumentBalance]
AS
BEGIN
DECLARE @SQL varchar(max) ='', @SQL2 varchar(max) =''
CREATE TABLE #R ([SAP Company] varchar(4) COLLATE Latin1_General_CS_AS, [Document No_] varchar(20) COLLATE Latin1_General_CS_AS, [Account No_] varchar(10) COLLATE Latin1_General_CS_AS, [SAP Balance] dec(38,20), [NAV Balance] dec(38,20), [Difference] tinyint, [Error] dec(38,20), [Posting Date] date, PRIMARY KEY ([SAP Company],[Document No_],[Account No_]))
;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('Codenet','HRS','HRS Product Solutions GmbH','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','Trade','Venturecube')
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL = @SQL + CASE WHEN @SQL<>'' THEN 'UNION' ELSE ';WITH SAP AS
(' END
+'
   SELECT DD.[SAP Company]
        , DD.[Document No_]
        , CASE WHEN COALESCE(VM_GA.[Source Value],'''')=''178702'' THEN ''178700'' 
               WHEN COALESCE(VM_GA.[Source Value],'''')=''178711'' THEN ''178701'' 
               ELSE COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(VM_GA.[Source Value],VP.[Payables Account]),CP.[Receivables Account]),CASE WHEN DD.[Document Type] IN (''KR'',''AA'') THEN FA.[Acquisition Cost Account] ELSE FA.[Accum_ Depreciation Account] END),VM_PG.[Source Value]),RIGHT(DD.[Account No_],6)) END [Account No_]
        , SUM(DD.[Amount (LCY)]) [SAP Amount]
        , MAX([Posting Date]) [Posting Date]
     FROM [SAP Document Details] DD WITH (NOLOCK)
LEFT JOIN ['+[BUKRS]+'$Vendor] V WITH (NOLOCK) ON REPLACE(DD.[Account No_],DD.[SAP Company]+''-'','''')=CAST(V.[No_] AS varchar(20)) AND DD.[Account Type] IN (2,5)
LEFT JOIN ['+[BUKRS]+'$Vendor Posting Group] VP WITH (NOLOCK) ON VP.[Code]=V.[Vendor Posting Group]
LEFT JOIN ['+[BUKRS]+'$Value Mapping] VM_GA WITH (NOLOCK) 
       ON ((RIGHT(''0000000000''+RTRIM(VM_GA.[Destination Value]),10)=DD.[Account No_] AND VM_GA.[Source Table No_]=15 AND DD.[Account Type] IN (0,3))
       OR (COALESCE(DD.[AKONT],'''')<>'''' AND (RIGHT(''0000000000''+RTRIM(VM_GA.[Destination Value]),10)=DD.[AKONT]  OR VM_GA.[Destination Value]=DD.[AKONT]) AND VM_GA.[Source Table No_]=15 AND DD.[Account Type] IN (2,5)))
      AND VM_GA.[Export Structure Entry No_]=0
LEFT JOIN ['+[BUKRS]+'$Fixed Asset] F WITH (NOLOCK) ON (DD.[Account No_]=CAST(F.[No_] AS varchar(20)) OR REPLACE(DD.[Account No_],DD.[SAP Company]+''-'','''')=CAST(F.[No_] AS varchar(20))) AND DD.[Account Type] IN (4)
LEFT JOIN ['+[BUKRS]+'$FA Posting Group] FA WITH (NOLOCK) ON FA.[Code]=F.[FA Posting Group]
LEFT JOIN ['+[BUKRS]+'$Value Mapping] VM_FA WITH (NOLOCK) 
       ON (RIGHT(''0000000000''+RTRIM(VM_FA.[Destination Value]),10)=DD.[Account No_] AND VM_FA.[Source Table No_]=15 AND DD.[Account Type] IN (4))
LEFT JOIN [HRS$Value Mapping] VM_PG WITH (NOLOCK)  
       ON ''H''+RIGHT(''0000000000''+RTRIM(VM_PG.[Destination Value]),6)=DD.[Posting Group] AND VM_PG.[Source Table No_] = 15 
LEFT JOIN [HRS$Customer] CU WITH (NOLOCK) ON REPLACE(DD.[Account No_],DD.[SAP Company]+''-'','''')=CAST(CU.[No_] AS varchar(20)) AND DD.[Account Type] IN (2,5)
LEFT JOIN [HRS$Customer Posting Group] CP WITH (NOLOCK) ON CP.[Code]=CU.[Customer Posting Group]
    WHERE DD.[SAP Company]='''+[lkpBUKRS]+'''
 GROUP BY DD.[SAP Company]
        , DD.[Document No_]
        , CASE WHEN COALESCE(VM_GA.[Source Value],'''')=''178702'' THEN ''178700'' 
               WHEN COALESCE(VM_GA.[Source Value],'''')=''178711'' THEN ''178701'' 
               ELSE COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(VM_GA.[Source Value],VP.[Payables Account]),CP.[Receivables Account]),CASE WHEN DD.[Document Type] IN (''KR'',''AA'') THEN FA.[Acquisition Cost Account] ELSE FA.[Accum_ Depreciation Account] END),VM_PG.[Source Value]),RIGHT(DD.[Account No_],6)) END 
'
  FROM Q

;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('Codenet','HRS','HRS Product Solutions GmbH','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','Trade','Venturecube')
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL2 = @SQL2 + CASE WHEN @SQL2<>'' THEN 'UNION' ELSE '), NAV AS
(' END 
+ '
   SELECT '''+[lkpBUKRS]+''' [SAP Company]
        , [Document No_]
        , [G_L Account No_] [Account No_]
        , SUM(GL.[Amount]) [NAV Amount]
        , MAX([Posting Date]) [Posting Date]
     FROM ['+[BUKRS]+'$G_L Entry] GL WITH (NOLOCK)
    WHERE [Source Code]=''SAP''
      AND [Reversed]=0
 GROUP BY [Document No_]
        , [G_L Account No_]
'
  FROM Q

SELECT @SQL=@SQL+@SQL2+')
INSERT INTO #R
SELECT COALESCE(SAP.[SAP Company],NAV.[SAP Company])
     , COALESCE(SAP.[Document No_],NAV.[Document No_])
     , COALESCE(SAP.[Account No_],NAV.[Account No_])
     , COALESCE(SAP.[SAP Amount],0)
     , COALESCE(NAV.[NAV Amount],0), CASE WHEN COALESCE([NAV Amount],0)<>COALESCE([SAP Amount],0) THEN 1 ELSE 0 END, COALESCE(SAP.[SAP Amount],0)-COALESCE(NAV.[NAV Amount],0)
     , COALESCE(SAP.[Posting Date],NAV.[Posting Date])
  FROM SAP FULL OUTER JOIN NAV ON SAP.[SAP Company]=NAV.[SAP Company] AND SAP.[Account No_]=NAV.[Account No_] AND SAP.[Document No_]=NAV.[Document No_]

 --WHERE SAP.[Document No_]=''20210001000276'' AND SAP.[SAP Company]=''2000''

SELECT * FROM #R

--DELETE FROM S FROM [SAP Document Balance] S JOIN [SAP Documents] SD ON S.[SAP Company]=SD.[SAP Company] AND S.[Document No_]=SD.[Document No_] WHERE SD.[Posted]=1 AND SD.[Last Error]<>''''

UPDATE S SET 
       S.[Difference]=R.[Difference]
     , S.[SAP Balance]=R.[SAP Balance]
     , S.[NAV Balance]=R.[NAV Balance]
     , S.[Error]=R.[Error]
     , S.[Posting Date]=R.[Posting Date]
  FROM [SAP Document Balance] S
  JOIN #R R ON R.[SAP Company]=S.[SAP Company] AND R.[Document No_]=S.[Document No_] AND R.[Account No_]=S.[Account No_]
 WHERE S.[Difference]<>R.[Difference]
    OR S.[SAP Balance]<>R.[SAP Balance]
    OR S.[NAV Balance]<>R.[NAV Balance]
    OR S.[Error]<>R.[Error]
    OR S.[Posting Date]<>R.[Posting Date]

INSERT INTO [SAP Document Balance] ([SAP Company],[Document No_],[Account No_],[SAP Balance],[NAV Balance],[Difference],[Error],[Posting Date])
     SELECT R.[SAP Company],R.[Document No_],R.[Account No_],R.[SAP Balance],R.[NAV Balance],R.[Difference],R.[Error],R.[Posting Date]
       FROM #R R
  LEFT JOIN [SAP Document Balance] S ON R.[SAP Company]=S.[SAP Company] AND R.[Document No_]=S.[Document No_] AND R.[Account No_]=S.[Account No_]
      WHERE S.[SAP Company] IS NULL

DELETE FROM S
       FROM [SAP Document Balance] S
  LEFT JOIN #R R ON R.[SAP Company]=S.[SAP Company] AND R.[Document No_]=S.[Document No_] AND R.[Account No_]=S.[Account No_]
      WHERE R.[SAP Company] IS NULL
'

EXEC DebugPrint @SQL
EXEC(@SQL)



END
GO
