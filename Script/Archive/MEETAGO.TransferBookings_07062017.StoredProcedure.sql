USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MEETAGO].[TransferBookings_07062017]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================================================================
-- Author:		Thomas Marquardt
-- Create date: 06.08.2015
-- Description:	Transfer Meetago-Reservation into HRSDB.BUCHUNG and HRSDB.BUCHTEIL
--
-- Date       | Version |  Ticket  | Sign | Description
-- -----------+---------+----------+------+----------------------------------------------------------
-- 07.09.2016 | HRS001  | NAV-240  |  TM  | Disable HotelsContingents
--
/*
EXEC [MEETAGO].[TransferBookings] 381583,0
*/
-- ================================================================================================

CREATE PROC [MEETAGO].[TransferBookings_07062017] 
  @RequestId bigint = NULL
, @Debug int = 0

AS
BEGIN

IF NOT @RequestId IS NULL
BEGIN
  DELETE FROM HRSDB.BUCHUNG WHERE B_KEY = @RequestId
  DELETE FROM HRSDB.BUCHTEIL WHERE B_KEY = @RequestId
END

DECLARE @MeetagoBuchung TABLE (
    [BP_KEY] [bigint]
  , [B_KEY] [bigint]
  , [BT_POS] [bigint]
  , [B_KEY_COMMIT] [bigint]
  , [B_AN_DATUM] [date]
  , [B_AB_DATUM] [date]
  , [B_BESTELLER] [varchar](120)
  , [BT_ANZAHL] [bigint]
  , [BT_PAX_COUNT] [bigint]
  , [BT_VON] [date]
  , [BT_BIS] [date]
  , [KE_ID] [bigint]
  , [KE_BID] [bigint]
  , [H_KEY] [bigint]
  , [L_ID] [bigint]
  , [MUSE_ID] [varchar](20)
  , [B_QUELLE] [bigint]
  , [CTS] [datetime2](7)
  , [B_STATUS] [bigint]
  , [B_DATUM] [date]
  , [B_TOTAL_RATE] [bigint]
  , [B_TOTAL_RATE_INCLUSIVE] [bigint]
  , [BT_PREIS] [bigint]
  , [BT_RATE_BEZ] [varchar](1000)
  , [BT_KOMM_SATZ] [bigint]
  , [BT_KOMM_ART] [bigint]
  , [K_KEY] [bigint]
  , [BT_FRSTCK] [bigint]
  , [BT_FRST_PREIS] [bigint]
  , [BT_ZTYP] [bigint]
  , [BT_RATE_TYP] [bigint]
  , [R_KEY] [bigint]
  , [BT_ROOM_NUMBER] [bigint]
  , [MA_USER] [varchar](8)
  , [PRC_TYPE_ID] [bigint]
  , [W_ISO] [varchar](3)
  , [W_KURS] [bigint]
  , [NAV_LOADED] [bit]
  , [B_FIRMA] [varchar](80)
  , [B_GAST1] [varchar](120)
  , PRIMARY KEY CLUSTERED 
    (
	    [B_KEY] ASC
	  , [BT_POS] ASC
    )
)

DECLARE @HA TABLE ([RequestId] varchar(50),[BT_POS] bigint, [BT_RATE_BEZ] [varchar](1000), [Amount] bigint, [HotelId] varchar(50), TypeId varchar(50), [Total] decimal(37,20), TypeIdInt bigint, PRIMARY KEY CLUSTERED ([RequestId],[BT_POS],[HotelId]))
DECLARE @CM TABLE ([RequestId] varchar(50),[BT_POS] bigint, [BT_KOMM_SATZ] bigint, [HotelId] varchar(50), PRIMARY KEY CLUSTERED ([RequestId],[BT_POS],[HotelId]))
DECLARE @HC TABLE ([RequestId] varchar(50),Arrival date, Departure date)

