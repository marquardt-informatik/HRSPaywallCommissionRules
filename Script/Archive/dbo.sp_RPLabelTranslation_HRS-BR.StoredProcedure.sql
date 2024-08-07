USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPLabelTranslation_HRS-BR]    Script Date: 10.04.2024 14:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 09.09.2013
-- Description:	IBAN-Schreiben 
--
/*

EXEC [dbo].[sp_RPLabelTranslation_HRS-BR] 23,8,0
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPLabelTranslation_HRS-BR] 
    @Language int
  , @DocumentType int
  , @DocumentLevel int
AS
BEGIN
DECLARE
    @Language2 int
  , @DocumentType2 int
  , @DocumentLevel2 int
SET @Language2 = @Language
SET @DocumentType2 = @DocumentType
SET @DocumentLevel2 = @DocumentLevel
;WITH UTF AS
(
SELECT LabelID, Translation
  FROM UTFDocumentTranslation WITH (NOLOCK)
 WHERE (LanguageCode = @Language2)
   AND (Company = 'HRS-BR') 
   AND (DocumentType = @DocumentType2) 
   AND (DocumentLevel = @DocumentLevel2)
), UTF1 AS
(
SELECT LabelID, Translation
  FROM UTFDocumentTranslation WITH (NOLOCK)
 WHERE (LanguageCode = 1)
   AND (Company = 'HRS-BR') 
   AND (DocumentType = @DocumentType2) 
   AND (DocumentLevel = @DocumentLevel2)
)
   SELECT *
     FROM UTF   
    UNION
   SELECT UTF1.*
     FROM UTF1
LEFT JOIN UTF ON UTF.LabelID = UTF1.LabelID  
    WHERE UTF.LabelID IS NULL
END

GO
