USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_AffiliateYTD]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 20.02.2013
-- Description:	Kopfinformationen zur Gutschriftsanzeige
/*
DECLARE @DateFrom    datetime
      , @DateTo      datetime
      , @FirstOfYear datetime
      , @CustomeIDFilter varchar(max)
      , @ReservationsourceFilter varchar(max)
 SELECT @DateFrom    = '01.01.2013'
      , @DateTo      = '31.01.2013'
      , @FirstOfYear = '01.01.2013'
      , @CustomeIDFilter = '1037522001..1037522009'
      , @ReservationsourceFilter = '<>0&<>2&<>3&<>8&<>16'
EXEC [dbo].[sp_AffiliateYTD] @DateFrom, @DateTo, @FirstOfYear, @CustomeIDFilter, @ReservationsourceFilter
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_AffiliateYTD] 
    @DateFrom    datetime
  , @DateTo      datetime
  , @FirstOfYear datetime
  , @CustomeIDFilter varchar(max)
  , @ReservationsourceFilter varchar(max)
AS
BEGIN
SET Language German

DECLARE @Filter1 varchar(max)
      , @Filter2 varchar(max)
      , @SQL     varchar(max)

SELECT @Filter1 = CASE WHEN CHARINDEX('|',@ReservationsourceFilter)>0 THEN
                    [RS].[SqlFilterOR](@ReservationsourceFilter,'AP.[ReservationSource]',0)  
                  ELSE
                    [RS].[SqlFilterAND](@ReservationsourceFilter,'AP.[ReservationSource]',0) 
                  END 
     , @Filter2 = CASE WHEN CHARINDEX('|',@CustomeIDFilter)>0 THEN
                    [RS].[SqlFilterOR](@CustomeIDFilter,'AP.[AffiliatePartnerNo]',0)
                  ELSE
                    [RS].[SqlFilterAND](@CustomeIDFilter,'AP.[AffiliatePartnerNo]',0)  
                  END 
                  
DECLARE @Company TABLE (Name varchar(30))
INSERT INTO @Company VALUES ('HRS')--,('HRS-CN'),('TISCOVER')

PRINT @Filter1
PRINT @Filter2

SET @SQL = ''
SELECT @SQL = @SQL + CASE WHEN @SQL<>'' THEN '
UNION ALL' ELSE '' END 
+'
   SELECT ''MONTH'' AREA
	    , [PostingDate]
	    , [DocumentDate]
	    , [Description]
	    , [Description2]
	    , [ReservationNo]
	    , [ReservationPartNo]
	    , [InvoiceNo]
	    , [Amount_LCY]
	    , [Turnover_LCY]
	    , [CommissionType]
	    , [CommissionRateProz]
	    , [RoomNights]
	    , [IsNetRate]
	    , [Amount_LCY_corr]
	    , [Turnover_LCY_corr]
	    , [CommissionType_corr]
	    , [CommissionRateProz_corr]
	    , [RoomNights_corr]
	    , [IsNetRate_corr]
	    , [DepartureDate]
	    , [AffiliatePartnerNo]
	    , [HotelNo]
	    , [NAVCompanyName]
	    , [CustomerNo]
	    , [CountryCode]
	    , [Chain]
	    , [Brand]
	    , [MuseID]
	    , [TopBonusID]
	    , [Max Entry No_]
	    , [IsNoShow]
	    , [IsCanceled]
	    , [ContractStatus]
	    , [ClientCompany]
	    , [Handbooking]
	    , [BookingUser]
	    , [ReservationSource]
	    , [NavTransCommType]
	    , [PaymentNONCommisionableStay]
	    , [PaymentCancelation]
	    , [PaymentNoShow]
	    , [ArivalDate]
	    , [ReservationDate]
	    , [AffiliateReference1]
	    , [AffiliateReference2]
	    , [ProcessNumber]
	    , [BookingCode]
	    , [Orderer]
	    , [Turnover_Breakfast_LCY]
	    , [Turnover_Breakfast_LCY_corr]
	    , [Amount]
	    , [Turnover]
	    , [CurrencyFaktor]
	    , [CurrencyCode]
	    , [Amount_corr]
	    , [Turnover_corr]
	    , [CurrencyFaktor_corr]
	    , [CurrencyCode_corr]
	    , [PostAffiliatePartnerNo]
	    , [ConfirmedReservationNo]
	    , BS.[Name] [ReservationSourceName]
     FROM [' + C.Name + '$Affiliate Postings] AP WITH (READUNCOMMITTED) 
     JOIN [HRS$Booking Source]     BS WITH (NOLOCK) 
       ON BS.[No_] = AP.[ReservationSource] 
    WHERE [DepartureDate] BETWEEN ''%1'' AND ''%2'''
+ CASE WHEN @Filter1 <> '' THEN ' 
      AND ' + @Filter1 ELSE '' END
+ CASE WHEN @Filter2 <> '' THEN ' 
      AND ' + @Filter2 ELSE '' END
FROM @Company C   

SELECT @SQL = @SQL + CASE WHEN @SQL<>'' THEN '
UNION ALL' ELSE '' END 
+'
   SELECT ''YEAR'' AREA
	    , [PostingDate]
	    , [DocumentDate]
	    , [Description]
	    , [Description2]
	    , [ReservationNo]
	    , [ReservationPartNo]
	    , [InvoiceNo]
	    , [Amount_LCY]
	    , [Turnover_LCY]
	    , [CommissionType]
	    , [CommissionRateProz]
	    , [RoomNights]
	    , [IsNetRate]
	    , [Amount_LCY_corr]
	    , [Turnover_LCY_corr]
	    , [CommissionType_corr]
	    , [CommissionRateProz_corr]
	    , [RoomNights_corr]
	    , [IsNetRate_corr]
	    , [DepartureDate]
	    , [AffiliatePartnerNo]
	    , [HotelNo]
	    , [NAVCompanyName]
	    , [CustomerNo]
	    , [CountryCode]
	    , [Chain]
	    , [Brand]
	    , [MuseID]
	    , [TopBonusID]
	    , [Max Entry No_]
	    , [IsNoShow]
	    , [IsCanceled]
	    , [ContractStatus]
	    , [ClientCompany]
	    , [Handbooking]
	    , [BookingUser]
	    , [ReservationSource]
	    , [NavTransCommType]
	    , [PaymentNONCommisionableStay]
	    , [PaymentCancelation]
	    , [PaymentNoShow]
	    , [ArivalDate]
	    , [ReservationDate]
	    , [AffiliateReference1]
	    , [AffiliateReference2]
	    , [ProcessNumber]
	    , [BookingCode]
	    , [Orderer]
	    , [Turnover_Breakfast_LCY]
	    , [Turnover_Breakfast_LCY_corr]
	    , [Amount]
	    , [Turnover]
	    , [CurrencyFaktor]
	    , [CurrencyCode]
	    , [Amount_corr]
	    , [Turnover_corr]
	    , [CurrencyFaktor_corr]
	    , [CurrencyCode_corr]
	    , [PostAffiliatePartnerNo]
	    , [ConfirmedReservationNo]
	    , BS.[Name] [ReservationSourceName]
     FROM [' + C.Name + '$Affiliate Postings] AP WITH (READUNCOMMITTED) 
     JOIN [HRS$Booking Source]     BS WITH (NOLOCK) 
       ON BS.[No_] = AP.[ReservationSource] 
    WHERE [DepartureDate] BETWEEN ''%3'' AND ''%2'''
+ CASE WHEN @Filter1 <> '' THEN ' 
      AND ' + @Filter1 ELSE '' END
+ CASE WHEN @Filter2 <> '' THEN ' 
      AND ' + @Filter2 ELSE '' END
FROM @Company C   

CREATE TABLE #RESULTS
(
    AREA varchar(20),
	[PostingDate] [datetime] NULL,
	[DocumentDate] [datetime] NULL,
	[Description] [varchar](250) NULL,
	[Description2] [varchar](250) NULL,
	[ReservationNo] [int] NOT NULL,
	[ReservationPartNo] [int] NOT NULL,
	[InvoiceNo] [varchar](20) NOT NULL,
	[Amount_LCY] [decimal](37, 20) NULL,
	[Turnover_LCY] [decimal](37, 20) NULL,
	[CommissionType] [varchar](50) NULL,
	[CommissionRateProz] [decimal](37, 20) NULL,
	[RoomNights] [decimal](37, 20) NULL,
	[IsNetRate] [tinyint] NULL,
	[Amount_LCY_corr] [decimal](37, 20) NULL,
	[Turnover_LCY_corr] [decimal](37, 20) NULL,
	[CommissionType_corr] [varchar](50) NULL,
	[CommissionRateProz_corr] [decimal](37, 20) NULL,
	[RoomNights_corr] [decimal](37, 20) NULL,
	[IsNetRate_corr] [tinyint] NULL,
	[DepartureDate] [datetime] NULL,
	[AffiliatePartnerNo] [bigint] NULL,
	[HotelNo] [varchar](20) NULL,
	[NAVCompanyName] [varchar](50) NULL,
	[CustomerNo] [varchar](20) NULL,
	[CountryCode] [varchar](20) NULL,
	[Chain] [varchar](20) NULL,
	[Brand] [varchar](20) NULL,
	[MuseID] [varchar](20) NULL,
	[TopBonusID] [varchar](20) NULL,
	[Max Entry No_] [int] NULL,
	[IsNoShow] [tinyint] NULL,
	[IsCanceled] [tinyint] NULL,
	[ContractStatus] [varchar](50) NULL,
	[ClientCompany] [varchar](80) NULL,
	[Handbooking] [tinyint] NULL,
	[BookingUser] [varchar](20) NULL,
	[ReservationSource] [int] NULL,
	[NavTransCommType] [int] NULL,
	[PaymentNONCommisionableStay] [tinyint] NULL,
	[PaymentCancelation] [tinyint] NULL,
	[PaymentNoShow] [tinyint] NULL,
	[ArivalDate] [datetime] NULL,
	[ReservationDate] [datetime] NULL,
	[AffiliateReference1] [varchar](100) NULL,
	[AffiliateReference2] [varchar](100) NULL,
	[ProcessNumber] [int] NULL,
	[BookingCode] [varchar](80) NULL,
	[Orderer] [varchar](120) NULL,
	[Turnover_Breakfast_LCY] [decimal](37, 20) NULL,
	[Turnover_Breakfast_LCY_corr] [decimal](37, 20) NULL,
	[Amount] [decimal](37, 20) NULL,
	[Turnover] [decimal](37, 20) NULL,
	[CurrencyFaktor] [decimal](37, 20) NULL,
	[CurrencyCode] [varchar](10) NULL,
	[Amount_corr] [decimal](37, 20) NULL,
	[Turnover_corr] [decimal](37, 20) NULL,
	[CurrencyFaktor_corr] [decimal](37, 20) NULL,
	[CurrencyCode_corr] [varchar](10) NULL,
	[PostAffiliatePartnerNo] [bigint] NULL,
	[ConfirmedReservationNo] [int] NULL,
	[ReservationSourceName] varchar(100) NULL
)

SET @SQL = 'WITH RESULT AS (' + @SQL + ') INSERT INTO #RESULTS SELECT * FROM RESULT'
PRINT @SQL
--EXEC(@SQL)
--SELECT * FROM #RESULTS 
END
GO
