USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Affiliate_Travelport]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_Affiliate_Travelport]
  @dateFrom Date
, @dateTo Date

AS
BEGIN
; WITH 
[_TISCOVER_AP] AS (
  SELECT CASE 
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND     DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '01 BASE'
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND NOT DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '02 BASE'
		   WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr=0 THEN '03 NON-COMM'
		   WHEN Turnover_LCY_corr=0 THEN '04 CANCELLATION'
         END [TAB]
       , InvoiceNo
       , ReservationNo
	   , ReservationPartNo
       , ProcessNumber
       , Turnover_LCY
       , Amount_LCY
       , CommissionType
       , CommissionRateProz	   
       , Turnover_LCY_corr
       , Amount_LCY_corr
       , AffiliatePartnerNo	   
       , ArivalDate
       , DepartureDate
       , ReservationDate
       , [ReservationSource]
	   , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , Interface
	   , [Description]
	   , [TopBonusID]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]	
    FROM [TISCOVER$Affiliate Postings] WITH (NOLOCK)
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [TISCOVER$Affiliate Postings].[AffiliatePartnerNo]
	JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = [TISCOVER$Affiliate Postings].[CountryCode]
    JOIN [HRS$Booking Source] WITH (NOLOCK)
      ON [HRS$Booking Source].[No_] = [TISCOVER$Affiliate Postings].[ReservationSource]
    JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = [HRS$Booking Source].Interface
   WHERE (1=1)
	AND ([TISCOVER$Affiliate Postings].[DepartureDate] BETWEEN @dateFrom AND @dateTo)
	AND ([TISCOVER$Affiliate Postings].[ReservationSource] BETWEEN 798 AND 801)
)
 , 
[_HRS-CN_AP] AS (
  SELECT CASE 
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND     DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '01 BASE'
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND NOT DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '02 BASE'
		   WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr=0 THEN '03 NON-COMM'
		   WHEN Turnover_LCY_corr=0 THEN '04 CANCELLATION'
         END [TAB]
       , InvoiceNo
       , ReservationNo
	   , ReservationPartNo
       , ProcessNumber
       , Turnover_LCY
       , Amount_LCY
       , CommissionType
       , CommissionRateProz	   
       , Turnover_LCY_corr
       , Amount_LCY_corr
       , AffiliatePartnerNo
	   , ArivalDate
       , DepartureDate
       , ReservationDate
       , [ReservationSource]
       , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , Interface
	   , [Description]
	   , [TopBonusID]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
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
	AND ([HRS-CN$Affiliate Postings].[DepartureDate] BETWEEN @dateFrom AND @dateTo)
	AND ([HRS-CN$Affiliate Postings].[ReservationSource] BETWEEN 798 AND 801) 
)
 , 
[_HRS-BR_AP] AS (
  SELECT CASE 
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND     DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '01 BASE'
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND NOT DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '02 BASE'
		   WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr=0 THEN '03 NON-COMM'
		   WHEN Turnover_LCY_corr=0 THEN '04 CANCELLATION'
         END [TAB]
       , InvoiceNo
       , ReservationNo
	   , ReservationPartNo
       , ProcessNumber
       , Turnover_LCY
       , Amount_LCY
       , CommissionType
       , CommissionRateProz	   
       , Turnover_LCY_corr
       , Amount_LCY_corr
       , AffiliatePartnerNo	   
       , ArivalDate
       , DepartureDate
       , ReservationDate
       , [ReservationSource]
	   , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , Interface
	   , [Description]
	   , [TopBonusID]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	
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
	AND ([HRS-BR$Affiliate Postings].[DepartureDate] BETWEEN @dateFrom AND @dateTo)
	AND ([HRS-BR$Affiliate Postings].[ReservationSource] BETWEEN 798 AND 801) 
)
 , 
