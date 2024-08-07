USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_AddSalesTrend_HRS-CN]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
   EXEC [dbo].[sp_AddSalesTrend_HRS] '60579757'
*/
CREATE PROC [dbo].[sp_AddSalesTrend_HRS-CN]
  @EntryNo varchar(max) = NULL
AS BEGIN
  DECLARE @SQL varchar(max), @Debug int=0

  SET @SQL = '
DELETE FROM [HRS-CN$Sales Trend New] WHERE [Entry No_] IN ('+ @EntryNo + ')
   ;WITH D2_MAX AS
   (
   SELECT DL.[Display Case No_]
	    , DL.[Reservation No_]
	    , MIN(DL.[Position No_]) [Position No_]
     FROM DynNavHRS.dbo.[HRS-CN$Agency Display Line]   DL WITH (NOLOCK)
 GROUP BY DL.[Display Case No_]
	    , DL.[Reservation No_]
   )
   INSERT INTO [HRS-CN$Sales Trend New] ([Reservation No_],[Position No_],[Entry No_ General Ledger Entry], [Posting Date],[Amount (LCY)],[Turnover (LCY)],[Entry No_],[Customer No_])
   SELECT DISTINCT 
          COALESCE(COALESCE(GD.[Reservation No_],DL.[Reservation No_]),CL.[Reservierungsnr_]) [Reservation No_]
		, COALESCE(GD.[Position No_],COALESCE(DL.[Position No_],1))                           [Position No_]
		, CL.[Entry No_]                                       [Entry No_ General Ledger Entry]
		, GL.[Posting Date]
		, COALESCE(ROUND(GD.[Line Amount Diff_ (LCY)] * 1.02,2),COALESCE(
		  CASE WHEN CL.[Document Type]=2 THEN 1 ELSE -1 END
		* DL.[Line Amount] / CASE WHEN DH.[Currency Factor]=0 THEN 1 ELSE DH.[Currency Factor] END * CASE WHEN DL.[Action]=3 THEN 0 ELSE 1 END
		* CASE WHEN COALESCE(GL.[Amount],(-CL.[Sales (LCY)]))=0 THEN 1 ELSE (-CL.[Sales (LCY)]) / COALESCE(GL.[Amount],(-CL.[Sales (LCY)])) END
		, GL.[Amount] * -1))                                    [Amount (LCY)]
		, COALESCE(COALESCE(
		  DL.[Commission Base Amount] / CASE WHEN DH.[Currency Factor]=0 THEN 1 ELSE DH.[Currency Factor] END * DL.[Number of Nights] * CASE WHEN DL.[Action]=3 THEN 0 ELSE 1 END
		* CASE WHEN COALESCE(GL.[Amount],(-CL.[Sales (LCY)]))=0 THEN 1 ELSE (-CL.[Sales (LCY)]) / COALESCE(GL.[Amount],(-CL.[Sales (LCY)])) END
		, D2.[Commission Base Amount (LCY)] * D2.[Number of Nights] * CASE WHEN D2.[Action]=3 THEN 0 ELSE 1 END),0)
		* CASE WHEN CL.[Document Type]=2 THEN 1 ELSE -1 END    [Turnover (LCY)]
		, GL.[Entry No_]
		, CL.[Customer No_]
     FROM DynNavHRS.dbo.[HRS-CN$G_L Entry]             GL WITH (NOLOCK)
     JOIN DynNavHRS.dbo.[HRS-CN$Cust_ Ledger Entry]    CL WITH (NOLOCK)
       ON GL.[Transaction No_]      = CL.[Transaction No_]
LEFT JOIN [HRS-CN$CDG Import Zahlungszentralen$VSIFT$9] ZZ WITH (NOLOCK)
       ON ZZ.[Reservierungsnummer] = CL.[Reservierungsnr_]
	  AND CL.[Reservierungsnr_] <> 0
