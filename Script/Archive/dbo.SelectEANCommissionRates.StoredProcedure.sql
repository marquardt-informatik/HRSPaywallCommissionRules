USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[SelectEANCommissionRates]    Script Date: 10.04.2024 14:31:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SelectEANCommissionRates] AS BEGIN
;WITH 
  DH AS (SELECT DH.[Case No_], DH.[Posted Invoice No_], DH.[Correction from] FROM [DynNavHRS].dbo.[HRS$Agency Display Header] DH WITH (NOLOCK) WHERE DH.[Bill-to Customer No_]='99990111' AND DH.[Creation Date]>='2022-01-01')
, CH AS 
(
   SELECT D1.[Case No_]
     FROM DH D1
LEFT JOIN DH D2 ON D2.[Correction from]=D1.[Posted Invoice No_]
    WHERE D2.[Case No_] IS NULL
)
   SELECT DL.[Hotel No_]
        , CO.[Name]
        , CO.[City]
        , CR.[Name] [Country]
        , NULLIF(CO.[Chain],'99999') [Chain]
        , NULLIF(CO.[Brand],'99999') [Brand]
        , DL.[Reservation No_]
        , DL.[Position No_]
        , DL.[Room Price]
        , DL.[Number of Nights]
        , ROUND(DL.[Commission Rate] / 0.63,2) [Commission Rate]
     FROM [DynNavHRS].dbo.[HRS$Agency Display Line] DL WITH (NOLOCK)
     JOIN CH DH ON DH.[Case No_]=DL.[Display Case No_]
     JOIN [DynNavHRS].dbo.[HRS$Contact] CO WITH (NOLOCK) ON CO.[No_]=DL.[Hotel No_]
     JOIN [DynNavHRS].dbo.[HRS$Country_Region] CR WITH (NOLOCK) ON CR.[Code]=CO.[Country_Region Code]
    WHERE DL.[Action]<>3
      AND DL.[Line Amount]>0
      AND DL.[Commission Rate] / 0.63 BETWEEN 8.4 AND 42
      --AND CO.[Country_Region Code]='33'
 ORDER BY CR.[Name]
        , CO.[City]
        , DL.[Hotel No_]
        , DL.[Reservation No_]
        , DL.[Position No_]
END
GO
