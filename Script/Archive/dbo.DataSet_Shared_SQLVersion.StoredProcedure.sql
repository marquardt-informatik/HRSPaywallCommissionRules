USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[DataSet_Shared_SQLVersion]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[DataSet_Shared_SQLVersion] @script_name varchar(80) = null, @name varchar(60) = null AS 
IF OBJECT_ID ('tbl_SCRIPT_ENVIRONMENT_DETAILS') IS NOT NULL
  SELECT [Value]
  FROM tbl_SCRIPT_ENVIRONMENT_DETAILS
  WHERE script_name = 'SQL 2005 Perf Stats Script'
    AND [Name] = 'SQL Version (SP)'
ELSE
  SELECT '' AS [value]
  -- SELECT CONVERT (varchar, SERVERPROPERTY ('ProductVersion')) + ' (' + CONVERT (varchar, SERVERPROPERTY ('ProductLevel')) + ')' AS [value]
GO
