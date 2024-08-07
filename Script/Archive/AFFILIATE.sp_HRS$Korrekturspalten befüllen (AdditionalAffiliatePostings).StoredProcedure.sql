USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)]    Script Date: 10.04.2024 14:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [AFFILIATE].[sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)]
AS
BEGIN

-- "normale" Korrekturen
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'normale Korrekturen', 'Start'
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APCORR]') AND type in (N'U'))
  DROP TABLE [APCORR]
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AP]') AND type in (N'U'))
  DROP TABLE [AP]
   
CREATE TABLE APCORR ([Product] int not null,[ReservationNo] [int] NOT NULL, [ReservationPartNo] [int] NOT NULL, [InvoiceNo] [varchar](20) NOT NULL, [Amount_LCY_corr] [decimal](37, 20) NULL, [Turnover_LCY_corr] [decimal](37, 20) NULL, [CommissionType_corr] [varchar](50) NULL, [CommissionRateProz_corr] [decimal](37, 20) NULL, [RoomNights_corr] [decimal](37, 20) NULL, [IsNetRate_corr] [tinyint] NULL, [IsNoShow] [tinyint] NULL, [BookingUser] [varchar](20) NULL, [Turnover_Breakfast_LCY_corr] [decimal](37, 20) NULL, [Amount_corr] [decimal](37, 20) NULL, [Turnover_corr] [decimal](37, 20) NULL, [CurrencyFaktor_corr] [decimal](37, 20) NULL, [CurrencyCode_corr] [varchar](10) NULL, [Segment_corr] [int] NULL,[TAF Amount (LCY) (corr_)] [decimal](37, 20) NULL,[Agency Amount (LCY) (corr_)] [decimal](37, 20) NULL)
CREATE TABLE AP ([Product] int not null,[ReservationNo] [int] NOT NULL, [ReservationPartNo] [int] NOT NULL, [InvoiceNo] [varchar](20) NOT NULL, [Amount_LCY_corr] [decimal](37, 20) NULL, [Turnover_LCY_corr] [decimal](37, 20) NULL, [CommissionType_corr] [varchar](50) NULL, [CommissionRateProz_corr] [decimal](37, 20) NULL, [RoomNights_corr] [decimal](37, 20) NULL, [IsNetRate_corr] [tinyint] NULL, [IsNoShow] [tinyint] NULL, [BookingUser] [varchar](20) NULL, [Turnover_Breakfast_LCY_corr] [decimal](37, 20) NULL, [Amount_corr] [decimal](37, 20) NULL, [Turnover_corr] [decimal](37, 20) NULL, [CurrencyFaktor_corr] [decimal](37, 20) NULL, [CurrencyCode_corr] [varchar](10) NULL, [Segment_corr] [int] NULL,[TAF Amount (LCY) (corr_)] [decimal](37, 20) NULL,[Agency Amount (LCY) (corr_)] [decimal](37, 20) NULL)
  -- drop table #APCORR
  -- drop table #AP
INSERT INTO APCORR
SELECT AP.[Product]
     , AP.[ReservationNo]
     , AP.[ReservationPartNo]
	 , AP.[InvoiceNo]
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Line Amount] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0.0 END
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights] ELSE 0.0 END 
     , CASE WHEN IC.[Credit Memo No_] = '' THEN CASE AL1.[Calculated with Function ID] WHEN 1 THEN 'Prozent' WHEN 2 THEN 'Fix' WHEN 3 THEN 'Prozent+Fix' WHEN 4 THEN 'Prozent ohne Frstk' WHEN 5 THEN 'Prozent ohne Frstk+Fix' WHEN 6 THEN 'Online' WHEN 7 THEN 'Zusatzprovision' WHEN 8 THEN '% netto Logis' WHEN 9 THEN '% netto Logis + Frstk' WHEN 10 THEN '% Nettoumsatz' WHEN 11 THEN 'Fix pro RN' WHEN 12 THEN 'Company rate' ELSE '' END ELSE '' END
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Commission Rate] ELSE 0.0 END
     , CASE WHEN IC.[Credit Memo No_] = '' THEN CASE WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] ELSE 0 END ELSE 0.0 END
     , CASE WHEN AL1.[Room Price] * AL1.[Number of Nights] > 0.0 AND AL1.[Commission Amount (LCY)] = 0.0 THEN 1 ELSE 0 END
     , 0
     , AL1.[Modified by User]
     , CASE WHEN AL1.[Breakfast Type] = 1 THEN AL1.[Number of Rooms]  * AL1.[Number of Nights] * AL1.[Number of Person] * AL1.[Breakfast Price] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0 END
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Line Amount] ELSE 0.0 END     
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Commission Base Amount] * AL1.[Number of Nights] ELSE 0.0 END
     , AL1.[Currency Faktor]
     , AL1.[Currency Code]
	 , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Segment] ELSE 0 END  
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[TAF Line Amount] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0.0 END
     , CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Agency Line Amount] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0.0 END
  FROM [HRS$Additional Affiliate Postings] AP
  JOIN [HRS$Add.Prod. Sales Invoice Corrections] IC WITH (READUNCOMMITTED)
    ON IC.[Document No_] = AP.[InvoiceNo]
  JOIN [HRS$Agency Display Header]   AH1 WITH (READUNCOMMITTED)
    ON AH1.[Posted Invoice No_]   = IC.[Max Document No_]
  JOIN [HRS$Agency Display Line]      AL1 WITH (READUNCOMMITTED)
    ON AL1.[Reservation No_]      = AP.[ReservationNo]
   AND AL1.[Position No_]         = AP.[ReservationPartNo]
   AND AL1.[Display Case No_]     = AH1.[Case No_]
  JOIN HRSDB.BUCHTEIL                 TL WITH (READUNCOMMITTED)
       ON TL.B_KEY  = AL1.[Reservation No_]
      AND TL.BT_POS = AL1.[Position No_]
