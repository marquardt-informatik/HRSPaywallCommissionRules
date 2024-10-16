USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebatePayedRebateBlock2_HDE]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Kopfinformationen zur Gutschriftsanzeige
/*
EXEC [dbo].[sp_RebatePayedRebateBlock2_HDE] 'K0000003874/02'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebatePayedRebateBlock2_HDE] 
    @RebateNo varchar(20)
AS
BEGIN
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
    AND RH.Cancels = 0

DECLARE @Parameter TABLE
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

DECLARE @Result TABLE
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
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
   AND AH.[Enable retroactive correction] = 1
UNION 
SELECT AH.*
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
   AND AH.[Enable retroactive correction] = 1
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
     AND RH.Cancels = 0
)
INSERT INTO @Parameter
SELECT * FROM RL
 WHERE ','+@ParameterList+',' LIKE '%,' + [No_] + ',%'

INSERT INTO @Parameter
SELECT '','',0.0,'' UNION
SELECT PM.[Rebate No_],PA.[Code], PA.[Value Decimal], PA.[Name]
  FROM [hotel_de$Parameter] PA WITH (NOLOCK), (SELECT DISTINCT [Rebate No_] FROM @Parameter) PM
 WHERE ','+@ParameterList+',' LIKE '%,' + PA.[Code] + ',%'
   AND NOT PA.[Code] IN (SELECT [No_] FROM @Parameter)

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
  FROM [hotel_de$Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
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
  FROM [hotel_de$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
), _ALL AS
(
--   SELECT RH.[Posting Date]
--        , 0[Value Decimal]
--        , RH.[Interval Start Date]
--        , RH.[Interval End Date]
--        , AH.[Input Parameter 1 Code]   [Code P1]
--        , AH.[Input Parameter 2 Code]   [Code P2]
--        , AH.[Input Parameter 3 Code]   [Code P3]
--        , AH.[Input Parameter 4 Code]   [Code P4]
--        , AH.[Input Parameter 5 Code]   [Code P5]
--        , AH.[Input Parameter 6 Code]   [Code P6]
--        , AH.[Input Parameter 7 Code]   [Code P7]
--        , AH.[Input Parameter 8 Code]   [Code P8]
--        , AH.[Input Parameter 9 Code]   [Code P9]
--        , AH.[Input Parameter 10 Code] [Code P10]
--        , AH.[Output Parameter Code]    [Code PA]
--        , 0 [State]
--        , AH.[Rebate No_]
--        , RH.[No_] [Past Rebate No_]
--     FROM [hotel_de$Rebate Header] RH
--     JOIN AgreementHeader AH
--       ON AH.[No_] = RH.[Rebate Agreement No_]
--      AND RH.[Document Date] >= AH.[Year Start Date] 
--      AND RH.[Document Date] <  AH.[Posting Date]
--    WHERE RH.[No_] <> @RebateNo
--UNION   
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
     FROM [hotel_de$Rebate Header] RH
     JOIN [hotel_de$Rebate Reserve Entry] RE
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
     FROM [hotel_de$Posted Rebate Header] RH
     JOIN AgreementHeader AH
       ON AH.[No_] = RH.[Rebate Agreement No_]
      AND RH.[Document Date] >= AH.[Year Start Date] 
      AND RH.[Document Date] <=  AH.[Document Date]
      AND RH.[Posting Date] <  AH.[Posting Date]
LEFT JOIN [hotel_de$G_L Entry] GLE WITH (NOLOCK)
       ON GLE.[Posting Date] = AH.[Posting Date]
      AND GLE.[Document No_] = RH.[Rebate No_]
      AND GLE.[Source No_]   = AH.[Rebate-to Vendor No_]
      AND GLE.Amount         > 0
LEFT JOIN [hotel_de$Rebate Setup] RS WITH (NOLOCK)
       ON (RS.[Account No_ Reserve] = GLE.[G_L Account No_])
	   OR GLE.[G_L Account No_]       ='472500'
       OR RH.[Statement Posting Type] = 2
    WHERE RH.[Cancels] = 0
      AND RH.[Rebate No_] <> @RebateNo
      AND RH.[No_] <> @RebateNo
      AND NOT GLE.[Posting Date] IS NULL
)
INSERT INTO @Result ([Posting Date], [Value Decimal], [Interval Start Date], [Interval End Date], [State], [Rebate No_], [Code P1], [Code P2], [Code P3], [Code P4], [Code P5], [Code P6], [Code P7], [Code P8], [Code P9], [Code P10], [Code PA])
SELECT [Posting Date], [Value Decimal], [Interval Start Date], [Interval End Date], [State], [Rebate No_], [Code P1], [Code P2], [Code P3], [Code P4], [Code P5], [Code P6], [Code P7], [Code P8], [Code P9], [Code P10], [Code PA]
  FROM _ALL

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
  
  SELECT * FROM @Result ORDER BY [Interval Start Date]   
END

GO
