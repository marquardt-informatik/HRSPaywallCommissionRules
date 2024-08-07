USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BI].[InsertPAYOutstandingsPayment]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI].[InsertPAYOutstandingsPayment]
AS
BEGIN
DECLARE @Classification varchar(20)='PAY', @LegalEntity varchar(50)='HRS Pay GmbH', @Bucket varchar(10)='uninvoiced'
      , @ProductTypeMULTISOURCE varchar(20)='Multisource'
      , @ProductTypeSOURCING varchar(20)='Sourcing'
      , @ProductTypeUNALLOCATED varchar(20)='Unallocated'
      , @ProductTypeOther varchar(20)='Other'

   DELETE FROM BI
     FROM BI.Outstandings BI
    WHERE BI.[Legal Entity]=@LegalEntity
      AND BI.[Classification] IN (@Classification)

DECLARE @RecreateRE int=1, @RecreateCE int=1, @RecreateRES int=1
IF OBJECT_ID('tempdb..#CE') IS NOT NULL
BEGIN
    IF @RecreateCE = 1
    BEGIN
        DROP TABLE #CE;
    END
END
IF OBJECT_ID('tempdb..#CE') IS NULL
BEGIN
    CREATE TABLE #CE ([Entry No_] int primary key,[Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Original Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Document Type] int
    ,[Customer No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Due Date] datetime,[Remaining Amount (LCY)] DECIMAL(38, 20)
    , [Salesperson Code] VARCHAR(10) COLLATE Latin1_General_CS_AS, [Payment Method Code] VARCHAR(10) COLLATE Latin1_General_CS_AS
    );
    INSERT INTO #CE ([Entry No_], [Document No_], [Original Document No_], [Document Type],[Customer No_],[Due Date],[Remaining Amount (LCY)],[Salesperson Code],[Payment Method Code])
    SELECT CE.[Entry No_]
         , CASE WHEN CHARINDEX('/',CE.[Document No_])>0 THEN LEFT(CE.[Document No_], CHARINDEX('/',CE.[Document No_])-1) ELSE CE.[Document No_] END [Document No_]
         , CE.[Document No_] [Original Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , CE.[Due Date]
         , SUM(DE.[Amount (LCY)]) [Remaining Amount (LCY)]
         , MAX(CE.[Payment Method Code]) [Payment Method Code]
         , MAX(CE.[Salesperson Code]) [Salesperson Code]
      FROM DynNavHRS.dbo.[HRS Payment$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN DynNavHRS.dbo.[HRS Payment$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE CE.[Open]=1
  GROUP BY CE.[Entry No_]
         , CE.[Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , CE.[Due Date]
END

IF OBJECT_ID('tempdb..#RES') IS NOT NULL
BEGIN
    IF @RecreateRES = 1
    BEGIN
        DROP TABLE #RES;
    END
END
IF OBJECT_ID('tempdb..#RES') IS NULL
BEGIN
    CREATE TABLE #RES ([Classification] varchar(20) COLLATE Latin1_General_CS_AS, [Reservation No_] int, [Document No_] varchar(20) COLLATE Latin1_General_CS_AS
    , [Document Type] varchar(20) COLLATE Latin1_General_CS_AS, [Customer No_] varchar(20) COLLATE Latin1_General_CS_AS, [Chain Code] varchar(20) COLLATE Latin1_General_CS_AS
    , [Brand Code] varchar(20) COLLATE Latin1_General_CS_AS, [MuseID] varchar(20) COLLATE Latin1_General_CS_AS, [Due Date] datetime, [Payment Terms Code] varchar(100) COLLATE Latin1_General_CS_AS
    , [Country Name] varchar(100) COLLATE Latin1_General_CS_AS, Bucket varchar(10), [Agency Amount (LCY)] DECIMAL(38,20), [TAF Amount (LCY)] DECIMAL(38,20), [Amount (LCY)] DECIMAL(38,20)
    , [Paid Amount (LCY)] DECIMAL(38,20), [Remaining Amount (LCY)] DECIMAL(38,20),[Legal Entity] varchar(50) COLLATE Latin1_General_CS_AS
    , [Salesperson Code] VARCHAR(10) COLLATE Latin1_General_CS_AS, [Payment Method Code] VARCHAR(10) COLLATE Latin1_General_CS_AS
    )

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
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 1 THEN 'not due'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 31 THEN '1-30'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 61 THEN '31-60'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 91 THEN '61-90'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 181 THEN '91-180'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 361 THEN '181-360'
             ELSE '361+'
           END [Bucket]
         , null [Agency Amount (LCY)]
         , null [TAF Amount (LCY)]
         , null [Amount (LCY)]
         , null [Paid Amount (LCY)]
         , CE.[Remaining Amount (LCY)]
         , CE.[Payment Method Code]
         , CE.[Salesperson Code]
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
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 1 THEN 'not due'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 31 THEN '1-30'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 61 THEN '31-60'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 91 THEN '61-90'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 181 THEN '91-180'
             WHEN DATEDIFF(dd,CE.[Due Date],GETDATE()) < 361 THEN '181-360'
             ELSE '361+'
           END [Bucket]
         , null [Agency Amount (LCY)]
         , CE.[Amount (LCY)] [TAF Amount (LCY)]
         , CE.[Amount (LCY)] [Amount (LCY)]
         , null [Paid Amount (LCY)]
         , CE.[Amount (LCY)]     
         , CE.[Payment Method Code]
         , CE.[Salesperson Code]
      FROM IL CE
      JOIN DynNavHRS.dbo.[HRS Payment$Customer] CU ON CU.[No_]=CE.[Customer No_]
      JOIN DynNavHRS.dbo.[HRS Payment$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
      JOIN dbo.Split(' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund',',') DT ON DT.[Index]-1=CE.[Document Type]
)
   INSERT INTO #RES ([Classification], [Reservation No_], [Document No_], [Document Type], [Customer No_], [Chain Code], [Brand Code], [MuseID], [Due Date], [Payment Terms Code], [Country Name]
   , Bucket, [Agency Amount (LCY)], [TAF Amount (LCY)], [Amount (LCY)], [Paid Amount (LCY)], [Remaining Amount (LCY)],[Legal Entity]
    ,[Payment Method Code],[Salesperson Code]
   )
    SELECT @Classification
         , COALESCE(BP.[Reservation No_],999999999) [Reservation No_]
         , CE.[Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , null [Chain Code]
         , null [Brand Code]
         , null [MuseID]
         , CE.[Due Date]
         , CE.[Payment Terms Code]
         , CE.[Country Name]
         , CE.Bucket
         , SUM(COALESCE(CE.[Agency Amount (LCY)],0))
         , SUM(COALESCE(CE.[TAF Amount (LCY)],0))
         , SUM(COALESCE(CE.[Amount (LCY)],0))
         , SUM(COALESCE(CE.[Paid Amount (LCY)],0))
         , SUM(COALESCE(CE.[Remaining Amount (LCY)],0))
         , @LegalEntity
         , MAX(CE.[Payment Method Code]) [Payment Method Code]
         , MAX(CE.[Salesperson Code]) [Salesperson Code]
      FROM CE
 LEFT JOIN BP ON CE.[Process No_]=BP.[Process No_]
 LEFT JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY=BP.[Reservation No_]
  GROUP BY COALESCE(BP.[Reservation No_],999999999) 
         , CE.[Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , BU.KE_BID 
         , BU.KE_ID 
         , BU.MUSE_ID 
         , CE.[Due Date]
         , CE.[Payment Terms Code]
         , CE.[Country Name]
         , CE.Bucket
END

    INSERT INTO BI.Outstandings ([Classification],[Reservation No_],[Document No_],[Document Type],[Customer No_],[Chain Code],[Brand Code],[MuseID],[Due Date],[Payment Terms Code],[Country Name]
    ,[Bucket],[Agency Amount (LCY)],[TAF Amount (LCY)],[Amount (LCY)],[Paid Amount (LCY)],[Remaining Amount (LCY)],[Legal Entity],[Inserted at],[Product type],[Document Date]
    ,[Days after Document Date],[Company No_]
    ,[Payment Method Code],[Salesperson Code]
   )
   SELECT SU.Classification
        , SU.[Reservation No_]
        , SU.[Document No_]
        , SU.[Document Type]
        , SU.[Customer No_]
        , SU.[Chain Code]
        , SU.[Brand Code]
        , SU.[MuseID]
        , SU.[Due Date]
        , PT.[Description] [Payment Terms Code]
        , SU.[Country Name]
        , SU.[Bucket]
        , SU.[Agency Amount (LCY)]
        , SU.[TAF Amount (LCY)]
        , SU.[Amount (LCY)]
        , SU.[Paid Amount (LCY)]
        , SU.[Remaining Amount (LCY)]
        , SU.[Legal Entity]
        , GETDATE()
        , '' [Product type]
        , SU.[Due Date] [Document Date]
        , DATEDIFF(dd,SU.[Due Date],GETDATE()) [Days after Document Date]
        , BU.K_KEY [Company No_]
        , SU.[Payment Terms Code]
        , SU.[Salesperson Code]
     FROM #RES SU
LEFT JOIN BI.Outstandings BI ON BI.[Classification]=@Classification AND BI.[Reservation No_]=SU.[Reservation No_] AND BI.[Customer No_]=SU.[Customer No_] AND BI.[Legal Entity]=@LegalEntity AND SU.[Document Type]=BI.[Document Type] AND SU.[Due Date]=BI.[Due Date]
LEFT JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY=SU.[Reservation No_]
LEFT JOIN [HRS Payment$Payment Terms] PT WITH (NOLOCK) ON PT.[Code]=SU.[Payment Terms Code]
    WHERE BI.[Reservation No_] IS NULL

   DELETE FROM BI
     FROM BI.Outstandings BI
LEFT JOIN #RES SU ON BI.[Classification]=@Classification AND BI.[Reservation No_]=SU.[Reservation No_] AND BI.[Customer No_]=SU.[Customer No_] AND BI.[Legal Entity]=@LegalEntity AND SU.[Document Type]=BI.[Document Type] AND SU.[Due Date]=BI.[Due Date]
    WHERE SU.[Reservation No_] IS NULL
      AND BI.[Legal Entity]=@LegalEntity
      AND BI.[Classification]=@Classification

-- Uninvoiced MEETAGO
      DELETE FROM [BI].[Outstandings] WHERE [Classification]=@Classification AND [Bucket]=@Bucket AND [Legal Entity]=@LegalEntity

;WITH BP AS
(
    SELECT BP_KEY [Process No_]
         , MAX(B_KEY) [Reservation No_]
      FROM HRSDB.BUCHUNG WITH (NOLOCK)
  GROUP BY BP_KEY
)
    INSERT INTO [BI].[Outstandings] ([Classification],[Reservation No_],[Document No_],[Document Type],[Customer No_],[Chain Code],[Brand Code],[MuseID],[Due Date],[Payment Terms Code],[Country Name]
    ,[Bucket],[Agency Amount (LCY)],[TAF Amount (LCY)],[Amount (LCY)],[Paid Amount (LCY)],[Remaining Amount (LCY)],[Legal Entity],[Inserted at],[Modified at],[Product type],[HQ Customer No_]
    ,[Document Date],[Days after Document Date],[Company No_]
    ,[Payment Method Code],[Salesperson Code]
   )
   SELECT @Classification [Classification]
        , COALESCE(BP.[Reservation No_],999999999) [Reservation No_]
        , II.[Invoice GUID] [Document No_]
        , 'Invoice' [Document Type]
        , COALESCE(NULLIF(VA.[Customer No_],0),999999999) [Customer No_]
        , null [Chain Code]
        , null [Brand Code]
        , null [MuseID]
        , II.[Invoice Date] [Due Date]
        , PT.[Description] [Payment Terms Code]
        , COALESCE(CR.[Name],COALESCE(CRP.[Name],'')) [Country Name]
        , @Bucket [Bucket]
        , null [Agency Amount (LCY)]
        , null [TAF Amount (LCY)]
        , II.[Amount (LCY)]
        , null [Paid Amount (LCY)]
        , II.[Amount (LCY)] [Remaining Amount (LCY)]
        , @LegalEntity [Legal Entoty]
        , GETDATE() [Inserted at]
        , null [Modified at]
        , '' [Product type]
        , null [HQ Customer No_]
        , null [Document Date]
        , DATEDIFF(dd,II.[Invoice Date],GETDATE()) [Days after Document Date]
        , II.[Company No_]
        , CU.[Payment Terms Code]
        , CU.[Salesperson Code]
     FROM [Itelya Invoice] II
LEFT JOIN BP ON BP.[Process No_]=II.[Process No_]
LEFT JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY=BP.[Reservation No_]
LEFT JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] VA ON VA.[Company No_]=II.[Company No_]
LEFT JOIN [HRS Payment$Customer] CU ON VA.[Customer No_]=CU.[No_]
LEFT JOIN [HRS Payment$Country_Region] CR ON CR.[Code]=CU.[Country_Region Code]
LEFT JOIN [Affiliate Partner] AP ON AP.[No_]=II.[Company No_]
LEFT JOIN [HRS Payment$Country_Region] CRP ON CRP.[Code]=AP.[Country Code]
LEFT JOIN [HRS Payment$Payment Terms] PT WITH (NOLOCK) ON PT.[Code]=CU.[Payment Terms Code]
    WHERE [Payment Type]=15
      AND [CentralPay]=0
      AND [Posted]=0

-- Uninvoiced TRANSIENT
;WITH BP AS
(
    SELECT BP_KEY [Process No_]
         , MAX(B_KEY) [Reservation No_]
      FROM HRSDB.BUCHUNG WITH (NOLOCK)
  GROUP BY BP_KEY
)
    INSERT INTO [BI].[Outstandings] ([Classification],[Reservation No_],[Document No_],[Document Type],[Customer No_],[Chain Code],[Brand Code],[MuseID],[Due Date],[Payment Terms Code],[Country Name]
    ,[Bucket],[Agency Amount (LCY)],[TAF Amount (LCY)],[Amount (LCY)],[Paid Amount (LCY)],[Remaining Amount (LCY)],[Legal Entity],[Inserted at],[Modified at],[Product type],[HQ Customer No_]
    ,[Document Date],[Days after Document Date],[Company No_]
    ,[Payment Method Code],[Salesperson Code]
    )
    SELECT @Classification [Classification]
         , BP.[Reservation No_]
         , '999999999' [Document No_]
         , 'Invoice'   [Document Type]
         , COALESCE(NULLIF(VA.[Customer No_],0),999999999) [Customer No_]
         , null [Chain Code]
         , null [Brand Code]
         , null [MuseID]
         , [PAY POSTING DATE] [Due Date]
        , PT.[Description] [Payment Terms Code]
         , COALESCE(CR.[Name],'') [Country Name]
         , @Bucket [Bucket]
        , null [Agency Amount (LCY)]
        , null [TAF Amount (LCY)]
        , IT.[AMOUNT (LCY)] [Amount (LCY)]
        , null [Paid Amount (LCY)]
        , COALESCE(IT.[AMOUNT (LCY)],0) [Remaining Amount (LCY)]
        , @LegalEntity [Legal Entity]
        , GETDATE() [Inserted at]
        , null [Modified at]
        , '' [Product type]
        , null [HQ Customer No_]
        , null [Document Date]
        , DATEDIFF(dd,IT.[PAY POSTING DATE],GETDATE()) [Days after Document Date]
        , IT.[K_KEY] [Company No_]
        , CU.[Payment Terms Code]
        , CU.[Salesperson Code]
     FROM [DynNavHRS].[HRSDB].[INVOICE_TRACE_PAYMENT] IT
     JOIN BP ON BP.[Process No_]=IT.[PROCESS_NO]
LEFT JOIN [Affiliate Partner] AP ON AP.[No_]=IT.[K_KEY]
LEFT JOIN [HRS Payment$Country_Region] CR ON CR.[Code]=AP.[Country Code]
LEFT JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] VA ON VA.[Company No_]=IT.[K_KEY]
LEFT JOIN [HRS Payment$Customer] CU ON VA.[Customer No_]=CU.[No_]
LEFT JOIN [HRS Payment$Payment Terms] PT WITH (NOLOCK) ON PT.[Code]=CU.[Payment Terms Code]
 WHERE NOT [ERROR_TEXT] IN ('Rechnung wurde gebucht')

-- Multisource
  UPDATE BI SET
         BI.[Product type] = @ProductTypeMULTISOURCE
    FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
    JOIN BI.Outstandings BI ON BI.[Reservation No_]=BU.B_KEY
   WHERE BU.MULTISOURCED=1
     AND COALESCE(BI.[Product type],'') = ''
     AND [Legal Entity]=@LegalEntity

-- Unallocated
  UPDATE BI SET
         BI.[Product type] = @ProductTypeUNALLOCATED
    FROM BI.Outstandings BI 
   WHERE BI.[Customer No_] LIKE '990____'
     AND COALESCE(BI.[Product type],'') = ''
     AND [Legal Entity]=@LegalEntity

-- Sourcing
  UPDATE BI SET
         BI.[Product type] = @ProductTypeSOURCING
    FROM BI.Outstandings BI 
    JOIN [HRS Payment$Sales Invoice Header] SH WITH (NOLOCK) ON SH.[No_]=BI.[Document No_] AND SH.[Order Type]=5
   WHERE COALESCE(BI.[Product type],'') = ''
     AND [Legal Entity]=@LegalEntity

-- Other
  UPDATE BI SET
         BI.[Product type] = @ProductTypeOTHER
    FROM BI.Outstandings BI 
   WHERE COALESCE(BI.[Product type],'') = ''
     AND [Legal Entity]=@LegalEntity

END
GO
