USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [HRSDB].[sp_InsertUpdateBUCHUNG]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC HRSDB.sp_InsertUpdateBUCHUNG ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
*/
CREATE PROC [HRSDB].[sp_InsertUpdateBUCHUNG]
(
    @CTS datetime2(7)
  , @K_KEY bigint
  , @H_KEY int
  , @MA_USER varchar(8)
  , @B_STATUS bigint
  , @B_DATUM date
  , @B_ZEIT datetime
  , @B_QUELLE bigint
  , @B_AN_DATUM date
  , @B_AB_DATUM date
  , @B_FIRMA varchar(80)
  , @B_GAST1 varchar(120)
  , @B_GAST2 varchar(120)
  , @B_KOMM_STATUS bigint
  , @B_K_REF_TEXT varchar(15)
  , @MUSE_ID varchar(20)
  , @W_ISO varchar(3)
  , @W_KURS bigint
  , @KE_ID bigint
  , @KE_BID bigint
  , @B_HANDBOOKING bigint
  , @B_IFC_VERSION bigint
  , @B_TOTAL_RATE bigint
  , @B_TOTAL_RATE_INCLUSIVE bigint
  , @B_PERCENT_DISCOUNT bigint
  , @B_PASSWORD varchar(80)
  , @BP_KEY bigint
  , @L_ID bigint
  , @BCDT_VALUE varchar(2000)
  , @B_BESTELLER varchar(120)
  , @B_KEY_ALT bigint
  , @QUALITY_MA_USER varchar(8)
  , @QUALITY_CTS datetime2(7)
  , @B_KEY_COMMIT bigint
  , @B_ZAHL_ART bigint
  , @B_INFORMATION bigint
  , @B_OFFER_ID varchar(36)
  , @MULTISOURCED bigint
  , @DEFAULT_CRS_TYPE varchar(20)
  , @B_EMAIL_NEW varchar(150)
  , @B_SEGMENT int  
  , @B_KEY bigint
  , @EXTERNAL_BOOKING_SEGMENT varchar(100)
)
AS BEGIN
IF EXISTS(SELECT * FROM HRSDB.BUCHUNG WHERE B_KEY=@B_KEY)

UPDATE [HRSDB].[BUCHUNG]
   SET [CTS] = @CTS
      ,[K_KEY] = @K_KEY
      ,[H_KEY] = @H_KEY
      ,[MA_USER] = @MA_USER
      ,[B_STATUS] = @B_STATUS
      ,[B_DATUM] = @B_DATUM
      ,[B_ZEIT] = @B_ZEIT
      ,[B_QUELLE] = @B_QUELLE
      ,[B_AN_DATUM] = @B_AN_DATUM
      ,[B_AB_DATUM] = @B_AB_DATUM
      ,[B_FIRMA] = @B_FIRMA
      ,[B_GAST1] = @B_GAST1
      ,[B_GAST2] = @B_GAST2
      ,[B_KOMM_STATUS] = @B_KOMM_STATUS
      ,[B_K_REF_TEXT] = @B_K_REF_TEXT
      ,[MUSE_ID] = @MUSE_ID
      ,[W_ISO] = @W_ISO
      ,[W_KURS] = @W_KURS
      ,[KE_ID] = @KE_ID
      ,[KE_BID] = @KE_BID
      ,[B_HANDBOOKING] = @B_HANDBOOKING
      ,[B_IFC_VERSION] = @B_IFC_VERSION
      ,[B_TOTAL_RATE] = @B_TOTAL_RATE
      ,[B_TOTAL_RATE_INCLUSIVE] = @B_TOTAL_RATE_INCLUSIVE
      ,[B_PERCENT_DISCOUNT] = @B_PERCENT_DISCOUNT
      ,[B_PASSWORD] = @B_PASSWORD
      ,[BP_KEY] = @BP_KEY
      ,[L_ID] = @L_ID
      ,[BCDT_VALUE] = @BCDT_VALUE
      ,[NAV_LOADED] = [NAV_LOADED]
      ,[B_BESTELLER] = @B_BESTELLER
      ,[B_KEY_ALT] = @B_KEY_ALT
      ,[QUALITY_MA_USER] = @QUALITY_MA_USER
      ,[QUALITY_CTS] = @QUALITY_CTS
      ,[B_KEY_COMMIT] = @B_KEY_COMMIT
      ,[B_CANCELLATION] = [B_CANCELLATION]
      ,[B_ZAHL_ART] = @B_ZAHL_ART
      ,[B_KEY_ROOT] = [B_KEY_ROOT]
      ,[B_KEY_LAST_NBVL] = [B_KEY_LAST_NBVL]
      ,[B_KEY_LAST_BVL] = [B_KEY_LAST_BVL]
      ,[B_INFORMATION] = @B_INFORMATION
      ,[B_OFFER_ID] = @B_OFFER_ID
      ,[MULTISOURCED] = @MULTISOURCED
      ,[DEFAULT_CRS_TYPE] = @DEFAULT_CRS_TYPE
      ,[B_EMAIL_NEW] = @B_EMAIL_NEW
      ,[B_SEGMENT] = @B_SEGMENT
	  ,[EXTERNAL_BOOKING_SEGMENT] = @EXTERNAL_BOOKING_SEGMENT
 WHERE [B_KEY] = @B_KEY
