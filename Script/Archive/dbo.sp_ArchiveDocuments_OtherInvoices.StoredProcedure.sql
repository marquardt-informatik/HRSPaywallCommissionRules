USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_ArchiveDocuments_OtherInvoices]    Script Date: 10.04.2024 14:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_ArchiveDocuments_OtherInvoices] AS
BEGIN

;WITH ARCH AS (
  SELECT DISTINCT J.No_
    FROM [HRS$EBPP Journal] J WITH (NOLOCK)
    JOIN [HRS$EBPP Journal Subtable] JS WITH (NOLOCK) 
      ON J.[EBPP Provider Code] = JS.[EBPP Provider Code] AND J.Reference = JS.Reference AND JS.Archived = 1
   WHERE J.[Document Type] IN (32)
   UNION
  SELECT DISTINCT J.No_
    FROM [HRS$EBPP Journal Archive] J WITH (NOLOCK)
    JOIN [HRS$EBPP Journal Archive Subtable] JS WITH (NOLOCK) 
	  ON J.[EBPP Provider Code] = JS.[EBPP Provider Code] AND J.Reference = JS.Reference AND JS.Archived = 1
   WHERE J.[Document Type] IN (32)
), ARCH_BR AS (
  SELECT DISTINCT J.No_
    FROM [HRS-BR$EBPP Journal] J WITH (NOLOCK)
    JOIN [HRS-BR$EBPP Journal Subtable] JS WITH (NOLOCK) 
      ON J.[EBPP Provider Code] = JS.[EBPP Provider Code] AND J.Reference = JS.Reference AND JS.Archived = 1
   WHERE J.[Document Type] IN (32)
   UNION
  SELECT DISTINCT J.No_
    FROM [HRS-BR$EBPP Journal Archive] J WITH (NOLOCK)
    JOIN [HRS-BR$EBPP Journal Archive Subtable] JS WITH (NOLOCK) 
	  ON J.[EBPP Provider Code] = JS.[EBPP Provider Code] AND J.Reference = JS.Reference AND JS.Archived = 1
   WHERE J.[Document Type] IN (32)
), ARCH_CN AS (
  SELECT DISTINCT J.No_
    FROM [HRS-CN$EBPP Journal] J WITH (NOLOCK)
    JOIN [HRS-CN$EBPP Journal Subtable] JS WITH (NOLOCK) 
      ON J.[EBPP Provider Code] = JS.[EBPP Provider Code] AND J.Reference = JS.Reference AND JS.Archived = 1
   WHERE J.[Document Type] IN (32)
   UNION
  SELECT DISTINCT J.No_
    FROM [HRS-CN$EBPP Journal Archive] J WITH (NOLOCK)
    JOIN [HRS-CN$EBPP Journal Archive Subtable] JS WITH (NOLOCK) 
	  ON J.[EBPP Provider Code] = JS.[EBPP Provider Code] AND J.Reference = JS.Reference AND JS.Archived = 1
   WHERE J.[Document Type] IN (32)
)
   SELECT CASE 
            WHEN SIH.[Order Type] = 4 THEN 32
		  END [Document Type]
		, SIH.No_ [Document No_]
		, 'HRS' [Company]
     FROM [HRS$Sales Invoice Header] SIH WITH (NOLOCK)
LEFT JOIN ARCH 
       ON SIH.No_ = ARCH.No_
	WHERE SIH.[Posting Date] >= '2020-01-01'
	  AND ARCH.No_ IS NULL
	  AND SIH.[Order Type] IN (4)

	UNION

   SELECT CASE 
            WHEN SIH.[Order Type] = 4 THEN 32
		  END [Document Type]
		, SIH.No_ [Document No_]
		, 'HRS-BR' [Company]
     FROM [HRS-BR$Sales Invoice Header] SIH WITH (NOLOCK)
LEFT JOIN ARCH_BR ARCH 
       ON SIH.No_  = ARCH.No_
	WHERE SIH.[Posting Date] >= '2020-01-01'
	  AND ARCH.No_ IS NULL
	  AND SIH.[Order Type] IN (4)

	UNION

   SELECT CASE 
            WHEN SIH.[Order Type] = 4 THEN 32
		  END [Document Type]
		, SIH.No_ [Document No_]
		, 'HRS-CN' [Company]
     FROM [HRS-CN$Sales Invoice Header] SIH WITH (NOLOCK)
LEFT JOIN ARCH_CN ARCH 
       ON SIH.No_  = ARCH.No_
	WHERE SIH.[Posting Date] >= '2020-01-01'
	  AND ARCH.No_ IS NULL
	  AND SIH.[Order Type] IN (4)

END
GO
