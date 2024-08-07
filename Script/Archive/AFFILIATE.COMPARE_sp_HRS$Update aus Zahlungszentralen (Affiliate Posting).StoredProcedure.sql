USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[COMPARE_sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
EXEC [AFFILIATE].[COMPARE_sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)]
*/
CREATE PROCEDURE [AFFILIATE].[COMPARE_sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)]
AS
BEGIN


EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)', 'Init', 'Start'
;WITH ZZ AS
(
  SELECT ZZ.[Reservierungsnummer]
       , MAX(CASE WHEN ([Buch_ Description] LIKE '%/NON Commisionable Stay%' OR [Action Code] = 'NETC') THEN 1 ELSE 0 END) [PaymentNONCommisionableStay]
       , MAX(CASE WHEN ([Buch_ Description] LIKE '%/Cancellation%'           OR [Action Code] = 'CXLD') THEN 1 ELSE 0 END) [PaymentCancelation]
       , MAX(CASE WHEN ([Buch_ Description] LIKE '%/NoShow%'                 OR [Action Code] = 'NSHW') THEN 1 ELSE 0 END) [PaymentNoShow]
	   -- ACS-844: Feld wird nicht verwendet >>
       --, SUM(ZZ.NetCommissionPaymentCurrency) NetCommissionPaymentCurrency 
	   -- ACS-844 <<
    FROM [HRS$CDG Import Zahlungszentralen] ZZ WITH (NOLOCK)
   WHERE [Reservierungsnummer]<>0
GROUP BY [Reservierungsnummer]
)
UPDATE AP SET
       AP.[PaymentNONCommisionableStay] = ZZ.[PaymentNONCommisionableStay]
     , AP.[PaymentCancelation]          = ZZ.[PaymentCancelation]       
     , AP.[PaymentNoShow]               = ZZ.[PaymentNoShow]               
  FROM [COMPARE_HRS$Affiliate Postings]           AP WITH (READUNCOMMITTED)
  JOIN [HRS$CDG Import Zahlungszentralen] ZA WITH (READUNCOMMITTED)
    ON ZA.[Reservierungsnummer] = AP.[ReservationNo]
  JOIN ZZ ON ZZ.Reservierungsnummer = ZA.Reservierungsnummer
 WHERE COALESCE(AP.[PaymentNONCommisionableStay],0) <> ZZ.[PaymentNONCommisionableStay]
    OR COALESCE(AP.[PaymentCancelation],0)          <> ZZ.[PaymentCancelation]        
    OR COALESCE(AP.[PaymentNoShow],0)               <> ZZ.[PaymentNoShow]            

DECLARE @ReservationNo int, @ReservationPartNo int, @InvoiceNo varchar(20)
EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)', 'Init', 'Ende'

EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)', 'UPDATE 1', 'Start'
-- ACS-844: Cursor ersetzt >>
--DECLARE cur CURSOR FOR  
-- SELECT ReservationNo, ReservationPartNo, InvoiceNo
--   FROM DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] AP WITH (NOLOCK)   
--  WHERE AP.[Amount_LCY_corr] <> 0 
--    AND (AP.[PaymentNONCommisionableStay] =1 OR AP.[PaymentCancelation]  = 1 OR AP.[PaymentNoShow]  = 1)

--OPEN cur

--FETCH NEXT FROM cur INTO @ReservationNo, @ReservationPartNo, @InvoiceNo  

--WHILE @@FETCH_STATUS=0
--BEGIN
--  UPDATE DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] SET [Amount_LCY_corr] = 0, [Amount_corr] = 0
--   WHERE ReservationNo=@ReservationNo 
--     AND ReservationPartNo=@ReservationPartNo
--     AND InvoiceNo=@InvoiceNo
--  FETCH NEXT FROM cur INTO @ReservationNo, @ReservationPartNo, @InvoiceNo 
--END   

--CLOSE cur
--DEALLOCATE cur

DECLARE @cnt int

SELECT @cnt=COUNT(1) FROM DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] WHERE [Amount_LCY_corr] <> 0 AND ([PaymentNONCommisionableStay] =1 OR [PaymentCancelation]  = 1 OR [PaymentNoShow]  = 1)

WHILE @cnt>0
BEGIN
	PRINT @cnt

	UPDATE TOP(10000) DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] SET [Amount_LCY_corr] = 0, [Amount_corr] = 0
	 WHERE [Amount_LCY_corr] <> 0 
	   AND ([PaymentNONCommisionableStay] =1 OR [PaymentCancelation]  = 1 OR [PaymentNoShow]  = 1)

	SELECT @cnt=COUNT(1) FROM DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] WHERE [Amount_LCY_corr] <> 0 AND ([PaymentNONCommisionableStay] =1 OR [PaymentCancelation]  = 1 OR [PaymentNoShow]  = 1)
END
-- ACS-844 <<
EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)', 'UPDATE 1', 'Ende'

EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)', 'UPDATE 2', 'Start'
-- ACS-844: Cursor ersetzt >>
----DECLARE @ReservationNo int, @ReservationPartNo int, @InvoiceNo varchar(20)    
--DECLARE cur CURSOR FOR  
--SELECT ReservationNo, ReservationPartNo, InvoiceNo
--  FROM DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] AP WITH (NOLOCK)     
-- WHERE AP.[Turnover_LCY_corr] <> 0 
--   AND (AP.[PaymentCancelation]  = 1 OR AP.[PaymentNoShow]  = 1)

--OPEN cur

--FETCH NEXT FROM cur INTO @ReservationNo, @ReservationPartNo, @InvoiceNo  

--WHILE @@FETCH_STATUS=0
--BEGIN
--  UPDATE DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] SET [Turnover_LCY_corr] = 0, [Turnover_corr] = 0
--   WHERE ReservationNo=@ReservationNo 
--     AND ReservationPartNo=@ReservationPartNo
--     AND InvoiceNo=@InvoiceNo
--  FETCH NEXT FROM cur INTO @ReservationNo, @ReservationPartNo, @InvoiceNo 
--END   

--CLOSE cur
--DEALLOCATE cur


SELECT @cnt=COUNT(1) FROM DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] WHERE [Turnover_LCY_corr] <> 0 AND ([PaymentCancelation]  = 1 OR [PaymentNoShow]  = 1)

WHILE @cnt>0
BEGIN
	PRINT @cnt

	UPDATE TOP(10000) DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] SET [Turnover_LCY_corr] = 0, [Turnover_corr] = 0
	 WHERE [Turnover_LCY_corr] <> 0 
	   AND ([PaymentCancelation]  = 1 OR [PaymentNoShow]  = 1)

	SELECT @cnt=COUNT(1) FROM DynNavHRS.dbo.[COMPARE_HRS$Affiliate Postings] WHERE [Turnover_LCY_corr] <> 0 AND ([PaymentCancelation]  = 1 OR [PaymentNoShow]  = 1)
END
-- ACS-844 <<
EXEC AFFILIATE.[COMPARE_sp_Protokollierung] 'sp_HRS$Update aus Zahlungszentralen (Affiliate Posting)', 'UPDATE 2', 'Ende'
END

GO
