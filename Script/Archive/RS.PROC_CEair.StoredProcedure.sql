USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CEair]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 06.02.2013
-- Description:	Liefert die Basis der EgyptAir Bonuspunkte-Abrechnung
/*
  EXECUTE [RS].[PROC_CEair] '2013-01-01', '2013-12-31'
*/
-- =============================================
CREATE PROCEDURE [RS].[PROC_CEair] 
    @DateBonusStart DATETIME = null
  , @DateBonusEnd DATETIME = null
AS 
BEGIN
  set nocount ON

  IF @DateBonusEnd IS null
  BEGIN
     SET @DateBonusEnd = GETDATE()
     SET @DateBonusEnd = DATEADD(dd,-1,DATEADD(mm,-1,DATEADD(dd,-DATEPART(dd,@DateBonusEnd)+1, @DateBonusEnd)))
  END
  IF @DateBonusStart IS null
  BEGIN
    SET @DateBonusStart = GETDATE()
    SET @DateBonusStart = DATEADD(mm,-2,DATEADD(dd,-DATEPART(dd,@DateBonusStart)+1, @DateBonusStart))
  END

--SET @DateBonusStart = '2013-01-01'
--SET @DateBonusEnd = '2013-12-31'

DECLARE @Result TABLE
(
       [TID]                                 INT
     , [Record Type]                         NCHAR(  2) -- Position   1 : Record Type
     , [FFP Program]                         NCHAR(  3) -- Position   3 : FFP Program
     , [FFP Member Number]                   NCHAR( 20) -- Position   6 : FFP Member Number
     , [FFP Member Name]                     NCHAR( 80) -- Position  25 : FFP Member Name
     , [Name check override]                 NCHAR(  1) -- Position 106 : Name check override
     , [Point Type]                          NCHAR(  2) -- Position 107 : Point Type
     , [Consume Date]                        NCHAR(  8) -- Position 109 : Consume Date
     , [Consume Times]                       NCHAR(  2) -- Position 117 : Consume Times
     , [Consume Content]                     NCHAR( 60) -- Position 119 : Consume Content
     , [Base Points]                         NCHAR( 10) -- Position 179 : Base Points
     , [Service Points]                      NCHAR( 10) -- Position 189 : Service Points
     , [Promotional Points]                  NCHAR( 10) -- Position 199 : Promotional Points
     , [Promotion Code]                      NCHAR(  8) -- Position 209 : Promotion Code
     , [Premier/ Tier/ Elite Status Points]  NCHAR( 10) -- Position 217 : Premier/ Tier/ Elite Status Points
     , [Courtesy Points]                     NCHAR( 10) -- Position 227 : Courtesy Points
     , [Point Identity Code]                 NCHAR(  1) -- Position 237 : Point Identity Code
     , [Point Source Code]                   NCHAR(  2) -- Position 238 : Point Source Code
     , [Partner Authorization Number]        NCHAR( 16) -- Position 240 : Partner Authorization Number
     , [CEAEM Reference Number]              NCHAR( 16) -- Position 256 : CEAEM Reference Number
     , [Accrual Posting Status]              NCHAR(  2) -- Position 272 : Accrual Posting Status
     , [Response Code 1]                     NCHAR(  3) -- Position 274 : Response Code
     , [Response Code 2]                     NCHAR(  3) -- Position 277 : Response Code
     , [Response Code 3]                     NCHAR(  3) -- Position 280 : Response Code
     , [Response Code 4]                     NCHAR(  3) -- Position 283 : Response Code
     , [Response Code 5]                     NCHAR(  3) -- Position 286 : Response Code
     , [Response Code 6]                     NCHAR(  3) -- Position 289 : Response Code
     , [Tier Level]                          NCHAR(  2) -- Position 292 : Tier Level
     , [Gender]                              NCHAR(  1) -- Position 292 : Tier Level
     , [Branch Code]                         NCHAR(  6) -- Position 295 : Branch Code
     , [Filler]                              NCHAR(100) -- Position 301 : Filler
     , [Partner Additional Info]             NCHAR(100) -- Position 401 : Partner Additional Info
)

