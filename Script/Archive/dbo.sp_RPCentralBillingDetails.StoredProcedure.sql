USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCentralBillingDetails]    Script Date: 10.04.2024 14:31:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 17.10.2017
-- Description:	Is Copy of sp_RPCentralBillingInvoiceHeader
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 
-- 
-- 
-- 
/*
DECLARE @ProzessNo varchar(20)
 SELECT @ProzessNo = '105180580'--'105344145 '--'102149406'--'103801050'
EXEC [dbo].[sp_RPCentralBillingDetails] @ProzessNo
*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCentralBillingDetails] 
    @ProzessNo VARCHAR(36)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Guests VARCHAR(250)  --Fügt alle Gäste zusammen

	;WITH _GAST AS
	(
	  SELECT DISTINCT CASE WHEN COALESCE([B_GAST2],'') <> ''
						   THEN [B_GAST1] + '; ' + [B_GAST2]
						   ELSE [B_GAST1]
					  END [Gast]
	 FROM [HRSDB].[BUCHUNG] WHERE [BP_KEY]  = @ProzessNo
	)
	
	SELECT @Guests = STUFF((
						SELECT '; ' + [Gast]
										FROM _GAST
										 FOR XML PATH('') 
									 ), 1, 1, ''
									)

    ;WITH [_PSI] AS
    (
      SELECT [PSII].[Process No_]
           , [PSII].[Vendor Posting No_]
           , [PSII].[Hotel No_]
           , [PSII].[Currency Code]												[Head Currency Code]
           , [PSII].[Vendor Posting Date]
           , [C].[Name]															[Hotel_Name]
		   , [C].[Name] + ', ' + [C].[Address] + ', ' + [C].[City]				[Hotel_Address]
		   , [C].[Country_Region Code]											[Hotel_CountryRegionCode]
		   , CASE 
               WHEN [CR].[Customer Template Code] = 1 THEN [PCVA].[Vendor No_ Domestic]
               WHEN [CR].[EU affiliation]         = 1 THEN [PCVA].[Vendor No_ EU]
               WHEN [CR].[EU affiliation]         = 1 THEN [PCVA].[Vendor No_ Other]
             END [Vendor No_]
           , [PCVA].[Customer No_]
           , [PSII].[Arrival Date]
           , [PSII].[Departure Date]
           , [PSII].[Cust_ Ledger Entry No_]
           , SUBSTRING([CLE].[Description], CHARINDEX(' PD',[CLE].[Description])+1,100) [Invoice No_]
		   , [CLE].[Due Date]
           , [PSII].[Cust_ Posting Date]
		   , [PSILI].[Amount]
		   , [PSILI].[Amount (LCY)]
		   , [PSILI].[Service Date]
		   , [PSILI].[Service Code]
		   , [PSILI].[Service Description]
		   , [PSILI].[Sales VAT Base Amount (LCY)]
		   , [PSILI].[Sales VAT Amount (LCY)]
		   , [PSILI].[Currency Code]											[Line Currency Code]
		   , [PSILI].[Cust_ VAT %]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      [PSII] WITH (NOLOCK)       
		JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] [PSILI] WITH (NOLOCK)
          ON [PSILI].[Invoice GUID] = [PSII].[Invoice GUID]
        JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] [PCVA] WITH (NOLOCK)
          ON [PCVA].[Company No_] = [PSII].[Company No_]
        JOIN [HRS$Contact]                              [C] WITH (NOLOCK)
          ON [C].[No_] = [PSII].[Hotel No_]
        JOIN [HRS$Country_Region]                       [CR] WITH (NOLOCK)
          ON [CR].[Code] = [C].[Country_Region Code]
   LEFT JOIN [HRS Payment$Cust_ Ledger Entry]			[CLE] WITH (NOLOCK)
          ON [CLE].[Entry No_] = [PSII].[Cust_ Ledger Entry No_]
	   WHERE [PSII].[Process No_] = @ProzessNo
       
	   UNION
       
      SELECT [PSI].[Process No_]
           , [PSI].[Vendor Posting No_]
           , [PSI].[Hotel No_]
           , [PSI].[Currency Code]											[Head Currency Code]
           , [PSI].[Vendor Posting Date]
           , [C].[Name]															[Hotel_Name]
		   , [C].[Name] + ', ' + [C].[Address] + ', ' + [C].[City]				[Hotel_Address]
		   , [C].[Country_Region Code]											[Hotel_CountryRegionCode]
           , CASE 
               WHEN [CR].[Customer Template Code] = 1 THEN [PCVA].[Vendor No_ Domestic]
               WHEN [CR].[EU affiliation]         = 1 THEN [PCVA].[Vendor No_ EU]
               WHEN [CR].[EU affiliation]         = 1 THEN [PCVA].[Vendor No_ Other]
             END [Vendor No_]
           , [PCVA].[Customer No_]
           , [PSI].[Arrival Date]
           , [PSI].[Departure Date]
           , [PSI].[Cust_ Ledger Entry No_]
           , SUBSTRING([CLE].[Description], CHARINDEX(' PD',[CLE].[Description])+1,100) [Invoice No_]
		   , [CLE].[Due Date]
           , [PSI].[Cust_ Posting Date]
		   , [PSIL].[Amount]
		   , [PSIL].[Amount (LCY)]
		   , [PSIL].[Service Date]
		   , [PSIL].[Service Code]
		   , [PSIL].[Service Description]
		   , [PSIL].[Sales VAT Base Amount (LCY)]
		   , [PSIL].[Sales VAT Amount (LCY)]
		   , [PSIL].[Currency Code]											[Line Currency Code]
		   , [PSIL].[Cust_ VAT %]
        FROM [HRS Payment$Paym_ Solution Invoice]       [PSI] WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line]	[PSIL] WITH (NOLOCK)
          ON [PSIL].[Invoice GUID] = [PSI].[Invoice GUID]
        JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] [PCVA] WITH (NOLOCK)
          ON [PCVA].[Company No_] = [PSI].[Company No_]
        JOIN [HRS$Contact]                              [C] WITH (NOLOCK)
          ON [C].[No_] = [PSI].[Hotel No_]
        JOIN [HRS$Country_Region]                       [CR] WITH (NOLOCK)
          ON [CR].[Code] = [C].[Country_Region Code]
        JOIN [HRS Payment$Cust_ Ledger Entry]			[CLE] WITH (NOLOCK)
          ON [CLE].[Entry No_] = [PSI].[Cust_ Ledger Entry No_]
	   WHERE [PSI].[Process No_] = @ProzessNo
    )

	, [_BU] AS
    (
      SELECT [BU].[BP_KEY]									[Process No_]
           , MAX([BU].[B_GAST1])							[Guest]
		   , MAX([BU].[B_GAST2])							[Guest2]
           , MAX([BU].[K_KEY])								[Company No_]
           , MAX([BU].[H_KEY])								[Hotel No_]
           , MIN([BU].[B_AN_DATUM])							[Arrival Date]
           , MAX([BU].[B_AB_DATUM])							[Departure Date]
		   , MAX([BU].[B_DATUM])							[Reservation Date]
		   , MAX([BU].[B_EMAIL_NEW])						[B_EMAIL_NEW]
           , MAX(COALESCE([D1].[BCDT_VALUE],''))			[DBI_PK]
           , MAX(COALESCE([D2].[BCDT_VALUE],''))			[DBI_KS]
		   , MAX(COALESCE([D3].[BCDT_VALUE],''))			[DBI_AK]
		   , MAX(COALESCE([D4].[BCDT_VALUE],''))			[DBI_RZ]
		   , MAX(COALESCE([D5].[BCDT_VALUE],''))			[DBI_DS]
		   , MAX(COALESCE([D6].[BCDT_VALUE],''))			[DBI_AU]
		   , MAX(COALESCE([D7].[BCDT_VALUE],''))			[DBI_AE]
		   , MAX(COALESCE([D8].[BCDT_VALUE],''))			[DBI_PR]
		   , MAX(COALESCE([D9].[BCDT_VALUE],''))			[DBI_BD]
		   , MAX(COALESCE([D10].[BCDT_VALUE],''))			[DBI_IK]
		   , MAX(COALESCE([CCPC].[UATP_CARD_HOLDER],''))	[UATP_CARD_HOLDER]
		   , MAX(COALESCE([CCPC].[UATP_CARD_NUMBER],''))	[UATP_CARD_NUMBER]
        FROM [HRSDB].[BUCHUNG] [BU]					WITH (NOLOCK)
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D1] WITH (NOLOCK)
          ON [D1].[B_KEY] = [BU].[B_KEY]
         AND [D1].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_PK' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D2] WITH (NOLOCK)
          ON [D2].[B_KEY] = [BU].[B_KEY]
         AND [D2].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_KS' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D3] WITH (NOLOCK)
          ON [D3].[B_KEY] = [BU].[B_KEY]
         AND [D3].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_AK' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D4] WITH (NOLOCK)
          ON [D4].[B_KEY] = [BU].[B_KEY]
         AND [D4].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_RZ' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D5] WITH (NOLOCK)
          ON [D5].[B_KEY] = [BU].[B_KEY]
         AND [D5].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_DS' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D6] WITH (NOLOCK)
          ON [D6].[B_KEY] = [BU].[B_KEY]
         AND [D6].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_AU' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D7] WITH (NOLOCK)
          ON [D7].[B_KEY] = [BU].[B_KEY]
         AND [D7].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_AE' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D8] WITH (NOLOCK)
          ON [D8].[B_KEY] = [BU].[B_KEY]
         AND [D8].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_PR' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D9] WITH (NOLOCK)
          ON [D9].[B_KEY] = [BU].[B_KEY]
         AND [D9].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_BD' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_TEXT_DA] [D10] WITH (NOLOCK)
          ON [D10].[B_KEY] = [BU].[B_KEY]
         AND [D10].BP_GROUP_ID in (SELECT [ATTRIBUTE_NUMBER] FROM [HRSDB].[CUS_CI_CUSTOM_BOOKING_ATTRIBUTE] WHERE [ATTRIBUTE_NAME] = 'DBI_IK' GROUP BY [ATTRIBUTE_NUMBER])
   LEFT JOIN [HRSDB].[BKG_CI_DATA_DA]	[CI] WITH (NOLOCK)
          ON [CI].[B_KEY] = [BU].[B_KEY]
   LEFT JOIN [HRSDB].[CUS_CI_PAYMENT_CONFIGURATION] [CCPC] WITH (NOLOCK)
          ON [CCPC].[ID_VALUE] = [CI].[PAYMENT_CONFIGURATION_ID]
	   WHERE [BU].[BP_KEY] = @ProzessNo
    GROUP BY [BU].[BP_KEY]
	)

	, [_K_KEY] AS
	(
	  SELECT [BU].[BP_KEY]									[Process No_]
		   , REPLACE([C].[VAT Registration No_], ' ', '')	[VAT Registration No_]
		   , [C].[Country_Region Code]	
        FROM [HRSDB].[BUCHUNG]							[BU]	WITH (NOLOCK)	
   LEFT JOIN [HRS Payment$Paym_ Cust _ Vend Assignment]	[PCVA]	WITH (NOLOCK)
		  ON [PCVA].[Company No_] = [BU].[K_KEY]
   LEFT JOIN [HRS Payment$Customer]						[C]		WITH (NOLOCK)
		  ON [C].[No_] = [PCVA].[Customer No_] 
	   WHERE [BU].[BP_KEY] = @ProzessNo
	     AND [C].[VAT Registration No_] <> ''
    GROUP BY [BU].[BP_KEY], [C].[VAT Registration No_], [C].[Country_Region Code]	 	   
	)

    SELECT CASE WHEN LEN([_BU].[UATP_CARD_NUMBER])>'' THEN SUBSTRING([_BU].[UATP_CARD_NUMBER],1,4) + ' xxxx xxxx ' + RIGHT([_BU].[UATP_CARD_NUMBER],4) ELSE '' END [Kartennummer]
         , [_BU].[UATP_CARD_HOLDER]										[Karteninhaber-Name]
         , ''     														[Karteninhaber-Stadt]
		 , [_PSI].[Invoice No_]											[Rechnungsnummer]
		 , [_PSI].[Cust_ Posting Date]									[Rechnungsdatum]
		 , [_PSI].[Amount (LCY)]										[Bruttobetrag]
		 , ''															[Positionsnummer]
		 , [_PSI].[Service Code]										[Leistungsart]
		 , @ProzessNo													[Dokumentennummer]
		 , @Guests 														[Name]
		 , [_PSI].[Service Description]									[Routing]
		 , [_BU].UATP_CARD_HOLDER										[Leistungserbringer]
         , [_PSI].[Vendor Posting Date]								    [VerkaufsDatum]
         , [_PSI].[Arrival Date]										[ReiseDatum]
         , ''     														[Klasse]
		 , ''     														[AirlineCode]
         , [_PSI].[Head Currency Code]									[VerkaufsWaehrung]
		 , [_PSI].[Sales VAT Base Amount (LCY)]							[Netto(VW)]
		 , [_PSI].[Sales VAT Amount (LCY)]								[MwSt(VW)]
         , [_PSI].[Line Currency Code]									[AbrechnungsWaehrung]
		 , [_PSI].[Amount (LCY)]										[Brutto(AW)]
         , [_BU].[DBI_RZ]												[Details]
         , [_BU].[DBI_PK]												[Personal-ID]
         , [_BU].[DBI_DS]												[Dienststelle]
         , [_BU].[DBI_KS]     											[Kostenstelle]
         , [_BU].[DBI_AE]												[Abrechnungseinheit]
         , [_BU].[DBI_AU]												[Internes Konto]
         , [_BU].[DBI_BD]												[Bearbeitungsdatum]
         , [_BU].[DBI_PR]												[Projektnummer]
         , [_BU].[DBI_AK]												[Auftragsnummer]
         , [_PSI].[Process No_]											[Aktionsnummer]
         , [_PSI].[Hotel_Address] 										[Reiseziel]
         , [_BU].[DBI_IK]												[Kundenreferenz]
		 , ''     														[Nullrechnungsnummer]
		 , ''     														[IATA-nummer]
		 , [_PSI].[Cust_ VAT %]											[MwSt-Satz (%)]
         , ''     														[Geb.-Zeichen]
         , ''     														[CC_Leistungscode]
         , ''     														[DOM-Kennzeichen]
		 , [_PSI].[Due Date]											[Fälligkeitstag]
		 , ''     														[Zusatzversicherung]
		 , CONVERT(VARCHAR(10), [_BU].[Arrival Date], 104) + ' - ' + 
		   CONVERT(VARCHAR(10), [_BU].[Departure Date], 104)			[Leistungsbeschreibung1]
		 , [_PSI].[Service Description]									[Leistungsbeschreibung2]
		 , [_PSI].[Hotel_Name]											[Leistungsbeschreibung3]
		 , ''     														[Gebuehren]
		 , ''     														[A.I.D.A. Nummer]
		 , ''     														[Mwst Typ]
		 , 'HRS Payment Solution GmbH'									[Name Rechnungssteller]
		 , [VI].[VAT Identifier]										[USt-IdNr. Rechnungssteller (Airplus)]
		 , [_K_KEY].[VAT Registration No_]     							[USt-IdNr. von Würth]
		 , [_BU].[B_EMAIL_NEW]   										[Email]
      FROM [_PSI]
 LEFT JOIN [_BU]
		ON [_BU].[Process No_] = [_PSI].[Process No_]
 LEFT JOIN [_K_KEY]
		ON [_K_KEY].[Process No_] = [_PSI].[Process No_]
 LEFT JOIN [HRS Payment$VAT Identifier Assignement]			[VIA]	WITH (NOLOCK)
		ON [VIA].[Customer Country_Region Code] = [_K_KEY].[Country_Region Code]
	   AND [VIA].[Hotel Country_Region Code] = [_PSI].[Hotel_CountryRegionCode]
 LEFT JOIN [HRS Payment$VAT Identifier]						[VI]	WITH (NOLOCK)
		ON [VI].[VAT Identifier Code] = [VIA].[VAT Identifier Code]
END
GO
