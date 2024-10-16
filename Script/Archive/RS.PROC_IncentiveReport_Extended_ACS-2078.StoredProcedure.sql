USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_IncentiveReport_Extended_ACS-2078]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ================================================
-- Author:		Dennis Juhr / Sascha Altgeld
-- Create date: 29.03.2019
-- Description:	Incentive Report Extended
--              Zusammenfassung aller geb. Bonus-Dokumente
-- 
-- 01.04.2019 HRS001 ACS-1746 - get offline Sources from Source Class
-- 01.04.2019 HRS002 ACS-1746 - get RV_SATZ from $Rebate Line
-- 03.04.2019 HRS003 ACS-1746 - removed Filter on Posting Type "Proforma"
-- 07.01.2020 HRS004 ACS-2078 - separated source 613
-- 08.01.2020 HRS005 ACS-2078 - added offline sources
--
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'EXTDJU02'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 50119
EXEC [RS].[PROC_IncentiveReport_Extended_ACS-2078] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_IncentiveReport_Extended_ACS-2078] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

--BEGIN Perioden in Variablen eintragen
DECLARE
	@DateEnd			DATETIME
  , @DateStart			DATETIME
  , @DateFilterStart	DATETIME
  , @DateFilterEnd		DATETIME
SET @DateStart = CAST(CAST(YEAR(GETDATE())-1 AS VARCHAR(4))+'-01-01' AS DATETIME)
SET @DateEnd = DATEADD(dd,-1,DATEADD(YEAR,1,@DateStart))

--BEGIN Filter aus den FlowFilter
SET @DateStart = COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
		AND [Field ID]  = 1), @DateStart);	    

SET @DateEnd = COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 2), @DateEnd);	

SET Language English

PRINT @DateStart
PRINT @DateEnd

--HRS002 >>
--;WITH RV AS
--(
--  SELECT RL.[Rebate Agreement No_]
--       , MAX([Value Decimal]/100.)                  [Configurated Revenue Share Rate]
--    FROM [HRS$Posted Rebate Line]   RL WITH (NOLOCK)
--    JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK)
--      ON RH.[No_] = RL.[Document No_]
--   WHERE RL.[No_]   = 'RV_SATZ'
--     AND RL.[Type] IN (1,2)
--     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
--GROUP BY RL.[Rebate Agreement No_]

DECLARE @Result Table
(
		  [Rebate No_]					varchar(150)
		, [Rebate-to Vendor No_]		varchar(150)
        , [Rebate-to Customer Name]		varchar(150)
        , [Rebate-to Customer Name 2]	varchar(150)
        , [Rebate-to Address]			varchar(150)
        , [Rebate-to Address 2]			varchar(150)
        , [Rebate-to City]				varchar(150)
        , [Rebate-to Contact]			varchar(150)
        , [Rebate-to Post Code]			varchar(150)
        , [Rebate-to Country_Region Code]	varchar(10)
        , [Affiliate Partner List]		varchar(max)
        , [Currency Code]				varchar(10)
        , [Currency Factor]				DEC(37,20)
        , [Interval]					INT
        , [Posting Date]				datetime
        , [Document Date]				datetime
        , [Language Code]				varchar(10)
        , [Year Start Date]				datetime		
        , [Year End Date]				datetime		
        , [Till Start Date]				datetime
        , [Interval Start Date]				datetime
        , [Interval End Date]				datetime
        , [Document Type (Statement)]		int
        , [Document Type (Cr_ Memo)]		int
        , [Correspondence Type]				int
        , [Vendor Bank Name]				varchar(150)			
        , [Vendor IBAN]						varchar(150)
        , [Vendor SWIFT Code]				varchar(150)
        , [Vendor Bank Branch No_]			varchar(150)
        , [Vendor Bank Account No_]			varchar(150)	
        , [Template Type]					int
        , [Matrix _ Vector Code]			varchar(150)
        , [Code P1]							varchar(100)
		, [Name P1]							varchar(100)
        , [Value P1]						DEC(37,20)
        , [Constant Value P1] DEC(37,20)
        , [Code P2]							varchar(100)
		, [Name P2]							varchar(100)
        , [Value P2]						DEC(37,20)
        , [Constant Value P2] DEC(37,20)
        , [Code P3]							varchar(100)
		, [Name P3]							varchar(100)
        , [Value P3]						DEC(37,20)
        , [Constant Value P3] DEC(37,20)
        , [Code P4]							varchar(100)
		, [Name P4]							varchar(100)
        , [Value P4]						DEC(37,20)
        , [Constant Value P4] DEC(37,20)
        , [Code P5]							varchar(100)
		, [Name P5]							varchar(100)
        , [Value P5]						DEC(37,20)
        , [Constant Value P5] DEC(37,20)
        , [Code P6]							varchar(100)
		, [Name P6]							varchar(100)
        , [Value P6]						DEC(37,20)
        , [Constant Value P6] DEC(37,20)
        , [Code P7]							varchar(100)
		, [Name P7]							varchar(100)
        , [Value P7]						DEC(37,20)
        , [Constant Value P7] DEC(37,20)
        , [Code P8]							varchar(100)
		, [Name P8]							varchar(100)
        , [Value P8]						DEC(37,20)
        , [Constant Value P8] DEC(37,20)
        , [Code P9]							varchar(100)
		, [Name P9]							varchar(100)
        , [Value P9]						DEC(37,20)
        , [Constant Value P9] DEC(37,20)
        , [Code P10]							varchar(100)
		, [Name P10]							varchar(100)
        , [Value P10]						DEC(37,20)
        , [Constant Value P10] DEC(37,20)
        , [Code PA]							varchar(100)
		, [Name PA]							varchar(100)
        , [Value PA]						DEC(37,20)
        , [Constant Value PA] DEC(37,20)
		, [VatBusPostingGroup]	varchar(10)
		, [CurrencyCode] 	varchar(10)
		, [VAT Registration Label] varchar(30)
		, [VAT Registration No_] varchar(30)
		, [Salutation Code] varchar(150)
		, [Salesperson E-Mail] varchar(150)
		, [Salesperson Fax No_] varchar(150)
		, [Salesperson Name] varchar(150)
		, [Salesperson Phone No_] varchar(150)
		, [EU Country_Region Code] varchar(150)
		, [Country_Region Name] varchar(150)
		, [Online Reservation Source] varchar(150)
		, [Offline Reservation Source] varchar(150)
		, [Print Booking Source]  varchar(150)
		, [Enable retroactive correction] varchar(150)
		, [Estimated Commission] varchar(150)
		, [Vector Range] varchar(150)
		, [EU affiliation] INT
		, [Partner Type] INT
		, [Group contract Code] varchar(150)
		, [Output Reservation Source] varchar(150)
		, [Output Commission Type] int
        , [Payed Rebate Interval Start Date] datetime	
        , [Payed Rebate Interval End Date] datetime	
        , [Include online cancellation] int
		, [Include offline bookings] int
		, [TMC API Base Code] varchar(150)
		, [TMC API Base Value] DEC(37,20)
		, [TMC API Result Value] DEC(37,20)
		, [TMC API Result Code] varchar(150)
		, [TMC API Text] varchar(max)
		, [TMC GDS Base Code] varchar(150)
		, [TMC GDS Base Value] DEC(37,20)
		, [TMC GDS Result Value] DEC(37,20)
		, [TMC GDS Result Code] varchar(150)
		, [TMC GDS Text] varchar(max)
		, [TMC RD Base Code] varchar(150)
		, [TMC RD Base Value] DEC(37,20)
		, [TMC RD Result Value] DEC(37,20)
		, [TMC RD Result Code] varchar(150)
		, [TMC RD Text] varchar(max)
		, [TMC RR Base Code] varchar(150)
		, [TMC RR Base Value] DEC(37,20)
		, [TMC RR Result Value] DEC(37,20)
		, [TMC RR Result Code]  varchar(150)
		, [TMC RR Text] varchar(max)
		, [TMC OBE Base Code] varchar(150)
		, [TMC OBE Base Value] DEC(37,20)
		, [TMC OBE Result Value] DEC(37,20)
		, [TMC OBE Result Code] varchar(150)
		, [TMC OBE Text] varchar(max)
		, [TMC IATA Filter] varchar(2500)
		, [Rebate Agreement No_] varchar(30)
)

