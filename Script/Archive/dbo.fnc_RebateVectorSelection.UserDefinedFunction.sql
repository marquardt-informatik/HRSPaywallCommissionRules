USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[fnc_RebateVectorSelection]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 11.04.2013
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[fnc_RebateVectorSelection] 
(
    @RebateVector varchar(20)
  , @Value decimal(37,20)
)
RETURNS varchar(250)
AS
BEGIN
  DECLARE @ResultVar varchar(250)
  
  SELECT @ResultVar = VR.[Description]
    FROM [HRS$Rebate Vector Ranges] VR
   WHERE VR.[Vector Code] = @RebateVector
     AND @Value BETWEEN [Value From (Decimal)] AND [Value To (Decimal)]

  RETURN @ResultVar
END
GO
