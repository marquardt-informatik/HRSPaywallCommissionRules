USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GenerateCommissionInvoices_HRS-BR ACS-1986]    Script Date: 10.04.2024 14:31:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 17.06.2016
-- Description:	Creates Commission Invoices (Pendant to Navision Report 50005)
--
/*
EXEC [dbo].[sp_GenerateCommissionInvoices_HRS-BR] 
    @MuseIdFilter = 'MEETAGO|MEETAGO_HDE'
  , @today = '2016-07-31'
*/
-- Date     Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 22.07.16 HRS001    NAV-105   TM 
-- 29.12.16			  NAV-421   SAK 
-- 04.05.17 HRS003    NAV-588   TM
-- 20.07.19 HRS004    ACS-1857  TMA New Fields: "Breakfast Approval Status", "Rate Plan Code"
-- 25.07.19 HRS005    ACS-1873  TMA Load BOOKING_SEGMENTATION for all Chains but 550,15,165,204    
-- 23.12.19 HRS006    ACS-1434  DJU New Field: "Confirmed"
--                                  
CREATE PROCEDURE [dbo].[sp_GenerateCommissionInvoices_HRS-BR ACS-1986]
--DECLARE
    @today         date    = NULL --'2016-04-30'
  , @Query         tinyint = 0
  , @HotelFilter   varchar(max)= NULL --'22|226|227|228'
  , @MuseIdFilter  varchar(max)= NULL --'MEETAGO|MEETAGO_HDE'
AS BEGIN  

SET @today = COALESCE(@today,CAST(GETDATE() as smalldatetime))

DECLARE @dateFrom    date
      , @dateTo      date
      , @PostingDate date
      , @NoSeries    varchar(10) = 'AGV'

DECLARE @OldNumber int
SELECT @OldNumber = CAST(REPLACE([Last No_ Used],'V','') AS INT) FROM [HRS-BR$No_ Series Line] WHERE [Series Code] = @NoSeries
PRINT @OldNumber

IF DATEPART(dd,@today)<5
  SET @dateTo = DATEADD(dd,-DATEPART(dd,@today), @today)
ELSE
  SET @dateTo = DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,-DATEPART(dd,@today)+1, @today)))
  
SET @PostingDate = @dateTo
SET @dateFrom = DATEADD(mm,-3,DATEADD(dd,1,@dateTo))

PRINT @PostingDate
DECLARE @toBeDeleted int = 1

-- ----------------------------------------
-- delete AMADEUS bookings
-- ----------------------------------------  
WHILE @toBeDeleted>0
BEGIN
   DELETE TOP(1000) FROM DL
     FROM [HRS-BR$Agency Display Line] DL 
	 JOIN [HRS-BR$Agency Display Header] DH 
	   ON DL.[Display Case No_] = DH.[Case No_]
	WHERE DH.[Posting Date] = @PostingDate
      AND DH.[Case No_] LIKE 'V%'
      AND DH.[Posted Invoice No_] = ''
      AND ('|'+@HotelFilter+'|' LIKE '%|'+DH.[Bill-to Customer No_]+'|%' OR @HotelFilter IS NULL)
      AND ('|'+@MuseIdFilter+'|' LIKE '%|'+DH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
      AND DL.[MuseID] = 'AMADEUS'

   SELECT @toBeDeleted = COALESCE(COUNT(1),0)
     FROM [HRS-BR$Agency Display Line] DL 
	 JOIN [HRS-BR$Agency Display Header] DH 
	   ON DL.[Display Case No_] = DH.[Case No_]
	WHERE DH.[Posting Date] = @PostingDate
      AND DH.[Case No_] LIKE 'V%'
      AND DH.[Posted Invoice No_] = ''
      AND ('|'+@HotelFilter+'|' LIKE '%|'+DH.[Bill-to Customer No_]+'|%' OR @HotelFilter IS NULL)
      AND ('|'+@MuseIdFilter+'|' LIKE '%|'+DH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
      AND DL.[MuseID] = 'AMADEUS'
END

-- ----------------------------------------
-- delete canceled bookings
-- ----------------------------------------  
IF @Query=0
BEGIN
SET @toBeDeleted = 1
WHILE @toBeDeleted>0
BEGIN
   DELETE TOP(1000) FROM DL
     FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line]   DL WITH (NOLOCK)
     JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] DH WITH (NOLOCK)
       ON DH.[Case No_] = DL.[Display Case No_]
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = DL.[Reservation No_]
     JOIN DynNavHRS.HRSDB.BUCHTEIL BT WITH (NOLOCK)
       ON BT.B_KEY = DL.[Reservation No_]
      AND BT.BT_POS = DL.[Position No_]
    WHERE DH.[Posting Date] = @PostingDate
      AND DH.[Case No_] LIKE 'V%'
      AND DH.[Posted Invoice No_] = ''
      AND (BU.B_STATUS = 10000 OR BT.B_STATUS IN (10000,19998))
      
   SELECT @toBeDeleted = COALESCE(COUNT(1),0)
     FROM DynNavHRS.dbo.[HRS-BR$Agency Display Line]   DL WITH (NOLOCK)
     JOIN DynNavHRS.dbo.[HRS-BR$Agency Display Header] DH WITH (NOLOCK)
       ON DH.[Case No_] = DL.[Display Case No_]
     JOIN DynNavHRS.HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = DL.[Reservation No_]
     JOIN DynNavHRS.HRSDB.BUCHTEIL BT WITH (NOLOCK)
       ON BT.B_KEY = DL.[Reservation No_]
      AND BT.BT_POS = DL.[Position No_]
    WHERE DH.[Posting Date] = @PostingDate
      AND DH.[Case No_] LIKE 'V%'
      AND DH.[Posted Invoice No_] = ''
      AND (BU.B_STATUS = 10000 OR BT.B_STATUS IN (10000,19998))
END
END

-- ----------------------------------------
-- delete empty invoices
-- ---------------------------------------- 
IF @Query=0
BEGIN
DECLARE @Empty TABLE ([Display Case No_] varchar(20) PRIMARY KEY)
;WITH ADL AS
(
   SELECT ADL.[Display Case No_]
        , COUNT(1) CountADL
     FROM [HRS-BR$Agency Display Line] ADL WITH (NOLOCK)
    WHERE ADL.Action<>3
 GROUP BY ADL.[Display Case No_]
)
   INSERT INTO @Empty
   SELECT ADH.[Case No_] 
     FROM [HRS-BR$Agency Display Header] ADH WITH (NOLOCK)
LEFT JOIN [HRS-BR$Batch Posting Log Entry] BPE WITH (NOLOCK)
       ON BPE.[Display Case No_] = ADH.[Case No_]
