USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[HRS-CN$tmp_deleted_reservations]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 19.12.2011
-- Description:	<Description,,>
/*
SELECT * FROM tmp_missing_Header()
*/
-- =============================================
CREATE FUNCTION [dbo].[HRS-CN$tmp_deleted_reservations]()
RETURNS 
@ResultTab TABLE 
(
	[Range] varchar(1024)
)
AS
BEGIN
DECLARE @Result varchar(max)
 SELECT @Result = ''
;WITH _AH AS
(
   SELECT CH.[Reservation No_]
     FROM DynNavHRS.dbo.[HRS-CN$Correction Agency Header] CH WITH (NOLOCK)
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Correction Agency Line]   CL WITH (NOLOCK)
       ON CL.[Reservation No_] = CH.[Reservation No_]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Posted Agency Header]     PH WITH (NOLOCK)
       ON PH.[Reservation No_] = CH.[Reservation No_]
    WHERE CL.[Reservation No_] IS NULL
      AND PH.[Reservation No_] IS NULL
      AND CH.[Departure Date] > '2011-12-01'
      AND CH.[Reservation State] < 10000
), _Insert AS
(
SELECT TOP 100 _AH.[Reservation No_], ROW_NUMBER() OVER(ORDER BY _AH.[Reservation No_]) [RowNumber]
  FROM _AH      
)
SELECT @Result = @Result + CASE WHEN @Result='' THEN '' ELSE ',' END  + [Reservation No_]
  FROM _Insert

INSERT INTO @ResultTab
SELECT CAST('AND B.B_KEY IN ('+CASE WHEN @Result = '' THEN '0' ELSE @Result END +')' AS varchar(max)) [Range]
	RETURN 
END
GO
