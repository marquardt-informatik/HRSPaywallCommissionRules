USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateBookings]    Script Date: 10.04.2024 14:31:42 ******/
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
EXEC [dbo].[sp_RebateBookings] '0000020830/02'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateBookings] 
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
   FROM [HRS$Rebate Header]    RH WITH (NOLOCK)
   JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
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
   FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
   JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
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
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[Rebate No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo

)
INSERT INTO @AP
SELECT AV.[Affiliate Partner No_], AH.[No_]
  FROM [HRS$Affiliate Partner Vendor] AV WITH (NOLOCK)
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
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
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
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
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
--CREATE TABLE #Parameter
--(
--    [Rebate No_]    VARCHAR(20) COLLATE Latin1_General_CS_AS NOT NULL
--  , [No_]           VARCHAR(20) COLLATE Latin1_General_CS_AS NOT NULL
--  , [Value Decimal] DEC(37,20)
--  , [Name]          VARCHAR(120) COLLATE Latin1_General_CS_AS
--)
--ALTER TABLE #Parameter ADD PRIMARY KEY NONCLUSTERED ([Rebate No_],[No_])

;WITH AgreementHeader AS
(
SELECT AH.*, 0 [Posted]
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + '''
UNION 
SELECT AH.*, 1 [Posted]
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + ''' OR RH.[Rebate No_] = ''' + @RebateNo + '''
),  RL AS
(
  SELECT RH.[No_] [Rebate No_], RL.[No_], RL.[Value Decimal], PA.[Name]
    FROM [HRS$Rebate Line]   RL WITH (NOLOCK) 
    JOIN [HRS$Rebate Header] RH WITH (NOLOCK) 
      ON RL.[Document No_] = RH.[No_]
    JOIN [HRS$Parameter]     PA WITH (NOLOCK)
      ON PA.[Code]  = RL.[No_]
    JOIN AgreementHeader     AH 
      ON AH.[No_] = RH.[Rebate Agreement No_]
   WHERE RL.[Type] IN (1,2)
UNION   
  SELECT RH.[No_], RL.[No_], RL.[Value Decimal], PA.[Name]
    FROM [HRS$Posted Rebate Line]   RL WITH (NOLOCK) 
    JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK) 
      ON RL.[Document No_] = RH.[No_]
    JOIN [HRS$Parameter]     PA WITH (NOLOCK)
      ON PA.[Code]  = RL.[No_]
    JOIN AgreementHeader     AH 
      ON AH.[No_] = RH.[Rebate Agreement No_]
   WHERE RL.[Type] IN (1,2)
)
INSERT INTO @Parameter
--INSERT INTO #Parameter
SELECT * FROM RL