;WITH _HA AS
(
SELECT HA.[RequestId]
	 , HA.[HotelId]
     , CASE  
	     WHEN HA.TypeId='OFFER'     AND HA.Total>0 THEN 0
		 WHEN HA.TypeId='CURRENT'   AND HA.Total>0 THEN 1
		 WHEN HA.TypeId='CONFIRMED' AND HA.Total>0 THEN 2
	     WHEN HA.TypeId='OFFER'     AND HA.Total=0 THEN 0
		 WHEN HA.TypeId='CURRENT'   AND HA.Total=0 THEN 0
		 WHEN HA.TypeId='CONFIRMED' AND HA.Total=0 THEN 0
		 ELSE 0
	   END TypeId
  FROM [MEETAGO].[HotelsAmount] HA 
 WHERE HA.[RequestId] = @RequestId OR @RequestId IS NULL
), _HAMAX AS
(
  SELECT HA.[RequestId]
	   , HA.[HotelId]
	   , MAX(TypeId) TypeId
	FROM _HA HA
GROUP BY HA.[RequestId]
	   , HA.[HotelId]
), _HASELECT AS
(
 SELECT HA.[RequestId]
	  , HA.[HotelId]
	  , HA.TypeId
	  , HA.[Meeting]
	  , HA.[NoShow]
	  , HA.[Other]
      , HA.[GuestRooms]
      , HA.[Total]
      , HM.[TypeId] [TypeIdInt]
   FROM [MEETAGO].[HotelsAmount] HA 
   JOIN _HAMAX HM
	 ON HM.HotelId = HA.HotelId
    AND HM.RequestId = HA.RequestId
	AND HM.TypeId    
     = CASE  
	     WHEN HA.TypeId='OFFER'     AND HA.Total>0 THEN 0
		 WHEN HA.TypeId='CURRENT'   AND HA.Total>0 THEN 1
		 WHEN HA.TypeId='CONFIRMED' AND HA.Total>0 THEN 2
	     WHEN HA.TypeId='OFFER'     AND HA.Total=0 THEN 0
		 WHEN HA.TypeId='CURRENT'   AND HA.Total=0 THEN -1
		 WHEN HA.TypeId='CONFIRMED' AND HA.Total=0 THEN -2
	   END 
   WHERE HA.[RequestId] = @RequestId OR @RequestId IS NULL
), HA AS
(
  SELECT HA.[RequestId], 100 [BT_POS], 'Meeting' [BT_RATE_BEZ], CAST(ROUND(([Meeting])*100.0,0) AS BIGINT)    [Amount], HA.[HotelId], HA.TypeId, HA.Total, HA.TypeIdInt FROM _HASELECT HA UNION
  SELECT HA.[RequestId], 200 [BT_POS], 'NoShow'  [BT_RATE_BEZ], CAST(ROUND(([NoShow])*100.0,0) AS BIGINT)     [Amount], HA.[HotelId], HA.TypeId, HA.Total, HA.TypeIdInt FROM _HASELECT HA UNION
  SELECT HA.[RequestId], 300 [BT_POS], 'Other'   [BT_RATE_BEZ], CAST(ROUND(([Other])*100.0,0) AS BIGINT)      [Amount], HA.[HotelId], HA.TypeId, HA.Total, HA.TypeIdInt FROM _HASELECT HA UNION
  SELECT HA.[RequestId], 400 [BT_POS], 'Rooms'   [BT_RATE_BEZ], CAST(ROUND(([GuestRooms])*100.0,0) AS BIGINT) [Amount], HA.[HotelId], HA.TypeId, HA.Total, HA.TypeIdInt FROM _HASELECT HA
)
INSERT INTO @HA
SELECT * FROM HA

IF @Debug=1
  SELECT '@HA',* FROM @HA

;WITH CM AS
(
  SELECT HA.[RequestId], 100 [BT_POS], MAX(CASE WHEN HA.[StatusCategory] = 'CANCELLATION' THEN 0 ELSE CAST(ROUND([CommissionMeetingServices]*100.0,0) AS BIGINT) END)  [BT_KOMM_SATZ], HA.[HotelId] FROM [MEETAGO].[RequestHotel] HA WHERE [StatusCategory] IN ('BOOKING','CANCELLATION') GROUP BY HA.[RequestId],HA.[HotelId] UNION
  SELECT HA.[RequestId], 200 [BT_POS], MAX(CASE WHEN HA.[StatusCategory] = 'CANCELLATION' THEN 0 ELSE CAST(ROUND([CommissionGroupGuestRooms]*100.0,0) AS BIGINT) END)  [BT_KOMM_SATZ], HA.[HotelId] FROM [MEETAGO].[RequestHotel] HA WHERE [StatusCategory] IN ('BOOKING','CANCELLATION') GROUP BY HA.[RequestId],HA.[HotelId] UNION
  SELECT HA.[RequestId], 300 [BT_POS], MAX(CASE WHEN HA.[StatusCategory] = 'CANCELLATION' THEN 0 ELSE CAST(ROUND([CommissionGroupGuestRooms]*100.0,0) AS BIGINT) END)  [BT_KOMM_SATZ], HA.[HotelId] FROM [MEETAGO].[RequestHotel] HA WHERE [StatusCategory] IN ('BOOKING','CANCELLATION') GROUP BY HA.[RequestId],HA.[HotelId] UNION
  SELECT HA.[RequestId], 400 [BT_POS], MAX(CASE WHEN HA.[StatusCategory] = 'CANCELLATION' THEN 0 ELSE CAST(ROUND([CommissionGroupGuestRooms]*100.0,0) AS BIGINT) END)  [BT_KOMM_SATZ], HA.[HotelId] FROM [MEETAGO].[RequestHotel] HA WHERE [StatusCategory] IN ('BOOKING','CANCELLATION') GROUP BY HA.[RequestId],HA.[HotelId] 
)
INSERT INTO @CM
SELECT * FROM CM
 WHERE CM.[RequestId] = @RequestId OR @RequestId IS NULL

