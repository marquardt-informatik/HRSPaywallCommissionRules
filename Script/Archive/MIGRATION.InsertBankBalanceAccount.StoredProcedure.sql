USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[InsertBankBalanceAccount]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 17.12.20
-- Description:	Erstellt Bankkonten aus Exceliste und fügt den Eintrag in die Mapping-Tabelle ein
/*
EXEC MIGRATION.InsertBankBalanceAccount '121110', 'Spk KölnBonn 0030002042 (EIN)', 'Spk KölnBonn 0030002042 (EIN)','2000','120000','E'
*/
-- =============================================
CREATE PROCEDURE [MIGRATION].[InsertBankBalanceAccount] 
    @No varchar(10) = ''
  , @Name varchar(30) = ''
  , @SearchName varchar(30) = ''
  , @BUKRS varchar(4)
  , @Sammel varchar(10) = ''
  , @EA varchar(1)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #BUKRS ( BUKRS varchar(30), lkpBUKRS varchar(4))
INSERT INTO #BUKRS
EXEC MIGRATION.ZHRS_MIG_LookupBUKRS

DECLARE @Company varchar(30)
SELECT @Company=REPLACE(BUKRS,'.','_') FROM #BUKRS WHERE lkpBUKRS=@BUKRS

DECLARE @SQL varchar(max)=''
SET @SQL =
'IF OBJECT_ID(''['+@Company+'$G_L Account]'')>0 
IF NOT EXISTS(SELECT * FROM ['+@Company+'$G_L Account] WHERE [No_]='''+@No+''')
INSERT INTO ['+@Company+'$G_L Account] ([No_],[Name],[Search Name],[Account Type],[Global Dimension 1 Code],[Global Dimension 2 Code],[Income_Balance],[Debit_Credit],[No_ 2],[Blocked],[Direct Posting],[Reconciliation Account],[New Page],[No_ of Blank Lines],[Indentation],[Last Date Modified],[Totaling],[Consol_ Translation Method],[Consol_ Debit Acc_],[Consol_ Credit Acc_],[Gen_ Posting Type],[Gen_ Bus_ Posting Group],[Gen_ Prod_ Posting Group],[Automatic Ext_ Texts],[Tax Area Code],[Tax Liable],[Tax Group Code],[VAT Bus_ Posting Group],[VAT Prod_ Posting Group],[Exchange Rate Adjustment],[Default IC Partner G_L Acc_ No],[Check Balance 0],[Cost Account No_],[Project Account No_],[Liquid Account No_],[Perf_ Dir_ German Bundesbank],[Dim_ for System Entries],[Build Open Entries],[Application Bal_ Debit Acc_],[Application Bal_ Credit Acc_],[Acc_ Schedule Name 1],[Acc_ Schedule Name 2],[Acc_ Schedule Name 3],[Acc_ Schedule Line 1],[Acc_ Schedule Line 2],[Acc_ Schedule Line 3],[Account Group 1],[Account Group 2],[Account Group 3],[Blocked from])
SELECT '''+@No+''' [No_],'''+@Name+''' [Name],'''+@SearchName+''' [Search Name],[Account Type],[Global Dimension 1 Code],[Global Dimension 2 Code],[Income_Balance],[Debit_Credit],[No_ 2],0 [Blocked],[Direct Posting],[Reconciliation Account],[New Page],[No_ of Blank Lines],[Indentation],''1753-01-01'' [Last Date Modified],[Totaling],[Consol_ Translation Method],[Consol_ Debit Acc_],[Consol_ Credit Acc_],[Gen_ Posting Type],[Gen_ Bus_ Posting Group],[Gen_ Prod_ Posting Group],[Automatic Ext_ Texts],[Tax Area Code],[Tax Liable],[Tax Group Code],[VAT Bus_ Posting Group],[VAT Prod_ Posting Group],[Exchange Rate Adjustment],[Default IC Partner G_L Acc_ No],[Check Balance 0],'''' [Cost Account No_],[Project Account No_],[Liquid Account No_],[Perf_ Dir_ German Bundesbank],[Dim_ for System Entries],[Build Open Entries],[Application Bal_ Debit Acc_],[Application Bal_ Credit Acc_],[Acc_ Schedule Name 1],[Acc_ Schedule Name 2],[Acc_ Schedule Name 3],[Acc_ Schedule Line 1],[Acc_ Schedule Line 2],[Acc_ Schedule Line 3],[Account Group 1],[Account Group 2],[Account Group 3],[Blocked from]
  FROM [dbo].[HRS$G_L Account]
 WHERE [No_]=''120089''
'
EXEC(@SQL)
PRINT(@SQL)

IF @Sammel<>''
BEGIN
  IF @EA='E'
    SET @SQL = 'UPDATE ['+@Company+'$Bank Account Posting Group] SET [Inbound G_L Bank Account No_]='''+@No+''' WHERE [G_L Bank Account No_]='''+@Sammel+''' '
  ELSE
    SET @SQL = 'UPDATE ['+@Company+'$Bank Account Posting Group] SET [Outbound G_L Bank Account No_]='''+@No+''' WHERE [G_L Bank Account No_]='''+@Sammel+''' '
  EXEC(@SQL)
  PRINT(@SQL)
END

SET @SQL =
'UPDATE ['+@Company+'$Value Mapping] SET [Destination Value]='''+@No+''',[Mapping validated by]=''ggi01'',[Mapping validated at]='''+CONVERT(varchar(10),GETDATE(),120)+'''   WHERE [Source Table No_]=15 AND [Source Value]='''+@No+''' '
EXEC(@SQL)
PRINT(@SQL)


END
GO
