USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [BI].[InsertSTAYOutstandingsHRS-BR]    Script Date: 10.04.2024 14:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [BI].[InsertSTAYOutstandingsHRS-BR]
AS
BEGIN
DECLARE @Classification varchar(20)='STAY', @LegalEntity varchar(50)='Hotel Reservation Service Brasil Ltda.', @ClassificationWORK varchar(20)='WORK'
      , @ProductTypeMULTISOURCE varchar(20)='Multisource'
      , @ProductTypeSOURCING varchar(20)='Sourcing'
      , @ProductTypeUNALLOCATED varchar(20)='Unallocated'
      , @ProductTypeOther varchar(20)='Other'

   DELETE FROM BI
     FROM BI.Outstandings BI
    WHERE BI.[Legal Entity]=@LegalEntity
      AND BI.[Classification] IN (@Classification,@ClassificationWORK)

DECLARE @RecreateRE int=1, @RecreateCE int=1, @RecreateRES int=1
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
      FROM [HRS-BR$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN [HRS-BR$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE 1=1--CE.[Document Date]<'2023-08-31'
       AND CE.[Document Date]>'2020-12-31'
       AND CE.Reservierungsnr_>0
       AND DE.[Entry Type]=1
       --AND DE.[Customer No_]='438931'
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
    , [Due Date] datetime, [Reservation No_] int, [Initial Amount (LCY)] DECIMAL(38, 20), [Remaining Amount (LCY)] DECIMAL(38, 20)
    , [Salesperson Code] VARCHAR(10) COLLATE Latin1_General_CS_AS, [Payment Method Code] VARCHAR(100) COLLATE Latin1_General_CS_AS
    );
    INSERT INTO #CE ([Entry No_],[Document No_],[Customer No_],[Document Type],[Due Date],[Reservation No_],[Initial Amount (LCY)],[Remaining Amount (LCY)],[Salesperson Code],[Payment Method Code])
    SELECT CE.[Entry No_]
         , CE.[Document No_]
         , CE.[Customer No_]
         , CE.[Document Type]
         , CE.[Due Date]
         , CASE WHEN CE.[Reservierungsnr_]=0 OR CE.[Document Type]=2 THEN 999999999 ELSE CE.[Reservierungsnr_] END [Reservation No_]
         , SUM(CASE WHEN DE.[Entry Type]=1 THEN DE.[Amount (LCY)] ELSE 0 END) [Initial Amount(LCY)]
         , SUM(DE.[Amount (LCY)]) [Remaining Amount (LCY)]
         , MAX(CE.[Payment Method Code]) [Payment Method Code]
         , MAX(CE.[Salesperson Code]) [Salesperson Code]
      FROM [HRS-BR$Detailed Cust_ Ledg_ Entry] DE WITH (NOLOCK)
      JOIN [HRS-BR$Cust_ Ledger Entry] CE WITH (NOLOCK) ON DE.[Cust_ Ledger Entry No_]=CE.[Entry No_]
     WHERE CE.[Open]=1
       --AND DE.[Document Type]=2
       --AND DE.[Customer No_]='438931'
  GROUP BY CE.[Entry No_]
         , CE.[Document No_]
         , CE.[Document Type]
         , CE.[Customer No_]
         , CE.[Due Date]
         , CASE WHEN CE.[Reservierungsnr_]=0 OR CE.[Document Type]=2 THEN 999999999 ELSE CE.[Reservierungsnr_] END
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
CREATE TABLE #RES ([Reservation No_] int,[Document No_] VARCHAR(20) COLLATE Latin1_General_CS_AS,[Document Type] VARCHAR(20) COLLATE Latin1_General_CS_AS
    , [Customer No_] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Chain Code] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Brand Code] VARCHAR(20) COLLATE Latin1_General_CS_AS
    , [MuseID] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Due Date] datetime, [Payment Terms Code] VARCHAR(20) COLLATE Latin1_General_CS_AS, [Country Name] VARCHAR(100) COLLATE Latin1_General_CS_AS
    , [Bucket] VARCHAR(10) COLLATE Latin1_General_CS_AS, [Agency Amount (LCY)] decimal(38,20), [TAF Amount (LCY)] decimal(38,20), [Amount (LCY)] decimal(38,20), [Paid Amount (LCY)] decimal(38,20)
    , [Remaining Amount (LCY)] decimal(38,20),[Product type] VARCHAR(20) COLLATE Latin1_General_CS_AS
    , [Salesperson Code] VARCHAR(10) COLLATE Latin1_General_CS_AS, [Payment Method Code] VARCHAR(10) COLLATE Latin1_General_CS_AS
    );