IF @Debug=1
  SELECT '@CM',* FROM @CM

IF @Debug=1
BEGIN
  SELECT 'HotelsContingents',* FROM [MEETAGO].[HotelsContingents] HC WITH (NOLOCK) WHERE HC.[RequestId] = @RequestId OR @RequestId IS NULL
  SELECT 'RequestHotel',* FROM [MEETAGO].[RequestHotel]      RH WITH (NOLOCK) WHERE RH.[RequestId] = @RequestId OR @RequestId IS NULL
  SELECT 'HotelsAmount',* FROM [MEETAGO].[HotelsAmount]      HA WITH (NOLOCK) WHERE HA.[RequestId] = @RequestId OR @RequestId IS NULL 
     SELECT RH.[RecordId]                                                           [BP_KEY]
          , RH.[RequestId]                                                          [B_KEY]
	      , (DENSE_RANK() OVER
		    ( 
			  PARTITION BY RH.[RecordId] 
			  ORDER BY RH.[HotelId], HC.[ContingentId], COALESCE(HC.[Arrival],'1753-01-01')
			) -1)+HA.[BT_POS]                                                        [BT_POS]
          , RH.[RequestId] [B_KEY_COMMIT]
		  , RH.[StartDate]                                                           [B_AN_DATUM]
		  , RH.[EndDate]                                                             [B_AB_DATUM]
	      , RH.[InquirerCompany] +' , '
		  + RH.[InquirerFirstName] + ' ' + RH.[InquirerLastName]                     [B_BESTELLER]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN
		      1
			ELSE
              COALESCE(
		      CASE WHEN HC.[QuantityCurrent] = 0 THEN 
			    HC.[QuantityContract] 
			  ELSE 
			    HC.[QuantityCurrent] 
			  END,1)
			END                                                                      [BT_ANZAHL]
		  , 1                                                                        [BT_PAX_COUNT]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 
		      RH.[StartDate] 
			ELSE 
			  COALESCE(HC.[Arrival],RH.[StartDate]) 
			END                                                                      [BT_VON]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 
		      RH.[EndDate] 
			ELSE 
		      COALESCE(HC.[Departure], RH.[EndDate])
			END                                                                      [BT_BIS]
		  , HO.[KE_ID] 
		  , HO.[KE_BID] 
		  , HO.[H_KEY]
		  , HO.[L_ID]
		  , 'MEETAGO' [MUSE_ID]
		  , 5 [B_QUELLE]
		  , R.[LastDateModified] [CTS]
          , CASE WHEN RH.[StatusId] IN (15,16,17) AND HA.[Amount]>0 THEN 0 ELSE 10000 END [B_STATUS]
          , RH.[OfferDate] [B_DATUM]
          , CASE WHEN HA.[Total]*100.0 BETWEEN -2147483648 AND 2147483647 THEN CAST(ROUND(HA.[Total]*100.0,0) AS BIGINT) ELSE -1 END [B_TOTAL_RATE]
          , CASE WHEN HA.[Total]*100.0 BETWEEN -2147483648 AND 2147483647 THEN CAST(ROUND(HA.[Total]*100.0,0) AS BIGINT) ELSE -1 END [B_TOTAL_RATE_INCLUSIVE]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 
		      CASE WHEN HA.[Amount]*100.0 BETWEEN -2147483648 AND 2147483647 THEN HA.[Amount] ELSE -1 END
		    ELSE
		      COALESCE(CAST(ROUND(CASE WHEN HC.[PricePerNight] = 0 THEN 
                0.01 * CASE WHEN HA.[Amount]*100.0 BETWEEN -2147483648 AND 2147483647 THEN HA.[Amount] ELSE -1 END
			  / CASE WHEN HC.[QuantityCurrent] = 0 THEN 
			      HC.[QuantityContract] 
                ELSE 
			      HC.[QuantityCurrent] 
			    END 
			  ELSE 
			    HC.[PricePerNight] 
			  END * 100.0,0) AS bigint),CASE WHEN HA.[Amount]*100.0 BETWEEN -2147483648 AND 2147483647 THEN HA.[Amount] ELSE -1 END) 
            END                                                                      [BT_PREIS]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN
		      'Rooms'
			ELSE 
		      HA.[BT_RATE_BEZ]
			END                                                                      [BT_RATE_BEZ]
		  , CM.[BT_KOMM_SATZ]
		  , 0 [BT_KOMM_ART]
		  , RH.[InquirerDepartmentId] [K_KEY]
		  , 0 [BT_FRSTCK]
		  , 0 [BT_FRST_PREIS]
		  , 0 [BT_ZTYP]
