USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateCancelationStatistics]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT COUNT(1) FROM [HRS$Correction Agency Line History] WITH (NOLOCK)
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.04.2020
-- Description:	Populates [HRS$Cancellation Statistics] with statistics of final bookview cancellations
--
/*
EXEC sp_UpdateCancelationStatistics '2017-01-01','2017-01-31'
EXEC sp_UpdateCancelationStatistics '2017-02-01','2017-02-28'
EXEC sp_UpdateCancelationStatistics '2017-03-01','2017-03-31'
EXEC sp_UpdateCancelationStatistics '2017-04-01','2017-04-30'
EXEC sp_UpdateCancelationStatistics '2017-05-01','2017-05-31'
EXEC sp_UpdateCancelationStatistics '2017-06-01','2017-06-30'
EXEC sp_UpdateCancelationStatistics '2017-07-01','2017-07-31'
EXEC sp_UpdateCancelationStatistics '2017-08-01','2017-08-31'
EXEC sp_UpdateCancelationStatistics '2017-09-01','2017-09-30'
EXEC sp_UpdateCancelationStatistics '2017-10-01','2017-10-31'
EXEC sp_UpdateCancelationStatistics '2017-11-01','2017-11-30'
EXEC sp_UpdateCancelationStatistics '2017-12-01','2017-12-31'
EXEC sp_UpdateCancelationStatistics '2018-01-01','2018-01-31'
EXEC sp_UpdateCancelationStatistics '2018-02-01','2018-02-28'
EXEC sp_UpdateCancelationStatistics '2018-03-01','2018-03-31'
EXEC sp_UpdateCancelationStatistics '2018-04-01','2018-04-30'
EXEC sp_UpdateCancelationStatistics '2018-05-01','2018-05-31'
EXEC sp_UpdateCancelationStatistics '2018-06-01','2018-06-30'
EXEC sp_UpdateCancelationStatistics '2018-07-01','2018-07-31'
EXEC sp_UpdateCancelationStatistics '2018-08-01','2018-08-31'
EXEC sp_UpdateCancelationStatistics '2018-09-01','2018-09-30'
EXEC sp_UpdateCancelationStatistics '2018-10-01','2018-10-31'
EXEC sp_UpdateCancelationStatistics '2018-11-01','2018-11-30'
EXEC sp_UpdateCancelationStatistics '2018-12-01','2018-12-31'
EXEC sp_UpdateCancelationStatistics '2019-01-01','2019-01-31'
EXEC sp_UpdateCancelationStatistics '2019-02-01','2019-02-28'
EXEC sp_UpdateCancelationStatistics '2019-03-01','2019-03-31'
EXEC sp_UpdateCancelationStatistics '2019-04-01','2019-04-30'
EXEC sp_UpdateCancelationStatistics '2019-05-01','2019-05-31'
EXEC sp_UpdateCancelationStatistics '2019-06-01','2019-06-30'
EXEC sp_UpdateCancelationStatistics '2019-07-01','2019-07-31'
EXEC sp_UpdateCancelationStatistics '2019-08-01','2019-08-31'
EXEC sp_UpdateCancelationStatistics '2019-09-01','2019-09-30'
EXEC sp_UpdateCancelationStatistics '2019-10-01','2019-10-31'
EXEC sp_UpdateCancelationStatistics '2019-11-01','2019-11-30'
EXEC sp_UpdateCancelationStatistics '2019-12-01','2019-12-31'
EXEC sp_UpdateCancelationStatistics '2020-01-01','2020-01-31'
EXEC sp_UpdateCancelationStatistics '2020-02-01','2020-02-28'
EXEC sp_UpdateCancelationStatistics '2020-03-01','2020-03-31'
*/
-- =============================================
CREATE PROC [dbo].[sp_UpdateCancelationStatistics](
        @DateFrom DATE = '2020-03-01'
      , @DateTo DATE = '2020-03-31'
) AS BEGIN

IF @DateFrom>= '2019-01-01'
BEGIN
DELETE FROM [HRS$Cancellation Statistics] WHERE [Assigned Posting Date] BETWEEN @DateFrom AND @DateTo AND Done = 0

