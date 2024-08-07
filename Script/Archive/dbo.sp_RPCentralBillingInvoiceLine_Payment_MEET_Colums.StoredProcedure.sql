USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingInvoiceLine_Payment_MEET_Colums]    Script Date: 10.04.2024 14:31:47 ******/
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
-- 
-- 
-- 
-- 
/*
DECLARE @ReNr varchar(36)
 SELECT @ReNr = '9F233B5C-E460-4DCE-9D43-6DABD8B718D2'
EXEC [dbo].[sp_RPCentralBillingInvoiceLine_Payment_MEET_Colums] @ReNr
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingInvoiceLine_Payment_MEET_Colums] 
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
      SELECT IP.[Process No_]
		   , IP.[Invoice GUID]
           , LE.[Document No_]
           , LE.[Description]
           , IP.[Invoice No_] [External Invoice No_]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp] IP WITH (NOLOCK)
   LEFT JOIN [HRS Payment$Cust_ Ledger Entry] LE WITH (NOLOCK) ON IP.[Cust_ Ledger Entry No_]=LE.[Entry No_]
       UNION
      SELECT IP.[Process No_]
		   , IP.[Invoice GUID]
           , LE.[Document No_]
           , LE.[Description]
           , IP.[Invoice No_] [External Invoice No_]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
   LEFT JOIN [HRS Payment$Cust_ Ledger Entry] LE WITH (NOLOCK) ON IP.[Cust_ Ledger Entry No_]=LE.[Entry No_]
    )
      SELECT ROW_NUMBER() OVER(ORDER BY IP.[Process No_]) [Row Number]
           , IP.*
           , @ContractNo [Contract No_], @CompanyContractNo [Company Contract No_], @ContractDate [Contract Date], @StartDate [Start Date], @EndDate [End Date], @OfferDate [Offer Date], @PurchaseOrder [Purchase Order], @SIEMENSARENo [SIEMENS ARE No_], @ContactPerson [Contact Person], @Destination [Destination], @OrgId [Org Id], @CostCenter [Cost Center], @DBI01 [DBI01], @DBI02 [DBI02], @DBI03 [DBI03], @DBI04 [DBI04], @DBI05 [DBI05], @DBI06 [DBI06], @DBI07 [DBI07], @DBI08 [DBI08], @DBI09 [DBI09], @DBI10 [DBI10], @InquirerEMail [InquirerEMail], @HotelName [Hotel Name], @HotelAddress [Hotel Address]
           , II.[VAT Base Amount Breakfast]
           , II.[VAT Rate Breakfast]
           , II.[VAT Amount Breakfast]
           , II.[Amount Breakfast]
           , II.[VAT Base Amount F & B]
           , II.[VAT Rate F & B]
           , II.[VAT Amount F & B]
           , II.[Amount F & B]
           , II.[VAT Base Amount Logis]
           , II.[VAT Rate Logis]
           , II.[VAT Amount Logis]
           , II.[Amount Logis]
           , II.[VAT Base Amount Business]
           , II.[VAT Rate Business]
           , II.[VAT Amount Business]
           , II.[Amount Business]
           , II.[VAT Base Amount Internet]
           , II.[VAT Rate Internet]
           , II.[VAT Amount Internet]
           , II.[Amount Internet]
           , II.[VAT Base Amount Local Tax]
           , II.[VAT Rate Local Tax]
           , II.[VAT Amount Local Tax]
           , II.[Amount Local Tax]
           , II.[VAT Base Amount NoShow]
           , II.[VAT Rate NoShow]
           , II.[VAT Amount NoShow]
           , II.[Amount NoShow]
           , II.[VAT Base Amount Meeting]
           , II.[VAT Rate Meeting]
           , II.[VAT Amount Meeting]
           , II.[Amount Meeting]
           , II.[VAT Base Amount MeetingExpenses]
           , II.[VAT Rate MeetingExpenses]
           , II.[VAT Amount MeetingExpenses]
           , II.[Amount MeetingExpenses]
           , II.[VAT Base Amount Misc]
           , II.[VAT Rate Misc]
           , II.[VAT Amount Misc]
           , II.[Amount Misc]
           , II.[VAT Base Amount Tech]
           , II.[VAT Rate Tech]
           , II.[VAT Amount Tech]
           , II.[Amount Tech]
           , II.[VAT Base Amount Revers]
           , II.[VAT Rate Revers]
           , II.[VAT Amount Revers]
           , II.[Amount Revers]
           , II.[VAT Base Amount Parking]
           , II.[VAT Rate Parking]
           , II.[VAT Amount Parking]
           , II.[Amount Parking]
           , II.[VAT Base Amount Transfer]
           , II.[VAT Rate Transfer]
           , II.[VAT Amount Transfer]
           , II.[Amount Transfer]
           , II.[VAT Base Amount Deposit]
           , II.[VAT Rate Deposit]
           , II.[VAT Amount Deposit]
           , II.[Amount Deposit]
           , II.[VAT Base Amount]
           , II.[VAT Amount]
           , II.[Amount] 
           , II.[Currency Factor]
           , II.[Currency Code]
        FROM IP
        JOIN ITELYA.InvoiceLinesSum II ON II.[Invoice GUID]=IP.[Invoice GUID]
       WHERE IP.[Invoice GUID] = @ReNr
END
GO
