USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[usp_CalcCommission ACS-1986]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================================================================
-- Author:		Thomas Marquardt
-- Create date: 31.08.2015
-- Description:	Transfer Meetago-Reservation into HRSDB.BUCHUNG and HRSDB.BUCHTEIL
--
-- Date       | Version |  Ticket  | Sign | Description
-- -----------+---------+----------+------+----------------------------------------------------------
-- 07.09.2016 | HRS001  | NAV-240  |  TM  | Change "= 20025" to " IN (20025,25021,25022,25023,25024)"
-- 29.03.2019 | HRS002  | ACS-1741 |  TM  | Boolean @BreakfastCommission : 0=don't calculate commission on breakfast, 1=calculate commission on breakfast regarding commission rule
/*
DECLARE 
    @CalculatedwithFunctionID VARCHAR(10) = '10'
  , @ForeignTaxPercent        DECIMAL(37,20) = 18.0
  , @BreakfastTaxPercent      DECIMAL(37,20) = 0.0
  , @NumberofNights           DECIMAL(38,20) = 3
  , @NumberofRooms            DECIMAL(37,20) = 1
  , @NumberofPerson           DECIMAL(37,20) = 1
  , @RoomPrice                DECIMAL(37,20) = 9999.00
  , @BreakfastPrice           DECIMAL(37,20) = 0.0
  , @ExchangeRate             DECIMAL(37,20) = 78.27273
  , @RateType                 INTEGER = 20020
  , @PriceType                INTEGER = 0
  , @BreakfastType            INTEGER = 0
  , @NetRoomPrice             DECIMAL(37,20) = 9999.00
  , @UseNetRoomPrice          TINYINT = 0
  , @NetBreakfastPrice        DECIMAL(37,20) = 0.0
  , @ForeignTaxBaseAmount     DECIMAL(37,20) 
  , @CommissionRate           DECIMAL(37,20) 
  , @CommissionFix            DECIMAL(37,20) 
  , @ForeignTaxAmount         DECIMAL(37,20) 
  , @CommissionBaseAmount     DECIMAL(38,20) 
  , @CommissionAmount         DECIMAL(37,20) 
  , @LineAmount               DECIMAL(37,20) 
  , @HotelsalesinclVAT        DECIMAL(37,20) 
  , @BreakfastCommission      TINYINT = 0
  , @Debug                    INT = 1

    EXEC dbo.usp_CalcCommission 
      @ContractCalcFunctionCode 
    , @ForeignTaxPercent
    , @BreakfastTaxPercent
    , @NumberofNights
    , @NumberofRooms
    , @NumberofPerson
    , @RoomPrice
    , @BreakfastPrice
    , @CommissionFixExchangeRate
    , @RateType
    , @PriceType
    , @BreakfastType 
    , @NetRoomPrice
    , @UseNetRoomPrice
    , @NetBreakfastPrice
    , @ForeignTaxBaseAmountOUT OUTPUT
    , @NewCommissionRate       OUTPUT
    , @CommissionFix           OUTPUT
    , @ForeignTaxAmountOUT     OUTPUT
    , @CommissionBaseAmountOUT OUTPUT
    , @CommissionAmountOUT     OUTPUT
    , @LineAmountOUT           OUTPUT
    , @HotelsalesinclVATOUT    OUTPUT
	, @BreakfastCommission
    , @Debug                    
*/
CREATE PROCEDURE [dbo].[usp_CalcCommission ACS-1986]
    @CalculatedwithFunctionID VARCHAR(10)
  , @ForeignTaxPercent        DECIMAL(37,20)
  , @BreakfastTaxPercent      DECIMAL(37,20)
  , @NumberofNights           DECIMAL(38,20)
  , @NumberofRooms            DECIMAL(37,20) 
  , @NumberofPerson           DECIMAL(37,20)
  , @RoomPrice                DECIMAL(37,20) 
  , @BreakfastPrice           DECIMAL(37,20)
  , @ExchangeRate             DECIMAL(37,20)
  , @RateType                 INTEGER
  , @PriceType                INTEGER
  , @BreakfastType            INTEGER
  , @NetRoomPrice             DECIMAL(37,20) OUTPUT
  , @UseNetRoomPrice          TINYINT
  , @NetBreakfastPrice        DECIMAL(37,20) OUTPUT
  , @ForeignTaxBaseAmount     DECIMAL(37,20) OUTPUT
  , @CommissionRate           DECIMAL(37,20) OUTPUT
  , @CommissionFix            DECIMAL(37,20) OUTPUT
  , @ForeignTaxAmount         DECIMAL(37,20) OUTPUT 
  , @CommissionBaseAmount     DECIMAL(38,20) OUTPUT
  , @CommissionAmount         DECIMAL(37,20) OUTPUT
  , @LineAmount               DECIMAL(37,20) OUTPUT
  , @HotelsalesinclVAT        DECIMAL(37,20) OUTPUT
  , @BreakfastCommission      TINYINT = 0
  , @Debug                    INT = 0
