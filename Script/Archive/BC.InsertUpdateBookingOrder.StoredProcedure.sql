USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BC].[InsertUpdateBookingOrder]    Script Date: 10.04.2024 14:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [BC].[InsertUpdateBookingOrder]
  @transactionId nvarchar(36)
, @externalId nvarchar(50)
, @propertyId nvarchar(50)
, @arrivalDate date
, @departureDate date
, @totalAmountGross dec(38,20)
, @propertyName nvarchar(250)
, @whitelabel nvarchar(250)
, @propertyLocation nvarchar(250)
AS
BEGIN
    IF EXISTS(SELECT * FROM BC.BookingOrder WHERE transactionId=@transactionId)
        UPDATE BC.BookingOrder SET 
               externalId=@externalId 
             , propertyId=@propertyId
             , arrivalDate=@arrivalDate
             , departureDate=@departureDate
             , totalAmountGross=@totalAmountGross
             , propertyName=@propertyName
             , whitelabel=@whitelabel
             , propertyLocation=@propertyLocation
         WHERE transactionId=@transactionId
    ELSE
        INSERT INTO BC.BookingOrder(transactionId,externalId,propertyId,arrivalDate,departureDate,totalAmountGross,propertyName,whitelabel,propertyLocation)
        SELECT @transactionId, @externalId, @propertyId, @arrivalDate, @departureDate, @totalAmountGross, @propertyName, @whitelabel, @propertyLocation
END
GO