CREATE TABLE #ResultBuffer
(
		  [Rebate No_]					varchar(150)
		, [Rebate-to Vendor No_]		varchar(150)
        , [Rebate-to Customer Name]		varchar(150)
        , [Rebate-to Customer Name 2]	varchar(150)
        , [Rebate-to Address]			varchar(150)
        , [Rebate-to Address 2]			varchar(150)
        , [Rebate-to City]				varchar(150)
        , [Rebate-to Contact]			varchar(150)
        , [Rebate-to Post Code]			varchar(150)
        , [Rebate-to Country_Region Code]	varchar(10)
        , [Affiliate Partner List]		varchar(max)
        , [Currency Code]				varchar(10)
        , [Currency Factor]				DEC(37,20)
        , [Interval]					INT
        , [Posting Date]				datetime
        , [Document Date]				datetime
        , [Language Code]				varchar(10)
        , [Year Start Date]				datetime		
        , [Year End Date]				datetime		
        , [Till Start Date]				datetime
        , [Interval Start Date]				datetime
        , [Interval End Date]				datetime
        , [Document Type (Statement)]		int
        , [Document Type (Cr_ Memo)]		int
        , [Correspondence Type]				int
        , [Vendor Bank Name]				varchar(150)			
        , [Vendor IBAN]						varchar(150)
        , [Vendor SWIFT Code]				varchar(150)
        , [Vendor Bank Branch No_]			varchar(150)
        , [Vendor Bank Account No_]			varchar(150)	
        , [Template Type]					int
        , [Matrix _ Vector Code]			varchar(150)
        , [Code P1]							varchar(100)
		, [Name P1]							varchar(100)
        , [Value P1]						DEC(37,20)
        , [Constant Value P1] DEC(37,20)
        , [Code P2]							varchar(100)
		, [Name P2]							varchar(100)
        , [Value P2]						DEC(37,20)
        , [Constant Value P2] DEC(37,20)
        , [Code P3]							varchar(100)
		, [Name P3]							varchar(100)
        , [Value P3]						DEC(37,20)
        , [Constant Value P3] DEC(37,20)
        , [Code P4]							varchar(100)
		, [Name P4]							varchar(100)
        , [Value P4]						DEC(37,20)
        , [Constant Value P4] DEC(37,20)
        , [Code P5]							varchar(100)
		, [Name P5]							varchar(100)
        , [Value P5]						DEC(37,20)
        , [Constant Value P5] DEC(37,20)
        , [Code P6]							varchar(100)
		, [Name P6]							varchar(100)
        , [Value P6]						DEC(37,20)
        , [Constant Value P6] DEC(37,20)
        , [Code P7]							varchar(100)
		, [Name P7]							varchar(100)
        , [Value P7]						DEC(37,20)
        , [Constant Value P7] DEC(37,20)
        , [Code P8]							varchar(100)
		, [Name P8]							varchar(100)
        , [Value P8]						DEC(37,20)
        , [Constant Value P8] DEC(37,20)
        , [Code P9]							varchar(100)
		, [Name P9]							varchar(100)
        , [Value P9]						DEC(37,20)
        , [Constant Value P9] DEC(37,20)
        , [Code P10]							varchar(100)
		, [Name P10]							varchar(100)
        , [Value P10]						DEC(37,20)
        , [Constant Value P10] DEC(37,20)
        , [Code PA]							varchar(100)
		, [Name PA]							varchar(100)
        , [Value PA]						DEC(37,20)
        , [Constant Value PA] DEC(37,20)
		, [VatBusPostingGroup]	varchar(10)
		, [CurrencyCode] 	varchar(10)
		, [VAT Registration Label] varchar(30)
		, [VAT Registration No_] varchar(30)
		, [Salutation Code] varchar(150)
		, [Salesperson E-Mail] varchar(150)
		, [Salesperson Fax No_] varchar(150)
		, [Salesperson Name] varchar(150)
		, [Salesperson Phone No_] varchar(150)
		, [EU Country_Region Code] varchar(150)
		, [Country_Region Name] varchar(150)
		, [Online Reservation Source] varchar(150)
		, [Offline Reservation Source] varchar(150)
		, [Print Booking Source]  varchar(150)
		, [Enable retroactive correction] varchar(150)
		, [Estimated Commission] varchar(150)
		, [Vector Range] varchar(150)
		, [EU affiliation] INT
		, [Partner Type] INT
		, [Group contract Code] varchar(150)
		, [Output Reservation Source] varchar(150)
		, [Output Commission Type] int
        , [Payed Rebate Interval Start Date] datetime	
        , [Payed Rebate Interval End Date] datetime	
        , [Include online cancellation] int
		, [Include offline bookings] int
		, [TMC API Base Code] varchar(150)
		, [TMC API Base Value] DEC(37,20)
		, [TMC API Result Value] DEC(37,20)
		, [TMC API Result Code] varchar(150)
		, [TMC API Text] varchar(max)
		, [TMC GDS Base Code] varchar(150)
		, [TMC GDS Base Value] DEC(37,20)
		, [TMC GDS Result Value] DEC(37,20)
		, [TMC GDS Result Code] varchar(150)
		, [TMC GDS Text] varchar(max)
		, [TMC RD Base Code] varchar(150)
		, [TMC RD Base Value] DEC(37,20)
		, [TMC RD Result Value] DEC(37,20)
		, [TMC RD Result Code] varchar(150)
		, [TMC RD Text] varchar(max)
		, [TMC RR Base Code] varchar(150)
		, [TMC RR Base Value] DEC(37,20)
		, [TMC RR Result Value] DEC(37,20)
		, [TMC RR Result Code]  varchar(150)
		, [TMC RR Text] varchar(max)
		, [TMC OBE Base Code] varchar(150)
		, [TMC OBE Base Value] DEC(37,20)
		, [TMC OBE Result Value] DEC(37,20)
		, [TMC OBE Result Code] varchar(150)
		, [TMC OBE Text] varchar(max)
		, [TMC IATA Filter] varchar(2500)
		, [Rebate Agreement No_] varchar(30)
)

