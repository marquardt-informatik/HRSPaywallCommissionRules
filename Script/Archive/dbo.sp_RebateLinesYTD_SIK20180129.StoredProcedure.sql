USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateLinesYTD_SIK20180129]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Kopfinformationen zur Gutschriftsanzeige
-- SAK NAV-373 Berichtsausgabe soll auf Belegdatum basieren
/*
EXEC [dbo].[sp_RebateLinesYTD] 'K0000039312'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateLinesYTD_SIK20180129] 
    @RebateNo varchar(20)
AS
BEGIN
DECLARE @PrintNet int, @ResultText VARCHAR(MAX), @TableName VARCHAR(120), @CompanyName VARCHAR(30), @FieldName varchar(20)
 SELECT @TableName = 'RL', @FieldName = 'Reservation Source'
 
DECLARE @SQL VARCHAR(max),@SQL1 VARCHAR(max), @SQLCancelled VARCHAR(max), @FilterText VARCHAR(max), @OnlineCancellations tinyint, @OfflineBookings tinyint

SELECT @FilterText = ''
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
)
SELECT @FilterText = [Online Reservation Source]
     , @OnlineCancellations = [Include online cancellation] 
	 , @OfflineBookings = [Include offline bookings]
  FROM AgreementHeader

IF @OfflineBookings = 1
BEGIN
  SET @FilterText = ''
  PRINT '@OfflineBookings = '+CAST(@OfflineBookings AS varchar(max))
END
IF @OfflineBookings = 0
BEGIN
	IF COALESCE(@FilterText,'')=''
	BEGIN  
		;WITH AgreementHeader AS
		(
		SELECT RH.[Posting Date]
			 , RH.[Interval Start Date]
			 , RH.[Interval End Date]
			 , AH.*
		  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
		  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
			ON AH.[No_] = RH.[Rebate Agreement No_] 
		 WHERE RH.[No_] = @RebateNo
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
		)
		SELECT @FilterText = CASE WHEN @FilterText<>'' THEN @FilterText + '|' ELSE '' END + [Filter Text]
		  FROM SourceFilter  
	END
	IF COALESCE(@FilterText,'')=''
	BEGIN  
		;WITH AgreementHeader AS
		(
		SELECT RH.[Posting Date]
			 , RH.[Interval Start Date]
			 , RH.[Interval End Date]
			 , AH.*
		  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
		  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
			ON AH.[No_] = RH.[Rebate Agreement No_] 
		 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
		), SourceFilter AS
		(
		  SELECT P.[Reservation Source Filter Txt] [Filter Text]
			FROM [HRS$Parameter]              P
			JOIN [HRS$Rebate Agreement Line] AL
			  ON AL.[Input Parameter 1 Code] = P.[Code]
			  OR AL.[Input Parameter 2 Code] = P.[Code]
			  OR AL.[Input Parameter 3 Code] = P.[Code]
			  OR AL.[Input Parameter 4 Code] = P.[Code]
			  OR AL.[Input Parameter 5 Code] = P.[Code]
			JOIN AgreementHeader             AH
			  ON AH.[No_]                     = AL.[Rebate No_] 
		   WHERE P.[Reservation Source Filter Txt] <> ''    
		)
		SELECT @FilterText = CASE WHEN @FilterText<>'' THEN @FilterText + '|' ELSE '' END + [Filter Text]
		  FROM SourceFilter  
	END  
END
PRINT   @FilterText

;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
)
SELECT @PrintNet = COALESCE([Print Net Turnover],0) FROM AgreementHeader

SELECT @ResultText= ''  
IF @FilterText <>'' 
BEGIN
SELECT @ResultText = @ResultText + 
       CASE WHEN CHARINDEX('&', @FilterText) > 0 THEN 
         CASE WHEN @ResultText <> '' THEN ' AND ' ELSE '' END 
       + RS.SqlFilterAND('' + [String] + '', @TableName + '.[' + @FieldName +']',0)
       ELSE
         CASE WHEN @ResultText <> '' THEN ' OR ' ELSE '' END 
       + RS.SqlFilterOR('' + [String] + '', @TableName + '.[' + @FieldName +']',0)
       END
  FROM RS.Split(@FilterText,'&')
SELECT @ResultText = 'AND (' + @ResultText + ')'
END

PRINT @ResultText
SET @SQL = '
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
 WHERE RH.[No_] = ''' + @RebateNo + '''
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
 WHERE (RH.[No_] = ''' + @RebateNo + ''' OR RH.[Rebate No_] = ''' + @RebateNo + ''')
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
   SELECT ''BASE'' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_]
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
        OR RH.[Rebate Agreement No_] = ''V0000007569''
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
--    AND RL.[Amount (LCY) (corr_)] <> 0
   ' + @ResultText + '
UNION
   SELECT ''BASE'' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_]  
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
        OR RH.[Rebate Agreement No_] = ''V0000007569''
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.Cancels = 0
--    AND RL.[Amount (LCY) (corr_)] <> 0
   ' + @ResultText
SET @SQL1 = '
UNION
   SELECT ''COMPANYRATE'' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_] 
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
        OR RH.[Rebate Agreement No_] = ''V0000007569''
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RL.[Commission Type] = 13
   ' + @ResultText + '
UNION
   SELECT ''COMPANYRATE'',RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_] 
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
        OR RH.[Rebate Agreement No_] = ''V0000007569''
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RL.[Commission Type] = 13
      AND RH.Cancels = 0
   )
SELECT ROW_NUMBER() OVER (PARTITION BY [Tab] ORDER BY [Reservation No_], [Reservation Part No_] ) RowNumber
     , Tab+RIGHT(''0000''+CAST(CAST((ROW_NUMBER() OVER (PARTITION BY [Tab] ORDER BY [Reservation No_], [Reservation Part No_] )) * 1. / 60000. AS int) as varchar(max)),4) PageNumber
     , *
  FROM Data RL
 WHERE 1=1
 ' + @ResultText

SET @SQLCancelled = '
UNION
   SELECT ''BASENS'' Tab,NULL [Loyality Rewards Account 1 No_],NULL [Loyality Rewards Account 2 No_],BU.B_DATUM [Reservation Date],BT.BT_VON [Arival Date],NULL [Post Affiliate Partner No_],NULL [Turnover Breakfast (LCY)],NULL [Turnover Breakfast (LCY) (c_)],NULL [Amount],BT_PREIS / 100. [Turnover],NULL [Amount (corr_)],NULL [Turnover (corr_)],ROUND(1./(BU.W_KURS/100000.),5) [Currency Faktor],BU.W_ISO [Currency Code],NULL [Currency Faktor (corr_)],NULL [Currency Code (corr_)],NULL [Document No_],NULL [Line No_],6 [Type],NULL [Rebate Amount Line],0 [No Print],NULL [No_],NULL [Rebate Agreement No_],NULL [Posting Date (Import)],NULL [Document Date (Import)],BU.B_GAST1 [Description],BU.B_GAST2 [Description 2],BT.B_KEY [Reservation No_],BT.BT_POS [Reservation Part No_],NULL [Value Type],NULL [Value],NULL [Value Text],NULL [Value Decimal],NULL [Value Boolean],NULL [Value Date],NULL [Invoice No_],NULL [Amount (LCY)],NULL [Turnover (LCY)],NULL [Commission Type],NULL [Commission Rate %],NULL [Amount (LCY) (corr_)],NULL [Turnover (LCY) (corr_)],NULL [Commission Type (corr_)],NULL [Commission Rate % (corr_)],BT.BT_BIS [Departure Date],BU.K_KEY [Affiliate Partner No_],BU.H_KEY [Hotel No_],NULL [Room Nights],NULL [Is Net Rate],NULL [Room Nights Post Corection],NULL [Is Net Rate Post Corection],NULL [Max Entry No_],NULL [Is No Show],NULL [Top Bonus ID],BU.MUSE_ID [MuseID],NULL [Correction Kennung],BU.B_FIRMA [Company Name],BU.H_KEY [Customer No_],NULL [Country Code],NULL [Chain],NULL [Brand],NULL [Rebate-to Vendor No_],BU.B_HANDBOOKING [Handbooking],BU.MA_USER [Booking User],BU.B_QUELLE [Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name],BU.BP_KEY [Process Number],NULL [Amadeus No_]
     FROM AgreementHeader AH,HRSDB.BUCHUNG B1 WITH (NOLOCK)
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = B1.B_KEY_ROOT
     JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK)
       ON BT.B_KEY = BU.B_KEY
     JOIN AP
       ON AP.[Affiliate Partner No_] = BU.K_KEY
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = BU.B_QUELLE
 WHERE BU.B_AB_DATUM BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
   AND B1.B_CANCELLATION = 1
'   

IF @OnlineCancellations=1
BEGIN
	PRINT SUBSTRING(@SQL+@SQLCancelled+@SQL1,1,8000)
	PRINT SUBSTRING(@SQL+@SQLCancelled+@SQL1,8001,8000)
	PRINT SUBSTRING(@SQL+@SQLCancelled+@SQL1,16001,8000)
	EXEC(@SQL+@SQLCancelled+@SQL1) 
END
ELSE
BEGIN
	PRINT SUBSTRING(@SQL+@SQL1,1,8000)
	PRINT SUBSTRING(@SQL+@SQL1,8001,8000)
	PRINT SUBSTRING(@SQL+@SQL1,16001,8000)
	EXEC(@SQL+@SQL1) 
END
END
GO
