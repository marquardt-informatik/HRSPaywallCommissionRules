USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPPendingClosureLines]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jens Högg
-- Create date: 14.05.2013
-- Description:	Mahnungszeilen für Pending Closure / Closure
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 14.05.13 HRS001    70469  JHO    Erstellt für Mahnungszeilen für Pending Closure / Closure
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'M003812937'
EXEC [dbo].[sp_RPPendingClosureLines]  @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPPendingClosureLines] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Description varchar(max), @ReminderNo varchar(20), @LineNo int
  SET @Description = ''
  
  SELECT @Description = @Description + CASE WHEN [Description]='' OR @Description = '' THEN CHAR(10)+CHAR(13)+CHAR(10)+CHAR(13) ELSE [Description] END, @ReminderNo = [Reminder No_], @LineNo = [Line No_]
    FROM [HRS$Issued Reminder Line] WITH (READUNCOMMITTED)
   WHERE ([Reminder No_] = @ReNr) AND 
         ([Type] = 0)
ORDER BY [Reminder No_]
       , [Line No_]       

  SELECT @Description = @Description + CASE WHEN [Description]='' OR @Description = '' THEN CHAR(10)+CHAR(13)+CHAR(10)+CHAR(13) ELSE [Description] END, @ReminderNo = [Reminder No_], @LineNo = [Line No_]
    FROM [HRS$Reminder Line] WITH (READUNCOMMITTED)
   WHERE ([Reminder No_] = @ReNr) AND 
         ([Type] = 0)
ORDER BY [Reminder No_]
       , [Line No_]       
         
  SELECT @Description [Description]
END
GO