DECLARE @Detail TABLE
(
       [TID]                                 INT
     , [Detail]                              NCHAR(500)
)

;WITH AP AS
(
   SELECT AP.[ReservationNo]
        , CAST(CAST(ROUND(SUM(AP.[Turnover_corr])/10*5,0) AS INT) AS varchar(10))    [Base Points]
        , MAX(COALESCE(AffiliateReference1,''))                 [CID]
        , MAX(UPPER(REPLACE(COALESCE(UC.[Kunde Gastname 1],AP.[Description]),', ','/'))) [Gast 1 Name]
        , MAX(AP.[DepartureDate])                               [Departure Date]
     FROM [HRS$Affiliate Postings]   AP WITH (NOLOCK)
LEFT JOIN [ReservationUnicodeFields] UC WITH (NOLOCK)
       ON UC.[Reservierungsnr_] = AP.[ReservationNo]
    WHERE AffiliatePartnerNo = 860000437
      AND DepartureDate BETWEEN @DateBonusStart AND @DateBonusEnd
 GROUP BY AP.[ReservationNo]
   HAVING SUM(AP.[Turnover_corr]) > 0
UNION 
   SELECT AP.[ReservationNo]
        , CAST(CAST(ROUND(SUM(AP.[Turnover_corr])/10*5,0) AS INT) AS varchar(10))    [Base Points]
        , MAX(COALESCE(AffiliateReference1,''))                 [CID]
        , MAX(UPPER(REPLACE(COALESCE(UC.[Kunde Gastname 1],AP.[Description]),', ','/'))) [Gast 1 Name]
        , MAX(AP.[DepartureDate])                               [Departure Date]
     FROM [HRS-CN$Affiliate Postings] AP
LEFT JOIN [ReservationUnicodeFields] UC WITH (NOLOCK)
       ON UC.[Reservierungsnr_] = AP.[ReservationNo]
    WHERE AffiliatePartnerNo = 860000437
      AND DepartureDate BETWEEN @DateBonusStart AND @DateBonusEnd
 GROUP BY AP.[ReservationNo]
   HAVING SUM(AP.[Turnover_corr]) > 0
UNION 
   SELECT AP.[ReservationNo]
        , CAST(CAST(ROUND(SUM(AP.[Turnover_corr])/10*5,0) AS INT) AS varchar(10))    [Base Points]
        , MAX(COALESCE(AffiliateReference1,''))                 [CID]
        , MAX(UPPER(REPLACE(COALESCE(UC.[Kunde Gastname 1],AP.[Description]),', ','/'))) [Gast 1 Name]
        , MAX(AP.[DepartureDate])                               [Departure Date]
     FROM [HRS-BR$Affiliate Postings] AP
LEFT JOIN [ReservationUnicodeFields] UC WITH (NOLOCK)
       ON UC.[Reservierungsnr_] = AP.[ReservationNo]
    WHERE AffiliatePartnerNo = 860000437
      AND DepartureDate BETWEEN @DateBonusStart AND @DateBonusEnd
 GROUP BY AP.[ReservationNo]
   HAVING SUM(AP.[Turnover_corr]) > 0
), Pre AS
(
SELECT ROW_NUMBER() OVER(ORDER BY [ReservationNo])                   [TID]
     , LEFT(REPLACE([CID],'MU','')+REPLICATE(' ',20),20)             [FFP Member Number]
     , [Gast 1 Name]
     + REPLICATE(' ',80-LEN([Gast 1 Name]))                          
     [FFP Member Name]
     , CONVERT(varchar(8),[Departure Date],112)                      [Consume Date]
     , REPLICATE('0',10-LEN([Base Points])) + [Base Points]          [Base Points]
     , REPLICATE('0',16-LEN(CAST([ReservationNo] AS varchar(16)))) + CAST([ReservationNo] AS varchar(16)) [ReservationNo]
     , [Gast 1 Name]
  FROM AP  
 WHERE [CID] LIKE '%[0-9]%'
--   AND [CID] IN ('620500947363        ', '610250115403        ')
)
INSERT INTO @Result
SELECT TID
     , '02'                [Record Type]                         -- Position   1 : Record Type
     , 'MU '               [FFP Program]                         -- Position   3 : FFP Program
     ,                     [FFP Member Number]                   -- Position   6 : FFP Member Number
     ,                     [FFP Member Name]                     -- Position  25 : FFP Member Name
     , 'N'                 [Name check override]                 -- Position 106 : Name check override
     , '01'                [Point Type]                          -- Position 107 : Point Type
     ,                     [Consume Date]                        -- Position 109 : Consume Date
     , '01'                [Consume Times]                       -- Position 117 : Consume Times
     , REPLICATE(' ',60)   [Consume Content]                     -- Position 119 : Consume Content
     ,                     [Base Points]                         -- Position 179 : Base Points
     , REPLICATE('0',10)   [Service Points]                      -- Position 189 : Service Points
     , REPLICATE('0',10)   [Promotional Points]                  -- Position 199 : Promotional Points
     , REPLICATE(' ', 8)   [Promotion Code]                      -- Position 209 : Promotion Code
     , REPLICATE('0',10)   [Premier/ Tier/ Elite Status Points]  -- Position 217 : Premier/ Tier/ Elite Status Points
     , REPLICATE('0',10)   [Courtesy Points]                     -- Position 227 : Courtesy Points
     , 'A'                 [Point Identity Code]                 -- Position 237 : Point Identity Code
     , '02'                [Point Source Code]                   -- Position 238 : Point Source Code
     , [ReservationNo]     [Partner Authorization Number]        -- Position 240 : Partner Authorization Number
     , REPLICATE(' ',16)   [CEAEM Reference Number]              -- Position 256 : CEAEM Reference Number
     , '00'                [Accrual Posting Status]              -- Position 272 : Accrual Posting Status
     , '000'               [Response Code 1]                     -- Position 274 : Response Code
     , '000'               [Response Code 2]                     -- Position 277 : Response Code
     , '000'               [Response Code 3]                     -- Position 280 : Response Code
     , '000'               [Response Code 4]                     -- Position 283 : Response Code
     , '000'               [Response Code 5]                     -- Position 286 : Response Code
     , '000'               [Response Code 6]                     -- Position 289 : Response Code
     , '  '                [Tier Level]                          -- Position 292 : Tier Level
     , ' '                 [Gender]                              -- Position 294 : Gender
     , REPLICATE(' ',  6)  [Branch Code]                         -- Position 295 : Branch Code
     , REPLICATE(' ',100)  [Filler]                              -- Position 301 : Filler
     , REPLICATE(' ',100)  [Partner Additional Info]          -- Position 401 : Partner Additional Info
  FROM Pre

