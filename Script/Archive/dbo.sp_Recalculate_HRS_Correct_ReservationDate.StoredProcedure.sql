USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Recalculate_HRS_Correct_ReservationDate]    Script Date: 10.04.2024 14:31:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 19.11.2012
-- Description:	Ersetzt Reservierungsdatum mit dem der ersten Buchung in der Kette B
/*
  EXECUTE [dbo].[sp_Recalculate_HRS_Correct_ReservationDate] '2014-04-01', '2014-05-20'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_Recalculate_HRS_Correct_ReservationDate] 
    @DateFrom datetime = NULL
  , @DateTo   datetime = NULL
WITH RECOMPILE
AS
BEGIN

;WITH _History AS
(
SELECT AH.[Reservation No_]
     , AH.[Parent Reservation No_]
     , AH.[Reservation Date]
     , AH.[Reservation Time] 
     , AH.[Reservation Activator]
     , AH.[Reservation Source]
  FROM [HRS$Agency Header] AH WITH (NOLOCK)  
  JOIN [HRS$Agency Header] AP ON AP.[Reservation No_] = AH.[Parent Reservation No_] 
 WHERE AH.[Departure Date] BETWEEN @DateFrom 
 AND @DateTo 
UNION
SELECT AH.[Reservation No_]
     , AH.[Parent Reservation No_]
     , AH.[Reservation Date]
     , AH.[Reservation Time] 
     , AH.[Reservation Activator]
     , AH.[Reservation Source]
  FROM [HRS$Agency Header] AH WITH (NOLOCK) 
  JOIN [HRS$Correction Agency Header] AP ON AP.[Reservation No_] = AH.[Parent Reservation No_] 
 WHERE AH.[Departure Date] BETWEEN @DateFrom AND @DateTo 
UNION 
SELECT AH.[Reservation No_]
     , AH.[Parent Reservation No_]
     , AH.[Reservation Date]
     , AH.[Reservation Time] 
     , AH.[Reservation Activator]
     , AH.[Reservation Source]
  FROM [HRS$Correction Agency Header] AH WITH (NOLOCK) 
  JOIN [HRS$Correction Agency Header] AP WITH (NOLOCK) ON AP.[Reservation No_] = AH.[Parent Reservation No_] 
 WHERE AH.[Departure Date] BETWEEN @DateFrom AND @DateTo 
UNION 
SELECT AH.[Reservation No_]
     , AH.[Parent Reservation No_]
     , AH.[Reservation Date],AH.[Reservation Time] 
     , AH.[Reservation Activator]
     , AH.[Reservation Source]
  FROM [HRS$Correction Agency Header] AH WITH (NOLOCK) 
 WHERE [Parent Reservation No_] = '' AND AH.[Departure Date] BETWEEN @DateFrom AND @DateTo
), History AS
(
SELECT CAST([Reservation No_] AS VARCHAR(MAX)) [Path]
     , 20 Depth,[Reservation Date] [Date]
     , [Reservation Time] [Time]
     , [Reservation Date] [Date Actual]
     , [Reservation Time] [Time Actual]
     , [Reservation No_]
     , [Reservation No_] [Root Reservation No_]
     , [Parent Reservation No_] 
     , [Reservation Activator]
     , [Reservation Source]
  FROM _History WHERE [Parent Reservation No_] = '' UNION ALL 
SELECT _History.[Reservation No_]+'.'+History.[Path]
     , History.Depth - 1
     , History.[Date]
     , History.[Time]
     , [Reservation Date] [Date Actual]
     , [Reservation Time] [Time Actual]
     , _History.[Reservation No_]
     , History.[Root Reservation No_]
     , _History.[Parent Reservation No_] 
     , History.[Reservation Activator]
     , History.[Reservation Source]
  FROM _History 
  JOIN History ON History.[Reservation No_] = _History.[Parent Reservation No_] 
 WHERE _History.[Parent Reservation No_] <> '' AND History.Depth>0 
)
, Fold AS 
(
SELECT [Root Reservation No_]
     , MIN(Depth) Depth 
  FROM History 
 WHERE [Parent Reservation No_] <> '' GROUP BY [Root Reservation No_]
)
UPDATE AH SET
       AH.[Reservation Date]      = History.[Date]
     , AH.[Reservation Source]    = History.[Reservation Source]
  FROM History
  JOIN Fold ON Fold.[Root Reservation No_] = History.[Root Reservation No_] AND Fold.Depth = History.Depth
  JOIN [HRS$Agency Header] AH WITH (NOLOCK)
    ON AH.[Reservation No_] = History.[Reservation No_]
 WHERE AH.[Reservation Date]   <> History.[Date]
    OR AH.[Reservation Source] <> History.[Reservation Source]

DECLARE	
    @BP_KEY   int
  , @B_KEY    int
  , @MA_USER  varchar(8)
DECLARE @History TABLE(BP_KEY int, B_KEY int, MA_USER varchar(8), PRIMARY KEY (BP_KEY,B_KEY))

;WITH History AS
(
  SELECT H.BP_KEY   
       , H.B_KEY      
       , H.MA_USER   
    FROM HRSDB.BUCHUNG H WITH (NOLOCK)  
   WHERE H.B_AB_DATUM BETWEEN @DateFrom AND @DateTo 
     AND H.B_KEY_ALT IS NULL
)
  INSERT INTO @History
  SELECT H.BP_KEY   
       , H.B_KEY
       , H.MA_USER   
    FROM History H
    JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA P WITH (NOLOCK)
      ON P.BP_KEY = H.BP_KEY
     AND P.B_KEY  = H.B_KEY
     AND COALESCE(P.MA_USER,'') <> H.MA_USER
ORDER BY H.BP_KEY   
       , H.B_KEY  
       
DECLARE cur CURSOR FOR
 SELECT * FROM @History  
 
OPEN cur

FETCH NEXT FROM cur INTO @BP_KEY, @B_KEY, @MA_USER

WHILE @@FETCH_STATUS = 0
BEGIN
  UPDATE HRSDB.BKG_PROCESS_LIST_ALL_DA SET MA_USER = @MA_USER WHERE BP_KEY = @BP_KEY AND COALESCE(MA_USER,'') <> @MA_USER
  FETCH NEXT FROM cur INTO @BP_KEY, @B_KEY, @MA_USER
END
CLOSE cur

DEALLOCATE cur        

END

GO
