USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[GetCIBTFilter]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 03.06.13
/*
SELECT dbo.GetCIBTFilter ('2631')
*/
-- Description:	
-- =============================================
CREATE FUNCTION [dbo].[GetCIBTFilter] (@VendorNo VARCHAR(20))
RETURNS varchar(max)
AS
BEGIN
DECLARE @AP AS TABLE([CIBT] int, [Rebate No_] varchar(20))
DECLARE @ActualCustomer int, @PreviousCustomer int, @FirstCustomer int
 SELECT @ActualCustomer = 0, @PreviousCustomer = 0, @FirstCustomer = 0
DECLARE @CustList varchar(max)
 SELECT @CustList = ''

INSERT INTO @AP
SELECT DISTINCT AP.[CIBT], @VendorNo
  FROM [HRS$Affiliate Partner Vendor] AV WITH (NOLOCK)
  JOIN [Affiliate Partner] AP WITH (NOLOCK)
    ON AP.[No_] = AV.[Affiliate Partner No_]
 WHERE @VendorNo = AV.[Vendor No_]
   AND AP.[CIBT] <> 0

DECLARE cur CURSOR FOR SELECT * FROM @AP ORDER BY 1

OPEN cur

FETCH NEXT FROM cur INTO @ActualCustomer, @VendorNo

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
  FETCH NEXT FROM cur INTO @ActualCustomer, @VendorNo
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
