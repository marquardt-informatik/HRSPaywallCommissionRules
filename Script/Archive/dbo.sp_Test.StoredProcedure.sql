USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_Test]    Script Date: 10.04.2024 14:31:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_Test] AS
;WITH BankAccount AS
(
SELECT [Vendor No_], [Name], [IBAN], [Bank Branch No_], [Bank Account No_], [SWIFT Code]
  FROM DynNavHRS.dbo.[HRS$Vendor Bank Account] WITH (READUNCOMMITTED) 
 WHERE [Clearing] = 1
), HeaderInfo AS
(
   SELECT 'K0000025098' [Rebate No_]
        , RH.[Rebate Agreement No_]
        , RH.[Rebate-to Vendor No_]
        , VE.[Name] [Rebate-to Customer Name]
        , VE.[Name 2] [Rebate-to Customer Name 2]
        , VE.[Address] [Rebate-to Address]
        , VE.[Address 2] [Rebate-to Address 2]
        , VE.City [Rebate-to City]
        , RA.[Rebate-to Contact]
        , VE.[Post Code] [Rebate-to Post Code]
        , VE.[Country_Region Code] [Rebate-to Country_Region Code]
        , '422748001..422748003|428310006|1009825001..1009825002|1017078005|1039101001..1039101008|1039352001..1039352002|1040441001..1040441003|1040915004..1040915005|1044252001|1049786001..1049786019|1053642001|1056305001..1056305003|1059947015|1059976001|1061766004|1063409002..1063409003|1063785001..1063785002|1063919002..1063919003|1065084002|1065085002' [Affiliate Partner List]
        , RH.[Currency Factor]
        , RH.[Interval]
        , RH.[Posting Date]
        , RH.[Document Date]    
        , CASE WHEN RH.[Language Code]='' THEN '0' ELSE RH.[Language Code] END [Language Code]
        , CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+1, RH.[Interval Start Date])
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END [Year Start Date]
        , DATEADD(dd,-1,CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+13, RH.[Interval Start Date]) 
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END) [Year End Date]
        , DATEADD(dd,-0,RH.[Interval Start Date]) [Till Start Date]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RH.[Document Type (Statement)]
        , RH.[Document Type (Cr_ Memo)]
        , RH.[Correspondence Type] 
        , COALESCE(BA.Name,'')                [Vendor Bank Name]
        , COALESCE(BA.[IBAN],'')              [Vendor IBAN]
        , COALESCE(BA.[SWIFT Code],'')        [Vendor SWIFT Code]
        , COALESCE(BA.[Bank Branch No_],'')   [Vendor Bank Branch No_]
        , COALESCE(BA.[Bank Account No_], '') [Vendor Bank Account No_]
        , RA.[Template Type]
        , RA.[Matrix _ Vector Code]
        , RA.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], COALESCE( L2.[Value Decimal], P2.[Value Decimal])  [Value P2]
		, VE.[VAT Bus_ Posting Group]					   [VatBusPostingGroup]
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    'txtVATRegistrationNo'
		  ELSE
            'txtRegistrationNo'
		  END                                              [VAT Registration Label]
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    VE.[VAT Registration No_]
		  ELSE
            VE.[Registration No_]
		  END                                              [VAT Registration No_]
		, DynNavHRS.dbo.[HRS$GetSalutation](RA.[Salutation Code],CASE WHEN RH.[Language Code]='' THEN '0' ELSE RH.[Language Code] END,0,1,RA.[No_]) [Saludation]
		, COALESCE(SP.[E-Mail],'kreditoren@hrs.de')    [Salesperson E-Mail]
		, COALESCE(SP.[Fax No_],'377')                 [Salesperson Fax No_]
		, COALESCE(SP.[Name],'')                       [Salesperson Name]
		, COALESCE(SP.[Phone No_],'800')               [Salesperson Phone No_]
		, COALESCE(CR.[EU Country_Region Code],'')     [EU Country_Region Code]
		, COALESCE(CR.[Name],'')                       [Country_Region Name]
		, RH.[Online Reservation Source]
		, RH.[Offline Reservation Source]
		, RA.[Print Booking Source] 
		, RA.[Enable retroactive correction]
		, RA.[Estimated Commission]
     FROM DynNavHRS.dbo.[HRS$Rebate Header]           RH WITH (READUNCOMMITTED) 
     JOIN DynNavHRS.dbo.[HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
     JOIN DynNavHRS.dbo.[HRS$Vendor]                  VE WITH (READUNCOMMITTED) ON VE.[No_]                 = RH.[Rebate-to Vendor No_]
 JOIN DynNavHRS.dbo.[HRS$Country_Region]          CR WITH (READUNCOMMITTED) ON CR.[Code]                = VE.[Country_Region Code]     
LEFT JOIN [BankAccount]                 BA                        ON BA.[Vendor No_]          = RH.[Rebate-to Vendor No_]
LEFT JOIN DynNavHRS.dbo.[HRS$Salesperson_Purchaser]   SP WITH (READUNCOMMITTED) ON SP.[Code]                = VE.[Purchaser Code]
LEFT JOIN DynNavHRS.dbo.[HRS$Parameter]               P2 WITH (READUNCOMMITTED) ON P2.[Code]                = RA.[Input Parameter 2 Code]
LEFT JOIN DynNavHRS.dbo.[HRS$Rebate Line]             L2 WITH (READUNCOMMITTED) ON L2.[Document No_]        = RH.[No_]                    AND L2.[No_]                 = RA.[Input Parameter 2 Code] AND L2.[Type]                IN (1,2)
   WHERE RH.[No_] = 'K0000025098'
UNION
   SELECT 'K0000025098' [Rebate No_]
        , RH.[Rebate Agreement No_]
        , RH.[Rebate-to Vendor No_]
        , VE.[Name] [Rebate-to Customer Name]
        , VE.[Name 2] [Rebate-to Customer Name 2]
        , VE.[Address] [Rebate-to Address]
        , VE.[Address 2] [Rebate-to Address 2]
        , VE.City [Rebate-to City]
        , RA.[Rebate-to Contact]
        , VE.[Post Code] [Rebate-to Post Code]
        , VE.[Country_Region Code] [Rebate-to Country_Region Code]
        , '422748001..422748003|428310006|1009825001..1009825002|1017078005|1039101001..1039101008|1039352001..1039352002|1040441001..1040441003|1040915004..1040915005|1044252001|1049786001..1049786019|1053642001|1056305001..1056305003|1059947015|1059976001|1061766004|1063409002..1063409003|1063785001..1063785002|1063919002..1063919003|1065084002|1065085002' [Affiliate Partner List]
        , RH.[Currency Factor]
        , RH.[Interval]
        , RH.[Posting Date]
        , RH.[Document Date]    
        , CASE WHEN RH.[Language Code]='' THEN '0' ELSE RH.[Language Code] END [Language Code]
        , CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+1, RH.[Interval Start Date])
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END [Year Start Date]
        , DATEADD(dd,-1,CASE WHEN RA.[Fiscal Year Start (Month)] = 0 THEN
            DATEADD(mm,-DATEPART(mm,RH.[Interval Start Date])+13, RH.[Interval Start Date]) 
          ELSE
            CASE WHEN DATEPART(mm,RH.[Interval Start Date])>=RA.[Fiscal Year Start (Month)] THEN
              DATEADD(mm,12-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            ELSE
              DATEADD(mm,-(DATEPART(mm,RH.[Interval Start Date])-RA.[Fiscal Year Start (Month)]), RH.[Interval Start Date])
            END
          END) [Year End Date]
        , DATEADD(dd,-0,RH.[Interval Start Date]) [Till Start Date]
        , RH.[Interval Start Date]
        , RH.[Interval End Date]
        , RH.[Document Type (Statement)]
        , RH.[Document Type (Cr_ Memo)]
        , RH.[Correspondence Type] 
        , COALESCE(BA.Name,'')                [Vendor Bank Name]
        , COALESCE(BA.[IBAN],'')              [Vendor IBAN]
        , COALESCE(BA.[SWIFT Code],'')        [Vendor SWIFT Code]
        , COALESCE(BA.[Bank Branch No_],'')   [Vendor Bank Branch No_]
        , COALESCE(BA.[Bank Account No_], '') [Vendor Bank Account No_]
        , RA.[Template Type]
        , RA.[Matrix _ Vector Code]
        , RA.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], COALESCE( L2.[Value Decimal], P2.[Value Decimal])  [Value P2]
		, VE.[VAT Bus_ Posting Group]					   [VatBusPostingGroup]
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    'txtVATRegistrationNo'
		  ELSE
            'txtRegistrationNo'
		  END                                              [VAT Registration Label]
		, CASE WHEN VE.[VAT Registration No_] <> '' THEN 
		    VE.[VAT Registration No_]
		  ELSE
            VE.[Registration No_]
		  END                                              [VAT Registration No_]
		, DynNavHRS.dbo.[HRS$GetSalutation](RA.[Salutation Code],CASE WHEN RH.[Language Code]='' THEN '0' ELSE RH.[Language Code] END,0,1,RA.[No_])
		, COALESCE(SP.[E-Mail],'kreditoren@hrs.de')    [Salesperson E-Mail]
		, COALESCE(SP.[Fax No_],'377')                 [Salesperson Fax No_]
		, COALESCE(SP.[Name],'')                       [Salesperson Name]
		, COALESCE(SP.[Phone No_],'800')               [Salesperson Phone No_]
		, COALESCE(CR.[EU Country_Region Code],'')     [EU Country_Region Code]
		, COALESCE(CR.[Name],'')                       [Country_Region Name]
		, RH.[Online Reservation Source]
		, RH.[Offline Reservation Source]
		, RA.[Print Booking Source] 
		, RA.[Enable retroactive correction]
		, RA.[Estimated Commission]
     FROM DynNavHRS.dbo.[HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
     JOIN DynNavHRS.dbo.[HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
     JOIN DynNavHRS.dbo.[HRS$Vendor]                  VE WITH (READUNCOMMITTED) ON VE.[No_]                 = RH.[Rebate-to Vendor No_]
LEFT JOIN DynNavHRS.dbo.[HRS$Country_Region]          CR WITH (READUNCOMMITTED) ON CR.[Code]                = VE.[Country_Region Code]     
LEFT JOIN [BankAccount]                 BA                        ON BA.[Vendor No_]          = RH.[Rebate-to Vendor No_]
LEFT JOIN DynNavHRS.dbo.[HRS$Salesperson_Purchaser]   SP WITH (READUNCOMMITTED) ON SP.[Code]                = VE.[Purchaser Code]
LEFT JOIN DynNavHRS.dbo.[HRS$Parameter]               P2 WITH (READUNCOMMITTED) ON P2.[Code]                = RA.[Input Parameter 2 Code]
LEFT JOIN DynNavHRS.dbo.[HRS$Posted Rebate Line]      L2 WITH (READUNCOMMITTED) ON L2.[Document No_]        = RH.[No_]                    AND L2.[No_]                 = RA.[Input Parameter 2 Code] AND L2.[Type]                IN (1,2)
   WHERE RH.[No_] = 'K0000025098'
), Summary AS
(
  SELECT RL.[Affiliate Partner No_]
       , CASE WHEN SUM(RL.[Amount (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Amount (LCY)]) - SUM(RL.[Amount (LCY) (corr_)])) / SUM(RL.[Amount (LCY)]) END [Amount Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Turnover (LCY)]) - SUM(RL.[Turnover (LCY) (corr_)])) / SUM(RL.[Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Turnover (LCY) (corr_)] END) [Commissionable Turnover]   
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]   
    FROM HeaderInfo                    RE
    JOIN DynNavHRS.dbo.[HRS$Rebate Header]      RH WITH (NOLOCK)
      ON RH.[Rebate Agreement No_] = RE.[Rebate Agreement No_]
    JOIN DynNavHRS.dbo.[HRS$Rebate Line]        RL WITH (NOLOCK)
      ON RH.[No_]                  = RL.[Document No_]
   WHERE (
             (RH.[Posting Date] BETWEEN RE.[Year Start Date] AND RE.[Posting Date] AND RE.[Enable retroactive correction] = 1)
          OR (RH.[No_] = RE.[Rebate No_] AND RE.[Enable retroactive correction] = 0)
		OR RH.[Rebate Agreement No_] = 'V0000007569'
         )
     AND RL.[Departure Date] BETWEEN RE.[Year Start Date] AND RE.[Posting Date]
     AND RL.[Eligible RevShare] = 0
     AND RL.[Type] = 5
     AND RL.[Travelagency No_] = 0
     AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16))
