USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceHeader_HRS-CN]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 17.06.2011
-- Description:	Kopie der SP vom P-NAV-MSSQL-1
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 07.07.11 HRS001    27148  JH bss Um die Servicegebühr im Beleg darzustellen wurde die Berechnung für Mwst und Amount geändert. Außerdem das
--                                  Feld Service Amount hinzugefügt.
-- 21.09.11 HRS002    49724  TM     [Hide Amount] eingefügt zur Steuerung der Ausgabe der Betragswerte
-- 24.04.15 HRS005    94215  TM     identify Fapiao
-- 13.10.16 HRS007    NAV-342  TM   Wrong Service Daterange on Report when [Posting Date] <> [Creation Date]
-- 22.02.20 HRS008   ACS-1991 DJU   Added TAF
-- 30.03.19 HRS009   ACS-2222 DJU   Added 6% VAT
--
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = 'CN1536794/01'
EXEC [dbo].[sp_RPKommSalesInvoiceHeader_HRS-CN] @ReNr

SELECT * FROM [HRS-CN$Agency Display Header] AH WHERE AH.[Posted Invoice No_] = @ReNr
*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceHeader_HRS-CN] 
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr

	-- 24.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS005
	DECLARE @HasFapiao int = 0, @DeliveryType int, @DeliveryDate date, @FapiaoNo varchar(20)
    SELECT @HasFapiao = MAX(CASE WHEN [Document Type] = '9' THEN 1 ELSE 0 END)
	     , @DeliveryType = MAX(CASE WHEN [Document Type] = '9' THEN [Delivery Type Fapiao] ELSE 0 END)
		 , @DeliveryDate = MAX(CASE WHEN [Document Type] = '9' THEN [Delivery Date Fapiao] ELSE 0 END)
		 , @FapiaoNo     = MAX(CASE WHEN [Document Type] = '9' THEN [Fapiao No_]           ELSE '' END)
	  FROM [HRS-CN$Agency Display Header] WITH (NOLOCK)
	WHERE [Posted Invoice No_] LIKE CASE WHEN CHARINDEX('/',@ReNr)>0 THEN LEFT(@ReNr, CHARINDEX('/',@ReNr)-1) ELSE @ReNr END +'%'
    -- 24.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS005

    -- Insert statements for procedure here    
	SELECT AH.[Bill-to Customer No_]
		 -- 13.10.16 TM >>>>>>>>>>>>>>>>>>>> HRS007
         , MAX(DATEADD(dd,-1,DATEADD(mm,1,DATEADD(dd,1-DATEPART(dd,AL.[Departure Date]),AL.[Departure Date])))) [Posting Date]
         -- Original : , AH.[Posting Date]
		 -- 13.10.16 TM <<<<<<<<<<<<<<<<<<<< HRS007
         , AH.[Creation Date]                  [Document Date]
         , AH.[Currency Code]
         , CASE WHEN AH.[Currency Factor]=0 THEN 1 ELSE AH.[Currency Factor] END [Currency Factor]
         , AH.[Language Code]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name]          ELSE P1.[Content]       END [Sell-to Customer Name]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name 2]        ELSE P2.[Content]       END [Sell-to Customer Name 2]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address]       ELSE P3.[Content]       END [Sell-to Address]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address 2]     ELSE P4.[Content]       END [Sell-to Address 2]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to City]          ELSE P5.[Content]       END [Sell-to City]
         , AH.[Bill-to Post Code]           AS [Sell-to Post Code]
         , AH.[Bill-to Country_Region Code] AS [Sell-to Country Code]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                    ELSE P6.[Content]       END Name
         , CO.[EU Country_Region Code][EU Ländercode]
         , SP.[Fax Extension]                                   [Durchwahl Fax]
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]                                            [Bank Name]
         , BA.[IBAN]                                            [IBAN]
         , LA.[ISO Code]                                        [ISO_Code]
		 -- 30.03.20 DJU >>>>>>>>>>>>>>>>>>>> HRS009
         -- , CASE WHEN AH.[Bill-to Country_Region Code] = '33' THEN 19   ELSE 0 END [VAT]
		 , CASE 
		     WHEN AH.[Bill-to Country_Region Code] = '33' THEN 19 
			 WHEN AH.[Creation Date] >= '2020-04-30' THEN 6
			 ELSE 0 
		   END [VAT]
		 -- 30.03.20 DJU <<<<<<<<<<<<<<<<<<<< HRS009
         , SUM(ROUND(AL.[Line Amount],2))                                [Amount]
         , SUM(ROUND(AL.[Line Amount],2)) 
		 -- 30.03.20 DJU >>>>>>>>>>>>>>>>>>>> HRS009
         -- * CASE WHEN AH.[Bill-to Country_Region Code] = '33' THEN 0.19 ELSE 0 END [Mwst]
		 * CASE 
		     WHEN AH.[Bill-to Country_Region Code] = '33' THEN 0.19 
			 WHEN AH.[Creation Date] >= '2020-04-30' THEN 0.06
			 ELSE 0 
		   END [Mwst]
		 -- 30.03.20 DJU <<<<<<<<<<<<<<<<<<<< HRS009
         , SUM(ROUND(AL.[Line Amount],2)) 
		 -- 30.03.20 DJU >>>>>>>>>>>>>>>>>>>> HRS009
         -- * CASE WHEN AH.[Bill-to Country_Region Code] = '33' THEN 1.19 ELSE 1 END [Total]
		 * CASE 
		     WHEN AH.[Bill-to Country_Region Code] = '33' THEN 1.19 
			 WHEN AH.[Creation Date] >= '2020-04-30' THEN 1.06
			 ELSE 1 
		   END [Total]
		 -- 30.03.20 DJU <<<<<<<<<<<<<<<<<<<< HRS009
         , MAX(CAST(JO.[Contract Status] AS int))               [Vertrag Status]
         , COALESCE(DA.[Hide Amount],0)                         [Hide Amount]
         , MAX(CO.Continent)                                    Continent
         , MAX(CASE WHEN CO.[Bank Country Code]<>'' THEN 1 ELSE 0 END) SEPA
