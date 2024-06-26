USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[CheckPatternMatchProc]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CheckPatternMatchProc] 
--ALTER FUNCTION dbo.CheckPatternMatch (
    @StringToCheck varchar(max),
    @Pattern varchar(max),
    @AlternatePattern varchar(max),
    @ISOCode char(2)
--)
--RETURNS integer
AS
BEGIN
    DECLARE @Result integer = 0;
    DECLARE @i int;
    DECLARE @j int;
    DECLARE @lenPattern int;
    DECLARE @lenString int;
    DECLARE @pchar char(1);
    DECLARE @schar char(1);
    DECLARE @optionalChars varchar(max);
    DECLARE @endBracketIndex int;

    -- Check for special case: "- NO CODES -"
    IF @Pattern = '- NO CODES -'
    BEGIN
        IF LEN(@StringToCheck) > 0
            SET @Result = 0;
    END
    ELSE
    BEGIN
        -- Replace "CC" with the ISO code
        SET @Pattern = REPLACE(@Pattern, 'CC', @ISOCode);

        SET @i = 1;
        SET @j = 1;
        SET @lenPattern = LEN(@Pattern);
        SET @lenString = LEN(@StringToCheck);

        WHILE @i <= @lenPattern AND @j <= @lenString
        BEGIN
            SET @pchar = SUBSTRING(@Pattern, @i, 1);
            SET @schar = SUBSTRING(@StringToCheck, @j, 1);

            IF @pchar = '['
            BEGIN
                SET @endBracketIndex = CHARINDEX(']', @Pattern, @i);
                IF @endBracketIndex = 0
                BEGIN
                    -- Invalid pattern, missing closing bracket
                    SET @Result = 0;
                    BREAK;
                END

                SET @optionalChars = SUBSTRING(@Pattern, @i + 1, @endBracketIndex - @i - 1);

                IF NOT (@optionalChars LIKE '%' + @schar + '%') AND NOT @schar = ''
                BEGIN
                    -- Character mismatch in optional pattern
                    SET @Result = 0;
                    BREAK;
                END

                SET @i = @endBracketIndex;
            END
            ELSE
            BEGIN
                IF @pchar = @schar 
                   OR (@pchar = '?' AND (@schar LIKE '[A-Z]' OR @schar LIKE '[0-9]'))
                   OR (@pchar = 'N' AND @schar LIKE '[0-9]')
                   OR (@pchar = 'A' AND @schar LIKE '[A-Z]')
                BEGIN
                    SET @i = @i + 1;
                END
                ELSE
                BEGIN
                    -- Character mismatch
                    SET @Result = 0;
                    BREAK;
                END
            END

            SET @j = @j + 1;
        END

        IF @i > @lenPattern AND @j > @lenString
            SET @Result = 1;
    END

    -- If the primary pattern doesn't match, check against the alternate pattern
    IF @Result = 0
    BEGIN
        SET @Result = 1
        -- Replace "CC" with the ISO code in the alternate pattern
        SET @AlternatePattern = REPLACE(@AlternatePattern, 'CC', @ISOCode);

        SET @i = 1;
        SET @j = 1;
        SET @lenPattern = LEN(@AlternatePattern);
        SET @lenString = LEN(@StringToCheck);

        WHILE @i <= @lenPattern AND @j <= @lenString
        BEGIN
            SET @pchar = SUBSTRING(@AlternatePattern, @i, 1);
            SET @schar = SUBSTRING(@StringToCheck, @j, 1);

            IF @pchar = '['
            BEGIN
                SET @endBracketIndex = CHARINDEX(']', @AlternatePattern, @i);
                IF @endBracketIndex = 0
                BEGIN
                    -- Invalid pattern, missing closing bracket
                    SET @Result = 0;
                    BREAK;
                END

                SET @optionalChars = SUBSTRING(@AlternatePattern, @i + 1, @endBracketIndex - @i - 1);

                IF NOT (@optionalChars LIKE '%' + @schar + '%') AND NOT @schar = ''
                BEGIN
                    PRINT @i
                    PRINT '@AlternatePattern : ' + @AlternatePattern + ', @StringToCheck : ' + @StringToCheck
                    PRINT '@optionalChars : ' + @optionalChars + ', @schar : ' + @schar
                    -- Character mismatch in optional pattern
                    SET @Result = 0;
                    BREAK;
                END

                SET @i = @endBracketIndex;
            END
            ELSE
            BEGIN
                IF @pchar = @schar 
                   OR (@pchar = '?' AND (@schar LIKE '[A-Z]' OR @schar LIKE '[0-9]'))
                   OR (@pchar = 'N' AND @schar LIKE '[0-9]')
                   OR (@pchar = 'A' AND @schar LIKE '[A-Z]')
                BEGIN
                    SET @i = @i + 1;
                END
                ELSE
                BEGIN
                    --PRINT '@pchar : ' + @pchar + ', @schar : ' + @schar
                    -- Character mismatch
                    SET @Result = 0;
                    BREAK;
                END
            END

            SET @j = @j + 1;
        END

        IF @i > @lenPattern AND @j > @lenString
            SET @Result = 1;
    END
    PRINT @Result
    RETURN @Result;
END
GO