LEFT JOIN D2_MAX
       ON D2_MAX.[Display Case No_]                   = ZZ.[MIN$DocumentNo]
	  AND D2_MAX.[Reservation No_]                    = ZZ.[Reservierungsnummer]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Line]   D2 WITH (NOLOCK)
       ON D2.[Display Case No_]                   = D2_MAX.[Display Case No_]
	  AND D2.[Reservation No_]                    = D2_MAX.[Reservation No_]
	  AND D2.[Position No_]                       = D2_MAX.[Position No_]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Sales Cr_Memo Header]  CH WITH (NOLOCK)
	   ON CH.[No_]                                = CL.[Document No_]
	  AND CL.[Document Type]                      = 3 -- Gutschrift
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Sales Invoice Header]  SH WITH (NOLOCK)
	   ON SH.[No_]                                = CASE WHEN CH.[Applies-to Doc_ No_]<>'''' THEN CH.[Applies-to Doc_ No_] ELSE CASE WHEN CHARINDEX(''/CR'',GL.[Document No_]) > 0 THEN SUBSTRING(GL.[Document No_],1,CHARINDEX(''/CR'',GL.[Document No_])-1) ELSE GL.[Document No_] END END
	  AND CL.[Document Type]                      = 3 -- Rechnung
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Header] DH WITH (NOLOCK)
       ON (
	      (GL.[Document Type] = 2 AND DH.[Posted Invoice No_] IN (GL.[Document No_],SH.[No_]))
	   OR (GL.[Document Type] = 3 AND DH.[Posted Invoice No_] IN (GL.[Document No_],SH.[No_],CASE WHEN CHARINDEX(''/'',GL.[Document No_]) > 0 AND LEN(GL.[Document No_])-CHARINDEX(''/'',GL.[Document No_])>3 THEN REVERSE(SUBSTRING(REVERSE(GL.[Document No_]),CHARINDEX(''/'',REVERSE(GL.[Document No_]))+1,100)) ELSE GL.[Document No_] END))
	      )
      AND CL.[Customer No_] = DH.[Bill-to Customer No_]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Sales Invoice Header]   SH2 WITH (NOLOCK)
       ON CL.[Document No_]                        = SH2.[No_]
	  AND CL.[Document Type]                       = 2
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Sales Cr_Memo Header]   CH2 WITH (NOLOCK)
	   ON CH2.[No_]                               IN (SH2.[Applies-to Doc_ No_], CL.[Document No_])
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Cr_ Memo Header] GH WITH (NOLOCK)
       ON CH2.[No_]                                = GH.[Posted Cr_ Memo No_]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Cr_ Memo Line]   GD WITH (NOLOCK)
       ON GD.[Document No_]                        = GH.[No_]
	  AND GD.[Source]                             IN (''CI'',''CCR'',''MICE'',''HOTEL.DE'',''TMC'',''DEALS'')
	  AND GD.[Action]                             IN (''Refund'')
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Display Line]    DL WITH (NOLOCK)
       ON DL.[Display Case No_]                    = DH.[Case No_]
	  AND ZZ.[Reservierungsnummer] IS NULL
	  AND GD.[Document No_]  IS NULL
    WHERE CL.[Document Type]                     IN (2,3)
	  --AND COALESCE(DL.[Reservation No_],CL.[Reservierungsnr_])<>0--=39125045
	  AND GL.[Entry No_]                         IN ('+ @EntryNo + ')

   DECLARE @VT TABLE ([Entry No_] INT PRIMARY KEY, [SUM$Amount (LCY)] dec(38,20), [$Cnt] int)
   INSERT INTO @VT
   SELECT [Entry No_], [SUM$Amount (LCY)], [$Cnt]
     FROM [HRS-CN$Sales Trend New$VSIFT$2] WITH (NOLOCK)
    WHERE [Entry No_] IN ('+ @EntryNo + ')
   
   UPDATE ST SET
          ST.[Amount (LCY)] 
        = CASE WHEN VT.[SUM$Amount (LCY)]=0 THEN
		    (-GL.[Amount]) / CASE WHEN VT.[$Cnt]=0 THEN 1 ELSE VT.[$Cnt] END
		  ELSE
		    ST.[Amount (LCY)] * CASE WHEN VT.[SUM$Amount (LCY)]=0 THEN 1 ELSE (-GL.[Amount]) / VT.[SUM$Amount (LCY)] END
          END
        , ST.[Turnover (LCY)] = ST.[Turnover (LCY)] * CASE WHEN VT.[SUM$Amount (LCY)]=0 THEN 1 ELSE (-GL.[Amount]) / VT.[SUM$Amount (LCY)] END
     FROM [HRS-CN$Sales Trend New] ST
     JOIN [HRS-CN$G_L Entry] GL WITH (NOLOCK)
       ON GL.[Entry No_] = ST.[Entry No_]
     JOIN @VT VT
       ON VT.[Entry No_] = ST.[Entry No_]
    WHERE (CASE WHEN VT.[SUM$Amount (LCY)]=0 THEN 1 ELSE (-GL.[Amount]) / VT.[SUM$Amount (LCY)] END <> 1 OR VT.[SUM$Amount (LCY)]=0)
'
IF @Debug = 1
BEGIN
PRINT(SUBSTRING(@SQL,1,8000))
PRINT(SUBSTRING(@SQL,8001,8000))
PRINT(SUBSTRING(@SQL,16001,8000))
PRINT(SUBSTRING(@SQL,24001,8000))
END
IF @Debug <> 1
  EXEC(@SQL)

END
GO
