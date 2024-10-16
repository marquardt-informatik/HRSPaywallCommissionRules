USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateCancelationStatistics_Shortage_HRS-CN]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.04.2020
-- Description:	Populates [HRS-CN$Cancellation Statistics] with statistics of night cancellations
--
/*
EXEC [sp_UpdateCancelationStatistics_Shortage_HRS-CN] '2020-01-01','2020-01-31'
*/
CREATE PROCEDURE [dbo].[sp_UpdateCancelationStatistics_Shortage_HRS-CN](
        @DateFrom DATE = '2020-03-01'
      , @DateTo DATE = '2020-03-31'
) AS BEGIN
  DECLARE @ActicityCode varchar(20) = 'ITELYA_SHORT'

DECLARE @RecreateINV int=0
      , @CountINV int = -1
	  , @RecreateDL int = 1
	  , @CountDL int = -1
	  , @RecreateCH int = 1
      , @CountCH int = -1


IF @RecreateINV=1
  IF OBJECT_ID('tempdb..#INV') IS NOT NULL
    DROP TABLE #INV

IF OBJECT_ID('tempdb..#INV') IS NOT NULL
  SELECT @CountINV=COUNT(1) FROM #INV

IF @CountINV=0
  DROP TABLE #INV

IF OBJECT_ID('tempdb..#INV') IS NULL
BEGIN     
  CREATE TABLE #INV ([Process No_] int PRIMARY KEY, [Document Date] date, [Hotel No_] int, [Client No_] int, [Total Rate incl_]  dec(38,20), [Total Rate]  dec(38,20), [Currency Code] varchar(10) COLLATE Latin1_General_CS_AS, [Arrival Date] date, [Departure Date] date, [Version] int, [Payment Method] int, [Breakfast]  dec(38,20), [Breakfast incl_ VAT] dec(38,20), [Logis] dec(38,20), [Logis incl_ VAT] dec(38,20), [Hotel Turnover] dec(38,20), [Hotel Turnover incl_ VAT] dec(38,20))
  ;WITH INL AS
  (
    SELECT INL.OR_INVOICE_ID_VALUE
         , SUM(CASE WHEN INL.SERVICE_CODE IN ('BRE','FAB')                           THEN INL.AMOUNT_BEFORE_TAX ELSE 0 END) [Breakfast]
         , SUM(CASE WHEN INL.SERVICE_CODE IN ('BRE','FAB')                           THEN INL.AMOUNT_AFTER_TAX  ELSE 0 END) [Breakfast incl_ VAT]
         , SUM(CASE WHEN INL.SERVICE_CODE IN ('LOG','NOS','NOS-A','STR')             THEN INL.AMOUNT_BEFORE_TAX ELSE 0 END) [Logis]
         , SUM(CASE WHEN INL.SERVICE_CODE IN ('LOG','NOS','NOS-A','STR')             THEN INL.AMOUNT_AFTER_TAX  ELSE 0 END) [Logis incl_ VAT]
	     , SUM(CASE WHEN INL.SERVICE_CODE IN ('BRE','FAB','LOG','NOS','NOS-A','STR') THEN INL.AMOUNT_BEFORE_TAX ELSE 0 END) [Hotel Turnover]
	     , SUM(CASE WHEN INL.SERVICE_CODE IN ('BRE','FAB','LOG','NOS','NOS-A','STR') THEN INL.AMOUNT_AFTER_TAX  ELSE 0 END) [Hotel Turnover incl. VAT]
	     , MAX(CASE WHEN INL.SERVICE_CODE IN ('NOS','NOS-A','STR')                   THEN 1                     ELSE 0 END) [NoShow]
      FROM HRSDB.CIA_PS_INVOICE_POSITION INL WITH (NOLOCK)
  GROUP BY INL.OR_INVOICE_ID_VALUE
  ), _INV AS
  (
    SELECT INV.BOOKING_PROCESS_ID_VALUE [Process No_]
         , INV.INVOICE_NO               [External Document No_]
	     , INV.INVOICE_DATE             [Document Date]
	     , INV.HOTEL_ID_VALUE           [Hotel No_]
	     , INV.COMPANY_ID_VALUE         [Client No_]
	     , INV.AMOUNT_AFTER_TAX         [Total Rate incl_]
	     , INV.AMOUNT_BEFORE_TAX        [Total Rate]
	     , INV.INVOICE_CURRENCY         [Currency Code]
	     , INV.DATE_OF_STAY_FROM_DATE   [Arrival Date]
	     , INV.DATE_OF_STAY_TO_DATE     [Departure Date]
	     , INV.VERSION_COUNTER          [Version]
	     , INV.PAYMENT_METHOD           [Payment Method]   
	     , INL.[Breakfast]
	     , INL.[Breakfast incl_ VAT]
	     , INL.[Logis]
	     , INL.[Logis incl_ VAT]
	     , INL.[Hotel Turnover]
	     , INL.[Hotel Turnover incl. VAT]
      FROM HRSDB.CIA_PS_INVOICE INV WITH (NOLOCK)
      JOIN INL
        ON INL.OR_INVOICE_ID_VALUE = INV.INVOICE_ID_VALUE
     WHERE INV.INVOICE_STATUS<>'invalid'
  ), INV AS
  (
    SELECT [Process No_]
         , MAX([Document Date])            [Document Date]
	     , MAX([Hotel No_])                [Hotel No_]
	     , MAX([Client No_])               [Client No_]
	     , SUM([Total Rate incl_])         [Total Rate incl_]
	     , SUM([Total Rate])               [Total Rate]
	     , MAX([Currency Code])            [Currency Code]
	     , MIN([Arrival Date])             [Arrival Date]
	     , MAX([Departure Date])           [Departure Date]
	     , MAX([Version])                  [Version]
	     , MAX([Payment Method])           [Payment Method]
	     , SUM([Breakfast])                [Breakfast]
	     , SUM([Breakfast incl_ VAT])      [Breakfast incl_ VAT]
	     , SUM([Logis])                    [Logis]
	     , SUM([Logis incl_ VAT])          [Logis incl_ VAT]
	     , SUM([Hotel Turnover])           [Hotel Turnover]
	     , SUM([Hotel Turnover incl. VAT]) [Hotel Turnover incl_ VAT]
      FROM _INV
  GROUP BY [Process No_]
  )
  INSERT INTO #INV
  SELECT * FROM INV WHERE [Departure Date] BETWEEN @DateFrom AND @DateTo
