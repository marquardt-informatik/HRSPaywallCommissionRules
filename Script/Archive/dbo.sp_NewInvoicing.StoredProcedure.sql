USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_NewInvoicing]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_NewInvoicing]
AS
BEGIN


DECLARE @Invoices TABLE ([Hotel No_] int, [Year] int, [Month] int, [Posting Date] date, [Line Amount (LCY)] decimal(37,20), [RevShare Base Amount (LCY)] decimal(37,20), [Invoice Amount (LCY)] decimal(37,20), PRIMARY KEY ([Hotel No_], [Posting Date]))
DECLARE @Months TABLE ([Year] int, [Month] int, [Hotel No_] int, [Start of Month] date, [End of Month] date, PRIMARY KEY ([Hotel No_], [End of Month]))
DECLARE @StartDate date, @EndDate date
DECLARE @loopYear int = 13, @loopMonth int

;WITH Invoices AS
(
  SELECT DH.[Bill-to Customer No_] [Hotel No_]
       , DH.[Posting Date]
       , SUM([Line Amount (LCY)]) [Line Amount (LCY)]
       , SUM(CASE WHEN APV.[Affiliate Partner No_] IS NULL THEN 0 ELSE [Line Amount (LCY)] END) [RevShare Base Amount (LCY)]
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-CN$Agency Display Header] DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
LEFT JOIN [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK) ON DL.[Client No_] = APV.[Affiliate Partner No_]
   WHERE DH.[Case No_] LIKE 'V%'
     AND DH.[Posting Date] >= '2013-01-31'
     --AND DH.[Bill-to Customer No_] IN ('6880')
GROUP BY DH.[Bill-to Customer No_]
       , DH.[Posting Date]
  HAVING SUM([Line Amount (LCY)]) > 0
)
INSERT INTO @Invoices
  SELECT A1.[Hotel No_]
       , YEAR(A1.[Posting Date])
       , MONTH(A1.[Posting Date])
       , A1.[Posting Date]
       , SUM(A2.[Line Amount (LCY)]) [Aggregate Line Amount (LCY)]
       , A1.[RevShare Base Amount (LCY)]
       , A1.[Line Amount (LCY)] [Invoice Amount (LCY)]
    FROM Invoices A1
    JOIN Invoices A2
      ON A1.[Hotel No_] = A2.[Hotel No_]
     AND A1.[Posting Date] >= A2.[Posting Date]
GROUP BY A1.[Hotel No_]
       , YEAR(A1.[Posting Date])
       , MONTH(A1.[Posting Date])
       , A1.[Posting Date]     
       , A1.[RevShare Base Amount (LCY)]
       , A1.[Line Amount (LCY)]

DECLARE @HotelNo int
DECLARE cur CURSOR FOR
SELECT DISTINCT [Hotel No_] FROM @Invoices

OPEN cur
FETCH NEXT FROM cur INTO @HotelNo

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @loopYear = 13
  WHILE @loopYear < 15
  BEGIN
    SET @loopMonth=1
    WHILE @loopMonth < 13
    BEGIN 
      SET @StartDate = DATEADD(mm,@loopMonth-1,DATEADD(yy,@loopYear-1,'2001-01-01'))
      SET @EndDate   = DATEADD(dd,-1,DATEADD(mm,@loopMonth,DATEADD(yy,@loopYear-1,'2001-01-01')))
      IF @EndDate <= '2014-06-30'
      INSERT INTO @Months VALUES(@loopYear, @loopMonth, @HotelNo, @StartDate, @EndDate)
      SET @loopMonth = @loopMonth + 1
    END
    SET @loopYear = @loopYear + 1
  END
  FETCH NEXT FROM cur INTO @HotelNo
END

CLOSE cur
DEALLOCATE cur

DECLARE res CURSOR FOR
   SELECT M.[Hotel No_]
        , M.[Year]
        , M.[Month]
        , M.[End of Month]
        , COALESCE(I.[Line Amount (LCY)],0) [Line Amount (LCY)]
        , COALESCE(I.[RevShare Base Amount (LCY)],0) [RevShare Base Amount (LCY)]
        , COALESCE([Invoice Amount (LCY)],0) [Invoice Amount (LCY)]
     FROM @Months M
LEFT JOIN @Invoices I
       ON M.[Hotel No_]= I.[Hotel No_]
      AND M.[End of Month] = I.[Posting Date]
 ORDER BY M.[Hotel No_], M.[Year], M.[Month]    