AS
  --DECLARE @Debug int=0
  
  IF @BreakfastTaxPercent = 0 
    SET @BreakfastTaxPercent = @ForeignTaxPercent

  IF @NetRoomPrice = 0
    SET @UseNetRoomPrice = 0

  IF @UseNetRoomPrice = 1
  BEGIN
    --
    -- SDA03 : GrossCountries sollen weiterhin sichtbar sein aber mit Amount before Tax abgerechnet werden
    --
    IF @NetRoomPrice>@RoomPrice AND @RoomPrice>0
      SET @NetRoomPrice = @RoomPrice
	IF @NetRoomPrice<@RoomPrice AND @RoomPrice<0
      SET @NetRoomPrice = @RoomPrice
    IF @NetRoomPrice<>0 AND @CalculatedwithFunctionID=4
      SET @CalculatedwithFunctionID=8
    IF @BreakfastType=1
      BEGIN
        IF @NetBreakfastPrice=0 
          SET @NetBreakfastPrice = @BreakfastPrice * @BreakfastCommission -- ASC-1741
-- 02.09.16 : Bei Paketraten Frühstück trotzdem mit der Anzahl Nächte multiplizieren
-- Original       SELECT @ForeignTaxBaseAmount   = (@NumberofRooms * @NetRoomPrice) + (@NumberofRooms * @NumberofPerson * @NetBreakfastPrice)
        SELECT @ForeignTaxBaseAmount   = 
		 CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
           (@NumberofRooms * @NetRoomPrice) + (@NumberofRooms * @NumberofPerson * @NetBreakfastPrice * @NumberofNights * @BreakfastCommission) -- ASC-1741
         ELSE
           (@NumberofRooms * @NetRoomPrice) + (@NumberofRooms * @NumberofPerson * @NetBreakfastPrice * @BreakfastCommission) -- ASC-1741
         END
