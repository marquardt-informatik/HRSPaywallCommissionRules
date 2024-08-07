USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[GenerateRecalculationMatrix ACS-1986]    Script Date: 10.04.2024 14:31:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC [dbo].[GenerateRecalculationMatrix]
*/
CREATE PROC [dbo].[GenerateRecalculationMatrix ACS-1986] AS BEGIN
SET NOCOUNT ON
DECLARE @SetActualOrder varchar(max) = 'SET @ActualSortorder = %SortorderNo% /*%Description%*/'
DECLARE @UpdateSQL varchar(max) = 'UPDATE AL SET AL.[Sortorder No_] = @ActualSortorder, AL.[Code] = R2.[Code]/*, AL.[TAF Code] = R2.[Code]*/, AL.[Contract Code] = COALESCE(CASE WHEN (CU.[Commission w_o Breakfast]=1 OR CU.[No breakfast offered]=1) AND CU.[Commission based on net amount]=1 THEN NULLIF(R2.[Contract Code Net Logis],'''') WHEN (CU.[Commission w_o Breakfast]=1 OR CU.[No breakfast offered]=1) AND CU.[Commission based on net amount]=0 THEN NULLIF(R2.[Contract Code w_o Breakfast],'''') WHEN (CU.[Commission w_o Breakfast]=0 AND CU.[No breakfast offered]=0) AND CU.[Commission based on net amount]=1 THEN NULLIF(R2.[Contract Code Net Sales],'''') ELSE R2.[Contract Code] END,R2.[Contract Code])/*, AL.[TAF Contract Code] = R2.[TAF Contract Code]*/, AL.[Contract Grp_ Code] = R2.[Contract Grp_ Code]/*, AL.[TAF Contract Grp_ Code] = R2.[Contract Grp_ Code]*/ FROM #_AgencyLines AL JOIN [HRS$Customer] CU WITH (NOLOCK) ON AL.[Hotel No_] = CU.[No_] JOIN [HRS$Contact] CO WITH (NOLOCK) ON AL.[Hotel No_] = CO.[No_] JOIN [HRS$Agency Business Rules] R2 WITH (NOLOCK) ON '
DECLARE @SQL varchar(max) = ''
DECLARE @JoinClause varchar(max) = ''

-- ReverseOrder 
--   0 : Vergleich (=) -> <Name> = <TrueValue>|<FalseValue>
--   1 : Bereich       -> <TrueValue>|<FalseValue> BETWEEN <Name>
--   2 : Optional      -> <TrueValue>|<FalseValue>
IF OBJECT_ID('tempdb..#Fields') IS NOT NULL
    DROP TABLE #Fields
CREATE TABLE #Fields (ID int primary key, Name varchar(100), TrueValue varchar(100), FalseValue varchar(100), ReverseOrder int)
INSERT INTO #Fields VALUES 
  ( 1,'R2.[Date of Reference]'                   , '1'                                    , '0'                  , 0)
, ( 2,'R2.[Category]'                            , 'AL.[Category]'                        , '0'                  , 0)
, ( 3,'R2.[Partner No_]'                         , 'AL.[Client No_]'                      , ''''''               , 0)
, ( 4,'R2.[Hotel No_]'                           , 'AL.[Hotel No_]'                       , ''''''               , 0)
, ( 5,'R2.[Company No_]'                         , 'AL.[Company No_]'                     , ''''''               , 0)
, ( 6,'R2.[Contract Status]'                     , 'AL.[Contract Status]'                 , ''''''               , 0)
, ( 7,'R2.[Brand]'                               , 'AL.[Brand]'                           , ''''''               , 0)
, ( 8,'R2.[Chain]'                               , 'AL.[Chain]'                           , ''''''               , 0)
, ( 9,'R2.[MuseID]'                              , 'AL.[MuseID]'                          , ''''''               , 0)
, (10,'R2.[Country Code]'                        , 'AL.[Country_Region Code]'             , ''''''               , 0)
, (11,'R2.[Continent]'                           , 'AL.[Continent]'                       , ''''''               , 0)
, (12,'R2.[Rate Type]'                           , 'AL.[Rate Type]'                       , ''''''               , 0)
, (13,'R2.[Corporate Rate Discount]'             , 'AL.[Corporate Rate Discount]'         , '0'                  , 0)
, (14,'R2.[Segment]'                             , 'AL.[Segment]'                         , '0'                  , 0)
, (15,'R2.[Approved]'                            , '1'                                    , '0'                  , 0)
, (16,'R2.[Enabled]'                             , '1'                                    , '0'                  , 0)
, (17,'R2.[Valid from] AND R2.[Valid to]'        , 'AL.[Reservation Date]'                , 'AL.[Departure Date]', 1)
--, (18,'AL.[Commission Type Group]'               , 'R2.[Commission Type]'                 , '0'                  , 1)
, (19,'AL.[Company No_]'                         , 'AL.[Company No_]<>'''''               , '1=1'                , 2)
--, (20,'R2.[GTC Status]'                          , 'R2.[GTC Status] = 2'                  , '1=1'                , 2)
--, (21,'CO.[GTC Status]'                          , 'CO.[GTC Status] = 2'                  , '1=1'                , 2)
--, (22,'R2.[Rate Plan Code]'                      , 'AL.[Rate Plan Code]'                  , ''''''               , 0)
, (23,'AL.[Multisourced]'                        , 'AL.[Multisourced] = 1'                , '1=1'                , 2)
, (90,'AL.[Sortorder No_]'                       , 'AL.[Sortorder No_] < @ActualSortorder', '1=1'                , 2)
, (91,'R2.[Searchorder No_]'                     , '%Searchorder No_%'                    , '0'                  , 0)

