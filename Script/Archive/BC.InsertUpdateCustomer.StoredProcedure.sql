USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BC].[InsertUpdateCustomer]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [BC].[InsertUpdateCustomer]
  @No nvarchar(50)
, @Name nvarchar(100)
, @Name2 nvarchar(100)
, @Adress nvarchar(100)
, @Adress2 nvarchar(100)
, @City nvarchar(100)
, @PostCode nvarchar(30)
, @CountryRegion nvarchar(10)
, @TerritoryCode nvarchar(10)
AS
BEGIN
    IF EXISTS(SELECT * FROM BC.Customer WHERE [No_]=@No)
        UPDATE BC.Customer SET 
               [Name]=@Name 
             , [Name2]=@Name2
             , [Address]=@Adress
             , [Address2]=@Adress2
             , [City]=@City
             , [PostCode]=@PostCode
             , [CountryRegion]=@CountryRegion
             , [TerritoryCode]=@TerritoryCode
         WHERE [No_]=@No
    ELSE
        INSERT INTO BC.Customer([No_],[Name],[Name2],[Address],[Address2],[City],[PostCode],[CountryRegion],[TerritoryCode])
        SELECT @No, @Name, @Name2, @Adress, @Adress2, @City, @PostCode, @CountryRegion, @TerritoryCode
END
GO
