USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_QueryRebateHeader]    Script Date: 10.04.2024 14:31:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 16.04.19
-- Description:	Zeigt für jedes Jahr den zuletzt gebuchten Kontoauszug und den ersten noch nicht gebuchten Kontoauszug
-- Duration:    1 Sekunde
--
-- Version | Date     | Developer | Ticket   | Description      
-- --------+----------+-----------+----------+-----------------------------------------------------------------------------------------------------   
--         |          |           |          | 
/*
DECLARE @VendorNo varchar(20) = '1502'
EXEC [dbo].[sp_QueryRebateHeader] @VendorNo
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_QueryRebateHeader]
  @VendorNo varchar(20) = ''
AS
BEGIN
    WITH RH AS
	(
	  SELECT RH.[Rebate Agreement No_]
	       , RH.[Rebate-to Vendor No_]
		   , YEAR(RH.[Document Date]) [Rebate Year]
		   , AH.[Interval]
		   , '1753-01-01' [Last Posted Document Date]
		   , '' [Last Posted Document No_]
		   , RH.[Document Date] [Actual Document Date]
		   , RH.[No_] [Actual Document No_]
		   , AH.[Active]
	    FROM [HRS$Rebate Header] RH WITH (NOLOCK)
		JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
		  ON AH.[No_] = RH.[Rebate Agreement No_]
       WHERE @VendorNo IN (RH.[Rebate-to Vendor No_],'')
       UNION
	  SELECT RH.[Rebate Agreement No_]
	       , RH.[Rebate-to Vendor No_]
		   , YEAR(RH.[Document Date]) [Rebate Year]
		   , AH.[Interval]
		   , RH.[Document Date] [Last Posted Document Date]
		   , RH.[No_] [Last Posted Document No_]
		   , '1753-01-01' [Actual Document Date]
		   , '' [Actual Document No_]
		   , AH.[Active]
	    FROM [HRS$Posted Rebate Header] RH WITH (NOLOCK)
		JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
		  ON AH.[No_] = RH.[Rebate Agreement No_]
       WHERE RH.[Cancels] = 0
         AND @VendorNo IN (RH.[Rebate-to Vendor No_],'')
	), RHL AS
	(
	  SELECT [Rebate Agreement No_]
	       , [Rebate-to Vendor No_]
		   , [Rebate Year]
		   , [Interval]
		   , MAX([Active]) [Active]
		   , MAX([Last Posted Document Date]) [Last Posted Document Date]
	    FROM RH
    GROUP BY [Rebate Agreement No_]
	       , [Rebate-to Vendor No_]
		   , [Rebate Year]
		   , [Interval]
	), RHA AS
	(
	  SELECT [Rebate Agreement No_]
	       , [Rebate-to Vendor No_]
		   , [Rebate Year]
		   , [Interval]
		   , MAX([Active]) [Active]
		   , MIN([Actual Document Date]) [Actual Document Date]
	    FROM RH
    GROUP BY [Rebate Agreement No_]
	       , [Rebate-to Vendor No_]
		   , [Rebate Year]
		   , [Interval]
	), RHM AS
	(
	  SELECT RHA.[Rebate Agreement No_]
	       , RHA.[Rebate-to Vendor No_]
		   , RHA.[Rebate Year]
		   , RHA.[Interval]
		   , RHA.[Actual Document Date]
		   , MIN(A.[Actual Document No_]) [Actual Document No_]
		   , RHL.[Last Posted Document Date]
		   , MAX(L.[Last Posted Document No_]) [Last Posted Document No_]
	    FROM RHA
	    JOIN RHL
	      ON RHL.[Rebate Agreement No_]    = RHA.[Rebate Agreement No_]
         AND RHL.[Rebate Year]             = RHA.[Rebate Year]
	    JOIN RH A
	      ON A.[Rebate Agreement No_]      = RHA.[Rebate Agreement No_]
         AND A.[Rebate Year]               = RHA.[Rebate Year]
         AND A.[Actual Document Date]      = RHA.[Actual Document Date]
	    JOIN RH L
	      ON L.[Rebate Agreement No_]      = RHA.[Rebate Agreement No_]
         AND L.[Rebate Year]               = RHA.[Rebate Year]
         AND L.[Last Posted Document Date] = RHL.[Last Posted Document Date]
    GROUP BY RHA.[Rebate Agreement No_]
	       , RHA.[Rebate-to Vendor No_]
		   , RHA.[Rebate Year]
		   , RHA.[Interval]
		   , RHA.[Actual Document Date]
		   , RHL.[Last Posted Document Date]
	)
	SELECT *
	  FROM RHM
  ORDER BY [Rebate Agreement No_], [Rebate Year]	  
END
GO