END


IF @RecreateDL=1
  IF OBJECT_ID('tempdb..#DL') IS NOT NULL
    DROP TABLE #DL

IF OBJECT_ID('tempdb..#DL') IS NOT NULL
  SELECT @CountDL=COUNT(1) FROM #DL

IF @CountDL=0
  DROP TABLE #DL

IF OBJECT_ID('tempdb..#DL') IS NULL
BEGIN  
  CREATE TABLE #DL([Process No_] int PRIMARY KEY, [Display Case No_] varchar(20) COLLATE Latin1_General_CS_AS, [MuseID] varchar(20) COLLATE Latin1_General_CS_AS, [Currency Code] varchar(10) COLLATE Latin1_General_CS_AS, [Arrival Date] date, [Departure Date] date, [Logis] dec(38,20), [Logis incl_ VAT] dec(38,20), [Breakfast]  dec(38,20), [Breakfast incl_ VAT] dec(38,20), [Hotel Turnover incl_ VAT] dec(38,20), [Breakfast Type] int) 
  ;WITH DH AS
  (
    SELECT DL.[ProcessNumber]
         , MAX(REPLACE(DL.[Display Case No_],'V','A')) [Display Case No_]
      FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
      JOIN #INV INV
        ON INV.[Process No_] = DL.[ProcessNumber]
  GROUP BY DL.[ProcessNumber]
  ), DL AS
  (
    SELECT DL.[ProcessNumber]
	     , DL.[Display Case No_]
	     , MAX([MuseID])                   [MuseID]
	     , MAX(CASE WHEN [Action]<>3                        THEN [Currency Code]                                                                     ELSE ''           END) [Currency Code]
	     , MIN(CASE WHEN [Action]<>3                        THEN [Arrival Date]                                                                      ELSE '1753-01-01' END) [Arrival Date]
	     , MAX(CASE WHEN [Action]<>3                        THEN [Departure Date]                                                                    ELSE '1753-01-01' END) [Departure Date]
		 , SUM(CASE WHEN [Action]<>3                        THEN [Number of Rooms] * [Number of Nights] * [Net Room Price]                           ELSE 0 END) [Logis]
		 , SUM(CASE WHEN [Action]<>3                        THEN [Number of Rooms] * [Number of Nights] * [Room Price]                               ELSE 0 END) [Logis incl. VAT]
		 , SUM(CASE WHEN [Action]<>3 AND [Breakfast Type]=1 THEN [Number of Person] * [Number of Rooms] * [Number of Nights] * [Net Breakfast Price] ELSE 0 END) [Breakfast]
		 , SUM(CASE WHEN [Action]<>3 AND [Breakfast Type]=1 THEN [Number of Person] * [Number of Rooms] * [Number of Nights] * [Breakfast Price]     ELSE 0 END) [Breakfast incl. VAT]
		 , SUM(CASE WHEN [Action]<>3                        THEN [Number of Nights] * [Hotel sales incl_ VAT]                                                                                                          ELSE 0 END) [Hotel sales incl_ VAT]
		 , MAX([Breakfast Type]) [Breakfast Type]
      FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
	  JOIN DH
        ON DH.[Display Case No_] = REPLACE(DL.[Display Case No_],'V','A')
       AND DH.[ProcessNumber] = DL.[ProcessNumber]
  GROUP BY DL.[ProcessNumber]
	     , DL.[Display Case No_]
  )
  INSERT INTO #DL
  SELECT * FROM DL 