DECLARE @SearchOrderNo int, @SortOrderNo int, @DateOfReferenceFilter tinyint, @CategoryFilter tinyint, @ClientFilter tinyint, @HotelFilter tinyint, @ContractStatusFilter tinyint, @BrandFilter tinyint, @ChainFilter tinyint, @MuseIDFilter tinyint, @CountryFilter tinyint, @ContinentFilter tinyint, @CommissionTypeFilter tinyint, @GTCRejectedFilter tinyint, @Description varchar(100), @SegmentFilter tinyint, @CompanyFilter tinyint, @RateTypeFilter tinyint, @CorporateRateDiscountFilter tinyint, @Multisource tinyint, @RatePlanCodeFilter tinyint
      
 DECLARE cur CURSOR FOR
  SELECT ABR.[No_], ABR.[Sortorder No_], ABR.[Date of Reference Filter], ABR.[Category Filter], ABR.[Client Filter], ABR.[Hotel Filter], ABR.[Contract Status Filter], ABR.[Brand Filter], ABR.[Chain Filter], ABR.[MuseID Filter], ABR.[Country Filter], ABR.[Continent Filter]/*, ABR.[Commission Type Filter], ABR.[GTC Rejected Filter]*/, ABR.[Description], ABR.[Segment Filter], ABR.[Company Filter], ABR.[Rate Type Filter], ABR.[Corporate Rate Discount Filter], ABR.[Multisource]/*, ABR.[Rate Plan Code Filter]*/
    FROM [HRS$Agency Bus_ Rules Searchorder] ABR WITH (NOLOCK)
ORDER BY [Sortorder No_] DESC

OPEN cur

FETCH NEXT FROM cur INTO @SearchOrderNo, @SortOrderNo, @DateOfReferenceFilter, @CategoryFilter, @ClientFilter, @HotelFilter, @ContractStatusFilter, @BrandFilter, @ChainFilter, @MuseIDFilter, @CountryFilter, @ContinentFilter/*, @CommissionTypeFilter, @GTCRejectedFilter*/, @Description, @SegmentFilter, @CompanyFilter, @RateTypeFilter, @CorporateRateDiscountFilter, @Multisource/*, @RatePlanCodeFilter	*/

