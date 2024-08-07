USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectNAV2027_Payment]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectNAV2027_Payment]
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
    CREATE TABLE #CE ([Entry No_] int primary key,[Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Original Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Document Type] int,[Customer No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Due Date] datetime,[Remaining Amount (LCY)] DECIMAL(38, 20));
    INSERT INTO #CE ([Entry No_], [Document No_], [Original Document No_], [Document Type],[Customer No_],[Due Date],[Remaining Amount (LCY)])
    SELECT CE.[Entry No_]
         , CASE WHEN CHARINDEX('/',CE.[Document No_])>0 THEN LEFT(CE.[Document No_], CHARINDEX('/',CE.[Document No_])-1) ELSE CE.[Document No_] END [Document No_]
         , CE.[Document No_] [Original Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , CE.[Due Date]
         , SUM(DE.[Amount (LCY)]) [Remaining Amount (LCY)]
      FROM DynNavHRS.dbo.[HRS Payment$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN DynNavHRS.dbo.[HRS Payment$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE CE.[Open]=1
  GROUP BY CE.[Entry No_]
         , CE.[Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , CE.[Due Date]
END

;WITH BP AS
(
    SELECT BP_KEY [Process No_]
         , MAX(B_KEY) [Reservation No_]
      FROM HRSDB.BUCHUNG WITH (NOLOCK)
  GROUP BY BP_KEY
), IL AS -- TAF Invoices
(
    SELECT CE.*
         , IL.[Line No_] [Process No_]
         , IL.[Amount]*IH.[Currency Factor] [Amount (LCY)]
      FROM #CE CE
      JOIN DynNavHRS.dbo.[HRS Payment$Sales Invoice Line] IL WITH (NOLOCK) ON IL.[Document No_]=CE.[Original Document No_] AND CE.[Document Type]=2
      JOIN DynNavHRS.dbo.[HRS Payment$Sales Invoice Header] IH WITH (NOLOCK) ON IL.[Document No_]=IH.[No_]
), CE AS
(
   SELECT CASE WHEN ISNUMERIC([Document No_])>0 AND LEN([Document No_])<10  THEN CAST([Document No_] as int) ELSE 999999999 END [Process No_]
        , [Document No_]
        , DT.[String] [Document Type]
        , CE.[Customer No_]
        , CU.[Payment Terms Code]
        , CE.[Due Date]
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
     JOIN DynNavHRS.dbo.[HRS Payment$Customer] CU ON CU.[No_]=CE.[Customer No_]
     JOIN DynNavHRS.dbo.[HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
     JOIN dbo.Split(' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund',',') DT ON DT.[Index]-1=CE.[Document Type]
    WHERE NOT CE.[Original Document No_] IN (SELECT [Original Document No_] FROM IL)
UNION
   SELECT CE.[Process No_]
        , CE.[Document No_]
        , DT.[String] [Document Type]
        , CE.[Customer No_]
        , CU.[Payment Terms Code]
        , CE.[Due Date]
        , CR.[Name] [Country Name]
        , CASE 
            WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 30 THEN '0-30'
            WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 60 THEN '30-60'
            WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 90 THEN '60-90'
            ELSE '90+'
          END [Bucket]
        , null [Agency Amount (LCY)]
        , CE.[Amount (LCY)] [TAF Amount (LCY)]
        , CE.[Amount (LCY)] [Amount (LCY)]
        , null [Paid Amount (LCY)]
        , CE.[Amount (LCY)]     
     FROM IL CE
     JOIN DynNavHRS.dbo.[HRS Payment$Customer] CU ON CU.[No_]=CE.[Customer No_]
     JOIN DynNavHRS.dbo.[HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
     JOIN dbo.Split(' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund',',') DT ON DT.[Index]-1=CE.[Document Type]
)
   SELECT COALESCE(BP.[Reservation No_],999999999) [Reservation No_]
        , CE.[Document No_]
        , CE.[Document Type]
        , CE.[Customer No_]
        , BU.KE_BID [Chain Code]
        , BU.KE_ID [Brand Code]
        , BU.MUSE_ID [MuseID]
        , CE.[Due Date]
        , CE.[Payment Terms Code]
        , CE.[Country Name]
        , CE.Bucket
        , CE.[Agency Amount (LCY)]
        , CE.[TAF Amount (LCY)]
        , CE.[Amount (LCY)]
        , CE.[Paid Amount (LCY)]
        , CE.[Remaining Amount (LCY)]
     FROM CE
LEFT JOIN BP ON CE.[Process No_]=BP.[Process No_]
LEFT JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY=BP.[Reservation No_]
END
GO
