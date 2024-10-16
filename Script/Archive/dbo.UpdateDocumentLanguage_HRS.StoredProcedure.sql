USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[UpdateDocumentLanguage_HRS]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 22.02.2022
-- Description:	Update Document Language caused by SPRACHE_ID in HRSDB.HOTEL
-- Ticket :     ACS-3478
-- =============================================

CREATE PROC [dbo].[UpdateDocumentLanguage_HRS] 
  @CreationDate date
AS
BEGIN
UPDATE DH SET DH.[Language Code]=CR.[Primary Language Code]
  FROM [HRS$Agency Display Header] DH
  JOIN [HRS$Customer] CU ON CU.[No_]=DH.[Bill-to Customer No_]
  JOIN [HRS$Contact] CO ON CO.[No_]=DH.[Bill-to Customer No_]
  JOIN [HRS$Country_Region] CR ON CR.[Code]=CU.[Country_Region Code]
 WHERE NOT CU.[Country_Region Code] IN ('33','114')
   AND (CO.[Language Code]='0' OR CU.[Language Code]='0' OR DH.[Language Code]='0')
   AND DH.[Creation Date]=@CreationDate

UPDATE CU SET CU.[Language Code]=CR.[Primary Language Code]
  FROM [HRS$Agency Display Header] DH
  JOIN [HRS$Customer] CU ON CU.[No_]=DH.[Bill-to Customer No_]
  JOIN [HRS$Contact] CO ON CO.[No_]=DH.[Bill-to Customer No_]
  JOIN [HRS$Country_Region] CR ON CR.[Code]=CU.[Country_Region Code]
 WHERE NOT CU.[Country_Region Code] IN ('33','114')
   AND (CO.[Language Code]='0' OR CU.[Language Code]='0' OR DH.[Language Code]='0')
   AND DH.[Creation Date]=@CreationDate

UPDATE CO SET CO.[Language Code]=CR.[Primary Language Code]
  FROM [HRS$Agency Display Header] DH
  JOIN [HRS$Customer] CU ON CU.[No_]=DH.[Bill-to Customer No_]
  JOIN [HRS$Contact] CO ON CO.[No_]=DH.[Bill-to Customer No_]
  JOIN [HRS$Country_Region] CR ON CR.[Code]=CU.[Country_Region Code]
 WHERE NOT CU.[Country_Region Code] IN ('33','114')
   AND (CO.[Language Code]='0' OR CU.[Language Code]='0' OR DH.[Language Code]='0')
   AND DH.[Creation Date]=@CreationDate
END
GO
