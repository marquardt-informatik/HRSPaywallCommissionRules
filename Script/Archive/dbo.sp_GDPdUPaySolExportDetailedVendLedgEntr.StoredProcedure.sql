USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_GDPdUPaySolExportDetailedVendLedgEntr]    Script Date: 10.04.2024 14:31:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sascha Altgeld (SAL)
-- Create date: 16.10.2018
-- Description:	GDPdU Export - Detaillierte Kreditorenposten
-- =============================================
CREATE PROCEDURE [dbo].[sp_GDPdUPaySolExportDetailedVendLedgEntr]
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

	SELECT VLE.[Entry No_] [Lfd. Nr.]
	     , VLE.[Vendor Ledger Entry No_] [Kreditorenposten Lfd. Nr.]
		 , '"' + CASE 
					WHEN VLE.[Entry Type] = 0 THEN ' '
					WHEN VLE.[Entry Type] = 1 THEN 'Urspr. Posten'
					WHEN VLE.[Entry Type] = 2 THEN 'Ausgleich'
					WHEN VLE.[Entry Type] = 3 THEN 'Unrealisierter Verlust'
					WHEN VLE.[Entry Type] = 4 THEN 'Unrealisierter Gewinn'
					WHEN VLE.[Entry Type] = 5 THEN 'Realisierter Verlust'
					WHEN VLE.[Entry Type] = 6 THEN 'Realisierter Gewinn'
					WHEN VLE.[Entry Type] = 7 THEN 'Skonto'
                    WHEN VLE.[Entry Type] = 8 THEN 'Skonto (ohne MwSt.)'
                    WHEN VLE.[Entry Type] = 9 THEN 'Skonto (MwSt.-Regulierung)'
                    WHEN VLE.[Entry Type] = 10 THEN 'Ausgl. Rundung'	
                    WHEN VLE.[Entry Type] = 11 THEN 'Restbetrag Korrektur'	
                    WHEN VLE.[Entry Type] = 12 THEN 'Zahlungstoleranz'
                    WHEN VLE.[Entry Type] = 13 THEN 'Skontotoleranz' 	
                    WHEN VLE.[Entry Type] = 14 THEN 'Zahlungstoleranz (ohne MwSt.)'
                    WHEN VLE.[Entry Type] = 15 THEN 'Zahlungstoleranz (MwSt.-Regulierung)'
                    WHEN VLE.[Entry Type] = 16 THEN 'Skontotoleranz (ohne MwSt.)'	
                    WHEN VLE.[Entry Type] = 17 THEN 'Skontotoleranz (MwSt.-Regulierung)'	 	
				 END + '"' [Postenart]		 
		 , CONVERT(varchar(10), VLE.[Posting Date], 104) [Buchungsdatum]
		 , '"' + CASE 
					WHEN VLE.[Document Type] = 0 THEN ' '
					WHEN VLE.[Document Type] = 1 THEN 'Zahlung'
					WHEN VLE.[Document Type] = 2 THEN 'Rechnung'
					WHEN VLE.[Document Type] = 3 THEN 'Gutschrift'
					WHEN VLE.[Document Type] = 4 THEN 'Zinsrechnung'
					WHEN VLE.[Document Type] = 5 THEN 'Mahnung'
					WHEN VLE.[Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Belegart]		
		 , coalesce(REPLACE(CAST(CAST(VLE.Amount AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Betrag]
		 , coalesce(REPLACE(CAST(CAST(VLE.[Amount (LCY)] AS DECIMAL(38,2)) AS varchar(40)), '.', ','), '0,00') [Betrag (MW)]
		 , '"' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VLE.[Vendor No_], CHAR(10), ''), CHAR(13), ''), CHAR(34), ''), CHAR(39), ''), 'Ä', 'Ae'), 'ä', 'ae'), 'Ö', 'Oe'), 'ö', 'oe'), 'Ü', 'Ue'), 'ü', 'ue'), 'ß', 'ss') + '"' [Kreditorennr.]
		 , '"' + CASE 
					WHEN VLE.[Initial Document Type] = 0 THEN ' '
					WHEN VLE.[Initial Document Type] = 1 THEN 'Zahlung'
					WHEN VLE.[Initial Document Type] = 2 THEN 'Rechnung'
					WHEN VLE.[Initial Document Type] = 3 THEN 'Gutschrift'
					WHEN VLE.[Initial Document Type] = 4 THEN 'Zinsrechnung'
					WHEN VLE.[Initial Document Type] = 5 THEN 'Mahnung'
					WHEN VLE.[Initial Document Type] = 6 THEN 'Erstattung'
				 END + '"' [Urspr. Belegart]	
	     , VLE.[Applied Vend_ Ledger Entry No_] [Ausgegl. Kreditorenposten Lfd. Nr.]	
	FROM [HRS PaySol$Detailed Vendor Ledg_ Entry] VLE WITH (NOLOCK)
	WHERE VLE.[Posting Date] between @StartDateTime AND @EndDateTime
	ORDER BY VLE.[Entry No_]
END
GO
