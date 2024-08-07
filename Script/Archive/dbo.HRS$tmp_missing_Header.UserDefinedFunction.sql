USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [dbo].[HRS$tmp_missing_Header]    Script Date: 10.04.2024 14:30:57 ******/
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
CREATE FUNCTION [dbo].[HRS$tmp_missing_Header]()
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
   SELECT DISTINCT AL.[Reservation No_]
     FROM [HRS$Agency Line]              AL WITH (NOLOCK)
LEFT JOIN [HRS$Agency Header]            AH WITH (NOLOCK)
       ON AH.[Reservation No_] = AL.[Reservation No_]
LEFT JOIN [HRS$Correction Agency Header] CH WITH (NOLOCK)
       ON CH.[Reservation No_] = AL.[Reservation No_]
LEFT JOIN [HRS$Posted Agency Header]     PH WITH (NOLOCK)
       ON PH.[Reservation No_] = AL.[Reservation No_]
    WHERE AH.[Reservation No_] IS NULL
      AND CH.[Reservation No_] IS NULL
      AND PH.[Reservation No_] IS NULL
      AND AL.[Reservation Date to] >= '2011-12-01'
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
