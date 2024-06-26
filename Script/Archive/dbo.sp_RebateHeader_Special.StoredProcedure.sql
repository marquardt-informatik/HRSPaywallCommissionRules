USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateHeader_Special]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Kopfinformationen zur Gutschriftsanzeige
-- 20110909 RP1 Ausgabe erweitert um  [Kreditor].[MwSt.-Geschäftsbuchungsgruppe]
--									, [Kreditor].[Currency Code]
-- 20150206 RP  Erweit um API, GDS, RD und RR 
--				Basisverion: [sp_RebateHeader_SIK_20150206]
-- 	            [sp_RebateHeader2] hier reingemerged
--              NAV Filter von [Travelagency].IATA aufgebaut
/*
DECLARE @ReNr VARCHAR(20)
SELECT @ReNr = 'K0000055384'
EXEC [dbo].[sp_RebateHeader_Special] @ReNr

*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateHeader_Special] 
    @RebateNo varchar(20) = 'K0000042649'
  , @Debug int=0
WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON
DECLARE @CustList VARCHAR(MAX)
SELECT @CustList = ''

DECLARE @AP AS TABLE([Affiliate Partner No_] int, [Rebate No_] varchar(20))
DECLARE @ActualCustomer bigint, @PreviousCustomer bigint, @FirstCustomer bigint, @RangeMin bigint, @RangeMax bigint, @OldRangeMin bigint, @OldRangeMax bigint, @VendorNo VARCHAR(20)
 SELECT @ActualCustomer = 0, @PreviousCustomer = 0, @FirstCustomer = 0, @RangeMin = 0, @RangeMax = 0
 
DECLARE @ParameterList varchar(max)
 SELECT @ParameterList  = ''
 SELECT @ParameterList  = @ParameterList 
      + CASE WHEN AH.[Input Parameter 1 Code] <> '' THEN ',' + AH.[Input Parameter 1 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 2 Code] <> '' THEN ',' + AH.[Input Parameter 2 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 3 Code] <> '' THEN ',' + AH.[Input Parameter 3 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 4 Code] <> '' THEN ',' + AH.[Input Parameter 4 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 5 Code] <> '' THEN ',' + AH.[Input Parameter 5 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 6 Code] <> '' THEN ',' + AH.[Input Parameter 6 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 7 Code] <> '' THEN ',' + AH.[Input Parameter 7 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 8 Code] <> '' THEN ',' + AH.[Input Parameter 8 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 9 Code] <> '' THEN ',' + AH.[Input Parameter 9 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 10 Code] <> '' THEN ',' + AH.[Input Parameter 10 Code] ELSE '' END
      + CASE WHEN AH.[Output Parameter Code] <> '' THEN ',' + AH.[Output Parameter Code] ELSE '' END
      , @VendorNo = AH.[Rebate-to Vendor No_]
   FROM [HRS$Rebate Header]    RH WITH (NOLOCK)
   JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo

 SELECT @ParameterList  = @ParameterList 
      + CASE WHEN AH.[Input Parameter 1 Code] <> '' THEN ',' + AH.[Input Parameter 1 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 2 Code] <> '' THEN ',' + AH.[Input Parameter 2 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 3 Code] <> '' THEN ',' + AH.[Input Parameter 3 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 4 Code] <> '' THEN ',' + AH.[Input Parameter 4 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 5 Code] <> '' THEN ',' + AH.[Input Parameter 5 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 6 Code] <> '' THEN ',' + AH.[Input Parameter 6 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 7 Code] <> '' THEN ',' + AH.[Input Parameter 7 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 8 Code] <> '' THEN ',' + AH.[Input Parameter 8 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 9 Code] <> '' THEN ',' + AH.[Input Parameter 9 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 10 Code] <> '' THEN ',' + AH.[Input Parameter 10 Code] ELSE '' END
      + CASE WHEN AH.[Output Parameter Code] <> '' THEN ',' + AH.[Output Parameter Code] ELSE '' END
      , @VendorNo = AH.[Rebate-to Vendor No_]
   FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
   JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo

DECLARE @PayedRebateBlock TABLE
(
    [Posting Date]        DATETIME
  , [Value Decimal]       DEC(37,20)
  , [Interval Start Date] DATETIME
  , [Interval End Date]   DATETIME
  , [Code P1]             VARCHAR(20)
  , [Name P1]             VARCHAR(50)
  , [Value P1]            DEC(37,20)
  , [Code P2]             VARCHAR(20)
  , [Name P2]             VARCHAR(50)
  , [Value P2]            DEC(37,20)
  , [Code P3]             VARCHAR(20)
  , [Name P3]             VARCHAR(50)
  , [Value P3]            DEC(37,20)
  , [Code P4]             VARCHAR(20)
  , [Name P4]             VARCHAR(50)
  , [Value P4]            DEC(37,20)
  , [Code P5]             VARCHAR(20)
  , [Name P5]             VARCHAR(50)
  , [Value P5]            DEC(37,20)
  , [Code P6]             VARCHAR(20)
  , [Name P6]             VARCHAR(50)
  , [Value P6]            DEC(37,20)
  , [Code P7]             VARCHAR(20)
  , [Name P7]             VARCHAR(50)
  , [Value P7]            DEC(37,20)
  , [Code P8]             VARCHAR(20)
  , [Name P8]             VARCHAR(50)
  , [Value P8]            DEC(37,20)
  , [Code P9]             VARCHAR(20)
  , [Name P9]             VARCHAR(50)
  , [Value P9]            DEC(37,20)
  , [Code P10]            VARCHAR(20)
  , [Name P10]            VARCHAR(50)
  , [Value P10]           DEC(37,20)
  , [Code PA]             VARCHAR(20)
  , [Name PA]             VARCHAR(50)
  , [Value PA]            DEC(37,20)
  , [State]               INT
  , [Rebate No_]          VARCHAR(20)
)

DECLARE @PayedRebate TABLE
(
    [Posting Date]        DATETIME
  , [Value Decimal]       DEC(37,20)
  , [Interval Start Date] DATETIME
  , [Interval End Date]   DATETIME
  , [Code P1]             VARCHAR(20)
  , [Name P1]             VARCHAR(50)
  , [Value P1]            DEC(37,20)
  , [Code P2]             VARCHAR(20)
  , [Name P2]             VARCHAR(50)
  , [Value P2]            DEC(37,20)
  , [Code P3]             VARCHAR(20)
  , [Name P3]             VARCHAR(50)
  , [Value P3]            DEC(37,20)
  , [Code P4]             VARCHAR(20)
  , [Name P4]             VARCHAR(50)
  , [Value P4]            DEC(37,20)
  , [Code P5]             VARCHAR(20)
  , [Name P5]             VARCHAR(50)
  , [Value P5]            DEC(37,20)
  , [Code P6]             VARCHAR(20)
  , [Name P6]             VARCHAR(50)
  , [Value P6]            DEC(37,20)
  , [Code P7]             VARCHAR(20)
  , [Name P7]             VARCHAR(50)
  , [Value P7]            DEC(37,20)
  , [Code P8]             VARCHAR(20)
  , [Name P8]             VARCHAR(50)
  , [Value P8]            DEC(37,20)
  , [Code P9]             VARCHAR(20)
  , [Name P9]             VARCHAR(50)
  , [Value P9]            DEC(37,20)
  , [Code P10]            VARCHAR(20)
  , [Name P10]            VARCHAR(50)
  , [Value P10]           DEC(37,20)
  , [Code PA]             VARCHAR(20)
  , [Name PA]             VARCHAR(50)
  , [Value PA]            DEC(37,20)
  , [State]               INT
  , [Rebate No_]          VARCHAR(20)
)

-- sp_RebatePayedRebateBlock2 - Start
DECLARE @ParameterList2 varchar(max)
 SELECT @ParameterList2  = ''
 SELECT @ParameterList2  = @ParameterList2 
      + CASE WHEN AH.[Input Parameter 1 Code] <> '' THEN ',' + AH.[Input Parameter 1 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 2 Code] <> '' THEN ',' + AH.[Input Parameter 2 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 3 Code] <> '' THEN ',' + AH.[Input Parameter 3 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 4 Code] <> '' THEN ',' + AH.[Input Parameter 4 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 5 Code] <> '' THEN ',' + AH.[Input Parameter 5 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 6 Code] <> '' THEN ',' + AH.[Input Parameter 6 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 7 Code] <> '' THEN ',' + AH.[Input Parameter 7 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 8 Code] <> '' THEN ',' + AH.[Input Parameter 8 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 9 Code] <> '' THEN ',' + AH.[Input Parameter 9 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 10 Code] <> '' THEN ',' + AH.[Input Parameter 10 Code] ELSE '' END
      + CASE WHEN AH.[Output Parameter Code] <> '' THEN ',' + AH.[Output Parameter Code] ELSE '' END
   FROM [HRS$Rebate Header]    RH WITH (NOLOCK)
   JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo

 SELECT @ParameterList2  = @ParameterList2 
      + CASE WHEN AH.[Input Parameter 1 Code] <> '' THEN ',' + AH.[Input Parameter 1 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 2 Code] <> '' THEN ',' + AH.[Input Parameter 2 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 3 Code] <> '' THEN ',' + AH.[Input Parameter 3 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 4 Code] <> '' THEN ',' + AH.[Input Parameter 4 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 5 Code] <> '' THEN ',' + AH.[Input Parameter 5 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 6 Code] <> '' THEN ',' + AH.[Input Parameter 6 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 7 Code] <> '' THEN ',' + AH.[Input Parameter 7 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 8 Code] <> '' THEN ',' + AH.[Input Parameter 8 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 9 Code] <> '' THEN ',' + AH.[Input Parameter 9 Code] ELSE '' END
      + CASE WHEN AH.[Input Parameter 10 Code] <> '' THEN ',' + AH.[Input Parameter 10 Code] ELSE '' END
      + CASE WHEN AH.[Output Parameter Code] <> '' THEN ',' + AH.[Output Parameter Code] ELSE '' END
   FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
   JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
     ON AH.[No_] = RH.[Rebate Agreement No_] 
  WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
    AND RH.Cancels = 0

DECLARE @Parameter2 TABLE
(
    [Rebate No_]    VARCHAR(20)
  , [No_]           VARCHAR(20)
  , [Value Decimal] DEC(37,20)
  , [Name]          VARCHAR(120)
  , UNIQUE NONCLUSTERED  
    (
	    [Rebate No_] ASC
	  , [No_] ASC
    )
)

DECLARE @Result2 TABLE
(
    [Posting Date]        DATETIME
  , [Value Decimal]       DEC(37,20)
  , [Interval Start Date] DATETIME
  , [Interval End Date]   DATETIME
  , [Code P1]             VARCHAR(20)
  , [Name P1]             VARCHAR(50)
  , [Value P1]            DEC(37,20)
  , [Code P2]             VARCHAR(20)
  , [Name P2]             VARCHAR(50)
  , [Value P2]            DEC(37,20)
  , [Code P3]             VARCHAR(20)
  , [Name P3]             VARCHAR(50)
  , [Value P3]            DEC(37,20)
  , [Code P4]             VARCHAR(20)
  , [Name P4]             VARCHAR(50)
  , [Value P4]            DEC(37,20)
  , [Code P5]             VARCHAR(20)
  , [Name P5]             VARCHAR(50)
  , [Value P5]            DEC(37,20)
  , [Code P6]             VARCHAR(20)
  , [Name P6]             VARCHAR(50)
  , [Value P6]            DEC(37,20)
  , [Code P7]             VARCHAR(20)
  , [Name P7]             VARCHAR(50)
  , [Value P7]            DEC(37,20)
  , [Code P8]             VARCHAR(20)
  , [Name P8]             VARCHAR(50)
  , [Value P8]            DEC(37,20)
  , [Code P9]             VARCHAR(20)
  , [Name P9]             VARCHAR(50)
  , [Value P9]            DEC(37,20)
  , [Code P10]            VARCHAR(20)
  , [Name P10]            VARCHAR(50)
  , [Value P10]           DEC(37,20)
  , [Code PA]             VARCHAR(20)
  , [Name PA]             VARCHAR(50)
  , [Value PA]            DEC(37,20)
  , [State]               INT
  , [Rebate No_]          VARCHAR(20)
)

;WITH AgreementHeader AS
(
SELECT AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
   AND AH.[Enable retroactive correction] = 1
UNION 
SELECT AH.*
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
   AND AH.[Enable retroactive correction] = 1
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
     AND RH.Cancels = 0
)
INSERT INTO @Parameter2
SELECT * FROM RL
 WHERE ','+@ParameterList2+',' LIKE '%,' + [No_] + ',%'
   AND [No_]<>''

INSERT INTO @Parameter2
SELECT '','',0.0,'' UNION
SELECT PM.[Rebate No_],PA.[Code], PA.[Value Decimal], PA.[Name]
  FROM [HRS$Parameter] PA WITH (NOLOCK), (SELECT DISTINCT [Rebate No_] FROM @Parameter2) PM
 WHERE ','+@ParameterList2+',' LIKE '%,' + PA.[Code] + ',%'
   AND NOT PA.[Code] IN (SELECT [No_] FROM @Parameter2)

--SELECT * FROM @Parameter

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
 WHERE RH.[No_] = @RebateNo
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
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
), _ALL AS
(
   SELECT RH.[Posting Date]
        , 0.0 [Value Decimal]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , AH.[Input Parameter 1 Code]   [Code P1]
        , AH.[Input Parameter 2 Code]   [Code P2]
        , AH.[Input Parameter 3 Code]   [Code P3]
        , AH.[Input Parameter 4 Code]   [Code P4]
        , AH.[Input Parameter 5 Code]   [Code P5]
        , AH.[Input Parameter 6 Code]   [Code P6]
        , AH.[Input Parameter 7 Code]   [Code P7]
        , AH.[Input Parameter 8 Code]   [Code P8]
        , AH.[Input Parameter 9 Code]   [Code P9]
        , AH.[Input Parameter 10 Code] [Code P10]
        , AH.[Output Parameter Code]    [Code PA]
        , 0 [State]
        , AH.[Rebate No_]
        , RH.[No_] [Past Rebate No_]
     FROM [HRS$Rebate Header] RH WITH (NOLOCK)
     JOIN [HRS$Rebate Reserve Entry] RE WITH (NOLOCK)
       ON RE.[Rebate No_] = RH.[No_]
     JOIN AgreementHeader AH
       ON AH.[No_] = RH.[Rebate Agreement No_]
      --AND RH.[Document Date] >= AH.[Year Start Date] 
      --AND RH.[Document Date] <  AH.[Posting Date]
    WHERE RH.[No_] <> @RebateNo
UNION   
   SELECT RH.[Posting Date]
        , 0.0
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , AH.[Input Parameter 1 Code]   [Code P1]
        , AH.[Input Parameter 2 Code]   [Code P2]
        , AH.[Input Parameter 3 Code]   [Code P3]
        , AH.[Input Parameter 4 Code]   [Code P4]
        , AH.[Input Parameter 5 Code]   [Code P5]
        , AH.[Input Parameter 6 Code]   [Code P6]
        , AH.[Input Parameter 7 Code]   [Code P7]
        , AH.[Input Parameter 8 Code]   [Code P8]
        , AH.[Input Parameter 9 Code]   [Code P9]
        , AH.[Input Parameter 10 Code] [Code P10]
        , AH.[Output Parameter Code]    [Code PA]
        , 0 [State]
        , RH.[No_] [Rebate No_]
        , RH.[No_] [Past Rebate No_]
     FROM [HRS$Posted Rebate Header] RH WITH (NOLOCK)
     JOIN AgreementHeader AH
       ON AH.[No_] = RH.[Rebate Agreement No_]
      AND RH.[Document Date] >= AH.[Year Start Date] 
      AND RH.[Document Date] <=  AH.[Document Date]
      AND RH.[Posting Date] <  AH.[Posting Date]
LEFT JOIN [HRS$G_L Entry] GLE WITH (NOLOCK)
       ON GLE.[Posting Date] = AH.[Posting Date]
      AND GLE.[Document No_] = RH.[Rebate No_]
      AND GLE.[Source No_]   = AH.[Rebate-to Vendor No_]
      AND GLE.Amount         > 0
LEFT JOIN [HRS$Rebate Setup] RS WITH (NOLOCK)
       ON (RS.[Account No_ Reserve] = GLE.[G_L Account No_])
	   OR GLE.[G_L Account No_]       ='472500'
       OR RH.[Statement Posting Type] = 2
    WHERE RH.[Cancels] = 0
      AND RH.[Rebate No_] <> @RebateNo
      AND RH.[No_] <> @RebateNo
      AND NOT GLE.[Posting Date] IS NULL
)
INSERT INTO @Result2 ([Posting Date], [Value Decimal], [Interval Start Date], [Interval End Date], [State], [Rebate No_], [Code P1], [Code P2], [Code P3], [Code P4], [Code P5], [Code P6], [Code P7], [Code P8], [Code P9], [Code P10], [Code PA])
SELECT [Posting Date], [Value Decimal], [Interval Start Date], [Interval End Date], [State], [Rebate No_], [Code P1], [Code P2], [Code P3], [Code P4], [Code P5], [Code P6], [Code P7], [Code P8], [Code P9], [Code P10], [Code PA]
  FROM _ALL

UPDATE R SET 
       R.[Name P1] = P.[Name]
     , R.[Value P1] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P1] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P2] = P.[Name]
     , R.[Value P2] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P2] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P3] = P.[Name]
     , R.[Value P3] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P3] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P4] = P.[Name]
     , R.[Value P4] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P4] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P5] = P.[Name]
     , R.[Value P5] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P5] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P6] = P.[Name]
     , R.[Value P6] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P6] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P7] = P.[Name]
     , R.[Value P7] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P7] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P8] = P.[Name]
     , R.[Value P8] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P8] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P9] = P.[Name]
     , R.[Value P9] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P9] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name P10] = P.[Name]
     , R.[Value P10] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code P10] 
   AND P.[Rebate No_] = R.[Rebate No_]
  
UPDATE R SET 
       R.[Name PA] = P.[Name]
     , R.[Value PA] = P.[Value Decimal]
     , R.[Value Decimal] = P.[Value Decimal]
  FROM @Result2 R
  JOIN @Parameter2 P 
    ON P.[No_] = R.[Code PA] 
   AND P.[Rebate No_] = R.[Rebate No_]

  INSERT INTO @PayedRebateBlock
  SELECT * FROM @Result2 ORDER BY [Interval Start Date]   
-- sp_RebatePayedRebateBlock2 - Ende
--INSERT INTO @PayedRebateBlock
--EXEC [dbo].[sp_RebatePayedRebateBlock2] @RebateNo

--INSERT INTO @PayedRebate
--EXEC [dbo].[sp_RebatePayedRebate] @RebateNo

DECLARE @PayedRebateAmount                 DEC(37,20) = 0.0
      , @PayedRebateIntervalStartDate      DATETIME = '1753-01-01'
      , @PayedRebateIntervalEndDate        DATETIME = '1753-01-01'
      , @PayedRebateBlockAmount            DEC(37,20) = 0.0
      , @PayedRebateBlockIntervalStartDate DATETIME = '1753-01-01'
      , @PayedRebateBlockIntervalEndDate   DATETIME = '1753-01-01'
SELECT @PayedRebateBlockAmount            = COALESCE(SUM([Value PA]),0.0)
     , @PayedRebateBlockIntervalStartDate = COALESCE(MIN([Interval Start Date]),'2999-12-31')
     , @PayedRebateBlockIntervalEndDate   = COALESCE(MAX([Interval End Date]),'1753-01-01')
  FROM @PayedRebateBlock
  
SELECT @PayedRebateAmount                 = COALESCE(SUM([Value PA]),0.0)-@PayedRebateBlockAmount
     , @PayedRebateIntervalStartDate      = MIN([Interval Start Date])
     , @PayedRebateIntervalEndDate        = MAX(CASE WHEN [Interval End Date] < @PayedRebateBlockIntervalStartDate THEN [Interval End Date] ELSE '1753-01-01' END)
  FROM @PayedRebate

SELECT @PayedRebateIntervalStartDate      = CASE WHEN @PayedRebateIntervalStartDate = '1753-01-01' THEN NULL ELSE @PayedRebateIntervalStartDate END
     , @PayedRebateIntervalEndDate        = CASE WHEN @PayedRebateIntervalEndDate   = '1753-01-01' THEN NULL ELSE @PayedRebateIntervalEndDate   END

IF @Debug=1
BEGIN
PRINT '@PayedRebateAmount' + CAST(@PayedRebateAmount AS varchar)
PRINT '@PayedRebateIntervalStartDate' + CAST(@PayedRebateIntervalStartDate AS varchar)
PRINT '@PayedRebateIntervalEndDate' + CAST(@PayedRebateIntervalEndDate AS varchar)
PRINT '@PayedRebateBlockAmount' + CAST(@PayedRebateBlockAmount AS varchar)
PRINT '@PayedRebateBlockIntervalStartDate' + CAST(@PayedRebateBlockIntervalStartDate AS varchar)
PRINT '@PayedRebateBlockIntervalEndDate' + CAST(@PayedRebateBlockIntervalEndDate AS varchar)
END
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
IF @Debug=1
  PRINT '@VendorNo = ' + @VendorNo
SELECT @FirstCustomer = @ActualCustomer

WHILE @@FETCH_STATUS = 0
BEGIN
  IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
    IF @PreviousCustomer<> 0 AND (@RangeMax<@ActualCustomer OR @RangeMax=0) BEGIN
      SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
      SET @RangeMin=0
      SET @RangeMax=0
      SELECT @RangeMin = [Affiliate Partner No_ (from)]
           , @RangeMax = [Affiliate Partner No_ (to)]
        FROM [HRS$Reserved Customer-No_ Ranges] WITH (NOLOCK)
       WHERE @PreviousCustomer BETWEEN [Affiliate Partner No_ (from)] AND [Affiliate Partner No_ (to)]
         AND [Vendor No_] = @VendorNo
      IF @RangeMin<@FirstCustomer AND @RangeMin<>0
        SET @FirstCustomer = @RangeMin
      IF @RangeMax>@PreviousCustomer AND @RangeMax<>0
        SET @PreviousCustomer = @RangeMax
      SET @CustList = @CustList 
                    + CASE
                        WHEN @RangeMin>0 AND @RangeMax>0 THEN
                          CAST(@RangeMin AS varchar) + '..' + CAST(@RangeMax AS varchar)
                        WHEN @PreviousCustomer = @FirstCustomer THEN 
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

IF (@PreviousCustomer<> 0) BEGIN
  SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
  SET @RangeMin=0
  SET @RangeMax=0
  SELECT @RangeMin = [Affiliate Partner No_ (from)]
       , @RangeMax = [Affiliate Partner No_ (to)]
    FROM [HRS$Reserved Customer-No_ Ranges] WITH (NOLOCK)
   WHERE @PreviousCustomer BETWEEN [Affiliate Partner No_ (from)] AND [Affiliate Partner No_ (to)]
     AND [Vendor No_] = @VendorNo
  IF @RangeMin<@FirstCustomer AND @RangeMin<>0
    SET @FirstCustomer = @RangeMin
  IF @RangeMax>@PreviousCustomer AND @RangeMax<>0
    SET @PreviousCustomer = @RangeMax
  SET @CustList = @CustList 
                + CASE
                    WHEN @RangeMin>0 AND @RangeMax>0  THEN
                      CAST(@RangeMin AS varchar) + '..' + CAST(@RangeMax AS varchar)
                    WHEN @PreviousCustomer = @FirstCustomer THEN 
                      CAST(@PreviousCustomer AS varchar)
                    ELSE
                      CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                  END                   
END 

CLOSE cur
DEALLOCATE cur

--RP START
DECLARE @Iata VARCHAR(MAX) = ''
--SELECT @Iata = @Iata + CASE WHEN EXISTS (SELECT TOP 1 NULL
--										   FROM [Travelagency] WITH (NOLOCK)
--										  WHERE ISNUMERIC(IATA)=1
--										    AND ISNUMERIC(TA.IATA)=1
--										    AND CAST(IATA AS INT) = CAST(TA.IATA AS INT) + 1)
--						    THEN CASE WHEN RIGHT(@Iata, 2) = '..'
--								      THEN ''
--									  ELSE CASE WHEN LEN(@Iata) > 0
--												THEN '|' + TA.IATA + '..'
--												ELSE TA.IATA + '..'
--										   END
--								 END
--							ELSE CASE WHEN RIGHT(@Iata, 2) = '..' OR LEN(@Iata) = 0 
--									  THEN TA.IATA
--									  ELSE '|' + TA.IATA
--								 END
--					   END
-- FROM [Travelagency]				TA WITH (NOLOCK)
-- JOIN [HRS$Vendor Travelagency]		VT WITH (NOLOCK)
--   ON TA.[No_] = VT.[Travelagency No_]
-- JOIN [HRS$Rebate Header]			RH WITH (NOLOCK)
--   ON VT.[Vendor No_] = RH.[Rebate-to Vendor No_]
--WHERE RH.[No_] = @RebateNo
--ORDER BY CAST(TA.IATA AS INT)
--RP STOP
IF @Debug=1
    PRINT @IATA

DECLARE @Parameter TABLE
(
    [No_]           VARCHAR(20)
  , [Value Decimal] DEC(37,20)
  , [Name]          VARCHAR(120)
  , [Constant Value Decimal] DEC(37,20)
  --RP START
  , [Threshold Value Index]		INT
  , [Value]						VARCHAR(250)
  , [TMC Parameter]				VARCHAR(4)
  , [TMC Text]					VARCHAR(1000)
  --RP STOP
)

;WITH RL AS
(
  --RP START
  --SELECT RL.[No_], RL.[Value Decimal], PA.[Name], PA.[Value Decimal] [Constant Value Decimal]
  SELECT RL.[No_], RL.[Value Decimal], PA.[Name], PA.[Value Decimal] [Constant Value Decimal], RL.[Threshold Value Index], RL.[Value]
	   , CASE WHEN AH.[Input Parameter TMC API 1] = RL.[No_] THEN 'API1'
			  WHEN AH.[Input Parameter TMC API 2] = RL.[No_] THEN 'API2'
			  WHEN AH.[Input Parameter TMC API 3] = RL.[No_] THEN 'API3'
			  WHEN AH.[Input Parameter TMC API 4] = RL.[No_] THEN 'API4'
			  WHEN AH.[Input Parameter TMC GDS 1] = RL.[No_] THEN 'GDS1'
			  WHEN AH.[Input Parameter TMC GDS 2] = RL.[No_] THEN 'GDS2'
			  WHEN AH.[Input Parameter TMC GDS 3] = RL.[No_] THEN 'GDS3'
			  WHEN AH.[Input Parameter TMC GDS 4] = RL.[No_] THEN 'GDS4'
			  WHEN AH.[Input Parameter TMC RD 1]  = RL.[No_] THEN 'xRD1'
			  WHEN AH.[Input Parameter TMC RD 2]  = RL.[No_] THEN 'xRD2'
			  WHEN AH.[Input Parameter TMC RD 3]  = RL.[No_] THEN 'xRD3'
			  WHEN AH.[Input Parameter TMC RD 4]  = RL.[No_] THEN 'xRD4'
			  WHEN AH.[Input Parameter TMC RR 1]  = RL.[No_] THEN 'xRR1'
			  WHEN AH.[Input Parameter TMC RR 2]  = RL.[No_] THEN 'xRR2'
			  WHEN AH.[Input Parameter TMC RR 3]  = RL.[No_] THEN 'xRR3'
			  WHEN AH.[Input Parameter TMC RR 4]  = RL.[No_] THEN 'xRR4'
			  WHEN AH.[Input Parameter TMC OBE 1] = RL.[No_] THEN 'OBE1'
			  WHEN AH.[Input Parameter TMC OBE 2] = RL.[No_] THEN 'OBE2'
			  WHEN AH.[Input Parameter TMC OBE 3] = RL.[No_] THEN 'OBE3'
			  WHEN AH.[Input Parameter TMC OBE 4] = RL.[No_] THEN 'OBE4'
			  ELSE NULL
		END [TMC Parameter], NULL [TMC Text] 
  --RP STOP
    FROM [HRS$Rebate Line]   RL WITH (NOLOCK) 
    JOIN [HRS$Rebate Header] RH WITH (NOLOCK) 
      ON RL.[Document No_] = RH.[No_]
    JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK) 
      ON RL.[Rebate Agreement No_] = AH.[No_]
    JOIN [HRS$Parameter]     PA WITH (NOLOCK)
      ON PA.[Code]  = RL.[No_]
   WHERE RH.[No_]   = @RebateNo
     AND RL.[Type] IN (1,2)
UNION   
  --RP START  
  --SELECT RL.[No_], RL.[Value Decimal], PA.[Name], PA.[Value Decimal] [Constant Value Decimal]
  SELECT RL.[No_], RL.[Value Decimal], PA.[Name], PA.[Value Decimal] [Constant Value Decimal], RL.[Threshold Value Index], RL.[Value]
	   , CASE WHEN AH.[Input Parameter TMC API 1] = RL.[No_] THEN 'API1'
			  WHEN AH.[Input Parameter TMC API 2] = RL.[No_] THEN 'API2'
			  WHEN AH.[Input Parameter TMC API 3] = RL.[No_] THEN 'API3'
			  WHEN AH.[Input Parameter TMC API 4] = RL.[No_] THEN 'API4'
			  WHEN AH.[Input Parameter TMC GDS 1] = RL.[No_] THEN 'GDS1'
			  WHEN AH.[Input Parameter TMC GDS 2] = RL.[No_] THEN 'GDS2'
			  WHEN AH.[Input Parameter TMC GDS 3] = RL.[No_] THEN 'GDS3'
			  WHEN AH.[Input Parameter TMC GDS 4] = RL.[No_] THEN 'GDS4'
			  WHEN AH.[Input Parameter TMC RD 1]  = RL.[No_] THEN 'xRD1'
			  WHEN AH.[Input Parameter TMC RD 2]  = RL.[No_] THEN 'xRD2'
			  WHEN AH.[Input Parameter TMC RD 3]  = RL.[No_] THEN 'xRD3'
			  WHEN AH.[Input Parameter TMC RD 4]  = RL.[No_] THEN 'xRD4'
			  WHEN AH.[Input Parameter TMC RR 1]  = RL.[No_] THEN 'xRR1'
			  WHEN AH.[Input Parameter TMC RR 2]  = RL.[No_] THEN 'xRR2'
			  WHEN AH.[Input Parameter TMC RR 3]  = RL.[No_] THEN 'xRR3'
			  WHEN AH.[Input Parameter TMC RR 4]  = RL.[No_] THEN 'xRR4'
			  WHEN AH.[Input Parameter TMC OBE 1] = RL.[No_] THEN 'OBE1'
			  WHEN AH.[Input Parameter TMC OBE 2] = RL.[No_] THEN 'OBE2'
			  WHEN AH.[Input Parameter TMC OBE 3] = RL.[No_] THEN 'OBE3'
			  WHEN AH.[Input Parameter TMC OBE 4] = RL.[No_] THEN 'OBE4'
			  ELSE NULL
		END [TMC Parameter], NULL [TMC Text] 
  --RP STOP
    FROM [HRS$Posted Rebate Line]   RL WITH (NOLOCK) 
    JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK) 
      ON RL.[Document No_] = RH.[No_]
    JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK) 
      ON RL.[Rebate Agreement No_] = AH.[No_]
    JOIN [HRS$Parameter]     PA WITH (NOLOCK)
      ON PA.[Code]  = RL.[No_]
   WHERE (RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo)
     AND RL.[Type] IN (1,2)
)
INSERT INTO @Parameter
SELECT * FROM RL WHERE [No_]<>''

INSERT INTO @Parameter
--RP START
--SELECT '',0.0,'',0.0 UNION
--SELECT PA.[Code], PA.[Value Decimal], PA.[Name], PA.[Value Decimal]
SELECT '',0.0,'',0.0,NULL, NULL, NULL, NULL UNION
SELECT PA.[Code], PA.[Value Decimal], PA.[Name], PA.[Value Decimal], NULL, NULL, NULL, NULL
--RP STOP
  FROM [HRS$Parameter] PA WITH (NOLOCK)
 WHERE ','+@ParameterList+',' LIKE '%,' + PA.[Code] + ',%'
   AND NOT PA.[Code] IN (SELECT [No_] FROM @Parameter)

--SELECT * FROM @Parameter
--RP START
DECLARE @TMCParameter VARCHAR(4)
DECLARE TMCCursor CURSOR FOR SELECT DISTINCT [TMC Parameter] FROM @Parameter WHERE [TMC Parameter] LIKE '%4'--is NOT NULL
OPEN TMCCursor
FETCH NEXT FROM TMCCursor INTO @TMCParameter	
    IF @Debug=1
	    PRINT @TMCParameter
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		 DECLARE @ResultVar VARCHAR(1000) = ''
		 SELECT @ResultVar = @ResultVar + CASE WHEN [P3].[Threshold Value Index] = 1
											   THEN				   ' (' + CONVERT(VARCHAR, CAST([P3].[Value Decimal] AS MONEY),1) + ' %CUR * ' + [P2].[Value] + ')' 
											   ELSE CASE WHEN [P3].[Threshold Value Index] % 3 = 0
														 THEN '<br>+ (' + CONVERT(VARCHAR, CAST([P3].[Value Decimal] AS MONEY),1) + ' %CUR * ' + [P2].[Value] + ')' 
														 ELSE    ' + (' + CONVERT(VARCHAR, CAST([P3].[Value Decimal] AS MONEY),1) + ' %CUR * ' + [P2].[Value] + ')'
													END
											   END
							  FROM @Parameter [P2]
							  JOIN @Parameter [P3] 
								ON [P2].[Threshold Value Index] = [P3].[Threshold Value Index]
							 WHERE [P2].[TMC Parameter] = STUFF(@TMCParameter, 4, 1, '2') 	
							   AND [P3].[TMC Parameter] = STUFF(@TMCParameter, 4, 1, '3') 							  

		UPDATE @Parameter 
		   SET [TMC Text] = @ResultVar
		 WHERE [TMC Parameter] = @TMCParameter
		   AND [Threshold Value Index] = 0
		
		FETCH NEXT FROM TMCCursor INTO @TMCParameter
	END
CLOSE TMCCursor
DEALLOCATE TMCCursor
--RP STOP

;WITH BankAccount AS
(
SELECT [Vendor No_], [Name], [IBAN], [Bank Branch No_], [Bank Account No_], [SWIFT Code]
  FROM [HRS$Vendor Bank Account] WITH (READUNCOMMITTED) 
 WHERE [Clearing] = 1
)
   SELECT RH.[No_] [Rebate No_]
        , RH.[Rebate-to Vendor No_]
        , VE.[Name] [Rebate-to Customer Name]
        , VE.[Name 2] [Rebate-to Customer Name 2]
        , VE.[Address] [Rebate-to Address]
        , VE.[Address 2] [Rebate-to Address 2]
        , VE.City [Rebate-to City]
        , RA.[Rebate-to Contact]
        , VE.[Post Code] [Rebate-to Post Code]
        , VE.[Country_Region Code] [Rebate-to Country_Region Code]
        , @CustList [Affiliate Partner List]
        , RH.[Currency Code]
        , RH.[Currency Factor]
        , RH.[Interval]
        , RH.[Posting Date]
        , RH.[Document Date]    
        , CASE WHEN RH.[Language Code]='' THEN CASE WHEN VE.[Language Code]='' THEN '0' ELSE VE.[Language Code] END ELSE RH.[Language Code] END [Language Code]
        , CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+1, RH.[Interval Start Date])
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END [Year Start Date]
        , DATEADD(dd,-1,CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+13, RH.[Interval Start Date]) 
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END) [Year End Date]
        , DATEADD(dd,-0,RH.[Interval Start Date]) [Till Start Date]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RH.[Document Type (Statement)]
        , RH.[Document Type (Cr_ Memo)]
        , RH.[Correspondence Type] 
        , COALESCE(BA.Name,'')                [Vendor Bank Name]
        , COALESCE(BA.[IBAN],'')              [Vendor IBAN]
        , COALESCE(BA.[SWIFT Code],'')        [Vendor SWIFT Code]
        , COALESCE(BA.[Bank Branch No_],'')   [Vendor Bank Branch No_]
        , COALESCE(BA.[Bank Account No_], '') [Vendor Bank Account No_]
        , RA.[Template Type]
        , RA.[Matrix _ Vector Code]
        , RA.[Input Parameter 1 Code]   [Code P1],  P1.[Name]  [Name P1], P1.[Value Decimal]  [Value P1], P1.[Constant Value Decimal]  [Constant Value P1]
        , RA.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], P2.[Value Decimal]  [Value P2], P2.[Constant Value Decimal]  [Constant Value P2]
        , RA.[Input Parameter 3 Code]   [Code P3],  P3.[Name]  [Name P3], P3.[Value Decimal]  [Value P3], P3.[Constant Value Decimal]  [Constant Value P3]
        , RA.[Input Parameter 4 Code]   [Code P4],  P4.[Name]  [Name P4], P4.[Value Decimal]  [Value P4], P4.[Constant Value Decimal]  [Constant Value P4]
        , RA.[Input Parameter 5 Code]   [Code P5],  P5.[Name]  [Name P5], P5.[Value Decimal]  [Value P5], P5.[Constant Value Decimal]  [Constant Value P5]
        , RA.[Input Parameter 6 Code]   [Code P6],  P6.[Name]  [Name P6], P6.[Value Decimal]  [Value P6], P6.[Constant Value Decimal]  [Constant Value P6]
        , RA.[Input Parameter 7 Code]   [Code P7],  P7.[Name]  [Name P7], P7.[Value Decimal]  [Value P7], P7.[Constant Value Decimal]  [Constant Value P7]
        , RA.[Input Parameter 8 Code]   [Code P8],  P8.[Name]  [Name P8], P8.[Value Decimal]  [Value P8], P8.[Constant Value Decimal]  [Constant Value P8]
        , RA.[Input Parameter 9 Code]   [Code P9],  P9.[Name]  [Name P9], P9.[Value Decimal]  [Value P9], P9.[Constant Value Decimal]  [Constant Value P9]
        , RA.[Input Parameter 10 Code] [Code P10],  P10.[Name] [Name P10],P10.[Value Decimal] [Value P10], P10.[Constant Value Decimal]  [Constant Value P10]
        , RA.[Output Parameter Code]    [Code PA],  PA.[Name]  [Name PA], PA.[Value Decimal]  [Value PA], PA.[Constant Value Decimal]  [Constant Value PA]
		, VE.[VAT Bus_ Posting Group]					   [VatBusPostingGroup]
		, VE.[Currency Code]							   [CurrencyCode] 	
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    'txtVATRegistrationNo'
		  ELSE
            'txtRegistrationNo'
		  END                                              [VAT Registration Label]
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    VE.[VAT Registration No_]
		  ELSE
            VE.[Registration No_]
		  END                                              [VAT Registration No_]
		, dbo.[HRS$GetSalutation](RA.[Salutation Code],CASE WHEN RH.[Language Code]='' THEN CASE WHEN VE.[Language Code]='' THEN '0' ELSE VE.[Language Code] END ELSE RH.[Language Code] END,0,1,RA.[No_]) [Salutation]
		, COALESCE(SP.[E-Mail],'kreditoren@hrs.de')    [Salesperson E-Mail]
		, COALESCE(SP.[Fax No_],'377')                 [Salesperson Fax No_]
		, COALESCE(SP.[Name],'')                       [Salesperson Name]
		, COALESCE(SP.[Phone No_],'800')               [Salesperson Phone No_]
		, COALESCE(CR.[EU Country_Region Code],'')     [EU Country_Region Code]
		, COALESCE(CR.[Name],'')                       [Country_Region Name]
		, RH.[Online Reservation Source]
		, RH.[Offline Reservation Source]
		, RA.[Print Booking Source] 
		, RA.[Enable retroactive correction]
		, RA.[Estimated Commission]
		, dbo.fnc_RebateVectorSelection(RA.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
		, CR.[EU affiliation]
		, RA.[Partner Type]
		, RA.[Group contract Code]
		, RA.[Output Reservation Source]
		, RA.[Output Commission Type]
        , @PayedRebateIntervalStartDate [Payed Rebate Interval Start Date]
        , @PayedRebateIntervalEndDate   [Payed Rebate Interval End Date]
        , RA.[Include online cancellation]
		, RA.[Include offline bookings]
		--RP START
		, RA.[Input Parameter TMC API 1]					[TMC API Base Code]
		, PAPI1.[Value Decimal]								[TMC API Base Value]
		, [PAPI1-0].[Value Decimal]							[TMC API Result Value]
		, RA.[Input Parameter TMC API 4]					[TMC API Result Code]
		, [PAPI1-0].[TMC Text]								[TMC API Text]
		, RA.[Input Parameter TMC GDS 1]					[TMC GDS Base Code]
		, PGDS1.[Value Decimal]								[TMC GDS Base Value]
		, [PGDS1-0].[Value Decimal]							[TMC GDS Result Value]
		, RA.[Input Parameter TMC GDS 4]					[TMC GDS Result Code]
		, [PGDS1-0].[TMC Text]								[TMC GDS Text]
		, RA.[Input Parameter TMC RD 1]						[TMC RD Base Code]
		, PRD1.[Value Decimal]								[TMC RD Base Value]
		, [PRD1-0].[Value Decimal]							[TMC RD Result Value]
		, RA.[Input Parameter TMC RD 4]						[TMC RD Result Code]
		, [PRD1-0].[TMC Text]								[TMC RD Text]
		, RA.[Input Parameter TMC RR 1]						[TMC RR Base Code]
		, PRR1.[Value Decimal]								[TMC RR Base Value]
		, [PRR1-0].[Value Decimal]							[TMC RR Result Value]
		, RA.[Input Parameter TMC RR 4]						[TMC RR Result Code]
		, [PRR1-0].[TMC Text]								[TMC RR Text]
		, RA.[Input Parameter TMC OBE 1]					[TMC OBE Base Code]
		, POBE1.[Value Decimal]								[TMC OBE Base Value]
		, [POBE1-0].[Value Decimal]							[TMC OBE Result Value]
		, RA.[Input Parameter TMC OBE 4]					[TMC OBE Result Code]
		, [POBE1-0].[TMC Text]								[TMC OBE Text]
		, @Iata												[TMC IATA Filter]
		--RP STOP
		, RA.No_											[Rebate Agreement No_]	
     FROM [HRS$Rebate Header]           RH WITH (READUNCOMMITTED) 
     JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
     JOIN [HRS$Vendor]                  VE WITH (READUNCOMMITTED) ON VE.[No_]                 = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Country_Region]          CR WITH (READUNCOMMITTED) ON CR.[Code]                = VE.[Country_Region Code]     
LEFT JOIN [BankAccount]                 BA                        ON BA.[Vendor No_]          = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Salesperson_Purchaser]   SP WITH (READUNCOMMITTED) ON SP.[Code]                = VE.[Purchaser Code]
     JOIN @Parameter P1  ON P1.[No_]  = RA.[Input Parameter 1 Code]
     JOIN @Parameter P2  ON P2.[No_]  = RA.[Input Parameter 2 Code]
     JOIN @Parameter P3  ON P3.[No_]  = RA.[Input Parameter 3 Code]
     JOIN @Parameter P4  ON P4.[No_]  = RA.[Input Parameter 4 Code]
     JOIN @Parameter P5  ON P5.[No_]  = RA.[Input Parameter 5 Code]
     JOIN @Parameter P6  ON P6.[No_]  = RA.[Input Parameter 6 Code]
     JOIN @Parameter P7  ON P7.[No_]  = RA.[Input Parameter 7 Code]
     JOIN @Parameter P8  ON P8.[No_]  = RA.[Input Parameter 8 Code]
     JOIN @Parameter P9  ON P9.[No_]  = RA.[Input Parameter 9 Code]
     JOIN @Parameter P10 ON P10.[No_] = RA.[Input Parameter 10 Code]
     JOIN @Parameter PA  ON PA.[No_]  = RA.[Output Parameter Code]
	 --RP START
LEFT JOIN @Parameter PAPI1	   ON PAPI1.[No_]	  = RA.[Input Parameter TMC API 1]
LEFT JOIN @Parameter [PAPI1-0] ON [PAPI1-0].[No_] = RA.[Input Parameter TMC API 4] AND [PAPI1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter PGDS1	   ON PGDS1.[No_]	  = RA.[Input Parameter TMC GDS 1]
LEFT JOIN @Parameter [PGDS1-0] ON [PGDS1-0].[No_] = RA.[Input Parameter TMC GDS 4] AND [PGDS1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter PRD1	   ON PRD1.[No_]	  = RA.[Input Parameter TMC RD 1]
LEFT JOIN @Parameter [PRD1-0]  ON [PRD1-0].[No_]  = RA.[Input Parameter TMC RD 4]  AND [PRD1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter PRR1	   ON PRR1.[No_]	  = RA.[Input Parameter TMC RR 1]
LEFT JOIN @Parameter [PRR1-0] ON [PRR1-0].[No_]   = RA.[Input Parameter TMC RR 4]  AND [PRR1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter POBE1	   ON POBE1.[No_]	  = RA.[Input Parameter TMC OBE 1]
LEFT JOIN @Parameter [POBE1-0] ON [POBE1-0].[No_] = RA.[Input Parameter TMC OBE 4] AND [POBE1-0].[Threshold Value Index] = 0
	 --RP STOP
   WHERE RH.[No_] = @RebateNo
UNION
   SELECT RH.[Rebate No_] [Rebate No_]
        , RH.[Rebate-to Vendor No_]
        , VE.[Name] [Rebate-to Customer Name]
        , VE.[Name 2] [Rebate-to Customer Name 2]
        , VE.[Address] [Rebate-to Address]
        , VE.[Address 2] [Rebate-to Address 2]
        , VE.City [Rebate-to City]
        , RA.[Rebate-to Contact]
        , VE.[Post Code] [Rebate-to Post Code]
        , VE.[Country_Region Code] [Rebate-to Country_Region Code]
        , @CustList [Affiliate Partner List]
        , RH.[Currency Code]
        , RH.[Currency Factor]
        , RH.[Interval]
        , RH.[Posting Date]
        , RH.[Document Date]    
        , CASE WHEN RH.[Language Code]='' THEN CASE WHEN VE.[Language Code]='' THEN '0' ELSE VE.[Language Code] END ELSE RH.[Language Code] END [Language Code]
        , CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+1, RH.[Interval Start Date])
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END [Year Start Date]
        , DATEADD(dd,-1,CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+13, RH.[Interval Start Date]) 
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END) [Year End Date]
        , DATEADD(dd,-0,RH.[Interval Start Date]) [Till Start Date]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RH.[Document Type (Statement)]
        , RH.[Document Type (Cr_ Memo)]
        , RH.[Correspondence Type] 
        , COALESCE(BA.Name,'')                [Vendor Bank Name]
        , COALESCE(BA.[IBAN],'')              [Vendor IBAN]
        , COALESCE(BA.[SWIFT Code],'')        [Vendor SWIFT Code]
        , COALESCE(BA.[Bank Branch No_],'')   [Vendor Bank Branch No_]
        , COALESCE(BA.[Bank Account No_], '') [Vendor Bank Account No_]
        , RA.[Template Type]
        , RA.[Matrix _ Vector Code]
        , RA.[Input Parameter 1 Code]   [Code P1],  P1.[Name]  [Name P1], P1.[Value Decimal]  [Value P1], P1.[Constant Value Decimal]  [Constant Value P1]
        , RA.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], P2.[Value Decimal]  [Value P2], P2.[Constant Value Decimal]  [Constant Value P2]
        , RA.[Input Parameter 3 Code]   [Code P3],  P3.[Name]  [Name P3], P3.[Value Decimal]  [Value P3], P3.[Constant Value Decimal]  [Constant Value P3]
        , RA.[Input Parameter 4 Code]   [Code P4],  P4.[Name]  [Name P4], P4.[Value Decimal]  [Value P4], P4.[Constant Value Decimal]  [Constant Value P4]
        , RA.[Input Parameter 5 Code]   [Code P5],  P5.[Name]  [Name P5], P5.[Value Decimal]  [Value P5], P5.[Constant Value Decimal]  [Constant Value P5]
        , RA.[Input Parameter 6 Code]   [Code P6],  P6.[Name]  [Name P6], P6.[Value Decimal]  [Value P6], P6.[Constant Value Decimal]  [Constant Value P6]
        , RA.[Input Parameter 7 Code]   [Code P7],  P7.[Name]  [Name P7], P7.[Value Decimal]  [Value P7], P7.[Constant Value Decimal]  [Constant Value P7]
        , RA.[Input Parameter 8 Code]   [Code P8],  P8.[Name]  [Name P8], P8.[Value Decimal]  [Value P8], P8.[Constant Value Decimal]  [Constant Value P8]
        , RA.[Input Parameter 9 Code]   [Code P9],  P9.[Name]  [Name P9], P9.[Value Decimal]  [Value P9], P9.[Constant Value Decimal]  [Constant Value P9]
        , RA.[Input Parameter 10 Code] [Code P10],  P10.[Name] [Name P10],P10.[Value Decimal] [Value P10], P10.[Constant Value Decimal]  [Constant Value P10]
        , RA.[Output Parameter Code]    [Code PA],  PA.[Name]  [Name PA], PA.[Value Decimal]  [Value PA], PA.[Constant Value Decimal]  [Constant Value PA]
		, VE.[VAT Bus_ Posting Group]					   [VatBusPostingGroup]
		, VE.[Currency Code]							   [CurrencyCode] 	
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    'txtVATRegistrationNo'
		  ELSE
            'txtRegistrationNo'
		  END                                              [VAT Registration Label]
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    VE.[VAT Registration No_]
		  ELSE
            VE.[Registration No_]
		  END                                              [VAT Registration No_]
		, dbo.[HRS$GetSalutation](RA.[Salutation Code],CASE WHEN RH.[Language Code]='' THEN CASE WHEN VE.[Language Code]='' THEN '0' ELSE VE.[Language Code] END ELSE RH.[Language Code] END,0,1,RA.[No_])
		, COALESCE(SP.[E-Mail],'kreditoren@hrs.de')    [Salesperson E-Mail]
		, COALESCE(SP.[Fax No_],'377')                 [Salesperson Fax No_]
		, COALESCE(SP.[Name],'')                       [Salesperson Name]
		, COALESCE(SP.[Phone No_],'800')               [Salesperson Phone No_]
		, COALESCE(CR.[EU Country_Region Code],'')     [EU Country_Region Code]
		, COALESCE(CR.[Name],'')                       [Country_Region Name]
		, RH.[Online Reservation Source]
		, RH.[Offline Reservation Source]
		, RA.[Print Booking Source] 
		, RA.[Enable retroactive correction]
		, RA.[Estimated Commission]
		, dbo.fnc_RebateVectorSelection(RA.[Matrix _ Vector Code],P5.[Value Decimal]) [Vector Range]
		, CR.[EU affiliation]
		, RA.[Partner Type]
		, RA.[Group contract Code]
		, RA.[Output Reservation Source]
		, RA.[Output Commission Type]
        , @PayedRebateIntervalStartDate [Payed Rebate Interval Start Date]
        , @PayedRebateIntervalEndDate   [Payed Rebate Interval End Date]
        , RA.[Include online cancellation]
		, RA.[Include offline bookings]
		--RP START
		, RA.[Input Parameter TMC API 1]					[TMC API Base Code]
		, PAPI1.[Value Decimal]								[TMC API Base Value]
		, [PAPI1-0].[Value Decimal]							[TMC API Result Value]
		, RA.[Input Parameter TMC API 4]					[TMC API Result Code]
		, [PAPI1-0].[TMC Text]								[TMC API Text]
		, RA.[Input Parameter TMC GDS 1]					[TMC GDS Base Code]
		, PGDS1.[Value Decimal]								[TMC GDS Base Value]
		, [PGDS1-0].[Value Decimal]							[TMC GDS Result Value]
		, RA.[Input Parameter TMC GDS 4]					[TMC GDS Result Code]
		, [PGDS1-0].[TMC Text]								[TMC GDS Text]
		, RA.[Input Parameter TMC RD 1]						[TMC RD Base Code]
		, PRD1.[Value Decimal]								[TMC RD Base Value]
		, [PRD1-0].[Value Decimal]							[TMC RD Result Value]
		, RA.[Input Parameter TMC RD 4]						[TMC RD Result Code]
		, [PRD1-0].[TMC Text]								[TMC RD Text]
		, RA.[Input Parameter TMC RR 1]						[TMC RR Base Code]
		, PRR1.[Value Decimal]								[TMC RR Base Value]
		, [PRR1-0].[Value Decimal]							[TMC RR Result Value]
		, RA.[Input Parameter TMC RR 4]						[TMC RR Result Code]
		, [PRR1-0].[TMC Text]								[TMC RR Text]
		, RA.[Input Parameter TMC OBE 1]					[TMC OBE Base Code]
		, POBE1.[Value Decimal]								[TMC OBE Base Value]
		, [POBE1-0].[Value Decimal]							[TMC OBE Result Value]
		, RA.[Input Parameter TMC OBE 4]					[TMC OBE Result Code]
		, [POBE1-0].[TMC Text]								[TMC OBE Text]
		, ''												[TMC IATA Filter]
		, RA.No_											[Rebate Agreement No_]										
		--RP STOP
     FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
     JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
     JOIN [HRS$Vendor]                  VE WITH (READUNCOMMITTED) ON VE.[No_]                 = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Country_Region]          CR WITH (READUNCOMMITTED) ON CR.[Code]                = VE.[Country_Region Code]     
LEFT JOIN [BankAccount]                 BA                        ON BA.[Vendor No_]          = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Salesperson_Purchaser]   SP WITH (READUNCOMMITTED) ON SP.[Code]                = VE.[Purchaser Code]
     JOIN @Parameter P1  ON P1.[No_]  = RA.[Input Parameter 1 Code]
     JOIN @Parameter P2  ON P2.[No_]  = RA.[Input Parameter 2 Code]
     JOIN @Parameter P3  ON P3.[No_]  = RA.[Input Parameter 3 Code]
     JOIN @Parameter P4  ON P4.[No_]  = RA.[Input Parameter 4 Code]
     JOIN @Parameter P5  ON P5.[No_]  = RA.[Input Parameter 5 Code]
     JOIN @Parameter P6  ON P6.[No_]  = RA.[Input Parameter 6 Code]
     JOIN @Parameter P7  ON P7.[No_]  = RA.[Input Parameter 7 Code]
     JOIN @Parameter P8  ON P8.[No_]  = RA.[Input Parameter 8 Code]
     JOIN @Parameter P9  ON P9.[No_]  = RA.[Input Parameter 9 Code]
     JOIN @Parameter P10 ON P10.[No_] = RA.[Input Parameter 10 Code]
     JOIN @Parameter PA  ON PA.[No_]  = RA.[Output Parameter Code]
	 --RP START
LEFT JOIN @Parameter PAPI1	   ON PAPI1.[No_]	  = RA.[Input Parameter TMC API 1]
LEFT JOIN @Parameter [PAPI1-0] ON [PAPI1-0].[No_] = RA.[Input Parameter TMC API 4] AND [PAPI1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter PGDS1	   ON PGDS1.[No_]	  = RA.[Input Parameter TMC GDS 1]
LEFT JOIN @Parameter [PGDS1-0] ON [PGDS1-0].[No_] = RA.[Input Parameter TMC GDS 4] AND [PGDS1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter PRD1	   ON PRD1.[No_]	  = RA.[Input Parameter TMC RD 1]
LEFT JOIN @Parameter [PRD1-0]  ON [PRD1-0].[No_]  = RA.[Input Parameter TMC RD 4]  AND [PRD1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter PRR1	   ON PRR1.[No_]	  = RA.[Input Parameter TMC RR 1]
LEFT JOIN @Parameter [PRR1-0] ON [PRR1-0].[No_]   = RA.[Input Parameter TMC RR 4]  AND [PRR1-0].[Threshold Value Index] = 0

LEFT JOIN @Parameter POBE1	   ON POBE1.[No_]	  = RA.[Input Parameter TMC OBE 1]
LEFT JOIN @Parameter [POBE1-0] ON [POBE1-0].[No_] = RA.[Input Parameter TMC OBE 4] AND [POBE1-0].[Threshold Value Index] = 0
	 --RP STOP
   WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
END
GO