-- 07.09.2016 TM 
		  , CASE WHEN HA.BT_POS IN (100,200,300,400) /*AND HA.TypeId = 'CONFIRMED'*/ THEN 5000 + 20020 + CAST(HA.BT_POS/100 AS BIGINT) ELSE -1 END [BT_RATE_TYP]
-- Original: , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 20025 ELSE -1 END [BT_RATE_TYP]
-- 07.09.2016 TM 
		  , 0 [R_KEY]
		  , 0 [BT_ROOM_NUMBER]
		  , 'MEETAGO' [MA_USER]
		  , CASE WHEN HA.BT_POS  IN (100,200,300,400) /*AND HA.TypeId = 'CONFIRMED'*/ THEN 2 ELSE 0 END [PRC_TYPE_ID]
		  , RH.Currency [W_ISO]
		  , 100000 [W_KURS]
		  , 0 [NAV_LOADED]
		  , R.OrganizerSsoDepartmentId  --RH.[InquirerCompany] 25.04.17 TM
		  , RH.[InquirerFirstName] + ' ' + RH.[InquirerLastName] [B_GAST1]
       FROM [MEETAGO].[RequestHotel]      RH WITH (NOLOCK)
  LEFT JOIN HRSDB.BUCHUNG                BU WITH (NOLOCK)
         ON BU.B_KEY       = RH.[RequestId] 
       JOIN [MEETAGO].[Request]           R WITH (NOLOCK)
         ON R.[RequestId]  = RH.[RecordId]
       JOIN @HA                           HA
         ON HA.[RequestId] = RH.[RequestId]
        AND HA.[HotelId]   = RH.[HotelId]
       JOIN @CM                           CM
         ON CM.[RequestId] = HA.[RequestId]
        AND CM.[HotelId]   = HA.[HotelId]
        AND CM.[BT_POS]    = HA.[BT_POS]
  LEFT JOIN [MEETAGO].[HotelsContingents] HC WITH (NOLOCK)
         ON HC.[RequestId] = RH.[RequestId]
	    AND HC.[HotelId]   = RH.[HotelId]
	    AND HA.[BT_POS]    = 400
	    AND HA.[TypeIdInt] < 2
		AND HC.ContingentId <> 0        
-- 07.09.2016 TM Disable HotelsContingents
        AND 1=0
-- 07.09.2016 TM Disable HotelsContingents
       JOIN [MEETAGO].[HotelInfo]         HI WITH (NOLOCK)
         ON HI.[RequestId] = RH.[RequestId]
        AND HI.[HotelId]   = RH.[HotelId]
        AND ISNUMERIC(HI.[HrsId])=1
       JOIN [HRSDB].[HOTEL]               HO WITH (NOLOCK)
         ON (HO.[H_KEY] = HI.[HrsId] OR (HI.[HrsId] = '' AND HO.[H_KEY]=1))
      WHERE RH.[StatusId] IN (15,16,17,18,19)
	    AND (BU.B_KEY IS NULL OR NOT @RequestId IS NULL)
        AND (HA.[RequestId] = @RequestId OR @RequestId IS NULL)
END

