USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[CorrectChain993]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Soner Akdemir
-- Create date:2023-12-31
-- Description:	ACS-4231

--Alle Buchungen der Chain 993 mit Abreisedatum ab dem 01.08.23 sollen auf Chain 15 umgestellt werden.

--Hierzu bitte eine SP bauen, die im Kommissionslauf aufgerufen werden soll. Bitte die Änderungen in HRSDB.BUCHUNG, [HRS*$Agency Header] und ungebuchten [HRS*$Agency Display Header] durchführen.

-- Date     Version   RFC    Sign.  Description
-- ------------------------------------------------------------


CREATE PROCEDURE [dbo].[CorrectChain993] AS
BEGIN
UPDATE BU SET 
       BU.KE_BID=15
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
 WHERE BU.KE_BID = 993
 AND B_AB_DATUM >= '2023-08-01'

UPDATE AH SET 
       AH.[Chain ID]='15'
  FROM [HRS$Agency Header] AH WITH (NOLOCK)
 WHERE AH.[Chain ID] = '993'
 AND AH.[Departure Date] >= '2023-08-01'

UPDATE AH SET 
       AH.[Chain Code]='15'
  FROM [HRS$Agency Display Header] AH WITH (NOLOCK)
 WHERE AH.[Chain Code] = '993'
 AND AH.[Posting Date]>= '2023-08-01'

 END   
   
  
GO
