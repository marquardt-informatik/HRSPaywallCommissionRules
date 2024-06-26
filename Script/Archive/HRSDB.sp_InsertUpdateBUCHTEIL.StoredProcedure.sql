USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [HRSDB].[sp_InsertUpdateBUCHTEIL]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
EXEC HRSDB.sp_InsertUpdateBUCHTEIL ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
*/

CREATE PROC [HRSDB].[sp_InsertUpdateBUCHTEIL]
(
    @B_KEY bigint
  , @CTS datetime2(7)
  , @BT_POS int
  , @BT_VON date
  , @BT_BIS date
  , @BT_ANZAHL smallint
  , @BT_ZTYP smallint
  , @BT_RATE_BEZ varchar(1000)
  , @BT_PREIS bigint
  , @BT_FRSTCK smallint
  , @BT_FRST_PREIS bigint
  , @BT_KOMM_ART smallint
  , @BT_KOMM_SATZ smallint
  , @BT_KOMM_MWST smallint
  , @BT_KOMM_FIX smallint
  , @BT_RATE_TYP smallint
  , @R_KEY int
  , @BT_ROOM_NUMBER smallint
  , @BT_PAX_COUNT smallint
  , @MA_USER varchar(40)
  , @PRC_TYPE_ID smallint
  , @H_KEY int
  , @B_STATUS smallint
  , @B_AB_DATUM date
  , @W_ISO varchar(3)
  , @W_KURS bigint
  , @BP_KEY bigint
  , @L_ID bigint
  , @MUSE_ID varchar(20)
  , @BCDT_VALUE varchar(2000)
  , @BT_MEAL_APPROVAL_STATUS smallint
  , @BT_KOMM_FIX_INT bigint
)
AS BEGIN

IF EXISTS(SELECT * FROM HRSDB.BUCHTEIL WHERE B_KEY=@B_KEY AND BT_POS=@BT_POS)
UPDATE [HRSDB].[BUCHTEIL]
   SET [CTS] = @CTS
      ,[BT_POS] = @BT_POS
      ,[BT_VON] = @BT_VON
      ,[BT_BIS] = @BT_BIS
      ,[BT_ANZAHL] = @BT_ANZAHL
      ,[BT_ZTYP] = @BT_ZTYP
      ,[BT_RATE_BEZ] = @BT_RATE_BEZ
      ,[BT_PREIS] = @BT_PREIS
      ,[BT_FRSTCK] = @BT_FRSTCK
      ,[BT_FRST_PREIS] = @BT_FRST_PREIS
      ,[BT_KOMM_ART] = @BT_KOMM_ART
      ,[BT_KOMM_SATZ] = @BT_KOMM_SATZ
      ,[BT_KOMM_MWST] = @BT_KOMM_MWST
      ,[BT_KOMM_FIX] = @BT_KOMM_FIX
      ,[BT_RATE_TYP] = @BT_RATE_TYP
      ,[R_KEY] = @R_KEY
      ,[BT_ROOM_NUMBER] = @BT_ROOM_NUMBER
      ,[BT_PAX_COUNT] = @BT_PAX_COUNT
      ,[MA_USER] = @MA_USER
      ,[PRC_TYPE_ID] = @PRC_TYPE_ID
      ,[H_KEY] = @H_KEY
      ,[B_STATUS] = @B_STATUS
      ,[B_AB_DATUM] = @B_AB_DATUM
      ,[W_ISO] = @W_ISO
      ,[W_KURS] = @W_KURS
      ,[BP_KEY] = @BP_KEY
      ,[L_ID] = @L_ID
      ,[MUSE_ID] = @MUSE_ID
      ,[BCDT_VALUE] = @BCDT_VALUE
      ,[NAV_LOADED] = [NAV_LOADED]
      ,[BT_NETTO_PREIS] = [BT_NETTO_PREIS]
      ,[BT_NETTO_FRST_PREIS] = [BT_NETTO_FRST_PREIS]
      ,[BT_MEAL_APPROVAL_STATUS] = @BT_MEAL_APPROVAL_STATUS
      ,[BT_KOMM_FIX_INT] = @BT_KOMM_FIX_INT
 WHERE B_KEY=@B_KEY AND BT_POS=@BT_POS
ELSE
INSERT INTO [HRSDB].[BUCHTEIL]
           ([B_KEY]
           ,[CTS]
           ,[BT_POS]
           ,[BT_VON]
           ,[BT_BIS]
           ,[BT_ANZAHL]
           ,[BT_ZTYP]
           ,[BT_RATE_BEZ]
           ,[BT_PREIS]
           ,[BT_FRSTCK]
           ,[BT_FRST_PREIS]
           ,[BT_KOMM_ART]
           ,[BT_KOMM_SATZ]
           ,[BT_KOMM_MWST]
           ,[BT_KOMM_FIX]
           ,[BT_RATE_TYP]
           ,[R_KEY]
           ,[BT_ROOM_NUMBER]
           ,[BT_PAX_COUNT]
           ,[MA_USER]
           ,[PRC_TYPE_ID]
           ,[H_KEY]
           ,[B_STATUS]
           ,[B_AB_DATUM]
           ,[W_ISO]
           ,[W_KURS]
           ,[BP_KEY]
           ,[L_ID]
           ,[MUSE_ID]
           ,[BCDT_VALUE]
           ,[BT_MEAL_APPROVAL_STATUS]
           ,[BT_KOMM_FIX_INT])
     VALUES
(
    @B_KEY
  , @CTS
  , @BT_POS
  , @BT_VON 
  , @BT_BIS 
  , @BT_ANZAHL 
  , @BT_ZTYP 
  , @BT_RATE_BEZ
  , @BT_PREIS 
  , @BT_FRSTCK 
  , @BT_FRST_PREIS 
  , @BT_KOMM_ART 
  , @BT_KOMM_SATZ 
  , @BT_KOMM_MWST 
  , @BT_KOMM_FIX 
  , @BT_RATE_TYP 
  , @R_KEY 
  , @BT_ROOM_NUMBER 
  , @BT_PAX_COUNT 
  , @MA_USER
  , @PRC_TYPE_ID 
  , @H_KEY 
  , @B_STATUS 
  , @B_AB_DATUM 
  , @W_ISO 
  , @W_KURS 
  , @BP_KEY 
  , @L_ID 
  , @MUSE_ID 
  , @BCDT_VALUE 
  , @BT_MEAL_APPROVAL_STATUS 
  , @BT_KOMM_FIX_INT 
)

END
GO
