USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[CommissionSales_02]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
Author:			MMC Management Solutions GmbH
Create date:	06.07.2011
Description:	Replacement for NAV-Report "Commission Sales New"
/*
DECLARE
	@UserId			VARCHAR(20)	= 'TMA04',
	@CompanyName	VARCHAR(30)	= 'HRS',
	@ReportId		INT			= 50138,
	@Detailed		BIT			= 1,
	@NOfN			BIT			= 1,
	@TToInclVatBF	BIT			= 1,
	@CTo			BIT			= 1,
	@NetInvAmt		BIT			= 1,
	@NetInvAmtLCY	BIT			= 1,
	@VatAmt			BIT			= 1,
	@InvAmt			BIT			= 1,
	@InvAmtLCY		BIT			= 1,
	@NOfP			BIT			= 1,
	@CToPerPost		BIT			= 1,
	@Ori			BIT			= 1,
	@Corr			BIT			= 1,
	@DiffAmt		BIT			= 1,
	@DiffPerc		BIT			= 1

EXECUTE [RS].[CommissionSales_02]
	@UserId, @CompanyName, @ReportId, @Detailed, @NOfN , @TToInclVatBF, @CTo, @NetInvAmt, @NetInvAmtLCY, @VatAmt, @InvAmt
	,@InvAmtLCY, @NOfP, @CToPerPost, @Ori, @Corr, @DiffAmt, @DiffPerc

*/
-- ============================================= */
CREATE PROCEDURE [RS].[CommissionSales_02] (
	@UserId			VARCHAR(20),
	@CompanyName	VARCHAR(30),
	@ReportId		INT,
	@Detailed		BIT = 1,
	@NOfN			BIT = 1,	--NumberOfNights 
	@TToInclVatBF	BIT = 1,	--TotalTurnoverInclVatAndBreakfast
	@CTo			BIT = 1,	--CommissionableTurnover
	@NetInvAmt		BIT = 1,	--NetInvoiceAmount
	@NetInvAmtLCY	BIT = 1,	--InvoiceAmountNetLCY
	@VatAmt			BIT = 1,	--VAT Amount
	@InvAmt			BIT = 1,	--InvoiceAmount
	@InvAmtLCY		BIT = 1,	--InvoiceAmountLCY
	@NOfP			BIT = 1,	--NumberOfPosts
	@CToPerPost		BIT = 1,	--CommissionTurnoverPerPost
	@Ori			BIT = 1,	--Original
	@Corr			BIT = 1,	--AfterCorrection
	@DiffAmt		BIT = 1,	--DifferenceAmount
	@DiffPerc		BIT = 1		--DifferencePercent
) AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN --REGION: Definition
    SET Language German
	DECLARE
		@IDs	[RS].[TableIDs],
		@Stmt	VARCHAR(MAX)

	CREATE TABLE #Company (
		Name	VARCHAR(30)
	)
	CREATE TABLE #CommissionSales (
		[Company]						VARCHAR(30),
		[CustomerNo]					VARCHAR(30),
		[JobNo]							VARCHAR(20),
		[DetailDocumentNo]				VARCHAR(20),
		[OriginalNumberOfNights]		DECIMAL(38,20),
		[OriginalNetInvoiceAmount]		DECIMAL(38,20),
		[OriginalNetInvoiceAmountLCY]	DECIMAL(38,20),
		[OriginalInvoiceAmount]			DECIMAL(38,20),
		[OriginalInvoiceAmountLCY]		DECIMAL(38,20),
		[OriginalVatAmount]				DECIMAL(38,20),
		[OriginalCommBreakfast]			DECIMAL(38,20),
		[OriginalTax&VAT]				DECIMAL(38,20),
		[OriginalQtyPosts]				DECIMAL(38,20),
		[OriginalComBaseAmtInclBrkf]	DECIMAL(38,20),
		[OriginalCommAmount]			DECIMAL(38,20),
		[OriginalCommAmount/QtyPosts]	DECIMAL(38,20),
		[DetailNumberOfNights]			DECIMAL(38,20),
		[DetailNetInvoiceAmount]		DECIMAL(38,20),
		[DetailNetInvoiceAmountLCY]		DECIMAL(38,20),
		[DetailInvoiceAmount]			DECIMAL(38,20),
		[DetailInvoiceAmountLCY]		DECIMAL(38,20),
		[DetailVatAmount]				DECIMAL(38,20),
		[DetailCommBreakfast]			DECIMAL(38,20),
		[DetailTax&Vat]					DECIMAL(38,20),
		[DetailQtyPosts]				DECIMAL(38,20),
		[DetailComBaseAmtInclBrkf]		DECIMAL(38,20),
		[DetailCommAmount]				DECIMAL(38,20),
		[DetailCommAmount/QtyPosts]		DECIMAL(38,20),
		[DiffAmtNumberOfNights]			DECIMAL(38,20),
		[DiffAmtNetInvoiceAmount]		DECIMAL(38,20),
		[DiffAmtNetInvoiceAmountLCY]	DECIMAL(38,20),
		[DiffAmtInoviceAmount]			DECIMAL(38,20),
		[DiffAmtInoviceAmountLCY]		DECIMAL(38,20),
		[DiffAmtVatAmount]				DECIMAL(38,20),
		[DiffAmtCommBreakfast]			DECIMAL(38,20),
		[DiffAmtTax&Vat]				DECIMAL(38,20),
		[DiffAmtQtyPosts]				DECIMAL(38,20),
		[DiffAmtComBaseAmtInclBrkf]		DECIMAL(38,20),
		[DiffAmtCommAmount]				DECIMAL(38,20),
		[DiffAmtCommAmount/QtyPosts]	DECIMAL(38,20),
		[DiffPercNumberOfNights]		DECIMAL(38,20),
		[DiffPercNetInvoiceAmount]		DECIMAL(38,20),
		[DiffPercNetInvoiceAmountLCY]	DECIMAL(38,20),
		[DiffPercInvoiceAmount]			DECIMAL(38,20),
		[DiffPercInvoiceAmountLCY]		DECIMAL(38,20),
		[DiffPercVatAmount]				DECIMAL(38,20),
		[DiffPercCommBreakfast]			DECIMAL(38,20),
		[DiffPercTax&Vat]				DECIMAL(38,20),
		[DiffPercQtyPosts]				DECIMAL(38,20),
		[DiffPercComBaseAmtInclBrkf]	DECIMAL(38,20),
		[DiffPercCommAmount]			DECIMAL(38,20),
		[DiffPercCommAmount/QtyPosts]	DECIMAL(38,20),
	)
