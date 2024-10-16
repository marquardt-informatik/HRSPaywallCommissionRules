USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[CustomerBankAccounts]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Created 03/07/2023
-- DAP-1335
-- exec DynNavHRS.[MIGRATION].[CustomerBankAccounts]
CREATE PROC [MIGRATION].[CustomerBankAccounts]
AS 
BEGIN
DECLARE @SQL varchar(max)=''

 SELECT @SQL= @SQL + CASE WHEN @SQL='' THEN '' ELSE 'UNION' END
      + '
SELECT '''+Company+''' [Company in Navision]
     , CB.[Customer No_] [Customer No_ in Navision]
     , '''+Company+'|''+CAST(CB.[Customer No_] as varchar(20)) [BusinessPartner]
     , CB.[Code] [BankIdentification]
     , CB.[Bank Account No_] [BankAccount]
     , CU.[Name] [BankAccountHolderName]
     , CB.[Alternative Account Owner] [BankAccountName]
     , '''' [BankAccountReferenceText]
     , CASE WHEN CB.[IBAN]='''' THEN '''' ELSE RIGHT(LEFT(CB.[IBAN],4),2) END [BankControlKey]
     , CR.[Bank Country Code] [BankCountryKey]
     , CB.[Name] [BankName]
     , CB.[Bank Branch No_] [BankNumber]
     , CB.[City] [CityName]
     , CASE WHEN CB.[Mandate Status]=0 THEN ''false'' ELSE ''true'' END [CollectionAuthInd]
     , CB.[IBAN]
     , CB.[Mandate Date] [IBANValidityStartDate]
     , CB.[SWIFT Code] [SWIFTCode]
     , null [ValidityEndDate]
     , CB.[Mandate Date] [ValidityStartDate]
  FROM ['+Company+'$Customer] CU WITH (NOLOCK)
  JOIN ['+Company+'$Customer Bank Account] CB WITH (NOLOCK) ON CU.[No_]=CB.[Customer No_]
  JOIN ['+Company+'$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CB.[Country_Region Code]
 WHERE CB.[Clearing]=1
'
 FROM MIGRATION.GetCompanies() 

EXEC DebugPrint @SQL

EXEC(@SQL)
END
GO
