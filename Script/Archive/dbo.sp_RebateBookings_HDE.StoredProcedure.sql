USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateBookings_HDE]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 17.04.2013
-- Description:	Zeilen für Abrechnung nach Anzahl der Buchungen
--SAK NAV-373 Berichtsausgabe soll auf Belegdatum basieren
/*
EXEC [dbo].[sp_RebateBookings_HDE] 'K0000025063'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateBookings_HDE] 
    @RebateNo varchar(20)
AS
BEGIN
DECLARE @PrintNet int, @ResultText VARCHAR(MAX), @TableName VARCHAR(120), @CompanyName VARCHAR(30), @FieldName varchar(20)
 SELECT @TableName = 'RL', @FieldName = 'Reservation Source'

DECLARE @CustList VARCHAR(MAX)
SELECT @CustList = ''

DECLARE @AP AS TABLE([Affiliate Partner No_] int, [Rebate No_] varchar(20))
DECLARE @ActualCustomer int, @PreviousCustomer int, @FirstCustomer int
 SELECT @ActualCustomer = 0, @PreviousCustomer = 0, @FirstCustomer = 0

BEGIN -- Parameter 
DECLARE @ParameterList varchar(max)
 SELECT @ParameterList  = ''
 SELECT @ParameterList  = @ParameterList 
      + ',' + AH.[Input Parameter 1 Code]
      + ',' + AH.[Input Parameter 2 Code]
      + ',' + AH.[Input Parameter 3 Code]
      + ',' + AH.[Input Parameter 4 Code]
      + ',' + AH.[Input Parameter 5 Code]
      + ',' + AH.[Input Parameter 6 Code]
      + ',' + AH.[Input Parameter 7 Code]
      + ',' + AH.[Input Parameter 8 Code]
      + ',' + AH.[Input Parameter 9 Code]
      + ',' + AH.[Input Parameter 10 Code]
      + ',' + AH.[Output Parameter Code]
   FROM [hotel_de$Rebate Header]    RH WITH (NOLOCK)
   JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo

 SELECT @ParameterList  = @ParameterList 
      + ',' + AH.[Input Parameter 1 Code]
      + ',' + AH.[Input Parameter 2 Code]
      + ',' + AH.[Input Parameter 3 Code]
      + ',' + AH.[Input Parameter 4 Code]
      + ',' + AH.[Input Parameter 5 Code]
      + ',' + AH.[Input Parameter 6 Code]
      + ',' + AH.[Input Parameter 7 Code]
      + ',' + AH.[Input Parameter 8 Code]
      + ',' + AH.[Input Parameter 9 Code]
      + ',' + AH.[Input Parameter 10 Code]
      + ',' + AH.[Output Parameter Code]
   FROM [hotel_de$Posted Rebate Header]    RH WITH (NOLOCK)
   JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
END

BEGIN -- AffiliatePartnerList 
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[Rebate No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo

)
INSERT INTO @AP
SELECT AV.[Affiliate Partner No_], AH.[No_]
  FROM [hotel_de$Affiliate Partner Vendor] AV WITH (NOLOCK)
  JOIN AgreementHeader AH
    ON AH.[Rebate-to Vendor No_] = AV.[Vendor No_]

DECLARE cur CURSOR FOR SELECT * FROM @AP ORDER BY 1

OPEN cur

FETCH NEXT FROM cur INTO @ActualCustomer, @RebateNo

SELECT @FirstCustomer = @ActualCustomer

WHILE @@FETCH_STATUS = 0
BEGIN
  IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
    IF (@PreviousCustomer<> 0) BEGIN
      SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
      SET @CustList = @CustList 
                    + CASE WHEN @PreviousCustomer = @FirstCustomer THEN 
                        CAST(@PreviousCustomer AS varchar)
                      ELSE
                        CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                      END
      SELECT @FirstCustomer = @ActualCustomer
    END 
  END
  
  SELECT @PreviousCustomer = @ActualCustomer
  FETCH NEXT FROM cur INTO @ActualCustomer, @RebateNo
END

IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
  IF (@PreviousCustomer<> 0) BEGIN
    SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
    SET @CustList = @CustList 
                  + CASE WHEN @PreviousCustomer = @FirstCustomer THEN 
                      CAST(@PreviousCustomer AS varchar)
                    ELSE
                      CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                    END
    SELECT @FirstCustomer = @ActualCustomer
  END 
END

CLOSE cur
DEALLOCATE cur
END
  
BEGIN -- Filtertext 
DECLARE @SQL VARCHAR(max),@SQL1 VARCHAR(max), @FilterText VARCHAR(max)

SELECT @FilterText = ''
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
), SourceFilter AS
(
  SELECT MAX(P.[Reservation Source Filter Txt]) [Filter Text]
    FROM [hotel_de$Parameter]              P
    JOIN [hotel_de$Rebate Agreement Line] AL
      ON AL.[Input Parameter 1 Code] = P.[Code]
      OR AL.[Input Parameter 2 Code] = P.[Code]
      OR AL.[Input Parameter 3 Code] = P.[Code]
      OR AL.[Input Parameter 4 Code] = P.[Code]
      OR AL.[Input Parameter 5 Code] = P.[Code]
    JOIN AgreementHeader             AH
      ON AH.[No_]                     = AL.[Rebate No_]     
)
SELECT @FilterText = [Filter Text]
  FROM SourceFilter

IF COALESCE(@FilterText,'')=''
BEGIN  
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
), SourceFilter AS
(
  SELECT MAX(P.[Reservation Source Filter Txt]) [Filter Text]
    FROM [hotel_de$Parameter]              P
    JOIN [hotel_de$Rebate Agreement Line] AL
      ON AL.[Input Parameter 1 Code] = P.[Code]
      OR AL.[Input Parameter 2 Code] = P.[Code]
      OR AL.[Input Parameter 3 Code] = P.[Code]
      OR AL.[Input Parameter 4 Code] = P.[Code]
      OR AL.[Input Parameter 5 Code] = P.[Code]
    JOIN AgreementHeader             AH
      ON AH.[No_]                     = AL.[Rebate No_]     
)
SELECT @FilterText = [Filter Text]
  FROM SourceFilter  
END  
PRINT   @FilterText
END

;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
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
DECLARE @Parameter TABLE
(
    [Rebate No_]    VARCHAR(20)
  , [No_]           VARCHAR(20)
  , [Value Decimal] DEC(37,20)
  , [Name]          VARCHAR(120)
)

;WITH AgreementHeader AS
(
SELECT AH.*, 0 [Posted]
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + '''
UNION 
SELECT AH.*, 1 [Posted]
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + ''' OR RH.[Rebate No_] = ''' + @RebateNo + '''
),  RL AS
(
  SELECT RH.[No_] [Rebate No_], RL.[No_], RL.[Value Decimal], PA.[Name]
    FROM [hotel_de$Rebate Line]   RL WITH (NOLOCK) 
    JOIN [hotel_de$Rebate Header] RH WITH (NOLOCK) 
      ON RL.[Document No_] = RH.[No_]
    JOIN [hotel_de$Parameter]     PA WITH (NOLOCK)
      ON PA.[Code]  = RL.[No_]
    JOIN AgreementHeader     AH 
      ON AH.[No_] = RH.[Rebate Agreement No_]
   WHERE RL.[Type] IN (1,2)
UNION   
  SELECT RH.[No_], RL.[No_], RL.[Value Decimal], PA.[Name]
    FROM [hotel_de$Posted Rebate Line]   RL WITH (NOLOCK) 
    JOIN [hotel_de$Posted Rebate Header] RH WITH (NOLOCK) 
      ON RL.[Document No_] = RH.[No_]
    JOIN [hotel_de$Parameter]     PA WITH (NOLOCK)
      ON PA.[Code]  = RL.[No_]
    JOIN AgreementHeader     AH 
      ON AH.[No_] = RH.[Rebate Agreement No_]
   WHERE RL.[Type] IN (1,2)
)
INSERT INTO @Parameter
SELECT * FROM RL

INSERT INTO @Parameter
SELECT '''','''',0.0,'''' UNION
SELECT '''',PA.[Code], PA.[Value Decimal], PA.[Name]
  FROM [hotel_de$Parameter] PA WITH (NOLOCK)
 WHERE '',' + @ParameterList + ','' LIKE ''%,'' + PA.[Code] + '',%''
   AND NOT PA.[Code] IN (SELECT [No_] FROM @Parameter)
   
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
     , 0 [Posted]
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + '''
UNION 
SELECT RH.[Posting Date]
	 , RH.[Document Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , RH.[Rebate No_]
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
     , 1 [Posted]
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + ''' 
    OR RH.[Rebate No_] = ''' + @RebateNo + '''    
), _TOTAL AS
(
   SELECT RH.[Interval Start Date]
        , RH.[Interval End Date]
        , MAX(RL.[Loyality Rewards Account 1 No_]) [Loyality Rewards Account 1 No_]
        , MAX(RL.[Loyality Rewards Account 2 No_]) [Loyality Rewards Account 2 No_]
        , MIN(RL.[Reservation Date])               [Reservation Date]
        , MIN(RL.[Arival Date])                    [Arival Date]
        , MAX(RL.[Post Affiliate Partner No_])     [Post Affiliate Partner No_]
        , SUM(RL.[Turnover Breakfast (LCY)])       [Turnover Breakfast (LCY)]
        , SUM(RL.[Turnover Breakfast (LCY) (c_)])  [Turnover Breakfast (LCY) (c_)]
        , SUM(RL.[Amount])                         [Amount]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover]' 
          ELSE 
            '[Turnover]' 
          END +') [Turnover]
        , SUM(RL.[Amount (corr_)])                 [Amount (corr_)]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover (corr_)]' 
          ELSE 
            '[Turnover (corr_)]' 
          END + ') [Turnover (corr_)]
        , MAX(RL.[Currency Faktor])                [Currency Faktor]
        , MAX(RL.[Currency Code])                  [Currency Code]
        , MAX(RL.[Currency Faktor (corr_)])        [Currency Faktor (corr_)]
        , MAX(RL.[Currency Code (corr_)])          [Currency Code (corr_)]
        , MAX(RL.[Document No_])                   [Document No_]
        , MAX(RL.[Line No_])                       [Line No_]
        , MAX(RL.[Type])                           [Type]
        , MAX(RL.[Rebate Amount Line])             [Rebate Amount Line]
        , MAX(RL.[No Print])                       [No Print]
        , MAX(RL.[No_])                            [No_]
        , MAX(RL.[Rebate Agreement No_])           [Rebate Agreement No_]
        , MAX(RL.[Posting Date (Import)])          [Posting Date (Import)]
        , MAX(RL.[Document Date (Import)])         [Document Date (Import)]
        , MAX(RL.[Description])                    [Description]
        , MAX(RL.[Description 2])                  [Description 2]
        , RL.[Reservation No_]
        , 0 [Reservation Part No_]
        , MAX(RL.[Value Type]) [Value Type]
        , MAX(RL.[Value]) [Value]
        , MAX(RL.[Value Text]) [Value Text]
        , MAX(RL.[Value Decimal]) [Value Decimal]
        , MAX(RL.[Value Boolean]) [Value Boolean]
        , MAX(RL.[Value Date]) [Value Date]
        , MAX(RL.[Invoice No_]) [Invoice No_]
        , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +') [Turnover (LCY)]
        , MAX(RL.[Commission Type]) [Commission Type]
        , MAX(RL.[Commission Rate %]) [Commission Rate %]
        , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ') [Turnover (LCY) (corr_)]
        , MAX(RL.[Commission Type (corr_)]) [Commission Type (corr_)]
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
        , MAX(COALESCE(BS.[Name],'''')) [Reservation Source Name]
        , MAX(TA.[Amadeus No_]) [Amadeus No_]
        , MAX(RL.[Process Number]) [Process Number]
        , MAX(CASE WHEN [Turnover (LCY) (corr_)]>0 AND RL.[Reservation Part No_] = 1 THEN 1 ELSE 0 END) [Realized Bookings]
        , AH.[Input Parameter 1 Code]   [Code P1],  P1.[Name]  [Name P1], P1.[Value Decimal]  [Value P1]
        , AH.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], P2.[Value Decimal]  [Value P2]
        , AH.[Input Parameter 3 Code]   [Code P3],  P3.[Name]  [Name P3], P3.[Value Decimal]  [Value P3]
        , AH.[Input Parameter 4 Code]   [Code P4],  P4.[Name]  [Name P4], P4.[Value Decimal]  [Value P4]
        , AH.[Input Parameter 5 Code]   [Code P5],  P5.[Name]  [Name P5], P5.[Value Decimal]  [Value P5]
        , AH.[Input Parameter 6 Code]   [Code P6],  P6.[Name]  [Name P6], P6.[Value Decimal]  [Value P6]
        , AH.[Input Parameter 7 Code]   [Code P7],  P7.[Name]  [Name P7], P7.[Value Decimal]  [Value P7]
        , AH.[Input Parameter 8 Code]   [Code P8],  P8.[Name]  [Name P8], P8.[Value Decimal]  [Value P8]
        , AH.[Input Parameter 9 Code]   [Code P9],  P9.[Name]  [Name P9], P9.[Value Decimal]  [Value P9]
        , AH.[Input Parameter 10 Code] [Code P10],  P10.[Name] [Name P10],P10.[Value Decimal] [Value P10]
        , AH.[Output Parameter Code]    [Code PA],  PA.[Name]  [Name PA], PA.[Value Decimal]  [Value PA]
		, dbo.fnc_RebateVectorSelection(AH.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
     FROM AgreementHeader               AH
     JOIN [hotel_de$Rebate Header]           RH WITH (NOLOCK)
       ON AH.[No_]                    = RH.[Rebate Agreement No_]
      AND RH.[Document Date]         >= AH.[Year Start Date] 
      AND RH.[Document Date]         <= AH.[Document Date]
     JOIN [hotel_de$Rebate Line]             RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [hotel_de$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
     JOIN @Parameter P1  ON P1.[No_]  = AH.[Input Parameter 1 Code] AND P1.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P2  ON P2.[No_]  = AH.[Input Parameter 2 Code] AND P2.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P3  ON P3.[No_]  = AH.[Input Parameter 3 Code] AND P3.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P4  ON P4.[No_]  = AH.[Input Parameter 4 Code] AND P4.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P5  ON P5.[No_]  = AH.[Input Parameter 5 Code] AND P5.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P6  ON P6.[No_]  = AH.[Input Parameter 6 Code] AND P6.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P7  ON P7.[No_]  = AH.[Input Parameter 7 Code] AND P7.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P8  ON P8.[No_]  = AH.[Input Parameter 8 Code] AND P8.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P9  ON P9.[No_]  = AH.[Input Parameter 9 Code] AND P9.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P10 ON P10.[No_] = AH.[Input Parameter 10 Code] AND P10.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter PA  ON PA.[No_]  = AH.[Output Parameter Code] AND PA.[Rebate No_] IN (RH.[No_],'''')
    WHERE RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5 ' + @ResultText + '
 GROUP BY RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] ,  P1.[Name] , P1.[Value Decimal]
        , AH.[Input Parameter 2 Code] ,  P2.[Name] , P2.[Value Decimal]
        , AH.[Input Parameter 3 Code] ,  P3.[Name] , P3.[Value Decimal]
        , AH.[Input Parameter 4 Code] ,  P4.[Name] , P4.[Value Decimal]
        , AH.[Input Parameter 5 Code] ,  P5.[Name] , P5.[Value Decimal]
        , AH.[Input Parameter 6 Code] ,  P6.[Name] , P6.[Value Decimal]
        , AH.[Input Parameter 7 Code] ,  P7.[Name] , P7.[Value Decimal]
        , AH.[Input Parameter 8 Code] ,  P8.[Name] , P8.[Value Decimal]
        , AH.[Input Parameter 9 Code] ,  P9.[Name] , P9.[Value Decimal]
        , AH.[Input Parameter 10 Code],  P10.[Name],P10.[Value Decimal]
        , AH.[Output Parameter Code]  ,  PA.[Name] , PA.[Value Decimal]
        , AH.[Matrix _ Vector Code]
UNION
   -- Aufgelöste Rückstellungen werden mit dem Buchungsdatum des Beleges gebucht, der die Rückstellung auflöst
   SELECT RH.[Interval Start Date]
        , RH.[Interval End Date]
        , MAX(RL.[Loyality Rewards Account 1 No_]) [Loyality Rewards Account 1 No_]
        , MAX(RL.[Loyality Rewards Account 2 No_]) [Loyality Rewards Account 2 No_]
        , MIN(RL.[Reservation Date])               [Reservation Date]
        , MIN(RL.[Arival Date])                    [Arival Date]
        , MAX(RL.[Post Affiliate Partner No_])     [Post Affiliate Partner No_]
        , SUM(RL.[Turnover Breakfast (LCY)])       [Turnover Breakfast (LCY)]
        , SUM(RL.[Turnover Breakfast (LCY) (c_)])  [Turnover Breakfast (LCY) (c_)]
        , SUM(RL.[Amount])                         [Amount]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover]' 
          ELSE 
            '[Turnover]' 
          END +') [Turnover]
        , SUM(RL.[Amount (corr_)])                 [Amount (corr_)]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover (corr_)]' 
          ELSE 
            '[Turnover (corr_)]' 
          END + ') [Turnover (corr_)]
        , MAX(RL.[Currency Faktor])                [Currency Faktor]
        , MAX(RL.[Currency Code])                  [Currency Code]
        , MAX(RL.[Currency Faktor (corr_)])        [Currency Faktor (corr_)]
        , MAX(RL.[Currency Code (corr_)])          [Currency Code (corr_)]
        , MAX(RL.[Document No_])                   [Document No_]
        , MAX(RL.[Line No_])                       [Line No_]
        , MAX(RL.[Type])                           [Type]
        , MAX(RL.[Rebate Amount Line])             [Rebate Amount Line]
        , MAX(RL.[No Print])                       [No Print]
        , MAX(RL.[No_])                            [No_]
        , MAX(RL.[Rebate Agreement No_])           [Rebate Agreement No_]
        , MAX(RL.[Posting Date (Import)])          [Posting Date (Import)]
        , MAX(RL.[Document Date (Import)])         [Document Date (Import)]
        , MAX(RL.[Description])                    [Description]
        , MAX(RL.[Description 2])                  [Description 2]
        , RL.[Reservation No_]
        , 0 [Reservation Part No_]
        , MAX(RL.[Value Type]) [Value Type]
        , MAX(RL.[Value]) [Value]
        , MAX(RL.[Value Text]) [Value Text]
        , MAX(RL.[Value Decimal]) [Value Decimal]
        , MAX(RL.[Value Boolean]) [Value Boolean]
        , MAX(RL.[Value Date]) [Value Date]
        , MAX(RL.[Invoice No_]) [Invoice No_]
        , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +') [Turnover (LCY)]
        , MAX(RL.[Commission Type]) [Commission Type]
        , MAX(RL.[Commission Rate %]) [Commission Rate %]
        , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ') [Turnover (LCY) (corr_)]
        , MAX(RL.[Commission Type (corr_)]) [Commission Type (corr_)]
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
        , MAX(COALESCE(BS.[Name],'''')) [Reservation Source Name]
        , MAX(TA.[Amadeus No_]) [Amadeus No_]
        , MAX(RL.[Process Number]) [Process Number]
        , MAX(CASE WHEN [Turnover (LCY) (corr_)]>0 AND RL.[Reservation Part No_] = 1 THEN 1 ELSE 0 END) [Realized Bookings]
        , AH.[Input Parameter 1 Code]   [Code P1],  P1.[Name]  [Name P1], P1.[Value Decimal]  [Value P1]
        , AH.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], P2.[Value Decimal]  [Value P2]
        , AH.[Input Parameter 3 Code]   [Code P3],  P3.[Name]  [Name P3], P3.[Value Decimal]  [Value P3]
        , AH.[Input Parameter 4 Code]   [Code P4],  P4.[Name]  [Name P4], P4.[Value Decimal]  [Value P4]
        , AH.[Input Parameter 5 Code]   [Code P5],  P5.[Name]  [Name P5], P5.[Value Decimal]  [Value P5]
        , AH.[Input Parameter 6 Code]   [Code P6],  P6.[Name]  [Name P6], P6.[Value Decimal]  [Value P6]
        , AH.[Input Parameter 7 Code]   [Code P7],  P7.[Name]  [Name P7], P7.[Value Decimal]  [Value P7]
        , AH.[Input Parameter 8 Code]   [Code P8],  P8.[Name]  [Name P8], P8.[Value Decimal]  [Value P8]
        , AH.[Input Parameter 9 Code]   [Code P9],  P9.[Name]  [Name P9], P9.[Value Decimal]  [Value P9]
        , AH.[Input Parameter 10 Code] [Code P10],  P10.[Name] [Name P10],P10.[Value Decimal] [Value P10]
        , AH.[Output Parameter Code]    [Code PA],  PA.[Name]  [Name PA], PA.[Value Decimal]  [Value PA]
		, dbo.fnc_RebateVectorSelection(AH.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
     FROM AgreementHeader               AH
     JOIN [hotel_de$Posted Rebate Header]    RH WITH (NOLOCK)
       ON AH.[No_]                    = RH.[Rebate Agreement No_]
--      AND RH.[Document Date]         >= DATEADD(yy,-1,AH.[Year Start Date] )
      AND RH.[Document Date]         <= AH.[Document Date]
     JOIN [hotel_de$Posted Rebate Line]      RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [hotel_de$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
     JOIN [hotel_de$G_L Entry]               GLE WITH (NOLOCK)
       ON GLE.[Document Date]          = AH.[Document Date]
      AND GLE.[Document No_]          = RH.[Rebate No_]
      AND GLE.[Source No_]            = AH.[Rebate-to Vendor No_]
      AND GLE.Amount         <> 0
     JOIN [hotel_de$Rebate Setup] RS WITH (NOLOCK)
       ON RS.[Account No_ Reserve]    = GLE.[G_L Account No_]    
	   OR GLE.[G_L Account No_]       IN (''472500'',''472000'')
     JOIN @Parameter P1  ON P1.[No_]  = AH.[Input Parameter 1 Code] AND P1.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P2  ON P2.[No_]  = AH.[Input Parameter 2 Code] AND P2.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P3  ON P3.[No_]  = AH.[Input Parameter 3 Code] AND P3.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P4  ON P4.[No_]  = AH.[Input Parameter 4 Code] AND P4.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P5  ON P5.[No_]  = AH.[Input Parameter 5 Code] AND P5.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P6  ON P6.[No_]  = AH.[Input Parameter 6 Code] AND P6.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P7  ON P7.[No_]  = AH.[Input Parameter 7 Code] AND P7.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P8  ON P8.[No_]  = AH.[Input Parameter 8 Code] AND P8.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P9  ON P9.[No_]  = AH.[Input Parameter 9 Code] AND P9.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P10 ON P10.[No_] = AH.[Input Parameter 10 Code] AND P10.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter PA  ON PA.[No_]  = AH.[Output Parameter Code] AND PA.[Rebate No_] IN (RH.[No_],'''')
    WHERE RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.[Cancels] = 0 ' + @ResultText + '
	  AND AH.[Posted] = 1
 GROUP BY RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] ,  P1.[Name] , P1.[Value Decimal]
        , AH.[Input Parameter 2 Code] ,  P2.[Name] , P2.[Value Decimal]
        , AH.[Input Parameter 3 Code] ,  P3.[Name] , P3.[Value Decimal]
        , AH.[Input Parameter 4 Code] ,  P4.[Name] , P4.[Value Decimal]
        , AH.[Input Parameter 5 Code] ,  P5.[Name] , P5.[Value Decimal]
        , AH.[Input Parameter 6 Code] ,  P6.[Name] , P6.[Value Decimal]
        , AH.[Input Parameter 7 Code] ,  P7.[Name] , P7.[Value Decimal]
        , AH.[Input Parameter 8 Code] ,  P8.[Name] , P8.[Value Decimal]
        , AH.[Input Parameter 9 Code] ,  P9.[Name] , P9.[Value Decimal]
        , AH.[Input Parameter 10 Code],  P10.[Name],P10.[Value Decimal]
        , AH.[Output Parameter Code]  ,  PA.[Name] , PA.[Value Decimal]
        , AH.[Matrix _ Vector Code]
UNION
   -- nicht aufgelöste Rückstellungen stehen in der Tabelle [hotel_de$Rebate Reserve Entry]
   SELECT RH.[Interval Start Date]
        , RH.[Interval End Date]
        , MAX(RL.[Loyality Rewards Account 1 No_]) [Loyality Rewards Account 1 No_]
        , MAX(RL.[Loyality Rewards Account 2 No_]) [Loyality Rewards Account 2 No_]
        , MIN(RL.[Reservation Date])               [Reservation Date]
        , MIN(RL.[Arival Date])                    [Arival Date]
        , MAX(RL.[Post Affiliate Partner No_])     [Post Affiliate Partner No_]
        , SUM(RL.[Turnover Breakfast (LCY)])       [Turnover Breakfast (LCY)]
        , SUM(RL.[Turnover Breakfast (LCY) (c_)])  [Turnover Breakfast (LCY) (c_)]
        , SUM(RL.[Amount])                         [Amount]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover]' 
          ELSE 
            '[Turnover]' 
          END +') [Turnover]
        , SUM(RL.[Amount (corr_)])                 [Amount (corr_)]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover (corr_)]' 
          ELSE 
            '[Turnover (corr_)]' 
          END + ') [Turnover (corr_)]
        , MAX(RL.[Currency Faktor])                [Currency Faktor]
        , MAX(RL.[Currency Code])                  [Currency Code]
        , MAX(RL.[Currency Faktor (corr_)])        [Currency Faktor (corr_)]
        , MAX(RL.[Currency Code (corr_)])          [Currency Code (corr_)]
        , MAX(RL.[Document No_])                   [Document No_]
        , MAX(RL.[Line No_])                       [Line No_]
        , MAX(RL.[Type])                           [Type]
        , MAX(RL.[Rebate Amount Line])             [Rebate Amount Line]
        , MAX(RL.[No Print])                       [No Print]
        , MAX(RL.[No_])                            [No_]
        , MAX(RL.[Rebate Agreement No_])           [Rebate Agreement No_]
        , MAX(RL.[Posting Date (Import)])          [Posting Date (Import)]
        , MAX(RL.[Document Date (Import)])         [Document Date (Import)]
        , MAX(RL.[Description])                    [Description]
        , MAX(RL.[Description 2])                  [Description 2]
        , RL.[Reservation No_]
        , 0 [Reservation Part No_]
        , MAX(RL.[Value Type]) [Value Type]
        , MAX(RL.[Value]) [Value]
        , MAX(RL.[Value Text]) [Value Text]
        , MAX(RL.[Value Decimal]) [Value Decimal]
        , MAX(RL.[Value Boolean]) [Value Boolean]
        , MAX(RL.[Value Date]) [Value Date]
        , MAX(RL.[Invoice No_]) [Invoice No_]
        , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +') [Turnover (LCY)]
        , MAX(RL.[Commission Type]) [Commission Type]
        , MAX(RL.[Commission Rate %]) [Commission Rate %]
        , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ') [Turnover (LCY) (corr_)]
        , MAX(RL.[Commission Type (corr_)]) [Commission Type (corr_)]
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
        , MAX(COALESCE(BS.[Name],'''')) [Reservation Source Name]
        , MAX(TA.[Amadeus No_]) [Amadeus No_]
        , MAX(RL.[Process Number]) [Process Number]
        , MAX(CASE WHEN [Turnover (LCY) (corr_)]>0 AND RL.[Reservation Part No_] = 1 THEN 1 ELSE 0 END) [Realized Bookings]
        , AH.[Input Parameter 1 Code]   [Code P1],  P1.[Name]  [Name P1], P1.[Value Decimal]  [Value P1]
        , AH.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], P2.[Value Decimal]  [Value P2]
        , AH.[Input Parameter 3 Code]   [Code P3],  P3.[Name]  [Name P3], P3.[Value Decimal]  [Value P3]
        , AH.[Input Parameter 4 Code]   [Code P4],  P4.[Name]  [Name P4], P4.[Value Decimal]  [Value P4]
        , AH.[Input Parameter 5 Code]   [Code P5],  P5.[Name]  [Name P5], P5.[Value Decimal]  [Value P5]
        , AH.[Input Parameter 6 Code]   [Code P6],  P6.[Name]  [Name P6], P6.[Value Decimal]  [Value P6]
        , AH.[Input Parameter 7 Code]   [Code P7],  P7.[Name]  [Name P7], P7.[Value Decimal]  [Value P7]
        , AH.[Input Parameter 8 Code]   [Code P8],  P8.[Name]  [Name P8], P8.[Value Decimal]  [Value P8]
        , AH.[Input Parameter 9 Code]   [Code P9],  P9.[Name]  [Name P9], P9.[Value Decimal]  [Value P9]
        , AH.[Input Parameter 10 Code] [Code P10],  P10.[Name] [Name P10],P10.[Value Decimal] [Value P10]
        , AH.[Output Parameter Code]    [Code PA],  PA.[Name]  [Name PA], PA.[Value Decimal]  [Value PA]
		, dbo.fnc_RebateVectorSelection(AH.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
     FROM AgreementHeader               AH
     JOIN [hotel_de$Posted Rebate Header]    RH WITH (NOLOCK)
       ON AH.[No_]                    = RH.[Rebate Agreement No_]
      AND RH.[Document Date]         <= AH.[Document Date]
     JOIN [hotel_de$Posted Rebate Line]      RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [hotel_de$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
     JOIN [hotel_de$G_L Entry]               GLE WITH (NOLOCK)
       ON GLE.[Document No_]          = RH.[Rebate No_]
      AND GLE.[Source No_]            = AH.[Rebate-to Vendor No_]
      AND GLE.Amount         <> 0
     JOIN [hotel_de$Rebate Setup] RS WITH (NOLOCK)
       ON RS.[Account No_ Reserve]    = GLE.[G_L Account No_]    
	   OR GLE.[G_L Account No_]       IN (''472500'',''472000'')
     JOIN [hotel_de$Rebate Reserve Entry] RE WITH (NOLOCK)
       ON RE.[Document No_]           = RH.[Rebate No_]
     JOIN @Parameter P1  ON P1.[No_]  = AH.[Input Parameter 1 Code] AND P1.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P2  ON P2.[No_]  = AH.[Input Parameter 2 Code] AND P2.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P3  ON P3.[No_]  = AH.[Input Parameter 3 Code] AND P3.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P4  ON P4.[No_]  = AH.[Input Parameter 4 Code] AND P4.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P5  ON P5.[No_]  = AH.[Input Parameter 5 Code] AND P5.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P6  ON P6.[No_]  = AH.[Input Parameter 6 Code] AND P6.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P7  ON P7.[No_]  = AH.[Input Parameter 7 Code] AND P7.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P8  ON P8.[No_]  = AH.[Input Parameter 8 Code] AND P8.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P9  ON P9.[No_]  = AH.[Input Parameter 9 Code] AND P9.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P10 ON P10.[No_] = AH.[Input Parameter 10 Code] AND P10.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter PA  ON PA.[No_]  = AH.[Output Parameter Code] AND PA.[Rebate No_] IN (RH.[No_],'''')
    WHERE RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.[Cancels] = 0 ' + @ResultText + '
	  AND AH.[Posted] = 0
 GROUP BY RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] ,  P1.[Name] , P1.[Value Decimal]
        , AH.[Input Parameter 2 Code] ,  P2.[Name] , P2.[Value Decimal]
        , AH.[Input Parameter 3 Code] ,  P3.[Name] , P3.[Value Decimal]
        , AH.[Input Parameter 4 Code] ,  P4.[Name] , P4.[Value Decimal]
        , AH.[Input Parameter 5 Code] ,  P5.[Name] , P5.[Value Decimal]
        , AH.[Input Parameter 6 Code] ,  P6.[Name] , P6.[Value Decimal]
        , AH.[Input Parameter 7 Code] ,  P7.[Name] , P7.[Value Decimal]
        , AH.[Input Parameter 8 Code] ,  P8.[Name] , P8.[Value Decimal]
        , AH.[Input Parameter 9 Code] ,  P9.[Name] , P9.[Value Decimal]
        , AH.[Input Parameter 10 Code],  P10.[Name],P10.[Value Decimal]
        , AH.[Output Parameter Code]  ,  PA.[Name] , PA.[Value Decimal]
        , AH.[Matrix _ Vector Code]
UNION
   SELECT RH.[Interval Start Date]
        , RH.[Interval End Date]
        , MAX(RL.[Loyality Rewards Account 1 No_]) [Loyality Rewards Account 1 No_]
        , MAX(RL.[Loyality Rewards Account 2 No_]) [Loyality Rewards Account 2 No_]
        , MIN(RL.[Reservation Date])               [Reservation Date]
        , MIN(RL.[Arival Date])                    [Arival Date]
        , MAX(RL.[Post Affiliate Partner No_])     [Post Affiliate Partner No_]
        , SUM(RL.[Turnover Breakfast (LCY)])       [Turnover Breakfast (LCY)]
        , SUM(RL.[Turnover Breakfast (LCY) (c_)])  [Turnover Breakfast (LCY) (c_)]
        , SUM(RL.[Amount])                         [Amount]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover]' 
          ELSE 
            '[Turnover]' 
          END +') [Turnover]
        , SUM(RL.[Amount (corr_)])                 [Amount (corr_)]
        , SUM(RL.' 
        + CASE WHEN @PrintNet=1 THEN 
            '[Net Turnover (corr_)]' 
          ELSE 
            '[Turnover (corr_)]' 
          END + ') [Turnover (corr_)]
        , MAX(RL.[Currency Faktor])                [Currency Faktor]
        , MAX(RL.[Currency Code])                  [Currency Code]
        , MAX(RL.[Currency Faktor (corr_)])        [Currency Faktor (corr_)]
        , MAX(RL.[Currency Code (corr_)])          [Currency Code (corr_)]
        , MAX(RL.[Document No_])                   [Document No_]
        , MAX(RL.[Line No_])                       [Line No_]
        , MAX(RL.[Type])                           [Type]
        , MAX(RL.[Rebate Amount Line])             [Rebate Amount Line]
        , MAX(RL.[No Print])                       [No Print]
        , MAX(RL.[No_])                            [No_]
        , MAX(RL.[Rebate Agreement No_])           [Rebate Agreement No_]
        , MAX(RL.[Posting Date (Import)])          [Posting Date (Import)]
        , MAX(RL.[Document Date (Import)])         [Document Date (Import)]
        , MAX(RL.[Description])                    [Description]
        , MAX(RL.[Description 2])                  [Description 2]
        , RL.[Reservation No_]
        , 0 [Reservation Part No_]
        , MAX(RL.[Value Type]) [Value Type]
        , MAX(RL.[Value]) [Value]
        , MAX(RL.[Value Text]) [Value Text]
        , MAX(RL.[Value Decimal]) [Value Decimal]
        , MAX(RL.[Value Boolean]) [Value Boolean]
        , MAX(RL.[Value Date]) [Value Date]
        , MAX(RL.[Invoice No_]) [Invoice No_]
        , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY)]' ELSE '[Turnover (LCY)]' END +') [Turnover (LCY)]
        , MAX(RL.[Commission Type]) [Commission Type]
        , MAX(RL.[Commission Rate %]) [Commission Rate %]
        , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
        , SUM(RL.' + CASE WHEN @PrintNet=1 THEN '[Net Turnover (LCY) (corr_)]' ELSE '[Turnover (LCY) (corr_)]' END + ') [Turnover (LCY) (corr_)]
        , MAX(RL.[Commission Type (corr_)]) [Commission Type (corr_)]
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
        , MAX(COALESCE(BS.[Name],'''')) [Reservation Source Name]
        , MAX(TA.[Amadeus No_]) [Amadeus No_]
        , MAX(RL.[Process Number]) [Process Number]
        , MAX(CASE WHEN [Turnover (LCY) (corr_)]>0 AND RL.[Reservation Part No_] = 1 THEN 1 ELSE 0 END) [Realized Bookings]
        , AH.[Input Parameter 1 Code]   [Code P1],  P1.[Name]  [Name P1], P1.[Value Decimal]  [Value P1]
        , AH.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], P2.[Value Decimal]  [Value P2]
        , AH.[Input Parameter 3 Code]   [Code P3],  P3.[Name]  [Name P3], P3.[Value Decimal]  [Value P3]
        , AH.[Input Parameter 4 Code]   [Code P4],  P4.[Name]  [Name P4], P4.[Value Decimal]  [Value P4]
        , AH.[Input Parameter 5 Code]   [Code P5],  P5.[Name]  [Name P5], P5.[Value Decimal]  [Value P5]
        , AH.[Input Parameter 6 Code]   [Code P6],  P6.[Name]  [Name P6], P6.[Value Decimal]  [Value P6]
        , AH.[Input Parameter 7 Code]   [Code P7],  P7.[Name]  [Name P7], P7.[Value Decimal]  [Value P7]
        , AH.[Input Parameter 8 Code]   [Code P8],  P8.[Name]  [Name P8], P8.[Value Decimal]  [Value P8]
        , AH.[Input Parameter 9 Code]   [Code P9],  P9.[Name]  [Name P9], P9.[Value Decimal]  [Value P9]
        , AH.[Input Parameter 10 Code] [Code P10],  P10.[Name] [Name P10],P10.[Value Decimal] [Value P10]
        , AH.[Output Parameter Code]    [Code PA],  PA.[Name]  [Name PA], PA.[Value Decimal]  [Value PA]
		, dbo.fnc_RebateVectorSelection(AH.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
     FROM AgreementHeader               AH
     JOIN [hotel_de$Posted Rebate Header]    RH WITH (NOLOCK)
       ON AH.[Rebate No_]             = RH.[Rebate No_]
     JOIN [hotel_de$Posted Rebate Line]      RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [hotel_de$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
     JOIN @Parameter P1  ON P1.[No_]  = AH.[Input Parameter 1 Code] AND P1.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P2  ON P2.[No_]  = AH.[Input Parameter 2 Code] AND P2.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P3  ON P3.[No_]  = AH.[Input Parameter 3 Code] AND P3.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P4  ON P4.[No_]  = AH.[Input Parameter 4 Code] AND P4.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P5  ON P5.[No_]  = AH.[Input Parameter 5 Code] AND P5.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P6  ON P6.[No_]  = AH.[Input Parameter 6 Code] AND P6.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P7  ON P7.[No_]  = AH.[Input Parameter 7 Code] AND P7.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P8  ON P8.[No_]  = AH.[Input Parameter 8 Code] AND P8.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P9  ON P9.[No_]  = AH.[Input Parameter 9 Code] AND P9.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter P10 ON P10.[No_] = AH.[Input Parameter 10 Code] AND P10.[Rebate No_] IN (RH.[No_],'''')
     JOIN @Parameter PA  ON PA.[No_]  = AH.[Output Parameter Code] AND PA.[Rebate No_] IN (RH.[No_],'''')
LEFT JOIN [hotel_de$Rebate Reserve Entry] RE WITH (NOLOCK)
       ON RE.[Document No_]           = RH.[Rebate No_]
    WHERE RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5 ' + @ResultText + '
	  AND RE.[Document No_] IS NULL
 GROUP BY RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] ,  P1.[Name] , P1.[Value Decimal]
        , AH.[Input Parameter 2 Code] ,  P2.[Name] , P2.[Value Decimal]
        , AH.[Input Parameter 3 Code] ,  P3.[Name] , P3.[Value Decimal]
        , AH.[Input Parameter 4 Code] ,  P4.[Name] , P4.[Value Decimal]
        , AH.[Input Parameter 5 Code] ,  P5.[Name] , P5.[Value Decimal]
        , AH.[Input Parameter 6 Code] ,  P6.[Name] , P6.[Value Decimal]
        , AH.[Input Parameter 7 Code] ,  P7.[Name] , P7.[Value Decimal]
        , AH.[Input Parameter 8 Code] ,  P8.[Name] , P8.[Value Decimal]
        , AH.[Input Parameter 9 Code] ,  P9.[Name] , P9.[Value Decimal]
        , AH.[Input Parameter 10 Code],  P10.[Name],P10.[Value Decimal]
        , AH.[Output Parameter Code]  ,  PA.[Name] , PA.[Value Decimal]
        , AH.[Matrix _ Vector Code]
)
SELECT * FROM _TOTAL ORDER BY [Reservation No_]
'   

PRINT SUBSTRING(@SQL,1,8000)
PRINT SUBSTRING(@SQL,8001,8000)
PRINT SUBSTRING(@SQL,16001,8000)
PRINT SUBSTRING(@SQL,24001,8000)
PRINT SUBSTRING(@SQL,32001,8000)
PRINT SUBSTRING(@SQL,40001,8000)
EXEC(@SQL) 
END
GO