;WITH _DL AS
(
    SELECT DL.[Reservation No_]
         , CE.[Document No_]
         , DH.[Chain Code]
         , DH.[Brand Code]
         , DH.[MuseID]
         , DH.[Creation Date] [Due Date]
         , PT.[String] [Product type]
         , SUM(DL.[Agency Line Amount (LCY)]) [Agency Amount (LCY)]
         , SUM(DL.[TAF Line Amount (LCY)]) [TAF Amount (LCY)]
         , SUM(DL.[Agency Line Amount (LCY)]+DL.[TAF Line Amount (LCY)]) [Amount (LCY)]
         , MAX(CE.[Payment Method Code]) [Payment Method Code]
         , MAX(CE.[Salesperson Code]) [Salesperson Code]
      FROM #CE CE
      JOIN [HRS-BR$Agency Display Header] DH WITH (NOLOCK) ON DH.[Posted Invoice No_]=CE.[Document No_] 
      JOIN [HRS-BR$Agency Display Line] DL WITH (NOLOCK) ON DH.[Case No_]=DL.[Display Case No_]
      JOIN Split(',,,,,,,,,Commission Invoice,Commission Invoice,Commission Invoice,Commission Invoice,,,Commission Invoice,,,,,,,,,,,,,,,,,,,,,,Traveler TAF,Chain TAF,Partnership Fee,Additional Commission,PFP,Override,Sourcing Fee',',') PT ON PT.[Index]-1=CAST(DH.[Document Type] as int)
     WHERE DL.[Action]<>3
       AND CE.[Document Type]=2
  GROUP BY DL.[Reservation No_]
         , CE.[Document No_]
         , DH.[Chain Code]
         , DH.[Brand Code]
         , DH.[MuseID]
         , DH.[Creation Date]
         , PT.[String]
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
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 1 THEN 'not due'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 31 THEN '1-30'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 61 THEN '31-60'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 91 THEN '61-90'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 181 THEN '91-180'
            WHEN DATEDIFF(dd,IH.[Due Date],GETDATE()) < 361 THEN '181-360'
            ELSE '361+'
          END [Bucket]
        , DL.[Agency Amount (LCY)]
        , DL.[TAF Amount (LCY)]
        , DL.[Amount (LCY)]
        , RE.[Initial Amount (LCY)] [Paid Amount (LCY)]
        , DL.[Amount (LCY)] + COALESCE(RE.[Initial Amount (LCY)],0) [Remaining Amount (LCY)]
        , DL.[Product type]
        , DL.[Payment Method Code]
        , DL.[Salesperson Code]
     FROM DL
LEFT JOIN #RE RE ON RE.[Reservation No_]=DL.[Reservation No_]
     JOIN [HRS-BR$Sales Invoice Header] IH WITH (NOLOCK) ON IH.[No_]=DL.[Document No_]
     JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=IH.[Sell-to Country_Region Code]
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
        , null [Product type]
        , CE.[Payment Method Code]
        , CE.[Salesperson Code]
     FROM #CE CE
     JOIN [HRS-BR$Customer] CU WITH (NOLOCK) ON CU.[No_]=CE.[Customer No_]
     JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
    --WHERE CE.[Initial Amount (LCY)] - CE.[Remaining Amount (LCY)]<>0
), SU AS
(
SELECT * 
     , ROW_NUMBER() OVER (ORDER BY _SU.[Customer No_], _SU.[Document No_], _SU.[Reservation No_]) [Row No_]
  FROM _SU
)

    INSERT INTO #RES ([Reservation No_],[Document No_],[Document Type],[Customer No_],[Chain Code],[Brand Code],[MuseID],[Due Date],[Payment Terms Code],[Country Name],[Bucket],[Product type],[Agency Amount (LCY)],[TAF Amount (LCY)],[Amount (LCY)],[Paid Amount (LCY)],[Remaining Amount (LCY)],[Payment Method Code],[Salesperson Code])    
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
         , SU.[Product type]
         , SUM(COALESCE(SU.[Agency Amount (LCY)],0))
         , SUM(COALESCE(SU.[TAF Amount (LCY)],0))
         , SUM(COALESCE(SU.[Amount (LCY)],0))
         , SUM(COALESCE(SU.[Paid Amount (LCY)],0))
         , SUM(COALESCE(SU.[Remaining Amount (LCY)],0))
         , MAX(SU.[Payment Method Code]) [Payment Method Code]
         , MAX(SU.[Salesperson Code]) [Salesperson Code]
      FROM SU
      JOIN dbo.Split(' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund',',') DT ON DT.[Index]-1=SU.[Document Type]
  GROUP BY SU.[Reservation No_]
         , SU.[Document No_]
         , DT.[String] 
         , SU.[Customer No_]
         , SU.[Chain Code]
         , SU.[Brand Code]
         , SU.[MuseID]
         , SU.[Due Date]
         , SU.[Payment Terms Code]
         , SU.[Country Name]
         , SU.[Bucket]
         , SU.[Product type]
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


