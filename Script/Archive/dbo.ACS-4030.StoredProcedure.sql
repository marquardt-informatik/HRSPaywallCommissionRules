USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[ACS-4030]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 22.09.2022
-- Description:	ACS-4030 Hardcoded Segment Setting due to an error in booking engine
-- =============================================
CREATE PROCEDURE [dbo].[ACS-4030] AS BEGIN
    UPDATE BU SET 
        BU.B_SEGMENT =
        CASE [EXTERNAL_BOOKING_SEGMENT]
            WHEN '96189273' THEN 2  -- Leisure
            WHEN '96068766' THEN 
            CASE
                WHEN BT.BT_KOMM_ART=13 THEN 4 -- Corporate managed net
                ELSE 3 -- Corporate managed commissionable
            END
            WHEN '96078581' THEN 1 -- corporate unmanaged
        END
    FROM HRSDB.BUCHTEIL BT WITH (NOLOCK) 
    JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BT.B_KEY=BU.B_KEY
    WHERE BU.KE_BID = 550
    AND BU.[EXTERNAL_BOOKING_SEGMENT] IN ('96189273','96068766','96078581')
    AND BU.B_AB_DATUM >= '2022-09-01'
    AND BU.B_SEGMENT <>
        CASE [EXTERNAL_BOOKING_SEGMENT]
            WHEN '96189273' THEN 2  -- Leisure
            WHEN '96068766' THEN 
            CASE
                WHEN BT.BT_KOMM_ART=13 THEN 4 -- Corporate managed net
                ELSE 3 -- Corporate managed commissionable
            END
            WHEN '96078581' THEN 1 -- corporate unmanaged
        END

 UPDATE AH SET AH.[Segment] = BU.B_SEGMENT
   FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   JOIN [HRS$Agency Header] AH WITH (NOLOCK) ON CAST(BU.B_KEY AS varchar(20))=AH.[Reservation No_]
  WHERE BU.KE_BID = 550
    AND BU.[EXTERNAL_BOOKING_SEGMENT] IN ('96189273','96068766','96078581')
    AND BU.B_AB_DATUM >= '2022-09-01'
    AND BU.B_SEGMENT<>AH.[Segment]

 UPDATE AH SET AH.[Segment] = BU.B_SEGMENT
   FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   JOIN [HRS-BR$Agency Header] AH WITH (NOLOCK) ON CAST(BU.B_KEY AS varchar(20))=AH.[Reservation No_]
  WHERE BU.KE_BID = 550
    AND BU.[EXTERNAL_BOOKING_SEGMENT] IN ('96189273','96068766','96078581')
    AND BU.B_AB_DATUM >= '2022-09-01'
    AND BU.B_SEGMENT<>AH.[Segment]

 UPDATE AH SET AH.[Segment] = BU.B_SEGMENT
   FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK) ON CAST(BU.B_KEY AS varchar(20))=AH.[Reservation No_]
  WHERE BU.KE_BID = 550
    AND BU.[EXTERNAL_BOOKING_SEGMENT] IN ('96189273','96068766','96078581')
    AND BU.B_AB_DATUM >= '2022-09-01'
    AND BU.B_SEGMENT<>AH.[Segment]
END
GO
