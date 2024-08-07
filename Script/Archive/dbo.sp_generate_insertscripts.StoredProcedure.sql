USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_generate_insertscripts]    Script Date: 10.04.2024 14:31:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_generate_insertscripts]
(
    @TABLE_NAME VARCHAR(MAX),
    @FILTER_CONDITION VARCHAR(MAX)=''
)
AS
BEGIN

SET NOCOUNT ON

DECLARE @CSV_COLUMN VARCHAR(MAX),
        @QUOTED_DATA VARCHAR(MAX),
        @TEXT VARCHAR(MAX)

SELECT @CSV_COLUMN=STUFF
(
    (
     SELECT ',['+ NAME +']' FROM sys.all_columns 
     WHERE OBJECT_ID=OBJECT_ID(@TABLE_NAME) AND NAME <> 'timestamp' AND 
     is_identity!=1 FOR XML PATH('')
    ),1,1,''
)

SELECT @QUOTED_DATA=STUFF
(
    (
     SELECT ' ISNULL(QUOTENAME('+@TABLE_NAME+'.['+NAME+'],'+QUOTENAME('''','''''')+'),'+'''NULL'''+')+'','''+'+' FROM sys.all_columns 
     WHERE OBJECT_ID=OBJECT_ID(@TABLE_NAME) AND NAME <> 'timestamp' AND 
     is_identity!=1 FOR XML PATH('')
    ),1,1,''
)

SELECT @TEXT='SELECT ''INSERT INTO '+@TABLE_NAME+'('+@CSV_COLUMN+')VALUES('''+'+'+SUBSTRING(@QUOTED_DATA,1,LEN(@QUOTED_DATA)-5)+'+'+''')'''+' Insert_Scripts FROM '+@TABLE_NAME + @FILTER_CONDITION

--SELECT @CSV_COLUMN AS CSV_COLUMN,@QUOTED_DATA AS QUOTED_DATA,@TEXT TEXT

PRINT SUBSTRING(@TEXT,1,8000)
PRINT SUBSTRING(@TEXT,8001,16000)
EXEC (@Text)
SET NOCOUNT OFF

END
GO
