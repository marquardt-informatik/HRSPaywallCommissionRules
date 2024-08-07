USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[CorrectChain550]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 31.10.22
-- Description:	Correct the Chain ID see ACS-4091
/*
EXEC [dbo].[CorrectChain550]
*/
-- Date     Version   RFC    Sign.  Description
-- ------------------------------------------------------------
-- 03.11.22 HRS001    ACS-4091  TM  Creation
CREATE PROCEDURE [dbo].[CorrectChain550] AS
BEGIN
UPDATE BU SET 
       BU.KE_BID=550
  FROM HRSDB.BUCHUNG BU WITH (NOLOCK)
 WHERE BU.KE_ID IN (18,930,2431,1985,2829,659)
   AND BU.KE_BID <> 550
   AND BU.B_AB_DATUM>='2022-10-01'

UPDATE BU SET 
       BU.[Chain ID]='550'
  FROM [HRS$Agency Header] BU WITH (NOLOCK)
 WHERE BU.[Brand ID] IN ('18','930','2431','1985','2829','659')
   AND BU.[Chain ID] <> '550'
   AND BU.[Departure Date]>='2022-10-01'
END
GO
