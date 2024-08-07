USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPSourcingFeeSalesComment]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sascha Altgeld
-- Create date: 18.10.2017
-- Description:	Rechnungskommentare für Sourcing Fee (RevShare-Klausel enthalten)
-- 17.04.18		HRS001	SAL		ACS-355		Document Type extended by 3 + 8
-- 02.11.18     HRS002  DJU     ACS-1181    Prevent inserting spaces between lines
/*
execute [dbo].[sp_RPSourcingFeeSalesComment] 'R008154781','HRS'
execute [dbo].[sp_RPSourcingFeeSalesComment] 'MATEST','HRS'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPSourcingFeeSalesComment] 
    @ReNr varchar(20)
  , @Company varchar(30) = 'HRS'
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SQLText varchar(max)

  if @Company = '' SET @Company = 'HRS'
  
-- 02.11.18 DJU >>>>>>>>>>>>>>>>>>>> HRS002
--CREATE TABLE #RESULTS 
--	( [Comment]								VARCHAR(80)
--)
  
--  SET @SQLText = 
--'INSERT INTO #RESULTS
--SELECT [Comment]
--  FROM [' + @Company + '$Sales Comment Line] WITH (READUNCOMMITTED)
-- WHERE [No_] = ''' + @ReNr + '''
--   AND [Document Type] IN (2,3,7,8)
--   AND [Document Line No_] = 0
--   AND [Line No_] BETWEEN 2 AND 4'
   
--EXECUTE (@SQLText) 
--SELECT [Comment] + '' AS 'data()' FROM #RESULTS FOR XML PATH('')

  SET @SQLText = 
'DECLARE @comment varchar(max) = ''''

SELECT @comment += [Comment]
  FROM [' + @Company + '$Sales Comment Line] WITH (READUNCOMMITTED)
 WHERE [No_] = ''' + @ReNr + '''
   AND [Document Type] IN (2,3,7,8)
   AND [Document Line No_] = 0
   AND [Line No_] BETWEEN 2 AND 4

SELECT @comment [Comment]'
   
PRINT @SQLText
EXECUTE (@SQLText) 
-- 02.11.18 DJU <<<<<<<<<<<<<<<<<<<< HRS002

END

GO
