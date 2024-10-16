USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_MoveToParkingPosition_HRS-BR]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 16.04.2020
-- Description:	Verschieben der stornierten Reservierungen von [HRS-BR$Agency Header] nach [HRS-BR$Correction Agency Header]
--              Verschieben der stornierten Reservierungen von [HRS-BR$Agency Line] nach [HRS-BR$Correction Agency Line]
/*
EXEC [dbo].[sp_MoveToParkingPosition_HRS-BR]
*/
-- ================================================
CREATE PROC [dbo].[sp_MoveToParkingPosition_HRS-BR] AS
BEGIN
SET NOCOUNT ON
DECLARE @RecreateCH int = 1
      , @CountCH int = -1

IF @RecreateCH=1
  IF OBJECT_ID('tempdb..#CH') IS NOT NULL
    DROP TABLE #CH

IF OBJECT_ID('tempdb..#CH') IS NOT NULL
  SELECT @CountCH=COUNT(1) FROM #CH

IF @CountCH=0
  DROP TABLE #CH

IF OBJECT_ID('tempdb..#CH') IS NULL
BEGIN
  CREATE TABLE #CH ([Reservation No_][varchar](20) COLLATE Latin1_General_CS_AS PRIMARY KEY,[Client No_][int],[Hotel No_][varchar](20),[Reservation Activator][varchar](8),[Reservation State][int],[Reservation Date][datetime],[Reservation Time][datetime],[Reservation Source][int],[Arrival Date][datetime],[Departure Date][datetime],[Client Company][varchar](80),[Client Guestname 1][varchar](120),[Client Guestname 2][varchar](120),[Commission Status][int],[Description][varchar](70),[MuseID][varchar](20),[Currency Code][varchar](3),[Currency Factor][decimal](38, 20),[Chain ID][varchar](10),[Brand ID][varchar](10),[Handbooking][tinyint],[timestamp Source][datetime],[IFC Version][int],[Total Rate][decimal](38, 20),[Total Rate incl_][decimal](38, 20),[Discount %][decimal](38, 20),[MusePassword][varchar](80),[ProcessNumber][int],[Job No_][varchar](20),[Customer No_][varchar](20),[Booking Status][int],[Inserted by User][varchar](20),[Inserted at][datetime],[Modified by User][varchar](20),[Modified at][datetime],[Insert Header][tinyint],[Error Code][int],[Contract Code][varchar](20),[Contract Group Code][varchar](20),[Agency Business Rules Code][varchar](20),[Parent Reservation No_][varchar](20),[Confirmed Reservation No_][varchar](20),[Quality by User][varchar](20),[Quality at][datetime],[Company No_][varchar](20),[Final Cancellation][tinyint],[Inquiry Sent][tinyint],[Inquiry Sent At][datetime],[Ranking Booster][decimal](38, 20),[Corporate Rate Discount][int],[Booking Comment][tinyint],[Booking Rating][tinyint],[Multisourced][tinyint]) 

  INSERT INTO #CH ([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced])
  SELECT [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],0,0,'1753-01-01',[Ranking Booster],[Corporate Rate Discount],[Booking Comment],0,[Multisourced]
    FROM [HRS-BR$Agency Header] AH WITH (NOLOCK)
   WHERE AH.[Reservation State] = 10000
     --AND NOT [Reservation No_] IN (SELECT [Reservation No_] FROM [HRS-BR$Correction Agency Header] CH WITH (NOLOCK))
END

SELECT @CountCH=COUNT(1) FROM #CH

