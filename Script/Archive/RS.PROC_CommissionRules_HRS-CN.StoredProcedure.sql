USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [RS].[PROC_CommissionRules_HRS-CN]    Script Date: 10.04.2024 14:31:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Author:		Thomas Marquardt
-- Create date: 07.11.2013
-- Description:	Nav Report 50298; RFC-49556
-- 
/*
EXEC [RS].[PROC_CommissionRules_HRS-CN]
*/
-- ================================================
CREATE PROCEDURE [RS].[PROC_CommissionRules_HRS-CN] 

AS BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET Language German

DECLARE @ToDay datetime
 SELECT @ToDay = getdate()

;WITH CU_CN AS
(
  SELECT CU.[No_], CU.[Hotel Status], CU.[Brand], CU.[Chain], CASE WHEN CU.[Contract Status] IN ('10','11') THEN CU.[Contract Status] ELSE '01' END [Contract Status], CU.[Country_Region Code], CR.[Continent], CS.[Hotel Reference MuseID] 
    FROM DynNavHRS.dbo.[HRS-CN$Contact] CU WITH (NOLOCK)
    JOIN DynNavHRS.dbo.[HRS-CN$Customer] CS WITH (NOLOCK) ON CU.[No_] = CS.[No_]
    JOIN DynNavHRS.dbo.[HRS-CN$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CU.[Country_Region Code]
   WHERE CU.[Testhotel] = 0
     AND NOT CU.[Contract Status] IN ('00')
     AND NOT CU.[Chain] IN ('274','1612')
     AND NOT CU.[Brand] IN ('274','1612')
     AND CU.[Hotel Status] IN (0,1)
     AND NOT CU.[No_] IN (423715,463795)
     AND CU.[No_] < 699999
     --AND CU.[No_] = 3102
)
, TDMAX        AS (SELECT TD.[Tax Group Code], TD.[Tax Jurisdiction Code], MAX(TD.[Effective Date])[Effective Date] FROM DynNavHRS.dbo.[HRS$Tax Detail] TD WITH (NOLOCK) GROUP BY TD.[Tax Group Code], TD.[Tax Jurisdiction Code])
, TDSELECT     AS (SELECT TM.[Tax Group Code], TM.[Tax Jurisdiction Code], TD.[Tax Below Maximum] FROM TDMAX TM JOIN DynNavHRS.dbo.[HRS$Tax Detail] TD WITH (NOLOCK) ON TD.[Tax Group Code] = TM.[Tax Group Code] AND TD.[Tax Jurisdiction Code] = TM.[Tax Jurisdiction Code] AND TD.[Effective Date] = TM.[Effective Date])
, TaxDetail    AS (SELECT CO.[No_] [Hotel No_], CASE WHEN FT.[Use Hotelstamm] = 0 AND COALESCE(TG.[Use Hotelstamm],0) = 0 THEN FT.[VAT in %] ELSE COALESCE(T1.[Tax Below Maximum] ,0) END [VAT], CASE WHEN FT.[Use Hotelstamm] = 0 AND COALESCE(TG.[Use Hotelstamm],0) = 0 THEN FT.[Service Tax] ELSE COALESCE(T2.[Tax Below Maximum],0) END [SERVICETAX] FROM DynNavHRS.dbo.[HRS$Contact] CO WITH (NOLOCK) JOIN DynNavHRS.dbo.[HRS$Foreign Tax] FT WITH (NOLOCK) ON FT.[Country] = CO.[Country_Region Code] LEFT JOIN DynNavHRS.dbo.[HRS$Tax Group] TG WITH (NOLOCK) ON TG.[Code] = CO.[No_] LEFT JOIN TDSELECT T1 WITH (NOLOCK) ON T1.[Tax Group Code] = CO.[No_] AND T1.[Tax Jurisdiction Code] = 'VAT' LEFT JOIN TDSELECT T2 WITH (NOLOCK) ON T2.[Tax Group Code] = CO.[No_] AND T2.[Tax Jurisdiction Code] = 'SERVICETAX')
, AL_CN AS
(
  SELECT 26 /*Special Agreement               */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = AL.[No_] AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL
  SELECT 23 /*Brand/Chain je Land             */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = AL.[Brand] AND R2.[Chain] = AL.[Chain] AND R2.[MuseID] = '' AND R2.[Country Code] = AL.[Country_Region Code] AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT 20 /*Brand/Chain je Kontinent        */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = AL.[Brand] AND R2.[Chain] = AL.[Chain] AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = AL.[Continent] AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT 18 /*Brand/Chain                     */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = AL.[Brand] AND R2.[Chain] = AL.[Chain] AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT 16 /*Brand je Land                   */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = AL.[Brand] AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = AL.[Country_Region Code] AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT 15 /*Brand je Kontinent              */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = AL.[Brand] AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = AL.[Continent] AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT 14 /*Brand                           */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = AL.[Brand] AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT 12 /*Muse/Chain                      */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = AL.[Chain] AND NOT R2.[MuseID] IN ('','HRS') AND R2.[Country Code] = ''                       AND R2.[Continent] = ''AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] AND AL.[Contract Status] IN ('10','11') UNION ALL 
  SELECT 11 /*Chain je Land                   */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = AL.[Chain] AND R2.[MuseID] = '' AND R2.[Country Code] = AL.[Country_Region Code] AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT  9 /*Chain je Kontinent              */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = AL.[Chain] AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = AL.[Continent] AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT  6 /*Chain                           */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = AL.[Chain] AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT  4 /*Pegasus-Regel                   */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = ''         AND R2.[MuseID] <> '' AND R2.[Country Code] = ''                       AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] /*AND [Hotel Reference MuseID] <> ''*/ AND R2.[MuseID] = 'AMADEUS' AND AL.[Contract Status] IN ('10','11') UNION ALL 
  SELECT  3 /*AGB 2012 Standard               */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 1 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = '01' AND R2.[Brand] = ''         AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = AL.[Country_Region Code] AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT  2 /*Länderregel                     */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = AL.[Country_Region Code] AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT  1 /*Kontinentregel                  */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = AL.[Continent] AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] UNION ALL 
  SELECT  0 /*Default                         */ [Sortorder No_], R2.[Preferred], R2.[Category], R2.[Date of Reference], R2.[Code], R2.[Contract Code], R2.[Contract Grp_ Code], AL.[No_] [Hotel No_], [Hotel Reference MuseID], [Searchorder No_] FROM CU_CN AL JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules] R2 WITH (NOLOCK) ON R2.[Category] = 0 AND R2.[Partner No_] = '' AND R2.[Hotel No_] = ''       AND R2.[Company No_] = '' AND R2.[Contract Status] = ''   AND R2.[Brand] = ''         AND R2.[Chain] = ''         AND R2.[MuseID] = '' AND R2.[Country Code] = ''                       AND R2.[Continent] = ''             AND R2.[Approved] = 1 AND R2.[Enabled] = 1 AND @ToDay BETWEEN R2.[Valid from] AND R2.[Valid to] 
)
, MaxSortorder1_CN AS (SELECT AL.[Hotel No_], AL.[Sortorder No_], MAX([Searchorder No_]) [Searchorder No_] FROM AL_CN AL GROUP BY AL.[Hotel No_], AL.[Sortorder No_])
, MaxSortorder2_CN AS (SELECT AL.[Hotel No_], MAX(AL.[Sortorder No_]) [Sortorder No_] FROM AL_CN AL GROUP BY AL.[Hotel No_])
, HRS_CN AS
(
   SELECT AL.[Hotel No_]
        , CASE CU.[Hotel Status] WHEN 0 THEN 'open' WHEN 1 THEN 'closed' ELSE '' END [Hotel Status]
        , DV1.[Name] [Contract Status]
        , CU.[Country_Region Code]
        , CR.[Name] [Country Name]
        , CU.[Chain]
        , CH.[Description] [Chain Name]
        , CU.[Brand]
        , BR.[Description] [Brand Name]
        , AC.[Value %]       [Commission Rate]
        , FU.[Funktion Name] [Commission Type]
        , CASE WHEN FU.[Funktion ID] IN (8,9,10) THEN AC.[Value %] / (100. + [SERVICETAX]+[VAT]) * 100. ELSE AC.[Value %] END [normalized Commission Rate]
        , CASE WHEN COALESCE(GU.[Funktion ID],FU.[Funktion ID]) IN (8,9,10) THEN COALESCE(GC.[Value %],AC.[Value %]) / (100. + [SERVICETAX]+[VAT]) * 100. ELSE COALESCE(GC.[Value %],AC.[Value %]) END [normalized Commission Rate (AGB)]
        , CASE WHEN FU.[Funktion ID] IN (8,9,10) THEN AC.[Value %] / (100. + [SERVICETAX]+[VAT]) * 100. ELSE AC.[Value %] END 
        - CASE WHEN COALESCE(GU.[Funktion ID],FU.[Funktion ID]) IN (8,9,10) THEN COALESCE(GC.[Value %],AC.[Value %]) / (100. + [SERVICETAX]+[VAT]) * 100. ELSE COALESCE(GC.[Value %],AC.[Value %]) END [normalized Commission Rate (Difference)]
        , AL.[Preferred]
        , AL.[Sortorder No_]
     FROM MaxSortorder2_CN MS
     JOIN AL_CN AL 
       ON AL.[Hotel No_]            = MS.[Hotel No_]
      AND AL.[Sortorder No_]        = MS.[Sortorder No_]
     JOIN DynNavHRS.dbo.[HRS-CN$Contact] CU
       ON AL.[Hotel No_]            = CU.[No_]
     JOIN DynNavHRS.dbo.[HRS-CN$Country_Region]                  CR WITH (NOLOCK) 
       ON CR.[Code]                 = CU.[Country_Region Code]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Business Rules]          AGB WITH (NOLOCK) 
       ON AGB.[Category]            = 1 
      AND AGB.[Partner No_]         = '' 
      AND AGB.[Hotel No_]           = ''       
      AND AGB.[Company No_]         = '' 
      AND AGB.[Contract Status]     = '01' 
      AND AGB.[Brand]               = ''         
      AND AGB.[Chain]               = ''         
      AND AGB.[MuseID]              = '' 
      AND AGB.[Country Code]        = CU.[Country_Region Code] 
      AND AGB.[Continent]           = ''             
      AND AGB.[Approved]            = 1 
      AND AGB.[Enabled]             = 1
      AND @ToDay BETWEEN AGB.[Valid from] AND AGB.[Valid to]
     JOIN MaxSortorder1_CN MS1
       ON MS.[Hotel No_]            = MS1.[Hotel No_]
      AND MS.[Sortorder No_]        = MS1.[Sortorder No_]
      AND AL.[Searchorder No_]      = MS1.[Searchorder No_]
     JOIN DynNavHRS.dbo.[HRS-CN$Agency Contract]                AC WITH (NOLOCK)
       ON AC.[Code]                 = AL.[Contract Code]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Contract]                GC WITH (NOLOCK)
       ON GC.[Code]                 = AGB.[Contract Code]
     JOIN DynNavHRS.dbo.[HRS-CN$Agency Contract Calc_ Function] FU WITH (NOLOCK)
       ON FU.[Code]                 = AC.[Contract Calc_ Func_ Code]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Agency Contract Calc_ Function] GU WITH (NOLOCK)
       ON GU.[Code]                 = GC.[Contract Calc_ Func_ Code]
     JOIN TaxDetail TD
       ON TD.[Hotel No_]            = CU.[No_]
LEFT JOIN DynNavHRS.dbo.[HRS-CN$Dimension Value] DV1 WITH (NOLOCK)
       ON DV1.[Dimension Code] = 'CONTRACT STATUS'
      AND DV1.[Code]           = CU.[Contract Status]
LEFT JOIN DynNavHRS.dbo.[Chain] CH WITH (NOLOCK)
       ON CH.[Code]= CU.[Chain]
LEFT JOIN DynNavHRS.dbo.[Brand] BR WITH (NOLOCK)
       ON BR.[Code]= CU.[Brand]
)
   SELECT HRS.*, CASE WHEN [Preferred] = 1 OR [normalized Commission Rate (Difference)] > 0 OR [normalized Commission Rate (AGB)] = 0  THEN 0 ELSE [normalized Commission Rate (Difference)] / [normalized Commission Rate (AGB)] END [Disagio]
     FROM HRS_CN HRS
ORDER BY 1
END
GO
