USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateTASummary]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 27.07.2011
-- Description:	Statistische Zusammenfassung zur Gutschriftsanzeige
--
-- 03.07.2018 DJU ACS-799 - changed JOIN [BankAccount] to LEFT JOIN [BankAccount]
--
/*EXEC [dbo].[sp_RebateTASummary] 'K0000042470'

*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateTASummary] 
    @RebateNo varchar(20)
WITH RECOMPILE 
AS
BEGIN
DECLARE @PrintNet int, @ResultText VARCHAR(MAX), @TableName VARCHAR(120), @CompanyName VARCHAR(30), @FieldName varchar(20)
 SELECT @TableName = 'RL', @FieldName = 'Reservation Source'
 
DECLARE @SQL VARCHAR(max) = '',@SQL1 VARCHAR(max), @FilterText VARCHAR(max), @CurrencyCode VARCHAR(20)

SET @FilterText = ''
SET @CurrencyCode = ''

DECLARE @CustList VARCHAR(MAX)
SELECT @CustList = ''

DECLARE @AP AS TABLE([Travelagency No_] int, [Rebate No_] varchar(20))
DECLARE @ActualCustomer int, @PreviousCustomer int, @FirstCustomer int
 SELECT @ActualCustomer = 0, @PreviousCustomer = 0, @FirstCustomer = 0

;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[Rebate No_] = @RebateNo 
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.[Rebate-to Vendor No_]
     , RH.[No_]
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo

)
INSERT INTO @AP
SELECT AV.[Travelagency No_], AH.[No_]
  FROM [HRS$Vendor Travelagency] AV WITH (NOLOCK)
  JOIN AgreementHeader AH
    ON AH.[Rebate-to Vendor No_] = AV.[Vendor No_]

DECLARE cur CURSOR FOR SELECT * FROM @AP ORDER BY 1

OPEN cur

FETCH NEXT FROM cur INTO @ActualCustomer, @RebateNo

SELECT @FirstCustomer = @ActualCustomer

WHILE @@FETCH_STATUS = 0
BEGIN
  IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
    IF (@PreviousCustomer<> 0) BEGIN
      SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
      SET @CustList = @CustList 
                    + CASE WHEN @PreviousCustomer = @FirstCustomer THEN 
                        CAST(@PreviousCustomer AS varchar)
                      ELSE
                        CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                      END
      SELECT @FirstCustomer = @ActualCustomer
    END 
  END
  
  SELECT @PreviousCustomer = @ActualCustomer
  FETCH NEXT FROM cur INTO @ActualCustomer, @RebateNo
END

IF (@ActualCustomer <> @PreviousCustomer+1) BEGIN
  IF (@PreviousCustomer<> 0) BEGIN
    SET @CustList = CASE WHEN @CustList = '' THEN '' ELSE @CustList + '|' END
    SET @CustList = @CustList 
                  + CASE WHEN @PreviousCustomer = @FirstCustomer THEN 
                      CAST(@PreviousCustomer AS varchar)
                    ELSE
                      CAST(@FirstCustomer AS varchar) + '..' + CAST(@PreviousCustomer AS varchar)
                    END
    SELECT @FirstCustomer = @ActualCustomer
  END 
END

CLOSE cur
DEALLOCATE cur

SELECT @FilterText = ''
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
)
SELECT @FilterText = [Online Reservation Source] FROM AgreementHeader
PRINT @FilterText

IF COALESCE(@FilterText,'')=''
BEGIN
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
), SourceFilter AS
(
  SELECT MAX(P.[Reservation Source Filter Txt]) [Filter Text]
    FROM [HRS$Parameter]              P
    JOIN [HRS$Rebate Agreement Line] AL
      ON AL.[Input Parameter 1 Code] = P.[Code]
      OR AL.[Input Parameter 2 Code] = P.[Code]
      OR AL.[Input Parameter 3 Code] = P.[Code]
      OR AL.[Input Parameter 4 Code] = P.[Code]
      OR AL.[Input Parameter 5 Code] = P.[Code]
    JOIN AgreementHeader             AH
      ON AH.[No_]                     = AL.[Rebate No_]     
)
SELECT @FilterText = CASE WHEN [Filter Text]='' THEN RH.[Online Reservation Source] ELSE [Filter Text] END
     , @CurrencyCode = RH.[Currency Code]
  FROM SourceFilter,[HRS$Rebate Header] RH
 WHERE RH.[No_] = @RebateNo
END
 
IF (@FilterText='' )
BEGIN
;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE (RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo)
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
   AND RH.Cancels = 0
), SourceFilter AS
(
  SELECT MAX(P.[Reservation Source Filter Txt]) [Filter Text]
    FROM [HRS$Parameter]              P
    JOIN [HRS$Rebate Agreement Line] AL
      ON AL.[Input Parameter 1 Code] = P.[Code]
      OR AL.[Input Parameter 2 Code] = P.[Code]
      OR AL.[Input Parameter 3 Code] = P.[Code]
      OR AL.[Input Parameter 4 Code] = P.[Code]
      OR AL.[Input Parameter 5 Code] = P.[Code]
    JOIN AgreementHeader             AH
      ON AH.[No_]                     = AL.[Rebate No_]     
)
SELECT @FilterText = CASE WHEN [Filter Text]='' THEN RH.[Online Reservation Source] ELSE [Filter Text] END
     , @CurrencyCode = RH.[Currency Code]
  FROM SourceFilter,[HRS$Posted Rebate Header] RH
 WHERE (RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo)
END

;WITH AgreementHeader AS
(
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Rebate Header]           RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo
UNION
SELECT RH.[Posting Date]
     , RH.[Interval Start Date]
     , RH.[Interval End Date]
     , AH.*
  FROM [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
  JOIN [HRS$Rebate Agreement Header] AH WITH (NOLOCK)
    ON AH.[No_] = RH.[Rebate Agreement No_] 
 WHERE RH.[No_] = @RebateNo OR RH.[Rebate No_] = @RebateNo
)

SELECT @PrintNet = COALESCE([Print Net Turnover],0) FROM AgreementHeader

SELECT @ResultText= ''  
IF @FilterText <>'' 
BEGIN
SELECT @ResultText = @ResultText + 
       CASE WHEN CHARINDEX('&', @FilterText) > 0 THEN 
         CASE WHEN @ResultText <> '' THEN ' AND ' ELSE '' END 
       + RS.SqlFilterAND('' + [String] + '', @TableName + '.[' + @FieldName +']',0)
       ELSE
         CASE WHEN @ResultText <> '' THEN ' OR ' ELSE '' END 
       + RS.SqlFilterOR('' + [String] + '', @TableName + '.[' + @FieldName +']',0)
       END
  FROM RS.Split(@FilterText,'&')
SELECT @ResultText = 'AND (' + @ResultText + ')'
END

PRINT @ResultText

SET @SQL = '
;WITH BankAccount AS
(
SELECT [Vendor No_], [Name], [IBAN], [Bank Branch No_], [Bank Account No_], [SWIFT Code]
  FROM [HRS$Vendor Bank Account] WITH (READUNCOMMITTED) 
 WHERE [Clearing] = 1
), HeaderInfo AS
(
   SELECT ''' + @RebateNo + ''' [Rebate No_]
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
        , ''' + @CustList + ''' [Affiliate Partner List]
        , RH.[Currency Factor]
        , RH.[Interval]
        , RH.[Posting Date]
        , RH.[Document Date]    
        , CASE WHEN RH.[Language Code]='''' THEN ''0'' ELSE RH.[Language Code] END [Language Code]
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
        , COALESCE(BA.Name,'''')                [Vendor Bank Name]
        , COALESCE(BA.[IBAN],'''')              [Vendor IBAN]
        , COALESCE(BA.[SWIFT Code],'''')        [Vendor SWIFT Code]
        , COALESCE(BA.[Bank Branch No_],'''')   [Vendor Bank Branch No_]
        , COALESCE(BA.[Bank Account No_], '''') [Vendor Bank Account No_]
        , RA.[Template Type]
        , RA.[Matrix _ Vector Code]
        , RA.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], COALESCE( L2.[Value Decimal], P2.[Value Decimal])  [Value P2]
		, VE.[VAT Bus_ Posting Group]					   [VatBusPostingGroup]
		, CASE WHEN VE.[VAT Registration No_] <> '''' THEN 
		    ''txtVATRegistrationNo''
		  ELSE
            ''txtRegistrationNo''
		  END                                              [VAT Registration Label]
		, CASE WHEN VE.[VAT Registration No_] <> '''' THEN 
		    VE.[VAT Registration No_]
		  ELSE
            VE.[Registration No_]
		  END                                              [VAT Registration No_]
		, dbo.[HRS$GetSalutation](RA.[Salutation Code],CASE WHEN RH.[Language Code]='''' THEN ''0'' ELSE RH.[Language Code] END,0,1,RA.[No_]) [Saludation]
		, COALESCE(SP.[E-Mail],''kreditoren@hrs.de'')    [Salesperson E-Mail]
		, COALESCE(SP.[Fax No_],''377'')                 [Salesperson Fax No_]
		, COALESCE(SP.[Name],'''')                       [Salesperson Name]
		, COALESCE(SP.[Phone No_],''800'')               [Salesperson Phone No_]
		, COALESCE(CR.[EU Country_Region Code],'''')     [EU Country_Region Code]
		, COALESCE(CR.[Name],'''')                       [Country_Region Name]
		, RH.[Online Reservation Source]
		, RH.[Offline Reservation Source]
		, RA.[Print Booking Source] 
		, RA.[Enable retroactive correction]
		, RA.[Estimated Commission]
     FROM [HRS$Rebate Header]           RH WITH (READUNCOMMITTED) 
     JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
     JOIN [HRS$Vendor]                  VE WITH (READUNCOMMITTED) ON VE.[No_]                 = RH.[Rebate-to Vendor No_]
 JOIN [HRS$Country_Region]          CR WITH (READUNCOMMITTED) ON CR.[Code]                = VE.[Country_Region Code]     
LEFT JOIN [BankAccount]                 BA                        ON BA.[Vendor No_]          = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Salesperson_Purchaser]   SP WITH (READUNCOMMITTED) ON SP.[Code]                = VE.[Purchaser Code]
LEFT JOIN [HRS$Parameter]               P2 WITH (READUNCOMMITTED) ON P2.[Code]                = RA.[Input Parameter 2 Code]
LEFT JOIN [HRS$Rebate Line]             L2 WITH (READUNCOMMITTED) ON L2.[Document No_]        = RH.[No_]                    AND L2.[No_]                 = RA.[Input Parameter 2 Code] AND L2.[Type]                IN (1,2)
   WHERE RH.[No_] = ''' + @RebateNo + '''
UNION
   SELECT ''' + @RebateNo + ''' [Rebate No_]
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
        , ''' + @CustList + ''' [Affiliate Partner List]
        , RH.[Currency Factor]
        , RH.[Interval]
        , RH.[Posting Date]
        , RH.[Document Date]    
        , CASE WHEN RH.[Language Code]='''' THEN ''0'' ELSE RH.[Language Code] END [Language Code]
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
        , COALESCE(BA.Name,'''')                [Vendor Bank Name]
        , COALESCE(BA.[IBAN],'''')              [Vendor IBAN]
        , COALESCE(BA.[SWIFT Code],'''')        [Vendor SWIFT Code]
        , COALESCE(BA.[Bank Branch No_],'''')   [Vendor Bank Branch No_]
        , COALESCE(BA.[Bank Account No_], '''') [Vendor Bank Account No_]
        , RA.[Template Type]
        , RA.[Matrix _ Vector Code]
        , RA.[Input Parameter 2 Code]   [Code P2],  P2.[Name]  [Name P2], COALESCE( L2.[Value Decimal], P2.[Value Decimal])  [Value P2]
		, VE.[VAT Bus_ Posting Group]					   [VatBusPostingGroup]
		, CASE WHEN VE.[VAT Registration No_] <> '''' THEN 
		    ''txtVATRegistrationNo''
		  ELSE
            ''txtRegistrationNo''
		  END                                              [VAT Registration Label]
		, CASE WHEN VE.[VAT Registration No_] <> '''' THEN 
		    VE.[VAT Registration No_]
		  ELSE
            VE.[Registration No_]
		  END                                              [VAT Registration No_]
		, dbo.[HRS$GetSalutation](RA.[Salutation Code],CASE WHEN RH.[Language Code]='''' THEN ''0'' ELSE RH.[Language Code] END,0,1,RA.[No_])
		, COALESCE(SP.[E-Mail],''kreditoren@hrs.de'')    [Salesperson E-Mail]
		, COALESCE(SP.[Fax No_],''377'')                 [Salesperson Fax No_]
		, COALESCE(SP.[Name],'''')                       [Salesperson Name]
		, COALESCE(SP.[Phone No_],''800'')               [Salesperson Phone No_]
		, COALESCE(CR.[EU Country_Region Code],'''')     [EU Country_Region Code]
		, COALESCE(CR.[Name],'''')                       [Country_Region Name]
		, RH.[Online Reservation Source]
		, RH.[Offline Reservation Source]
		, RA.[Print Booking Source] 
		, RA.[Enable retroactive correction]
		, RA.[Estimated Commission]
     FROM [HRS$Posted Rebate Header]    RH WITH (READUNCOMMITTED)
     JOIN [HRS$Rebate Agreement Header] RA WITH (READUNCOMMITTED) ON RA.[No_]                 = RH.[Rebate Agreement No_]
     JOIN [HRS$Vendor]                  VE WITH (READUNCOMMITTED) ON VE.[No_]                 = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Country_Region]          CR WITH (READUNCOMMITTED) ON CR.[Code]                = VE.[Country_Region Code]     
LEFT JOIN [BankAccount]                 BA                        ON BA.[Vendor No_]          = RH.[Rebate-to Vendor No_]
LEFT JOIN [HRS$Salesperson_Purchaser]   SP WITH (READUNCOMMITTED) ON SP.[Code]                = VE.[Purchaser Code]
LEFT JOIN [HRS$Parameter]               P2 WITH (READUNCOMMITTED) ON P2.[Code]                = RA.[Input Parameter 2 Code]
LEFT JOIN [HRS$Posted Rebate Line]      L2 WITH (READUNCOMMITTED) ON L2.[Document No_]        = RH.[No_]                    AND L2.[No_]                 = RA.[Input Parameter 2 Code] AND L2.[Type]                IN (1,2)
   WHERE RH.[No_] = ''' + @RebateNo + '''
), Summary AS
(
  SELECT RL.[Travelagency No_]
       , RL.[Reservation Source]
       , CASE WHEN SUM(RL.[Amount (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Amount (LCY)]) - SUM(RL.[Amount (LCY) (corr_)])) / SUM(RL.[Amount (LCY)]) END [Amount Correction Ratio]' 
  + CASE WHEN @PrintNet<>1 THEN '
       , CASE WHEN SUM(RL.[Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Turnover (LCY)]) - SUM(RL.[Turnover (LCY) (corr_)])) / SUM(RL.[Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Turnover (LCY) (corr_)] END) [Commissionable Turnover]'
    ELSE '
       , CASE WHEN SUM(RL.[Net Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Net Turnover (LCY)]) - SUM(RL.[Net Turnover (LCY) (corr_)])) / SUM(RL.[Net Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Net Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Net Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Net Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Net Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Net Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Net Turnover (LCY) (corr_)] END) [Commissionable Turnover]'
    END + '   
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]'
  + CASE WHEN @PrintNet<>1 THEN '
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]'
    ELSE '
       , SUM(RL.[Net Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Net Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]'
    END + '   
    FROM HeaderInfo                    RE
    JOIN [HRS$Rebate Header]      RH WITH (NOLOCK)
      ON RH.[Rebate Agreement No_] = RE.[Rebate Agreement No_]
    JOIN [HRS$Rebate Line]        RL WITH (NOLOCK)
      ON RH.[No_]                  = RL.[Document No_]
   WHERE (
             (RH.[Document Date] BETWEEN RE.[Year Start Date] AND RE.[Document Date] AND RE.[Enable retroactive correction] = 1)
          OR (RH.[No_] = RE.[Rebate No_] AND RE.[Enable retroactive correction] = 0)
		  OR RH.[Rebate Agreement No_] = ''V0000007569''
         )
     AND RL.[Departure Date] BETWEEN RE.[Year Start Date] AND RE.[Document Date]
     AND RL.[Eligible RevShare] = 0
     AND RL.[Type] = 5
     AND RL.[Source Class] = 3
	 --AND RL.[Document No_] = ''P0000020886''
     ' + @ResultText +'
GROUP BY RL.[Travelagency No_]
       , RL.[Reservation Source]
UNION   
  SELECT RL.[Travelagency No_]
       , RL.[Reservation Source]
       , CASE WHEN SUM(RL.[Amount (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Amount (LCY)]) - SUM(RL.[Amount (LCY) (corr_)])) / SUM(RL.[Amount (LCY)]) END [Amount Correction Ratio]' 
  + CASE WHEN @PrintNet<>1 THEN '
       , CASE WHEN SUM(RL.[Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Turnover (LCY)]) - SUM(RL.[Turnover (LCY) (corr_)])) / SUM(RL.[Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Turnover (LCY) (corr_)] END) [Commissionable Turnover]'
    ELSE '
       , CASE WHEN SUM(RL.[Net Turnover (LCY)]) = 0 THEN 0 ELSE (SUM(RL.[Net Turnover (LCY)]) - SUM(RL.[Net Turnover (LCY) (corr_)])) / SUM(RL.[Net Turnover (LCY)]) END [Turnover Correction Ratio]
       , CASE WHEN SUM(RL.[Net Turnover (LCY) (corr_)]) = 0 THEN 0 ELSE SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Net Turnover (LCY) (corr_)] ELSE 0 END) / SUM(RL.[Net Turnover (LCY) (corr_)]) END [Net Rate Share Ratio]
       , SUM(CASE WHEN RL.[Commission Type] = 13 THEN RL.[Net Turnover (LCY) (corr_)] ELSE 0 END) [Net Rate Share]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN RL.[Net Turnover (LCY) (corr_)] ELSE 0 END) [Non Commissionables]
       , SUM(CASE WHEN RL.[Amount (LCY) (corr_)] = 0 THEN 0 ELSE RL.[Net Turnover (LCY) (corr_)] END) [Commissionable Turnover]'
    END + '   
       , SUM(RL.[Amount (LCY)]) [Amount (LCY)]
       , SUM(RL.[Amount (LCY) (corr_)]) [Amount (LCY) (corr_)]'
  + CASE WHEN @PrintNet<>1 THEN '
       , SUM(RL.[Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]'
    ELSE '
       , SUM(RL.[Net Turnover (LCY)]) [Turnover (LCY)]
       , SUM(RL.[Net Turnover (LCY) (corr_)]) [Turnover (LCY) (corr_)]'
    END + '   
    FROM HeaderInfo                    RE
    JOIN [HRS$Posted Rebate Header]    RH WITH (NOLOCK)
      ON RH.[Rebate Agreement No_] = RE.[Rebate Agreement No_]
    JOIN [HRS$Posted Rebate Line]      RL WITH (NOLOCK)
      ON RH.[No_]                  = RL.[Document No_]
   WHERE (
             (RH.[Document Date] BETWEEN RE.[Year Start Date] AND RE.[Document Date] AND RE.[Enable retroactive correction] = 1)
          OR (RH.[No_] = RE.[Rebate No_] AND RE.[Enable retroactive correction] = 0)
          OR RH.[Rebate Agreement No_] = ''V0000007569''
         )
     AND RL.[Departure Date] BETWEEN RE.[Year Start Date] AND RE.[Document Date]
     AND RL.[Eligible RevShare] = 0
     AND RL.[Type] = 5
     AND RH.Cancels = 0
     AND RL.[Source Class] = 3
	 --AND RL.[Document No_] = ''P0000020886''
   ' + @ResultText +'
GROUP BY RL.[Travelagency No_]
       , RL.[Reservation Source]
), Sums AS
(
  SELECT ''' + @CurrencyCode + '''          [CurrencyCode]
       , [Travelagency No_]
       , [Reservation Source]
       , SUM([Amount (LCY)])                [Amount (LCY)]
       , SUM([Amount (LCY) (corr_)])        [Amount (LCY) (corr_)]
       , SUM([Turnover (LCY)]) [Turnover (LCY)]
       , SUM([Turnover (LCY) (corr_)])      [Turnover (LCY) (corr_)]
       , CASE WHEN SUM([Amount (LCY)]) = 0 
         THEN 0 ELSE 
         (SUM([Amount (LCY)]) - SUM([Amount (LCY) (corr_)])) 
       / SUM([Amount (LCY)]) END            [Amount Correction Ratio]   
       , SUM([Turnover Correction Ratio])   [Turnover Correction Ratio]
       , CASE WHEN SUM([Turnover (LCY)]) = 0
         THEN 0 ELSE
         SUM([Net Rate Share]) / SUM([Turnover (LCY)])
         END                                [Net Rate Share Ratio]
       , SUM([Net Rate Share])              [Net Rate Share]
       , SUM([Non Commissionables])         [Non Commissionables]
       , SUM([Commissionable Turnover])     [Commissionable Turnover]
       , CASE WHEN SUM([Commissionable Turnover]) = 0 THEN 0 ELSE 
         SUM([Amount (LCY) (corr_)]) 
       / SUM([Commissionable Turnover]) END [Average Commission Rate]
    FROM Summary
GROUP BY [Travelagency No_]
       , [Reservation Source]
)
SELECT AP.[Name] [Company-Name], AP.[IATA], AP.[Amadeus No_],S.*, HI.* 
  FROM Sums S, [Travelagency] AP, HeaderInfo HI
 WHERE AP.[No_] = S.[Travelagency No_]
ORDER BY S.[Travelagency No_]'

PRINT (SUBSTRING(@SQL,1,8000))
PRINT (SUBSTRING(@SQL,8001,8000))
PRINT (SUBSTRING(@SQL,16001,8000))
PRINT (SUBSTRING(@SQL,24001,8000))
PRINT @PrintNet
EXEC(@SQL) 
END

GO
