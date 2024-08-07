USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_ModifyReservationStateByItelya]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 2020-04-02
-- Description:	Tag all reservations whith QUALITY_USER='ITELYA' and QUALITY_AT='<InvoiceDate>' if there is any Itelya-Invoice
/*
   DECLARE @dateFrom date = '2020-03-01'
         , @dateTo date   = '2020-03-31'
   EXECUTE sp_ModifyReservationStateByItelya @dateFrom, @dateTo
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_ModifyReservationStateByItelya] 
	-- Add the parameters for the stored procedure here
	@dateFrom date
  , @dateTo date
AS
BEGIN
	SET NOCOUNT ON;

-- -- HRSDB.BUCHUNG -----------------------------------------------
    UPDATE BU SET
	       BU.QUALITY_MA_USER = 'ITELYA'
         , BU.QUALITY_CTS = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND (BU.QUALITY_MA_USER = '')
	   
-- -- Agency Header -----------------------------------------------
    UPDATE AH SET
	       AH.[Quality by User] = 'ITELYA'
         , AH.[Quality at] = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
      JOIN [HRS$Agency Header] AH
        ON AH.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND AH.[Quality by User] = ''

    UPDATE AH SET
	       AH.[Quality by User] = 'ITELYA'
         , AH.[Quality at] = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
      JOIN [HRS-CN$Agency Header] AH
        ON AH.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND AH.[Quality by User] = ''

    UPDATE AH SET
	       AH.[Quality by User] = 'ITELYA'
         , AH.[Quality at] = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
      JOIN [HRS-BR$Agency Header] AH
        ON AH.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND AH.[Quality by User] = ''

-- -- Correction Agency Header ------------------------------------
    UPDATE AH SET
	       AH.[Quality by User] = 'ITELYA'
         , AH.[Quality at] = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
      JOIN [HRS$Correction Agency Header] AH
        ON AH.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND AH.[Quality by User] = ''

    UPDATE AH SET
	       AH.[Quality by User] = 'ITELYA'
         , AH.[Quality at] = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
      JOIN [HRS-CN$Correction Agency Header] AH
        ON AH.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND AH.[Quality by User] = ''

    UPDATE AH SET
	       AH.[Quality by User] = 'ITELYA'
         , AH.[Quality at] = INV.INVOICE_DATE
      FROM HRSDB.CIA_PS_INVOICE INV
	  JOIN HRSDB.BUCHUNG BU
	    ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
      JOIN [HRS-BR$Correction Agency Header] AH
        ON AH.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
     WHERE INV.INVOICE_DATE BETWEEN @dateFrom AND @dateTo
	   AND AH.[Quality by User] = ''

-- -- Agency Display Line -----------------------------------------

   DECLARE @RecreateDL int = 1

        IF @RecreateDL=1
        BEGIN
          IF OBJECT_ID('tempdb..#DL') IS NOT NULL
            DROP TABLE #DL
        END

        IF OBJECT_ID('tempdb..#DL') IS NULL
        BEGIN
          CREATE TABLE #DL ([Display Case No_] varchar(20) COLLATE Latin1_General_CS_AS not null, [Reservation No_] varchar(20) COLLATE Latin1_General_CS_AS not null, [Position No_] int, [Quality at] date, PRIMARY KEY ([Display Case No_],[Reservation No_], [Position No_])) 
          INSERT INTO #DL
          SELECT DISTINCT DL.[Display Case No_], DL.[Reservation No_], DL.[Position No_], MAX(INV.INVOICE_DATE)
            FROM [HRS$Agency Display Line] DL
            JOIN [HRS$Agency Display Header] DH
              ON DH.[Case No_] = DL.[Display Case No_]
            JOIN HRSDB.BUCHUNG BU
              ON DL.[Reservation No_] = CAST(BU.B_KEY AS varchar(20))
            JOIN HRSDB.CIA_PS_INVOICE INV
              ON BU.BP_KEY = INV.BOOKING_PROCESS_ID_VALUE
           WHERE DH.[Creation Date] BETWEEN @dateFrom AND @dateTo
             AND DL.[Quality by User] = ''
        GROUP BY DL.[Display Case No_], DL.[Reservation No_], DL.[Position No_]
        END

        DECLARE @countDL int = 0
		SELECT @countDL = COUNT(1) FROM #DL

        WHILE @countDL>0
        BEGIN
          IF OBJECT_ID('tempdb..#DLL') IS NOT NULL
            DROP TABLE #DLL
          CREATE TABLE #DLL ([Display Case No_] varchar(20) COLLATE Latin1_General_CS_AS not null, [Reservation No_] varchar(20) COLLATE Latin1_General_CS_AS not null, [Position No_] int, [Quality at] date, PRIMARY KEY ([Display Case No_],[Reservation No_], [Position No_])) 
          INSERT INTO #DLL
          SELECT TOP(100) * FROM #DL

          UPDATE DL SET DL.[Quality by User] = 'ITELYA', [Quality at] = #DLL.[Quality at] FROM [HRS$Agency Display Line] DL JOIN #DLL ON #DLL.[Display Case No_] = DL.[Display Case No_] AND #DLL.[Reservation No_] = DL.[Reservation No_] AND #DLL.[Position No_] = DL.[Position No_]
          DELETE FROM #DL FROM #DL JOIN #DLL ON #DL.[Display Case No_]=#DLL.[Display Case No_] AND #DL.[Reservation No_] = #DLL.[Reservation No_] AND #DL.[Position No_] = #DLL.[Position No_]
          SELECT @countDL = COUNT(1) FROM #DL
        END
END
GO
