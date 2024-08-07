USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingFeeHeader_PaySol]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 12.12.2014
-- Description:	Rechnungskopf der Transaction Fee
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 04.01.18 HRS001			 SAL	Optimization in case condition for Country/Region JOIN and SH.Bill-to Country/Region Code
-- 19.07.18 HRS002   ACS-694 DJU    Added field [Central Billing Fee Type]
--                                  + corrected VAT Amount and Amount
-- 27.06.19 HRS003  ACS-1847 DJU    Added field [Salesperson Code]
-- 
/*
DECLARE @ReNr varchar(20), @Company varchar(30)
 SELECT @ReNr = 'PD00219162', @Company = 'HRS Payment'
EXEC [dbo].[sp_RPCentralBillingFeeHeader_PaySol] @ReNr, @Company 
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingFeeHeader_PaySol] 
    @ReNr varchar(20)
  , @Company varchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLStatement VARCHAR(max)
	DECLARE @SQLGroupBy  VARCHAR(max)
  
	CREATE TABLE #RESULTS 
	( 
		[No_]								VARCHAR(250)
	  , [Sell-to Customer No_]				VARCHAR(250)
	  , [Sell-to Contact]					VARCHAR(250)
	  , [Sell-to Customer Name]				VARCHAR(250)
	  , [Sell-to Customer Name 2]			VARCHAR(250)
	  , [Sell-to Address]					VARCHAR(250)
	  , [Sell-to Address 2]					VARCHAR(250)
	  , [Sell-to City]						VARCHAR(250)
	  , [Sell-to Post Code]					VARCHAR(250)
	  , [Sell-to Country Code]              VARCHAR(250)
	  , [Bill-to Customer No_]				VARCHAR(250)
	  , [Posting Date]                      DATETIME
	  , [Payment Method Code]				VARCHAR(250)
	  , [EU Ländercode]						VARCHAR(250)
	  , [ISO_Code]							VARCHAR(250)
	  , [Fax Extension]						VARCHAR(250)
	  , [Phone Extension]					VARCHAR(250)
	  , [Name]								VARCHAR(250)
	  , [Document Date]						DATETIME
	  , [Posting Description]				VARCHAR(250)
	  , [Currency Code]						VARCHAR(250)
	  , [Currency Factor]					DECIMAL(38,20)
	  , [VAT]								DECIMAL(38,20)
	  , [Amount]							DECIMAL(38,20)
	  , [Mwst]								DECIMAL(38,20)
	  , [Total]								DECIMAL(38,20)
      , [Bank Branch No_]                   VARCHAR(250)
      , [Bank Account No_]                  VARCHAR(250)
      , [Bank Name]                         VARCHAR(250)
      , [IBAN]                              VARCHAR(250)
      , [BIC]                               VARCHAR(250)
	  , [Language Code]						NVARCHAR(250)
	  , [SEPA]								tinyint
	  , [Bank_1_Descrption]					VARCHAR(250)
	  , [Bank_1_Account]					VARCHAR(250)
	  , [Bank_1_BLZ]						VARCHAR(250)
	  , [Bank_1_Swift]						VARCHAR(250)
	  , [Bank_1_IBAN]						VARCHAR(250)
	  , [Bank_1_BankTxt]					NVARCHAR(max)
	  , [Bank_2_Descrption]					VARCHAR(250)
	  , [Bank_2_Account]					VARCHAR(250)
	  , [Bank_2_BLZ]						VARCHAR(250)
	  , [Bank_2_Swift]						VARCHAR(250)
	  , [Bank_2_IBAN]						VARCHAR(250)
	  , [Bank_2_BankTxt]					NVARCHAR(max)
	  , [Bank_3_Descrption]					VARCHAR(250)
	  , [Bank_3_Account]					VARCHAR(250)
	  , [Bank_3_BLZ]						VARCHAR(250)
	  , [Bank_3_Swift]						VARCHAR(250)
	  , [Bank_3_IBAN]						VARCHAR(250)
	  , [Bank_3_BankTxt]					NVARCHAR(max)
	  , [Quantity]                          int
	  , [Customer VAT Registration No_]     VARCHAR(250) 
	  , [Central Billing Fee Type]			int
	  , [Order Type]						int
	  -- HRS003 >>
	  , [Salesperson Code]					VARCHAR(250)
	  -- HRS003 <<
	)
	SET @SQLGroupBy = 
' GROUP BY SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END 
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END 
         , SH.[Sell-to Post Code]
         , SH.[Bill-to Country_Region Code]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]     
         , SH.[Language Code]                  
         , SP.[Fax Extension]              
         , SP.[Phone Extension]            
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
         , RTRIM(BA.[Bank Branch No_])
         , RTRIM(BA.[Bank Account No_])
         , RTRIM(BA.[Name])
         , RTRIM(BA.[IBAN])
         , RTRIM(BA.[SWIFT Code])
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END
		 , SH.[Central Billing Fee Type]
		 , SH.[Order Type]
		 -- HRS003 >>
		 , SH.[Salesperson Code]
		 -- HRS003 <<
       '
	
	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Invoice Header] WHERE [No_] = ''' + @ReNr + ''')
    WITH BANK AS
    (
      SELECT BR.[Sequences]
           , BR.[Country Code]
           , BK.[BankTxt]
           , BK.[BLZ]
           , BK.[Swift]
           , BK.[IBAN]
           , BK.[Account]
           , BK.[Description]
           , BR.[Sequences]    [Reihenfolgen]
        FROM [HRS$Bank Regulation] BR WITH (READUNCOMMITTED)
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
    )
    INSERT INTO #RESULTS
    SELECT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
         , CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END AS [Bill-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added]
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Durchwahl Fax]
         , SP.[Phone Extension]             AS [Durchwahl Telefon]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
         , MAX(SL.[VAT %])                  AS VAT
         , SUM(SL.Amount)                   AS Amount
         , SUM(SL.[Amount Including VAT]) - SUM(SL.Amount) AS Mwst
         , SUM(SL.[Amount Including VAT])   AS Total
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
         , MAX(COALESCE(B1.[Description],''''))                        [Bank_1_Descrption]
         , MAX(COALESCE(B1.[Account],''''))                            [Bank_1_Account]
         , MAX(COALESCE(B1.[BLZ],''''))                                [Bank_1_BLZ]
         , MAX(COALESCE(B1.[Swift],''''))                              [Bank_1_Swift]
         , MAX(COALESCE(B1.[IBAN],''''))                               [Bank_1_IBAN]
         , MAX(COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_1_BankTxt]
         , MAX(COALESCE(B2.[Description],''''))                        [Bank_2_Descrption]
         , MAX(COALESCE(B2.[Account],''''))                            [Bank_2_Account]
         , MAX(COALESCE(B2.[BLZ],''''))                                [Bank_2_BLZ]
         , MAX(COALESCE(B2.[Swift],''''))                              [Bank_2_Swift]
         , MAX(COALESCE(B2.[IBAN],''''))                               [Bank_2_IBAN]
         , MAX(COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_2_BankTxt]
         , MAX(COALESCE(B3.[Description],'''') )                       [Bank_3_Descrption]
         , MAX(COALESCE(B3.[Account],''''))                            [Bank_3_Account]
         , MAX(COALESCE(B3.[BLZ],''''))                                [Bank_3_BLZ]
         , MAX(COALESCE(B3.[Swift],''''))                              [Bank_3_Swift]
         , MAX(COALESCE(B3.[IBAN],''''))                               [Bank_3_IBAN]
         , MAX(COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_3_BankTxt]
         , SUM(SL.[Quantity])                                          [Quantity]
         , MAX(CU.[VAT Registration No_])                              [VAT Registration No_]
		 , SH.[Central Billing Fee Type]                               [Central Billing Fee Type]
		 , SH.[Order Type]											   [Order Type]
		 -- HRS003 >>
		 , SH.[Salesperson Code]
		 -- HRS003 <<'
	SET @SQLStatement = @SQLStatement + 
'
      FROM [' + @Company + '$Sales Invoice Header] AS SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
        -- // 04.01.18 SAL HRS001 >>
		--ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
		ON CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
        -- // 04.01.18 SAL HRS001 <<
	  JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN [' + @Company + '$Sales Invoice Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [' + @Company + '$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]   
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
   WHERE (SH.No_ = ''' + @ReNr + ''')
'	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,1,8000))
	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,8001,8000))
	EXECUTE(@SQLStatement+@SQLGroupBy)       

	SET @SQLStatement = 
'IF EXISTS(SELECT * FROM [' + @Company + '$Sales Header] WHERE [No_] = ''' + @ReNr + ''')
    WITH BANK AS
    (
      SELECT BR.[Sequences]
           , BR.[Country Code]
           , BK.[BankTxt]
           , BK.[BLZ]
           , BK.[Swift]
           , BK.[IBAN]
           , BK.[Account]
           , BK.[Description]
           , BR.[Sequences]    [Reihenfolgen]
        FROM [HRS$Bank Regulation] BR WITH (READUNCOMMITTED)
        JOIN [Bank] BK WITH (READUNCOMMITTED)
          ON BR.[Bank No_] = BK.[BankCode] COLLATE Latin1_General_CI_AS
    )
    INSERT INTO #RESULTS
    SELECT SH.[No_]
         , SH.[Sell-to Customer No_]
         , SH.[Sell-to Contact]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name]   ELSE P1.[Content] END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Customer Name 2] ELSE P2.[Content] END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address]         ELSE P3.[Content] END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to Address 2]       ELSE P4.[Content] END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN SH.[Sell-to City]            ELSE P5.[Content] END [Sell-to City]
         , SH.[Sell-to Post Code]
         , CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END AS [Bill-to Country Code]  -- 04.01.18 HRS001 CASE-Condition added
         , SH.[Bill-to Customer No_]
         , SH.[Posting Date]
         , SH.[Payment Method Code]
         , CO.[EU Country_Region Code]      AS [EU Ländercode]
         , SH.[Language Code]               AS [ISO_Code]
         , SP.[Fax Extension]               AS [Durchwahl Fax]
         , SP.[Phone Extension]             AS [Durchwahl Telefon]
         , CASE WHEN P6.[Content] IS NULL   THEN CO.Name                      ELSE P6.[Content] END Name
         , SH.[Document Date]
         , SH.[Posting Description]       
         , CASE WHEN SH.[Currency Code] = '''' THEN ''EUR'' ELSE SH.[Currency Code] END
         , CASE WHEN SH.[Currency Factor]=0 THEN 1 ELSE SH.[Currency Factor] END
         , MAX(SL.[VAT %])                  AS VAT
         , SUM(SL.[Line Amount])-SUM([Line Discount Amount]) AS Amount
         , SUM(SL.[Outstanding Amount]) - (SUM(SL.[Line Amount])-SUM([Line Discount Amount])) AS Mwst
         , SUM(SL.[Outstanding Amount])   AS Total
         , RTRIM(BA.[Bank Branch No_])         [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_])        [Bank Account No_]
         , RTRIM(BA.[Name])                    [Bank Name]
         , RTRIM(BA.[IBAN])                    [IBAN]
         , RTRIM(BA.[SWIFT Code])              [BIC]
         , CASE WHEN SH.[Language Code]='''' THEN CO.[Primary Language Code] ELSE SH.[Language Code] END [Language Code]
         , MAX(CASE WHEN CO.[Bank Country Code]<>'''' THEN 1 ELSE 0 END) SEPA
         , MAX(COALESCE(B1.[Description],''''))                        [Bank_1_Descrption]
         , MAX(COALESCE(B1.[Account],''''))                            [Bank_1_Account]
         , MAX(COALESCE(B1.[BLZ],''''))                                [Bank_1_BLZ]
         , MAX(COALESCE(B1.[Swift],''''))                              [Bank_1_Swift]
         , MAX(COALESCE(B1.[IBAN],''''))                               [Bank_1_IBAN]
         , MAX(COALESCE(CAST(B1.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_1_BankTxt]
         , MAX(COALESCE(B2.[Description],''''))                        [Bank_2_Descrption]
         , MAX(COALESCE(B2.[Account],''''))                            [Bank_2_Account]
         , MAX(COALESCE(B2.[BLZ],''''))                                [Bank_2_BLZ]
         , MAX(COALESCE(B2.[Swift],''''))                              [Bank_2_Swift]
         , MAX(COALESCE(B2.[IBAN],''''))                               [Bank_2_IBAN]
         , MAX(COALESCE(CAST(B2.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_2_BankTxt]
         , MAX(COALESCE(B3.[Description],'''') )                       [Bank_3_Descrption]
         , MAX(COALESCE(B3.[Account],''''))                            [Bank_3_Account]
         , MAX(COALESCE(B3.[BLZ],''''))                                [Bank_3_BLZ]
         , MAX(COALESCE(B3.[Swift],''''))                              [Bank_3_Swift]
         , MAX(COALESCE(B3.[IBAN],''''))                               [Bank_3_IBAN]
         , MAX(COALESCE(CAST(B3.[BankTxt] AS NVARCHAR(max)),''''))     [Bank_3_BankTxt]
         , SUM(SL.[Quantity])                                          [Quantity]
         , MAX(CU.[VAT Registration No_])                              [VAT Registration No_]
		 , SH.[Central Billing Fee Type]                               [Central Billing Fee Type]
		 , SH.[Order Type]											   [Order Type]
		 -- HRS003 >>
		 , SH.[Salesperson Code]
		 -- HRS003 <<'
	SET @SQLStatement = @SQLStatement + 
'
      FROM [' + @Company + '$Sales Header] AS SH WITH (READUNCOMMITTED)
      JOIN [' + @Company + '$Customer] AS CU WITH (READUNCOMMITTED) 
        ON SH.[Sell-to Customer No_] = CU.[No_]
      JOIN [' + @Company + '$Country_Region] AS CO WITH (READUNCOMMITTED) 
      -- // 04.01.18 SAL HRS001 >>
		--ON CASE WHEN SH.[Bill-to Country_Region Code] = ''0'' THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
		ON CASE WHEN SH.[Bill-to Country_Region Code] IN (''0'', '''') THEN ''33'' ELSE SH.[Bill-to Country_Region Code] END = CO.Code 
      -- // 04.01.18 SAL HRS001 <<
	  JOIN [' + @Company + '$Printer Group] AS SP WITH (READUNCOMMITTED) 
        ON SH.[Salesperson Code] = SP.Code 
      JOIN [' + @Company + '$Sales Line] AS SL WITH (READUNCOMMITTED) 
        ON SH.No_ = SL.[Document No_] 
 LEFT JOIN [' + @Company + '$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON SH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = SH.[Sell-to Customer No_]
 LEFT JOIN BANK B1 ON B1.[Sequences] = 0 AND B1.[Country Code] = SH.[Bill-to Country_Region Code]   
 LEFT JOIN BANK B2 ON B2.[Sequences] = 1 AND B2.[Country Code] = SH.[Bill-to Country_Region Code]
 LEFT JOIN BANK B3 ON B3.[Sequences] = 2 AND B3.[Country Code] = SH.[Bill-to Country_Region Code]
     WHERE (SH.No_ = ''' + @ReNr + ''')
'
	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,1,8000))
	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,8001,8000))
	PRINT (SUBSTRING(@SQLStatement+@SQLGroupBy  ,16001,8000))
	EXECUTE(@SQLStatement+@SQLGroupBy)  
	SELECT * FROM #RESULTS
END
GO