WHERE AL1.Action<>3 
  AND AL1.MuseID <> 'EAN'
  AND (
       ROUND(AP.[Amount_LCY_corr],2)            <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Line Amount] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0.0 END,2)
    OR ROUND(AP.[Turnover_LCY_corr],2)          <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights] ELSE 0.0 END,2)
    OR ROUND(AP.[CommissionRateProz_corr],2)    <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Commission Rate] ELSE 0.0 END,2)
    OR ROUND(AP.[RoomNights_corr],2)            <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN CASE WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] ELSE 0 END ELSE 0.0 END,2)
    OR ROUND(AP.[IsNetRate_corr],2)             <>ROUND(CASE WHEN AL1.[Room Price] * AL1.[Number of Nights] > 0.0 AND AL1.[Commission Amount (LCY)] = 0.0 THEN 1 ELSE 0 END,2)
    OR AP.[IsNoShow]<>0
    OR ROUND(AP.[Turnover_Breakfast_LCY_corr],2)<>ROUND(CASE WHEN AL1.[Breakfast Type] = 1 THEN AL1.[Number of Rooms]  * AL1.[Number of Nights] * AL1.[Number of Person] * AL1.[Breakfast Price] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0 END,2)
    OR ROUND(AP.[Amount_corr],2)                <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Line Amount] ELSE 0.0 END,2)
    OR ROUND(AP.[Turnover_corr],2)              <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Commission Base Amount] * AL1.[Number of Nights] ELSE 0.0 END,2)
    OR ROUND(AP.[CurrencyFaktor_corr],2)        <>ROUND(AL1.[Currency Faktor],2)
	OR AP.Segment_corr							<>CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Segment] ELSE 0 END  
    OR ROUND(AP.[TAF Amount (LCY) (corr_)],2)   <>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[TAF Line Amount] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0.0 END,2)
    OR ROUND(AP.[Agency Amount (LCY) (corr_)],2)<>ROUND(CASE WHEN IC.[Credit Memo No_] = '' THEN AL1.[Agency Line Amount] / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END ELSE 0.0 END,2)
      )  
   --AND NOT (AP.[PaymentNONCommisionableStay] =1 OR AP.[PaymentCancelation]  = 1 OR AP.[PaymentNoShow]  = 1)   
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'normale Korrekturen', 'Ende'

-- schleife start
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'schleife', 'Start'
ALTER TABLE [dbo].[AP] ADD  CONSTRAINT [IX_AP] PRIMARY KEY CLUSTERED 
(
    [Product] ASC,
	[ReservationNo] ASC,
	[ReservationPartNo] ASC
)
ALTER TABLE [dbo].[APCORR] ADD  CONSTRAINT [IX_APCORR] PRIMARY KEY CLUSTERED 
(
	[Product] ASC,
    [ReservationNo] ASC,
	[ReservationPartNo] ASC
)


DECLARE @cnt int

SELECT @cnt=COUNT(1) FROM APCORR

WHILE @cnt>0
BEGIN
  PRINT @cnt

INSERT INTO AP
SELECT TOP 10000 * FROM APCORR ORDER BY [Product], [ReservationNo], [ReservationPartNo]
DELETE TOP(10000) FROM AP
  FROM APCORR AP
  JOIN AP _AP
    ON _AP.[ReservationNo] = AP.[ReservationNo]
   AND _AP.[ReservationPartNo] = AP.[ReservationPartNo]

