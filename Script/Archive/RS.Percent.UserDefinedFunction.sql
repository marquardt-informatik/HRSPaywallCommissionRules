USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [RS].[Percent]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =============================================
Author:			MMC Management Solutions GmbH
Create date:	07.07.2011
Description:	Created: Percent calulation for stored procedure "CommissionSales"
============================================= */
CREATE FUNCTION [RS].[Percent](
	@Value1		DECIMAL(38,20),
	@Value2		DECIMAL(38,20)
)
RETURNS DECIMAL(38,20) AS BEGIN
DECLARE @RET	DECIMAL(38,20)

	SET @RET = CASE @Value2
		WHEN 0 THEN 0
		ELSE @Value1 / @Value2 * 100
	END

	RETURN @RET
END

GO
