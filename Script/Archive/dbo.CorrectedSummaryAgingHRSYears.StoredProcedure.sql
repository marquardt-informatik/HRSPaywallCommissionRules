USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[CorrectedSummaryAgingHRSYears]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CorrectedSummaryAgingHRSYears]
AS
BEGIN
;WITH GE AS
(
  SELECT SUM(CASE WHEN [Posting Date]>='2023-01-01' THEN Amount ELSE 0 END) [Change 2023]
       , SUM(CASE WHEN [Posting Date] BETWEEN '2022-10-01' AND '2022-12-31' THEN Amount ELSE 0 END) [Change 2022 < 90T]
       , SUM(CASE WHEN [Posting Date] BETWEEN '2022-01-01' AND '2022-09-30' THEN Amount ELSE 0 END) [Change 2022 > 90T]
       , SUM(CASE WHEN [Posting Date] BETWEEN '2021-01-01' AND '2021-12-31' THEN Amount ELSE 0 END) [Change 2021]
       , SUM(CASE WHEN [Posting Date] BETWEEN '2020-01-01' AND '2020-12-31' THEN Amount ELSE 0 END) [Change 2020]
       , SUM(CASE WHEN [Posting Date] BETWEEN '2019-01-01' AND '2019-12-31' THEN Amount ELSE 0 END) [Change 2019]
       , SUM(CASE WHEN [Posting Date] <= '2018-12-31' THEN Amount ELSE 0 END) [Change 2018 an before]
       , CASE WHEN ISNUMERIC(GL.[Source No_])>0 THEN GL.[Source No_] ELSE '' END [Customer No_]
    FROM DynNavHRS.dbo.[HRS$G_L Entry] GL WITH (NOLOCK)
   WHERE GL.[G_L Account No_] IN ('140100','140200','140320','140500','140510','147000','159000') 
     --AND GL.[Source No_]='6'
GROUP BY CASE WHEN ISNUMERIC(GL.[Source No_])>0 THEN GL.[Source No_] ELSE '' END
), VE AS
(
    SELECT SUM (DE.[Amount (LCY)])	[Balance]
         , C.[No_] [Customer No_]
	  FROM DynNavHRS.dbo.[HRS$Customer] C WITH (NOLOCK)
	  JOIN DynNavHRS.dbo.[HRS$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
		ON DE.[Customer No_] = CAST(C.[No_] AS VARCHAR(20)) 	
	  JOIN DynNavHRS.dbo.[HRS$Cust_ Ledger Entry] VE WITH (NOLOCK)
		ON VE.[Entry No_] = DE.[Cust_ Ledger Entry No_] 	
	   AND VE.[Open] = 1 -- NAV-196 
       --AND C.[No_]='6'
  GROUP BY C.[No_]
), DLE AS
(
  SELECT DLE.[Customer No_]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] >= '2022-12-31' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [nicht fällig]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] BETWEEN '2022-10-01' AND '2022-12-30' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [fällig 2022 < 90T]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] BETWEEN '2022-01-01' AND '2022-09-30' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [fällig 2022 >= 90T]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] BETWEEN '2021-01-01' AND '2021-12-31' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [fällig 2021]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] BETWEEN '2020-01-01' AND '2020-12-31' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [fällig 2020]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] BETWEEN '2019-01-01' AND '2019-12-31' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [fällig 2019]
       , SUM(CASE WHEN DLE.[Initial Entry Due Date] <'2019-01-01' THEN DLE.[SUM$Amount (LCY)] ELSE 0 END) [fällig 2018 und davor]
       , SUM(DLE.[SUM$Amount (LCY)]) [offen 31.12.2022]
    FROM DynNavHRS.dbo.[HRS$Detailed Cust_ Ledg_ Entry$VSIFT$4] DLE WITH (NOLOCK)
   WHERE DLE.[Posting Date]<='2022-12-31'
GROUP BY DLE.[Customer No_]
), CE AS
(
SELECT *
  FROM DLE
 --WHERE [fällig 2022 < 90T]<>0
 --   OR [fällig 2022 >= 90T]<>0
 --   OR [fällig 2021]<>0
 --   OR [fällig 2020]<>0
 --   OR [fällig 2019]<>0
 --   OR [fällig 2018 und davor]<>0
), R AS
(
   SELECT CE.[Customer No_]
        , CE.[nicht fällig] 
        , CE.[fällig 2022 < 90T]
        , CE.[fällig 2022 >= 90T]
        , CE.[fällig 2021]
        , CE.[fällig 2020]
        , CE.[fällig 2019]
        , CE.[fällig 2018 und davor]
        , COALESCE(GE.[Change 2023],0) [Change 2023]
        , COALESCE(GE.[Change 2022 < 90T],0) [Change 2022 < 90T]
        , COALESCE(GE.[Change 2022 > 90T],0) [Change 2022 > 90T]
        , COALESCE(GE.[Change 2021],0) [Change 2021]
        , COALESCE(GE.[Change 2020],0) [Change 2020]
        , COALESCE(GE.[Change 2019],0) [Change 2019]
        , COALESCE(GE.[Change 2018 an before],0) [Change 2018 an before]
     FROM CE
LEFT JOIN GE ON CE.[Customer No_]=GE.[Customer No_]
)
   SELECT R.[Customer No_]  
        , R.[fällig 2018 und davor]
        , R.[fällig 2019]
        , R.[fällig 2020]
        , R.[fällig 2021]
        , R.[fällig 2022 >= 90T]
        , R.[fällig 2022 < 90T]
        , COALESCE(VE.[Balance],0) - R.[Change 2023] - R.[fällig 2022 < 90T] - R.[fällig 2022 >= 90T] - R.[fällig 2021] - R.[fällig 2020] - R.[fällig 2019] - R.[fällig 2018 und davor] [nicht fällig]
        , COALESCE(VE.[Balance],0) - R.[Change 2023] [offen 31.12.22]
     FROM R
LEFT JOIN VE ON VE.[Customer No_]=R.[Customer No_]
END
GO
