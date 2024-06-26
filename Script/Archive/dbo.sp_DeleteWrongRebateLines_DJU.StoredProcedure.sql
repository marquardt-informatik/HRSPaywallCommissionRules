USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_DeleteWrongRebateLines_DJU]    Script Date: 10.04.2024 14:31:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 15.04.19
-- Description:	Löschen von Kontoauszugszeilen, bei denen die Vertragszugehörigkeit nicht mehr stimmt
-- Duration:    5 Minuten
--
-- Version | Date     | Developer | Ticket   | Description      
-- --------+----------+-----------+----------+-----------------------------------------------------------------------------------------------------   
--         |          |           |          | 
/*
DECLARE @VendorNo varchar(20) = '12081'
EXEC [sp_DeleteWrongRebateLines_DJU] @VendorNo
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_DeleteWrongRebateLines_DJU]
  @VendorNo varchar(20) = ''
AS
BEGIN
DECLARE @ReCreateRL tinyint = 1
      , @ReCreateRLSUM tinyint = 1
	  , @ReCreateAP tinyint = 1
      , @ReCreateAPSUM tinyint = 1
      , @ReCreateRH tinyint = 1

BEGIN -- #RH
  IF @ReCreateRH=1
    IF OBJECT_ID('tempdb..#RH') IS NOT NULL
      DROP TABLE #RH

  IF OBJECT_ID('tempdb..#RH') IS NULL
  BEGIN
    CREATE TABLE #RH ([Rebate Agreement No_] varchar(20) COLLATE Latin1_General_CS_AS, [Rebate-to Vendor No_] varchar(20) COLLATE Latin1_General_CS_AS, [Year] int, [Interval] int, [Active] tinyint, [Last Posted Document Date] date, [Last Posted Rebate No_] varchar(20) COLLATE Latin1_General_CS_AS, [Actual Document Date] date, [Actual Rebate No_] varchar(20) COLLATE Latin1_General_CS_AS, CONSTRAINT PK_RHTEMP PRIMARY KEY  ([Rebate Agreement No_],[Year]))
    SET @ReCreateRH=1
  END

  IF @ReCreateRH=1
    WITH RH AS
	(
	  SELECT RH.[Rebate Agreement No_]
	       , RH.[Rebate-to Vendor No_]
		   , YEAR(RH.[Document Date]) [Rebate Year]
		   , AH.[Interval]
		   , '1753-01-01' [Last Posted Document Date]
		   , '' [Last Posted Document No_]
		   , RH.[Document Date] [Actual Document Date]
		   , RH.[No_] [Actual Rebate No_]
		   , AH.[Active]
	    FROM [HRS$Rebate Header] RH WITH (NOLOCK)
		JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
		  ON AH.[No_] = RH.[Rebate Agreement No_]
       WHERE (@VendorNo = RH.[Rebate-to Vendor No_] OR @VendorNo IS NULL)
       UNION
	  SELECT RH.[Rebate Agreement No_]
	       , RH.[Rebate-to Vendor No_]
		   , YEAR(RH.[Document Date]) [Rebate Year]
		   , AH.[Interval]
		   , RH.[Document Date] [Last Posted Document Date]
		   , RH.[No_] [Last Posted Document No_]
		   , '1753-01-01' [Actual Document Date]
		   , '' [Actual Rebate No_]
		   , AH.[Active]
	    FROM [HRS$Posted Rebate Header] RH WITH (NOLOCK)
		JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
		  ON AH.[No_] = RH.[Rebate Agreement No_]
       WHERE RH.[Cancels] = 0
         AND (@VendorNo = RH.[Rebate-to Vendor No_] OR @VendorNo IS NULL)
	), RHM AS
	(
	  SELECT [Rebate Agreement No_]
	       , [Rebate-to Vendor No_]
		   , [Rebate Year]
		   , [Interval]
		   , MAX([Active]) [Active]
		   , MAX([Last Posted Document Date]) [Last Posted Document Date]
		   , MAX([Actual Document Date]) [Actual Document Date]
	    FROM RH
    GROUP BY [Rebate Agreement No_]
	       , [Rebate-to Vendor No_]
		   , [Rebate Year]
		   , [Interval]
	)
	  INSERT INTO #RH
      SELECT RHM.[Rebate Agreement No_]
	       , RHM.[Rebate-to Vendor No_]
		   , RHM.[Rebate Year]
		   , RHM.[Interval]
		   , RHM.[Active]
		   , COALESCE(RHP.[Last Posted Document Date],'1753-01-01') [Last Posted Document Date]
		   , MAX(COALESCE(RHP.[Last Posted Document No_],'')) [Last Posted Document No_]
		   , COALESCE(RHU.[Actual Document Date],'1753-01-01') [Actual Document Date]
		   , MAX(COALESCE(RHU.[Actual Rebate No_],'')) [Actual Rebate No_]
        FROM RHM
   LEFT JOIN RH RHU
          ON RHU.[Rebate Agreement No_]      = RHM.[Rebate Agreement No_]
         AND RHU.[Rebate-to Vendor No_]      = RHM.[Rebate-to Vendor No_]
         AND RHU.[Rebate Year]               = RHM.[Rebate Year]
         AND RHU.[Interval]                  = RHM.[Interval]
		 AND RHU.[Actual Document Date]      = RHM.[Actual Document Date]
		 AND RHU.[Actual Document Date] <> '1753-01-01'
   LEFT JOIN RH RHP
          ON RHP.[Rebate Agreement No_]      = RHM.[Rebate Agreement No_]
         AND RHP.[Rebate-to Vendor No_]      = RHM.[Rebate-to Vendor No_]
         AND RHP.[Rebate Year]               = RHM.[Rebate Year]
         AND RHP.[Interval]                  = RHM.[Interval]
		 AND RHP.[Last Posted Document Date] = RHM.[Last Posted Document Date]
		 AND RHP.[Last Posted Document Date] <> '1753-01-01'
       WHERE RHM.[Rebate Agreement No_] NOT IN ('V0000000105')
	     --AND RHM.[Rebate Agreement No_] = 'V0000002593'
    GROUP BY RHM.[Rebate Agreement No_]
	       , RHM.[Rebate-to Vendor No_]
		   , RHM.[Rebate Year]
		   , RHM.[Interval]
		   , RHM.[Active]
		   , COALESCE(RHP.[Last Posted Document Date],'1753-01-01') 
		   , COALESCE(RHU.[Actual Document Date],'1753-01-01')
END -- #RH

BEGIN -- #RL
  IF @ReCreateRL=1
    IF OBJECT_ID('tempdb..#RL') IS NOT NULL
      DROP TABLE #RL

  IF OBJECT_ID('tempdb..#RL') IS NULL
  BEGIN
    CREATE TABLE #RL ([Reservation No_] int, [Reservation Part No_] int, [Rebate-to Vendor No_] int, [Affiliate Partner No_] int, [Travelagency No_] int, [Turnover (LCY) (corr_)] decimal(37,20), [Posted] tinyint, [Document No_] varchar(20) COLLATE Latin1_General_CS_AS)
    SET @ReCreateRL=1
  END

  IF @ReCreateRL=1
  BEGIN
  WITH RL AS
  (
    SELECT RL.[Reservation No_]
         , RL.[Reservation Part No_]
	     , RL.[Rebate-to Vendor No_]
	     , RL.[Affiliate Partner No_]
	     , RL.[Travelagency No_]
	     , RL.[Turnover (LCY) (corr_)]
	     , 0 [Posted]
		 , RL.[Document No_]
      FROM [HRS$Rebate Line] RL WITH (NOLOCK)
     WHERE RL.[Departure Date] >= '2018-01-01'
       AND (@VendorNo = RL.[Rebate-to Vendor No_] OR @VendorNo IS NULL)
  UNION
    SELECT RL.[Reservation No_]
         , RL.[Reservation Part No_]
	     , MAX(RL.[Rebate-to Vendor No_])[Rebate-to Vendor No_]
	     , MAX(RL.[Affiliate Partner No_])[Affiliate Partner No_]
	     , MAX(RL.[Travelagency No_])[Travelagency No_]
	     , SUM(RL.[Turnover (LCY) (corr_)])[Turnover (LCY) (corr_)]
	     , 1 [Posted]
		 , MAX(RL.[Document No_]) [Document No_]
      FROM [HRS$Posted Rebate Line] RL WITH (NOLOCK)
     WHERE RL.[Departure Date] >= '2018-01-01'
       AND (@VendorNo = RL.[Rebate-to Vendor No_] OR @VendorNo IS NULL)
  GROUP BY RL.[Reservation No_]
         , RL.[Reservation Part No_]
    HAVING SUM(RL.[Turnover (LCY) (corr_)])<>0
  )
  INSERT INTO #RL
  SELECT * FROM RL
  END
END -- #RL

BEGIN -- #RLSUM
IF @ReCreateRLSUM=1
  IF OBJECT_ID('tempdb..#RLSUM') IS NOT NULL
    DROP TABLE #RLSUM

IF OBJECT_ID('tempdb..#RLSUM') IS NULL
BEGIN
  CREATE TABLE #RLSUM ([Reservation No_] int, [Reservation Part No_] int, [Turnover (LCY) (corr_)] decimal(37,20), CONSTRAINT PK_RLSUMTEMP PRIMARY KEY ([Reservation No_], [Reservation Part No_]))
  SET @ReCreateRLSUM=1
END

IF @ReCreateRLSUM=1
BEGIN
  WITH RL_SUM AS
  (
    SELECT RL.[Reservation No_]
         , RL.[Reservation Part No_]
	     , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
      FROM #RL RL
  GROUP BY RL.[Reservation No_]
         , RL.[Reservation Part No_]
    HAVING SUM(RL.[Turnover (LCY) (corr_)])<>0
  )
  INSERT INTO #RLSUM
  SELECT * FROM RL_SUM
END
END --#RLSUM

BEGIN -- #AP
IF @ReCreateAP=1
  IF OBJECT_ID('tempdb..#AP') IS NOT NULL
    DROP TABLE #AP

IF OBJECT_ID('tempdb..#AP') IS NULL
BEGIN
  CREATE TABLE #AP ([Reservation No_] int, [Reservation Part No_] int, [Rebate-to Vendor No_] int, [Affiliate Partner No_] int, [Travelagency No_] int, [Turnover (LCY) (corr_)] decimal(37,20), [Reservation Source] int)
  SET @ReCreateAP=1
END

IF @ReCreateAP=1
BEGIN
  WITH AP AS
  (
     SELECT AP.[ReservationNo] [Reservation No_]
          , AP.[ReservationPartNo] [Reservation Part No_]
		  , COALESCE(APV.[Vendor No_], APT.[Vendor No_]) [Rebate-to Vendor No_]
	      , AP.[AffiliatePartnerNo] [Affiliate Partner No_]
  	      , AP.[Travelagency No_]
		  , AP.[Turnover_LCY_corr] [Turnover (LCY) (corr_)]
		  , AP.[ReservationSource]
       FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
  LEFT JOIN [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK)
         ON APV.[Affiliate Partner No_] = AP.[AffiliatePartnerNo]
  LEFT JOIN [HRS$Vendor Travelagency] APT WITH (NOLOCK)
         ON APT.[Travelagency No_] = AP.[Travelagency No_]
      WHERE AP.[DepartureDate] >= '2018-01-01'
        AND (@VendorNo = COALESCE(APV.[Vendor No_], APT.[Vendor No_]) OR @VendorNo IS NULL)
        --AND NOT COALESCE(APV.[Vendor No_], APT.[Vendor No_]) IS NULL
  UNION
     SELECT AP.[ReservationNo] [Reservation No_]
          , AP.[ReservationPartNo] [Reservation Part No_]
		  , COALESCE(APV.[Vendor No_], APT.[Vendor No_]) [Rebate-to Vendor No_]
	      , AP.[AffiliatePartnerNo] [Affiliate Partner No_]
	      , AP.[Travelagency No_]
		  , AP.[Turnover_LCY_corr] [Turnover (LCY) (corr_)]
		  , AP.[ReservationSource]
       FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
  LEFT JOIN [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK)
         ON APV.[Affiliate Partner No_] = AP.[AffiliatePartnerNo]
  LEFT JOIN [HRS$Vendor Travelagency] APT WITH (NOLOCK)
         ON APT.[Travelagency No_] = AP.[Travelagency No_]
      WHERE AP.[DepartureDate] >= '2018-01-01'
        AND (@VendorNo = COALESCE(APV.[Vendor No_], APT.[Vendor No_]) OR @VendorNo IS NULL)
        --AND NOT COALESCE(APV.[Vendor No_], APT.[Vendor No_]) IS NULL
  UNION
     SELECT AP.[ReservationNo] [Reservation No_]
          , AP.[ReservationPartNo] [Reservation Part No_]
		  , COALESCE(APV.[Vendor No_], APT.[Vendor No_]) [Rebate-to Vendor No_]
	      , AP.[AffiliatePartnerNo] [Affiliate Partner No_]
	      , AP.[Travelagency No_]
		  , AP.[Turnover_LCY_corr] [Turnover (LCY) (corr_)]
		  , AP.[ReservationSource]
       FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
  LEFT JOIN [HRS$Affiliate Partner Vendor] APV WITH (NOLOCK)
         ON APV.[Affiliate Partner No_] = AP.[AffiliatePartnerNo]
  LEFT JOIN [HRS$Vendor Travelagency] APT WITH (NOLOCK)
         ON APT.[Travelagency No_] = AP.[Travelagency No_]
      WHERE AP.[DepartureDate] >= '2018-01-01'
        AND (@VendorNo = COALESCE(APV.[Vendor No_], APT.[Vendor No_]) OR @VendorNo IS NULL)
        --AND NOT COALESCE(APV.[Vendor No_], APT.[Vendor No_]) IS NULL
  )
  INSERT INTO #AP
  SELECT * FROM AP
END
END -- #AP

BEGIN -- #APSUM
IF @ReCreateAPSUM=1
  IF OBJECT_ID('tempdb..#APSUM') IS NOT NULL
    DROP TABLE #APSUM

IF OBJECT_ID('tempdb..#APSUM') IS NULL
BEGIN
  CREATE TABLE #APSUM ([Reservation No_] int, [Reservation Part No_] int, [Turnover (LCY) (corr_)] decimal(37,20), CONSTRAINT PK_APSUMTEMP PRIMARY KEY ([Reservation No_], [Reservation Part No_]))
  SET @ReCreateAPSUM=1
END

IF @ReCreateAPSUM=1
BEGIN
  WITH AP_SUM AS
  (
    SELECT RL.[Reservation No_]
         , RL.[Reservation Part No_]
	     , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
      FROM #AP RL
  GROUP BY RL.[Reservation No_]
         , RL.[Reservation Part No_]
  )
  INSERT INTO #APSUM
  SELECT * FROM AP_SUM
END
END -- #APSUM
  
;WITH RAH AS
(
  SELECT RAH.[Rebate-to Vendor No_]
       , COUNT(1) [CountRAH]
    FROM [HRS$Rebate Agreement Header] RAH WITH (NOLOCK)
   WHERE RAH.[Active] = 1
GROUP BY RAH.[Rebate-to Vendor No_]  
), _AP AS
(
  SELECT AP.[Reservation No_]
       , AP.[Reservation Part No_]
	   , AP.[Affiliate Partner No_]
	   , AP.[Travelagency No_]
	   , AP.[Rebate-to Vendor No_]
	   , AP.[Reservation Source]
    FROM #AP AP
	JOIN RAH
	  ON RAH.[Rebate-to Vendor No_] = AP.[Rebate-to Vendor No_]
), _AS AS
(
   SELECT 'Kkey-Vendor<>' [Comment]
        , RL.*
        , COALESCE(VA.[Vendor No_],'') [Vendor No_]
     FROM #RL RL
LEFT JOIN [HRS$Affiliate Partner Vendor] VA WITH (NOLOCK)
	   ON RL.[Affiliate Partner No_] = VA.[Affiliate Partner No_]
    WHERE RL.[Rebate-to Vendor No_]<>COALESCE(VA.[Vendor No_],'')
UNION
   SELECT 'TA-Vendor<>' [Comment]
        , RL.*
        , COALESCE(VA.[Vendor No_],'') [Vendor No_]
     FROM #RL RL
LEFT JOIN [HRS$Vendor Travelagency] VA WITH (NOLOCK)
	   ON RL.[Travelagency No_] = VA.[Travelagency No_]
LEFT JOIN [HRS$Affiliate Partner Vendor] AP WITH (NOLOCK)
	   ON RL.[Affiliate Partner No_] = AP.[Affiliate Partner No_]
    WHERE RL.[Rebate-to Vendor No_]<>COALESCE(VA.[Vendor No_],'')
      AND AP.[Affiliate Partner No_] IS NULL
), BS AS
(
  SELECT BS.[No_]
       , BS.[Name]
    FROM [HRS$Booking Source] BS WITH (NOLOCK)
   WHERE [Is GDS] = 1
)
   DELETE FROM RL
  -- SELECT RL.[Reservation No_]
  --      , RL.[Reservation Part No_]
  --      , RL.[Rebate-to Vendor No_] [Actual Vendor No_]
  --      , COALESCE(AP.[Rebate-to Vendor No_],0) [New Vendor No_]
  --      , RL.[Affiliate Partner No_] [Actual Affiliate Partner No_]
  --      , AP.[Affiliate Partner No_] [New Affiliate Partner No_]
  --      , RL.[Travelagency No_] [Actual Travelagency No_]
  --      , COALESCE(AP.[Travelagency No_],0) [New Travelagency No_]
  --      , AP.[Reservation Source]
     FROM [HRS$Rebate Line] RL WITH (NOLOCK)
     JOIN #RL PRL
       ON PRL.[Reservation No_] = RL.[Reservation No_]
      AND PRL.[Reservation Part No_] = RL.[Reservation Part No_]
LEFT JOIN #AP AP
       ON RL.[Reservation No_] = AP.[Reservation No_]
	  AND RL.[Reservation Part No_] = AP.[Reservation Part No_]
    WHERE COALESCE(AP.[Rebate-to Vendor No_],'')<>RL.[Rebate-to Vendor No_]
	  AND RL.[Rebate-to Vendor No_] <> '54698' -- WPS
	  AND RL.[Rebate-to Vendor No_] <> '9357' -- Sabre
	  AND (@VendorNo IS NULL OR RL.[Rebate-to Vendor No_] = @VendorNo)
END
GO