INSERT INTO @Detail  
SELECT TID 
     , [Record Type]
     + [FFP Program]
     + [FFP Member Number]
     + [FFP Member Name]
     + [Name check override]
     + [Point Type]
     + [Consume Date]
     + [Consume Times]
     + [Consume Content]
     + [Base Points]
     + [Service Points]                      
     + [Promotional Points]                  
     + [Promotion Code]                      
     + [Premier/ Tier/ Elite Status Points]  
     + [Courtesy Points]                     
     + [Point Identity Code]                 
     + [Point Source Code]                   
     + [Partner Authorization Number]        
     + [CEAEM Reference Number]              
     + [Accrual Posting Status]              
     + [Response Code 1]                     
     + [Response Code 2]                     
     + [Response Code 3]                     
     + [Response Code 4]                     
     + [Response Code 5]                     
     + [Response Code 6]                     
     + [Tier Level]                          
     + [Gender]                              
     + [Branch Code]                         
     + [Filler]                              
     + [Partner Additional Info]   
       [Detail]         
  FROM @Result 
  
DECLARE @ResultHeader TABLE
(
       [Record Type]                         NCHAR(  2) -- Position   1 : Record Type
     , [File Type]                           NCHAR(  2) -- Position   3 : File Type
     , [Delivery Sequence Number]            NCHAR(  5) -- Position   5 : Delivery Sequence Number
     , [Sender]                              NCHAR( 20) -- Position  10 : Sender
     , [Receiver]                            NCHAR( 20) -- Position  30 : Receiver
     , [Partner Sub ID]                      NCHAR(  2) -- Position  50 : Partner Sub ID
     , [Create Date]                         NCHAR(  8) -- Position  52 : Create Date
     , [Version]                             NCHAR(  2) -- Position  60 : Version
     , [Partner reference]                   NCHAR( 16) -- Position  62 : Partner reference
     , [Filler]                              NCHAR(423) -- Position  78 : Filler
)
INSERT INTO @ResultHeader
SELECT '01'                [Record Type]                -- Position   1 : Record Type
     , '01'                [File Type]                  -- Position   3 : File Type
     , RIGHT(
       REPLICATE('0',5)
     + CAST(MONTH(GETDATE()) + (YEAR(GETDATE())-2014) * 12 AS VARCHAR(5))
       ,5)                 [Delivery Sequence Number]   -- Position   5 : Delivery Sequence Number
     , 'REGALIA'           [Sender]                     -- Position  10 : Sender
     , 'CEAEM'             [Receiver]                   -- Position  30 : Receiver
     , '00'                [Partner Sub ID]             -- Position  50 : Partner Sub ID
     , CONVERT(varchar(8),GETDATE(),112) [Create Date]  -- Position  52 : Create Date
     , '01'                [Version]                    -- Position  60 : Version
     , REPLICATE(' ', 16)  [Partner reference]          -- Position  62 : Partner reference
     , REPLICATE(' ',423)  [Filler]                     -- Position  78 : Filler

