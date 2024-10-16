USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[FillVendorOpenItems]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[FillVendorOpenItems]
AS
BEGIN
DECLARE @SQL varchar(max)='', @SQLWith varchar(max)=''

;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('Codenet','HRS','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','TREX','Trade','Venturecube'	 )
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQLWith = @SQLWith + CASE WHEN @SQLWith='' THEN 'TRUNCATE TABLE DynNavHRS.[MIGRATION].[VendorOpenItems]
;WITH Q AS (SELECT Q.* FROM (VALUES (''AIRPLUS'',''3''),(''AUSNAHME1'',''3''),(''AUSNAHME2'',''3''),(''AUSNAHME3'',''3''),(''AUSNAHME4'',''3''),(''AZV'',''2''),(''CC_AUTO'',''3''),(''CC_IND'',''3''),(''CORE'',''1''),(''CORE-CRS'',''1''),(''CORONA'',''3''),(''DAUER'',''3''),(''DISK'',''3''),(''EXCEPTION'',''3''),(''GIRO'',''1''),(''HOC'',''3''),(''IHG VERW.'',''3''),(''IHG-ICS'',''3''),(''IMPOSSIBLE'',''3''),(''LAST-AT'',''2''),(''LAST-ES'',''2''),(''LAST-FR'',''2''),(''LAST-IHG'',''2''),(''LAST-IT'',''2''),(''LAST-NL'',''2''),(''LAST-PL'',''2''),(''LAST-RID'',''2''),(''LASTSCHRIF'',''2''),(''LAST-UK'',''2''),(''LSVCH'',''2''),(''MANUELL'',''3''),(''ONHOLD'',''3''),(''RECHN'',''3''),(''REFUSED1'',''3''),(''SCHECK'',''3''),(''SCHECK NZD'',''3''),(''SCHECK USD'',''3''),(''SCHECK_AUD'',''3''),(''SCHECK_CAD'',''3''),(''SCHECK_FRA'',''3''),(''SCHECK_GBP'',''3''),(''SCHECK_IRL'',''3''),(''SEPA'',''1''),(''ÜBW'',''3''),(''VERWEIGER2'',''3''),(''VERWEIGERT'',''3''))Q([Payment Method Code],[ZLSCH]))
,DVLE AS
(' ELSE '
UNION
' END +'
  SELECT '''+lkpBUKRS+''' [BUKRS]
       , [Vendor Ledger Entry No_]
       , SUM([Amount]) [Amount]
       , SUM([Amount (LCY)]) [Amount (LCY)]
    FROM ['+BUKRS+'$Detailed Vendor Ledg_ Entry]
GROUP BY [Vendor Ledger Entry No_]
'
  FROM Q
SET @SQLWith=@SQLWith+')
INSERT INTO DynNavHRS.[MIGRATION].[VendorOpenItems]
'


;WITH Q AS
(
  SELECT REPLACE(VM.[Source Value],'.','_') [BUKRS]
       , VM.[Destination Value] [lkpBUKRS]
    FROM DynNavHRS.dbo.[HRS$Value Mapping] VM WITH (NOLOCK)
   WHERE VM.[Source Table No_] = 2000000006
     AND VM.[Mapping validated by] <> ''
     AND REPLACE(VM.[Source Value],'.','_') IN ('Codenet','HRS','HRS Innovation Hub GmbH','HRS Prod_ Sol_ Germany GmbH','HRS Product Solutions GmbH','HRS Ragge Holding','Hotel Solutions Verwaltung','Invisible Pay GmbH','Product Development','RoRa Familien Holding','RoRa Familien Holding Verw_','TREX','Trade','Venturecube')
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN '' ELSE '
UNION
' END
     + '
   SELECT '''+lkpBUKRS+''' [BUKRS]
        , CAST(VLE.[Entry No_] as varchar(16)) [XBLNR]
        , '''+lkpBUKRS+''' + ''-'' + VLE.[Vendor No_] [LIFNR]
-- ACS-2616 +++++
	    , ''900003'' [GKONT]
	    , ''MG'' [BLART]
--	    , VM_A.[Destination Value] [GKONT]
--	    , CASE VLE.[Document Type] WHEN 0 THEN ''KA'' WHEN 1 THEN ''ZP'' WHEN 2 THEN ''KR'' WHEN 3 THEN ''KG'' END [BLART]
-- ACS-2616 -----
		, null [UMSKZ]
	    , VLE.[Document Date] AS [BLDAT]
	    , VLE.[Posting Date] AS [BUDAT]
	    , LEFT(VLE.[External Document No_],25) [BKTXT] --LEFT(VLE.[Description],25)
	    , LEFT(VLE.[Description],50) [SGTXT] -- 17.01.21 war VLE.[Document No_]
	    , COALESCE(VM_W.[Destination Value],(SELECT [LCY Code] FROM DynNavHRS.dbo.['+BUKRS+'$General Ledger Setup])) [WAERS]
		, DVLE.[Amount] [WRBTR]
		, (SELECT [LCY Code] FROM DynNavHRS.dbo.['+BUKRS+'$General Ledger Setup]) [HWAER]
		, DVLE.[Amount (LCY)] [DMBTR]
		, null [HWAE2]
		, null [DMBE2]
		, null [HWAE3]
		, null [DMBE3]
		, '''' [MWSKZ]
		, '''' [BUPLA]
		, '''' [ZTERM]
		, VLE.[Due Date] [ZFBDT]
		, COALESCE(Q.[ZLSCH],3) [ZLSCH]
		, VLE.[On Hold] [ZLSPR]
		, null [ZBD1T]
		, null [ZBD1P]
		, null [ZBD2T]
		, null [ZBD2P]
		, null [ZBD3T]
		, null [SKFBT]
		, null [ACSKT]
		, null [HBKID]
		, null [HKTID]
		, null [BVTYP]
		, null [DTWS1]
		, null [DTWS2]
		, null [DTWS3]
		, null [DTWS4]
		, CASE WHEN V.[Country_Region Code] IN (''33'',''DE'') THEN null ELSE ''523'' END [LZBKZ]
		, null [LANDL]
		, null [PRCTR]
		, null [FKBER]
		, LEFT(VLE.[Document No_],18) [ZUONR] -- 17.01.21 war null
-- ACS-2616 +++++
		, null [COSTCENTER]
		, null [ZZ_COST_OBJ]
--		, LEFT(KOSTL.lkpKOSTL,10) [COSTCENTER]
--		, LEFT(VLE.[Global Dimension 2 Code],3) [ZZ_COST_OBJ]
-- ACS-2616 -----
		, VLE.[Entry No_]
     FROM DynNavHRS.dbo.['+BUKRS+'$Vendor Ledger Entry] VLE WITH (NOLOCK)
     JOIN DynNavHRS.dbo.['+BUKRS+'$Vendor] V WITH (NOLOCK) ON V.[No_] = VLE.[Vendor No_]
     JOIN DynNavHRS.dbo.['+BUKRS+'$Value Mapping] VM WITH (NOLOCK) ON VM.[Source Table No_]=23 AND VM.[Source Value] = VLE.[Vendor No_] AND VM.[Export Structure Entry No_] IN (15,16,17,18,19,20)
     JOIN DynNavHRS.dbo.['+BUKRS+'$Vendor Posting Group] VPG WITH (NOLOCK) ON VPG.[Code]=V.[Vendor Posting Group]
     JOIN DynNavHRS.dbo.['+BUKRS+'$Value Mapping] VM_A WITH (NOLOCK) ON VM_A.[Source Table No_]=15 AND VM_A.[Source Value] = VPG.[Payables Account] 
LEFT JOIN DynNavHRS.dbo.['+BUKRS+'$Value Mapping] VM_W WITH (NOLOCK) ON VM_W.[Source Table No_]=4  AND VM_W.[Source Value] = VLE.[Currency Code]
     JOIN DVLE ON VLE.[Entry No_]=DVLE.[Vendor Ledger Entry No_] AND DVLE.[BUKRS]='''+lkpBUKRS+'''
LEFT JOIN DynNavHRS.dbo.KOSTL WITH (NOLOCK) ON KOSTL.BUKRS='''+BUKRS+''' AND KOSTL.KOSTL=VLE.[Global Dimension 1 Code]
LEFT JOIN Q ON Q.[Payment Method Code]=REPLACE(REPLACE(VLE.[Payment Method Code],CHAR(10),''''),CHAR(13),'''')
    WHERE VLE.[Open]=1
	  AND VLE.[Vendor No_]<>''70000''
'
  FROM Q

EXEC(@SQLWith+@SQL)
PRINT(SUBSTRING(@SQLWith+@SQL,1,8000))
PRINT(SUBSTRING(@SQLWith+@SQL,8001,8000))
PRINT(SUBSTRING(@SQLWith+@SQL,16001,8000))
PRINT(SUBSTRING(@SQLWith+@SQL,24001,8000))

  SELECT * FROM DynNavHRS.[MIGRATION].[VendorOpenItems] 
END
GO