END

;WITH BC AS
(
  SELECT INV.[Hotel No_]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,INV.[Departure Date])+1, INV.[Departure Date]))) [Assigned Posting Date]
	   , COUNT(DISTINCT CASE WHEN INV.[Hotel Turnover incl_ VAT]>DL.[Hotel Turnover incl_ VAT] THEN INV.[Process No_]ELSE NULL END) [Bookings with RN Reduction]
	   , CAST(CASE WHEN SUM(DATEDIFF(dd,INV.[Arrival Date],INV.[Departure Date]))=0 THEN 100 ELSE SUM(DATEDIFF(dd,INV.[Arrival Date],INV.[Departure Date])-DATEDIFF(dd,DL.[Arrival Date],DL.[Departure Date]))*1.0/SUM(DATEDIFF(dd,INV.[Arrival Date],INV.[Departure Date]))*100.0 END AS INTEGER) [Roomnights Reduction Rate %]
    FROM #INV INV
    JOIN #DL DL
      ON DL.[Process No_] = INV.[Process No_]
   WHERE DATEDIFF(dd,INV.[Arrival Date],INV.[Departure Date])>DATEDIFF(dd,DL.[Arrival Date],DL.[Departure Date])
	 AND NOT DL.MuseID = 'EAN'
	 AND DL.[Arrival Date]<>'1753-01-01'
GROUP BY INV.[Hotel No_]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,INV.[Departure Date])+1, INV.[Departure Date])))
)
  UPDATE CS SET 
         CS.[Bookings with RN Reduction] = BC.[Bookings with RN Reduction]
       , CS.[Roomnights Reduction Rate %] = BC.[Roomnights Reduction Rate %]
    FROM [HRS-CN$Cancellation Statistics] CS
	JOIN BC
	  ON CS.[Hotel No_] = BC.[Hotel No_]
     AND CS.[Assigned Posting Date] = BC.[Assigned Posting Date]
   WHERE CS.[Bookings with RN Reduction] <> BC.[Bookings with RN Reduction]
      OR CS.[Roomnights Reduction Rate %] <> BC.[Roomnights Reduction Rate %]
