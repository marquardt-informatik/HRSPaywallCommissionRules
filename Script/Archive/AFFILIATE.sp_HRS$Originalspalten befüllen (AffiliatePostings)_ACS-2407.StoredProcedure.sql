USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[sp_HRS$Originalspalten befüllen (AffiliatePostings)_ACS-2407]    Script Date: 10.04.2024 14:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [AFFILIATE].[sp_HRS$Originalspalten befüllen (AffiliatePostings)_ACS-2407] AS 
BEGIN

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'INSERT [HRS$Affiliate Postings] 1', 'Start'
INSERT INTO [HRS$Affiliate Postings]([PostingDate], [DocumentDate], [Description], [Description2], [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount_LCY], [Turnover_LCY], [CommissionType], [CommissionRateProz], [RoomNights], [IsNetRate], [Amount_LCY_corr], [Turnover_LCY_corr], [CommissionType_corr], [CommissionRateProz_corr], [RoomNights_corr], [IsNetRate_corr], [DepartureDate], [AffiliatePartnerNo], [HotelNo], [NAVCompanyName], [CustomerNo], [CountryCode], [Chain], [Brand], [MuseID], [TopBonusID], [Max Entry No_], [IsNoShow], [IsCanceled], [ContractStatus], [ClientCompany], [Handbooking], [BookingUser], [ReservationSource], [ArivalDate], [ReservationDate], [AffiliateReference1], [AffiliateReference2], [ProcessNumber], [BookingCode], [Orderer], [Turnover_Breakfast_LCY], [Turnover_Breakfast_LCY_corr], [Amount], [Turnover], [CurrencyFaktor], [CurrencyCode], [Amount_corr], [Turnover_corr], [CurrencyFaktor_corr], [CurrencyCode_corr], [PostAffiliatePartnerNo], [Segment], [Segment_corr],[TAF Amount (LCY)],[TAF Amount (LCY) (corr_)],[Agency Amount (LCY)],[Agency Amount (LCY) (corr_)])
 SELECT   P.[Posting Date]                                      [PostingDate] 
        , AH1.[Creation Date]                                   [DocumentDate] 
        , AL1.[Client Guestname 1]                              [Description]
        , AL1.[Client Guestname 2]                              [Description2]
        , AL1.[Reservation No_]                                 [ReservationNo]
        , AL1.[Position No_]                                    [ReservationPartNo]
        , AH1.[Posted Invoice No_]                              [InvoiceNo]
        , AL1.[Line Amount]                    
        / CASE WHEN AL1.[Currency Faktor]=0 THEN 1 ELSE AL1.[Currency Faktor] END [Amount_LCY]
        , AL1.[Commission Base Amount (LCY)]                    
        * AL1.[Number of Nights]                                [Turnover_LCY]
        , CASE AL1.[Calculated with Function ID]
            WHEN 1 THEN 'Prozent'
            WHEN 2 THEN 'Fix'
            WHEN 3 THEN 'Prozent+Fix'
            WHEN 4 THEN 'Prozent ohne Frstk'
            WHEN 5 THEN 'Prozent ohne Frstk+Fix'
            WHEN 6 THEN 'Online'
            WHEN 7 THEN 'Zusatzprovision'
            WHEN 8 THEN '% netto Logis'
            WHEN 9 THEN '% netto Logis + Frstk'
            WHEN 10 THEN '% Nettoumsatz'
            WHEN 11 THEN 'Fix pro RN'
            WHEN 12 THEN 'Company rate'
            ELSE ''
          END                                                   [CommissionType]
        , AL1.[Commission Rate]                                 [CommissionRateProz]
        , CASE 
		    WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 -- TMA04 21.05.19 : wird nicht mehr verwendet AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3 
			  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] 
			  ELSE 0 
	      END [RoomNights]
        , CASE
            WHEN AL1.[Room Price] 
               * AL1.[Number of Nights] > 0.0 
             AND AL1.[Commission Amount (LCY)] = 0.0 THEN
              1
            ELSE
              0
          END                                                   [IsNetRate]
        , AL1.[Line Amount]                    
        / CASE WHEN AL1.[Currency Faktor]=0 THEN 1 ELSE AL1.[Currency Faktor] END [Amount_LCY_corr]
        , AL1.[Commission Base Amount (LCY)]                    
        * AL1.[Number of Nights]                                [Turnover_LCY_corr]
        , CASE AL1.[Calculated with Function ID]
            WHEN 1 THEN 'Prozent'
            WHEN 2 THEN 'Fix'
            WHEN 3 THEN 'Prozent+Fix'
            WHEN 4 THEN 'Prozent ohne Frstk'
            WHEN 5 THEN 'Prozent ohne Frstk+Fix'
            WHEN 6 THEN 'Online'
            WHEN 7 THEN 'Zusatzprovision'
            WHEN 8 THEN '% netto Logis'
            WHEN 9 THEN '% netto Logis + Frstk'
            WHEN 10 THEN '% Nettoumsatz'
            WHEN 11 THEN 'Fix pro RN'
            WHEN 12 THEN 'Company rate'
            ELSE ''
          END                                                   [CommissionType_corr]
        , AL1.[Commission Rate]                                 [CommissionRateProz_corr]
        , CASE 
		    WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 -- TMA04 21.05.19 : wird nicht mehr verwendet AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3 
			  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] 
			  ELSE 0 
	      END                                                   [RoomNights_corr]
        , CASE
            WHEN AL1.[Room Price] 
               * AL1.[Number of Nights] > 0.0 
             AND AL1.[Commission Amount (LCY)] = 0.0 THEN
              1
            ELSE
              0
          END                                                   [IsNetRate_corr]        
        , AL1.[Departure Date]                                  [DepartutreDate]
        , AL1.[Client No_]                                      [AffiliatePartnerNo]
        , AL1.[Hotel No_]                            [HotelNo]
        , 'HRS'                                                 [NAVCompanyName]
        , AH1.[Bill-to Customer No_]                            [CustomerNo]
        , AH1.[Bill-to Country_Region Code]                     [CountryCode]
        , J.[Chain]                                             [Chain]
        , J.[Brand]                                             [Brand]
        , AL1.[MuseID]                                          [MuseID]
        , LEFT(AL1.[Loyality Rewards Account No_],20)           [TopBonusID]
        , P.[Max Entry No_]                                     [Max Entry No_]   
        , 1                                                     [IsNoShow]     
        , P.[Is Canceled]
        , CASE J.[Contract Status]
            WHEN '00' THEN 'No-Contract'
            WHEN '01' THEN 'Free-Sale'
            WHEN '02' THEN 'Free-Sale-Chain'
            WHEN '03' THEN 'Hotel enquiry'
            WHEN '04' THEN 'Chain enquiry'
            WHEN '05' THEN 'Enquiry without contract'
            WHEN '06' THEN 'contract incorrect'
            WHEN '07' THEN 'Rejection'
            WHEN '08' THEN 'Company-Rate-To-Hotel'
            WHEN '09' THEN 'Company-Rate-To-Chain'
            WHEN '10' THEN 'Non-Hrs-With-Contract'
            WHEN '11' THEN 'External hotel  without contract'
            WHEN '12' THEN 'Unchecked'
            WHEN '13' THEN 'Hotel enquiry'
            WHEN '14' THEN 'CRS connection'
            WHEN '15' THEN 'incomplete'
          END                                                   [ContractStatus]   
        , AL1.[Client Company]                                  [ClientCompany]
        , AL1.[Handbooking]                                     [Handbooking]
        , ''                                                    [BookingUser]
        , AL1.[Reservation Source]                              [ReservationSource]
        , AL1.[Arrival Date]                                    [ArivalDate]
        , AL1.[Reservation Date]                                [ReservationDate]
        , ''                                                    [AffiliateReference1]
        , ''                                                    [AffiliateReference2]
        , AL1.[Process Number]                                  [ProcessNumber]
        , AL1.[Booking Code]                                    [BookingCode]
        , ''                                                    [Orderer] -- TMA04 21.05.19 : COALESCE(BU.B_BESTELLER,'')
        , CASE WHEN AL1.[Breakfast Type] = 1 THEN
            AL1.[Number of Rooms]  * AL1.[Number of Nights] 
          * AL1.[Number of Person] * AL1.[Breakfast Price]
          / CASE WHEN AL1.[Currency Faktor]=0 THEN 1 ELSE AL1.[Currency Faktor] END 
          ELSE 0 END                                            [Turnover_Breakfast_LCY]
        , 0                                                     [Turnover_Breakfast_LCY_corr]
        , AL1.[Line Amount]                                     [Amount]
        , AL1.[Commission Base Amount]                    
        * AL1.[Number of Nights]                                [Turnover]
        , AL1.[Currency Faktor]                                 [CurrencyFaktor]
        , AL1.[Currency Code]                                   [CurrencyCode]
        , 0.0                                                   [Amount_corr]
        , 0.0                                                   [Turnover_corr]
        , 0.0                                                   [CurrencyFaktor_corr]
        , ''                                                    [CurrencyCode_corr]
        , AL1.[Client No_]                                      [PostAffiliatePartnerNo] -- TMA04 21.05.19 : COALESCE(BT.K_KEY,AL1.[Client No_]) with nicht mehr verwendet
		, AL1.[Segment]											[Segment]
		, AL1.[Segment]											[Segment_corr]
		, AL1.[TAF Line Amount (LCY)]                           [TAF Amount (LCY)]
		, 0.0 [TAF Amount (LCY) (corr_)]
		, AL1.[Agency Line Amount (LCY)]                        [Agency Amount (LCY)]
		, 0.0 [Agency Amount (LCY) (corr_)]
     FROM [HRS$Agency Display Line]     AL1 WITH (READUNCOMMITTED)
	 /*
LEFT JOIN HRSDB.BUCHUNG                  BU WITH (READUNCOMMITTED)
       ON BU.B_KEY = AL1.[Reservation No_]
LEFT JOIN HRSDB.BUCHTEIL                 TL WITH (READUNCOMMITTED)
       ON TL.B_KEY = AL1.[Reservation No_]
      AND TL.BT_POS = AL1.[Position No_]
LEFT JOIN HRSDB.BUCH_TEXTE               BT WITH (READUNCOMMITTED) 
       ON BT.B_KEY = AL1.[Reservation No_] 
*/
     JOIN [HRS$Agency Display Header]   AH1 WITH (READUNCOMMITTED)
       ON AH1.[Case No_]                  = AL1.[Display Case No_]