;WITH MB AS
(
     SELECT RH.[RecordId]                                                           [BP_KEY]
          , RH.[RequestId]                                                          [B_KEY]
	      , (DENSE_RANK() OVER
		    ( 
			  PARTITION BY RH.[RecordId] 
			  ORDER BY RH.[HotelId], HC.[ContingentId], COALESCE(HC.[Arrival],'1753-01-01')
			) -1)+HA.[BT_POS]                                                        [BT_POS]
          , RH.[RequestId] [B_KEY_COMMIT]
		  , RH.[StartDate]                                                           [B_AN_DATUM]
		  , RH.[EndDate]                                                             [B_AB_DATUM]
	      , RH.[InquirerCompany] +' , '
		  + RH.[InquirerFirstName] + ' ' + RH.[InquirerLastName]                     [B_BESTELLER]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN
		      1
			ELSE
              COALESCE(
		      CASE WHEN HC.[QuantityCurrent] = 0 THEN 
			    HC.[QuantityContract] 
			  ELSE 
			    HC.[QuantityCurrent] 
			  END,1)
			END                                                                      [BT_ANZAHL]
		  , 1                                                                        [BT_PAX_COUNT]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 
		      RH.[StartDate] 
			ELSE 
			  COALESCE(HC.[Arrival],RH.[StartDate]) 
			END                                                                      [BT_VON]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 
		      RH.[EndDate] 
			ELSE 
		      COALESCE(HC.[Departure], RH.[EndDate])
			END                                                                      [BT_BIS]
		  , HO.[KE_ID] 
		  , HO.[KE_BID] 
		  , HO.[H_KEY]
		  , HO.[L_ID]
		  , 'MEETAGO' [MUSE_ID]
		  , 5 [B_QUELLE]
		  , R.[LastDateModified] [CTS]
          , CASE WHEN RH.[StatusId] IN (15,16,17) AND HA.[Amount]>0 THEN 0 ELSE 10000 END [B_STATUS]
          , RH.[OfferDate] [B_DATUM]
         , CASE WHEN HA.[Total]*100.0 BETWEEN -2147483648 AND 2147483647 THEN CAST(ROUND(HA.[Total]*100.0,0) AS BIGINT) ELSE -1 END [B_TOTAL_RATE]
          , CASE WHEN HA.[Total]*100.0 BETWEEN -2147483648 AND 2147483647 THEN CAST(ROUND(HA.[Total]*100.0,0) AS BIGINT) ELSE -1 END [B_TOTAL_RATE_INCLUSIVE]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 
		      CASE WHEN HA.[Amount]*100.0 BETWEEN -2147483648 AND 2147483647 THEN HA.[Amount] ELSE -1 END
		    ELSE
		      COALESCE(CAST(ROUND(CASE WHEN HC.[PricePerNight] = 0 THEN 
                0.01 * CASE WHEN HA.[Amount]*100.0 BETWEEN -2147483648 AND 2147483647 THEN HA.[Amount] ELSE -1 END
			  / CASE WHEN HC.[QuantityCurrent] = 0 THEN 
			      HC.[QuantityContract] 
                ELSE 
			      HC.[QuantityCurrent] 
			    END 
			  ELSE 
			    HC.[PricePerNight] 
			  END * 100.0,0) AS bigint),CASE WHEN HA.[Amount]*100.0 BETWEEN -2147483648 AND 2147483647 THEN HA.[Amount] ELSE -1 END) 
            END                                                                      [BT_PREIS]
		  , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN
		      'Rooms'
			ELSE 
		      HA.[BT_RATE_BEZ]
			END                                                                      [BT_RATE_BEZ]
		  , CM.[BT_KOMM_SATZ]
		  , 0 [BT_KOMM_ART]
-- 04.04.17 TM >>>>>>>>>>>>>>>>>>>>
		  , RQ.[OrganizerSsoDepartmentId] [K_KEY]
-- Original: , RH.[InquirerDepartmentId] [K_KEY]
-- 04.04.17 TM <<<<<<<<<<<<<<<<<<<<
		  , 0 [BT_FRSTCK]
		  , 0 [BT_FRST_PREIS]
		  , 0 [BT_ZTYP]
-- 07.09.2016 TM 
		  , CASE WHEN HA.BT_POS IN (100,200,300,400) /*AND HA.TypeId = 'CONFIRMED'*/ THEN 5000 + 20020 + CAST(HA.BT_POS/100 AS BIGINT) ELSE -1 END [BT_RATE_TYP]
-- Original: , CASE WHEN HA.BT_POS = 400 AND HA.TypeId = 'CONFIRMED' THEN 20025 ELSE -1 END [BT_RATE_TYP]
-- 07.09.2016 TM 
		  , 0 [R_KEY]
		  , 0 [BT_ROOM_NUMBER]
		  , 'MEETAGO' [MA_USER]
		  , CASE WHEN HA.BT_POS IN (100,200,300,400) /*AND HA.TypeId = 'CONFIRMED'*/ THEN 2 ELSE 0 END [PRC_TYPE_ID]
		  , RH.Currency [W_ISO]
		  , 100000 [W_KURS]
		  , 0 [NAV_LOADED]
		  , RH.[InquirerCompany]
		  , RH.[InquirerFirstName] + ' ' + RH.[InquirerLastName] [B_GAST1]
       FROM [MEETAGO].[RequestHotel]      RH WITH (NOLOCK)
	   JOIN [MEETAGO].[Request]           RQ WITH (NOLOCK)
	     ON RQ.[RequestId] = RH.[RecordId]
  LEFT JOIN HRSDB.BUCHUNG                BU WITH (NOLOCK)
         ON BU.B_KEY       = RH.[RequestId] 
       JOIN [MEETAGO].[Request]           R WITH (NOLOCK)
         ON R.[RequestId]  = RH.[RecordId]
       JOIN @HA                           HA
         ON HA.[RequestId] = RH.[RequestId]
        AND HA.[HotelId]   = RH.[HotelId]
       JOIN @CM                           CM
         ON CM.[RequestId] = HA.[RequestId]
        AND CM.[HotelId]   = HA.[HotelId]
        AND CM.[BT_POS]    = HA.[BT_POS]
  LEFT JOIN [MEETAGO].[HotelsContingents] HC WITH (NOLOCK)
         ON HC.[RequestId] = RH.[RequestId]
	    AND HC.[HotelId]   = RH.[HotelId]
	    AND HA.[BT_POS]    = 400
	    AND HA.[TypeIdInt] < 2
		AND HC.ContingentId <> 0
-- 07.09.2016 TM Disable HotelsContingents
        AND 1=0
-- 07.09.2016 TM Disable HotelsContingents
       JOIN [MEETAGO].[HotelInfo]         HI WITH (NOLOCK)
         ON HI.[RequestId] = RH.[RequestId]
        AND HI.[HotelId]   = RH.[HotelId]
        AND ISNUMERIC(HI.[HrsId])=1
       JOIN [HRSDB].[HOTEL]               HO WITH (NOLOCK)
         ON (HO.[H_KEY] = HI.[HrsId] OR (HI.[HrsId] = '' AND HO.[H_KEY]=1))
      WHERE RH.[StatusId] IN (15,16,17,18,19)
	    AND (BU.B_KEY IS NULL OR NOT @RequestId IS NULL)
        AND (HA.[RequestId] = @RequestId OR @RequestId IS NULL)
) 
  INSERT INTO @MeetagoBuchung
  SELECT *
    FROM MB
