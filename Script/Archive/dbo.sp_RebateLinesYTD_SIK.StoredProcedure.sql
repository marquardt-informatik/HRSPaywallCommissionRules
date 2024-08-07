USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateLinesYTD_SIK]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Kopfinformationen zur Gutschriftsanzeige
/*
EXEC [dbo].[sp_RebateLinesYTD] '0000006156'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateLinesYTD_SIK] 
    @RebateNo varchar(20)
AS
BEGIN
DECLARE @PrintNet int, @ResultText VARCHAR(MAX), @TableName VARCHAR(120), @CompanyName VARCHAR(30), @FieldName varchar(20)
 SELECT @TableName = 'RL', @FieldName = 'Reservation Source'
 
DECLARE @SQL VARCHAR(max),@SQL1 VARCHAR(max), @FilterText VARCHAR(max)

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
SELECT @FilterText = [Online Reservation Source] FROM AgreementHeader
PRINT @FilterText

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

SET @SQL = '
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
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
           (RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
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
           (RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
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
           (RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
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
           (RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RL.[Commission Type] = 13
      AND RH.Cancels = 0
   ' + @ResultText

PRINT SUBSTRING(@SQL+@SQL1,1,8000)
PRINT SUBSTRING(@SQL+@SQL1,8001,8000)
PRINT SUBSTRING(@SQL+@SQL1,16001,8000)
EXEC(@SQL+@SQL1) 
END

GO