UPDATE AP SET
       AP.[Amount_LCY_corr]             = _AP.[Amount_LCY_corr]
     , AP.[Turnover_LCY_corr]           = _AP.[Turnover_LCY_corr]
     , AP.[CommissionType_corr]         = _AP.[CommissionType_corr]
     , AP.[CommissionRateProz_corr]     = _AP.[CommissionRateProz_corr]
     , AP.[RoomNights_corr]             = _AP.[RoomNights_corr]
     , AP.[IsNetRate_corr]              = _AP.[IsNetRate_corr]
     , AP.[IsNoShow]                    = _AP.[IsNoShow]
     , AP.[BookingUser]                 = _AP.[BookingUser]
     , AP.[Turnover_Breakfast_LCY_corr] = _AP.[Turnover_Breakfast_LCY_corr]
     , AP.[Amount_corr]                 = _AP.[Amount_corr]
     , AP.[Turnover_corr]               = _AP.[Turnover_corr]
     , AP.[CurrencyFaktor_corr]         = _AP.[CurrencyFaktor_corr]
     , AP.[CurrencyCode_corr]           = _AP.[CurrencyCode_corr]
	 , AP.[Segment_corr]				= _AP.[Segment_corr]
     , AP.[TAF Amount (LCY) (corr_)]    = _AP.[TAF Amount (LCY) (corr_)]
     , AP.[Agency Amount (LCY) (corr_)] = _AP.[Agency Amount (LCY) (corr_)]
  FROM [HRS$Additional Affiliate Postings] AP
  JOIN AP _AP
    ON _AP.[ReservationNo] = AP.[ReservationNo]
   AND _AP.[ReservationPartNo] = AP.[ReservationPartNo]

TRUNCATE TABLE AP

SELECT @cnt=COUNT(1) FROM APCORR
-- schleife ende
END

   drop table APCORR
   drop table AP
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'schleife', 'Ende'

-- Komplettstornos 
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'Komplettstornos', 'Start'
UPDATE AP SET
       AP.[Amount_LCY_corr]             = 0.0
     , AP.[Turnover_LCY_corr]           = 0.0
     , AP.[CommissionType_corr]         = ''
     , AP.[CommissionRateProz_corr]     = 0.0
     , AP.[RoomNights_corr]             = 0.0
     , AP.[IsNetRate_corr]              = 0
     , AP.[IsNoShow]                    = 1
     , AP.[BookingUser]                 = ''
     , AP.[Turnover_Breakfast_LCY_corr] = 0.0
     , AP.[Amount_corr]                 = 0.0     
     , AP.[Turnover_corr]               = 0.0
     , AP.[CurrencyFaktor_corr]         = 0.0
     , AP.[CurrencyCode_corr]           = ''
	 , AP.[Segment_corr]				= 0
     , AP.[TAF Amount (LCY) (corr_)]    = 0.0
     , AP.[Agency Amount (LCY) (corr_)] = 0.0
  FROM [HRS$Additional Affiliate Postings] AP
  JOIN [HRS$Add.Prod. Sales Invoice Corrections] IC WITH (READUNCOMMITTED)
    ON IC.[Document No_]          = AP.[InvoiceNo]
  JOIN [HRS$Agency Display Header]    AH1 WITH (READUNCOMMITTED)
    ON AH1.[Posted Invoice No_]   = IC.[Max Document No_]
  JOIN [HRS$Agency Display Line]      AL1 WITH (READUNCOMMITTED)
    ON AL1.[Reservation No_]      = AP.[ReservationNo]
   AND AL1.[Position No_]         = AP.[ReservationPartNo]
   AND AL1.[Display Case No_]     = AH1.[Case No_]
WHERE AL1.Action=3 
  AND (
       AP.[Amount_LCY_corr]             <> 0.0
    OR AP.[Turnover_LCY_corr]           <> 0.0
    OR AP.[CommissionType_corr]         <> ''
    OR AP.[CommissionRateProz_corr]     <> 0.0
    OR AP.[RoomNights_corr]             <> 0.0
    OR AP.[IsNetRate_corr]              <> 0
    OR AP.[IsNoShow]                    <> 1
    OR AP.[BookingUser]                 <> ''
    OR AP.[Turnover_Breakfast_LCY_corr] <> 0.0
    OR AP.[Amount_corr]                 <> 0.0     
    OR AP.[Turnover_corr]               <> 0.0
    OR AP.[CurrencyFaktor_corr]         <> 0.0
    OR AP.[CurrencyCode_corr]           <> ''
	OR AP.[Segment_corr]				<> 0
    OR AP.[TAF Amount (LCY) (corr_)]    <> 0.0
    OR AP.[Agency Amount (LCY) (corr_)] <> 0.0
      ) 
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'Komplettstornos', 'Ende'

-- Nachbelastungen : RFC-76099
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'Nachbelastungen : RFC-76099', 'Start'
DECLARE @countNBCorrection int
    SET @countNBCorrection = 0
