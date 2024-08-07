USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateBOOKVIEWChanges]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.04.2020
-- Description:	Updates Last Changes of BOOKVIEW
--
/*
EXEC [dbo].[sp_UpdateBOOKVIEWChanges]  '2019-01-01','2019-01-31'
*/
-- =============================================
CREATE PROC [dbo].[sp_UpdateBOOKVIEWChanges](
        @DateFrom DATE = '2020-03-01'
      , @DateTo DATE = '2020-03-31'
) AS BEGIN
----------------------------------------------------------------------------------------------
-- Start : BOOKVIEW - Änderungen ermitteln 
--         Letzte Änderung in Kette ermitteln, die keine BOOKVIEW-Änderung ist
--         Letzte BOOKVIEW-Änderung ermitteln
--         Diese beiden Buchungen merken um sie vergleichen zu können
----------------------------------------------------------------------------------------------
-- Alle Buchungen
DECLARE @_History TABLE ([Reservation No_] int, [Parent Reservation No_] int, [Changed by] varchar(30), PRIMARY KEY ([Reservation No_]))
;WITH P AS
(
  SELECT BP_KEY
       , COUNT(1) Anzahl
    FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   WHERE MA_USER = 'BOOKVIEW'
GROUP BY BP_KEY 
)
INSERT INTO @_History
SELECT BU.B_KEY
     , COALESCE(BU.B_KEY_ALT, 0)
     , BU.MA_USER
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)  
  JOIN P ON P.BP_KEY = BU.BP_KEY
 WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
--   AND B_KEY IN (92581115, 94665598, 94665603)
-- Alle Köpfe der Buchungsketten
DECLARE @History TABLE ([Root Reservation No_] int, [Last Non-BVL Reservation No_] int, [Last BVL Reservation No_] int, PRIMARY KEY ([Root Reservation No_]))
;WITH P AS
(
  SELECT BP_KEY
       , COUNT(1) Anzahl
    FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
   WHERE MA_USER = 'BOOKVIEW'
GROUP BY BP_KEY 
)
INSERT INTO @History
SELECT BU.B_KEY
     , BU.B_KEY
     , BU.B_KEY
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)  
  JOIN P ON P.BP_KEY = BU.BP_KEY
 WHERE BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
   AND COALESCE(BU.B_KEY_ALT, 0) = 0
--   AND B_KEY = 92581115
DECLARE @ChangedBy varchar(20)
      , @ParentChangedBy varchar(20)
      , @ReservationNoInt int
      , @ParentReservationNo int
      , @RootReservationNo int
DECLARE cur CURSOR FOR
SELECT [Root Reservation No_] FROM @History
OPEN cur
FETCH NEXT FROM cur INTO @RootReservationNo
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @ReservationNoInt = @RootReservationNo
  SET @ChangedBy = ''
  WHILE @ReservationNoInt <> 0
  BEGIN
    SET @ParentReservationNo = @ReservationNoInt
    SET @ReservationNoInt = 0
    SET @ParentChangedBy = @ChangedBy
    SET @ChangedBy = ''
    SELECT @ReservationNoInt = [Reservation No_] 
         , @ChangedBy = [Changed by]
      FROM @_History 
     WHERE [Parent Reservation No_] = @ParentReservationNo
       AND [Changed by] <> 'BOOKVIEW'
  END
  
  SET @ChangedBy = ''
  SET @ReservationNoInt = 0
  SELECT @ReservationNoInt = [Reservation No_] 
       , @ChangedBy = [Changed by]
    FROM @_History 
   WHERE [Parent Reservation No_] = @ParentReservationNo
  IF (@ChangedBy='BOOKVIEW') AND (@ParentChangedBy<>'BOOKVIEW')
  BEGIN
    UPDATE @History SET [Last Non-BVL Reservation No_] = @ParentReservationNo WHERE [Root Reservation No_] = @RootReservationNo
    WHILE @ReservationNoInt <> 0
    BEGIN
      SET @ParentReservationNo = @ReservationNoInt
      SET @ReservationNoInt = 0
      SET @ParentChangedBy = @ChangedBy
      SET @ChangedBy = ''
      SELECT @ReservationNoInt = [Reservation No_] 
           , @ChangedBy = [Changed by]
        FROM @_History 
       WHERE [Parent Reservation No_] = @ParentReservationNo
         AND [Changed by] = 'BOOKVIEW'
    END  
    UPDATE @History SET [Last BVL Reservation No_] = @ParentReservationNo WHERE [Root Reservation No_] = @RootReservationNo         
  END
  FETCH NEXT FROM cur INTO @RootReservationNo 
END
CLOSE cur
DEALLOCATE cur
UPDATE BU SET
       BU.B_KEY_ROOT = [Root Reservation No_]
  FROM HRSDB.BUCHUNG BU
  JOIN @History ON [Last Non-BVL Reservation No_] = B_KEY
 WHERE [Root Reservation No_] <> COALESCE(B_KEY_ROOT,0)
UPDATE BU SET
       BU.B_KEY_ROOT = [Root Reservation No_]
  FROM HRSDB.BUCHUNG BU
  JOIN @History ON [Last BVL Reservation No_] = B_KEY
 WHERE [Root Reservation No_] <> COALESCE(B_KEY_ROOT,0)
 
UPDATE BU SET
       BU.B_KEY_LAST_NBVL = [Last Non-BVL Reservation No_]
     , BU.B_KEY_LAST_BVL  = [Last BVL Reservation No_]
  FROM HRSDB.BUCHUNG BU
  JOIN @History ON [Root Reservation No_] = B_KEY
 WHERE COALESCE(B_KEY_LAST_NBVL,0) <> [Last Non-BVL Reservation No_]
    OR COALESCE(B_KEY_LAST_BVL,0)  <> [Last BVL Reservation No_]
----------------------------------------------------------------------------------------------
-- Ende : BOOKVIEW - Änderungen ermitteln 
----------------------------------------------------------------------------------------------
END
GO
