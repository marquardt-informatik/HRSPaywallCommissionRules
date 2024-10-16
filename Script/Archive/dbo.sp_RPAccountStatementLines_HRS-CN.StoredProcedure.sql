USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPAccountStatementLines_HRS-CN]    Script Date: 10.04.2024 14:31:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.07.2012
-- Description:	Mahnungszeilen
-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'CN1000302251'
EXEC [dbo].[sp_RPAccountStatementLines_HRS-CN] @ReNr
EXEC [dbo].[sp_RPReminderHeader_HRS-CN] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPAccountStatementLines_HRS-CN] 
    @ReNr varchar(25)
AS
BEGIN
  DECLARE @CurrencyCode VARCHAR(10), @CurrencyFactor DECIMAL(38,20)
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS-CN$Issued Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr
  IF @CurrencyCode IS NULL  
   SELECT @CurrencyCode = [Currency Code], @CurrencyFactor = [Currency Factor] FROM [HRS-CN$Reminder Header] WITH (READUNCOMMITTED) WHERE [No_] = @ReNr

  DECLARE @Result TABLE 
  (
      [Reminder No_]           varchar(20)
	, [Line No_]               int
	, [Document Date]          date
	, [Document Type]          varchar(250)
	, [Document Description]   varchar(100)
	, [Document No_]           varchar(20)
	, [Currency Code (Entry)]  varchar(10)
	, [Amount]                 decimal(38,20)
	, [Original Amount]        decimal(38,20)
	, [Remaining Amount]       decimal(38,20)
	, [Due Date]               date
	, [Fapiao]                 tinyint
	, [Booking Overview]       tinyint
    , [Payment]                tinyint
	, [Action]                 varchar(250)
  )
  SET NOCOUNT ON;
  WITH RL AS
  (
   SELECT [Reminder No_]
        , [Line No_]
        , RL.[Document Date]
	    , CASE 
		    WHEN RL.[Document Type]              = 1   THEN 'txtPayment'            
		    WHEN COALESCE(DH.[Document Type],'') = '9' THEN 'txtFapiao' 
			                                           ELSE 'txtBookingOverview' 
		  END [Document Type]
 	    , CASE WHEN COALESCE(DH.[Document Type],'') = '9' THEN CL.[Description] ELSE '' END [Document Description]
        , RL.[Document No_]
	    , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyCode ELSE RL.[Currency Code (Entry)] END [Currency Code (Entry)]
        , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyFactor * Amount ELSE RL.Amount END Amount
        , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyFactor * [Original Amount (Curr)] ELSE [Original Amount (Curr)] END [Original Amount]
        , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyFactor * [Remaining Amount (Curr)] ELSE [Remaining Amount (Curr)] END [Remaining Amount]
        , CASE WHEN RL.[Document Type] = 1 THEN NULL ELSE DATEADD(dd,14,RL.[Due Date]) END [Due Date]
        , CASE WHEN COALESCE(DH.[Document Type],'') = '9' THEN 1 ELSE 0 END [Fapiao]
        , CASE WHEN COALESCE(DH.[Document Type],'') = '9' THEN 0 ELSE 1 END [Booking Overview]
		, CASE WHEN RL.[Document Type]              = 1   THEN 1 ELSE 0 END [Payment]
	    , CASE 
	        WHEN COALESCE(DH.[Document Type],'') = '9' AND RL.Amount = 0 THEN 'txtNotYetDue'
	        WHEN COALESCE(DH.[Document Type],'') = '9' AND RL.Amount > 0 THEN 'txtdueForPayment'
			WHEN RL.[Document Type]              = 1                     THEN 'txtEmpty'
	 	                                                                 ELSE 'txtConfirmationMissing'
		  END [Action]
     FROM [HRS-CN$Issued Reminder Line] RL WITH (READUNCOMMITTED)
	 JOIN [HRS-CN$Cust_ Ledger Entry] CL WITH (NOLOCK)
	   ON CL.[Entry No_] = RL.[Entry No_]
LEFT JOIN [HRS-CN$Agency Display Header] DH WITH (READUNCOMMITTED)
	   ON DH.[Posted Invoice No_] = RL.[Document No_]
	  AND Type = 2
    WHERE [Reminder No_] = @ReNr
UNION         
   SELECT [Reminder No_]
        , [Line No_]
        , RL.[Document Date]
	    , CASE 
		    WHEN RL.[Document Type]              = 1   THEN 'txtPayment'            
		    WHEN COALESCE(DH.[Document Type],'') = '9' THEN 'txtFapiao' 
			                                           ELSE 'txtBookingOverview' 
		  END [Document Type]
 	    , CASE WHEN COALESCE(DH.[Document Type],'') = '9' THEN CL.[Description] ELSE '' END [Document Description]
        , RL.[Document No_]
	    , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyCode ELSE RL.[Currency Code (Entry)] END [Currency Code (Entry)]
        , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyFactor * Amount ELSE RL.Amount END Amount
        , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyFactor * [Original Amount (Curr)] ELSE [Original Amount (Curr)] END [Original Amount]
        , CASE WHEN RL.[Currency Code (Entry)] = 'EUR' THEN @CurrencyFactor * [Remaining Amount (Curr)] ELSE [Remaining Amount (Curr)] END [Remaining Amount]
        , CASE WHEN RL.[Document Type] = 1 THEN NULL ELSE DATEADD(dd,14,RL.[Posting Date]) END [Due Date]
        , CASE WHEN COALESCE(DH.[Document Type],'') = '9' THEN 1 ELSE 0 END [Fapiao]
        , CASE WHEN COALESCE(DH.[Document Type],'') = '9' THEN 0 ELSE 1 END [Booking Overview]
		, CASE WHEN RL.[Document Type]              = 1   THEN 1 ELSE 0 END [Payment]
	    , CASE 
	        WHEN COALESCE(DH.[Document Type],'') = '9' AND RL.Amount = 0 THEN 'txtNotYetDue'
	        WHEN COALESCE(DH.[Document Type],'') = '9' AND RL.Amount > 0 THEN 'txtdueForPayment'
			WHEN RL.[Document Type]              = 1                     THEN 'txtEmpty'
	 	                                                                 ELSE 'txtConfirmationMissing'
		  END [Action]
     FROM [HRS-CN$Reminder Line] RL WITH (READUNCOMMITTED)
	 JOIN [HRS-CN$Cust_ Ledger Entry] CL WITH (NOLOCK)
	   ON CL.[Entry No_] = RL.[Entry No_]
LEFT JOIN [HRS-CN$Agency Display Header] DH WITH (READUNCOMMITTED)
	   ON DH.[Posted Invoice No_] = RL.[Document No_]
	  AND Type = 2
   WHERE [Reminder No_] = @ReNr
UNION 
   SELECT @ReNr [Reminder No_]
        , 999999999 [Line No_]
		, MAX(CL.[Document Date]) [Document Date]
		, 'txtFapiao' [Document Type]
		, MAX(CL.[Description]) [Document Description]
		, MAX(CL.[Document No_]) [Document No_]
		, MAX(CL.[Currency Code]) [Currency Code]
		, 0 [Amount]
		, SUM(CASE WHEN LE.[Entry Type]=0 THEN LE.[Amount] ELSE 0 END) [Original Amount]
		, SUM(LE.[Amount]) [Remaining Amount] 
		, MAX(DATEADD(dd,14,CL.[Posting Date])) [Due Date]
		, 1 [Fapiao]
		, 0 [Booking Overview]
		, 0 [Payment]
		, 'txtNotYetDue' [Action]
     FROM [HRS-CN$Issued Reminder Header] RH WITH (NOLOCK)
	 JOIN [HRS-CN$Cust_ Ledger Entry] CL WITH (NOLOCK)
	   ON CL.[Customer No_] = RH.[Customer No_]
	  AND CL.[Open] = 1
	  AND CL.[Document Type] = 2
	 JOIN [HRS-CN$Detailed Cust_ Ledg_ Entry] LE WITH (NOLOCK)
	   ON CL.[Entry No_] = LE.[Cust_ Ledger Entry No_]
LEFT JOIN [HRS-CN$Issued Reminder Line] RL WITH (READUNCOMMITTED)
       ON RL.[Reminder No_] = RH.[No_]
	  AND RL.[Document No_] = CL.[Document No_]
	WHERE RL.[Reminder No_] IS NULL
	  AND RH.[No_] = @ReNr
UNION
   SELECT @ReNr [Reminder No_]
        , -999999999 [Line No_]
		, MAX(CL.[Document Date]) [Document Date]
		, 'txtFapiao' [Document Type]
		, MAX(CL.[Description]) [Document Description]
		, MAX(CL.[Document No_]) [Document No_]
		, MAX(CL.[Currency Code]) [Currency Code]
		, 0 [Amount]
		, SUM(CASE WHEN LE.[Entry Type]=1 THEN LE.[Amount] ELSE 0 END) [Original Amount]
		, SUM(LE.[Amount]) [Remaining Amount] 
		, MAX(DATEADD(dd,14,CL.[Posting Date])) [Due Date]
		, 1 [Fapiao]
		, 0 [Booking Overview]
		, 0 [Payment]
		, 'txtNotYetDue' [Action]
     FROM [HRS-CN$Reminder Header] RH WITH (NOLOCK)
	 JOIN [HRS-CN$Cust_ Ledger Entry] CL WITH (NOLOCK)
	   ON CL.[Customer No_] = RH.[Customer No_]
	  AND CL.[Open] = 1
	  AND CL.[Document Type] = 2
	 JOIN [HRS-CN$Detailed Cust_ Ledg_ Entry] LE WITH (NOLOCK)
	   ON CL.[Entry No_] = LE.[Cust_ Ledger Entry No_]
LEFT JOIN [HRS-CN$Reminder Line] RL WITH (READUNCOMMITTED)
       ON RL.[Reminder No_] = RH.[No_]
	  AND RL.[Document No_] = CL.[Document No_]
	WHERE RL.[Reminder No_] IS NULL
	  AND RH.[No_] = @ReNr
) 
INSERT INTO @Result
SELECT *
  FROM RL
 WHERE NOT RL.[Document No_] IS NULL
ORDER BY 8
       , 1
       , 9
       , 3

UPDATE R SET R.[Booking Overview] = 1-(SELECT MAX([Fapiao]) FROM @Result WHERE [Payment] = 0)
  FROM @Result R
 WHERE [Payment] = 1

UPDATE R SET R.[Fapiao] = (SELECT MAX([Fapiao]) FROM @Result WHERE [Payment] = 0)
  FROM @Result R
 WHERE [Payment] = 1

UPDATE R SET 
       R.[Amount]           = [dbo].[CurrencyExchange]([Currency Code (Entry)],'CNY',[Amount]          ,[Document Date])
     , R.[Original Amount]  = [dbo].[CurrencyExchange]([Currency Code (Entry)],'CNY',[Original Amount] ,[Document Date])
     , R.[Remaining Amount] = [dbo].[CurrencyExchange]([Currency Code (Entry)],'CNY',[Remaining Amount],[Document Date])
	 , R.[Currency Code (Entry)] = 'CNY'
  FROM @Result R
 WHERE [Currency Code (Entry)] <> 'CNY'
   AND [Payment] = 1

  SELECT * FROM @Result ORDER BY [Line No_]
END
GO
