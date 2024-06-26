USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_SetUpCommission_CN]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ================================================================================================
-- Author:		Soner Akdemir
-- Create date: 15.01.2019
-- Description:	Prepare Commission Process
--
-- Date       | Version |  Ticket  | Sign | Description
-- -----------+---------+----------+------+----------------------------------------------------------
-- 02.07.2019   HRS001    ACS-1715   SAK01   Create
-- 25.07.2019   HRS002    ACS-1873   TMA04   Load BOOKING_SEGMENTATION for all Chains but 550,15,165,204
-- 18.02.2019   HRS003    ACS-2173   TMA04   RatePlan Code Aktualisierung
-- 29.01.2021   HRS004    ACS-2644   SAK01   Comm Type Change
-- 02.11.2021   HRS005    ACS-3318   SAK01   RatePlan Code Aktualisierung 
-- 23.01.2023   HRS006    ACS-4208   TMA04   Segment by IATA
-- 15.08.2023   HRS007	  NAV-1940   EXTSAK01 Bug Segment 	
-- ================================================================================================
CREATE PROCEDURE [dbo].[sp_SetUpCommission_CN]
AS
SET QUOTED_IDENTIFIER ON

DECLARE @DateFrom datetime, @DateTo datetime

DECLARE @PostingDate DATETIME

IF DATEPART(dd,GETDATE())<5
BEGIN
  SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE()),120),10) AS DATETIME)
END

IF DATEPART(dd,GETDATE())>=5
BEGIN
  SELECT @PostingDate = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1-DATEPART(dd,GETDATE()),GETDATE()))),120),10) AS DATETIME)
END

 SELECT @DateTo = COALESCE(@DateTo,@PostingDate)
      , @DateFrom = COALESCE(@DateFrom,DATEADD(dd,1,DATEADD(mm,-3,@PostingDate)))

-- HRS002 +++++
-- ----------------------------------------------------------------------------------------------
-- Update Segment Information to all Chains execpt 550,15,165,204
-- ----------------------------------------------------------------------------------------------
/*
DB2 Site Values
1 = Leisure
2 = MICE
3 = Corporate unmanaged
4 = Corporate managed
NAVISION Site Values
1 = Corporate
2 = Leisure	
3 = Managed Commissionable
4 = Managed Net	
5 = Meetings and Groups	
*/
/*
UPDATE BU SET 
	BU.B_SEGMENT =
	CASE
		WHEN  BS.BOOKING_SEGMENT = 1 THEN 2
		WHEN  BS.BOOKING_SEGMENT = 2 THEN 5
		WHEN  BS.BOOKING_SEGMENT = 3 THEN 1
		WHEN  BS.BOOKING_SEGMENT = 4 THEN 3
		ELSE 2
	END		
FROM [HRSDB].[BKG_PROCESS_HIST_DA_BOOKING_SEGMENT] BS WITH (NOLOCK)
	JOIN [HRSDB].[BUCHUNG] BU WITH (NOLOCK)
		ON BU.BP_KEY = BS.BP_KEY  
WHERE BU.[B_AB_DATUM] >= '2018-12-01'
   AND NOT BU.KE_BID IN (550,15,165,204)
   AND BU.KE_ID <> 2023
   AND BU.B_SEGMENT <> CASE
		WHEN  BS.BOOKING_SEGMENT = 1 THEN 2
		WHEN  BS.BOOKING_SEGMENT = 2 THEN 5
		WHEN  BS.BOOKING_SEGMENT = 3 THEN 1
		WHEN  BS.BOOKING_SEGMENT = 4 THEN 3
		ELSE 2
	END;

UPDATE AH SET 
	AH.Segment =
	CASE
		WHEN  BS.BOOKING_SEGMENT = 1 THEN 2
		WHEN  BS.BOOKING_SEGMENT = 2 THEN 5
		WHEN  BS.BOOKING_SEGMENT = 3 THEN 1
		WHEN  BS.BOOKING_SEGMENT = 4 THEN 3
		ELSE 2
	END		
FROM [HRSDB].[BKG_PROCESS_HIST_DA_BOOKING_SEGMENT] BS WITH (NOLOCK)
	JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK)
		ON AH.ProcessNumber = BS.BP_KEY  
WHERE AH.[Departure Date] >= '2018-12-01'
	AND NOT AH.[Chain ID] IN (550,15,165,204)
	AND AH.[Brand ID] <> 2023
	AND AH.Segment <> CASE
		WHEN  BS.BOOKING_SEGMENT = 1 THEN 2
		WHEN  BS.BOOKING_SEGMENT = 2 THEN 5
		WHEN  BS.BOOKING_SEGMENT = 3 THEN 1
		WHEN  BS.BOOKING_SEGMENT = 4 THEN 3
		ELSE 2
	END;
-- HRS002 -----
*/

