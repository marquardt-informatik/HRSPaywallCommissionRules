USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[SQLFilter]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[SQLFilter] (@NavisionFilter varchar(2048), @NaisionField varchar(100), @DoubleQuotes int)
RETURNS varchar(4000)
AS
BEGIN
  DECLARE @SQL varchar(4000), @String varchar(2048), @POs int;
      SET @SQL = '';

  DECLARE cu CURSOR FAST_FORWARD FOR SELECT String FROM dbo.Split(@NavisionFilter, '|')
  OPEN CU
  FETCH NEXT FROM cu INTO @String

  WHILE @@FETCH_STATUS = 0
  BEGIN
    IF LEN(@SQL) > 0 
      SET @SQL = @SQL + ' OR '
    ELSE
      SET @SQL = '('

    SET @Pos = CHARINDEX('..', @String)
    IF @Pos > 0 
      IF @DoubleQuotes = 1 
        SET @SQL = @SQL + @NaisionField + ' BETWEEN ''''''' + LEFT(@STRING,@POS-1) + ''''''' AND ''''''' + RIGHT(@String, LEN(@String) - @Pos - 1) + ''''''''
      ELSE
        SET @SQL = @SQL + @NaisionField + ' BETWEEN ''' + LEFT(@STRING,@POS-1) + ''' AND ''' + RIGHT(@String, LEN(@String) - @Pos - 1) + ''''
    ELSE IF CHARINDEX('*', @String) > 0 OR CHARINDEX('?', @String) > 0
      IF @DoubleQuotes = 1 
        SET @SQL = @SQL + @NaisionField + ' LIKE ''''''' + REPLACE(REPLACE(@STRING,'*','%'),'?','_') + ''''''''
      ELSE
        SET @SQL = @SQL + @NaisionField + ' LIKE ''' + REPLACE(REPLACE(@STRING,'*','%'),'?','_') + '''' 
    ELSE
      IF @DoubleQuotes = 1 
        SET @SQL = @SQL + @NaisionField + ' = ''''''' + @STRING + ''''''''
      ELSE
        SET @SQL = @SQL + @NaisionField + ' = ''' + @STRING + ''''

    FETCH NEXT FROM cu INTO @String
  END CLOSE cu DEALLOCATE cu

  RETURN @SQL+')'
END


GO
