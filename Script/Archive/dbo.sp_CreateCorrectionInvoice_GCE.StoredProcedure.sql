USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_CreateCorrectionInvoice_GCE]    Script Date: 10.04.2024 14:31:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 05.03.19
-- Description:	Creates a unposted correction commission invoice
-- 01.07.21 TMA Neues Feld [Confirmed at] in [HRS$Agency Display Header]
/*
EXEC [dbo].[sp_CreateCorrectionInvoice_GCE] 72
--UPDATE [HRS$Partner Import Line] SET [Correction Case No_] = '' WHERE [Import Entry No_] = 42
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_CreateCorrectionInvoice_GCE] 
  @ImportEntryNo int
AS
BEGIN
SET NOCOUNT ON  
	DECLARE @dateFrom    date
		  , @dateTo      date
		  , @PostingDate date
		  , @NoSeries    varchar(10) = 'AGKV'
		  , @PostedInvoiceNo varchar(20) = ''
		  , @CorrectionFrom varchar(20) = ''
		  , @CaseNo varchar(20) = ''
		  , @CorrectionUnposted tinyint = 0

DECLARE @Status int = 2
DECLARE @OldCaseNo varchar(20)='', @NewCaseNo varchar(20)=''
DECLARE @UnpostedCrMemoNo varchar(20), @UnpostedInvoiceNo varchar(20)

-- übergebene Reservierungen werden nicht gefunden, da bei HRS nachträglich Korrekturen stattgefunden haben -> es wurden zu Vorgängen eine oder mehrere neue Reservierungsnummern erzeugt
BEGIN -- Reservierungsnummern aktualisieren
	DECLARE @BP_KEY int, @B_KEY int, @ImportLineNo int, @ReservationNo varchar(20)
	DECLARE cur CURSOR FOR
	SELECT PIL.[Import Line No_]
		 , PIL.[Reservation No_]
	  FROM [HRS$Partner Import Line] PIL WITH (NOLOCK)
	 WHERE 1=1 --ABS(PIL.[Comm_ Amount Paym_ Curr_])>=0.1
	   AND PIL.[Import Entry No_] = @ImportEntryNo
	   AND ISNUMERIC(PIL.[Reservation No_])>0

	OPEN cur

	FETCH NEXT FROM cur INTO @ImportLineNo, @ReservationNo

	WHILE @@FETCH_STATUS=0
	BEGIN

	  WHILE EXISTS( SELECT * FROM HRSDB.BUCHUNG WHERE B_KEY_ALT=@ReservationNo)
	  BEGIN
	    SELECT @ReservationNo = B_KEY FROM HRSDB.BUCHUNG WHERE B_KEY_ALT=@ReservationNo
	  END

	  SELECT @CaseNo = COALESCE(RIGHT(MAX(CASE WHEN LEFT(DH.[Case No_],1)='V' THEN 'A' ELSE 'B' END + DH.[Case No_]),10),'')
	  FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
	  JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
		ON DH.[Case No_] = DL.[Display Case No_]
	 WHERE DL.[Reservation No_] = @ReservationNo
	   AND DH.[Status] = 1

	SELECT @NewCaseNo = COALESCE(RIGHT(MAX(CASE WHEN LEFT(DH.[Case No_],1)='V' THEN 'A' ELSE 'B' END + DH.[Case No_]),10),'')
	  FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
	  JOIN [HRS$Agency Display Header] DH WITH (NOLOCK)
		ON DH.[Case No_] = DL.[Display Case No_]
	 WHERE DL.[Reservation No_] = @ReservationNo
	   AND DH.[Status] = 2


	BEGIN TRY
	  UPDATE [HRS$Partner Import Line] SET [Reservation No_] = @ReservationNo, [Display Case No_] = @CaseNo, [Correction Case No_] = @NewCaseNo 
	   WHERE [Import Line No_] = @ImportLineNo
	     AND (
		     [Reservation No_] <> @ReservationNo
		  OR [Display Case No_] <> @CaseNo
		  OR [Correction Case No_] <> @NewCaseNo
		     )
	END TRY
	BEGIN CATCH
	  PRINT '@ImportLineNo : ' + CAST(@ImportLineNo AS varchar(20)) + ', @ReservationNo : ' + CAST(@ReservationNo AS varchar(20))
	  PRINT '  -> @CaseNo = ' + @CaseNo + ', @NewCaseNo = ' + @NewCaseNo 
	END CATCH
	  PRINT '@ImportLineNo : ' + CAST(@ImportLineNo AS varchar(20)) + ', @ReservationNo : ' + CAST(@ReservationNo AS varchar(20))
	  PRINT '  -> @CaseNo = ' + @CaseNo + ', @NewCaseNo = ' + @NewCaseNo 
	 FETCH NEXT FROM cur INTO @ImportLineNo, @ReservationNo
	END

	CLOSE cur
	DEALLOCATE cur
END -- 

     SELECT @PostedInvoiceNo = [Posted Invoice No_]
	      , @CorrectionFrom = [Correction from]
		  , @CaseNo = ADH.[Case No_]
       FROM [HRS$Agency Display Header] ADH
	   JOIN [HRS$Partner Import Header] PIH
	     ON PIH.[Entry No_] = @ImportEntryNo
        AND PIH.[Posting Date] = ADH.[Creation Date]
        AND PIH.[Bill-to Customer No_] = ADH.[Bill-to Customer No_]
        AND (ADH.[Posted Invoice No_] NOT IN 
            (
              SELECT H.[Correction from] 
                FROM [HRS$Agency Display Header] H WITH (NOLOCK)
                JOIN [HRS$Partner Import Header] I
                  ON I.[Entry No_] = @ImportEntryNo
                 AND I.[Posting Date] = H.[Creation Date]
                 AND I.[Bill-to Customer No_] = H.[Bill-to Customer No_]
            ) OR ADH.[Posted Invoice No_]='')

SELECT @PostedInvoiceNo = [Posted Invoice No_] FROM [HRS$Agency Display Header] WHERE [Case No_]=@CaseNo
PRINT '@PostedInvoiceNo   :' + @PostedInvoiceNo
SET @CorrectionUnposted = CASE WHEN @PostedInvoiceNo='' AND @CorrectionFrom<>'' THEN 1 ELSE 0 END

IF @CorrectionUnposted = 1
  SET @NewCaseNo = @CaseNo

PRINT '@PostedInvoiceNo   :' + @PostedInvoiceNo
PRINT '@CorrectionFrom    :' + @CorrectionFrom
PRINT '@CaseNo            :' + @CaseNo
PRINT '@CorrectionUnposted:' + CAST(@CorrectionUnposted AS varchar)
PRINT '@NewCaseNo         :' + @NewCaseNo

    DECLARE @OldNumber int, @StartNumber varchar(20)
     SELECT @OldNumber = CAST(REPLACE([Last No_ Used],'K','') AS INT), @StartNumber=NSL.[Starting No_] FROM [HRS$No_ Series Line] NSL WHERE [Series Code] = @NoSeries AND [Open] =1 AND Dummy = 0

PRINT '@OldNumber         :' + CAST(@OldNumber AS varchar(20))

IF @CorrectionUnposted = 1
  SET @PostedInvoiceNo = @CorrectionFrom
SELECT @UnpostedCrMemoNo = @PostedInvoiceNo + '/CR'
     , @UnpostedInvoiceNo = CASE WHEN CHARINDEX('/',@PostedInvoiceNo)=0 THEN @PostedInvoiceNo + '/01' 
	                             ELSE LEFT(@PostedInvoiceNo,LEN(@PostedInvoiceNo)-2) + RIGHT('00'+CAST(CAST(RIGHT(@PostedInvoiceNo,2) AS int)+1 AS varchar(2)),2)
							END
PRINT @PostedInvoiceNo
PRINT @UnpostedCrMemoNo
PRINT @UnpostedInvoiceNo

SELECT @OldCaseNo = [Case No_] FROM [HRS$Agency Display Header] WHERE [Posted Invoice No_] = @PostedInvoiceNo AND [Status] = 1

IF @OldCaseNo<>'' 
BEGIN
  SELECT @NewCaseNo = [Case No_] FROM [HRS$Agency Display Header] WHERE [Correction from] = @PostedInvoiceNo
  IF @NewCaseNo=''
  BEGIN
    SELECT @NewCaseNo = CAST(@OldNumber+1 AS varchar(20))
    SELECT @NewCaseNo = LEFT(@StartNumber,LEN(@StartNumber)-LEN(@NewCaseNo))+@NewCaseNo
  END

  PRINT @OldCaseNo
  PRINT @NewCaseNo

  IF NOT EXISTS (SELECT * FROM [HRS$Agency Display Header] WHERE [Correction from] = @PostedInvoiceNo)
  BEGIN
    INSERT INTO [HRS$Agency Display Header]([Case No_],[Bill-to Customer No_],[Bill-to Name],[Bill-to Address],[Bill-to Address 2],[Bill-to City],[Bill-to Post Code],[Bill-to Country_Region Code],[Bill-to Contact No_],[Bill-to Contact],[No_ Series],[Status],[Posted Invoice No_],[Correction from],[Creation Date],[Posting Date],[Currency Factor],[MuseID],[Currency Code],[Salesperson Code],[Foreign Tax %],[Chain Code],[Language Code],[Document Type],[Brand Code],[VAT Bus_ Posting Group],[VAT Prod_ Posting Group],[Loyality Rewards Account No_],[Bill-to Name 2],[Unposted Invoice No_],[Unposted Cred_ Memo No_],[Subsequent Debit from],[Delivery Type Split Invoice],[Receipient Split Invoice],[Delivery Type Fapiao],[Delivery Date Fapiao],[Fapiao No_],[Confirmed],[Confirmed at])
    SELECT @NewCaseNo [Case No_],[Bill-to Customer No_],[Bill-to Name],[Bill-to Address],[Bill-to Address 2],[Bill-to City],[Bill-to Post Code],[Bill-to Country_Region Code],[Bill-to Contact No_],[Bill-to Contact],[No_ Series], @Status [Status],''[Posted Invoice No_],@PostedInvoiceNo [Correction from],[Creation Date],[Posting Date],[Currency Factor],[MuseID],[Currency Code],[Salesperson Code],[Foreign Tax %],[Chain Code],[Language Code],[Document Type],[Brand Code],[VAT Bus_ Posting Group],[VAT Prod_ Posting Group],[Loyality Rewards Account No_],[Bill-to Name 2],@UnpostedInvoiceNo [Unposted Invoice No_],@UnpostedCrMemoNo [Unposted Cred_ Memo No_],[Subsequent Debit from],[Delivery Type Split Invoice],[Receipient Split Invoice],[Delivery Type Fapiao],[Delivery Date Fapiao],[Fapiao No_],[Confirmed],[Confirmed at]
      FROM [HRS$Agency Display Header] WHERE [Case No_] = @OldCaseNo
    UPDATE [HRS$No_ Series Line] SET [Last No_ Used] = @NewCaseNo, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) 
     WHERE [Series Code] = @NoSeries
       AND [Open] =1 AND Dummy = 0
  END -- IF NOT EXISTS Correction 

  SET @CorrectionUnposted=1
END

IF @CorrectionUnposted=1
BEGIN
   INSERT INTO [HRS$Agency Display Line]([Display Case No_],[Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Client No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Action],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Client Company],[Client Guestname 1],[Client Guestname 2],[Description],[MuseID],[Handbooking],[ProcessNumber],[Booking Quality],[Booking Code],[Invoice No_ Old System],[Invoice Line No_ Old System],[Loyality Rewards Account No_],[Foreign Tax Roomnight Base Amt],[Foreign Tax Breakf Base Amount],[Commission Roomnight Base Amnt],[Commission Breakf Base Amount],[Foreign Tax Roomnight Amount],[Foreign Tax Breakf Amount],[Commission Roomnight Amount],[Commission Breakf Amount],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Confirmed Reservation No_],[Quality by User],[Quality at],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Booking Comment],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Booking Rating],[Multisourced],[Segment],[Reason For Change],[Breakfast Approval Status],[Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_],[TAF Business Rules Code])
   SELECT @NewCaseNo [Display Case No_],ADL.[Reservation No_],ADL.[Position No_],ADL.[Reservation Status],ADL.[Reservation Date from],ADL.[Reservation Date to],ADL.[Number of Rooms],ADL.[Room Type],ADL.[Rate Description],ADL.[Room Price],ADL.[Breakfast Type],ADL.[Breakfast Price],ADL.[Commission Type],ADL.[Commission Rate],ADL.[Commission Fix],ADL.[Rate Type],ADL.[Rate Key],ADL.[Currency Code],ADL.[Currency Faktor],ADL.[Room Number],ADL.[Activity Code],ADL.[Number of Person],ADL.[Hotel No_],ADL.[Commission Tax Type],ADL.[timestamp Source],ADL.[Price Type],ADL.[Process Number],ADL.[Inserted by User],ADL.[Inserted at],ADL.[Modified by User],ADL.[Modified at],ADL.[Number of Nights],ADL.[Commission Base Amount],ADL.[Commission Amount],ADL.[Commission Base Amount (LCY)],ADL.[Commission Amount (LCY)],ADL.[Foreign Tax %],ADL.[Foreign Tax Amount],ADL.[Line Amount],ADL.[Line Amount (LCY)],ADL.[Foreign Tax Base Amount],ADL.[Hotel sales incl_ VAT],ADL.[Client No_],ADL.[Reservation Activator],ADL.[Reservation State],ADL.[Reservation Date],ADL.[Reservation Time],ADL.[Reservation Source],ADL.[Arrival Date],ADL.[Departure Date],CASE WHEN ADL.[Action]<>3 THEN 0 ELSE ADL.[Action] END [Action],ADL.[Calculated with Contract Code],ADL.[Calculated with Function ID],ADL.[Calculated with Function Desc_],ADL.[Client Company],ADL.[Client Guestname 1],ADL.[Client Guestname 2],ADL.[Description],ADL.[MuseID],ADL.[Handbooking],ADL.[ProcessNumber],ADL.[Booking Quality],ADL.[Booking Code],ADL.[Invoice No_ Old System],ADL.[Invoice Line No_ Old System],ADL.[Loyality Rewards Account No_],ADL.[Foreign Tax Roomnight Base Amt],ADL.[Foreign Tax Breakf Base Amount],ADL.[Commission Roomnight Base Amnt],ADL.[Commission Breakf Base Amount],ADL.[Foreign Tax Roomnight Amount],ADL.[Foreign Tax Breakf Amount],ADL.[Commission Roomnight Amount],ADL.[Commission Breakf Amount],ADL.[Foreign Tax % Roomnight],ADL.[Foreign Tax % Breakf],ADL.[Confirmed Reservation No_],ADL.[Quality by User],ADL.[Quality at],ADL.[Ranking Booster],ADL.[Corporate Rate Discount],ADL.[Net Room Price],ADL.[Net Breakfast Price],ADL.[Booking Comment],ADL.[Agency Business Rules Code],ADL.[Deduction Type],ADL.[Deductible Amount],ADL.[Booking Rating],ADL.[Multisourced],ADL.[Segment],ADL.[Reason For Change],ADL.[Breakfast Approval Status], ADL.[Rate Plan Code],ADL.[Agency Line Amount],ADL.[Agency Line Amount (LCY)],ADL.[TAF Line Amount],ADL.[TAF Line Amount (LCY)],ADL.[TAF Type],ADL.[TAF Rate],ADL.[TAF Fix],ADL.[TAF Contract Code],ADL.[TAF Function ID],ADL.[TAF Function Desc_],ADL.[TAF Business Rules Code]
     FROM [HRS$Agency Display Line] ADL
LEFT JOIN [HRS$Agency Display Line] PIL WITH (NOLOCK)
       ON PIL.[Reservation No_] = ADL.[Reservation No_]
      AND PIL.[Position No_] = ADL.[Position No_]
      AND PIL.[Display Case No_] = @NewCaseNo
    WHERE ADL.[Display Case No_] = @OldCaseNo
      AND PIL.[Reservation No_] IS NULL

   INSERT INTO [HRS$Agency Display Line]([Display Case No_],[Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Client No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Action],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Client Company],[Client Guestname 1],[Client Guestname 2],[Description],[MuseID],[Handbooking],[ProcessNumber],[Booking Quality],[Booking Code],[Invoice No_ Old System],[Invoice Line No_ Old System],[Loyality Rewards Account No_],[Foreign Tax Roomnight Base Amt],[Foreign Tax Breakf Base Amount],[Commission Roomnight Base Amnt],[Commission Breakf Base Amount],[Foreign Tax Roomnight Amount],[Foreign Tax Breakf Amount],[Commission Roomnight Amount],[Commission Breakf Amount],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Confirmed Reservation No_],[Quality by User],[Quality at],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Booking Comment],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Booking Rating],[Multisourced],[Segment],[Reason For Change],[Breakfast Approval Status],[Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_],[TAF Business Rules Code])
   SELECT DISTINCT @NewCaseNo [Display Case No_],ADL.[Reservation No_],ADL.[Position No_],ADL.[Reservation Status],ADL.[Reservation Date from],ADL.[Reservation Date to],ADL.[Number of Rooms],ADL.[Room Type],ADL.[Rate Description],ADL.[Room Price],ADL.[Breakfast Type],ADL.[Breakfast Price],ADL.[Commission Type],ADL.[Commission Rate],ADL.[Commission Fix],ADL.[Rate Type],ADL.[Rate Key],ADL.[Currency Code],ADL.[Currency Faktor],ADL.[Room Number],ADL.[Activity Code],ADL.[Number of Person],ADL.[Hotel No_],ADL.[Commission Tax Type],ADL.[timestamp Source],ADL.[Price Type],ADL.[Process Number],ADL.[Inserted by User],ADL.[Inserted at],ADL.[Modified by User],ADL.[Modified at],ADL.[Number of Nights],ADL.[Commission Base Amount],ADL.[Commission Amount],ADL.[Commission Base Amount (LCY)],ADL.[Commission Amount (LCY)],ADL.[Foreign Tax %],ADL.[Foreign Tax Amount],ADL.[Line Amount],ADL.[Line Amount (LCY)],ADL.[Foreign Tax Base Amount],ADL.[Hotel sales incl_ VAT],ADL.[Client No_],ADL.[Reservation Activator],ADL.[Reservation State],ADL.[Reservation Date],ADL.[Reservation Time],ADL.[Reservation Source],ADL.[Arrival Date],ADL.[Departure Date],CASE WHEN ADL.[Action]<>3 THEN 0 ELSE ADL.[Action] END [Action],ADL.[Calculated with Contract Code],ADL.[Calculated with Function ID],ADL.[Calculated with Function Desc_],ADL.[Client Company],ADL.[Client Guestname 1],ADL.[Client Guestname 2],ADL.[Description],ADL.[MuseID],ADL.[Handbooking],ADL.[ProcessNumber],ADL.[Booking Quality],ADL.[Booking Code],ADL.[Invoice No_ Old System],ADL.[Invoice Line No_ Old System],ADL.[Loyality Rewards Account No_],ADL.[Foreign Tax Roomnight Base Amt],ADL.[Foreign Tax Breakf Base Amount],ADL.[Commission Roomnight Base Amnt],ADL.[Commission Breakf Base Amount],ADL.[Foreign Tax Roomnight Amount],ADL.[Foreign Tax Breakf Amount],ADL.[Commission Roomnight Amount],ADL.[Commission Breakf Amount],ADL.[Foreign Tax % Roomnight],ADL.[Foreign Tax % Breakf],ADL.[Confirmed Reservation No_],ADL.[Quality by User],ADL.[Quality at],ADL.[Ranking Booster],ADL.[Corporate Rate Discount],ADL.[Net Room Price],ADL.[Net Breakfast Price],ADL.[Booking Comment],ADL.[Agency Business Rules Code],ADL.[Deduction Type],ADL.[Deductible Amount],ADL.[Booking Rating],ADL.[Multisourced],ADL.[Segment],ADL.[Reason For Change],ADL.[Breakfast Approval Status], ADL.[Rate Plan Code],ADL.[Agency Line Amount],ADL.[Agency Line Amount (LCY)],ADL.[TAF Line Amount],ADL.[TAF Line Amount (LCY)],ADL.[TAF Type],ADL.[TAF Rate],ADL.[TAF Fix],ADL.[TAF Contract Code],ADL.[TAF Function ID],ADL.[TAF Function Desc_],ADL.[TAF Business Rules Code]
     FROM [HRS$Partner Import Line] PIL
     JOIN [HRS$Agency Display Line] ADL WITH (NOLOCK)
       ON ADL.[Display Case No_] = PIL.[Display Case No_]
      AND ADL.[Reservation No_] = PIL.[Reservation No_]
LEFT JOIN [HRS$Agency Display Line] DL2 WITH (NOLOCK)
       ON DL2.[Reservation No_] = ADL.[Reservation No_]
      AND DL2.[Position No_] = ADL.[Position No_]
      AND DL2.[Display Case No_] = @NewCaseNo
    WHERE PIL.[Import Entry No_] = @ImportEntryNo
      AND PIL.[Correction Case No_] = ''
      AND DL2.[Reservation No_] IS NULL

	  BEGIN -- Missing found in [HRS$Correction Agency Header]
DECLARE @MISSING TABLE ([Reservation No_] varchar(20) PRIMARY KEY)
;WITH PIL AS
(
  SELECT PIL.[Reservation No_]
       , PIL.[Correction Case No_] [Display Case No_]
	   , MAX(CASE WHEN PIL.[Comm_ Amount Paym_ Curr_] = 0 THEN 0 ELSE PIL.[Import Line No_] END) [Import Line No_]
	   , MIN(PIL.[Import Line No_]) [Min_ Import Line No_]
       , SUM(PIL.[Comm_ Amount Paym_ Curr_] 
	   / CASE WHEN PIH.[Payment Exchange Rate]=0 THEN 1 ELSE PIH.[Payment Exchange Rate] END) [Line Amount (LCY)]
       , SUM(PIL.[Comm_ Amount Paym_ Curr_] 
	   / CASE WHEN PIH.[Payment Exchange Rate]=0 THEN 1 ELSE PIH.[Payment Exchange Rate] END) [Line Amount]
	   , SUM(PIL.[Invoice Amount (LCY) corr_]) [Invoice Amount (LCY) corr_]
    FROM [HRS$Partner Import Line] PIL WITH (NOLOCK)
	JOIN [HRS$Partner Import Header] PIH WITH (NOLOCK)
	  ON PIL.[Import Entry No_] = PIH.[Entry No_]
   WHERE PIL.[Import Entry No_] = @ImportEntryNo
     AND ISNUMERIC(PIL.[Reservation No_])>0
GROUP BY PIL.[Reservation No_]
       , PIL.[Correction Case No_]
), DL AS
(
  SELECT DL.[Display Case No_]
       , DL.[Reservation No_]
       , SUM(CASE WHEN DL.[Action]<>3 THEN DL.[Line Amount (LCY)] ELSE 0 END) [Line Amount (LCY)]
       , MIN(DL.[Position No_]) [Position No_]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
	JOIN PIL
	  ON PIL.[Display Case No_] = DL.[Display Case No_]
     AND PIL.[Reservation No_] = DL.[Reservation No_]
GROUP BY DL.[Display Case No_]
       , DL.[Reservation No_]
)
   INSERT INTO @MISSING
   SELECT PIL.[Reservation No_]
     FROM PIL
LEFT JOIN DL
       ON DL.[Reservation No_] = PIL.[Reservation No_]
     JOIN [HRS$Correction Agency Header] CH WITH (NOLOCK)
	   ON CH.[Reservation No_] = PIL.[Reservation No_]
    WHERE ABS(PIL.[Line Amount (LCY)]-COALESCE(DL.[Line Amount (LCY)],0))>0.01

   INSERT INTO [HRS$Agency Display Line]([Display Case No_],[Reservation No_],[Position No_],[Reservation Status],[Reservation Date from],[Reservation Date to],[Number of Rooms],[Room Type],[Rate Description],[Room Price],[Breakfast Type],[Breakfast Price],[Commission Type],[Commission Rate],[Commission Fix],[Rate Type],[Rate Key],[Currency Code],[Currency Faktor],[Room Number],[Activity Code],[Number of Person],[Hotel No_],[Commission Tax Type],[timestamp Source],[Price Type],[Process Number],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Number of Nights],[Commission Base Amount],[Commission Amount],[Commission Base Amount (LCY)],[Commission Amount (LCY)],[Foreign Tax %],[Foreign Tax Amount],[Line Amount],[Line Amount (LCY)],[Foreign Tax Base Amount],[Hotel sales incl_ VAT],[Client No_],[Reservation Activator],[Reservation State],[Reservation Date],[Reservation Time],[Reservation Source],[Arrival Date],[Departure Date],[Action],[Calculated with Contract Code],[Calculated with Function ID],[Calculated with Function Desc_],[Client Company],[Client Guestname 1],[Client Guestname 2],[Description],[MuseID],[Handbooking],[ProcessNumber],[Booking Quality],[Booking Code],[Invoice No_ Old System],[Invoice Line No_ Old System],[Loyality Rewards Account No_],[Foreign Tax Roomnight Base Amt],[Foreign Tax Breakf Base Amount],[Commission Roomnight Base Amnt],[Commission Breakf Base Amount],[Foreign Tax Roomnight Amount],[Foreign Tax Breakf Amount],[Commission Roomnight Amount],[Commission Breakf Amount],[Foreign Tax % Roomnight],[Foreign Tax % Breakf],[Confirmed Reservation No_],[Quality by User],[Quality at],[Ranking Booster],[Corporate Rate Discount],[Net Room Price],[Net Breakfast Price],[Booking Comment],[Agency Business Rules Code],[Deduction Type],[Deductible Amount],[Booking Rating],[Multisourced],[Segment],[Reason For Change],[Breakfast Approval Status], [Rate Plan Code],[Agency Line Amount],[Agency Line Amount (LCY)],[TAF Line Amount],[TAF Line Amount (LCY)],[TAF Type],[TAF Rate],[TAF Fix],[TAF Contract Code],[TAF Function ID],[TAF Function Desc_],[TAF Business Rules Code])
   SELECT DISTINCT @NewCaseNo [Display Case No_],CH.[Reservation No_],1 [Position],0 [Status],CH.[Arrival Date],CH.[Departure Date],1 [Number of Rooms],0 [Room Type],'' [Rate Description],0 [Room Price],0 [Breakfast Type],0 [Breakfast Price],0 [Commission Type],0 [Commission Rate],0 [Commission Fix],0 [Rate Type],0 [Rate Key],'' [Currency Code],0 [Currency Faktor],0 [Room Number],1 [Activity Code],1 [Number of Person],CH.[Hotel No_],0 [Commission Tax Type],CH.[timestamp Source],0 [Price Type],CH.[ProcessNumber],CH.[Inserted by User],CH.[Inserted at],CH.[Modified by User],CH.[Modified at],0 [Number of Nights],0 [Commission Base Amount],0 [Commission Amount],0 [Commission Base Amount (LCY)],0 [Commission Amount (LCY)],0 [Foreign Tax %],0 [Foreign Tax Amount],0 [Line Amount],0 [Line Amount (LCY)],0 [Foreign Tax Base Amount],0 [Hotel sales incl_ VAT],0 [Client No_],0 [Reservation Activator],0 [Reservation State],CH.[Reservation Date],CH.[Reservation Time],CH.[Reservation Source],CH.[Arrival Date],CH.[Departure Date],1 [Action],'' [Calculated with Contract Code], 0 [Calculated with Function ID],'' [Calculated with Function Desc_],''[Client Company],'' [Client Guestname 1],'' [Client Guestname 2],'' [Description],'' [MuseID],0 [Handbooking],CH.[ProcessNumber],0 [Booking Quality],'' [Booking Code], '' [Invoice No_ Old System],0 [Invoice Line No_ Old System],'' [Loyality Rewards Account No_],0 [Foreign Tax Roomnight Base Amt],0 [Foreign Tax Breakf Base Amount],0 [Commission Roomnight Base Amnt],0 [Commission Breakf Base Amount],0 [Foreign Tax Roomnight Amount],0 [Foreign Tax Breakf Amount],0 [Commission Roomnight Amount],0 [Commission Breakf Amount],0 [Foreign Tax % Roomnight],0 [Foreign Tax % Breakf],0 [Confirmed Reservation No_],CH.[Quality by User],CH.[Quality at],CH.[Ranking Booster],0 [Corporate Rate Discount],0 [Net Room Price],0 [Net Breakfast Price],CH.[Booking Comment],'' [Agency Business Rules Code],0 [Deduction Type],0 [Deductible Amount],0 [Booking Rating],0 [Multisourced],0 [Segment],0 [Reason For Change],0 [Breakfast Approval Status], '' [Rate Plan Code],0 [Agency Line Amount],0 [Agency Line Amount (LCY)],0 [TAF Line Amount],0 [TAF Line Amount (LCY)],0 [TAF Type],0 [TAF Rate],0 [TAF Fix],'' [TAF Contract Code],'' [TAF Function ID],'' [TAF Function Desc_],'' [TAF Business Rules Code]
     FROM @MISSING M
	 JOIN [HRS$Correction Agency Header] CH WITH (NOLOCK)
	   ON CH.[Reservation No_] = M.[Reservation No_]
LEFT JOIN [HRS$Agency Display Line] DL2 WITH (NOLOCK)
       ON DL2.[Reservation No_] = M.[Reservation No_]
      AND DL2.[Position No_] = 1
      AND DL2.[Display Case No_] = @NewCaseNo
    WHERE DL2.[Reservation No_] IS NULL
	  END -- Missing found in [HRS$Correction Agency Header]

   UPDATE PIL SET PIL.[Correction Case No_] = CASE WHEN ADL.[Display Case No_] IS NULL THEN '' ELSE @NewCaseNo END
     FROM [HRS$Partner Import Line] PIL
LEFT JOIN [HRS$Agency Display Line] ADL
       ON ADL.[Display Case No_] = @NewCaseNo
      AND ADL.[Reservation No_] = PIL.[Reservation No_]
    WHERE PIL.[Import Entry No_] = @ImportEntryNo
      AND PIL.[Correction Case No_] <> CASE WHEN ADL.[Display Case No_] IS NULL THEN '' ELSE @NewCaseNo END
      
   UPDATE ADL SET ADL.[Action] = 3
     FROM [HRS$Agency Display Line] ADL 
LEFT JOIN [HRS$Partner Import Line] PIL WITH (NOLOCK)
       ON PIL.[Reservation No_] = ADL.[Reservation No_]
      AND PIL.[Import Entry No_] = @ImportEntryNo
    WHERE PIL.[Reservation No_] IS NULL
      AND ADL.[Action] <> 3
      AND ADL.[Display Case No_] = @NewCaseNo

  UPDATE DL SET DL.[Action]=3
    FROM DynNavHRS.dbo.[HRS$Agency Display Line] DL WITH (NOLOCK)
   WHERE DL.[Action]<>3
     AND DL.[Display Case No_] = @NewCaseNo
	 AND DL.[Position No_]<>1

--   UPDATE PIL SET PIL.[Display Case No_] = CASE WHEN ADL.[Display Case No_] IS NULL THEN '' ELSE @OldCaseNo END
--     FROM [HRS$Partner Import Line] PIL
--LEFT JOIN [HRS$Agency Display Line] ADL
--       ON ADL.[Display Case No_] = @OldCaseNo
--      AND ADL.[Reservation No_] = PIL.[Reservation No_]
--    WHERE PIL.[Import Entry No_] = @ImportEntryNo
--      AND PIL.[Display Case No_] <> CASE WHEN ADL.[Display Case No_] IS NULL THEN '' ELSE @OldCaseNo END

;WITH PIL AS
(
  SELECT PIL.[Reservation No_]
       , PIL.[Correction Case No_] [Display Case No_]
	   , MAX(CASE WHEN PIL.[Comm_ Amount Paym_ Curr_] = 0 THEN 0 ELSE PIL.[Import Line No_] END) [Import Line No_]
	   , MIN(PIL.[Import Line No_]) [Min_ Import Line No_]
       , SUM(PIL.[Comm_ Amount Paym_ Curr_] 
	   / CASE WHEN PIH.[Payment Exchange Rate]=0 THEN 1 ELSE PIH.[Payment Exchange Rate] END) [Line Amount (LCY)]
       , SUM(PIL.[Comm_ Amount Paym_ Curr_] 
	   / CASE WHEN PIH.[Payment Exchange Rate]=0 THEN 1 ELSE PIH.[Payment Exchange Rate] END) [Line Amount]
	   , SUM(PIL.[Invoice Amount (LCY) corr_]) [Invoice Amount (LCY) corr_]
    FROM [HRS$Partner Import Line] PIL WITH (NOLOCK)
	JOIN [HRS$Partner Import Header] PIH WITH (NOLOCK)
	  ON PIL.[Import Entry No_] = PIH.[Entry No_]
   WHERE PIL.[Import Entry No_] = @ImportEntryNo
     AND ISNUMERIC(PIL.[Reservation No_])>0
GROUP BY PIL.[Reservation No_]
       , PIL.[Correction Case No_]
), DL AS
(
  SELECT DL.[Display Case No_]
       , DL.[Reservation No_]
       , SUM(CASE WHEN DL.[Action]<>3 THEN DL.[Line Amount (LCY)] ELSE 0 END) [Line Amount (LCY)]
       , MIN(DL.[Position No_]) [Position No_]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
	JOIN PIL
	  ON PIL.[Display Case No_] = DL.[Display Case No_]
     AND PIL.[Reservation No_] = DL.[Reservation No_]
GROUP BY DL.[Display Case No_]
       , DL.[Reservation No_]
)
   UPDATE ADL SET
          ADL.[Action] = CASE WHEN PIL.[Line Amount (LCY)]=0 THEN 3 ELSE CASE WHEN ADL.[Position No_]=1 THEN 2 ELSE 3 END END
        , ADL.[Line Amount (LCY)] = CASE WHEN ADL.[Position No_]=1 THEN PIL.[Line Amount (LCY)] ELSE 0 END
		, ADL.[Line Amount] = CASE WHEN ADL.[Position No_]=1 THEN PIL.[Line Amount] ELSE 0 END
		, ADL.[Commission Amount] = CASE WHEN ADL.[Position No_]=1 THEN PIL.[Line Amount]/CASE WHEN ADL.[Number of Nights]=0 THEN 1 ELSE ADL.[Number of Nights] END ELSE 0 END
		, ADL.[Commission Rate] 
		= CASE 
			      WHEN PIL.[Line Amount (LCY)] = 0 
				    THEN ADL.[Commission Rate] 
				    ELSE ADL.[Commission Rate] * COALESCE(DL.[Line Amount (LCY)],0) / PIL.[Line Amount (LCY)] 
          END
     FROM [HRS$Agency Display Line] ADL
     JOIN PIL
	   ON PIL.[Display Case No_] = ADL.[Display Case No_]
      AND PIL.[Reservation No_] = ADL.[Reservation No_]
LEFT JOIN DL
       ON DL.[Reservation No_] = PIL.[Reservation No_]
    WHERE ADL.[Line Amount (LCY)]<>CASE WHEN ADL.[Position No_]=1 THEN PIL.[Line Amount (LCY)] ELSE 0 END
	   OR ADL.[Action] <> CASE WHEN PIL.[Line Amount (LCY)]=0 THEN 3 ELSE CASE WHEN ADL.[Position No_]=2 THEN 1 ELSE 3 END END
	   OR ADL.[Line Amount] <> CASE WHEN ADL.[Position No_]=1 THEN PIL.[Line Amount] ELSE 0 END
	   OR ADL.[Commission Amount] <> CASE WHEN ADL.[Position No_]=1 THEN PIL.[Line Amount]/CASE WHEN ADL.[Number of Nights]=0 THEN 1 ELSE ADL.[Number of Nights] END ELSE 0 END
       OR ADL.[Commission Rate] 
       <> CASE 
			      WHEN PIL.[Line Amount (LCY)] = 0 
				    THEN ADL.[Commission Rate] 
				    ELSE ADL.[Commission Rate] * COALESCE(DL.[Line Amount (LCY)],0) / PIL.[Line Amount (LCY)] 
          END

;WITH PIL AS
(
  SELECT PIL.[Reservation No_]
       , PIL.[Correction Case No_] [Display Case No_]
	   , MAX(CASE WHEN PIL.[Comm_ Amount Paym_ Curr_] = 0 THEN 0 ELSE PIL.[Import Line No_] END) [Import Line No_]
	   , MIN(PIL.[Import Line No_]) [Min_ Import Line No_]
       , SUM(PIL.[Comm_ Amount Paym_ Curr_] 
	   / CASE WHEN PIH.[Payment Exchange Rate]=0 THEN 1 ELSE PIH.[Payment Exchange Rate] END) [Line Amount (LCY)]
       , SUM(PIL.[Comm_ Amount Paym_ Curr_] 
	   / CASE WHEN PIH.[Payment Exchange Rate]=0 THEN 1 ELSE PIH.[Payment Exchange Rate] END) [Line Amount]
	   , SUM(PIL.[Invoice Amount (LCY) corr_]) [Invoice Amount (LCY) corr_]
    FROM [HRS$Partner Import Line] PIL WITH (NOLOCK)
	JOIN [HRS$Partner Import Header] PIH WITH (NOLOCK)
	  ON PIL.[Import Entry No_] = PIH.[Entry No_]
   WHERE PIL.[Import Entry No_] = @ImportEntryNo
     AND ISNUMERIC(PIL.[Reservation No_])>0
GROUP BY PIL.[Reservation No_]
       , PIL.[Correction Case No_]
), DL AS
(
  SELECT DL.[Display Case No_]
       , DL.[Reservation No_]
       , SUM(CASE WHEN DL.[Action]<>3 THEN DL.[Line Amount (LCY)]ELSE 0 END) [Line Amount (LCY)]
       , MIN(DL.[Position No_]) [Position No_]
    FROM [HRS$Agency Display Line] DL WITH (NOLOCK)
	JOIN PIL
	  ON PIL.[Display Case No_] = DL.[Display Case No_]
     AND PIL.[Reservation No_] = DL.[Reservation No_]
GROUP BY DL.[Display Case No_]
       , DL.[Reservation No_]
)
   UPDATE IL SET
          IL.[Invoice Amount (LCY) corr_] = CASE WHEN PIL.[Import Line No_] IS NULL THEN 0 ELSE DL.[Line Amount (LCY)] END
     FROM [HRS$Partner Import Line] IL
LEFT JOIN PIL
	   ON IL.[Import Line No_] = CASE WHEN PIL.[Import Line No_]=0 THEN PIL.[Min_ Import Line No_] ELSE PIL.[Import Line No_] END
LEFT JOIN DL
       ON DL.[Reservation No_] = IL.[Reservation No_]
    WHERE IL.[Invoice Amount (LCY) corr_] <> CASE WHEN PIL.[Import Line No_] IS NULL THEN 0 ELSE DL.[Line Amount (LCY)] END 
	  AND IL.[Import Entry No_] = @ImportEntryNo
END -- IF @OldCaseNo<>''

END -- sp_CreateCorrectionInvoice

GO
