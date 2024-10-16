USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CustClaimStatusReportDetailed_Chain]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--
-- EXEC [RS].[PROC_CustClaimStatusReportDetailed_Chain] '2019-03-20'
--
-- =============================================
CREATE PROCEDURE [RS].[PROC_CustClaimStatusReportDetailed_Chain] 
	@StartDate					DATETIME
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE
	    @Date1End			DATETIME
	  , @Date2Start			DATETIME
	  , @Date2End			DATETIME
	  , @Date3Start			DATETIME
	  , @Date3End			DATETIME
	  , @Date4Start			DATETIME
	  , @Date4End			DATETIME
	  , @Date5Start			DATETIME
	  , @Date5End			DATETIME
	  , @Date6Start			DATETIME
	  , @Date6End			DATETIME
	  , @Date7Start			DATETIME

	SET @Date7Start = @StartDate 
	SET @Date6End   = DATEADD(dd,  -1, @Date7Start) 
	SET @Date6Start = DATEADD(dd, -30, @Date7Start) 
	SET @Date5End   = DATEADD(dd,  -1, @Date6Start) 
	SET @Date5Start = DATEADD(dd, -30, @Date6Start) 
	SET @Date4End   = DATEADD(dd,  -1, @Date5Start) 
	SET @Date4Start = DATEADD(dd, -30, @Date5Start) 
	SET @Date3End   = DATEADD(dd,  -1, @Date4Start)
	SET @Date3Start = DATEADD(dd, -30, @Date4Start) 
	SET @Date2End   = DATEADD(dd,  -1, @Date3Start)
	SET @Date2Start = DATEADD(dd, -30, @Date3Start) 
	SET @Date1End   = DATEADD(dd,  -1, @Date2Start)

	PRINT(@Date7Start)
	PRINT(@Date6End)
	PRINT(@Date6Start)
	PRINT(@Date5End) 
	PRINT(@Date5Start)
	PRINT(@Date4End) 
	PRINT(@Date4Start) 
	PRINT(@Date3End)
	PRINT(@Date3Start) 
	PRINT(@Date2End)
	PRINT(@Date2Start) 
	PRINT(@Date1End)

