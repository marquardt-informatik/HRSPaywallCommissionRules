USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUExportDetailedCustLedgEntrHDE]    Script Date: 10.04.2024 14:31:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Detaillierte Debitorenposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUExportDetailedCustLedgEntrHDE]
	@StartDate varchar(15),
	@EndDate varchar(15),
	@WithUltimo BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @StartDateTime datetime = cast(@StartDate as datetime);
	DECLARE @EndDateTime datetime = CASE WHEN @WithUltimo = 0 THEN cast(@EndDate as datetime) ELSE cast(@EndDate as datetime) + cast('23:59:59' as datetime) END;

	SELECT CLE.[Entry No_] [Lfd. Nr.]
	     , CLE.[Cust_ Ledger Entry No_] [Debitorenposten Lfd. Nr.]
		 , '"' + CASE 
					WHEN CLE.[Entry Type] = 0 THEN ' '
					WHEN CLE.[Entry Type] = 1 THEN 'Urspr. Posten'
					WHEN CLE.[Entry Type] = 2 THEN 'Ausgleich'
					WHEN CLE.[Entry Type] = 3 THEN 'Unrealisierter Verlust'
					WHEN CLE.[Entry Type] = 4 THEN 'Unrealisierter Gewinn'
					WHEN CLE.[Entry Type] = 5 THEN 'Realisierter Verlust'
					WHEN CLE.[Entry Type] = 6 THEN 'Realisierter Gewinn'
					WHEN CLE.[Entry Type] = 7 THEN 'Skonto'
                    WHEN CLE.[Entry Type] = 8 THEN 'Skonto (ohne MwSt.)'
                    WHEN CLE.[Entry Type] = 9 THEN 'Skonto (MwSt.-Regulierung)'
                    WHEN CLE.[Entry Type] = 10 THEN 'Ausgl. Rundung'	
                    WHEN CLE.[Entry Type] = 11 THEN 'Restbetrag Korrektur'	
                    WHEN CLE.[Entry Type] = 12 THEN 'Zahlungstoleranz'
                    WHEN CLE.[Entry Type] = 13 THEN 'Skontotoleranz' 	
                    WHEN CLE.[Entry Type] = 14 THEN 'Zahlungstoleranz (ohne MwSt.)'
                    WHEN CLE.[Entry Type] = 15 THEN 'Zahlungstoleranz (MwSt.-Regulierung)'
                    WHEN CLE.[Entry Type] = 16 THEN 'Skontotoleranz (ohne MwSt.)'	
                    WHEN CLE.[Entry Type] = 17 THEN  'Skontotoleranz (MwSt.-Regulierung)'	 	
				 END + '"' [Postenart]		 
		 , CONVERT(varchar(10), CLE.[Posting Date], 104) [Buchungsdatum]
		 , '"' + CASE 
					WHEN CLE.[Document Type] = 0 THEN ' '
					WHEN CLE.[Document Type] = 1 THEN 'Zahlung'
					WHEN CLE.[Document Type] = 2 THEN 'Rechnung'
					WHEN CLE.[Document Type] = 3 THEN 'Gutschrift'
					WHEN CLE.[Document Type] = 4 THEN 'Zinsrechnung'
					WHEN CLE.[Document Type] = 5 THEN 'Mahnung'
					WHEN CLE.[Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Belegart]		
		 , coalesce(REPLACE(CAST(CAST(CLE.Amount AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Betrag]
		 , coalesce(REPLACE(CAST(CAST(CLE.[Amount (LCY)] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Betrag (MW)]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CLE.[Customer No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Kreditorennr.]
		 , '"' + CASE 
					WHEN CLE.[Initial Document Type] = 0 THEN ' '
					WHEN CLE.[Initial Document Type] = 1 THEN 'Zahlung'
					WHEN CLE.[Initial Document Type] = 2 THEN 'Rechnung'
					WHEN CLE.[Initial Document Type] = 3 THEN 'Gutschrift'
					WHEN CLE.[Initial Document Type] = 4 THEN 'Zinsrechnung'
					WHEN CLE.[Initial Document Type] = 5 THEN 'Mahnung'
					WHEN CLE.[Initial Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Urspr. Belegart]	
	     , CLE.[Applied Cust_ Ledger Entry No_] [Ausgegl. Debitorenposten Lfd. Nr.]	
	FROM [hotel_de$Detailed Cust_ Ledg_ Entry] CLE WITH (NOLOCK)
	WHERE CLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY CLE.[Entry No_]
END
GO
