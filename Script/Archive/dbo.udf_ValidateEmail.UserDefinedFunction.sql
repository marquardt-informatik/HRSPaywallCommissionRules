USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_ValidateEmail]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create FUNCTION [dbo].[udf_ValidateEmail] (@email varChar(255))

RETURNS bit
AS
begin
return
(
select 
	Case 
		When 	@Email is null then 0	                	--NULL Email is invalid
		When	charindex(' ', @email) 	<> 0 or		--Check for invalid character
				charindex('/', @email) 	<> 0 or --Check for invalid character
				charindex(':', @email) 	<> 0 or --Check for invalid character
				charindex(';', @email) 	<> 0 then 0 --Check for invalid character
		When len(@Email)-1 <= charindex('.', @Email) then 0--check for '%._' at end of string
		When 	@Email like '%@%@%'or 
				@Email Not Like '%@%.%'  then 0--Check for duplicate @ or invalid format
		Else 1
	END
)
end
GO