LEFT JOIN ADL
       ON ADL.[Display Case No_] = ADH.[Case No_]
    WHERE ADH.[Posting Date] = @PostingDate
      AND ADH.[Status] = 0
      AND ADL.CountADL IS NULL

   DELETE FROM BPE
     FROM [HRS-BR$Batch Posting Log Entry] BPE
     JOIN @Empty EMP
       ON EMP.[Display Case No_] = BPE.[Display Case No_]

   DELETE FROM ADL
     FROM [HRS-BR$Agency Display Line] ADL
     JOIN @Empty EMP
       ON EMP.[Display Case No_] = ADL.[Display Case No_]

   DELETE FROM ADH
     FROM [HRS-BR$Agency Display Header] ADH
     JOIN @Empty EMP
       ON EMP.[Display Case No_] = ADH.[Case No_]
END

-- ----------------------------------------
-- prepare commissioning
-- ----------------------------------------  
BEGIN
  DECLARE @ER TABLE ([Currency Code] varchar(20) PRIMARY KEY, [Exchange Rate Amount] DECIMAL(38,20))
    ;WITH _ER          AS (SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [HRS-BR$Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate UNION SELECT ER.[Currency Code], ER.[Exchange Rate Amount], ER.[Starting Date] FROM [HRS-BR$OANDA_Currency Exchange Rate] ER WITH (NOLOCK) WHERE ER.[Starting Date] <= @PostingDate)
        , ExchangeRate AS (SELECT ER1.[Currency Code], ER1.[Exchange Rate Amount] FROM _ER ER1 JOIN (SELECT [Currency Code], MAX([Starting Date]) [Starting Date] FROM _ER GROUP BY [Currency Code]) ER2 ON ER2.[Starting Date] = ER1.[Starting Date] AND ER2.[Currency Code] = ER1.[Currency Code] )
   INSERT INTO @ER
   SELECT * FROM ExchangeRate

   CREATE TABLE #AgencyDisplayHeader ([Bill-to Customer No_] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Currency Code] [varchar](10) COLLATE Latin1_General_CS_AS NOT NULL,[MuseID] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Document Type] [varchar](10) COLLATE Latin1_General_CS_AS NOT NULL,[Case No_] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Amount (LCY)] decimal(38,20), [Country_Region Code] varchar(20) COLLATE Latin1_General_CS_AS NOT NULL,[existing] tinyint NOT NULL,[to delete] tinyint NOT NULL,[Posting Date] [datetime] NOT NULL,[VAT Bus_ Posting Group] [varchar](10) NOT NULL,[VAT Prod_ Posting Group] [varchar](10) NOT NULL,[Salesperson Code] [varchar](10) NOT NULL,[Chain Code] [varchar](20) NOT NULL,[Brand Code] [int] NOT NULL, [Exchange Rate Amount] DECIMAL(38,20) NOT NULL, PRIMARY KEY([Bill-to Customer No_],[Currency Code],[MuseID],[Document Type]))

  DECLARE @AgencyDisplayHeader TABLE([Bill-to Customer No_] [varchar](20) NOT NULL,[Currency Code] [varchar](10) NOT NULL,[MuseID] [varchar](20) NOT NULL,[Document Type] [varchar](10) NOT NULL,[Case No_] [varchar](20) NOT NULL,[Amount (LCY)] decimal(38,20), [Country_Region Code] varchar(20) NOT NULL,[existing] tinyint NOT NULL,[to delete] tinyint NOT NULL,[Posting Date] [datetime] NOT NULL,[VAT Bus_ Posting Group] [varchar](10) NOT NULL,[VAT Prod_ Posting Group] [varchar](10) NOT NULL,[Salesperson Code] [varchar](10) NOT NULL,[Chain Code] [varchar](20) NOT NULL,[Brand Code] [int] NOT NULL, [Exchange Rate Amount] DECIMAL(38,20) NOT NULL, PRIMARY KEY([Bill-to Customer No_],[Currency Code],[MuseID],[Document Type]))
   INSERT INTO #AgencyDisplayHeader
   SELECT DH.[Bill-to Customer No_]
        , DH.[Currency Code]
        , DH.[MuseID] 
        , DH.[Document Type]
        , DH.[Case No_]
        , SUM(DL.[Line Amount (LCY)]) [Amount (LCY)]
        , CO.[Country_Region Code]
        , 1 [existing]
        , 0 [to delete]
        , DH.[Posting Date]
        , DH.[VAT Bus_ Posting Group]
        , DH.[VAT Prod_ Posting Group]
        , DH.[Salesperson Code]
        , DH.[Chain Code]
        , DH.[Brand Code]
        , MAX(ER.[Exchange Rate Amount])
     FROM [HRS-BR$Agency Display Header] DH WITH (NOLOCK)
     JOIN [HRS-BR$Agency Display Line]   DL WITH (NOLOCK)
       ON DL.[Display Case No_]     = DH.[Case No_]
     JOIN [HRS-BR$Customer]              CO WITH (NOLOCK)
       ON CO.[No_]                  = DH.[Bill-to Customer No_]
     JOIN @ER ER
       ON ER.[Currency Code]        = DH.[Currency Code]
    WHERE DH.[Status] = 0
      AND DH.[Case No_] LIKE 'V%'
      AND DH.[Posting Date] = @PostingDate
      AND ('|'+@HotelFilter+'|' LIKE '%|'+DH.[Bill-to Customer No_]+'|%' OR @HotelFilter IS NULL)
      AND ('|'+@MuseIdFilter+'|' LIKE '%|'+DH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
 GROUP BY DH.[Bill-to Customer No_]
        , DH.[Currency Code]
        , DH.[MuseID] 
        , DH.[Document Type]
        , DH.[Case No_]
        , CO.[Country_Region Code]
        , DH.[Posting Date]
        , DH.[VAT Bus_ Posting Group]
        , DH.[VAT Prod_ Posting Group]
        , DH.[Salesperson Code]
        , DH.[Chain Code]
        , DH.[Brand Code]
        
  -- ----------------------------------------
  -- switch MS + delete
  -- ----------------------------------------    
  BEGIN
    UPDATE AH SET
           AH.[to delete] = 1
      FROM #AgencyDisplayHeader AH
      JOIN [HRS-BR$Customer] CU WITH (NOLOCK)
        ON CU.[No_] = AH.[Bill-to Customer No_]
     WHERE AH.[MuseID] LIKE '%_MS'
       AND CU.[Treat Hotel as multisource] = 0
       AND ('|'+@HotelFilter+'|' LIKE '%|'+AH.[Bill-to Customer No_]+'|%' OR @HotelFilter IS NULL)
       AND ('|'+@MuseIdFilter+'|' LIKE '%|'+AH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
       
SELECT * FROM #AgencyDisplayHeader       
        
    DELETE FROM DL
      FROM #AgencyDisplayHeader AH
      JOIN [HRS-BR$Agency Display Header] DH
        ON DH.[Currency Code]        = AH.[Currency Code]
       AND DH.[Document Type]        = AH.[Document Type]
       AND DH.[Bill-to Customer No_] = AH.[Bill-to Customer No_]
       AND DH.[MuseID]               = AH.[MuseID]
      JOIN [HRS-BR$Agency Display Line]   DL
        ON DL.[Display Case No_]     = DH.[Case No_]
	   AND DH.[Status]               = 0
	   AND DH.[Correction from]      = ''
     WHERE AH.[to delete]            = 1

    DELETE FROM DH
      FROM #AgencyDisplayHeader AH
      JOIN [HRS-BR$Agency Display Header] DH
        ON DH.[Currency Code]        = AH.[Currency Code]
       AND DH.[Document Type]        = AH.[Document Type]
       AND DH.[Bill-to Customer No_] = AH.[Bill-to Customer No_]
       AND DH.[MuseID]               = AH.[MuseID]
     WHERE AH.[to delete]            = 1
	   AND DH.[Status]               = 0
	   AND DH.[Correction from]      = ''
  END     
      
   CREATE TABLE #AgencyDisplayLine ([Case No_] [varchar](20) COLLATE Latin1_General_CS_AS,[Posting Date] [datetime] NOT NULL,[Document Type] [varchar](10) COLLATE Latin1_General_CS_AS NOT NULL,[Reservation No_] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Position No_] [int] NOT NULL,[Reservation Status] [int] NOT NULL,[Reservation Date from] [datetime] NOT NULL,[Reservation Date to] [datetime] NOT NULL,[Number of Rooms] [int] NOT NULL,[Room Type] [int] NOT NULL,[Rate Description] [varchar](100) NOT NULL,[Room Price] [decimal](38, 20) NOT NULL,[Breakfast Type] [int] NOT NULL,[Breakfast Price] [decimal](38, 20) NOT NULL,[Commission Type] [int] NOT NULL,[Commission Rate] [decimal](38, 20) NOT NULL,[Commission Fix] [decimal](38, 20) NOT NULL,[Rate Type] [int] NOT NULL,[Rate Key] [int] NOT NULL,[Currency Code] [varchar](3) COLLATE Latin1_General_CS_AS NOT NULL,[Currency Faktor] [decimal](38, 20) NOT NULL,[Room Number] [int] NOT NULL,[Activity Code] [varchar](40) NOT NULL,[Number of Person] [int] NOT NULL,[Hotel No_] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Commission Tax Type] [int] NOT NULL,[timestamp Source] [datetime] NOT NULL,[Price Type] [int] NOT NULL,[Process Number] [int] NOT NULL,[Inserted by User] [varchar](20) NOT NULL,[Inserted at] [datetime] NOT NULL,[Modified by User] [varchar](20) NOT NULL,[Modified at] [datetime] NOT NULL,[Number of Nights] [decimal](38, 20) NOT NULL,[Commission Base Amount] [decimal](38, 20) NOT NULL,[Commission Amount] [decimal](38, 20) NOT NULL,[Commission Base Amount (LCY)] [decimal](38, 20) NOT NULL,[Commission Amount (LCY)] [decimal](38, 20) NOT NULL,[Foreign Tax %] [decimal](38, 20) NOT NULL,[Foreign Tax Amount] [decimal](38, 20) NOT NULL,[Line Amount] [decimal](38, 20) NOT NULL,[Line Amount (LCY)] [decimal](38, 20) NOT NULL,[Foreign Tax Base Amount] [decimal](38, 20) NOT NULL,[Hotel sales incl_ VAT] [decimal](38, 20) NOT NULL,[Client No_] [int] NOT NULL,[Reservation Activator] [varchar](10) NOT NULL,[Reservation State] [int] NOT NULL,[Reservation Date] [datetime] NOT NULL,[Reservation Time] [datetime] NOT NULL,[Reservation Source] [int] NOT NULL,[Arrival Date] [datetime] NOT NULL,[Departure Date] [datetime] NOT NULL,[Action] [int] NOT NULL,[Calculated with Contract Code] [varchar](20) NOT NULL,[Calculated with Function ID] [varchar](10) NOT NULL,[Calculated with Function Desc_] [varchar](100) NOT NULL,[Client Company] [varchar](80) NOT NULL,[Client Guestname 1] [varchar](120) NOT NULL,[Client Guestname 2] [varchar](120) NOT NULL,[Description] [varchar](70) NOT NULL,[MuseID] [varchar](20) COLLATE Latin1_General_CS_AS NOT NULL,[Handbooking] [tinyint] NOT NULL,[ProcessNumber] [int] NOT NULL,[Booking Quality] [tinyint] NOT NULL,[Booking Code] [varchar](80) NOT NULL,[Invoice No_ Old System] [varchar](20) NOT NULL,[Invoice Line No_ Old System] [int] NOT NULL,[Loyality Rewards Account No_] [varchar](100) NOT NULL,[Foreign Tax Roomnight Base Amt] [decimal](38, 20) NOT NULL,[Foreign Tax Breakf Base Amount] [decimal](38, 20) NOT NULL,[Commission Roomnight Base Amnt] [decimal](38, 20) NOT NULL,[Commission Breakf Base Amount] [decimal](38, 20) NOT NULL,[Foreign Tax Roomnight Amount] [decimal](38, 20) NOT NULL,[Foreign Tax Breakf Amount] [decimal](38, 20) NOT NULL,[Commission Roomnight Amount] [decimal](38, 20) NOT NULL,[Commission Breakf Amount] [decimal](38, 20) NOT NULL,[Foreign Tax % Roomnight] [decimal](38, 20) NOT NULL,[Foreign Tax % Breakf] [decimal](38, 20) NOT NULL,[Confirmed Reservation No_] [varchar](20) NOT NULL,[Quality by User] [varchar](20) NOT NULL,[Quality at] [datetime] NOT NULL,[Ranking Booster] [decimal](38, 20) NOT NULL,[Corporate Rate Discount] [int] NOT NULL,[Net Room Price] [decimal](38, 20) NOT NULL,[Net Breakfast Price] [decimal](38, 20) NOT NULL,[Booking Comment] [tinyint] NOT NULL,[Agency Business Rules Code] [varchar](20) NOT NULL,[Deduction Type] [int] NOT NULL,[Deductible Amount] [decimal](38, 20) NOT NULL,[Booking Rating] [tinyint] NOT NULL,[Multisourced] [tinyint] NOT NULL,[Segment] [int] NOT NULL, [Breakfast Approval Status] int NOT NULL, [Rate Plan Code] varchar(20)NOT NULL,PRIMARY KEY([Reservation No_] ASC,[Position No_] ASC))
  DECLARE @AgencyDisplayLine TABLE ([Case No_] [varchar](20),[Posting Date] [datetime] NOT NULL,[Document Type] [varchar](10) NOT NULL,[Reservation No_] [varchar](20) NOT NULL,[Position No_] [int] NOT NULL,[Reservation Status] [int] NOT NULL,[Reservation Date from] [datetime] NOT NULL,[Reservation Date to] [datetime] NOT NULL,[Number of Rooms] [int] NOT NULL,[Room Type] [int] NOT NULL,[Rate Description] [varchar](100) NOT NULL,[Room Price] [decimal](38, 20) NOT NULL,[Breakfast Type] [int] NOT NULL,[Breakfast Price] [decimal](38, 20) NOT NULL,[Commission Type] [int] NOT NULL,[Commission Rate] [decimal](38, 20) NOT NULL,[Commission Fix] [decimal](38, 20) NOT NULL,[Rate Type] [int] NOT NULL,[Rate Key] [int] NOT NULL,[Currency Code] [varchar](3) NOT NULL,[Currency Faktor] [decimal](38, 20) NOT NULL,[Room Number] [int] NOT NULL,[Activity Code] [varchar](40) NOT NULL,[Number of Person] [int] NOT NULL,[Hotel No_] [varchar](20) NOT NULL,[Commission Tax Type] [int] NOT NULL,[timestamp Source] [datetime] NOT NULL,[Price Type] [int] NOT NULL,[Process Number] [int] NOT NULL,[Inserted by User] [varchar](20) NOT NULL,[Inserted at] [datetime] NOT NULL,[Modified by User] [varchar](20) NOT NULL,[Modified at] [datetime] NOT NULL,[Number of Nights] [decimal](38, 20) NOT NULL,[Commission Base Amount] [decimal](38, 20) NOT NULL,[Commission Amount] [decimal](38, 20) NOT NULL,[Commission Base Amount (LCY)] [decimal](38, 20) NOT NULL,[Commission Amount (LCY)] [decimal](38, 20) NOT NULL,[Foreign Tax %] [decimal](38, 20) NOT NULL,[Foreign Tax Amount] [decimal](38, 20) NOT NULL,[Line Amount] [decimal](38, 20) NOT NULL,[Line Amount (LCY)] [decimal](38, 20) NOT NULL,[Foreign Tax Base Amount] [decimal](38, 20) NOT NULL,[Hotel sales incl_ VAT] [decimal](38, 20) NOT NULL,[Client No_] [int] NOT NULL,[Reservation Activator] [varchar](10) NOT NULL,[Reservation State] [int] NOT NULL,[Reservation Date] [datetime] NOT NULL,[Reservation Time] [datetime] NOT NULL,[Reservation Source] [int] NOT NULL,[Arrival Date] [datetime] NOT NULL,[Departure Date] [datetime] NOT NULL,[Action] [int] NOT NULL,[Calculated with Contract Code] [varchar](20) NOT NULL,[Calculated with Function ID] [varchar](10) NOT NULL,[Calculated with Function Desc_] [varchar](100) NOT NULL,[Client Company] [varchar](80) NOT NULL,[Client Guestname 1] [varchar](120) NOT NULL,[Client Guestname 2] [varchar](120) NOT NULL,[Description] [varchar](70) NOT NULL,[MuseID] [varchar](20) NOT NULL,[Handbooking] [tinyint] NOT NULL,[ProcessNumber] [int] NOT NULL,[Booking Quality] [tinyint] NOT NULL,[Booking Code] [varchar](80) NOT NULL,[Invoice No_ Old System] [varchar](20) NOT NULL,[Invoice Line No_ Old System] [int] NOT NULL,[Loyality Rewards Account No_] [varchar](100) NOT NULL,[Foreign Tax Roomnight Base Amt] [decimal](38, 20) NOT NULL,[Foreign Tax Breakf Base Amount] [decimal](38, 20) NOT NULL,[Commission Roomnight Base Amnt] [decimal](38, 20) NOT NULL,[Commission Breakf Base Amount] [decimal](38, 20) NOT NULL,[Foreign Tax Roomnight Amount] [decimal](38, 20) NOT NULL,[Foreign Tax Breakf Amount] [decimal](38, 20) NOT NULL,[Commission Roomnight Amount] [decimal](38, 20) NOT NULL,[Commission Breakf Amount] [decimal](38, 20) NOT NULL,[Foreign Tax % Roomnight] [decimal](38, 20) NOT NULL,[Foreign Tax % Breakf] [decimal](38, 20) NOT NULL,[Confirmed Reservation No_] [varchar](20) NOT NULL,[Quality by User] [varchar](20) NOT NULL,[Quality at] [datetime] NOT NULL,[Ranking Booster] [decimal](38, 20) NOT NULL,[Corporate Rate Discount] [int] NOT NULL,[Net Room Price] [decimal](38, 20) NOT NULL,[Net Breakfast Price] [decimal](38, 20) NOT NULL,[Booking Comment] [tinyint] NOT NULL,[Agency Business Rules Code] [varchar](20) NOT NULL,[Deduction Type] [int] NOT NULL,[Deductible Amount] [decimal](38, 20) NOT NULL,[Booking Rating] [tinyint] NOT NULL,[Multisourced] [tinyint] NOT NULL,[Segment] [int] NOT NULL, [Breakfast Approval Status] int NOT NULL, [Rate Plan Code] varchar(20) NOT NULL, PRIMARY KEY([Reservation No_] ASC,[Position No_] ASC))
        ; WITH 
          AP AS (SELECT ReservationNo [Reservation No_], ReservationPartNo [Position No_], COUNT(1) Anzahl FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK) GROUP BY ReservationNo, ReservationPartNo)
        , DL AS (SELECT DL.[Reservation No_], DL.[Position No_] FROM [HRS-BR$Agency Display Line] DL WITH (NOLOCK) JOIN [HRS-BR$Agency Display Header] DH WITH (NOLOCK) ON DL.[Display Case No_] = DH.[Case No_] WHERE DH.[Status] = 0 AND DH.[Case No_] LIKE 'V%')
   INSERT INTO #AgencyDisplayLine
   SELECT DH.[Case No_]
        , @PostingDate [Posting Date]
        , CASE
            WHEN CU.[Force Direct Debit]=1 THEN '10'
            -- 22.07.16 TM >>>>>>>>>>>>>>>>>>>> HRS001
            WHEN CU.[Treat Hotel as multisource]=1 AND AH.[Multisourced] = 1 THEN '11'
            -- Original : WHEN AH.[Multisourced] = 1     THEN '11'
            -- 22.07.16 TM <<<<<<<<<<<<<<<<<<<< HRS001                        
            WHEN CU.[Export Center]<>'' AND CU.[Print Invoices]=0 THEN '11'
            WHEN CU.[Print Invoices]=1     THEN '10'
            ELSE COALESCE(DT.[Document Type],'10')
          END [Document Type]
        , AL.[Reservation No_]
        , AL.[Position No_]
        , AL.[Reservation Status]
        , AL.[Reservation Date from]
        , AL.[Reservation Date to]
        , AL.[Number of Rooms]
        , AL.[Room Type]
        , AL.[Rate Description]
        , AL.[Room Price]
        , AL.[Breakfast Type]
        , AL.[Breakfast Price]
        , AL.[Commission Type]
        , AL.[Commission Rate]
        , AL.[Commission Fix]
        , AL.[Rate Type]
        , AL.[Rate Key]
        , AL.[Currency Code]
        , ER.[Exchange Rate Amount] [Currency Faktor]
        , AL.[Room Number]
        , AL.[Activity Code]
        , AL.[Number of Person]
        , AL.[Hotel No_]
        , AL.[Commission Tax Type]
        , AL.[timestamp Source]
        , AL.[Price Type]
        , AL.[Process Number]
        , AL.[Inserted by User]
        , AL.[Inserted at]
        , AL.[Modified by User]
        , AL.[Modified at]
        , AL.[Number of Nights]
        , AL.[Commission Base Amount]
        , AL.[Commission Amount]
        , AL.[Commission Base Amount (LCY)]
        , AL.[Commission Amount (LCY)]
        , AL.[Foreign Tax %]
        , AL.[Foreign Tax Amount]
        , AL.[Line Amount]
        , AL.[Line Amount (LCY)]
        , AL.[Foreign Tax Base Amount]
        , AL.[Hotel sales incl_ VAT]
        , AL.[Client No_]
        , AH.[Reservation Activator]
        , AH.[Reservation State]
        , AH.[Reservation Date]
        , AH.[Reservation Time]
        , AH.[Reservation Source]
        , AH.[Arrival Date]
        , AH.[Departure Date]
        , 0  [Action]
        , AL.[Calculated with Contract Code]
        , AL.[Calculated with Function ID]
        , AL.[Calculated with Function Desc_]
        , AH.[Client Company]
        , AH.[Client Guestname 1]
        , AH.[Client Guestname 2]
        , AH.[Description]
        , CASE 
            -- 22.07.16 TM >>>>>>>>>>>>>>>>>>>> HRS001
            WHEN AH.Multisourced=1 AND CU.[Treat Hotel as multisource]=0 THEN 'HRS'
            -- 22.07.16 TM <<<<<<<<<<<<<<<<<<<< HRS001                        
            -- 04.05.17 TM >>>>>>>>>>>>>>>>>>>> HRS003
            WHEN AH.Multisourced=1 AND CU.[Treat Hotel as multisource]=1 THEN AH.[MuseID] + CASE WHEN CU.[Force Direct Debit]=0 AND AH.Multisourced=1 THEN '_MS' ELSE '' END
            -- 04.05.17 TM <<<<<<<<<<<<<<<<<<<< HRS003
			-- 02.08.16 TM >>>>>>>>>>>>>>>>>>>> HRS002
            WHEN AH.[MuseID]='AMADEUS' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS'
            -- 02.08.16 TM <<<<<<<<<<<<<<<<<<<< HRS002
			ELSE AH.[MuseID]
               + CASE WHEN CU.[Force Direct Debit]=0 AND AH.Multisourced=1 THEN '_MS' ELSE '' END 
          END [MuseID]
        , AH.[Handbooking]
        , AH.[ProcessNumber]
        , 0  [Booking Quality]
        , AH.MusePassword [Booking Code]
        , '' [Invoice No_ Old System]
        , 0  [Invoice Line No_ Old System]
        , AL.[Loyality Rewards Account No_]
        , 0  [Foreign Tax Roomnight Base Amt]
        , 0  [Foreign Tax Breakf Base Amount]
        , 0  [Commission Roomnight Base Amnt]
        , 0  [Commission Breakf Base Amount]
        , 0  [Foreign Tax Roomnight Amount]
        , 0  [Foreign Tax Breakf Amount]
        , 0  [Commission Roomnight Amount]
        , 0  [Commission Breakf Amount]
        , AL.[Foreign Tax % Roomnight]
        , AL.[Foreign Tax % Breakf]
        , AH.[Confirmed Reservation No_]
        , AH.[Quality by User]
        , AH.[Quality at]
        , AH.[Ranking Booster]
        , AL.[Corporate Rate Discount]
        , AL.[Net Room Price]
        , AL.[Net Breakfast Price]
        , AH.[Booking Comment]
        , AL.[Agency Business Rules Code]
        , AL.[Deduction Type]
        , AL.[Deductible Amount]
        , 0  [Booking Rating]
        , AH.[Multisourced]
   -- 25.07.19 HRS005 TM >>>>>>>>>>>>>>>>>>>>     
		, CASE WHEN COALESCE(AH.Segment, 0)=3 AND AL.[Commission Type]=13 THEN 4 ELSE COALESCE(AH.Segment, 0) END
   -- Original :, COALESCE(AH.Segment, 0)
   -- 25.07.19 HRS005 TM <<<<<<<<<<<<<<<<<<<<
        , AL.[Breakfast Approval Status] 
        , AL.[Rate Plan Code]
     FROM [HRS-BR$Agency Line] AL WITH (NOLOCK)
     JOIN [HRS-BR$Agency Header] AH WITH (NOLOCK)
       ON AH.[Reservation No_] = AL.[Reservation No_]
     JOIN @ER ER
       ON ER.[Currency Code] = AH.[Currency Code]   
     JOIN [HRS-BR$Customer] CU WITH (NOLOCK)
       ON CU.[No_] = AH.[Hotel No_]
     JOIN [HRS-BR$Agency Setup] SA WITH (NOLOCK)
       ON 1=1
     JOIN [HRS-BR$Booking Source] BS WITH (NOLOCK)
       ON BS.[No_] = AH.[Reservation Source]
LEFT JOIN [HRS-BR$Document Type Assignment] DT WITH (NOLOCK)
       ON DT.[Chain Code] = CU.Chain
      AND DT.[Brand Code] = CU.Brand
      AND DT.[Muse ID]    = AH.[MuseID] + CASE WHEN CU.[Force Direct Debit]=0 AND AH.Multisourced=1 THEN '_MS' ELSE '' END
      AND (DT.[Reservation Date valid til] >= AH.[Reservation Date] OR DT.[Reservation Date valid til] = '1753-01-01')
LEFT JOIN #AgencyDisplayHeader DH
       ON DH.[Bill-to Customer No_] = AH.[Hotel No_]
      AND DH.[Currency Code]        = ER.[Currency Code]
      AND DH.[MuseID]               
        = CASE 
            -- 22.07.16 TM >>>>>>>>>>>>>>>>>>>> HRS001
            WHEN AH.Multisourced=1 AND CU.[Treat Hotel as multisource]=0 THEN 'HRS'
            -- 22.07.16 TM <<<<<<<<<<<<<<<<<<<< HRS001                        
            -- 04.05.17 TM >>>>>>>>>>>>>>>>>>>> HRS003
            WHEN AH.Multisourced=1 AND CU.[Treat Hotel as multisource]=1 THEN AH.[MuseID] + CASE WHEN CU.[Force Direct Debit]=0 AND AH.Multisourced=1 THEN '_MS' ELSE '' END
            -- 04.05.17 TM <<<<<<<<<<<<<<<<<<<< HRS003                                    
			-- 02.08.16 TM >>>>>>>>>>>>>>>>>>>> HRS002
            WHEN AH.[MuseID]='AMADEUS' AND NOT CU.[Contract Status] IN ('10','11') THEN 'HRS'
            -- 02.08.16 TM <<<<<<<<<<<<<<<<<<<< HRS002
			ELSE AH.[MuseID]
               + CASE WHEN CU.[Force Direct Debit]=0 AND AH.Multisourced=1 THEN '_MS' ELSE '' END 
          END
      AND DH.[Document Type]        
        = CASE
            WHEN CU.[Force Direct Debit]=1 THEN '10'
            -- 22.07.16 TM >>>>>>>>>>>>>>>>>>>> HRS001
            WHEN CU.[Treat Hotel as multisource]=1 AND AH.[Multisourced] = 1 THEN '11'
            -- Original : WHEN AH.[Multisourced] = 1     THEN '11'
            -- 22.07.16 TM <<<<<<<<<<<<<<<<<<<< HRS001                        
            WHEN CU.[Export Center]<>'' AND CU.[Print Invoices]=0 THEN '11'
            WHEN CU.[Print Invoices]=1     THEN '10'
            ELSE COALESCE(DT.[Document Type],'10')
          END 
LEFT JOIN AP     
       ON AP.[Reservation No_] = AL.[Reservation No_]
      AND AP.[Position No_]    = AL.[Position No_]
LEFT JOIN DL 
       ON DL.[Reservation No_] = AL.[Reservation No_]
      AND DL.[Position No_]    = AL.[Position No_]   
    WHERE AH.[Reservation State] < 10000
      AND AL.[Reservation Status]  IN (0,1,19997)   
      AND AH.[Departure Date] BETWEEN @dateFrom AND @dateTo
      AND AH.[Booking Status]    = 1
      AND (DATEADD(dd,7,AH.[Departure Date]) <= @dateTo OR BS.Category IN (0,1))
      AND AP.[Reservation No_] IS NULL
      AND DL.[Reservation No_] IS NULL
      AND ('|'+@HotelFilter+'|' LIKE '%|'+AH.[Hotel No_]+'|%' OR @HotelFilter IS NULL)
      AND ('|'+@MuseIdFilter+'|' LIKE '%|'+AH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
   OPTION (MAXDOP 1) 
   SELECT * FROM #AgencyDisplayLine

END
 
-- ----------------------------------------
-- add potential new Commission invoices
-- ----------------------------------------
    ;WITH AL AS 
   (
   SELECT DL.[Hotel No_]
        , DL.[Currency Code]
        , DL.[MuseID]
        , DL.[Case No_]
        , DL.[Document Type]
        , DL.[Posting Date]
        , SUM(DL.[Line Amount (LCY)]) [Amount (LCY)] 
     FROM #AgencyDisplayLine DL
 GROUP BY [Hotel No_]
        , [Currency Code]
        , [MuseID]
        , [Case No_]
        , [Document Type]
        , [Posting Date]
   )
   INSERT INTO #AgencyDisplayHeader
   SELECT AL.[Hotel No_]
        , AL.[Currency Code]
        , AL.[MuseID]
        , AL.[Document Type]
        , 'V'+RIGHT('000000000'+CAST(DENSE_RANK() OVER(ORDER BY CAST(AL.[Hotel No_] AS integer), AL.[Currency Code], AL.[MuseID], AL.[Document Type], AL.[Posting Date])+@OldNumber AS varchar(20)),9) [Case No_]
        , AL.[Amount (LCY)]
        , CU.[Country_Region Code]
        , 0 [existing]
        , 0 [to delete]
        , AL.[Posting Date]
        , CU.[VAT Bus_ Posting Group] [VAT Bus_ Posting Group]
        , SA.[Default VAT Prod_ Posting Grp] [VAT Prod_ Posting Group]
        , CU.[Salesperson Code] 
        , CU.[Chain] [Chain Code]
        , CAST(CU.[Brand] AS int) [Brand Code]
        , ER.[Exchange Rate Amount]
     FROM AL
     JOIN [HRS-BR$Customer]              CU WITH (NOLOCK)
       ON CU.[No_]                  = AL.[Hotel No_]
     JOIN [HRS-BR$Agency Setup] SA WITH (NOLOCK)
       ON 1=1
     JOIN @ER ER
       ON ER.[Currency Code]        = AL.[Currency Code]
    WHERE AL.[Case No_] IS NULL
   OPTION (MAXDOP 1)      

-- ----------------------------------------
-- update amount of existing commission invoices
-- ----------------------------------------
     ;WITH AL AS (SELECT [Hotel No_], [Currency Code], [MuseID], [Case No_], [Document Type], [Posting Date], SUM([Line Amount (LCY)]) [Amount (LCY)] FROM @AgencyDisplayLine GROUP BY [Hotel No_], [Currency Code], [MuseID], [Case No_], [Document Type], [Posting Date])
    UPDATE AH SET 
           AH.[Amount (LCY)] = AL.[Amount (LCY)] + AH.[Amount (LCY)]
      FROM #AgencyDisplayHeader AH
      JOIN AL 
        ON AL.[Currency Code] = AH.[Currency Code]
       AND AL.[Document Type] = AH.[Document Type]
       AND AL.[Hotel No_]     = AH.[Bill-to Customer No_]
       AND AL.[MuseID]        = AH.[MuseID]
     WHERE AH.existing        = 1
 
-- ----------------------------------------
-- update lines with new case no.
-- ----------------------------------------
    UPDATE AL SET 
           AL.[Case No_] = AH.[Case No_]
      FROM #AgencyDisplayHeader AH
      JOIN #AgencyDisplayLine AL 
        ON AL.[Currency Code] = AH.[Currency Code]
       AND AL.[Document Type] = AH.[Document Type]
       AND AL.[Hotel No_]     = AH.[Bill-to Customer No_]
       AND AL.[MuseID]        = AH.[MuseID]
     WHERE AH.existing        = 0
     
-- ----------------------------------------
-- amount limits
-- ----------------------------------------  
  IF DATEPART(m,@PostingDate)%3<>0
  BEGIN
    DELETE FROM AL
      FROM #AgencyDisplayLine AL
      JOIN #AgencyDisplayHeader AH
        ON AL.[Currency Code] = AH.[Currency Code]
       AND AL.[Document Type] = AH.[Document Type]
       AND AL.[Hotel No_]     = AH.[Bill-to Customer No_]
       AND AL.[MuseID]        = AH.[MuseID]
      JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK)
        ON CR.[Code]          = AH.[Country_Region Code]
     WHERE master.dbo.fn_varbintohexstr (CAST(SUBSTRING(CR.[Accounting Period],1,2) AS varbinary(2))) = '0x0106'
       AND CR.[Commission Value Limit (LCY)]>AH.[Amount (LCY)]
       AND AH.[MuseID]        = 'HRS'
	   AND AL.[Calculated with Function ID] <> 12

    UPDATE AH SET
           AH.[to delete] = 1
      FROM #AgencyDisplayHeader AH
      JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK)
        ON CR.[Code]          = AH.[Country_Region Code]
 LEFT JOIN #AgencyDisplayLine AL
        ON AL.[Currency Code] = AH.[Currency Code]
       AND AL.[Document Type] = AH.[Document Type]
       AND AL.[Hotel No_]     = AH.[Bill-to Customer No_]
       AND AL.[MuseID]        = AH.[MuseID]
	   AND AL.[Calculated with Function ID] = 12
     WHERE master.dbo.fn_varbintohexstr (CAST(SUBSTRING(CR.[Accounting Period],1,2) AS varbinary(2))) = '0x0106'
       AND CR.[Commission Value Limit (LCY)]>AH.[Amount (LCY)]
       AND AH.[MuseID]        = 'HRS'
	   AND AL.[Currency Code] IS NULL
        
    DELETE FROM DL
      FROM #AgencyDisplayHeader AH
      JOIN [HRS-BR$Agency Display Header] DH
        ON DH.[Currency Code]        = AH.[Currency Code]
       AND DH.[Document Type]        = AH.[Document Type]
       AND DH.[Bill-to Customer No_] = AH.[Bill-to Customer No_]
       AND DH.[MuseID]               = AH.[MuseID]
      JOIN [HRS-BR$Agency Display Line]   DL
        ON DL.[Display Case No_]     = DH.[Case No_]
     WHERE AH.[to delete]            = 1
	   AND DH.[Status]               = 0
	   AND DH.[Correction from]      = ''

    DELETE FROM DH
      FROM #AgencyDisplayHeader AH
      JOIN [HRS-BR$Agency Display Header] DH
        ON DH.[Currency Code]        = AH.[Currency Code]
       AND DH.[Document Type]        = AH.[Document Type]
       AND DH.[Bill-to Customer No_] = AH.[Bill-to Customer No_]
       AND DH.[MuseID]               = AH.[MuseID]
     WHERE AH.[to delete]            = 1
	   AND DH.[Status]               = 0
	   AND DH.[Correction from]      = ''
  END
 
-- ----------------------------------------
-- creating commission invoices
-- ----------------------------------------  
IF @Query = 0
BEGIN
     INSERT INTO [DynNavHRS].[dbo].[HRS-BR$Agency Display Header]([Case No_],[Bill-to Customer No_],[Bill-to Name],[Bill-to Address],[Bill-to Address 2],[Bill-to City],[Bill-to Post Code],[Bill-to Country_Region Code],[Bill-to Contact No_],[Bill-to Contact],[No_ Series],[Status],[Posted Invoice No_],[Correction from],[Creation Date],[Posting Date],[Currency Factor],[MuseID],[Currency Code],[Salesperson Code],[Foreign Tax %],[Chain Code],[Language Code],[Document Type],[Brand Code],[VAT Bus_ Posting Group],[VAT Prod_ Posting Group],[Loyality Rewards Account No_],[Bill-to Name 2],[Unposted Invoice No_],[Unposted Cred_ Memo No_],[Subsequent Debit from],[Delivery Type Split Invoice],[Receipient Split Invoice],[Delivery Type Fapiao],[Delivery Date Fapiao],[Fapiao No_],[Confirmed])
     SELECT DH.[Case No_]
          , DH.[Bill-to Customer No_]
          , CU.[Name]                    [Bill-to Name]
          , CU.[Address]                 [Bill-to Address]
          , CU.[Address 2]               [Bill-to Address 2]
          , CU.[City]                    [Bill-to City]
          , CU.[Post Code]               [Bill-to Post Code]
          , DH.[Country_Region Code]     [Bill-to Country_Region Code]
          , ''                           [Bill-to Contact No_]
          , CU.[Contact]                 [Bill-to Contact]
          , @NoSeries                    [No_ Series]
          , 0                            [Status]
          , ''                           [Posted Invoice No_]
          , ''                           [Correction from]
          , @PostingDate                 [Creation Date]
          , @PostingDate                 [Posting Date]
          , DH.[Exchange Rate Amount]    [Currency Factor]
          , DH.[MuseID]                  [MuseID]
          , DH.[Currency Code]           [Currency Code]
          , DH.[Salesperson Code]        [Salesperson Code]
          , 0                            [Foreign Tax %]
          , DH.[Chain Code]              [Chain Code]
          , CU.[Language Code]           [Language Code]
          , DH.[Document Type]           [Document Type]
          , DH.[Brand Code]              [Brand Code]
          , DH.[VAT Bus_ Posting Group]  [VAT Bus_ Posting Group]
          , DH.[VAT Prod_ Posting Group] [VAT Prod_ Posting Group]
          , ''                           [Loyality Rewards Account No_]
          , CU.[Name 2]                  [Bill-to Name 2]
          , ''                           [Unposted Invoice No_]
          , ''                           [Unposted Cred_ Memo No_]
          , ''                           [Subsequent Debit from]
          , 0                            [Delivery Type Split Invoice]
          , ''                           [Receipient Split Invoice]
          , 0                            [Delivery Type Fapiao]
          , '1753-01-01'                 [Delivery Date Fapiao]
          , ''                           [Fapiao No_]
		  , 0                            [Confirmed]
       FROM #AgencyDisplayHeader DH
       JOIN [HRS-BR$Customer] CU WITH (NOLOCK)
         ON CU.[No_] = DH.[Bill-to Customer No_]
      WHERE DH.[existing] = 0
   ORDER BY [Case No_]   
     OPTION (MAXDOP 1)

    DECLARE @LastNoUsed varchar(20)
     SELECT @LastNoUsed = MAX([Case No_]) FROM #AgencyDisplayHeader
     PRINT @LastNoUsed
     UPDATE [HRS-BR$No_ Series Line] SET [Last No_ Used] = @LastNoUsed, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) 
      WHERE [Series Code] = @NoSeries
        AND @OldNumber < CAST(REPLACE(@LastNoUsed,'V','') AS INT)
