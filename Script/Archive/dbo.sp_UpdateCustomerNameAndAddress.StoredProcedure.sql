USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateCustomerNameAndAddress]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- exec sp_UpdateCustomerNameAndAddress 168685, 'ALIAT, S.L.', 'AD01HESPERIA ANDORRA LA VELLA', 'L706303M', '15217'
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateCustomerNameAndAddress]
  @No int
, @Name varchar(130)
, @Name2 varchar(70)
, @Address varchar(130)
, @Address2 varchar(70)
AS
BEGIN
  DECLARE @ExecDate AS datetime = getdate()
  DECLARE @ExecTime AS datetime = CAST('1754-01-01 ' + CONVERT(varchar(14),@ExecDate,114) AS datetime)
  DECLARE @TableNo int = 18
  DECLARE @Update int = 1
  DECLARE @PrimaryKeyField1No int = 1
;WITH Fields AS
(
  SELECT 2 [Field No_] UNION SELECT 4 UNION SELECT 5 UNION SELECT 6
)  
INSERT INTO [HRS$Change Log Entry]([Date and Time],[Time],[User ID],[Table No_],[Field No_],[Type of Change],[Old Value],[New Value],[Primary Key],[Primary Key Field 1 No_],[Primary Key Field 1 Value],[Primary Key Field 2 No_],[Primary Key Field 2 Value],[Primary Key Field 3 No_],[Primary Key Field 3 Value])
SELECT @ExecDate, @ExecTime, 'TMA04', @TableNo, [Field No_], @Update
     , CASE [Field No_]
         WHEN 2 THEN [Name]
         WHEN 4 THEN [Name 2]
         WHEN 5 THEN [Address]
         WHEN 6 THEN [Address 2]
       END -- <Old Value, varchar(250),>
     , CASE [Field No_]
         WHEN 2 THEN @Name
         WHEN 4 THEN @Name2
         WHEN 5 THEN @Address
         WHEN 6 THEN @Address2
       END -- <New Value, varchar(250),>
     , 'Nr.=' + CAST(@No AS varchar) -- <Primary Key, varchar(250),>
     , @PrimaryKeyField1No
     , CAST(@No AS varchar) -- <Primary Key Field 1 Value, varchar(50),>
     , 0, '', 0, ''
  FROM [HRS$Customer],[Fields]
 WHERE [No_]= @No
   AND (
            ([Field No_] = 2 AND [Name]<>@Name)
         OR ([Field No_] = 4 AND [Name 2]<>@Name2)
         OR ([Field No_] = 5 AND [Address]<>@Address)
         OR ([Field No_] = 6 AND [Address 2]<>@Address2)
       )
UPDATE [HRS$Customer] SET [Name]=@Name WHERE [Name]<>@Name AND [No_] = @No
UPDATE [HRS$Customer] SET [Name 2]=@Name2 WHERE [Name 2]<>@Name2 AND [No_] = @No
UPDATE [HRS$Customer] SET [Address]=@Address WHERE [Address]<>@Address AND [No_] = @No
UPDATE [HRS$Customer] SET [Address 2]=@Address2 WHERE [Address 2]<>@Address2 AND [No_] = @No
END
GO
