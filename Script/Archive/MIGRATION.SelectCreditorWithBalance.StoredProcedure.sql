USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[SelectCreditorWithBalance]    Script Date: 10.04.2024 14:31:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [MIGRATION].[SelectCreditorWithBalance]
AS
BEGIN
DECLARE @SQL varchar(max)='', @SQLWith varchar(20)=''

;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('HRS','Codenet','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','TREX','Trade','Venturecube')
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN '
CREATE TABLE #V ([BUKRS] varchar(4), [Mandant] varchar(35), [Vendor No_] varchar(20), [Name] varchar(100), [Balance (LCY)] dec(38,20), [Purchaser Code] varchar(20),[Payment Method Code] varchar(20),SEPA int,[Bank Country Code] varchar(10),[Country] varchar(100), BPEXT varchar(20),ZWELS_LFB1 int, [Due Date]date, [External Document No_] varchar(100),[Posting Date] date)
' ELSE '
' END
     + ';WITH VLE AS (SELECT VLE.[Vendor No_], VLE.[External Document No_], VLE.[Due Date], VLE.[Posting Date], SUM(DVLE.[Amount (LCY)]) [Balance (LCY)] FROM DynNavHRS.dbo.['+BUKRS+'$Vendor Ledger Entry] VLE WITH (NOLOCK) JOIN DynNavHRS.dbo.['+BUKRS+'$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK) ON VLE.[Entry No_]=DVLE.[Vendor Ledger Entry No_] WHERE VLE.[Posting Date]>''1970-12-31'' AND VLE.[Posting Date] < ''2021-01-31'' AND VLE.[Open]=1 GROUP BY VLE.[Vendor No_], VLE.[Due Date], VLE.[External Document No_], VLE.[Posting Date] HAVING SUM(DVLE.[Amount (LCY)])<>0)
INSERT INTO #V
SELECT '''+lkpBUKRS+''' [BUKRS]
     , '''+BUKRS+''' [Mandant]
	 , [No_] [Vendor No_]
	 , V.[Name]
	 , COALESCE([Balance (LCY)],0)
	 , [Purchaser Code]
	 , [Payment Method Code]
	 , CASE WHEN CR.[Bank Country Code] IN (''BE'',''DE'',''EE'',''FI'',''FR'',''GR'',''IE'',''IT'',''LV'',''LT'',''LU'',''MT'',''NL'',''PT'',''SK'',''SI'',''ES'',''CY'',''AT'',''BG'',''HR'',''CZ'',''DK'',''HU'',''PL'',''RO'',''SE'',''UK'') THEN 1 ELSE 0 END [SEPA]
	 , [Bank Country Code]
	 , CR.[Name]
	 , '''+lkpBUKRS+''' + ''-'' + CAST([No_] as varchar(max)) [BPEXT]
	 , CASE WHEN [Payment Method Code]=''SEPA'' THEN 1 WHEN [Payment Method Code]=''AZV'' THEN 2 ELSE 3 END ZWELS_LFB1
	 , VLE.[Due Date]
	 , VLE.[External Document No_]
	 , VLE.[Posting Date]
  FROM DynNavHRS.dbo.['+BUKRS+'$Vendor] V WITH (NOLOCK) JOIN VLE ON V.[No_]=VLE.[Vendor No_]
  JOIN DynNavHRS.dbo.[HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = CASE WHEN V.[Country_Region Code]='''' THEN ''33'' ELSE V.[Country_Region Code] END
'
FROM Q

SET @SQL = @SQL + '
UPDATE #V SET ZWELS_LFB1=1 WHERE SEPA=1 AND ZWELS_LFB1<>1
UPDATE #V SET ZWELS_LFB1=2 WHERE [Payment Method Code]=''AZV'' AND ZWELS_LFB1<>2
SELECT * FROM #V ORDER BY BUKRS, CAST([Vendor No_] AS int)
'
EXEC(@SQL)
END
GO
