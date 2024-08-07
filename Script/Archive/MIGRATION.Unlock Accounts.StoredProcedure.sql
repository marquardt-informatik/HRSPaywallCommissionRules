USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MIGRATION].[Unlock Accounts]    Script Date: 10.04.2024 14:31:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MIGRATION].[Unlock Accounts]
AS 
BEGIN
UPDATE [RoRa Familien Holding$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [RoRa Familien Holding Verw_$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [HRS Ragge Holding$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [HRS$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [HRS Product Solutions GmbH$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [HRS Prod_ Sol_ Germany GmbH$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [Product Development$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [Venturecube$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [HRS Innovation Hub GmbH$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [Codenet$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [Hotel Solutions Verwaltung$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [Invisible Pay GmbH$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
UPDATE [Trade$G_L Account] SET [Blocked from]='1753-01-01' WHERE [Blocked from]<>'1753-01-01'
END
GO
