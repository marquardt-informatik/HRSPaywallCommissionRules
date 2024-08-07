USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Split]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt	
-- Create date: 21.07.2011
-- Description:	Änderungen in der Tabelle [Label Translation] werden in das Unicode-Pendant geschrieben
/*
DECLARE @StringToSplit varchar(max) = '\u041F EUR\u043E\u0436\u0430\u043B\u0443\u0439\u0441\u0442\u0430, \u043E\u0431\u0440\u0430\u0442\u0438\u0442\u0435 \u0432\u043D\u0438\u043C\u0430\u043D\u0438\u0435, \u0447\u0442\u043E \u0442\u0435\u043A\u0443\u0449\u0438\u0435, \u0430 \u0442\u0430\u043A\u0436\u0435 \u0432\u044B\u043F\u043E\u043B\u043D\u0435\u043D\u043D\u044B\u0435 \u0431\u0440\u043E\u043D\u0438\u0440\u043E\u0432\u0430\u043D\u0438\u044F, \u043E\u0441\u0442\u0430\u044E\u0442\u0441\u044F \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043B\u044C\u043D\u044B\u043C\u0438\u0432 \u0441\u043E\u043E\u0442\u0432\u0435\u0442\u0441\u0442\u0432\u0438\u0438 \u0441 \u041E\u0431\u0449\u0438\u043C\u0438 \u043A\u043E\u043C\u043C\u0435\u0440\u0447\u0435\u0441\u043A\u0438\u043C\u0438 \u0443\u0441\u043B\u043E\u0432\u0438\u044F\u043C\u0438.\u041D\u0435\u043E\u043F\u043B\u0430\u0447\u0435\u043D\u043D\u0430\u044F \u0441\u0443\u043C\u043C\u0430, \u0432\u043A\u043B\u044E\u0447\u0430\u044E\u0449\u0430\u044F \u0448\u0442\u0440\u0430\u0444 \u0437\u0430 \u043F\u0440\u043E\u0441\u0440\u043E\u0447\u043A\u0443 \u043F\u043B\u0430\u0442\u0435\u0436\u0430, \u0441\u043E\u0441\u0442\u0430\u0432\u043B\u044F\u0435\u0442 4.466,57 EUR.'
DECLARE @Separator varchar(128) = '\u'
EXEC [dbo].[sp_Split] @StringToSplit, @Separator
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_Split]
    @StringToSplit  varchar(max)
  , @Separator varchar(128)
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @E int = 1, @S int = 0
DECLARE @Result TABLE ([String] varchar(max))
PRINT CHARINDEX(@Separator, @StringToSplit, @E)

WHILE CHARINDEX(@Separator, @StringToSplit, @E+1) > 0
BEGIN
  SELECT @S = @E
  SELECT @E = CHARINDEX(@Separator, @StringToSplit, @E+1)
  INSERT INTO @Result 
  VALUES(SUBSTRING(@StringToSplit
                 , @S+LEN(@Separator)
                 , CASE WHEN (@E-@S) > len(@Separator) THEN
                     @E-@S-len(@Separator)
                   ELSE 
                     LEN(@StringToSplit) - @S + 1 
                   END
                   )
         )
END
  SELECT @S = @E
  SELECT @E = CHARINDEX(@Separator, @StringToSplit, @E+1) 
  INSERT INTO @Result 
  VALUES(SUBSTRING(@StringToSplit
                 , @S+LEN(@Separator)
                 , CASE WHEN (@E-@S) > len(@Separator) THEN
                     @E-@S-len(@Separator)
                   ELSE 
                     LEN(@StringToSplit) - @S + 1 
                   END
                   )
         )

  SELECT * FROM @Result
END
GO
