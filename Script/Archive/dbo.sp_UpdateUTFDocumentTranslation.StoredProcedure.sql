USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateUTFDocumentTranslation]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt	
-- Create date: 21.07.2011
-- Description:	Änderungen in der Tabelle [Label Translation] werden in das Unicode-Pendant geschrieben
--
-- 24.09.18 HRS001 ACS-1082 DJU - Added ValidFrom
/*
DECLARE @LanguageCode  varchar(10)
      , @Company       varchar(30)
      , @DocumentType  tinyint
      , @DocumentLevel int
      , @LabelCode     varchar(10)
	  , @ValidFrom     date
    SELECT @LanguageCode  = '0'
         , @Company       = 'HRS'
         , @DocumentType  = 12
         , @DocumentLevel = 0
         , @LabelCode     = 'RL000010'
		 , @ValidFrom     = '2021-01-01'
EXEC [dbo].[sp_UpdateUTFDocumentTranslation] @LanguageCode, @Company, @DocumentType, @DocumentLevel, @LabelCode, @ValidFrom
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateUTFDocumentTranslation]
    @LanguageCode  varchar(10)
  , @Company       varchar(30)
  , @DocumentType  tinyint
  , @DocumentLevel int
  , @LabelCode     varchar(10)
-- 24.09.18 DJU >>>>>>>>>>>>>>>>>>>> HRS001
  , @ValidFrom        date
-- 24.09.18 DJU <<<<<<<<<<<<<<<<<<<< HRS001
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
	 -- 24.09.18 DJU >>>>>>>>>>>>>>>>>>>> HRS001
	 AND UTF.[ValidFrom]     = LT.[Valid From]
	 -- 24.09.18 DJU <<<<<<<<<<<<<<<<<<<< HRS001
    JOIN [Report Label] RL
      ON RL.[Code]= LT.[Label Code]
     AND UTF.[LabelID]       = RL.[Description]
   WHERE LT.[Language Code]  = @LanguageCode
     AND LT.[Company]        = @Company
     AND LT.[Document Type]  = @DocumentType
     AND LT.[Document Level] = @DocumentLevel
     AND LT.[Label Code]     = @LabelCode
	 -- 24.09.18 DJU >>>>>>>>>>>>>>>>>>>> HRS001
	 AND LT.[Valid From]      = @ValidFrom
	 -- 24.09.18 DJU <<<<<<<<<<<<<<<<<<<< HRS001

DECLARE @OutStr nvarchar(max) = ''
  
 SELECT @OutStr = @OutStr + [Translation]
   FROM [Label Translation] 
  WHERE [Language Code]  = @LanguageCode
    AND [Company]        = @Company
    AND [Document Type]  = @DocumentType
    AND [Document Level] = @DocumentLevel
    AND [Label Code]     = @LabelCode
	-- 24.09.18 DJU >>>>>>>>>>>>>>>>>>>> HRS001
	AND [Valid From]     = @ValidFrom
	-- 24.09.18 DJU <<<<<<<<<<<<<<<<<<<< HRS001

    
  DECLARE @UnicodeList TABLE ([String] varchar(max))
   INSERT INTO @UnicodeList
     EXEC [dbo].[sp_Split] @OutStr,'\u'
  
;WITH UL AS
(
  SELECT DISTINCT [String] FROM @UnicodeList
)
   SELECT @OutStr = REPLACE(@OutStr,'\u'+LEFT([String],4),nchar(dbo.fn_HexToIntnt(LEFT([String],4)))) 
     FROM UL
    WHERE NOT dbo.fn_HexToIntnt(LEFT([String],4)) IS NULL

  
--IF @OutStr > ''
BEGIN 
   INSERT INTO [UTFDocumentTranslation]
   SELECT @LanguageCode
        , L.[ISO Code]
        , @Company
        , @DocumentType
        , @DocumentLevel
        , RL.[Description]
        , RL.[Description]
        , @OutStr
		-- 24.09.18 DJU >>>>>>>>>>>>>>>>>>>> HRS001
		, @ValidFrom
		-- 24.09.18 DJU <<<<<<<<<<<<<<<<<<<< HRS001
     FROM [HRS$Language] L, [Report Label] RL
    WHERE RL.[Code]= @LabelCode  
      AND L.[Code] = @LanguageCode 
  END
END

GO