-- 02.09.16 Ende
        SELECT @CommissionBaseAmount   = @ForeignTaxBaseAmount
        SELECT @ForeignTaxAmount       = (@NumberofRooms * @RoomPrice) + (@NumberofRooms * @NumberofPerson * @BreakfastPrice * @BreakfastCommission) - @ForeignTaxBaseAmount -- ASC-1741
        SELECT @ForeignTaxPercent      = CASE WHEN @ForeignTaxBaseAmount = 0 THEN 0 ELSE ROUND(@RoomPrice / CASE WHEN @NetRoomPrice = 0 THEN CASE WHEN @RoomPrice=0 THEN 1 ELSE @RoomPrice END ELSE @NetRoomPrice END -1,2) * 100. END
      END
    IF @BreakfastType<>1
      BEGIN
        SELECT @ForeignTaxBaseAmount   = (@NumberofRooms * @NetRoomPrice)
        SELECT @CommissionBaseAmount   = @ForeignTaxBaseAmount
        SELECT @ForeignTaxAmount       = (@NumberofRooms * @RoomPrice) - @ForeignTaxBaseAmount
        SELECT @ForeignTaxPercent      = CASE WHEN @ForeignTaxBaseAmount = 0 THEN 0 ELSE ROUND(@RoomPrice / CASE WHEN @NetRoomPrice = 0 THEN CASE WHEN @RoomPrice=0 THEN 1 ELSE @RoomPrice END ELSE @NetRoomPrice END -1,2) * 100. END

      END
      
    SELECT @CommissionBaseAmount 
       = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
           @ForeignTaxBaseAmount / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
         ELSE
           @ForeignTaxBaseAmount
         END
  END


  	
  IF @UseNetRoomPrice = 0
  BEGIN
    SELECT @ForeignTaxBaseAmount   = (@NumberofRooms * @RoomPrice)
    SELECT @CommissionBaseAmount = @ForeignTaxBaseAmount

    IF @NetRoomPrice = 0
	 SELECT @NetRoomPrice = @RoomPrice / (100.0 + @ForeignTaxPercent) * 100.0
    IF @NetBreakfastPrice = 0
	 SELECT @NetBreakfastPrice = @BreakfastPrice / (100.0 + @BreakfastTaxPercent) * 100.0
  
    IF @BreakfastType=1
    BEGIN      
-- 02.09.16 : Bei Paketraten Frühstück trotzdem mit der Anzahl Nächte multiplizieren
-- Original       SELECT @ForeignTaxBaseAmount   = (@NumberofRooms * @RoomPrice) + (@NumberofRooms * @NumberofPerson * @BreakfastPrice)
        SELECT @ForeignTaxBaseAmount   = 
		 CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
           (@NumberofRooms * @RoomPrice) + (@NumberofRooms * @NumberofPerson * @BreakfastPrice * @NumberofNights * @BreakfastCommission) -- ASC-1741
         ELSE
           (@NumberofRooms * @RoomPrice) + (@NumberofRooms * @NumberofPerson * @BreakfastPrice * @BreakfastCommission) -- ASC-1741
         END
