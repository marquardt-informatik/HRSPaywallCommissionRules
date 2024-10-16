USE [DynNavHRS]
GO
/****** Object:  UserDefinedFunction [MIGRATION].[GetCompanies]    Script Date: 10.04.2024 14:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [MIGRATION].[GetCompanies]()
RETURNS TABLE
AS RETURN
(
  SELECT [Company],[BUKRS] FROM 
  (
    VALUES ('RoRa Familien Holding',1000)
         , ('RoRa Familien Holding Verw_',1001)
         , ('HRS Ragge Holding',1002)
         , ('HRS',2000)
         , ('HRS Product Solutions GmbH',3000)
         , ('HRS Prod_ Sol_ Germany GmbH',3001)
         , ('Product Development',3002)
         , ('Venturecube',3003)
         , ('HRS Innovation Hub GmbH',3004)
         , ('Codenet',3005)
         , ('Hotel Solutions Verwaltung',4000)
         , ('Invisible Pay GmbH',5002)
         , ('Trade',6000)
  ) AS q ([Company],[BUKRS])
)
GO
