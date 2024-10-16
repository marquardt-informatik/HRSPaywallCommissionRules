USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_QueryKTAdditionalProducts]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_QueryKTAdditionalProducts] 
(
    @DateFrom date = '2019-03-01'
  , @DateTo   date = '2020-02-29'
  , @VendorNo varchar(20) = '5591'
) AS BEGIN
; WITH ZB AS (SELECT DISTINCT [Document No_],MONTH([Posting Date]) [Posting Month] FROM [HRS-CN$Cust_ Ledger Entry] WITH (NOLOCK) WHERE [Posting Date] BETWEEN '2019-03-31' AND '2020-02-29' AND [Document Type]=2), 
[_HRS_AP] AS (
  SELECT P.[String] [Product]
       , InvoiceNo
       , ReservationNo
       , ReservationPartNo
       , ProcessNumber
       , SUM(Turnover_LCY) Turnover_LCY
       , SUM([Amount_LCY]-[TAF Amount (LCY)]) Amount_LCY
       , CommissionType_corr CommissionType
       , CommissionRateProz_corr CommissionRateProz
       , SUM(Turnover_LCY_corr) Turnover_LCY_corr
       , SUM([Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]) Amount_LCY_corr
       , AffiliatePartnerNo
       , MIN(ArivalDate) ArivalDate
       , MAX(DepartureDate) DepartureDate
       , MIN(ReservationDate) ReservationDate
       , [ReservationSource]
       , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	   , CASE
	       WHEN Segment = 0 THEN ''
	       WHEN Segment = 1 THEN 'Corporate unmanaged'
	       WHEN Segment = 2 THEN 'Leisure'
	       WHEN Segment = 3 THEN 'Corporate managed commissionable'
	       WHEN Segment = 4 THEN 'Corporate managed net'
	       WHEN Segment = 5 THEN 'MICE'
		 END [Segment]
		, SUM(RoomNights) RoomNights
		, SUM(RoomNights_corr) RoomNights_corr
		, [Chain]
		, [Brand]
		, [MuseID]
		, CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (/*Turnover_LCY_corr<>0 AND*/ ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END [NonComm]
       , SUM([TAF Amount (LCY)]) [TAF Amount (LCY)]
       , SUM([TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
    FROM [HRS$Additional Affiliate Postings] WITH (NOLOCK)
LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [HRS$Additional Affiliate Postings].[AffiliatePartnerNo]
LEFT JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = [HRS$Additional Affiliate Postings].[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = [HRS$Additional Affiliate Postings].[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS$Booking Source].Interface
    JOIN dbo.Split('Traveler TAF,Chain TAF,Partnership Fee,Additional Commission,PFP,Override,Sourcing Fee',',') P ON P.[Index]=[HRS$Additional Affiliate Postings].[Product]
   WHERE (1=1)
	AND ([HRS$Additional Affiliate Postings].[DepartureDate] BETWEEN @DateFrom AND @DateTo) 
	
     AND AffiliatePartnerNo IN 
         (
            SELECT [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)
	AND ([HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = @VendorNo) 
         )	   
GROUP BY P.[String]
       , InvoiceNo
       , ReservationNo
       , ReservationPartNo
       , ProcessNumber
       , CommissionType_corr
       , CommissionRateProz_corr
       , AffiliatePartnerNo
       , [ReservationSource]
       , [HRS$Booking Source].[Name]
       , I.[String]
       , [HotelNo]
	   , SC.[Name]
	   , DC.[Name]
	   , CASE
	       WHEN Segment = 0 THEN ''
	       WHEN Segment = 1 THEN 'Corporate unmanaged'
	       WHEN Segment = 2 THEN 'Leisure'
	       WHEN Segment = 3 THEN 'Corporate managed commissionable'
	       WHEN Segment = 4 THEN 'Corporate managed net'
	       WHEN Segment = 5 THEN 'MICE'
		 END
       , [Chain]
	   , [Brand]
	   , [MuseID]
       , CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (/*Turnover_LCY_corr<>0 AND*/ ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END
)
 , 
[_HRS-BR_AP] AS (
  SELECT P.[String] [Product]
       , InvoiceNo
       , ReservationNo
       , ReservationPartNo
       , ProcessNumber
       , SUM(Turnover_LCY) Turnover_LCY
       , SUM([Amount_LCY]-[TAF Amount (LCY)]) Amount_LCY
       , CommissionType_corr CommissionType
       , CommissionRateProz_corr CommissionRateProz
       , SUM(Turnover_LCY_corr) Turnover_LCY_corr
       , SUM([Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]) Amount_LCY_corr
       , AffiliatePartnerNo
       , MIN(ArivalDate) ArivalDate
       , MAX(DepartureDate) DepartureDate
       , MIN(ReservationDate) ReservationDate
       , [ReservationSource]
       , [HRS-BR$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	   , CASE
	       WHEN Segment = 0 THEN ''
	       WHEN Segment = 1 THEN 'Corporate unmanaged'
	       WHEN Segment = 2 THEN 'Leisure'
	       WHEN Segment = 3 THEN 'Corporate managed commissionable'
	       WHEN Segment = 4 THEN 'Corporate managed net'
	       WHEN Segment = 5 THEN 'MICE'
		 END [Segment]
		, SUM(RoomNights) RoomNights
		, SUM(RoomNights_corr) RoomNights_corr
		, [Chain]
		, [Brand]
		, [MuseID]
		, CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (/*Turnover_LCY_corr<>0 AND*/ ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END [NonComm]
       , SUM([TAF Amount (LCY)]) [TAF Amount (LCY)]
       , SUM([TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
    FROM [HRS-BR$Additional Affiliate Postings] WITH (NOLOCK)
LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [HRS-BR$Additional Affiliate Postings].[AffiliatePartnerNo]
LEFT JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = [HRS-BR$Additional Affiliate Postings].[CountryCode]
    JOIN [HRS-BR$Booking Source] WITH (NOLOCK)
      ON [HRS-BR$Booking Source].[No_] = [HRS-BR$Additional Affiliate Postings].[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS-BR$Booking Source].Interface
    JOIN dbo.Split('Traveler TAF,Chain TAF,Partnership Fee,Additional Commission,PFP,Override,Sourcing Fee',',') P ON P.[Index]=[HRS-BR$Additional Affiliate Postings].[Product]
   WHERE (1=1)
	AND ([HRS-BR$Additional Affiliate Postings].[DepartureDate] BETWEEN @DateFrom AND @DateTo) 
     AND AffiliatePartnerNo IN 
         (
            SELECT [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)
	AND ([HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = @VendorNo) 
         )	   
GROUP BY P.[String] 
       , InvoiceNo
       , ReservationNo
       , ReservationPartNo
       , ProcessNumber
       , CommissionType_corr
       , CommissionRateProz_corr
       , AffiliatePartnerNo
       , [ReservationSource]
       , [HRS-BR$Booking Source].[Name]
       , I.[String]
       , [HotelNo]
	   , SC.[Name]
	   , DC.[Name]
	   , CASE
	       WHEN Segment = 0 THEN ''
	       WHEN Segment = 1 THEN 'Corporate unmanaged'
	       WHEN Segment = 2 THEN 'Leisure'
	       WHEN Segment = 3 THEN 'Corporate managed commissionable'
	       WHEN Segment = 4 THEN 'Corporate managed net'
	       WHEN Segment = 5 THEN 'MICE'
		 END
       , [Chain]
	   , [Brand]
	   , [MuseID]
		, CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (/*Turnover_LCY_corr<>0 AND*/ ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END
)
 , 
[_HRS-CN_AP] AS (
  SELECT P.[String] [Product]
       , InvoiceNo
       , ReservationNo
       , ReservationPartNo
       , ProcessNumber
       , SUM(Turnover_LCY) Turnover_LCY
       , SUM([Amount_LCY]-[TAF Amount (LCY)]) Amount_LCY
       , CommissionType_corr CommissionType
       , CommissionRateProz_corr CommissionRateProz
       , SUM(Turnover_LCY_corr) Turnover_LCY_corr
       , SUM([Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]) Amount_LCY_corr
       , AffiliatePartnerNo
       , MIN(ArivalDate) ArivalDate
       , MAX(DepartureDate) DepartureDate
       , MIN(ReservationDate) ReservationDate
       , [ReservationSource]
       , [HRS-CN$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	   , CASE
	       WHEN Segment = 0 THEN ''
	       WHEN Segment = 1 THEN 'Corporate unmanaged'
	       WHEN Segment = 2 THEN 'Leisure'
	       WHEN Segment = 3 THEN 'Corporate managed commissionable'
	       WHEN Segment = 4 THEN 'Corporate managed net'
	       WHEN Segment = 5 THEN 'MICE'
		 END [Segment]
		, SUM(RoomNights) RoomNights
		, SUM(RoomNights_corr) RoomNights_corr
		, [Chain]
		, [Brand]
		, [MuseID]
		, CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (/*Turnover_LCY_corr<>0 AND*/ ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END [NonComm]
       , SUM([TAF Amount (LCY)]) [TAF Amount (LCY)]
       , SUM([TAF Amount (LCY) (corr_)]) [TAF Amount (LCY) (corr_)]
    FROM [HRS-CN$Additional Affiliate Postings] APO WITH (NOLOCK)
LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = APO.[AffiliatePartnerNo]
LEFT JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = APO.[CountryCode]
    JOIN [HRS-CN$Booking Source] WITH (NOLOCK)
      ON [HRS-CN$Booking Source].[No_] = APO.[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS-CN$Booking Source].Interface
    JOIN dbo.Split('Traveler TAF,Chain TAF,Partnership Fee,Additional Commission,PFP,Override,Sourcing Fee',',') P ON P.[Index]=APO.[Product]
   WHERE (1=1)
	AND (APO.[DepartureDate] BETWEEN @DateFrom AND @DateTo) 
     AND AffiliatePartnerNo IN 
         (
            SELECT [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)
	AND ([HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = @VendorNo) 
         )	   
GROUP BY P.[String] 
       , InvoiceNo
       , ReservationNo
       , ReservationPartNo
       , ProcessNumber
       , CommissionType_corr
       , CommissionRateProz_corr
       , AffiliatePartnerNo
       , [ReservationSource]
       , [HRS-CN$Booking Source].[Name]
       , I.[String]
       , [HotelNo]
	   , SC.[Name]
	   , DC.[Name]
	   , CASE
	       WHEN Segment = 0 THEN ''
	       WHEN Segment = 1 THEN 'Corporate unmanaged'
	       WHEN Segment = 2 THEN 'Leisure'
	       WHEN Segment = 3 THEN 'Corporate managed commissionable'
	       WHEN Segment = 4 THEN 'Corporate managed net'
	       WHEN Segment = 5 THEN 'MICE'
		 END
       , [Chain]
	   , [Brand]
	   , [MuseID]
		, CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (/*Turnover_LCY_corr<>0 AND*/ ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END
)
	SELECT *
	  FROM [_HRS_AP]
 
UNION ALL 	 
	SELECT *
	  FROM [_HRS-BR_AP]
 
UNION ALL 	 
	SELECT *
	  FROM [_HRS-CN_AP]
END
GO