-- 02.09.16 Ende

    END
  
    SELECT @ForeignTaxAmount = @NumberofRooms * @RoomPrice * @ForeignTaxPercent / 100. 
	                        +  @NumberofRooms * @NumberofPerson * @BreakfastPrice * @BreakfastTaxPercent * @BreakfastCommission / 100. -- ASC-1741
    SELECT @CommissionBaseAmount 
           = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
               @ForeignTaxBaseAmount / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
             ELSE
               @ForeignTaxBaseAmount
             END
  END
  
  BEGIN TRY
  -- Percent
  IF @CalculatedwithFunctionID=1
  BEGIN
    IF @Debug<>0 PRINT 'Percent'
	SELECT @ForeignTaxBaseAmount   = (@NumberofRooms * @RoomPrice)
	SELECT @CommissionBaseAmount 
	         = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	             @ForeignTaxBaseAmount / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	           ELSE
	             @ForeignTaxBaseAmount
	           END
	SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100.
	SELECT @LineAmount        = @CommissionAmount * @NumberofNights
  END
  
  -- Fix
  IF @CalculatedwithFunctionID=2
  BEGIN
    IF @Debug<>0 PRINT 'Fix'
	SELECT @CommissionAmount     = @CommissionFix	
	SELECT @LineAmount           = @CommissionAmount
  END

  -- Percent + Fix
  IF @CalculatedwithFunctionID=3
  BEGIN
    IF @Debug<>0 PRINT 'Percent + Fix'
    SELECT @ForeignTaxBaseAmount   = (@NumberofRooms * @RoomPrice)
	SELECT @CommissionBaseAmount 
	         = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	             @ForeignTaxBaseAmount / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	           ELSE
	             @ForeignTaxBaseAmount
	           END
	SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100. + @CommissionFix
	SELECT @LineAmount        = @CommissionAmount * @NumberofNights
  END
  
  -- Percent w/o Breakfast
  IF @CalculatedwithFunctionID=4
  BEGIN
    IF @Debug<>0 PRINT 'Percent w/o Breakfast'
    SELECT @CommissionBaseAmount = @NumberofRooms * @RoomPrice
	SELECT @CommissionAmount 
	         = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	             @CommissionBaseAmount * @CommissionRate / 100. / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	           ELSE
	             @CommissionBaseAmount * @CommissionRate / 100.
	           END
	SELECT @LineAmount        = @CommissionAmount * @NumberofNights
  END
  
  -- Percent w/o Breakfast + Fix
  IF @CalculatedwithFunctionID=5
  BEGIN
    IF @Debug<>0 PRINT 'Percent w/o Breakfast + Fix'
    SELECT @CommissionBaseAmount = @NumberofRooms * @RoomPrice
	SELECT @CommissionAmount 
	         = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	             @CommissionBaseAmount * @CommissionRate / 100. / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	           ELSE
	             @CommissionBaseAmount * @CommissionRate / 100.
	           END + @CommissionFix
	SELECT @LineAmount        = @CommissionAmount * @NumberofNights
  END
  
  -- Online
  IF @CalculatedwithFunctionID=6
  BEGIN
    IF @Debug<>0 PRINT 'Online'
    SELECT @CommissionBaseAmount = 0
    SELECT @CommissionAmount     = @CommissionFix
    SELECT @LineAmount           = @CommissionAmount
  END
  
  -- Additional provision
  IF @CalculatedwithFunctionID=7
  BEGIN
    IF @Debug<>0 PRINT 'Additional provision'
    SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100.
    SELECT @LineAmount        = @CommissionAmount
  END
  
  -- Percent net lodging
  IF @CalculatedwithFunctionID=8
  BEGIN
    SET @UseNetRoomPrice  = COALESCE(@UseNetRoomPrice,1)
    IF @UseNetRoomPrice = 0
    BEGIN
	  SELECT @CommissionBaseAmount 
	           = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	               @ForeignTaxBaseAmount / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	             ELSE
  	               @ForeignTaxBaseAmount
	             END
      IF @BreakfastType=0
      BEGIN
        SELECT @ForeignTaxAmount   = (@ForeignTaxPercent * @NumberofRooms * @RoomPrice) / (100 + CASE WHEN @ForeignTaxPercent=-100. THEN 0. ELSE @ForeignTaxPercent END)
		                           + (@BreakfastTaxPercent * @NumberofRooms * @NumberofPerson * @BreakfastPrice * @BreakfastCommission) / (100 + CASE WHEN @BreakfastTaxPercent=-100. THEN 0. ELSE @BreakfastTaxPercent END) -- ASC-1741
        SELECT @CommissionBaseAmount = (@ForeignTaxBaseAmount - @ForeignTaxAmount)
		                             / CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	                                     CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	                                   ELSE
  	                                     1
	                                   END
      END
      IF @BreakfastType=1
      BEGIN
        SELECT @ForeignTaxAmount   = (@ForeignTaxPercent * (@ForeignTaxBaseAmount-@NumberofRooms*@BreakfastPrice * @NumberofPerson * @BreakfastCommission))  / (100 + CASE WHEN @ForeignTaxPercent=-100. THEN 0. ELSE @ForeignTaxPercent END) -- ASC-1741
        SELECT @CommissionBaseAmount = (@ForeignTaxBaseAmount-@NumberofRooms*@BreakfastPrice * @NumberofPerson * @BreakfastCommission) - (@ForeignTaxPercent * (@ForeignTaxBaseAmount-@NumberofRooms*@BreakfastPrice * @NumberofPerson * @BreakfastCommission)) / (100 + CASE WHEN @ForeignTaxPercent=-100. THEN 0. ELSE @ForeignTaxPercent END) -- ASC-1741
		                             / CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	                                     CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	                                   ELSE
  	                                     1
	                                   END
      END
      SELECT @CommissionAmount     = @CommissionBaseAmount * @CommissionRate / 100.
  	  SELECT @LineAmount           = @CommissionAmount     * @NumberofNights
  	END
    IF @UseNetRoomPrice = 1
  	BEGIN
      IF @BreakfastType=1
      BEGIN
        SELECT @ForeignTaxAmount   = (@ForeignTaxPercent * @ForeignTaxBaseAmount)  / (100. + CASE WHEN @ForeignTaxPercent=-100. THEN 0. ELSE @ForeignTaxPercent END)
        SELECT @CommissionBaseAmount = @ForeignTaxBaseAmount - @NumberofRooms*@BreakfastPrice * @NumberofPerson * @BreakfastCommission -- ASC-1741
      END
      SELECT @CommissionAmount     = @CommissionBaseAmount * @CommissionRate / 100.
  	  SELECT @LineAmount           = @CommissionAmount     * @NumberofNights
  	END
  	 	
  END
  
  -- Percent net lodging + Breakf
  IF @CalculatedwithFunctionID=9
  BEGIN
    IF @Debug<>0 PRINT 'Percent net lodging + Breakf'
    SET @UseNetRoomPrice  = COALESCE(@UseNetRoomPrice,1)
	IF @UseNetRoomPrice = 0
    BEGIN
      SELECT @ForeignTaxAmount   = (@ForeignTaxPercent * @ForeignTaxBaseAmount) / (100 + CASE WHEN @ForeignTaxPercent=-100. THEN 0. ELSE @ForeignTaxPercent END)  
  	  SELECT @CommissionBaseAmount 
	           = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	               (@ForeignTaxBaseAmount - @ForeignTaxAmount) / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	             ELSE
	               (@ForeignTaxBaseAmount - @ForeignTaxAmount)
	             END
	  SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100.
	  SELECT @LineAmount        = @CommissionAmount     * @NumberofNights
	END
    IF @UseNetRoomPrice = 1
    BEGIN
	  SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100.
	  SELECT @LineAmount        = @CommissionAmount     * @NumberofNights
	END
  END
  
  --Percent net sales
  IF @CalculatedwithFunctionID=10
  BEGIN
    IF @Debug<>0 PRINT 'Percent net sales'
    SET @UseNetRoomPrice  = COALESCE(@UseNetRoomPrice,1)
    IF @UseNetRoomPrice = 0
    BEGIN
    SELECT @ForeignTaxAmount = (@ForeignTaxPercent * @ForeignTaxBaseAmount) / (100 + CASE WHEN @ForeignTaxPercent=-100. THEN 0. ELSE @ForeignTaxPercent END)
	SELECT @CommissionBaseAmount 
	         = CASE WHEN @RateType IN (20025,25021,25022,25023,25024) AND @PriceType = 2 THEN 
	             (@ForeignTaxBaseAmount - @ForeignTaxAmount) / CASE WHEN @NumberofNights = 0 THEN 1 ELSE @NumberofNights END
	           ELSE
	             (@ForeignTaxBaseAmount - @ForeignTaxAmount)
	           END
  	  SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100.
	  SELECT @LineAmount        = @CommissionAmount     * @NumberofNights
	END
    IF @UseNetRoomPrice = 1
    BEGIN
  	  SELECT @CommissionAmount  = @CommissionBaseAmount * @CommissionRate / 100.
	  SELECT @LineAmount        = @CommissionAmount     * @NumberofNights
	END
  END

  -- Fix per Roomnight
  IF @CalculatedwithFunctionID=11
  BEGIN
    IF @Debug<>0 PRINT 'Fix per Roomnight'
    SELECT @CommissionFix     = @CommissionFix -- CASE WHEN @ExchangeRate=0 THEN 1 ELSE @ExchangeRate END
    SELECT @CommissionAmount  = @CommissionFix        * @NumberofRooms
	SELECT @LineAmount        = @CommissionAmount     * @NumberofNights
  END

  -- NonCommissionable
  IF @CalculatedwithFunctionID = 12
  BEGIN
    IF @Debug<>0 PRINT 'NonCommissionable'
    SELECT @CommissionAmount     = 0
    SELECT @CommissionRate       = 0
    SELECT @LineAmount           = 0
  END
