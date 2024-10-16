USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectAccountSums]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SelectAccountSums]
  @GLAccFrom varchar(max)='157000'
, @GLAccTo varchar(max)='157999'
AS
BEGIN

DECLARE @SQL varchar(max)='', @SQLWith varchar(20)=''

SELECT @SQL = @SQL + CASE WHEN @SQL='' THEN '' ELSE '
UNION
' END +
CASE WHEN S.String='HRS' THEN
'
  SELECT '''+S.String+''' [Mandant]
       , GE.[G_L Account No_] [Kontonummer]
       , YEAR(GE.[Posting Date]) [Jahr]
       , MONTH(GE.[Posting Date]) [Monat]
       , GE.[VAT Prod_ Posting Group] [Steurkennzeichen]
       , CASE
           WHEN GE.[Amount]=0 AND [VAT Amount]=0 THEN ''0''
           WHEN GE.[Amount]<>0 AND [VAT Amount]=0 THEN ''0''
           WHEN GE.[Amount]=0 AND [VAT Amount]<>0 THEN ''100''
           WHEN GE.[Amount]<>0 AND [VAT Amount]<>0 THEN REPLACE(REPLACE(GE.[VAT Prod_ Posting Group],''N'',''''),''V'','''')
         END [Steuer Rate]
       , CASE 
           WHEN NOT CU.[No_] IS NULL THEN CASE WHEN CU.[Chain]=''13'' AND CU.[Country_Region Code]=''33'' THEN ''AUSLAND'' ELSE GE.[VAT Bus_ Posting Group] END
           ELSE GE.[VAT Bus_ Posting Group]
         END [VAT Bus_ Posting Group]
       , SUM(GE.[Amount]) [Betrag]
       , SUM(GE.[VAT Amount]) [MwSt. Betrag]
       , COUNT(1) [Entries]
    FROM ['+S.String+'$G_L Entry] GE WITH (NOLOCK)
    JOIN ['+S.String+'$G_L Account] GA WITH (NOLOCK) ON GE.[G_L Account No_] = GA.[No_]
LEFT JOIN ['+S.String+'$Customer] CU WITH (NOLOCK) ON GE.[Source Type]=1 AND GE.[Source No_]=CAST(CU.[No_] AS varchar(20))
   WHERE GA.[No_] BETWEEN '''+@GLAccFrom+''' AND '''+@GLAccTo+'''
     AND 
       ( 
           GE.[Posting Date] BETWEEN ''2020-01-01 00:00:00'' AND ''2020-12-31 00:00:00''
        OR GE.[Posting Date] BETWEEN ''2021-01-01 00:00:00'' AND ''2021-12-31 00:00:00''
       )
     AND GE.[Amount]<>0
GROUP BY GE.[G_L Account No_]
       , YEAR(GE.[Posting Date]) 
       , MONTH(GE.[Posting Date]) 
       , GE.[VAT Prod_ Posting Group]
       , CASE
           WHEN GE.[Amount]=0 AND [VAT Amount]=0 THEN ''0''
           WHEN GE.[Amount]<>0 AND [VAT Amount]=0 THEN ''0''
           WHEN GE.[Amount]=0 AND [VAT Amount]<>0 THEN ''100''
           WHEN GE.[Amount]<>0 AND [VAT Amount]<>0 THEN REPLACE(REPLACE(GE.[VAT Prod_ Posting Group],''N'',''''),''V'','''')
         END
       , CASE 
           WHEN NOT CU.[No_] IS NULL THEN CASE WHEN CU.[Chain]=''13'' AND CU.[Country_Region Code]=''33'' THEN ''AUSLAND'' ELSE GE.[VAT Bus_ Posting Group] END
           ELSE GE.[VAT Bus_ Posting Group]
         END 
' 
ELSE
'
  SELECT '''+S.String+''' [Mandant]
       , GE.[G_L Account No_] [Kontonummer]
       , YEAR(GE.[Posting Date]) [Jahr]
       , MONTH(GE.[Posting Date]) [Monat]
       , GE.[VAT Prod_ Posting Group] [Steurkennzeichen]
       , CASE
           WHEN [Amount]=0 AND [VAT Amount]=0 THEN ''0''
           WHEN [Amount]<>0 AND [VAT Amount]=0 THEN ''0''
           WHEN [Amount]=0 AND [VAT Amount]<>0 THEN ''100''
           WHEN [Amount]<>0 AND [VAT Amount]<>0 THEN REPLACE(REPLACE(GE.[VAT Prod_ Posting Group],''N'',''''),''V'','''')
         END [Steuer Rate]
       , GE.[VAT Bus_ Posting Group]
       , SUM(GE.[Amount]) [Betrag]
       , SUM(GE.[VAT Amount]) [MwSt. Betrag]
       , COUNT(1) [Entries]
    FROM ['+S.String+'$G_L Entry] GE WITH (NOLOCK)
    JOIN ['+S.String+'$G_L Account] GA WITH (NOLOCK) ON GE.[G_L Account No_] = GA.[No_]
   WHERE GA.[No_] BETWEEN '''+@GLAccFrom+''' AND '''+@GLAccTo+'''
     AND
       ( 
           GE.[Posting Date] BETWEEN ''2020-01-01 00:00:00'' AND ''2020-12-31 00:00:00''
        OR GE.[Posting Date] BETWEEN ''2021-01-01 00:00:00'' AND ''2021-12-31 00:00:00''
       )
     AND GE.[Amount]<>0
GROUP BY GE.[G_L Account No_]
       , YEAR(GE.[Posting Date]) 
       , MONTH(GE.[Posting Date]) 
       , GE.[VAT Prod_ Posting Group]
       , CASE
           WHEN [Amount]=0 AND [VAT Amount]=0 THEN ''0''
           WHEN [Amount]<>0 AND [VAT Amount]=0 THEN ''0''
           WHEN [Amount]=0 AND [VAT Amount]<>0 THEN ''100''
           WHEN [Amount]<>0 AND [VAT Amount]<>0 THEN REPLACE(REPLACE(GE.[VAT Prod_ Posting Group],''N'',''''),''V'','''')
         END
       , GE.[VAT Bus_ Posting Group]
' 
END
FROM dbo.Split('HRS,Trade,Hotel Solutions Verwaltung,HRS Product Solutions GmbH,HRS Prod_ Sol_ Germany GmbH,HRS Innovation Hub GmbH,Product Development,Venturecube,Codenet,HRS PaySol,HRS Payment',',') S

EXEC DebugPrint @SQL
EXEC (@SQL)
END
GO
