USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_MigrateInsertLog]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_MigrateInsertLog]
  @SAPName varchar(20)
, @SAPType varchar(10)
, @SAPSubType varchar(30)
, @Source int --DB2=0,NAV=1,CRM=2
, @SourceTableName varchar(30)
, @PrimaryKeyValue varchar(250)
, @ErrorCode varchar(3) --000 Start 999 Ende
, @Count int
, @ExportedFileName varchar(250)
AS 
BEGIN
  DECLARE @ExportStructureEntrNo int

  SELECT @ExportStructureEntrNo = [Entry No_]
    FROM [Export Structure] ES WITH (NOLOCK)
   WHERE ES.[SAP Name] = @SAPName
     AND ES.[Type]     = @SAPType
	 AND ES.[Sub Type] = @SAPSubType

INSERT INTO [Export Log] ([Source Table Name],[Source],[Error Code],[Primary Key Value],[Export Structure Entry No_],[Timestamp],[Entry Type],[Exported Rows],[Exported File Name])
SELECT @SourceTableName [Source Table Name]
     , @Source [Source]
	 , @ErrorCode
	 , @PrimaryKeyValue [Primary Key Value]
	 , @ExportStructureEntrNo [Export Structure Entry No_]
	 , GETDATE() [Timestamp]
	 , 1 [Entry Type]
	 , @Count
	 , @ExportedFileName
END
GO
