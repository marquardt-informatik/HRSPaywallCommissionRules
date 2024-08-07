USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_MoveReservation]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_MoveReservation] 
(
    @Debug int = 0
  , @StartDate date = '2020-01-01'
)
AS BEGIN



DECLARE @ToMove TABLE ([Reservation No_] int, [From Company] varchar(30), [To Company] varchar(30), [Table Name] varchar(30))
DECLARE @Cmd1 varchar(max), @Cmd2 varchar(max), @Cmd3 varchar(max), @Cmd4 varchar(max)
DECLARE @CorrectionAgencyHeaderCopyCommand varchar(max) = 'IF NOT EXISTS (SELECT [Reservation No_] FROM [%ToCompany%$Correction Agency Header] WHERE [Reservation No_] = %ReservationNo%) INSERT INTO [%ToCompany%$Correction Agency Header]([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Multisourced],[Corporate Rate Discount],[Booking Comment],[Booking Rating]) SELECT [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Multisourced],[Corporate Rate Discount],[Booking Comment],[Booking Rating] FROM [%FromCompany%$Correction Agency Header] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @CorrectionAgencyHeaderDeleteCommand varchar(max) = 'DELETE FROM [%FromCompany%$Correction Agency Header] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @CorrectionAgencyLineCopyCommand varchar(max) = 'IF NOT EXISTS (SELECT [Reservation No_] FROM [%ToCompany%$Correction Agency Line] WHERE [Reservation No_] = %ReservationNo%) INSERT INTO [%ToCompany%$Correction Agency Line]([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Deductible Amount],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type]) SELECT [Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Deductible Amount],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type]  FROM [%FromCompany%$Correction Agency Line] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @CorrectionAgencyLineDeleteCommand varchar(max) = 'DELETE FROM [%FromCompany%$Correction Agency Line] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @AgencyHeaderCopyCommand varchar(max) = 'IF NOT EXISTS (SELECT [Reservation No_] FROM [%ToCompany%$Agency Header] WHERE [Reservation No_] = %ReservationNo%) INSERT INTO [%ToCompany%$Agency Header]([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Loyality Rewards Account No_],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Ranking Booster],[Payment Type],[TAF Business Rules Code],[Corporate Rate Discount],[Booking Comment],[Multisourced],[Segment],[TAF Contract Code]) SELECT [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Loyality Rewards Account No_],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Ranking Booster],[Payment Type],[TAF Business Rules Code],[Corporate Rate Discount],[Booking Comment],[Multisourced],[Segment],[TAF Contract Code] FROM [%FromCompany%$Agency Header] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @AgencyHeaderDeleteCommand varchar(max) = 'DELETE FROM [%FromCompany%$Agency Header] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @AgencyLineCopyCommand varchar(max) = 'IF NOT EXISTS (SELECT [Reservation No_] FROM [%ToCompany%$Agency Line] WHERE [Reservation No_] = %ReservationNo%) INSERT INTO [%ToCompany%$Agency Line]([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Loyality Rewards Account No_],[Chain],[Brand],[Client No_],[Country_Region Code],[Ranking Booster],[Payment Type],[TAF Business Rules Code],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Breakfast Approval Status],[Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_]) SELECT [Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Loyality Rewards Account No_],[Chain],[Brand],[Client No_],[Country_Region Code],[Ranking Booster],[Payment Type],[TAF Business Rules Code],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Breakfast Approval Status],[Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_] FROM [%FromCompany%$Agency Line] WHERE [Reservation No_] = %ReservationNo%'
DECLARE @AgencyLineDeleteCommand varchar(max) = 'DELETE FROM [%FromCompany%$Agency Line] WHERE [Reservation No_] = %ReservationNo%'

