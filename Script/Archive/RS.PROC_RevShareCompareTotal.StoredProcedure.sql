USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_RevShareCompareTotal]    Script Date: 10.04.2024 14:31:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 16.07.13
-- Description:	

-- 
/*
EXEC [RS].[PROC_RevShareCompareTotal] 'TMA04','HRS',1
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_RevShareCompareTotal] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German
;WITH APV AS
(
  SELECT AH.[No_] [Rebate Agreement No_]
       , C.Name [Company Name]
       , [Affiliate Partner No_]
       , AH.[Enable retroactive correction]
       , AH.Interval
       , COUNT(1) CountAPV
    FROM [Company] C, [HRS$Rebate Agreement Header] AH WITH (NOLOCK), [HRS$Affiliate Partner Vendor] APV  WITH (NOLOCK)
   WHERE C.Name IN ('HRS','HRS-CN','TISCOVER')
     AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_]
	 AND AH.[Active] = 1
	 AND AH.[Template No_] <> 'TMC'
--     AND APV.[Vendor No_] IN('1634','1553','2628')
GROUP BY AH.[No_]
       , C.Name
       , APV.[Affiliate Partner No_]
       , AH.[Enable retroactive correction]
       , AH.Interval
), AP_PART AS
(
   SELECT L.[Rebate Agreement No_]
        , L.Interval
        , CASE L.Interval
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate)
            WHEN 1 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%3,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 2 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%6,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 3 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%12,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
          END [Period Start Date]
        , ROUND(SUM(AP.[Turnover_LCY]),2) [Turnover (LCY)]
        , ROUND(SUM(AP.Turnover_LCY_corr),2) [Turnover (LCY) (corr_)]
        , ROUND(SUM(AP.[Amount_LCY]),2) [Amount (LCY)]
        , ROUND(SUM(AP.Amount_LCY_corr),2) [Amount (LCY) (corr_)]
     FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS'
    WHERE AP.DepartureDate            >= '2013-01-01'
 GROUP BY L.[Rebate Agreement No_]
        , L.Interval
        , CASE L.Interval
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate)
            WHEN 1 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%3,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 2 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%6,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 3 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%12,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
          END 
UNION
   SELECT L.[Rebate Agreement No_]
        , L.Interval
        , CASE L.Interval
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate)
            WHEN 1 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%3,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 2 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%6,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 3 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%12,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
          END [Period Start Date]
        , ROUND(SUM(AP.[Turnover_LCY]),2) [Turnover (LCY)]
        , ROUND(SUM(AP.Turnover_LCY_corr),2) [Turnover (LCY) (corr_)]
        , ROUND(SUM(AP.[Amount_LCY]),2) [Amount (LCY)]
        , ROUND(SUM(AP.Amount_LCY_corr),2) [Amount (LCY) (corr_)]
     FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS-CN'
    WHERE AP.DepartureDate            >= '2013-01-01'
 GROUP BY L.[Rebate Agreement No_]
        , L.Interval
        , CASE L.Interval
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate)
            WHEN 1 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%3,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 2 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%6,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 3 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%12,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
          END 
UNION
   SELECT L.[Rebate Agreement No_]
        , L.Interval
        , CASE L.Interval
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate)
            WHEN 1 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%3,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 2 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%6,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 3 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%12,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
          END [Period Start Date]
        , ROUND(SUM(AP.[Turnover_LCY]),2) [Turnover (LCY)]
        , ROUND(SUM(AP.Turnover_LCY_corr),2) [Turnover (LCY) (corr_)]
        , ROUND(SUM(AP.[Amount_LCY]),2) [Amount (LCY)]
        , ROUND(SUM(AP.Amount_LCY_corr),2) [Amount (LCY) (corr_)]
     FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'TISCOVER'
    WHERE AP.DepartureDate            >= '2013-01-01'
 GROUP BY L.[Rebate Agreement No_]
        , L.Interval
        , CASE L.Interval
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate)
            WHEN 1 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%3,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 2 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%6,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
            WHEN 3 THEN DATEADD(mm,-(DATEPART(mm,AP.DepartureDate)-1)%12,DATEADD(dd,-DATEPART(dd,AP.DepartureDate)+1,AP.DepartureDate))
          END           
), AP AS
(
   SELECT AP.[Rebate Agreement No_]
        , AP.[Period Start Date]
        , CASE AP.Interval
            WHEN 0 THEN DATEADD(dd,-1,DATEADD(mm,1,AP.[Period Start Date]))
            WHEN 1 THEN DATEADD(dd,-1,DATEADD(mm,3,AP.[Period Start Date]))
            WHEN 2 THEN DATEADD(dd,-1,DATEADD(mm,6,AP.[Period Start Date]))
            WHEN 3 THEN DATEADD(dd,-1,DATEADD(mm,12,AP.[Period Start Date]))
          END [Period End Date]
        , ROUND(SUM(AP.[Amount (LCY)]),2)           [AP Amount (LCY)]
        , ROUND(SUM(AP.[Amount (LCY) (corr_)]),2)   [AP Amount (LCY) (corr_)]
        , ROUND(SUM(AP.[Turnover (LCY)]),2)         [AP Turnover (LCY)]
        , ROUND(SUM(AP.[Turnover (LCY) (corr_)]),2) [AP Turnover (LCY) (corr_)]
     FROM AP_PART AP
    GROUP BY AP.[Rebate Agreement No_]
        , AP.[Period Start Date]
        , CASE AP.Interval
            WHEN 0 THEN DATEADD(dd,-1,DATEADD(mm,1,AP.[Period Start Date]))
            WHEN 1 THEN DATEADD(dd,-1,DATEADD(mm,3,AP.[Period Start Date]))
            WHEN 2 THEN DATEADD(dd,-1,DATEADD(mm,6,AP.[Period Start Date]))
            WHEN 3 THEN DATEADD(dd,-1,DATEADD(mm,12,AP.[Period Start Date]))
          END
), RH AS
(
   SELECT RH.[Rebate Agreement No_]
        , RH.[No_]
        , RH.[Interval Start Date]
        , ROUND(SUM(RL.[Amount (LCY)]),2)           [RH Amount (LCY)]
        , ROUND(SUM(RL.[Amount (LCY) (corr_)]),2)   [RH Amount (LCY) (corr_)]
        , ROUND(SUM(RL.[Turnover (LCY)]),2)         [RH Turnover (LCY)]
        , ROUND(SUM(RL.[Turnover (LCY) (corr_)]),2) [RH Turnover (LCY) (corr_)]
     FROM AP
     JOIN [HRS$Rebate Header] RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_] = AP.[Rebate Agreement No_]
      AND RH.[Interval Start Date]  = AP.[Period Start Date]
     JOIN [HRS$Rebate Line] RL WITH (NOLOCK)
       ON RL.[Document No_] = RH.[No_]
      AND RL.Type = 5
	  AND RL.[Correction Kennung] = 0
 GROUP BY RH.[Rebate Agreement No_]
        , RH.[No_]
        , RH.[Interval Start Date]
)
   SELECT RH.[No_]
        , RH.[Rebate Agreement No_]
        , AH.[Description]
        , RH.[Interval Start Date]
        , RH.[RH Amount (LCY)]          , AP.[AP Amount (LCY)]          , RH.[RH Amount (LCY)]           - AP.[AP Amount (LCY)]           [Diff Amount (LCY)]      
        , RH.[RH Amount (LCY) (corr_)]  , AP.[AP Amount (LCY) (corr_)]  , RH.[RH Amount (LCY) (corr_)]   - AP.[AP Amount (LCY) (corr_)]   [Diff Amount (LCY) (corr_)]
        , RH.[RH Turnover (LCY)]        , AP.[AP Turnover (LCY)]        , RH.[RH Turnover (LCY)]         - AP.[AP Turnover (LCY)]         [Diff Turnover (LCY)]
        , RH.[RH Turnover (LCY) (corr_)], AP.[AP Turnover (LCY) (corr_)], RH.[RH Turnover (LCY) (corr_)] - AP.[AP Turnover (LCY) (corr_)] [Diff Turnover (LCY) (corr_)]
     FROM RH
     JOIN AP ON AP.[Rebate Agreement No_] = RH.[Rebate Agreement No_] AND AP.[Period Start Date] = RH.[Interval Start Date]
     JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK) ON AH.[No_] = RH.[Rebate Agreement No_]
    WHERE ABS(RH.[RH Amount (LCY)]           - AP.[AP Amount (LCY)]          ) > 0.01
       OR ABS(RH.[RH Amount (LCY) (corr_)]   - AP.[AP Amount (LCY) (corr_)]  ) > 0.01
       OR ABS(RH.[RH Turnover (LCY)]         - AP.[AP Turnover (LCY)]        ) > 0.01
       OR ABS(RH.[RH Turnover (LCY) (corr_)] - AP.[AP Turnover (LCY) (corr_)]) > 0.01
 ORDER BY 2,3     
END
GO
