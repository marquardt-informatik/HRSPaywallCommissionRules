USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[DATEFROMPARTS]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Thomas Marquardt
-- Create date: 25.07.18
-- Description: Datum anhand übergebener Datumsbestandteile ermitteln
-- =============================================
CREATE FUNCTION [dbo].[DATEFROMPARTS] 
(
    @Year int = 0
  , @Month int = 0
  , @Day int = 0
)
RETURNS date
AS
BEGIN

	DECLARE @ResultVar date


	SET @ResultVar = RIGHT('0000'+CAST(@Year as varchar(4)),4)+'-'+RIGHT('0000'+CAST(@Month as varchar(2)),2)+'-'+RIGHT('0000'+CAST(@Day as varchar(2)),2)

	RETURN @ResultVar

END
GO
