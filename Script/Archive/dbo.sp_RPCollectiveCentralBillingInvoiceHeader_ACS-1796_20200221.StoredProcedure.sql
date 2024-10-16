USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPCollectiveCentralBillingInvoiceHeader_ACS-1796_20200221]    Script Date: 10.04.2024 14:31:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 12.05.15
-- Description:	
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 13.06.16          100013      
-- 24.04.18  HRS002  ACS-482 DJU    Added Field Cancellation
-- 12.10.18  HRS003 ACS-1135 SAL    Added Field [AirPlus Invoice No.] from CC Invoice Line
-- 18.01.19  HRS004          DJU    Prevent Division by Zero
-- 29.07.19  HRS005 INC0021842 SAL  Extend JOIN Condition in Statement part "AL"  
-- 20.12.19  HRS006 ACS-2082 DJU    Added Field [IsTOMS] 
/*
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'R000003404'
EXEC [dbo].[sp_RPCollectiveCentralBillingInvoiceHeader] @ReNr
*/

*/
-- ============================================= 
CREATE PROCEDURE [dbo].[sp_RPCollectiveCentralBillingInvoiceHeader_ACS-1796_20200221] 
    @ReNr varchar(25)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @Count int=0
     SELECT @Count = COALESCE(COUNT(1),0)
	   FROM [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS Payment$Sales Line] SL WITH (NOLOCK)
         ON SL.[Document No_] = CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	   JOIN [HRS Payment$Sales Header] SH WITH (NOLOCK)
	     ON SH.[No_] = SL.[Document No_] 
	  WHERE SH.[No_] = @ReNr

    IF @Count=0
	BEGIN
     SELECT @Count = COALESCE(COUNT(1),0)
	   FROM [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS Payment$Cust_ CC Invoice Header] CH WITH (NOLOCK)
	     ON CC.[CC Invoice Entry No_] = CH.[Entry No_]
	   JOIN [HRS Payment$Sales Invoice Header] SH WITH (NOLOCK)
	     ON SH.[Pre-Assigned No_] = CC.[Document No_] 
	   JOIN [HRS Payment$Sales Invoice Line] SL WITH (NOLOCK)
         ON SH.[Pre-Assigned No_]= CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	  WHERE @ReNr In (SH.[No_], SH.[Pre-Assigned No_])
	END
	
	IF @Count=0
	BEGIN
    -- Insert statements for procedure here
    ;WITH IP AS
    (
      SELECT IP.[Process No_]
	       , IP.[Company No_]
           , SUM(IL.[VAT Base Amount]) [VAT Base Amount]
           , SUM(IL.[VAT Amount]) [VAT Amount]
           , SUM(IL.[Amount]) [Amount]
        FROM [HRS Payment$Paym_ Solution Inv_ Imp]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Inv_ Line Imp] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
    GROUP BY IP.[Process No_]
	       , IP.[Company No_]
       UNION
       
      SELECT IP.[Process No_]
	       , IP.[Company No_]
           , SUM(IL.[VAT Base Amount]) [VAT Base Amount]
           , SUM(IL.[VAT Amount]) [VAT Amount]
           , SUM(IL.[Amount]) [Amount]
        FROM [HRS Payment$Paym_ Solution Invoice]      IP WITH (NOLOCK)
        JOIN [HRS Payment$Paym_ Solution Invoice Line] IL WITH (NOLOCK)
          ON IL.[Invoice GUID] = IP.[Invoice GUID]
    GROUP BY IP.[Process No_]
	       , IP.[Company No_]
    ), AL AS
	(
	  SELECT AH.[No_]
	       , AH.[Bill-to Customer No_] [Customer No_]
		   , AH.[Posting Date]
		   , IP.[Company No_]
           , SUM(IP.[VAT Base Amount]) [VAT Base Amount]
           , SUM(IP.[VAT Amount]) [VAT Amount]
           , SUM(IP.[Amount]) [Amount]
	    FROM [HRS Payment$Sales Invoice Line] AL WITH (NOLOCK)
	    JOIN [HRS Payment$Sales Invoice Header] AH WITH (NOLOCK)
	      ON AH.[No_] = AL.[Document No_]
	    JOIN IP ON IP.[Process No_] = AL.[Line No_] or IP.[Process No_] = AL.[Reservation No_] -- HRS005 - add 2nd condition
       WHERE (AH.[No_] = @ReNr OR AH.[Pre-Assigned No_] = @ReNr)
    GROUP BY AH.[No_]
	       , AH.[Bill-to Customer No_]
		   , AH.[Posting Date]
		   , IP.[Company No_]
UNION
	  SELECT AH.[No_]
	       , AH.[Bill-to Customer No_] [Customer No_]
		   , AH.[Posting Date]
		   , IP.[Company No_]
           , SUM(IP.[VAT Base Amount]) [VAT Base Amount]
           , SUM(IP.[VAT Amount]) [VAT Amount]
           , SUM(IP.[Amount]) [Amount]
	    FROM [HRS Payment$Sales Line] AL WITH (NOLOCK)
	    JOIN [HRS Payment$Sales Header] AH WITH (NOLOCK)
	      ON AH.[No_] = AL.[Document No_]
	    JOIN IP ON IP.[Process No_] = AL.[Line No_] or IP.[Process No_] = AL.[Reservation No_] -- HRS005 - add 2nd condition
       WHERE AH.[No_] = @ReNr
	     AND AH.[Document Type] = 2
    GROUP BY AH.[No_]
	       , AH.[Bill-to Customer No_]
		   , AH.[Posting Date]
		   , IP.[Company No_]
	), EP AS
	(
	SELECT AL.[Customer No_]
	     , MAX(CASE WHEN [FieldID] = 2 THEN EP.[Content] ELSE NULL END) [Bill-to Name]
	     , MAX(CASE WHEN [FieldID] = 4 THEN EP.[Content] ELSE NULL END) [Bill-to Name 2]
	     , MAX(CASE WHEN [FieldID] = 5 THEN EP.[Content] ELSE NULL END) [Bill-to Address]
	     , MAX(CASE WHEN [FieldID] = 6 THEN EP.[Content] ELSE NULL END) [Bill-to Address 2]
	     , MAX(CASE WHEN [FieldID] = 7 THEN EP.[Content] ELSE NULL END) [Bill-to City]
	     , MAX(CASE WHEN [FieldID] = 50012 THEN EP.[Content] ELSE '' END) [Country Name]
	  FROM AL
 LEFT JOIN [ExtendedProperties] EP WITH (NOLOCK) 
        ON AL.[Customer No_] = EP.KeyField1Value
	   AND EP.[TableID] = 18
	   AND EP.[FieldID] IN (2,4,5,6,7,50012)
  GROUP BY AL.[Customer No_]
	), IH AS
	(
	SELECT AH.[Bill-to Customer No_] [Customer No_]
	     , AH.[Bill-to Address]
	     , AH.[Bill-to Address 2]
		 , AH.[Bill-to Name]
		 , AH.[Bill-to Name 2]
		 , AH.[Bill-to City]
		 , AH.[Bill-to Country_Region Code]
	  FROM [HRS Payment$Sales Header] AH WITH (NOLOCK)
	 WHERE AH.[No_] = @ReNr
UNION
	SELECT AH.[Bill-to Customer No_] [Customer No_]
	     , AH.[Bill-to Address]
	     , AH.[Bill-to Address 2]
		 , AH.[Bill-to Name]
		 , AH.[Bill-to Name 2]
		 , AH.[Bill-to City]
		 , AH.[Bill-to Country_Region Code]
	  FROM [HRS Payment$Sales Invoice Header] AH WITH (NOLOCK)
	 WHERE (AH.[No_] = @ReNr OR AH.[Pre-Assigned No_] = @ReNr)
	)
    SELECT AL.[Customer No_]
         , AL.[Posting Date]            [Posting Date]
         , CASE WHEN CU.[Language Code]='' THEN 
		     COALESCE(CR.[Primary Language Code],'1') 
		   ELSE 
		     CU.[Language Code] 
		   END                          [Language Code]
         , CASE WHEN EP.[Bill-to Name] IS NULL THEN IH.[Bill-to Address]   ELSE EP.[Bill-to Address]   END [Bill-to Address]
         , CASE WHEN EP.[Bill-to Name] IS NULL THEN IH.[Bill-to Address 2] ELSE EP.[Bill-to Address 2] END [Bill-to Address 2]
         , CASE WHEN EP.[Bill-to Name] IS NULL THEN IH.[Bill-to Name]      ELSE EP.[Bill-to Name]      END [Bill-to Name]
		 , CASE WHEN EP.[Bill-to Name] IS NULL THEN IH.[Bill-to Name 2]    ELSE EP.[Bill-to Name 2]    END [Bill-to Name 2]
         , CASE WHEN EP.[Bill-to Name] IS NULL THEN IH.[Bill-to City]      ELSE EP.[Bill-to City]      END [Bill-to City]
         , CASE WHEN EP.[Bill-to Name] IS NULL THEN CR.[Name]              ELSE EP.[Country Name]      END [Bill-to Country Name]
         , CU.[Post Code]               [Bill-to Post Code]
         , CU.[Country_Region Code]     [Bill-to Country Code]
         , CU.[Contact]                 [Bill-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CR.[EU Country_Region Code]  [EU Ländercode]
         , SP.[Fax Extension]
         , SP.[Phone Extension]
         , RTRIM(BA.[Bank Branch No_])  [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_]) [Bank Account No_] 
         , RTRIM(BA.[Name])             [Bank Name]
         , RTRIM(BA.[IBAN])             [IBAN]
         , RTRIM(BA.[SWIFT Code])       [BIC]
         , LA.[ISO Code]                [ISO_Code]
         , AL.[VAT Base Amount]
         , AL.[VAT Amount]
         , AL.[Amount]
		 , CU.[VAT Registration No_]
         , CASE WHEN LEN(CA.[UATP Card Number])>'' THEN SUBSTRING(CA.[UATP Card Number],1,4) + ' xxxx xxxx ' + RIGHT(CA.[UATP Card Number],3) ELSE '' END [UATP Card Number]
		 , CA.[UATP Card Valid Until]
		 , CA.[UATP Card Holder]
		 , AL.[Customer No_] + '_' + CAST(YEAR(AL.[Posting Date]) AS char(4)) + '/' + RIGHT('00'+CAST(DATEPART(mm,AL.[Posting Date]) AS varchar(2)),2) +CASE WHEN PSH.[VAT Bus_ Posting Group]='AUSLAND' THEN '' ELSE '_'+PSH.[VAT Bus_ Posting Group] END [Invoice No.] 
		 -- HRS002 >>
		 , PSH.Cancellation [Cancellation]
		 -- HRS002 <<
		 -- HRS006 >>
		 , 0 [IsTOMS]
		 -- HRS006 <<
      FROM AL
	  JOIN IH ON IH.[Customer No_] = AL.[Customer No_]
	  JOIN [HRS Payment$Sales Header] PSH WITH (NOLOCK)
	  ON PSH.No_ = AL.[No_]
 LEFT JOIN EP ON EP.[Customer No_] = AL.[Customer No_]
   	  JOIN [HRS Payment$Paym_ Cust _ Vend Assignment] CA WITH (READUNCOMMITTED)
	    ON CA.[Company No_] = AL.[Company No_]
 LEFT JOIN [HRS Payment$Customer]             CU WITH (READUNCOMMITTED)
        ON AL.[Customer No_]                = CU.[No_] 
 LEFT JOIN [HRS$Country_Region]               CR WITH (READUNCOMMITTED)
        ON CU.[Country_Region Code]         = CR.Code
 LEFT JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON CU.[Language Code]               = LA.Code 
 LEFT JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AL.[Customer No_]                = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
    END
  END
 PRINT @Count
  IF @Count>0
  BEGIN
    ;WITH AL AS
	(
	 SELECT CH.[Customer No_]
	      , SH.[Posting Date]
          , SH.[Bill-to Address]
          , SH.[Bill-to Address 2] 
          , SH.[Bill-to Name]     
		  , SH.[Bill-to Name 2]   
          , SH.[Bill-to City]     
		  -- HRS002 >>
		  , MAX(SH.Cancellation) [Cancellation]
		  -- HRS002 <<
		  -- HRS004 >>
	      --, SUM(CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Net Amount (SC)]) [VAT Base Amount]
	      --, SUM(CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Tax(SC)]) [VAT Amount]
		  , SUM(CASE WHEN CC.[Gross Amount] * CC.[Net Amount (SC)] <> 0 THEN CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Net Amount (SC)] else 0 END) [VAT Base Amount]
	      , SUM(CASE WHEN CC.[Gross Amount] * CC.[Tax(SC)] <> 0 THEN CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Tax(SC)] ELSE 0 END) [VAT Amount]
		  -- HRS004 <<
	      , SUM(CC.[Gross Amount (BC)]) [Amount]
		  , REPLACE(SH.[Posting Description],'.csv','')+CASE WHEN SH.[VAT Bus_ Posting Group]='AUSLAND' THEN '' ELSE '_'+SH.[VAT Bus_ Posting Group] END [Invoice No.]
		  , VI.[VAT Identifier]
		  -- HRS003 >>
		  , MAX(CC.[Invoice No_]) [AirPlus Invoice No.]
		  -- HRS003 <<
		  -- HRS006 >>
		  , CASE WHEN SH.Area = 'TOMS' THEN 1 ELSE 0 END [IsTOMS]
		  -- HRS006 <<
	   FROM [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS Payment$Cust_ CC Invoice Header] CH WITH (NOLOCK)
	     ON CC.[CC Invoice Entry No_] = CH.[Entry No_]
	   JOIN [HRS Payment$Sales Line] SL WITH (NOLOCK)
         ON SL.[Document No_] = CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	   JOIN [HRS Payment$Sales Header] SH WITH (NOLOCK)
	     ON SH.[No_] = SL.[Document No_] 
	   JOIN [HRS Payment$Paym_ Solution Invoice] IP WITH (NOLOCK)
	     ON CC.[Invoice GUID] = IP.[Invoice GUID]
	   JOIN [HRS Payment$Contact] CO WITH (NOLOCK)
	     ON CO.[No_] = IP.[Hotel No_]
  LEFT JOIN [HRS Payment$VAT Identifier Assignement] VA WITH (NOLOCK)
         ON VA.[Customer Country_Region Code] = SH.[Bill-to Country_Region Code]
		AND VA.[Hotel Country_Region Code] = CO.[Country_Region Code]
  LEFT JOIN [HRS Payment$VAT Identifier] VI WITH (NOLOCK)
         ON VI.[VAT Identifier Code] = VA.[VAT Identifier Code]
	  WHERE SH.[No_] = @ReNr
   GROUP BY CH.[Customer No_]
	      , SH.[Posting Date]
          , SH.[Bill-to Address]
          , SH.[Bill-to Address 2] 
          , SH.[Bill-to Name]     
		  , SH.[Bill-to Name 2]   
          , SH.[Bill-to City]   
		  , REPLACE(SH.[Posting Description],'.csv','')+CASE WHEN SH.[VAT Bus_ Posting Group]='AUSLAND' THEN '' ELSE '_'+SH.[VAT Bus_ Posting Group] END  
		  , VI.[VAT Identifier]
		  -- HRS006 >>
		  , CASE WHEN SH.Area = 'TOMS' THEN 1 ELSE 0 END
		  -- HRS006 <<