WHILE @CountCH>0 
BEGIN
  IF OBJECT_ID('tempdb..#CHH') IS NOT NULL
    DROP TABLE #CHH
  CREATE TABLE #CHH ([Reservation No_][varchar](20) COLLATE Latin1_General_CS_AS PRIMARY KEY,[Client No_][int],[Hotel No_][varchar](20),[Reservation Activator][varchar](8),[Reservation State][int],[Reservation Date][datetime],[Reservation Time][datetime],[Reservation Source][int],[Arrival Date][datetime],[Departure Date][datetime],[Client Company][varchar](80),[Client Guestname 1][varchar](120),[Client Guestname 2][varchar](120),[Commission Status][int],[Description][varchar](70),[MuseID][varchar](20),[Currency Code][varchar](3),[Currency Factor][decimal](38, 20),[Chain ID][varchar](10),[Brand ID][varchar](10),[Handbooking][tinyint],[timestamp Source][datetime],[IFC Version][int],[Total Rate][decimal](38, 20),[Total Rate incl_][decimal](38, 20),[Discount %][decimal](38, 20),[MusePassword][varchar](80),[ProcessNumber][int],[Job No_][varchar](20),[Customer No_][varchar](20),[Booking Status][int],[Inserted by User][varchar](20),[Inserted at][datetime],[Modified by User][varchar](20),[Modified at][datetime],[Insert Header][tinyint],[Error Code][int],[Contract Code][varchar](20),[Contract Group Code][varchar](20),[Agency Business Rules Code][varchar](20),[Parent Reservation No_][varchar](20),[Confirmed Reservation No_][varchar](20),[Quality by User][varchar](20),[Quality at][datetime],[Company No_][varchar](20),[Final Cancellation][tinyint],[Inquiry Sent][tinyint],[Inquiry Sent At][datetime],[Ranking Booster][decimal](38, 20),[Corporate Rate Discount][int],[Booking Comment][tinyint],[Booking Rating][tinyint],[Multisourced][tinyint]) 

  INSERT INTO #CHH ([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced])
  SELECT TOP(1000) [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced] FROM #CH

  INSERT INTO [HRS-BR$Correction Agency Header] ([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced])
  SELECT [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced] FROM #CHH WHERE NOT [Reservation No_] IN (SELECT [Reservation No_] FROM [HRS-BR$Correction Agency Header])

  DELETE FROM AH  FROM [HRS-BR$Agency Header] AH JOIN #CHH ON AH.[Reservation No_] = #CHH.[Reservation No_]

  DELETE FROM #CH FROM #CH JOIN #CHH ON #CH.[Reservation No_] = #CHH.[Reservation No_]

  SELECT @CountCH=COUNT(1) FROM #CH
  PRINT @CountCH
END

-- Verschieben der "verwaisten" Zeilen von [HRS-BR$Agency Line] zu [HRS-BR$Correction Agency Line]
DECLARE @RecreateCL int = 0
      , @CountCL int = -1

IF @RecreateCL=1
  IF OBJECT_ID('tempdb..#CL') IS NOT NULL
    DROP TABLE #CL

IF OBJECT_ID('tempdb..#CL') IS NOT NULL
  SELECT @CountCL=COUNT(1) FROM #CL

IF @CountCL=0
  DROP TABLE #CL

