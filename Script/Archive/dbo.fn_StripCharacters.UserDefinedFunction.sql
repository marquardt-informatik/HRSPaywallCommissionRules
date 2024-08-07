USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_StripCharacters]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_StripCharacters]
(
    @String NVARCHAR(1000), 
    @MatchExpression VARCHAR(255)
)
RETURNS VARCHAR(1000)
AS
BEGIN
    SET @MatchExpression =  '%['+@MatchExpression+']%'

    WHILE PatIndex(@MatchExpression, @String) > 0
        SET @String = Stuff(@String, PatIndex(@MatchExpression, @String), 1, '')

    RETURN @String

END
GO
