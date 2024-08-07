USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPTAFInvoiceDetailNew_20200702_performance]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sascha Altgeld
-- Create date: 27.11.18
-- Description:	Rechnungsdetails der Transaction Fee
-- Datum    Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 06.11.18 HRS001	ACS-1291  SAL	
-- 
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = '14643795', @Company = 'HRS'
EXEC [dbo].[sp_RPTAFInvoiceDetail] @ReNr, @Company 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPTAFInvoiceDetailNew_20200702_performance] 
    @ReNr varchar(20),
	@Company varchar (30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
	
	CREATE TABLE #RESULTS
	(
		[HRS Process No_]		int
	  , [HRS Reservation No_]	VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [CRS Booking Code]		VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Arrival Date]			DATETIME
	  , [Departure Date]		DATETIME
	  , [Guestname 1]  			VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Guestname 2]			VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Client Company]		VARCHAR(250) COLLATE Latin1_General_CS_AS		
	  , [Language Code]			VARCHAR(250) COLLATE Latin1_General_CS_AS
	  , [Customer No_]			VARCHAR(250) COLLATE Latin1_General_CS_AS
	)

	SET @SQLStatement =
	'INSERT INTO #RESULTS
	select distinct 
	  ADL.[Process Number]		[HRS Process No_]
	, ADL.[Reservation No_]			[HRS Reservation No_]
	, ADL.[Booking Code]			[CRS Booking Code]
	, ADL.[Arrival Date]
	, ADL.[Departure Date]
	, ADL.[Client Guestname 1]		[Guestname 1]  	
	, ADL.[Client Guestname 2]		[Guestname 2]
	, ADL.[Client Company]			
	, CASE WHEN CU.[Language Code] = ''0'' THEN ''0'' ELSE ''1'' END [Language Code]
	, CU.[No_]						[Customer No_]
	from [' + @Company + '$TAF Invoice Header] TAFInv with (nolock)
		join [' + @Company + '$Agency Display Line] ADL with (nolock)
			-- on TAFInv.[Display Case No_] = ADL.[Display Case No_]
			on ADL.[Process Number] IN (
				SELECT [Process No_] 
				FROM [' + @Company + '$TAF Invoice Line] with (nolock)
				WHERE [TAF Invoice No_] = TAFInv.No_
			    )
			and ADL.[Action] <> 3

		join [' + @Company + '$Customer] CU with (nolock)
		on CU.No_ = TAFInv.[Bill-to Customer No_]
	where TAFInv.[Posted Sales Invoice No_] = ''' + @ReNr + '''
	ORDER BY ADL.[Process Number], ADL.[Reservation No_]
	'

	PRINT(@SQLStatement)
	EXECUTE(@SQLStatement)

	SELECT * FROM #RESULTS
END
GO
