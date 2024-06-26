USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_QueryKTZero]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_QueryKTZero] 
(
    @DateFrom date = '2019-03-01'
  , @DateTo   date = '2020-02-29'
  , @VendorNo varchar(20) = '5591'
) AS BEGIN
; WITH 
[_HRS_AP] AS (
  SELECT InvoiceNo
       , ReservationNo
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
    FROM [HRS$Affiliate Postings] WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [HRS$Affiliate Postings].[AffiliatePartnerNo]
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = [HRS$Affiliate Postings].[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = [HRS$Affiliate Postings].[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS$Booking Source].Interface
   WHERE (1=1)
	AND ([HRS$Affiliate Postings].[DepartureDate] BETWEEN @DateFrom AND @DateTo) 
    --AND [Travelagency No_] NOT IN (SELECT [Travelagency No_] FROM [HRS$Vendor Travelagency])
    --AND AffiliatePartnerNo NOT IN (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor])
	
     AND AffiliatePartnerNo IN 
         (
            SELECT [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)
	AND ([HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = @VendorNo) 
         )
     --AND CASE WHEN [Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]>=-0.01 AND [Amount_LCY_corr]-[TAF Amount (LCY) (corr_)] <= 0.01 AND Turnover_LCY_corr<>0 AND [TAF Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END=1 
     AND CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (Turnover_LCY_corr<>0 AND ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END=1 
GROUP BY InvoiceNo
       , ReservationNo
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
--HAVING SUM(Amount_LCY_corr) = 0       
)
 , 
[_HRS-BR_AP] AS (
  SELECT InvoiceNo
       , ReservationNo
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
    FROM [HRS-BR$Affiliate Postings] WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [HRS-BR$Affiliate Postings].[AffiliatePartnerNo]
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = [HRS-BR$Affiliate Postings].[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = [HRS-BR$Affiliate Postings].[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS$Booking Source].Interface
   WHERE (1=1)
	AND ([HRS-BR$Affiliate Postings].[DepartureDate] BETWEEN @DateFrom AND @DateTo) 
    --AND [Travelagency No_] NOT IN (SELECT [Travelagency No_] FROM [HRS$Vendor Travelagency])
    --AND AffiliatePartnerNo NOT IN (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor])
	
     AND AffiliatePartnerNo IN 
         (
            SELECT [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)
	AND ([HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = @VendorNo) 
         )
     --AND CASE WHEN [Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]>=-0.01 AND [Amount_LCY_corr]-[TAF Amount (LCY) (corr_)] <= 0.01 AND Turnover_LCY_corr<>0 AND [TAF Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END=1 
     AND CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (Turnover_LCY_corr<>0 AND ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END=1 
GROUP BY InvoiceNo
       , ReservationNo
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
--HAVING SUM(Amount_LCY_corr) = 0       
)
 , 
[_HRS-CN_AP] AS (
  SELECT InvoiceNo
       , ReservationNo
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
    FROM [HRS-CN$Affiliate Postings] WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [HRS-CN$Affiliate Postings].[AffiliatePartnerNo]
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = [HRS-CN$Affiliate Postings].[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = [HRS-CN$Affiliate Postings].[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS$Booking Source].Interface
   WHERE (1=1)
	AND ([HRS-CN$Affiliate Postings].[DepartureDate] BETWEEN @DateFrom AND @DateTo) 
    --AND [Travelagency No_] NOT IN (SELECT [Travelagency No_] FROM [HRS$Vendor Travelagency])
    --AND AffiliatePartnerNo NOT IN (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor])
	
     AND AffiliatePartnerNo IN 
         (
            SELECT [HRS$Affiliate Partner Vendor].[Affiliate Partner No_]
              FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK)
              JOIN [HRS$Rebate Agreement Header] WITH (NOLOCK)
                ON [HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = [HRS$Affiliate Partner Vendor].[Vendor No_]
             WHERE (1=1)
	AND ([HRS$Rebate Agreement Header].[Rebate-to Vendor No_] = @VendorNo) 
         )
     --AND CASE WHEN [Amount_LCY_corr]-[TAF Amount (LCY) (corr_)]>=-0.01 AND [Amount_LCY_corr]-[TAF Amount (LCY) (corr_)] <= 0.01 AND Turnover_LCY_corr<>0 AND [TAF Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END=1 
     AND CASE WHEN ABS([TAF Amount (LCY) (corr_)])>0.01 OR (Turnover_LCY_corr<>0 AND ABS([Amount_LCY_corr])<=0.01) THEN 1 ELSE 0 END=1 
GROUP BY InvoiceNo
       , ReservationNo
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
--HAVING SUM(Amount_LCY_corr) = 0       
)

	SELECT *
	  FROM [_HRS_AP]
 
UNION 	 
	SELECT *
	  FROM [_HRS-BR_AP]
 
UNION 	 
	SELECT *
	  FROM [_HRS-CN_AP]
END
GO
