USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectCommissionInvoices_HRS-BR]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SelectCommissionInvoices_HRS-BR] 
    @DocumentDate Date = '2023-05-31'
AS BEGIN
;WITH DL AS
(
   SELECT DL.[Display Case No_]
        , SUM(DL.[Line Amount])              [Line Amount]
        , SUM(DL.[Line Amount (LCY)])        [Line Amount (LCY)]
        , SUM(DL.[TAF Line Amount])          [TAF Line Amount]
        , SUM(DL.[TAF Line Amount (LCY)])    [TAF Line Amount (LCY)]
        , SUM(DL.[Agency Line Amount])       [Agency Line Amount]
        , SUM(DL.[Agency Line Amount (LCY)]) [Agency Line Amount (LCY)]
        , SUM(DL.[Number of Nights])         [Number of Nights]
     FROM [DynNavHRS].dbo.[HRS-BR$Agency Display Line] DL WITH (NOLOCK)
     JOIN [DynNavHRS].dbo.[HRS-BR$Agency Display Header] DH WITH (NOLOCK) ON DH.[Case No_]=DL.[Display Case No_]
    WHERE DH.[Creation Date]=@DocumentDate
      AND DH.[Status]=0
      AND DL.[Action]<>3
 GROUP BY DL.[Display Case No_]
)

   SELECT DH.[Case No_]
        , DH.[Bill-to Customer No_]
        , CU.[HPP Webportal enabled]
        , CU.[HPP Webportal registered]
        , DH.[Document Type]
        , CU.[Payment Method Code]
        , DH.[Bill-to Name]
        , DH.[Bill-to Address]
        , DH.[Bill-to Address 2]
        , DH.[Bill-to City]
        , DH.[Bill-to Post Code]
        , DH.[Bill-to Country_Region Code]
        , DH.[Bill-to Name 2]
        , DH.[Bill-to Contact No_]
        , DH.[Bill-to Contact]
        , DH.[MuseID]
        , DH.[Currency Code]
        , DL.[Line Amount] [Invoice Amount]
        , DL.[Line Amount (LCY)] [Invoice Amount (LCY)]
        , DL.[Line Amount] * ( 100 + COALESCE(VP.[VAT %],0)) [Invoice Amount incl_ VAT]
        , DL.[Line Amount (LCY)] * ( 100 + COALESCE(VP.[VAT %],0)) [Invoice Amount (LCY) incl_ VAT]
        , DH.[Salesperson Code]
        , DL.[Number of Nights]
        , DH.[Chain Code]
        , DH.[Brand Code]
        , DH.[Posting Date]
        , DH.[Unposted Invoice No_]
        , DH.[Creation Date] [Document Date]
        , DH.[Delivery Type Fapiao]
        , DH.[Delivery Date Fapiao]
        , DH.[Fapiao No_]
        , DL.[Agency Line Amount]
        , DL.[Agency Line Amount (LCY)]
        , DL.[TAF Line Amount]
        , DL.[TAF Line Amount (LCY)]
        , CU.[E-Mail] [Customer email address]
        , CU.[VAT Registration No_] [Customer VAT Registration ID]
     FROM [DynNavHRS].dbo.[HRS-BR$Agency Display Header] DH WITH (NOLOCK)
     JOIN DL ON DL.[Display Case No_]=DH.[Case No_]
     JOIN [DynNavHRS].dbo.[HRS-BR$Customer] CU WITH (NOLOCK) ON CAST(CU.[No_] AS varchar(20))=DH.[Bill-to Customer No_]
LEFT JOIN [DynNavHRS].dbo.[HRS-BR$VAT Posting Setup] VP WITH (NOLOCK) ON VP.[VAT Bus_ Posting Group]=DH.[VAT Bus_ Posting Group] AND VP.[VAT Prod_ Posting Group]=DH.[VAT Prod_ Posting Group] AND VP.[VAT Calculation Type]=0
    WHERE DH.[Creation Date]=@DocumentDate
      AND DH.[Status]=0
END
GO
