USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[sp_HRS$Erstellen und Befüllen von 'HRS$Sales Invoice Corrections']    Script Date: 10.04.2024 14:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [AFFILIATE].[sp_HRS$Erstellen und Befüllen von 'HRS$Sales Invoice Corrections']
AS
BEGIN
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'DROP TABLE', 'Start'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[HRS$Sales Invoice Corrections]') AND type in (N'U'))
  DROP TABLE [HRS$Sales Invoice Corrections]
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'DROP TABLE', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'CREATE TABLE', 'Start'
CREATE TABLE [HRS$Sales Invoice Corrections]
(
    [Document No_]     varchar(20) NOT NULL
  , [Posting Date]     datetime
  , [Min Document No_] varchar(20)
  , [Max Document No_] varchar(20)
  , [Country_Region Code] varchar(20)
  , [Customer No] varchar(20)
  , [Is Corrected]     tinyint
  , [Is Canceled]      tinyint
  , [Credit Memo No_]  varchar(20)
  , [Max Entry No_]    int
)
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'CREATE TABLE', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'INSERT INTO', 'Start'
INSERT INTO [HRS$Sales Invoice Corrections]
SELECT * 
  FROM [dbo].[vw_HRS$Sales Invoice Corrections]
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'INSERT INTO', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'ALTER TABLE', 'Start'
ALTER TABLE dbo.[HRS$Sales Invoice Corrections] 
  ADD CONSTRAINT [PK_HRS$Sales Invoice Correction]
	PRIMARY KEY CLUSTERED
	(
	    [Document No_] 
	)
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'ALTER TABLE', 'Ende'
  
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'CREATE INDEX', 'Start'
CREATE UNIQUE INDEX [IX_HRS$Sales Invoice Correction_Min Document No_] ON [HRS$Sales Invoice Corrections] ([Min Document No_]) 
CREATE UNIQUE INDEX [IX_HRS$Sales Invoice Correction_Max Document No_] ON [HRS$Sales Invoice Corrections] ([Max Document No_])
CREATE NONCLUSTERED INDEX [IX_HRS$Sales Invoice Corrections_Credit Memo No_]
ON [dbo].[HRS$Sales Invoice Corrections] ([Credit Memo No_])
INCLUDE ([Min Document No_])
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Erstellen und Befüllen von HRS$Sales Invoice Corrections', 'CREATE INDEX', 'Ende'
END
GO
