USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[sp_HRS$Accor TAF]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

Hotel Reservation Services Robert Ragge GmbH
------------------------------------------------------------

Datum     Version  RFC    Sign Beschreibung
------------------------------------------------------------
28.05.20  HRS001          TM   created

EXEC [AFFILIATE].[sp_HRS$Accor TAF]
*/
CREATE PROCEDURE [AFFILIATE].[sp_HRS$Accor TAF]
AS
BEGIN
SET QUOTED_IDENTIFIER ON
DECLARE @RecreateTI int = 0
      , @CountTI int = -1
	  , @RecreateAP int = 0
	  , @CountAP int = -1

IF @RecreateTI=1
  IF OBJECT_ID('tempdb..#TI') IS NOT NULL
    DROP TABLE #TI

IF OBJECT_ID('tempdb..#TI') IS NOT NULL
  SELECT @CountTI=COUNT(1) FROM #TI

IF @CountTI=0
  DROP TABLE #TI

IF OBJECT_ID('tempdb..#TI') IS NULL
BEGIN
  CREATE TABLE #TI ([Process No_] int primary key, [Amount] decimal(38,20), [Currency Code] varchar(10), [Currency Factor] decimal(38,20), [Amount (LCY)] decimal(38,20))
  ;WITH 
   _TI AS (SELECT [Process No_], MAX([TAF Invoice No_]) [TAF Invoice No_] FROM [HRS$TAF Invoice Line] WITH (NOLOCK) GROUP BY [Process No_])
  , TI AS (SELECT TI.[Process No_], TI.[Amount], TI.[Currency Code], TI.[Currency Factor], TI.[Amount (LCY)] FROM [HRS$TAF Invoice Line] TI WITH (NOLOCK) JOIN _TI ON _TI.[Process No_] = TI.[Process No_] AND _TI.[TAF Invoice No_] = TI.[TAF Invoice No_])
  INSERT INTO #TI
  SELECT * FROM TI
END

IF @RecreateAP=1
  IF OBJECT_ID('tempdb..#AP') IS NOT NULL
    DROP TABLE #AP

IF OBJECT_ID('tempdb..#AP') IS NOT NULL
  SELECT @CountAP=COUNT(1) FROM #AP

IF @CountAP=0
  DROP TABLE #AP

IF OBJECT_ID('tempdb..#AP') IS NULL
BEGIN
  CREATE TABLE #AP ([ReservationNo] int,[ReservationPartNo] int, [InvoiceNo] varchar(20) COLLATE Latin1_General_CS_AS, [Process No_] int, [TAF Amount (LCY)] decimal(38,20), [TAF Amount (LCY) (corr_)] decimal(38,20), [Amount_LCY] decimal(38,20), [Amount_LCY_corr] decimal(38,20), [Agency Amount (LCY)] decimal(38,20), [Agency Amount (LCY) (corr_)] decimal(38,20),CONSTRAINT [PK_#AP] PRIMARY KEY CLUSTERED([ReservationNo] ASC,[ReservationPartNo] ASC, [InvoiceNo] ASC))
  INSERT INTO #AP
  SELECT AP.[ReservationNo]
       , AP.[ReservationPartNo]
	   , AP.[InvoiceNo]
       , TI.[Process No_]
	   , AP.[TAF Amount (LCY)]
	   , AP.[TAF Amount (LCY) (corr_)]
	   , AP.[Amount_LCY]
	   , AP.[Amount_LCY_corr]
	   , AP.[Agency Amount (LCY)]
	   , AP.[Agency Amount (LCY) (corr_)]
    FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
    JOIN #TI TI
      ON AP.ProcessNumber = TI.[Process No_]
END

;WITH SL AS
(
  SELECT [Process No_]
       , [ReservationNo]
	   , [ReservationPartNo]
	   , [InvoiceNo]
	   , DENSE_RANK() OVER(PARTITION BY [Process No_] ORDER BY [ReservationNo], [ReservationPartNo], [InvoiceNo]) [Rank]
    FROM #AP AP
)
  UPDATE AP SET
         AP.[TAF Amount (LCY)] = CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
       , AP.[TAF Amount (LCY) (corr_)] = CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
	   , AP.Amount_LCY = AP.[Agency Amount (LCY)] + CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
	   , AP.Amount_LCY_corr = AP.[Agency Amount (LCY)] + CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
    FROM SL
	JOIN #AP AP
	  ON AP.ReservationNo = SL.ReservationNo
     AND AP.ReservationPartNo = SL.ReservationPartNo
     AND AP.InvoiceNo = SL.InvoiceNo
    JOIN #TI TI
      ON TI.[Process No_]=AP.[Process No_]
   WHERE SL.[Rank]=1
     AND (AP.[TAF Amount (LCY)] <> CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
     OR AP.[TAF Amount (LCY) (corr_)] <> CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
     OR AP.Amount_LCY <> AP.[Agency Amount (LCY)] + CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END
     OR AP.Amount_LCY_corr <> AP.[Agency Amount (LCY)] + CASE WHEN SL.[Rank]=1 THEN TI.[Amount (LCY)] ELSE 0 END)

  UPDATE AP SET 
         AP.[TAF Amount (LCY)] = SL.[TAF Amount (LCY)]
       , AP.[TAF Amount (LCY) (corr_)] = SL.[TAF Amount (LCY)]
	   , AP.Amount_LCY = AP.[Agency Amount (LCY)] + SL.[TAF Amount (LCY)]
	   , AP.Amount_LCY_corr = AP.[Agency Amount (LCY)] + SL.[TAF Amount (LCY)]
    FROM [HRS$Affiliate Postings] AP
	JOIN #AP SL
	  ON AP.ReservationNo = SL.ReservationNo
     AND AP.ReservationPartNo = SL.ReservationPartNo
     AND AP.InvoiceNo = SL.InvoiceNo
   WHERE AP.[TAF Amount (LCY)] <> SL.[TAF Amount (LCY)]
     OR AP.[TAF Amount (LCY) (corr_)] <> SL.[TAF Amount (LCY)]
     OR AP.Amount_LCY <> AP.[Agency Amount (LCY)] + SL.[TAF Amount (LCY)]
     OR AP.Amount_LCY_corr <> AP.[Agency Amount (LCY)] + SL.[TAF Amount (LCY)]
END
GO