UPDATE BI SET
       BI.[Agency Amount (LCY)]=SU.[Agency Amount (LCY)]
     , BI.[TAF Amount (LCY)] = SU.[TAF Amount (LCY)]
     , BI.[Amount (LCY)] = SU.[Amount (LCY)]
     , BI.[Paid Amount (LCY)] = SU.[Paid Amount (LCY)]
     , BI.[Remaining Amount (LCY)] = SU.[Remaining Amount (LCY)]
     , BI.[Bucket] = SU.[Bucket]
     , BI.[Modified at]=GETDATE()
     , BI.[Document Date]=BI.[Due Date]
     , BI.[Days after Document Date]=DATEDIFF(dd,BI.[Due Date],GETDATE())
  FROM BI.Outstandings BI
  JOIN #RES SU ON SU.[Reservation No_]=BI.[Reservation No_] AND SU.[Document No_]=BI.[Document No_] AND SU.[Customer No_]=BI.[Customer No_] AND SU.[Document Type]=BI.[Document Type] AND SU.[Due Date]=BI.[Due Date] AND SU.[Product type]=BI.[Product type]
 WHERE BI.[Classification] IN (@Classification,@ClassificationWORK)
   AND BI.[Legal Entity]=@LegalEntity
   AND (
       COALESCE(BI.[Agency Amount (LCY)],0) <> COALESCE(SU.[Agency Amount (LCY)],0)
    OR COALESCE(BI.[TAF Amount (LCY)],0) <> COALESCE(SU.[TAF Amount (LCY)],0)
    OR COALESCE(BI.[Amount (LCY)],0) <> COALESCE(SU.[Amount (LCY)],0)
    OR COALESCE(BI.[Paid Amount (LCY)],0) <> COALESCE(SU.[Paid Amount (LCY)],0)
    OR COALESCE(BI.[Remaining Amount (LCY)],0) <> COALESCE(SU.[Remaining Amount (LCY)],0)
    OR BI.[Bucket] <> SU.[Bucket]
    OR COALESCE(BI.[Document Date],'1753-01-01') <> BI.[Due Date]
    OR COALESCE(BI.[Days after Document Date],0) <> DATEDIFF(dd,BI.[Due Date],GETDATE())
       )

   INSERT INTO BI.Outstandings ([Classification],[Reservation No_],[Document No_],[Document Type],[Customer No_],[Chain Code],[Brand Code],[MuseID],[Due Date],[Payment Terms Code],[Country Name],[Bucket],[Agency Amount (LCY)],[TAF Amount (LCY)],[Amount (LCY)],[Paid Amount (LCY)],[Remaining Amount (LCY)],[Legal Entity],[Inserted at],[Product type],[Document Date],[Days after Document Date],[Payment Method Code],[Salesperson Code])
   SELECT DISTINCT @Classification
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
        , @LegalEntity
        , GETDATE()
        , COALESCE(SU.[Product type],'') [Product type]
        , SU.[Due Date] [Document Date]
        , DATEDIFF(dd,SU.[Due Date],GETDATE()) [Days after Document Date]
        , SU.[Payment Terms Code]
        , SU.[Salesperson Code]
     FROM #RES SU
