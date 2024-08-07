USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectBusinessPartner]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectBusinessPartner]
AS
BEGIN
DECLARE @SQL varchar(max)='', @SQLWith varchar(20)=''

;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Source Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('HRS','Codenet','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','TREX','Trade','Venturecube')
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN '
CREATE TABLE #V ([Type] varchar(20), [Company] varchar(35), [No.] varchar(20), [Name] varchar(130), [Name 2] varchar(70), [Address] varchar(130), [Address 2] varchar(70), [VAT Registration No.] varchar(130), [Post Code] varchar(130), [City] varchar(130), [Country] varchar(130), [Last Posting Date] date)
' ELSE '
' END
     + ';WITH 
  CLE AS (SELECT [Customer No_], MAX([Posting Date]) [Posting Date]  FROM DynNavHRS.dbo.['+BUKRS+'$Cust_ Ledger Entry] CLE WITH (NOLOCK) GROUP BY [Customer No_])
, VLE AS (SELECT [Vendor No_], MAX([Posting Date]) [Posting Date]  FROM DynNavHRS.dbo.['+BUKRS+'$Vendor Ledger Entry] CLE WITH (NOLOCK) GROUP BY [Vendor No_])
INSERT INTO #V
SELECT ''Customer'' [Type]
     , '''+[lkpBUKRS]+''' [Company]
     , CU.[No_]
     , CU.[Name]
     , CU.[Name 2]
     , CU.[Address]
     , CU.[Address 2]
     , CU.[VAT Registration No_]
     , CU.[Post Code]
     , CU.[City]
     , CR.[Name] [Country]
     , CLE.[Posting Date] [Last Posting Date]
  FROM DynNavHRS.dbo.['+BUKRS+'$Customer] CU WITH (NOLOCK) JOIN CLE ON CLE.[Customer No_]=CU.[No_]
  JOIN DynNavHRS.dbo.['+BUKRS+'$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
 WHERE CLE.[Posting Date]>=''2010-01-01''
UNION
SELECT ''Vendor'' [Type]
     , '''+[lkpBUKRS]+''' [Company]
     , CU.[No_]
     , CU.[Name]
     , CU.[Name 2]
     , CU.[Address]
     , CU.[Address 2]
     , CU.[VAT Registration No_]
     , CU.[Post Code]
     , CU.[City]
     , CR.[Name] [Country]
     , VLE.[Posting Date] [Last Posting Date]
  FROM DynNavHRS.dbo.['+BUKRS+'$Vendor] CU WITH (NOLOCK) JOIN VLE ON VLE.[Vendor No_]=CU.[No_]
  JOIN DynNavHRS.dbo.['+BUKRS+'$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
 WHERE VLE.[Posting Date]>=''2010-01-01''
 '
FROM Q

SET @SQL = @SQL + '
SELECT * FROM #V
'
exec DebugPrint @SQL
EXEC(@SQL)
END
GO
