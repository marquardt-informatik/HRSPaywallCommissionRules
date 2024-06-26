USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPReminderLines_HRS-CN]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.07.2012
-- Description:	Mahnungszeilen
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '835372000'
EXEC [dbo].[sp_RPReminderLines_HRS-CN] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPReminderLines_HRS-CN] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT [Reminder No_]
       , [Line No_]
       , [Document No_]
       , [Due Date]
       , Amount
       , [Original Amount]
       , [Remaining Amount]
       , [Document Date]
       , [Document Type]
    FROM [HRS-CN$Issued Reminder Line] WITH (READUNCOMMITTED)
   WHERE ([Reminder No_] = @ReNr) AND 
         (Type = 2 OR Type = 3)
UNION         
  SELECT [Reminder No_]
       , [Line No_]
       , [Document No_]
       , [Due Date]
       , Amount
       , [Original Amount]
       , [Remaining Amount]
       , [Document Date]
       , [Document Type]
    FROM [HRS-CN$Reminder Line] WITH (READUNCOMMITTED)
   WHERE ([Reminder No_] = @ReNr) AND 
         (Type = 2 OR Type = 3)
ORDER BY 8
       , 1
       , 9
       , 3
END
GO