-- create missing entries in [HRS-CN$Correction Agency Header]
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
  ;WITH BP AS (SELECT BP_KEY,MAX(B_KEY) B_KEY, MAX(CTS) CTS FROM HRSDB.BKG_PROCESS_LIST_ALL_DA WITH (NOLOCK) GROUP BY BP_KEY)
  INSERT INTO #CH ([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced])
   SELECT BP.B_KEY [Reservation No_]
        , INV.[Client No_]
		, INV.[Hotel No_]
		, 'ITELYA'
		, 10000 [Reservation State]
		, BU.B_DATUM [Reservation Date]
		, '1754-01-01' [Reservation Time]
		, BU.B_QUELLE [Reservation Source]
		, INV.[Arrival Date]
		, INV.[Departure Date]
		, BU.B_FIRMA [Client Company]
		, BU.B_GAST1 [Client Guestname 1]
		, COALESCE(BU.B_GAST2,'') [Client Guestname 2]
		, 0 [Commission Status]
		, BU.B_INFORMATION [Description]
		, BU.MUSE_ID [MuseID]
		, BU.W_ISO [Currency Code]
		, 100000 / CASE WHEN BU.W_KURS=0 THEN 1 ELSE BU.W_KURS END [Currency Factor]
		, COALESCE(BU.KE_BID,'99999') [Chain ID]
		, COALESCE(BU.KE_ID,'99999') [Brand ID]
		, BU.B_HANDBOOKING [Handbooking]
		, BU.CTS [timestamp Source]
		, BU.B_IFC_VERSION [IFC Version]
		, INV.[Hotel Turnover incl_ VAT]-DL.[Hotel Turnover incl_ VAT] [Total Rate]
		, INV.[Hotel Turnover incl_ VAT]-DL.[Hotel Turnover incl_ VAT] [Total Rate incl_]
		, 0 [Discount %]
		, COALESCE(BU.B_PASSWORD,'') [MusePassword]
		, INV.[Process No_] [ProcessNumber]
		, INV.[Hotel No_] [Job No_]
		, INV.[Hotel No_] [Customer No_]
		, 0 [Booking Status]
	    , @ActicityCode [Inserted by User]
	    , GETDATE() [Inserted at]
	    , @ActicityCode [Modified by User]
	    , GETDATE() [Modified at]
		, 0 [Insert Header]
		, 0 [Error Code]
		, '' [Contract Code]
		, '' [Contract Group Code]
		, '' [Agency Business Rules Code]
		, BU.B_KEY [Parent Reservation No_]
		, '' [Confirmed Reservation No_]
		, @ActicityCode [Quality by User]
		, INV.[Departure Date] [Quality at]
		, '' [Company No_]
		, 1 [Final Cancellation]
		, 1 [Inquiry Sent]
		, INV.[Departure Date] [Inquiry Sent At]
		, 0 [Ranking Booster]
		, 0 [Corporate Rate Discount]
		, 0 [Booking Comment]
		, 0 [Booking Rating]
		, COALESCE(BU.MULTISOURCED,0) [Multisourced]
     FROM #INV INV
     JOIN #DL DL
       ON DL.[Process No_] = INV.[Process No_]
	 JOIN BP
       ON BP.BP_KEY = INV.[Process No_]
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = BP.B_KEY
   WHERE DATEDIFF(dd,INV.[Arrival Date],INV.[Departure Date])>DATEDIFF(dd,DL.[Arrival Date],DL.[Departure Date])
	 AND NOT DL.MuseID = 'EAN'
	 AND DL.[Arrival Date]<>'1753-01-01'
	 AND INV.[Logis incl_ VAT]>DL.[Logis incl_ VAT]


  INSERT INTO [HRS-CN$Correction Agency Header] ([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced])
  SELECT [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Final Cancellation],[Inquiry Sent],[Inquiry Sent At],[Ranking Booster],[Corporate Rate Discount],[Booking Comment],[Booking Rating],[Multisourced] 
    FROM #CH
   WHERE [Reservation No_] NOT IN (SELECT [Reservation No_] FROM [HRS-CN$Correction Agency Header] WITH (NOLOCK))

  UPDATE CH SET CH.[Quality by User] = @ActicityCode FROM [HRS-CN$Correction Agency Header] CH JOIN #CH ON #CH.[Reservation No_] = CH.[Reservation No_]

