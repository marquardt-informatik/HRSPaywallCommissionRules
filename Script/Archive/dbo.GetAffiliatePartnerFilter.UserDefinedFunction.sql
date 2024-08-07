USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[GetAffiliatePartnerFilter]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 03.06.13
/*
SELECT dbo.GetAffiliatePartnerFilter ('K0000000712')
*/
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[GetAffiliatePartnerFilter] (@RebateNo VARCHAR(20))
RETURNS varchar(max)
AS
BEGIN
DECLARE @AP AS TABLE([Affiliate Partner No_] int, [Rebate No_] varchar(20))
DECLARE @ActualCustomer int, @PreviousCustomer int, @FirstCustomer int
 SELECT @ActualCustomer = 0, @PreviousCustomer = 0, @FirstCustomer = 0
DECLARE @CustList varchar(max)
 SELECT @CustList = ''

INSERT INTO @AP
SELECT AV.[Affiliate Partner No_], @RebateNo
  FROM [HRS$Affiliate Partner Vendor] AV WITH (NOLOCK)
 WHERE @RebateNo = AV.[Vendor No_]

DECLARE cur CURSOR FOR SELECT * FROM @AP ORDER BY 1

OPEN cur

FETCH NEXT FROM cur INTO @ActualCustomer, @RebateNo

SELECT @FirstCustomer = @ActualCustomer

WHILE @@FETCH_STATUS = 0
BEGIN
  IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
    IF (@PreviousCustomer<> 0) BEGIN
      SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
      SET @CustList = @CustList 
                    + CASE WHEN @PreviousCustomer = @FirstCustomer THEN 
                        CAST(@PreviousCustomer AS varchar)
                      ELSE
                        CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                      END
      SELECT @FirstCustomer = @ActualCustomer
    END 
  END
  
  SELECT @PreviousCustomer = @ActualCustomer
  FETCH NEXT FROM cur INTO @ActualCustomer, @RebateNo
END

IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
  IF (@PreviousCustomer<> 0) BEGIN
    SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
    SET @CustList = @CustList 
                  + CASE WHEN @PreviousCustomer = @FirstCustomer THEN 
                      CAST(@PreviousCustomer AS varchar)
                    ELSE
                      CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                    END
    SELECT @FirstCustomer = @ActualCustomer
  END 
END

CLOSE cur
DEALLOCATE cur

RETURN @CustList
END
GO
