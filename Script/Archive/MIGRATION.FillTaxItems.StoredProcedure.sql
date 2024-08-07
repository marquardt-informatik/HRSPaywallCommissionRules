USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[FillTaxItems]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[FillTaxItems]
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
     AND VM.[Source Value] = 'HRS'
	 AND OBJECT_ID(N'DynNavHRS.dbo.['+REPLACE(VM.[Source Value],'.','_')+'$Vendor Ledger Entry]')>0
)
SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN 'TRUNCATE TABLE DynNavHRS.[MIGRATION].[TaxItems]
;WITH VAT AS
(
SELECT Q.* FROM (VALUES (''A2'',''N19''),(''V4'',''19''),(''V4'',''DR19''),(''A4'',''N0''),(''A5'',''N16''),(''V5'',''U16''),(''V0'',''0''),(''V3'',''RC19''),(''V4'',''V19''),(''V5'',''V7''),(''V6'',''V16''),(''V7'',''V5''),(''V5'',''N7''),(''V7'',''N5''),(''V0'',''V0''),(''V0'',''U0''),('''','''')) Q ([TAXKEY], [lkpTAXKEY])
)
INSERT INTO DynNavHRS.[MIGRATION].[TaxItems] ' ELSE 'UNION' END
     + '
   SELECT '''+lkpBUKRS+'''                                                                                           [BUKRS]
        , CAST(VLE.[Entry No_] as varchar(16))                                                                       [XBLNR]
        , VLE.[Vendor No_]                                                                                           [LIFNR]
		, ROW_NUMBER() OVER(PARTITION BY VLE.[Entry No_],VLE.[Vendor No_] ORDER BY VLE.[Entry No_],VLE.[Vendor No_]) [BUZEI]
		, CASE WHEN VM_A.[Destination Value]='''' THEN GLE.[G_L Account No_]  ELSE VM_A.[Destination Value] END      [HKONT]
	    , CASE WHEN VM_G.[Destination Value]='''' THEN VPG.[Payables Account] ELSE VM_G.[Destination Value] END      [GKONT2]
		, COALESCE(VAT.[TAXKEY],GLE.[VAT Prod_ Posting Group])                                                       [MWSKZ]
		, GLE.Amount * DVLE.[Amount] / DVLE.[Amount (LCY)]                                                           [FWBAS]
		, CASE WHEN VAT.[TAXKEY]='''' THEN 0.0 ELSE GLE.[VAT Amount] END * DVLE.[Amount] / DVLE.[Amount (LCY)]       [FWSTE]
		, GLE.Amount [HWBAS]
		, CASE WHEN VAT.[TAXKEY]='''' THEN 0.0 ELSE GLE.[VAT Amount] END [HWSTE]
		, null [H2BAS]
		, null [H2STE]
		, null [H3BAS]
		, null [H3STE]
		, VLE.[Entry No_]
     FROM DynNavHRS.dbo.['+BUKRS+'$Vendor Ledger Entry] VLE WITH (NOLOCK)
	 JOIN DynNavHRS.[MIGRATION].[VendorOpenItems] VOP WITH (NOLOCK) ON VOP.[Vendor Ledger Entry]=VLE.[Entry No_]
     JOIN DynNavHRS.dbo.['+BUKRS+'$Vendor] V WITH (NOLOCK) ON V.[No_] = VLE.[Vendor No_]
     JOIN DynNavHRS.dbo.['+BUKRS+'$Vendor Posting Group] VPG WITH (NOLOCK) ON VPG.[Code]=V.[Vendor Posting Group]
     JOIN DynNavHRS.dbo.['+BUKRS+'$Value Mapping] VM_G WITH (NOLOCK) ON VM_G.[Source Table No_]=15 AND VM_G.[Source Value] = VPG.[Payables Account] 
	 JOIN DynNavHRS.dbo.['+BUKRS+'$G_L Entry] GLE WITH (NOLOCK) ON VLE.[Transaction No_]=GLE.[Transaction No_]
     JOIN DynNavHRS.dbo.['+BUKRS+'$Value Mapping] VM_A WITH (NOLOCK) ON VM_A.[Source Table No_]=15 AND VM_A.[Source Value] = GLE.[G_L Account No_] 
     JOIN DynNavHRS.dbo.['+BUKRS+'$Detailed Vendor Ledg_ Entry] DVLE WITH (NOLOCK) ON VLE.[Entry No_]=DVLE.[Vendor Ledger Entry No_] AND DVLE.[Entry Type]=1
LEFT JOIN VAT ON GLE.[VAT Prod_ Posting Group] = VAT.[lkpTAXKEY]
    WHERE CASE WHEN VM_A.[Destination Value]='''' THEN GLE.[G_L Account No_]  ELSE VM_A.[Destination Value] END
	   <> CASE WHEN VM_G.[Destination Value]='''' THEN VPG.[Payables Account] ELSE VM_G.[Destination Value] END

'
  FROM Q

EXEC(@SQL)
PRINT(@SQL)

SELECT * FROM DynNavHRS.[MIGRATION].[TaxItems]
END
GO
