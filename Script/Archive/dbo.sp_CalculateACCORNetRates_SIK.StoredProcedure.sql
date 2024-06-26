USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_CalculateACCORNetRates_SIK]    Script Date: 10.04.2024 14:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC [dbo].[sp_CalculateACCORNetRates]
GO
UPDATE AL SET 
       AL.[Net Room Price] = COALESCE(BT.BT_NETTO_PREIS,0)  / 100.
  FROM [HRS$Agency Line] AL 
  JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK)
    ON BT.B_KEY = AL.[Reservation No_]
   AND BT.BT_POS = AL.[Position No_]
  JOIN [HRS$Agency Header] AH WITH (NOLOCK) ON AL.[Reservation No_] = AH.[Reservation No_]
 WHERE AH.[Reservation Date] >= '2014-07-01' 
   AND DL.[Net Room Price] <> COALESCE(BT.BT_NETTO_PREIS,0)  / 100.
   --AND B_KEY = 107905740 
GO
 UPDATE AL SET AL.[Net Room Price] =0
   FROM [HRS$Agency Line] AL 
   JOIN [HRS$Agency Header]AH WITH (NOLOCK) ON AL.[Reservation No_] = AH.[Reservation No_]
  WHERE (AH.[Reservation Date] < '2014-07-01' OR AH.[Departure Date] < '2014-07-01')
    AND AL.[Net Room Price] <> 0   
*/
CREATE PROCEDURE [dbo].[sp_CalculateACCORNetRates_SIK]
AS
BEGIN

;WITH BU AS
(
SELECT B_KEY
     , CASE WHEN B_TOTAL_RATE_INCLUSIVE = B_TOTAL_RATE AND FT.[Use VAT]=1 AND FT.[Use Breakfast Tax]=1 AND CU.[Chain] IN ('204') THEN [VAT in %]      ELSE CASE WHEN ROUND((B_TOTAL_RATE_INCLUSIVE - B_TOTAL_RATE)*100.0 / B_TOTAL_RATE,0) = (B_TOTAL_RATE_INCLUSIVE - B_TOTAL_RATE)*100.0 / B_TOTAL_RATE THEN (B_TOTAL_RATE_INCLUSIVE - B_TOTAL_RATE)*100.0 / B_TOTAL_RATE ELSE 0 END END [Tax %]
     , CASE WHEN B_TOTAL_RATE_INCLUSIVE = B_TOTAL_RATE AND FT.[Use VAT]=1 AND FT.[Use Breakfast Tax]=1 AND CU.[Chain] IN ('204') THEN 0               ELSE CASE WHEN ROUND((B_TOTAL_RATE_INCLUSIVE - B_TOTAL_RATE)*100.0 / B_TOTAL_RATE,0) = (B_TOTAL_RATE_INCLUSIVE - B_TOTAL_RATE)*100.0 / B_TOTAL_RATE THEN 0                                                            ELSE B_TOTAL_RATE_INCLUSIVE - B_TOTAL_RATE END END [Tax Amount]
     , CASE WHEN B_TOTAL_RATE_INCLUSIVE = B_TOTAL_RATE AND FT.[Use VAT]=1 AND FT.[Use Breakfast Tax]=1 AND CU.[Chain] IN ('204') THEN [Breakfast Tax] ELSE 0 END [Breakfast Tax %]
     , W_KURS
	 , B_TOTAL_RATE_INCLUSIVE 
	 , B_TOTAL_RATE    
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
  JOIN [HRS$Contact] CU WITH (NOLOCK)
    ON CU.[No_] = BU.H_KEY
  JOIN [HRS$Foreign Tax] FT WITH (NOLOCK)
    ON FT.[Country] = CU.[Country_Region Code]
 WHERE CU.[Chain] IN ('550','204')
   AND BU.KE_BID  IN ('550','204')
   AND BU.B_AB_DATUM >= '2014-10-01'
   AND BU.B_DATUM >= '2014-01-01'
   AND B_TOTAL_RATE <> 0
--   AND BU.CTS BETWEEN '2014-12-01' AND '2014-12-02' -- Test
), RN AS
(
  SELECT BU.B_KEY 
       , SUM(
         BT_ANZAHL
       * CASE WHEN DATEDIFF(dd,BT.BT_VON,BT.BT_BIS)=0 THEN 1 ELSE DATEDIFF(dd,BT.BT_VON,BT.BT_BIS) END
         ) BT_ROOMNIGHTS
    FROM BU
    JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK) ON BU.B_KEY = BT.B_KEY
   WHERE BT.B_STATUS <> 19998
