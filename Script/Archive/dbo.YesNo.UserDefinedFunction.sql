USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[YesNo]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[YesNo] 
(
	@YesNo int
)
RETURNS varchar(20)
AS
BEGIN
	IF @YesNo = 0
	  RETURN 'Nein'
	IF @YesNo = 1
	  RETURN 'Ja'
    RETURN ''
END
GO