UNION
	 SELECT CH.[Customer No_]
	      , SH.[Posting Date]
          , SH.[Bill-to Address]
          , SH.[Bill-to Address 2] 
          , SH.[Bill-to Name]     
		  , SH.[Bill-to Name 2]   
          , SH.[Bill-to City]     
		  -- HRS002 >>
		  , 0 [Cancellation]
		  -- HRS002 <<
	      , SUM(CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Net Amount (SC)]) [VAT Base Amount]
	      , SUM(CC.[Gross Amount (BC)]/CC.[Gross Amount] * CC.[Tax(SC)]) [VAT Amount]
	      , SUM(CC.[Gross Amount (BC)]) [Amount]
		  , REPLACE(SH.[Posting Description],'.csv','')+CASE WHEN SH.[VAT Bus_ Posting Group]='AUSLAND' THEN '' ELSE '_'+SH.[VAT Bus_ Posting Group] END [Invoice No.]
		  , VI.[VAT Identifier]
		  -- HRS003 >>
		  , MAX(CC.[Invoice No_]) [AirPlus Invoice No.]
		  -- HRS003 <<
		  -- HRS006 >>
		  , CASE WHEN SH.Area = 'TOMS' THEN 1 ELSE 0 END [IsTOMS]
		  -- HRS006 <<
	   FROM [HRS Payment$Cust_ CC Invoice Line] CC WITH (NOLOCK)
	   JOIN [HRS Payment$Cust_ CC Invoice Header] CH WITH (NOLOCK)
	     ON CC.[CC Invoice Entry No_] = CH.[Entry No_]
	   JOIN [HRS Payment$Sales Invoice Header] SH WITH (NOLOCK)
	     ON SH.[Pre-Assigned No_] = CC.[Document No_] 
	   JOIN [HRS Payment$Sales Invoice Line] SL WITH (NOLOCK)
         ON SH.[Pre-Assigned No_]= CC.[Document No_] 
        AND SL.[Line No_] = CC.[Line No_]
	   JOIN [HRS Payment$Paym_ Solution Invoice] IP WITH (NOLOCK)
	     ON CC.[Invoice GUID] = IP.[Invoice GUID]
	   JOIN [HRS Payment$Contact] CO WITH (NOLOCK)
	     ON CO.[No_] = IP.[Hotel No_]
  LEFT JOIN [HRS Payment$VAT Identifier Assignement] VA WITH (NOLOCK)
         ON VA.[Customer Country_Region Code] = SH.[Bill-to Country_Region Code]
		AND VA.[Hotel Country_Region Code] = CO.[Country_Region Code]
  LEFT JOIN [HRS Payment$VAT Identifier] VI WITH (NOLOCK)
         ON VI.[VAT Identifier Code] = VA.[VAT Identifier Code]
	  WHERE @ReNr In (SH.[No_], SH.[Pre-Assigned No_])
   GROUP BY CH.[Customer No_]
	      , SH.[Posting Date]
          , SH.[Bill-to Address]
          , SH.[Bill-to Address 2] 
          , SH.[Bill-to Name]     
		  , SH.[Bill-to Name 2]   
          , SH.[Bill-to City]   
		  , REPLACE(SH.[Posting Description],'.csv','')+CASE WHEN SH.[VAT Bus_ Posting Group]='AUSLAND' THEN '' ELSE '_'+SH.[VAT Bus_ Posting Group] END  
		  , VI.[VAT Identifier]
		  -- HRS006 >>
		  , CASE WHEN SH.Area = 'TOMS' THEN 1 ELSE 0 END
		  -- HRS006 <<
	), CA AS
	(
	SELECT DISTINCT CA.[Customer No_],CA.[UATP Card Holder],CA.[UATP Card Number],CA.[UATP Card Valid Until]
   	  FROM [HRS Payment$Paym_ Cust _ Vend Assignment] CA WITH (READUNCOMMITTED)
	  JOIN AL
	    ON CA.[Customer No_] = AL.[Customer No_]
	)
	SELECT AL.[Customer No_]
	     , AL.[Posting Date]
         , CASE WHEN CU.[Language Code]='' THEN 
		     COALESCE(CR.[Primary Language Code],'1') 
		   ELSE 
		     CU.[Language Code] 
		   END                          [Language Code]
         , AL.[Bill-to Address]
         , AL.[Bill-to Address 2] 
         , AL.[Bill-to Name]     
		 , AL.[Bill-to Name 2]   
         , AL.[Bill-to City]     
         , CR.[Name]                                              [Bill-to Country Name]
         , CU.[Post Code]               [Bill-to Post Code]
         , CU.[Country_Region Code]     [Bill-to Country Code]
         , CU.[Contact]                 [Bill-to Contact]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CR.[EU Country_Region Code]  [EU Ländercode]
         , SP.[Fax Extension]
         , SP.[Phone Extension]
         , RTRIM(BA.[Bank Branch No_])  [Bank Branch No_]
         , RTRIM(BA.[Bank Account No_]) [Bank Account No_] 
         , RTRIM(BA.[Name])             [Bank Name]
         , RTRIM(BA.[IBAN])             [IBAN]
         , RTRIM(BA.[SWIFT Code])       [BIC]
         , LA.[ISO Code]                [ISO_Code]
		 , AL.[VAT Base Amount]
		 , AL.[VAT Amount]
		 , AL.[Amount]
		 , CU.[VAT Registration No_]
         , CASE WHEN LEN(CA.[UATP Card Number])>'' THEN SUBSTRING(CA.[UATP Card Number],1,4) + ' xxxx xxxx ' + RIGHT(CA.[UATP Card Number],3) ELSE '' END [UATP Card Number]
		 , CA.[UATP Card Valid Until]
		 , CA.[UATP Card Holder]
		 , AL.[Invoice No.]
		 , COALESCE(AL.[VAT Identifier], VI.[VAT Identifier] ) [VAT Identifier]
		 -- HRS002 >>
		 , AL.Cancellation [Cancellation]
		 -- HRS002 <<
		 -- HRS003 >>
		  , AL.[AirPlus Invoice No.]
		 -- HRS003 <<
		 -- HRS006 >>
		 , AL.[IsTOMS]
		 -- HRS006 <<
	  FROM AL
   	  JOIN CA
	    ON CA.[Customer No_] = AL.[Customer No_]
 LEFT JOIN [HRS Payment$Customer]             CU WITH (READUNCOMMITTED)
        ON AL.[Customer No_]                = CU.[No_] 
 LEFT JOIN [HRS$Country_Region]               CR WITH (READUNCOMMITTED)
        ON CU.[Country_Region Code]         = CR.Code
 LEFT JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON CU.[Language Code]               = LA.Code 
 LEFT JOIN [HRS$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AL.[Customer No_]                = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
      JOIN [HRS Payment$VAT Identifier] VI WITH (NOLOCK)
         ON VI.[VAT Identifier Code] = 'ROW' 	
  END
GO
