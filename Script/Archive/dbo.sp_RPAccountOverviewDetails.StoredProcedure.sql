USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPAccountOverviewDetails]    Script Date: 10.04.2024 14:31:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 
-- Description:	
/*
SET Language German
DECLARE   @ReNr VARCHAR(20)
 SELECT @ReNr  = '1328353000' -- 3-facher Wert
 SELECT @ReNr  = '1323418000' -- zu hoher Restbetrag
 SELECT @ReNr  = '1325275000' -- kein Betrag
 SELECT @ReNr  = 'M006424941'
EXEC [dbo].[sp_RPAccountOverviewDetails] @ReNr 
EXEC DynNavHRS.[dbo].[sp_RPAccountOverviewDetails] '3002054276'
*/

-- 15.02.18 DJU HRS001 ACS-136 Filter auf Debitorenposten Offen=TRUE auskommentiert
-- 21.12.18 DJU HRS002 ACS-1306 Weitere Rechnungstypen ergänzt
-- 28.12.18 SAL HRS003 ACS-1310 Fremdwährungsbeträge aus Mahnungszeilen ausweisen (RL.[Original Amount (Curr)], RL.[Remaining Amount (Curr)])
-- 03.03.20 DJU HRS004 ACS-2202 Enable execution from Pending Closure and Closure
-- 10.03.20 DJU HRS005 ACS-2202 Add Cr. Memos
-- 03.04.20 DJU HRS006 ACS-2202 Currency correction
-- ================================================
CREATE PROCEDURE [dbo].[sp_RPAccountOverviewDetails] 
(
	  @ReNr							VARCHAR(20)
) WITH RECOMPILE
AS BEGIN
-- HRS004 >>
-- get Document Type
DECLARE @DocumentType VARCHAR(20)

SELECT @DocumentType = RH.[Document Type]
  FROM [HRS$Reminder Header] RH
 WHERE RH.[No_] = @ReNr

IF @DocumentType IS NULL
	SELECT @DocumentType = RH.[Document Type]
	  FROM [HRS$Issued Reminder Header] RH
	 WHERE RH.[No_] = @ReNr