INSERT INTO @Detail
SELECT 0
     , [Record Type]
     + [File Type]
     + [Delivery Sequence Number]
     + [Sender]
     + [Receiver]
     + [Partner Sub ID]
     + [Create Date]
     + [Version]
     + [Partner reference]
     + [Filler]
  FROM @ResultHeader
  
DECLARE @ResultFooter TABLE
(
       [Record Type]                         NCHAR(  2) -- Position   1 : Record Type
     , [Total number of records]             NCHAR(  9) -- Position   3 : Total number of records
     , [Number of accepted without changes]  NCHAR(  9) -- Position  12 : Number of accepted without changes
     , [Number of accepted with changes]     NCHAR(  9) -- Position  21 : Number of accepted with changes
     , [Number of rejected records]          NCHAR(  9) -- Position  30 : Number of rejected records
     , [Filler]                              NCHAR(462) -- Position  39 : Filler
)
INSERT INTO @ResultFooter
SELECT '03'                [Record Type]                -- Position   1 : Record Type
     , RIGHT(
       REPLICATE('0',9)
     + CAST((SELECT COUNT(1) FROM @Result) AS VARCHAR(9))
       , 9)               [Total number of records]            -- Position   3 : Total number of records
     , REPLICATE('0',9  )  [Number of accepted without changes] -- Position  12 : Number of accepted without changes
     , REPLICATE('0',9  )  [Number of accepted with changes]    -- Position  21 : Number of accepted with changes
     , REPLICATE('0',9  )  [Number of rejected records]         -- Position  30 : Number of rejected records
     , REPLICATE(' ',462)  [Filler]                             -- Position  39 : Filler
     
INSERT INTO @Detail
SELECT 999999999
     , [Record Type]
     + [Total number of records]
     + [Number of accepted without changes]
     + [Number of accepted with changes]
     + [Number of rejected records]
     + [Filler]
  FROM @ResultFooter
  
  SELECT [TID], [Detail] FROM @Detail ORDER BY TID

  set nocount off 

END
GO
