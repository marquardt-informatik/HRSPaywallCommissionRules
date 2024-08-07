USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPReminderLine_HI]    Script Date: 10.04.2024 14:31:51 ******/
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
DECLARE @ReNr varchar(20), @PosNr integer, @DestCurrency varchar(3), @CurrencyFactor decimal(38,20)
 SELECT @ReNr = '0033488', @PosNr = 10000, @DestCurrency = 'EUR', @CurrencyFactor = 1
EXEC [dbo].[sp_RPReminderLine_HI] @ReNr, @PosNr, @DestCurrency, @CurrencyFactor
*/
-- ============================================= 
create PROCEDURE [dbo].[sp_RPReminderLine_HI] 
    @ReNr varchar(25)
  , @PosNr integer
  , @DestCurrency varchar(3)
  , @DestCurrencyFactor decimal(38,20)
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @Currency varchar(3), @CurrencyFactor decimal(38,20)
   SELECT @Currency = CASE WHEN [Currency Code (Entry)]>'A' THEN [Currency Code (Entry)] ELSE 'EUR' END
     FROM [HRS Holidays$Issued Reminder Line] 
    WHERE [Reminder No_] = @ReNr
      AND [Line No_] = @PosNr
PRINT @Currency
SELECT [Reminder No_]
     , [Line No_]
     , [Type]
     , [Due Date]
     , [Document Type]
     , [Document No_]
     , CASE 
         WHEN [Original Amount] < 0 THEN 
           0 
         ELSE 
           CASE WHEN (@Currency <> @DestCurrency) OR @Currency='EUR' THEN
             [Original Amount] * @DestCurrencyFactor
           ELSE 
             [Original Amount (Curr)]
           END
       END [Invoice Amount]
     , CASE 
         WHEN [Document Type] = 2 THEN 
           CASE WHEN (@Currency <> @DestCurrency) OR @Currency='EUR' THEN 
             ([Original Amount]-[Remaining Amount]) * @DestCurrencyFactor
           ELSE 
             [Original Amount (Curr)]-[Remaining Amount (Curr)] 
           END               
         WHEN [Document Type] IN (0) OR [Original Amount] > 0 THEN 
           0
         ELSE 
           CASE WHEN (@Currency <> @DestCurrency) OR @Currency='EUR' THEN 
             -[Remaining Amount] * @DestCurrencyFactor
           ELSE 
             -[Remaining Amount (Curr)] 
           END               
       END [Payment(s) received]
     , Type
     , [Document Date]
     , @DestCurrency [Currency Code (Entry)]
     , [Amount] * @DestCurrencyFactor [Interest Amount]
  FROM [HRS Holidays$Issued Reminder Line] WITH (READUNCOMMITTED)
 WHERE ([Reminder No_] = @ReNr) AND ([Line No_] = @PosNr)
UNION
SELECT [Reminder No_]
     , [Line No_]
     , [Type]
     , [Due Date]
     , [Document Type]
     , [Document No_]
     , CASE 
         WHEN [Document Type] = 1 THEN 
           0 
         ELSE 
           CASE WHEN (@Currency <> @DestCurrency) OR @Currency='EUR' THEN
             [Original Amount] * @DestCurrencyFactor
           ELSE 
             [Original Amount (Curr)]
           END
       END [Invoice Amount]
     , CASE 
         WHEN [Document Type] IN (2) THEN 
           CASE WHEN (@Currency <> @DestCurrency) OR @Currency='EUR' THEN 
             ([Original Amount]-[Remaining Amount]) * @DestCurrencyFactor
           ELSE 
             [Original Amount (Curr)]-[Remaining Amount (Curr)] 
           END               
         WHEN [Document Type] IN (0) THEN 
           0
         ELSE 
           CASE WHEN (@Currency <> @DestCurrency) OR @Currency='EUR' THEN 
             -[Remaining Amount] * @DestCurrencyFactor
           ELSE 
             -[Remaining Amount (Curr)] 
           END               
       END [Payment(s) received]
     , Type
     , [Document Date]
     , @DestCurrency [Currency Code (Entry)]
     , [Amount] * @DestCurrencyFactor [Interest Amount]
  FROM [HRS Holidays$Reminder Line] WITH (READUNCOMMITTED)
 WHERE ([Reminder No_] = @ReNr) AND ([Line No_] = @PosNr)
ORDER BY 10, 1, 6
END




GO