-- if Pending Closure or Closure get last Issue Reminder
IF @DocumentType = '20' OR @DocumentType = '21'  
BEGIN
   ;WITH RH AS
   (
     SELECT RH.[Customer No_]
          , RH.[Document Date]
          , RH.[Document Type]
       FROM [HRS$Issued Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
    UNION
     SELECT RH.[Customer No_]
          , RH.[Document Date]
          , RH.[Document Type]
       FROM [HRS$Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
   ), RH_MAX AS
   (
     SELECT RH.[Customer No_]
          , MAX(IH.[Document Date]) [Document Date]
       FROM RH
       JOIN [HRS$Issued Reminder Header] IH WITH (READUNCOMMITTED)
         ON IH.[Customer No_] = RH.[Customer No_]
      WHERE RH.[Document Date] > IH.[Document Date]
	    AND IH.[Document Type] <> '20'
		AND IH.[Document Type] <> '21'
		AND IH.[Document Type] <> '25'
		AND IH.[Document Type] <> '26'
   GROUP BY RH.[Customer No_]
   )
   -- set last Issue Reminder as new @ReNr
   SELECT TOP 1 @ReNr = RH.[No_]
     FROM [HRS$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN RH_MAX
       ON RH_MAX.[Customer No_] = RH.[Customer No_]
      AND RH_MAX.[Document Date] = RH.[Document Date]
	  ORDER BY RH.[No_] DESC
END
-- HRS004 <<

  DECLARE @CurrencyCode VARCHAR(10), @CurrencyFactor DECIMAL(38,20), @MaxDate datetime, @DocumentDate datetime
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS$Issued Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  IF @CurrencyCode IS NULL  
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS$Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr

IF @CurrencyFactor = 0 
  SET @CurrencyFactor = 1

PRINT @CurrencyCode
PRINT @CurrencyFactor

DECLARE @UserList VARCHAR(max)
 SELECT @UserList = ','
SELECT @UserList = @UserList + [User ID] + ',' FROM [HRS$User Setup]
PRINT @UserList

DECLARE @CustomerNo VARCHAR(20), @LanguageCode VARCHAR(10)
  ;WITH RH AS
  (
   SELECT RH.[Customer No_], RH.[Language Code], RH.[Posting Date]
     FROM [HRS$Reminder Header] RH
     JOIN [HRS$Customer] CU 
       ON CU.[No_]= RH.[Customer No_]
      --AND CU.[Contract Status] IN ('10','11')
    WHERE RH.[No_] = @ReNr
	  -- HRS004 >>
	  AND RH.[Document Type] = '16'
	  -- HRS004 <<
   UNION
   SELECT RH.[Customer No_], RH.[Language Code], RH.[Posting Date]
     FROM [HRS$Issued Reminder Header] RH
     JOIN [HRS$Customer] CU 
       ON CU.[No_]= RH.[Customer No_]
      --AND CU.[Contract Status] IN ('10','11')
    WHERE RH.[No_] = @ReNr
	  -- HRS004 >>
	  AND RH.[Document Type] = '16'
	  -- HRS004 <<
  )
  SELECT @CustomerNo = RH.[Customer No_] 
       , @LanguageCode = RH.[Language Code]
       , @MaxDate = RH.[Posting Date] --DATEADD(dd,-DATEPART(dd,RH.[Posting Date])-1,RH.[Posting Date])
       , @DocumentDate = RH.[Posting Date]
    FROM RH
  
  ;WITH RL AS 
  (
   SELECT RL.[Document No_]
        , RL.[Document Type]
        , RL.[Posting Date]
        , RL.[Document Date]
        , RL.Description
        , RL.[Original Amount (Curr)]
        , RL.[Remaining Amount (Curr)]
        , RL.[Original Amount]
        , RL.[Remaining Amount] 
        , RL.[Currency Code (Entry)]
        , CASE WHEN CLE.[Original Currency Factor]=0 THEN 1 ELSE CLE.[Original Currency Factor] END [Currency Rate]
     FROM [HRS$Reminder Header]      RH WITH (NOLOCK) 
     JOIN [HRS$Reminder Line]        RL WITH (NOLOCK) ON RH.[No_]        = RL.[Reminder No_] 
     JOIN [HRS$Cust_ Ledger Entry]  CLE WITH (NOLOCK) ON CLE.[Entry No_] = RL.[Entry No_]
    WHERE RH.[No_] = @ReNr 
    UNION
   SELECT RL.[Document No_]
        , RL.[Document Type]
        , RL.[Posting Date]
        , RL.[Document Date]
        , RL.Description
        , RL.[Original Amount (Curr)]
        , RL.[Remaining Amount (Curr)]
        , RL.[Original Amount]
        , RL.[Remaining Amount] 
        , RL.[Currency Code (Entry)]
        , CASE WHEN CLE.[Original Currency Factor]=0 THEN 1 ELSE CLE.[Original Currency Factor] END [Currency Rate]
     FROM [HRS$Issued Reminder Header] RH 
     JOIN [HRS$Issued Reminder Line] RL WITH (NOLOCK) ON RH.[No_]        = RL.[Reminder No_] 
     JOIN [HRS$Cust_ Ledger Entry]  CLE WITH (NOLOCK) ON CLE.[Entry No_] = RL.[Entry No_]
    WHERE RH.[No_] = @ReNr
  )
  , _BookingSums AS
  (
            SELECT CLE.[Reservierungsnr_]
                 , SUM(DLE.[Amount (LCY)]) [Amount (LCY)]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  0 THEN DLE.[Amount] ELSE 0 END,2)) AS [Unknown_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  1 THEN DLE.[Amount] ELSE 0 END,2)) AS [Initial Entry_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  2 THEN DLE.[Amount] ELSE 0 END,2)) AS [Application_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  2 THEN DLE.[Amount (LCY)] ELSE 0 END,2)) AS [Application_R (LCY)]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  3 THEN DLE.[Amount] ELSE 0 END,2)) AS [Unrealized Loss_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  4 THEN DLE.[Amount] ELSE 0 END,2)) AS [Unrealized Gain_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  5 THEN DLE.[Amount] ELSE 0 END,2)) AS [Realized Loss_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  6 THEN DLE.[Amount] ELSE 0 END,2)) AS [Realized Gain_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  7 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Discount_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  8 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Discount (VAT Excl.)_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] =  9 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Discount (VAT Adjustment)_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 10 THEN DLE.[Amount] ELSE 0 END,2)) AS [ppln. Rounding_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 11 THEN DLE.[Amount] ELSE 0 END,2)) AS [Correction of Remaining Amount_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 12 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Tolerance_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 13 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Discount Tolerance_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 14 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Tolerance (VAT Excl.)_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 15 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Tolerance (VAT Adjustment)_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 16 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Discount Tolerance (VAT Excl.)_Payment_R]
                 , SUM(ROUND(CASE WHEN DLE.[Entry Type] = 17 THEN DLE.[Amount] ELSE 0 END,2)) AS [Payment Discount Tolerance (VAT Adjustment)_Payment_R]
              FROM [HRS$Detailed Cust_ Ledg_ Entry] DLE WITH (NOLOCK)
              JOIN [HRS$Cust_ Ledger Entry]         CLE WITH (NOLOCK)  
                ON DLE.[Cust_ Ledger Entry No_]=CLE.[Entry No_]
			  JOIN [HRS$Customer]                   CU  WITH (NOLOCK)
			 	ON CU.[No_] = CLE.[Customer No_]
			  JOIN RL ON RL.[Document No_] = CLE.[Document No_]
             WHERE CU.[No_] = @CustomerNo
          GROUP BY CLE.[Reservierungsnr_]
  ), _InvoiceSums AS
  (
            SELECT CLE.[Document No_]
                 , CLE.[Document Type]
                 , CLE.[Currency Code]
                 , CLE.[Customer No_]
                 , SUM(DLE.[Amount (LCY)]) AS [Balance]
                 , SUM(CASE WHEN DLE.[Entry Type] =  0 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Unknown_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  1 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Initial Entry_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  2 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Application_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  3 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Unrealized Loss_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  4 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Unrealized Gain_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  5 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Realized Loss_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  6 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Realized Gain_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  7 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Discount_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  8 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Discount (VAT Excl.)_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] =  9 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Discount (VAT Adjustment)_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 10 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [ppln. Rounding_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 11 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Correction of Remaining Amount_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 12 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Tolerance_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 13 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Discount Tolerance_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 14 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Tolerance (VAT Excl.)_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 15 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Tolerance (VAT Adjustment)_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 16 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Discount Tolerance (VAT Excl.)_Payment_R]
                 , SUM(CASE WHEN DLE.[Entry Type] = 17 THEN DLE.[Amount (LCY)] ELSE 0 END) AS [Payment Discount Tolerance (VAT Adjustment)_Payment_R]
              FROM [HRS$Detailed Cust_ Ledg_ Entry] DLE WITH (NOLOCK)
              JOIN [HRS$Cust_ Ledger Entry]         CLE WITH (NOLOCK)  
                ON DLE.[Cust_ Ledger Entry No_]=CLE.[Entry No_]
			  JOIN [HRS$Customer]                   CU  WITH (NOLOCK)
			 	ON CU.[No_] = CLE.[Customer No_]													  
			  JOIN RL ON RL.[Document No_] = CLE.[Document No_]
             WHERE CU.[No_] = @CustomerNo
               --AND CLE.[Document Type] IN (2,3)
			   --HRS001 >>
               --AND CLE.[Open] = 1
			   --HRS001 <<
          GROUP BY CLE.[Document No_]
                 , CLE.[Document Type]
                 , CLE.[Currency Code]
                 , CLE.[Customer No_]
  ), ZZ AS
  (
           SELECT [Reservierungsnummer]
                , MAX(CustLedgConversationRate) CustLedgConversationRate 
                , MAX(ConversationRate) ConversationRate 
                , MAX([CustLedgValue (LCY)]) [CustLedgValue (LCY)]
                , SUM([NetCommissionPaymentCurrency]) [NetCommissionPaymentCurrency]
                , SUM(CASE WHEN ConversationRate=0 THEN 0 ELSE [NetCommissionPaymentCurrency]/ConversationRate END) [NetCommissionPayment]
                , SUM([Differenz]) [Differenz]
                , SUM([Differenz]*ConversationRate) [Differenz (MW)]
             FROM [HRS$CDG Import Zahlungszentralen] ZZ WITH (NOLOCK) 
            WHERE NOT (
                         COALESCE([Buch_ Description],'') LIKE '%/Cancellation%'           OR COALESCE([Action Code],'') = 'CXLD'
                      OR COALESCE([Buch_ Description],'') LIKE '%/NoShow%'                 OR COALESCE([Action Code],'') = 'NSHW'
                      OR COALESCE([Buch_ Description],'') LIKE '%/NON Commisionable Stay%' OR COALESCE([Action Code],'') = 'NETC' 
                      )
              AND NOT ','+ZZ.[User]+',' LIKE @UserList
         GROUP BY [Reservierungsnummer]
  ), _AgencyHeader AS
  (
            SELECT AH.[Posted Invoice No_] 
                 , AL.[MuseID]
                 , AL.[Reservation No_]
                 , MAX(AL.[Client Guestname 1])    AS [Guestname 1]
                 , MAX(AL.[Client Guestname 2])    AS [Guestname 2]
                 , MIN(AL.[Reservation Date from]) AS Arrival
                 , MAX(AL.[Reservation Date to])   AS Departure
                 , MAX(AL.[Booking Code])          AS Buchungscode
                 , MAX(AL.[Rate Type])             AS [Rate Typ]
                 , MAX(AL.[Rate Description])      AS [Rate Bezeichnung]
                 , SUM(ROUND(CASE WHEN ZZ.[Reservierungsnummer] IS NULL THEN AL.[Line Amount] ELSE 0 END,2))       AS [Amount of Debits]
                 , AH.[Currency Factor]
                 , SUM(ROUND(CASE WHEN ZZ.[Reservierungsnummer] IS NULL THEN AL.[Line Amount (LCY)] ELSE 0 END,2))       AS [Amount of Debits (LCY)]
              FROM [HRS$Agency Display Line]   AL WITH (NOLOCK)
              JOIN [HRS$Agency Display Header] AH WITH (NOLOCK)
                ON AH.[Case No_] = AL.[Display Case No_]
              JOIN [HRS$Customer]              CU WITH (NOLOCK)
                ON CU.[No_] = AH.[Bill-to Customer No_]
			  JOIN RL 
			    ON RL.[Document No_]  = AH.[Posted Invoice No_]
			   AND RL.[Document Type] = 2
         LEFT JOIN [HRS$CDG Import Zahlungszentralen] ZZ WITH (NOLOCK) 
                ON ZZ.[Reservierungsnummer] = AL.[Reservation No_]
               AND (
                      [Buch_ Description] LIKE '%/Cancellation%'           OR [Action Code] = 'CXLD'
                   OR [Buch_ Description] LIKE '%/NoShow%'                 OR [Action Code] = 'NSHW'
                   OR [Buch_ Description] LIKE '%/NON Commisionable Stay%' OR [Action Code] = 'NETC' 
                   )
               AND NOT ','+ZZ.[User]+',' LIKE @UserList
             WHERE CU.[No_] = @CustomerNo
               AND AL.Action<>3
          GROUP BY AH.[Posted Invoice No_] 
                 , AL.[MuseID]
                 , AL.[Reservation No_]
                 , AH.[Currency Factor]
  ), _Result AS
  (
     SELECT CLE.[Document No_]
          , CLE.[Document Type]
          , CASE WHEN CLE.[Currency Code]<>@CurrencyCode THEN @CurrencyCode ELSE CLE.[Currency Code] END [Currency Code]
          , AH.MuseID
          , AH.[Reservation No_]
          , AH.Buchungscode
          , AH.[Guestname 1]
          , AH.[Guestname 2]
          , AH.Arrival
          , AH.Departure
          , CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 19 ELSE 0 END AS VAT
          , COALESCE(AH.[Rate Bezeichnung],'') [Rate Bezeichnung]
            -- [Amount of Debits] -- Currency
          , ROUND(COALESCE(CASE WHEN CLE.[Currency Code]<>@CurrencyCode THEN AH.[Amount of Debits] / AH.[Currency Factor] * @CurrencyFactor ELSE AH.[Amount of Debits] END * CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 1.19 ELSE 1 END,0.0), 2) AS [Amount of Debits] -- Currency
            -- [Application_R]
		  -- HRS006 >>
          -- , COALESCE([BookingSums].[Application_R (LCY)],0.0)  * @CurrencyFactor AS [Application_R]
		  , COALESCE([BookingSums].[Application_R],0.0) AS [Application_R]
		  -- HRS006 <<
            -- [Difference]
          , (ROUND(COALESCE(CASE WHEN CLE.[Currency Code]<>@CurrencyCode THEN AH.[Amount of Debits] / AH.[Currency Factor] * @CurrencyFactor ELSE AH.[Amount of Debits] END * CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 1.19 ELSE 1 END,0.0), 2))
		  -- HRS006 >>
          -- - ([BookingSums].[Application_R (LCY)] * @CurrencyFactor) AS [Difference]
		  - COALESCE([BookingSums].[Application_R],0.0) AS [Difference]
		  -- HRS006 <<
            -- [Amount of Debits (LCY)] 
-- 20.07.15 auskommentiert          , ROUND(CASE WHEN ZZ.[Reservierungsnummer] IS NULL THEN AH.[Amount of Debits (LCY)] ELSE ZZ.[CustLedgValue (LCY)] * CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 1.19 ELSE 1 END END, 2) AS [Amount of Debits (LCY)]
          , ROUND(COALESCE(CASE WHEN CLE.[Currency Code]<>@CurrencyCode THEN AH.[Amount of Debits] / AH.[Currency Factor] ELSE AH.[Amount of Debits] END * CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 1.19 ELSE 1 END,0.0), 2) AS [Amount of Debits (LCY)] -- Currency
            -- [Application_R (LCY)]
          , COALESCE([BookingSums].[Application_R (LCY)],0.0)                                 AS [Application_R (LCY)]
            -- [Difference (LCY)]
          , ROUND(COALESCE(CASE WHEN CLE.[Currency Code]<>@CurrencyCode THEN AH.[Amount of Debits] / AH.[Currency Factor] ELSE AH.[Amount of Debits] END * CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 1.19 ELSE 1 END,0.0), 2)
          - COALESCE([BookingSums].[Application_R (LCY)],0)                     AS [Difference (LCY)]
       FROM [HRS$Cust_ Ledger Entry]                CLE WITH (NOLOCK)
       JOIN RL 
         ON RL.[Document No_]       = CLE.[Document No_]
        AND RL.[Document Type]      = CLE.[Document Type]   
       JOIN [HRS$Customer] CU WITH (NOLOCK)
         ON CLE.[Customer No_] = CU.[No_]
       JOIN [HRS$Sales Invoice Header]              SH  WITH (NOLOCK)
         ON CLE.[Document No_]      = SH.[No_] 
		AND CLE.[Document Type]     = 2 
        AND CLE.[Rg__Gs_-Art]       IN (0,1) --= 1
  LEFT JOIN _AgencyHeader AH
         ON CLE.[Document No_]      = AH.[Posted Invoice No_] 
        AND CLE.[Document Type]     = 2 
        AND CLE.[Rg__Gs_-Art]       IN (0,1) --= 1  
  LEFT JOIN _BookingSums [BookingSums] ON [BookingSums].[Reservierungsnr_] = AH.[Reservation No_] 
  LEFT JOIN _InvoiceSums [InvoiceSums] ON [InvoiceSums].[Document No_] = CLE.[Document No_] AND [InvoiceSums].[Document Type] = 2
  LEFT JOIN ZZ WITH (NOLOCK) 
         ON ZZ.[Reservierungsnummer] = AH.[Reservation No_]
    --AND NOT (
    --             COALESCE([Buch_ Description],'') LIKE '%/Cancellation%'           OR COALESCE([Action Code],'') = 'CXLD'
    --          OR COALESCE([Buch_ Description],'') LIKE '%/NoShow%'                 OR COALESCE([Action Code],'') = 'NSHW'
    --          OR COALESCE([Buch_ Description],'') LIKE '%/NON Commisionable Stay%' OR COALESCE([Action Code],'') = 'NETC' 
    --        )
    --AND NOT ','+ZZ.[User]+',' LIKE @UserList
      WHERE CLE.[Open]              = 1
        AND ((CLE.[Document Type] IN (2,3) AND CLE.[Posting Date] <= @MaxDate) OR NOT CLE.[Document Type] IN (2,3))
  ), _DistinctResult AS
  (
    SELECT DISTINCT * FROM _Result
  ), _ResultSum AS
  (
               SELECT [Document No_]
                    , [Document Type]
                    , SUM([Amount of Debits]) [Amount of Debits]
                    , SUM([Application_R])    [Application_R]
                    , SUM([Amount of Debits]) - SUM([Application_R]) [Difference]
                    , SUM([Amount of Debits (LCY)]) [Amount of Debits (LCY)]
                    , SUM([Application_R (LCY)])    [Application_R (LCY)]
                    , SUM([Difference (LCY)]) [Difference (LCY)]
                 FROM _Result
             GROUP BY [Document No_]
                    , [Document Type]
               HAVING ABS(SUM([Amount of Debits (LCY)]) - SUM([Application_R (LCY)])) > 0.09
  )
  --SELECT * FROM _ResultSum
