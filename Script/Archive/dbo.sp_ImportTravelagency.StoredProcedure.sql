USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_ImportTravelagency]    Script Date: 10.04.2024 14:31:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 22.06.2015
-- Description:	Übertragung der IATA Import Zeilen in die Tabelle Travelagency
/*
EXEC [sp_ImportTravelagency]
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_ImportTravelagency]
AS
BEGIN
    ;WITH TA AS(SELECT [IATA], MAX([No_]) AS [No_] FROM [Travelagency] WITH (NOLOCK) GROUP BY [IATA]) 
   INSERT INTO [Travelagency]([Travelagency Code],[Name],[Name 2],[Address],[Address 2],[City],[Contact],[Phone No_],[Country_Region Code],[E-Mail],[Correspondence Type],[Post Code],[IATA],[IATA2],[Amadeus No_],[Travelagency ID],[Modified at],[Modified by],[Sabre No_])
   SELECT '',II.[Legal1],II.[Legal2],II.[LAdd1],II.[LAdd2],II.[LCity],'','',CR.[Code],II.[LEmail],1,II.[LPostal],II.[IATACode],'','','',CAST(GETDATE() AS DATE),'IATA-IMPORT',''
     FROM [IATA Import Line] II WITH (NOLOCK)
LEFT JOIN TA ON TA.IATA = II.[IATACode]
     JOIN [HRS$Country_Region] CR WITH (NOLOCK)
	   ON II.[LRegISO]  = CR.[ISO Code]
    WHERE TA.IATA IS NULL
	  AND ISNUMERIC(CR.[Code])=1

UPDATE T SET 
       T.[Name] = I.[Legal1]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[Name] = ''
   AND I.[Legal1] <> ''

UPDATE T SET 
       T.[Name 2] = I.[Legal2]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[Name 2] = ''
   AND I.[Legal2] <> ''

UPDATE T SET 
       T.[Address] = I.[LAdd1]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[Address] = ''
   AND I.[LAdd1] <> ''

UPDATE T SET 
       T.[Address 2] = I.[LAdd2]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[Address 2] = ''
   AND I.[LAdd2] <> ''

UPDATE T SET 
       T.[City] = I.[LCity]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[City] = ''
   AND I.[LCity] <> ''

UPDATE T SET 
       T.[City] = I.[LCity]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[City] = ''
   AND I.[LCity] <> ''

UPDATE T SET 
       T.[Post Code] = I.[LPostal]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
 WHERE T.[Post Code] = ''
   AND I.[LPostal] <> ''

UPDATE T SET 
       T.[Country_Region Code] = CR.[Code]
  FROM [Travelagency] T
  JOIN [IATA Import Line] I
    ON I.[IATACode] = T.[IATA]
  JOIN [HRS$Country_Region] CR WITH (NOLOCK)
	ON I.[LRegISO]  = CR.[ISO Code]
 WHERE T.[Country_Region Code] = ''
   AND CR.[Code] <> ''
END

GO
