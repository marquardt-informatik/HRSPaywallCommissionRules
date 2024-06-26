USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPLabelTranslation_HI]    Script Date: 10.04.2024 14:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 09.09.2013
-- Description:	IBAN-Schreiben 
-- 07.02.18  RPR Hole restlichen Labels aus dem HRS Mandanten, wenn in "HRS Holidays" nicht vorhanden
--				 Language 1 nicht beachtet				
/*

EXEC [dbo].[sp_RPLabelTranslation_HI] 0,23,0
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPLabelTranslation_HI] 
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
		 WHERE (LanguageCode = @Language)
		   AND (Company = 'HRS Holidays') 
		   AND (DocumentType = @DocumentType) 
		   AND (DocumentLevel = @DocumentLevel)
	), UTF1 AS
	(
		-->> RPR
		--SELECT LabelID, Translation
		--  FROM UTFDocumentTranslation WITH (NOLOCK)
		-- WHERE (LanguageCode = 1)
		--   AND (Company = 'HRS Holidays') 
		--   AND (DocumentType = @DocumentType2) 
		--   AND (DocumentLevel = @DocumentLevel2)
		SELECT LabelID, Translation
		  FROM UTFDocumentTranslation WITH (NOLOCK)
		 WHERE (LanguageCode = @Language)
		   AND (Company = 'HRS') 
		   AND (DocumentType = @DocumentType2) 
		   AND (DocumentLevel = @DocumentLevel2)
		--<< RPR
	)
	   SELECT *
		 FROM UTF   
		UNION ALL
	   SELECT UTF1.*
		 FROM UTF1
	LEFT JOIN UTF 
		   ON UTF.LabelID = UTF1.LabelID  
		WHERE UTF.LabelID IS NULL

END
GO