;WITH ToMove AS
(
SELECT [Reservation No_]
     , 'HRS' [From Company]
     , CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END   [To Company]
     , 'Agency Header' [Table Name]
  FROM [HRS$Agency Header] AH WITH (NOLOCK)
  JOIN [HRS$Contact]       CU WITH (NOLOCK)
    ON CU.[No_] = AH.[Hotel No_]
 WHERE CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END <> 'HRS'
UNION
SELECT [Reservation No_]
     , 'HRS-CN' [From Company]
     , CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END   [To Company]
     , 'Agency Header' [Table Name]
  FROM [HRS-CN$Agency Header] AH WITH (NOLOCK)
  JOIN [HRS-CN$Contact]       CU WITH (NOLOCK)
    ON CU.[No_] = AH.[Hotel No_]
 WHERE CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END <> 'HRS-CN'       
 UNION
SELECT [Reservation No_]
     , 'HRS-BR' [From Company]
     , CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END   [To Company]
     , 'Agency Header' [Table Name]
  FROM [HRS-BR$Agency Header] AH WITH (NOLOCK)
  JOIN [HRS-BR$Contact]       CU WITH (NOLOCK)
    ON CU.[No_] = AH.[Hotel No_]
 WHERE CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END <> 'HRS-BR'
  UNION
SELECT [Reservation No_]
     , 'HRS' [From Company]
     , CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END   [To Company]
     , 'Corrected Agency Header' [Table Name]
  FROM [HRS$Correction Agency Header] AH WITH (NOLOCK)
  JOIN [HRS$Contact]       CU WITH (NOLOCK)
    ON CU.[No_] = AH.[Hotel No_]
 WHERE CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END <> 'HRS'
   AND AH.[Departure Date]>= @StartDate
UNION
SELECT [Reservation No_]
     , 'HRS-CN' [From Company]
     , CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END   [To Company]
     , 'Corrected Agency Header' [Table Name]
  FROM [HRS-CN$Correction Agency Header] AH WITH (NOLOCK)
  JOIN [HRS-CN$Contact]       CU WITH (NOLOCK)
    ON CU.[No_] = AH.[Hotel No_]
 WHERE CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END <> 'HRS-CN'       
   AND AH.[Departure Date]>= @StartDate
 UNION
SELECT [Reservation No_]
     , 'HRS-BR' [From Company]
     , CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END   [To Company]
     , 'Corrected Agency Header' [Table Name]
  FROM [HRS-BR$Correction Agency Header] AH WITH (NOLOCK)
  JOIN [HRS-BR$Contact]       CU WITH (NOLOCK)
    ON CU.[No_] = AH.[Hotel No_]
 WHERE CASE
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '29' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-CN'
         WHEN AH.[MuseID] IN ('ELONG','CTRIP','ATOUR','VIENNA','CHINALODGING')                                      THEN 'HRS-CN'
         WHEN                           CU.[Chain] IN ('2025', '1330','1332')                                       THEN 'HRS-CN'
         WHEN AH.[MuseID] = 'HRS'   AND CU.[Country_Region Code] = '23' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS-BR'
		 WHEN AH.[Hotel No_] IN (110331,163957,164062,367018,367020,367022,373234,373236,373237,373238,374575,417072,422470,539060,731711) THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND CU.[Chain] = '28' THEN 'HRS-BR'
		 WHEN CU.[Country_Region Code] = '23' AND AH.[MuseID] = 'ACCOR' THEN 'HRS-BR'
         ELSE                                                                                                            'HRS'
       END <> 'HRS-BR'         
   AND AH.[Departure Date]>= @StartDate
)
INSERT INTO @ToMove
SELECT * FROM ToMove

DECLARE cur CURSOR FOR
SELECT * FROM @ToMove

DECLARE @Total int = 0, @Finished int = 0
SELECT @Total = COUNT(1) FROM @ToMove

DECLARE @ReservationNo int, @FromCompany varchar(30), @ToCompany varchar(30), @TableName varchar(30)

OPEN cur

FETCH NEXT FROM cur INTO @ReservationNo, @FromCompany, @ToCompany, @TableName 

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @Finished = @Finished + 1
  IF @Debug=1
    PRINT CAST(@Finished as varchar(20))
    + ' von ' + CAST(@Total as varchar(20))
	+ ' erledigt'
    + ' = ' +LEFT(CAST(ROUND(100.0 * @Finished/@Total,5) AS varchar(15)),8)
	+ ' %'
	+ ', Rest : ' + CAST(@Total-@Finished as varchar(20))
  IF @TableName = 'Corrected Agency Header'
  BEGIN
	  SET @Cmd1 = REPLACE(REPLACE(REPLACE(@CorrectionAgencyHeaderCopyCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
	  SET @Cmd2 = REPLACE(REPLACE(REPLACE(@CorrectionAgencyHeaderDeleteCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
	  SET @Cmd3 = REPLACE(REPLACE(REPLACE(@CorrectionAgencyLineCopyCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
	  SET @Cmd4 = REPLACE(REPLACE(REPLACE(@CorrectionAgencyLineDeleteCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
  END
  IF @TableName = 'Agency Header'
  BEGIN
	  SET @Cmd1 = REPLACE(REPLACE(REPLACE(@AgencyHeaderCopyCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
	  SET @Cmd2 = REPLACE(REPLACE(REPLACE(@AgencyHeaderDeleteCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
	  SET @Cmd3 = REPLACE(REPLACE(REPLACE(@AgencyLineCopyCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
	  SET @Cmd4 = REPLACE(REPLACE(REPLACE(@AgencyLineDeleteCommand
		, '%ReservationNo%', CAST(@ReservationNo AS varchar(20)))
		, '%FromCompany%'  , @FromCompany)
		, '%ToCompany%'    , @ToCompany)
  END
  BEGIN TRANSACTION
  
  BEGIN TRY
    EXEC(@Cmd1)
    EXEC(@Cmd2)
    EXEC(@Cmd3)
    EXEC(@Cmd4)
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
      PRINT @Cmd1
      PRINT @Cmd2
      PRINT @Cmd3
      PRINT @Cmd4
      ROLLBACK TRANSACTION
    END
  END CATCH
  
  IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
    

  FETCH NEXT FROM cur INTO @ReservationNo, @FromCompany, @ToCompany, @TableName
END

CLOSE cur
DEALLOCATE cur
END
GO
