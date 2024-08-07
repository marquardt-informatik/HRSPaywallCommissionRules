USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_HDE]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 16.10.2014
-- Description:	Liefert die Basis der HDE Bonuspunkte-Abrechnung
/*
  EXECUTE [RS].[PROC_HDE] '2014-12-30', '2014-12-31', '2014-01-01'
*/
-- =============================================
CREATE PROCEDURE [RS].[PROC_HDE] 
    @DateFrom datetime, @DateTo datetime, @FirstOfYear datetime
AS 
BEGIN
WITH BP AS (
  SELECT BP_KEY, MAX(CASE WHEN MA_USER = 'HDE-SBI' OR B_QUELLE IN (843,7)  THEN 'HDE-SBI' ELSE '' END) MA_USER, COUNT(1) [CountBU] 
    FROM HRSDB.BUCHUNG GROUP BY BP_KEY
), _BU AS (
  SELECT B_KEY
       , BT_POS
       , CASE WHEN BT_VON = BT_BIS THEN 1 ELSE DATEDIFF(dd,BT_VON,BT_BIS) END [Number of Nights]
       , BT_ANZAHL                                                            [Number of Rooms]
       , CAST(BT_PREIS AS DECIMAL(37,20)) / 100.                                                      [Room Price]
       , CASE WHEN BT_VON = BT_BIS THEN 1 ELSE DATEDIFF(dd,BT_VON,BT_BIS) END * CAST(BT_PREIS AS DECIMAL(37,20)) / 100.
       * CASE WHEN BT_RATE_TYP = 20025 THEN 1 ELSE BT_ANZAHL END
       + CASE WHEN BT_FRSTCK = 0 THEN 0 ELSE CASE WHEN BT_VON = BT_BIS THEN 1 ELSE DATEDIFF(dd,BT_VON,BT_BIS) END * CAST(BT_FRST_PREIS AS DECIMAL(37,20)) * BT_PAX_COUNT * 1. / 100. END [GrossTurnover]
    FROM HRSDB.BUCHTEIL WITH (NOLOCK) 
), BU AS (
     SELECT 'MONTH' AREA,AP.InvoiceNo, AP.ReservationNo, AP.ReservationPartNo, AP.Turnover_LCY, AP.Amount_LCY, AP.CommissionType_corr, AP.CommissionRateProz_corr, AP.Turnover_LCY_corr, AP.Amount_LCY_corr, AP.AffiliatePartnerNo, AP.DepartureDate, AP.ReservationSource, BS.[Name], AP.[ProcessNumber], AP.[Amount_corr], AP.[Turnover_corr], AP.[CurrencyCode], AP.[CurrencyFaktor], AP.[CurrencyCode_corr], AP.[CurrencyFaktor_corr], AP.[Turnover_Breakfast_LCY], AP.[Turnover_Breakfast_LCY_corr], CASE WHEN COALESCE(MA_USER,'') = 'HDE-SBI' THEN 1 ELSE 0 END [oneX], [GrossTurnover], [GrossTurnover]/CASE WHEN [CurrencyFaktor]=0 THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2) [GrossTurnover_corr], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2)/CASE WHEN[CurrencyFaktor]=0THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY_corr]
       FROM [HRS-CN$Affiliate Postings] AP WITH (READUNCOMMITTED) 
       JOIN _BU BU ON BU.B_KEY = AP.ReservationNo AND BU.BT_POS = AP.ReservationPartNo
  LEFT JOIN BP 
         ON BP.BP_KEY = AP.[ProcessNumber] 
       JOIN [HRS$Booking Source] BS WITH (NOLOCK) 
         ON BS.[No_] = AP.[ReservationSource] 
      WHERE [DepartureDate] BETWEEN @DateFrom AND @DateTo AND (AP.ReservationSource IN (383,843,7) OR AP.AffiliatePartnerNo IN (1016845087,1032506001,6013)) AND NOT AP.ReservationSource IN (0,2,3,8,16) 