;WITH 
  DL AS(SELECT DH1.[Case No_], DH1.[Posted Invoice No_], CLE.[Entry No_], DL1.[Reservation No_], DL1.[Position No_], DL1.[Currency Faktor], DL1.[Currency Code], DL1.[Commission Base Amount], DL1.[Commission Base Amount (LCY)], DL1.[Commission Amount (LCY)], DL1.[Line Amount], DL1.[Number of Nights], DL1.[Number of Person], DL1.[Number of Rooms], DL1.[Calculated with Function ID], DL1.[Commission Rate], DL1.[Rate Type], DL1.[Room Price], DL1.[Modified by User], DL1.[Breakfast Type], DL1.[Breakfast Price], DL1.[Segment],DL1.[Agency Line Amount],DL1.[Agency Line Amount (LCY)],DL1.[TAF Line Amount],DL1.[TAF Line Amount (LCY)] FROM [HRS$Agency Display Line]   DL1 WITH (NOLOCK) JOIN [HRS$Agency Display Header] DH1 WITH (NOLOCK) ON DH1.[Case No_]     = DL1.[Display Case No_] JOIN [HRS$Cust_ Ledger Entry]    CLE WITH (NOLOCK) ON CLE.[Document No_] = DH1.[Posted Invoice No_] AND CLE.[Document Type] = 2 WHERE DH1.[Subsequent Debit from] <> '' AND DL1.Action <> 3 AND DL1.[MuseID]<>'EAN')