EXEC [sp_UpdateCancelationStatistics_Commission_HRS] @DateFrom, @DateTo
EXEC [sp_UpdateCancelationStatistics_Commission_HRS-CN] @DateFrom, @DateTo
EXEC [sp_UpdateCancelationStatistics_Commission_HRS-BR] @DateFrom, @DateTo
;WITH C AS
(
  SELECT CAST([Hotel No_] AS int) [Hotel No_]
       , COUNT(1) [Canceled Bookings]
       , SUM([Total Rate incl_] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Canceled Hotel Turnover (LCY)]
       , SUM([Inquiry Sent]) [Inquiry Sent]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
	   , SUM(CASE WHEN [Quality by User] = 'ITELYA' THEN 1 ELSE 0 END) [Itelya Invoices]
    FROM [HRS$Correction Agency Header] WITH (NOLOCK)
   WHERE [Final Cancellation] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT C.[Hotel No_]
        , C.[Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , ROUND(CASE WHEN COALESCE(B.[Invoiced Bookings], 0)=0 THEN 100. ELSE (C.[Canceled Bookings]*100.0/(C.[Canceled Bookings]+COALESCE(B.[Invoiced Bookings], 0))) END,2) [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , C.[Canceled Hotel Turnover (LCY)]
        , C.[Inquiry Sent]
        , C.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
		, COALESCE(C.[Itelya Invoices],0)
     FROM C LEFT JOIN B ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]
LEFT JOIN [HRS$Cancellation Statistics] OC WITH (NOLOCK)
       ON OC.[Hotel No_] = C.[Hotel No_]
      AND OC.[Assigned Posting Date] = C.[Assigned Posting Date]
    WHERE OC.[Hotel No_] IS NULL
 ORDER BY C.[Hotel No_]

DELETE FROM [HRS-CN$Cancellation Statistics] WHERE [Assigned Posting Date] BETWEEN @DateFrom AND @DateTo AND Done = 0
;WITH C AS
(
  SELECT CAST([Hotel No_] AS int) [Hotel No_]
       , COUNT(1) [Canceled Bookings]
       , SUM([Total Rate incl_] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Canceled Hotel Turnover (LCY)]
       , SUM([Inquiry Sent]) [Inquiry Sent]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
	   , SUM(CASE WHEN [Quality by User] = 'ITELYA' THEN 1 ELSE 0 END) [Itelya Invoices]
    FROM [HRS-CN$Correction Agency Header] WITH (NOLOCK)
   WHERE [Final Cancellation] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) 
--ORDER BY CAST([Hotel No_] AS int) 
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-CN$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS-CN$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT C.[Hotel No_]
        , C.[Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , ROUND(CASE WHEN COALESCE(B.[Invoiced Bookings], 0)=0 THEN 100. ELSE (C.[Canceled Bookings]*100.0/(C.[Canceled Bookings]+COALESCE(B.[Invoiced Bookings], 0))) END,2) [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , C.[Canceled Hotel Turnover (LCY)]
        , C.[Inquiry Sent]
        , C.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
		, COALESCE(C.[Itelya Invoices],0)
     FROM C LEFT JOIN B ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]
LEFT JOIN [HRS-CN$Cancellation Statistics] OC WITH (NOLOCK)
       ON OC.[Hotel No_] = C.[Hotel No_]
      AND OC.[Assigned Posting Date] = C.[Assigned Posting Date]
 ORDER BY C.[Hotel No_]

DELETE FROM [HRS-BR$Cancellation Statistics] WHERE [Assigned Posting Date] BETWEEN @DateFrom AND @DateTo AND Done = 0
;WITH C AS
(
  SELECT CAST([Hotel No_] AS int) [Hotel No_]
       , COUNT(1) [Canceled Bookings]
       , SUM([Total Rate incl_] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Canceled Hotel Turnover (LCY)]
       , SUM([Inquiry Sent]) [Inquiry Sent]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
	   , SUM(CASE WHEN [Quality by User] = 'ITELYA' THEN 1 ELSE 0 END) [Itelya Invoices]
    FROM [HRS-BR$Correction Agency Header] WITH (NOLOCK)
   WHERE [Final Cancellation] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) 
--ORDER BY CAST([Hotel No_] AS int) 
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-CN$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS-BR$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT C.[Hotel No_]
        , C.[Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , ROUND(CASE WHEN COALESCE(B.[Invoiced Bookings], 0)=0 THEN 100. ELSE (C.[Canceled Bookings]*100.0/(C.[Canceled Bookings]+COALESCE(B.[Invoiced Bookings], 0))) END,2) [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , C.[Canceled Hotel Turnover (LCY)]
        , C.[Inquiry Sent]
        , C.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
		, COALESCE(C.[Itelya Invoices],0)
     FROM C LEFT JOIN B ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]
LEFT JOIN [HRS-BR$Cancellation Statistics] OC WITH (NOLOCK)
       ON OC.[Hotel No_] = C.[Hotel No_]
      AND OC.[Assigned Posting Date] = C.[Assigned Posting Date]
 ORDER BY C.[Hotel No_]
END

IF @DateFrom< '2019-01-01'
BEGIN
DELETE FROM [HRS$Cancellation Statistics] WHERE [Assigned Posting Date] BETWEEN @DateFrom AND @DateTo AND Done = 0
;WITH C AS
(
  SELECT CAST([Hotel No_] AS int) [Hotel No_]
       , COUNT(1) [Canceled Bookings]
       , SUM([Total Rate incl_] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Canceled Hotel Turnover (LCY)]
       , SUM([Inquiry Sent]) [Inquiry Sent]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
	   , SUM(CASE WHEN [Quality by User] = 'ITELYA' THEN 1 ELSE 0 END) [Itelya Invoices]
    FROM [HRS$Correction Agency Header History] WITH (NOLOCK)
   WHERE [Final Cancellation] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT C.[Hotel No_]
        , C.[Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , ROUND(CASE WHEN COALESCE(B.[Invoiced Bookings], 0)=0 THEN 100. ELSE (C.[Canceled Bookings]*100.0/(C.[Canceled Bookings]+COALESCE(B.[Invoiced Bookings], 0))) END,2) [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , C.[Canceled Hotel Turnover (LCY)]
        , C.[Inquiry Sent]
        , C.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
		, COALESCE(C.[Itelya Invoices],0)
     FROM C LEFT JOIN B ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]
LEFT JOIN [HRS$Cancellation Statistics] OC WITH (NOLOCK)
       ON OC.[Hotel No_] = C.[Hotel No_]
      AND OC.[Assigned Posting Date] = C.[Assigned Posting Date]
    WHERE OC.[Hotel No_] IS NULL
 ORDER BY C.[Hotel No_]

DELETE FROM [HRS-CN$Cancellation Statistics] WHERE [Assigned Posting Date] BETWEEN @DateFrom AND @DateTo AND Done = 0
;WITH C AS
(
  SELECT CAST([Hotel No_] AS int) [Hotel No_]
       , COUNT(1) [Canceled Bookings]
       , SUM([Total Rate incl_] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Canceled Hotel Turnover (LCY)]
       , SUM([Inquiry Sent]) [Inquiry Sent]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
	   , SUM(CASE WHEN [Quality by User] = 'ITELYA' THEN 1 ELSE 0 END) [Itelya Invoices]
    FROM [HRS-CN$Correction Agency Header History] WITH (NOLOCK)
   WHERE [Final Cancellation] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) 
--ORDER BY CAST([Hotel No_] AS int) 
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-CN$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS-CN$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT C.[Hotel No_]
        , C.[Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , ROUND(CASE WHEN COALESCE(B.[Invoiced Bookings], 0)=0 THEN 100. ELSE (C.[Canceled Bookings]*100.0/(C.[Canceled Bookings]+COALESCE(B.[Invoiced Bookings], 0))) END,2) [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , C.[Canceled Hotel Turnover (LCY)]
        , C.[Inquiry Sent]
        , C.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
		, COALESCE(C.[Itelya Invoices],0)
     FROM C LEFT JOIN B ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]
LEFT JOIN [HRS-CN$Cancellation Statistics] OC WITH (NOLOCK)
       ON OC.[Hotel No_] = C.[Hotel No_]
      AND OC.[Assigned Posting Date] = C.[Assigned Posting Date]
 ORDER BY C.[Hotel No_]

DELETE FROM [HRS-BR$Cancellation Statistics] WHERE [Assigned Posting Date] BETWEEN @DateFrom AND @DateTo AND Done = 0
;WITH C AS
(
  SELECT CAST([Hotel No_] AS int) [Hotel No_]
       , COUNT(1) [Canceled Bookings]
       , SUM([Total Rate incl_] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Canceled Hotel Turnover (LCY)]
       , SUM([Inquiry Sent]) [Inquiry Sent]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
	   , SUM(CASE WHEN [Quality by User] = 'ITELYA' THEN 1 ELSE 0 END) [Itelya Invoices]
    FROM [HRS-BR$Correction Agency Header History] WITH (NOLOCK)
   WHERE [Final Cancellation] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) 
--ORDER BY CAST([Hotel No_] AS int) 
), B AS
(
  SELECT DL.[Hotel No_]
       , COUNT(1) [Invoiced Bookings]
       , SUM(DL.[Foreign Tax Base Amount] * DL.[Number of Nights] * DL.[Room Number] / CASE WHEN [Currency Factor]=0 THEN 1 ELSE [Currency Factor] END) [Invoiced Hotel Turnover (LCY)]
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date]))) [Assigned Posting Date]
    FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
    JOIN [HRS-CN$Agency Display Header]DH WITH (NOLOCK)
      ON DH.[Case No_] = DL.[Display Case No_]
   WHERE DH.[Correction from] = ''
     AND DL.[Position No_] = 1
     AND [Departure Date] BETWEEN @DateFrom AND @DateTo
GROUP BY [Hotel No_] 
       , DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd, -DATEPART(dd,[Departure Date])+1, [Departure Date])))
)
   INSERT INTO [HRS-BR$Cancellation Statistics] ([Hotel No_], [Canceled Bookings], [Invoiced Bookings], [Cancellation Rate %], [Invoiced Hotel Turnover (LCY)], [Canceled Hotel Turnover (LCY)], [Inquiry Sent], [Assigned Posting Date], [Done], [Done by], [Done at], [Reduced Bookings], [Reduction Rate %],[Roomnights],[Reduced Roomnights],[Roomnights Reduction Rate %],[Bookings with RN Reduction],[Breakfast Reduction Rate %],[Bookings with BF Reduction],[Itelya Invoices])
   SELECT C.[Hotel No_]
        , C.[Canceled Bookings]
        , COALESCE(B.[Invoiced Bookings], 0) [Invoiced Bookings]
        , ROUND(CASE WHEN COALESCE(B.[Invoiced Bookings], 0)=0 THEN 100. ELSE (C.[Canceled Bookings]*100.0/(C.[Canceled Bookings]+COALESCE(B.[Invoiced Bookings], 0))) END,2) [Cancellation Rate %]
        , COALESCE(B.[Invoiced Hotel Turnover (LCY)],0.0)
        , C.[Canceled Hotel Turnover (LCY)]
        , C.[Inquiry Sent]
        , C.[Assigned Posting Date]
        , 0 [Done]
        , '' [Done by]
        , '1753-01-01' [Done at]
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
        , 0
		, COALESCE(C.[Itelya Invoices],0)
     FROM C LEFT JOIN B ON C.[Hotel No_] = B.[Hotel No_] AND C.[Assigned Posting Date] = B.[Assigned Posting Date]
LEFT JOIN [HRS-BR$Cancellation Statistics] OC WITH (NOLOCK)
       ON OC.[Hotel No_] = C.[Hotel No_]
      AND OC.[Assigned Posting Date] = C.[Assigned Posting Date]
 ORDER BY C.[Hotel No_]
END

EXEC [dbo].[sp_UpdateCancelationStatistics_BF_HRS] @DateFrom, @DateTo
EXEC [dbo].[sp_UpdateCancelationStatistics_BF_HRS-CN] @DateFrom, @DateTo
EXEC [dbo].[sp_UpdateCancelationStatistics_BF_HRS-BR] @DateFrom, @DateTo
END
GO