WHILE @@FETCH_STATUS=0
BEGIN
  SET @SQL = REPLACE(REPLACE(@SetActualOrder,'%SortorderNo%',CAST(@SortorderNo AS varchar(100))),'%Description%',@Description)
  PRINT @SQL
  SET @SQL = @UpdateSQL
  SET @JoinClause = ''
  SELECT @JoinClause =
         @JoinClause + CASE WHEN @JoinClause='' THEN '' ELSE 'AND ' END
       + CASE F.ID 
           WHEN  1 THEN F.Name + ' = ' + CASE WHEN @DateOfReferenceFilter=1       THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @DateOfReferenceFilter=0       THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END) 
           WHEN  2 THEN F.Name + ' = ' + CASE WHEN @CategoryFilter=1              THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @CategoryFilter=0              THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END) 
           WHEN  3 THEN F.Name + ' = ' + CASE WHEN @ClientFilter=1                THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @ClientFilter=0                THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END) 
           WHEN  4 THEN F.Name + ' = ' + CASE WHEN @HotelFilter=1                 THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @HotelFilter=0                 THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END) 
           WHEN  5 THEN F.Name + ' = ' + CASE WHEN @CompanyFilter=1               THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @CompanyFilter=0               THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN  6 THEN F.Name + ' = ' + CASE WHEN @ContractStatusFilter=1        THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @ContractStatusFilter=0        THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN  7 THEN F.Name + ' = ' + CASE WHEN @BrandFilter=1                 THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @BrandFilter=0                 THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN  8 THEN F.Name + ' = ' + CASE WHEN @ChainFilter=1                 THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @ChainFilter=0                 THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN  9 THEN F.Name + ' = ' + CASE WHEN @MuseIDFilter=1                THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @MuseIDFilter=0                THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 10 THEN F.Name + ' = ' + CASE WHEN @CountryFilter=1               THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @CountryFilter=0               THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 11 THEN F.Name + ' = ' + CASE WHEN @ContinentFilter=1             THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @ContinentFilter=0             THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 12 THEN F.Name + ' = ' + CASE WHEN @RateTypeFilter=1              THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @RateTypeFilter=0              THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 13 THEN F.Name + ' = ' + CASE WHEN @CorporateRateDiscountFilter=1 THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @CorporateRateDiscountFilter=0 THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 14 THEN F.Name + ' = ' + CASE WHEN @SegmentFilter=1  THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @SegmentFilter=0  THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 15 THEN F.Name + ' = ' + F.TrueValue + ' '
           WHEN 16 THEN F.Name + ' = ' + F.TrueValue + ' '
           WHEN 17 THEN                  CASE WHEN @DateOfReferenceFilter=1       THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @DateOfReferenceFilter=0       THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END) + 'BETWEEN ' + F.Name +' ' 
           --WHEN 18 THEN F.Name + ' = ' + CASE WHEN @CommissionTypeFilter=1        THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @CommissionTypeFilter=0        THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 19 THEN                  CASE WHEN @CompanyFilter=1               THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @CompanyFilter=0               THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           --WHEN 20 THEN                  CASE WHEN @GTCRejectedFilter=1           THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @GTCRejectedFilter=0           THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           --WHEN 21 THEN                  CASE WHEN @GTCRejectedFilter=1           THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @GTCRejectedFilter=0           THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           --WHEN 22 THEN F.Name + ' = ' + CASE WHEN @RatePlanCodeFilter=1  THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @RatePlanCodeFilter=0  THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 23 THEN                  CASE WHEN @Multisource=1  THEN F.TrueValue ELSE F.FalseValue END + REPLICATE(' ',CASE WHEN @Multisource=0  THEN LEN(F.TrueValue)-LEN(F.FalseValue)+1 ELSE 1 END)  
           WHEN 90 THEN F.TrueValue + ' '
           WHEN 91 THEN F.Name + ' = ' + REPLACE(F.TrueValue,'%Searchorder No_%',CAST(@SearchorderNo as varchar(max)))
           ELSE ''
         END
    FROM #Fields F 
ORDER BY F.ID    
  PRINT @UpdateSQL + @JoinClause
  
  FETCH NEXT FROM cur INTO @SearchOrderNo, @SortOrderNo, @DateOfReferenceFilter, @CategoryFilter, @ClientFilter, @HotelFilter, @ContractStatusFilter, @BrandFilter, @ChainFilter, @MuseIDFilter, @CountryFilter, @ContinentFilter/*, @CommissionTypeFilter, @GTCRejectedFilter*/, @Description, @SegmentFilter, @CompanyFilter, @RateTypeFilter, @CorporateRateDiscountFilter, @Multisource/*, @RatePlanCodeFilter	*/
END

CLOSE cur
DEALLOCATE cur
END
GO
