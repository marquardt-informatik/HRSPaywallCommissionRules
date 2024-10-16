USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BI].[InsertIncome]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI].[InsertIncome]
AS
BEGIN
TRUNCATE TABLE BI.Income
;WITH GE AS
(
  SELECT 'HRS GmbH' [Legal Entity]
       , GE.[Source No_] [Customer No_]
       , GE.[G_L Account No_]
       , GA.[Name] [G_L Account Name]
       , DATEADD(dd,-DATEPART(dd,GE.[Posting Date])+1,GE.[Posting Date]) [Posting Month]
       , DATEADD(dd,-DATEPART(dd,GE.[Posted at])+1,GE.[Posted at]) [Posted at Month]
       , SUM(GE.[Amount]) [Amount (LCY)]
    FROM [HRS$G_L Entry] GE WITH (NOLOCK)
    JOIN [HRS$G_L Account] GA WITH (NOLOCK) ON GA.[No_]=GE.[G_L Account No_]
   WHERE GE.[G_L Account No_] LIKE '8%'
GROUP BY GE.[G_L Account No_]
       , GA.[Name]
       , GE.[Source No_]
       , DATEADD(dd,-DATEPART(dd,GE.[Posting Date])+1,GE.[Posting Date]) 
       , DATEADD(dd,-DATEPART(dd,GE.[Posted at])+1,GE.[Posted at]) 
UNION
  SELECT 'Hotel Reservation Service (Shanghai) Co., Ltd.' [Legal Entity]
       , GE.[Source No_] [Customer No_]
       , GE.[G_L Account No_]
       , GA.[Name] [G_L Account Name]
       , DATEADD(dd,-DATEPART(dd,GE.[Posting Date])+1,GE.[Posting Date]) [Posting Month]
       , DATEADD(dd,-DATEPART(dd,GE.[Posted at])+1,GE.[Posted at]) [Posted at Month]
       , SUM(GE.[Amount]) [Amount (LCY)]
    FROM [HRS-CN$G_L Entry] GE WITH (NOLOCK)
    JOIN [HRS-CN$G_L Account] GA WITH (NOLOCK) ON GA.[No_]=GE.[G_L Account No_]
   WHERE GE.[G_L Account No_] LIKE '8%'
GROUP BY GE.[G_L Account No_]
       , GA.[Name]
       , GE.[Source No_]
       , DATEADD(dd,-DATEPART(dd,GE.[Posting Date])+1,GE.[Posting Date]) 
       , DATEADD(dd,-DATEPART(dd,GE.[Posted at])+1,GE.[Posted at]) 
UNION
  SELECT 'Hotel Reservation Service Brasil Ltda.' [Legal Entity]
       , GE.[Source No_] [Customer No_]
       , GE.[G_L Account No_]
       , GA.[Name] [G_L Account Name]
       , DATEADD(dd,-DATEPART(dd,GE.[Posting Date])+1,GE.[Posting Date]) [Posting Month]
       , DATEADD(dd,-DATEPART(dd,GE.[Posted at])+1,GE.[Posted at]) [Posted at Month]
       , SUM(GE.[Amount]) [Amount (LCY)]
    FROM [HRS-BR$G_L Entry] GE WITH (NOLOCK)
    JOIN [HRS-BR$G_L Account] GA WITH (NOLOCK) ON GA.[No_]=GE.[G_L Account No_]
   WHERE GE.[G_L Account No_] LIKE '8%'
GROUP BY GE.[G_L Account No_]
       , GA.[Name]
       , GE.[Source No_]
       , DATEADD(dd,-DATEPART(dd,GE.[Posting Date])+1,GE.[Posting Date]) 
       , DATEADD(dd,-DATEPART(dd,GE.[Posted at])+1,GE.[Posted at]) 
)
INSERT INTO [BI].[Income] ([Legal Entity],[Customer No_],[G_L Account No_],[G_L Account Name],[Posting Month],[Posted at Month],[Amount (LCY)])
SELECT [Legal Entity],[Customer No_],[G_L Account No_],[G_L Account Name],[Posting Month],[Posted at Month],[Amount (LCY)] FROM GE
END
GO