CREATE TABLE #RebateNumbers
(
	    No_						VARCHAR(20) Primary Key Not Null
	  , [Rebate Agreement No_]	VARCHAR(20)
	  , [Vendor No_]			VARCHAR(20)
)

PRINT('After DECLARE')

DECLARE cur CURSOR LOCAL for
	SELECT DISTINCT RA.No_, RA.[Enable retroactive correction] 
	FROM [HRS$Rebate Agreement Header] RA with (readuncommitted)
	JOIN (SELECT [Rebate Agreement No_], [Document Date], Cancels
	      FROM [HRS$Posted Rebate Header] with (readuncommitted)
		  UNION
		  SELECT [Rebate Agreement No_], [Document Date], 0 [Cancels]
	      FROM [HRS$Rebate Header] with (readuncommitted)) RH
	ON RH.[Rebate Agreement No_] = RA.No_
	WHERE RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	AND RH.Cancels = 0
    AND RA.[Group contract Code] <> 'GDS'

DECLARE @RANo VARCHAR(20)
DECLARE @pRebNo VARCHAR(20)
DECLARE @VNo VARCHAR(20)
DECLARE @YTD int
DECLARE @DocumentDate datetime
--SELECT @ReNr = 'K0000045846/01'

--INSERT INTO @Result 
--EXEC [dbo].[sp_RebateHeader] @ReNr

open cur 
fetch next from cur into @RANo, @YTD
while @@FETCH_STATUS = 0 BEGIN
    if (@YTD = 1) BEGIN
		SET @pRebNo = ''
		SELECT TOP 1 @pRebNo = RH.[Rebate No_], @VNo = RA.[Rebate-to Vendor No_], @DocumentDate = RH.[Document Date]
		FROM [HRS$Rebate Agreement Header] RA with (readuncommitted)
		JOIN [HRS$Posted Rebate Header] RH with (readuncommitted)
		ON RH.[Rebate Agreement No_] = RA.No_
		WHERE RA.No_ = @RANo
		AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
		AND RH.Cancels = 0
	    AND RA.[Group contract Code] <> 'GDS'
		ORDER BY RH.[Document Date] DESC
	
		if (@pRebNo = '') BEGIN
			SELECT TOP 1 @pRebNo = RH.[No_], @VNo = RA.[Rebate-to Vendor No_], @DocumentDate = RH.[Document Date]
			FROM [HRS$Rebate Agreement Header] RA with (readuncommitted)
			JOIN [HRS$Rebate Header] RH with (readuncommitted)
			ON RH.[Rebate Agreement No_] = RA.No_
			WHERE RA.No_ = @RANo
			AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
			AND RA.[Group contract Code] <> 'GDS'
			ORDER BY RH.[Document Date] DESC
		END
		ELSE BEGIN
			SELECT TOP 1 @pRebNo = RH.[No_], @VNo = RA.[Rebate-to Vendor No_], @DocumentDate = RH.[Document Date]
			FROM [HRS$Rebate Agreement Header] RA with (readuncommitted)
			JOIN [HRS$Rebate Header] RH with (readuncommitted)
			ON RH.[Rebate Agreement No_] = RA.No_
			WHERE RA.No_ = @RANo
			AND RH.[Document Date] BETWEEN @DocumentDate AND @DateEnd
			AND RA.[Group contract Code] <> 'GDS'
			ORDER BY RH.[Document Date] DESC
		END

		PRINT(@pRebNo)
		--execute your sproc on each row
		INSERT INTO @Result 
		EXEC [dbo].[sp_RebateHeader_Special] @pRebNo 
	END

	if (@YTD = 0) BEGIN
		SET @pRebNo = ''	
		TRUNCATE TABLE #RebateNumbers
		TRUNCATE TABLE #ResultBuffer

		INSERT #RebateNumbers
		SELECT RH.[Rebate No_], RA.No_, RA.[Rebate-to Vendor No_]
		  FROM [HRS$Rebate Agreement Header] RA with (readuncommitted)
		  JOIN [HRS$Posted Rebate Header] RH with (readuncommitted) ON RH.[Rebate Agreement No_] = RA.No_
		 WHERE RA.No_ = @RANo
		   AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
		   AND RH.Cancels = 0
		   AND RA.[Group contract Code] <> 'GDS'

		INSERT #RebateNumbers
		SELECT RH.[No_], RA.No_, RA.[Rebate-to Vendor No_]
		  FROM [HRS$Rebate Agreement Header] RA with (readuncommitted)
		  JOIN [HRS$Rebate Header] RH with (readuncommitted) ON RH.[Rebate Agreement No_] = RA.No_
		 WHERE RA.No_ = @RANo
		   AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
		   AND RA.[Group contract Code] <> 'GDS'
		
		DECLARE @LocRebNo VARCHAR(20)
		While Exists (Select * FROM #RebateNumbers) BEGIN
			SELECT @LocRebNo = MAX([No_]) FROM #RebateNumbers
			INSERT INTO #ResultBuffer
			EXEC [dbo].[sp_RebateHeader_Special] @LocRebNo;
			DELETE #RebateNumbers WHERE No_ = @LocRebNo
		END

		INSERT @Result ([Rebate No_], [Rebate-to Vendor No_], [TMC API Base Value], [TMC API Result Value], [TMC GDS Base Value], [TMC GDS Result Value], [TMC RD Base Value] 
                      , [TMC RD Result Value], [TMC RR Base Value], [TMC RR Result Value], [TMC OBE Base Value], [TMC OBE Result Value], [Rebate Agreement No_])
        SELECT MAX([Rebate No_]), MAX([Rebate-to Vendor No_]), SUM([TMC API Base Value]), SUM([TMC API Result Value]), SUM([TMC GDS Base Value]), SUM([TMC GDS Result Value]), SUM([TMC RD Base Value]) 
             , SUM([TMC RD Result Value]), SUM([TMC RR Base Value]), SUM([TMC RR Result Value]), SUM([TMC OBE Base Value]), SUM([TMC OBE Result Value]), MAX([Rebate Agreement No_])
        FROM #ResultBuffer

    END

    fetch next from cur into @RANo, @YTD
END

close cur
deallocate cur


;WITH _RV AS
(
  SELECT RL.[Rebate Agreement No_]
       , MAX([Value Decimal]/100.)                  [Configurated Revenue Share Rate]
    FROM [HRS$Posted Rebate Line]   RL WITH (NOLOCK)
    JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK)
      ON RH.[No_] = RL.[Document No_]
   WHERE RL.[No_]   = 'RV_SATZ'
     AND RL.[Type] IN (1,2)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
GROUP BY RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Rebate Agreement No_]
       , MAX([Value Decimal]/100.)                  [Configurated Revenue Share Rate]
    FROM [HRS$Rebate Line]   RL WITH (NOLOCK)
    JOIN [HRS$Rebate Header] RH WITH (NOLOCK)
      ON RH.[No_] = RL.[Document No_]
   WHERE RL.[No_]   = 'RV_SATZ'
     AND RL.[Type] IN (1,2)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
