USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [AFFILIATE].[sp_HRS$Amadeus Office-IDs aktualisieren_SIK20180812]    Script Date: 10.04.2024 14:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

Hotel Reservation Services Robert Ragge GmbH
------------------------------------------------------------

Datum     Version  RFC    Sign Beschreibung
------------------------------------------------------------
05.07.18  HRS001          TM   new Field "Is GDS"

EXEC [AFFILIATE].[sp_HRS$Amadeus Office-IDs aktualisieren]

*/
CREATE PROCEDURE [AFFILIATE].[sp_HRS$Amadeus Office-IDs aktualisieren_SIK20180812]
AS
BEGIN
SET QUOTED_IDENTIFIER ON

DECLARE @tableHTML  NVARCHAR(MAX)
      , @mailRecipients NVARCHAR(MAX) = 'tma04@hrs.de'--'List_HRS_SQL-Jobs@hrs.de'
      , @mailProfileName NVARCHAR(MAX) = 'List_HRS_Nav_MSSQL_Jobs'
      , @TABody NVARCHAR(MAX)
      , @stepTitle VARCHAR(max)
	  , @count int


-- ---------------------------------------------------------
-- Update Travelagency from [HRS$Amadeus Import Line]
-- ---------------------------------------------------------
SET @stepTitle = 'Update Travelagency from [HRS$Amadeus Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
BEGIN TRY
    SELECT @count =COUNT(1)
	  FROM [HRS$Affiliate Postings] AP WITH (NOLOCK) 
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) 
	  ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET 
		   AP.[Travelagency No_]  = T.[No_]
		 , AP.[Travelagency Code] = T.[Travelagency Code]
	  FROM [HRS$Affiliate Postings] AP
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])

    SELECT @count =COUNT(1)
	  FROM [HRS$Affiliate Postings] AP WITH (NOLOCK) 
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
        ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) 
	  ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), ''FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th><th>Travelagency Code</th><th>New Travelagency Code</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = T.[No_], ''
		 , td = AP.[Travelagency Code], ''
		 , td = T.[Travelagency Code]
	  FROM [HRS$Affiliate Postings] AP
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
BEGIN TRY
    SELECT @count =COUNT(1)
	  FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK) 
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) 
	  ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET 
		   AP.[Travelagency No_]  = T.[No_]
		 , AP.[Travelagency Code] = T.[Travelagency Code]
	  FROM [HRS-CN$Affiliate Postings] AP
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])

    SELECT @count =COUNT(1)
	  FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK) 
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) 
	  ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), ''FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th><th>Travelagency Code</th><th>New Travelagency Code</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = T.[No_], ''
		 , td = AP.[Travelagency Code], ''
		 , td = T.[Travelagency Code]
	  FROM [HRS-CN$Affiliate Postings] AP
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
BEGIN TRY
    SELECT @count =COUNT(1)
	  FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK) 
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) 
	  ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET 
		   AP.[Travelagency No_]  = T.[No_]
		 , AP.[Travelagency Code] = T.[Travelagency Code]
	  FROM [HRS-BR$Affiliate Postings] AP
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])

    SELECT @count =COUNT(1)
	  FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK) 
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) 
	  ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), ''FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th><th>Travelagency Code</th><th>New Travelagency Code</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = T.[No_], ''
		 , td = AP.[Travelagency Code], ''
		 , td = T.[Travelagency Code]
	  FROM [HRS-BR$Affiliate Postings] AP
	  JOIN [HRS$Amadeus Import Line] AM WITH (NOLOCK) 	  
	    ON AM.[Process No_] = AP.ProcessNumber
		OR AM.[Process No_] = AP.ReservationNo
	  JOIN [Travelagency] T WITH (NOLOCK) ON T.[No_] = AM.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
	 WHERE COALESCE(AP.[Travelagency No_],0)  <> T.[No_] 
	   AND YEAR(AM.[Departure Date]) = YEAR(AP.[DepartureDate])
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

-- ---------------------------------------------------------
-- Update HRS-CN Travelagency from [Travelport Import Line]
-- ---------------------------------------------------------
SET @stepTitle = 'Update HRS-CN Travelagency from [Travelport Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
BEGIN TRY
	SELECT @count = COUNT(1) 
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET 
		   AP.[Travelagency No_] = TI.[Travelagency No_]
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]

	SELECT @count = COUNT(1) 
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), '' FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = TI.[Travelagency No_]
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

