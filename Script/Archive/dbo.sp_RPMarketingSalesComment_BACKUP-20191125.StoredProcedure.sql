USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPMarketingSalesComment_BACKUP-20191125]    Script Date: 10.04.2024 14:31:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 01.08.2012
-- Description:	Rechnungskommentare
-- 
/*
execute [dbo].[sp_RPMarketingSalesComment] 'MA151954','HRS'
execute [dbo].[sp_RPMarketingSalesComment] 'MATEST','HRS'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RPMarketingSalesComment_BACKUP-20191125] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SQLText varchar(max)
  
CREATE TABLE #RESULTS 
	( [Comment]								VARCHAR(80)
)
  
  SET @SQLText = 
'INSERT INTO #RESULTS
SELECT [Comment]
  FROM [' + @Company + '$Sales Comment Line] WITH (READUNCOMMITTED)
 WHERE [No_] = ''' + @ReNr + '''
   AND [Document Type] IN (2,7)'
   
EXECUTE (@SQLText) 
SELECT * FROM #RESULTS  

END
GO
