USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[VendorLedgerCreation]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [MIGRATION].[VendorLedgerCreation]
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
       , VLE.[Entry No_]
       , MAX(GLR.[Creation Date]) [Creation Date]
       , MAX(GLR.[User ID]) [User ID]
    FROM ['+BUKRS+'$Vendor Ledger Entry] VLE WITH (NOLOCK)
    JOIN ['+BUKRS+'$G_L Entry] GLE WITH (NOLOCK) ON  VLE.[Transaction No_] = GLE.[Transaction No_]
    JOIN ['+BUKRS+'$G_L Register] GLR WITH (NOLOCK) ON GLR.[From Entry No_] <= GLE.[Entry No_] AND GLE.[Entry No_] <= GLR.[To Entry No_]
   WHERE VLE.[Posting Date]>=''2020-01-01''
GROUP BY VLE.[Entry No_]
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
