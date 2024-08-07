USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_FormatNumber]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 11.06.18
-- Description:	Datumsformatierung anhanf Formatierungsstring
/*
DECLARE
    @value decimal(37,20) = 123456.78
  , @DecimalSeparator varchar(50) = ','
  , @GroupSeparator varchar(50) = '.'
  , @GroupSize int = 3
  , @NumberyDecimalDigits int = 2
SELECT dbo.fnc_FormatNumber(
    @value
  , @DecimalSeparator
  , @GroupSeparator
  , @GroupSize
  , @NumberyDecimalDigits
)   
*/
-- =============================================
CREATE FUNCTION [dbo].[fnc_FormatNumber](
    @value decimal(37,20)
  , @DecimalSeparator varchar(50)
  , @GroupSeparator varchar(50)
  , @GroupSize int
  , @NumberyDecimalDigits int
)
RETURNS nvarchar(50)
AS
BEGIN
  DECLARE @String nvarchar(50), @Result nvarchar(50)='', @remainder varchar(50)
  SELECT @String = CAST(@value AS nvarchar(50))
 
  DECLARE @intString nvarchar(50)
  SELECT @intString = @String
  IF CHARINDEX('.',@String)>0
    SELECT @intString = LEFT(@String,CHARINDEX('.',@String)-1)

  SELECT @remainder = ''
  IF CHARINDEX('.',@String)>0
    SELECT @remainder = LEFT(SUBSTRING(@String,CHARINDEX('.',@String)+1,LEN(@String)-CHARINDEX('.',@String)),@NumberyDecimalDigits)

  SELECT @String = @intString
  WHILE LEN(@String)>0
  BEGIN
    IF LEN(@String)>@GroupSize
      SELECT @Result = @GroupSeparator + RIGHT(@String,@GroupSize) + @Result
    ELSE
      SELECT @Result = @String + @Result

    IF LEN(@String)>=@GroupSize
      SELECT @String = LEFT(@String,LEN(@String)-@GroupSize)
	ELSE
      SELECT @String = ''

  END
  SELECT @Result = @Result + @DecimalSeparator + @remainder
  
  RETURN @Result
END
GO
