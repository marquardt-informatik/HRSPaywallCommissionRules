USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPKommSalesInvoiceLine_HRS-CN]    Script Date: 10.04.2024 14:31:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_RPKommSalesInvoiceLine_HRS-CN] 
    @ReNr varchar(25)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ReNr2 varchar(25)
	SET @ReNr2 = @ReNr

    -- Insert statements for procedure here
  SELECT DL.[Display Case No_]
       , DL.[Reservation No_]
       , DL.[Position No_]
       , DL.[Reservation Status]
       , DL.[Reservation Date from]
       , DL.[Reservation Date to]
       , DL.[Number of Rooms]
       , DL.[Room Type]
       , DL.[Rate Description]
       , DL.[Room Price]
       , DL.[Breakfast Type]
       , DL.[Breakfast Price]
       , DL.[Commission Type]
       , DL.[Commission Rate]
       , DL.[Commission Fix]
       , DL.[Rate Type]
       , DL.[Rate Key]
       , DL.[Currency Code]
       , DL.[Currency Faktor]
       , DL.[Room Number]
       , DL.[Activity Code]
       , DL.[Number of Person]
       , DL.[Hotel No_]
       , DL.[Commission Tax Type]
       , DL.[timestamp Source]
       , DL.[Price Type]
       , DL.[Process Number]
       , DL.[Number of Nights]
       , DL.[Commission Base Amount]
       , DL.[Commission Amount]
       , DL.[Commission Base Amount (LCY)]
       , DL.[Commission Amount (LCY)]
       , DL.[Foreign Tax %]
       , DL.[Foreign Tax Amount]
       , DL.[Line Amount]
       , DL.[Client No_]
       , DL.[Reservation Activator]
       , DL.[Reservation State]
       , DL.[Reservation Date]
       , DL.[Reservation Time]
       , DL.[Reservation Source]
       , DL.[Arrival Date]
       , DL.[Departure Date]
       , DL.[Action]
       , DL.[Calculated with Contract Code]
       , DL.[Calculated with Function ID]
       , DL.[Calculated with Function Desc_]
       , DL.[Client Company]
       , DL.[Client Guestname 1]
       , DL.[Client Guestname 2]
       , DL.[Description]
       , DL.[Line Amount (LCY)]
       , DL.[Foreign Tax Base Amount]
    FROM [HRS-CN$Agency Display Line] DL WITH (READUNCOMMITTED)  
    JOIN [HRS-CN$Agency Display Header] DH WITH (READUNCOMMITTED)  
      ON DL.[Display Case No_] = DH.[Case No_]
   WHERE (DH.[Posted Invoice No_] = @ReNr2
      OR DH.[Case No_] = @ReNr2)
     AND [Action] != 3
ORDER BY DL.[Reservation No_],DL.[Position No_]
END
GO