; WITH RESULT AS (
	-- HRS
	SELECT CU.Chain
	     , CU.No_
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] <= @Date1End
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1]	  		 
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date2Start AND @Date2End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date3Start AND @Date3End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date4Start AND @Date4End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date5Start AND @Date5End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date6Start AND @Date6End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY6]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] >= @Date7Start 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY7]
		, SUM (DCLE.[Amount (LCY)])	[CustBalanceDueLCYTotal]
	FROM [HRS$Customer] CU WITH (NOLOCK)
	JOIN [HRS$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.No_
	LEFT JOIN [HRS$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0

	UNION ALL

	-- HRS-BR
	SELECT CU.Chain
	     , CU.No_
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] <= @Date1End
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1]	  		 
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date2Start AND @Date2End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date3Start AND @Date3End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date4Start AND @Date4End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date5Start AND @Date5End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date6Start AND @Date6End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY6]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] >= @Date7Start 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY7]
		, SUM (DCLE.[Amount (LCY)])	[CustBalanceDueLCYTotal]
	FROM [HRS-BR$Customer] CU WITH (NOLOCK)
	JOIN [HRS-BR$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS-BR$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS-BR$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.No_
	LEFT JOIN [HRS-BR$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0

	UNION ALL

	-- HRS-CN
	SELECT CU.Chain
	     , CU.No_
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] <= @Date1End
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY1]	  		 
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date2Start AND @Date2End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY2]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date3Start AND @Date3End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY3]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date4Start AND @Date4End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY4]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date5Start AND @Date5End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY5]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] BETWEEN @Date6Start AND @Date6End 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY6]
		 , SUM (CASE WHEN DCLE.[Initial Entry Due Date] >= @Date7Start 
					 THEN DCLE.[Amount (LCY)]
					 ELSE 0
				END)	[CustBalanceDueLCY7]
		, SUM (DCLE.[Amount (LCY)])	[CustBalanceDueLCYTotal]
	FROM [HRS-CN$Customer] CU WITH (NOLOCK)
	JOIN [HRS-CN$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS-CN$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS-CN$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.No_
	LEFT JOIN [HRS-CN$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0
),RESULT_ES AS (
	--HRS
	SELECT CU.Chain
	     , CU.No_ 
		 , CASE WHEN COUNT(APost.InvoiceNo) IS NOT NULL AND COUNT(APost.InvoiceNo) <> 0 THEN COUNT(APost.InvoiceNo) ELSE 0 END [ES Entries]
	FROM [HRS$Customer] CU WITH (NOLOCK)
	JOIN [HRS$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.[No_]
	LEFT JOIN [HRS$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	LEFT JOIN [HRS$Affiliate Postings] APost WITH (NOLOCK) 
		   ON APost.InvoiceNo = CASE WHEN CHARINDEX('/', ADH.[Posted Invoice No_]) <> 0 
									 THEN SUBSTRING(ADH.[Posted Invoice No_], 1, CHARINDEX('/', ADH.[Posted Invoice No_]) - 1) 
									 ELSE ADH.[Posted Invoice No_] END
	LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK) ON APost.[AffiliatePartnerNo] = AP.No_
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	  AND ((APost.ReservationSource <> '383' AND AP.[Distribution Channel ID] NOT IN (2,9,12))
	   OR (APost.ReservationSource = '383' AND (AP.[Distribution Channel ID] < 10 OR AP.[Company-No_] = 0)))
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0

UNION ALL

	--HRS-BR
	SELECT CU.Chain
	     , CU.No_ 
		 , CASE WHEN COUNT(APost.InvoiceNo) IS NOT NULL AND COUNT(APost.InvoiceNo) <> 0 THEN COUNT(APost.InvoiceNo) ELSE 0 END [ES Entries]
	FROM [HRS-BR$Customer] CU WITH (NOLOCK)
	JOIN [HRS-BR$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS-BR$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS-BR$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.[No_]
	LEFT JOIN [HRS-BR$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	LEFT JOIN [HRS-BR$Affiliate Postings] APost WITH (NOLOCK) 
		   ON APost.InvoiceNo = CASE WHEN CHARINDEX('/', ADH.[Posted Invoice No_]) <> 0 
									 THEN SUBSTRING(ADH.[Posted Invoice No_], 1, CHARINDEX('/', ADH.[Posted Invoice No_]) - 1) 
									 ELSE ADH.[Posted Invoice No_] END
	LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK) ON APost.[AffiliatePartnerNo] = AP.No_
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	  AND ((APost.ReservationSource <> '383' AND AP.[Distribution Channel ID] NOT IN (2,9,12))
	   OR (APost.ReservationSource = '383' AND (AP.[Distribution Channel ID] < 10 OR AP.[Company-No_] = 0)))
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0	
	
UNION ALL

	--HRS-CN
	SELECT CU.Chain
	     , CU.No_ 
		 , CASE WHEN COUNT(APost.InvoiceNo) IS NOT NULL AND COUNT(APost.InvoiceNo) <> 0 THEN COUNT(APost.InvoiceNo) ELSE 0 END [ES Entries]
	FROM [HRS-CN$Customer] CU WITH (NOLOCK)
	JOIN [HRS-CN$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS-CN$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS-CN$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.[No_]
	LEFT JOIN [HRS-CN$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	LEFT JOIN [HRS-CN$Affiliate Postings] APost WITH (NOLOCK) 
		   ON APost.InvoiceNo = CASE WHEN CHARINDEX('/', ADH.[Posted Invoice No_]) <> 0 
									 THEN SUBSTRING(ADH.[Posted Invoice No_], 1, CHARINDEX('/', ADH.[Posted Invoice No_]) - 1) 
									 ELSE ADH.[Posted Invoice No_] END
	LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK) ON APost.[AffiliatePartnerNo] = AP.No_
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	  AND ((APost.ReservationSource <> '383' AND AP.[Distribution Channel ID] NOT IN (2,9,12))
	   OR (APost.ReservationSource = '383' AND (AP.[Distribution Channel ID] < 10 OR AP.[Company-No_] = 0)))
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0		
),RESULT_BS AS (
	--HRS
	SELECT CU.Chain
	     , CU.No_ 
		 , CASE WHEN COUNT(APost.InvoiceNo) IS NOT NULL AND COUNT(APost.InvoiceNo) <> 0 THEN COUNT(APost.InvoiceNo) ELSE 0 END [BS Entries]
	FROM [HRS$Customer] CU WITH (NOLOCK)
	JOIN [HRS$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.[No_]
	LEFT JOIN [HRS$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	LEFT JOIN [HRS$Affiliate Postings] APost WITH (NOLOCK) 
		   ON APost.InvoiceNo = CASE WHEN CHARINDEX('/', ADH.[Posted Invoice No_]) <> 0 
									 THEN SUBSTRING(ADH.[Posted Invoice No_], 1, CHARINDEX('/', ADH.[Posted Invoice No_]) - 1) 
									 ELSE ADH.[Posted Invoice No_] END
	LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK) ON APost.[AffiliatePartnerNo] = AP.No_
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	  AND ((APost.ReservationSource <> '383' AND AP.[Distribution Channel ID] IN (2,9,12))
	   OR (APost.ReservationSource = '383' AND (AP.[Distribution Channel ID] >= 10 AND AP.[Company-No_] <> 0)))
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0

UNION ALL

	--HRS-BR
	SELECT CU.Chain
	     , CU.No_ 
		 , CASE WHEN COUNT(APost.InvoiceNo) IS NOT NULL AND COUNT(APost.InvoiceNo) <> 0 THEN COUNT(APost.InvoiceNo) ELSE 0 END [BS Entries]
	FROM [HRS-BR$Customer] CU WITH (NOLOCK)
	JOIN [HRS-BR$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS-BR$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS-BR$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.[No_]
	LEFT JOIN [HRS-BR$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	LEFT JOIN [HRS-BR$Affiliate Postings] APost WITH (NOLOCK) 
		   ON APost.InvoiceNo = CASE WHEN CHARINDEX('/', ADH.[Posted Invoice No_]) <> 0 
									 THEN SUBSTRING(ADH.[Posted Invoice No_], 1, CHARINDEX('/', ADH.[Posted Invoice No_]) - 1) 
									 ELSE ADH.[Posted Invoice No_] END
	LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK) ON APost.[AffiliatePartnerNo] = AP.No_
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	  AND ((APost.ReservationSource <> '383' AND AP.[Distribution Channel ID] IN (2,9,12))
	   OR (APost.ReservationSource = '383' AND (AP.[Distribution Channel ID] >= 10 AND AP.[Company-No_] <> 0)))
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0	
	
UNION ALL

	--HRS-CN
	SELECT CU.Chain
	     , CU.No_ 
		 , CASE WHEN COUNT(APost.InvoiceNo) IS NOT NULL AND COUNT(APost.InvoiceNo) <> 0 THEN COUNT(APost.InvoiceNo) ELSE 0 END [BS Entries]
	FROM [HRS-CN$Customer] CU WITH (NOLOCK)
	JOIN [HRS-CN$Cust_ Ledger Entry] CLE WITH (NOLOCK) ON CU.No_ = CLE.[Customer No_]
	JOIN [HRS-CN$Detailed Cust_ Ledg_ Entry] DCLE WITH (NOLOCK) ON CLE.[Entry No_] = DCLE.[Cust_ Ledger Entry No_]
	LEFT JOIN [HRS-BR$Sales Invoice Header] SIH WITH (NOLOCK) ON CLE.[Document No_] = SIH.[No_]
	LEFT JOIN [HRS-CN$Agency Display Header] ADH WITH (NOLOCK) ON SIH.No_ = ADH.[Posted Invoice No_]
	LEFT JOIN [HRS-CN$Affiliate Postings] APost WITH (NOLOCK) 
		   ON APost.InvoiceNo = CASE WHEN CHARINDEX('/', ADH.[Posted Invoice No_]) <> 0 
									 THEN SUBSTRING(ADH.[Posted Invoice No_], 1, CHARINDEX('/', ADH.[Posted Invoice No_]) - 1) 
									 ELSE ADH.[Posted Invoice No_] END
	LEFT JOIN [Affiliate Partner] AP WITH (NOLOCK) ON APost.[AffiliatePartnerNo] = AP.No_
	WHERE DCLE.[Posted At Date] <= @StartDate
      AND CU.Testhotel = ''
	  -- Nur CRS Hotels
	  AND CU.[Contract Status] IN ('10', '11')
	  -- Rechnungen Filtern
	  AND ((CLE.[Document Type] = 2 
	           AND CLE.[Document No_] NOT LIKE 'MS%' -- Multisource
			   AND SIH.[Order Type] <> 5             -- Sourcing
			   AND SIH.[Order Type] <> 4             -- Marketplace
			   AND SIH.[Order Type] <> 7             -- TAF 
			   AND ADH.MuseID <> 'EAN'               -- EAN
			   AND ADH.MuseID <> 'MEETAGO'           -- Meetago
			   AND ADH.MuseID <> 'MEETAGO_HDE'       -- Meetago
		    )
			OR (CLE.[Document Type] <> 2)
		  )
	  AND ((APost.ReservationSource <> '383' AND AP.[Distribution Channel ID] IN (2,9,12))
	   OR (APost.ReservationSource = '383' AND (AP.[Distribution Channel ID] >= 10 AND AP.[Company-No_] <> 0)))
	GROUP BY CU.Chain, CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0)
	
	SELECT RESULT.Chain
	     , RESULT.No_
		 , CASE WHEN RESULT_ES.[ES Entries] + RESULT_BS.[BS Entries] > 0 THEN ROUND(CAST(RESULT_ES.[ES Entries] AS float) / CAST(RESULT_ES.[ES Entries] + RESULT_BS.[BS Entries] AS float)  * 100, 2) ELSE 0 END [Percentage ES]
		 , CASE WHEN RESULT_ES.[ES Entries] + RESULT_BS.[BS Entries] > 0 THEN ROUND(CAST(RESULT_BS.[BS Entries] AS float) / CAST(RESULT_ES.[ES Entries] + RESULT_BS.[BS Entries] AS float)  * 100, 2) ELSE 0 END [Percentage BS]
		 , SUM (CAST(RESULT.[CustBalanceDueLCY1] AS	float)) [CustBalanceDueLCY1]	  		 
		 , SUM (CAST(RESULT.[CustBalanceDueLCY2] AS float))	[CustBalanceDueLCY2]
		 , SUM (CAST(RESULT.[CustBalanceDueLCY3] AS float))	[CustBalanceDueLCY3]
		 , SUM (CAST(RESULT.[CustBalanceDueLCY4] AS float))	[CustBalanceDueLCY4]
		 , SUM (CAST(RESULT.[CustBalanceDueLCY5] AS float))	[CustBalanceDueLCY5]
		 , SUM (CAST(RESULT.[CustBalanceDueLCY6] AS float))	[CustBalanceDueLCY6]
		 , SUM (CAST(RESULT.[CustBalanceDueLCY7] AS float))	[CustBalanceDueLCY7]
		 , SUM (CAST(RESULT.[CustBalanceDueLCYTotal] AS float))	[CustBalanceDueLCYTotal]
	FROM RESULT
	LEFT JOIN RESULT_ES ON RESULT.Chain = RESULT_ES.Chain AND RESULT.No_ = RESULT_ES.No_
	LEFT JOIN RESULT_BS ON RESULT.Chain = RESULT_BS.Chain AND RESULT.No_ = RESULT_BS.No_
	GROUP BY RESULT.Chain
	     , RESULT.No_
		 , RESULT_ES.[ES Entries] 
		 , RESULT_BS.[BS Entries] 	
END	
GO
