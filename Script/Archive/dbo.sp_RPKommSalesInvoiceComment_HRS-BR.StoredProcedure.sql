USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceComment_HRS-BR]    Script Date: 10.04.2024 14:31:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.06.2011
-- Description:	Kopie der SP vom P-NAV-MSSQL-1
-- execute [dbo].[sp_RPKommSalesInvoiceComment_HRS-BR] 'K000287191'
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceComment_HRS-BR] 
  @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
DECLARE @Comment varchar(max)
 SELECT @Comment = ''
DECLARE @ReNr2 varchar(25)
    SET @ReNr2 = @ReNr
;WITH ML AS 
(
  SELECT CL.[No_] [Case No_], MIN([Line No_]) MinLineNo 
    FROM [HRS-BR$Agency Comment Line] CL
    JOIN [HRS-BR$Agency Display Header] RH
      ON RH.[Case No_] = CL.[No_]
   WHERE (RH.[Posted Invoice No_] = @ReNr2 OR RH.[Case No_] = @ReNr2)
     AND [Table Name] = 1
     AND Comment<>''
GROUP BY CL.[No_]     
)     
  SELECT @Comment = @Comment + CHAR(10)+ Comment
       --+ CASE 
       --    WHEN Comment='' AND SUBSTRING(@Comment,LEN(@Comment)-1,2) <> CHAR(10)+CHAR(10) THEN CHAR(10)+CHAR(10)
       --    WHEN LEN(Comment) < 30 THEN CHAR(10)+Comment
       --    ELSE Comment
       --  END
    FROM [HRS-BR$Agency Comment Line] CL
    JOIN [HRS-BR$Agency Display Header] RH
      ON RH.[Case No_] = CL.[No_]
    JOIN ML ON ML.[Case No_] = RH.[Case No_]
   WHERE (RH.[Posted Invoice No_] = @ReNr2 OR RH.[Case No_] = @ReNr2)
     AND [Table Name] = 1
     AND ML.MinLineNo<=CL.[Line No_]
ORDER BY [Line No_]

SELECT @Comment Comment
END



GO
