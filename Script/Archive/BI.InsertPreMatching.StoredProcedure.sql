USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BI].[InsertPreMatching]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [BI].[InsertPreMatching]
  @CDG_Code int
, @h_key varchar(50)
, @booking_id varchar(50)  
AS
BEGIN
INSERT INTO [BI].[PreMatching]([CDG_Code],[h_key],[booking_id])  
SELECT   @CDG_Code, @h_key, @booking_id

END
GO