, DM AS(SELECT DL.[Reservation No_], DL.[Position No_], MAX(DL.[Entry No_]) [Entry No_] FROM DL GROUP BY DL.[Reservation No_], DL.[Position No_])
, SD AS(SELECT DL.* FROM DL JOIN DM ON DM.[Reservation No_] = DL.[Reservation No_] AND DM.[Position No_] = DL.[Position No_] AND DM.[Entry No_] = DL.[Entry No_])
 SELECT @countNBCorrection = COUNT(1)
  FROM [HRS$Additional Affiliate Postings] AP
  JOIN SD ON SD.[Reservation No_] = AP.ReservationNo AND SD.[Position No_] = AP.ReservationPartNo
  JOIN [HRS$Add.Prod. Sales Invoice Corrections] IC WITH (READUNCOMMITTED)ON IC.[Document No_] = SD.[Posted Invoice No_]
  JOIN HRSDB.BUCHTEIL                 TL WITH (READUNCOMMITTED)
    ON TL.B_KEY  = AP.[ReservationNo]
   AND TL.BT_POS = AP.[ReservationPartNo]
 WHERE AP.[Amount_LCY_corr]             <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
    OR AP.[Turnover_LCY_corr]           <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Base Amount (LCY)] * SD.[Number of Nights] ELSE 0.0 END 
    OR AP.[CommissionType_corr]         <> CASE WHEN IC.[Credit Memo No_] = '' THEN CASE SD.[Calculated with Function ID] WHEN 1 THEN 'Prozent' WHEN 2 THEN 'Fix' WHEN 3 THEN 'Prozent+Fix' WHEN 4 THEN 'Prozent ohne Frstk' WHEN 5 THEN 'Prozent ohne Frstk+Fix' WHEN 6 THEN 'Online' WHEN 7 THEN 'Zusatzprovision' WHEN 8 THEN '% netto Logis' WHEN 9 THEN '% netto Logis + Frstk' WHEN 10 THEN '% Nettoumsatz' WHEN 11 THEN 'Fix pro RN' WHEN 12 THEN 'Company rate' ELSE '' END ELSE '' END
    OR AP.[CommissionRateProz_corr]     <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Rate] ELSE 0.0 END
    OR AP.[RoomNights_corr]             <> CASE WHEN IC.[Credit Memo No_] = '' THEN CASE WHEN SD.[Rate Type]<30000  AND SD.[Commission Base Amount (LCY)] * SD.[Number of Nights]>0 AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3  THEN SD.[Number of Rooms] * SD.[Number of Nights] ELSE 0 END ELSE 0.0 END
    OR AP.[IsNetRate_corr]              <> CASE WHEN SD.[Room Price] * SD.[Number of Nights] > 0.0 AND SD.[Commission Amount (LCY)] = 0.0 THEN 1 ELSE 0 END
    OR AP.[IsNoShow]                    <> 0
    OR AP.[BookingUser]                 <> SD.[Modified by User]
    OR AP.[Turnover_Breakfast_LCY_corr] <> CASE WHEN SD.[Breakfast Type] = 1 THEN SD.[Number of Rooms]  * SD.[Number of Nights] * SD.[Number of Person] * SD.[Breakfast Price] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0 END
    OR AP.[Amount_corr]                 <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Line Amount] ELSE 0.0 END     
    OR AP.[Turnover_corr]               <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Base Amount] * SD.[Number of Nights] ELSE 0.0 END
    OR AP.[CurrencyFaktor_corr]         <> SD.[Currency Faktor]
    OR AP.[CurrencyCode_corr]           <> SD.[Currency Code]
	OR AP.[Segment_corr]				<> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Segment] ELSE 0 END
    OR AP.[TAF Amount (LCY) (corr_)]    <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[TAF Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
    OR AP.[Agency Amount (LCY) (corr_)] <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Agency Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
   AND NOT (AP.[PaymentNONCommisionableStay] =1 OR AP.[PaymentCancelation]  = 1 OR AP.[PaymentNoShow]  = 1)   

DECLARE @loop int
    SET @loop = 0

WHILE @loop < @countNBCorrection
BEGIN 
;WITH 
  DL AS(SELECT DH1.[Case No_], DH1.[Posted Invoice No_], CLE.[Entry No_], DL1.[Reservation No_], DL1.[Position No_], DL1.[Currency Faktor], DL1.[Currency Code], DL1.[Commission Base Amount], DL1.[Commission Base Amount (LCY)], DL1.[Commission Amount (LCY)], DL1.[Line Amount], DL1.[Number of Nights], DL1.[Number of Person], DL1.[Number of Rooms], DL1.[Calculated with Function ID], DL1.[Commission Rate], DL1.[Rate Type], DL1.[Room Price], DL1.[Modified by User], DL1.[Breakfast Type], DL1.[Breakfast Price], DL1.[Segment],DL1.[Agency Line Amount],DL1.[Agency Line Amount (LCY)],DL1.[TAF Line Amount],DL1.[TAF Line Amount (LCY)] FROM [HRS$Agency Display Line]   DL1 WITH (NOLOCK) JOIN [HRS$Agency Display Header] DH1 WITH (NOLOCK) ON DH1.[Case No_]     = DL1.[Display Case No_] JOIN [HRS$Cust_ Ledger Entry]    CLE WITH (NOLOCK) ON CLE.[Document No_] = DH1.[Posted Invoice No_] AND CLE.[Document Type] = 2 WHERE DH1.[Subsequent Debit from] <> '' AND DL1.Action <> 3 AND DL1.[MuseID]<>'EAN')
, DM AS(SELECT DL.[Reservation No_], DL.[Position No_], MAX(DL.[Entry No_]) [Entry No_] FROM DL GROUP BY DL.[Reservation No_], DL.[Position No_])
, SD AS(SELECT DL.* FROM DL JOIN DM ON DM.[Reservation No_] = DL.[Reservation No_] AND DM.[Position No_] = DL.[Position No_] AND DM.[Entry No_] = DL.[Entry No_])
UPDATE TOP (10000) AP SET
       AP.[Amount_LCY_corr]             = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
     , AP.[Turnover_LCY_corr]           = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Base Amount (LCY)] * SD.[Number of Nights] ELSE 0.0 END 
     , AP.[CommissionType_corr]         = CASE WHEN IC.[Credit Memo No_] = '' THEN CASE SD.[Calculated with Function ID] WHEN 1 THEN 'Prozent' WHEN 2 THEN 'Fix' WHEN 3 THEN 'Prozent+Fix' WHEN 4 THEN 'Prozent ohne Frstk' WHEN 5 THEN 'Prozent ohne Frstk+Fix' WHEN 6 THEN 'Online' WHEN 7 THEN 'Zusatzprovision' WHEN 8 THEN '% netto Logis' WHEN 9 THEN '% netto Logis + Frstk' WHEN 10 THEN '% Nettoumsatz' WHEN 11 THEN 'Fix pro RN' WHEN 12 THEN 'Company rate' ELSE '' END ELSE '' END
     , AP.[CommissionRateProz_corr]     = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Rate] ELSE 0.0 END
     , AP.[RoomNights_corr]             = CASE WHEN IC.[Credit Memo No_] = '' THEN CASE WHEN SD.[Rate Type]<30000  AND SD.[Commission Base Amount (LCY)] * SD.[Number of Nights]>0 AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3  THEN SD.[Number of Rooms] * SD.[Number of Nights] ELSE 0 END ELSE 0.0 END
     , AP.[IsNetRate_corr]              = CASE WHEN SD.[Room Price] * SD.[Number of Nights] > 0.0 AND SD.[Commission Amount (LCY)] = 0.0 THEN 1 ELSE 0 END
     , AP.[IsNoShow]                    = 0
     , AP.[BookingUser]                 = SD.[Modified by User]
     , AP.[Turnover_Breakfast_LCY_corr] = CASE WHEN SD.[Breakfast Type] = 1 THEN SD.[Number of Rooms]  * SD.[Number of Nights] * SD.[Number of Person] * SD.[Breakfast Price] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0 END
     , AP.[Amount_corr]                 = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Line Amount] ELSE 0.0 END     
     , AP.[Turnover_corr]               = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Base Amount] * SD.[Number of Nights] ELSE 0.0 END
     , AP.[CurrencyFaktor_corr]         = SD.[Currency Faktor]
     , AP.[CurrencyCode_corr]           = SD.[Currency Code]
	 , AP.[Segment_corr]				= CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Segment] ELSE 0 END
     , AP.[TAF Amount (LCY) (corr_)]    = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[TAF Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
     , AP.[Agency Amount (LCY) (corr_)] = CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Agency Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
  FROM [HRS$Additional Affiliate Postings] AP
  JOIN SD ON SD.[Reservation No_] = AP.ReservationNo AND SD.[Position No_] = AP.ReservationPartNo
  JOIN [HRS$Add.Prod. Sales Invoice Corrections] IC WITH (READUNCOMMITTED)ON IC.[Document No_] = SD.[Posted Invoice No_]
  JOIN HRSDB.BUCHTEIL                 TL WITH (READUNCOMMITTED)
    ON TL.B_KEY  = AP.[ReservationNo]
   AND TL.BT_POS = AP.[ReservationPartNo]
 WHERE AP.[Amount_LCY_corr]             <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
    OR AP.[Turnover_LCY_corr]           <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Base Amount (LCY)] * SD.[Number of Nights] ELSE 0.0 END 
    OR AP.[CommissionType_corr]         <> CASE WHEN IC.[Credit Memo No_] = '' THEN CASE SD.[Calculated with Function ID] WHEN 1 THEN 'Prozent' WHEN 2 THEN 'Fix' WHEN 3 THEN 'Prozent+Fix' WHEN 4 THEN 'Prozent ohne Frstk' WHEN 5 THEN 'Prozent ohne Frstk+Fix' WHEN 6 THEN 'Online' WHEN 7 THEN 'Zusatzprovision' WHEN 8 THEN '% netto Logis' WHEN 9 THEN '% netto Logis + Frstk' WHEN 10 THEN '% Nettoumsatz' WHEN 11 THEN 'Fix pro RN' WHEN 12 THEN 'Company rate' ELSE '' END ELSE '' END
    OR AP.[CommissionRateProz_corr]     <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Rate] ELSE 0.0 END
    OR AP.[RoomNights_corr]             <> CASE WHEN IC.[Credit Memo No_] = '' THEN CASE WHEN SD.[Rate Type]<30000  AND SD.[Commission Base Amount (LCY)] * SD.[Number of Nights]>0 AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3  THEN SD.[Number of Rooms] * SD.[Number of Nights] ELSE 0 END ELSE 0.0 END
    OR AP.[IsNetRate_corr]              <> CASE WHEN SD.[Room Price] * SD.[Number of Nights] > 0.0 AND SD.[Commission Amount (LCY)] = 0.0 THEN 1 ELSE 0 END
    OR AP.[IsNoShow]                    <> 0
    OR AP.[BookingUser]                 <> SD.[Modified by User]
    OR AP.[Turnover_Breakfast_LCY_corr] <> CASE WHEN SD.[Breakfast Type] = 1 THEN SD.[Number of Rooms]  * SD.[Number of Nights] * SD.[Number of Person] * SD.[Breakfast Price] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0 END
    OR AP.[Amount_corr]                 <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Line Amount] ELSE 0.0 END     
    OR AP.[Turnover_corr]               <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Commission Base Amount] * SD.[Number of Nights] ELSE 0.0 END
    OR AP.[CurrencyFaktor_corr]         <> SD.[Currency Faktor]
    OR AP.[CurrencyCode_corr]           <> SD.[Currency Code]
	OR AP.[Segment_corr]				<> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Segment] ELSE 0 END
	OR AP.[TAF Amount (LCY) (corr_)]    <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[TAF Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
	OR AP.[Agency Amount (LCY) (corr_)] <> CASE WHEN IC.[Credit Memo No_] = '' THEN SD.[Agency Line Amount] / CASE WHEN SD.[Currency Faktor] = 0 THEN 1 ELSE SD.[Currency Faktor] END ELSE 0.0 END
   AND NOT (AP.[PaymentNONCommisionableStay] =1 OR AP.[PaymentCancelation]  = 1 OR AP.[PaymentNoShow]  = 1)   
  SET @loop = @loop + 10000
END    
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AffiliatePostings)', 'Nachbelastungen : RFC-76099', 'Ende'