GROUP BY RL.[Affiliate Partner No_]
UNION   
  SELECT RL.[Affiliate Partner No_]
       , CASE WHEN SUM(RL.[Amount (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Amount (LCY)]) - SUM(RL.[Amount (LCY) (corr_)])) / SUM(RL.[Amount (LCY)]) END [Amount Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Turnover (LCY)]) - SUM(RL.[Turnover (LCY) (corr_)])) / SUM(RL.[Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Turnover (LCY) (corr_)] END) [Commissionable Turnover]   
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]   
    FROM HeaderInfo                    RE
    JOIN DynNavHRS.dbo.[HRS$Posted Rebate Header]    RH WITH (NOLOCK)
      ON RH.[Rebate Agreement No_] = RE.[Rebate Agreement No_]
    JOIN DynNavHRS.dbo.[HRS$Posted Rebate Line]      RL WITH (NOLOCK)
      ON RH.[No_]                  = RL.[Document No_]
   WHERE (
             (RH.[Posting Date] BETWEEN RE.[Year Start Date] AND RE.[Posting Date] AND RE.[Enable retroactive correction] = 1)
          OR (RH.[No_] = RE.[Rebate No_] AND RE.[Enable retroactive correction] = 0)
		OR RH.[Rebate Agreement No_] = 'V0000007569'
         )
     AND RL.[Departure Date] BETWEEN RE.[Year Start Date] AND RE.[Posting Date]
     AND RL.[Eligible RevShare] = 0
     AND RL.[Type] = 5
     AND RH.Cancels = 0
     AND RL.[Travelagency No_] = 0
   AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16))
