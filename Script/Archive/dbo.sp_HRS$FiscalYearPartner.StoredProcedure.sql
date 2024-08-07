USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_HRS$FiscalYearPartner]    Script Date: 10.04.2024 14:31:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Thomas Marquardt
-- Create date: 25.07.18
-- Description: Geschäftsjahr Partner ermitteln
/*
DECLARE
    @Date                   date = '2017-05-13'
  , @BeginMonth             int
  , @EndMonth               int
  , @BeginFiscalYearHRS     date = '2017-01-01'
  , @EndFiscalYearHRS       date = '2017-12-31' 
  , @BeginFiscalYearPartner date 
  , @EndFiscalYearPartner   date 
  , @Result                 int
EXEC [dbo].[sp_HRS$FiscalYearPartner]
    @Date               
  , @BeginMonth         
  , @EndMonth           
  , @BeginFiscalYearHRS 
  , @EndFiscalYearHRS   
  , @BeginFiscalYearPartner OUT
  , @EndFiscalYearPartner   OUT
  , @Result                 OUT 
PRINT '@Date                   : ' + CONVERT(varchar(12),@Date,120)
IF @BeginMonth<>0
  PRINT '@BeginMonth             : ' + CAST(@BeginMonth AS varchar(max))
IF @EndMonth<>0
  PRINT '@EndMonth               : ' + CAST(@EndMonth AS varchar(max))
PRINT '@BeginFiscalYearHRS     : ' + CONVERT(varchar(12),@BeginFiscalYearHRS,120)
PRINT '@EndFiscalYearHRS       : ' + CONVERT(varchar(12),@EndFiscalYearHRS,120)
PRINT '@BeginFiscalYearPartner : ' + CONVERT(varchar(12),@BeginFiscalYearPartner,120)
PRINT '@EndFiscalYearPartner   : ' + CONVERT(varchar(12),@EndFiscalYearPartner,120)
PRINT @Result 
*/
CREATE PROCEDURE [dbo].[sp_HRS$FiscalYearPartner]
    @Date                   date
  , @BeginMonth             int
  , @EndMonth               int
  , @BeginFiscalYearHRS     date 
  , @EndFiscalYearHRS       date 
  , @BeginFiscalYearPartner date output
  , @EndFiscalYearPartner   date output
  , @Result                 int  output
AS BEGIN
  DECLARE @nullDate date = '1753-01-01'
   SELECT @BeginFiscalYearPartner = '1753-01-01'
        , @EndFiscalYearPartner = '1753-01-01'

  IF @BeginMonth<>0 AND @EndMonth<>0 
    BEGIN
      IF DATEPART(mm,@Date)<@BeginMonth
	    SET @BeginFiscalYearPartner = dbo.DATEFROMPARTS(DATEPART(yy,@Date)-1, @BeginMonth, 1)
	  ELSE
	    SET @BeginFiscalYearPartner = dbo.DATEFROMPARTS(DATEPART(yy,@Date), @BeginMonth, 1)

	  SET @EndFiscalYearPartner = dbo.DATEFROMPARTS(DATEPART(yy,@Date),@EndMonth,1)
      IF @EndMonth>=@BeginMonth
		SET @EndFiscalYearPartner = DATEADD(dd,-1,DATEADD(mm,1,@EndFiscalYearPartner))
	  ELSE
		SET @EndFiscalYearPartner = DATEADD(dd,-1,DATEADD(mm,1,DATEADD(yy,1,@EndFiscalYearPartner)))
    END
  ELSE
    BEGIN
      SET @BeginFiscalYearPartner = @BeginFiscalYearHRS
      SET @EndFiscalYearPartner = @EndFiscalYearHRS
    END

  IF @Date>@EndFiscalYearPartner
  BEGIN
    SET @BeginFiscalYearPartner = DATEADD(yy,DATEDIFF(yy,@EndFiscalYearPartner,@Date),@BeginFiscalYearPartner)
    SET @EndFiscalYearPartner = DATEADD(yy,1,DATEADD(dd,-1,@BeginFiscalYearPartner))
  END
END
GO