GROUP BY BU.B_KEY   
), BT AS
(
  SELECT BU.* 
       , BT.BT_POS
       , BT_ANZAHL
       * CASE WHEN DATEDIFF(dd,BT.BT_VON,BT.BT_BIS)=0 THEN 1 ELSE DATEDIFF(dd,BT.BT_VON,BT.BT_BIS) END
         BT_ROOMNIGHTS
       , BT_FRST_PREIS
       , BT_PREIS
       , BT_FRSTCK
    FROM BU
    JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK) ON BU.B_KEY = BT.B_KEY
   WHERE BT.B_STATUS <> 19998
)
  UPDATE T SET 
         T.BT_NETTO_PREIS  
       = ROUND(
         CASE 
           WHEN [Tax %] > 0      THEN BT.BT_PREIS * 1.0 / (100 + [Tax %]) * 100. 
           WHEN [Tax Amount] > 0 THEN BT.BT_PREIS - [Tax Amount] / RN.BT_ROOMNIGHTS 
           ELSE BT.BT_PREIS
         END
       , 0)
       , T.BT_NETTO_FRST_PREIS
       = ROUND(
         CASE
           WHEN [Breakfast Tax %] > 0 THEN BT.BT_FRST_PREIS * 1.0 / (100 + [Breakfast Tax %]) * 100.
           ELSE BT.BT_FRST_PREIS
         END
       , 0)
    FROM BT
    JOIN HRSDB.BUCHTEIL T ON T.B_KEY = BT.B_KEY AND T.BT_POS = BT.BT_POS
    JOIN RN ON RN.B_KEY = BT.B_KEY
   WHERE COALESCE(T.BT_NETTO_PREIS,0)
      <> ROUND(
         CASE 
           WHEN [Tax %] > 0      THEN BT.BT_PREIS * 1.0 / (100 + [Tax %]) * 100. 
           WHEN [Tax Amount] > 0 THEN BT.BT_PREIS - [Tax Amount] / RN.BT_ROOMNIGHTS 
           ELSE BT.BT_PREIS
         END
       , 0)
      OR COALESCE(T.BT_NETTO_FRST_PREIS,0)
      <> ROUND(
         CASE
           WHEN [Breakfast Tax %] > 0 THEN BT.BT_FRST_PREIS * 1.0 / (100 + [Breakfast Tax %]) * 100.
           ELSE BT.BT_FRST_PREIS
         END
       , 0)
OPTION (MAXDOP 1)
         
UPDATE AL SET 
       AL.[Net Room Price] = COALESCE(BT.BT_NETTO_PREIS,0)  / 100.
     , AL.[Net Breakfast Price] = COALESCE(BT.BT_NETTO_FRST_PREIS,0)  / 100.
  FROM [HRS$Agency Line] AL 
  JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK)
    ON BT.B_KEY = AL.[Reservation No_]
   AND BT.BT_POS = AL.[Position No_]
  JOIN [HRS$Agency Header] AH WITH (NOLOCK) ON AL.[Reservation No_] = AH.[Reservation No_]
 WHERE (AL.[Net Room Price] <> COALESCE(BT.BT_NETTO_PREIS,0)  / 100.
    OR AL.[Net Breakfast Price] <> COALESCE(BT.BT_NETTO_FRST_PREIS,0)  / 100.)
OPTION (MAXDOP 1)

END

--SELECT * FROM HRSDB.BUCHTEIL WITH (NOLOCK) WHERE B_KEY = 117590931 
GO
