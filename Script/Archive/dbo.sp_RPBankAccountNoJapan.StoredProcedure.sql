USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPBankAccountNoJapan]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Sascha Altgeld
-- Create date: 12.12.2018
-- Description:	Ausgabe des Virtuellen Bankkontos für Deutsche Bank Japan
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 12.12.18 HRS001  ACS-1168 SAL    Created
/*
DECLARE @CustomerNo varchar(20)
 SELECT @CustomerNo = '7420'
EXEC [dbo].[sp_RPBankAccountNoJapan] @CustomerNo
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPBankAccountNoJapan] 
    @CustomerNo varchar(20)
AS
BEGIN
	SET NOCOUNT ON;

	WITH CU AS
	(	
		SELECT [No_] [Customer No_]
		     , [Country_Region Code]  
		FROM [HRS$Customer] WITH (NOLOCK)
		WHERE [No_] = @CustomerNo
	), VirtAcc AS 
	(		
		SELECT [Virtual Account No_] 
		FROM [HRS$Customer Virtual Account] WITH (NOLOCK) 
		WHERE [Customer No_] = @CustomerNo
			
	), Bank AS
	(	
		SELECT [Bank Account No_]
		FROM [HRS$Bank Account] WITH (NOLOCK)
		WHERE [No_] = 'DB JAPAN'
	)

	SELECT CU.[Customer No_]
	     , CU.[Country_Region Code]
		 , CASE 
			WHEN CU.[Country_Region Code] <> '67' THEN ''
			WHEN CU.[Country_Region Code] = '67' AND VirtAcc.[Virtual Account No_] <> '' THEN VirtAcc.[Virtual Account No_]	   
			WHEN CU.[Country_Region Code] = '67' AND VirtAcc.[Virtual Account No_] IS NULL THEN Bank.[Bank Account No_]
		   END [Account No_]
	FROM CU
		LEFT JOIN VirtAcc
		ON 1 = 1
		LEFT JOIN Bank
		ON 1 = 1    
END

GO
