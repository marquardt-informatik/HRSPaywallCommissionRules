USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_RebateTravelagencySummary]    Script Date: 10.04.2024 14:31:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 04.10.18
-- Description:	Calls sp_RebateCustomerSummary and fills [Excel Buffer 4 SSRS]
-- 
/*
DECLARE   @UserId					VARCHAR(250)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS' 
		, @ReportId					INT				= 90002
	    , @ConnectionID             INT             = 90002
	    , @WindowsLanguageID        INT             = 1031
	    , @RebateNo                 VARCHAR(250)     = 'K0000042470'
EXEC [RS].[PROC_RebateTravelagencySummary] @UserId, @CompanyName, @ReportId, @ConnectionID, @WindowsLanguageID, @RebateNo
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_RebateTravelagencySummary] 
(
	  @UserId						VARCHAR(250)
	, @CompanyName				    VARCHAR(30)
	, @ReportId						INT
	, @ConnectionID                 INT
	, @WindowsLanguageID            INT
	, @RebateNo                     VARCHAR(250)
)
AS BEGIN
DECLARE @Summary TABLE 
(
    [Company-Name] varchar(250)
  , [IATA] varchar(20)
  , [Amadeus No_] varchar(20)
  , [CurrencyCode] varchar(250)
  , [Travelagency No_] int
  , [Reservation Source] int
  , [Amount (LCY)] decimal(37,20)
  , [Amount (LCY) (corr_)] decimal(37,20)	
  , [Turnover (LCY)] decimal(37,20)	
  , [Turnover (LCY) (corr_)] decimal(37,20)	
  , [Amount Correction Ratio] decimal(37,20)	
  , [Turnover Correction Ratio] decimal(37,20)	
  , [Net Rate Share Ratio] decimal(37,20)	
  , [Net Rate Share] decimal(37,20)	
  , [Non Commissionables] decimal(37,20)	
  , [Commissionable Turnover] decimal(37,20)	
  , [Average Commission Rate] decimal(37,20)
  , [Rebate No_] varchar(250)	
  , [Rebate Agreement No_] varchar(250)
  , [Rebate-to Vendor No_] varchar(250)
  , [Rebate-to Customer Name] varchar(250)	
  , [Rebate-to Customer Name 2] varchar(250)	
  , [Rebate-to Address] varchar(250)	
  , [Rebate-to Address 2] varchar(250)
  , [Rebate-to City] varchar(250)	
  , [Rebate-to Contact] varchar(250)	
  , [Rebate-to Post Code] varchar(250)	
  , [Rebate-to Country_Region Code] varchar(250)	
  , [Affiliate Partner List] varchar(max)	
  , [Currency Factor] decimal(37,20)	
  , [Interval] int	
  , [Posting Date] date	
  , [Document Date] date	
  , [Language Code] varchar(250)	
  , [Year Start Date] date	
  , [Year End Date] date	
  , [Till Start Date] date	
  , [Interval Start Date] date	
  , [Interval End Date] date	
  , [Document Type (Statement)] varchar(250)	
  , [Document Type (Cr_ Memo)] varchar(250)	
  , [Correspondence Type] int	
  , [Vendor Bank Name] varchar(250)	
  , [Vendor IBAN] varchar(250)	
  , [Vendor SWIFT Code] varchar(250)	
  , [Vendor Bank Branch No_] varchar(250)	
  , [Vendor Bank Account No_] varchar(250)	
  , [Template Type] varchar(250)	
  , [Matrix _ Vector Code] varchar(250)	
  , [Code P2] varchar(250)	
  , [Name P2] varchar(250)	
  , [Value P2] decimal(37,20)	
  , [VatBusPostingGroup] varchar(250)	
  , [VAT Registration Label] varchar(250)	
  , [VAT Registration No_] varchar(250)	
  , [Saludation] varchar(250)	
  , [Salesperson E-Mail] varchar(250)	
  , [Salesperson Fax No_] varchar(250)	
  , [Salesperson Name] varchar(250)	
  , [Salesperson Phone No_] varchar(250)	
  , [EU Country_Region Code] varchar(250)	
  , [Country_Region Name] varchar(250)	
  , [Online Reservation Source] varchar(250)	
  , [Offline Reservation Source] varchar(250)	
  , [Print Booking Source] int	
  , [Enable retroactive correction] int	
  , [Estimated Commission] int
)
INSERT INTO @Summary
EXEC [dbo].[sp_RebateTASummary] @RebateNo
--SELECT * FROM @Summary

DECLARE @NumberDecimalSeparator varchar(50) = ','
      , @NumberGroupSeparator varchar(50) = '.'
      , @NumberGroupSize int = 3
      , @NumberDecimalDigits int = 2
SELECT @NumberDecimalSeparator = CI.[Number Decimal Separator]
     , @NumberGroupSeparator = CI.[Number Group Separator]
     , @NumberGroupSize = CI.[Number Group Size]
     , @NumberDecimalDigits = CI.[Number Decimal Digits]
  FROM [Culture Info] CI
 WHERE [Windows Language ID]=@WindowsLanguageID  

DELETE 
  FROM [Excel Buffer 4 SSRS]
 WHERE [Report ID]		= @ReportId
   AND [ConnectionID]	= @ConnectionID
   AND [USERID]			= @UserId
   
INSERT INTO [Excel Buffer 4 SSRS] ([timestamp],[Row No_], [Column No_], [Report ID], [ConnectionID], [USERID], xlRowID, xlColID, [Cell Value as Text], Comment, Formula, Bold, Italic, Underline, NumberFormat, Formula2, Formula3, Formula4) 
  VALUES
  (NULL, 1, 1 , @ReportId, @ConnectionID, @UserId, '1', 'A', 'Reservation Source'				, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 2 , @ReportId, @ConnectionID, @UserId, '1', 'B', 'IATA'  	                        , '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 3 , @ReportId, @ConnectionID, @UserId, '1', 'C', 'Amadeus No.'						, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 4 , @ReportId, @ConnectionID, @UserId, '1', 'D', 'Name'     	                    , '', '', 1, 0, 0, '', '', '', '')

, (NULL, 1, 5 , @ReportId, @ConnectionID, @UserId, '1', 'E', 'Hotel turnover [€]'				, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 6 , @ReportId, @ConnectionID, @UserId, '1', 'F', 'Hotel Turnover (corr.) [€]'		, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 7 , @ReportId, @ConnectionID, @UserId, '1', 'G', 'Hotel turnover correction ratio'	, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 8 , @ReportId, @ConnectionID, @UserId, '1', 'H', 'Company Rates'	                , '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1, 9 , @ReportId, @ConnectionID, @UserId, '1', 'I', 'Company Rates Ratio'				, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1,10 , @ReportId, @ConnectionID, @UserId, '1', 'J', 'Non Commissionables'				, '', '', 1, 0, 0, '', '', '', '')
, (NULL, 1,11 , @ReportId, @ConnectionID, @UserId, '1', 'K', 'Commissionable Turnover'			, '', '', 1, 0, 0, '', '', '', '')

INSERT INTO [Excel Buffer 4 SSRS] ([timestamp],[Row No_], [Column No_], [Report ID], [ConnectionID], [USERID], xlRowID, xlColID, [Cell Value as Text], Comment, Formula, Bold, Italic, Underline, NumberFormat, Formula2, Formula3, Formula4) 
SELECT NULL [timestamp]
     , ROW_NUMBER() OVER(PARTITION BY X.xlColID ORDER BY X.xlColID, S.[Reservation Source], S.[IATA])+1 [Row No_] 
     , X.[Column No_]
     , @ReportId, @ConnectionID, @UserId
     , CAST(ROW_NUMBER() OVER(PARTITION BY X.xlColID ORDER BY X.xlColID, S.[Reservation Source], S.[IATA])+1 AS varchar(10)) [xlRowID]
     , X.[xlColID]
     , CASE X.[Column No_] 
         WHEN  1 THEN CAST(S.[Reservation Source] AS varchar(250))
         WHEN  2 THEN CAST(S.[IATA] AS varchar(250))
		 WHEN  3 THEN [Amadeus No_]
         WHEN  4 THEN [Company-Name]

         WHEN  5 THEN dbo.fnc_FormatNumber([Turnover (LCY)], @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)
         WHEN  6 THEN dbo.fnc_FormatNumber([Turnover (LCY) (corr_)], @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)
         WHEN  7 THEN dbo.fnc_FormatNumber([Turnover Correction Ratio]*100., @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)
         WHEN  8 THEN dbo.fnc_FormatNumber([Net Rate Share], @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)
         WHEN  9 THEN dbo.fnc_FormatNumber([Net Rate Share Ratio]*100., @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)
         WHEN 10 THEN dbo.fnc_FormatNumber([Non Commissionables], @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)
         WHEN 11 THEN dbo.fnc_FormatNumber([Commissionable Turnover], @NumberDecimalSeparator, @NumberGroupSeparator, @NumberGroupSize, @NumberDecimalDigits)

         ELSE ''
       END [Cell Value as Text]
     , '', ''
     , 0 -- Bold
     , 0, 0, '', '', '', ''
  FROM @Summary S,[Excel Buffer 4 SSRS] X
 WHERE [Report ID]		= @ReportId
   AND [ConnectionID]	= @ConnectionID
   AND [USERID]			= @UserId
   
--SELECT *
--  FROM [Excel Buffer 4 SSRS]
-- WHERE [Report ID]		= @ReportId
--   AND [ConnectionID]	= @ConnectionID
--   AND [USERID]			= @UserId  
END
GO