END

-- create missing entries in [HRS-CN$Correction Agency Line]
DECLARE @RecreateCL int = 1
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
  CREATE TABLE #CL([Reservation No_] [varchar](20) COLLATE Latin1_General_CS_AS,[Position No_] [int],[Reservation Status] [int],[Reservation Date from] [datetime],[Reservation Date to] [datetime],[Number of Rooms] [int],[Room Type] [int],[Rate Description] [varchar](100),[Room Price] [decimal](38, 20),[Breakfast Type] [int],[Breakfast Price] [decimal](38, 20),[Commission Type] [int],[Commission Rate] [decimal](38, 20),[Commission Fix] [decimal](38, 20),[Rate Type] [int],[Rate Key] [int],[Currency Code] [varchar](3),[Currency Faktor] [decimal](38, 20),[Room Number] [int],[Activity Code] [varchar](40),[Number of Person] [int],[Hotel No_] [varchar](20),[Commission Tax Type] [int],[timestamp Source] [datetime],[Price Type] [int],[Process Number] [int],[Inserted by User] [varchar](20),[Inserted at] [datetime],[Modified by User] [varchar](20),[Modified at] [datetime],[Number of Nights] [decimal](38, 20),[Commission Base Amount] [decimal](38, 20),[Commission Amount] [decimal](38, 20),[Commission Base Amount (LCY)] [decimal](38, 20),[Commission Amount (LCY)] [decimal](38, 20),[Foreign Tax %] [decimal](38, 20),[Foreign Tax Amount] [decimal](38, 20),[Line Amount] [decimal](38, 20),[Line Amount (LCY)] [decimal](38, 20),[Foreign Tax Base Amount] [decimal](38, 20),[Hotel sales incl_ VAT] [decimal](38, 20),[Calculated with Contract Code] [varchar](20),[Calculated with Function ID] [varchar](10),[Calculated with Function Desc_] [varchar](100),[Final Cancellation] [tinyint],[Ranking Booster] [decimal](38, 20),[Corporate Rate Discount] [int],[Net Room Price] [decimal](38, 20),[Net Breakfast Price] [decimal](38, 20),[Deduction Type] [int],[Deductible Amount] [decimal](38, 20),CONSTRAINT [PK_#CL] PRIMARY KEY CLUSTERED([Reservation No_] ASC,[Position No_] ASC))
  ;WITH BP AS (SELECT BP_KEY,MAX(B_KEY) B_KEY, MAX(CTS) CTS FROM HRSDB.BKG_PROCESS_LIST_ALL_DA WITH (NOLOCK) GROUP BY BP_KEY)
  INSERT INTO #CL ([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type],[Deductible Amount])  
  SELECT BP.B_KEY [Reservation No_]
       , 999   [Position No_]
	   , 10000 [Reservation Status]
	   , INV.[Arrival Date] [Reservation Date from]
	   , INV.[Departure Date] [Reservation Date to]
	   , 0 [Number of Rooms]
	   , 0 [Room Type]
	   , 'Difference' [Rate Description]
	   , INV.[Logis incl_ VAT]-DL.[Logis incl_ VAT] [Room Price]
	   , 1 [Breakfast Type]
	   , CASE WHEN DL.[Breakfast incl_ VAT]=0 THEN 0 ELSE INV.[Breakfast incl_ VAT]-DL.[Breakfast incl_ VAT] END [Breakfast Price]
	   , 12 [Commission Type]
	   , 0.0 [Commission Rate]
	   , 0.0 [Commission Fix]
	   , -1 [Rate Type]
	   , -1 [Rate Key]
	   , W_ISO [Currency Code]
	   , 1 [Currency Faktor]
	   , 0 [Room Number]
	   , @ActicityCode [Activity Code]
	   , 1 [Number of Person]
	   , INV.[Hotel No_]
	   , 0 [Commission Tax Type]
	   , BP.CTS [timestamp Source]
	   , 0 [Price Type]
	   , INV.[Process No_] [Process Number]
	   , @ActicityCode [Inserted by User]
	   , GETDATE() [Inserted at]
	   , @ActicityCode [Modified by User]
	   , GETDATE() [Modified at]
	   , 1 [Number of Nights]
	   , 0 [Commission Base Amount]
	   , 0 [Commission Amount]
	   , 0 [Commission Base Amount (LCY)]
	   , 0 [Commission Amount (LCY)]
	   , 0 [Foreign Tax %]
	   , 0 [Foreign Tax Amount]
	   , 0 [Line Amount]
	   , 0 [Line Amount (LCY)]
	   , 0 [Foreign Tax Base Amount]
	   , 0 [Hotel sales incl_ VAT]
	   , '' [Calculated with Contract Code]
	   , '' [Calculated with Function ID]
	   , '' [Calculated with Function Desc_]
	   , 1 [Final Cancellation]
	   , 0 [Ranking Booster]
	   , 0 [Corporate Rate Discount]
	   , INV.[Logis incl_ VAT]-DL.[Logis incl_ VAT] [Net Room Price]
	   , CASE WHEN DL.[Breakfast incl_ VAT]=0 THEN 0 ELSE INV.[Breakfast incl_ VAT]-DL.[Breakfast incl_ VAT] END [Net Breakfast Price]
	   , 0 [Deduction Type]
	   , 0 [Deductible Amount]
     FROM #INV INV
     JOIN #DL DL
       ON DL.[Process No_] = INV.[Process No_]
	 JOIN BP
       ON BP.BP_KEY = INV.[Process No_]
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = BP.B_KEY
LEFT JOIN [HRS-CN$Correction Agency Line] CL
       ON CL.[Reservation No_] = CAST(BP.B_KEY AS varchar(20))
      AND CL.[Position No_] = 999
    WHERE DATEDIFF(dd,INV.[Arrival Date],INV.[Departure Date])>DATEDIFF(dd,DL.[Arrival Date],DL.[Departure Date])
 	  AND NOT DL.MuseID = 'EAN'
	  AND INV.[Logis incl_ VAT]>DL.[Logis incl_ VAT]
	  AND DL.[Arrival Date]<>'1753-01-01'
	  AND CL.[Reservation No_] IS NULL

  INSERT INTO [HRS-CN$Correction Agency Line] ([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Final Cancellation],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Deduction Type],[Deductible Amount])
  SELECT CLL.[Reservation No_],CLL.[Position No_],CLL.[Reservation Status],CLL.[Reservation Date from],CLL.[Reservation Date to],CLL.[Number of Rooms],CLL.[Room Type],CLL.[Rate Description],CLL.[Room Price],CLL.[Breakfast Type],CLL.[Breakfast Price],CLL.[Commission Type],CLL.[Commission Rate],CLL.[Commission Fix],CLL.[Rate Type],CLL.[Rate Key],CLL.[Currency Code],CLL.[Currency Faktor],CLL.[Room Number],CLL.[Activity Code],CLL.[Number of Person],CLL.[Hotel No_],CLL.[Commission Tax Type],CLL.[timestamp Source],CLL.[Price Type],CLL.[Process Number],CLL.[Inserted by User],CLL.[Inserted at],CLL.[Modified by User],CLL.[Modified at],CLL.[Number of Nights],CLL.[Commission Base Amount],CLL.[Commission Amount],CLL.[Commission Base Amount (LCY)],CLL.[Commission Amount (LCY)],CLL.[Foreign Tax %],CLL.[Foreign Tax Amount],CLL.[Line Amount],CLL.[Line Amount (LCY)],CLL.[Foreign Tax Base Amount],CLL.[Hotel sales incl_ VAT],CLL.[Calculated with Contract Code],CLL.[Calculated with Function ID],CLL.[Calculated with Function Desc_],CLL.[Final Cancellation],CLL.[Ranking Booster],CLL.[Corporate Rate Discount],CLL.[Net Room Price],CLL.[Net Breakfast Price],CLL.[Deduction Type],CLL.[Deductible Amount] FROM #CL CLL
END
END
GO