-- "manuell eingefügte" Korrekturen ohne DB/2-Bezug
--EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AffiliatePostings)', 'manuell eingefügte Korrekturen ohne DB2-Bezug', 'Start'
--INSERT INTO [HRS$Additional Affiliate Postings]([Product], [PostingDate], [DocumentDate], [Description], [Description2], [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount_LCY], [Turnover_LCY], [CommissionType], [CommissionRateProz], [RoomNights], [IsNetRate], [Amount_LCY_corr], [Turnover_LCY_corr], [CommissionType_corr], [CommissionRateProz_corr], [RoomNights_corr], [IsNetRate_corr], [DepartureDate], [AffiliatePartnerNo], [HotelNo], [NAVCompanyName], [CustomerNo], [CountryCode], [Chain], [Brand], [MuseID], [TopBonusID], [Max Entry No_], [IsNoShow], [IsCanceled], [ContractStatus], [ClientCompany], [Handbooking], [BookingUser], [ReservationSource], [ArivalDate], [ReservationDate], [AffiliateReference1], [AffiliateReference2], [ProcessNumber], [BookingCode], [Orderer], [Turnover_Breakfast_LCY], [Turnover_Breakfast_LCY_corr], [Amount], [Turnover], [CurrencyFaktor], [CurrencyCode], [Amount_corr], [Turnover_corr], [CurrencyFaktor_corr], [CurrencyCode_corr], [PostAffiliatePartnerNo], [Segment], [Segment_corr],[TAF Amount (LCY)],[TAF Amount (LCY) (corr_)],[Agency Amount (LCY)],[Agency Amount (LCY) (corr_)])
-- SELECT   CAST(AH1.[Document Type] as int)-36
--        , IC.[Posting Date]                                      [PostingDate] 
--        , AH1.[Creation Date]                                   [DocumentDate] 
--        , AL1.[Client Guestname 1]                              [Description]
--        , AL1.[Client Guestname 2]                              [Description2]
--        , AL1.[Reservation No_]                                 [ReservationNo]
--        , AL1.[Position No_]                                    [ReservationPartNo]
--        , AH1.[Posted Invoice No_]                              [InvoiceNo]
--        , 0.0                                                   [Amount_LCY]
--        , 0.0                                                   [Turnover_LCY]
--        , ''                                                    [CommissionType]
--        , 0.0                                                   [CommissionRateProz]
--        , 0.0                                                   [RoomNights]
--        , 0                                                     [IsNetRate]        
--        , AL1.[Line Amount]                    
--        / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END [Amount_LCY_corr]
--        , AL1.[Commission Base Amount (LCY)]                    
--        * AL1.[Number of Nights]                                [Turnover_LCY_corr]
--        , CASE AL1.[Calculated with Function ID]
--            WHEN 1 THEN 'Prozent'
--            WHEN 2 THEN 'Fix'
--            WHEN 3 THEN 'Prozent+Fix'
--            WHEN 4 THEN 'Prozent ohne Frstk'
--            WHEN 5 THEN 'Prozent ohne Frstk+Fix'
--            WHEN 6 THEN 'Online'
--            WHEN 7 THEN 'Zusatzprovision'
--            WHEN 8 THEN '% netto Logis'
--            WHEN 9 THEN '% netto Logis + Frstk'
--            WHEN 10 THEN '% Nettoumsatz'
--            WHEN 11 THEN 'Fix pro RN'
--            WHEN 12 THEN 'Company rate'
--            ELSE ''
--          END                                                   [CommissionType_corr]
--        , AL1.[Commission Rate]                                 [CommissionRateProz_corr]
--        , CASE 
--		    WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 --AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3 
--			  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] 
--			  ELSE 0 
--	      END [RoomNights]
--        , CASE
--            WHEN AL1.[Room Price] 
--               * AL1.[Number of Nights] > 0.0 
--             AND AL1.[Commission Amount (LCY)] = 0.0 THEN
--              1
--            ELSE
--              0
--          END                                                   [IsNetRate_corr]
--        , AL1.[Departure Date]                                  [DepartutreDate]
--        , AL1.[Client No_]                                      [AffiliatePartnerNo]
--        , AH1.[Bill-to Customer No_]                            [HotelNo]
--        , 'HRS'                                                 [NAVCompanyName]
--        , AH1.[Bill-to Customer No_]                            [CustomerNo]
--        , AH1.[Bill-to Country_Region Code]                     [CountryCode]
--        , D1.[Dimension Value Code]                             [Chain]
--        , D2.[Dimension Value Code]                             [Brand]
--        , AL1.[MuseID]                                          [MuseID]
--        , LEFT(AL1.[Loyality Rewards Account No_],20)           [TopBonusID]
--        , IC.[Max Entry No_]                                    [Max Entry No_]   
--        , 0                                                     [IsNoShow]     
--        , IC.[Is Canceled]
--        , CASE J.[Contract Status]
--            WHEN '00' THEN 'No-Contract'
--            WHEN '01' THEN 'Free-Sale'
--            WHEN '02' THEN 'Free-Sale-Chain'
--            WHEN '03' THEN 'Hotel enquiry'
--            WHEN '04' THEN 'Chain enquiry'
--            WHEN '05' THEN 'Enquiry without contract'
--            WHEN '06' THEN 'contract incorrect'
--            WHEN '07' THEN 'Rejection'
--            WHEN '08' THEN 'Company-Rate-To-Hotel'
--            WHEN '09' THEN 'Company-Rate-To-Chain'
--            WHEN '10' THEN 'Non-Hrs-With-Contract'
--            WHEN '11' THEN 'External hotel  without contract'
--            WHEN '12' THEN 'Unchecked'
--            WHEN '13' THEN 'Hotel enquiry'
--            WHEN '14' THEN 'CRS connection'
--            WHEN '15' THEN 'incomplete'
--          END                                                   [ContractStatus]   
--        , AL1.[Client Company]                                  [ClientCompany]
--        , AL1.[Handbooking]                                     [Handbooking]
--        , ''                                                    [BookingUser]
--        , AL1.[Reservation Source]                              [ReservationSource]
--        , AL1.[Arrival Date]                                    [ArivalDate]
--        , AL1.[Reservation Date]                                [ReservationDate]
--        , ''                                                    [AffiliateReference1]
--        , ''                                                    [AffiliateReference2]
--        , AL1.[Process Number]                                  [ProcessNumber]
--        , AL1.[Booking Code]                                    [BookingCode]
--        , ''                                                    [Orderer]
--        , 0                                                     [Turnover_Breakfast_LCY]
--        , CASE WHEN AL1.[Breakfast Type] = 1 THEN
--            AL1.[Number of Rooms]  * AL1.[Number of Nights] 
--          * AL1.[Number of Person] * AL1.[Breakfast Price]
--          / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END 
--          ELSE 0 END                                            [Turnover_Breakfast_LCY_corr]
--        , 0.0                                                   [Amount]
--        , 0.0                                                   [Turnover]
--        , 0.0                                                   [CurrencyFaktor]
--        , ''                                                    [CurrencyCode]
--        , AL1.[Line Amount]                                     [Amount_corr]
--        , AL1.[Commission Base Amount]                    
--        * AL1.[Number of Nights]                                [Turnover_corr]
--        , AL1.[Currency Faktor]                                 [CurrencyFaktor_corr]
--        , AL1.[Currency Code]                                   [CurrencyCode_corr]
--        , 0                                                     [PostAffiliatePartnerNo]
--		, 0														[Segment]
--		, AL1.[Segment]											[Segment_corr]
--		, AL1.[TAF Line Amount (LCY)]                           [TAF Amount (LCY)]
--		, 0.0                                                   [TAF Amount (LCY) (corr_)]
--		, AL1.[Agency Line Amount (LCY)]                        [Agency Amount (LCY)]
--		, 0.0                                                   [Agency Amount (LCY) (corr_)]
--     FROM [HRS$Add.Prod. Sales Invoice Corrections]   IC  WITH (READUNCOMMITTED)
--     JOIN [HRS$Agency Display Header]       AH1 WITH (READUNCOMMITTED)
--       ON AH1.[Posted Invoice No_]        = IC.[Max Document No_]
--     JOIN [HRS$Agency Display Line]         AL1 WITH (READUNCOMMITTED)
--       ON AL1.[Display Case No_]          = AH1.[Case No_]
--LEFT JOIN [HRS$Additional Affiliate Postings]          AP  WITH (READUNCOMMITTED)
--       ON AL1.[Reservation No_]           = AP.[ReservationNo]
--      AND AL1.[Position No_]              = AP.[ReservationPartNo]
--     JOIN [HRS$Customer]                    J
--       ON J.[No_]                         = AH1.[Bill-to Customer No_]
--     JOIN [HRS$Default Dimension]           D1  WITH (READUNCOMMITTED)
--       ON D1.[Table ID]                   = 18
--      AND D1.[No_]                        = J.[No_]
--      AND D1.[Dimension Code]             = 'CHAIN'
--     JOIN [HRS$Default Dimension]           D2 WITH (READUNCOMMITTED)
--       ON D2.[Table ID]                   = 18
--      AND D2.[No_]                        = J.[No_]
--      AND D2.[Dimension Code]             = 'BRAND'
--    WHERE AL1.Action<>3 
--      AND AP.[ReservationNo] IS NULL
--      AND AH1.[Posting Date] >= '2014-01-01'
--   OPTION (MAXDOP 1)
--EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'manuell eingefügte Korrekturen ohne DB2-Bezug', 'Ende'