IF OBJECT_ID('tempdb..#CL') IS NULL
BEGIN
  CREATE TABLE #CL([Reservation No_] [varchar](20) COLLATE Latin1_General_CS_AS,[Position No_] [int],[Reservation Status] [int],[Reservation Date from] [datetime],[Reservation Date to] [datetime],[Number of Rooms] [int],[Room Type] [int],[Rate Description] [varchar](100),[Room Price] [decimal](38, 20),[Breakfast Type] [int],[Breakfast Price] [decimal](38, 20),[Commission Type] [int],[Commission Rate] [decimal](38, 20),[Commission Fix] [decimal](38, 20),[Rate Type] [int],[Rate Key] [int],[Currency Code] [varchar](3),[Currency Faktor] [decimal](38, 20),[Room Number] [int],[Activity Code] [varchar](40),[Number of Person] [int],[Hotel No_] [varchar](20),[Commission Tax Type] [int],[timestamp Source] [datetime],[Price Type] [int],[Process Number] [int],[Inserted by User] [varchar](20),[Inserted at] [datetime],[Modified by User] [varchar](20),[Modified at] [datetime],[Number of Nights] [decimal](38, 20),[Commission Base Amount] [decimal](38, 20),[Commission Amount] [decimal](38, 20),[Commission Base Amount (LCY)] [decimal](38, 20),[Commission Amount (LCY)] [decimal](38, 20),[Foreign Tax %] [decimal](38, 20),[Foreign Tax Amount] [decimal](38, 20),[Line Amount] [decimal](38, 20),[Line Amount (LCY)] [decimal](38, 20),[Foreign Tax Base Amount] [decimal](38, 20),[Hotel sales incl_ VAT] [decimal](38, 20),[Calculated with Contract Code] [varchar](20),[Calculated with Function ID] [varchar](10),[Calculated with Function Desc_] [varchar](100),[Final Cancellation] [tinyint],[Ranking Booster] [decimal](38, 20),[Corporate Rate Discount] [int],[Net Room Price] [decimal](38, 20),[Net Breakfast Price] [decimal](38, 20),[Deduction Type] [int],[Deductible Amount] [decimal](38, 20),CONSTRAINT [PK_BR#CL] PRIMARY KEY CLUSTERED([Reservation No_] ASC,[Position No_] ASC))
  INSERT INTO #CL ([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type],[Deductible Amount])
  SELECT AL.[Reservation No_],AL.[Position No_],AL.[Reservation Status],AL.[Reservation Date from],AL.[Reservation Date to],AL.[Number of Rooms],AL.[Room Type],AL.[Rate Description],AL.[Room Price],AL.[Breakfast Type],AL.[Breakfast Price],AL.[Commission Type],AL.[Commission Rate],AL.[Commission Fix],AL.[Rate Type],AL.[Rate Key],AL.[Currency Code],AL.[Currency Faktor],AL.[Room Number],AL.[Activity Code],AL.[Number of Person],AL.[Hotel No_],AL.[Commission Tax Type],AL.[timestamp Source],AL.[Price Type],AL.[Process Number],AL.[Inserted by User],AL.[Inserted at],AL.[Modified by User],AL.[Modified at],AL.[Number of Nights],AL.[Commission Base Amount],AL.[Commission Amount],AL.[Commission Base Amount (LCY)],AL.[Commission Amount (LCY)],AL.[Foreign Tax %],AL.[Foreign Tax Amount],AL.[Line Amount],AL.[Line Amount (LCY)],AL.[Foreign Tax Base Amount],AL.[Hotel sales incl_ VAT],AL.[Calculated with Contract Code],AL.[Calculated with Function ID],AL.[Calculated with Function Desc_],0,AL.[Ranking Booster],AL.[Corporate Rate Discount],AL.[Net Room Price],AL.[Net Breakfast Price],AL.[Deduction Type],AL.[Deductible Amount]
    FROM [HRS-BR$Agency Line] AL WITH (NOLOCK)
    JOIN [HRS-BR$Correction Agency Header] CH WITH (NOLOCK)
	  ON CH.[Reservation No_] = AL.[Reservation No_]
END

SELECT @CountCL=COUNT(1) FROM #CL

