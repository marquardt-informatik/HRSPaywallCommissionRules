USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateCancelationStatistics_Commission_HRS]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_UpdateCancelationStatistics_Commission_HRS] 
    @DateFrom date
  , @DateTo date
AS
BEGIN
;WITH B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN DL.[Currency Faktor]=0 THEN 1 ELSE DL.[Currency Faktor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
	 AND DH.[Case No_] LIKE 'V%'
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT B.[Hotel No_]
        , 0 [Canceled Bookings]
        , B.[Invoiced Bookings]
        , 0 [Cancellation Rate %]
        , B.[Invoiced Hotel Turnover (LCY)]
        , 0 [Canceled Hotel Turnover (LCY)]
        , 0 [Inquiry Sent]
        , B.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0 [Reduced Bookings]
        , 0 [Reduction Rate %]
        , 0 [Roomnights]
        , 0 [Reduced Roomnights]
        , 0 [Roomnights Reduction Rate %]
        , 0 [Bookings with RN Reduction]
        , 0 [Breakfast Reduction Rate %]
        , 0 [Bookings with BF Reduction]
		, 0 [Itelya Invoices]
     FROM B 
LEFT JOIN [HRS$Cancellation Statistics] CS WITH (NOLOCK)
       ON B.[Hotel No_] = CS.[Hotel No_] AND B.[Assigned Posting Date] = CS.[Assigned Posting Date]
    WHERE CS.[Hotel No_] IS NULL
END
GO
