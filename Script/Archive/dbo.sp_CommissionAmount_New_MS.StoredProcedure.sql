USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_CommissionAmount_New_MS]    Script Date: 10.04.2024 14:31:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 09.01.2015
-- Description:	
/*
EXEC [dbo].[sp_CommissionAmount_New_MS] 
  @DateFrom       = '2018-01-01'
, @DateTo         = '2018-01-31'
, @Hotel          = null
, @Brand          = null
, @Chain          = null
, @ContractStatus = null
, @MuseID         = null
, @Country        = null
, @Company        = 'HRS'
, @Salesperson    = null
, @BookingSource  = null
, @Category       = 'Company'
, @SubCategory    = 'Consumer'
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_CommissionAmount_New_MS] 
    @DateFrom       date = '2015-01-01'
  , @DateTo         date = '2016-12-31'
  , @Hotel          varchar(MAX) = null
  , @Brand          varchar(MAX) = null
  , @Chain          varchar(MAX) = null
  , @ContractStatus varchar(MAX) = null
  , @MuseID         varchar(MAX) = null
  , @Country        varchar(MAX) = null
  , @Company        varchar(MAX) = null
  , @Salesperson    varchar(MAX) = null -- 14.01.2015
  , @BookingSource	varchar(MAX) = null
  , @Category       varchar(MAX) = 'MuseID'
  , @SubCategory    varchar(MAX) = 'Month'
AS
BEGIN

  DECLARE   @Stmt						VARCHAR(MAX) = '' 
		  , @StmtCompanyName			VARCHAR(MAX) = ''
		  , @GroupBy                    VARCHAR(MAX) = ''
		  , @CatName                    VARCHAR(MAX) = ''
		  , @SubGroupBy                 VARCHAR(MAX) = ''
		  , @SubName                    VARCHAR(MAX) = ''
		  , @TableIDs					[RS].[TableIDs]
		  , @RevShareOnly               TINYINT = 0
  
  SET @Hotel          = ',' + COALESCE(@Hotel,'') + ','
  SET @Brand          = ',' + COALESCE(@Brand,'') + ','
  SET @Chain          = ',' + COALESCE(@Chain,'') + ','
  SET @ContractStatus = ',' + COALESCE(@ContractStatus,'') + ','
  SET @MuseID         = ',' + COALESCE(@MuseID,'') + ','
  SET @Country        = ',' + COALESCE(@Country,'') + ','
  SET @Salesperson    = ',' + COALESCE(@Salesperson,'') + ','-- 14.01.2015
  SET @BookingSource  = ',' + COALESCE(@BookingSource,'') + ','-- 30.06.2015
  SET @Company        = CASE WHEN @Company IS NULL 
                          THEN ',HRS,HRS-CN,HRS-BR,TISCOVER,Partner,hotel.de,'
                          ELSE ',' + @Company + ','
                        END
  
  --BEGIN Mandantenauswahl	
  CREATE TABLE #RESULTS_CompanyName 
  (
	      [CompanyName]			VARCHAR(30)
	    , [RowNumber]				INT
  )  
  
  INSERT INTO #RESULTS_CompanyName
  SELECT REPLACE([Name] ,'.','_')
	   , ROW_NUMBER() OVER (ORDER BY [Name])
    FROM [Company]
   WHERE @Company LIKE '%,'+[Name]+',%'
  --ENDE Mandantenauswahl
  
  SET @GroupBy = CASE @Category 
                   WHEN 'Month'           THEN 'CONVERT(CHAR(7),AP.[DepartureDate],111)'
                   WHEN 'Company'         THEN null
                   WHEN 'Chain'           THEN 'CH.[Code]'
                   WHEN 'Brand'           THEN 'BR.[Code]'
                   WHEN 'Country'         THEN 'CO.[Country_Region Code]'
                   WHEN 'MuseID'          THEN 'AP.[MuseID]'
                   WHEN 'Contract Status' THEN 'CO.[Contract Status]'
                   WHEN 'Hotel'           THEN 'CAST(AP.HotelNo AS int)'
                   WHEN 'Salesperson'     THEN 'CO.[Salesperson Code]'-- 14.01.2015
                   WHEN 'Booking Source'  THEN 'AP.[ReservationSource]'-- 30.06.2015
				   WHEN 'Consumer'        THEN 'CASE WHEN (AP.[ReservationSource]<>383 AND COALESCE(APA.[Distribution Channel ID],0) IN (2,9,12)) OR (AP.[ReservationSource]=383 AND COALESCE(APA.[Distribution Channel ID],0) >= 10 AND COALESCE(APA.[Company-No_],0) <> 0) THEN ''BTS'' ELSE ''ES'' END'
                   ELSE null
                 END
                 
  SET @CatName = CASE @Category 
                   WHEN 'Month'           THEN ''''''
                   WHEN 'Company'         THEN ''''''
                   WHEN 'Chain'           THEN 'CH.[Description]'
                   WHEN 'Brand'           THEN 'BR.[Description]'
                   WHEN 'Country'         THEN 'CR.[Name]'
                   WHEN 'MuseID'          THEN ''''''
                   WHEN 'Contract Status' THEN 'CS.[Name]'
                   WHEN 'Hotel'           THEN 'CO.[Name]'
                   WHEN 'Salesperson'     THEN ''''''-- 14.01.2015
                   WHEN 'Booking Source'  THEN 'BS.[Name]'-- 30.06.2015
				   WHEN 'Consumer'        THEN 'CASE WHEN (AP.[ReservationSource]<>383 AND COALESCE(APA.[Distribution Channel ID],0) IN (2,9,12)) OR (AP.[ReservationSource]=383 AND COALESCE(APA.[Distribution Channel ID],0) >= 10 AND COALESCE(APA.[Company-No_],0) <> 0) THEN ''Business'' ELSE ''Endconsumer'' END'
                   ELSE ''''''
                 END
  SET @SubGroupBy = CASE @SubCategory 
                   WHEN 'Month'           THEN 'CONVERT(CHAR(7),AP.[DepartureDate],111)'
                   WHEN 'Company'         THEN null
                   WHEN 'Chain'           THEN 'CH.[Code]'
                   WHEN 'Brand'           THEN 'BR.[Code]'
                   WHEN 'Country'         THEN 'CO.[Country_Region Code]'
                   WHEN 'MuseID'          THEN 'AP.[MuseID]'
                   WHEN 'Contract Status' THEN 'CO.[Contract Status]'
                   WHEN 'Hotel'           THEN 'CAST(AP.HotelNo AS int)'
                   WHEN 'Salesperson'     THEN 'CO.[Salesperson Code]'-- 14.01.2015
                   WHEN 'Booking Source'  THEN 'AP.[ReservationSource]'-- 30.06.2015
				   WHEN 'Consumer'        THEN 'CASE WHEN (AP.[ReservationSource]<>383 AND COALESCE(APA.[Distribution Channel ID],0) IN (2,9,12)) OR (AP.[ReservationSource]=383 AND COALESCE(APA.[Distribution Channel ID],0) >= 10 AND COALESCE(APA.[Company-No_],0) <> 0) THEN ''BTS'' ELSE ''ES'' END'
                   ELSE null
                 END                 
  SET @SubName = CASE @SubCategory 
                   WHEN 'Month'           THEN ''''''
                   WHEN 'Company'         THEN ''''''
                   WHEN 'Chain'           THEN 'CH.[Description]'
                   WHEN 'Brand'           THEN 'BR.[Description]'
                   WHEN 'Country'         THEN 'CR.[Name]'
                   WHEN 'MuseID'          THEN ''''''
                   WHEN 'Contract Status' THEN 'CS.[Name]'
                   WHEN 'Hotel'           THEN 'CO.[Name]'
                   WHEN 'Salesperson'     THEN ''''''-- 14.01.2015
                   WHEN 'Booking Source'  THEN 'BS.[Name]'-- 30.06.2015
				   WHEN 'Consumer'        THEN 'CASE WHEN (AP.[ReservationSource]<>383 AND COALESCE(APA.[Distribution Channel ID],0) IN (2,9,12)) OR (AP.[ReservationSource]=383 AND COALESCE(APA.[Distribution Channel ID],0) >= 10 AND COALESCE(APA.[Company-No_],0) <> 0) THEN ''Business'' ELSE ''Endconsumer'' END'
                   ELSE ''''''
                 END
                 
CREATE TABLE #RL ([Reservation No_] INT NOT NULL PRIMARY KEY)
IF @RevShareOnly=1   
BEGIN
WITH RL AS
(
  SELECT [Reservation No_], COUNT(1) Dummy FROM [HRS$Rebate Line] WITH (NOLOCK) GROUP BY [Reservation No_] UNION
  SELECT [Reservation No_], COUNT(1) Dummy FROM [hotel_de$Rebate Line] WITH (NOLOCK) GROUP BY [Reservation No_] UNION
  SELECT [Reservation No_], COUNT(1) Dummy FROM [HRS$Posted Rebate Line] WITH (NOLOCK) GROUP BY [Reservation No_] UNION
  SELECT [Reservation No_], COUNT(1) Dummy FROM [hotel_de$Posted Rebate Line] WITH (NOLOCK) GROUP BY [Reservation No_]
)
INSERT INTO #RL
SELECT DISTINCT [Reservation No_] FROM RL
END              
SET @Stmt = ''
SELECT @Stmt = @Stmt
+ (SELECT CASE WHEN RowNumber = 1 THEN '
;WITH CR AS
('
ELSE '
UNION ALL'
END)
+ '
  SELECT SUM(AP.[Turnover_LCY]) [Turnover_LCY]
       , SUM(AP.[Turnover_LCY_corr]) [Turnover_LCY_corr]
       , CASE WHEN SUM(AP.[Turnover_LCY]) = 0 THEN 1 ELSE 1-SUM(AP.[Turnover_LCY_corr])/SUM(AP.[Turnover_LCY]) END [Turnover_LCY_corr_ratio]
       , SUM(CASE WHEN AP.[CommissionType] = ''Company rate'' THEN AP.[Turnover_LCY_corr] ELSE 0 END) [Turnover_LCY_companyrate]
       , CASE WHEN SUM(AP.[Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM(CASE WHEN AP.[CommissionType] = ''Company rate'' THEN AP.[Turnover_LCY_corr] ELSE 0 END) / SUM(AP.[Turnover_LCY_corr]) END [Turnover_LCY_companyrate_ratio]
       , SUM(AP.[Amount_LCY]) [Amount_LCY]
       , SUM(AP.[Amount_LCY_corr]) [Amount_LCY_corr]
       , CASE WHEN SUM(AP.[Amount_LCY]) = 0 THEN 1 ELSE 1-SUM(AP.[Amount_LCY_corr])/SUM(AP.[Amount_LCY]) END [Amount_LCY_corr_ratio]
       , CASE WHEN SUM(AP.[Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM(AP.[Amount_LCY_corr]) / SUM(AP.[Turnover_LCY_corr]) END [Avg_Commission_Rate]
       , SUM(AP.[RoomNights]) [RoomNights]
       , SUM(AP.[RoomNights_corr]) [RoomNights_corr]
       , CASE WHEN SUM(AP.[RoomNights]) = 0 THEN 1 ELSE 1-SUM(AP.[RoomNights_corr])/SUM(AP.[RoomNights]) END [RoomNights_corr_ratio]
       , SUM(CASE WHEN AP.[CommissionType] = ''Company rate'' THEN AP.[RoomNights_corr] ELSE 0 END) [RoomNights_companyrate]
       , CASE WHEN SUM(AP.[RoomNights_corr]) = 0 THEN 1 ELSE SUM(CASE WHEN AP.[CommissionType] = ''Company rate'' THEN AP.[RoomNights_corr] ELSE 0 END) / SUM(AP.[RoomNights_corr]) END [RoomNights_companyrate_ratio]
       , SUM(AP.[Turnover_Breakfast_LCY]) [Turnover_Breakfast_LCY]
       , SUM(AP.[Turnover_Breakfast_LCY_corr]) [Turnover_Breakfast_LCY_corr]
	   , SUM(AP.[Turnover_Breakfast_LCY]) * CASE WHEN SUM(AP.[Turnover_LCY]) = 0 THEN 1 ELSE SUM(AP.[Amount_LCY]) / SUM(AP.[Turnover_LCY]) END [Amount_Breakfast_LCY]
	   , SUM(AP.[Turnover_Breakfast_LCY_corr]) * CASE WHEN SUM(AP.[Turnover_LCY_corr]) = 0 THEN 1 ELSE SUM(AP.[Amount_LCY_corr]) / SUM(AP.[Turnover_LCY_corr]) END [Amount_Breakfast_LCY_corr]
       , CASE WHEN SUM(AP.[Turnover_Breakfast_LCY]) = 0 THEN 0 ELSE 1-SUM(AP.[Turnover_Breakfast_LCY_corr])/SUM(AP.[Turnover_Breakfast_LCY]) END [Turnover_Breakfast_LCY_corr_ratio]
       , SUM(AP.[Turnover_LCY] * COALESCE(1.0/(1.0+(FT.[VAT in %]+FT.[Service Tax])/100.),1)) /1000. [Net_Turnover_LCY]
       , SUM(AP.[Turnover_LCY_corr] * COALESCE(1.0/(1.0+(FT.[VAT in %]+FT.[Service Tax])/100.),1)) /1000. [Net_Turnover_LCY_corr]
	   , SUM(CASE COALESCE(BT.BT_FRSTCK,0) WHEN 0 THEN 1 ELSE 0 END) [Incl_Breakfast]
	   , SUM(CASE COALESCE(BT.BT_FRSTCK,0) WHEN 0 THEN 0 WHEN 1 THEN 1 ELSE 0 END) [Excl_Breakfast]
	   , SUM(CASE COALESCE(BT.BT_FRSTCK,0) WHEN 0 THEN 0 WHEN 1 THEN CASE WHEN COALESCE(BT_FRST_PREIS,0)>0 THEN 0 ELSE 1 END ELSE 0 END) [Excl_Breakfast_Zero]
       --, SUM(CASE WHEN AP.[Turnover_LCY]=0 THEN 0 ELSE AP.[Turnover_Breakfast_LCY]/AP.[Turnover_LCY]*[Amount_LCY] END) [Amount_Breakfast_LCY]
       --, SUM(CASE WHEN AP.[Turnover_LCY_corr]=0 THEN 0 ELSE AP.[Turnover_Breakfast_LCY_corr]/AP.[Turnover_LCY_corr]*[Amount_LCY_corr] END) [Amount_Breakfast_LCY_corr]
'
+ CASE WHEN COALESCE(@GroupBy,'Company') = 'Company' THEN '       , '''+[CompanyName] + ''' [Category]' ELSE '       , ' + @GroupBy + ' [Category]' END +'
'
+ CASE WHEN @CatName IS null THEN '' ELSE '       , ' + @CatName + ' [CategoryName]' END +'
'
+ CASE WHEN COALESCE(@SubGroupBy,'Company') = 'Company' THEN '       , '''+[CompanyName] + ''' [SubCategory]' ELSE '       , ' + @SubGroupBy + ' [SubCategory]' END +'
'
+ CASE WHEN @SubName IS null THEN '' ELSE '       , ' + @SubName + ' [SubCategoryName]' END +'
    FROM [' + [CompanyName] + '$Affiliate Postings] AP WITH (NOLOCK)
LEFT JOIN [Affiliate Partner] APA WITH (NOLOCK)  ON APA.[No_] = AP.[AffiliatePartnerNo]
LEFT JOIN HRSDB.BUCHTEIL BT WITH (NOLOCK) ON BT.B_KEY = AP.ReservationNo AND BT.BT_POS = AP.ReservationPartNo
    JOIN [' + [CompanyName] + '$Contact] CO WITH (NOLOCK) ON CO.No_ = AP.HotelNo
    JOIN [' + [CompanyName] + '$Foreign Tax] FT WITH (NOLOCK) ON FT.Country = CO.[Country_Region Code]
    JOIN [' + [CompanyName] + '$Country_Region] CR WITH (NOLOCK) ON CR.[Code] = CO.[Country_Region Code]
    JOIN [' + [CompanyName] + '$Booking Source] BS WITH (NOLOCK) ON BS.[No_] = AP.[ReservationSource]
    JOIN [Chain] CH WITH (NOLOCK) ON CH.[Code] = CO.[Chain]
    JOIN [Brand] BR WITH (NOLOCK) ON BR.[Code] = CO.[Brand]
    JOIN [' + [CompanyName] + '$Dimension Value] CS WITH (NOLOCK) ON CS.[Code] = CO.[Contract Status] AND CS.[Dimension Code] = ''CONTRACT STATUS''
'+CASE WHEN @RevShareOnly=1 THEN '    JOIN #RL RL ON RL.[Reservation No_]=AP.ReservationNo' ELSE '' END +'    
   WHERE AP.[DepartureDate] BETWEEN '''+CONVERT(char(10),@DateFrom,120)+''' AND '''+CONVERT(char(10),@DateTo,120)+'''
     AND AP.InvoiceNo LIKE ''MS%'''
+ CASE WHEN @Hotel = ',,' THEN '' ELSE '
     AND '''+@Hotel+''' LIKE ''%,''+AP.HotelNo+'',%''' END   
+ CASE WHEN @Brand = ',,' THEN '' ELSE '
     AND '''+@Brand+''' LIKE ''%,''+CO.[Brand]+'',%''' END   
+ CASE WHEN @Chain = ',,' THEN '' ELSE '
     AND '''+@Chain+''' LIKE ''%,''+CO.[Chain]+'',%''' END   
+ CASE WHEN @ContractStatus = ',,' THEN '' ELSE '
     AND '''+@ContractStatus+''' LIKE ''%,''+CO.[Contract Status]+'',%''' END
+ CASE WHEN @MuseID = ',,' THEN '' ELSE '
     AND '''+@MuseID+''' LIKE ''%,''+AP.[MuseID]+'',%''' END   
+ CASE WHEN @BookingSource = ',,' THEN '' ELSE '
     AND '''+@BookingSource+''' LIKE ''%,''+CAST(AP.[ReservationSource] AS varchar(20))+'',%''' END   
+ CASE WHEN @Country = ',,' THEN '' ELSE '
     AND '''+@Country+''' LIKE ''%,''+CO.[Country_Region Code]+'',%''' END   
+ CASE WHEN @Salesperson = ',,' THEN '' ELSE '                               -- 14.01.2015
     AND '''+@Salesperson+''' LIKE ''%,''+CO.[Salespersonn Code]+'',%''' END -- 14.01.2015
+ CASE WHEN COALESCE(@GroupBy,'')='' THEN '' ELSE '
GROUP BY ' + @GroupBy  END
+ CASE WHEN COALESCE(@CatName,'')='' THEN '' WHEN COALESCE(@CatName,'')='''''' THEN '' ELSE '
       , ' + @CatName  END
+ CASE WHEN COALESCE(@GroupBy,'')='' AND COALESCE(@SubGroupBy,'')<>'' THEN '
GROUP BY ' + @SubGroupBy WHEN COALESCE(@SubGroupBy,'')='' THEN '' ELSE '
       , ' + @SubGroupBy  END
+ CASE WHEN COALESCE(@SubName,'')='' THEN '' WHEN COALESCE(@SubName,'')='''''' THEN '' ELSE '
       , ' + @SubName  END
FROM #RESULTS_CompanyName
ORDER BY RowNumber 

SET @Stmt = @Stmt +'
)
  SELECT SUM([Turnover_LCY]) [Turnover_LCY]
       , SUM([Turnover_LCY_corr]) [Turnover_LCY_corr]
       , CASE WHEN SUM([Turnover_LCY]) = 0 THEN 1 ELSE 1-SUM([Turnover_LCY_corr])/SUM([Turnover_LCY]) END [Turnover_LCY_corr_ratio]
       , SUM([Turnover_LCY_companyrate]) [Turnover_LCY_companyrate]
       , CASE WHEN SUM([Turnover_LCY_corr]) = 0 THEN 
           1 
         ELSE 
           SUM([Turnover_LCY_companyrate]) / SUM([Turnover_LCY_corr]) 
         END [Turnover_LCY_companyrate_ratio]
       , SUM([Amount_LCY]) [Amount_LCY]
       , SUM([Amount_LCY_corr]) [Amount_LCY_corr]
       , CASE WHEN SUM([Amount_LCY]) = 0 THEN 
           1 
         ELSE 
           1-SUM([Amount_LCY_corr])/SUM([Amount_LCY]) 
         END [Amount_LCY_corr_ratio]
       , CASE WHEN SUM([Turnover_LCY_corr]) = 0 THEN 
           1 
         ELSE 
           SUM([Amount_LCY_corr]) / SUM([Turnover_LCY_corr]) 
         END [Avg_Commission_Rate]
       , SUM([RoomNights]) [RoomNights]
       , SUM([RoomNights_corr]) [RoomNights_corr]
       , CASE WHEN SUM([RoomNights]) = 0 THEN 1 ELSE 1-SUM([RoomNights_corr])/SUM([RoomNights]) END [RoomNights_corr_ratio]
       , SUM([RoomNights_companyrate]) [RoomNights_companyrate]
       , CASE WHEN SUM([RoomNights_corr]) = 0 THEN 
           1 
         ELSE 
           SUM([RoomNights_companyrate]) / SUM([RoomNights_corr]) 
         END [RoomNights_companyrate_ratio]
       , ROUND(SUM([Turnover_Breakfast_LCY]),2) [Turnover_Breakfast_LCY]
       , SUM([Turnover_Breakfast_LCY_corr]) [Turnover_Breakfast_LCY_corr]
       , CASE WHEN SUM([Turnover_Breakfast_LCY]) = 0 THEN 
           0
         ELSE 
           1-SUM([Turnover_Breakfast_LCY_corr])/SUM([Turnover_Breakfast_LCY]) 
         END [Turnover_Breakfast_LCY_corr_ratio]
       , SUM([Net_Turnover_LCY]) [Net_Turnover_LCY]
       , SUM([Net_Turnover_LCY_corr]) [Net_Turnover_LCY_corr]
	   , SUM([Incl_Breakfast]) [Incl_Breakfast]
	   , SUM([Excl_Breakfast]) [Excl_Breakfast]
	   , SUM([Excl_Breakfast_Zero]) [Excl_Breakfast_Zero]
	   , SUM([Amount_Breakfast_LCY]) [Amount_Breakfast_LCY]
	   , SUM([Amount_Breakfast_LCY_corr]) [Amount_Breakfast_LCY_corr]
       , CASE WHEN SUM([Amount_Breakfast_LCY]) = 0 THEN 
           0
         ELSE 
           1-SUM([Amount_Breakfast_LCY_corr])/SUM([Amount_Breakfast_LCY]) 
         END [Amount_Breakfast_LCY_corr_ratio]
       , [Category]
       , [CategoryName]
       , [SubCategory]
       , [SubCategoryName]
    FROM CR
GROUP BY [Category]
       , [CategoryName]
       , [SubCategory]
       , [SubCategoryName]  
ORDER BY [Category]        
       , [SubCategory]
'       
       
  PRINT SUBSTRING(@Stmt,1,8000)
  PRINT SUBSTRING(@Stmt,8001,8000)
  PRINT SUBSTRING(@Stmt,16001,8000)
  PRINT SUBSTRING(@Stmt,24001,8000)
  PRINT SUBSTRING(@Stmt,32001,8000)
  
  EXEC (@Stmt)
END
GO
