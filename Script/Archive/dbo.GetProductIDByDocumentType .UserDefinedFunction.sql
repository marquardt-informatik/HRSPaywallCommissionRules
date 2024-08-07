USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[GetProductIDByDocumentType ]    Script Date: 10.04.2024 14:30:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author:Khaled Mamdouh>
-- Create date: <Create Date, 11.06.22>
-- Description:	<Description, Retrieve product ID using DocumentType (No or Description)>
-- =============================================
CREATE FUNCTION [dbo].[GetProductIDByDocumentType ] (@DocType varchar(50)) RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar varchar(50)
    DECLARE @PRODUCTS TABLE ([ProductNo] tinyint PRIMARY KEY, [Description] varchar(50), [Produkt Document Type] varchar(20))
	
	INSERT INTO @PRODUCTS VALUES (1,'Traveler TAF',		'37');
	INSERT INTO @PRODUCTS VALUES (2,'Chain TAF',				'38');
	INSERT INTO @PRODUCTS VALUES (3,'Partnership Fee ',			'39');
	INSERT INTO @PRODUCTS VALUES (4,'Additional Commission',	'40');
	INSERT INTO @PRODUCTS VALUES (5,'PFP',						'41');
	INSERT INTO @PRODUCTS VALUES (6,'Override',					'42');
	INSERT INTO @PRODUCTS VALUES (7,'Sourcing Fee',				'43');

	SELECT @ResultVar ='0';
	IF ISNUMERIC(@DocType) =1 
	  SELECT @ResultVar = (Select ProductNo FROM @PRODUCTS WHERE  [Produkt Document Type] = @DocType); 
	ELSE
	  SELECT @ResultVar = (Select ProductNo FROM @PRODUCTS WHERE  [Description] = @DocType);


	SET @ResultVar  = CASE WHEN @ResultVar IS NULL THEN '-1' ELSE @ResultVar END

	-- Return the result of the function
	RETURN @ResultVar

END

--Select dbo.GetProductIDByDocumentType('37') Product;
GO
