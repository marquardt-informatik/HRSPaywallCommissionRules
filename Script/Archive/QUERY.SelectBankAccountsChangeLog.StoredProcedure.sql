USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [QUERY].[SelectBankAccountsChangeLog]    Script Date: 10.04.2024 14:31:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [QUERY].[SelectBankAccountsChangeLog]
AS
BEGIN
;WITH Q AS ( SELECT Q.* FROM (VALUES('6009','CORE'),('16065','CORE'),('22766','CORE'),('31614','CORE'),('40806','CORE'),('41000','CORE'),('44429','CORE'),('50717','CORE'),('50719','CORE'),('50720','CORE'),('60336','CORE'),('60410','CORE'),('62394','CORE'),('62587','CORE'),('70323','CORE'),('82287','CORE'),('84258','CORE'),('154753','CORE'),('217489','CORE'),('386806','CORE'),('399652','CORE'),('413755','CORE'),('414347','CORE'),('451936','CORE'),('540019','CORE'),('574303','CORE'),('582323','CORE'),('642427','CORE'),('1008758','CORE'))Q([Customer No_],[Code]))


SELECT * FROM [HRS$Change Log Entry] 
  JOIN Q 
    ON [Primary Key Field 1 Value]=Q.[Customer No_]
   AND [Primary Key Field 2 Value]=Q.Code
 WHERE [Table No_]=287
   AND (
       [Field No_] = 5157894 -- Mandatsreferenz
    OR [Field No_] = 5157895 -- Mandatsdatum
    OR [Field No_] = 5157902 --Zuletzt benutzt
       )
   AND [Date and Time]>='2021-01-01'
ORDER BY [Primary Key Field 1 Value]
       , [Primary Key Field 2 Value]
       , [Entry No_] DESC
END
GO