-- 24.04.15 TM >>>>>>>>>>>>>>>>>>>> HRS005
         , @DeliveryType [Delivery Type Fapiao]
         , @DeliveryDate [Delivery Date Fapiao]
         , @HasFapiao [has Fapiao]
		 , MAX(AL.[Commission Rate]) [Commission Rate]
		 , @FapiaoNo [Fapiao No_]
-- 24.04.15 TM <<<<<<<<<<<<<<<<<<<< HRS005
		 -- 22.02.20 DJU >>>>>>>>>>>>>>>>>>>> HRS008
		 , SUM(ROUND(AL.[Line Amount],2)) - SUM(ROUND(AL.[TAF Line Amount],2)) [Commission Amount]
		 , SUM(ROUND(AL.[TAF Line Amount],2)) [TAF Amount]
		 -- 22.02.20 DJU <<<<<<<<<<<<<<<<<<<< HRS008
      FROM [HRS-CN$Agency Display Header]        AH WITH (READUNCOMMITTED)
      JOIN [HRS-CN$Agency Display Line]          AL WITH (READUNCOMMITTED)
        ON AL.[Display Case No_] = AH.[Case No_]
       AND AL.[Action] <> 3	  
      JOIN [HRS-CN$Customer]                     CU WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = CU.[No_] 
      JOIN [HRS-CN$Country_Region]               CO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Country_Region Code] = CO.Code
 LEFT JOIN [HRS-CN$Language]                     LA WITH (READUNCOMMITTED)
        ON AH.[Language Code]               = LA.Code 
 LEFT JOIN [HRS-CN$Printer Group]                SP WITH (READUNCOMMITTED)
        ON SP.[Code]                        = CU.[Salesperson Code]
 LEFT JOIN [HRS-CN$Job]                          JO WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_]        = JO.[No_] 
 LEFT JOIN [HRS-CN$Customer Bank Account]        BA WITH (READUNCOMMITTED)
        ON AH.[Bill-to Customer No_] = BA.[Customer No_]
       AND BA.Clearing =1 
 LEFT JOIN [HRS-CN$Bank Branch No_]              BB WITH (READUNCOMMITTED)
        ON BA.[Bank Branch No_]             = BB.Code
 LEFT JOIN [HRS-CN$Document Type Assignment] DA WITH (READUNCOMMITTED)
        ON DA.[Brand Code]                  = AH.[Brand Code]
       AND DA.[Muse ID]                     = AH.[MuseID]
       AND DA.[Document Type]               = AH.[Document Type]
 LEFT JOIN [ExtendedProperties]               P1 WITH (NOLOCK)
        ON P1.[TableID]                     = 18
       AND P1.[FieldID]                     = 2
       AND P1.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P2 WITH (NOLOCK)
        ON P2.[TableID]                     = 18
       AND P2.[FieldID]                     = 4
       AND P2.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P3 WITH (NOLOCK)
        ON P3.[TableID]                     = 18
       AND P3.[FieldID]                     = 5
       AND P3.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P4 WITH (NOLOCK)
        ON P4.[TableID]                     = 18
       AND P4.[FieldID]                     = 6
       AND P4.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P5 WITH (NOLOCK)
        ON P5.[TableID]                     = 18
       AND P5.[FieldID]                     = 7
       AND P5.[KeyField1Value]              = AH.[Bill-to Customer No_]
 LEFT JOIN [ExtendedProperties]               P6 WITH (NOLOCK)
        ON P6.[TableID]                     = 18
       AND P6.[FieldID]                     = 50012
       AND P6.[KeyField1Value]              = AH.[Bill-to Customer No_]
     WHERE AH.[Posted Invoice No_] = @ReNr2
        OR AH.[Case No_] = @ReNr2
  GROUP BY AH.[Bill-to Customer No_]
--         , AH.[Posting Date]
         , AH.[Creation Date]
         , AH.[Currency Code]
         , AH.[Currency Factor]
         , AH.[Language Code]
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name]          ELSE P1.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Name 2]        ELSE P2.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address]       ELSE P3.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to Address 2]     ELSE P4.[Content]       END
         , CASE WHEN P1.[Content] IS NULL   THEN AH.[Bill-to City]          ELSE P5.[Content]       END
         , AH.[Bill-to Post Code]
         , AH.[Bill-to Country_Region Code]
         , CU.[Payment Method Code]
         , CU.[Responsibility Center]
         , CASE WHEN P1.[Content] IS NULL   THEN CO.Name                    ELSE P6.[Content]       END 
         , CO.[EU Country_Region Code]
         , SP.[Fax Extension] 
         , BA.[Bank Branch No_]
         , BA.[Bank Account No_]
         , BA.[Name]
         , BA.[IBAN] 
         , COALESCE(DA.[Hide Amount],0)         
         , LA.[ISO Code]
END

GO
