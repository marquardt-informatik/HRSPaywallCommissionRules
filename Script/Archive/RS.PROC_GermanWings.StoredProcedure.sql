USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_GermanWings]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 06.02.2013
-- Description:	Liefert die Basis der Germanwings Bonuspunkte-Abrechnung
/*
  EXECUTE [RS].[PROC_GermanWings]
*/
-- =============================================
CREATE PROCEDURE [RS].[PROC_GermanWings] AS BEGIN
DECLARE @DateBonusStart     DATETIME
      , @DateBonusEnd       DATETIME
      , @DateDeductionStart DATETIME
      , @DateDeductionEnd   DATETIME

 SELECT @DateBonusEnd       = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-DATEPART(dd,GETDATE()),GETDATE()),120),10) AS DATETIME)
 SELECT @DateBonusStart     = CAST(LEFT(CONVERT(VARCHAR,DATEADD(mm, -1, DATEADD(dd, 1,@DateBonusEnd))             ,120),10) AS DATETIME)
 SELECT @DateDeductionEnd   = CAST(LEFT(CONVERT(VARCHAR,DATEADD(dd,-1,@DateBonusStart)                 ,120),10) AS DATETIME)
 SELECT @DateDeductionStart = CAST(LEFT(CONVERT(VARCHAR,DATEADD(mm,-1,@DateBonusStart)               ,120),10) AS DATETIME)

SELECT DISTINCT 
       'SINGLE' [Tab]
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , 500                                                 [Points]
     , '424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003' [Filter]
  FROM [HRS$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateBonusStart AND @DateBonusEnd
UNION ALL   
SELECT DISTINCT 
       'SINGLE'
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , -500                                                 [Points]
     , '424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003' [Filter]
  FROM [HRS$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateDeductionStart AND @DateDeductionEnd
   AND AP.[Amount_LCY_corr] = 0
UNION ALL
SELECT DISTINCT 
       'ACTION'
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , 500                                                 [Points]
     , '424316768,1015517007' [Filter]
  FROM [HRS$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316768,1015517007)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateBonusStart AND @DateBonusEnd
UNION ALL   
SELECT DISTINCT 
       'ACTION'
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , -500                                                 [Points]
     , '424316768,1015517007' [Filter]
  FROM [HRS$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316768,1015517007)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateDeductionStart AND @DateDeductionEnd
   AND AP.[Amount_LCY_corr] = 0
UNION ALL
SELECT DISTINCT 
       'SINGLE' [Tab]
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , 500                                                 [Points]
     , '424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003' [Filter]
  FROM [HRS-CN$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateBonusStart AND @DateBonusEnd
UNION ALL   
SELECT DISTINCT 
       'SINGLE'
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , -500                                                 [Points]
     , '424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003' [Filter]
  FROM [HRS-CN$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316280,424316278,424316279,424316272,424316769,424316746,424316273,1015517007,424316740,424316274,424316270,424316269,424316513,424316696,424316767,424316271,424316277,424316275,424316276,416873143,416873142,416873141,416873560,424316768,424316114,7000953,403593002,403593001,403598001,7014926,7014929,7014927,7014928,7014931,7014932,7014930,1015517075,1015517031,1043853002,1043853003)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateDeductionStart AND @DateDeductionEnd
   AND AP.[Amount_LCY_corr] = 0
UNION ALL
SELECT DISTINCT 
       'ACTION'
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , 500                                                 [Points]
     , '424316768,1015517007' [Filter]
  FROM [HRS-CN$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316768,1015517007)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateBonusStart AND @DateBonusEnd
UNION ALL   
SELECT DISTINCT 
       'ACTION'
     , [AffiliateReference1]                              [FrequentFlyerID]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         SUBSTRING(
             AP.[Description]
           , 0
           , CHARINDEX(',',AP.[Description]) 
         )
       ELSE
         AP.[Description]
       END                                                 [FamilyName]
     , CASE WHEN CHARINDEX(',',AP.[Description]) > 0 THEN
         LTRIM(SUBSTRING(AP.[Description], CHARINDEX(',',AP.[Description])+1, LEN(AP.[Description])-CHARINDEX(',',AP.[Description])+1) )
       ELSE
         AP.[Description]
       END                                                 [GivenName]
     , AP.[ReservationDate]                                [ReservationDate]
     , AP.[DepartureDate]                                  [DepartureDate]
     , 'HRS Hotelbuchung'                                  [Use]
     , AP.[ReservationNo]                                  [ReservationNo]
     , ''                                                  [LeftBlank]
     , -500                                                 [Points]
     , '424316768,1015517007' [Filter]
  FROM [HRS-CN$Affiliate Postings] AP
 WHERE [AffiliatePartnerNo] IN (424316768,1015517007)
   AND [AffiliateReference1] <> ''
   AND [DepartureDate] BETWEEN @DateDeductionStart AND @DateDeductionEnd
   AND AP.[Amount_LCY_corr] = 0
END
GO
