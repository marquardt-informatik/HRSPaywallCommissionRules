USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertAffiliatePartnerVendor]    Script Date: 10.04.2024 14:31:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_InsertAffiliatePartnerVendor] @APList as varchar(max), @Vendor as varchar(max)
AS
BEGIN
DECLARE @SQL varchar(max), @NullDate varchar(max)
 SELECT @NullDate = '1753-01-01' 

SELECT @SQL = '
INSERT INTO [HRS$Affiliate Partner Vendor]([Affiliate Partner No_],[Vendor No_],[Starting Date])
SELECT AP.[No_], ''' + @Vendor + ''',''' + @NullDate + '''
  FROM [Affiliate Partner] AP
 WHERE ' + [dbo].[SQLFilter] (@APList,'AP.[No_]',0)
 
EXEC(@SQL)  
END
GO
