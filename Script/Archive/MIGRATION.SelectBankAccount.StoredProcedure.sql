USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[SelectBankAccount]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [MIGRATION].[SelectBankAccount]
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
CREATE TABLE #BA ([BUKRS] varchar(4), [Mandant] varchar(35), [Country/Region] varchar(100), [Currency Code] varchar(10), [Bank Account No.] varchar(50), [IBAN] varchar(50), [SWIFT Code] varchar(50), [IFSC] varchar(50), [Bank Account Name] varchar(100))
' ELSE '
' END
     + ';WITH BLE AS (SELECT BLE.[Bank Account No_] FROM DynNavHRS.dbo.['+BUKRS+'$Bank Account Ledger Entry] BLE WITH (NOLOCK) GROUP BY BLE.[Bank Account No_])
INSERT INTO #BA
   SELECT '''+lkpBUKRS+''' [BUKRS]
        , '''+BUKRS+''' [Mandant]
        , COALESCE(CR.[Name],''Germany'') [Country/Region]
        , BA.[Currency Code]
        , BA.[Bank Account No_]
		, BA.[IBAN]
		, BA.[SWIFT Code]
		, CASE WHEN COALESCE(CR.[Name],''Germany'')=''India'' THEN BA.[Bank Branch No_] ELSE '''' END [IFSC]
        , BA.[Name] [Bank Account Name]
     FROM DynNavHRS.dbo.['+BUKRS+'$Bank Account] BA WITH (NOLOCK)
LEFT JOIN DynNavHRS.dbo.['+BUKRS+'$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=BA.[Country_Region Code]
LEFT JOIN BLE ON BLE.[Bank Account No_]=BA.[No_]
    WHERE BA.[Blocked]=0
'
FROM Q

SET @SQL = @SQL + '
SELECT * FROM #BA ORDER BY BUKRS, [Bank Account Name]
'
EXEC(@SQL)
END
GO
