USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_HRS$FiscalYearHRS]    Script Date: 10.04.2024 14:31:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 14.11.1325.07.18
-- Description: Geschäftsjahr HRS anhand der Tabelle [Accounting Period] ermitteln
/*
DECLARE
    @Date               date = '2017-05-13'
  , @BeginFiscalYearHRS date 
  , @EndFiscalYearHRS   date 
  , @Result             int
EXEC [dbo].[sp_HRS$FiscalYearHRS]
    @Date               
  , @BeginFiscalYearHRS OUT
  , @EndFiscalYearHRS   OUT
  , @Result             OUT 
PRINT '@Date               : ' + CONVERT(varchar(12),@Date,120)
PRINT '@BeginFiscalYearHRS : ' + CONVERT(varchar(12),@BeginFiscalYearHRS,120)
PRINT '@EndFiscalYearHRS   : ' + CONVERT(varchar(12),@EndFiscalYearHRS,120)
PRINT @Result 
*/
CREATE PROCEDURE [dbo].[sp_HRS$FiscalYearHRS]
    @Date               date
  , @BeginFiscalYearHRS date output
  , @EndFiscalYearHRS   date output
  , @Result             int  output
AS BEGIN
  DECLARE @nullDate date = '1753-01-01'
  SELECT @BeginFiscalYearHRS = '1753-01-01'
       , @EndFiscalYearHRS = '1753-01-01'
  SELECT @BeginFiscalYearHRS = COALESCE(MAX(AP.[Starting Date]),@nullDate)
    FROM [HRS$Accounting Period] AP WITH (NOLOCK)
   WHERE AP.[Starting Date]<=@Date
     AND AP.[New Fiscal Year]=1

  SET @Result = -1
  IF @BeginFiscalYearHRS<>@nullDate
  BEGIN
    SET @Result=0
	SELECT @EndFiscalYearHRS = COALESCE(MIN(AP.[Starting Date]),DATEADD(yy,1,DATEADD(dd,-1,@BeginFiscalYearHRS)))
      FROM [HRS$Accounting Period] AP WITH (NOLOCK)
   WHERE AP.[Starting Date]>@BeginFiscalYearHRS
     AND AP.[New Fiscal Year]=1
	IF @Date>@EndFiscalYearHRS
	BEGIN
	  SET @BeginFiscalYearHRS = DATEADD(yy,DATEDIFF(yy,@EndFiscalYearHRS,@Date),@BeginFiscalYearHRS)
	  SET @EndFiscalYearHRS = DATEADD(yy,1,DATEADD(dd,-1,@BeginFiscalYearHRS))
	END
  END
END
GO
