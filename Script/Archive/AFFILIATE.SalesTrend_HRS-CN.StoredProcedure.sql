USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[SalesTrend_HRS-CN]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC AFFILIATE.[SalesTrend_HRS-CN]
*/
CREATE PROC [AFFILIATE].[SalesTrend_HRS-CN]
AS
BEGIN
DECLARE @KEY varchar(20), @i int, @List varchar(max)='', @Now date = GETDATE()

  DECLARE cur CURSOR FOR
   SELECT CAST(GL.[Entry No_] AS VARCHAR(20))[Entry No_]
     FROM [HRS-CN$G_L Entry] GL WITH (NOLOCK)
LEFT JOIN [HRS-CN$Sales Trend New$VSIFT$2] ST WITH (NOLOCK)
       ON GL.[Entry No_] = ST.[Entry No_]
    WHERE GL.[Posting Date]>= '2020-01-01'
   AND GL.[G_L Account No_] IN ('780000')
   AND GL.[Document Type] IN (2,3)
   AND ABS(ROUND(GL.[Amount],2)+ROUND(COALESCE(ST.[SUM$Amount (LCY)],0),2))>0.01
 ORDER BY 1 DESC

OPEN cur

SET @i=1
FETCH NEXT FROM cur INTO @KEY
WHILE @@FETCH_STATUS=0
BEGIN
  IF LEN(@List) > 7900 
  BEGIN
    EXEC [sp_AddSalesTrend_HRS-CN] @List
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
  EXEC [sp_AddSalesTrend_HRS-CN] @List
END

CLOSE cur
DEALLOCATE cur
END
GO
