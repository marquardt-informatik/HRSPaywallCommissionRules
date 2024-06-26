USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[PrepareJinJiang]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 03.05.22
-- Description:	Ändert den Rate Plan Code 
-- 1219
-- 475
-- =============================================
CREATE PROC [dbo].[PrepareJinJiang]
AS
BEGIN
UPDATE AL SET
       AL.[Rate Plan Code]='JIN-0.0'
     , AL.[Commission Type]=12
  FROM [HRS-CN$Agency Line] AL 
  JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK) ON AH.[Reservation No_]=AL.[Reservation No_]
 WHERE AH.[Departure Date] >= '2022-01-01'
   AND AH.[MuseID] = 'JINJIANG'
   AND SUBSTRING(AL.[Rate Description], CHARINDEX('-',AL.[Rate Description])+1,3)='0.0'

UPDATE AL SET
       AL.[Rate Plan Code]='JIN-3.0'
     , AL.[Commission Type]=12
  FROM [HRS-CN$Agency Line] AL 
  JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK) ON AH.[Reservation No_]=AL.[Reservation No_]
 WHERE AH.[Departure Date] >= '2022-01-01'
   AND AH.[MuseID] = 'JINJIANG'
   AND SUBSTRING(AL.[Rate Description], CHARINDEX('-',AL.[Rate Description])+1,3)='3.0'
END
GO