-- ---------------------------------------------------------
-- Update HRS-BR Travelagency from [Travelport Import Line]
-- ---------------------------------------------------------
SET @stepTitle = 'Update HRS-BR Travelagency from [Travelport Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
BEGIN TRY
	SELECT @count = COUNT(1)
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET 
		   AP.[Travelagency No_] = TI.[Travelagency No_]
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]

	SELECT @count = COUNT(1)
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), '' FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = TI.[Travelagency No_]
	  FROM [Travelport Import Line] TI WITH (NOLOCK)
	  JOIN [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
		ON AP.[ProcessNumber] = TI.[Process No_]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> TI.[Travelagency No_]
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

-- ---------------------------------------------------------
-- Update HRS Travelagency from [SABRE Import Line]
-- ---------------------------------------------------------
SET @stepTitle = 'Update HRS Travelagency from [SABRE Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
BEGIN TRY
	SELECT @count = COUNT(1)
	  FROM [HRS$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
  WHILE @count>0
  BEGIN
	UPDATE TOP (10000) AP SET
		   AP.[Travelagency No_] = SI.[Travelagency No_]
	  FROM [HRS$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002

	SELECT @count = COUNT(1)
	  FROM [HRS$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), '' FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = SI.[Travelagency No_]
  FROM [HRS$Affiliate Postings] AP 
  JOIN [SABRE Import Line] SI 
    ON SI.[Process No_] = AP.[ProcessNumber]
 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
   AND SI.[Travelagency No_] <> 0
   AND AP.[PostAffiliatePartnerNo] = 1044137002
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

-- ---------------------------------------------------------
-- Update HRS-CN Travelagency from [SABRE Import Line]
-- ---------------------------------------------------------
SET @stepTitle = 'Update HRS-CN Travelagency from [SABRE Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
BEGIN TRY
	SELECT @count = COUNT(1)
	  FROM [HRS-CN$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET
		   AP.[Travelagency No_] = SI.[Travelagency No_]
	  FROM [HRS-CN$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002

	SELECT @count = COUNT(1)
	  FROM [HRS-CN$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), '' FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = SI.[Travelagency No_]
	  FROM [HRS-CN$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

-- ---------------------------------------------------------
-- Update HRS-BR Travelagency from [SABRE Import Line]
-- ---------------------------------------------------------
SET @stepTitle = 'Update HRS-CN Travelagency from [SABRE Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
BEGIN TRY
	SELECT @count = COUNT(1)
	  FROM [HRS-BR$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
  WHILE @count>0
  BEGIN
	UPDATE TOP(10000) AP SET
		   AP.[Travelagency No_] = SI.[Travelagency No_]
	  FROM [HRS-BR$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
	SELECT @count = COUNT(1)
	  FROM [HRS-BR$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
  END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), '' FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>Travelagency No_</th><th>New Travelagency No_</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	SELECT td = AP.[Travelagency No_], ''
		 , td = SI.[Travelagency No_]
	  FROM [HRS-BR$Affiliate Postings] AP 
	  JOIN [SABRE Import Line] SI 
		ON SI.[Process No_] = AP.[ProcessNumber]
	 WHERE COALESCE(AP.[Travelagency No_],0) <> SI.[Travelagency No_]
	   AND SI.[Travelagency No_] <> 0
	   AND AP.[PostAffiliatePartnerNo] = 1044137002
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

-- ---------------------------------------------------------
-- Update [Rebate Line] Travelagency from [HRS$Affiliate Postings]
-- ---------------------------------------------------------
SET @stepTitle = 'Update HRS-CN Travelagency from [SABRE Import Line]'
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Start'
DECLARE @remainingCnt int
BEGIN TRY
		SELECT @remainingCnt = COUNT(1)
		  FROM [HRS$Rebate Line] RL
		  JOIN [HRS$Affiliate Postings] AP WITH (NOLOCK)
			ON AP.[ReservationNo]     = RL.[Reservation No_]
		   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
		   AND AP.[InvoiceNo]         = RL.[Invoice No_]
		  JOIN [Travelagency]           TP WITH (NOLOCK) 
			ON TP.[No_]               = AP.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
		 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]
	WHILE @remainingCnt>0 
	BEGIN
		UPDATE TOP (1000) RL SET 
			   RL.[Travelagency No_] = AP.[Travelagency No_]
		  FROM [HRS$Rebate Line] RL
		  JOIN [HRS$Affiliate Postings] AP WITH (NOLOCK)
			ON AP.[ReservationNo]     = RL.[Reservation No_]
		   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
		   AND AP.[InvoiceNo]         = RL.[Invoice No_]
		  JOIN [Travelagency]           TP WITH (NOLOCK) 
			ON TP.[No_]               = AP.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
		 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]
		 
		SELECT @remainingCnt = COUNT(1)
		  FROM [HRS$Rebate Line] RL
		  JOIN [HRS$Affiliate Postings] AP WITH (NOLOCK)
			ON AP.[ReservationNo]     = RL.[Reservation No_]
		   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
		   AND AP.[InvoiceNo]         = RL.[Invoice No_]
		  JOIN [Travelagency]           TP WITH (NOLOCK) 
			ON TP.[No_]               = AP.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
		 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]
	END
END TRY
BEGIN CATCH
       SET @TABody = '<H1>Error Step '+@stepTitle+N'</H1><table border="1"><tr><th>ErrorNumber</th><th>ErrorSeverity</th><th>ErrorState</th><th>ErrorProcedure</th><th>ErrorMessage</th></tr>'
         + CAST((SELECT td = ERROR_NUMBER(), '', td = ERROR_SEVERITY(), '', td = ERROR_STATE(), '', td = ERROR_PROCEDURE(), '', td = ERROR_MESSAGE(), '' FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) )
		 + N'</table>'
		 + N'<H1>Failed '+@stepTitle+N'</H1><table border="1"><tr><th>ReservationNo</th><th>ReservationPartNo</th><th>Travelagency No</th><th>New Travelagency No</th></tr>'
	   SET @tableHTML = @TABody + CAST ( ( 
	    SELECT td = AP.[ReservationNo], ''
		     , td = AP.[ReservationPartNo], ''
		     , td = RL.[Travelagency No_], ''
		     , td = AP.[Travelagency No_], ''
		  FROM [HRS$Rebate Line] RL
		  JOIN [HRS$Affiliate Postings] AP WITH (NOLOCK)
			ON AP.[ReservationNo]     = RL.[Reservation No_]
		   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
		   AND AP.[InvoiceNo]         = RL.[Invoice No_]
		  JOIN [Travelagency]           TP WITH (NOLOCK) 
			ON TP.[No_]               = AP.[Travelagency No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
		 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]
	   FOR XML PATH('tr'), TYPE   
		) AS NVARCHAR(MAX) ) +  
		N'</table>' ; 		  
	  EXEC msdb.dbo.sp_send_dbmail @profile_name = @mailProfileName, @recipients=@mailRecipients, @body = @tableHTML, @body_format = 'HTML'  
END CATCH
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', @stepTitle, 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', 'UPDATE AP', 'Start'
UPDATE AP SET AP.[Travelagency No_]=AI.[Travelagency No_]
  FROM [HRS$Affiliate Postings] AP WITH (NOLOCK)
  JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA BP WITH (NOLOCK)
    ON [ProcessNumber] = BP_KEY
  JOIN [HRS$Amadeus Import Line] AI WITH (NOLOCK)
    ON B_KEY = AI.[Process No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE YEAR(AP.[DepartureDate]) = YEAR(AI.[Departure Date])
   AND AP.[Travelagency No_]=0

UPDATE AP SET AP.[Travelagency No_]=AI.[Travelagency No_]
  FROM [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
  JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA BP WITH (NOLOCK)
    ON [ProcessNumber] = BP_KEY
  JOIN [HRS$Amadeus Import Line] AI WITH (NOLOCK)
    ON B_KEY = AI.[Process No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE YEAR(AP.[DepartureDate]) = YEAR(AI.[Departure Date])
   AND AP.[Travelagency No_]=0

UPDATE AP SET AP.[Travelagency No_]=AI.[Travelagency No_]
  FROM [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
  JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA BP WITH (NOLOCK)
    ON [ProcessNumber] = BP_KEY
  JOIN [HRS$Amadeus Import Line] AI WITH (NOLOCK)
    ON B_KEY = AI.[Process No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE YEAR(AP.[DepartureDate]) = YEAR(AI.[Departure Date])
   AND AP.[Travelagency No_]=0

 UPDATE AP SET AP.[Travelagency No_]=AI.[Travelagency No_]
  FROM [Partner$Affiliate Postings] AP WITH (NOLOCK)
  JOIN HRSDB.BKG_PROCESS_LIST_ALL_DA BP WITH (NOLOCK)
    ON [ProcessNumber] = BP_KEY
  JOIN [HRS$Amadeus Import Line] AI WITH (NOLOCK)
    ON B_KEY = AI.[Process No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE YEAR(AP.[DepartureDate]) = YEAR(AI.[Departure Date])
   AND AP.[Travelagency No_]=0
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', 'UPDATE AP', 'Ende'

EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', 'UPDATE RL', 'Start'
UPDATE RL SET 
       RL.[Travelagency No_] = AP.[Travelagency No_]
  FROM [HRS$Rebate Line] RL
  JOIN [HRS$Affiliate Postings] AP WITH (NOLOCK)
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]

UPDATE RL SET 
       RL.[Travelagency No_] = AP.[Travelagency No_]
  FROM [HRS$Rebate Line] RL
  JOIN [HRS-BR$Affiliate Postings] AP WITH (NOLOCK)
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]

UPDATE RL SET 
       RL.[Travelagency No_] = AP.[Travelagency No_]
  FROM [HRS$Rebate Line] RL
  JOIN [HRS-CN$Affiliate Postings] AP WITH (NOLOCK)
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]


UPDATE RL SET 
       RL.[Travelagency No_] = AP.[Travelagency No_]
  FROM [HRS$Rebate Line] RL
  JOIN [Partner$Affiliate Postings] AP WITH (NOLOCK)
    ON AP.[ReservationNo]     = RL.[Reservation No_]
   AND AP.[ReservationPartNo] = RL.[Reservation Part No_]
-- 05.07.18  HRS001          TM ++++++++++
	  JOIN [HRS$Booking Source] BS
	    ON BS.[No_] = AP.[ReservationSource]
       AND BS.[Is GDS] = 1
-- 05.07.18  HRS001          TM ----------
 WHERE RL.[Travelagency No_]  <> AP.[Travelagency No_]
EXEC AFFILIATE.[sp_Protokollierung] 'sp_HRS$Amadeus Office-IDs aktualisieren', 'UPDATE RL', 'Ende'
END

GO
