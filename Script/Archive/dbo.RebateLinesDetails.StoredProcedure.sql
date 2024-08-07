USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[RebateLinesDetails]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[RebateLinesDetails]
(
  @ReNr varchar(20) = 'K0000046285'
, @TabName varchar(20) = 'COMPANYRATE'
)
AS

;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
	 , RH.[Document Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , RH.[No_] [Rebate No_]
     , CASE WHEN AH.[Fiscal Year Start (Month)] = 0 THEN
         DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+1, RH.[Interval Start Date])
       ELSE
         CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=AH.[Fiscal Year Start (Month)] THEN
           DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         ELSE
           DATEADD(mm,-12-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         END
       END [Year Start Date]
     , DATEADD(dd,-1,CASE WHEN AH.[Fiscal Year Start (Month)] = 0 THEN
         DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+13, RH.[Interval Start Date]) 
       ELSE
         CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=AH.[Fiscal Year Start (Month)] THEN
           DATEADD(mm,12-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         ELSE
           DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         END
       END) [Year End Date]
     , AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @ReNr
UNION 
SELECT RH.[Posting Date]
	 , RH.[Document Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , RH.[No_] [Rebate No_]
     , CASE WHEN AH.[Fiscal Year Start (Month)] = 0 THEN
         DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+1, RH.[Interval Start Date])
       ELSE
         CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=AH.[Fiscal Year Start (Month)] THEN
           DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         ELSE
           DATEADD(mm,-12-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         END
       END [Year Start Date]
     , DATEADD(dd,-1,CASE WHEN AH.[Fiscal Year Start (Month)] = 0 THEN
         DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+13, RH.[Interval Start Date]) 
       ELSE
         CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=AH.[Fiscal Year Start (Month)] THEN
           DATEADD(mm,12-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         ELSE
           DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-AH.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
         END
       END) [Year End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE (RH.[No_] = @ReNr OR RH.[Rebate No_] = @ReNr)
), AP AS
(
	SELECT AV.[Affiliate Partner No_], AH.[No_]
	  FROM [HRS$Affiliate Partner Vendor] AV WITH (NOLOCK)
	  JOIN AgreementHeader AH
		ON AH.[Rebate-to Vendor No_] = AV.[Vendor No_]
), SourceFilter AS
(
  SELECT MAX(P.[Reservation Source Filter Txt]) [Filter Text]
    FROM [HRS$Parameter]              P
    JOIN [HRS$Rebate Agreement Line] AL
      ON AL.[Input Parameter 1 Code] = P.[Code]
      OR AL.[Input Parameter 2 Code] = P.[Code]
      OR AL.[Input Parameter 3 Code] = P.[Code]
      OR AL.[Input Parameter 4 Code] = P.[Code]
      OR AL.[Input Parameter 5 Code] = P.[Code]
    JOIN AgreementHeader             AH
      ON AH.[No_]                     = AL.[Rebate No_]     
), Data As
(
   SELECT 'BASE' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_], CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END [Is NonCom]
		, CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Rebate Header]             RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Rebate Line]               RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     JOIN [Travelagency]                  TA WITH (NOLOCK)
       ON TA.[No_]                      = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE (
           (RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
        OR RH.[Rebate Agreement No_] = 'V0000007569'
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
	  AND RL.[Source Class]<>1
--    AND RL.[Amount (LCY) (corr_)] <> 0
   AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16) AND (RL.[Reservation Source] != 5) AND (RL.[Reservation Source] != 7) AND (RL.[Reservation Source] != 4))
UNION
   SELECT 'BASE' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_], CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END [Is NonCom]  
		, CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     JOIN [Travelagency]                  TA WITH (NOLOCK)
       ON TA.[No_]                      = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE (
           (RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
        OR RH.[Rebate Agreement No_] = 'V0000007569'
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.Cancels = 0
	  AND RL.[Source Class]<>1
--    AND RL.[Amount (LCY) (corr_)] <> 0
   AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16) AND (RL.[Reservation Source] != 5) AND (RL.[Reservation Source] != 7) AND (RL.[Reservation Source] != 4))