END TRY
BEGIN CATCH
  SET @Debug = 1
END CATCH
  
  SELECT @HotelsalesinclVAT    = ROUND(@ForeignTaxBaseAmount,2) -- ROUND(@ForeignTaxAmount,2)

    IF @Debug<>0 
    BEGIN
      PRINT '-------------------'
      PRINT '@UseNetRoomPrice           = ' + CASE WHEN @UseNetRoomPrice = 0 THEN '0' ELSE '1' END
      PRINT '@BreakfastType             = ' + CASE WHEN @BreakfastType = 0   THEN '0' ELSE '1' END
      PRINT '@ForeignTaxPercent         = ' + COALESCE(CAST(@ForeignTaxPercent as varchar(max)),'<null>')
      PRINT '@ForeignTaxBaseAmount      = ' + COALESCE(CAST(@ForeignTaxBaseAmount as varchar(max)),'<null>')
      PRINT '@ForeignTaxAmount          = ' + COALESCE(CAST(@ForeignTaxAmount as varchar(max)),'<null>')
      PRINT '@NumberofRooms             = ' + COALESCE(CAST(@NumberofRooms as varchar(max)),'<null>')
	  PRINT '@RoomPrice                 = ' + COALESCE(CAST(@RoomPrice as varchar(max)),'<null>')
      PRINT '@BreakfastPrice            = ' + COALESCE(CAST(@BreakfastPrice as varchar(max)),'<null>')
      PRINT '@NumberofPerson            = ' + COALESCE(CAST(@NumberofPerson as varchar(max)),'<null>')
      PRINT '@CommissionBaseAmount      = ' + COALESCE(CAST(@CommissionBaseAmount as varchar(max)),'<null>')
      PRINT '@CommissionAmount          = ' + COALESCE(CAST(@CommissionAmount as varchar(max)),'<null>')
      PRINT '@CommissionRate            = ' + COALESCE(CAST(@CommissionRate as varchar(max)),'<null>')
      PRINT '@LineAmount                = ' + COALESCE(CAST(@LineAmount as varchar(max)),'<null>')
      PRINT '@NetRoomPrice              = ' + COALESCE(CAST(@NetRoomPrice as varchar(max)),'<null>')
	  PRINT '@RateType                  = ' + COALESCE(CAST(@RateType as varchar(max)),'<null>')
	  PRINT '@CalculatedwithFunctionID  = ' + COALESCE(CAST(@CalculatedwithFunctionID as varchar(max)),'<null>')
	  PRINT '@NumberOfNights            = ' + COALESCE(CAST(@NumberOfNights as varchar(max)),'<null>')
	  PRINT '@ExchangeRate              = ' + COALESCE(CAST(@ExchangeRate as varchar(max)),'<null>')
	  PRINT ''
	  PRINT 'OUTPUT'
	  PRINT '-------------------'
	  PRINT '@ForeignTaxBaseAmount      = ' + COALESCE(CAST(@ForeignTaxBaseAmount as varchar(max)),'<null>')
	  PRINT '@CommissionRate            = ' + COALESCE(CAST(@CommissionRate as varchar(max)),'<null>')
	  PRINT '@CommissionFix             = ' + COALESCE(CAST(@CommissionFix as varchar(max)),'<null>')
	  PRINT '@ForeignTaxAmount          = ' + COALESCE(CAST(@ForeignTaxAmount as varchar(max)),'<null>')
	  PRINT '@CommissionBaseAmount      = ' + COALESCE(CAST(@CommissionBaseAmount as varchar(max)),'<null>')
	  PRINT '@CommissionAmount          = ' + COALESCE(CAST(@CommissionAmount as varchar(max)),'<null>')
	  PRINT '@LineAmount                = ' + COALESCE(CAST(@LineAmount as varchar(max)),'<null>')
	  PRINT '@HotelsalesinclVAT         = ' + COALESCE(CAST(@HotelsalesinclVAT as varchar(max)),'<null>')
	END


GO
