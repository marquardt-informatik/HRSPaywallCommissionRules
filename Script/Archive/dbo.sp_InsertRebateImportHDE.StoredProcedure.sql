USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertRebateImportHDE]    Script Date: 10.04.2024 14:31:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 14.11.13
-- Description:	Übertragung der Bonuszeilen ohne Webservice
/*

EXEC sp_InsertRebateImportHDE '90002'
EXEC sp_InsertRebateImportHDE '90014'
GO
EXEC sp_InsertRebateImportHDE '90013'
GO
EXEC sp_InsertRebateImportHDE '90015'
GO
EXEC sp_InsertRebateImportHDE '90130'
GO
EXEC sp_InsertRebateImportHDE '90022'
GO
EXEC sp_InsertRebateImportHDE '90038'
GO
EXEC sp_InsertRebateImportHDE''

TRUNCATE TABLE [hotel_de$Rebate Import]

SELECT * FROM [hotel_de$Rebate Import] WITH (NOLOCK)
  
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_InsertRebateImportHDE]
  @VendorNo varchar(20) = ''
AS
BEGIN
DECLARE @Updates TABLE
(
    [Reservation No_]                  int
  , [Reservation Part No_]             int
  , [Process Number]                   int
  , [Posting Date]                     date
  , [Document Date]                    date
  , [Travelagency Code]                varchar(10)
  , [Travelagency No_]                 int
  , [Rebate Agreement No_]             varchar(20)
  , [Company Name]                     varchar(30)
  , [Invoice No_]                      varchar(20)
  , [Description]                      varchar(250)
  , [Description 2]                    varchar(250)
  , [Amount (LCY)]                     decimal(37,20)
  , [Turnover (LCY)]                   decimal(37,20)
  , [Turnover Breakfast (LCY)]         decimal(37,20)
  , [Net Turnover (LCY)]               decimal(37,20)
  , [Amount]                           decimal(37,20)
  , [Turnover]                         decimal(37,20)
  , [Net Turnover]                     decimal(37,20)
  , [Commission Type]                  int
  , [Commission Rate %]                decimal(37,20)
  , [Room Nights]                      decimal(37,20)
  , [Is Net Rate]                      tinyint
  , [Amount (LCY) (corr_)]             decimal(37,20)
  , [Turnover (LCY) (corr_)]           decimal(37,20)
  , [Turnover Breakfast (LCY) (corr_)] decimal(37,20)
  , [Net Turnover (LCY) (corr_)]       decimal(37,20)
  , [Amount (corr_)]                   decimal(37,20)
  , [Turnover (corr_)]                 decimal(37,20)
  , [Net Turnover (corr_)]             decimal(37,20)
  , [Commission Type (corr_)]          int
  , [Commission Rate % (corr_)]        decimal(37,20)
  , [Room Nights (corr_)]              decimal(37,20)
  , [Is Net Rate (corr_)]              tinyint
  , [Is No Show]                       tinyint
  , [Reservation Date]                 date
  , [Arrival Date]                     date
  , [Departure Date]                   date
  , [Affiliate Partner No_]            varchar(20)
  , [Hotel No_]                        varchar(20)
  , [Customer No_]                     varchar(20)
  , [Country Code]                     varchar(20)
  , [Chain]                            varchar(10)
  , [Brand]                            varchar(10)
  , [MuseID]                           varchar(20)
  , [Top Bonus ID]                     varchar(20) 
  , [Loyality Rewards Account 1 No_]   varchar(100)
  , [Loyality Rewards Account 2 No_]   varchar(100)
  , [Reservation Source]               int
  , [Booking User]                     varchar(120)
  , [Booking Code]                     varchar(80)
  , [Currency Factor]                  decimal(37,20)
  , [Currency Code]                    varchar(10)
  , [Currency Factor (corr_)]          decimal(37,20)
  , [Currency Code (corr_)]            varchar(10)
  , [K-Amount (LCY)]                   decimal(37,20)
  , [K-Turnover (LCY)]                 decimal(37,20)
  , [K-Amount (LCY) (corr_)]           decimal(37,20)
  , [K-Turnover (LCY) (corr_)]         decimal(37,20)
  , [K-Room Nights]                    decimal(37,20)
  , [K-Room Nights (corr_)]            decimal(37,20)
  , [K-Net Turnover (LCY)]             decimal(37,20)
  , [K-Net Turnover (LCY) (corr_)]     decimal(37,20)
  , [K-Net Turnover]                   decimal(37,20)
  , [K-Net Turnover (corr_)]           decimal(37,20)
  , [Eligible RevShare]                tinyint
  , [Post Affiliate Partner No_]       varchar(20)
  , [Max Entry No_]                    int
  , [Handbooking]                      tinyint
  , [Rebate-to Vendor No_]             varchar(20)
  , [Interval]                         int
  , [Interval Start Date]              date
  , [Interval End Date]                date
  , [Correction Kennung]               int
  , [Date Interval Coordination]       date
  , [DatenOK]                          tinyint
  , [Error Text]                       varchar(250)
  , [Posted]                           tinyint
  , [Existing]                         tinyint
  , UNIQUE NONCLUSTERED  
    (
	    [Reservation No_] ASC
	  , [Reservation Part No_] ASC
    )
)

;WITH APV AS
(
  SELECT C.Name [Company Name], [Affiliate Partner No_], AH.[Enable retroactive correction], COUNT(1) CountAPV, AH.[No_] [Rebate Agreement No_], APV.[Vendor No_]
    FROM [Company] C, [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK), [hotel_de$Affiliate Partner Vendor] APV  WITH (NOLOCK)
   WHERE C.Name IN ('HRS','HRS-CN','TISCOVER','HRS-BR','Partner')
     AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_]
     AND (APV.[Vendor No_] = @VendorNo OR @VendorNo = '')
	 AND AH.[Active] = 1
     --AND AH.[Group contract Code] = 'DER'
GROUP BY C.Name, APV.[Affiliate Partner No_], AH.[Enable retroactive correction], AH.[No_], APV.[Vendor No_]
), APT AS
(
  SELECT C.Name [Company Name], APV.[Travelagency No_], AH.[Enable retroactive correction], COUNT(1) CountAPV, AH.[No_] [Rebate Agreement No_], APV.[Vendor No_]
    FROM [Company] C, [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK), [hotel_de$Vendor Travelagency] APV  WITH (NOLOCK)
   WHERE C.Name IN ('HRS','HRS-CN','TISCOVER','HRS-BR','Partner')
     AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_]
     AND (APV.[Vendor No_] = @VendorNo OR @VendorNo = '')
	 AND AH.[Active] = 1
     --AND AH.[Group contract Code] = 'DER'
GROUP BY C.Name, APV.[Travelagency No_], AH.[Enable retroactive correction], AH.[No_], APV.[Vendor No_]
), _RL AS
(
  SELECT RL.[Reservation No_]
       , RL.[Reservation Part No_]
	   , RL.[Rebate Agreement No_]
       , 0 [Posted]
       , SUM(RL.[Amount (LCY)])               [Amount (LCY)]
       , SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
       , SUM(RL.[Room Nights])                [Room Nights]
       , SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
       , SUM(RL.[Turnover])                   [Turnover]
       , SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
    FROM [hotel_de$Rebate Line] RL
    JOIN APV
      ON APV.[Affiliate Partner No_] = RL.[Affiliate Partner No_]
   WHERE APV.[Company Name]             = 'HRS'
GROUP BY RL.[Reservation No_]
       , RL.[Reservation Part No_]    
	   , RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Reservation No_]
       , RL.[Reservation Part No_]
	   , RL.[Rebate Agreement No_]
       , 0 [Posted]
       , SUM(RL.[Amount (LCY)])               [Amount (LCY)]
       , SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
       , SUM(RL.[Room Nights])                [Room Nights]
       , SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
       , SUM(RL.[Turnover])                   [Turnover]
       , SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
    FROM [hotel_de$Rebate Line] RL
    JOIN APT
      ON APT.[Travelagency No_]      = RL.[Travelagency No_]
   WHERE APT.[Company Name]             = 'HRS'
GROUP BY RL.[Reservation No_]
       , RL.[Reservation Part No_]    
	   , RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Reservation No_]
       , RL.[Reservation Part No_]
	   , RL.[Rebate Agreement No_]
       , 1 [Posted]
       , SUM(RL.[Amount (LCY)])               [Amount (LCY)]
       , SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
       , SUM(RL.[Room Nights])                [Room Nights]
       , SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
       , SUM(RL.[Turnover])                   [Turnover]
       , SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
    FROM [hotel_de$Posted Rebate Line] RL
    JOIN APV
      ON APV.[Affiliate Partner No_] = RL.[Affiliate Partner No_]
   WHERE APV.[Company Name]             = 'HRS'
     AND RL.[Cancels] = 0
GROUP BY RL.[Reservation No_]
       , RL.[Reservation Part No_]    
	   , RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Reservation No_]
       , RL.[Reservation Part No_]
	   , RL.[Rebate Agreement No_]
       , 1 [Posted]
       , SUM(RL.[Amount (LCY)])               [Amount (LCY)]
       , SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
       , SUM(RL.[Room Nights])                [Room Nights]
       , SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
       , SUM(RL.[Turnover])                   [Turnover]
       , SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
    FROM [hotel_de$Posted Rebate Line] RL
    JOIN APT
      ON APT.[Travelagency No_]      = RL.[Travelagency No_]
   WHERE APT.[Company Name]             = 'HRS'
     AND RL.[Cancels] = 0
GROUP BY RL.[Reservation No_]
       , RL.[Reservation Part No_]    
	   , RL.[Rebate Agreement No_]
), RL AS
(
  SELECT RL.[Reservation No_]
       , RL.[Reservation Part No_]
	   , RL.[Rebate Agreement No_]
       , MAX(RL.[Posted])                 [Posted]
       , SUM(RL.[Amount (LCY)])           [Amount (LCY)]
       , SUM(RL.[Turnover (LCY)])         [Turnover (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)])   [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
       , SUM(RL.[Room Nights])            [Room Nights]
       , SUM(RL.[Room Nights (corr_)])    [Room Nights (corr_)]
       , SUM(RL.[Turnover])                   [Turnover]
       , SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
    FROM _RL RL
GROUP BY RL.[Reservation No_]
       , RL.[Reservation Part No_]    
	   , RL.[Rebate Agreement No_]
), _APV AS
(
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS'
    WHERE AP.[DepartureDate]>= '2017-01-01'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS-CN'
    WHERE AP.[DepartureDate]>= '2017-01-01'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS-BR'
    WHERE AP.[DepartureDate]>= '2017-01-01'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'TISCOVER'
    WHERE AP.[DepartureDate]>= '2017-01-01'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [Partner$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'Partner'
    WHERE AP.[DepartureDate]>= '2017-01-01'
), _APT AS
(
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [HRS$Affiliate Postings]  AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'HRS'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'HRS-CN'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'HRS-BR'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'TISCOVER'
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [Partner$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'Partner'
), _AP AS
(
   SELECT * FROM _APV
UNION
   SELECT * FROM _APT   
), AP AS
(
  SELECT AP.ReservationNo                         [Reservation No_]
       , AP.ReservationPartNo                     [Reservation Part No_]
       , MAX(COALESCE(AP.IsNoShow,0))             [Is No Show]
       , MAX(COALESCE(AP.ProcessNumber,0))        [Process Number]
       , MAX([Company Name])                      [Company Name]
       , MAX(AP.PostingDate)                      [Posting Date]
       , MAX(AP.DocumentDate)                     [Document Date]
       , MAX(COALESCE([Travelagency Code],''))    [Travelagency Code]
       , MAX(COALESCE([Travelagency No_],0))      [Travelagency No_]
       , MIN(AP.[Rebate Agreement No_])           [Rebate Agreement No_]
       , MIN(AP.InvoiceNo)                        [Invoice No_]
       , MAX(COALESCE([Description],''))          [Description]
       , MAX(COALESCE([Description2],''))         [Description 2]
       , SUM(AP.Amount_LCY)                       [Amount (LCY)]
       , SUM(AP.Turnover_LCY)                     [Turnover (LCY)]
       , SUM(AP.Amount)                           [Amount]
       , SUM(AP.Turnover)                         [Turnover]
       , SUM(AP.Amount_LCY_corr)                  [Amount (LCY) (corr_)]
       , SUM(AP.Turnover_LCY_corr)                [Turnover (LCY) (corr_)]
       , SUM(AP.Amount_corr)                      [Amount (corr_)]
       , SUM(AP.Turnover_corr)                    [Turnover (corr_)]
       , SUM(AP.RoomNights)                       [Room Nights]
       , SUM(AP.RoomNights_corr)                  [Room Nights (corr_)]
       , MAX(COALESCE(AP.IsNetRate,0))            [Is Net Rate]
       , MAX(COALESCE(AP.IsNetRate_corr,0))       [Is Net Rate (corr_)]
       , MAX(
            CASE AP.[CommissionType]
              WHEN 'Prozent' THEN 0
              WHEN 'Fix' THEN 1
              WHEN 'Prozent+Fix' THEN 2
              WHEN 'Prozent ohne Frstk' THEN 3
              WHEN 'Prozent ohne Frstk+Fix' THEN 4
              WHEN 'Online' THEN 5
              WHEN 'Zusatzprovision' THEN 6
              WHEN '% netto Logis' THEN 7
              WHEN '% netto Logis + Frstk' THEN 8
              WHEN '% Nettoumsatz' THEN 9
              WHEN 'keine Angaben' THEN 10
              WHEN 'Fix pro RN' THEN 11
              WHEN 'Default' THEN 12
              WHEN 'Company Rate' THEN 13
              ELSE 13
            END
          )                                       [Commission Type]
       , MAX(AP.CommissionRateProz)               [Commission Rate %]
       , MAX(
            CASE AP.[CommissionType_corr]
              WHEN 'Prozent' THEN 0
              WHEN 'Fix' THEN 1
              WHEN 'Prozent+Fix' THEN 2
              WHEN 'Prozent ohne Frstk' THEN 3
              WHEN 'Prozent ohne Frstk+Fix' THEN 4
              WHEN 'Online' THEN 5
              WHEN 'Zusatzprovision' THEN 6
              WHEN '% netto Logis' THEN 7
              WHEN '% netto Logis + Frstk' THEN 8
              WHEN '% Nettoumsatz' THEN 9
              WHEN 'keine Angaben' THEN 10
              WHEN 'Fix pro RN' THEN 11
              WHEN 'Default' THEN 12
              WHEN 'Company Rate' THEN 13
              ELSE 13
            END
          )                                       [Commission Type (corr_)]
       , MAX(AP.CommissionRateProz_corr)          [Commission Rate % (corr_)]
       , MAX(AP.ReservationDate)                  [Reservation Date]
       , MAX(AP.ArivalDate)                       [Arrival Date]
       , MAX(AP.DepartureDate)                    [Departure Date]
       , MAX(AP.AffiliatePartnerNo)               [Affiliate Partner No_]
       , MAX(AP.HotelNo)                          [Hotel No_]
       , MAX(COALESCE(AP.CountryCode,''))         [Country Code]
       , MAX(COALESCE(AP.Chain,''))               [Chain]
       , MAX(COALESCE(AP.Brand,''))               [Brand]
       , MAX(COALESCE(AP.MuseID,''))              [MuseID]
       , MAX(COALESCE(AP.TopBonusID,''))          [Top Bonus ID]
       , MAX(COALESCE(AP.AffiliateReference1,'')) [Loyality Rewards Account 1 No_]
       , MAX(COALESCE(AP.AffiliateReference2,'')) [Loyality Rewards Account 2 No_]
       , MAX(COALESCE(AP.ReservationSource,0))    [Reservation Source]
       , MAX(COALESCE(AP.Orderer,''))             [Booking User]
       , MAX(COALESCE(AP.BookingCode,''))         [Booking Code]
       , SUM(AP.Turnover_Breakfast_LCY)           [Turnover Breakfast (LCY)]
       , SUM(AP.Turnover_Breakfast_LCY_corr)      [Turnover Breakfast (LCY) (corr_)]
       , MAX(AP.CurrencyFaktor)                   [Currency Factor]
       , MAX(AP.CurrencyFaktor_corr)              [Currency Factor (corr_)]
       , MAX(AP.CurrencyCode)                     [Currency Code]
       , MAX(AP.CurrencyCode_corr)                [Currency Code (corr_)]
    FROM _AP AP
GROUP BY AP.ReservationNo
       , AP.ReservationPartNo    
), _RAH AS
(
   SELECT [No_]
        , [Rebate-to Vendor No_]
        , CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END [Valid from]
        , CASE WHEN [Valid to]   = '1753-01-01' THEN '2099-12-31' ELSE [Valid to] END [Valid to]
        , [Interval]
        , CASE WHEN [Fiscal Year Start (Month)] = 0 THEN 1 ELSE [Fiscal Year Start (Month)] END [Fiscal Year Start (Month)]
        , CASE WHEN [Fiscal Year End (Month)] = 0 THEN 12 ELSE [Fiscal Year End (Month)] END [Fiscal Year End (Month)]
        , [Enable retroactive correction]
        , [Active]
        , CASE [Interval] 
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END)
            WHEN 1 THEN DATEADD(mm,-DATEPART(mm,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END)%3+1, DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END))
            WHEN 2 THEN DATEADD(mm,-DATEPART(mm,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END)%6+1, DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END))
            WHEN 3 THEN DATEADD(mm,-DATEPART(mm,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END)%12+1, DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2016-01-01' ELSE [Valid from] END))
          END [Max_ Interval End Date]
     FROM [hotel_de$Rebate Agreement Header] AH WITH (NOLOCK)
    WHERE [Is Template] = 0
), URH AS
(
--  SELECT RH.[Rebate Agreement No_]
--       , MAX(RH.[Interval End Date]) [Max_ Interval End Date]
--    FROM [hotel_de$Rebate Header] RH WITH (NOLOCK)
--GROUP BY RH.[Rebate Agreement No_]
--UNION
  SELECT RH.[Rebate Agreement No_]
       , MAX(RH.[Interval End Date]) [Max_ Interval End Date]
    FROM [hotel_de$Posted Rebate Header] RH WITH (NOLOCK)
   WHERE RH.[Cancels] = 0
GROUP BY RH.[Rebate Agreement No_]
), RH AS
(
  SELECT [Rebate Agreement No_]
       , MAX([Max_ Interval End Date]) [Max_ Interval End Date]
    FROM URH
GROUP BY [Rebate Agreement No_]
), RAH AS
(
   SELECT AH.[No_] [Rebate Agreement No_]
        , AH.[Rebate-to Vendor No_]
        , COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]) [Max_ Interval End Date]
        , CASE WHEN MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])) = [Fiscal Year End (Month)] THEN 
            DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))
          ELSE
            DATEADD(mm,-MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))+[Fiscal Year Start (Month)]-1, DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])))
          END [Fiscal Year Start]
        , DATEADD(dd, -1, DATEADD(mm,12,CASE WHEN MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])) = [Fiscal Year End (Month)] THEN 
            DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))
          ELSE
            DATEADD(mm,-MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))+[Fiscal Year Start (Month)]-1, DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])))
          END)) [Fiscal Year End]
        , DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])) [Next Interval Start Date]
        , CASE [Interval]
            WHEN 0 THEN DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
            WHEN 1 THEN DATEADD(dd,-1,DATEADD(mm,3,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
            WHEN 2 THEN DATEADD(dd,-1,DATEADD(mm,6,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
            WHEN 3 THEN DATEADD(dd,-1,DATEADD(mm,12,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
          END [Next Interval End Date]
        , [Valid from]
        , [Valid to]
        , [Interval]
        , [Enable retroactive correction]
        , [Active]
     FROM _RAH AH
LEFT JOIN RH ON AH.[No_] = RH.[Rebate Agreement No_]
)
  INSERT INTO @Updates
   SELECT AP.[Reservation No_]
        , AP.[Reservation Part No_]
        , AP.[Process Number]
        , AP.[Posting Date]
        , AP.[Document Date]
        , AP.[Travelagency Code]
        , AP.[Travelagency No_]
        , AP.[Rebate Agreement No_]
        , AP.[Company Name]
        , AP.[Invoice No_]
        , AP.[Description]
        , AP.[Description 2]
        , AP.[Amount (LCY)]
        , AP.[Turnover (LCY)]
        , AP.[Turnover Breakfast (LCY)]
        , AP.[Turnover (LCY)] * COALESCE(100./(100+FT.[VAT in %]),1)
        , AP.[Amount]
        , AP.[Turnover]
        , AP.[Turnover] * COALESCE(100./(100+FT.[VAT in %]),1)
        , AP.[Commission Type]
        , AP.[Commission Rate %]
        , AP.[Room Nights]
        , AP.[Is Net Rate]
        , AP.[Amount (LCY) (corr_)]
        , AP.[Turnover (LCY) (corr_)]
        , AP.[Turnover Breakfast (LCY) (corr_)]
        , AP.[Turnover (LCY) (corr_)] * COALESCE(100./(100+FT.[VAT in %]),1)
        , AP.[Amount (corr_)]
        , AP.[Turnover (corr_)]
        , AP.[Turnover (corr_)] * COALESCE(100./(100+FT.[VAT in %]),1)
        , AP.[Commission Type (corr_)]
        , AP.[Commission Rate % (corr_)]
        , AP.[Room Nights (corr_)]
        , AP.[Is Net Rate (corr_)]
        , AP.[Is No Show]
        , AP.[Reservation Date]
        , AP.[Arrival Date]
        , AP.[Departure Date]
        , AP.[Affiliate Partner No_]
        , AP.[Hotel No_]
        , AP.[Hotel No_]
        , AP.[Country Code]
        , AP.[Chain]
        , AP.[Brand]
        , AP.[MuseID]
        , AP.[Top Bonus ID]
        , AP.[Loyality Rewards Account 1 No_]
        , AP.[Loyality Rewards Account 2 No_]
        , AP.[Reservation Source]
        , AP.[Booking User]
        , AP.[Booking Code]
        , AP.[Currency Factor]
        , AP.[Currency Code]
        , AP.[Currency Factor (corr_)]
        , AP.[Currency Code (corr_)]
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Amount (LCY)] IS NULL           THEN 0 ELSE AP.[Amount (LCY)]           - COALESCE(RL.[Amount (LCY)],0)           END
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY)] IS NULL         THEN 0 ELSE AP.[Turnover (LCY)]         - COALESCE(RL.[Turnover (LCY)],0)         END
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Amount (LCY) (corr_)] IS NULL   THEN 0 ELSE AP.[Amount (LCY) (corr_)]   - COALESCE(RL.[Amount (LCY) (corr_)],0)   END
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY) (corr_)] IS NULL THEN 0 ELSE AP.[Turnover (LCY) (corr_)] - COALESCE(RL.[Turnover (LCY) (corr_)],0) END
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Room Nights] IS NULL            THEN 0 ELSE AP.[Room Nights]            - COALESCE(RL.[Room Nights],0)            END
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Room Nights (corr_)] IS NULL    THEN 0 ELSE AP.[Room Nights (corr_)]    - COALESCE(RL.[Room Nights (corr_)],0)    END
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY)] IS NULL         THEN 0 ELSE AP.[Turnover (LCY)]         - COALESCE(RL.[Turnover (LCY)],0)         END * COALESCE(100./(100+FT.[VAT in %]),1)
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY) (corr_)] IS NULL THEN 0 ELSE AP.[Turnover (LCY) (corr_)] - COALESCE(RL.[Turnover (LCY) (corr_)],0) END * COALESCE(100./(100+FT.[VAT in %]),1)
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover] IS NULL               THEN 0 ELSE AP.[Turnover]               - COALESCE(RL.[Turnover],0)         END * COALESCE(100./(100+FT.[VAT in %]),1)
        , CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (corr_)] IS NULL       THEN 0 ELSE AP.[Turnover (corr_)]       - COALESCE(RL.[Turnover (corr_)],0) END * COALESCE(100./(100+FT.[VAT in %]),1)
        , 0 [Eligible RevShare]
        , '' [Post Affiliate Partner No_]
        , 0 [Max Entry No_]
        , 0 [Handbooking]
        , RAH.[Rebate-to Vendor No_]
        , RAH.[Interval]
        , RAH.[Next Interval Start Date]
        , RAH.[Next Interval End Date]
        , CASE WHEN RL.[Amount (LCY)] IS NULL THEN 0 ELSE 1 END
        , RAH.[Next Interval Start Date]
        , 0
        , ''
        , COALESCE(RL.[Posted],0)
        , CASE WHEN RL.[Posted] IS NULL THEN 0 ELSE 1 END
     FROM AP
LEFT JOIN RL
       ON RL.[Reservation No_]          = AP.[Reservation No_]
      AND RL.[Reservation Part No_]     = AP.[Reservation Part No_]
	  AND RL.[Rebate Agreement No_]     = AP.[Rebate Agreement No_]    
     JOIN RAH
       ON RAH.[Rebate Agreement No_]    = AP.[Rebate Agreement No_]
LEFT JOIN [hotel_de$Foreign Tax] FT WITH (NOLOCK)
       ON AP.[Country Code] = FT.Country       
    WHERE (
          AP.[Amount (LCY)]            <> COALESCE(RL.[Amount (LCY)],0)
       OR AP.[Turnover (LCY)]          <> COALESCE(RL.[Turnover (LCY)],0)
       OR AP.[Amount (LCY) (corr_)]    <> COALESCE(RL.[Amount (LCY) (corr_)],0)
       OR AP.[Turnover (LCY) (corr_)]  <> COALESCE(RL.[Turnover (LCY) (corr_)],0)
          )
      AND AP.[Departure Date] >= DATEADD(yy,-1,RAH.[Fiscal Year Start])
      AND AP.[Departure Date] >= '2017-01-01'
	  AND NOT AP.[Affiliate Partner No_] IN (SELECT [Affiliate Partner No_] FROM [HRS$Affiliate Partner Vendor] WITH (NOLOCK))
--SELECT * FROM @Updates
      
INSERT INTO [hotel_de$Rebate Import]
     (
       [Reservation No_]
     , [Reservation Part No_]
     , [Process Number]
     , [Posting Date]
     , [Document Date]
     , [Travelagency No_]
     , [Rebate Agreement No_]
     , [Company Name]
     , [Invoice No_]
     , [Description]
     , [Description 2]
     , [Amount (LCY)]
     , [Turnover (LCY)]
     , [Turnover Breakfast (LCY)]
     , [Net Turnover (LCY)]
     , [Amount]
     , [Turnover]
     , [Net Turnover]
     , [Commission Type]
     , [Commission Rate %]
     , [Room Nights]
     , [Is Net Rate]
     , [Amount (LCY) (corr_)]
     , [Turnover (LCY) (corr_)]
     , [Turnover Breakfast (LCY) (c_)]
     , [Net Turnover (LCY) (corr_)]
     , [Amount (corr_)]
     , [Turnover (corr_)]
     , [Net Turnover (corr_)]
     , [Commission Type (corr_)]
     , [Commission Rate % (corr_)]
     , [Room Nights Post Corection]
     , [Is Net Rate Post Corection]
     , [Is No Show]
     , [Reservation Date]
     , [Arival Date]
     , [Departure Date]
     , [Affiliate Partner No_]
     , [Hotel No_]
     , [Customer No_]
     , [Country Code]
     , [Chain]
     , [Brand]
     , [MuseID]
     , [Top Bonus ID]
     , [Loyality Rewards Account 1 No_]
     , [Loyality Rewards Account 2 No_]
     , [Reservation Source]
     , [Booking User]
     , [Booking Code]
     , [Currency Faktor]
     , [Currency Code]
     , [Currency Faktor (corr_)]
     , [Currency Code (corr_)]
     , [K-Amount (LCY)]
     , [K-Turnover (LCY)]
     , [K-Amount (LCY) (corr_)]
     , [K-Turnover (LCY) (corr_)]
     , [K-Room Nights]
     , [K-Room Nights Post Corection]
     , [K-Net Turnover (LCY)]
     , [K-Net Turnover (LCY) (corr_)]
     , [K-Net Turnover]
     , [K-Net Turnover (corr_)]
     , [Eligible RevShare]
     , [Post Affiliate Partner No_]
     , [Max Entry No_]
     , [Handbooking]
     , [Rebate-to Vendor No_]
     , [Interval]
     , [Interval Start Date]
     , [Interval End Date]
     , [Correction Kennung]
     , [Date Interval Coordination]
     , [DatenOK]
     , [Error Text]
     )
SELECT [Reservation No_]
     , [Reservation Part No_]
     , [Process Number]
     , [Posting Date]
     , [Document Date]
     , [Travelagency No_]
     , [Rebate Agreement No_]
     , [Company Name]
     , [Invoice No_]
     , [Description]
     , [Description 2]
     , [Amount (LCY)]
     , [Turnover (LCY)]
     , [Turnover Breakfast (LCY)]
     , [Net Turnover (LCY)]
     , [Amount]
     , [Turnover]
     , [Net Turnover]
     , [Commission Type]
     , [Commission Rate %]
     , [Room Nights]
     , [Is Net Rate]
     , [Amount (LCY) (corr_)]
     , [Turnover (LCY) (corr_)]
     , [Turnover Breakfast (LCY) (corr_)]
     , [Net Turnover (LCY) (corr_)]
     , [Amount (corr_)]
     , [Turnover (corr_)]
     , [Net Turnover (corr_)]
     , [Commission Type (corr_)]
     , [Commission Rate % (corr_)]
     , [Room Nights (corr_)]
     , [Is Net Rate (corr_)]
     , [Is No Show]
     , [Reservation Date]
     , [Arrival Date]
     , [Departure Date]
     , [Affiliate Partner No_]
     , [Hotel No_]
     , [Customer No_]
     , [Country Code]
     , [Chain]
     , [Brand]
     , [MuseID]
     , [Top Bonus ID]
     , [Loyality Rewards Account 1 No_]
     , [Loyality Rewards Account 2 No_]
     , [Reservation Source]
     , [Booking User]
     , [Booking Code]
     , [Currency Factor]
     , [Currency Code]
     , [Currency Factor (corr_)]
     , [Currency Code (corr_)]
     , [K-Amount (LCY)]
     , [K-Turnover (LCY)]
     , [K-Amount (LCY) (corr_)]
     , [K-Turnover (LCY) (corr_)]
     , [K-Room Nights]
     , [K-Room Nights (corr_)]
     , [K-Net Turnover (LCY)]
     , [K-Net Turnover (LCY) (corr_)]
     , [K-Net Turnover]
     , [K-Net Turnover (corr_)]
     , [Eligible RevShare]
     , [Post Affiliate Partner No_]
     , [Max Entry No_]
     , [Handbooking]
     , [Rebate-to Vendor No_]
     , [Interval]
     , [Interval Start Date]
     , [Interval End Date]
     , [Correction Kennung]
     , [Date Interval Coordination]
     , 0--[DatenOK]
     , [Error Text]
  FROM @Updates UP
 WHERE ([Existing] = 0 OR Posted = 1)
   AND [Departure Date] >= '2017-01-01'
--   AND [Process Number] IN (65447351,65317707,65917505,65950508,70467138)
OPTION (MAXDOP 1)  

--SELECT * FROM  [hotel_de$Rebate Import]
    
UPDATE RL SET
       RL.[Amount (LCY)]                     = AP.[Amount (LCY)]
     , RL.[Turnover (LCY)]                   = AP.[Turnover (LCY)]
     , RL.[Turnover Breakfast (LCY)]         = AP.[Turnover Breakfast (LCY)]
     , RL.[Net Turnover (LCY)]               = AP.[Net Turnover (LCY)]
     , RL.[Amount]                           = AP.[Amount]
     , RL.[Turnover]                         = AP.[Turnover]
     , RL.[Net Turnover]                     = AP.[Net Turnover]
     , RL.[Commission Type]                  = AP.[Commission Type]
     , RL.[Commission Rate %]                = AP.[Commission Rate %]
     , RL.[Room Nights]                      = AP.[Room Nights]
     , RL.[Is Net Rate]                      = AP.[Is Net Rate]
     , RL.[Amount (LCY) (corr_)]             = AP.[Amount (LCY) (corr_)]
     , RL.[Turnover (LCY) (corr_)]           = AP.[Turnover (LCY) (corr_)]
     , RL.[Turnover Breakfast (LCY) (c_)]    = AP.[Turnover Breakfast (LCY) (corr_)]
     , RL.[Net Turnover (LCY) (corr_)]       = AP.[Net Turnover (LCY) (corr_)]
     , RL.[Amount (corr_)]                   = AP.[Amount (corr_)]
     , RL.[Turnover (corr_)]                 = AP.[Turnover (corr_)]
     , RL.[Net Turnover (corr_)]             = AP.[Net Turnover (corr_)]
     , RL.[Commission Type (corr_)]          = AP.[Commission Type (corr_)]
     , RL.[Commission Rate % (corr_)]        = AP.[Commission Rate % (corr_)]
     , RL.[Room Nights Post Corection]       = AP.[Room Nights (corr_)]
     , RL.[Is Net Rate Post Corection]       = AP.[Is Net Rate (corr_)]
     , RL.[Is No Show]                       = AP.[Is No Show]
     , RL.[Currency Faktor]                  = AP.[Currency Factor]
     , RL.[Currency Code]                    = AP.[Currency Code]
     , RL.[Currency Faktor (corr_)]          = AP.[Currency Factor (corr_)]
     , RL.[Currency Code (corr_)]            = AP.[Currency Code (corr_)]
  FROM [hotel_de$Rebate Line] RL
  JOIN @Updates          AP
    ON AP.[Reservation No_]      = RL.[Reservation No_]
   AND AP.[Reservation Part No_] = RL.[Reservation Part No_]
 WHERE AP.[Existing] = 1
   AND AP.Posted = 0
OPTION (MAXDOP 1)   

UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Rebate Line] PL 
  JOIN [hotel_de$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Rebate Line] PL 
  JOIN [HRS-CN$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Rebate Line] PL 
  JOIN [HRS-BR$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Rebate Line] PL 
  JOIN [TISCOVER$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Posted Rebate Line] PL 
  JOIN [hotel_de$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Posted Rebate Line] PL 
  JOIN [HRS-CN$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [hotel_de$Posted Rebate Line] PL 
  JOIN [TISCOVER$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
;WITH AP AS
(
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [hotel_de$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
)
UPDATE RL SET
       RL.[Amount]                  = AP.[Amount]
     , RL.[Turnover]                = AP.[Turnover]
     , RL.[Currency Code]           = AP.[CurrencyCode]
     , RL.[Currency Faktor]         = AP.[CurrencyFaktor]
     , RL.[Amount (corr_)]          = AP.[Amount_corr]
     , RL.[Turnover (corr_)]        = AP.[Turnover_corr]
     , RL.[Currency Code (corr_)]   = AP.[CurrencyCode_corr]
     , RL.[Currency Faktor (corr_)] = AP.[CurrencyFaktor_corr]
  FROM [hotel_de$Posted Rebate Line] RL
  JOIN AP 
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
   AND AP.[InvoiceNo]         = RL.[Invoice No_]
 WHERE RL.[Type] = 5
   AND RL.[Currency Code]=''
OPTION (MAXDOP 1)   
   
;WITH AP AS
(
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [hotel_de$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
)
UPDATE RL SET
       RL.[Amount]                  = AP.[Amount]
     , RL.[Turnover]                = AP.[Turnover]
     , RL.[Currency Code]           = AP.[CurrencyCode]
     , RL.[Currency Faktor]         = AP.[CurrencyFaktor]
     , RL.[Amount (corr_)]          = AP.[Amount_corr]
     , RL.[Turnover (corr_)]        = AP.[Turnover_corr]
     , RL.[Currency Code (corr_)]   = AP.[CurrencyCode_corr]
     , RL.[Currency Faktor (corr_)] = AP.[CurrencyFaktor_corr]
  FROM [hotel_de$Rebate Line] RL
  JOIN AP 
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
   AND AP.[InvoiceNo]         = RL.[Invoice No_]
 WHERE RL.[Type] = 5
   AND RL.[Currency Code]=''  
OPTION (MAXDOP 1)   
    
END

GO