UNION
   SELECT 'COMPANYRATE' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_], CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END [Is NonCom] 
		, CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Rebate Header]             RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Rebate Line]               RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     JOIN [Travelagency]                  TA WITH (NOLOCK)
       ON TA.[No_]                      = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE (
           (RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
        OR RH.[Rebate Agreement No_] = 'V0000007569'
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
	  AND RL.[Source Class]<>1
      AND RL.[Commission Type (corr_)] = 13
	  AND ABS(RL.[Turnover (LCY) (corr_)]) >= 0.01
	  AND ABS(RL.[Amount (LCY) (corr_)]) < 0.01
   AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16) AND (RL.[Reservation Source] != 5) AND (RL.[Reservation Source] != 7) AND (RL.[Reservation Source] != 4))
UNION
   SELECT 'COMPANYRATE',RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_], CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END [Is NonCom] 
		, CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     JOIN [Travelagency]                  TA WITH (NOLOCK)
       ON TA.[No_]                      = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE (
           (RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
        OR RH.[Rebate Agreement No_] = 'V0000007569'
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RL.[Commission Type (corr_)] = 13
	  AND ABS(RL.[Turnover (LCY) (corr_)]) >= 0.01
	  AND ABS(RL.[Amount (LCY) (corr_)]) < 0.01
      AND RH.Cancels = 0
	  AND RL.[Source Class]<>1
), Data2 AS
(
  SELECT Tab
       , MAX(RL.[Loyality Rewards Account 1 No_]) [Loyality Rewards Account 1 No_]
       , MAX(RL.[Loyality Rewards Account 2 No_]) [Loyality Rewards Account 2 No_]
       , MIN(RL.[Reservation Date])               [Reservation Date]
       , MIN(RL.[Arival Date])                    [Arival Date]
       , MAX(RL.[Post Affiliate Partner No_])     [Post Affiliate Partner No_]
       , SUM(RL.[Turnover Breakfast (LCY)])       [Turnover Breakfast (LCY)]
       , SUM(RL.[Turnover Breakfast (LCY) (c_)])  [Turnover Breakfast (LCY) (c_)]
       , SUM(RL.[Amount])                         [Amount]
       , SUM(RL.[Turnover])                       [Turnover]
       , SUM(RL.[Amount (corr_)])                 [Amount (corr_)]
       , SUM(RL.[Turnover (corr_)])               [Turnover (corr_)]
       , MAX(RL.[Currency Faktor])                [Currency Faktor]
       , MAX(RL.[Currency Code])                  [Currency Code]
       , MAX(RL.[Currency Faktor (corr_)])        [Currency Faktor (corr_)]
       , MAX(RL.[Currency Code (corr_)])          [Currency Code (corr_)]
       , MAX(RL.[Document No_])                   [Document No_]
       , MIN(RL.[Line No_])                       [Line No_]
       , MAX(RL.[Type])                           [Type]
       , MAX(RL.[Rebate Amount Line])             [Rebate Amount Line]
       , MAX(RL.[No Print])                       [No Print]
       , MAX(RL.[No_])                            [No_]
       , MAX(RL.[Rebate Agreement No_])           [Rebate Agreement No_]
       , MAX(RL.[Posting Date (Import)]) [Posting Date (Import)]
       , MAX(RL.[Document Date (Import)]) [Document Date (Import)]
       , MAX(RL.[Description]) [Description]
       , MAX(RL.[Description 2]) [Description 2]
       , RL.[Reservation No_]
       , RL.[Reservation Part No_]
       , MAX(RL.[Value Type]) [Value Type]
       , MAX(RL.[Value]) [Value]
       , MAX(RL.[Value Text]) [Value Text]
       , MAX(RL.[Value Decimal]) [Value Decimal]
       , MAX(RL.[Value Boolean]) [Value Boolean]
       , MAX(RL.[Value Date]) [Value Date]
       , MAX(RL.[Invoice No_]) [Invoice No_]
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , MAX(RL.[Commission Type]) [Commission Type]
       , MAX(RL.[Commission Rate %]) [Commission Rate %]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , MAX(RL.[Commission Type (corr_)])[Commission Type (corr_)]
       , MAX(RL.[Commission Rate % (corr_)]) [Commission Rate % (corr_)]
       , MAX(RL.[Departure Date]) [Departure Date]
       , MAX(RL.[Affiliate Partner No_]) [Affiliate Partner No_]
       , MAX(RL.[Hotel No_]) [Hotel No_]
       , SUM(RL.[Room Nights]) [Room Nights]
       , MAX(RL.[Is Net Rate]) [Is Net Rate]
       , SUM(RL.[Room Nights Post Corection]) [Room Nights Post Corection]
       , MAX(RL.[Is Net Rate Post Corection]) [Is Net Rate Post Corection]
       , MAX(RL.[Max Entry No_]) [Max Entry No_]
       , MAX(RL.[Is No Show]) [Is No Show]
       , MAX(RL.[Top Bonus ID]) [Top Bonus ID]
       , MAX(RL.[MuseID]) [MuseID]
       , MAX(RL.[Correction Kennung]) [Correction Kennung]
       , MAX(RL.[Company Name]) [Company Name]
       , MAX(RL.[Customer No_]) [Customer No_]
       , MAX(RL.[Country Code]) [Country Code]
       , MAX(RL.[Chain]) [Chain]
       , MAX(RL.[Brand]) [Brand]
       , MAX(RL.[Rebate-to Vendor No_]) [Rebate-to Vendor No_]
       , MAX(RL.[Handbooking]) [Handbooking]
       , MAX(RL.[Booking User]) [Booking User]
       , MAX(RL.[Reservation Source]) [Reservation Source]
       , MAX(RL.[Reservation Source Name]) [Reservation Source Name]
       , MAX(RL.[Process Number]) [Process Number]
       , MAX(RL.[Amadeus No_]) [Amadeus No_]
       , MAX(RL.[Is NonCom]) [Is NonCom]
	   , MAX([Remark]) [Remark]
    FROM Data RL
GROUP BY Tab      
       , RL.[Reservation No_]
       , RL.[Reservation Part No_]
), Data3 AS
(
  SELECT ROW_NUMBER() OVER (PARTITION BY [Tab] ORDER BY [Reservation No_], [Reservation Part No_] ) RowNumber
       , Tab+RIGHT('0000'+CAST(CAST((ROW_NUMBER() OVER (PARTITION BY [Tab] ORDER BY [Reservation No_], [Reservation Part No_] )) * 1. / 60000. AS int) as varchar(max)),4) PageNumber
       , *
    FROM Data2 RL
   WHERE 1=1
     AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16) AND (RL.[Reservation Source] != 5) AND (RL.[Reservation Source] != 7) AND (RL.[Reservation Source] != 4))
)
SELECT * FROM AgreementHeader
--SELECT [Invoice No_]
--     , [Process Number]
--     , [Reservation No_]
--	 , [Reservation Part No_]
--	 , [Turnover (LCY)]
--	 , [Turnover (LCY) (corr_)]
--	 , [Affiliate Partner No_]
--	 , [Reservation Date]
--	 , [Arival Date]
--	 , [Departure Date]
--	 , [Hotel No_]
--	 , [Room Nights]
--	 , [Room Nights Post Corection]
--     , CASE WHEN [Is NonCom] = 1 THEN 'Ja' ELSE 'Nein' END [Ist NonCom]
--     , [Remark]
--  FROm Data3
-- WHERE [Tab] = @TabName
--ORDER BY [Reservation No_],[Reservation Part No_]
GO
