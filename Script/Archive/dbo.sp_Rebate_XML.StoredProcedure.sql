USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Rebate_XML]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Statistische Zusammenfassung zur Gutschriftsanzeige
/*
DECLARE @RebateNo VARCHAR(20)
 SELECT @RebateNo = 'K0000000026'
EXEC [DynNavHRS].[dbo].[sp_Rebate_XML] 'K0000000026'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_Rebate_XML] 
    @RebateNo varchar(20)
AS
BEGIN

DECLARE @Result        TABLE
(
    [Tag]                  int
  , [Parent]               int
  , [Report!1]             varchar(20)
  , [Bookingparts!2]                 int
  , [Name!3]                         varchar(100)
  , [DateRange1!4]                   varchar(23)
  , [DateRange2!5]                   varchar(23)
  , [ClientFilter!6]                 varchar(max)
  , [ReservationSource!7]            varchar(100)
  , [VendorName!8]                   varchar(130)
  , [Bookingpart!9]                  int
  , [Bookingpart!9!ID]               int
  , [InvoiceNo!10]                   varchar(20)
  , [ReservationNo!11]               bigint
  , [ReservationPartNo!12]           int
  , [ClientNo!13]                    bigint
  , [HotelNo!14]                     int
  , [BonusID1!15]                    varchar(100)
  , [BonusID2!16]                    varchar(100)
  , [TurnoverLCY!17]                 decimal(37,20)
  , [AmountLCY!18]                   decimal(37,20)
  , [TurnoverLCYCorr!19]             decimal(37,20)
  , [AmountLCYCorr!20]               decimal(37,20)
  , [Turnover!21]                    decimal(37,20)
  , [Amount!22]                      decimal(37,20)
  , [TurnoverCorr!23]                decimal(37,20)
  , [AmountCorr!24]                  decimal(37,20)
  , [RoomNights!25]                  decimal(37,20)
  , [RoomNightsCorr!26]              decimal(37,20)
  , [ReservationDate!27]             datetime
  , [ArivalDate!28]                  datetime
  , [DepartueDate!29]                datetime
  , [RebateNo!30]                    varchar(20)
  , [HeaderCaption!31]               int
  , [DateRange1!32]                  varchar(100)
  , [DateRange2!33]                  varchar(100)
  , [ClientFilter!34]                varchar(100)
  , [ReservationSource!35]           varchar(100)
  , [DetailCaption!36]               int
  , [InvoiceNo!37]                   varchar(100)
  , [ReservationNo!38]               varchar(100)
  , [ReservationPartNo!39]           varchar(100)
  , [ClientNo!40]                    varchar(100)
  , [HotelNo!41]                     varchar(100)
  , [BonusID1!42]                    varchar(100)
  , [BonusID2!43]                    varchar(100)
  , [TurnoverLCY!44]                 varchar(100)
  , [AmountLCY!45]                   varchar(100)
  , [TurnoverLCYCorr!46]             varchar(100)
  , [AmountLCYCorr!47]               varchar(100)
  , [Turnover!48]                    varchar(100)
  , [Amount!49]                      varchar(100)
  , [TurnoverCorr!50]                varchar(100)
  , [AmountCorr!51]                  varchar(100)
  , [RoomNights!52]                  varchar(100)
  , [RoomNightsCorr!53]              varchar(100)
  , [ReservationDate!54]             varchar(100)
  , [ArivalDate!55]                  varchar(100)
  , [DepartueDate!56]                varchar(100)
  , [Summary!57]                     int
  , [TurnoverLCYCorr!58]             decimal(37,20)
  , [AmountLCYCorr!59]               decimal(37,20)
  , [RevenueShareRate!60]            decimal(37,20)
  , [RevenueShare!61]                decimal(37,20)
  , [RevShareVAT!62]                 decimal(37,20)
  , [RevShareTotal!63]               decimal(37,20)
  , [CompanyRates!64]                decimal(37,20)
  , [NonCommissionables!65]          decimal(37,20)
  , [CommissionableTurnover!66]      decimal(37,20)
  , [AvgCommissionRate!67]           decimal(37,20)
  , [CorrectionRateCommission!68]    decimal(37,20)
  , [CorrectionRateHotelTurnover!69] decimal(37,20)
  , [CompanyRatesRatio!70]           decimal(37,20)
  , [RevenueShareRatio!71]           decimal(37,20)
  , [ValueP1!72]                     decimal(37,20)
  , [ValueP2!73]                     decimal(37,20)
  , [ValueP3!74]                     decimal(37,20)
  , [ValueP4!75]                     decimal(37,20)
  , [ValueP5!76]                     decimal(37,20)
  , [ValueP6!77]                     decimal(37,20)
  , [ValueP7!78]                     decimal(37,20)
  , [ValueP8!79]                     decimal(37,20)
  , [ValueP9!80]                     decimal(37,20)
  , [ValueP10!81]                    decimal(37,20)
  , [ValuePA!82]                     decimal(37,20)
  , [SummaryCaption!83]              int
  , [CompanyRates!84]                varchar(100)
  , [NonCommissionables!85]          varchar(100)
  , [CommissionableTurnover!86]      varchar(100)
  , [AvgCommissionRate!87]           varchar(100)
  , [CorrectionRateCommission!88]    varchar(100)
  , [CorrectionRateHotelTurnover!89] varchar(100)
  , [CompanyRatesRatio!90]           varchar(100)
  , [RevenueShareRatio!91]           varchar(100)
  , [Summary2!92]                     int
)
DECLARE @ResultSP      TABLE
(
    [Tab]                            VARCHAR(100)
  , [Loyality Rewards Account 1 No_] VARCHAR(100)
  , [Loyality Rewards Account 2 No_] VARCHAR(100)
  , [Reservation Date]               DATETIME
  , [Arival Date]                    DATETIME
  , [Post Affiliate Partner No_]     VARCHAR(20)
  , [Turnover Breakfast (LCY)]       DECIMAL(37,20)
  , [Turnover Breakfast (LCY) (c_)]  DECIMAL(37,20)
  , [Amount]  DECIMAL(37,20)
  , [Turnover]  DECIMAL(37,20)
  , [Amount (corr_)]  DECIMAL(37,20)
  , [Turnover (corr_)]  DECIMAL(37,20)
  , [Currency Faktor]  DECIMAL(37,20)
  , [Currency Code] VARCHAR(10)
  , [Currency Faktor (corr_)]  DECIMAL(37,20)
  , [Currency Code (corr_)] VARCHAR(10)
  , [Document No_]  VARCHAR(20)
  , [Line No_] INT
  , [Type] INT
  , [Rebate Amount Line] INT
  , [No Print] INT
  , [No_] TINYINT
  , [Rebate Agreement No_]  VARCHAR(20)
  , [Posting Date (Import)] DATETIME
  , [Document Date (Import)] DATETIME
  , [Description] VARCHAR(120)
  , [Description 2] VARCHAR(120)
  , [Reservation No_]  INT
  , [Reservation Part No_] INT
  , [Value Type] INT
  , [Value] VARCHAR(250)
  , [Value Text] VARCHAR(250)
  , [Value Decimal]  DECIMAL(37,20)
  , [Value Boolean] TINYINT
  , [Value Date] DATETIME
  , [Invoice No_]  VARCHAR(20)
  , [Amount (LCY)]  DECIMAL(37,20)
  , [Turnover (LCY)]  DECIMAL(37,20)
  , [Commission Type] INT
  , [Commission Rate %]  DECIMAL(37,20)
  , [Amount (LCY) (corr_)]  DECIMAL(37,20)
  , [Turnover (LCY) (corr_)]  DECIMAL(37,20)
  , [Commission Type (corr_)] INT
  , [Commission Rate % (corr_)]  DECIMAL(37,20)
  , [Departure Date] DATETIME
  , [Affiliate Partner No_]  INT
  , [Hotel No_]  VARCHAR(20)
  , [Room Nights]  DECIMAL(37,20)
  , [Is Net Rate] TINYINT
  , [Room Nights Post Corection]  DECIMAL(37,20)
  , [Is Net Rate Post Corection] TINYINT
  , [Max Entry No_] INT
  , [Is No Show] TINYINT
  , [Top Bonus ID]  VARCHAR(50)
  , [MuseID]  VARCHAR(20)
  , [Correction Kennung] INT
  , [Company Name] VARCHAR(30)
  , [Customer No_]  VARCHAR(20)
  , [Country Code]  INT
  , [Chain]  VARCHAR(20)
  , [Brand]  VARCHAR(20)
  , [Rebate-to Vendor No_]  VARCHAR(20)
  , [Handbooking] TINYINT
  , [Booking User]  VARCHAR(120)
  , [Reservation Source] INT
)
DECLARE @ResultHeader  TABLE
(
    [Rebate No_] VARCHAR(20)
  , [Rebate-to Vendor No_] VARCHAR(20)
  , [Rebate-to Customer Name]  VARCHAR(120)
  , [Rebate-to Customer Name 2]  VARCHAR(120)
  , [Rebate-to Address]  VARCHAR(120)
  , [Rebate-to Address 2]  VARCHAR(120)
  , [Rebate-to City]  VARCHAR(120)
  , [Rebate-to Contact]  VARCHAR(120)
  , [Rebate-to Post Code] VARCHAR(20)
  , [Rebate-to Country_Region Code] VARCHAR(20)
  , [Affiliate Partner List] VARCHAR(MAX)
  , [Currency Code] VARCHAR(20)
  , [Currency Factor] DECIMAL(37,20)
  , [Interval] INT
  , [Posting Date] DATETIME
  , [Document Date] DATETIME
  , [Language Code] VARCHAR(20)
  , [Year Start Date] DATETIME
  , [Year End Date] DATETIME
  , [Till Start Date] DATETIME
  , [Interval Start Date] DATETIME
  , [Interval End Date] DATETIME
  , [Document Type (Statement)] VARCHAR(20)
  , [Document Type (Cr_ Memo)] VARCHAR(20)
  , [Correspondence Type] INT
  , [Vendor Bank Name]  VARCHAR(120)
  , [Vendor IBAN]  VARCHAR(120)
  , [Vendor SWIFT Code]  VARCHAR(120)
  , [Vendor Bank Branch No_]  VARCHAR(120)
  , [Vendor Bank Account No_]  VARCHAR(120)
  , [Template Type] INT
  , [Matrix _ Vector Code] VARCHAR(20)
  , [Code P1] VARCHAR(20)
  , [Name P1]  VARCHAR(120)
  , [Value P1] DECIMAL(37,20)
  , [Code P2] VARCHAR(20)
  , [Name P2]  VARCHAR(120)
  , [Value P2] DECIMAL(37,20)
  , [Code P3] VARCHAR(20)
  , [Name P3]  VARCHAR(120)
  , [Value P3] DECIMAL(37,20)
  , [Code P4] VARCHAR(20)
  , [Name P4]  VARCHAR(120)
  , [Value P4] DECIMAL(37,20)
  , [Code P5] VARCHAR(20)
  , [Name P5]  VARCHAR(120)
  , [Value P5] DECIMAL(37,20)
  , [Code P6] VARCHAR(20)
  , [Name P6]  VARCHAR(120)
  , [Value P6] DECIMAL(37,20)
  , [Code P7] VARCHAR(20)
  , [Name P7]  VARCHAR(120)
  , [Value P7] DECIMAL(37,20)
  , [Code P8] VARCHAR(20)
  , [Name P8]  VARCHAR(120)
  , [Value P8] DECIMAL(37,20)
  , [Code P9] VARCHAR(20)
  , [Name P9]  VARCHAR(120)
  , [Value P9] DECIMAL(37,20)
  , [Code P10] VARCHAR(20)
  , [Name P10]  VARCHAR(120)
  , [Value P10] DECIMAL(37,20)
  , [Code PA] VARCHAR(20)
  , [Name PA]  VARCHAR(120)
  , [Value PA] DECIMAL(37,20)
  , [VatBusPostingGroup] VARCHAR(20)
  , [CurrencyCode] VARCHAR(20)
  , [VAT Registration Label]  VARCHAR(120)
  , [VAT Registration No_]  VARCHAR(120)
  , [Salutation]  VARCHAR(120)
  , [Salesperson E-Mail]  VARCHAR(120)
  , [Salesperson Fax No_]  VARCHAR(120)
  , [Salesperson Name]  VARCHAR(120)
  , [Salesperson Phone No_]  VARCHAR(120)
  , [EU Country_Region Code] VARCHAR(20)
  , [Country_Region Name]  VARCHAR(120)
  , [Online Reservation Source]  VARCHAR(120)
  , [Offline Reservation Source]  VARCHAR(120)
  , [Print Booking Source] int
  , [Enable retroactive correction] int
)
DECLARE @ResultSummary TABLE
(
    [CurrencyCode] VARCHAR(20)
  , [Amount Correction Ratio] DECIMAL(37,20)
  , [Turnover Correction Ratio] DECIMAL(37,20)
  , [Net Rate Share Ratio] DECIMAL(37,20)
  , [Net Rate Share] DECIMAL(37,20)
  , [Non Commissionables] DECIMAL(37,20)
  , [Commissionable Turnover] DECIMAL(37,20)
  , [Average Commission Rate] DECIMAL(37,20)
  , [Revenue Share Ratio] DECIMAL(37,20)
)

DECLARE @LanguageCode VARCHAR(20)
SET @LanguageCode = ''
;WITH LC AS (SELECT [Language Code] FROM [HRS$Rebate Header] WITH (NOLOCK) WHERE [No_] = @RebateNo UNION SELECT [Language Code] FROM [HRS$Posted Rebate Header] WITH (NOLOCK) WHERE [No_] = @RebateNo)
SELECT @LanguageCode = [Language Code] FROM LC

DECLARE @HeaderLabels TABLE
(
    LabelID VARCHAR(50)
  , Translation VARCHAR(MAX)
)
INSERT INTO @HeaderLabels
SELECT LabelID,Translation 
     FROM UTFDocumentTranslation WITH (NOLOCK)
    WHERE LanguageCode       = @LanguageCode
      AND Company            = 'HRS' 
      AND DocumentType       = 13 
      AND DocumentLevel      = 0 
    UNION
   SELECT UTF1.LabelID
        , UTF1.Translation 
     FROM UTFDocumentTranslation UTF1 WITH (NOLOCK) 
    WHERE UTF1.LanguageCode  = '1'
      AND UTF1.Company       = 'HRS' 
      AND UTF1.DocumentType  = 13 
      AND UTF1.DocumentLevel = 0 
      AND (
            SELECT COUNT(1) 
              FROM UTFDocumentTranslation WITH (NOLOCK)
             WHERE LanguageCode       = @LanguageCode
               AND Company            = 'HRS' 
               AND DocumentType       = 13 
               AND DocumentLevel      = 0
          ) =0
          
INSERT INTO @ResultSummary EXEC [dbo].[sp_RebateSummary]  @RebateNo
INSERT INTO @ResultSP      EXEC [dbo].[sp_RebateLinesYTD] @RebateNo
INSERT INTO @ResultHeader  EXEC [dbo].[sp_RebateHeader]   @RebateNo

UPDATE @ResultSP SET [Line No_] = [Line No_]+ CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END

DECLARE @Pageoffset TABLE 
(
  Number int
)
INSERT INTO @Pageoffset
SELECT DISTINCT CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FirstPage FROM @ResultSP

DECLARE @FirstPage int
;WITH _TAB AS(SELECT DISTINCT [Tab] FROM @ResultSP)
SELECT @FirstPage = MIN(CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END) FROM _TAB


;WITH _TAB AS(SELECT DISTINCT [Tab] FROM @ResultSP)
INSERT INTO @Result ([Tag],[Parent],[Bookingpart!9!ID])
SELECT 2,1,CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

;WITH _TAB AS(SELECT DISTINCT [Tab] FROM @ResultSP)
INSERT INTO @Result ([Tag],[Parent],[Name!3],[Bookingpart!9!ID])
SELECT 3,2,[Tab],CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

;WITH _TAB AS(SELECT DISTINCT [Tab], [Interval Start Date], [Interval End Date] FROM @ResultSP,@ResultHeader)
INSERT INTO @Result ([Tag],[Parent],[DateRange1!4],[Name!3],[Bookingpart!9!ID])
SELECT 4,2,CONVERT(VARCHAR(10),[Interval Start Date],120) + ' - ' + CONVERT(VARCHAR(10),[Interval End Date],120),[Tab],CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

;WITH _TAB AS(SELECT DISTINCT [Tab], [Year Start Date], [Year End Date] FROM @ResultSP,@ResultHeader)
INSERT INTO @Result ([Tag],[Parent],[DateRange2!5],[Name!3],[Bookingpart!9!ID])
SELECT 5,2,CONVERT(VARCHAR(10),[Year Start Date],120) + ' - ' + CONVERT(VARCHAR(10),[Year End Date],120),[Tab],CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

;WITH _TAB AS(SELECT DISTINCT [Tab], [Affiliate Partner List] FROM @ResultSP,@ResultHeader)
INSERT INTO @Result ([Tag],[Parent],[ClientFilter!6],[Name!3],[Bookingpart!9!ID])
SELECT 6,2,[Affiliate Partner List],[Tab],CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

;WITH _TAB AS(SELECT DISTINCT [Tab], [Online Reservation Source] , [Offline Reservation Source] FROM @ResultSP,@ResultHeader)
INSERT INTO @Result ([Tag],[Parent],[ReservationSource!7],[Name!3],[Bookingpart!9!ID])
SELECT 7,2,CASE WHEN [Tab] = 'BASEOFFLINE' THEN [Offline Reservation Source] ELSE [Online Reservation Source] END,[Tab],CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

;WITH _TAB AS(SELECT DISTINCT [Tab], [Rebate-to Customer Name] FROM @ResultSP,@ResultHeader)
INSERT INTO @Result ([Tag],[Parent],[VendorName!8],[Name!3],[Bookingpart!9!ID])
SELECT 8,2,[Rebate-to Customer Name],[Tab],CASE [Tab] WHEN 'BASE' THEN 1000000 WHEN 'BASEONLINE' THEN 2000000 WHEN 'BASEOFFLINE' THEN 3000000 WHEN 'COMPANYRATE' THEN 4000000 END FROM _TAB

UPDATE SP SET SP.Tab = HL.Translation
  FROM @ResultSP SP
  JOIN @HeaderLabels HL
    ON HL.LabelID = SP.Tab

UPDATE SP SET SP.[Name!3] = HL.Translation
  FROM @Result SP
  JOIN @HeaderLabels HL
    ON HL.LabelID = SP.[Name!3]

INSERT INTO @Result ([Tag])                                                               VALUES(1)
INSERT INTO @Result ([Tag],[Parent],[Bookingpart!9!ID],[Name!3])                        SELECT DISTINCT 9,2,[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[InvoiceNo!10]        ,[Bookingpart!9!ID],[Name!3]) SELECT 10,9,[Invoice No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[ReservationNo!11]    ,[Bookingpart!9!ID],[Name!3]) SELECT 11,9,[Reservation No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[ReservationPartNo!12],[Bookingpart!9!ID],[Name!3]) SELECT 12,9,[Reservation Part No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[ClientNo!13]         ,[Bookingpart!9!ID],[Name!3]) SELECT 13,9,[Affiliate Partner No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[HotelNo!14]          ,[Bookingpart!9!ID],[Name!3]) SELECT 14,9,[Hotel No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[BonusID1!15]         ,[Bookingpart!9!ID],[Name!3]) SELECT 15,9,[Loyality Rewards Account 1 No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[BonusID2!16]         ,[Bookingpart!9!ID],[Name!3]) SELECT 16,9,[Loyality Rewards Account 2 No_],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[TurnoverLCY!17]      ,[Bookingpart!9!ID],[Name!3]) SELECT 17,9,[Turnover (LCY)],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[AmountLCY!18]        ,[Bookingpart!9!ID],[Name!3]) SELECT 18,9,[Amount (LCY)],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[TurnoverLCYCorr!19]  ,[Bookingpart!9!ID],[Name!3]) SELECT 19,9,[Turnover (LCY) (corr_)],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[AmountLCYCorr!20]    ,[Bookingpart!9!ID],[Name!3]) SELECT 20,9,[Amount (LCY) (corr_)],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[Turnover!21]         ,[Bookingpart!9!ID],[Name!3]) SELECT 21,9,[Turnover],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[Amount!22]           ,[Bookingpart!9!ID],[Name!3]) SELECT 22,9,[Amount],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[TurnoverCorr!23]     ,[Bookingpart!9!ID],[Name!3]) SELECT 23,9,[Turnover (corr_)],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[AmountCorr!24]       ,[Bookingpart!9!ID],[Name!3]) SELECT 24,9,[Amount (corr_)],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[RoomNights!25]       ,[Bookingpart!9!ID],[Name!3]) SELECT 25,9,[Room Nights],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[RoomNightsCorr!26]   ,[Bookingpart!9!ID],[Name!3]) SELECT 26,9,[Room Nights Post Corection],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[ReservationDate!27]  ,[Bookingpart!9!ID],[Name!3]) SELECT 27,9,[Reservation Date],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[ArivalDate!28]       ,[Bookingpart!9!ID],[Name!3]) SELECT 28,9,[Arival Date],[Line No_],[Tab] FROM @ResultSP
INSERT INTO @Result ([Tag],[Parent],[DepartueDate!29]     ,[Bookingpart!9!ID],[Name!3]) SELECT 29,9,[Departure Date],[Line No_],[Tab] FROM @ResultSP

INSERT INTO @Result ([Tag],[Parent],[Bookingpart!9!ID])                                                    SELECT 31,2,Number FROM @Pageoffset
INSERT INTO @Result ([Tag],[Parent],[DateRange1!32],[Bookingpart!9!ID])                                    SELECT 32,31,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'Periode'
INSERT INTO @Result ([Tag],[Parent],[DateRange2!33],[Bookingpart!9!ID])                                    SELECT 33,31,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'FiscalYear'
INSERT INTO @Result ([Tag],[Parent],[ClientFilter!34],[Bookingpart!9!ID])                                  SELECT 34,31,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'CustomerIDs'
INSERT INTO @Result ([Tag],[Parent],[ReservationSource!35],[Bookingpart!9!ID])                             SELECT 35,31,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'ReservationSource'
INSERT INTO @Result ([Tag],[Parent],[Bookingpart!9!ID])                                                    SELECT 36,2,Number FROM @Pageoffset
INSERT INTO @Result ([Tag],[Parent],[InvoiceNo!37],[Bookingpart!9!ID])                                     SELECT 37,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'InvoiceNo'
INSERT INTO @Result ([Tag],[Parent],[ReservationNo!38],[Bookingpart!9!ID])                                 SELECT 38,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'ReservationNo'
INSERT INTO @Result ([Tag],[Parent],[ReservationPartNo!39],[Bookingpart!9!ID])                             SELECT 39,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'PositionNo'
INSERT INTO @Result ([Tag],[Parent],[ClientNo!40],[Bookingpart!9!ID])                                      SELECT 40,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'CustomerIDs'
INSERT INTO @Result ([Tag],[Parent],[HotelNo!41],[Bookingpart!9!ID])                                       SELECT 41,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'HotelNo'
INSERT INTO @Result ([Tag],[Parent],[BonusID1!42],[Bookingpart!9!ID])                                      SELECT 42,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'BonusID1'
INSERT INTO @Result ([Tag],[Parent],[BonusID2!43],[Bookingpart!9!ID])                                      SELECT 43,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'BonusID2'
INSERT INTO @Result ([Tag],[Parent],[TurnoverLCY!44],[Bookingpart!9!ID])                                   SELECT 44,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'TurnoverLCY'
INSERT INTO @Result ([Tag],[Parent],[AmountLCY!45],[Bookingpart!9!ID])                                     SELECT 45,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'AmountLCY'
INSERT INTO @Result ([Tag],[Parent],[TurnoverLCYCorr!46],[Bookingpart!9!ID])                               SELECT 46,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'TurnoverLCYCorr'
INSERT INTO @Result ([Tag],[Parent],[AmountLCYCorr!47],[Bookingpart!9!ID])                                 SELECT 47,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'AmountLCYCorr'
INSERT INTO @Result ([Tag],[Parent],[Turnover!48],[Bookingpart!9!ID])                                      SELECT 48,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'Turnover'
INSERT INTO @Result ([Tag],[Parent],[Amount!49],[Bookingpart!9!ID])                                        SELECT 49,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'Amount'
INSERT INTO @Result ([Tag],[Parent],[TurnoverCorr!50],[Bookingpart!9!ID])                                  SELECT 50,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'TurnoverCorr'
INSERT INTO @Result ([Tag],[Parent],[AmountCorr!51],[Bookingpart!9!ID])                                    SELECT 51,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'AmountCorr'
INSERT INTO @Result ([Tag],[Parent],[RoomNights!52],[Bookingpart!9!ID])                                    SELECT 52,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'Roomnights'
INSERT INTO @Result ([Tag],[Parent],[RoomNightsCorr!53],[Bookingpart!9!ID])                                SELECT 53,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'RoomnightsCorr'
INSERT INTO @Result ([Tag],[Parent],[ReservationDate!54],[Bookingpart!9!ID])                               SELECT 54,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'ReservationDate'
INSERT INTO @Result ([Tag],[Parent],[ArivalDate!55],[Bookingpart!9!ID])                                    SELECT 55,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'ArivalDate'
INSERT INTO @Result ([Tag],[Parent],[DepartueDate!56],[Bookingpart!9!ID])                                  SELECT 56,36,Translation,Number FROM @HeaderLabels, @Pageoffset WHERE LabelID = 'DepartureDate'

INSERT INTO @Result ([Tag],[Parent],[Bookingpart!9!ID])                                                    VALUES (57,2,@FirstPage)
INSERT INTO @Result ([Tag],[Parent],[CompanyRates!64],[Bookingpart!9!ID])                                  SELECT 64,57,[Net Rate Share],@FirstPage            FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[NonCommissionables!65],[Bookingpart!9!ID])                            SELECT 65,57,[Non Commissionables],@FirstPage       FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[CommissionableTurnover!66],[Bookingpart!9!ID])                        SELECT 66,57,[Commissionable Turnover],@FirstPage   FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[AvgCommissionRate!67],[Bookingpart!9!ID])                             SELECT 67,57,[Average Commission Rate],@FirstPage   FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[CorrectionRateCommission!68],[Bookingpart!9!ID])                      SELECT 68,57,[Amount Correction Ratio],@FirstPage   FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[CorrectionRateHotelTurnover!69],[Bookingpart!9!ID])                   SELECT 69,57,[Turnover Correction Ratio],@FirstPage FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[CompanyRatesRatio!70],[Bookingpart!9!ID])                             SELECT 70,57,[Net Rate Share Ratio],@FirstPage      FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[RevenueShareRatio!71],[Bookingpart!9!ID])                             SELECT 71,57,[Revenue Share Ratio],@FirstPage       FROM @ResultSummary
INSERT INTO @Result ([Tag],[Parent],[ValueP1!72],[Bookingpart!9!ID])                                       SELECT 72,57,[Value P1],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP2!73],[Bookingpart!9!ID])                                       SELECT 73,57,[Value P2],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP3!74],[Bookingpart!9!ID])                                       SELECT 74,57,[Value P3],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP4!75],[Bookingpart!9!ID])                                       SELECT 75,57,[Value P4],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP5!76],[Bookingpart!9!ID])                                       SELECT 76,57,[Value P5],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP6!77],[Bookingpart!9!ID])                                       SELECT 77,57,[Value P6],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP7!78],[Bookingpart!9!ID])                                       SELECT 78,57,[Value P7],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP8!79],[Bookingpart!9!ID])                                       SELECT 79,57,[Value P8],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP9!80],[Bookingpart!9!ID])                                       SELECT 80,57,[Value P9],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValueP10!81],[Bookingpart!9!ID])                                      SELECT 81,57,[Value P10],@FirstPage                 FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[ValuePA!82],[Bookingpart!9!ID])                                       SELECT 82,57,[Value PA],@FirstPage                  FROM @ResultHeader
INSERT INTO @Result ([Tag],[Parent],[Bookingpart!9!ID])                                                    VALUES (83,2,@FirstPage)
INSERT INTO @Result ([Tag],[Parent],[CompanyRates!84],[Bookingpart!9!ID])                                  SELECT 84,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'CompanyRates'
INSERT INTO @Result ([Tag],[Parent],[NonCommissionables!85],[Bookingpart!9!ID])                            SELECT 85,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'NonCommissionables'
INSERT INTO @Result ([Tag],[Parent],[CommissionableTurnover!86],[Bookingpart!9!ID])                        SELECT 86,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'CommissionableTurnover'
INSERT INTO @Result ([Tag],[Parent],[AvgCommissionRate!87],[Bookingpart!9!ID])                             SELECT 87,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'AvgCommissionRate'
INSERT INTO @Result ([Tag],[Parent],[CorrectionRateCommission!88],[Bookingpart!9!ID])                      SELECT 88,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'CorrectionRateCommission'
INSERT INTO @Result ([Tag],[Parent],[CorrectionRateHotelTurnover!89],[Bookingpart!9!ID])                   SELECT 89,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'CorrectionRateHotelTurnover'
INSERT INTO @Result ([Tag],[Parent],[CompanyRatesRatio!90],[Bookingpart!9!ID])                             SELECT 90,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'CompanyRatesRatio'
INSERT INTO @Result ([Tag],[Parent],[RevenueShareRatio!91],[Bookingpart!9!ID])                             SELECT 91,83,Translation,@FirstPage FROM @HeaderLabels WHERE LabelID = 'RevenueShareRatio'
  
SELECT * FROM @Result ORDER BY [Bookingpart!9!ID],[Tag]
FOR XML EXPLICIT

END
GO
