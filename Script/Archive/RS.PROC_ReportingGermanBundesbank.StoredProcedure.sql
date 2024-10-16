USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_ReportingGermanBundesbank]    Script Date: 10.04.2024 14:31:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 15.03.2013
-- Description:	

-- 
/*
SET Language German
DECLARE   @UserId					VARCHAR(20)		= 'TMA04'
		, @CompanyName				VARCHAR(30)		= 'HRS'
		, @ReportId					INT				= 50037
EXEC [RS].[PROC_ReportingGermanBundesbank] @UserId, @CompanyName, @ReportId
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_ReportingGermanBundesbank] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German
	
DECLARE   @Stmt						VARCHAR(MAX) = '' 
		, @StmtCompanyName			VARCHAR(MAX) = ''
		, @Filter					VARCHAR(MAX) = ''
		, @TableIDs					[RS].[TableIDs]
		, @AliasIDs					[RS].[TableIDs]
		, @HRS						VARCHAR(20) = 'HRS'

--BEGIN Parameter aus RS-Execution
DECLARE   @DateStart					DATETIME
		, @DateEnd						DATETIME		
		
SET @DateStart = CONVERT(VARCHAR(10), COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 1), '01.01.1753'), 104);	
SET @DateEnd = CONVERT(VARCHAR(10), COALESCE(
	(SELECT [Filter Value]
	   FROM [RS-Report Execution]
 	  WHERE [Start Company] = @CompanyName
	    AND [UserID]	= @UserId
	    AND [Report ID] = @ReportId
	    AND [Table ID]  = 0
	    AND [Field ID]  = 2), '31.12.2999'), 104);
--END Parameter aus RS-Execution	

--BEGIN Rückgabetabelle
CREATE TABLE #RESULTS 
	( [1. Voucher type]						INT
	, [2. Code]								CHAR(3)
	, [3. Purpose of payments]				VARCHAR(140)
	, [4. Country code ]					CHAR(2)
	, [5. Amount]							DEC(38,0)
	, [6. ISIN]								VARCHAR(12)
	, [7. Quantity]							DEC(38,0)
	, [8. Issue currency]					VARCHAR(3)
	, [Von-No.]								VARCHAR(20)	
	, [Von-Name]							VARCHAR(130)	
	, [Nach-No.]							VARCHAR(20)	
	, [Nach-Name]							VARCHAR(130)	
	, [Country Code]						VARCHAR(10)
	, [Country Name]						VARCHAR(100)
	, [Entry No.]							INT
	, [Posting Date]						DATETIME
	, [Document No.]						VARCHAR(20)	
)

;WITH GLEMAX AS
(
SELECT GLE.[Entry No_], GLE.[Amount], GLE.[Transaction No_], GLE.[G_L Account No_], GLE.[Bal_ Account No_], GLE.[Posting Date], GLE.[Description]
  FROM DynNavHRS.dbo.[HRS$G_L Entry] GLE WITH (NOLOCK)
 WHERE [Posting Date] BETWEEN @DateStart AND @DateEnd
   AND ([Amount] > 12500 OR [Amount] < -12500)
   AND GLE.[G_L Account No_] BETWEEN '100000' AND '129300'
   AND NOT GLE.[Bal_ Account No_] BETWEEN '9999' AND '999999'
), _RESULT AS
(
   SELECT 1 [1. Voucher type]
        , RIGHT('000'+CAST(ROW_NUMBER() OVER(ORDER BY GLE.[Entry No_]) AS varchar(10)),3) [2. Code]
        , GLE.[Description] [3. Purpose of payments]
        , CR.[ISO Code] [4. Country code ]
        , GLE.Amount [5. Amount]
        , '' [6. ISIN]
        , 0.0 [7. Quantity]
        , '' [8. Issue currency]
        , GLE.[G_L Account No_]  [Von-No.]
        , GA.[Name]              [Von-Name]
        , GLE.[Bal_ Account No_] [Nach-No.]
        , CU.[Name]              [Nach-Name]
        , CR.Code                [Country Code]
        , CR.Name                [Country Name]
        , GLE.[Entry No_]        [Entry No.]
        , GLE.[Posting Date]     [Posting Date]
        , LE.[Document No_]      [Document No.]
     FROM GLEMAX GLE
     JOIN DynNavHRS.dbo.[HRS$G_L Account] GA
       ON GA.[No_] = GLE.[G_L Account No_]
     JOIN DynNavHRS.dbo.[HRS$Detailed Cust_ Ledg_ Entry] VLE WITH (NOLOCK)
       ON VLE.[Transaction No_] = GLE.[Transaction No_]
     JOIN DynNavHRS.dbo.[HRS$Cust_ Ledger Entry] LE WITH (NOLOCK)
       ON LE.[Entry No_] = VLE.[Cust_ Ledger Entry No_]
     JOIN DynNavHRS.dbo.[HRS$Customer] CU WITH (NOLOCK)
       ON CU.[No_] = LE.[Customer No_]
     JOIN DynNavHRS.dbo.[HRS$Country_Region] CR WITH (NOLOCK)
       ON CR.[Code] 
     = CASE WHEN LE.[Customer No_] = '900025' THEN
         CASE LOWER(GLE.[Description])
           WHEN 'marriott'       THEN '165'
           WHEN 'marriot'        THEN '165'
           WHEN 'interconti ihg' THEN '165'
           WHEN 'accor'          THEN '62'
           WHEN 'wps'            THEN '140'
           WHEN 'interconti six' THEN '62'
           WHEN 'wyndham'        THEN '165'
                                 ELSE '33'
         END
       ELSE
         CU.[Country_Region Code]  
       END
 WHERE VLE.[Entry Type] = 1
   AND LE.[Closed by Entry No_]<>0
UNION   
   SELECT CASE WHEN GLE.[Bal_ Account No_] BETWEEN '129000' AND '199500' THEN 
            CASE WHEN GLE.[Amount]<0 THEN 3 ELSE 4 END
          ELSE
            2
          END [1. Voucher type]
        , RIGHT('000'+CAST(ROW_NUMBER() OVER(ORDER BY GLE.[Entry No_]) AS varchar(10)),3) [2. Code]
        , GLE.[Description] [3. Purpose of payments]
        , CR.[ISO Code] [4. Country code ]
        , GLE.Amount [5. Amount]
        , '' [6. ISIN]
        , 0.0 [7. Quantity]
        , '' [8. Issue currency]
        , GLE.[G_L Account No_]
        , GA.[Name]        
        , GLE.[Bal_ Account No_]
        , GB.[Name]        
        , CR.Code [Country Code]
        , CR.Name [Country Name]
        , GLE.[Entry No_]
        , GLE.[Posting Date]
        , GLE.[Document No_]
     FROM DynNavHRS.dbo.[HRS$G_L Entry] GLE WITH (NOLOCK)
     JOIN GLEMAX GLM ON GLM.[Entry No_] = GLE.[Entry No_]
     JOIN DynNavHRS.dbo.[HRS$G_L Account] GA
       ON GA.[No_] = GLE.[G_L Account No_]
     JOIN DynNavHRS.dbo.[HRS$G_L Account] GB
       ON GB.[No_] = GLE.[Bal_ Account No_]
     JOIN DynNavHRS.dbo.[HRS$Country_Region] CR
       ON CR.[Code]
        = CASE GLE.[G_L Account No_]
            WHEN '103000' THEN '29'
            WHEN '103050' THEN '29'
            WHEN '103060' THEN '29'
            WHEN '120000' THEN '33'
            WHEN '120100' THEN '33'
            WHEN '123000' THEN '33'
            WHEN '124000' THEN '33'
            WHEN '125000' THEN '33'
            WHEN '126000' THEN '33'
            WHEN '127000' THEN '33'
            WHEN '127010' THEN '156'
            WHEN '127020' THEN '156'
            WHEN '127030' THEN '160'
            WHEN '127040' THEN '160'
            WHEN '127050' THEN '140'
            WHEN '127080' THEN '65'
            WHEN '127100' THEN '33'
            WHEN '127111' THEN '113'
            WHEN '127112' THEN '131'
            WHEN '127113' THEN '32'
            WHEN '127114' THEN '42'
            WHEN '127116' THEN '146'
            WHEN '127117' THEN '234'
            WHEN '127119' THEN '164'
            WHEN '127121' THEN '223'
            WHEN '127122' THEN '140'
            WHEN '127124' THEN '65'
            WHEN '127129' THEN '151'
            WHEN '127132' THEN '137'
            WHEN '127134' THEN '201'
            WHEN '127135' THEN '29'
            WHEN '127140' THEN '165'
            WHEN '127150' THEN '49'
            WHEN '127160' THEN '58'
            WHEN '127170' THEN '157'
            WHEN '127190' THEN '157'
            WHEN '128000' THEN '132'
            WHEN '128100' THEN '114'
            WHEN '128210' THEN '33'
            WHEN '128500' THEN '132'
            WHEN '128600' THEN '123'
            ELSE '99999'
          END
LEFT JOIN DynNavHRS.dbo.[HRS$Detailed Vendor Ledg_ Entry] VLE WITH (NOLOCK)
       ON VLE.[Transaction No_] = GLE.[Transaction No_]
LEFT JOIN DynNavHRS.dbo.[HRS$Detailed Cust_ Ledg_ Entry] CLE WITH (NOLOCK)
       ON CLE.[Transaction No_] = GLE.[Transaction No_]
    WHERE VLE.[Transaction No_] IS NULL
      AND CLE.[Transaction No_] IS NULL
UNION
 SELECT 2 [1. Voucher type]
        , RIGHT('000'+CAST(DENSE_RANK() OVER(ORDER BY GLE.[Entry No_]) AS varchar(10)),3) [2. Code]
        , VE.[Description] [3. Purpose of payments]
        , CR.[ISO Code] [4. Country code ]
        , GLE.Amount [5. Amount]
        , '' [6. ISIN]
        , 0.0 [7. Quantity]
        , '' [8. Issue currency]
        , GLE.[G_L Account No_]
        , GA.[Name]        
        , GLE.[Bal_ Account No_]
        , V.[Name]        
        , CR.Code [Country Code]
        , CR.Name [Country Name]
        , GLE.[Entry No_]
        , GLE.[Posting Date]
        , VE.[Document No_]
     FROM DynNavHRS.dbo.[HRS$G_L Entry] GLE WITH (NOLOCK)
     JOIN GLEMAX GLM ON GLM.[Entry No_] = GLE.[Entry No_]
     JOIN DynNavHRS.dbo.[HRS$G_L Account] GA
       ON GA.[No_] = GLE.[G_L Account No_]
     JOIN DynNavHRS.dbo.[HRS$Detailed Vendor Ledg_ Entry] VLE WITH (NOLOCK)
       ON VLE.[Transaction No_] = GLE.[Transaction No_]
      AND VLE.[Entry Type]      = 2
     JOIN DynNavHRS.dbo.[HRS$Vendor Ledger Entry] VE WITH (NOLOCK)
       ON VE.[Entry No_] = VLE.[Vendor Ledger Entry No_]
      AND VE.[Document Type] = 2
     JOIN DynNavHRS.dbo.[HRS$G_L Entry] PH WITH (NOLOCK)
       ON PH.[Document No_] = VE.[Document No_]
      AND PH.[Posting Date] = VE.[Posting Date]
     JOIN DynNavHRS.dbo.[HRS$Vendor] V WITH (NOLOCK)
       ON V.[No_] = VE.[Vendor No_]
     JOIN DynNavHRS.dbo.[HRS$Country_Region] CR
       ON CR.[Code] = V.[Country_Region Code]
    WHERE GLE.[Bal_ Account Type] = 2
      AND GLE.[Bal_ Account No_] <> ''
      AND VLE.Amount > 0
      AND PH.[G_L Account No_] BETWEEN '410000' AND '497100'
)
   INSERT INTO #RESULTS
   SELECT [1. Voucher type]
	    , RIGHT('000'+CAST(DENSE_RANK() OVER(ORDER BY [Entry No.]) AS varchar(10)),3) [2. Code]
	    , [3. Purpose of payments]
	    , [4. Country code ]
	    , [5. Amount]
	    , [6. ISIN]
	    , [7. Quantity]
	    , [8. Issue currency]
	    , [Von-No.]
	    , [Von-Name]
	    , [Nach-No.]
	    , [Nach-Name]
	    , [Country Code]
	    , [Country Name]
	    , [Entry No.]
	    , [Posting Date]
	    , [Document No.] 
     FROM _RESULT      
 ORDER BY [Entry No.]

SELECT * FROM #RESULTS

END

GO
