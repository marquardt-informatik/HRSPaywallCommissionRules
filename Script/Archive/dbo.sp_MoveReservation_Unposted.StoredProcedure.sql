USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_MoveReservation_Unposted]    Script Date: 10.04.2024 14:31:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<KMA>
-- Create date: <01.08.22>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_MoveReservation_Unposted] 
	@FromCompany varchar(20),
	@TOCompany VARCHAR(20),
	@ReservationNo VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Declare @SqlSt VARCHAR (MAX);

BEGIN TRANSACTION


SET @SqlSt = 'INSERT INTO [DynNavHRS].[dbo].['+ @TOCompany +'$Agency Header]([Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Loyality Rewards Account No_],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Ranking Booster],[Payment Type],[Corporate Rate Discount],[Booking Comment],[Multisourced],[Segment],[TAF Business Rules Code],[TAF Contract Code])
SELECT [Reservation No_],[Client No_],[Hotel No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Client Company],[Client Guestname 1],[Client Guestname 2],[Commission Status],[Description],[MuseID],[Currency Code],[Currency Factor],[Chain ID],[Brand ID],[Handbooking],[timestamp Source],[IFC Version],[Total Rate],[Total Rate incl_],[Discount %],[MusePassword],[ProcessNumber],[Job No_],[Customer No_],[Booking Status],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Insert Header],[Error Code],[Contract Code],[Contract Group Code],[Agency Business Rules Code],[Loyality Rewards Account No_],[Parent Reservation No_],[Confirmed Reservation No_],[Quality by User],[Quality at],[Company No_],[Ranking Booster],[Payment Type],[Corporate Rate Discount],[Booking Comment],[Multisourced],[Segment],[TAF Business Rules Code],[TAF Contract Code]
  FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Header]
 WHERE [Reservation No_] = ' + @ReservationNo;
EXEC(@SqlSt);

 
SET @SqlSt = 'INSERT INTO [DynNavHRS].[dbo].['+ @TOCompany +'$Agency Line] ([Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Loyality Rewards Account No_],[Chain],[Brand],[Client No_],[Country_Region Code],[Ranking Booster],[Payment Type],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Reason For Change],[TAF Business Rules Code],[Breakfast Approval Status],[Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_])
SELECT [Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Loyality Rewards Account No_],[Chain],[Brand],[Client No_],[Country_Region Code],[Ranking Booster],[Payment Type],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Reason For Change],[TAF Business Rules Code],[Breakfast Approval Status],[Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_]
  FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Line]
 WHERE [Reservation No_] = ' + @ReservationNo; 
EXEC(@SqlSt);

 
SET @SqlSt = 'DELETE FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Line]
 WHERE [Reservation No_] = '+ @ReservationNo;
EXEC(@SqlSt); 
 
SET @SqlSt = 'DELETE
  FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Header]
 WHERE [Reservation No_] = ' + @ReservationNo; 
 EXEC(@SqlSt);


----Delete Invoices

SET @SqlSt = 'DELETE FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Line] 
WHERE [Reservation No_] = ' + @ReservationNo +' AND [Display Case No_] 
IN (SELECT DH.[Case No_] FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Line] DL
JOIN [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Header] DH ON DH.[Case No_]= DL.[Display Case No_]
WHERE DL.[Reservation No_] = '+@ReservationNo +' AND DH.[Status] =0 AND DH.[Posted Invoice No_] = '''')';
EXEC(@SqlSt);

SET @SqlSt = 'DELETE FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Header] WHERE [Case No_] 
IN (SELECT DH.[Case No_] FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Line] DL
JOIN [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Header] DH ON DH.[Case No_]= DL.[Display Case No_]
WHERE DL.[Reservation No_] = '+@ReservationNo +' AND DH.[Status] =0 AND DH.[Posted Invoice No_] = '''' 
AND 0 = (SELECT Count(1) FROM [DynNavHRS].[dbo].['+ @FromCompany +'$Agency Display Line] WHERE [Display Case No_] = [Case No_]))'; 
EXEC(@SqlSt); 

--ROLLBACK; 
COMMIT   
--Select CASE WHEN 1=1 Then '1' ELSE '0' END [Count]  

END
GO
