USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[CorrectFromPattern]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CorrectFromPattern] (
    @StringToCheck varchar(max),
    @Pattern varchar(max),
    @AlternatePattern varchar(max),
    @ISOCode char(2)
)
RETURNS varchar(max)
AS
BEGIN
  DECLARE @ReturnValue varchar(max)=@StringToCheck
 
  -- Search for CC
  DECLARE @CountryISOPosition int
  DECLARE @CountryCCPosition int
  SET @CountryCCPosition = CHARINDEX('CC',@Pattern)
  SET @CountryISOPosition = CHARINDEX(@ISOCode,@Pattern)
  IF (@CountryISOPosition=0) AND (@CountryCCPosition>0)
  BEGIN
    -- Correct Missing ISOCode
    SET @ReturnValue = @ISOCode+@StringToCheck
  END

  RETURN @ReturnValue
END
GO