LEFT JOIN [HRS-BR$Payment Terms] PT WITH (NOLOCK) ON PT.[Code]=SU.[Payment Terms Code]
--LEFT JOIN BI.Outstandings BI 
--       ON BI.[Classification] IN (@Classification,@ClassificationWORK) 
--      AND BI.[Reservation No_]=SU.[Reservation No_] 
--      AND SU.[Document No_]=BI.[Document No_] 
--      AND SU.[Document Type]=BI.[Document Type] 
--      AND BI.[Customer No_]=SU.[Customer No_] 
--      AND BI.[Legal Entity]=@LegalEntity 
--      AND SU.[Due Date]=BI.[Due Date] 
--      AND SU.[Product type]=BI.[Product type]
--    WHERE BI.[Reservation No_] IS NULL

--   DELETE FROM BI
--     FROM BI.Outstandings BI
--LEFT JOIN #RES SU ON BI.[Classification] IN (@Classification,@ClassificationWORK) AND BI.[Reservation No_]=SU.[Reservation No_] AND BI.[Customer No_]=SU.[Customer No_] AND BI.[Legal Entity]=@LegalEntity AND SU.[Document Type]=BI.[Document Type] AND SU.[Due Date]=BI.[Due Date] AND SU.[Product type]=BI.[Product type]
--    WHERE SU.[Reservation No_] IS NULL
--      AND BI.[Legal Entity]=@LegalEntity
--      AND BI.[Classification] IN (@Classification,@ClassificationWORK)

   UPDATE BI SET
          BI.[Classification] = @ClassificationWORK
     FROM BI.Outstandings BI
     JOIN HRSDB.BUCHUNG BU WITH (NOLOCK) ON BU.B_KEY=BI.[Reservation No_]
    WHERE BU.B_QUELLE IN (5,7)
      AND BI.[Classification]=@Classification
      AND BI.[Legal Entity]=@LegalEntity

;WITH HQ AS (SELECT MAX(CAST([No_] as varchar(20))) [No_], [Chain] [Chain Code] FROM [HRS-BR$Customer] WHERE [No_] BETWEEN 99990000 AND 99999999 AND NOT [Chain] IN ('','99999') GROUP BY [Chain])
   UPDATE BI SET
          BI.[HQ Customer No_] = HQ.[No_]
     FROM BI.Outstandings BI
     JOIN HQ ON HQ.[Chain Code]=BI.[Chain Code]
    WHERE BI.[Classification]=@Classification
      AND BI.[Legal Entity]=@LegalEntity

   UPDATE BI SET
          BI.[Company No_] = 999999999
     FROM BI.Outstandings BI
    WHERE BI.[Company No_] IS NULL
      AND BI.[Classification] IN (@Classification,@ClassificationWORK) 
      AND BI.[Legal Entity]=@LegalEntity

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
    JOIN [HRS-BR$Sales Invoice Header] SH WITH (NOLOCK) ON SH.[No_]=BI.[Document No_] AND SH.[Order Type]=5
   WHERE COALESCE(BI.[Product type],'') = ''
     AND [Legal Entity]=@LegalEntity

-- Other
  UPDATE BI SET
         BI.[Product type] = @ProductTypeOTHER
    FROM BI.Outstandings BI 
   WHERE COALESCE(BI.[Product type],'') = ''
     AND [Legal Entity]=@LegalEntity

     UPDATE BI.Outstandings SET [Amount (LCY)]=[Remaining Amount (LCY)]-[Paid Amount (LCY)]
 WHERE ABS([Amount (LCY)]+[Paid Amount (LCY)]-[Remaining Amount (LCY)])>1
   AND [Amount (LCY)]<>[Remaining Amount (LCY)]-[Paid Amount (LCY)]

END
GO