GROUP BY RL.[Rebate Agreement No_]
), RV AS(
  SELECT [Rebate Agreement No_]
       , MAX([Configurated Revenue Share Rate])     [Configurated Revenue Share Rate]
    FROM _RV
GROUP BY [Rebate Agreement No_]
--HRS002 <<
UNION
  SELECT AH.[No_]                                   [Rebate Agreement No_]
       , PV.[Value Decimal]/100.                    [Configurated Revenue Share Rate]
    FROM [HRS$Rebate Agreement Header] AH WITH (READUNCOMMITTED)
    JOIN [HRS$Posted Rebate Header]    RH WITH (NOLOCK)          ON RH.[Rebate Agreement No_] = AH.[No_]
    JOIN [HRS$Parameter]               PV WITH (READUNCOMMITTED) ON PV.[Code]                 = AH.[Input Parameter 2 Code]
   WHERE NOT AH.[No_] IN
         (
		 --HRS002 >>
		 --SELECT RL.[Rebate Agreement No_]
         --  FROM [HRS$Posted Rebate Line]   RL WITH (NOLOCK)
         --  JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK) ON RH.[No_] = RL.[Document No_]
         -- WHERE RL.[No_]   = 'RV_SATZ' AND RL.[Type] IN (1,2) AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
		 SELECT [Rebate Agreement No_]
		   FROM _RV
		 --HRS002 <<
         )
), VALUE_TYPE9 AS
(
  SELECT RH.[Rebate Agreement No_]
       , SUM(L6.[Value Decimal]) [Non-Commissionable Turnover]
       , SUM(L7.[Value Decimal]) [Commissionable Turnover]
       , SUM(L9.[Value Decimal]) [Turnover (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Parameter]               P6 WITH (READUNCOMMITTED) ON P6.[Code]                = RA.[Input Parameter 6 Code]
    JOIN [HRS$Posted Rebate Line]      L6 WITH (READUNCOMMITTED) ON L6.[Document No_]        = RH.[No_]                    
                                                                AND L6.[No_]                 = RA.[Input Parameter 6 Code] 
                                                                AND L6.[Type]                IN (1,2)
    JOIN [HRS$Parameter]               P7 WITH (READUNCOMMITTED) ON P7.[Code]                = RA.[Input Parameter 7 Code]
    JOIN [HRS$Posted Rebate Line]      L7 WITH (READUNCOMMITTED) ON L7.[Document No_]        = RH.[No_]                    
                                                                AND L7.[No_]                 = RA.[Input Parameter 7 Code] 
                                                                AND L7.[Type]                IN (1,2)
    JOIN [HRS$Parameter]               P9 WITH (READUNCOMMITTED) ON P9.[Code]                = RA.[Input Parameter 9 Code]
    JOIN [HRS$Posted Rebate Line]      L9 WITH (READUNCOMMITTED) ON L9.[Document No_]        = RH.[No_]                    
                                                                AND L9.[No_]                 = RA.[Input Parameter 9 Code] 
                                                                AND L9.[Type]                IN (1,2)
   WHERE RA.[Template Type] = 9
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
GROUP BY RH.[Rebate Agreement No_]
), _RS AS
(
  SELECT RL.[Rebate Agreement No_]
       , SUM(RL.[Value Decimal]) [Revenue Share]
    FROM [HRS$Rebate Line] RL WITH (NOLOCK)
    JOIN [HRS$Rebate Header] RH WITH (NOLOCK)
      ON RH.[No_] = RL.[Document No_]
   WHERE RL.[Rebate Amount Line] = 1
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 --HRS003 >>
	 --AND RH.[Statement Posting Type]<>1
	 --HRS003 <<
GROUP BY RL.[Rebate Agreement No_]
UNION 
  SELECT RL.[Rebate Agreement No_]
       , SUM(RL.[Value Decimal]) [Revenue Share]
    FROM [HRS$Posted Rebate Line] RL WITH (NOLOCK)
    JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK)
      ON RH.[No_] = RL.[Document No_]
   WHERE RL.[Rebate Amount Line] = 1
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 --HRS003 >>
	 --AND RH.[Statement Posting Type]<>1
	 --HRS003 <<
GROUP BY RL.[Rebate Agreement No_]
), RS AS
(
  SELECT RS.[Rebate Agreement No_]
       , SUM(RS.[Revenue Share]) [Revenue Share]
    FROM _RS RS
GROUP BY RS.[Rebate Agreement No_]
), _RL AS
(
  SELECT RL.[Rebate Agreement No_]
       , SUM(RL.[Turnover (LCY) (corr_)])           [Turnover (LCY) (corr_)]
       , SUM(CASE WHEN RL.[Commission Type] = 13 
                  THEN RL.[Turnover (LCY) (corr_)] 
                  ELSE 0 
             END)                                       [Turnover (LCY) (corr_) CR]
       , SUM(RL.[Amount (LCY) (corr_)])             [Amount (LCY) (corr_)]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 
                  THEN RL.[Turnover (LCY) (corr_)] 
                  ELSE 0 
             END)                                       [Turnover (LCY) (corr_) NC]
    FROM [HRS$Posted Rebate Line] RL WITH (NOLOCK)
    JOIN [HRS$Posted Rebate Header] RH WITH (NOLOCK)
      ON RH.[No_] = RL.[Document No_]
   WHERE RL.[Type] = 5
	 -- HRS001 >>
   	 --AND RL.[Reservation Source] != 0 
   	 --AND RL.[Reservation Source] != 2 
   	 --AND RL.[Reservation Source] != 3 
   	 --AND RL.[Reservation Source] != 8 
   	 --AND RL.[Reservation Source] != 16
	 AND RL.[Reservation Source] NOT IN (SELECT No_
	                                       FROM [HRS$Booking Source] WITH (NOLOCK)
										  WHERE [Source Class] = 1)
	 -- HRS001 <<
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 --HRS003 >>
	 --AND RH.[Statement Posting Type]<>1
	 --HRS003 <<
GROUP BY RL.[Rebate Agreement No_] 
UNION
  SELECT RL.[Rebate Agreement No_]
       , SUM(RL.[Turnover (LCY) (corr_)])           [Turnover (LCY) (corr_)]
       , SUM(CASE WHEN RL.[Commission Type] = 13 
                  THEN RL.[Turnover (LCY) (corr_)] 
                  ELSE 0 
             END)                                       [Turnover (LCY) (corr_) CR]
       , SUM(RL.[Amount (LCY) (corr_)])             [Amount (LCY) (corr_)]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 
                  THEN RL.[Turnover (LCY) (corr_)] 
                  ELSE 0 
             END)                                       [Turnover (LCY) (corr_) NC]
    FROM [HRS$Rebate Line] RL WITH (NOLOCK)
    JOIN [HRS$Rebate Header] RH WITH (NOLOCK)
      ON RH.[No_] = RL.[Document No_]
   WHERE RL.[Type] = 5
	 -- HRS001 >>
   	 --AND RL.[Reservation Source] != 0 
   	 --AND RL.[Reservation Source] != 2 
   	 --AND RL.[Reservation Source] != 3 
   	 --AND RL.[Reservation Source] != 8 
   	 --AND RL.[Reservation Source] != 16
	 AND RL.[Reservation Source] NOT IN (SELECT No_
	                                       FROM [HRS$Booking Source] WITH (NOLOCK)
										  WHERE [Source Class] = 1)
	 -- HRS001 <<
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 --HRS003 >>
	 --AND RH.[Statement Posting Type]<>1
	 --HRS003 <<