WHILE @CountCL>0 
BEGIN
  IF OBJECT_ID('tempdb..#CLL') IS NOT NULL
    DROP TABLE #CLL
  CREATE TABLE #CLL ([Reservation No_] [varchar](20) COLLATE Latin1_General_CS_AS,[Position No_] [int],[Reservation Status] [int],[Reservation Date from] [datetime],[Reservation Date to] [datetime],[Number of Rooms] [int],[Room Type] [int],[Rate Description] [varchar](100),[Room Price] [decimal](38, 20),[Breakfast Type] [int],[Breakfast Price] [decimal](38, 20),[Commission Type] [int],[Commission Rate] [decimal](38, 20),[Commission Fix] [decimal](38, 20),[Rate Type] [int],[Rate Key] [int],[Currency Code] [varchar](3),[Currency Faktor] [decimal](38, 20),[Room Number] [int],[Activity Code] [varchar](40),[Number of Person] [int],[Hotel No_] [varchar](20),[Commission Tax Type] [int],[timestamp Source] [datetime],[Price Type] [int],[Process Number] [int],[Inserted by User] [varchar](20),[Inserted at] [datetime],[Modified by User] [varchar](20),[Modified at] [datetime],[Number of Nights] [decimal](38, 20),[Commission Base Amount] [decimal](38, 20),[Commission Amount] [decimal](38, 20),[Commission Base Amount (LCY)] [decimal](38, 20),[Commission Amount (LCY)] [decimal](38, 20),[Foreign Tax %] [decimal](38, 20),[Foreign Tax Amount] [decimal](38, 20),[Line Amount] [decimal](38, 20),[Line Amount (LCY)] [decimal](38, 20),[Foreign Tax Base Amount] [decimal](38, 20),[Hotel sales incl_ VAT] [decimal](38, 20),[Calculated with Contract Code] [varchar](20),[Calculated with Function ID] [varchar](10),[Calculated with Function Desc_] [varchar](100),[Final Cancellation] [tinyint],[Ranking Booster] [decimal](38, 20),[Corporate Rate Discount] [int],[Net Room Price] [decimal](38, 20),[Net Breakfast Price] [decimal](38, 20),[Deduction Type] [int],[Deductible Amount] [decimal](38, 20),CONSTRAINT [PK_BR#CLL] PRIMARY KEY CLUSTERED([Reservation No_] ASC,[Position No_] ASC))

  INSERT INTO #CLL ([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type],[Deductible Amount])
  SELECT TOP(1000) [Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type],[Deductible Amount] FROM #CL

  INSERT INTO [HRS-BR$Correction Agency Line] ([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type],[Deductible Amount])
  SELECT CLL.[Reservation No_],CLL.[Position No_],CLL.[Reservation Status],CLL.[Reservation Date from],CLL.[Reservation Date to],CLL.[Number of Rooms],CLL.[Room Type],CLL.[Rate Description],CLL.[Room Price],CLL.[Breakfast Type],CLL.[Breakfast Price],CLL.[Commission Type],CLL.[Commission Rate],CLL.[Commission Fix],CLL.[Rate Type],CLL.[Rate Key],CLL.[Currency Code],CLL.[Currency Faktor],CLL.[Room Number],CLL.[Activity Code],CLL.[Number of Person],CLL.[Hotel No_],CLL.[Commission Tax Type],CLL.[timestamp Source],CLL.[Price Type],CLL.[Process Number],CLL.[Inserted by User],CLL.[Inserted at],CLL.[Modified by User],CLL.[Modified at],CLL.[Number of Nights],CLL.[Commission Base Amount],CLL.[Commission Amount],CLL.[Commission Base Amount (LCY)],CLL.[Commission Amount (LCY)],CLL.[Foreign Tax %],CLL.[Foreign Tax Amount],CLL.[Line Amount],CLL.[Line Amount (LCY)],CLL.[Foreign Tax Base Amount],CLL.[Hotel sales incl_ VAT],CLL.[Calculated with Contract Code],CLL.[Calculated with Function ID],CLL.[Calculated with Function Desc_],CLL.[Final Cancellation],CLL.[Ranking Booster],CLL.[Corporate Rate Discount],CLL.[Net Room Price],CLL.[Net Breakfast Price],CLL.[Deduction Type],CLL.[Deductible Amount] FROM #CLL CLL
  LEFT JOIN [HRS-BR$Correction Agency Line] CL ON CLL.[Reservation No_] = CL.[Reservation No_] AND CLL.[Position No_] = CL.[Position No_] WHERE CL.[Reservation No_] IS NULL

  DELETE FROM AL  FROM [HRS-BR$Agency Line] AL JOIN #CLL ON AL.[Reservation No_] = #CLL.[Reservation No_] AND AL.[Position No_] = #CLL.[Position No_]

  DELETE FROM #CL FROM #CL JOIN #CLL ON #CL.[Reservation No_] = #CLL.[Reservation No_] AND #CL.[Position No_] = #CLL.[Position No_]

  SELECT @CountCL=COUNT(1) FROM #CL
  PRINT @CountCL
END

END
GO
