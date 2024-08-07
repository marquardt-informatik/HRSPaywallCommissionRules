USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[SalesTrend_HRS]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC AFFILIATE.[SalesTrend_HRS]
-- Laufzeit : < 3 Stunden
*/
CREATE PROC [AFFILIATE].[SalesTrend_HRS]
AS
BEGIN
DECLARE @KEY varchar(20), @i int, @List varchar(max)='', @Now date = GETDATE()

  DECLARE cur CURSOR FOR
   SELECT CAST(GL.[Entry No_] AS VARCHAR(20))[Entry No_]
     FROM [HRS$G_L Entry] GL WITH (NOLOCK)
LEFT JOIN [HRS$Sales Trend New$VSIFT$2] ST WITH (NOLOCK)
       ON GL.[Entry No_] = ST.[Entry No_]
    WHERE GL.[Posting Date]>= '2020-01-01'
   AND GL.[G_L Account No_] IN ('800000','800008','800018','800020')
   AND GL.[Document Type] IN (0,2,3)
   AND ABS(ROUND(GL.[Amount],2)+ROUND(COALESCE(ST.[SUM$Amount (LCY)],0),2))>0.01
 ORDER BY 1 DESC

OPEN cur

SET @i=1
FETCH NEXT FROM cur INTO @KEY
WHILE @@FETCH_STATUS=0
BEGIN
  IF LEN(@List) > 7900 
  BEGIN
    EXEC [sp_AddSalesTrend_HRS] @List
    SET @List = '' 
 SET @i=1
  END
  IF @i>1
    SET @List = @List + ',' 
  SET @List = @List + @KEY 
  FETCH NEXT from cur INTO @KEY
  SET @i=@i+1
END
IF @List<>''
BEGIN
  EXEC [sp_AddSalesTrend_HRS] @List
END

CLOSE cur
DEALLOCATE cur


--DECLARE @Count int = 100

--WHILE @Count>0
--BEGIN

--;WITH ST AS
--(
--  SELECT ST.[Reservation No_]
--       , ST.[Position No_]
--    , SUM(ST.[Amount (LCY)]) [Amount (LCY)]
--    , SUM(ST.[Turnover (LCY)]) [Turnover (LCY)]
--    FROM [HRS$Sales Trend New] ST WITH (NOLOCK)
--GROUP BY ST.[Reservation No_]
--       , ST.[Position No_]
--)
--  UPDATE TOP (100000) AP SET
--         AP.Amount_LCY_corr   = ST.[Amount (LCY)]
--       , AP.Turnover_LCY_corr = ST.[Turnover (LCY)]
--    , AP.Amount_corr       = ST.[Amount (LCY)]   * AP.CurrencyFaktor_corr
--    , AP.Turnover_corr     = ST.[Turnover (LCY)] * AP.CurrencyFaktor_corr
--    FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
-- JOIN ST
--      ON ST.[Reservation No_] = AP.ReservationNo
--     AND ST.[Position No_]    = AP.ReservationPartNo
--   WHERE ROUND(AP.Amount_LCY_corr,2) <> ROUND(ST.[Amount (LCY)],2)
--      OR ROUND(AP.Turnover_LCY_corr,2) <> ROUND(ST.[Turnover (LCY)],2)
--  SET @Count = @@ROWCOUNT
--  PRINT @Count
--END
END
GO
