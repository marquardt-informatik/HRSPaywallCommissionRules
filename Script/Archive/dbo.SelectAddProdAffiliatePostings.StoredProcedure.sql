USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectAddProdAffiliatePostings]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectAddProdAffiliatePostings]
    @MaxEntryNo int
AS
BEGIN
SELECT AP.*,SI.[Max Entry No_]
  FROM DynNavHRS.dbo.[HRS$Additional Affiliate Postings] AP WITH (NOLOCK)
  JOIN DynNavHRS.dbo.[HRS$Add.Prod. Sales Invoice Corrections] SI WITH (NOLOCK) ON SI.[Min Document No_]=AP.[InvoiceNo]
 WHERE SI.[Max Entry No_]>@MaxEntryNo
END
GO