GROUP BY RL.[Rebate Agreement No_] 
), RL AS
(
  SELECT RL.[Rebate Agreement No_]
       , SUM(RL.[Turnover (LCY) (corr_)])           [Turnover (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_) CR])        [Turnover (LCY) (corr_) CR]
       , SUM(RL.[Amount (LCY) (corr_)])             [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_) NC])        [Turnover (LCY) (corr_) NC]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)])=0 THEN 0 ELSE SUM([Turnover (LCY) (corr_) NC])
       / SUM(RL.[Turnover (LCY) (corr_)]) END           [Company Rates Ratio]
    FROM _RL RL
GROUP BY RL.[Rebate Agreement No_] 
), _RH AS
(
  SELECT DISTINCT RH.[Rebate Agreement No_], RH.[Rebate-to Vendor No_]
    FROM [HRS$Posted Rebate Header] RH WITH (NOLOCK)
   WHERE RH.[Cancels] = 0
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 --HRS003 >>
	 --AND RH.[Statement Posting Type]<>1
	 --HRS003 <<
UNION
  SELECT DISTINCT RH.[Rebate Agreement No_], RH.[Rebate-to Vendor No_]
    FROM [HRS$Rebate Header] RH WITH (NOLOCK)
   WHERE RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     --HRS003 >>
	 --AND RH.[Statement Posting Type]<>1
	 --HRS003 <<
), RH AS
(
  SELECT [Rebate Agreement No_], [dbo].[GetAffiliatePartnerFilter]([Rebate-to Vendor No_]) [Affiliate Partner Filter] /*MAX([Affiliate Partner Filter]) [Affiliate Partner Filter]*/ FROM _RH --GROUP BY [Rebate Agreement No_]
), REV_SUM AS
(
   SELECT AH.[Rebate-to Vendor No_]
        , CASE WHEN AH.[Rebate-to Name] = '' THEN AH.[Description] ELSE AH.[Rebate-to Name] END [Rebate-to Name]
		, RH.[Rebate Agreement No_]
		, NULLIF(AH.[Valid from],'1753-01-01') [Valid from]
		, NULLIF(AH.[Valid to],'1753-01-01') [Valid to]
        , RH.[Affiliate Partner Filter]
        , RL.[Turnover (LCY) (corr_) CR]
        , RL.[Amount (LCY) (corr_)]
        , AH.[Estimated Commission]                          [10% Commission applied]
        , RS.[Revenue Share]                                 [Revenue Share]
        , RL.[Company Rates Ratio]                           [Company Rates Ratio]
        , RV.[Configurated Revenue Share Rate]               [Configurated Revenue Share Rate]
        , COALESCE(
            VT9.[Commissionable Turnover]
          , RL.[Turnover (LCY) (corr_)] 
          - RL.[Turnover (LCY) (corr_) NC]
          )                                                  [Commissionable Turnover]
        , COALESCE(
            VT9.[Non-Commissionable Turnover]
          , RL.[Turnover (LCY) (corr_) NC]
          )                                                  [Turnover (LCY) (corr_) NC]          
        , COALESCE(
            VT9.[Turnover (LCY) (corr_)]
          , RL.[Turnover (LCY) (corr_)]
          )                                                  [Turnover (LCY) (corr_)]          
		, CASE
		    WHEN AH.[Partner Type] =0  THEN ''
		    WHEN AH.[Partner Type] =1 THEN 'Incentive'
		    WHEN AH.[Partner Type] =2 THEN 'Affiliate' 
		    WHEN AH.[Partner Type] =3 THEN 'strategic Partner'
		    WHEN AH.[Partner Type] =4 THEN 'Metasearcher'
		    WHEN AH.[Partner Type] =5 THEN 'Mobile'
		    WHEN AH.[Partner Type] =6 THEN 'TMC'
		    WHEN AH.[Partner Type] =7 THEN 'GDS'
	      ELSE  'OBE' END [PartnerType]
     FROM [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
     JOIN RH ON RH.[Rebate Agreement No_] = AH.[No_]
LEFT JOIN RL ON RL.[Rebate Agreement No_] = AH.[No_]
LEFT JOIN RS ON RS.[Rebate Agreement No_] = AH.[No_]
LEFT JOIN RV ON RV.[Rebate Agreement No_] = AH.[No_]
LEFT JOIN VALUE_TYPE9 VT9 ON VT9.[Rebate Agreement No_] = AH.[No_]
	 WHERE AH.[Group contract Code] <> 'GDS'
),Summary_CI_API_GDS_OBE AS(
  SELECT R.[Rebate Agreement No_]
	   , SUM(CASE WHEN R.[TMC RD Base Value] + R.[TMC RR Base Value] <> 0 then R.[TMC RD Base Value] + R.[TMC RR Base Value] 
	              WHEN R.[TMC RD Base Value] IS NULL AND R.[TMC RR Base Value] <> 0 THEN R.[TMC RR Base Value]
				  WHEN R.[TMC RD Base Value] <> 0 AND R.[TMC RR Base Value] IS NULL THEN R.[TMC RD Base Value]
				  ELSE 0 
			 END)	[CI Turnover (LCY) (corr_)]
	   , SUM(CASE WHEN R.[TMC RD Result Value] + R.[TMC RR Result Value] <> 0 then R.[TMC RD Result Value] + R.[TMC RR Result Value] 
	              WHEN R.[TMC RD Result Value] IS NULL AND R.[TMC RR Result Value] <> 0 THEN R.[TMC RR Result Value]
				  WHEN R.[TMC RD Result Value] <> 0 AND R.[TMC RR Result Value] IS NULL THEN R.[TMC RD Result Value]
	              ELSE 0 
			 END) [CI RevShare Amount]
	   , SUM(R.[TMC API Base Value])		[API Turnover (LCY) (corr_)]
	   , SUM(R.[TMC API Result Value])		[API RevShare Amount]
	   , SUM(R.[TMC GDS Base Value])		[GDS Turnover (LCY) (corr_)]
	   , SUM(R.[TMC GDS Result Value])		[GDS RevShare Amount]
	   , SUM(R.[TMC OBE Base Value])		[OBE Turnover (LCY) (corr_)]
	   , SUM(R.[TMC OBE Result Value])		[OBE RevShare Amount]
    FROM @Result R
	GROUP BY R.[Rebate Agreement No_]
),Summary_CI2 AS(
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 2)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 2)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
),Totals_CI2 AS(
  SELECT [Rebate Agreement No_]
	   , SUM([Non-Commissionable Turnover])	[Non-Commissionable Turnover]
	   , SUM([Commissionable Turnover])		[Commissionable Turnover]
	   , SUM([Commission Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM Summary_CI2
  GROUP BY [Rebate Agreement No_]
),Summary_API2 AS(
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 4)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 4)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
),Totals_API2 AS(
  SELECT [Rebate Agreement No_]
	   , SUM([Non-Commissionable Turnover])	[Non-Commissionable Turnover]
	   , SUM([Commissionable Turnover])		[Commissionable Turnover]
	   , SUM([Commission Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM Summary_API2
  GROUP BY [Rebate Agreement No_]
),Summary_GDS2 AS(
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 3)
     -- HRS004 >>
     AND RL.[Reservation Source] <> '613'
	 -- HRS004 <<
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 3)
     -- HRS004 >>
     AND RL.[Reservation Source] <> '613'
	 -- HRS004 <<
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
),Totals_GDS2 AS(
  SELECT [Rebate Agreement No_]
	   , SUM([Non-Commissionable Turnover])	[Non-Commissionable Turnover]
	   , SUM([Commissionable Turnover])		[Commissionable Turnover]
	   , SUM([Commission Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM Summary_GDS2
  GROUP BY [Rebate Agreement No_]
),Summary_OBE2 AS(
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 5)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
     --  , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (SELECT No_ FROM [HRS$Booking Source] WITH (READUNCOMMITTED) WHERE [Source Class] = 5)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 AND RA.[Group contract Code] <> 'GDS'
  GROUP BY RH.[Rebate Agreement No_]
),Totals_OBE2 AS(
  SELECT [Rebate Agreement No_]
	   , SUM([Non-Commissionable Turnover])	[Non-Commissionable Turnover]
	   , SUM([Commissionable Turnover])		[Commissionable Turnover]
	   , SUM([Commission Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM Summary_OBE2
  GROUP BY [Rebate Agreement No_]
),Summary_HDE AS (
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                    
   WHERE RL.[Reservation Source] = '383'
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                    
   WHERE RL.[Reservation Source] = '383'
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 AND RA.[Group contract Code] <> 'GDS'
     --AND RH.[Cancels] = 0
GROUP BY RH.[Rebate Agreement No_]
),Totals_HDE AS (
  SELECT [Rebate Agreement No_]
       , SUM([Non-Commissionable Turnover])		[Non-Commissionable Turnover]
	   , SUM([Commissionable Turnover])			[Commissionable Turnover]
	   , SUM([Turnover (LCY) (corr_)])			[Turnover (LCY) (corr_)]
	   , SUM([Commission Amount (LCY) (corr_)])	[Commission Amount (LCY) (corr_)]
    FROM Summary_HDE
GROUP BY [Rebate Agreement No_]
),Summary_Meetago AS(
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (5,7)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                    
   WHERE RL.[Reservation Source] IN (5,7)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RA.[Group contract Code] <> 'GDS'
GROUP BY RH.[Rebate Agreement No_]
),Totals_Meetago AS (
  SELECT S.[Rebate Agreement No_]
       , SUM(S.[Non-Commissionable Turnover])		[Non-Commissionable Turnover]
	   , SUM(S.[Commissionable Turnover])			[Commissionable Turnover]
	   , SUM(S.[Turnover (LCY) (corr_)])			[Turnover (LCY) (corr_)]
	   , SUM(CASE WHEN CHARINDEX('5', RA.[Offline Reservation Source]) <> 0  THEN 0 ELSE S.[Commission Amount (LCY) (corr_)] END)	[Commission Amount (LCY) (corr_)]
    FROM Summary_Meetago S
	JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_] = S.[Rebate Agreement No_]
GROUP BY [Rebate Agreement No_]
)
-- HRS004 >>
,Summary_613 AS (
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                    
   WHERE RL.[Reservation Source] = '613'
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                    
   WHERE RL.[Reservation Source] = '613'
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
	 AND RA.[Group contract Code] <> 'GDS'
     --AND RH.[Cancels] = 0
GROUP BY RH.[Rebate Agreement No_]
),Totals_613 AS (
  SELECT [Rebate Agreement No_]
       , SUM([Non-Commissionable Turnover])		[Non-Commissionable Turnover]
	   , SUM([Commissionable Turnover])			[Commissionable Turnover]
	   , SUM([Turnover (LCY) (corr_)])			[Turnover (LCY) (corr_)]
	   , SUM([Commission Amount (LCY) (corr_)])	[Commission Amount (LCY) (corr_)]
    FROM Summary_613
GROUP BY [Rebate Agreement No_]
)
-- HRS004 <<
-- HRS005 >>
,Summary_Offline AS(
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                     
   WHERE RL.[Reservation Source] IN (0,2,3,4,8,16,900)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RH.[Cancels] = 0
	 AND RA.[Group contract Code] <> 'GDS'
GROUP BY RH.[Rebate Agreement No_]
UNION
  SELECT RH.[Rebate Agreement No_]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]=0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non-Commissionable Turnover]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)]<>0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Commissionable Turnover]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Commission Amount (LCY) (corr_)]
    FROM [HRS$Rebate Header]    RH WITH (READUNCOMMITTED)
    JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]      RL WITH (READUNCOMMITTED) ON RL.[Document No_]        = RH.[No_]                    
   WHERE RL.[Reservation Source] IN (0,2,3,4,8,16,900)
     AND RH.[Document Date] BETWEEN @DateStart AND @DateEnd
     AND RA.[Group contract Code] <> 'GDS'
