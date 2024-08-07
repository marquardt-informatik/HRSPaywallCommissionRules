USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[PaymSolutionVATMatrix]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [MIGRATION].[PaymSolutionVATMatrix]
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
     AND REPLACE(VM.[Source Value],'.','_') IN ('Codenet','HRS','HRS-BR','HRS-CN','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','Trade','Venturecube', 'HRS Payment','HRS PaySol'	 
     )
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Paym_ Solution VAT Matrix]')>0
)
SELECT @SQLWith = @SQLWith + CASE WHEN @SQLWith='' THEN '
;WITH VPS AS
(' ELSE '
UNION
' END +'
SELECT '''+lkpBUKRS+''' [lkpBUKRS]
      ,'''+BUKRS+''' [BUKRS]
      ,[Cust_ VAT Bus_ Posting Group]
      ,[Service Code]
      ,[VAT %]
    FROM ['+BUKRS+'$Paym_ Solution VAT Matrix] VPS WITH (NOLOCK)
'
  FROM Q
SELECT @SQLWith = @SQLWith + ')'

SELECT @SQL=@SQLWith + '

SELECT [lkpBUKRS] [BUKRS]
      ,[BUKRS] [Mandant]
      ,[Cust_ VAT Bus_ Posting Group]
      ,[Service Code]
      ,[VAT %]
  FROM VPS
  ORDER BY 1,2,3,4
  '
EXEC DebugPrint @SQL
EXEC (@SQL)
END
GO
