USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateLinesYTD_Test]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Kopfinformationen zur Gutschriftsanzeige
/*
EXEC [dbo].[sp_RebateLinesYTD_Test] 'K0000000285'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateLinesYTD_Test] 
    @RebateNo varchar(20)
AS
BEGIN
DECLARE @PrintNet int, @ResultText VARCHAR(MAX), @TableName VARCHAR(120), @CompanyName VARCHAR(30), @FieldName varchar(20)
 SELECT @TableName = 'RL', @FieldName = 'Reservation Source'
 
DECLARE @SQL               VARCHAR(max)
      , @SQL1              VARCHAR(max)
      , @OnlineFilterText  VARCHAR(8000)
      , @OfflineFilterText VARCHAR(8000)
      , @FilterText        VARCHAR(8000)
      , @Filtertype        int
SET @OnlineFilterText  = ''
SET @OfflineFilterText = ''
SET @Filtertype = 0

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
  SELECT MAX(CASE WHEN P.[Reservation Source Filter Txt] LIKE '%<>%' THEN P.[Reservation Source Filter Txt] ELSE '' END) [Online Filter Text]
       , MAX(CASE WHEN P.[Reservation Source Filter Txt] LIKE '%|%'  THEN P.[Reservation Source Filter Txt] ELSE '' END) [Offline Filter Text]
       , MAX(AH.[Print Net Turnover]) [Print Booking Source]
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
SELECT @OnlineFilterText = CASE WHEN [Online Filter Text]=''  THEN RH.[Online Reservation Source]  ELSE [Online Filter Text]  END
     , @OfflineFilterText= CASE WHEN [Offline Filter Text]='' THEN RH.[Offline Reservation Source] ELSE [Offline Filter Text] END
     , @Filtertype = [Print Booking Source]
  FROM SourceFilter,[HRS$Rebate Header] RH
  
 WHERE RH.[No_] = @RebateNo

IF ((@OfflineFilterText='') AND ((@OnlineFilterText='')))
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
 WHERE (RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo)
), SourceFilter AS
(
  SELECT MAX(CASE WHEN P.[Reservation Source Filter Txt] LIKE '%<>%' THEN P.[Reservation Source Filter Txt] ELSE '' END) [Online Filter Text]
       , MAX(CASE WHEN P.[Reservation Source Filter Txt] LIKE '%|%'  THEN P.[Reservation Source Filter Txt] ELSE '' END) [Offline Filter Text]
       , MAX(AH.[Print Net Turnover]) [Print Booking Source]
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
SELECT @OnlineFilterText = CASE WHEN [Online Filter Text]=''  THEN RH.[Online Reservation Source]  ELSE [Online Filter Text]  END
     , @OfflineFilterText= CASE WHEN [Offline Filter Text]='' THEN RH.[Offline Reservation Source] ELSE [Offline Filter Text] END
     , @Filtertype = [Print Booking Source]
  FROM SourceFilter,[HRS$Posted Rebate Header] RH
 WHERE RH.[No_] = @RebateNo
END

;WITH AgreementHeader AS
(
SELECT [Print Net Turnover]
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
)
SELECT @PrintNet = COALESCE([Print Net Turnover],0) FROM AgreementHeader

SELECT @ResultText= ''
SELECT @FilterText = 
       CASE @Filtertype 
         WHEN 0 THEN @OnlineFilterText 
         WHEN 1 THEN @OfflineFilterText
         WHEN 2 THEN ''
       END
       
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
PRINT @Filtertype

SET @SQL = '
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
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
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
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
 WHERE (RH.[Rebate No_] = ''' + @RebateNo + ''') OR (RH.[No_] = ''' + @RebateNo + ''')
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
SELECT CAST(''BASE'' AS VARCHAR(20)) Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source] 
  FROM AgreementHeader          AH
  JOIN [HRS$Rebate Header]      RH WITH (NOLOCK)
    ON RH.[Rebate Agreement No_] = AH.[No_]
  JOIN [HRS$Rebate Line]        RL WITH (NOLOCK)
    ON RL.[Document No_]         = RH.[No_]
 WHERE RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date]
   AND RL.[Type] = 5
   ' + @ResultText + '
UNION
SELECT ''BASE'' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source] 
  FROM AgreementHeader          AH
  JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
    ON RH.[Rebate Agreement No_] = AH.[No_]
  JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
    ON RL.[Document No_]         = RH.[No_]
 WHERE RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date]
   AND RL.[Type] = 5
   ' + @ResultText
SET @SQL1 = '
UNION
SELECT ''COMPANYRATE'' Tab,RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source]
  FROM AgreementHeader          AH
  JOIN [HRS$Rebate Header]      RH WITH (NOLOCK)
    ON RH.[Rebate Agreement No_] = AH.[No_]
  JOIN [HRS$Rebate Line]        RL WITH (NOLOCK)
    ON RL.[Document No_]         = RH.[No_]
 WHERE RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date]
   AND RL.[Type] = 5
   AND RL.[Commission Type] = 13
   ' + @ResultText + '
UNION
SELECT ''COMPANYRATE'',RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source]
  FROM AgreementHeader          AH
  JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
    ON RH.[Rebate Agreement No_] = AH.[No_]
  JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
    ON RL.[Document No_]         = RH.[No_]
 WHERE RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date]
   AND RL.[Type] = 5
   AND RL.[Commission Type] = 13
   ' + @ResultText

--PRINT (@SQL+@SQL1)
--EXEC(@SQL+@SQL1) 
END

GO