UNION ALL 

     SELECT 'MONTH' AREA,AP.InvoiceNo, AP.ReservationNo, AP.ReservationPartNo, AP.Turnover_LCY, AP.Amount_LCY, AP.CommissionType_corr, AP.CommissionRateProz_corr, AP.Turnover_LCY_corr, AP.Amount_LCY_corr, AP.AffiliatePartnerNo, AP.DepartureDate, AP.ReservationSource, BS.[Name], AP.[ProcessNumber], AP.[Amount_corr], AP.[Turnover_corr], AP.[CurrencyCode], AP.[CurrencyFaktor], AP.[CurrencyCode_corr], AP.[CurrencyFaktor_corr], AP.[Turnover_Breakfast_LCY], AP.[Turnover_Breakfast_LCY_corr], CASE WHEN COALESCE(MA_USER,'') = 'HDE-SBI' THEN 1 ELSE 0 END [1x], [GrossTurnover], [GrossTurnover]/CASE WHEN [CurrencyFaktor]=0 THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2) [GrossTurnover_corr], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2)/CASE WHEN[CurrencyFaktor]=0THEN 1 ELSE [CurrencyFaktor] END
       FROM [HRS-BR$Affiliate Postings] AP WITH (READUNCOMMITTED) 
       JOIN _BU BU ON BU.B_KEY = AP.ReservationNo AND BU.BT_POS = AP.ReservationPartNo
  LEFT JOIN BP 
         ON BP.BP_KEY = AP.[ProcessNumber] 
       JOIN [HRS$Booking Source] BS WITH (NOLOCK) 
         ON BS.[No_] = AP.[ReservationSource] 
      WHERE [DepartureDate] BETWEEN @DateFrom AND @DateTo AND (AP.ReservationSource IN (383) OR AP.AffiliatePartnerNo IN (1016845087,1032506001,6013)) AND NOT AP.ReservationSource IN (0,2,3,8,16) 
      
UNION ALL 

     SELECT 'MONTH' AREA,AP.InvoiceNo, AP.ReservationNo, AP.ReservationPartNo, AP.Turnover_LCY, AP.Amount_LCY, AP.CommissionType_corr, AP.CommissionRateProz_corr, AP.Turnover_LCY_corr, AP.Amount_LCY_corr, AP.AffiliatePartnerNo, AP.DepartureDate, AP.ReservationSource, BS.[Name], AP.[ProcessNumber], AP.[Amount_corr], AP.[Turnover_corr], AP.[CurrencyCode], AP.[CurrencyFaktor], AP.[CurrencyCode_corr], AP.[CurrencyFaktor_corr], AP.[Turnover_Breakfast_LCY], AP.[Turnover_Breakfast_LCY_corr], CASE WHEN COALESCE(MA_USER,'') = 'HDE-SBI' THEN 1 ELSE 0 END [1x], [GrossTurnover], [GrossTurnover]/CASE WHEN [CurrencyFaktor]=0 THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2) [GrossTurnover_corr], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2)/CASE WHEN[CurrencyFaktor]=0THEN 1 ELSE [CurrencyFaktor] END
       FROM [HRS$Affiliate Postings] AP WITH (READUNCOMMITTED) 
       JOIN _BU BU ON BU.B_KEY = AP.ReservationNo AND BU.BT_POS = AP.ReservationPartNo
  LEFT JOIN BP 
         ON BP.BP_KEY = AP.[ProcessNumber] 
       JOIN [HRS$Booking Source] BS WITH (NOLOCK) 
         ON BS.[No_] = AP.[ReservationSource] 
      WHERE [DepartureDate] BETWEEN @DateFrom AND @DateTo AND (AP.ReservationSource IN (383,843,7) OR AP.AffiliatePartnerNo IN (1016845087,1032506001,6013)) AND NOT AP.ReservationSource IN (0,2,3,8,16) 
      
UNION ALL 

     SELECT 'YEAR_'+RIGHT('00'+CAST(MONTH(AP.DepartureDate) AS varchar(2)),2) AREA,AP.InvoiceNo, AP.ReservationNo, AP.ReservationPartNo, AP.Turnover_LCY, AP.Amount_LCY, AP.CommissionType_corr, AP.CommissionRateProz_corr, AP.Turnover_LCY_corr, AP.Amount_LCY_corr, AP.AffiliatePartnerNo, AP.DepartureDate, AP.ReservationSource, BS.[Name], AP.[ProcessNumber], AP.[Amount_corr], AP.[Turnover_corr], AP.[CurrencyCode], AP.[CurrencyFaktor], AP.[CurrencyCode_corr], AP.[CurrencyFaktor_corr], AP.[Turnover_Breakfast_LCY], AP.[Turnover_Breakfast_LCY_corr], CASE WHEN COALESCE(MA_USER,'') = 'HDE-SBI' THEN 1 ELSE 0 END [1x], [GrossTurnover], [GrossTurnover]/CASE WHEN [CurrencyFaktor]=0 THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2) [GrossTurnover_corr], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2)/CASE WHEN[CurrencyFaktor]=0THEN 1 ELSE [CurrencyFaktor] END
       FROM [HRS-CN$Affiliate Postings] AP WITH (READUNCOMMITTED) 
       JOIN _BU BU ON BU.B_KEY = AP.ReservationNo AND BU.BT_POS = AP.ReservationPartNo
  LEFT JOIN BP 
         ON BP.BP_KEY = AP.[ProcessNumber] 
       JOIN [HRS$Booking Source] BS WITH (NOLOCK) 
         ON BS.[No_] = AP.[ReservationSource] 
      WHERE [DepartureDate] BETWEEN @FirstOfYear AND @DateTo AND (AP.ReservationSource IN (383,843,7) OR AP.AffiliatePartnerNo IN (1016845087,1032506001,6013)) AND NOT AP.ReservationSource IN (0,2,3,8,16) 
      