END

-- ----------------------------------------
-- creating commission invoice lines
-- ----------------------------------------  
IF @Query = 0
BEGIN    
     INSERT INTO [DynNavHRS].[dbo].[HRS-BR$Agency Display Line]([Display Case No_],[Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Client No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Action],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Client Company],[Client Guestname 1],[Client Guestname 2],[Description],[MuseID],[Handbooking],[ProcessNumber],[Booking Quality],[Booking Code],[Invoice No_ Old System],[Invoice Line No_ Old System],[Loyality Rewards Account No_],[Foreign Tax Roomnight Base Amt],[Foreign Tax Breakf Base Amount],[Commission Roomnight Base Amnt],[Commission Breakf Base Amount],[Foreign Tax Roomnight Amount],[Foreign Tax Breakf Amount],[Commission Roomnight Amount],[Commission Breakf Amount],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Confirmed Reservation No_],[Quality by User],[Quality at],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Booking Comment],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Booking Rating],[Multisourced],[Segment],[Breakfast Approval Status],[Rate Plan Code])
     SELECT AL.[Case No_]
          , AL.[Reservation No_]
          , AL.[Position No_]
          , AL.[Reservation Status]
          , AL.[Reservation Date from]
          , AL.[Reservation Date to]
          , AL.[Number of Rooms]
          , AL.[Room Type]
          , AL.[Rate Description]
          , AL.[Room Price]
          , AL.[Breakfast Type]
          , AL.[Breakfast Price]
          , AL.[Commission Type]
          , AL.[Commission Rate]
          , AL.[Commission Fix]
          , AL.[Rate Type]
          , AL.[Rate Key]
          , AL.[Currency Code]
          , AL.[Currency Faktor]
          , AL.[Room Number]
          , AL.[Activity Code]
          , AL.[Number of Person]
          , AL.[Hotel No_]
          , AL.[Commission Tax Type]
          , AL.[timestamp Source]
          , AL.[Price Type]
          , AL.[Process Number]
          , AL.[Inserted by User]
          , AL.[Inserted at]
          , AL.[Modified by User]
          , AL.[Modified at]
          , AL.[Number of Nights]
          , AL.[Commission Base Amount]
          , AL.[Commission Amount]
          , AL.[Commission Base Amount (LCY)]
          , AL.[Commission Amount (LCY)]
          , AL.[Foreign Tax %]
          , AL.[Foreign Tax Amount]
          , AL.[Line Amount]
          , AL.[Line Amount (LCY)]
          , AL.[Foreign Tax Base Amount]
          , AL.[Hotel sales incl_ VAT]
          , AL.[Client No_]
          , AL.[Reservation Activator]
          , AL.[Reservation State]
          , AL.[Reservation Date]
          , AL.[Reservation Time]
          , AL.[Reservation Source]
          , AL.[Arrival Date]
          , AL.[Departure Date]
          , AL.[Action]
          , AL.[Calculated with Contract Code]
          , AL.[Calculated with Function ID]
          , AL.[Calculated with Function Desc_]
          , AL.[Client Company]
          , AL.[Client Guestname 1]
          , AL.[Client Guestname 2]
          , AL.[Description]
          , AL.[MuseID]
          , AL.[Handbooking]
          , AL.[ProcessNumber]
          , AL.[Booking Quality]
          , AL.[Booking Code]
          , AL.[Invoice No_ Old System]
          , AL.[Invoice Line No_ Old System]
          , AL.[Loyality Rewards Account No_]
          , AL.[Foreign Tax Roomnight Base Amt]
          , AL.[Foreign Tax Breakf Base Amount]
          , AL.[Commission Roomnight Base Amnt]
          , AL.[Commission Breakf Base Amount]
          , AL.[Foreign Tax Roomnight Amount]
          , AL.[Foreign Tax Breakf Amount]
          , AL.[Commission Roomnight Amount]
          , AL.[Commission Breakf Amount]
          , AL.[Foreign Tax % Roomnight]
          , AL.[Foreign Tax % Breakf]
          , AL.[Confirmed Reservation No_]
          , AL.[Quality by User]
          , AL.[Quality at]
          , AL.[Ranking Booster]
          , AL.[Corporate Rate Discount]
          , AL.[Net Room Price]
          , AL.[Net Breakfast Price]
          , AL.[Booking Comment]
          , AL.[Agency Business Rules Code]
          , AL.[Deduction Type]
          , AL.[Deductible Amount]
          , AL.[Booking Rating]
          , AL.[Multisourced]
		  , AL.Segment
        , AL.[Breakfast Approval Status] 
        , AL.[Rate Plan Code]
       FROM #AgencyDisplayLine AL
   ORDER BY AL.[Case No_]
          , AL.[Reservation No_]
          , AL.[Position No_]

     UPDATE DL SET 
            DL.[MuseID] = BU.[MUSE_ID]
       FROM [HRS-BR$Agency Display Header] DH WITH (NOLOCK)
       JOIN [HRS-BR$Agency Display Line] DL WITH (NOLOCK)
         ON DL.[Display Case No_] = DH.[Case No_]
       JOIN [HRS-BR$Customer] CU WITH (NOLOCK)
         ON CU.[No_] = DH.[Bill-to Customer No_]
       JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
         ON BU.B_KEY = DL.[Reservation No_]
       JOIN [HRS-BR$Agency Header] AH WITH (NOLOCK)
         ON AH.[Reservation No_] = DL.[Reservation No_]
      WHERE DL.Multisourced = 1
        AND DH.[Posting Date] = @PostingDate
        AND DH.[Status] = 0
        AND DL.[MuseID] <> BU.[MUSE_ID]
        AND ('|'+@HotelFilter+'|' LIKE '%|'+DH.[Bill-to Customer No_]+'|%' OR @HotelFilter IS NULL)
        AND ('|'+@MuseIdFilter+'|' LIKE '%|'+DH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
        
     UPDATE AH SET 
            AH.[MuseID] = BU.[MUSE_ID]
       FROM [HRS-BR$Agency Display Header] DH WITH (NOLOCK)
       JOIN [HRS-BR$Agency Display Line] DL WITH (NOLOCK)
         ON DL.[Display Case No_] = DH.[Case No_]
       JOIN [HRS-BR$Customer] CU WITH (NOLOCK)
         ON CU.[No_] = DH.[Bill-to Customer No_]
       JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
         ON BU.B_KEY = DL.[Reservation No_]
       JOIN [HRS-BR$Agency Header] AH WITH (NOLOCK)
         ON AH.[Reservation No_] = DL.[Reservation No_]
      WHERE DL.Multisourced = 1
        AND DH.[Posting Date] = @PostingDate
        AND DH.[Status] = 0    
        AND AH.[MuseID] <> BU.[MUSE_ID]      
        AND ('|'+@HotelFilter+'|' LIKE '%|'+DH.[Bill-to Customer No_]+'|%' OR @HotelFilter IS NULL)
        AND ('|'+@MuseIdFilter+'|' LIKE '%|'+DH.[MuseID]+'|%' OR @MuseIdFilter IS NULL)
END

IF @Query = 0
BEGIN
  SELECT * FROM #AgencyDisplayHeader ORDER BY [Case No_]
  SELECT * FROM #AgencyDisplayLine ORDER BY [Case No_],[Reservation No_],[Position No_]
END       

DROP TABLE #AgencyDisplayHeader
DROP TABLE #AgencyDisplayLine
END

GO