DECLARE @Year int, @Month int, @PostingDate date, @Amount decimal(37,20), @Payment tinyint = 0, @NewInvoiceAmount decimal(37,20), @OldInvoiceAmount decimal(37,20)
DECLARE @OldHotelNo int, @OldYear int, @OldMonth int, @OldPostingDate date, @OldAmount decimal(37,20), @OldPayment tinyint, @CompareAmount decimal(37,20), @RevShareBaseAmount decimal(37,20), @InvoiceAmount decimal(37,20), @NotPayedAmount decimal(37,20)

DECLARE @Payments TABLE (
  [Hotel No_] int
, [Year] int
, [Month] int
, [Posting Date] date
, [New Invoice Amount (LCY)] decimal(37,20)
, [Compare Amount (LCY)] decimal (37,20)
, [Payment] tinyint
, [RevShare Base Amount (LCY)] decimal (37,20)
, [Old Invoice Amount (LCY)] decimal (37,20)
, PRIMARY KEY ([Hotel No_], [Posting Date]))

OPEN res
FETCH NEXT FROM res INTO @HotelNo, @Year, @Month, @PostingDate, @Amount, @RevShareBaseAmount, @InvoiceAmount

WHILE @@FETCH_STATUS = 0
BEGIN
  IF COALESCE(@HotelNo,'') <> COALESCE(@OldHotelNo,'')
  BEGIN
    SET @OldPayment = 0
    SET @CompareAmount = 0
    SET @OldAmount = 0
    SET @OldInvoiceAmount = 0
    SET @NewInvoiceAmount = 0
    SET @NotPayedAmount = 0
  END

  --IF @Amount > 0 
  --  SET @CompareAmount = @Amount

  IF @OldPayment=1 
    SET @NewInvoiceAmount = @InvoiceAmount

    
  --IF @HotelNo = @OldHotelNo AND @Amount = 0
  --  SET @OldAmount = 0
      
  --IF @OldPayment=1 OR @OldAmount=0
  --  SET @Amount = @InvoiceAmount
    
  IF ((@InvoiceAmount+@NotPayedAmount) >= 20 OR @Month IN (3,6,9,12)) AND (@InvoiceAmount+@NotPayedAmount) > 0 
  BEGIN
    SET @NewInvoiceAmount = @NotPayedAmount + @InvoiceAmount
    SET @Payment = 1
    SET @OldPayment = @Payment
    SET @NotPayedAmount = 0
  END
  ELSE
  BEGIN
    --SET @Amount = 0
    SET @Payment = 0
    SET @OldPayment = 0
    SET @NewInvoiceAmount = 0
  END
  INSERT INTO @Payments VALUES(@HotelNo, @Year, @Month, @PostingDate, @NewInvoiceAmount, @CompareAmount, @Payment, @RevShareBaseAmount, @InvoiceAmount)
  
  IF @NewInvoiceAmount = 0 
    SET @NotPayedAmount = @NotPayedAmount + @InvoiceAmount
  IF (@InvoiceAmount>0) OR COALESCE(@HotelNo,'') <> COALESCE(@OldHotelNo,'') OR @Month IN (3,6,9,12)
  BEGIN
    SET @OldYear = @Year
    SET @OldMonth = @Month
    SET @OldPostingDate = @PostingDate
    SET @OldAmount = @Amount
    SET @OldHotelNo = @HotelNo
    SET @OldInvoiceAmount = @NewInvoiceAmount
  --SET @OldPayment = @Payment
  END
  FETCH NEXT FROM res INTO @HotelNo, @Year, @Month, @PostingDate, @Amount, @RevShareBaseAmount, @InvoiceAmount
END

CLOSE res
DEALLOCATE res

  SELECT [Hotel No_]
       , [Year]
       , [Month]
       , [New Invoice Amount (LCY)]
       , [RevShare Base Amount (LCY)]
       , [Payment] [new Invoice]
       , CASE WHEN [Old Invoice Amount (LCY)]>0 THEN 1 ELSE 0 END [old Invoice] 
       , [Old Invoice Amount (LCY)]
       , [Compare Amount (LCY)]
    FROM @Payments
ORDER BY [Hotel No_]
       , [Year]
       , [Month]        

--  SELECT [Year]
--       , [Month]
--       , SUM([Payment]) [New Invoiced]
--       , SUM(CASE WHEN [Compare Amount (LCY)]<>0 THEN 1 ELSE 0 END) [Old Invoiced]
--    FROM @Payments
--GROUP BY [Year]
--       , [Month] 
--ORDER BY [Year]
--       , [Month]        
END
GO