END --REGION: Definition

BEGIN --REGION: Companies
	DELETE FROM @IDs
	INSERT INTO @IDs
	SELECT [Table ID], [Table Name]
	FROM [RS-Report Execution]
	WHERE [Start Company] = @CompanyName
		AND [UserID] = @UserId
		AND [Report ID] = @ReportId
		AND [Table ID] = 2000000006

	SET @Stmt = '-- Company Fetching
	INSERT INTO #Company (Name)
	SELECT Name FROM Company
	WHERE (1=1)' + [RS].[Nav2SqlString](@UserId, @CompanyName, @ReportId, @IDs, 0)
	
	PRINT(@Stmt)
	EXEC(@Stmt)
END --REGION: Companies

BEGIN --REGION: Company Iteration
	DELETE FROM @IDs
	INSERT INTO @IDs
	SELECT [Table ID], [Table Name]
	FROM [RS-Report Execution]
	WHERE [Start Company] = @CompanyName
		AND [UserID] = @UserId
		AND [Report ID] = @ReportId
		AND [Table ID] != 2000000006
		AND NOT ([Table ID] = 21 AND [Field ID] = 3)
	SET @Stmt = ''
	SELECT @Stmt = @Stmt + '--Company Iteration
	INSERT INTO #CommissionSales
	SELECT
		--ALLWAYS
		''' + [#Company].[Name] + '''
		,[' + [#Company].[Name] + '$Job].[Bill-to Customer No_]
		,[' + [#Company].[Name] + '$Job].[No_]
		--DETAIL
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Document No_]
		--ORIGINAL
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Number of Nights]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Net Invoice Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Net Invoice Amount (LCY)]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Invoice Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Invoice Amount (LCY)]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ VAT Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Comm_ Breakfast]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ TAX & VAT]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ ComBase Amt incl_ Brkf_]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig CommAmount]
		, CASE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
			WHEN 0 THEN 0
			ELSE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig CommAmount] / [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
		END
		--DETAIL & AFTER CORRECTION
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Number of Nights]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Net Invoice Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Net Invoice Amount (LCY)]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Invoice Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Invoice Amount (LCY)]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[VAT Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Comm_ Breakfast]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[TAX & VAT]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[ComBase Amt incl_ Brkf_]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[CommAmount]
		, CASE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
			WHEN 0 THEN 0
			ELSE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[CommAmount] / [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
		END
		--AFTER CORRECTION - ORIGINAL (DIFFERENCE AMOUNT)
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Number of Nights] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Number of Nights]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Net Invoice Amount] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Net Invoice Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Net Invoice Amount (LCY)] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Net Invoice Amount (LCY)]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Invoice Amount] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Invoice Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Invoice Amount (LCY)] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Invoice Amount (LCY)]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[VAT Amount] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ VAT Amount]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Comm_ Breakfast] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Comm_ Breakfast]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[TAX & VAT] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ TAX & VAT]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[ComBase Amt incl_ Brkf_] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ ComBase Amt incl_ Brkf_]
		,[' + [#Company].[Name] + '$Cust_ Ledger Entry].[CommAmount] - [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig CommAmount]
		, CASE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
			WHEN 0 THEN 0
			ELSE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[CommAmount] / [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
		END - CASE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
			WHEN 0 THEN 0
			ELSE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig CommAmount] / [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
		END
		--AFTER CORRECTION - ORIGINAL (DIFFERENCE PERCENT)
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Number of Nights], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Number of Nights])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Net Invoice Amount], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Net Invoice Amount])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Net Invoice Amount (LCY)], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Net Invoice Amount (LCY)])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Invoice Amount], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Invoice Amount])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Invoice Amount (LCY)], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Invoice Amount (LCY)])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[VAT Amount], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ VAT Amount])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Comm_ Breakfast], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Comm_ Breakfast])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[TAX & VAT], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ TAX & VAT])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[ComBase Amt incl_ Brkf_], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ ComBase Amt incl_ Brkf_])
		,[RS].[CommissionSalesPercent]([' + [#Company].[Name] + '$Cust_ Ledger Entry].[CommAmount], [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig CommAmount])
		,[RS].[CommissionSalesPercent](CASE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
			WHEN 0 THEN 0
			ELSE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[CommAmount] / [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Qty_ Postings]
		END , CASE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
			WHEN 0 THEN 0
			ELSE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig CommAmount] / [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Orig_ Qty_ Postings]
		END)
	FROM [' + [#Company].[Name] + '$Job]
	INNER JOIN [' + [#Company].[Name] + '$Cust_ Ledger Entry]
		ON [' + [#Company].[Name] + '$Job].[Bill-to Customer No_] = [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Customer No_]
	WHERE [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Document Type] IN (2,3) AND NOT [' + [#Company].[Name] + '$Cust_ Ledger Entry].[Document No_] LIKE ''MA%'' ' + [RS].[Nav2SqlString](@UserId, [#Company].[Name], @ReportId, @IDs, 2)
	FROM [#Company]
	
	PRINT(SUBSTRING(@Stmt,1,8000))
	PRINT(SUBSTRING(@Stmt,8001,8000))
	PRINT(SUBSTRING(@Stmt,16001,8000))
	PRINT(SUBSTRING(@Stmt,24001,8000))
	EXEC(@Stmt)
END  --REGION: Company Iteration

BEGIN	--REGION: Final Select + Cleanup
	SELECT * FROM [#CommissionSales] ORDER BY [Company] ASC, [CustomerNo] ASC
	DROP TABLE [#CommissionSales]
	DROP TABLE [#Company]
	DELETE FROM @IDs
END		--REGION: Final Select + Cleanup

END -- STORED PROCEDURE

GO