INSERT INTO @Parameter
--INSERT INTO #Parameter
SELECT '''','''',0.0,'''' UNION
SELECT '''',PA.[Code], PA.[Value Decimal], PA.[Name]
  FROM [HRS$Parameter] PA WITH (NOLOCK)
 WHERE '',' + @ParameterList + ','' LIKE ''%,'' + PA.[Code] + '',%''
   AND NOT PA.[Code] IN (SELECT [No_] FROM @Parameter)
   --AND NOT PA.[Code] IN (SELECT [No_] FROM #Parameter)

DECLARE @Result TABLE
(
          [Rebate No_] varchar(20)
        , [Interval Start Date] date
        , [Interval End Date] date
        , [Loyality Rewards Account 1 No_] varchar(100)
        , [Loyality Rewards Account 2 No_] varchar(100)
        , [Reservation Date] date
        , [Arival Date] date
        , [Post Affiliate Partner No_] varchar(100)
        , [Turnover Breakfast (LCY)] decimal(37,10)
        , [Turnover Breakfast (LCY) (c_)] decimal(37,10)
        , [Amount] decimal(37,10)
        , [Turnover] decimal(37,10)
        , [Amount (corr_)] decimal(37,10)
        , [Turnover (corr_)] decimal(37,10)
        , [Currency Faktor] decimal(37,10)
        , [Currency Code] varchar(10)
        , [Currency Faktor (corr_)] decimal(37,10)
        , [Currency Code (corr_)] varchar(10)
        , [Document No_] varchar(20)
        , [Line No_] int
        , [Type] varchar(20)
        , [Rebate Amount Line] decimal(37,10)
        , [No Print] varchar(20)
        , [No_] varchar(20)
        , [Rebate Agreement No_] varchar(20)
        , [Posting Date (Import)] date
        , [Document Date (Import)] date
        , [Description] varchar(100)
        , [Description 2] varchar(100)
        , [Reservation No_] varchar(20)
        , [Reservation Part No_] varchar(20)
        , [Value Type] int
        , [Value] varchar(250)
        , [Value Text] varchar(250)
        , [Value Decimal] decimal(37,10)
        , [Value Boolean] tinyint
        , [Value Date] date
        , [Invoice No_] varchar(20)
        , [Amount (LCY)] decimal(37,10)
        , [Turnover (LCY)] decimal(37,10)
        , [Commission Type] varchar(100)
        , [Commission Rate %] decimal(37,10)
        , [Amount (LCY) (corr_)] decimal(37,10)
        , [Turnover (LCY) (corr_)] decimal(37,10)
        , [Commission Type (corr_)] varchar(100)
        , [Commission Rate % (corr_)] decimal(37,10)
        , [Departure Date] date
        , [Affiliate Partner No_] varchar(100)
        , [Hotel No_] varchar(20)
        , [Room Nights] decimal(37,10)
        , [Is Net Rate] tinyint
        , [Room Nights Post Corection] decimal(37,10)
        , [Is Net Rate Post Corection] tinyint
        , [Max Entry No_] int
        , [Is No Show] tinyint
        , [Top Bonus ID] varchar(100)
        , [MuseID] varchar(20)
        , [Correction Kennung] tinyint
        , [Company Name] varchar(30)
        , [Customer No_] varchar(20)
        , [Country Code] varchar(20)
        , [Chain] varchar(10)
        , [Brand] varchar(10)
        , [Rebate-to Vendor No_] varchar(20)
        , [Handbooking] tinyint
        , [Reservation Source] varchar(20)
        , [Reservation Source Name] varchar(100)
        , [Amadeus No_] varchar(20)
        , [Process Number] int
        , [Realized Bookings] tinyint
        , [Code P1] varchar(20)
		, [Name P1] varchar(100)
		, [Value P1] decimal(37,10)
        , [Code P2] varchar(20)
		, [Name P2] varchar(100)
		, [Value P2] decimal(37,10)
        , [Code P3] varchar(20)
		, [Name P3] varchar(100)
		, [Value P3] decimal(37,10)
        , [Code P4] varchar(20)
		, [Name P4] varchar(100)
		, [Value P4] decimal(37,10)
        , [Code P5] varchar(20)
		, [Name P5] varchar(100)
		, [Value P5] decimal(37,10)
        , [Code P6] varchar(20)
		, [Name P6] varchar(100)
		, [Value P6] decimal(37,10)
        , [Code P7] varchar(20)
		, [Name P7] varchar(100)
		, [Value P7] decimal(37,10)
        , [Code P8] varchar(20)
		, [Name P8] varchar(100)
		, [Value P8] decimal(37,10)
        , [Code P9] varchar(20)
		, [Name P9] varchar(100)
		, [Value P9] decimal(37,10)
        , [Code P10] varchar(20)
		, [Name P10] varchar(100)
		, [Value P10] decimal(37,10)
        , [Code PA] varchar(20)
		, [Name PA] varchar(100)
		, [Value PA] decimal(37,10)
        , [Matrix _ Vector Code] varchar(20)
		, [Vector Range] varchar(250)
)
   
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
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
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
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = ''' + @RebateNo + ''' 
    OR RH.[Rebate No_] = ''' + @RebateNo + '''    
), _TOTAL AS
(
   SELECT RH.[No_] [Rebate No_]
        , RH.[Interval Start Date]
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
		, AH.[Input Parameter 1 Code] [Code P1]
		, '''' [Name P1]
		, 0.0 [Value P1]
		, AH.[Input Parameter 2 Code] [Code P2]
		, '''' [Name P2]
		, 0.0 [Value P2]
		, AH.[Input Parameter 3 Code] [Code P3]
		, '''' [Name P3]
		, 0.0 [Value P3]
		, AH.[Input Parameter 4 Code] [Code P4]
		, '''' [Name P4]
		, 0.0 [Value P4]
		, AH.[Input Parameter 5 Code] [Code P5]
		, '''' [Name P5]
		, 0.0 [Value P5]
		, AH.[Input Parameter 6 Code] [Code P6]
		, '''' [Name P6]
		, 0.0 [Value P6]
		, AH.[Input Parameter 7 Code] [Code P7]
		, '''' [Name P7]
		, 0.0 [Value P7]
		, AH.[Input Parameter 8 Code] [Code P8]
		, '''' [Name P8]
		, 0.0 [Value P8]
		, AH.[Input Parameter 9 Code] [Code P9]
		, '''' [Name P9]
		, 0.0 [Value P9]
		, AH.[Input Parameter 10 Code] [Code P10]
		, '''' [Name P10]
		, 0.0 [Value P10]
		, AH.[Output Parameter Code] [Code PA]
		, '''' [Name PA]
		, 0.0 [Value PA]
		, '''' [Vector Range]
		, AH.[Matrix _ Vector Code] [Matrix _ Vector Code]
     FROM AgreementHeader               AH
     JOIN [HRS$Rebate Header]           RH WITH (NOLOCK)
       ON AH.[No_]                    = RH.[Rebate Agreement No_]
      AND RH.[Document Date]         >= AH.[Year Start Date] 
      AND RH.[Document Date]         <= AH.[Document Date]
     JOIN [HRS$Rebate Line]             RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
    WHERE RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5 ' + @ResultText + '
 GROUP BY RH.[No_]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] 
        , AH.[Input Parameter 2 Code] 
        , AH.[Input Parameter 3 Code] 
        , AH.[Input Parameter 4 Code] 
        , AH.[Input Parameter 5 Code] 
        , AH.[Input Parameter 6 Code] 
        , AH.[Input Parameter 7 Code] 
        , AH.[Input Parameter 8 Code] 
        , AH.[Input Parameter 9 Code] 
        , AH.[Input Parameter 10 Code]
        , AH.[Output Parameter Code]  
        , AH.[Matrix _ Vector Code]
