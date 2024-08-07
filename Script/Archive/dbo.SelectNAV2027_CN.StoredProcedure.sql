USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectNAV2027_CN]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectNAV2027_CN]
AS
BEGIN

DECLARE @RecreateRE int=0, @RecreateCE int=0
IF OBJECT_ID('tempdb..#CE') IS NOT NULL
BEGIN
    IF @RecreateCE = 1
    BEGIN
        DROP TABLE #CE;
    END
END
IF OBJECT_ID('tempdb..#CE') IS NULL
BEGIN
    CREATE TABLE #CE ([Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS PRIMARY KEY,[Initial Amount (LCY)] DECIMAL(38, 20));
    INSERT INTO #CE ([Document No_],[Initial Amount (LCY)])
    SELECT CE.[Document No_]
         , DE.[Amount (LCY)] [Initial Amount(LCY)]
      FROM [HRS-CN$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN [HRS-CN$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE CE.[Open]=1
       AND CE.[Document Date]<'2023-08-31'
       AND DE.[Document Type]=2
       AND DE.[Entry Type]=1
END

;WITH _DL AS
(
   SELECT DL.[Reservation No_]
        , CE.[Document No_]
        , DH.[Chain Code]
        , DH.[Brand Code]
        , DH.[MuseID]
        , SUM(DL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
        , SUM(DL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
        , SUM(DL.[Agency Line Amount (LCY)]+DL.[TAF Line Amount (LCY)]) [Amount (LCY)]
     FROM #CE CE
     JOIN [HRS-CN$Agency Display Header] DH WITH (NOLOCK) ON DH.[Posted Invoice No_]=CE.[Document No_]
     JOIN [HRS-CN$Agency Display Line] DL WITH (NOLOCK) ON DH.[Case No_]=DL.[Display Case No_]
    WHERE DL.[Action]<>3
 GROUP BY DL.[Reservation No_]
        , CE.[Document No_]
        , DH.[Chain Code]
        , DH.[Brand Code]
        , DH.[MuseID]
), DL AS
(
   SELECT _DL.*
        , ROW_NUMBER() OVER(ORDER BY _DL.[Reservation No_]) [Order No_]
     FROM _DL
)
   SELECT DL.[Reservation No_]
        , DL.[Document No_]
        , IH.[Sell-to Customer No_] [Customer No_]
        , DL.[Chain Code]
        , DL.[Brand Code]
        , DL.[MuseID]
        , IH.[Due Date]
        , IH.[Payment Terms Code]
        , CR.[Name] [Country Name]
        , CASE 
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 30 THEN '0-30'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 60 THEN '30-60'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 90 THEN '60-90'
            ELSE '90+'
          END [Bucket]
        , DL.[Agency Amount (LCY)]
        , DL.[TAF Amount (LCY)]
        , DL.[Amount (LCY)]
     FROM DL
     JOIN [HRS-CN$Sales Invoice Header] IH WITH (NOLOCK) ON IH.[No_]=DL.[Document No_]
     JOIN [HRS-CN$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=IH.[Sell-to Country_Region Code]
     WHERE DL.[Amount (LCY)]>0
 ORDER BY DL.[Reservation No_]
END
GO