--   WHERE B_KEY = 378859
ORDER BY [B_KEY], [BT_POS]

IF @Debug=2
  SELECT * FROM @MeetagoBuchung

IF @Debug=1
BEGIN
;WITH MinMB AS
(
  SELECT [B_KEY], MIN([BT_POS]) [BT_POS], MIN(B_STATUS) B_STATUS FROM @MeetagoBuchung GROUP BY [B_KEY]
)
   SELECT MB.[B_KEY],MB.[CTS],MB.[K_KEY],MB.[H_KEY],MB.[MA_USER],MinMB.[B_STATUS],MB.[B_DATUM],null,MB.[B_QUELLE],MB.[B_AN_DATUM],MB.[B_AB_DATUM],MB.[B_FIRMA],MB.[B_GAST1],null,null,null,MB.[MUSE_ID],MB.[W_ISO],MB.[W_KURS],MB.[KE_ID],MB.[KE_BID],1 [B_HANDBOOKING],null [B_IFC_VERSION],MB.[B_TOTAL_RATE],MB.[B_TOTAL_RATE_INCLUSIVE],null [B_PERCENT_DISCOUNT],null [B_PASSWORD],MB.[BP_KEY],MB.[L_ID],null [BCDT_VALUE],MB.[NAV_LOADED],MB.[B_BESTELLER],null [B_KEY_ALT],null [QUALITY_MA_USER],null [QUALITY_CTS],MB.[B_KEY_COMMIT],null [B_CANCELLATION],null [B_ZAHL_ART],null [B_KEY_ROOT],null [B_KEY_LAST_NBVL],null [B_KEY_LAST_BVL],null [B_INFORMATION],null [B_OFFER_ID]     
     FROM @MeetagoBuchung MB
	 JOIN MinMB ON MinMB.B_KEY = MB.B_KEY AND MinMB.BT_POS = MB.BT_POS
LEFT JOIN [HRSDB].[BUCHUNG] BU
       ON BU.B_KEY = MB.B_KEY
	WHERE BU.B_KEY IS NULL
END

