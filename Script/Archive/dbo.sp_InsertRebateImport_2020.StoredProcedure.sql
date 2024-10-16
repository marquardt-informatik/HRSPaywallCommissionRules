USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertRebateImport_2020]    Script Date: 10.04.2024 14:31:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 14.11.13
-- Description:	Übertragung der Bonuszeilen ohne Webservice
--
-- Version | Date     | Developer | Ticket   | Description      
-- --------+----------+-----------+----------+-----------------------------------------------------------------------------------------------------   
-- HRS001  | 08.04.19 | TMA       | ACS-1645 | einmal falsch zugeordnete Reservierungen in gebuchten Belegen dürfen im ungebuchten Beleg zugeordnet 
--         |          |           |          | werden, auch wenn eine Zuordnung nicht mehr besteht
-- HRS002  | 15.04.19 | TMA       | ACS-1645 | ausgelagert in separate SP
-- HRS003  | 09.12.19 | TMA       |          | für die Fälle, dass in der Kommissionsrechnung kein numerischer Schlüssel für das Land eingetragen wurde
/*
EXEC sp_InsertRebateImport_2019 ''
EXEC sp_InsertRebateImport_2020 '5164'
EXEC sp_InsertRebateImport_2020 '7268' -- TUI
EXEC sp_InsertRebateImport_2020 '55330' -- AVL
EXEC sp_InsertRebateImport_2020 '11347' -- Selectour Preference
TRUNCATE TABLE [HRS$Rebate Import]
DELETE FROM [HRS$Rebate Import] WHERE [Departure Date]<'2020-01-01'

--DELETE FROM [HRS$Rebate Import] WHERE [Error Text] <>''--[Rebate-to Vendor No_]='10482'
SELECT COUNT(*) FROM [HRS$Rebate Import] WITH (NOLOCK) WHERE [DatenOK] = 1 
SELECT COUNT(*) FROM [HRS$Rebate Import] WITH (NOLOCK) WHERE [Error Text] <>'' 
SELECT COUNT(*) FROM [HRS$Rebate Import] WITH (NOLOCK) WHERE [DatenOK] = 0 AND [Error Text] =''
--SELECT [Line No_], * FROM [HRS$Rebate Import]
--WHERE [Rebate-to Vendor No_]='10482'

  NOT [Process Number] IN (93330589,93768121,94167583,94401925,95008387,95262887,96022476,96719118,97017234,97085011,97650736,97691316,99122761,99377704,99508285,99628758,99702962,99703153,100021593,100065445,100121674,100178859,100323923,100769677,101821293,102237031,102446480,102471648,102673093,103050793,103638507,93860429,94512217,94658867,94972659,95271044,96678286,96732216,96840797,97394867,97590953,98297957,98870243,99108495,99129134,99245154,99371397,99378935,99702305,99921423,99986449,100073571,100087076,100296134,100322538,100638055,102442464,103050750,103309926,93314757,94667750,95269751,96365219,96556177,96732289,97138588,97214830,97548895,97739066,98328499,98643761,98887429,98939373,99080578,99702646,100244566,100269034,101354091,101354891,102795892,103367941,103775127,92557085,93658103,93658169,93658212,93962807,94667678,95190203,95190344,96556052,96678154,96906973,96908043,96937966,97400827,98298021,98309860,98643810,99106946,99186723,99280418,99378449,99822306,99905832,99951149,100189969,100940563,102335249,102972072,103224987,94632680,94634001,95190422,95190489,95372407,95372772,95703598,95716447,96365095,96556383,96862556,96990657,97377817,98288296,98348814,99098934,99120276,99334632,99334696,99448008,99496657,99762136,100197481,100290833,100482007,100684382,100940199,102252228,103050697,103346877,103395341,94401215,94667597,95248210,95832260,96288662,96411409,96622810,96806182,96852281,96943215,97148886,97210847,97485942,98654453,98854069,99049587,99163735,99386586,99598248,99644894,99909947,99949798,100021594,100106569,100106962,100171513,100235403,100403031,100478989,102581574,102689102,103226628,103310088,93657598,94105343,94770433,95089205,95190568,96022046,96022093,96365335,96555976,96622909,96703797,96768590,96876839,96916177,96937820,97119888,98297882,98536270,98539610,98938770,99157521,99186335,99332299,99336243,99550984,99891046,100077909,100083927,100110467,100243380,100333477,100382477,100891641,101018002,101354158,102397501,103160474,103160691,93962595,94444576,94512246,95003958,95010567,95247744,95372702,95378368,96229911,96365154,96610251,96732155,96768519,96871060,96873264,97138774,98285161,98753720,98879196,98939828,99066015,99182210,99186511,99334662,99363270,99508227,99822480,99905926,100257615,100638291,100768229,101019503,101801772,103050728,103160610)
  DELETE FROM [HRS$Rebate Import] WHERE NOT [Departure Date] BETWEEN '2020-01-01' AND '2018-12-31'
  SELECT COUNT(1) FROM [HRS$Rebate Import] WITH (NOLOCK) WHERE [Error Text]='' ORDER BY 1
  SELECT COUNT(DISTINCT [Rebate-to Vendor No_]) FROM [HRS$Rebate Import] WITH (NOLOCK) WHERE [Error Text]='' ORDER BY 1
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_InsertRebateImport_2020]
  @VendorNo varchar(20) = ''
AS
BEGIN

-- falsche Zuordnung löschen -- Anfang TMA 15.04.19
EXEC dbo.[sp_DeleteWrongRebateLines] @VendorNo
-- falsche Zuordnung löschen -- Ende   TMA 15.04.19

DECLARE @ReservationNo int-- = 170451410
DECLARE @Updates TABLE ([Reservation No_] int,[Reservation Part No_] int,[Process Number] int,[Posting Date] date,[Document Date] date,[Travelagency Code] varchar(10),[Travelagency No_] int,[Rebate Agreement No_] varchar(20),[Company Name] varchar(30),[Invoice No_] varchar(20),[Description] varchar(250),[Description 2] varchar(250),[Amount (LCY)] decimal(37,20),[Turnover (LCY)] decimal(37,20),[Turnover Breakfast (LCY)] decimal(37,20),[Net Turnover (LCY)] decimal(37,20),[Amount] decimal(37,20),[Turnover] decimal(37,20),[Net Turnover] decimal(37,20),[Commission Type] int,[Commission Rate %] decimal(37,20),[Room Nights] decimal(37,20),[Is Net Rate] tinyint,[Amount (LCY) (corr_)] decimal(37,20),[Turnover (LCY) (corr_)] decimal(37,20),[Turnover Breakfast (LCY) (corr_)] decimal(37,20),[Net Turnover (LCY) (corr_)] decimal(37,20),[Amount (corr_)] decimal(37,20),[Turnover (corr_)] decimal(37,20),[Net Turnover (corr_)] decimal(37,20),[Commission Type (corr_)] int,[Commission Rate % (corr_)] decimal(37,20),[Room Nights (corr_)] decimal(37,20),[Is Net Rate (corr_)] tinyint,[Is No Show] tinyint,[Reservation Date] date,[Arrival Date] date,[Departure Date] date,[Affiliate Partner No_] varchar(20),[Hotel No_] varchar(20),[Customer No_] varchar(20),[Country Code] varchar(20),[Chain] varchar(10),[Brand] varchar(10),[MuseID] varchar(20),[Top Bonus ID] varchar(20) ,[Loyality Rewards Account 1 No_] varchar(100),[Loyality Rewards Account 2 No_] varchar(100),[Reservation Source] int,[Booking User] varchar(120),[Booking Code] varchar(80),[Currency Factor] decimal(37,20),[Currency Code] varchar(10),[Currency Factor (corr_)] decimal(37,20),[Currency Code (corr_)] varchar(10),[K-Amount (LCY)] decimal(37,20),[K-Turnover (LCY)] decimal(37,20),[K-Amount (LCY) (corr_)] decimal(37,20),[K-Turnover (LCY) (corr_)] decimal(37,20),[K-Room Nights] decimal(37,20),[K-Room Nights (corr_)] decimal(37,20),[K-Net Turnover (LCY)] decimal(37,20),[K-Net Turnover (LCY) (corr_)] decimal(37,20),[K-Net Turnover] decimal(37,20),[K-Net Turnover (corr_)] decimal(37,20),[Eligible RevShare] tinyint,[Post Affiliate Partner No_] varchar(20),[Max Entry No_] int,[Handbooking] tinyint,[Rebate-to Vendor No_] varchar(20),[Interval] int,[Interval Start Date] date,[Interval End Date] date,[Correction Kennung] int,[Date Interval Coordination] date,[DatenOK] tinyint,[Error Text] varchar(250),[Posted] tinyint,[Existing] tinyint,UNIQUE NONCLUSTERED ([Reservation No_] ASC,[Reservation Part No_] ASC))

;WITH APV AS
(
  SELECT C.Name [Company Name], [Affiliate Partner No_], AH.[Enable retroactive correction], COUNT(1) CountAPV, AH.[No_] [Rebate Agreement No_], APV.[Vendor No_]
    FROM [Company] C, [HRS$Rebate Agreement Header] AH WITH (NOLOCK), [HRS$Affiliate Partner Vendor] APV  WITH (NOLOCK)
   WHERE C.Name IN ('HRS','HRS-CN','HRS-BR')
     AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_]
     AND (APV.[Vendor No_] = @VendorNo OR @VendorNo = '')
	 AND AH.[Active] = 1
     --AND AH.[Group contract Code] = 'DER'
GROUP BY C.Name, APV.[Affiliate Partner No_], AH.[Enable retroactive correction], AH.[No_], APV.[Vendor No_]
), APT AS
(
  SELECT C.Name [Company Name], APV.[Travelagency No_], AH.[Enable retroactive correction], COUNT(1) CountAPV, AH.[No_] [Rebate Agreement No_], APV.[Vendor No_]
    FROM [Company] C, [HRS$Rebate Agreement Header] AH WITH (NOLOCK), [HRS$Vendor Travelagency] APV  WITH (NOLOCK)
   WHERE C.Name IN ('HRS','HRS-CN','HRS-BR')
     AND AH.[Rebate-to Vendor No_] = APV.[Vendor No_]
     AND (APV.[Vendor No_] = @VendorNo OR @VendorNo = '')
	 AND AH.[Active] = 1
     --AND AH.[Group contract Code] = 'DER'
GROUP BY C.Name, APV.[Travelagency No_], AH.[Enable retroactive correction], AH.[No_], APV.[Vendor No_]
), _RL AS
(
  SELECT RL.[Reservation No_]
     ,RL.[Reservation Part No_]
	 ,RL.[Rebate Agreement No_]
     ,0 [Posted]
     ,SUM(RL.[Amount (LCY)])               [Amount (LCY)]
     ,SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
     ,SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
     ,SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
     ,SUM(RL.[Room Nights])                [Room Nights]
     ,SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
     ,SUM(RL.[Turnover])                   [Turnover]
     ,SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
     ,SUM(RL.[Net Turnover (LCY)])         [Net Turnover (LCY)]
     ,SUM(RL.[Net Turnover (LCY) (corr_)]) [Net Turnover (LCY) (corr_)]
     ,SUM(RL.[Net Turnover])         [Net Turnover]
     ,SUM(RL.[Net Turnover (corr_)]) [Net Turnover (corr_)]
    FROM [HRS$Rebate Line] RL
    JOIN APV
      ON APV.[Affiliate Partner No_] = RL.[Affiliate Partner No_]
   WHERE APV.[Company Name]             = 'HRS'
GROUP BY RL.[Reservation No_]
     ,RL.[Reservation Part No_]    
	 ,RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Reservation No_]
     ,RL.[Reservation Part No_]
	 ,RL.[Rebate Agreement No_]
     ,0 [Posted]
     ,SUM(RL.[Amount (LCY)])               [Amount (LCY)]
     ,SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
     ,SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
     ,SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
     ,SUM(RL.[Room Nights])                [Room Nights]
     ,SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
     ,SUM(RL.[Turnover])                   [Turnover]
     ,SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
     ,SUM(RL.[Net Turnover (LCY)])         [Net Turnover (LCY)]
     ,SUM(RL.[Net Turnover (LCY) (corr_)]) [Net Turnover (LCY) (corr_)]
     ,SUM(RL.[Net Turnover])         [Net Turnover]
     ,SUM(RL.[Net Turnover (corr_)]) [Net Turnover (corr_)]
    FROM [HRS$Rebate Line] RL
    JOIN APT
      ON APT.[Travelagency No_]      = RL.[Travelagency No_]
   WHERE APT.[Company Name]             = 'HRS'
GROUP BY RL.[Reservation No_]
     ,RL.[Reservation Part No_]    
	 ,RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Reservation No_]
     ,RL.[Reservation Part No_]
	 ,RL.[Rebate Agreement No_]
     ,1 [Posted]
     ,SUM(RL.[Amount (LCY)])               [Amount (LCY)]
     ,SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
     ,SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
     ,SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
     ,SUM(RL.[Room Nights])                [Room Nights]
     ,SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
     ,SUM(RL.[Turnover])                   [Turnover]
     ,SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
     ,SUM(RL.[Net Turnover (LCY)])         [Net Turnover (LCY)]
     ,SUM(RL.[Net Turnover (LCY) (corr_)]) [Net Turnover (LCY) (corr_)]
     ,SUM(RL.[Net Turnover])         [Net Turnover]
     ,SUM(RL.[Net Turnover (corr_)]) [Net Turnover (corr_)]
    FROM [HRS$Posted Rebate Line] RL
    JOIN APV
      ON APV.[Affiliate Partner No_] = RL.[Affiliate Partner No_]
   WHERE APV.[Company Name]             = 'HRS'
     AND RL.[Cancels] = 0
GROUP BY RL.[Reservation No_]
     ,RL.[Reservation Part No_]    
	 ,RL.[Rebate Agreement No_]
UNION
  SELECT RL.[Reservation No_]
     ,RL.[Reservation Part No_]
	 ,RL.[Rebate Agreement No_]
     ,1 [Posted]
     ,SUM(RL.[Amount (LCY)])               [Amount (LCY)]
     ,SUM(RL.[Turnover (LCY)])             [Turnover (LCY)]
     ,SUM(RL.[Amount (LCY) (corr_)])       [Amount (LCY) (corr_)]
     ,SUM(RL.[Turnover (LCY) (corr_)])     [Turnover (LCY) (corr_)]
     ,SUM(RL.[Room Nights])                [Room Nights]
     ,SUM(RL.[Room Nights Post Corection]) [Room Nights (corr_)]
     ,SUM(RL.[Turnover])                   [Turnover]
     ,SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
     ,SUM(RL.[Net Turnover (LCY)])         [Net Turnover (LCY)]
     ,SUM(RL.[Net Turnover (LCY) (corr_)]) [Net Turnover (LCY) (corr_)]
     ,SUM(RL.[Net Turnover])         [Net Turnover]
     ,SUM(RL.[Net Turnover (corr_)]) [Net Turnover (corr_)]
    FROM [HRS$Posted Rebate Line] RL
    JOIN APT
      ON APT.[Travelagency No_]      = RL.[Travelagency No_]
   WHERE APT.[Company Name]             = 'HRS'
     AND RL.[Cancels] = 0
GROUP BY RL.[Reservation No_]
     ,RL.[Reservation Part No_]    
	 ,RL.[Rebate Agreement No_]
), RL AS
(
  SELECT RL.[Reservation No_]
     ,RL.[Reservation Part No_]
	 ,RL.[Rebate Agreement No_]
     ,MAX(RL.[Posted])                 [Posted]
     ,SUM(RL.[Amount (LCY)])           [Amount (LCY)]
     ,SUM(RL.[Turnover (LCY)])         [Turnover (LCY)]
     ,SUM(RL.[Amount (LCY) (corr_)])   [Amount (LCY) (corr_)]
     ,SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]
     ,SUM(RL.[Room Nights])            [Room Nights]
     ,SUM(RL.[Room Nights (corr_)])    [Room Nights (corr_)]
     ,SUM(RL.[Turnover])                   [Turnover]
     ,SUM(RL.[Turnover (corr_)])           [Turnover (corr_)]
     ,SUM(RL.[Net Turnover (LCY)])         [Net Turnover (LCY)]
     ,SUM(RL.[Net Turnover (LCY) (corr_)]) [Net Turnover (LCY) (corr_)]
     ,SUM(RL.[Net Turnover])         [Net Turnover]
     ,SUM(RL.[Net Turnover (corr_)]) [Net Turnover (corr_)]
    FROM _RL RL
GROUP BY RL.[Reservation No_]
     ,RL.[Reservation Part No_]    
	 ,RL.[Rebate Agreement No_]
), _APV AS
(
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS'
    WHERE AP.[DepartureDate] BETWEEN '2020-01-01' AND '2020-12-31'
--	  AND AP.[ReservationSource]<>383
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS-CN'
    WHERE AP.[DepartureDate] BETWEEN '2020-01-01' AND '2020-12-31'
--	  AND AP.[ReservationSource]<>383
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APV L
       ON AP.[AffiliatePartnerNo]      = L.[Affiliate Partner No_]
      AND L.[Company Name]             = 'HRS-BR'
    WHERE AP.[DepartureDate] BETWEEN '2020-01-01' AND '2020-12-31'
--	  AND AP.[ReservationSource]<>383
), _APT AS
(
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM [HRS$Affiliate Postings]  AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'HRS'
    WHERE AP.[DepartureDate] BETWEEN '2020-01-01' AND '2020-12-31'
--	  AND AP.[ReservationSource]<>383
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'HRS-CN'
    WHERE AP.[DepartureDate] BETWEEN '2020-01-01' AND '2020-12-31'
--	  AND AP.[ReservationSource]<>383
UNION      
   SELECT AP.*, L.[Rebate Agreement No_], L.[Company Name]
     FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
     JOIN APT L
       ON AP.[Travelagency No_] = L.[Travelagency No_]
      AND L.[Company Name]             = 'HRS-BR'
    WHERE AP.[DepartureDate] BETWEEN '2020-01-01' AND '2020-12-31'
--	  AND AP.[ReservationSource]<>383
), _AP AS
(
   SELECT * FROM _APV
UNION
   SELECT * FROM _APT   
), AP AS
(
  SELECT AP.ReservationNo                         [Reservation No_]
     ,AP.ReservationPartNo                     [Reservation Part No_]
     ,MAX(COALESCE(AP.IsNoShow,0))             [Is No Show]
     ,MAX(COALESCE(AP.ProcessNumber,0))        [Process Number]
     ,MAX([Company Name])                      [Company Name]
     ,MAX(AP.PostingDate)                      [Posting Date]
     ,MAX(AP.DocumentDate)                     [Document Date]
     ,MAX(COALESCE([Travelagency Code],''))    [Travelagency Code]
     ,MAX(COALESCE([Travelagency No_],0))      [Travelagency No_]
     ,MIN(AP.[Rebate Agreement No_])           [Rebate Agreement No_]
     ,MIN(AP.InvoiceNo)                        [Invoice No_]
     ,MAX(COALESCE([Description],''))          [Description]
     ,MAX(COALESCE([Description2],''))         [Description 2]
     ,SUM(CASE WHEN [TAF Amount (LCY)]=0 THEN AP.[Amount_LCY] ELSE AP.[Amount_LCY]-AP.[TAF Amount (LCY)] END) [Amount (LCY)]
     ,SUM(AP.Turnover_LCY)                     [Turnover (LCY)]
     ,SUM(AP.Amount)                           [Amount]
     ,SUM(AP.Turnover)                         [Turnover]
     ,SUM(CASE WHEN [TAF Amount (LCY) (corr_)]=0 THEN AP.[Amount_LCY_corr] ELSE AP.[Amount_LCY_corr]-AP.[TAF Amount (LCY) (corr_)] END) [Amount (LCY) (corr_)]
     ,SUM(AP.Turnover_LCY_corr)                [Turnover (LCY) (corr_)]
     ,SUM(AP.Amount_corr)                      [Amount (corr_)]
     ,SUM(AP.Turnover_corr)                    [Turnover (corr_)]
     ,SUM(AP.RoomNights)                       [Room Nights]
     ,SUM(AP.RoomNights_corr)                  [Room Nights (corr_)]
     ,MAX(COALESCE(AP.IsNetRate,0))            [Is Net Rate]
     ,MAX(COALESCE(AP.IsNetRate_corr,0))       [Is Net Rate (corr_)]
     ,MAX(
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
     ,MAX(AP.CommissionRateProz)               [Commission Rate %]
     ,MAX(
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
     ,MAX(AP.CommissionRateProz_corr)          [Commission Rate % (corr_)]
     ,MAX(AP.ReservationDate)                  [Reservation Date]
     ,MAX(AP.ArivalDate)                       [Arrival Date]
     ,MAX(AP.DepartureDate)                    [Departure Date]
     ,MAX(AP.AffiliatePartnerNo)               [Affiliate Partner No_]
     ,MAX(AP.HotelNo)                          [Hotel No_]
     ,MAX(CASE WHEN ISNUMERIC(COALESCE(AP.CountryCode,''))=0 THEN '' ELSE AP.CountryCode END) [Country Code] -- 09.12.19 HRS003 TMA für die Fälle, dass in der Kommissionsrechnung kein numerischer Schlüssel für das Land eingetragen wurde 
     ,MAX(COALESCE(AP.Chain,''))               [Chain]
     ,MAX(COALESCE(AP.Brand,''))               [Brand]
     ,MAX(COALESCE(AP.MuseID,''))              [MuseID]
     ,MAX(COALESCE(AP.TopBonusID,''))          [Top Bonus ID]
     ,MAX(COALESCE(AP.AffiliateReference1,'')) [Loyality Rewards Account 1 No_]
     ,MAX(COALESCE(AP.AffiliateReference2,'')) [Loyality Rewards Account 2 No_]
     ,MAX(COALESCE(AP.ReservationSource,0))    [Reservation Source]
     ,MAX(COALESCE(AP.Orderer,''))             [Booking User]
     ,MAX(COALESCE(AP.BookingCode,''))         [Booking Code]
     ,SUM(AP.Turnover_Breakfast_LCY)           [Turnover Breakfast (LCY)]
     ,SUM(AP.Turnover_Breakfast_LCY_corr)      [Turnover Breakfast (LCY) (corr_)]
     ,MAX(AP.CurrencyFaktor)                   [Currency Factor]
     ,MAX(AP.CurrencyFaktor_corr)              [Currency Factor (corr_)]
     ,MAX(AP.CurrencyCode)                     [Currency Code]
     ,MAX(AP.CurrencyCode_corr)                [Currency Code (corr_)]
    FROM _AP AP
GROUP BY AP.ReservationNo
     ,AP.ReservationPartNo    
), _RAH AS
(
   SELECT [No_]
   ,[Rebate-to Vendor No_]
      ,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END [Valid from]
      ,CASE WHEN [Valid to]   = '1753-01-01' THEN '2099-12-31' ELSE [Valid to] END [Valid to]
   ,[Interval]
      ,CASE WHEN [Fiscal Year Start (Month)] = 0 THEN 1 ELSE [Fiscal Year Start (Month)] END [Fiscal Year Start (Month)]
      ,CASE WHEN [Fiscal Year End (Month)] = 0 THEN 12 ELSE [Fiscal Year End (Month)] END [Fiscal Year End (Month)]
   ,[Enable retroactive correction]
   ,[Active]
      ,CASE [Interval] 
            WHEN 0 THEN DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END)
            WHEN 1 THEN DATEADD(mm,-DATEPART(mm,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END)%3+1, DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END))
            WHEN 2 THEN DATEADD(mm,-DATEPART(mm,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END)%6+1, DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END))
            WHEN 3 THEN DATEADD(mm,-DATEPART(mm,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END)%12+1, DATEADD(dd,-DATEPART(dd,CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END), CASE WHEN [Valid from] = '1753-01-01' THEN '2020-01-01' ELSE [Valid from] END))
          END [Max_ Interval End Date]
     FROM [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    WHERE [Is Template] = 0
), URH AS
(
--  SELECT RH.[Rebate Agreement No_]
--     ,MAX(RH.[Interval End Date]) [Max_ Interval End Date]
--    FROM [HRS$Rebate Header] RH WITH (NOLOCK)
--GROUP BY RH.[Rebate Agreement No_]
--UNION
  SELECT RH.[Rebate Agreement No_]
     ,MAX(RH.[Interval End Date]) [Max_ Interval End Date]
    FROM [HRS$Posted Rebate Header] RH WITH (NOLOCK)
   WHERE RH.[Cancels] = 0
GROUP BY RH.[Rebate Agreement No_]
), RH AS
(
  SELECT [Rebate Agreement No_]
     ,MAX([Max_ Interval End Date]) [Max_ Interval End Date]
    FROM URH
GROUP BY [Rebate Agreement No_]
), RAH AS
(
   SELECT AH.[No_] [Rebate Agreement No_]
      ,AH.[Rebate-to Vendor No_]
      ,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]) [Max_ Interval End Date]
      ,CASE WHEN MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])) = [Fiscal Year End (Month)] THEN 
            DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))
          ELSE
            DATEADD(mm,-MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))+[Fiscal Year Start (Month)]-1, DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])))
          END [Fiscal Year Start]
      ,DATEADD(dd, -1, DATEADD(mm,12,CASE WHEN MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])) = [Fiscal Year End (Month)] THEN 
            DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))
          ELSE
            DATEADD(mm,-MONTH(COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))+[Fiscal Year Start (Month)]-1, DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])))
          END)) [Fiscal Year End]
      ,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date])) [Next Interval Start Date]
      ,CASE [Interval]
            WHEN 0 THEN DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
            WHEN 1 THEN DATEADD(dd,-1,DATEADD(mm,3,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
            WHEN 2 THEN DATEADD(dd,-1,DATEADD(mm,6,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
            WHEN 3 THEN DATEADD(dd,-1,DATEADD(mm,12,DATEADD(dd,1,COALESCE(RH.[Max_ Interval End Date], AH.[Max_ Interval End Date]))))
          END [Next Interval End Date]
   ,[Valid from]
   ,[Valid to]
   ,[Interval]
   ,[Enable retroactive correction]
   ,[Active]
     FROM _RAH AH
LEFT JOIN RH ON AH.[No_] = RH.[Rebate Agreement No_]
)
  INSERT INTO @Updates
   SELECT AP.[Reservation No_]
      ,AP.[Reservation Part No_]
      ,AP.[Process Number]
      ,AP.[Posting Date]
      ,AP.[Document Date]
      ,AP.[Travelagency Code]
      ,AP.[Travelagency No_]
      ,AP.[Rebate Agreement No_]
      ,AP.[Company Name]
      ,AP.[Invoice No_]
      ,AP.[Description]
      ,AP.[Description 2]
      ,AP.[Amount (LCY)]
      ,AP.[Turnover (LCY)]
      ,AP.[Turnover Breakfast (LCY)]
      ,AP.[Turnover (LCY)] * COALESCE(100./(100+FT.[VAT in %]),1)
      ,AP.[Amount]
      ,AP.[Turnover]
      ,AP.[Turnover] * COALESCE(100./(100+FT.[VAT in %]),1)
      ,AP.[Commission Type]
      ,AP.[Commission Rate %]
      ,AP.[Room Nights]
      ,AP.[Is Net Rate]
      ,AP.[Amount (LCY) (corr_)]
      ,AP.[Turnover (LCY) (corr_)]
      ,AP.[Turnover Breakfast (LCY) (corr_)]
      ,AP.[Turnover (LCY) (corr_)] * COALESCE(100./(100+FT.[VAT in %]),1)
      ,AP.[Amount (corr_)]
      ,AP.[Turnover (corr_)]
      ,AP.[Turnover (corr_)] * COALESCE(100./(100+FT.[VAT in %]),1)
      ,AP.[Commission Type (corr_)]
      ,AP.[Commission Rate % (corr_)]
      ,AP.[Room Nights (corr_)]
      ,AP.[Is Net Rate (corr_)]
      ,AP.[Is No Show]
      ,AP.[Reservation Date]
      ,AP.[Arrival Date]
      ,AP.[Departure Date]
      ,AP.[Affiliate Partner No_]
      ,AP.[Hotel No_]
      ,AP.[Hotel No_]
      ,AP.[Country Code]
      ,AP.[Chain]
      ,AP.[Brand]
      ,AP.[MuseID]
      ,AP.[Top Bonus ID]
      ,AP.[Loyality Rewards Account 1 No_]
      ,AP.[Loyality Rewards Account 2 No_]
      ,AP.[Reservation Source]
      ,AP.[Booking User]
      ,AP.[Booking Code]
      ,AP.[Currency Factor]
      ,AP.[Currency Code]
      ,AP.[Currency Factor (corr_)]
      ,AP.[Currency Code (corr_)]
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Amount (LCY)] IS NULL           THEN 0 ELSE AP.[Amount (LCY)]           - COALESCE(RL.[Amount (LCY)],0)           END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY)] IS NULL         THEN 0 ELSE AP.[Turnover (LCY)]         - COALESCE(RL.[Turnover (LCY)],0)         END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Amount (LCY) (corr_)] IS NULL   THEN 0 ELSE AP.[Amount (LCY) (corr_)]   - COALESCE(RL.[Amount (LCY) (corr_)],0)   END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY) (corr_)] IS NULL THEN 0 ELSE AP.[Turnover (LCY) (corr_)] - COALESCE(RL.[Turnover (LCY) (corr_)],0) END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Room Nights] IS NULL            THEN 0 ELSE AP.[Room Nights]            - COALESCE(RL.[Room Nights],0)            END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Room Nights (corr_)] IS NULL    THEN 0 ELSE AP.[Room Nights (corr_)]    - COALESCE(RL.[Room Nights (corr_)],0)    END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY)] IS NULL         THEN 0 ELSE AP.[Turnover (LCY)]         * COALESCE(100./(100+FT.[VAT in %]),1) - COALESCE(RL.[Net Turnover (LCY)],0)         END 
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (LCY) (corr_)] IS NULL THEN 0 ELSE AP.[Turnover (LCY) (corr_)] * COALESCE(100./(100+FT.[VAT in %]),1) - COALESCE(RL.[Net Turnover (LCY) (corr_)],0) END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover] IS NULL               THEN 0 ELSE AP.[Turnover]               * COALESCE(100./(100+FT.[VAT in %]),1) - COALESCE(RL.[Net Turnover],0)               END
      ,CASE WHEN COALESCE(RL.[Posted],0) = 0 OR RL.[Turnover (corr_)] IS NULL       THEN 0 ELSE AP.[Turnover (corr_)]       * COALESCE(100./(100+FT.[VAT in %]),1) - COALESCE(RL.[Net Turnover (corr_)],0)       END
      ,0 [Eligible RevShare]
      ,'' [Post Affiliate Partner No_]
      ,0 [Max Entry No_]
      ,0 [Handbooking]
      ,RAH.[Rebate-to Vendor No_]
      ,RAH.[Interval]
      ,RAH.[Next Interval Start Date]
      ,RAH.[Next Interval End Date]
      ,CASE WHEN RL.[Amount (LCY)] IS NULL THEN 0 ELSE 1 END
      ,RAH.[Next Interval Start Date]
      ,0 -- [DatenOK]
      ,''
      ,COALESCE(RL.[Posted],0)
      ,CASE WHEN RL.[Posted] IS NULL THEN 0 ELSE 1 END
     FROM AP
LEFT JOIN RL
       ON RL.[Reservation No_]          = AP.[Reservation No_]
      AND RL.[Reservation Part No_]     = AP.[Reservation Part No_]
	  AND RL.[Rebate Agreement No_]     = AP.[Rebate Agreement No_]    
     JOIN RAH
       ON RAH.[Rebate Agreement No_]    = AP.[Rebate Agreement No_]
LEFT JOIN [HRS$Foreign Tax] FT WITH (NOLOCK)
       ON AP.[Country Code] = CAST(FT.Country AS varchar(20))
    WHERE (
          AP.[Amount (LCY)]            <> COALESCE(RL.[Amount (LCY)],0)
       OR AP.[Turnover (LCY)]          <> COALESCE(RL.[Turnover (LCY)],0)
       OR AP.[Amount (LCY) (corr_)]    <> COALESCE(RL.[Amount (LCY) (corr_)],0)
       OR AP.[Turnover (LCY) (corr_)]  <> COALESCE(RL.[Turnover (LCY) (corr_)],0)
       OR AP.[Turnover (LCY)] * COALESCE(100./(100+FT.[VAT in %]),1)      <> COALESCE(RL.[Net Turnover (LCY)],0)
       OR AP.[Turnover (LCY) (corr_)] * COALESCE(100./(100+FT.[VAT in %]),1)  <> COALESCE(RL.[Net Turnover (LCY) (corr_)],0)
	   OR 1=1
          )
      AND AP.[Departure Date] >= DATEADD(yy,-1,RAH.[Fiscal Year Start])
      AND AP.[Departure Date]  >='2020-01-01' 
	  --AND NOT AP.[Affiliate Partner No_] IN (SELECT [Affiliate Partner No_] FROM [hotel_de$Affiliate Partner Vendor] WITH (NOLOCK))
      --AND AP.[Reservation No_]=@ReservationNo
--AND AP.[Reservation No_] IN (194591749,194591750,194591751,195306900,195653849,195900710,195905436,195906485,195908939,195921663,196092083,196092084,196092086,196103094,196141000,196206535,196206647,196208077,196249325,196518755,196555384,196576732,196662845,196662846,196689756,196710570,196713623,196771596,196771597,196827872,196869001,196871154,196878535,196912017,196950452,196950453,196954990,196986880,196987683,197030367,197049168,197066446,197066447,197070915,197099049,197099872,197104662,197114953,197140030,197145907,197192687,197222926,197234153,197290966,197291581,197294062,197317822,197323978,197364685,197368059,197374856,197378205,197378431,197379132,197380035,197381029,197415808,197415809,197453669,197454694,197457473,197460160,197518030,197520811,197551815,197591320,197591321,197599899,197623734,197624483,197727769,197740245,197741878,197757111,197762034,197763530,197768674,197771573,197798548,197802168,197805679,197830691,197846455,197846456,197904192,197927167,197970914,197976578,197979014,197994294,198021834,198038090,198038091,198038092,198038093,198038094,198038095,198038096,198062992,198071136,198171520,198205043,198218189,198218673,198218928,198270508,198271146,198310502,198310503,198310504,198319416,198343197,198343837,198353104,198360784,198373655,198396019,198431037,198451674,198451675,198455940,198462586,198464033,198477854,198477855,198478988,198478989,198497246,198498498,198504714,198519140,198519812,198533514,198535575,198535989,198536558,198536978,198553050,198614544,198624015,198626660,198634232,198650602,198651726,198651727,198651728,198652536,198652876,198652992,198659035,198662959,198662960,198710121,198725951,198744301,198787667,198800611,198800612,198805227,198812922,198814929,198868160,198868752,198871295,198876417,198892954,198902645,198906855,198908598,198913641,198915138,198915814,198938707,198939025,198940393,198940671,198948438,198948937,198952002,198952244,198961443,198961444,198961445,198968939,198980611,199071289,199071650,199072300,199072301,199072302,199096904,199101419,199102151,199136397,199145158,199148211,199150049,199163659,199176212,199176709,199180816,199203981,199212352,199228230,199231700,199231708,199231709,199233083,199239489,199249360,199258989,199284048,199284052,199286600,199302897,199321710,199326912,199334971,199334972,199353414,199353415,199398773,199402486,199424715,199424818,199486441,199486442,199486469,199493958,199517034,199540072,199583164,199597926,199615593,199620035,199620036,199678979,199679398,199689421,199704076,199735934,199739342,199746415,199751635,199765738,199823073,199823074,199823075,199823076,199827512,199829506,199839040,199840544,199853828,199853829,199962904,199971480,199976720,200001670,200045070,200047611,200047915,200047916,200047917,200050550,200060456,200061147,200062597,200116866,200151998,200152351,200166708,200202817,200202992,200209041,200223053,200233379,200245197,200250492,200250493,200294588,200294589,200294590,200336120,200416081,200416082,200416083,200425881,200450839,200451295,200451296,200451297,200455590,200455592,200456422,200462645,200469148,200503039,200503119,200503175,200503204,200551113,200551114,200552704,200552850,200553127,200599828,200605353,200606981,200643381,200649233,200649629,200680354,200692154,200693868,200699072,200709953,200714046,200723712,200770192,200786777,200898003,200898452,200917600,200917601,200917602,200942501,200981147,200990896,200991511,200992010,200992497,201034277,201034278,201034279,201034280,201045571,201045572,201073425,201073752,201117050,201147356,201183436,201189266,201196183,201219028,201219040,201229942,201247839,201263202,201264276,201264277,201268302,201275526,201281928,201281929,201363552,201372727,201390197,201390198,201390199,201401397,201409010,201417243,201472993,201477540,201486603,201496079,201513223,201549687,201552721,201625751,201636037,201636118,201644366,201644368,201645578,201645579,201645580,201672882,201739216,201746633)
--SELECT * FROM @Updates
      
INSERT INTO [HRS$Rebate Import]([Reservation No_]
,[Reservation Part No_]
,[Process Number]
,[Posting Date]
,[Document Date]
,[Travelagency No_]
,[Rebate Agreement No_]
,[Company Name]
,[Invoice No_]
,[Description]
,[Description 2]
,[Amount (LCY)]
,[Turnover (LCY)]
,[Turnover Breakfast (LCY)]
,[Net Turnover (LCY)]
,[Amount]
,[Turnover]
,[Net Turnover]
,[Commission Type]
,[Commission Rate %]
,[Room Nights]
,[Is Net Rate]
,[Amount (LCY) (corr_)]
,[Turnover (LCY) (corr_)]
,[Turnover Breakfast (LCY) (c_)]
,[Net Turnover (LCY) (corr_)]
,[Amount (corr_)]
,[Turnover (corr_)]
,[Net Turnover (corr_)]
,[Commission Type (corr_)]
,[Commission Rate % (corr_)]
,[Room Nights Post Corection]
,[Is Net Rate Post Corection]
,[Is No Show]
,[Reservation Date]
,[Arival Date]
,[Departure Date]
,[Affiliate Partner No_]
,[Hotel No_]
,[Customer No_]
,[Country Code]
,[Chain]
,[Brand]
,[MuseID]
,[Top Bonus ID]
,[Loyality Rewards Account 1 No_]
,[Loyality Rewards Account 2 No_]
,[Reservation Source]
,[Booking User]
,[Booking Code]
,[Currency Faktor]
,[Currency Code]
,[Currency Faktor (corr_)]
,[Currency Code (corr_)]
,[K-Amount (LCY)]
,[K-Turnover (LCY)]
,[K-Amount (LCY) (corr_)]
,[K-Turnover (LCY) (corr_)]
,[K-Room Nights]
,[K-Room Nights Post Corection]
,[K-Net Turnover (LCY)]
,[K-Net Turnover (LCY) (corr_)]
,[K-Net Turnover]
,[K-Net Turnover (corr_)]
,[Eligible RevShare]
,[Post Affiliate Partner No_]
,[Max Entry No_]
,[Handbooking]
,[Rebate-to Vendor No_]
,[Interval]
,[Interval Start Date]
,[Interval End Date]
,[Correction Kennung]
,[Date Interval Coordination]
,[DatenOK]
,[Error Text]
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
      , [DatenOK]
      , [Error Text]
  FROM @Updates UP
 WHERE ([Existing] = 0 OR Posted = 1)
   AND [Departure Date] BETWEEN '2020-01-01' AND '2020-12-31'
--   AND [Process Number] IN (65447351,65317707,65917505,65950508,70467138)
OPTION (MAXDOP 1)  

SELECT * FROM  [HRS$Rebate Import]
    
UPDATE RL SET
       RL.[Amount (LCY)]                     = AP.[Amount (LCY)]
   ,RL.[Turnover (LCY)]                   = AP.[Turnover (LCY)]
   ,RL.[Turnover Breakfast (LCY)]         = AP.[Turnover Breakfast (LCY)]
   ,RL.[Net Turnover (LCY)]               = AP.[Net Turnover (LCY)]
   ,RL.[Amount]                           = AP.[Amount]
   ,RL.[Turnover]                         = AP.[Turnover]
   ,RL.[Net Turnover]                     = AP.[Net Turnover]
   ,RL.[Commission Type]                  = AP.[Commission Type]
   ,RL.[Commission Rate %]                = AP.[Commission Rate %]
   ,RL.[Room Nights]                      = AP.[Room Nights]
   ,RL.[Is Net Rate]                      = AP.[Is Net Rate]
   ,RL.[Amount (LCY) (corr_)]             = AP.[Amount (LCY) (corr_)]
   ,RL.[Turnover (LCY) (corr_)]           = AP.[Turnover (LCY) (corr_)]
   ,RL.[Turnover Breakfast (LCY) (c_)]    = AP.[Turnover Breakfast (LCY) (corr_)]
   ,RL.[Net Turnover (LCY) (corr_)]       = AP.[Net Turnover (LCY) (corr_)]
   ,RL.[Amount (corr_)]                   = AP.[Amount (corr_)]
   ,RL.[Turnover (corr_)]                 = AP.[Turnover (corr_)]
   ,RL.[Net Turnover (corr_)]             = AP.[Net Turnover (corr_)]
   ,RL.[Commission Type (corr_)]          = AP.[Commission Type (corr_)]
   ,RL.[Commission Rate % (corr_)]        = AP.[Commission Rate % (corr_)]
   ,RL.[Room Nights Post Corection]       = AP.[Room Nights (corr_)]
   ,RL.[Is Net Rate Post Corection]       = AP.[Is Net Rate (corr_)]
   ,RL.[Is No Show]                       = AP.[Is No Show]
   ,RL.[Currency Faktor]                  = AP.[Currency Factor]
   ,RL.[Currency Code]                    = AP.[Currency Code]
   ,RL.[Currency Faktor (corr_)]          = AP.[Currency Factor (corr_)]
   ,RL.[Currency Code (corr_)]            = AP.[Currency Code (corr_)]
  FROM [HRS$Rebate Line] RL
  JOIN @Updates          AP
    ON AP.[Reservation No_]      = RL.[Reservation No_]
   AND AP.[Reservation Part No_] = RL.[Reservation Part No_]
 WHERE AP.[Existing] = 1
   AND AP.Posted = 0
OPTION (MAXDOP 1)   

UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Rebate Line] PL 
  JOIN [HRS$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Rebate Line] PL 
  JOIN [HRS-CN$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Rebate Line] PL 
  JOIN [HRS-BR$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Rebate Line] PL 
  JOIN [TISCOVER$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Rebate Line] PL 
  JOIN [Partner$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Posted Rebate Line] PL 
  JOIN [HRS$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Posted Rebate Line] PL 
  JOIN [HRS-CN$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Posted Rebate Line] PL 
  JOIN [TISCOVER$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   

UPDATE PL SET PL.[Arival Date] = AP.ArivalDate, PL.[Reservation Date] = AP.ReservationDate
  FROM [HRS$Posted Rebate Line] PL 
  JOIN [Partner$Affiliate Postings] AP
    ON AP.[ReservationNo] = PL.[Reservation No_]
   AND AP.ReservationPartNo = PL.[Reservation Part No_]
 WHERE PL.[Arival Date] = '1753-01-01 00:00:00.000' AND PL.Type = 5
OPTION (MAXDOP 1)   
 
;WITH AP AS
(
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [Partner$Affiliate Postings] AP WITH (NOLOCK)
)
UPDATE RL SET
       RL.[Amount]                  = AP.[Amount]
   ,RL.[Turnover]                = AP.[Turnover]
   ,RL.[Currency Code]           = AP.[CurrencyCode]
   ,RL.[Currency Faktor]         = AP.[CurrencyFaktor]
   ,RL.[Amount (corr_)]          = AP.[Amount_corr]
   ,RL.[Turnover (corr_)]        = AP.[Turnover_corr]
   ,RL.[Currency Code (corr_)]   = AP.[CurrencyCode_corr]
   ,RL.[Currency Faktor (corr_)] = AP.[CurrencyFaktor_corr]
  FROM [HRS$Posted Rebate Line] RL
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
    FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [Partner$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
UNION    
  SELECT [ReservationNo], [ReservationPartNo], [InvoiceNo], [Amount], [Turnover], [Amount_corr], [Turnover_corr], [CurrencyFaktor], [CurrencyCode], [CurrencyFaktor_corr], [CurrencyCode_corr]
    FROM [TISCOVER$Affiliate Postings] AP WITH (NOLOCK)
)
UPDATE RL SET
       RL.[Amount]                  = AP.[Amount]
   ,RL.[Turnover]                = AP.[Turnover]
   ,RL.[Currency Code]           = AP.[CurrencyCode]
   ,RL.[Currency Faktor]         = AP.[CurrencyFaktor]
   ,RL.[Amount (corr_)]          = AP.[Amount_corr]
   ,RL.[Turnover (corr_)]        = AP.[Turnover_corr]
   ,RL.[Currency Code (corr_)]   = AP.[CurrencyCode_corr]
   ,RL.[Currency Faktor (corr_)] = AP.[CurrencyFaktor_corr]
  FROM [HRS$Rebate Line] RL
  JOIN AP 
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
   AND AP.[InvoiceNo]         = RL.[Invoice No_]
 WHERE RL.[Type] = 5
   AND RL.[Currency Code]=''  
OPTION (MAXDOP 1) 

END

GO