-- 23.01.2023   HRS006    ACS-4208   TMA04 +++
EXEC [sp_CorrectSegmentByIATA]
--UPDATE AH SET AH.Segment = BU.B_SEGMENT
--  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
--  JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK)
--    ON AH.[Reservation No_] = BU.B_KEY
-- -- JOIN RPC4
-- --   ON RPC4.H_KEY = BU.H_KEY
-- --  AND RPC4.MUSE_ID = BU.MUSE_ID
-- --  AND RPC4.K_KEY = BU.K_KEY
-- WHERE BU.B_AB_DATUM >= '2018-11-01'
--   AND AH.Segment <> BU.B_SEGMENT;
-- 23.01.2023   HRS006    ACS-4208   TMA04 ---
execute [dbo].[sp_CalculateCorporateDiscount_CN];

-- ----------------------------------------------------------------------------------------------
-- RatePlan Code Update
-- ----------------------------------------------------------------------------------------------

EXEC [dbo].[sp_UpdateRatePlanCode_HRS-CN]

-- ----------------------------------------------------------------------------------------------
-- AGB Zustimmung für Freesale auf "Akzeptiert" stellen, sofern kein Wiederspruch eingelegt wurde (ACS-2248)
-- ----------------------------------------------------------------------------------------------
  UPDATE HO SET 
         HO.H_GTC_STATUS =2
    FROM HRSDB.HOTEL HO WITH (NOLOCK)
   WHERE HO.H_GTC_STATUS=0
     AND NOT HO.HJ_FIT_STATUS IN (10,11)

  UPDATE CO SET
         CO.[GTC Status] = HO.H_GTC_STATUS
    FROM [HRS-CN$Contact] CO
	JOIN HRSDB.HOTEL HO WITH (NOLOCK)
	  ON HO.H_KEY = CO.[No_]
   WHERE CO.[GTC Status] <> HO.H_GTC_STATUS

-- ----------------------------------------------------------------------------------------------
-- Update Commission Type ACS-2644
-- ----------------------------------------------------------------------------------------------


--UPDATE HRSDB.BUCHTEIL SET BT_KOMM_ART=13 WHERE MUSE_ID='CHINALODGING' AND BT_RATE_PLAN LIKE '%-0-%' AND BT_KOMM_ART<>13
--UPDATE HRSDB.BUCHTEIL SET BT_KOMM_ART=10,BT_KOMM_SATZ=3 WHERE MUSE_ID='CHINALODGING' AND BT_RATE_PLAN LIKE '%-3-%' AND (BT_KOMM_ART<>10 OR BT_KOMM_SATZ<>3)

UPDATE AL SET AL.[Rate Plan Code] = 'CHLODG:0', AL.[Commission Type] = 12
from [HRS-CN$Agency Line] AL WITH (NOLOCK)
JOIN HRSDB.BUCHTEIL BT ON BT.B_KEY = AL.[Reservation No_]
WHERE 1=1
AND BT.MUSE_ID='CHINALODGING' 
AND BT_RATE_PLAN LIKE '%-0-%' 


UPDATE AL SET AL.[Rate Plan Code] = 'CHLODG:3', AL.[Commission Type] = 12
from [HRS-CN$Agency Line] AL WITH (NOLOCK)
JOIN HRSDB.BUCHTEIL BT ON BT.B_KEY = AL.[Reservation No_]
WHERE 1=1
AND BT.MUSE_ID='CHINALODGING' 
AND BT_RATE_PLAN LIKE '%-3-%' 


UPDATE AL SET AL.[Rate Plan Code] = CASE WHEN BT_RATE_PLAN LIKE '%-0.0' THEN 'JIN-0.0' ELSE 'JIN-3.0' END
  FROM HRSDB.BUCHTEIL BT WITH (NOLOCK)
  JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY=BT.B_KEY
  JOIN [HRS-CN$Agency Line] AL ON CAST(BT.B_KEY AS varchar(20))=AL.[Reservation No_] AND BT.BT_POS=AL.[Position No_]
 WHERE BU.B_AB_DATUM BETWEEN '2021-11-01' AND '2021-11-30' 
   AND BU.MUSE_ID =  'JINJIANG'
   AND BT_RATE_PLAN IN ('CORLJIN-0.0','CORLXIRUAN-0.0','CORLXIRUAN-3.0','CORLJIN-3.0','CORLKANGBO-0.0','CORLPLATE-0.0','CORLJINSTAR-0.0','CORLJINSTAR-3.0')

/* HRS007
UPDATE AL SET AL.[Commission Type]=12
  FROM [HRS-CN$Agency Line] AL 
  JOIN [HRS-CN$Agency Header] AH ON AH.[Reservation No_]=AL.[Reservation No_]
 WHERE AH.[Chain ID]=5
   AND AL.[Rate Type] BETWEEN 21020 AND 21023
   AND AL.[Commission Type]<>12

UPDATE AL SET AL.[Commission Type]=12
  FROM [HRS-CN$Agency Line] AL 
  JOIN [HRS-CN$Agency Header] AH ON AH.[Reservation No_]=AL.[Reservation No_]
 WHERE AH.[Chain ID]=5
   AND AL.[Commission Type]=13
*/
GO
