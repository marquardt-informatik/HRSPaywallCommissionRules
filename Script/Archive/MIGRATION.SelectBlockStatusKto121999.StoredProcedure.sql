USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[SelectBlockStatusKto121999]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[SelectBlockStatusKto121999]
AS
BEGIN
DECLARE @SQL varchar(max)=''
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
SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN '' ELSE '
UNION
' END
     + 'SELECT '''+lkpBUKRS+''' [BUKRS], '''+BUKRS+''' [Company], [No_], [Name], CASE WHEN [Blocked from]=''1753-01-01'' THEN null ELSE [Blocked from] END [Blocked from], [Blocked] FROM ['+BUKRS+'$G_L Account] GA WITH (NOLOCK) WHERE [No_]=''121999'''
FROM Q
EXEC DebugPrint @SQL
EXEC(@SQL)
END
GO