---- Netto Raten
--EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'Netto Raten', 'Start'
--UPDATE [HRS$Additional Affiliate Postings] SET [IsNetRate_corr] = 0 WHERE [IsNoShow] = 1 AND [IsNetRate_corr] = 1
--EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'Netto Raten', 'Ende'

-- falsche Null-Setzung korrigieren
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'falsche Null-Setzung korrigieren', 'Start'
UPDATE AP SET 
       AP.[Turnover_LCY_corr] = 0.0
     , AP.[Turnover_Breakfast_LCY_corr] = 0.0
     , AP.[Turnover_corr]= 0.0
  FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
 WHERE AP.[Turnover_LCY_corr] > 0.0
   AND AP.[CommissionType] = AP.[CommissionType_corr]
   AND AP.[CommissionRateProz] > 0.0
   AND AP.[CommissionRateProz_corr] = 0.0
   AND AP.PostingDate >= '2013-01-01'
   AND AP.MuseID <> 'HRS'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Korrekturspalten befüllen (AdditionalAffiliatePostings)', 'falsche Null-Setzung korrigieren', 'Ende'

UPDATE [HRS$Additional Affiliate Postings] SET [TAF Amount (LCY) (corr_)]=Amount_LCY_corr-[Agency Amount (LCY) (corr_)] WHERE [TAF Amount (LCY) (corr_)]<>Amount_LCY_corr-[Agency Amount (LCY) (corr_)]

END   

GO
