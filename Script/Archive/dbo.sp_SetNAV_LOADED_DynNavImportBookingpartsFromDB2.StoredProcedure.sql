USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_SetNAV_LOADED_DynNavImportBookingpartsFromDB2]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SetNAV_LOADED_DynNavImportBookingpartsFromDB2] AS BEGIN
DECLARE @DateFrom datetime, @DateTo datetime, @HotelNo int

IF DATEPART(dd,GETDATE()) > 5
  BEGIN
   SELECT @DateFrom = CAST(LEFT(CONVERT(VARCHAR,DATEADD(MM,-2,DATEADD(dd,-DATEPART(dd,GETDATE())+1,GETDATE())),120),10) AS DATETIME)
        , @DateTo = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,DATEADD(MM,1,DATEADD(dd,-DATEPART(dd,GETDATE())+1,GETDATE()))),120),10) AS DATETIME)
        , @HotelNo = NULL
  END
ELSE
  BEGIN
   SELECT @DateFrom = CAST(LEFT(CONVERT(VARCHAR,DATEADD(MM,-3,DATEADD(dd,-DATEPART(dd,GETDATE())+1,GETDATE())),120),10) AS DATETIME)
        , @DateTo = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,DATEADD(dd,-DATEPART(dd,GETDATE())+1,GETDATE())),120),10) AS DATETIME)
        , @HotelNo = NULL
  END

  PRINT @DateFrom;
  PRINT @DateTo;

;WITH _NAV AS
(      
SELECT AL.[Reservation No_], AL.[Position No_], '[HRS-CN$Agency Line]' Source, AL.[Reservation Status]
  FROM [HRS-CN$Agency Line] AL WITH (NOLOCK)
  JOIN [HRS-CN$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = AL.[Reservation No_]
 WHERE (AH.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND AH.[Departure Date] BETWEEN @DateFrom AND @DateTo
UNION ALL   
SELECT AL.[Reservation No_], AL.[Position No_], '[HRS-CN$Agency Line]' Source, AL.[Reservation Status]
  FROM [HRS-CN$Agency Display Line] AL WITH (NOLOCK)
 WHERE (AL.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND AL.[Departure Date] BETWEEN @DateFrom AND @DateTo
UNION ALL   
SELECT CL.[Reservation No_], CL.[Position No_], '[HRS-CN$Correction Agency Line]' Source, 10000 
  FROM [HRS-CN$Correction Agency Line] CL WITH (NOLOCK)
  JOIN [HRS-CN$Correction Agency Header] CH WITH (NOLOCK)
    ON CH.[Reservation No_] = CL.[Reservation No_]
 WHERE (CH.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND CH.[Departure Date] BETWEEN @DateFrom AND @DateTo   
UNION ALL   
SELECT AL.[Reservation No_], AL.[Position No_], '[HRS-BR$Agency Line]' Source, AL.[Reservation Status]
  FROM [HRS-BR$Agency Line] AL WITH (NOLOCK)
  JOIN [HRS-BR$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = AL.[Reservation No_]
 WHERE (AH.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND AH.[Departure Date] BETWEEN @DateFrom AND @DateTo
UNION ALL   
SELECT AL.[Reservation No_], AL.[Position No_], '[HRS-BR$Agency Line]' Source, AL.[Reservation Status]
  FROM [HRS-BR$Agency Display Line] AL WITH (NOLOCK)
 WHERE (AL.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND AL.[Departure Date] BETWEEN @DateFrom AND @DateTo
UNION ALL   
SELECT CL.[Reservation No_], CL.[Position No_], '[HRS-BR$Correction Agency Line]' Source, 10000 
  FROM [HRS-BR$Correction Agency Line] CL WITH (NOLOCK)
  JOIN [HRS-BR$Correction Agency Header] CH WITH (NOLOCK)
    ON CH.[Reservation No_] = CL.[Reservation No_]
 WHERE (CH.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND CH.[Departure Date] BETWEEN @DateFrom AND @DateTo   
UNION ALL   
SELECT AL.[Reservation No_], AL.[Position No_], '[HRS$Agency Line]' Source, AL.[Reservation Status]
  FROM [HRS$Agency Line] AL WITH (NOLOCK)
  JOIN [HRS$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = AL.[Reservation No_]
 WHERE (AH.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND AH.[Departure Date] BETWEEN @DateFrom AND @DateTo
UNION ALL   
SELECT AL.[Reservation No_], AL.[Position No_], '[HRS$Agency Line]' Source, AL.[Reservation Status]
  FROM [HRS$Agency Display Line] AL WITH (NOLOCK)
 WHERE (AL.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND AL.[Departure Date] BETWEEN @DateFrom AND @DateTo
UNION ALL   
SELECT CL.[Reservation No_], CL.[Position No_], '[HRS$Correction Agency Line]' Source, 10000
  FROM [HRS$Correction Agency Line] CL WITH (NOLOCK)
  JOIN [HRS$Correction Agency Header] CH WITH (NOLOCK)
    ON CH.[Reservation No_] = CL.[Reservation No_]
 WHERE (CH.[Hotel No_] = @HotelNo OR @HotelNo IS NULL)
   AND CH.[Departure Date] BETWEEN @DateFrom AND @DateTo      
     
), Compare AS
(
   SELECT S.B_KEY,BT_POS
        , CASE WHEN COALESCE(B.B_STATUS,10000) = 10000 THEN 
            10000 
          ELSE 
            S.B_STATUS 
          END B_STATUS
        , (CASE 
             WHEN N.[Reservation No_] IS NULL 
                  OR COALESCE(N.[Reservation Status],10000) <> S.B_STATUS THEN 1 ELSE 0 END) [Different]
        , N.* 
     FROM HRSDB.BUCHTEIL S
LEFT JOIN HRSDB.BUCHUNG B
       ON B.B_KEY = S.B_KEY
     JOIN HRSDB.HOTEL    H
       ON S.H_KEY = H.H_KEY
LEFT JOIN _NAV N
       ON N.[Reservation No_] = S.B_KEY
      AND N.[Position No_] = S.BT_POS     
    WHERE (H.H_KEY = @HotelNo OR @HotelNo IS NULL)
      AND S.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
      AND H.H_TEST_HOTEL = 0
)
   UPDATE S SET S.NAV_LOADED = (CASE WHEN N.[Reservation No_] IS NULL OR COALESCE(N.[Reservation Status],10000) <> C.B_STATUS THEN 0 ELSE 1 END)
     FROM HRSDB.BUCHTEIL S
     JOIN Compare C
       ON C.B_KEY = S.B_KEY
      AND C.BT_POS = S.BT_POS
     JOIN HRSDB.HOTEL    H
       ON S.H_KEY = H.H_KEY
LEFT JOIN _NAV N
       ON N.[Reservation No_] = S.B_KEY
      AND N.[Position No_] = S.BT_POS     
    WHERE (H.H_KEY = @HotelNo OR @HotelNo IS NULL)
      AND B_AB_DATUM BETWEEN @DateFrom AND @DateTo
      AND H.H_TEST_HOTEL = 0
      AND S.NAV_LOADED <> (CASE WHEN N.[Reservation No_] IS NULL OR COALESCE(N.[Reservation Status],10000) <> C.B_STATUS THEN 0 ELSE 1 END)
END
GO
