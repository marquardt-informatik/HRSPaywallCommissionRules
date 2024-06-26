USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Helper2]    Script Date: 10.04.2024 14:31:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_Helper2]
AS
BEGIN
SELECT [Invoice No_] [Rechnung-Nr.]
     , [Process Number] [Vorgangsnumer]
     , [Reservation No_] [Buchungs-Nr.]
	 , [Reservation Part No_] [Pos.-Nr.]
	 , [Turnover (LCY)] [Hotelumsatz]
	 , [Turnover (LCY) (corr_)] [Hotelumsatz (korr.)]
     , [Affiliate Partner No_] [Kunden-Nr.]
	 , [Reservation Date] [Reservierungsdatum]
	 , [Arival Date] [Anreisedatum]
	 , [Departure Date] [Abreisedatum]
	 , [Hotel No_] [Hotel-Nr.]
	 , [Room Nights] [Übernachtungen]
	 , [Room Nights Post Corection] [Übernachtungen (korr.)]
  FROm DynNavHRS.dbo.V0000008553_2016 V
  JOIN dynNavHRS.dbo.Split('Prozent,Fix,Prozent+Fix,Prozent ohne Frstk,Prozent ohne Frstk+Fix,Online,Zusatzprovision,% netto Logis,% netto Logis + Frstk,% Nettoumsatz,keine Angaben,Fix pro RN,Default,Company Rate',',')
    ON [Index] = V.[Commission Type]+1
 WHERE [Tab] = 'COMPANYRATE'
ORDER BY [Reservation No_],[Reservation Part No_]
 END
GO
