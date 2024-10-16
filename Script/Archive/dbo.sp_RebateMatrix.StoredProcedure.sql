USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateMatrix]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Matrixinformationen zur Gutschriftsanzeige
/*
DECLARE @ReNr VARCHAR(20)
SELECT @ReNr = 'NRM1'
EXEC [dbo].[sp_RebateMatrix] @ReNr
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateMatrix] 
    @RebateMatrix varchar(20)
AS
BEGIN

SELECT R1.[Description] [Description 1]
     , R2.[Description] [Description 2]
     , DV.[Range Line 1 No_]
     , DV.[Range Line 2 No_]
     , DV.[Value Decimal]
     , D1.[Name] [Dimension 1 Name]
     , D2.[Name] [Dimension 2 Name]
  FROM [HRS$Rebate Matrix]  RM WITH (NOLOCK)
  JOIN [HRS$OLAP Dimension] D1 WITH (NOLOCK)
    ON D1.[Code] = RM.[OLAP Dim_ 1 Code]
  JOIN [HRS$OLAP Dimension] D2 WITH (NOLOCK)
    ON D2.[Code] = RM.[OLAP Dim_ 2 Code]
  JOIN [HRS$Rebate Dimension Ranges] R1 WITH (NOLOCK)
    ON R1.[Matrix Code] = RM.[Code]
   AND R1.[OLAP Dimension Code] = D1.[Code]
  JOIN [HRS$Rebate Dimension Ranges] R2 WITH (NOLOCK)
    ON R2.[Matrix Code] = RM.[Code]
   AND R2.[OLAP Dimension Code] = D2.[Code]
  JOIN [HRS$Rebate Matrix Values] DV WITH (NOLOCK)
    ON DV.[Matrix Code] = RM.[Code]
   AND DV.[Range Line 1 No_] = R1.[Range Line No_]
   AND DV.[Range Line 2 No_] = R2.[Range Line No_]
 WHERE RM.[Code] = @RebateMatrix
END

GO