GROUP BY RL.[Affiliate Partner No_]
), Sums AS
(
  SELECT ''          [CurrencyCode]
       , [Affiliate Partner No_]
       , CR.[Name]                          [Country]
       , SUM([Amount (LCY)])                [Amount (LCY)]
       , SUM([Amount (LCY) (corr_)])        [Amount (LCY) (corr_)]
       , SUM([Turnover (LCY)]) [Turnover (LCY)]
       , SUM([Turnover (LCY) (corr_)])      [Turnover (LCY) (corr_)]
       , CASE WHEN SUM([Amount (LCY)]) = 0 
         THEN 0 ELSE 
         (SUM([Amount (LCY)]) - SUM([Amount (LCY) (corr_)])) 
       / SUM([Amount (LCY)]) END            [Amount Correction Ratio]   
       , SUM([Turnover Correction Ratio])   [Turnover Correction Ratio]
       , SUM([Net Rate Share Ratio])        [Net Rate Share Ratio]
       , SUM([Net Rate Share])   
           [Net Rate Share]
       , SUM([Non Commissionables])         [Non Commissionables]
       , SUM([Commissionable Turnover])     [Commissionable Turnover]
       , CASE WHEN SUM([Commissionable Turnover]) = 0 THEN 0 ELSE 
         SUM([Amount (LCY) (corr_)]) 
       / SUM([Commissionable Turnover]) END [Average Commission Rate]
    FROM Summary
    JOIN [Affiliate Partner] AP WITH (NOLOCK)
      ON AP.[No_] = [Affiliate Partner No_]
    JOIN DynNavHRS.dbo.[HRS$Country_Region] CR WITH (NOLOCK)
      ON CR.[Code]= AP.[Country Code]
GROUP BY [Affiliate Partner No_]
       , CR.[Name] 
)
  SELECT RL.[Affiliate Partner No_]
       , RL.[Reservation No_]
	   , RL.[Reservation Part No_]
       , CASE WHEN SUM(RL.[Amount (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Amount (LCY)]) - SUM(RL.[Amount (LCY) (corr_)])) / SUM(RL.[Amount (LCY)]) END [Amount Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Turnover (LCY)]) - SUM(RL.[Turnover (LCY) (corr_)])) / SUM(RL.[Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Turnover (LCY) (corr_)] END) [Commissionable Turnover]   
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]   
    FROM HeaderInfo                    RE
    JOIN DynNavHRS.dbo.[HRS$Rebate Header]      RH WITH (NOLOCK)
      ON RH.[Rebate Agreement No_] = RE.[Rebate Agreement No_]
    JOIN DynNavHRS.dbo.[HRS$Rebate Line]        RL WITH (NOLOCK)
      ON RH.[No_]                  = RL.[Document No_]
   WHERE (
             (RH.[Posting Date] BETWEEN RE.[Year Start Date] AND RE.[Posting Date] AND RE.[Enable retroactive correction] = 1)
          OR (RH.[No_] = RE.[Rebate No_] AND RE.[Enable retroactive correction] = 0)
		OR RH.[Rebate Agreement No_] = 'V0000007569'
         )
     AND RL.[Departure Date] BETWEEN RE.[Year Start Date] AND RE.[Interval End Date]
     AND RL.[Eligible RevShare] = 0
     AND RL.[Type] = 5