ELSE
INSERT INTO [HRSDB].[BUCHUNG]
           ([B_KEY]
           ,[CTS]
           ,[K_KEY]
           ,[H_KEY]
           ,[MA_USER]
           ,[B_STATUS]
           ,[B_DATUM]
           ,[B_ZEIT]
           ,[B_QUELLE]
           ,[B_AN_DATUM]
           ,[B_AB_DATUM]
           ,[B_FIRMA]
           ,[B_GAST1]
           ,[B_GAST2]
           ,[B_KOMM_STATUS]
           ,[B_K_REF_TEXT]
           ,[MUSE_ID]
           ,[W_ISO]
           ,[W_KURS]
           ,[KE_ID]
           ,[KE_BID]
           ,[B_HANDBOOKING]
           ,[B_IFC_VERSION]
           ,[B_TOTAL_RATE]
           ,[B_TOTAL_RATE_INCLUSIVE]
           ,[B_PERCENT_DISCOUNT]
           ,[B_PASSWORD]
           ,[BP_KEY]
           ,[L_ID]
           ,[BCDT_VALUE]
           ,[NAV_LOADED]
           ,[B_BESTELLER]
           ,[B_KEY_ALT]
           ,[QUALITY_MA_USER]
           ,[QUALITY_CTS]
           ,[B_KEY_COMMIT]
           ,[B_CANCELLATION]
           ,[B_ZAHL_ART]
           ,[B_KEY_ROOT]
           ,[B_KEY_LAST_NBVL]
           ,[B_KEY_LAST_BVL]
           ,[B_INFORMATION]
           ,[B_OFFER_ID]
           ,[MULTISOURCED]
           ,[DEFAULT_CRS_TYPE]
           ,[B_EMAIL_NEW]
           ,[B_SEGMENT]
		   ,[EXTERNAL_BOOKING_SEGMENT] )
     VALUES 
(
    @B_KEY         
  , @CTS
  , @K_KEY
  , @H_KEY
  , @MA_USER
  , @B_STATUS
  , @B_DATUM
  , @B_ZEIT
  , @B_QUELLE 
  , @B_AN_DATUM 
  , @B_AB_DATUM 
  , @B_FIRMA 
  , @B_GAST1 
  , @B_GAST2 
  , @B_KOMM_STATUS 
  , @B_K_REF_TEXT 
  , @MUSE_ID
  , @W_ISO 
  , @W_KURS 
  , @KE_ID 
  , @KE_BID 
  , @B_HANDBOOKING 
  , @B_IFC_VERSION 
  , @B_TOTAL_RATE 
  , @B_TOTAL_RATE_INCLUSIVE 
  , @B_PERCENT_DISCOUNT 
  , @B_PASSWORD 
  , @BP_KEY 
  , @L_ID 
  , @BCDT_VALUE 
  , 0
  , @B_BESTELLER 
  , @B_KEY_ALT 
  , @QUALITY_MA_USER 
  , @QUALITY_CTS 
  , @B_KEY_COMMIT 
  , NULL 
  , @B_ZAHL_ART 
  , NULL
  , NULL 
  , NULL 
  , @B_INFORMATION 
  , @B_OFFER_ID 
  , @MULTISOURCED 
  , @DEFAULT_CRS_TYPE 
  , @B_EMAIL_NEW 
  , @B_SEGMENT
  , @EXTERNAL_BOOKING_SEGMENT
)

END
GO
