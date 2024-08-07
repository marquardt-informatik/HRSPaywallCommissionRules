USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[QueryAddProdByMuse]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[QueryAddProdByMuse]
AS
BEGIN

DECLARE @PostingDate DATETIME
IF DATEPART(dd,GETDATE())<5 BEGIN SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE()),120),10) AS DATETIME) END

IF DATEPART(dd,GETDATE())>=5 BEGIN SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1-DATEPART(dd,GETDATE()),GETDATE()))),120),10) AS DATETIME) END

    SELECT 'AddProd' [Company]
       , AL.[MuseID]
       , SUM(AL.[Commission Base Amount (LCY)]*CASE WHEN AL.[Price Type]=2 THEN 1 ELSE AL.[Number of Nights] END) [HTO]
       , SUM(CASE WHEN [Agency Line Amount (LCY)]=0 THEN 0 ELSE AL.[Commission Base Amount (LCY)]*CASE WHEN AL.[Price Type]=2 THEN 1 ELSE AL.[Number of Nights] END END) [commissionable HTO]
       , SUM(AL.[Agency Line Amount (LCY)]) [Commission]
       , SUM(AL.[TAF Line Amount (LCY)]) [TAF]
    FROM DynNavHRS.dbo.[HRS$Agency Display Header] AH WITH (NOLOCK)
    JOIN DynNavHRS.dbo.[HRS$Agency Display Line] AL WITH (NOLOCK) ON AL.[Display Case No_]=AH.[Case No_]
   WHERE AH.[Document Type] IN ('38','39','40','41','42','43')
     AND AH.[Creation Date] = @PostingDate
GROUP BY AL.[MuseID]
END
GO
