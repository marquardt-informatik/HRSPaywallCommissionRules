USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_InquiryEfficiency]    Script Date: 10.04.2024 14:31:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 18.07.13
-- Description:	Nav Report xxx
--				Diese Procedure wird in dem Report InquiryEfficiency verwendet.
-- 
/*
EXEC [RS].[PROC_InquiryEfficiency] '','',50041
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_InquiryEfficiency] 
(
	  @UserId						VARCHAR(20)
	, @CompanyName					VARCHAR(30)
	, @ReportId						INT
)
AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

;WITH RM_HRS AS
(
SELECT AH.[No_], AL.[Date _ Time], AL.[User ID]
  FROM [HRS$EBPP Journal Archive Subtable] AL WITH (NOLOCK)
  JOIN [HRS$EBPP Journal Archive]          AH WITH (NOLOCK)
    ON AH.[EBPP Provider Code] = AL.[EBPP Provider Code]
   AND AH.[Reference]          = AL.[Reference]
 WHERE AL.[Document Type] = 18
   AND AL.[Error Flag] = 0
), DL_HRS AS
( 
SELECT DISTINCT 'HRS' Company, DL.[Process Number], DH.[Case No_], DL.[Reservation No_], DL.[Position No_], DL.[Line Amount (LCY)] 
  FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
  JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
    ON DH.[Case No_] = DL.[Display Case No_]
 WHERE DH.[Subsequent Debit from] <> ''
   AND DL.[Action] <> 3
), RM_CN AS
(
SELECT AH.[No_], AL.[Date _ Time], AL.[User ID]
  FROM [HRS-CN$EBPP Journal Archive Subtable] AL WITH (NOLOCK)
  JOIN [HRS-CN$EBPP Journal Archive]          AH WITH (NOLOCK)
    ON AH.[EBPP Provider Code] = AL.[EBPP Provider Code]
   AND AH.[Reference]          = AL.[Reference]
 WHERE AL.[Document Type] = 18
   AND AL.[Error Flag] = 0
), DL_CN AS
( 
SELECT DISTINCT 'HRS-CN' Company, DL.[Process Number], DH.[Case No_], DL.[Reservation No_], DL.[Position No_], DL.[Line Amount (LCY)] 
  FROM [HRS-CN$Agency Display Line] DL WITH (NOLOCK)
  JOIN [HRS-CN$Agency Display Header] DH WITH (NOLOCK)
    ON DH.[Case No_] = DL.[Display Case No_]
 WHERE DH.[Subsequent Debit from] <> ''
   AND DL.[Action] <> 3
), SUM_RM AS
(
   SELECT RM.*, DL.*
     FROM RM_HRS RM
LEFT JOIN DL_HRS DL ON DL.[Process Number] = RM.[No_]
UNION
   SELECT RM.*, DL.*
     FROM RM_CN RM
LEFT JOIN DL_CN DL ON DL.[Process Number] = RM.[No_]
)
  SELECT [User ID]
       , CAST(CONVERT(VARCHAR(10),DATEADD(dd, -DATEPART(dd,[Date _ Time])+1, [Date _ Time]),120) AS DATE) [Date _ Time]
       , COUNT(1)                                           [Count Inquiry sent]
       , SUM(CASE WHEN [Company] IS NULL THEN 0 ELSE 1 END) [Count Susequent invoiced]
       , SUM(CASE WHEN [Company] IS NULL THEN 0 ELSE [Line Amount (LCY)] END) [Susequent invoiced Amount]
    FROM SUM_RM S
   WHERE YEAR([Date _ Time])+3>= YEAR(GETDATE()) 
GROUP BY [User ID]
       , CAST(CONVERT(VARCHAR(10),DATEADD(dd, -DATEPART(dd,[Date _ Time])+1, [Date _ Time]),120) AS DATE)
ORDER BY 2,1       
END

GO
