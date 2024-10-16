USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateUTFDocumentTranslation_SIK2]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt	
-- Create date: 21.07.2011
-- Description:	Änderungen in der Tabelle [Label Translation] werden in das Unicode-Pendant geschrieben
/*
DECLARE @LanguageCode  varchar(10)
      , @Company       varchar(30)
      , @DocumentType  tinyint
      , @DocumentLevel int
      , @ReminderLevel int
      , @LabelCode     varchar(10)
    SELECT @LanguageCode  = '0'
         , @Company       = 'HRS'
         , @DocumentType  = 8
         , @DocumentLevel = 1
         , @ReminderLevel = 2
         , @LabelCode     = 'RL000012'
EXEC [dbo].[sp_UpdateUTFDocumentTranslation] @LanguageCode, @Company, @DocumentType, @DocumentLevel, @LabelCode
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateUTFDocumentTranslation_SIK2]
    @LanguageCode  varchar(10)
  , @Company       varchar(30)
  , @DocumentType  tinyint
  , @DocumentLevel int
  , @LabelCode     varchar(10)
AS
BEGIN
	SET NOCOUNT ON;
  DELETE FROM UTF
    FROM UTFDocumentTranslation UTF
    JOIN [Label Translation] LT
      ON UTF.[LanguageCode]  = LT.[Language Code]
     AND UTF.[Company]       = LT.[Company]
     AND UTF.[DocumentType]  = LT.[Document Type]
     AND UTF.[DocumentLevel] = LT.[Document Level]
    JOIN [Report Label] RL
      ON RL.[Code]= LT.[Label Code]
     AND UTF.[LabelID]       = RL.[Description]
   WHERE LT.[Language Code]  = @LanguageCode
     AND LT.[Company]        = @Company
     AND LT.[Document Type]  = @DocumentType
     AND LT.[Document Level] = @DocumentLevel
     AND LT.[Label Code]     = @LabelCode
    
;WITH _Trans (Fld, [Language Code], [Company], [Document Type], [Document Level], [Label Code], [Translation]) AS
(
  SELECT DISTINCT 1                         [Fld]
       , @LanguageCode, @Company, @DocumentType, @DocumentLevel, @LabelCode
       , CAST('' AS varchar(8000)) [Translation]
  UNION ALL
  SELECT B.Fld + 1
       , B.[Language Code]
       , B.[Company]
       , B.[Document Type]
       , B.[Document Level]
       , B.[Label Code]
       , B.[Translation] + A.[Translation]
    FROM (
          SELECT RANK() OVER (PARTITION BY [Language Code], [Company], [Document Type], [Document Level], [Label Code] ORDER BY [Line No_]  ) AS RN, [Language Code], [Company], [Document Type], [Document Level], [Label Code], [Translation] 
            FROM [Label Translation] 
           WHERE [Language Code]  = @LanguageCode
             AND [Company]        = @Company
             AND [Document Type]  = @DocumentType
             AND [Document Level] = @DocumentLevel
             AND [Label Code]     = @LabelCode
         ) A
    JOIN _Trans B
      ON B.Fld = A.RN
     AND B.[Language Code] = A.[Language Code]
     AND B.[Company]       = A.[Company]
     AND B.[Document Type] = A.[Document Type]
     AND B.[Document Level]= A.[Document Level]
     AND B.[Label Code]    = A.[Label Code]
   WHERE A.[Translation] <> ''
)
   INSERT INTO [UTFDocumentTranslation]
   SELECT A.[Language Code]
        , L.[ISO Code]
        , A.[Company]
        , A.[Document Type]
        , A.[Document Level]
        , RL.[Description]
        , RL.[Description]
        , dbo.fn_ConvertUnicode(A.[Translation]) [Translation]
     FROM _Trans A
     JOIN (SELECT [Language Code], [Company], [Document Type], [Document Level], [Label Code], MAX([Fld]) MaxFld FROM _Trans GROUP BY [Language Code], [Company], [Document Type], [Document Level], [Label Code]) B
       ON B.MaxFld = A.Fld
      AND B.[Language Code] = A.[Language Code]
      AND B.[Company]       = A.[Company]
      AND B.[Document Type] = A.[Document Type]
      AND B.[Document Level]= A.[Document Level]
      AND B.[Label Code]    = A.[Label Code]
     JOIN [HRS$Language] L
       ON L.[Code] = A.[Language Code]
     JOIN [Report Label] RL
       ON RL.[Code]= A.[Label Code]   
LEFT JOIN [UTFDocumentTranslation] UTF
       ON UTF.[LanguageCode]  = A.[Language Code]
      AND UTF.[Company]       = A.[Company]
      AND UTF.[DocumentType]  = A.[Document Type]
      AND UTF.[DocumentLevel] = A.[Document Level]
      AND UTF.[LabelID]       = RL.[Description]
    WHERE A.[Translation] <> ''
      AND UTF.Company IS NULL

END

GO
