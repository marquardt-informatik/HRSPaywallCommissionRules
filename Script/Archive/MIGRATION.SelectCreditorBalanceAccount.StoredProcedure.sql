USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[SelectCreditorBalanceAccount]    Script Date: 10.04.2024 14:31:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [MIGRATION].[SelectCreditorBalanceAccount]
AS
BEGIN
DECLARE @SQL varchar(max)='', @SQLWith varchar(20)=''

IF OBJECT_ID('CreditorBalanceAccount') IS NOT NULL
    DROP TABLE CreditorBalanceAccount
CREATE TABLE CreditorBalanceAccount ([Vendor No.] varchar(25),[Account No.] varchar(25))

DECLARE @V AS TABLE ([Vendor No.] varchar(25),[Account No.] varchar(25))
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
DECLARE @V AS TABLE ([Vendor No.] varchar(25) collate Latin1_General_CI_AS primary key,[Account No.] varchar(25))
INSERT INTO CreditorBalanceAccount
' ELSE '
UNION
' END
     + '
SELECT RTRIM(CAST('''+lkpBUKRS+'-''+ CAST([No_] as varchar(20)) as varchar(25))) [Vendor No.]
     , CAST(''0000''+VM.[Destination Value] AS varchar(25)) [Account No.]
  FROM DynNavHRS.dbo.['+BUKRS+'$Vendor] V WITH (NOLOCK) 
  JOIN DynNavHRS.dbo.['+BUKRS+'$Vendor Posting Group] VP WITH (NOLOCK) ON V.[Vendor Posting Group]=VP.[Code]
  JOIN DynNavHRS.dbo.['+BUKRS+'$Value Mapping] VM WITH (NOLOCK) ON VM.[Source Table No_]=15 AND VM.[Source Value]=VP.[Payables Account]
'
FROM Q

SET @SQL = @SQL + '
SELECT * FROM CreditorBalanceAccount ORDER BY 1
'

EXEC DebugPrint @SQL


EXEC(@SQL)
END
GO
