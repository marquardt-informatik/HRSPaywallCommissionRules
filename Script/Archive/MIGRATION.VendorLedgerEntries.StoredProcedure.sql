USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[VendorLedgerEntries]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [MIGRATION].[VendorLedgerEntries]
AS
BEGIN

DECLARE @SQL varchar(max)='', @SQLWith varchar(max)='', @SQLWith2 varchar(max)=''

;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('Codenet','HRS','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','Trade','Venturecube'	 
     )
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQLWith = @SQLWith + CASE WHEN @SQLWith='' THEN '
;WITH DVLE AS
(' ELSE '
UNION
' END +'
  SELECT '''+lkpBUKRS+''' [BUKRS]
       , DVLE.[Vendor Ledger Entry No_]
       , SUM(DVLE.[Amount]) [Amount]
       , SUM(DVLE.[Amount (LCY)]) [Amount (LCY)]
       , SUM(CASE WHEN DVLE.[Entry Type]=1 THEN [Amount] ELSE 0 END) [Initial Amount]
       , SUM(CASE WHEN DVLE.[Entry Type]=1 THEN [Amount (LCY)] ELSE 0 END) [Initial Amount (LCY)]
       , MAX(VLE.[Open]) [Open]
    FROM ['+BUKRS+'$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK)
    JOIN ['+BUKRS+'$Vendor Ledger Entry] VLE WITH (NOLOCK) ON DVLE.[Vendor Ledger Entry No_]=VLE.[Entry No_]
GROUP BY DVLE.[Vendor Ledger Entry No_]
'
  FROM Q
SELECT @SQLWith = @SQLWith + ')'

SELECT @SQL=@SQLWith + '

SELECT *
  FROM DVLE
  '
EXEC DebugPrint @SQL
EXEC (@SQL)
END
GO
