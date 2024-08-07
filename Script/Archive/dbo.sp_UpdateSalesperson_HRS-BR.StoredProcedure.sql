USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateSalesperson_HRS-BR]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 09.07.2014
-- Description:	Aktualisiert den Verkäufercode im Mandanten HRS
/*
EXEC [dbo].[sp_UpdateSalesperson_HRS-BR]
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateSalesperson_HRS-BR]
AS
BEGIN
DECLARE @DebitCollSalesPerson varchar(10) = ''
 SELECT @DebitCollSalesPerson = [Debit Coll_ Salesperson Code] FROM [HRS-BR$Sales & Receivables Setup] 

DECLARE @Salesperson varchar(10)
      , @CountrySelection varchar(max)
      , @CustomerFilter varchar(max)
	  , @ResponsibilityCenter varchar(max)
      , @CustomerFilterFrom varchar(max)
      , @CustomerFilterTo varchar(max)
      , @PostcodeFilter varchar(max)
      , @PostcodeFilterFrom varchar(max)
      , @PostcodeFilterTo varchar(max)
      , @SQL varchar(max)

DECLARE cur CURSOR FOR
SELECT TL.[Salesperson_Purchaser Code]
     , TL.[Country Filter]
     , TL.[Customer Filter]
     , TL.[Post Code Filter]
	 , TL.[Responsibility Center]
  FROM [HRS-BR$Team Line] TL WITH (NOLOCK)
 WHERE TL.[Salesperson_Purchaser Code] <> 'BUCH'
--   AND TL.[Salesperson_Purchaser Code] = 'SSC02'
  
OPEN cur
FETCH NEXT FROM cur INTO @Salesperson, @CountrySelection, @CustomerFilter, @PostcodeFilter, @ResponsibilityCenter

WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT @CustomerFilterFrom = '1', @CustomerFilterTo = '9999999'
  IF (CHARINDEX('..',@CustomerFilter,1)>0) 
    BEGIN
      SET @CustomerFilterFrom = SUBSTRING(@CustomerFilter,1,CHARINDEX('..',@CustomerFilter,1)-1)
      SET @CustomerFilterTo = SUBSTRING(@CustomerFilter,CHARINDEX('..',@CustomerFilter,1)+2,10)
    END
  IF (CHARINDEX('..',@PostcodeFilter,1)>0) 
    BEGIN
      SET @PostcodeFilterFrom = SUBSTRING(@PostcodeFilter,1,CHARINDEX('..',@PostcodeFilter,1)-1)
      SET @PostcodeFilterTo = SUBSTRING(@PostcodeFilter,CHARINDEX('..',@PostcodeFilter,1)+2,10)
    END
  PRINT @Salesperson + ' ' + @CountrySelection + ' ' + @CustomerFilterFrom + ', ' + @CustomerFilterTo + ' ' + @PostcodeFilter
  IF @PostcodeFilter = ''
    BEGIN
      UPDATE CO SET 
	         CO.[Salesperson Code] = CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
        FROM [HRS-BR$Contact] CO
        JOIN [HRS-BR$Customer] CU ON CO.[No_] = CU.[No_]
       WHERE CO.[Salesperson Code] <> CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
         AND (('|'+@CountrySelection+'|' LIKE '%|'+CO.[Country_Region Code]+'|%' AND @CountrySelection<>'') OR (@CountrySelection=''))
         AND CO.[No_] BETWEEN @CustomerFilterFrom AND @CustomerFilterTo
         --AND NOT CO.[Contract Status] IN ('10','11')
         
      UPDATE CU SET 
	         CU.[Salesperson Code] = CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
		   , CU.[Responsibility Center] = CASE WHEN @ResponsibilityCenter='' THEN CU.[Responsibility Center] ELSE @ResponsibilityCenter END
        FROM [HRS-BR$Customer] CU
        JOIN [HRS-BR$Contact] CO ON CO.[No_] = CU.[No_]
       WHERE (
	         CU.[Salesperson Code] <> CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
          OR CU.[Responsibility Center] <> CASE WHEN @ResponsibilityCenter='' THEN CU.[Responsibility Center] ELSE @ResponsibilityCenter END
		     )
         AND (('|'+@CountrySelection+'|' LIKE '%|'+CO.[Country_Region Code]+'|%' AND @CountrySelection<>'') OR (@CountrySelection=''))
         AND CO.[No_] BETWEEN @CustomerFilterFrom AND @CustomerFilterTo    
         --AND NOT CO.[Contract Status] IN ('10','11')
    END
  IF @PostcodeFilter <> ''
    BEGIN
      UPDATE CO SET CO.[Salesperson Code] = CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
        FROM [HRS-BR$Contact] CO
        JOIN [HRS-BR$Customer] CU ON CO.[No_] = CU.[No_]
       WHERE CO.[Salesperson Code] <> CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
         AND (('|'+@CountrySelection+'|' LIKE '%|'+CO.[Country_Region Code]+'|%' AND @CountrySelection<>'') OR (@CountrySelection=''))
         AND CO.[No_] BETWEEN @CustomerFilterFrom AND @CustomerFilterTo
         AND CO.[Post Code] BETWEEN @PostcodeFilterFrom AND @PostcodeFilterTo
         --AND NOT CO.[Contract Status] IN ('10','11')
         
      UPDATE CU SET 
	         CU.[Salesperson Code] = CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END
		   , CU.[Responsibility Center] = CASE WHEN @ResponsibilityCenter='' THEN CU.[Responsibility Center] ELSE @ResponsibilityCenter END
        FROM [HRS-BR$Customer] CU
        JOIN [HRS-BR$Contact] CO ON CO.[No_] = CU.[No_]
       WHERE (
	         CU.[Salesperson Code] <> CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE @Salesperson END 
          OR CU.[Responsibility Center] <> CASE WHEN @ResponsibilityCenter='' THEN CU.[Responsibility Center] ELSE @ResponsibilityCenter END
		     )
         AND (('|'+@CountrySelection+'|' LIKE '%|'+CO.[Country_Region Code]+'|%' AND @CountrySelection<>'') OR (@CountrySelection=''))
         AND CO.[No_] BETWEEN @CustomerFilterFrom AND @CustomerFilterTo
         AND CO.[Post Code] BETWEEN @PostcodeFilterFrom AND @PostcodeFilterTo
         --AND NOT CO.[Contract Status] IN ('10','11')
    END
  FETCH NEXT FROM cur INTO @Salesperson, @CountrySelection, @CustomerFilter, @PostcodeFilter, @ResponsibilityCenter 
END

CLOSE cur
DEALLOCATE cur

UPDATE CU SET CU.[Salesperson Code] = CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
  FROM [HRS-BR$Customer] CU
  JOIN [Chain] BR
    ON CU.[Chain] = BR.[Code]
 WHERE (CU.[Contract Status] IN ('10','11') OR BR.[Includes Extranet Hotels]=1)
   AND CU.[Chain] <> '99999'
   AND BR.[Salesperson Code] <> ''
   AND CU.[Salesperson Code] <> CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
   
UPDATE CU SET CU.[Salesperson Code] = CASE WHEN CO.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
  FROM [HRS-BR$Contact] CU
  JOIN [Chain] BR
    ON CU.[Chain] = BR.[Code]
  JOIN [HRS-BR$Customer] CO WITH (NOLOCK)
    ON CO.[No_]= CU.[No_]
 WHERE (CU.[Contract Status] IN ('10','11') OR BR.[Includes Extranet Hotels]=1)
   AND CU.[Chain] <> '99999'
   AND BR.[Salesperson Code] <> ''
   AND CU.[Salesperson Code] <> CASE WHEN CO.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
   
UPDATE CU SET CU.[Salesperson Code] = CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
  FROM [HRS-BR$Customer] CU
  JOIN [Brand] BR
    ON CU.[Brand] = BR.[Code]
 WHERE (CU.[Contract Status] IN ('10','11') OR BR.[Includes Extranet Hotels]=1)
   --AND CU.[Chain] = '99999'
   AND BR.[Salesperson Code] <> ''
   AND CU.[Salesperson Code] <> CASE WHEN CU.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
   
UPDATE CU SET CU.[Salesperson Code] = CASE WHEN CO.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END
  FROM [HRS-BR$Contact] CU
  JOIN [Brand] BR
    ON CU.[Brand] = BR.[Code]
  JOIN [HRS-BR$Customer] CO WITH (NOLOCK)
    ON CO.[No_]= CU.[No_]
 WHERE (CU.[Contract Status] IN ('10','11') OR BR.[Includes Extranet Hotels]=1)
   --AND CU.[Chain] = '99999'
   AND BR.[Salesperson Code] <> ''   
   AND CU.[Salesperson Code] <> CASE WHEN CO.[Closed for more Bookings]=1 AND @DebitCollSalesPerson<>'' THEN @DebitCollSalesPerson ELSE BR.[Salesperson Code] END

      UPDATE DH SET DH.[Salesperson Code] = CO.[Salesperson Code]
        FROM [HRS-BR$Agency Display Header] DH 
        JOIN [HRS-BR$Customer] CO WITH (NOLOCK)
          ON CO.[No_] = DH.[Bill-to Customer No_]
       WHERE DH.[Salesperson Code] <> CO.[Salesperson Code]
         AND DH.[Status] = 0
         AND DH.[Correction from] = ''
         AND DH.[Subsequent Debit from] = ''

  ;WITH RM AS
  (
SELECT CU.[No_]
     , CASE 
	     WHEN CU.[Contract Status] IN ('10','11') OR CU.[Salesperson Code] IN ('SDA03','MEN01','FBE02','SBA10') THEN
           'CRS'  
         WHEN CH.[Reminder Terms Code]<>'' THEN
           CH.[Reminder Terms Code]
		 ELSE
	       CR.[Reminder Termscode]
       END [Reminder Termscode]
  FROM [HRS-BR$Customer] CU WITH (NOLOCK)
  JOIN [HRS-BR$Country_Region] CR WITH (NOLOCK)
    ON CR.[Code] = CU.[Country_Region Code]
  JOIN [Chain] CH WITH (NOLOCK)
    ON CH.[Code] = CU.[Chain]
  )
  UPDATE CU SET CU.[Reminder Terms Code] = RM.[Reminder Termscode]
    FROM [HRS-BR$Customer] CU
	JOIN RM
      ON RM.[No_] = CU.[No_]
   WHERE CU.[Reminder Terms Code] <> RM.[Reminder Termscode]

END
GO
