USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[ACS-4047]    Script Date: 10.04.2024 14:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 22.09.2022
-- Description:	ACS-4047 Update BrandID for ACCOR in Sep. 2022
-- =============================================
CREATE PROCEDURE [dbo].[ACS-4047] 
  @DateFrom date
, @DateTo date
AS BEGIN
    UPDATE BU SET
           BU.KE_ID=HO.KE_ID
      FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
      JOIN HRSDB.HOTEL HO WITH (NOLOCK) ON BU.H_KEY=HO.H_KEY
     WHERE HO.KE_BID=550
       AND BU.KE_ID=550
       AND BU.B_AB_DATUM BETWEEN @DateFrom AND @DateTo
       AND BU.KE_ID<>HO.KE_ID

    UPDATE BU SET
           BU.[Brand ID]=HO.[Brand]
      FROM [HRS$Agency Header] BU WITH (NOLOCK)
      JOIN [HRS$Customer] HO WITH (NOLOCK) ON BU.[Chain ID]=HO.[Chain]
     WHERE HO.[Chain]=550
       AND BU.[Brand ID]=550
       AND BU.[Departure Date] BETWEEN @DateFrom AND @DateTo
       AND BU.[Brand ID]<>HO.[Brand]

    UPDATE BU SET
           BU.[Brand ID]=HO.[Brand]
      FROM [HRS-CN$Agency Header] BU WITH (NOLOCK)
      JOIN [HRS-CN$Customer] HO WITH (NOLOCK) ON BU.[Chain ID]=HO.[Chain]
     WHERE HO.[Chain]=550
       AND BU.[Brand ID]=550
       AND BU.[Departure Date] BETWEEN @DateFrom AND @DateTo
       AND BU.[Brand ID]<>HO.[Brand]

    UPDATE BU SET
           BU.[Brand ID]=HO.[Brand]
      FROM [HRS-BR$Agency Header] BU WITH (NOLOCK)
      JOIN [HRS-BR$Customer] HO WITH (NOLOCK) ON BU.[Chain ID]=HO.[Chain]
     WHERE HO.[Chain]=550
       AND BU.[Brand ID]=550
       AND BU.[Departure Date] BETWEEN @DateFrom AND @DateTo
       AND BU.[Brand ID]<>HO.[Brand]
END
GO
