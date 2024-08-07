USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[CorrectChain795]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 21.07.22
-- Description:	Correct the Chain ID based on HMD
/*
EXEC [dbo].[CorrectChain795]
*/
-- Date     Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 01.08.22 HRS001    ACS-3977  TM  Creation
CREATE PROCEDURE [dbo].[CorrectChain795] AS
BEGIN
UPDATE BU SET 
       BU.KE_BID=795
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
 WHERE BU.KE_ID IN (795)
   AND BU.KE_BID <> 795

UPDATE BU SET 
       BU.[Chain ID]='795'
  FROM [HRS$Agency Header] BU WITH (NOLOCK)
 WHERE BU.[Brand ID] IN ('795')
   AND BU.[Chain ID] <> '795'
END   
   
  
GO
