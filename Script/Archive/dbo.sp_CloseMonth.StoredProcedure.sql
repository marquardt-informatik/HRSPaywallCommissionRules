USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_CloseMonth]    Script Date: 10.04.2024 14:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_CloseMonth] 
    @AllowPostingFrom        date    = '2016-10-01'
  , @AllowPostingFromSpecial date    = '2016-09-01'
  , @SoftClose               varchar(20) = '09'
AS
BEGIN

  UPDATE [HRS$General Ledger Setup]              SET [Allow Posting From] = @AllowPostingFrom
  UPDATE [Codenet$General Ledger Setup]          SET [Allow Posting From] = @AllowPostingFrom
  UPDATE [Hotel Solutions$General Ledger Setup]  SET [Allow Posting From] = @AllowPostingFrom
  UPDATE [HRS-BR$General Ledger Setup]           SET [Allow Posting From] = @AllowPostingFrom
  UPDATE [HRS-CN$General Ledger Setup]           SET [Allow Posting From] = @AllowPostingFrom

  UPDATE US SET US.[Allow Posting From] = @AllowPostingFromSpecial FROM [Windows User] WU WITH (NOLOCK) JOIN [HRS$User Setup] US ON US.[User ID] = WU.[Short ID] WHERE WU.[Security Role] IN ('08','09','11') AND WU.[deleted] = 0
  UPDATE US SET US.[Allow Posting From] = @AllowPostingFromSpecial FROM [Windows User] WU WITH (NOLOCK) JOIN [Codenet$User Setup] US ON US.[User ID] = WU.[Short ID] WHERE WU.[Security Role] IN ('08','09','11') AND WU.[deleted] = 0
  UPDATE US SET US.[Allow Posting From] = @AllowPostingFromSpecial FROM [Windows User] WU WITH (NOLOCK) JOIN [Hotel Solutions$User Setup] US ON US.[User ID] = WU.[Short ID] WHERE WU.[Security Role] IN ('08','09','11') AND WU.[deleted] = 0
  UPDATE US SET US.[Allow Posting From] = @AllowPostingFromSpecial FROM [Windows User] WU WITH (NOLOCK) JOIN [HRS-BR$User Setup] US ON US.[User ID] = WU.[Short ID] WHERE WU.[Security Role] IN ('08','09','11') AND WU.[deleted] = 0
  UPDATE US SET US.[Allow Posting From] = @AllowPostingFromSpecial FROM [Windows User] WU WITH (NOLOCK) JOIN [HRS-CN$User Setup] US ON US.[User ID] = WU.[Short ID] WHERE WU.[Security Role] IN ('08','09','11') AND WU.[deleted] = 0

  IF NOT COALESCE(@SoftClose,'')=''
  BEGIN
    UPDATE US SET US.[Allow Posting From] = '1753-01-01' FROM [Windows User] WU WITH (NOLOCK) JOIN [HRS$User Setup]             US ON US.[User ID] = WU.[Short ID] WHERE ','+WU.[Security Role]+',' LIKE '%,'+@SoftClose+',%' AND WU.[deleted] = 0
    UPDATE US SET US.[Allow Posting From] = '1753-01-01' FROM [Windows User] WU WITH (NOLOCK) JOIN [Codenet$User Setup]         US ON US.[User ID] = WU.[Short ID] WHERE ','+WU.[Security Role]+',' LIKE '%,'+@SoftClose+',%' AND WU.[deleted] = 0
    UPDATE US SET US.[Allow Posting From] = '1753-01-01' FROM [Windows User] WU WITH (NOLOCK) JOIN [Hotel Solutions$User Setup] US ON US.[User ID] = WU.[Short ID] WHERE ','+WU.[Security Role]+',' LIKE '%,'+@SoftClose+',%' AND WU.[deleted] = 0
    UPDATE US SET US.[Allow Posting From] = '1753-01-01' FROM [Windows User] WU WITH (NOLOCK) JOIN [HRS-BR$User Setup]          US ON US.[User ID] = WU.[Short ID] WHERE ','+WU.[Security Role]+',' LIKE '%,'+@SoftClose+',%' AND WU.[deleted] = 0
    UPDATE US SET US.[Allow Posting From] = '1753-01-01' FROM [Windows User] WU WITH (NOLOCK) JOIN [HRS-CN$User Setup]          US ON US.[User ID] = WU.[Short ID] WHERE ','+WU.[Security Role]+',' LIKE '%,'+@SoftClose+',%' AND WU.[deleted] = 0
  END

END
GO
