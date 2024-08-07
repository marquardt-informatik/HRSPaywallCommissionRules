USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPChainInvoiceDetails_ACS_2334]    Script Date: 10.04.2024 14:31:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 07.08.2014
-- Description:	Ketten-Rechnung
--

-- Datum    Version   RFC    Sign.  Beschreibung
-- ------------------------------------------------------------
-- 07.08.14 HRS001    90207  TM     Erstellt
-- 10.05.19 HRS002 INC0017304 DJU   Filter deleted lines
/*
DECLARE @ReNr varchar(20)
 SELECT @ReNr = '1417_2014-07-31'
EXEC [dbo].[sp_RPChainInvoiceDetails] @ReNr

*/
-- ============================================= 52092780
CREATE PROCEDURE [dbo].[sp_RPChainInvoiceDetails_ACS_2334] 
    @ReNr varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ChainNo     varchar(20)
	      , @PostingDate date
	SET @ChainNo     = LEFT(@ReNr,CHARINDEX('_',@ReNr)-1)
	SET @PostingDate = CAST(RIGHT(@ReNr,LEN(@ReNr)-CHARINDEX('_',@ReNr)) AS date)
	
    SELECT CO.[No_]                                                    [HRS Hotelnr.]
         ,   CO.[Name] 
           + CASE WHEN CO.[Name 2]='' THEN '' ELSE ' ' END 
           + CO.[Name 2]                                               [HRS Hotelname]
         , DH.[Posted Invoice No_]                                     [InvoiceNo.]
         , DL.[Reservation No_]                                        [HRS Booking No.]
         , DL.[Position No_] 
         , DL.[Booking Code]                                           [PEG/AMA Booking No.]
         ,   DL.[Client Guestname 1] 
           + CASE WHEN DL.[Client Guestname 2]='' THEN '' ELSE ';' END 
           + DL.[Client Guestname 2]                                   [Guestname]
         , DL.[Reservation Date from]                                  [Arrival]
         , DL.[Reservation Date to]                                    [Departure]
         , DL.[Number of Rooms] * DL.[Number of Nights]                [No. of RN]
         , DL.[Rate Description]                                       [Rate Description]
         ,   DL.[Commission Base Amount] 
           * DL.[Number of Nights]                                       [Hotelrevenue in Hotel’s Currency]
         , DL.[Commission Rate]                                        [Commission Percentage]
         ,   DL.[Commission Amount] 
           * DL.[Number of Nights]                                     [Commission Amount in Hotel’s Currency]
         ,   DL.[Commission Amount (LCY)] 
           * DL.[Number of Nights]                                     [Commission Amount in EUR]
         , DL.[MuseID]
	     , CASE WHEN CU.[Language Code]=''  THEN CR.[Primary Language Code] ELSE CU.[Language Code] END AS [Language Code]
	     , CH.[Bill-to Customer No_]                                   [Customer No_]
	     , @PostingDate                                                [Posting Date]
	     , DL.[Currency Code]
	     , DL.[Currency Faktor] [Currency Factor]
      FROM [HRS$Agency Display Line]          DL WITH (NOLOCK)
      JOIN [HRS$Agency Display Header]        DH WITH (NOLOCK)
        ON DH.[Case No_]                    = DL.[Display Case No_]
      JOIN [HRS$Contact]                      CO WITH (NOLOCK)
        ON CO.[No_]                         = DH.[Bill-to Customer No_]
      JOIN [Chain]                            CH WITH (NOLOCK)
        ON CH.[Code]                        = DH.[Chain Code]
      JOIN [HRS$Customer]                     CU WITH (NOLOCK)
        ON CU.[No_]                         = CH.[Bill-to Customer No_]
      JOIN [HRS$Country_Region]               CR WITH (NOLOCK)
        ON CU.[Country_Region Code]         = CR.Code
      JOIN [HRS$Language]                     LA WITH (READUNCOMMITTED)
        ON CU.[Language Code]               = LA.Code 
     WHERE DH.[Posting Date]    = @PostingDate
       AND DH.[Correction from] = ''
       AND DH.[Case No_]     LIKE 'V%'
       AND DH.[Chain Code]      = @ChainNo
       AND ('|'+CH.[Country Filter]+'|' LIKE '%|'+DH.[Bill-to Country_Region Code]+'|%' OR CH.[Country Filter]='')
	   -- HRS002 >>
	   AND DL.[Action] <> 3
	   -- HRS002 <<
       --AND DL.[Reservation No_] = 105985971
  ORDER BY CO.[No_]
         , DL.[Reservation No_]
         , DL.[Position No_] 
END
GO
