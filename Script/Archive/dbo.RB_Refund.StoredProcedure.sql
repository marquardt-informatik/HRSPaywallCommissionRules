USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[RB_Refund]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[RB_Refund] AS
BEGIN
DECLARE @RecreateRB tinyint=0
      , @RecreateAP tinyint=0

IF @RecreateRB=1
BEGIN
  IF OBJECT_ID('tempdb..#RB') IS NOT NULL 
    DROP TABLE #RB
END

IF @RecreateAP=1
BEGIN
  IF OBJECT_ID('tempdb..#AP') IS NOT NULL 
    DROP TABLE #AP
END

IF OBJECT_ID('tempdb..#RB') IS NULL
BEGIN
  CREATE TABLE #RB(
      [Hotel No_] int primary key
	, [Apply Line Amount Diff (LCY)] decimal(38,20)
	, [Refund Line Amount Diff (LCY)] decimal(38,20)
	, [Line Amount Diff (LCY)] decimal(38,20)
	, [MICE] decimal(38,20)
	, [CustCenter / Private Fit] decimal(38,20)
	, [CI] decimal(38,20)
	, [CCR] decimal(38,20)
	, [HOTEL.DE] decimal(38,20)
	, [TISCOVER] decimal(38,20)
	, [TMC] decimal(38,20)
	, [Deals] decimal(38,20)
	, [Min_ Posting Date] date
	, [Max_ Posting Date] date
	)

	;WITH RBH AS
	(
	  SELECT [Hotel No_]
		   , MAX(CASE WHEN Action='apply' THEN 1 ELSE 0 END) [apply]
		   , MAX(CASE WHEN Action='Refund' THEN 1 ELSE 0 END) [Refund]
		   , MAX(CASE WHEN NOT Action IN ('Refund','apply') THEN 1 ELSE 0 END) [other]
		FROM DynNavHRS.dbo.AgencyLineRB RB WITH (NOLOCK)
	   WHERE Action IN ('Refund','apply') AND Source IN ('MICE','CustCenter / Private Fit', 'CI', 'CCR', 'HOTEL.DE','TISCOVER', 'TMC', 'Deals')
	GROUP BY [Hotel No_]
	  HAVING SUM(RB.[Line Amount Diff (LCY)])<0
	), RB_PAYBACK AS
	(
	  SELECT RB.[Hotel No_]
		   , SUM(CASE WHEN [apply]=1 AND [Refund] = 0 THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [Apply Line Amount Diff (LCY)]
		   , SUM(CASE WHEN [apply]=1 AND [Refund] = 0 THEN 0 ELSE RB.[Line Amount Diff (LCY)] END) [Refund Line Amount Diff (LCY)]
		   , SUM(RB.[Line Amount Diff (LCY)]) [Line Amount Diff (LCY)]
		   , SUM(CASE WHEN RB.[Source] = 'MICE'                     THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [MICE]
		   , SUM(CASE WHEN RB.[Source] = 'CustCenter / Private Fit' THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [CustCenter / Private Fit]
		   , SUM(CASE WHEN RB.[Source] = 'CI'                       THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [CI]
		   , SUM(CASE WHEN RB.[Source] = 'CCR'                      THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [CCR]
		   , SUM(CASE WHEN RB.[Source] = 'HOTEL.DE'                 THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [HOTEL.DE]
		   , SUM(CASE WHEN RB.[Source] = 'TISCOVER'                 THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [TISCOVER]
		   , SUM(CASE WHEN RB.[Source] = 'TMC'                      THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [TMC]
		   , SUM(CASE WHEN RB.[Source] = 'Deals'                    THEN RB.[Line Amount Diff (LCY)] ELSE 0 END) [Deals]
		FROM DynNavHRS.dbo.AgencyLineRB RB WITH (NOLOCK)
		JOIN RBH
		  ON RBH.[Hotel No_] = RB.[Hotel No_]
	   WHERE Action IN ('Refund','apply') AND Source IN ('MICE','CustCenter / Private Fit', 'CI', 'CCR', 'HOTEL.DE','TISCOVER', 'TMC', 'Deals')
	GROUP BY RB.[Hotel No_]
	), _CL AS
	(
	  SELECT CL.[Customer No_], MIN([Posting Date]) [Min_ Posting Date], MAX([Posting Date]) [Max_ Posting Date] FROM DynNavHRS.dbo.[HRS$Cust_ Ledger Entry] CL WITH (NOLOCK) WHERE CL.[Document Type] = 2 GROUP BY CL.[Customer No_] UNION 
	  SELECT CL.[Customer No_], MIN([Posting Date]) [Min_ Posting Date], MAX([Posting Date]) [Max_ Posting Date] FROM DynNavHRS.dbo.[HRS-CN$Cust_ Ledger Entry] CL WITH (NOLOCK) WHERE CL.[Document Type] = 2 GROUP BY CL.[Customer No_] UNION 
	  SELECT CL.[Customer No_], MIN([Posting Date]) [Min_ Posting Date], MAX([Posting Date]) [Max_ Posting Date] FROM DynNavHRS.dbo.[HRS-BR$Cust_ Ledger Entry] CL WITH (NOLOCK) WHERE CL.[Document Type] = 2 GROUP BY CL.[Customer No_]
	), CL AS
	(
	  SELECT CL.[Customer No_] [Hotel No_]
		   , MIN([Min_ Posting Date]) [Min_ Posting Date]
		   , MAX([Max_ Posting Date]) [Max_ Posting Date]
		FROM _CL CL WITH (NOLOCK)
	GROUP BY CL.[Customer No_]
	)
	  INSERT INTO #RB ([Hotel No_], [Apply Line Amount Diff (LCY)], [Refund Line Amount Diff (LCY)], [Line Amount Diff (LCY)], [MICE], [CustCenter / Private Fit], [CI], [CCR], [HOTEL.DE], [TISCOVER], [TMC], [Deals], [Min_ Posting Date], [Max_ Posting Date])
	  SELECT PB.[Hotel No_]
	       , PB.[Apply Line Amount Diff (LCY)]
	       , PB.[Refund Line Amount Diff (LCY)]
	       , PB.[Line Amount Diff (LCY)]
	       , PB.[MICE]
		   , PB.[CustCenter / Private Fit]
		   , PB.[CI]
		   , PB.[CCR]
	       , PB.[HOTEL.DE]
	       , PB.[TISCOVER]
	       , PB.[TMC]
	       , PB.[Deals]
		   , CL.[Min_ Posting Date]
		   , CL.[Max_ Posting Date]
		FROM RB_PAYBACK PB
		JOIN CL
		  ON CL.[Hotel No_] = PB.[Hotel No_]
END

IF OBJECT_ID('tempdb..#AP') IS NULL
BEGIN
  CREATE TABLE #AP ([Hotel No_] int primary key, [Avg. Commission Amount per Month (LCY)] decimal(38,20), [Total Commission Amount (LCY)] decimal(38,20), [Avg. Commission Rate %] decimal(38,20), [Avg. non commissionable Ratio %] decimal(38,20)	, [Min. RB Posting Date] date, [Max. RB Posting Date] date
)

;WITH _AP AS
(
  SELECT AP.HotelNo [Hotel No_]
       , YEAR(AP.DepartureDate) [Travel Year]
       , MONTH(AP.DepartureDate) [Travel Month]
       , SUM(AP.Amount_LCY) [Amount (LCY)]
	   , SUM(AP.Turnover_LCY) [Turnover (LCY)]
	   , SUM(AP.Amount_LCY_corr) [Amount post Correction (LCY)]
	   , SUM(AP.Turnover_LCY_corr) [Turnover post Correction (LCY)]
	   , SUM(CASE WHEN AP.Amount_LCY = 0 THEN AP.Turnover_LCY ELSE 0 END) [Turnover non commissionable (LCY)]
	   , SUM(CASE WHEN AP.Amount_LCY_corr = 0 THEN AP.Turnover_LCY_corr ELSE 0 END) [Turnover n.c. post Correction (LCY)]
	   , MIN(CASE WHEN BP.RANKING_BOOSTER > 0 THEN AP.PostingDate ELSE '2999-12-31' END) [Min. RB Posting Date]
	   , MAX(CASE WHEN BP.RANKING_BOOSTER > 0 THEN AP.PostingDate ELSE '1753-01-01' END) [Max. RB Posting Date]
    FROM DynNavHRS.dbo.[HRS$Affiliate Postings] AP WITH (NOLOCK)
	JOIN DynNavHRS.HRSDB.BKG_PROCESS_ALL_DA BP WITH (NOLOCK)
	  ON BP.BP_KEY = AP.ProcessNumber
GROUP BY AP.HotelNo
       , YEAR(AP.DepartureDate)
       , MONTH(AP.DepartureDate)
UNION
  SELECT AP.HotelNo [Hotel No_]
       , YEAR(AP.DepartureDate) [Travel Year]
       , MONTH(AP.DepartureDate) [Travel Month]
       , SUM(AP.Amount_LCY) [Amount (LCY)]
	   , SUM(AP.Turnover_LCY) [Turnover (LCY)]
	   , SUM(AP.Amount_LCY_corr) [Amount post Correction (LCY)]
	   , SUM(AP.Turnover_LCY_corr) [Turnover post Correction (LCY)]
	   , SUM(CASE WHEN AP.Amount_LCY = 0 THEN AP.Turnover_LCY ELSE 0 END) [Turnover non commissionable (LCY)]
	   , SUM(CASE WHEN AP.Amount_LCY_corr = 0 THEN AP.Turnover_LCY_corr ELSE 0 END) [Turnover n.c. post Correction (LCY)]
	   , MIN(CASE WHEN BP.RANKING_BOOSTER > 0 THEN AP.PostingDate ELSE '2999-12-31' END) [Min. RB Posting Date]
	   , MAX(CASE WHEN BP.RANKING_BOOSTER > 0 THEN AP.PostingDate ELSE '1753-01-01' END) [Max. RB Posting Date]
    FROM DynNavHRS.dbo.[HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
	JOIN DynNavHRS.HRSDB.BKG_PROCESS_ALL_DA BP WITH (NOLOCK)
	  ON BP.BP_KEY = AP.ProcessNumber
GROUP BY AP.HotelNo
       , YEAR(AP.DepartureDate)
       , MONTH(AP.DepartureDate)
UNION
  SELECT AP.HotelNo [Hotel No_]
       , YEAR(AP.DepartureDate) [Travel Year]
       , MONTH(AP.DepartureDate) [Travel Month]
       , SUM(AP.Amount_LCY) [Amount (LCY)]
	   , SUM(AP.Turnover_LCY) [Turnover (LCY)]
	   , SUM(AP.Amount_LCY_corr) [Amount post Correction (LCY)]
	   , SUM(AP.Turnover_LCY_corr) [Turnover post Correction (LCY)]
	   , SUM(CASE WHEN AP.Amount_LCY = 0 THEN AP.Turnover_LCY ELSE 0 END) [Turnover non commissionable (LCY)]
	   , SUM(CASE WHEN AP.Amount_LCY_corr = 0 THEN AP.Turnover_LCY_corr ELSE 0 END) [Turnover n.c. post Correction (LCY)]
	   , MIN(CASE WHEN BP.RANKING_BOOSTER > 0 THEN AP.PostingDate ELSE '2999-12-31' END) [Min. RB Posting Date]
	   , MAX(CASE WHEN BP.RANKING_BOOSTER > 0 THEN AP.PostingDate ELSE '1753-01-01' END) [Max. RB Posting Date]
    FROM DynNavHRS.dbo.[HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
	JOIN DynNavHRS.HRSDB.BKG_PROCESS_ALL_DA BP WITH (NOLOCK)
	  ON BP.BP_KEY = AP.ProcessNumber
GROUP BY AP.HotelNo
       , YEAR(AP.DepartureDate)
       , MONTH(AP.DepartureDate)
), AP AS
(
  SELECT AP.[Hotel No_]
       , AVG(AP.[Amount post Correction (LCY)]) [Avg. Commission Amount per Month (LCY)]
	   , SUM(AP.[Amount post Correction (LCY)]) [Total Commission Amount (LCY)]
	   , SUM(AP.[Amount post Correction (LCY)]) / SUM([Turnover post Correction (LCY)]) * 100. [Avg. Commission Rate %]
	   , SUM(AP.[Turnover n.c. post Correction (LCY)]) / SUM(AP.[Turnover post Correction (LCY)]) * 100. [Avg. non commissionable Ratio %]
	   , MIN(AP.[Min. RB Posting Date]) [Min. RB Posting Date]
	   , MAX(AP.[Max. RB Posting Date]) [Max. RB Posting Date]
    FROM _AP AP
GROUP BY AP.[Hotel No_]
)
  INSERT INTO #AP
  SELECT AP.* 
    FROM #RB RB
	JOIN AP
	  ON AP.[Hotel No_] = RB.[Hotel No_]
END

SELECT RB.[Hotel No_]
     , RB.[Apply Line Amount Diff (LCY)]
	 , RB.[Refund Line Amount Diff (LCY)]
	 , RB.[Line Amount Diff (LCY)]
     , RB.[MICE]
     , RB.[CustCenter / Private Fit]
     , RB.[CI]
     , RB.[CCR]
     , RB.[HOTEL.DE]
     , RB.[TISCOVER]
     , RB.[TMC]
     , RB.[Deals]
	 , CONVERT(varchar(12),RB.[Min_ Posting Date],104)[Min_ Posting Date]
	 , CONVERT(varchar(12),RB.[Max_ Posting Date],104)[Max_ Posting Date]
	 , CONVERT(varchar(12),AP.[Min. RB Posting Date],104) [Min. RB Posting Date]
	 , CONVERT(varchar(12),AP.[Max. RB Posting Date],104) [Max. RB Posting Date]
	 , AP.[Total Commission Amount (LCY)]
	 , AP.[Avg. Commission Amount per Month (LCY)]
	 , AP.[Avg. Commission Rate %]
	 , AP.[Avg. non commissionable Ratio %]
	 , CO.[Name] [Hotel Name]
	 , CO.[Name 2] [Hotel Name 2]
	 , CO.[Address] [Hotel Address]
	 , CO.[Address 2] [Hotel Address 2]
	 , CO.[Post Code] [Hotel Post Code]
	 , CO.[City] [Hotel City]
	 , CR.[Name] [Hotel Country]
	 , CU.[Name] [Invoice Name]
	 , CU.[Name 2] [Invoice Name 2]
	 , CU.[Address] [Invoice Address]
	 , CU.[Address 2] [Invoice Address 2]
	 , CU.[Post Code] [Invoice Post Code]
	 , CU.[City] [Invoice City]
	 , CC.[Name] [Invoice Country]
	 , HL.[ISO Code] [Hotel Language ISO Code]
	 , HL.[Name] [Hotel Language]
	 , CU.[E-Mail] [Invoice E-Mail]
	 , CBR.[No_] [HSM Code]
	 , SP.[Name] [HSM Name]
	 , SP.[E-Mail] [HSM E-Mail]
	 , SP.[Phone No_] [HSM Phone No_]
	 , CASE WHEN COALESCE(DCA.[Hotel No_],0)=0 THEN 0 ELSE 1 END [DCA History]
     , CO.[Contract Status]
	 , CU.[Payment Method Code]
	 , BA.[SWIFT Code]
	 , BA.[IBAN]
	 , BA.[Name]
  FROM #RB RB
  JOIN #AP AP On AP.[Hotel No_] = RB.[Hotel No_]
  JOIN [HRS$Contact] CO WITH (NOLOCK)
    ON CO.[No_] = RB.[Hotel No_]
  JOIN [HRS$Country_Region] CR WITH (NOLOCK)
    ON CR.Code = CO.[Country_Region Code]
  JOIN [HRS$Customer] CU WITH (NOLOCK)
    ON CU.[No_] = RB.[Hotel No_]
  JOIN [HRS$Country_Region] CC WITH (NOLOCK)
    ON CC.Code = CU.[Country_Region Code]
  JOIN [HRS$Language] HL WITH (NOLOCK)
    ON HL.Code = CU.[Language Code]  
LEFT JOIN [HRS$Contact Business Relation] CBR WITH (NOLOCK)
       ON CBR.[Contact No_] = CU.[No_]
      AND CBR.[Link to Table] = 4
	  AND CBR.[Business Relation Code] = 'HSM'
LEFT JOIN [HRS$Salesperson_Purchaser] SP WITH (NOLOCK)
       ON SP.[Code] = CBR.[No_]
LEFT JOIN [HRS$Debit Collection Case] DCA
       ON DCA.[Hotel No_] = CU.[No_]
LEFT JOIN [HRS$Customer Bank Account] BA WITH (NOLOCK)
       ON BA.[Customer No_] = CU.[No_]
	  AND BA.[Clearing]     = 1
ORDER BY 4
END
GO
