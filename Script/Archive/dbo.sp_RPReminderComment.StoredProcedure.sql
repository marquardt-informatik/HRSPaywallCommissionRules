USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPReminderComment]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 23.10.2013
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPReminderComment] 
  @ReNr varchar(25)
 ,@Company varchar(30)
AS
BEGIN
  SET NOCOUNT ON;
  IF @Company = 'HRS'
  SELECT Comment
    FROM [HRS$Reminder Comment Line] CL
   WHERE [No_] = @ReNr
     AND Comment<>''
ORDER BY [Line No_]
  IF @Company = 'HRS-CN'
  SELECT Comment
    FROM [HRS-CN$Reminder Comment Line] CL
   WHERE [No_] = @ReNr
     AND Comment<>''
ORDER BY [Line No_]
END
GO
