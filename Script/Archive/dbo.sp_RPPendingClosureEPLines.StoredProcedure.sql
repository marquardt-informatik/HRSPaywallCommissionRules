USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPPendingClosureEPLines]    Script Date: 10.04.2024 14:31:51 ******/
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
-- 13.01.15 HRS001    XXXX   ZD     Adding [Remaining Amount (Curr)]  Column in PendingClosureEP report (Based on Yvonne Request)
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'M004448364'
EXEC [dbo].[sp_RPPendingClosureEPLines] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPPendingClosureEPLines] 
    @ReNr varchar(25)
AS
BEGIN
  SET NOCOUNT ON;
   SELECT RL.[Reminder No_]
        , RL.[Line No_]
        , RL.[Document No_]
        , RL.[Due Date]
        , RL.Amount
        , RL.[Original Amount]
		, RL.[Original Amount (Curr)]
        , RL.[Remaining Amount]
        , RL.[Remaining Amount (Curr)]     -- HRS001
        , RL.[Document Date]
        , RL.[Document Type]
        , CASE  
            WHEN RL.[Document Type] = 0                                  THEN ''
            WHEN RL.[Document Type] = 1                                  THEN 'DTPayment'
            WHEN DH.[Document Type] = '15'                               THEN 'DTSubsequentDebitInvoice'
            WHEN NOT DH.[Case No_] IS NULL AND DH.[Document Type] = '10' THEN 'DTCommissionInvoice'
            WHEN NOT DH.[Case No_] IS NULL AND DH.[Document Type] = '11' THEN 'DTBookingOverview'
            WHEN NOT SH.[No_]      IS NULL AND SH.[Debit Coll_]=1        THEN 'DTCollectionCost'
            WHEN NOT SH.[No_]      IS NULL AND SH.[Order Type]=2         THEN 'DTRefundInvoice'
            WHEN NOT SH.[No_]      IS NULL AND SH.[Marketing Invoice]=1  THEN 'DTMarketingInvoice'
            WHEN RL.[Document Type] = 2                                  THEN 'Invoice'
            WHEN RL.[Document Type] = 3                                  THEN 'DTCreditMemo'
            WHEN RL.[Document Type] = 4                                  THEN 'Finance Charge Memo'
            WHEN RL.[Document Type] = 5                                  THEN 'DTIssuedReminder'
            WHEN RL.[Document Type] = 6                                  THEN 'Refund'
          END [Document Type Code]
        , RL.[Description]
        , RL.[Currency Code (Entry)]
     FROM [HRS$Issued Reminder Line]  RL WITH (READUNCOMMITTED)
LEFT JOIN [HRS$Sales Invoice Header]  SH WITH (READUNCOMMITTED)
       ON SH.[No_]                  = RL.[Document No_]
      AND RL.[Document Type]        = 2
LEFT JOIN [HRS$Agency Display Header] DH
       ON DH.[Posted Invoice No_]   = RL.[Document No_]
   WHERE ([Reminder No_] = @ReNr) AND 
         (Type = 2 OR Type = 3)
UNION         
   SELECT RL.[Reminder No_]
        , RL.[Line No_]
        , RL.[Document No_]
        , RL.[Due Date]
        , RL.Amount
        , RL.[Original Amount]
		, RL.[Original Amount (Curr)]
        , RL.[Remaining Amount]
        , RL.[Remaining Amount (Curr)]     -- HRS001
        , RL.[Document Date]
        , RL.[Document Type]
        , CASE  
            WHEN RL.[Document Type] = 0                                  THEN ''
            WHEN RL.[Document Type] = 1                                  THEN 'DTPayment'
            WHEN DH.[Document Type] = '15'                               THEN 'DTSubsequentDebitInvoice'
            WHEN NOT DH.[Case No_] IS NULL AND DH.[Document Type] = '10' THEN 'DTCommissionInvoice'
            WHEN NOT DH.[Case No_] IS NULL AND DH.[Document Type] = '11' THEN 'DTBookingOverview'
            WHEN NOT SH.[No_]      IS NULL AND SH.[Debit Coll_]=1        THEN 'DTCollectionCost'
            WHEN NOT SH.[No_]      IS NULL AND SH.[Order Type]=2         THEN 'DTRefundInvoice'
            WHEN NOT SH.[No_]      IS NULL AND SH.[Marketing Invoice]=1  THEN 'DTMarketingInvoice'
            WHEN RL.[Document Type] = 2                                  THEN 'Invoice'
            WHEN RL.[Document Type] = 3                                  THEN 'DTCreditMemo'
            WHEN RL.[Document Type] = 4                                  THEN 'Finance Charge Memo'
            WHEN RL.[Document Type] = 5                                  THEN 'DTIssuedReminder'
            WHEN RL.[Document Type] = 6                                  THEN 'Refund'
          END [Document Type Code]
        , RL.[Description]
        , RL.[Currency Code (Entry)]
     FROM [HRS$Reminder Line]         RL WITH (READUNCOMMITTED)
LEFT JOIN [HRS$Sales Invoice Header]  SH WITH (READUNCOMMITTED)
       ON SH.[No_]                  = RL.[Document No_]
      AND RL.[Document Type]        = 2
LEFT JOIN [HRS$Agency Display Header] DH WITH (READUNCOMMITTED)
       ON DH.[Posted Invoice No_]   = RL.[Document No_]
   WHERE ([Reminder No_] = @ReNr) AND 
         (Type = 2 OR Type = 3)
ORDER BY 8
       , 1
       , 9
       , 3
END

GO
