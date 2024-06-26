USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[MoveReservationToCollectiveInvoice]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 22.02.2022
-- Description:	Mislanding Reservations were moved from single Hotel to HQ Invoice
-- Ticket :     ACS-3477
-- =============================================
CREATE PROC [dbo].[MoveReservationToCollectiveInvoice]
  @CreationDate date
AS
BEGIN
UPDATE DL SET 
       DL.[Display Case No_]=DH2.[Case No_]
     , DL.[Currency Code] = DH2.[Currency Code]
     , DL.[Currency Faktor] = DH2.[Currency Factor]
     , DL.[Commission Base Amount]=ROUND(DL.[Commission Base Amount (LCY)] * DH2.[Currency Factor],2)
     , DL.[Commission Amount]=ROUND(DL.[Commission Amount (LCY)] * DH2.[Currency Factor],2)
     , DL.[Line Amount]=ROUND(DL.[Line Amount (LCY)] * DH2.[Currency Factor],2)
     , DL.[Agency Line Amount]=ROUND(DL.[Agency Line Amount (LCY)] * DH2.[Currency Factor],2)
     , DL.[TAF Line Amount]=ROUND(DL.[TAF Line Amount (LCY)] * DH2.[Currency Factor],2)
     , DL.[Room Price]=ROUND(DL.[Room Price] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Net Room Price]=ROUND(DL.[Net Room Price] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Breakfast Price]=ROUND(DL.[Breakfast Price] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Net Breakfast Price]=ROUND(DL.[Net Breakfast Price] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Foreign Tax Amount]=ROUND(DL.[Foreign Tax Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Foreign Tax Base Amount]=ROUND(DL.[Foreign Tax Base Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[TAF Fix]=ROUND(DL.[TAF Fix] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Hotel sales incl_ VAT]=ROUND(DL.[Hotel sales incl_ VAT] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Foreign Tax Roomnight Base Amt]=ROUND(DL.[Foreign Tax Roomnight Base Amt] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Foreign Tax Breakf Base Amount]=ROUND(DL.[Foreign Tax Breakf Base Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Commission Roomnight Base Amnt]=ROUND(DL.[Commission Roomnight Base Amnt] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Commission Breakf Base Amount]=ROUND(DL.[Commission Breakf Base Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Foreign Tax Roomnight Amount]=ROUND(DL.[Foreign Tax Roomnight Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Foreign Tax Breakf Amount]=ROUND(DL.[Foreign Tax Breakf Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Commission Roomnight Amount]=ROUND(DL.[Commission Roomnight Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
     , DL.[Commission Breakf Amount]=ROUND(DL.[Commission Breakf Amount] * DH2.[Currency Factor] / DL.[Currency Faktor],2)
  FROM [HRS$Agency Display Line]   DL WITH (NOLOCK) 
  JOIN [HRS$Agency Display Header] DH WITH (NOLOCK) ON DL.[Display Case No_]=DH.[Case No_]
  JOIN [HRS$Agency Line] AL WITH (NOLOCK)
    ON DL.[Reservation No_]=AL.[Reservation No_]
   AND DL.[Position No_]=AL.[Position No_]
  JOIN [HRS$Agency Business Rules] BR WITH(NOLOCK)
    ON BR.[Code] IN (DL.[TAF Business Rules Code],DL.[Agency Business Rules Code])
  JOIN [HRS$Agency Display Header] DH2 WITH (NOLOCK) ON DH2.[Bill-to Customer No_]=BR.[Differing Customer No_] AND DH2.[Creation Date]='2022-01-31' AND DH2.[Status]=0 AND DH2.[Correction from]=''
 WHERE DH.[Creation Date] = @CreationDate
   AND DH.[Status]=0
   AND DH.[Correction from]=''
   AND BR.[Differing Customer No_]<>''
   AND BR.[Differing Customer No_]<>DH.[Bill-to Customer No_]  
END
GO