UNION ALL 

     SELECT 'YEAR_'+RIGHT('00'+CAST(MONTH(AP.DepartureDate) AS varchar(2)),2) AREA,AP.InvoiceNo, AP.ReservationNo, AP.ReservationPartNo, AP.Turnover_LCY, AP.Amount_LCY, AP.CommissionType_corr, AP.CommissionRateProz_corr, AP.Turnover_LCY_corr, AP.Amount_LCY_corr, AP.AffiliatePartnerNo, AP.DepartureDate, AP.ReservationSource, BS.[Name], AP.[ProcessNumber], AP.[Amount_corr], AP.[Turnover_corr], AP.[CurrencyCode], AP.[CurrencyFaktor], AP.[CurrencyCode_corr], AP.[CurrencyFaktor_corr], AP.[Turnover_Breakfast_LCY], AP.[Turnover_Breakfast_LCY_corr], CASE WHEN COALESCE(MA_USER,'') = 'HDE-SBI' THEN 1 ELSE 0 END [1x], [GrossTurnover], [GrossTurnover]/CASE WHEN [CurrencyFaktor]=0 THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2) [GrossTurnover_corr], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2)/CASE WHEN[CurrencyFaktor]=0THEN 1 ELSE [CurrencyFaktor] END
       FROM [HRS-BR$Affiliate Postings] AP WITH (READUNCOMMITTED) 
       JOIN _BU BU ON BU.B_KEY = AP.ReservationNo AND BU.BT_POS = AP.ReservationPartNo
  LEFT JOIN BP 
         ON BP.BP_KEY = AP.[ProcessNumber] 
       JOIN [HRS$Booking Source] BS WITH (NOLOCK) 
         ON BS.[No_] = AP.[ReservationSource] 
      WHERE [DepartureDate] BETWEEN @FirstOfYear AND @DateTo AND (AP.ReservationSource IN (383,843,7) OR AP.AffiliatePartnerNo IN (1016845087,1032506001,6013)) AND NOT AP.ReservationSource IN (0,2,3,8,16) 
      
UNION ALL 
     SELECT 'YEAR_'+RIGHT('00'+CAST(MONTH(AP.DepartureDate) AS varchar(2)),2) AREA,AP.InvoiceNo, AP.ReservationNo, AP.ReservationPartNo, AP.Turnover_LCY, AP.Amount_LCY, AP.CommissionType_corr, AP.CommissionRateProz_corr, AP.Turnover_LCY_corr, AP.Amount_LCY_corr, AP.AffiliatePartnerNo, AP.DepartureDate, AP.ReservationSource, BS.[Name], AP.[ProcessNumber], AP.[Amount_corr], AP.[Turnover_corr], AP.[CurrencyCode], AP.[CurrencyFaktor], AP.[CurrencyCode_corr], AP.[CurrencyFaktor_corr], AP.[Turnover_Breakfast_LCY], AP.[Turnover_Breakfast_LCY_corr], CASE WHEN COALESCE(MA_USER,'') = 'HDE-SBI' THEN 1 ELSE 0 END [1x], [GrossTurnover], [GrossTurnover]/CASE WHEN [CurrencyFaktor]=0 THEN 1 ELSE [CurrencyFaktor] END [GrossTurnover_LCY], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2) [GrossTurnover_corr], ROUND(CASE WHEN [Turnover]=0 THEN 0 ELSE [GrossTurnover]/[Turnover]*[Turnover_corr] END,2)/CASE WHEN[CurrencyFaktor]=0THEN 1 ELSE [CurrencyFaktor] END
       FROM [HRS$Affiliate Postings] AP WITH (READUNCOMMITTED) 
       JOIN _BU BU ON BU.B_KEY = AP.ReservationNo AND BU.BT_POS = AP.ReservationPartNo
  LEFT JOIN BP 
         ON BP.BP_KEY = AP.[ProcessNumber] 
       JOIN [HRS$Booking Source] BS WITH (NOLOCK) 
         ON BS.[No_] = AP.[ReservationSource] 
      WHERE [DepartureDate] BETWEEN @FirstOfYear AND @DateTo AND (AP.ReservationSource IN (383,843,7) OR AP.AffiliatePartnerNo IN (1016845087,1032506001,6013)) AND NOT AP.ReservationSource IN (0,2,3,8,16)
)
     SELECT * 
       FROM BU ORDER BY AREA,ReservationNo
END
GO
