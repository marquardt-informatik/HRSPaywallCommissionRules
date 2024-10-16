USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPDebitCollectionComment_CN]    Script Date: 10.04.2024 14:31:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 11.03.15
-- Description:	Kopie von sp_RPDebitCollectionComment
-- execute [dbo].[sp_RPDebitCollectionComment_CN] ''
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPDebitCollectionComment_CN] 
  @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
;WITH ML AS 
(
  SELECT CL.[No_] [Debit Case No_], MIN([Line No_]) MinLineNo 
    FROM [HRS-CN$Agency Comment Line] CL
   WHERE CL.[No_] = @ReNr
     AND CL.[Table Name] = 4
     AND CL.Comment<>''
GROUP BY CL.[No_]     
)     
  SELECT Comment
    FROM [HRS-CN$Agency Comment Line] CL
    JOIN ML ON ML.[Debit Case No_] = CL.[No_]
   WHERE CL.[No_] = @ReNr
     AND CL.[Table Name] = 4
     AND ML.MinLineNo<=CL.[Line No_]
ORDER BY [Line No_]
END

GO
