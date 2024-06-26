USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[CustomerSearch]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Ralph Prangenberg
-- Create date: 15.10.2015
-- Description:	Volltextsuche für HRS Holidays Debitoren
--				Für Abgleich Werte HRS Holidays und Wild East
/*
EXEC [CustomerSearch] 'Kur und Bäder GmbH Bad Krozingen  KUR UND BÄDER GMBH BAD KROZINGEN', 'Herbert Hellmann Allee  12 ', '79189', 'Bad Krozingen'
EXEC [CustomerSearch] 'Appartementservice Müller APPARTEMENTSERVICE MÜLLER', 'Hafenstrasse 17', '18546', 'Sassnitz'
DECLARE   @CustName			NVARCHAR(332)	= 'Stadt Mahlberg'
		, @CustAddress		NVARCHAR(201)   = '*'
		, @CustPostCode		NVARCHAR(20)	= '77972'
		, @CustCity			NVARCHAR(70)	= 'Mahlberg'
EXEC [CustomerSearch] @CustName, @CustAddress, @CustPostCode, @CustCity	
*/
-- ================================================
create PROCEDURE [dbo].[CustomerSearch] 
	(
		  @CustName			NVARCHAR(332)
		, @CustAddress		NVARCHAR(201)
		, @CustPostCode		NVARCHAR(20)
		, @CustCity			NVARCHAR(70)
	)
AS BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET Language German

	DECLARE		@Pos					INT
			  , @Piece					VARCHAR(500)
			  , @SearchCustName			VARCHAR(500) = ''
			  , @SearchCustAddress		VARCHAR(500) = ''
			  , @SearchPostCode			VARCHAR(500) = ''
			  , @SearchCustCity			VARCHAR(500) = ''
			  , @Stmt					VARCHAR(MAX) = '' 
			  
	CREATE TABLE #RESULTSofName
	(
			[NoofName]			VARCHAR(20)
	)  
	CREATE TABLE #RESULTSofLocation
	(
			[NoofLocation]		VARCHAR(20)
	) 	
	CREATE TABLE #RESULTSofAddress
	(
			[NoofLocation]		VARCHAR(20)
	) 				   

	SELECT @SearchCustName		= [dbo].[SplitandDistinct4FullText] (@CustName, ' ')
	SELECT @SearchCustAddress	= [dbo].[SplitandDistinct4FullText] (@CustAddress, ' ')
	SELECT @SearchPostCode		= [dbo].[SplitandDistinct4FullText] (@CustPostCode, ' ')
	SELECT @SearchCustCity		= [dbo].[SplitandDistinct4FullText] (@CustCity, ' ')

	INSERT INTO #RESULTSofName
	SELECT [No_] 
	  FROM [HRS Holidays$Customer] WITH (NOLOCK) 
	 WHERE CONTAINS(	    [Name], @SearchCustName)
		OR CONTAINS(	  [Name 2], @SearchCustName)
		OR CONTAINS([Search Name], @SearchCustName)

	--Adress und Adress 2
	INSERT INTO #RESULTSofAddress
	SELECT [No_] 
	  FROM [HRS Holidays$Customer] WITH (NOLOCK)     
	 WHERE CONTAINS(  [Address], @SearchCustAddress)	
		OR CONTAINS([Address 2], @SearchCustAddress)	

	--Post Code und City
	INSERT INTO #RESULTSofLocation
	SELECT [No_] 
	  FROM [HRS Holidays$Customer] WITH (NOLOCK)     
	 WHERE CONTAINS([Post Code], @SearchPostCode)	
		OR CONTAINS(	    [City], @SearchCustCity)		 

	SELECT [RN].[NoofName]
		 , REPLACE(COALESCE(CONVERT(VARCHAR(20), CONVERT(DECIMAL(38,2), SUM([DCLE].[Amount]))),''),'.',',')	[SUMAmount]
		 , REPLACE(REPLACE( CONVERT(VARCHAR(20), CONVERT(INT,         COUNT([DCLE].[Amount]))),'0',''),'.',',') [COUNTDocuments]
	  FROM #RESULTSofName			[RN]
	  JOIN #RESULTSofAddress		[RA]
	    ON [RN].[NoofName] = [RA].[NoofLocation]
	  JOIN #RESULTSofLocation		[RL]
		ON [RN].[NoofName] = [RL].[NoofLocation]
 LEFT JOIN [HRS Holidays$Detailed Cust_ Ledg_ Entry]	[DCLE] WITH (NOLOCK) 
		ON [DCLE].[Customer No_] COLLATE DATABASE_DEFAULT = [RN].[NoofName]
       AND [DCLE].[Posting Date] BETWEEN DATEADD(yy,-1,GETDATE()) AND GETDATE() 
	   AND [DCLE].[Entry Type] = 1
	   AND [DCLE].[Document Type] IN (2,3)
  GROUP BY [RN].[NoofName]
END
GO
