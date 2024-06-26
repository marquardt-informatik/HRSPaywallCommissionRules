USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_CorrectSegmentByIATA]    Script Date: 10.04.2024 14:31:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================================================================
-- Author:		Thomas Marquardt
-- Create date: 23.01.2023
-- Description:	Correct Segment by Configuration in NAV
--
-- Date       | Version |  Ticket  | Sign | Description
-- -----------+---------+----------+------+----------------------------------------------------------
-- 23.01.2023   HRS001    ACS-4208    TMA04   Segment by IATA
-- ================================================================================================
CREATE PROC [dbo].[sp_CorrectSegmentByIATA]
AS
BEGIN
UPDATE BU SET 
       BU.B_SEGMENT=SI.[Segment]
  FROM HRSDB.BUCHTEIL BT 
  JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) 
    ON BT.B_KEY=BU.B_KEY
  JOIN [Segmentation by IATA] SI 
    ON SI.IATA=BU.EXTERNAL_BOOKING_SEGMENT
   AND SI.MuseID=BU.MUSE_ID
   AND SI.Active=1
   AND BU.B_AB_DATUM >= SI.[Valid from]
   AND (
           (BT.BT_KOMM_ART<>13 AND SI.[Commission Type] IN (0,2)) 
        OR (BT.BT_KOMM_ART=13  AND SI.[Commission Type] IN (1))
       )
 WHERE SI.[Segment]<>BU.B_SEGMENT
   AND BU.B_AB_DATUM>='2022-01-01'

UPDATE AH SET AH.Segment = BU.B_SEGMENT
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
  JOIN [HRS$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = CAST(BU.B_KEY AS VARCHAR(20))
 WHERE BU.B_AB_DATUM >= '2022-01-01'
   AND AH.Segment <> BU.B_SEGMENT;

UPDATE AH SET AH.Segment = BU.B_SEGMENT
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
  JOIN [HRS-BR$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = CAST(BU.B_KEY AS VARCHAR(20))
 WHERE BU.B_AB_DATUM >= '2022-01-01'
   AND AH.Segment <> BU.B_SEGMENT;

UPDATE AH SET AH.Segment = BU.B_SEGMENT
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
  JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = CAST(BU.B_KEY AS VARCHAR(20))
 WHERE BU.B_AB_DATUM >= '2022-01-01'
   AND AH.Segment <> BU.B_SEGMENT;
END
GO
