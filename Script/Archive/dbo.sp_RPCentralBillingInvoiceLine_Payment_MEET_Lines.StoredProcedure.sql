USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingInvoiceLine_Payment_MEET_Lines]    Script Date: 10.04.2024 14:31:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 28.11.2014
-- Description:	
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- 05.10.23 HRS001  ACS-4516 TM     Copy of sp_RPCentralBillingInvoiceLine_LCY
-- ------------------------------------------------------------

/*
DECLARE @ReNr varchar(36)= '2DDED493-E934-4549-9CC6-F463C692EC64'
DECLARE @ProcessNo int = 1125918

--EXEC [dbo].[sp_RPCentralBillingInvoiceLine_Payment_MEET_Lines] @ReNr


SELECT *
      FROM MEETAGO.AttributeList AD WHERE AD.[Process No_]=@ProcessNo AND AD.[Invoice GUID]=@ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingInvoiceLine_Payment_MEET_Lines] 
    @ReNr varchar(36)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT @ReNr=UPPER(@ReNr)

  DECLARE @ProcessNo int, @InvoiceCount int, @ContractNo varchar(max), @CompanyContractNo varchar(max), @ContractDate varchar(max), @StartDate varchar(max), @EndDate varchar(max), @OfferDate varchar(max), @PurchaseOrder varchar(max), @SIEMENSARENo varchar(max), @ContactPerson varchar(max), @Destination varchar(max), @OrgId varchar(max), @CostCenter varchar(max), @DBI01 varchar(max), @DBI02 varchar(max), @DBI03 varchar(max), @DBI04 varchar(max), @DBI05 varchar(max), @DBI06 varchar(max), @DBI07 varchar(max), @DBI08 varchar(max), @DBI09 varchar(max), @DBI10 varchar(max), @InquirerEMail varchar(max), @HotelName varchar(max), @HotelAddress varchar(max), @InvoiceGUID varchar(max)

    ;WITH _IH AS
	(
	  SELECT IP.[Process No_]
	       , IP.[Invoice No_]
		   , IP.[Invoice GUID]
	    FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
       WHERE [Invoice GUID] = @ReNr
       UNION
	  SELECT IP.[Process No_]
	       , IP.[Invoice No_]
		   , IP.[Invoice GUID]
	    FROM [HRS Payment$Paym_ Solution Invoice]       IP WITH (NOLOCK)
       WHERE [Invoice GUID] = @ReNr
	)
      SELECT @ProcessNo=_IH.[Process No_], @InvoiceGUID=_IH.[Invoice GUID],@InvoiceCount=COUNT(1) FROM _IH GROUP BY [Process No_], [Invoice GUID]

      PRINT @ProcessNo

    SELECT @ContractNo=[Contract No_], @CompanyContractNo=[Company Contract No_], @ContractDate=[Contract Date], @StartDate=[Start Date], @EndDate=[End Date], @OfferDate=[Offer Date], @PurchaseOrder=[Purchase Order], @SIEMENSARENo=[SIEMENS ARE No_], @ContactPerson=[Contact Person], @Destination=[Destination], @OrgId=[Org Id], @CostCenter=[Cost Center], @DBI01=[DBI01], @DBI02=[DBI02], @DBI03=[DBI03], @DBI04=[DBI04], @DBI05=[DBI05], @DBI06=[DBI06], @DBI07=[DBI07], @DBI08=[DBI08], @DBI09=[DBI09], @DBI10=[DBI10], @InquirerEMail=[InquirerEMail], @HotelName=[Hotel Name], @HotelAddress=[Hotel Address], @InvoiceGUID=[Invoice GUID]
      FROM MEETAGO.AttributeList AD WHERE AD.[Process No_]=@ProcessNo AND AD.[Invoice GUID]=@InvoiceGUID

    SELECT @ContractDate = COALESCE(@ContractDate,@OfferDate)

	;WITH IP AS
    (
      SELECT 'unposted' [Source]
           , IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
           , CASE WHEN IL.[VAT Amount]=0 THEN ROUND(IL.[Amount]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Base Amount] END [VAT Base Amount]
           , IL.[Orig_ VAT Rate] [VAT Rate]
           , CASE WHEN IL.[VAT Amount]=0 THEN IL.[Amount] - ROUND(IL.[Amount]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Amount] END [VAT Amount]
           , IL.[Amount]
           , CASE WHEN IL.[VAT Amount (LCY)]=0 THEN ROUND(IL.[Amount (LCY)]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Base Amount (LCY)] END [VAT Base Amount (LCY)]
           , CASE WHEN IL.[VAT Amount (LCY)]=0 THEN IL.[Amount (LCY)] - ROUND(IL.[Amount (LCY)]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Amount (LCY)] END [VAT Amount (LCY)]
           , IL.[Amount (LCY)]
		   , IL.[Cust_ VAT Bus_ Posting Group]
		   , IL.[Cust_ VAT Prod_ Posting Group]
		   , IP.[Invoice No_] [External Invoice No_]
		   , IP.[Invoice GUID]
           , IL.[Currency Code]
		   , @InvoiceCount Invoices
		   , IL.[Invoice Position GUID]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
       WHERE IP.[Invoice GUID] = @InvoiceGUID

       UNION
       
      SELECT 'posted' [Source]
           , IP.[Process No_]
           , IL.[Service Date]
           , IL.[Service Code]
           , IL.[Service Description]
           , CASE WHEN IL.[VAT Amount]=0 THEN ROUND(IL.[Amount]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Base Amount] END [VAT Base Amount]
           , IL.[Orig_ VAT Rate] [VAT Rate]
           , CASE WHEN IL.[VAT Amount]=0 THEN IL.[Amount] - ROUND(IL.[Amount]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Amount] END [VAT Amount]
           , IL.[Amount]
           , CASE WHEN IL.[VAT Amount (LCY)]=0 THEN ROUND(IL.[Amount (LCY)]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Base Amount (LCY)] END [VAT Base Amount (LCY)]
           , CASE WHEN IL.[VAT Amount (LCY)]=0 THEN IL.[Amount (LCY)] - ROUND(IL.[Amount (LCY)]/(100+[Orig_ VAT Rate]) * 100,2) ELSE IL.[VAT Amount (LCY)] END [VAT Amount (LCY)]
           , IL.[Amount (LCY)]
		   , IL.[Cust_ VAT Bus_ Posting Group]
		   , IL.[Cust_ VAT Prod_ Posting Group]
		   , IP.[Invoice No_] [External Invoice No_]
		   , IP.[Invoice GUID]
           , IL.[Currency Code]
		   , @InvoiceCount Invoices
		   , IL.[Invoice Position GUID]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
       WHERE IP.[Invoice GUID] = @InvoiceGUID
    )
    --SELECT * FROM IP
      SELECT ROW_NUMBER() OVER(ORDER BY IP.[Process No_],IP.[Service Date],IP.[Amount] DESC) [Row Number]
           , IP.*, @ContractNo [Contract No_], @CompanyContractNo [Company Contract No_], @ContractDate [Contract Date], @StartDate [Start Date], @EndDate [End Date], @OfferDate [Offer Date], @PurchaseOrder [Purchase Order], @SIEMENSARENo [SIEMENS ARE No_], @ContactPerson [Contact Person], @Destination [Destination], @OrgId [Org Id], @CostCenter [Cost Center], @DBI01 [DBI01], @DBI02 [DBI02], @DBI03 [DBI03], @DBI04 [DBI04], @DBI05 [DBI05], @DBI06 [DBI06], @DBI07 [DBI07], @DBI08 [DBI08], @DBI09 [DBI09], @DBI10 [DBI10], @InquirerEMail [InquirerEMail], @HotelName [Hotel Name], @HotelAddress [Hotel Address]
        FROM IP
        --JOIN MEETAGO.AttributeList AD ON IP.[Process No_]=AD.[Process No_] AND IP.[Invoice GUID]=AD.[Invoice GUID]
       WHERE IP.[Invoice GUID] = @ReNr
END
GO