LEFT JOIN [HRS$Affiliate Postings]       AP WITH (READUNCOMMITTED)
       ON AP.[InvoiceNo]                  = AH1.[Posted Invoice No_]
      AND AP.[ReservationNo]              = AL1.[Reservation No_]
      AND AP.[ReservationPartNo]          = AL1.[Position No_]
     JOIN [HRS$Sales Invoice Corrections] P
       ON AH1.[Posted Invoice No_]        = P.[Min Document No_]
     JOIN [HRS$Customer]                       J WITH (READUNCOMMITTED)
       ON J.[No_]                         = AL1.[Hotel No_]
LEFT JOIN [STAT].[Exclude from Affiliate Postings] S
       ON S.ReservationNo = AP.ReservationNo
      AND S.InvoiceNo = AP.InvoiceNo    
	WHERE AL1.[Reservation No_]           > 0
      AND AH1.[Status]                    = 1
      AND AL1.Action                     <> 3
      AND AP.[InvoiceNo] IS NULL
      AND AH1.[Subsequent Debit from]    = ''
	  AND S.ReservationNo IS NULL
	  AND AH1.[Document Type] NOT IN ('35')
--Atila: nächste Zeile von mir am 24.4.2013 hinzugefügt. Versuche die Zahl der parallelen Threads einzuschränken
OPTION (MAXDOP 3)
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'INSERT [HRS$Affiliate Postings] 1', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'INSERT [HRS$Affiliate Postings] 2', 'Start'
INSERT INTO [HRS$Affiliate Postings]([PostingDate], [DocumentDate], [Description], [Description2], [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount_LCY], [Turnover_LCY], [CommissionType], [CommissionRateProz], [RoomNights], [IsNetRate], [Amount_LCY_corr], [Turnover_LCY_corr], [CommissionType_corr], [CommissionRateProz_corr], [RoomNights_corr], [IsNetRate_corr], [DepartureDate], [AffiliatePartnerNo], [HotelNo], [NAVCompanyName], [CustomerNo], [CountryCode], [Chain], [Brand], [MuseID], [TopBonusID], [Max Entry No_], [IsNoShow], [IsCanceled], [ContractStatus], [ClientCompany], [Handbooking], [BookingUser], [ReservationSource], [ArivalDate], [ReservationDate], [AffiliateReference1], [AffiliateReference2], [ProcessNumber], [BookingCode], [Orderer], [Turnover_Breakfast_LCY], [Turnover_Breakfast_LCY_corr], [Amount], [Turnover], [CurrencyFaktor], [CurrencyCode], [Amount_corr], [Turnover_corr], [CurrencyFaktor_corr], [CurrencyCode_corr], [PostAffiliatePartnerNo], [Segment], [Segment_corr],[TAF Amount (LCY)],[TAF Amount (LCY) (corr_)],[Agency Amount (LCY)],[Agency Amount (LCY) (corr_)])   
 SELECT   P.[Posting Date]                                      [PostingDate] 
        , AH1.[Creation Date]                                   [DocumentDate] 
        , AL1.[Client Guestname 1]                              [Description]
        , AL1.[Client Guestname 2]                              [Description2]
        , AL1.[Reservation No_]                                 [ReservationNo]
        , AL1.[Position No_]                                    [ReservationPartNo]
        , AH1.[Posted Invoice No_]                              [InvoiceNo]
        , AL1.[Line Amount]                    
        / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END [Amount_LCY]
		, AL1.[Commission Base Amount (LCY)]                    
        * AL1.[Number of Nights]                                [Turnover_LCY]
        , CASE AL1.[Calculated with Function ID]
            WHEN 1 THEN 'Prozent'
            WHEN 2 THEN 'Fix'
            WHEN 3 THEN 'Prozent+Fix'
            WHEN 4 THEN 'Prozent ohne Frstk'
            WHEN 5 THEN 'Prozent ohne Frstk+Fix'
            WHEN 6 THEN 'Online'
            WHEN 7 THEN 'Zusatzprovision'
            WHEN 8 THEN '% netto Logis'
            WHEN 9 THEN '% netto Logis + Frstk'
            WHEN 10 THEN '% Nettoumsatz'
            WHEN 11 THEN 'Fix pro RN'
            WHEN 12 THEN 'Company rate'
            ELSE ''
          END                                                   [CommissionType]
        , AL1.[Commission Rate]                                 [CommissionRateProz]
        , CASE 
		    WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 -- TMA04 : AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3 
			  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] 
			  ELSE 0 
	      END [RoomNights]
        , CASE
            WHEN AL1.[Room Price] 
               * AL1.[Number of Nights] > 0.0 
             AND AL1.[Commission Amount (LCY)] = 0.0 THEN
              1
            ELSE
              0
          END                                                   [IsNetRate]
        , AL1.[Line Amount]                    
        / CASE WHEN AL1.[Currency Faktor] = 0 THEN 1 ELSE AL1.[Currency Faktor] END [Amount_LCY_corr]
        , AL1.[Commission Base Amount (LCY)]                    
        * AL1.[Number of Nights]                                [Turnover_LCY_corr]
        , CASE AL1.[Calculated with Function ID]
            WHEN 1 THEN 'Prozent'
            WHEN 2 THEN 'Fix'
            WHEN 3 THEN 'Prozent+Fix'
            WHEN 4 THEN 'Prozent ohne Frstk'
            WHEN 5 THEN 'Prozent ohne Frstk+Fix'
            WHEN 6 THEN 'Online'
            WHEN 7 THEN 'Zusatzprovision'
            WHEN 8 THEN '% netto Logis'
            WHEN 9 THEN '% netto Logis + Frstk'
            WHEN 10 THEN '% Nettoumsatz'
            WHEN 11 THEN 'Fix pro RN'
            WHEN 12 THEN 'Company rate'
            ELSE ''
          END                                                   [CommissionType_corr]
        , AL1.[Commission Rate]                                 [CommissionRateProz_corr]
        , CASE 
		    WHEN AL1.[Rate Type]<30000 AND AL1.[Commission Base Amount (LCY)] * AL1.[Number of Nights]>0 -- TMA04 : AND TL.BT_BIS <> TL.BT_VON AND BT_ZTYP <= 3 
			  THEN AL1.[Number of Rooms] * AL1.[Number of Nights] 
			  ELSE 0 
	      END                                                   [RoomNights_corr]
        , CASE
            WHEN AL1.[Room Price] 
               * AL1.[Number of Nights] > 0.0 
             AND AL1.[Commission Amount (LCY)] = 0.0 THEN
              1
            ELSE
              0
          END                                                   [IsNetRate_corr]        
        , AL1.[Departure Date]                                  [DepartutreDate]
        , AL1.[Client No_]                                      [AffiliatePartnerNo]
        , AH1.[Bill-to Customer No_]                            [HotelNo]
        , 'HRS'                                                 [NAVCompanyName]
        , AH1.[Bill-to Customer No_]                            [CustomerNo]
        , AH1.[Bill-to Country_Region Code]                     [CountryCode]
        , D1.[Dimension Value Code]                             [Chain]
        , D2.[Dimension Value Code]                             [Brand]
        , AL1.[MuseID]                                          [MuseID]
        , LEFT(AL1.[Loyality Rewards Account No_],20)           [TopBonusID]
        , P.[Max Entry No_]                                     [Max Entry No_]   
        , 1                                                     [IsNoShow]     
        , P.[Is Canceled]
        , CASE J.[Contract Status]
            WHEN '00' THEN 'No-Contract'
            WHEN '01' THEN 'Free-Sale'
            WHEN '02' THEN 'Free-Sale-Chain'
            WHEN '03' THEN 'Hotel enquiry'
            WHEN '04' THEN 'Chain enquiry'
            WHEN '05' THEN 'Enquiry without contract'
            WHEN '06' THEN 'contract incorrect'
            WHEN '07' THEN 'Rejection'
            WHEN '08' THEN 'Company-Rate-To-Hotel'
            WHEN '09' THEN 'Company-Rate-To-Chain'
            WHEN '10' THEN 'Non-Hrs-With-Contract'
            WHEN '11' THEN 'External hotel  without contract'
            WHEN '12' THEN 'Unchecked'
            WHEN '13' THEN 'Hotel enquiry'
            WHEN '14' THEN 'CRS connection'
            WHEN '15' THEN 'incomplete'
          END                                                   [ContractStatus]   
        , AL1.[Client Company]                                  [ClientCompany]
        , AL1.[Handbooking]                                     [Handbooking]
        , ''                                                    [BookingUser]
        , AL1.[Reservation Source]                              [ReservationSource]
        , AL1.[Arrival Date]                                    [ArivalDate]
        , AL1.[Reservation Date]                                [ReservationDate]
        , ''                                                    [AffiliateReference1]
        , ''                                                    [AffiliateReference2]
        , AL1.[Process Number]                                  [ProcessNumber]
        , AL1.[Booking Code]                                    [BookingCode]
        , ''                                                    [Orderer] -- TMA04 21.05.19 : COALESCE(BU.B_BESTELLER,'')
        , CASE WHEN AL1.[Breakfast Type] = 1 THEN
            AL1.[Number of Rooms]  * AL1.[Number of Nights] 
          * AL1.[Number of Person] * AL1.[Breakfast Price]
          / CASE WHEN AL1.[Currency Faktor]=0 THEN 1 ELSE AL1.[Currency Faktor] END 
          ELSE 0 END                                            [Turnover_Breakfast_LCY]
        , 0                                                     [Turnover_Breakfast_LCY_corr]
        , AL1.[Line Amount]                                     [Amount]
        , AL1.[Commission Base Amount]                    
        * AL1.[Number of Nights]                                [Turnover]
        , AL1.[Currency Faktor]                                 [CurrencyFaktor]
        , AL1.[Currency Code]                                   [CurrencyCode]
        , 0.0                                                   [Amount_corr]
        , 0.0                                                   [Turnover_corr]
        , 0.0                                                   [CurrencyFaktor_corr]
        , ''                                                    [CurrencyCode_corr]
        , AL1.[Client No_]                                      [PostAffiliatePartnerNo] -- TMA 21.05.19 : COALESCE(BT.K_KEY,AL1.[Client No_])
		, AL1.[Segment]											[Segment]
		, AL1.[Segment]											[Segment_corr]
        , AL1.[TAF Line Amount (LCY)]                           [TAF Amount (LCY)]
		, 0.0 [TAF Amount (LCY) (corr_)]
		, AL1.[Agency Line Amount (LCY)]                        [Agency Amount (LCY)]
		, 0.0 [Agency Amount (LCY) (corr_)]
     FROM [HRS$Agency Display Line]     AL1 WITH (READUNCOMMITTED)