[_HRS_AP] AS (
  SELECT CASE 
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND     DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '01 BASE'
           WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr<>0 AND NOT DC.[Code] IN ('110','114','122','123','125','131','140','15','156','160','169','198','199','200','201','223','234','235','25','32','33','42','43','49','50','62','65','91','98') THEN '02 BASE'
		   WHEN Turnover_LCY_corr<>0 AND Amount_LCY_corr=0 THEN '03 NON-COMM'
		   WHEN Turnover_LCY_corr=0 THEN '04 CANCELLATION'
         END [TAB]
       , InvoiceNo
       , ReservationNo
	   , ReservationPartNo
       , ProcessNumber
       , Turnover_LCY
       , Amount_LCY
       , CommissionType
       , CommissionRateProz	   
       , Turnover_LCY_corr
       , Amount_LCY_corr
       , AffiliatePartnerNo	   
       , ArivalDate
       , DepartureDate
       , ReservationDate
       , [ReservationSource]
       , [HRS$Booking Source].[Name] [ReservationSourceName]
       , I.[String]
       , [HotelNo]
	   , Interface
	   , [Description]
	   , [TopBonusID]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	
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
	AND ([HRS$Affiliate Postings].[DepartureDate] BETWEEN @dateFrom AND @dateTo)
	AND ([HRS$Affiliate Postings].[ReservationSource] BETWEEN 798 AND 801) 
), OnlineCancellations AS
(
  SELECT '04 CANCELLATION' TAB
       , '' InvoiceNo
       , BT.B_KEY ReservationNo
	   , BT.BT_POS ReservationPartNo
       , BU.BP_KEY ProcessNumber
       , 0.0 Turnover_LCY
       , 0.0 Amount_LCY
       , NULL CommissionType
       , NULL CommissionRateProz	   
       , 0.0 Turnover_LCY_corr
       , 0.0 Amount_LCY_corr
       , BU.K_KEY AffiliatePartnerNo	   
       , BU.B_AN_DATUM ArivalDate
       , BU.B_AB_DATUM DepartureDate
       , BU.B_DATUM ReservationDate
       , BU.B_QUELLE [ReservationSource]
       , BS.[Name] [ReservationSourceName]
       , I.[String]
       , BU.H_KEY [HotelNo]
	   , Interface
	   , BU.[B_GAST1]+' ' + BU.B_GAST2 [Description]
	   , '-' [TopBonusID]
	   , SC.[Name] [Source Country]
	   , DC.[Name] [Destination Country]
	   
     FROM HRSDB.BUCHUNG B1 WITH (NOLOCK)
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = B1.B_KEY_ROOT
     JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK)
       ON BT.B_KEY = BU.B_KEY
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = BU.B_QUELLE
LEFT JOIN dbo.Split('HHO-SOAP,HHOW,HHO-WIDGET,HWO,HWO_SOAP,JBook,none,SAP_SOAP,SOAP,WAP,',',') I
      ON I.[Index] = BS.Interface
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = BU.K_KEY
    JOIN [HRS$Country_Region] SC WITH (NOLOCK)
      ON SC.[Code] = AP.[Country Code]
	 AND ISNUMERIC(SC.Code)>0
    JOIN [HRS$Country_Region] DC WITH (NOLOCK)
      ON DC.[Code] = BU.L_ID
	 AND ISNUMERIC(DC.Code)>0
 WHERE BU.B_AB_DATUM BETWEEN @dateFrom AND @dateTo
   AND B1.B_CANCELLATION = 1
   AND BU.B_QUELLE BETWEEN 798 AND 801
)
SELECT * FROM [_TISCOVER_AP] UNION ALL 	 
SELECT * FROM [_HRS-CN_AP]   UNION ALL 	 
SELECT * FROM [_HRS-BR_AP]   UNION ALL 	 
SELECT * FROM [_HRS_AP]      UNION ALL 	 
SELECT * FROM OnlineCancellations
ORDER BY TAB,DepartureDate,ReservationNo,ReservationPartNo
END

GO
