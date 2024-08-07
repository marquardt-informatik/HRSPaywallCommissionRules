USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCustomerBankInformation2_HRS-Payment]    Script Date: 10.04.2024 14:31:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 06.09.2013
-- Description:	IBAN-Schreiben 
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 06.09.13 HRS001    79988  TM     erstellt
/*
DECLARE @CustomerNo int
 SELECT @CustomerNo = 460607
EXEC [dbo].[sp_RPCustomerBankInformation2] @CustomerNo
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCustomerBankInformation2_HRS-Payment] 
    @CustomerNo varchar(25)
AS
BEGIN
   SELECT CU.[No_] [Hotel No_]
        , CU.[Name] 
        , CU.[Name 2]
        , CU.[Address] 
        , CU.[Address 2]
        , CU.[Post Code]
        , CU.[City]
        , CU.[Phone No_] 
        , CU.[Fax No_]
        , CU.[E-Mail]
        , CU.Contact
        , CR.[Name] [Country Name]
        , BA.[IBAN]
        , CR.[max_ IBAN Length]
        , BA.[SWIFT Code]
        , CASE WHEN COALESCE(CU.[Language Code],'') = '' THEN '0' ELSE CU.[Language Code] END [Language Code]
        , CASE 
            WHEN CU.[Contract Status] IN ('10','11') THEN '3634'
            WHEN COALESCE(RC.[Fax No_],'') = ''      THEN COALESCE(PG.[Fax Extension for Reminder],'392') 
            ELSE COALESCE(RC.[Fax No_],'') 
          END [Fax Extension]
     FROM [HRS Payment$Customer] CU WITH (NOLOCK)
LEFT JOIN [HRS Payment$Customer Bank Account] BA WITH (NOLOCK) 
       ON BA.[Customer No_] = CU.[No_]
      AND BA.[Clearing] = 1
LEFT JOIN [HRS Payment$Responsibility Center]  RC WITH (READUNCOMMITTED)
       ON CU.[Responsibility Center] = RC.Code
LEFT JOIN [HRS Payment$Printer Group]          PG WITH (READUNCOMMITTED)
       ON PG.[Code] = CU.[Salesperson Code]
     JOIN [HRS Payment$Country_Region] CR WITH (NOLOCK)
       ON CR.[Code]= CASE WHEN COALESCE(CU.[Country_Region Code],'') = '' THEN '33' ELSE CU.[Country_Region Code] END
    WHERE CU.[No_] = @CustomerNo
--      AND LEFT(BA.[Code],2) = 'S_'
END


GO
