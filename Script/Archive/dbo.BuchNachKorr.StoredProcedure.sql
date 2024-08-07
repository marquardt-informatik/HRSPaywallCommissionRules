USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[BuchNachKorr]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 05.01.2012
-- Description:	Buchungen nach Korrektur auf Kundenebene
-- =============================================
CREATE PROCEDURE [dbo].[BuchNachKorr] 
	-- Add the parameters for the stored procedure here
	@Start	AS Varchar(10) = '01.01.2007',
	@Ende	AS Varchar(10) = '01.01.2007',
	@Kunde	AS Bigint = -1
AS
BEGIN
  SELECT AP.[ReservationNo]                               AS Reservierungsnummer
       , AP.[AffiliatePartnerNo]                          AS Kundennummer
       , SUM(AP.[Amount_LCY_corr] 
       * CASE WHEN SH.[VAT Bus_ Posting Group] = 'INLAND' THEN 
           1.19 
         ELSE 
           1 
         END)                                             AS Betrag
       , CONVERT(char(10),MIN(AP.[ArivalDate]),104)       AS Anreise
       , CONVERT(char(10),MAX(AP.[DepartureDate]),104)    AS Abreise
       , AVG(PL.[Number of Person])                       AS Personen
       , MONTH(AP.[PostingDate])                          AS Periode
       , YEAR(AP.[PostingDate])                           AS Jahr
       , AP.[HotelNo]                                     AS Hotel
       , SUM(AP.[RoomNights_corr])                        AS Roomnights
       , SUM(AP.[Amount_LCY_corr] 
       * CASE WHEN SH.[VAT Bus_ Posting Group] = 'INLAND' THEN 
           1.19 
         ELSE 
           1 
         END)                                             AS [€-Betrag]
       , SH.[Currency Code]                               AS WC
       , SH.[Currency Factor]                             AS WF
       , CONVERT(char(10),MIN(AP.[ReservationDate]),104)  AS Buchungsdatum
       , PH.[Reservation Activator]                       AS Reservierungsbucher
       , PH.[Reservation Source]                          AS Reservierungsquelle
       , SUM(AP.[Turnover_LCY_corr])                      AS Umsatz
       , SUM(PL.[Breakfast Price] / PL.[Currency Faktor]) AS [Betrag-Frühstück]
       , PH.[Client Company]                              AS [Kunde Firma]
       , AP.[CountryCode]                                 AS Ländercode
       , AP.[Description]                                 AS [Gastname 1]
       , AP.[Description2]                                AS [Gastname 2]
       , AP.[AffiliateReference1]                         AS Boomerangnummer
    FROM [HRS$Affiliate Postings]        AP WITH (NOLOCK)
    JOIN [HRS$Sales Invoice Corrections] SC WITH (NOLOCK)
      ON SC.[Document No_]       = AP.[InvoiceNo]
    JOIN [HRS$Sales Invoice Header]      SH WITH (NOLOCK)
      ON SH.[No_]                = SC.[Max Document No_]
    JOIN [HRS$Posted Agency Header]      PH WITH (NOLOCK)
      ON PH.[Posted Invoice No_] = SC.[Max Document No_]
     AND PH.[Reservation No_]    = AP.[ReservationNo]
    JOIN [HRS$Posted Agency Line]        PL WITH (NOLOCK)
      ON PL.[Posted Reservation No_] = PH.[Posted Reservation No_]
     AND PL.[Position No_]           = AP.[ReservationPartNo]
   WHERE AP.[AffiliatePartnerNo] = @Kunde
     AND AP.[DepartureDate] BETWEEN @Start AND @Ende
GROUP BY AP.[ReservationNo] 
       , AP.[AffiliatePartnerNo] 
       , AP.[PostingDate] 
       , AP.[HotelNo]
       , SH.[Currency Code]
       , SH.[Currency Factor]
       , PH.[Reservation Activator]
       , PH.[Reservation Source]
       , PH.[Client Company]
       , AP.[CountryCode]
       , AP.[Description]
       , AP.[Description2]
       , AP.[AffiliateReference1]
END       
GO