/*
LEFT JOIN HRSDB.BUCHUNG                  BU WITH (READUNCOMMITTED)
       ON BU.B_KEY = AL1.[Reservation No_]
LEFT JOIN HRSDB.BUCHTEIL                 TL WITH (READUNCOMMITTED)
       ON TL.B_KEY = AL1.[Reservation No_]
      AND TL.BT_POS = AL1.[Position No_]
LEFT JOIN HRSDB.BUCH_TEXTE               BT WITH (READUNCOMMITTED) 
       ON BT.B_KEY = AL1.[Reservation No_] 
*/
     JOIN [HRS$Agency Display Header]   AH1 WITH (READUNCOMMITTED)
       ON AH1.[Case No_]                  = AL1.[Display Case No_]
LEFT JOIN [HRS$Affiliate Postings]       AP WITH (READUNCOMMITTED)
       ON AP.[ReservationNo]              = AL1.[Reservation No_]
      AND AP.[ReservationPartNo]          = AL1.[Position No_]
     JOIN [HRS$Sales Invoice Corrections] P
       ON AH1.[Posted Invoice No_]        = P.[Min Document No_]
     JOIN [HRS$Customer]                       J WITH (READUNCOMMITTED)
       ON J.[No_]                         = AH1.[Bill-to Customer No_]
     JOIN [HRS$Default Dimension]        D1 WITH (READUNCOMMITTED)
       ON D1.[Table ID]                   = 18
      AND D1.[No_]                        = J.[No_]
      AND D1.[Dimension Code]             = 'CHAIN'
     JOIN [HRS$Default Dimension]        D2 WITH (READUNCOMMITTED)
       ON D2.[Table ID]                   = 18
      AND D2.[No_]                        = J.[No_]
      AND D2.[Dimension Code]             = 'BRAND'