IF @Debug=0
BEGIN
;WITH MinMB AS
(
  SELECT [B_KEY], MIN([BT_POS]) [BT_POS], MIN(B_STATUS) B_STATUS FROM @MeetagoBuchung GROUP BY [B_KEY]
)
   INSERT INTO [HRSDB].[BUCHUNG]([B_KEY],[CTS],[K_KEY],[H_KEY],[MA_USER],[B_STATUS],[B_DATUM],[B_ZEIT],[B_QUELLE],[B_AN_DATUM],[B_AB_DATUM],[B_FIRMA],[B_GAST1],[B_GAST2],[B_KOMM_STATUS],[B_K_REF_TEXT],[MUSE_ID],[W_ISO],[W_KURS],[KE_ID],[KE_BID],[B_HANDBOOKING],[B_IFC_VERSION],[B_TOTAL_RATE],[B_TOTAL_RATE_INCLUSIVE],[B_PERCENT_DISCOUNT],[B_PASSWORD],[BP_KEY],[L_ID],[BCDT_VALUE],[NAV_LOADED],[B_BESTELLER],[B_KEY_ALT],[QUALITY_MA_USER],[QUALITY_CTS],[B_KEY_COMMIT],[B_CANCELLATION],[B_ZAHL_ART],[B_KEY_ROOT],[B_KEY_LAST_NBVL],[B_KEY_LAST_BVL],[B_INFORMATION],[B_OFFER_ID])
   SELECT MB.[B_KEY],MB.[CTS],MB.[K_KEY],MB.[H_KEY],MB.[MA_USER],MinMB.[B_STATUS],MB.[B_DATUM],null,MB.[B_QUELLE],MB.[B_AN_DATUM],MB.[B_AB_DATUM],MB.[B_FIRMA],MB.[B_GAST1],null,null,null,MB.[MUSE_ID],MB.[W_ISO],MB.[W_KURS],MB.[KE_ID],MB.[KE_BID],1 [B_HANDBOOKING],null [B_IFC_VERSION],MB.[B_TOTAL_RATE],MB.[B_TOTAL_RATE_INCLUSIVE],null [B_PERCENT_DISCOUNT],null [B_PASSWORD],MB.[BP_KEY],MB.[L_ID],null [BCDT_VALUE],MB.[NAV_LOADED],MB.[B_BESTELLER],null [B_KEY_ALT],null [QUALITY_MA_USER],null [QUALITY_CTS],MB.[B_KEY_COMMIT],null [B_CANCELLATION],null [B_ZAHL_ART],null [B_KEY_ROOT],null [B_KEY_LAST_NBVL],null [B_KEY_LAST_BVL],null [B_INFORMATION],null [B_OFFER_ID]     
     FROM @MeetagoBuchung MB
	 JOIN MinMB ON MinMB.B_KEY = MB.B_KEY AND MinMB.BT_POS = MB.BT_POS
LEFT JOIN [HRSDB].[BUCHUNG] BU
       ON BU.B_KEY = MB.B_KEY
	WHERE BU.B_KEY IS NULL

;WITH MinMB AS
(
  SELECT [B_KEY], MIN([BT_POS]) [BT_POS], MIN(B_STATUS) B_STATUS FROM @MeetagoBuchung GROUP BY [B_KEY]
)
UPDATE BU SET
       BU.[BP_KEY] = MB.[BP_KEY]
     , BU.[B_KEY_COMMIT] = MB.[B_KEY_COMMIT]
     , BU.[B_AN_DATUM] = MB.[B_AN_DATUM]
     , BU.[B_AB_DATUM] = MB.[B_AB_DATUM]
     , BU.[B_BESTELLER] = MB.[B_BESTELLER]
     , BU.[KE_ID] = CASE WHEN MB.[KE_ID] BETWEEN -32768 AND 32767 THEN MB.[KE_ID] ELSE -1 END
     , BU.[KE_BID] = CASE WHEN MB.[KE_BID] BETWEEN -32768 AND 32767 THEN MB.[KE_BID] ELSE -1 END
     , BU.[H_KEY] = CASE WHEN MB.[H_KEY] BETWEEN -2147483648 AND 2147483647 THEN MB.[H_KEY] ELSE -1 END
     , BU.[L_ID] = MB.[L_ID]
     , BU.[MUSE_ID] = MB.[MUSE_ID]
     , BU.[B_QUELLE] = MB.[B_QUELLE]
     , BU.[CTS] = MB.[CTS]
     , BU.[B_STATUS] = MinMB.[B_STATUS]
     , BU.[B_DATUM] = MB.[B_DATUM]
     , BU.[B_TOTAL_RATE] = MB.[B_TOTAL_RATE]
     , BU.[B_TOTAL_RATE_INCLUSIVE] = MB.[B_TOTAL_RATE_INCLUSIVE]
     , BU.[K_KEY] = CASE WHEN MB.[K_KEY] BETWEEN -2147483648 AND 2147483647 THEN MB.[K_KEY] ELSE -1 END
     , BU.[MA_USER] = MB.[MA_USER]
     , BU.[W_ISO] = MB.[W_ISO]
     , BU.[W_KURS] = MB.[W_KURS]
     , BU.[NAV_LOADED] = MB.[NAV_LOADED]
     , BU.[B_FIRMA] = MB.[B_FIRMA]
     , BU.[B_GAST1] = MB.[B_GAST1]
  FROM [HRSDB].[BUCHUNG] BU
  JOIN @MeetagoBuchung MB
    ON MB.B_KEY = BU.[B_KEY]
  JOIN MinMB ON MinMB.B_KEY = MB.B_KEY AND MinMB.BT_POS = MB.BT_POS
 --WHERE MB.[BT_POS] = 1

   INSERT INTO [HRSDB].[BUCHTEIL]([B_KEY],[CTS],[BT_POS],[BT_VON],[BT_BIS],[BT_ANZAHL],[BT_ZTYP],[BT_RATE_BEZ],[BT_PREIS],[BT_FRSTCK],[BT_FRST_PREIS],[BT_KOMM_ART],[BT_KOMM_SATZ],[BT_KOMM_MWST],[BT_KOMM_FIX],[BT_RATE_TYP],[R_KEY],[BT_ROOM_NUMBER],[BT_PAX_COUNT],[MA_USER],[PRC_TYPE_ID],[H_KEY],[B_STATUS],[B_AB_DATUM],[W_ISO],[W_KURS],[BP_KEY],[L_ID],[MUSE_ID],[BCDT_VALUE],[NAV_LOADED],[BT_NETTO_PREIS],[BT_NETTO_FRST_PREIS])
   SELECT MB.[B_KEY],MB.[CTS],MB.[BT_POS],MB.[BT_VON],MB.[BT_BIS],MB.[BT_ANZAHL],MB.[BT_ZTYP],MB.[BT_RATE_BEZ],MB.[BT_PREIS],MB.[BT_FRSTCK],MB.[BT_FRST_PREIS],MB.[BT_KOMM_ART],MB.[BT_KOMM_SATZ],null [BT_KOMM_MWST],null [BT_KOMM_FIX],MB.[BT_RATE_TYP],MB.[R_KEY],MB.[BT_ROOM_NUMBER],MB.[BT_PAX_COUNT],MB.[MA_USER],MB.[PRC_TYPE_ID],MB.[H_KEY],MB.[B_STATUS],MB.[B_AB_DATUM],MB.[W_ISO],MB.[W_KURS],MB.[BP_KEY],MB.[L_ID],MB.[MUSE_ID],null [BCDT_VALUE],MB.[NAV_LOADED],null [BT_NETTO_PREIS],null [BT_NETTO_FRST_PREIS]     
     FROM @MeetagoBuchung MB
