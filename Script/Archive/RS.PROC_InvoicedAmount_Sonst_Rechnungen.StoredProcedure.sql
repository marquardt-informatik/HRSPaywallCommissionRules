USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_InvoicedAmount_Sonst_Rechnungen]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--
-- EXEC [RS].[PROC_InvoicedAmount_Sonst_Rechnungen] '2019-03-20'
--
-- =============================================
CREATE PROCEDURE [RS].[PROC_InvoicedAmount_Sonst_Rechnungen]
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
	SELECT CASE
	         WHEN CLE.[Document No_] LIKE 'MS%' THEN 'Multisource'
			 WHEN SIH.[Order Type] = 5          THEN 'Sourcing'
			 WHEN SIH.[Order Type] = 4          THEN 'Marketplace'
			 WHEN SIH.[Order Type] = 7          THEN 'TAF '
			 WHEN ADH.MuseID = 'EAN'            THEN 'EAN'
			 WHEN ADH.MuseID = 'MEETAGO'        THEN 'Meetago'
			 WHEN ADH.MuseID = 'MEETAGO_HDE'    THEN 'Meetago'
	       END [Rechnungstyp]
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
	  AND CLE.[Document Type] = 2 -- Rechnung
	  AND (DCLE.[Document Type] = 2 OR DCLE.[Document Type] = 3) -- Rechnung o. Gutschrift
	  AND ( -- Rechnungen Filtern
			CLE.[Document No_] LIKE 'MS%'    -- Multisource
			OR SIH.[Order Type] = 5          -- Sourcing
			OR SIH.[Order Type] = 4          -- Marketplace
			OR SIH.[Order Type] = 7          -- TAF 
			OR ADH.MuseID = 'EAN'            -- EAN
			OR ADH.MuseID = 'MEETAGO'        -- Meetago
			OR ADH.MuseID = 'MEETAGO_HDE'    -- Meetago)
		 )
	GROUP BY CASE
	           WHEN CLE.[Document No_] LIKE 'MS%' THEN 'Multisource'
			   WHEN SIH.[Order Type] = 5          THEN 'Sourcing'
			   WHEN SIH.[Order Type] = 4          THEN 'Marketplace'
			   WHEN SIH.[Order Type] = 7          THEN 'TAF '
			   WHEN ADH.MuseID = 'EAN'            THEN 'EAN'
			   WHEN ADH.MuseID = 'MEETAGO'        THEN 'Meetago'
			   WHEN ADH.MuseID = 'MEETAGO_HDE'    THEN 'Meetago'
	         END
	       , CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0

	UNION ALL

	-- HRS-BR
	SELECT CASE
	         WHEN CLE.[Document No_] LIKE 'MS%' THEN 'Multisource'
			 WHEN SIH.[Order Type] = 5          THEN 'Sourcing'
			 WHEN SIH.[Order Type] = 4          THEN 'Marketplace'
			 WHEN SIH.[Order Type] = 7          THEN 'TAF '
			 WHEN ADH.MuseID = 'EAN'            THEN 'EAN'
			 WHEN ADH.MuseID = 'MEETAGO'        THEN 'Meetago'
			 WHEN ADH.MuseID = 'MEETAGO_HDE'    THEN 'Meetago'
	       END [Rechnungstyp]
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
	  AND CLE.[Document Type] = 2 -- Rechnung
	  AND (DCLE.[Document Type] = 2 OR DCLE.[Document Type] = 3) -- Rechnung o. Gutschrift
	  AND ( -- Rechnungen Filtern
			CLE.[Document No_] LIKE 'MS%'    -- Multisource
			OR SIH.[Order Type] = 5          -- Sourcing
			OR SIH.[Order Type] = 4          -- Marketplace
			OR SIH.[Order Type] = 7          -- TAF 
			OR ADH.MuseID = 'EAN'            -- EAN
			OR ADH.MuseID = 'MEETAGO'        -- Meetago
			OR ADH.MuseID = 'MEETAGO_HDE'    -- Meetago)
		 )
	GROUP BY CASE
	           WHEN CLE.[Document No_] LIKE 'MS%' THEN 'Multisource'
			   WHEN SIH.[Order Type] = 5          THEN 'Sourcing'
			   WHEN SIH.[Order Type] = 4          THEN 'Marketplace'
			   WHEN SIH.[Order Type] = 7          THEN 'TAF '
			   WHEN ADH.MuseID = 'EAN'            THEN 'EAN'
			   WHEN ADH.MuseID = 'MEETAGO'        THEN 'Meetago'
			   WHEN ADH.MuseID = 'MEETAGO_HDE'    THEN 'Meetago'
	         END
	       , CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0

	UNION ALL

	-- HRS-CN
	SELECT CASE
	         WHEN CLE.[Document No_] LIKE 'MS%' THEN 'Multisource'
			 WHEN SIH.[Order Type] = 5          THEN 'Sourcing'
			 WHEN SIH.[Order Type] = 4          THEN 'Marketplace'
			 WHEN SIH.[Order Type] = 7          THEN 'TAF '
			 WHEN ADH.MuseID = 'EAN'            THEN 'EAN'
			 WHEN ADH.MuseID = 'MEETAGO'        THEN 'Meetago'
			 WHEN ADH.MuseID = 'MEETAGO_HDE'    THEN 'Meetago'
	       END [Rechnungstyp]
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
	  AND CLE.[Document Type] = 2 -- Rechnung
	  AND (DCLE.[Document Type] = 2 OR DCLE.[Document Type] = 3) -- Rechnung o. Gutschrift
	  AND ( -- Rechnungen Filtern
			CLE.[Document No_] LIKE 'MS%'    -- Multisource
			OR SIH.[Order Type] = 5          -- Sourcing
			OR SIH.[Order Type] = 4          -- Marketplace
			OR SIH.[Order Type] = 7          -- TAF 
			OR ADH.MuseID = 'EAN'            -- EAN
			OR ADH.MuseID = 'MEETAGO'        -- Meetago
			OR ADH.MuseID = 'MEETAGO_HDE'    -- Meetago)
		 )
	GROUP BY CASE
	           WHEN CLE.[Document No_] LIKE 'MS%' THEN 'Multisource'
			   WHEN SIH.[Order Type] = 5          THEN 'Sourcing'
			   WHEN SIH.[Order Type] = 4          THEN 'Marketplace'
			   WHEN SIH.[Order Type] = 7          THEN 'TAF '
			   WHEN ADH.MuseID = 'EAN'            THEN 'EAN'
			   WHEN ADH.MuseID = 'MEETAGO'        THEN 'Meetago'
			   WHEN ADH.MuseID = 'MEETAGO_HDE'    THEN 'Meetago'
	         END
	       , CU.No_
	HAVING SUM (DCLE.[Amount (LCY)]) <> 0
)
	SELECT [Rechnungstyp]
	     , No_
		 , SUM ([CustBalanceDueLCY1])	[CustBalanceDueLCY1]	  		 
		 , SUM ([CustBalanceDueLCY2])	[CustBalanceDueLCY2]
		 , SUM ([CustBalanceDueLCY3])	[CustBalanceDueLCY3]
		 , SUM ([CustBalanceDueLCY4])	[CustBalanceDueLCY4]
		 , SUM ([CustBalanceDueLCY5])	[CustBalanceDueLCY5]
		 , SUM ([CustBalanceDueLCY6])	[CustBalanceDueLCY6]
		 , SUM ([CustBalanceDueLCY7])	[CustBalanceDueLCY7]
		 , SUM ([CustBalanceDueLCYTotal])	[CustBalanceDueLCYTotal]
	FROM RESULT
	GROUP BY [Rechnungstyp], No_
END
GO
