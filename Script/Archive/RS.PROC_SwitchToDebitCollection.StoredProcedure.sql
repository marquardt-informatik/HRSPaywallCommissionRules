USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_SwitchToDebitCollection]    Script Date: 10.04.2024 14:31:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 30.07.2014
-- Description:	Nav Report 50149
--				Debitor - Inkassohistorie

-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50149
		, @StartDate				DATETIME		= '01.01.2014'
		, @EndDate					DATETIME		= '31.12.2014'
EXEC [RS].[PROC_SwitchToDebitCollection] @UserId, @CompanyName, @ReportId, @StartDate, @EndDate
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_SwitchToDebitCollection] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
	, @StartDate					DATETIME
	, @EndDate						DATETIME
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE @Filter_Salesperson		VARCHAR(MAX)
SET @Filter_Salesperson = 
	(SELECT CASE WHEN [Filter Value] = '' THEN '' ELSE RTRIM([Filter Value]) END
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1)
PRINT @Filter_Salesperson
;WITH LE AS
(
  SELECT YEAR(LE.[Date and Time]) [Year]
       , MONTH(LE.[Date and Time]) [Month]
       , LE.[Primary Key Field 1 Value]
       , COUNT(DISTINCT LE.[Primary Key Field 1 Value]) [One]
       , MIN(L2.[Old Value]) [Salesperson Code]
    FROM [HRS$Change Log Entry] LE WITH (NOLOCK)
    JOIN [HRS$Change Log Entry] L2 WITH (NOLOCK)
      ON L2.[Entry No_] BETWEEN LE.[Entry No_] - 10 AND LE.[Entry No_]
     AND L2.[Primary Key] = LE.[Primary Key]
     AND L2.[Field No_] = 29
   WHERE LE.[Table No_] = 18
     AND LE.[Field No_] = 51050
     AND LE.[Old Value]  IN ('Nein','No')   
     AND LE.[Date and Time] >= @StartDate
     AND LE.[Date and Time] < DATEADD(dd,1,@EndDate)
     AND L2.[Old Value] <> 'CBR05'     
GROUP BY YEAR(LE.[Date and Time])
       , MONTH(LE.[Date and Time])  
       , LE.[Primary Key Field 1 Value]
)
  SELECT [Year] 
       , [Month] 
       , [Salesperson Code]
       , SUM([One]) [Switch Count]
    FROM LE
   WHERE [Salesperson Code] <> 'CBR05'
     AND ('|'+@Filter_Salesperson+'|' LIKE '%|'+LE.[Salesperson Code]+'|%' OR @Filter_Salesperson='')
GROUP BY [Year]
       , [Month]
       , [Salesperson Code]
END

GO
