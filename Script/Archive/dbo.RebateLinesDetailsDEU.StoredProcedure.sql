USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[RebateLinesDetailsDEU]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[RebateLinesDetailsDEU]
(
  @ReNr varchar(20) = 'K0000057069' 
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
   SELECT 'BASE' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number]
        , CASE WHEN RL.[Amount (LCY) (corr_)] BETWEEN -0.01 AND 0.01 THEN 1 ELSE 0 END [Is NonCom]
		, CASE WHEN RL.[Amount (LCY) (corr_)] BETWEEN -0.01 AND 0.01 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Rebate Header]             RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Rebate Line]               RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
	  AND RL.[Source Class]<>1
--    AND RL.[Amount (LCY) (corr_)] <> 0
UNION ALL
   SELECT 'BASE' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number]
        , CASE WHEN RL.[Amount (LCY) (corr_)] BETWEEN -0.01 AND 0.01 THEN 1 ELSE 0 END [Is NonCom]  
		, CASE WHEN RL.[Amount (LCY) (corr_)] BETWEEN -0.01 AND 0.01 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.Cancels = 0
	  AND RL.[Source Class]<>1
--    AND RL.[Amount (LCY) (corr_)] <> 0
UNION ALL
   SELECT 'COMPANYRATE' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number], CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END [Is NonCom] 
		, CASE WHEN RL.[Amount (LCY) (corr_)] BETWEEN -0.01 AND 0.01 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Rebate Header]             RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Rebate Line]               RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     --JOIN [Travelagency]                  TA WITH (NOLOCK)
       --ON TA.[No_]                      = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
	  AND RL.[Source Class]<>1
      AND RL.[Commission Type (corr_)] = 13
	  AND ABS(RL.[Turnover (LCY) (corr_)]) >= 0.01
	  --AND ABS(RL.[Amount (LCY) (corr_)]) < 0.01
UNION ALL
   SELECT 'COMPANYRATE',RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.[Turnover] [Turnover],RL.[Amount (corr_)],RL.[Turnover (corr_)] [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.[Turnover (LCY)] [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.[Turnover (LCY) (corr_)] [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'') [Reservation Source Name], RL.[Process Number], CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN 1 ELSE 0 END [Is NonCom] 
		, CASE WHEN RL.[Amount (LCY) (corr_)] BETWEEN -0.01 AND 0.01 THEN 'NonCommissionables' ELSE '' END [Remark]
     FROM AgreementHeader                 AH
     JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     --JOIN [Travelagency]                  TA WITH (NOLOCK)
      -- ON TA.[No_]                      = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
    WHERE RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RL.[Commission Type (corr_)] = 13
	  AND ABS(RL.[Turnover (LCY) (corr_)]) >= 0.01
	  --AND ABS(RL.[Amount (LCY) (corr_)]) < 0.01
      AND RH.Cancels = 0
	  AND RL.[Source Class]<>1
), Data2 AS
(
  SELECT RL.[Reservation No_]
       , RL.[Reservation Part No_]
       , MIN(RL.[Reservation Date])               [Reservation Date]
       , MIN(RL.[Arival Date])                    [Arival Date]
       , MAX(RL.[Departure Date])                 [Departure Date]
       , MAX(RL.[Invoice No_]) [Invoice No_]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , MAX(RL.[Affiliate Partner No_]) [Affiliate Partner No_]
       , MAX(RL.[Hotel No_]) [Hotel No_]
       , SUM(RL.[Room Nights]) [Room Nights]
       , MAX(RL.[Is Net Rate]) [Is Net Rate]
       , SUM(RL.[Room Nights Post Corection]) [Room Nights Post Corection]
       , MAX(RL.[Process Number]) [Process Number]
       , CASE WHEN RL.[Is NonCom]=1 THEN 1 ELSE 0 END [Is NonCom]
	   , CASE WHEN RL.[Is NonCom]=1 THEN 'NonCommissionables' ELSE '' END [Remark]
    FROM Data RL
   WHERE [Tab] = @TabName
GROUP BY RL.[Reservation No_]
       , RL.[Reservation Part No_]
       , RL.[Is NonCom]
       --, RL.[Is NonCom]
)
--SELECT * FROM Data2
SELECT [Invoice No_] [Rechnung-Nr.]
     , [Process Number] [Vorgangsnumer]
     , [Reservation No_] [Buchungs-Nr.]
	 , [Reservation Part No_] [Pos.-Nr.]
	 , [Turnover (LCY)] [Hotelumsatz €]
	 , [Turnover (LCY) (corr_)] [Hotelumsatz (korr.) €]
	 , [Affiliate Partner No_] [Kunden-Nr.]
	 , [Reservation Date] [Reservierungsdatum]
	 , [Arival Date] [Anreisedatum]
	 , [Departure Date] [Abreisedatum]
	 , [Hotel No_] [Hotel-Nr.]
	 , [Room Nights] [Übernachtungen]
	 , [Room Nights Post Corection] [Übernachtungen (korr.)]
     , CASE WHEN [Is NonCom] = 1 THEN 'Ja' ELSE 'Nein' END [Ist NonCom]
     , [Remark] [Bemerkung]
  FROm Data2
ORDER BY [Reservation No_],[Reservation Part No_]
GO