UNION
   -- Aufgelöste Rückstellungen werden mit dem Buchungsdatum des Beleges gebucht, der die Rückstellung auflöst
   SELECT RH.[No_] [Rebate No_]
        , RH.[Interval Start Date]
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
        , MAX(BU.H_KEY) [Hotel No_]
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
		, AH.[Input Parameter 1 Code] [Code P1]
		, '''' [Name P1]
		, 0.0 [Value P1]
		, AH.[Input Parameter 2 Code] [Code P2]
		, '''' [Name P2]
		, 0.0 [Value P2]
		, AH.[Input Parameter 3 Code] [Code P3]
		, '''' [Name P3]
		, 0.0 [Value P3]
		, AH.[Input Parameter 4 Code] [Code P4]
		, '''' [Name P4]
		, 0.0 [Value P4]
		, AH.[Input Parameter 5 Code] [Code P5]
		, '''' [Name P5]
		, 0.0 [Value P5]
		, AH.[Input Parameter 6 Code] [Code P6]
		, '''' [Name P6]
		, 0.0 [Value P6]
		, AH.[Input Parameter 7 Code] [Code P7]
		, '''' [Name P7]
		, 0.0 [Value P7]
		, AH.[Input Parameter 8 Code] [Code P8]
		, '''' [Name P8]
		, 0.0 [Value P8]
		, AH.[Input Parameter 9 Code] [Code P9]
		, '''' [Name P9]
		, 0.0 [Value P9]
		, AH.[Input Parameter 10 Code] [Code P10]
		, '''' [Name P10]
		, 0.0 [Value P10]
		, AH.[Output Parameter Code] [Code PA]
		, '''' [Name PA]
		, 0.0 [Value PA]
		, '''' [Vector Range]
		, AH.[Matrix _ Vector Code] [Matrix _ Vector Code]
     FROM AgreementHeader               AH
     JOIN [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
       ON AH.[No_]                    = RH.[Rebate Agreement No_]
--      AND RH.[Document Date]         >= DATEADD(yy,-1,AH.[Year Start Date] )
      AND RH.[Document Date]         <= AH.[Document Date]
     JOIN [HRS$Posted Rebate Line]      RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = RL.[Reservation No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
     JOIN [HRS$G_L Entry]               GLE WITH (NOLOCK)
       ON GLE.[Document Date]          = AH.[Document Date]
      AND GLE.[Document No_]          = RH.[Rebate No_]
      AND GLE.[Source No_]            = AH.[Rebate-to Vendor No_]
      AND GLE.Amount         <> 0
     JOIN [HRS$Rebate Setup] RS WITH (NOLOCK)
       ON RS.[Account No_ Reserve]    = GLE.[G_L Account No_]    
	   OR GLE.[G_L Account No_]       IN (''472500'',''472000'')
    WHERE RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.[Cancels] = 0 ' + @ResultText + '
	  AND AH.[Posted] = 1
 GROUP BY RH.[No_]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] 
        , AH.[Input Parameter 2 Code] 
        , AH.[Input Parameter 3 Code] 
        , AH.[Input Parameter 4 Code] 
        , AH.[Input Parameter 5 Code] 
        , AH.[Input Parameter 6 Code] 
        , AH.[Input Parameter 7 Code] 
        , AH.[Input Parameter 8 Code] 
        , AH.[Input Parameter 9 Code] 
        , AH.[Input Parameter 10 Code]
        , AH.[Output Parameter Code]  
        , AH.[Matrix _ Vector Code]
UNION
   -- nicht aufgelöste Rückstellungen stehen in der Tabelle [HRS$Rebate Reserve Entry]
   SELECT RH.[No_] [Rebate No_]
        , RH.[Interval Start Date]
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
        , MAX(BU.H_KEY) [Hotel No_]
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
		, AH.[Input Parameter 1 Code] [Code P1]
		, '''' [Name P1]
		, 0.0 [Value P1]
		, AH.[Input Parameter 2 Code] [Code P2]
		, '''' [Name P2]
		, 0.0 [Value P2]
		, AH.[Input Parameter 3 Code] [Code P3]
		, '''' [Name P3]
		, 0.0 [Value P3]
		, AH.[Input Parameter 4 Code] [Code P4]
		, '''' [Name P4]
		, 0.0 [Value P4]
		, AH.[Input Parameter 5 Code] [Code P5]
		, '''' [Name P5]
		, 0.0 [Value P5]
		, AH.[Input Parameter 6 Code] [Code P6]
		, '''' [Name P6]
		, 0.0 [Value P6]
		, AH.[Input Parameter 7 Code] [Code P7]
		, '''' [Name P7]
		, 0.0 [Value P7]
		, AH.[Input Parameter 8 Code] [Code P8]
		, '''' [Name P8]
		, 0.0 [Value P8]
		, AH.[Input Parameter 9 Code] [Code P9]
		, '''' [Name P9]
		, 0.0 [Value P9]
		, AH.[Input Parameter 10 Code] [Code P10]
		, '''' [Name P10]
		, 0.0 [Value P10]
		, AH.[Output Parameter Code] [Code PA]
		, '''' [Name PA]
		, 0.0 [Value PA]
		, '''' [Vector Range]
		, AH.[Matrix _ Vector Code] [Matrix _ Vector Code]
     FROM AgreementHeader               AH
     JOIN [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
       ON AH.[No_]                    = RH.[Rebate Agreement No_]
      AND RH.[Document Date]         <= AH.[Document Date]
     JOIN [HRS$Posted Rebate Line]      RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = RL.[Reservation No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
     JOIN [HRS$G_L Entry]               GLE WITH (NOLOCK)
       ON GLE.[Document No_]          = RH.[Rebate No_]
      AND GLE.[Source No_]            = AH.[Rebate-to Vendor No_]
      AND GLE.Amount         <> 0
     JOIN [HRS$Rebate Setup] RS WITH (NOLOCK)
       ON RS.[Account No_ Reserve]    = GLE.[G_L Account No_]    
	   OR GLE.[G_L Account No_]       IN (''472500'',''472000'')
     JOIN [HRS$Rebate Reserve Entry] RE WITH (NOLOCK)
       ON RE.[Document No_]           = RH.[Rebate No_]
    WHERE RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5
      AND RH.[Cancels] = 0 ' + @ResultText + '
	  AND AH.[Posted] = 0
 GROUP BY RH.[No_]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] 
        , AH.[Input Parameter 2 Code] 
        , AH.[Input Parameter 3 Code] 
        , AH.[Input Parameter 4 Code] 
        , AH.[Input Parameter 5 Code] 
        , AH.[Input Parameter 6 Code] 
        , AH.[Input Parameter 7 Code] 
        , AH.[Input Parameter 8 Code] 
        , AH.[Input Parameter 9 Code] 
        , AH.[Input Parameter 10 Code]
        , AH.[Output Parameter Code]  
        , AH.[Matrix _ Vector Code]
UNION
   SELECT RH.[No_] [Rebate No_]
        , RH.[Interval Start Date]
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
        , MAX(BU.H_KEY) [Hotel No_]
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
		, AH.[Input Parameter 1 Code] [Code P1]
		, '''' [Name P1]
		, 0.0 [Value P1]
		, AH.[Input Parameter 2 Code] [Code P2]
		, '''' [Name P2]
		, 0.0 [Value P2]
		, AH.[Input Parameter 3 Code] [Code P3]
		, '''' [Name P3]
		, 0.0 [Value P3]
		, AH.[Input Parameter 4 Code] [Code P4]
		, '''' [Name P4]
		, 0.0 [Value P4]
		, AH.[Input Parameter 5 Code] [Code P5]
		, '''' [Name P5]
		, 0.0 [Value P5]
		, AH.[Input Parameter 6 Code] [Code P6]
		, '''' [Name P6]
		, 0.0 [Value P6]
		, AH.[Input Parameter 7 Code] [Code P7]
		, '''' [Name P7]
		, 0.0 [Value P7]
		, AH.[Input Parameter 8 Code] [Code P8]
		, '''' [Name P8]
		, 0.0 [Value P8]
		, AH.[Input Parameter 9 Code] [Code P9]
		, '''' [Name P9]
		, 0.0 [Value P9]
		, AH.[Input Parameter 10 Code] [Code P10]
		, '''' [Name P10]
		, 0.0 [Value P10]
		, AH.[Output Parameter Code] [Code PA]
		, '''' [Name PA]
		, 0.0 [Value PA]
		, '''' [Vector Range]
		, AH.[Matrix _ Vector Code] [Matrix _ Vector Code]
     FROM AgreementHeader               AH
     JOIN [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
       ON AH.[Rebate No_]             = RH.[Rebate No_]
     JOIN [HRS$Posted Rebate Line]      RL WITH (NOLOCK)
       ON RL.[Document No_]           = RH.[No_]
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK)
       ON BU.B_KEY = RL.[Reservation No_]
     JOIN [Travelagency]                TA WITH (NOLOCK)
       ON TA.[No_]                    = RL.[Travelagency No_]
LEFT JOIN [HRS$Booking Source]          BS WITH (NOLOCK)
       ON BS.[No_]                    = RL.[Reservation Source]
LEFT JOIN [HRS$Rebate Reserve Entry] RE WITH (NOLOCK)
       ON RE.[Document No_]           = RH.[Rebate No_]
    WHERE RH.[Document Date] BETWEEN AH.[Year Start Date] AND AH.[Document Date]
      AND RL.[Eligible RevShare] = 0
      AND RL.[Type] = 5 ' + @ResultText + '
	  AND RE.[Document No_] IS NULL
 GROUP BY RH.[No_]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RL.[Reservation No_]
        , AH.[Input Parameter 1 Code] 
        , AH.[Input Parameter 2 Code] 
        , AH.[Input Parameter 3 Code] 
        , AH.[Input Parameter 4 Code] 
        , AH.[Input Parameter 5 Code] 
        , AH.[Input Parameter 6 Code] 
        , AH.[Input Parameter 7 Code] 
        , AH.[Input Parameter 8 Code] 
        , AH.[Input Parameter 9 Code] 
        , AH.[Input Parameter 10 Code]
        , AH.[Output Parameter Code]  
        , AH.[Matrix _ Vector Code]
)
INSERT INTO @Result (
          [Rebate No_]
        , [Interval Start Date] 
        , [Interval End Date] 
        , [Loyality Rewards Account 1 No_]
        , [Loyality Rewards Account 2 No_] 
        , [Reservation Date] 
        , [Arival Date] 
        , [Post Affiliate Partner No_]
        , [Turnover Breakfast (LCY)] 
        , [Turnover Breakfast (LCY) (c_)] 
        , [Amount] 
        , [Turnover] 
        , [Amount (corr_)] 
        , [Turnover (corr_)] 
        , [Currency Faktor]
        , [Currency Code] 
        , [Currency Faktor (corr_)] 
        , [Currency Code (corr_)] 
        , [Document No_]
        , [Line No_] 
        , [Type] 
        , [Rebate Amount Line] 
        , [No Print] 
        , [No_] 
        , [Rebate Agreement No_]
        , [Posting Date (Import)] 
        , [Document Date (Import)] 
        , [Description] 
        , [Description 2] 
        , [Reservation No_] 
        , [Reservation Part No_] 
        , [Value Type] 
        , [Value]
        , [Value Text] 
        , [Value Decimal] 
        , [Value Boolean] 
        , [Value Date] 
        , [Invoice No_] 
        , [Amount (LCY)] 
        , [Turnover (LCY)] 
        , [Commission Type] 
        , [Commission Rate %] 
        , [Amount (LCY) (corr_)] 
        , [Turnover (LCY) (corr_)] 
        , [Commission Type (corr_)] 
        , [Commission Rate % (corr_)] 
        , [Departure Date] 
        , [Affiliate Partner No_] 
        , [Hotel No_] 
        , [Room Nights] 
        , [Is Net Rate] 
        , [Room Nights Post Corection] 
        , [Is Net Rate Post Corection] 
        , [Max Entry No_] 
        , [Is No Show] 
        , [Top Bonus ID] 
        , [MuseID] 
        , [Correction Kennung] 
        , [Company Name] 
        , [Customer No_] 
        , [Country Code] 
        , [Chain] 
        , [Brand] 
        , [Rebate-to Vendor No_]
        , [Handbooking] 
        , [Reservation Source] 
        , [Reservation Source Name] 
        , [Amadeus No_] 
        , [Process Number] 
        , [Realized Bookings] 
		, [Code P1]
		, [Code P2]
		, [Code P3]
		, [Code P4]
		, [Code P5]
		, [Code P6]
		, [Code P7]
		, [Code P8]
		, [Code P9]
		, [Code P10]
		, [Code PA]
		, [Matrix _ Vector Code]
)
SELECT    [Rebate No_]
        , [Interval Start Date] 
        , [Interval End Date] 
        , [Loyality Rewards Account 1 No_]
        , [Loyality Rewards Account 2 No_] 
        , [Reservation Date] 
        , [Arival Date] 
        , [Post Affiliate Partner No_]
        , [Turnover Breakfast (LCY)] 
        , [Turnover Breakfast (LCY) (c_)] 
        , [Amount] 
        , [Turnover] 
        , [Amount (corr_)] 
        , [Turnover (corr_)] 
        , [Currency Faktor]
        , [Currency Code] 
        , [Currency Faktor (corr_)] 
        , [Currency Code (corr_)] 
        , [Document No_]
        , [Line No_] 
        , [Type] 
        , [Rebate Amount Line] 
        , [No Print] 
        , [No_] 
        , [Rebate Agreement No_]
        , [Posting Date (Import)] 
        , [Document Date (Import)] 
        , [Description] 
        , [Description 2] 
        , [Reservation No_] 
        , [Reservation Part No_] 
        , [Value Type] 
        , [Value]
        , [Value Text] 
        , [Value Decimal] 
        , [Value Boolean] 
        , [Value Date] 
        , [Invoice No_] 
        , [Amount (LCY)] 
        , [Turnover (LCY)] 
        , [Commission Type] 
        , [Commission Rate %] 
        , [Amount (LCY) (corr_)] 
        , [Turnover (LCY) (corr_)] 
        , [Commission Type (corr_)] 
        , [Commission Rate % (corr_)] 
        , [Departure Date] 
        , [Affiliate Partner No_] 
        , [Hotel No_] 
        , [Room Nights] 
        , [Is Net Rate] 
        , [Room Nights Post Corection] 
        , [Is Net Rate Post Corection] 
        , [Max Entry No_] 
        , [Is No Show] 
        , [Top Bonus ID] 
        , [MuseID] 
        , [Correction Kennung] 
        , [Company Name] 
        , [Customer No_] 
        , [Country Code] 
        , [Chain] 
        , [Brand] 
        , [Rebate-to Vendor No_]
        , [Handbooking] 
        , [Reservation Source] 
        , [Reservation Source Name] 
        , [Amadeus No_] 
        , [Process Number] 
        , [Realized Bookings] 
		, [Code P1]
		, [Code P2]
		, [Code P3]
		, [Code P4]
		, [Code P5]
		, [Code P6]
		, [Code P7]
		, [Code P8]
		, [Code P9]
		, [Code P10]
		, [Code PA]
		, [Matrix _ Vector Code]
FROM _TOTAL ORDER BY [Reservation No_]

UPDATE R SET 
       R.[Name P1] = P.[Name]
     , R.[Value P1] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P1] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P2] = P.[Name]
     , R.[Value P2] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P2] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P3] = P.[Name]
     , R.[Value P3] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P3] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P4] = P.[Name]
     , R.[Value P4] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P4] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P5] = P.[Name]
     , R.[Value P5] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P5] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P6] = P.[Name]
     , R.[Value P6] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P6] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P7] = P.[Name]
     , R.[Value P7] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P7] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P8] = P.[Name]
     , R.[Value P8] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P8] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P9] = P.[Name]
     , R.[Value P9] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P9] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P10] = P.[Name]
     , R.[Value P10] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code P10] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name PA] = P.[Name]
     , R.[Value PA] = P.[Value Decimal]
     , R.[Value Decimal] = P.[Value Decimal]
  FROM @Result R
  JOIN @Parameter P 
    ON P.[No_] = R.[Code PA] 
   AND P.[Rebate No_] = R.[Rebate No_]

UPDATE R SET
       R.[Vector Range] = VR.[Description]
  FROM @Result R
  JOIN [HRS$Rebate Vector Ranges] VR
    ON VR.[Vector Code] = R.[Matrix _ Vector Code] 
   AND R.[Value P5] BETWEEN VR.[Value From (Decimal)] AND VR.[Value To (Decimal)]

SELECT * FROM @Result

--dbo.fnc_RebateVectorSelection(AH.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
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
