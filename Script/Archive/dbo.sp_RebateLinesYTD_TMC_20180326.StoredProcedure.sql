USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateLinesYTD_TMC_20180326]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 24.02.2015
-- Description:	Kopfinformationen zur Gutschriftsanzeige
--				Kopie von [sp_RebateLinesYTD]
--				Erweitert um TMC
/*
EXEC [dbo].[sp_RebateLinesYTD_TMC] 'K0000025533'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateLinesYTD_TMC_20180326] 
    @RebateNo varchar(20)
AS
BEGIN
--RP START
DECLARE @APIFilterString			VARCHAR(MAX) = ''
	  , @RegionDACHFilterString		VARCHAR(MAX) = ''
	  , @OBEFilterString			VARCHAR(MAX) = ''
CREATE TABLE #4String
	(
		StringValue	VARCHAR(100)
	)

DECLARE   @Stmt						VARCHAR(MAX) = '' 
--OBE Filter
DELETE #4String
SET @Stmt = '
	INSERT INTO #4String
	SELECT RL.[No_] 
	  FROM [HRS$Booking Source]               RL WITH (NOLOCK)
	 WHERE ' + (SELECT [dbo].[fnc_Nav2SqlFilter] (RS.[OBE Fee-Source], 'RL.[No_] ')
				  FROM [HRS$Rebate Setup] RS) + '
	'
  EXEC (@Stmt)
SELECT @OBEFilterString = @OBEFilterString + StringValue + ';'
  FROM #4String
PRINT '@OBEFilterString ='+@OBEFilterString
--API Filter
DELETE #4String
SET @Stmt = '
	INSERT INTO #4String
	SELECT RL.[No_] 
	  FROM [HRS$Booking Source]               RL WITH (NOLOCK)
	 WHERE ' + (SELECT [dbo].[fnc_Nav2SqlFilter] (RH.[API Fee-Source], 'RL.[No_]')
				  FROM [HRS$Posted Rebate Header]             RH WITH (NOLOCK)
				 WHERE RH.[No_] = @RebateNo) + '
	'
  EXEC (@Stmt)
SET @Stmt = '
	INSERT INTO #4String
	SELECT RL.[No_] 
	  FROM [HRS$Booking Source]               RL WITH (NOLOCK)
	 WHERE ' + (SELECT [dbo].[fnc_Nav2SqlFilter] (RH.[API Fee-Source], 'RL.[No_]')
				  FROM [HRS$Rebate Header]             RH WITH (NOLOCK)
				 WHERE RH.[No_] = @RebateNo) + '
	'
  EXEC (@Stmt)
  PRINT (@Stmt)
SELECT @APIFilterString = @APIFilterString + StringValue + ';'
  FROM #4String
PRINT '@APIFilterString ='+@APIFilterString
--Region DACH Filterr
DECLARE @RegionDACHSource varchar(max)
;WITH AH AS
(
	  SELECT [Region DACH-Source] FROM [HRS$Rebate Header] WHERE [No_] = @RebateNo UNION
	  SELECT [Region DACH-Source] FROM [HRS$Posted Rebate Header] WHERE @RebateNo IN ([No_], [Rebate No_]) 
)
SELECT @RegionDACHSource = [Region DACH-Source]
  FROM AH

DELETE #4String
SET @Stmt = '
INSERT INTO #4String
	SELECT CR.[Code] 
	  FROM [HRS$Country_Region] CR
	 WHERE CR.[Code]<''A'' AND ' + (SELECT [dbo].[fnc_Nav2SqlFilter] (@RegionDACHSource, 'CR.[Code] ')
				  FROM [HRS$Rebate Setup] RS) 
  EXEC (@Stmt)
SELECT @RegionDACHFilterString = @RegionDACHFilterString + StringValue + ';'
  FROM #4String
  
PRINT '@RegionDACHFilterString = '+@RegionDACHFilterString  + ';'
--RP STOP
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

PRINT @APIFilterString

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
), Data AS
(
   SELECT CASE WHEN (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@APIFilterString+''') > 0) 
                AND (RL.[Travelagency No_] = 0)
			   THEN ''API''
			   WHEN (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@APIFilterString+''') = 0) AND
					(CHARINDEX('';''+CAST(RL.[Originating Country Code] AS VARCHAR)+'';'', '';'+@RegionDACHFilterString+''') > 0) 
					' + + @ResultText + ' 
                AND (RL.[Travelagency No_] = 0)
			   THEN ''DACH''
			   WHEN (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@APIFilterString+';'') = 0) AND
					(CHARINDEX('';''+CAST(RL.[Originating Country Code] AS VARCHAR)+'';'', '';'+@RegionDACHFilterString+''') = 0) 
					' + + @ResultText + ' 
                AND (RL.[Travelagency No_] = 0)
			   THEN ''ROW''
			   WHEN (RL.[Travelagency No_] <> 0) -- OR (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@OBEFilterString+';'') <> 0)) 			        
			   THEN ''GDS'' 
			   ELSE ''BASE''
		  END Tab
		, RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_], RL.[Originating Country Code], CR.[Name] [Originating Country Name], TA.[IATA]
		, CO.[Name] [Hotel Name]
		, CO.[City] [Hotel City]
		, CC.[Name] [Hotel Country]
		, TC.[Name] [TA Country]
		, CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN ''NonCommissionables'' ELSE '''' END [Remark]
		, RL.[Document No_] [Rebate No_]
	 FROM AgreementHeader                 AH
     JOIN [HRS$Rebate Header]             RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Rebate Line]               RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     JOIN [Travelagency]                  TA WITH (NOLOCK)
       ON TA.[No_]                      = RL.[Travelagency No_]
     JOIN [HRS$Contact]                   CO WITH (NOLOCK)
       ON CO.[No_]                      = RL.[Hotel No_]
LEFT JOIN [HRS$Country_Region]            CC WITH (NOLOCK)
       ON CC.[Code]                     = CO.[Country_Region Code]
LEFT JOIN [HRS$Country_Region]            TC WITH (NOLOCK)
       ON TC.[Code]                     = TA.[Country_Region Code]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
LEFT JOIN [HRS$Country_Region]            CR WITH (NOLOCK)
       ON CR.[Code]                     = RL.[Originating Country Code]
      AND CR.[Code] BETWEEN ''1'' AND ''99999''
    WHERE (
           (RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
		OR RH.[Rebate Agreement No_] = ''V0000007569''
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
	  --AND RL.[Amount (LCY) (corr_)]<>0
   ' + @ResultText + '
UNION
   SELECT CASE WHEN (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@APIFilterString+''') > 0) 
                AND (RL.[Travelagency No_] = 0)
			   THEN ''API''
			   WHEN (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@APIFilterString+''') = 0) AND
					(CHARINDEX('';''+CAST(RL.[Originating Country Code] AS VARCHAR)+'';'', '';'+@RegionDACHFilterString+''') > 0) 
					' + + @ResultText + ' 
                AND (RL.[Travelagency No_] = 0)
			   THEN ''DACH''
			   WHEN (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@APIFilterString+';'') = 0) AND
					(CHARINDEX('';''+CAST(RL.[Originating Country Code] AS VARCHAR)+'';'', '';'+@RegionDACHFilterString+''') = 0) 
					' + + @ResultText + ' 
                AND (RL.[Travelagency No_] = 0)
			   THEN ''ROW''
			   WHEN (RL.[Travelagency No_] <> 0) -- OR (CHARINDEX('';''+CAST(RL.[Reservation Source] AS VARCHAR)+'';'', '';'+@OBEFilterString+';'') <> 0)) 			        
			   THEN ''GDS'' 
			   ELSE ''BASE''
		  END Tab
		, RL.[Loyality Rewards Account 1 No_],RL.[Loyality Rewards Account 2 No_],RL.[Reservation Date],RL.[Arival Date],RL.[Post Affiliate Partner No_],RL.[Turnover Breakfast (LCY)],RL.[Turnover Breakfast (LCY) (c_)],RL.[Amount],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover]' ELSE '[Turnover]' END +' [Turnover],RL.[Amount (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (corr_)]' ELSE '[Turnover (corr_)]' END + ' [Turnover (corr_)],RL.[Currency Faktor],RL.[Currency Code],RL.[Currency Faktor (corr_)],RL.[Currency Code (corr_)],RL.[Document No_],RL.[Line No_],RL.[Type],RL.[Rebate Amount Line],RL.[No Print],RL.[No_],RL.[Rebate Agreement No_],RL.[Posting Date (Import)],RL.[Document Date (Import)],RL.[Description],RL.[Description 2],RL.[Reservation No_],RL.[Reservation Part No_],RL.[Value Type],RL.[Value],RL.[Value Text],RL.[Value Decimal],RL.[Value Boolean],RL.[Value Date],RL.[Invoice No_],RL.[Amount (LCY)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +' [Turnover (LCY)],RL.[Commission Type],RL.[Commission Rate %],RL.[Amount (LCY) (corr_)],RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ' [Turnover (LCY) (corr_)],RL.[Commission Type (corr_)],RL.[Commission Rate % (corr_)],RL.[Departure Date],RL.[Affiliate Partner No_],RL.[Hotel No_],RL.[Room Nights],RL.[Is Net Rate],RL.[Room Nights Post Corection],RL.[Is Net Rate Post Corection],RL.[Max Entry No_],RL.[Is No Show],RL.[Top Bonus ID],RL.[MuseID],RL.[Correction Kennung],RL.[Company Name],RL.[Customer No_],RL.[Country Code],RL.[Chain],RL.[Brand],RL.[Rebate-to Vendor No_],RL.[Handbooking],RL.[Booking User],RL.[Reservation Source],COALESCE(BS.[Name],'''') [Reservation Source Name], RL.[Process Number], TA.[Amadeus No_], RL.[Originating Country Code], CR.[Name] [Originating Country Name], TA.[IATA]
		, CO.[Name] [Hotel Name]
		, CO.[City] [Hotel City]
		, CC.[Name] [Hotel Country]
		, TC.[Name] [TA Country]
		, CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN ''NonCommissionables'' ELSE '''' END [Remark]
		, RL.[Document No_] [Rebate No_]
	 FROM AgreementHeader                 AH
     JOIN [HRS$Posted Rebate Header]      RH WITH (NOLOCK)
       ON RH.[Rebate Agreement No_]     = AH.[No_]
     JOIN [HRS$Posted Rebate Line]        RL WITH (NOLOCK)
       ON RL.[Document No_]             = RH.[No_]
     JOIN [Travelagency]                  TA WITH (NOLOCK)
       ON TA.[No_]                      = RL.[Travelagency No_]
     JOIN [HRS$Contact]                   CO WITH (NOLOCK)
       ON CO.[No_]                      = RL.[Hotel No_]
LEFT JOIN [HRS$Country_Region]            CC WITH (NOLOCK)
       ON CC.[Code]                     = CO.[Country_Region Code]
LEFT JOIN [HRS$Country_Region]            TC WITH (NOLOCK)
       ON TC.[Code]                     = TA.[Country_Region Code]
LEFT JOIN [HRS$Booking Source]            BS WITH (NOLOCK)
       ON BS.[No_]                      = RL.[Reservation Source]
LEFT JOIN [HRS$Country_Region]            CR WITH (NOLOCK)
       ON CR.[Code]                     = RL.[Originating Country Code]
      AND CR.[Code] BETWEEN ''1'' AND ''99999''
    WHERE (
           (RH.[Posting Date] BETWEEN AH.[Year Start Date] AND AH.[Posting Date] AND AH.[Enable retroactive correction] = 1)
        OR (RH.[No_] = AH.[Rebate No_] AND AH.[Enable retroactive correction] = 0)
		OR RH.[Rebate Agreement No_] = ''V0000007569''
          )
      AND RL.[Departure Date] BETWEEN AH.[Year Start Date] AND AH.[Interval End Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.Cancels = 0
	  --AND RL.[Amount (LCY) (corr_)]<>0
   )
SELECT ROW_NUMBER() OVER (PARTITION BY [Tab] ORDER BY [Reservation No_], [Reservation Part No_] ) RowNumber
     , Tab+RIGHT(''0000''+CAST(CAST((ROW_NUMBER() OVER (PARTITION BY [Tab] ORDER BY [Reservation No_], [Reservation Part No_] )) * 1. / 60000. AS int) as varchar(max)),4) PageNumber
     , *
  FROM Data RL
 WHERE 1=1
 ' + @ResultText

  PRINT SUBSTRING(@SQL,1,8000)
  PRINT SUBSTRING(@SQL,8001,8000)
  PRINT SUBSTRING(@SQL,16001,8000)
  PRINT SUBSTRING(@SQL,24001,8000)
  EXEC(@SQL) 

END
GO
