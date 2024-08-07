USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Affiliate_ChangeLogBankAccount]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Affiliate_ChangeLogBankAccount]
	-- Add the parameters for the stored procedure here
	  @dateFrom Date = NULL
	, @dateTo Date = NULL
	--, @Company varchar(30)
AS
BEGIN
; WITH 
CL AS (
  SELECT 'HRS' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS$Change Log Entry] WITH (NOLOCK)
    UNION ALL
  SELECT 'HRS-BR' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS-BR$Change Log Entry] WITH (NOLOCK)
    UNION ALL
  SELECT 'HRS-CN' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS-CN$Change Log Entry] WITH (NOLOCK)
   UNION ALL
  SELECT 'HRS Payment' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS Payment$Change Log Entry] WITH (NOLOCK)
	UNION ALL
  SELECT 'CodeNet' AS [Company], *
  FROM [DynNavHRS].[dbo].[Codenet$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Hotel Savoy' AS [Company], *
  FROM [DynNavHRS].[dbo].[Hotel Savoy$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Hotel Savoy Immobilien' AS [Company], *
  FROM [DynNavHRS].[dbo].[Hotel Savoy Immobilien$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Hotel Solutions' AS [Company], *
  FROM [DynNavHRS].[dbo].[Hotel Solutions$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Hotel Solutions Verwaltung' AS [Company], *
  FROM [DynNavHRS].[dbo].[Hotel Solutions Verwaltung$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Hotel.de' AS [Company], *
  FROM [DynNavHRS].[dbo].[hotel_de$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'HRS Holidays' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS Holidays$Change Log Entry] with (nolock)
	UNION ALL
  --SELECT 'HRS Payment' AS [Company], *
  --FROM [DynNavHRS].[dbo].[HRS Payment$Change Log Entry] with (nolock)
  	--UNION ALL
  SELECT 'HRS-BR' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS-BR$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'HRS-CN' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS-CN$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'HRS-Global' AS [Company], *
  FROM [DynNavHRS].[dbo].[HRS-Global$Change Log Entry] with (nolock)
	UNION ALL
 -- SELECT 'HRS-UK' AS [Company], *
 -- FROM [HRS-UK$Change Log Entry] with (nolock)
	--UNION ALL
  SELECT 'Partner' AS [Company], *
  FROM [Partner$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Product Development' AS [Company], *
  FROM [DynNavHRS].[dbo].[Product Development$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Ragge Blaubach' AS [Company], *
  FROM [DynNavHRS].[dbo].[Ragge Blaubach$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Ragge Neusser' AS [Company], *
  FROM [DynNavHRS].[dbo].[Ragge Neusser$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Ragge Schubert' AS [Company], *
  FROM [DynNavHRS].[dbo].[Ragge Schubert$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Ragge Turiner' AS [Company], *
  FROM [DynNavHRS].[dbo].[Ragge Turiner$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'RoRa Familien Holding' AS [Company], *
  FROM [DynNavHRS].[dbo].[RoRa Familien Holding$Change Log Entry] with (nolock)
  UNION ALL
  SELECT 'RoRa Familien Holding Verw_' AS [Company], *
  FROM [DynNavHRS].[dbo].[RoRa Familien Holding Verw_$Change Log Entry] with (nolock)
   UNION ALL
  SELECT 'TISCOVER' AS [Company], *
  FROM [DynNavHRS].[dbo].[TISCOVER$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'Trade' AS [Company], *
  FROM [DynNavHRS].[dbo].[Trade$Change Log Entry] with (nolock)
	UNION ALL
  SELECT 'TREX' AS [Company], *
  FROM [DynNavHRS].[dbo].[TREX$Change Log Entry] with (nolock)
  UNION ALL
  SELECT 'Venturecube' AS [Company], *
  FROM [DynNavHRS].[dbo].[Venturecube$Change Log Entry] with (nolock)

),
VBA AS (
  SELECT 'HRS' AS [Company],
  [Vendor No_],
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS$Vendor Bank Account] WITH (NOLOCK)
    UNION ALL
  SELECT 'HRS-BR' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-BR$Vendor Bank Account] WITH (NOLOCK)
    UNION ALL
  SELECT 'HRS-CN' AS [Company], 
  [Vendor No_],
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-CN$Vendor Bank Account] WITH (NOLOCK)
   UNION ALL
  SELECT 'HRS Payment' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS Payment$Vendor Bank Account] WITH (NOLOCK)
	UNION ALL
  SELECT 'CodeNet' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[Codenet$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Hotel Savoy' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Savoy$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Hotel Savoy Immobilien' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Savoy Immobilien$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Hotel Solutions' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Solutions$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Hotel Solutions Verwaltung' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Solutions Verwaltung$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Hotel.de' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[hotel_de$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'HRS Holidays' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS Holidays$Vendor Bank Account] with (nolock)
	UNION ALL
  --SELECT 'HRS Payment' AS [Company],
  --[Vendor No_], 
  --[Code],
  --[Name]
  --FROM [DynNavHRS].[dbo].[HRS Payment$Vendor Bank Account] with (nolock)
  --	UNION ALL
  SELECT 'HRS-BR' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-BR$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'HRS-CN' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-CN$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'HRS-Global' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-Global$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Partner' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [Partner$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Product Development' AS [Company],
  [Vendor No_],
  [Code], 
  [Name]
  FROM [DynNavHRS].[dbo].[Product Development$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Ragge Blaubach' AS [Company],
  [Vendor No_], 
  [Code],
  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Blaubach$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Ragge Neusser' AS [Company],
	  [Vendor No_], 
	  [Code],
	  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Neusser$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Ragge Schubert' AS [Company],
	  [Vendor No_], 
	  [Code],
	  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Schubert$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Ragge Turiner' AS [Company],
	  [Vendor No_], 
	  [Code],
	  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Turiner$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'RoRa Familien Holding' AS [Company],
	 [Vendor No_], 
	 [Code],
	 [Name]
  FROM [DynNavHRS].[dbo].[RoRa Familien Holding$Vendor Bank Account] with (nolock)
  UNION ALL
  SELECT 'RoRa Familien Holding Verw_' AS [Company],
	[Vendor No_], 
	[Code],
	[Name]
  FROM [DynNavHRS].[dbo].[RoRa Familien Holding Verw_$Vendor Bank Account] with (nolock)
   UNION ALL
  SELECT 'TISCOVER' AS [Company],
	[Vendor No_], 
	[Code],
	[Name]
  FROM [DynNavHRS].[dbo].[TISCOVER$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'Trade' AS [Company],
	[Vendor No_], 
	[Code],
	[Name]
  FROM [DynNavHRS].[dbo].[Trade$Vendor Bank Account] with (nolock)
	UNION ALL
  SELECT 'TREX' AS [Company],
	[Vendor No_], 
	[Code],
	[Name]
  FROM [DynNavHRS].[dbo].[TREX$Vendor Bank Account] with (nolock)
  UNION ALL
  SELECT 'Venturecube' AS [Company],
	[Vendor No_], 
	[Code],
	[Name]
  FROM [DynNavHRS].[dbo].[Venturecube$Vendor Bank Account] with (nolock)
),
V AS (
  SELECT 'HRS' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS$Vendor] WITH (NOLOCK)
    UNION ALL
  SELECT 'HRS-BR' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-BR$Vendor] WITH (NOLOCK)
    UNION ALL
  SELECT 'HRS-CN' AS [Company], 
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-CN$Vendor] WITH (NOLOCK)
   UNION ALL
  SELECT 'HRS Payment' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS Payment$Vendor] WITH (NOLOCK)
	UNION ALL
  SELECT 'CodeNet' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Codenet$Vendor] with (nolock)
	UNION ALL
  SELECT 'Hotel Savoy' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Savoy$Vendor] with (nolock)
	UNION ALL
  SELECT 'Hotel Savoy Immobilien' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Savoy Immobilien$Vendor] with (nolock)
	UNION ALL
  SELECT 'Hotel Solutions' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Solutions$Vendor] with (nolock)
	UNION ALL
  SELECT 'Hotel Solutions Verwaltung' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Hotel Solutions Verwaltung$Vendor] with (nolock)
	UNION ALL
  SELECT 'Hotel.de' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[hotel_de$Vendor] with (nolock)
	UNION ALL
  SELECT 'HRS Holidays' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS Holidays$Vendor] with (nolock)
	UNION ALL
  --SELECT 'HRS Payment' AS [Company],
  --[No_],
  --[Name]
  --FROM [DynNavHRS].[dbo].[HRS Payment$Vendor] with (nolock)
  --	UNION ALL
  SELECT 'HRS-BR' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-BR$Vendor] with (nolock)
	UNION ALL
  SELECT 'HRS-CN' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-CN$Vendor] with (nolock)
	UNION ALL
  SELECT 'HRS-Global' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[HRS-Global$Vendor] with (nolock)
	UNION ALL
  SELECT 'Partner' AS [Company],
  [No_],
  [Name]
  FROM [Partner$Vendor] with (nolock)
	UNION ALL
  SELECT 'Product Development' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Product Development$Vendor] with (nolock)
	UNION ALL
  SELECT 'Ragge Blaubach' AS [Company],
  [No_],
  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Blaubach$Vendor] with (nolock)
	UNION ALL
  SELECT 'Ragge Neusser' AS [Company],
	  [No_],
	  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Neusser$Vendor] with (nolock)
	UNION ALL
  SELECT 'Ragge Schubert' AS [Company],
	  [No_],
	  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Schubert$Vendor] with (nolock)
	UNION ALL
  SELECT 'Ragge Turiner' AS [Company],
	  [No_],
	  [Name]
  FROM [DynNavHRS].[dbo].[Ragge Turiner$Vendor] with (nolock)
	UNION ALL
  SELECT 'RoRa Familien Holding' AS [Company],
	 [No_],
	 [Name]
  FROM [DynNavHRS].[dbo].[RoRa Familien Holding$Vendor] with (nolock)
  UNION ALL
  SELECT 'RoRa Familien Holding Verw_' AS [Company],
	[No_],
	[Name]
  FROM [DynNavHRS].[dbo].[RoRa Familien Holding Verw_$Vendor] with (nolock)
   UNION ALL
  SELECT 'TISCOVER' AS [Company],
	[No_],
	[Name]
  FROM [DynNavHRS].[dbo].[TISCOVER$Vendor] with (nolock)
	UNION ALL
  SELECT 'Trade' AS [Company],
	[No_],
	[Name]
  FROM [DynNavHRS].[dbo].[Trade$Vendor] with (nolock)
	UNION ALL
  SELECT 'TREX' AS [Company],
	[No_],
	[Name]
  FROM [DynNavHRS].[dbo].[TREX$Vendor] with (nolock)
  UNION ALL
  SELECT 'Venturecube' AS [Company],
	[No_],
	[Name]
  FROM [DynNavHRS].[dbo].[Venturecube$Vendor] with (nolock)
)
SELECT --*,
  CL.[Company],
  --VBA.Company,
  --V.Company,
  CL.[Date and Time],
  CL.[Primary Key Field 1 Value] AS KreditorNummer, 
  --CL.[Field No_] AS FeldNr,
  --CL.[Field Name],
  CL.[Table No_] as Tablename,
  VBA.[Name] AS BankName,
  V.[Name] AS KreditorName,  
  CL.[User ID],
  CASE CL.[Type of Change]
    WHEN 0 THEN 'New'
    WHEN 1 THEN 'Change'
    WHEN 2 THEN 'Delete'
  END AS [Type of Change],
  CL.[Old Value],
  CL.[New Value]
FROM CL
JOIN VBA
  ON  VBA.[Vendor No_] = CL.[Primary Key Field 1 Value]
	  AND VBA.Company = CL.Company
	  AND VBA.Code = CL.[Primary Key Field 2 Value]	
JOIN V
  ON V.[No_] = VBA.[Vendor No_]
	 AND CL.Company =V.Company 
     --AND CL.[Primary Key Field 1 Value]= V.[No_]
      
WHERE     1=1
      AND [Table No_] = 288
      AND [Field No_] IN(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,50000)
      AND CL.[Type of Change]<>2
      AND [Date and Time] BETWEEN @dateFrom AND @dateTo
      
      --AND CL.[Primary Key Field 1 Value]= 1 --12372--13346  
	 
ORDER BY [Date and Time]
END




---- Start of week SUNDAY - US_english language setting -
--SELECT CURRENT_TIMESTAMP, DATEADD (week, DATEDIFF(week,7, CURRENT_TIMESTAMP),7)
---- End of week SATURDAY
--SELECT CURRENT_TIMESTAMP, DATEADD (week, DATEDIFF(week,-6, CURRENT_TIMESTAMP),1)




GO