--     AND RL.[Travelagency No_] = 0
     AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16))
	 AND RL.[Affiliate Partner No_] = 1065084002
	 AND RL.[Reservation No_] = 149252366
GROUP BY RL.[Affiliate Partner No_]
       , RL.[Reservation No_]
	   , RL.[Reservation Part No_]
UNION   
  SELECT RL.[Affiliate Partner No_]
       , RL.[Reservation No_]
	   , RL.[Reservation Part No_]
       , CASE WHEN SUM(RL.[Amount (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Amount (LCY)]) - SUM(RL.[Amount (LCY) (corr_)])) / SUM(RL.[Amount (LCY)]) END [Amount Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Turnover (LCY)]) - SUM(RL.[Turnover (LCY) (corr_)])) / SUM(RL.[Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Turnover (LCY) (corr_)] END) [Commissionable Turnover]   
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]   
    FROM HeaderInfo                    RE
    JOIN DynNavHRS.dbo.[HRS$Posted Rebate Header]    RH WITH (NOLOCK)
      ON RH.[Rebate Agreement No_] = RE.[Rebate Agreement No_]
    JOIN DynNavHRS.dbo.[HRS$Posted Rebate Line]      RL WITH (NOLOCK)
      ON RH.[No_]                  = RL.[Document No_]
   WHERE (
             (RH.[Posting Date] BETWEEN RE.[Year Start Date] AND RE.[Posting Date] AND RE.[Enable retroactive correction] = 1)
          OR (RH.[No_] = RE.[Rebate No_] AND RE.[Enable retroactive correction] = 0)
		OR RH.[Rebate Agreement No_] = 'V0000007569'
         )
      AND RL.[Departure Date] BETWEEN RE.[Year Start Date] AND RE.[Interval End Date]
     AND RL.[Eligible RevShare] = 0
     AND RL.[Type] = 5
     AND RH.Cancels = 0
--     AND RL.[Travelagency No_] = 0
     AND ((RL.[Reservation Source] != 0) AND (RL.[Reservation Source] != 2) AND (RL.[Reservation Source] != 3) AND (RL.[Reservation Source] != 8) AND (RL.[Reservation Source] != 16))
	 AND RL.[Affiliate Partner No_] = 1065084002
	 AND RL.[Reservation No_] = 149252366
GROUP BY RL.[Affiliate Partner No_]
       , RL.[Reservation No_]
	   , RL.[Reservation Part No_]

GO
