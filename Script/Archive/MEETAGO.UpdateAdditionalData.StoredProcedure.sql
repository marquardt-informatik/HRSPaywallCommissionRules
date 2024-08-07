USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [MEETAGO].[UpdateAdditionalData]    Script Date: 10.04.2024 14:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [MEETAGO].[UpdateAdditionalData] AS
BEGIN
;WITH AD AS
(
SELECT [RequestId]
      ,[Id]
      ,CASE 
         WHEN [Name] IN ('BANF','Bestellung / Purchase Order Number','Bestellung Nr','Order Number','PO','PO number','PO Number','PO Nummer','Purchase Order','Purchase order No','Purchase Order Number','Purchasing Order','RDA request of purchase','SAP Nummer','SD-/CO-Auftragsnummer') 
           THEN 100
         WHEN [Name] IN ('ARE Nummer')
           THEN 101
         WHEN [Name] IN ('Project Code','Project Code (Enter 3000 if non- billable)','Project ID','Project Number','Projektnummer','PSP Element','PSP-Element','PSP-Element (Eingabe ohne Punkte)')
           THEN 102
         WHEN [Name] IN ('Cost center','Cost Center','Cost Center (incl. Company no.)','Cost Centre','Kostenstelle','Kostenstelle/Innenauftragsnummer')
           THEN 103
         ELSE [Id]
       END [NewId]
      ,[Name]
      ,CASE 
         WHEN [Name] IN ('BANF','Bestellung / Purchase Order Number','Bestellung Nr','Order Number','PO','PO number','PO Number','PO Nummer','Purchase Order','Purchase order No','Purchase Order Number','Purchasing Order','RDA request of purchase','SAP Nummer','SD-/CO-Auftragsnummer') 
           THEN 'PO Number'
         WHEN [Name] IN ('ARE Nummer')
           THEN 'ARE Nummer'
         WHEN [Name] IN ('Project Code','Project Code (Enter 3000 if non- billable)','Project ID','Project Number','Projektnummer','PSP Element','PSP-Element','PSP-Element (Eingabe ohne Punkte)')
           THEN 'Project Code'
         WHEN [Name] IN ('Cost center','Cost Center','Cost Center (incl. Company no.)','Cost Centre','Kostenstelle','Kostenstelle/Innenauftragsnummer')
           THEN 'Cost center'
         ELSE [Id]
       END [NewName]
      ,[Value]
  FROM [DynNavHRS].[MEETAGO].[AdditionalData]
)
DELETE FROM DD
  FROM [DynNavHRS].[MEETAGO].[AdditionalData] DD
  JOIN AD
    ON DD.RequestId=AD.RequestId
   AND DD.Id=AD.Id
 WHERE AD.Id<>AD.[NewId]

UPDATE MEETAGO.AdditionalData SET [Id]=100 WHERE [Name] IN ('BANF','Bestellung / Purchase Order Number','Bestellung Nr','Order Number','PO','PO number','PO Number','PO Nummer','Purchase Order','Purchase order No','Purchase Order Number','Purchasing Order','RDA request of purchase','SAP Nummer','SD-/CO-Auftragsnummer') AND [Id]<>100 AND [Value]<>''
UPDATE MEETAGO.AdditionalData SET [Id]=101 WHERE [Name] IN ('ARE Nummer') AND [Id]<>101 AND [Value]<>''
UPDATE MEETAGO.AdditionalData SET [Id]=102 WHERE [Name] IN ('Project Code','Project Code (Enter 3000 if non- billable)','Project ID','Project Number','Projektnummer','PSP Element','PSP-Element','PSP-Element (Eingabe ohne Punkte)') AND [Id]<>102 AND [Value]<>''
UPDATE MEETAGO.AdditionalData SET [Id]=103 WHERE [Name] IN ('Cost center','Cost Center','Cost Center (incl. Company no.)','Cost Centre','Kostenstelle','Kostenstelle/Innenauftragsnummer') AND [Id]<>103 AND [Value]<>''

END
GO