LEFT JOIN [HRSDB].[BUCHTEIL] BT
       ON BT.B_KEY = MB.B_KEY
	  AND BT.BT_POS = MB.BT_POS
	WHERE BT.B_KEY IS NULL

UPDATE BT SET
       BT.[CTS] = MB.[CTS]
     , BT.[BT_VON] = MB.[BT_VON]
     , BT.[BT_BIS] = MB.[BT_BIS]
     , BT.[BT_ANZAHL] = MB.[BT_ANZAHL]
     , BT.[BT_ZTYP] = MB.[BT_ZTYP]
     , BT.[BT_RATE_BEZ] = MB.[BT_RATE_BEZ]
     , BT.[BT_PREIS] = MB.[BT_PREIS]
     , BT.[BT_FRSTCK] = MB.[BT_FRSTCK]
     , BT.[BT_FRST_PREIS] = MB.[BT_FRST_PREIS]
     , BT.[BT_KOMM_ART] = MB.[BT_KOMM_ART]
     , BT.[BT_KOMM_SATZ] = MB.[BT_KOMM_SATZ]
     , BT.[BT_KOMM_MWST] = null
     , BT.[BT_KOMM_FIX] = null
     , BT.[BT_RATE_TYP] = MB.[BT_RATE_TYP]
     , BT.[R_KEY] = CASE WHEN MB.[R_KEY] BETWEEN -2147483648 AND 2147483647 THEN MB.[R_KEY] ELSE -1 END 
     , BT.[BT_ROOM_NUMBER] = MB.[BT_ROOM_NUMBER]
     , BT.[BT_PAX_COUNT] = MB.[BT_PAX_COUNT]
     , BT.[MA_USER] = MB.[MA_USER]
     , BT.[PRC_TYPE_ID] = MB.[PRC_TYPE_ID]
     , BT.[H_KEY] = CASE WHEN MB.[H_KEY] BETWEEN -2147483648 AND 2147483647 THEN MB.[H_KEY] ELSE -1 END
     , BT.[B_STATUS] = MB.[B_STATUS]
     , BT.[B_AB_DATUM] = MB.[B_AB_DATUM]
     , BT.[W_ISO] = MB.[W_ISO]
     , BT.[W_KURS] = MB.[W_KURS]
     , BT.[BP_KEY] = MB.[BP_KEY]
     , BT.[L_ID] = MB.[L_ID]
     , BT.[MUSE_ID] = MB.[MUSE_ID]
     , BT.[BCDT_VALUE] = null
     , BT.[NAV_LOADED] = MB.[NAV_LOADED]
     , BT.[BT_NETTO_PREIS] = null
     , BT.[BT_NETTO_FRST_PREIS] = null
  FROM [HRSDB].[BUCHTEIL] BT
  JOIN @MeetagoBuchung MB
    ON MB.B_KEY = BT.[B_KEY]
   AND BT.BT_POS = MB.BT_POS
END -- IF @Debug<>1   
END
GO
