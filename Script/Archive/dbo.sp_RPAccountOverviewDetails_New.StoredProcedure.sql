USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RPAccountOverviewDetails_New]    Script Date: 10.04.2024 14:31:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- ================================================
-- Author:		Dennis Juhr
-- Create date: 
-- Description:	
/*
SET Language German
EXEC DynNavHRS.[dbo].[sp_RPAccountOverviewDetails_New] '3002385758'
*/

-- 16.06.20 DJU HRS001 ACS-2271 Copied from sp_RPAccountOverviewDetails and changed to new Detailed Reminder Lines
-- 
-- ================================================
CREATE PROCEDURE [dbo].[sp_RPAccountOverviewDetails_New] 
(
	  @ReNr							VARCHAR(20)
) WITH RECOMPILE
AS BEGIN
-- get Document Type
DECLARE @DocumentType VARCHAR(20)

SELECT @DocumentType = RH.[Document Type]
  FROM [HRS$Reminder Header] RH
 WHERE RH.[No_] = @ReNr

IF @DocumentType IS NULL
	SELECT @DocumentType = RH.[Document Type]
	  FROM [HRS$Issued Reminder Header] RH
	 WHERE RH.[No_] = @ReNr

-- if Pending Closure or Closure get last Issue Reminder
IF @DocumentType = '20' OR @DocumentType = '21'  
BEGIN
   ;WITH RH AS
   (
     SELECT RH.[Customer No_]
          , RH.[Document Date]
          , RH.[Document Type]
		  , RH.[Currency Code]
		  , RH.[Currency Factor]
       FROM [HRS$Issued Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
    UNION
     SELECT RH.[Customer No_]
          , RH.[Document Date]
          , RH.[Document Type]
		  , RH.[Currency Code]
		  , RH.[Currency Factor]
       FROM [HRS$Reminder Header] RH WITH (READUNCOMMITTED)
      WHERE RH.[No_] = @ReNr
   ), RH_MAX AS
   (
     SELECT RH.[Customer No_]
          , MAX(IH.[Document Date]) [Document Date]
       FROM RH
       JOIN [HRS$Issued Reminder Header] IH WITH (READUNCOMMITTED)
         ON IH.[Customer No_] = RH.[Customer No_]
      WHERE RH.[Document Date] > IH.[Document Date]
	    AND IH.[Document Type] <> '20'
		AND IH.[Document Type] <> '21'
		AND IH.[Document Type] <> '25'
		AND IH.[Document Type] <> '26'
   GROUP BY RH.[Customer No_]
   )
   -- set last Issue Reminder as new @ReNr
   SELECT TOP 1 @ReNr = RH.[No_]
     FROM [HRS$Issued Reminder Header] RH WITH (READUNCOMMITTED)
     JOIN RH_MAX
       ON RH_MAX.[Customer No_] = RH.[Customer No_]
      AND RH_MAX.[Document Date] = RH.[Document Date]
	  ORDER BY RH.[No_] DESC
END

  ;WITH RL AS 
  (
   SELECT RH.[No_]
        , RH.[Language Code]
		, RH.[Customer No_]
		, RL.[Line No_]
        , RL.[Document No_]
		, RL.[Document Type]
        , RL.[Description]
		, RL.[Posting Date]
		, RL.[Document Date]
        , RL.[Original Amount (Curr)]
        , RL.[Remaining Amount (Curr)] 
        , RL.[Currency Code (Entry)]
		, RL.[Remaining Amount]
		, CASE WHEN CU.[VAT Bus_ Posting Group] = 'INLAND' THEN 1 ELSE 0 END [VAT]
		, CASE WHEN RL.[Currency Code (Entry)] <> RH.[Currency Code] THEN RL.[Remaining Amount (Curr)] * RH.[Currency Factor] ELSE RL.[Remaining Amount (Curr)] END [Remaining Amount (Reminder Curr)]
     FROM [HRS$Reminder Header]      RH WITH (NOLOCK) 
     JOIN [HRS$Reminder Line]        RL WITH (NOLOCK) ON RH.[No_] = RL.[Reminder No_] 
	 JOIN [HRS$Customer]             CU WITH (NOLOCK) ON RH.[Customer No_] = CU.No_
    WHERE RH.[No_] = @ReNr 
    UNION
   SELECT RH.[No_]
        , RH.[Language Code]
		, RH.[Customer No_]
		, RL.[Line No_]
        , RL.[Document No_]
		, RL.[Document Type]
        , RL.[Description]
		, RL.[Posting Date]
		, RL.[Document Date]
        , RL.[Original Amount (Curr)]
        , RL.[Remaining Amount (Curr)] 
        , RL.[Currency Code (Entry)]
		, RL.[Remaining Amount]
		, CASE WHEN CU.[VAT Bus_ Posting Group] = 'INLAND' THEN 1 ELSE 0 END [VAT]
		, CASE WHEN RL.[Currency Code (Entry)] <> RH.[Currency Code] THEN RL.[Remaining Amount (Curr)] * RH.[Currency Factor] ELSE RL.[Remaining Amount (Curr)] END [Remaining Amount (Reminder Curr)]
     FROM [HRS$Issued Reminder Header] RH WITH (NOLOCK)
     JOIN [HRS$Issued Reminder Line]   RL WITH (NOLOCK) ON RH.[No_] = RL.[Reminder No_] 
	 JOIN [HRS$Customer]               CU WITH (NOLOCK) ON RH.[Customer No_] = CU.No_
    WHERE RH.[No_] = @ReNr
  ), DRL AS 
  ( 
   SELECT DRL.[Reminder No_]
        , DRL.[Reminder Line No_]
        , DRL.[Reservation No_]
        , DRL.[Booking Code]
		, DRL.[MuseID]
        , DRL.[Arrival Date]
        , DRL.[Departure Date]
        , DRL.[Client Guestname 1]
        , DRL.[Client Guestname 2]
        , DRL.[Rate Description]
        , DRL.[Original Amount]
        , DRL.[Remaining Amount]
        , DRL.[Currency Code]
		, DRL.[Remaining Amount (LCY)]
		, CASE WHEN DRL.[Currency Code] <> RH.[Currency Code] THEN DRL.[Remaining Amount] * RH.[Currency Factor] ELSE DRL.[Remaining Amount] END [Remaining Amount (Reminder Curr)]
     FROM [HRS$Detailed Reminder Line] DRL WITH (NOLOCK)
	 JOIN [HRS$Reminder Header]        RH WITH (NOLOCK) ON DRL.[Reminder No_] = RH.No_
	WHERE DRL.[Reminder No_] = @ReNr
	UNION
   SELECT DRL.[Reminder No_]
        , DRL.[Reminder Line No_]
        , DRL.[Reservation No_]
        , DRL.[Booking Code]
		, DRL.[MuseID]
        , DRL.[Arrival Date]
        , DRL.[Departure Date]
        , DRL.[Client Guestname 1]
        , DRL.[Client Guestname 2]
        , DRL.[Rate Description]
        , DRL.[Original Amount]
        , DRL.[Remaining Amount]
        , DRL.[Currency Code]
		, DRL.[Remaining Amount (LCY)]
		, CASE WHEN DRL.[Currency Code] <> RH.[Currency Code] THEN DRL.[Remaining Amount] * RH.[Currency Factor] ELSE DRL.[Remaining Amount] END [Remaining Amount (Reminder Curr)]
     FROM [HRS$Issued Detailed Reminder Line] DRL WITH (NOLOCK)
	 JOIN [HRS$Issued Reminder Header]        RH WITH (NOLOCK) ON DRL.[Reminder No_] = RH.No_
	WHERE DRL.[Reminder No_] = @ReNr
  ), DRL_SUM AS 
  (
   SELECT DRL.[Reminder No_]
        , DRL.[Reminder Line No_]
		, SUM(DRL.[Remaining Amount])		[Remaining Amount]
		, SUM(DRL.[Remaining Amount (LCY)]) [Remaining Amount (LCY)]
		, SUM(DRL.[Remaining Amount (Reminder Curr)]) [Remaining Amount (Reminder Curr)]
     FROM DRL
 GROUP BY DRL.[Reminder No_]
        , DRL.[Reminder Line No_]
  )

     -- Commission Invoices
     SELECT RL.[Document No_]				[Document No_]
          , DRL.[Currency Code]				[Currency Code]
          , DRL.[MuseID]					[MuseID]
          , DRL.[Reservation No_]			[Reservation No_]
          , DRL.[Booking Code]				[Buchungscode]
          , DRL.[Client Guestname 1]		[Guestname 1]
          , DRL.[Client Guestname 2]		[Guestname 2]
          , DRL.[Arrival Date]				[Arrival]
          , DRL.[Departure Date]			[Departure]
		  , RL.VAT							[VAT]
          , DRL.[Rate Description]			[Rate Bezeichnung]
          , DRL.[Original Amount]			[Amount of Debits]
          , DRL.[Remaining Amount]			[Difference]
          , RL.[Language Code]				[Language Code]
          , 'REGULAR'						[ID]
		  , RL.[Customer No_]				[Customer No_]
		  , DRL.[Remaining Amount (Reminder Curr)]
          , DRL.[Remaining Amount (LCY)]
       FROM RL
       JOIN DRL 
         ON RL.[Line No_] = DRL.[Reminder Line No_]
      WHERE RL.[Document Type] = 2
	    AND ABS(DRL.[Remaining Amount]) > 0.09
		AND ABS(DRL.[Remaining Amount (LCY)]) > 0.09

	 UNION

     -- No Matching
     SELECT RL.[Document No_]				[Document No_]
          , RL.[Currency Code (Entry)]		[Currency Code]
          , NULL							[MuseID]
          , NULL							[Reservation No_]
          , NULL							[Buchungscode]
          , RL.[Description]				[Guestname 1]
          , NULL							[Guestname 2]
          , RL.[Posting Date]				[Arrival]
          , RL.[Document Date]				[Departure]
		  , RL.VAT							[VAT]
          , NULL							[Rate Bezeichnung]
          , RL.[Remaining Amount (Curr)] 
		  - DRL_SUM.[Remaining Amount]		[Amount of Debits]
          , RL.[Remaining Amount (Curr)] 
		  - DRL_SUM.[Remaining Amount]		[Difference]
          , RL.[Language Code]				[Language Code]
          , 'NOMATCHING'					[ID]
		  , RL.[Customer No_]				[Customer No_]
		  , RL.[Remaining Amount (Reminder Curr)]
		  - DRL_SUM.[Remaining Amount (Reminder Curr)]
		  , RL.[Remaining Amount]
		  - DRL_SUM.[Remaining Amount] [Remaining Amount (LCY)]
       FROM RL
       JOIN DRL_SUM 
         ON RL.[Line No_] = DRL_SUM.[Reminder Line No_]
      WHERE RL.[Document Type] = 2
	    AND ABS(RL.[Remaining Amount (Curr)] - DRL_SUM.[Remaining Amount]) > 0.09
		AND ABS(RL.[Remaining Amount] - DRL_SUM.[Remaining Amount (LCY)]) > 0.09

	 UNION

     -- Other Invoices
     SELECT RL.[Document No_]				[Document No_]
          , RL.[Currency Code (Entry)]		[Currency Code]
          , NULL							[MuseID]
          , NULL							[Reservation No_]
          , NULL							[Buchungscode]
          , RL.[Description]				[Guestname 1]
          , NULL							[Guestname 2]
          , RL.[Posting Date]				[Arrival]
          , RL.[Document Date]				[Departure]
		  , RL.VAT							[VAT]
          , NULL							[Rate Bezeichnung]
          , RL.[Original Amount (Curr)]		[Amount of Debits]
          , RL.[Remaining Amount (Curr)]	[Difference]
          , RL.[Language Code]				[Language Code]
          , CASE 
				WHEN LEFT(RL.[Document No_],2) = 'MA' THEN 'MARKETING' 
				WHEN LEFT(RL.[Document No_],2) = 'WB' THEN 'SUBSEQUENT' 
				WHEN SIH.[Order Type] = 4 THEN 'SUBSEQUENT' -- Marketplace Fee
				WHEN SIH.[Order Type] = 5 THEN 'SUBSEQUENT' -- Sourcing Fee
				WHEN SIH.[Order Type] = 7 THEN 'SUBSEQUENT' -- TAF
				ELSE 'REGULAR' 
			END								[ID]
		  , RL.[Customer No_]				[Customer No_]
		  , RL.[Remaining Amount (Reminder Curr)]
		  , RL.[Remaining Amount] [Remaining Amount (LCY)]
       FROM RL
  LEFT JOIN DRL 
         ON RL.[Line No_] = DRL.[Reminder Line No_]
  LEFT JOIN [HRS$Sales Invoice Header] SIH WITH (NOLOCK)
         ON RL.[Document No_] = SIH.No_
      WHERE RL.[Document Type] = 2
	    AND DRL.[Reminder Line No_] IS NULL

      UNION

     -- Payments
     SELECT RL.[Document No_]				[Document No_]
          , RL.[Currency Code (Entry)]		[Currency Code]
          , NULL							[MuseID]
          , NULL							[Reservation No_]
          , NULL							[Buchungscode]
          , RL.[Description]				[Guestname 1]
          , NULL							[Guestname 2]
          , RL.[Posting Date]				[Arrival]
          , RL.[Document Date]				[Departure]
		  , RL.VAT							[VAT]
          , NULL							[Rate Bezeichnung]
          , RL.[Original Amount (Curr)]		[Amount of Debits]
          , RL.[Remaining Amount (Curr)]	[Difference]
          , RL.[Language Code]				[Language Code]
          , 'PAYMENT'						[ID]
		  , RL.[Customer No_]				[Customer No_]
		  , RL.[Remaining Amount (Reminder Curr)]
		  , RL.[Remaining Amount] [Remaining Amount (LCY)]
       FROM RL
      WHERE RL.[Document Type] = 1

      UNION

     -- Cr. Memos
     SELECT RL.[Document No_]				[Document No_]
          , RL.[Currency Code (Entry)]		[Currency Code]
          , NULL							[MuseID]
          , NULL							[Reservation No_]
          , NULL							[Buchungscode]
          , RL.[Description]				[Guestname 1]
          , NULL							[Guestname 2]
          , RL.[Posting Date]				[Arrival]
          , RL.[Document Date]				[Departure]
		  , RL.VAT							[VAT]
          , NULL							[Rate Bezeichnung]
          , RL.[Original Amount (Curr)]		[Amount of Debits]
          , RL.[Remaining Amount (Curr)]	[Difference]
          , RL.[Language Code]				[Language Code]
          , 'CRMEMO'						[ID]
		  , RL.[Customer No_]				[Customer No_]
		  , RL.[Remaining Amount (Reminder Curr)]
		  , RL.[Remaining Amount] [Remaining Amount (LCY)]
       FROM RL
      WHERE RL.[Document Type] = 3
END
GO