LEFT JOIN [STAT].[Exclude from Affiliate Postings] S
       ON S.ReservationNo = AP.ReservationNo
      AND S.InvoiceNo = AP.InvoiceNo    
    WHERE AL1.[Reservation No_]           > 0
      AND AH1.[Status]                    = 1
      AND AL1.Action                     <> 3
      AND AP.[InvoiceNo] IS NULL
      AND AH1.[Subsequent Debit from]    <> ''
	  AND S.ReservationNo IS NULL
	  AND AH1.[Document Type] NOT IN ('35')
--Atila: nächste Zeile von mir am 24.4.2013 hinzugefügt. Versuche die Zahl der parallelen Threads einzuschränken
OPTION (MAXDOP 3)
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'INSERT [HRS$Affiliate Postings] 2', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'INSERT [STAT].[Exclude from Affiliate Postings]', 'Start'
;WITH APD AS
(
   SELECT [ReservationNo]
        , [ReservationPartNo]
	    , COUNT(1) CntInvoices
	    , MIN(InvoiceNo) InvoiceNo
     FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
 GROUP BY [ReservationNo]
        , [ReservationPartNo]
   HAVING COUNT(1)>1
), EX AS
(
   SELECT APD.[ReservationNo]
        , APD.[InvoiceNo]
		, COUNT(1) CntEx
     FROM [HRS$Affiliate Postings]                 AP WITH (NOLOCK)
	 JOIN APD
	   ON APD.[ReservationNo]                    = AP.[ReservationNo]
	  AND APD.[ReservationPartNo]                = AP.[ReservationPartNo]
	  AND APD.[InvoiceNo]                       <> AP.[InvoiceNo]
LEFT JOIN [STAT].[Exclude from Affiliate Postings] EX
       ON EX.[ReservationNo]                     = AP.[ReservationNo]
    WHERE EX.[ReservationNo] IS NULL
 GROUP BY APD.[ReservationNo]
        , APD.[InvoiceNo]
)
INSERT INTO [STAT].[Exclude from Affiliate Postings]
     SELECT EX.[ReservationNo]
          , EX.[InvoiceNo]
       FROM EX
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'INSERT [STAT].[Exclude from Affiliate Postings]', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'DELETE [HRS$Affiliate Postings]', 'Start'
DELETE FROM AP
       FROM [HRS$Affiliate Postings] AP
       JOIN [STAT].[Exclude from Affiliate Postings] S
         ON S.ReservationNo = AP.ReservationNo
        AND S.InvoiceNo = AP.InvoiceNo
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'DELETE [HRS$Affiliate Postings]', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'DROP TABLE', 'Start'
-- "normale" Korrekturen
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[APCORR]') AND type in (N'U'))
  DROP TABLE [APCORR]
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AP]') AND type in (N'U'))
  DROP TABLE [AP]
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Originalspalten befüllen (AffiliatePostings)', 'DROP TABLE', 'Ende'

END        
GO
