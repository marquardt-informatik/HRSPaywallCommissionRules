USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectNAV2027]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SelectNAV2027]
   @LimitFrom int = 1
 , @LimitTo int = 1000000
AS
BEGIN
DECLARE @RecreateRE int=0, @RecreateCE int=0, @RecreateRES int=0
IF OBJECT_ID('tempdb..#RE') IS NOT NULL
BEGIN
    IF @RecreateRE = 1
    BEGIN
        DROP TABLE #RE;
    END
END

IF OBJECT_ID('tempdb..#RE') IS NULL -- 11 seconds
BEGIN
    CREATE TABLE #RE ([Reservation No_] VARCHAR(20) COLLATE Latin1_General_CS_AS PRIMARY KEY,[Initial Amount (LCY)] DECIMAL(38, 20));
    INSERT INTO #RE ([Reservation No_],[Initial Amount (LCY)])
    SELECT CE.Reservierungsnr_ [Reservation No_]
         , SUM(DE.[Amount (LCY)]) [Initial Amount(LCY)]
      FROM [HRS$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN [HRS$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE 1=1--CE.[Document Date]<'2023-08-31'
       AND CE.[Document Date]>'2020-12-31'
       AND CE.Reservierungsnr_>0
       AND DE.[Entry Type]=1
--       AND DE.[Customer No_]='678'
  GROUP BY CE.Reservierungsnr_
    HAVING SUM(DE.[Amount (LCY)])<>0
END


IF OBJECT_ID('tempdb..#CE') IS NOT NULL
BEGIN
    IF @RecreateCE = 1
    BEGIN
        DROP TABLE #CE;
    END
END
IF OBJECT_ID('tempdb..#CE') IS NULL -- 1m22
BEGIN
    CREATE TABLE #CE ([Entry No_] int primary key,[Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Customer No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Document Type] int
    , [Due Date] datetime, [Reservation No_] int, [Initial Amount (LCY)] DECIMAL(38, 20), [Remaining Amount (LCY)] DECIMAL(38, 20));
    INSERT INTO #CE ([Entry No_],[Document No_],[Customer No_],[Document Type],[Due Date],[Reservation No_],[Initial Amount (LCY)],[Remaining Amount (LCY)])
    SELECT CE.[Entry No_]
         , CE.[Document No_]
         , CE.[Customer No_]
         , CE.[Document Type]
         , CE.[Due Date]
         , CASE WHEN CE.[Reservierungsnr_]=0 THEN 999999999 ELSE CE.[Reservierungsnr_] END [Reservation No_]
         , SUM(CASE WHEN DE.[Entry Type]=1 THEN DE.[Amount (LCY)] ELSE 0 END) [Initial Amount(LCY)]
         , SUM(DE.[Amount (LCY)]) [Remaining Amount (LCY)]
      FROM [HRS$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN [HRS$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE CE.[Open]=1
       --AND DE.[Document Type]=2
       --AND DE.[Customer No_]='678'
  GROUP BY CE.[Entry No_]
         , CE.[Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , CE.[Due Date]
         , CASE WHEN CE.[Reservierungsnr_]=0 THEN 999999999 ELSE CE.[Reservierungsnr_] END
       --AND DE.[Entry Type]=1
END

IF OBJECT_ID('tempdb..#RES') IS NOT NULL
BEGIN
    IF @RecreateRES = 1
    BEGIN
        DROP TABLE #RES;
    END
END
IF OBJECT_ID('tempdb..#RES') IS NULL -- 1m19
BEGIN
CREATE TABLE #RES ([Reservation No_] int,[Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Document Type] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Customer No_] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Chain Code] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Brand Code] VARCHAR(20) COLLATE Latin1_General_CS_AS, [MuseID] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Due Date] datetime, [Payment Terms Code] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Country Name] VARCHAR(100) COLLATE Latin1_General_CS_AS, [Bucket] VARCHAR(10) COLLATE Latin1_General_CS_AS, [Agency Amount (LCY)] decimal(38,20), [TAF Amount (LCY)] decimal(38,20), [Amount (LCY)] decimal(38,20), [Paid Amount (LCY)] decimal(38,20), [Remaining Amount (LCY)] decimal(38,20));
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
     JOIN [HRS$Agency Display Header] DH WITH (NOLOCK) ON DH.[Posted Invoice No_]=CE.[Document No_]
     JOIN [HRS$Agency Display Line] DL WITH (NOLOCK) ON DH.[Case No_]=DL.[Display Case No_]
    WHERE DL.[Action]<>3
      AND CE.[Document Type]=2
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
), _SU AS
(
   SELECT DL.[Reservation No_]
        , CASE WHEN CHARINDEX('/',DL.[Document No_])>0 THEN LEFT(DL.[Document No_],CHARINDEX('/',DL.[Document No_])-1) ELSE DL.[Document No_] END [Document No_]
        , 2 [Document Type]
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
        , RE.[Initial Amount (LCY)] [Paid Amount (LCY)]
        , DL.[Amount (LCY)] + COALESCE(RE.[Initial Amount (LCY)],0) [Remaining Amount (LCY)]
     FROM DL
LEFT JOIN #RE RE ON RE.[Reservation No_]=DL.[Reservation No_]
     JOIN [HRS$Sales Invoice Header] IH WITH (NOLOCK) ON IH.[No_]=DL.[Document No_]
     JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=IH.[Sell-to Country_Region Code]
    WHERE DL.[Amount (LCY)]+COALESCE(RE.[Initial Amount (LCY)],0)>0
UNION
   SELECT CE.[Reservation No_]
        , CASE WHEN CHARINDEX('/',CE.[Document No_])>0 THEN LEFT(CE.[Document No_],CHARINDEX('/',CE.[Document No_])-1) ELSE CE.[Document No_] END [Document No_]
        , CE.[Document Type]
        , CE.[Customer No_]
        , CU.Chain [Chain Code]
        , CU.Brand [Brand Code]
        , null [MuseID]
        , CE.[Due Date]
        , CU.[Payment Terms Code] [Payment Terms Code]
        , CR.[Name] [Country Name]
        , CASE 
            WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 30 THEN '0-30'
            WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 60 THEN '30-60'
            WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 90 THEN '60-90'
            ELSE '90+'
          END [Bucket]
        , null [Agency Amount (LCY)]
        , null [TAF Amount (LCY)]
        , null [Amount (LCY)]
        , null [Paid Amount (LCY)]
        , CE.[Remaining Amount (LCY)]
     FROM #CE CE
     JOIN [HRS$Customer] CU WITH (NOLOCK) ON CU.[No_]=CE.[Customer No_]
     JOIN [HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
    --WHERE CE.[Initial Amount (LCY)] - CE.[Remaining Amount (LCY)]<>0
), SU AS
(
SELECT * 
     , ROW_NUMBER() OVER (ORDER BY _SU.[Customer No_], _SU.[Document No_], _SU.[Reservation No_]) [Row No_]
  FROM _SU
)
INSERT INTO #RES
SELECT SU.[Reservation No_]
     , SU.[Document No_]
     , DT.[String] [Document Type]
     , SU.[Customer No_]
     , SU.[Chain Code]
     , SU.[Brand Code]
     , SU.[MuseID]
     , SU.[Due Date]
     , SU.[Payment Terms Code]
     , SU.[Country Name]
     , SU.[Bucket]
     , SU.[Agency Amount (LCY)]
     , SU.[TAF Amount (LCY)]
     , SU.[Amount (LCY)]
     , SU.[Paid Amount (LCY)]
     , SU.[Remaining Amount (LCY)]
  FROM SU
  JOIN dbo.Split(' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund',',') DT ON DT.[Index]-1=SU.[Document Type]
 --WHERE SU.[Row No_] BETWEEN @LimitFrom AND @LimitTo
ORDER BY SU.[Customer No_], SU.[Document No_], SU.[Reservation No_]

  ;WITH RES AS
  (
    SELECT R.[Document No_]
         , SUM(R.[Remaining Amount (LCY)]) [Remaining Amount (LCY)]
      FROM #RES R
     WHERE R.[Reservation No_]<>999999999
       AND R.[Document Type]='Invoice'
  GROUP BY R.[Document No_]
  )
  UPDATE R SET R.[Remaining Amount (LCY)] = R.[Remaining Amount (LCY)]- RES.[Remaining Amount (LCY)]
    FROM #RES R
    JOIN RES ON RES.[Document No_]=R.[Document No_]
     WHERE R.[Reservation No_]=999999999
       AND R.[Document Type]='Invoice'

  DELETE FROM #RES WHERE [Remaining Amount (LCY)]=0

END


;WITH SU AS
(
SELECT * 
     , ROW_NUMBER() OVER (ORDER BY _SU.[Customer No_], _SU.[Document No_], _SU.[Reservation No_]) [Row No_]
  FROM #RES _SU
)
SELECT SU.[Reservation No_]
     , SU.[Document No_]
     , SU.[Document Type]
     , SU.[Customer No_]
     , SU.[Chain Code]
     , SU.[Brand Code]
     , SU.[MuseID]
     , SU.[Due Date]
     , SU.[Payment Terms Code]
     , SU.[Country Name]
     , SU.[Bucket]
     , SU.[Agency Amount (LCY)]
     , SU.[TAF Amount (LCY)]
     , SU.[Amount (LCY)]
     , SU.[Paid Amount (LCY)]
     , SU.[Remaining Amount (LCY)]
  FROM SU
 WHERE SU.[Row No_] BETWEEN @LimitFrom AND @LimitTo
END
GO