GROUP BY RH.[Rebate Agreement No_]
),Totals_Offline AS (
  SELECT S.[Rebate Agreement No_]
       , SUM(S.[Non-Commissionable Turnover])		[Non-Commissionable Turnover]
	   , SUM(S.[Commissionable Turnover])			[Commissionable Turnover]
	   , SUM(S.[Turnover (LCY) (corr_)])			[Turnover (LCY) (corr_)]
	   , SUM(CASE WHEN CHARINDEX('5', RA.[Offline Reservation Source]) <> 0  THEN 0 ELSE S.[Commission Amount (LCY) (corr_)] END)	[Commission Amount (LCY) (corr_)]
    FROM Summary_Offline S
	JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_] = S.[Rebate Agreement No_]
GROUP BY [Rebate Agreement No_]
)
-- HRS005 <<

--SELECT * FROM RV ORDER BY 1
SELECT REV_SUM.[Rebate-to Vendor No_]
     , REV_SUM.[Rebate-to Name]
	 , REV_SUM.PartnerType

	 -- Turnover
	 -- --------
	 , REV_SUM.[Turnover (LCY) (corr_)]
	 , Totals_CI2.[Commissionable Turnover] + Totals_CI2.[Non-Commissionable Turnover]	    [CI Turnover (LCY) (corr_)]
	 , Totals_API2.[Commissionable Turnover] + Totals_API2.[Non-Commissionable Turnover]	[API Turnover (LCY) (corr_)]
	 , Totals_GDS2.[Commissionable Turnover] + Totals_GDS2.[Non-Commissionable Turnover]	[GDS Turnover (LCY) (corr_)]
	 , Totals_OBE2.[Commissionable Turnover] + Totals_OBE2.[Non-Commissionable Turnover]	[OBE Turnover (LCY) (corr_)]
	 , Totals_HDE.[Turnover (LCY) (corr_)]		[HDE Turnover (LCY) (corr_)]
	 , Totals_Meetago.[Turnover (LCY) (corr_)]	[Meetago Turnover (LCY) (corr_)]
	 -- HRS004 >>
	 , Totals_613.[Turnover (LCY) (corr_)]	[613 Turnover (LCY) (corr_)] 
	 -- HRS004 <<
	 -- HRS005 >>
	 , Totals_Offline.[Turnover (LCY) (corr_)]	[Offline Turnover (LCY) (corr_)]
	 -- HRS005 <<

	 -- Non-Commissionable Turnover
	 -- ---------------------------
	 , REV_SUM.[Turnover (LCY) (corr_) NC]		
	 , Totals_CI2.[Non-Commissionable Turnover] [CI Non-Commissionable Turnover]
	 , Totals_API2.[Non-Commissionable Turnover] [API Non-Commissionable Turnover]
	 , Totals_GDS2.[Non-Commissionable Turnover] [GDS Non-Commissionable Turnover]
	 , Totals_OBE2.[Non-Commissionable Turnover] [OBE Non-Commissionable Turnover]
	 , Totals_HDE.[Non-Commissionable Turnover]	[HDE Non-Commissionable Turnover]
	 , Totals_Meetago.[Non-Commissionable Turnover] [Meetago Non-Commissionable Turnover]
	 -- HRS004 >>
	 , Totals_613.[Non-Commissionable Turnover] [613 Non-Commissionable Turnover]
	 -- HRS004 <<
	 -- HRS005 >>
	 , Totals_Offline.[Non-Commissionable Turnover] [Offline Non-Commissionable Turnover]
	 -- HRS005 <<

	 -- Commissionable Turnover
	 -- -----------------------
	 , REV_SUM.[Commissionable Turnover]
	 , Totals_CI2.[Commissionable Turnover] [CI Commissionable Turnover]
	 , Totals_API2.[Commissionable Turnover] [API Commissionable Turnover]
	 , Totals_GDS2.[Commissionable Turnover]  [GDS Commissionable Turnover]
	 , Totals_OBE2.[Commissionable Turnover] [OBE Commissionable Turnover]
	 , Totals_HDE.[Commissionable Turnover] [HDE Commissionable Turnover]
	 , Totals_Meetago.[Commissionable Turnover] [Meetago Commissionable Turnover]
	 -- HRS004 >>
	 , Totals_613.[Commissionable Turnover] [613 Commissionable Turnover]
	 -- HRS004 <<
	 -- HRS005 >>
	 , Totals_Offline.[Commissionable Turnover] [Offline Commissionable Turnover]
	 -- HRS005 <<

	 -- Amount
	 -- ------
	 , REV_SUM.[Amount (LCY) (corr_)]
	 , Totals_CI2.[Commission Amount (LCY) (corr_)] [CI Amount (LCY) (corr_)]
	 , Totals_API2.[Commission Amount (LCY) (corr_)] [API Amount (LCY) (corr_)]
	 , Totals_GDS2.[Commission Amount (LCY) (corr_)] [GDS Amount (LCY) (corr_)]
	 , Totals_OBE2.[Commission Amount (LCY) (corr_)] [OBE Amount (LCY) (corr_)]
	 , Totals_HDE.[Commission Amount (LCY) (corr_)] [HDE Amount (LCY) (corr_)]
	 , Totals_Meetago.[Commission Amount (LCY) (corr_)] [Meetago Amount (LCY) (corr_)]
	 -- HRS004 >>
	 , Totals_613.[Commission Amount (LCY) (corr_)] [613 Amount (LCY) (corr_)]
	 -- HRS004 <<
	 -- HRS005 >>
	 , Totals_Offline.[Commission Amount (LCY) (corr_)] [Offline Amount (LCY) (corr_)]
	 -- HRS005 <<

	 -- Average Commission Rate
	 -- -----------------------
     , CASE WHEN REV_SUM.[Turnover (LCY) (corr_)] - REV_SUM.[Turnover (LCY) (corr_) NC] = 0 THEN 0 ELSE REV_SUM.[Amount (LCY) (corr_)] 
     / (REV_SUM.[Turnover (LCY) (corr_)] - REV_SUM.[Turnover (LCY) (corr_) NC]) END [Average Commission Rate]
     , CASE WHEN Totals_CI2.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_CI2.[Commission Amount (LCY) (corr_)] 
     / Totals_CI2.[Commissionable Turnover] END [CI Average Commission Rate]  
     , CASE WHEN Totals_API2.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_API2.[Commission Amount (LCY) (corr_)] 
     / Totals_API2.[Commissionable Turnover] END [API Average Commission Rate]     
     , CASE WHEN Totals_GDS2.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_GDS2.[Commission Amount (LCY) (corr_)] 
     / Totals_GDS2.[Commissionable Turnover] END [GDS Average Commission Rate]  	 
     , CASE WHEN Totals_OBE2.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_OBE2.[Commission Amount (LCY) (corr_)] 
     / Totals_OBE2.[Commissionable Turnover] END [OBE Average Commission Rate]  	
     , CASE WHEN Totals_HDE.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_HDE.[Commission Amount (LCY) (corr_)] 
     / Totals_HDE.[Commissionable Turnover] END [HDE Average Commission Rate] 	  
     , CASE WHEN Totals_Meetago.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_Meetago.[Commission Amount (LCY) (corr_)] 
     / Totals_Meetago.[Commissionable Turnover] END [Meetago Average Commission Rate] 	 
	 -- HRS004 >>
	 , CASE WHEN Totals_613.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_613.[Commission Amount (LCY) (corr_)] 
     / Totals_613.[Commissionable Turnover] END [613 Average Commission Rate]
	 -- HRS004 <<
	 -- HRS005 >>
	 , CASE WHEN Totals_Offline.[Commissionable Turnover] = 0 THEN 0 ELSE Totals_Offline.[Commission Amount (LCY) (corr_)] 
     / Totals_Offline.[Commissionable Turnover] END [Offline Average Commission Rate] 	 
	 -- HRS005 <<

	 -- Revenue Share Ratio
	 -- -------------------
	 , CASE WHEN REV_SUM.[Amount (LCY) (corr_)]=0 THEN 0 ELSE REV_SUM.[Revenue Share] / REV_SUM.[Amount (LCY) (corr_)] END [Revenue Share Ratio]
	 , CASE WHEN Totals_CI2.[Commission Amount (LCY) (corr_)]=0 THEN 0 ELSE Summary_CI_API_GDS_OBE.[CI RevShare Amount] / Totals_CI2.[Commission Amount (LCY) (corr_)] END [CI Revenue Share Ratio]
	 , CASE WHEN Totals_API2.[Commission Amount (LCY) (corr_)]=0 THEN 0 ELSE Summary_CI_API_GDS_OBE.[API RevShare Amount] / Totals_API2.[Commission Amount (LCY) (corr_)] END [API Revenue Share Ratio]	 
	 -- HRS004 >>
 	 -- , CASE WHEN Totals_GDS2.[Commission Amount (LCY) (corr_)]=0 THEN 0 ELSE Summary_CI_API_GDS_OBE.[GDS RevShare Amount] / Totals_GDS2.[Commission Amount (LCY) (corr_)] END [GDS Revenue Share Ratio]
	 , CASE WHEN Totals_GDS2.[Commission Amount (LCY) (corr_)]=0 THEN 0 ELSE (Summary_CI_API_GDS_OBE.[GDS RevShare Amount] - COALESCE(CASE WHEN Totals_613.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_613.[Commission Amount (LCY) (corr_)] / (Totals_GDS2.[Commission Amount (LCY) (corr_)] + Totals_613.[Commission Amount (LCY) (corr_)])) * Summary_CI_API_GDS_OBE.[GDS RevShare Amount] END, 0)) / Totals_GDS2.[Commission Amount (LCY) (corr_)] END [GDS Revenue Share Ratio]
	 -- HRS004 <<
	 , CASE WHEN Totals_OBE2.[Commission Amount (LCY) (corr_)]=0 THEN 0 ELSE Summary_CI_API_GDS_OBE.[OBE RevShare Amount] / Totals_OBE2.[Commission Amount (LCY) (corr_)] END [OBE Revenue Share Ratio]
	 , CASE WHEN Totals_HDE.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_HDE.[Commission Amount (LCY) (corr_)] / REV_SUM.[Amount (LCY) (corr_)]) 
	 * CASE WHEN REV_SUM.[Amount (LCY) (corr_)]=0 THEN 0 ELSE REV_SUM.[Revenue Share] / REV_SUM.[Amount (LCY) (corr_)] END END [HDE Revenue Share Ratio]
	 , CASE WHEN Totals_Meetago.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_Meetago.[Commission Amount (LCY) (corr_)] / REV_SUM.[Amount (LCY) (corr_)]) 
	 * CASE WHEN REV_SUM.[Amount (LCY) (corr_)]=0 THEN 0 ELSE REV_SUM.[Revenue Share] / REV_SUM.[Amount (LCY) (corr_)] END END [Meetago Revenue Share Ratio]
	 -- HRS004 >>
	 , CASE WHEN Totals_613.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_613.[Commission Amount (LCY) (corr_)] / (Totals_GDS2.[Commission Amount (LCY) (corr_)] + Totals_613.[Commission Amount (LCY) (corr_)])) * Summary_CI_API_GDS_OBE.[GDS RevShare Amount]
	 / Totals_613.[Commission Amount (LCY) (corr_)] END [613 Revenue Share Ratio]
	 -- HRS004 <<
	 -- HRS005 >>
	 , CASE WHEN Totals_Offline.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_Offline.[Commission Amount (LCY) (corr_)] / REV_SUM.[Amount (LCY) (corr_)]) 
	 * CASE WHEN REV_SUM.[Amount (LCY) (corr_)]=0 THEN 0 ELSE REV_SUM.[Revenue Share] / REV_SUM.[Amount (LCY) (corr_)] END END [Offline Revenue Share Ratio]
	 -- HRS005 <<

	 -- Revenue Share
	 -- -------------
	 , REV_SUM.[Revenue Share]
	 , Summary_CI_API_GDS_OBE.[CI RevShare Amount] [CI Revenue Share]
	 , Summary_CI_API_GDS_OBE.[API RevShare Amount] [API Revenue Share]
	 -- HRS004 >>
	 -- , Summary_CI_API_GDS_OBE.[GDS RevShare Amount] [GDS Revenue Share]
	 , Summary_CI_API_GDS_OBE.[GDS RevShare Amount] - COALESCE(CASE WHEN Totals_613.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_613.[Commission Amount (LCY) (corr_)] / (Totals_GDS2.[Commission Amount (LCY) (corr_)] + Totals_613.[Commission Amount (LCY) (corr_)])) * Summary_CI_API_GDS_OBE.[GDS RevShare Amount] END, 0) [GDS Revenue Share]
	 -- HRS004 <<
	 , Summary_CI_API_GDS_OBE.[OBE RevShare Amount] [OBE Revenue Share]
	 , CASE WHEN Totals_HDE.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_HDE.[Commission Amount (LCY) (corr_)] / REV_SUM.[Amount (LCY) (corr_)]) * REV_SUM.[Revenue Share] END [HDE Revenue Share]
	 , CASE WHEN Totals_Meetago.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_Meetago.[Commission Amount (LCY) (corr_)] / REV_SUM.[Amount (LCY) (corr_)]) * REV_SUM.[Revenue Share] END [Meetago Revenue Share]
	 -- HRS004 >>
	 , CASE WHEN Totals_613.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_613.[Commission Amount (LCY) (corr_)] / (Totals_GDS2.[Commission Amount (LCY) (corr_)] + Totals_613.[Commission Amount (LCY) (corr_)])) * Summary_CI_API_GDS_OBE.[GDS RevShare Amount] END [613 Revenue Share]
	 -- HRS004 <<
	 -- HRS005 >>
	 , CASE WHEN Totals_Offline.[Commission Amount (LCY) (corr_)]= 0 THEN 0 ELSE (Totals_Offline.[Commission Amount (LCY) (corr_)] / REV_SUM.[Amount (LCY) (corr_)]) * REV_SUM.[Revenue Share] END [Offline Revenue Share]
	 -- HRS005 <<

	 , @DateStart [DateStart]
     , @DateEnd [DateEnd]
  FROM REV_SUM
  LEFT JOIN @Result R ON R.[Rebate-to Vendor No_] = REV_SUM.[Rebate-to Vendor No_] AND R.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Summary_CI_API_GDS_OBE ON Summary_CI_API_GDS_OBE.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Totals_CI2 ON Totals_CI2.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  --LEFT JOIN Summary_API ON Summary_API.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Totals_API2 ON Totals_API2.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  --LEFT JOIN Summary_GDS ON Summary_GDS.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Totals_GDS2 ON Totals_GDS2.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  --LEFT JOIN Summary_OBE ON Summary_OBE.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Totals_OBE2 ON Totals_OBE2.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Totals_HDE ON Totals_HDE.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  LEFT JOIN Totals_Meetago ON Totals_Meetago.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  -- HRS004 >>
  LEFT JOIN Totals_613 ON Totals_613.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  -- HRS004 <<
  -- HRS005 >>
  LEFT JOIN Totals_Offline ON Totals_Offline.[Rebate Agreement No_] = REV_SUM.[Rebate Agreement No_]
  -- HRS005 <<
ORDER BY 1

DROP TABLE #RebateNumbers
DROP TABLE #ResultBuffer

END
GO
