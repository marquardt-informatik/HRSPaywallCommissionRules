USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Recalculate_HRS_Correct_Dimensions]    Script Date: 10.04.2024 14:31:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 19.11.2012
-- Description:	Ersetzt Reservierungsdatum mit dem der ersten Buchung in der Kette B
/*
  EXECUTE [dbo].[sp_Recalculate_HRS_Correct_Dimensions] 
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_Recalculate_HRS_Correct_Dimensions] 
WITH RECOMPILE
AS
BEGIN

DELETE FROM AD FROM [HRS$Contact] CO WITH (NOLOCK) JOIN [HRS$Agency Dimension] AD WITH (NOLOCK) ON AD.[Contact Code] = CO.[No_]AND AD.[Dimension Code] = 'BRAND' WHERE AD.[Dimension Value Code] <> CO.[Brand]
DELETE FROM AD FROM [HRS$Contact] CO WITH (NOLOCK) JOIN [HRS$Agency Dimension] AD WITH (NOLOCK) ON AD.[Contact Code] = CO.[No_]AND AD.[Dimension Code] = 'CHAIN' WHERE AD.[Dimension Value Code] <> CO.[Chain]
DELETE FROM AD FROM [HRS$Contact] CO WITH (NOLOCK) JOIN [HRS$Agency Dimension] AD WITH (NOLOCK) ON AD.[Contact Code] = CO.[No_]AND AD.[Dimension Code] = 'CONTRACT STATUS' WHERE AD.[Dimension Value Code] <> CO.[Contract Status]

INSERT INTO [HRS$Agency Dimension] ([Contact Code],[Dimension Code],[Dimension Value Code],[Value Posting],[Parameter_Dimension])  
SELECT CO.[No_],'BRAND',CO.[Brand],1,1 FROM [HRS$Contact] CO WITH (NOLOCK) LEFT JOIN [HRS$Agency Dimension] D1 WITH (NOLOCK)ON D1.[Contact Code] = CO.[No_]AND D1.[Dimension Code] = 'BRAND' WHERE D1.[Contact Code] IS NULL

INSERT INTO [HRS$Agency Dimension] ([Contact Code],[Dimension Code],[Dimension Value Code],[Value Posting],[Parameter_Dimension])  
SELECT CO.[No_],'CHAIN',CO.[Chain],1,1 FROM [HRS$Contact] CO WITH (NOLOCK) LEFT JOIN [HRS$Agency Dimension] D1 WITH (NOLOCK) ON D1.[Contact Code] = CO.[No_] AND D1.[Dimension Code] = 'CHAIN' WHERE D1.[Contact Code] IS NULL

INSERT INTO [HRS$Agency Dimension] ([Contact Code],[Dimension Code],[Dimension Value Code],[Value Posting],[Parameter_Dimension])  
SELECT CO.[No_],'CONTRACT STATUS',CO.[Contract Status],1,1 FROM [HRS$Contact] CO WITH (NOLOCK) LEFT JOIN [HRS$Agency Dimension] D1 WITH (NOLOCK) ON D1.[Contact Code] = CO.[No_] AND D1.[Dimension Code] = 'CONTRACT STATUS' WHERE D1.[Contact Code] IS NULL

DELETE FROM DD FROM [HRS$Customer] CU WITH (NOLOCK) JOIN [HRS$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'BRAND' AND DD.[Table ID] = 18 WHERE DD.[Dimension Value Code] <> CU.[Brand]
DELETE FROM DD FROM [HRS$Customer] CU WITH (NOLOCK) JOIN [HRS$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CHAIN' AND DD.[Table ID] = 18 WHERE DD.[Dimension Value Code] <> CU.[Chain]
DELETE FROM DD FROM [HRS$Customer] CU WITH (NOLOCK) JOIN [HRS$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[Table ID] = 18 WHERE DD.[Dimension Value Code] <> CU.[Contract Status]

INSERT INTO [HRS$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 18,CU.[No_],'BRAND',CU.[Brand],1,0 FROM [HRS$Customer] CU WITH (NOLOCK) LEFT JOIN [HRS$Default Dimension] DD ON DD.[Dimension Code] = 'BRAND' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 18 WHERE DD.[Table ID] IS NULL

INSERT INTO [HRS$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 18,CU.[No_],'CHAIN',CU.[Chain],1,0 FROM [HRS$Customer] CU WITH (NOLOCK) LEFT JOIN [HRS$Default Dimension] DD ON DD.[Dimension Code] = 'CHAIN' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 18 WHERE DD.[Table ID] IS NULL

INSERT INTO [HRS$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 18,CU.[No_],'CONTRACT STATUS',CU.[Contract Status],1,0 FROM [HRS$Customer] CU WITH (NOLOCK) LEFT JOIN [HRS$Default Dimension] DD ON DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 18 WHERE DD.[Table ID] IS NULL

DELETE FROM DD FROM [HRS$Job] CU WITH (NOLOCK) JOIN [HRS$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'BRAND' AND DD.[Table ID] = 167 WHERE DD.[Dimension Value Code] <> CU.[Brand]
DELETE FROM DD FROM [HRS$Job] CU WITH (NOLOCK) JOIN [HRS$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CHAIN' AND DD.[Table ID] = 167 WHERE DD.[Dimension Value Code] <> CU.[Chain]
DELETE FROM DD FROM [HRS$Job] CU WITH (NOLOCK) JOIN [HRS$Default Dimension] DD WITH (NOLOCK) ON DD.[No_] = CU.[No_]AND DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[Table ID] = 167 WHERE DD.[Dimension Value Code] <> CU.[Contract Status]

INSERT INTO [HRS$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 167,CU.[No_],'BRAND',CU.[Brand],1,0 FROM [HRS$Job] CU WITH (NOLOCK) LEFT JOIN [HRS$Default Dimension] DD ON DD.[Dimension Code] = 'BRAND' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 167 WHERE DD.[Table ID] IS NULL

INSERT INTO [HRS$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 167,CU.[No_],'CHAIN',CU.[Chain],1,0 FROM [HRS$Job] CU WITH (NOLOCK) LEFT JOIN [HRS$Default Dimension] DD ON DD.[Dimension Code] = 'CHAIN' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 167 WHERE DD.[Table ID] IS NULL

INSERT INTO [HRS$Default Dimension]([Table ID],[No_],[Dimension Code],[Dimension Value Code],[Value Posting],[Multi Selection Action])
SELECT 167,CU.[No_],'CONTRACT STATUS',CU.[Contract Status],1,0 FROM [HRS$Job] CU WITH (NOLOCK) LEFT JOIN [HRS$Default Dimension] DD ON DD.[Dimension Code] = 'CONTRACT STATUS' AND DD.[No_] = CU.[No_] AND DD.[Table ID] = 167 WHERE DD.[Table ID] IS NULL

END


GO
