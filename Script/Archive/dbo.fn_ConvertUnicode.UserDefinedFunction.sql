USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_ConvertUnicode]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.07.2011
-- Description:	Wandelt 'K\u00F6ln' um in 'Köln' und '\u6700\u540E\u50AC\u6B3E\u901A\u77E5' in '最后催款通知'
-- =============================================
CREATE FUNCTION [dbo].[fn_ConvertUnicode]
(
  @InStr nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
  DECLARE @OutStr nvarchar(max)
   SELECT @OutStr = @InStr

   SELECT @OutStr = REPLACE(@OutStr,'\u'+LEFT([String],4),nchar(dbo.fn_HexToIntnt(LEFT([String],4)))) 
     FROM [DynNavHRS].[dbo].[Split] (@InStr,'\u')
    WHERE NOT dbo.fn_HexToIntnt(LEFT([String],4)) IS NULL

   RETURN @OutStr
END
GO