--SELECT * FROM _Result WHERE [Document No_] = '10113057/01'
  --SELECT * FROM _AgencyHeader --_Result
     SELECT _Result.[Document No_]                    [Document No_]
          , _Result.[Document Type]                   [Document Type]
          , _Result.[Currency Code]                   [Currency Code]
          , _Result.[MuseID]                          [MuseID]
          , _Result.[Reservation No_]                 [Reservation No_]
          , _Result.[Buchungscode]                    [Buchungscode]
          , _Result.[Guestname 1]                     [Guestname 1]
          , _Result.[Guestname 2]                     [Guestname 2]
          , _Result.[Arrival]                         [Arrival]
          , _Result.[Departure]                       [Departure]
          , _Result.[VAT]                             [VAT]
          , _Result.[Rate Bezeichnung]                [Rate Bezeichnung]
          , _Result.[Amount of Debits]                [Amount of Debits]
		  -- HRS006 >>
          -- , _Result.[Application_R (LCY)] * @CurrencyFactor [Application_R]
		  , _Result.[Application_R]                   [Application_R]
		  -- HRS006 <<
          , _Result.[Amount of Debits]
		  -- HRS006 >>
		  -- - _Result.[Application_R (LCY)] * @CurrencyFactor [Difference]
		  - _Result.[Application_R]                   [Difference]
		  -- HRS006 <<
          , _Result.[Amount of Debits (LCY)]          [Amount of Debits (LCY)]
          , _Result.[Application_R (LCY)]             [Application_R (LCY)]
          , _Result.[Difference (LCY)]                [Difference (LCY)]
          , @LanguageCode                             [Language Code]
          , 'REGULAR'
          , RL.[Original Amount]                      [Original Amount]
          , RL.[Remaining Amount]                     [Remaining Amount]
		  , RL.[Original Amount (Curr)]  -- 28.12.18 SAL HRS003 >>
          , RL.[Remaining Amount (Curr)] 
		  , RL.[Currency Code (Entry)]   -- 28.12.18 SAL HRS003 <<
          , @CustomerNo                               [Customer No_]
       FROM _Result
       JOIN _ResultSum ON _ResultSum.[Document No_]  = _Result.[Document No_] AND _ResultSum.[Document Type] = _Result.[Document Type]
       JOIN RL ON RL.[Document No_]  = _Result.[Document No_] AND RL.[Document Type] = 2
      WHERE ABS(COALESCE(_Result.[Amount of Debits],0.0) - COALESCE(_Result.[Application_R],0.0))/@CurrencyFactor > 0.09
        AND ABS(_Result.[Amount of Debits] - _Result.[Application_R (LCY)] * @CurrencyFactor) > 0.09
     UNION
     SELECT [InvoiceSums].[Document No_]              [Document No_]
          , 11                                        [Document Type]
          , CASE WHEN [InvoiceSums].[Currency Code]<>@CurrencyCode THEN @CurrencyCode ELSE [InvoiceSums].[Currency Code] END [Currency Code]
          , AH.MuseID                                 [MuseID]
          , ''                                        [Reservation No_]
          , ''                                        [Buchungscode]
          , 'no matching'                             [Guestname 1]
          , ''                                        [Guestname 2]
          , SH.[Posting Date]                         [Arrival]
          , SH.[Posting Date]                         [Departure]
          , CASE WHEN SH.[VAT Bus_ Posting Group]='INLAND' THEN 19 ELSE 0 END AS VAT
          , ''                                        [Rate Bezeichnung]
          , 0                                                                     [Amount of Debits]
          , + (
                CASE WHEN RL.[Currency Code (Entry)] <> @CurrencyCode THEN
                    _ResultSum.[Difference] 
                  - RL.[Remaining Amount (Curr)] / RL.[Currency Rate] * @CurrencyFactor
                ELSE
                    _ResultSum.[Difference]
                  - RL.[Remaining Amount (Curr)]
                END
              )                                                                   [Application_R]
          , - (
                CASE WHEN RL.[Currency Code (Entry)] <> @CurrencyCode THEN
                    _ResultSum.[Difference] 
                  - RL.[Remaining Amount (Curr)] / RL.[Currency Rate] * @CurrencyFactor
                ELSE
                    _ResultSum.[Difference]
                  - RL.[Remaining Amount (Curr)]
                END
              )                                                                   [Difference]
          , 0                                                                     [Amount of Debits (LCY)]                
          , - (_ResultSum.[Difference (LCY)] - RL.[Remaining Amount])             [Application_R (LCY)]
          , + (_ResultSum.[Difference (LCY)] - RL.[Remaining Amount])             [Difference (LCY)]
          , @LanguageCode                                                         [Language Code]
          , 'NOMATCHING'
          , RL.[Original Amount]
          , RL.[Remaining Amount]
		  , RL.[Original Amount (Curr)]  -- 28.12.18 SAL HRS003 >>
          , RL.[Remaining Amount (Curr)] 
		  , RL.[Currency Code (Entry)]   -- 28.12.18 SAL HRS003 <<
          , @CustomerNo
       FROM _InvoiceSums [InvoiceSums]
       JOIN [HRS$Agency Display Header] AH WITH (NOLOCK)
         ON AH.[Posted Invoice No_]   = [InvoiceSums].[Document No_]
       JOIN [HRS$Sales Invoice Header]              SH  WITH (NOLOCK)
         ON SH.[No_]                  = [InvoiceSums].[Document No_]
       JOIN RL 
         ON RL.[Document No_]  = [InvoiceSums].[Document No_]
        AND RL.[Document Type] = 2
       JOIN _ResultSum
         ON _ResultSum.[Document No_] = [InvoiceSums].[Document No_]
      WHERE ABS(
                CASE WHEN RL.[Currency Code (Entry)] <> @CurrencyCode THEN
                    _ResultSum.[Difference] 
                  - RL.[Remaining Amount (Curr)] / RL.[Currency Rate] * @CurrencyFactor
                ELSE
                    _ResultSum.[Difference]
                  - RL.[Remaining Amount (Curr)]
                END
            )/@CurrencyFactor > 0.09
     UNION
     SELECT [InvoiceSums].[Document No_]
          , 2 -- komplett unbezahlte Rechnungen
          , DL.[Currency Code]
          , DL.[MuseID]
          , DL.[Reservation No_]
          , DL.[Booking Code]
          , DL.[Client Guestname 1]
          , DL.[Client Guestname 2]
          , DH.[Posting Date]
          , DH.[Creation Date]
          , CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 19 ELSE 0 END AS VAT
          , DL.[Rate Description]
          , DL.[Line Amount]
          , NULL
          , DL.[Line Amount]
          , DL.[Line Amount (LCY)] [Amount of Debits (LCY)]
          , NULL                   [Application_R (LCY)]
          , DL.[Line Amount (LCY)] [Difference (LCY)]
          , @LanguageCode [Language Code]
          , 'REGULAR'
          , RL.[Original Amount]
          , RL.[Remaining Amount]
		  , RL.[Original Amount (Curr)]  -- 28.12.18 SAL HRS003 >>
          , RL.[Remaining Amount (Curr)] 
		  , RL.[Currency Code (Entry)]   -- 28.12.18 SAL HRS003 <<
          , @CustomerNo
       FROM _InvoiceSums [InvoiceSums]
       JOIN [HRS$Customer]              CU WITH (NOLOCK) ON CU.[No_] = [InvoiceSums].[Customer No_]
       JOIN RL 
         ON RL.[Document No_]  = [InvoiceSums].[Document No_]
        AND RL.[Document Type] = 2
       JOIN [HRS$Sales Invoice Header]  SH WITH (NOLOCK) ON SH.[No_] = [InvoiceSums].[Document No_]
       JOIN [HRS$Agency Display Header] DH WITH (NOLOCK) ON DH.[Case No_] = SH.[Reason Code]
       JOIN [HRS$Agency Display Line]   DL WITH (NOLOCK) ON DH.[Case No_] = DL.[Display Case No_]
      WHERE NOT [InvoiceSums].[Document No_] IN (SELECT [Document No_] FROM _ResultSum)
        AND DL.[Action] <> 3
        AND [InvoiceSums].[Document Type] <> 1
        AND ABS(DL.[Line Amount]) > 0.09
        AND ABS([InvoiceSums].[Balance]) > 0.09

     UNION
     SELECT [InvoiceSums].[Document No_]
          , 1 -- Zahlungen
          , CASE WHEN [InvoiceSums].[Currency Code]<>@CurrencyCode THEN @CurrencyCode ELSE [InvoiceSums].[Currency Code] END [Currency Code]
          , ''
          , ''
          , ''
          , RL.[Description]
          , ''
          , RL.[Posting Date]
          , RL.[Document Date]
          , CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 19 ELSE 0 END AS VAT
          , ''
          , CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE RL.[Remaining Amount (Curr)] * @CurrencyFactor / RL.[Currency Rate] END
          , NULL
          , CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE RL.[Remaining Amount (Curr)] * @CurrencyFactor / RL.[Currency Rate] END
          , RL.[Original Amount]  [Amount of Debits (LCY)] 
          , NULL                  [Application_R (LCY)]
          , RL.[Remaining Amount] [Difference (LCY)]
          , @LanguageCode [Language Code]
          , 'PAYMENT'
          , RL.[Original Amount]
          , RL.[Remaining Amount]
		  , RL.[Original Amount (Curr)]  -- 28.12.18 SAL HRS003 >>
          , RL.[Remaining Amount (Curr)] 
		  , RL.[Currency Code (Entry)]   -- 28.12.18 SAL HRS003 <<
          , @CustomerNo
       FROM _InvoiceSums [InvoiceSums]
       JOIN [HRS$Customer] CU WITH (NOLOCK)
         ON CU.[No_] = [InvoiceSums].[Customer No_]
       JOIN RL 
         ON RL.[Document No_]  = [InvoiceSums].[Document No_]
        AND RL.[Document Type] = 1
      WHERE [InvoiceSums].[Document Type] = 1
     UNION
     SELECT [InvoiceSums].[Document No_]
          , 12 -- andere Rechnungen
          , CASE WHEN [InvoiceSums].[Currency Code]<>@CurrencyCode THEN @CurrencyCode ELSE [InvoiceSums].[Currency Code] END [Currency Code]
          , ''
          , ''
          , ''
          , RL.[Description]
          , ''
          , RL.[Posting Date]
          , RL.[Document Date]
          , CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 19 ELSE 0 END AS VAT
          , ''
		  -- HRS006 >>
          -- , RL.[Remaining Amount (Curr)] / RL.[Currency Rate] * @CurrencyFactor
		  , CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE RL.[Remaining Amount (Curr)] * @CurrencyFactor / RL.[Currency Rate] END
		  -- HRS006 <<
          , NULL
		  -- HRS006 >>
          -- , RL.[Remaining Amount (Curr)] / RL.[Currency Rate] * @CurrencyFactor
		  , CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE RL.[Remaining Amount (Curr)] * @CurrencyFactor / RL.[Currency Rate] END
		  -- HRS006 <<
          , RL.[Original Amount]  [Amount of Debits (LCY)]
          , NULL                  [Application_R (LCY)]
          , RL.[Remaining Amount] [Difference (LCY)]
          , @LanguageCode [Language Code]
		  -- HRS002 >>
          --, CASE LEFT([InvoiceSums].[Document No_],2) WHEN 'MA' THEN 'MARKETING' WHEN 'WB' THEN 'SUBSEQUENT' ELSE 'REGULAR' END [Category]
		  , CASE 
				WHEN LEFT([InvoiceSums].[Document No_],2) = 'MA' THEN 'MARKETING' 
				WHEN LEFT([InvoiceSums].[Document No_],2) = 'WB' THEN 'SUBSEQUENT' 
				WHEN SIH.[Order Type] = 4 THEN 'SUBSEQUENT' -- Marketplace Fee
				WHEN SIH.[Order Type] = 5 THEN 'SUBSEQUENT' -- Sourcing Fee
				WHEN SIH.[Order Type] = 7 THEN 'SUBSEQUENT' -- TAF
				ELSE 'REGULAR' 
			END [Category]
		  -- HRS002 <<
          , RL.[Original Amount]
          , RL.[Remaining Amount]
		  , RL.[Original Amount (Curr)]  -- 28.12.18 SAL HRS003 >>
          , RL.[Remaining Amount (Curr)] 
		  , RL.[Currency Code (Entry)]   -- 28.12.18 SAL HRS003 <<
          , @CustomerNo
       FROM _InvoiceSums [InvoiceSums]
       JOIN [HRS$Customer] CU WITH (NOLOCK)
         ON CU.[No_] = [InvoiceSums].[Customer No_]
       JOIN RL 
         ON RL.[Document No_]  = [InvoiceSums].[Document No_]
        AND RL.[Document Type] = [InvoiceSums].[Document Type]
		-- HRS002 >>
  LEFT JOIN [HRS$Sales Invoice Header] SIH WITH (NOLOCK)
         ON [InvoiceSums].[Document No_] = SIH.No_
		-- HRS002 <<
      WHERE NOT [InvoiceSums].[Document No_] IN (SELECT [Document No_] FROM _ResultSum)
        AND [InvoiceSums].[Document Type] = 2
	 -- HRS005 >>
     UNION
     SELECT [InvoiceSums].[Document No_]
          , 3 -- Gutschriften
          , CASE WHEN [InvoiceSums].[Currency Code]<>@CurrencyCode THEN @CurrencyCode ELSE [InvoiceSums].[Currency Code] END [Currency Code]
          , ''
          , ''
          , ''
          , RL.[Description]
          , ''
          , RL.[Posting Date]
          , RL.[Document Date]
          , CASE WHEN CU.[VAT Bus_ Posting Group]='INLAND' THEN 19 ELSE 0 END AS VAT
          , ''
          , CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE RL.[Remaining Amount (Curr)] * @CurrencyFactor / RL.[Currency Rate] END
          , NULL
          , CASE WHEN @CurrencyCode = RL.[Currency Code (Entry)] THEN RL.[Remaining Amount (Curr)] ELSE RL.[Remaining Amount (Curr)] * @CurrencyFactor / RL.[Currency Rate] END
          , RL.[Original Amount]  [Amount of Debits (LCY)] 
          , NULL                  [Application_R (LCY)]
          , RL.[Remaining Amount] [Difference (LCY)]
          , @LanguageCode [Language Code]
          , 'CRMEMO'
          , RL.[Original Amount]
          , RL.[Remaining Amount]
		  , RL.[Original Amount (Curr)]  -- 28.12.18 SAL HRS003 >>
          , RL.[Remaining Amount (Curr)] 
		  , RL.[Currency Code (Entry)]   -- 28.12.18 SAL HRS003 <<
          , @CustomerNo
       FROM _InvoiceSums [InvoiceSums]
       JOIN [HRS$Customer] CU WITH (NOLOCK)
         ON CU.[No_] = [InvoiceSums].[Customer No_]
       JOIN RL 
         ON RL.[Document No_]  = [InvoiceSums].[Document No_]
        AND RL.[Document Type] = 3
      WHERE [InvoiceSums].[Document Type] = 3
	 -- HRS005 <<
ORDER BY 1,2,5
END
GO
