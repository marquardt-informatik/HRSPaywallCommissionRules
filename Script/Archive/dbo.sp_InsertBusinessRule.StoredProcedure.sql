USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertBusinessRule]    Script Date: 10.04.2024 14:31:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Thomas Marquardt
-- Create date: 18.05.20
-- Description:	Erzeugt neue Regeln zum einfachen Einfügen über Excel
--
/*
-- SoC
DECLARE     
    @pHotel                 varchar(10) = '100572'
  , @pCompanyNo             varchar(20) = '31702'
  , @pCommissionType        int = 1 -- 0:Standard, 1:Firmenraten, 2:Andere
  , @pRatePlanCode          varchar(10) = 'GOV'
  , @pAgencyCalcFuncCode    varchar(10) = '8' -- 1:Percent, 2:Fix, 3:Percent+Fix, ..., 8:Percent net lodging, ... , 10:Percent net Sales, ... , 20:TAF per Stay, 21:TAF per Roomnight (limited)
  , @pAgencyValuePercentage decimal(38,20) = 10
  , @pMode                  tinyint = 5 -- 0:execute, 1: Excel-Template, 2: Excel-Replace, 3: Parameter

  EXECUTE [dbo].[sp_InsertBusinessRule] @Hotel=@pHotel, @CompanyNo=@pCompanyNo, @CommissionType=@pCommissionType, @RatePlanCode=@pRatePlanCode, @AgencyCalcFuncCode=@pAgencyCalcFuncCode, @AgencyValuePercentage=@pAgencyValuePercentage, @Mode=@pMode

-- Derbysoft
  EXECUTE [dbo].[sp_InsertBusinessRule] @Chain='2689', @MuseID='DERBYSOFT', @RatePlanCode='HRQ', @ValidFrom='2020-01-01', @ValidTo='2099-12-31'
*/
-- =============================================
CREATE PROC [dbo].[sp_InsertBusinessRule] 
(
    @CountryCode           varchar(10) = ''
  , @Continent             varchar(10) = ''
  , @MuseID                varchar(10) = ''
  , @Chain                 varchar(10) = ''
  , @Brand                 varchar(10) = ''
  , @Hotel                 varchar(10) = ''
  , @Partner               varchar(20) = ''
  , @CompanyNo             varchar(20) = ''
  , @ContractStatus        varchar(30) = ''
  , @DateOfReference       int = 0 -- 0:Abreisedatum, 1:Reservierungsdatum
  , @Category              int = 0 -- 0:<leer>, 1:Normal, 2:Group, 3:Meeting
  , @Segment               int = 0 -- 0:<leer>, 1:Corporate unmanaged, 2:Leisure, 3:Corporate managed commissionable, 4:Corporate managed net, 5:MICE
  , @CommissionType        int = 0 -- 0:Standard, 1:Firmenraten, 2:Andere
  , @GTCStatus             int = 0 -- 0:<leer>, 1:abgeleht, 2:zugestimmt
  , @RateType              varchar(10) = ''
  , @RatePlanCode          varchar(10) = ''
  , @CorporateRateDiscount int = 0
  , @Multisource           tinyint = 0
  , @ValidFrom             datetime = '2000-01-01'
  , @ValidTo               datetime = '2099-12-31'
  , @AgencyCalcFuncCode    varchar(10) = '' -- 1:Percent, 2:Fix, 3:Percent+Fix, ... , 20:TAF per Stay, 21:TAF per Roomnight (limited)
  , @AgencyValuePercentage decimal(38,20) = 0
  , @AgencyValueAmount     decimal(38,20) = 0
  , @AgencyCurrencyCode    varchar(10) = ''
  , @TAFCalcFuncCode       varchar(10) = '' -- 1:Percent, 2:Fix, 3:Percent+Fix, ... , 20:TAF per Stay, 21:TAF per Roomnight (limited)
  , @TAFValuePercentage    decimal(38,20) = 0
  , @TAFValueAmount        decimal(38,20) = 0
  , @TAFCurrencyCode       varchar(10) = ''
  , @TAFLimit              decimal(38,20) = 0
  , @NAVCompany            varchar(35) = 'HRS'
  , @Mode                  tinyint = 0 -- 0:execute, 1: Excel-Template, 2: Excel-Replace, 3: Parameter
  , @Action                tinyint = 0 -- 0:insert/update, 1:delete(deactivate)
)
AS BEGIN

-- Declarations
  DECLARE @Code                    varchar(20) = null
		, @ContractGrpCode         varchar(20) = ''
		, @ContractCode            varchar(20) = null
		, @OldContractCode         varchar(20) = null
		, @Enabled                 tinyint = null
		, @Approved                tinyint = null
		, @InsertedAt              datetime = GETDATE()
		, @InsertedByUser          varchar(20) = 'SQL'
		, @ModifiedAt              datetime = GETDATE()
		, @ModifiedByUser          varchar(20) = 'SQL'
		, @OldCode                 int = 0
		, @DB2Rule                 tinyint = 0
		, @Preferred               tinyint = 0
		, @ParentBusinessRule      varchar(20)=''
		, @timestampSource         datetime = '1973-01-01'
		, @SearchorderNo           int = null
		, @ContractCodeWOBreakfast varchar(20) = ''
		, @ContractCodeNetSales    varchar(20) = ''
		, @ContractCodeNetLogis    varchar(20) = ''
		, @TAFContractCode         varchar(20) = null
		, @OldTAFContractCode      varchar(20) = null
		, @Owner                   varchar(10) = ''
		, @RuleUpdate              tinyint = 0
		, @StrEmpty                varchar(20) = '<empty>'
		, @NoSeriesContract        varchar(20) = null
		, @NoSeriesBusinessRule    varchar(20) = null

--@SearchorderNo
  IF @NAVCompany='HRS'
    SELECT @NoSeriesContract = [Contract Nos_], @NoSeriesBusinessRule = [Business Rules Nos_] FROM [HRS$Agency Setup]
  IF @NAVCompany='HRS-CN'
    SELECT @NoSeriesContract = [Contract Nos_], @NoSeriesBusinessRule = [Business Rules Nos_] FROM [HRS-CN$Agency Setup]
  IF @NAVCompany='HRS-BR'
    SELECT @NoSeriesContract = [Contract Nos_], @NoSeriesBusinessRule = [Business Rules Nos_] FROM [HRS-BR$Agency Setup]

--@SearchorderNo
  IF @NAVCompany='HRS'
   SELECT @SearchorderNo =[No_] 
     FROM [HRS$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
    WHERE [Date of Reference Filter] = @DateOfReference
      AND [Category Filter] = CASE WHEN @Category<>0 THEN 1 ELSE 0 END
      AND [Client Filter] = CASE WHEN @Partner<>'' THEN 1 ELSE 0 END
      AND [Hotel Filter] = CASE WHEN @Hotel<>'' THEN 1 ELSE 0 END
      AND [Contract Status Filter] = CASE WHEN @ContractStatus<>'' THEN 1 ELSE 0 END
      AND [Brand Filter] = CASE WHEN @Brand<>'' THEN 1 ELSE 0 END
      AND [Chain Filter] = CASE WHEN @Chain<>'' THEN 1 ELSE 0 END
      AND [MuseID Filter] = CASE WHEN @MuseID<>'' THEN 1 ELSE 0 END
      AND [Country Filter] = CASE WHEN @CountryCode<>'' THEN 1 ELSE 0 END
      AND [Continent Filter] = CASE WHEN @Continent<>'' THEN 1 ELSE 0 END
      AND [Commission Type Filter] = CASE WHEN @CommissionType<>0 THEN 1 ELSE 0 END
      AND [GTC Rejected Filter] = CASE WHEN @GTCStatus<>0 THEN 1 ELSE 0 END
      AND [Segment Filter] = CASE WHEN @Segment<>0 THEN 1 ELSE 0 END
      AND [Company Filter] = CASE WHEN @CompanyNo<>'' THEN 1 ELSE 0 END
      AND [Rate Type Filter] = CASE WHEN @RateType<>'' THEN 1 ELSE 0 END
      AND [Corporate Rate Discount Filter] = CASE WHEN @CorporateRateDiscount<>0 THEN 1 ELSE 0 END
      AND [Multisource] = @Multisource
      AND [Rate Plan Code Filter] = CASE WHEN @RatePlanCode<>'' THEN 1 ELSE 0 END
  IF @NAVCompany='HRS-CN'
   SELECT @SearchorderNo =[No_] 
     FROM [HRS-CN$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
    WHERE [Date of Reference Filter] = @DateOfReference
      AND [Category Filter] = CASE WHEN @Category<>0 THEN 1 ELSE 0 END
      AND [Client Filter] = CASE WHEN @Partner<>'' THEN 1 ELSE 0 END
      AND [Hotel Filter] = CASE WHEN @Hotel<>'' THEN 1 ELSE 0 END
      AND [Contract Status Filter] = CASE WHEN @ContractStatus<>'' THEN 1 ELSE 0 END
      AND [Brand Filter] = CASE WHEN @Brand<>'' THEN 1 ELSE 0 END
      AND [Chain Filter] = CASE WHEN @Chain<>'' THEN 1 ELSE 0 END
      AND [MuseID Filter] = CASE WHEN @MuseID<>'' THEN 1 ELSE 0 END
      AND [Country Filter] = CASE WHEN @CountryCode<>'' THEN 1 ELSE 0 END
      AND [Continent Filter] = CASE WHEN @Continent<>'' THEN 1 ELSE 0 END
      AND [Commission Type Filter] = CASE WHEN @CommissionType<>0 THEN 1 ELSE 0 END
      AND [GTC Rejected Filter] = CASE WHEN @GTCStatus<>0 THEN 1 ELSE 0 END
      AND [Segment Filter] = CASE WHEN @Segment<>0 THEN 1 ELSE 0 END
      AND [Company Filter] = CASE WHEN @CompanyNo<>'' THEN 1 ELSE 0 END
      AND [Rate Type Filter] = CASE WHEN @RateType<>'' THEN 1 ELSE 0 END
      AND [Corporate Rate Discount Filter] = CASE WHEN @CorporateRateDiscount<>0 THEN 1 ELSE 0 END
      AND [Multisource] = @Multisource
      AND [Rate Plan Code Filter] = CASE WHEN @RatePlanCode<>'' THEN 1 ELSE 0 END
  IF @NAVCompany='HRS-BR'
   SELECT @SearchorderNo =[No_] 
     FROM [HRS-BR$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
    WHERE [Date of Reference Filter] = @DateOfReference
      AND [Category Filter] = CASE WHEN @Category<>0 THEN 1 ELSE 0 END
      AND [Client Filter] = CASE WHEN @Partner<>'' THEN 1 ELSE 0 END
      AND [Hotel Filter] = CASE WHEN @Hotel<>'' THEN 1 ELSE 0 END
      AND [Contract Status Filter] = CASE WHEN @ContractStatus<>'' THEN 1 ELSE 0 END
      AND [Brand Filter] = CASE WHEN @Brand<>'' THEN 1 ELSE 0 END
      AND [Chain Filter] = CASE WHEN @Chain<>'' THEN 1 ELSE 0 END
      AND [MuseID Filter] = CASE WHEN @MuseID<>'' THEN 1 ELSE 0 END
      AND [Country Filter] = CASE WHEN @CountryCode<>'' THEN 1 ELSE 0 END
      AND [Continent Filter] = CASE WHEN @Continent<>'' THEN 1 ELSE 0 END
      AND [Commission Type Filter] = CASE WHEN @CommissionType<>0 THEN 1 ELSE 0 END
      AND [GTC Rejected Filter] = CASE WHEN @GTCStatus<>0 THEN 1 ELSE 0 END
      AND [Segment Filter] = CASE WHEN @Segment<>0 THEN 1 ELSE 0 END
      AND [Company Filter] = CASE WHEN @CompanyNo<>'' THEN 1 ELSE 0 END
      AND [Rate Type Filter] = CASE WHEN @RateType<>'' THEN 1 ELSE 0 END
      AND [Corporate Rate Discount Filter] = CASE WHEN @CorporateRateDiscount<>0 THEN 1 ELSE 0 END
      AND [Multisource] = @Multisource
      AND [Rate Plan Code Filter] = CASE WHEN @RatePlanCode<>'' THEN 1 ELSE 0 END

--@Code, @Enabled, @Approved
  IF @NAVCompany='HRS'   
   SELECT @Code = [Code], @Enabled = [Enabled], @Approved = [Approved]
     FROM [HRS$Agency Business Rules] BR WITH (NOLOCK)
     JOIN [HRS$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK) ON BR.[Searchorder No_]= SO.[No_]
	WHERE [Searchorder No_] = @SearchorderNo
	  AND [Valid from]=@ValidFrom
	  AND [Valid to]=@ValidTo
	  AND ([Date of Reference]       = @DateOfReference       OR [Date of Reference Filter]       = 0)
      AND ([Category]                = @Category              OR [Category Filter]                = 0)
      AND ([Partner No_]             = @Partner               OR [Client Filter]                  = 0)
      AND ([Hotel No_]               = @Hotel                 OR [Hotel Filter]                   = 0)
      AND ([Contract Status]         = @ContractStatus        OR [Contract Status Filter]         = 0)
      AND ([Brand]                   = @Brand                 OR [Brand Filter]                   = 0)
      AND ([Chain]                   = @Chain                 OR [Chain Filter]                   = 0)
      AND ([MuseID]                  = @MuseID                OR [MuseID Filter]                  = 0)
      AND ([Country Code]            = @CountryCode           OR [Country Filter]                 = 0)
      AND ([Continent]               = @Continent             OR [Continent Filter]               = 0)
      AND ([Commission Type]         = @CommissionType        OR [Commission Type Filter]         = 0)
      AND ([GTC Status]              = @GTCStatus             OR [GTC Rejected Filter]            = 0)
      AND ([Segment]                 = @Segment               OR [Segment Filter]                 = 0)
      AND ([Company No_]             = @CompanyNo             OR [Company Filter]                 = 0)
      AND ([Rate Type]               = @RateType              OR [Rate Type Filter]               = 0)
      AND ([Corporate Rate Discount] = @CorporateRateDiscount OR [Corporate Rate Discount Filter] = 0)
      AND ([Rate Plan Code]          = @RatePlanCode          OR [Rate Plan Code Filter]          = 0)
  IF @NAVCompany='HRS-CN'   
   SELECT @Code = [Code], @Enabled = [Enabled], @Approved = [Approved]
     FROM [HRS-CN$Agency Business Rules] BR WITH (NOLOCK)
     JOIN [HRS-CN$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK) ON BR.[Searchorder No_]= SO.[No_]
	WHERE [Searchorder No_] = @SearchorderNo
	  AND [Valid from]=@ValidFrom
	  AND [Valid to]=@ValidTo
	  AND ([Date of Reference]       = @DateOfReference       OR [Date of Reference Filter]       = 0)
      AND ([Category]                = @Category              OR [Category Filter]                = 0)
      AND ([Partner No_]             = @Partner               OR [Client Filter]                  = 0)
      AND ([Hotel No_]               = @Hotel                 OR [Hotel Filter]                   = 0)
      AND ([Contract Status]         = @ContractStatus        OR [Contract Status Filter]         = 0)
      AND ([Brand]                   = @Brand                 OR [Brand Filter]                   = 0)
      AND ([Chain]                   = @Chain                 OR [Chain Filter]                   = 0)
      AND ([MuseID]                  = @MuseID                OR [MuseID Filter]                  = 0)
      AND ([Country Code]            = @CountryCode           OR [Country Filter]                 = 0)
      AND ([Continent]               = @Continent             OR [Continent Filter]               = 0)
      AND ([Commission Type]         = @CommissionType        OR [Commission Type Filter]         = 0)
      AND ([GTC Status]              = @GTCStatus             OR [GTC Rejected Filter]            = 0)
      AND ([Segment]                 = @Segment               OR [Segment Filter]                 = 0)
      AND ([Company No_]             = @CompanyNo             OR [Company Filter]                 = 0)
      AND ([Rate Type]               = @RateType              OR [Rate Type Filter]               = 0)
      AND ([Corporate Rate Discount] = @CorporateRateDiscount OR [Corporate Rate Discount Filter] = 0)
      AND ([Rate Plan Code]          = @RatePlanCode          OR [Rate Plan Code Filter]          = 0)
  IF @NAVCompany='HRS-BR'   
   SELECT @Code = [Code], @Enabled = [Enabled], @Approved = [Approved]
     FROM [HRS-BR$Agency Business Rules] BR WITH (NOLOCK)
     JOIN [HRS-BR$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK) ON BR.[Searchorder No_]= SO.[No_]
	WHERE [Searchorder No_] = @SearchorderNo
	  AND [Valid from]=@ValidFrom
	  AND [Valid to]=@ValidTo
	  AND ([Date of Reference]       = @DateOfReference       OR [Date of Reference Filter]       = 0)
      AND ([Category]                = @Category              OR [Category Filter]                = 0)
      AND ([Partner No_]             = @Partner               OR [Client Filter]                  = 0)
      AND ([Hotel No_]               = @Hotel                 OR [Hotel Filter]                   = 0)
      AND ([Contract Status]         = @ContractStatus        OR [Contract Status Filter]         = 0)
      AND ([Brand]                   = @Brand                 OR [Brand Filter]                   = 0)
      AND ([Chain]                   = @Chain                 OR [Chain Filter]                   = 0)
      AND ([MuseID]                  = @MuseID                OR [MuseID Filter]                  = 0)
      AND ([Country Code]            = @CountryCode           OR [Country Filter]                 = 0)
      AND ([Continent]               = @Continent             OR [Continent Filter]               = 0)
      AND ([Commission Type]         = @CommissionType        OR [Commission Type Filter]         = 0)
      AND ([GTC Status]              = @GTCStatus             OR [GTC Rejected Filter]            = 0)
      AND ([Segment]                 = @Segment               OR [Segment Filter]                 = 0)
      AND ([Company No_]             = @CompanyNo             OR [Company Filter]                 = 0)
      AND ([Rate Type]               = @RateType              OR [Rate Type Filter]               = 0)
      AND ([Corporate Rate Discount] = @CorporateRateDiscount OR [Corporate Rate Discount Filter] = 0)
      AND ([Rate Plan Code]          = @RatePlanCode          OR [Rate Plan Code Filter]          = 0)

-- @AgencyCalcFuncCode 
  IF @NAVCompany='HRS'
SELECT TOP 1 @AgencyCalcFuncCode = CASE WHEN @AgencyCalcFuncCode='' THEN AC.[Contract Calc_ Func_ Code] ELSE @AgencyCalcFuncCode END
  FROM [HRS$Agency Bus_ Rules Searchorder] SO WITH (NOLOCK)
  JOIN [HRS$Agency Business Rules] BR WITH (NOLOCK)
    ON BR.[Searchorder No_] = SO.[No_]
  JOIN [HRS$Customer] CU WITH (NOLOCK)
    ON ((SO.[Chain Filter] = 1 AND BR.[Chain] = CU.[Chain]) OR SO.[Chain Filter] = 0)
   AND ((SO.[Brand Filter] = 1 AND BR.[Brand] = CU.[Brand]) OR SO.[Brand Filter] = 0)
   AND ((SO.[Country Filter] = 1 AND BR.[Country Code] = CU.[Country_Region Code]) OR SO.[Country Filter] = 0)
   AND ((SO.[Hotel Filter] = 1 AND BR.[Hotel No_] = CU.[No_]) OR SO.[Hotel Filter] = 0)
  JOIN [HRS$Agency Contract] AC WITH (NOLOCK)
    ON BR.[Contract Code] = AC.[Code]
 WHERE NOT SO.[No_] IN (131,132,133,134)
   AND BR.[TAF Contract Code]=''
   AND SO.[Rate Type Filter]=0
   AND SO.[Segment Filter]=0
   AND SO.[Corporate Rate Discount Filter]=0
   AND SO.[Commission Type Filter]=0
   AND SO.[Multisource]=0
   AND SO.[Rate Plan Code Filter]=0
   AND SO.[Client Filter]=0
   AND SO.[Company Filter]=0
   AND SO.[MuseID Filter]=0
   AND SO.[Category Filter]=0
   --AND SO.[Hotel Filter]=0
   AND CU.[No_] = @Hotel
ORDER BY SO.[Sortorder No_] DESC

-- @OldContractCode
  IF @NAVCompany='HRS' 
    SELECT @OldContractCode = [Contract Code], @OldTAFContractCode = [TAF Contract Code] FROM [HRS$Agency Business Rules] WITH (NOLOCK) WHERE [Code] = @Code
  IF @NAVCompany='HRS-CN'
    SELECT @OldContractCode = [Contract Code], @OldTAFContractCode = [TAF Contract Code] FROM [HRS-CN$Agency Business Rules] WITH (NOLOCK) WHERE [Code] = @Code
  IF @NAVCompany='HRS-BR'
    SELECT @OldContractCode = [Contract Code], @OldTAFContractCode = [TAF Contract Code] FROM [HRS-BR$Agency Business Rules] WITH (NOLOCK) WHERE [Code] = @Code

--@ContractCode
  IF @NAVCompany='HRS'
    SELECT TOP(1) @ContractCode = [Code] 
	  FROM [HRS$Agency Contract] AC WITH (NOLOCK)
     WHERE AC.[Contract Calc_ Func_ Code] = @AgencyCalcFuncCode
	   AND AC.[Value %] = @AgencyValuePercentage
	   AND AC.[Value Total (LCY)] = @AgencyValueAmount
       AND [Locked] = 0
       AND [Type] = 0
  ORDER BY [Code] ASC
  IF @NAVCompany='HRS-CN'
    SELECT TOP(1) @ContractCode = [Code] 
	  FROM [HRS-CN$Agency Contract] AC WITH (NOLOCK)
     WHERE AC.[Contract Calc_ Func_ Code] = @AgencyCalcFuncCode
	   AND AC.[Value %] = @AgencyValuePercentage
	   AND AC.[Value Total (LCY)] = @AgencyValueAmount
       AND [Locked] = 0
       AND [Type] = 0
  ORDER BY [Code] ASC
  IF @NAVCompany='HRS-BR'
    SELECT TOP(1) @ContractCode = [Code]
	  FROM [HRS-BR$Agency Contract] AC WITH (NOLOCK)
     WHERE AC.[Contract Calc_ Func_ Code] = @AgencyCalcFuncCode
	   AND AC.[Value %] = @AgencyValuePercentage
	   AND AC.[Value Total (LCY)] = @AgencyValueAmount
       AND [Locked] = 0
       AND [Type] = 0
  ORDER BY [Code] ASC

--@TAFContractCode
  IF @NAVCompany='HRS'
    SELECT TOP(1) @TAFContractCode = [Code] 
	  FROM [HRS$Agency Contract] AC WITH (NOLOCK)
     WHERE AC.[Contract Calc_ Func_ Code] = @TAFCalcFuncCode
	   AND AC.[Value %] = @TAFValuePercentage
	   AND AC.[Value Total (LCY)] = @TAFValueAmount
       AND [Locked] = 0
       AND [Type] = 0
	   AND [Limit] = @TAFLimit
  ORDER BY [Code] ASC
  IF @NAVCompany='HRS-CN'
    SELECT TOP(1) @TAFContractCode = [Code] 
	  FROM [HRS-CN$Agency Contract] AC WITH (NOLOCK)
     WHERE AC.[Contract Calc_ Func_ Code] = @TAFCalcFuncCode
	   AND AC.[Value %] = @TAFValuePercentage
	   AND AC.[Value Total (LCY)] = @TAFValueAmount
       AND [Locked] = 0
       AND [Type] = 0
	   AND [Limit] = @TAFLimit
  ORDER BY [Code] ASC
  IF @NAVCompany='HRS-BR'
    SELECT TOP(1) @TAFContractCode = [Code] 
	  FROM [HRS-BR$Agency Contract] AC WITH (NOLOCK)
     WHERE AC.[Contract Calc_ Func_ Code] = @TAFCalcFuncCode
	   AND AC.[Value %] = @TAFValuePercentage
	   AND AC.[Value Total (LCY)] = @TAFValueAmount
       AND [Locked] = 0
       AND [Type] = 0
	   AND [Limit] = @TAFLimit
  ORDER BY [Code] ASC

--normalize values
  SELECT @Code                  = COALESCE(@Code,@StrEmpty)
       , @Enabled               = COALESCE(@Enabled,0)
	   , @Approved              = COALESCE(@Approved,0)
	   , @OldContractCode       = COALESCE(@OldContractCode,@StrEmpty)
	   , @ContractCode          = COALESCE(@ContractCode,@StrEmpty)
	   , @CountryCode           = COALESCE(@CountryCode,@StrEmpty)
	   , @Chain                 = COALESCE(@Chain,@StrEmpty)
	   , @Brand                 = COALESCE(@Brand,@StrEmpty)
	   , @Partner               = COALESCE(@Partner,@StrEmpty)
	   , @ContractStatus        = COALESCE(@ContractStatus,@StrEmpty)
	   , @InsertedByUser        = COALESCE(@InsertedByUser,@StrEmpty)
	   , @InsertedAt            = COALESCE(@InsertedAt,GETDATE())
	   , @ModifiedByUser        = COALESCE(@ModifiedByUser,@StrEmpty)
	   , @ModifiedAt            = COALESCE(@ModifiedAt,GETDATE())
	   , @Hotel                 = COALESCE(@Hotel,@StrEmpty)
	   , @Continent             = COALESCE(@Continent,@StrEmpty)
	   , @DateOfReference       = COALESCE(@DateOfReference,0)
	   , @Category              = COALESCE(@Category,0)
	   , @MuseID                = COALESCE(@MuseID,@StrEmpty)
	   , @CompanyNo             = COALESCE(@CompanyNo,@StrEmpty)
	   , @RateType              = COALESCE(@RateType,@StrEmpty)
	   , @CorporateRateDiscount = COALESCE(@CorporateRateDiscount,0)
	   , @Segment               = COALESCE(@Segment,0)
	   , @CommissionType        = COALESCE(@CommissionType,0)
	   , @TAFContractCode       = COALESCE(@TAFContractCode,@StrEmpty)
	   , @OldTAFContractCode    = COALESCE(@OldTAFContractCode,@StrEmpty)
	   , @GTCStatus             = COALESCE(@GTCStatus,0)
	   , @RatePlanCode          = COALESCE(@RatePlanCode,@StrEmpty)

--create new @ContractCode
  IF @AgencyCalcFuncCode=''
    SET @ContractCode = ''
  IF @ContractCode=@StrEmpty
  BEGIN
    IF @NAVCompany='HRS'
	BEGIN
	  SELECT @ContractCode = [Last No_ Used] FROM [HRS$No_ Series Line] WHERE [Series Code]=@NoSeriesContract AND [Open]=1
      SELECT @ContractCode = 'C'+RIGHT('000000000'+CAST(CAST(REPLACE(@ContractCode,'C','') AS INT)+1 AS varchar(20)),LEN(@ContractCode)-1)

	   BEGIN TRY
	     BEGIN TRAN
           INSERT INTO [HRS$Agency Contract]([Code],[Type],[Description],[Model],[Value %],[Value Total (LCY)],[Contract Calc_ Func_ Code],[Valid from],[Locked],[User ID],[No_ Series],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Currency Code],[Limit])
           SELECT @ContractCode,0,FC.[Description],CASE WHEN @AgencyCalcFuncCode IN ('1','10','3','4','5','7','8','9') THEN 0 ELSE 1 END,@AgencyValuePercentage,@AgencyValueAmount,@AgencyCalcFuncCode,@ValidFrom,0,'',@NoSeriesContract,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,'',0
             FROM [HRS$Agency Contract Calc_ Function] FC WHERE FC.[Code]=@AgencyCalcFuncCode

           UPDATE [HRS$No_ Series Line] SET [Last No_ Used] = @ContractCode, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesContract AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
       END CATCH
	END
    IF @NAVCompany='HRS-CN'
	BEGIN
	  SELECT @ContractCode = [Last No_ Used] FROM [HRS-CN$No_ Series Line] WHERE [Series Code]=@NoSeriesContract AND [Open]=1
      SELECT @ContractCode = 'C'+RIGHT('000000000'+CAST(CAST(REPLACE(@ContractCode,'C','') AS INT)+1 AS varchar(20)),LEN(@ContractCode)-1)

	   BEGIN TRY
	     BEGIN TRAN
           INSERT INTO [HRS-CN$Agency Contract]([Code],[Type],[Description],[Model],[Value %],[Value Total (LCY)],[Contract Calc_ Func_ Code],[Valid from],[Locked],[User ID],[No_ Series],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Currency Code],[Limit])
           SELECT @ContractCode,0,FC.[Description],CASE WHEN @AgencyCalcFuncCode IN ('1','10','3','4','5','7','8','9') THEN 0 ELSE 1 END,@AgencyValuePercentage,@AgencyValueAmount,@AgencyCalcFuncCode,@ValidFrom,0,'',@NoSeriesContract,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,'',0
             FROM [HRS-CN$Agency Contract Calc_ Function] FC WHERE FC.[Code]=@AgencyCalcFuncCode

           UPDATE [HRS-CN$No_ Series Line] SET [Last No_ Used] = @ContractCode, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesContract AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
       END CATCH
	END
    IF @NAVCompany='HRS-BR'
	BEGIN
	  SELECT @ContractCode = [Last No_ Used] FROM [HRS-BR$No_ Series Line] WHERE [Series Code]=@NoSeriesContract AND [Open]=1
      SELECT @ContractCode = 'C'+RIGHT('000000000'+CAST(CAST(REPLACE(@ContractCode,'C','') AS INT)+1 AS varchar(20)),LEN(@ContractCode)-1)

	   BEGIN TRY
	     BEGIN TRAN
           INSERT INTO [HRS-BR$Agency Contract]([Code],[Type],[Description],[Model],[Value %],[Value Total (LCY)],[Contract Calc_ Func_ Code],[Valid from],[Locked],[User ID],[No_ Series],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Currency Code],[Limit])
           SELECT @ContractCode,0,FC.[Description],CASE WHEN @AgencyCalcFuncCode IN ('1','10','3','4','5','7','8','9') THEN 0 ELSE 1 END,@AgencyValuePercentage,@AgencyValueAmount,@AgencyCalcFuncCode,@ValidFrom,0,'',@NoSeriesContract,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,'',0
             FROM [HRS-BR$Agency Contract Calc_ Function] FC WHERE FC.[Code]=@AgencyCalcFuncCode

           UPDATE [HRS-BR$No_ Series Line] SET [Last No_ Used] = @ContractCode, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesContract AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
       END CATCH
	END
  END

--create new @ContractCode
  IF @TAFCalcFuncCode=''
    SET @TAFContractCode = ''
  IF @TAFContractCode=@StrEmpty
  BEGIN
    IF @NAVCompany='HRS'
	BEGIN
	  SELECT @TAFContractCode = [Last No_ Used] FROM [HRS$No_ Series Line] WHERE [Series Code]=@NoSeriesContract AND [Open]=1
      SELECT @TAFContractCode = 'C'+RIGHT('000000000'+CAST(CAST(REPLACE(@TAFContractCode,'C','') AS INT)+1 AS varchar(20)),LEN(@TAFContractCode)-1)

	   BEGIN TRY
	     BEGIN TRAN
           INSERT INTO [HRS$Agency Contract]([Code],[Type],[Description],[Model],[Value %],[Value Total (LCY)],[Contract Calc_ Func_ Code],[Valid from],[Locked],[User ID],[No_ Series],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Currency Code],[Limit])
           SELECT @TAFContractCode,0,FC.[Description],CASE WHEN @TAFCalcFuncCode IN ('1','10','3','4','5','7','8','9') THEN 0 ELSE 1 END,@TAFValuePercentage,@TAFValueAmount,@TAFCalcFuncCode,@ValidFrom,0,'',@NoSeriesContract,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,@TAFCurrencyCode,@TAFLimit
             FROM [HRS$Agency Contract Calc_ Function] FC WHERE FC.[Code]=@TAFCalcFuncCode

           UPDATE [HRS$No_ Series Line] SET [Last No_ Used] = @TAFContractCode, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesContract AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
       END CATCH
	END
    IF @NAVCompany='HRS-CN'
	BEGIN
	  SELECT @TAFContractCode = [Last No_ Used] FROM [HRS-CN$No_ Series Line] WHERE [Series Code]=@NoSeriesContract AND [Open]=1
      SELECT @TAFContractCode = 'C'+RIGHT('000000000'+CAST(CAST(REPLACE(@TAFContractCode,'C','') AS INT)+1 AS varchar(20)),LEN(@TAFContractCode)-1)

	   BEGIN TRY
	     BEGIN TRAN
           INSERT INTO [HRS-CN$Agency Contract]([Code],[Type],[Description],[Model],[Value %],[Value Total (LCY)],[Contract Calc_ Func_ Code],[Valid from],[Locked],[User ID],[No_ Series],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Currency Code],[Limit])
           SELECT @TAFContractCode,0,FC.[Description],CASE WHEN @TAFCalcFuncCode IN ('1','10','3','4','5','7','8','9') THEN 0 ELSE 1 END,@TAFValuePercentage,@TAFValueAmount,@TAFCalcFuncCode,@ValidFrom,0,'',@NoSeriesContract,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,@TAFCurrencyCode,@TAFLimit
             FROM [HRS-CN$Agency Contract Calc_ Function] FC WHERE FC.[Code]=@TAFCalcFuncCode

           UPDATE [HRS-CN$No_ Series Line] SET [Last No_ Used] = @TAFContractCode, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesContract AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
       END CATCH
	END
    IF @NAVCompany='HRS-BR'
	BEGIN
	  SELECT @TAFContractCode = [Last No_ Used] FROM [HRS-BR$No_ Series Line] WHERE [Series Code]=@NoSeriesContract AND [Open]=1
      SELECT @TAFContractCode = 'C'+RIGHT('000000000'+CAST(CAST(REPLACE(@TAFContractCode,'C','') AS INT)+1 AS varchar(20)),LEN(@TAFContractCode)-1)

	   BEGIN TRY
	     BEGIN TRAN
           INSERT INTO [HRS-BR$Agency Contract]([Code],[Type],[Description],[Model],[Value %],[Value Total (LCY)],[Contract Calc_ Func_ Code],[Valid from],[Locked],[User ID],[No_ Series],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Currency Code],[Limit])
           SELECT @TAFContractCode,0,FC.[Description],CASE WHEN @TAFCalcFuncCode IN ('1','10','3','4','5','7','8','9') THEN 0 ELSE 1 END,@TAFValuePercentage,@TAFValueAmount,@TAFCalcFuncCode,@ValidFrom,0,'',@NoSeriesContract,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,@TAFCurrencyCode,@TAFLimit
             FROM [HRS-BR$Agency Contract Calc_ Function] FC WHERE FC.[Code]=@TAFCalcFuncCode

           UPDATE [HRS-BR$No_ Series Line] SET [Last No_ Used] = @TAFContractCode, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesContract AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
       END CATCH
	END
  END

-- create new Business
  IF @Mode=0
  BEGIN
    IF @NAVCompany='HRS'
    BEGIN
	  IF @Code IS NULL
	  BEGIN
	    UPDATE [HRS$Agency Business Rules] SET 
		       [Contract Code] = @ContractCode
             , [TAF Contract Code] = @TAFContractCode 
			 , [Valid from] = @ValidFrom
			 , [Valid to] = @ValidTo
         WHERE [Code] = @Code
		   AND ([Contract Code] <> @ContractCode
            OR [TAF Contract Code] <> @TAFContractCode 
			OR [Valid from] <> @ValidFrom
			OR [Valid to] <> @ValidTo)
	  END
	  ELSE
	  BEGIN
	   BEGIN TRY
	     BEGIN TRAN
           SELECT @Code = [Last No_ Used] FROM [HRS$No_ Series Line] WHERE [Series Code]=@NoSeriesBusinessRule AND [Open]=1
           SELECT @Code = RIGHT('000000000'+CAST(CAST(@Code AS INT)+1 AS varchar(20)),LEN(@Code))

           INSERT INTO [dbo].[HRS$Agency Business Rules]([Accounting Interval],[Starting Date],[Code],[Type],[Country Code],[Chain],[Brand],[Owner],[Partner No_],[Contract Status],[Contract Grp_ Code],[Contract Code],[Valid from],[Valid to],[Enabled],[Approved],[Inserted by User],[Inserted at],[Modified by User],[Modified at],[Hotel No_],[Old Code],[Continent],[Date of Reference],[Category],[MuseID],[Parent Business Rule Code],[Searchorder No_],[DB2 Rule],[timestamp Source],[Company No_],[Preferred],[Rate Type],[Corporate Rate Discount],[Contract Code w_o Breakfast],[Contract Code Net Sales],[Contract Code Net Logis],[Segment],[Commission Type],[TAF Contract Code],[GTC Status],[Rate Plan Code],[Differing Customer No_],[Product],[Source Class])
           VALUES (0,'1753-01-01',@Code,0,@CountryCode,@Chain,@Brand,@Owner,@Partner,@ContractStatus,@ContractGrpCode,@ContractCode,@ValidFrom,@ValidTo,1,1,@InsertedByUser,@InsertedAt,@ModifiedByUser,@ModifiedAt,@Hotel,@OldCode,@Continent,@DateOfReference,@Category,@MuseID,@ParentBusinessRule,@SearchorderNo,@DB2Rule,@timestampSource,@CompanyNo,@Preferred,@RateType,@CorporateRateDiscount,@ContractCodeWOBreakfast,@ContractCodeNetSales,@ContractCodeNetLogis,@Segment,@CommissionType,@TAFContractCode,@GTCStatus,@RatePlanCode,'',0,0)
           UPDATE [HRS$No_ Series Line] SET [Last No_ Used] = @Code, [Last Date Used]= CONVERT(varchar(10),GETDATE(),20) WHERE [Series Code] = @NoSeriesBusinessRule AND [Open]=1
		 COMMIT TRAN
       END TRY
       BEGIN CATCH
         ROLLBACK TRAN
		 PRINT ERROR_MESSAGE()
       END CATCH
	  END
	END
  END

-- Example  
  IF @Mode=1
  BEGIN
    PRINT 'EXECUTE [dbo].[sp_InsertBusinessRule] '
	    + CHAR(13) + '    @Hotel=''' + '%1' + ''''
		+ CHAR(13) + '  , @CompanyNo=''' + '%2' + ''''
		+ CHAR(13) + '  , @CommissionType=' + '%3' 
		+ CHAR(13) + '  , @RatePlanCode=''' + '%4' + ''''
		+ CHAR(13) + '  , @AgencyCalcFuncCode=''' + '%5' + ''''
		+ CHAR(13) + '  , @AgencyValuePercentage=' + '%6'
		+ CHAR(13) + '  , @NAVCompany=''' + '%7' + ''''
		+ CHAR(13) + '  , @Mode=1'
  END

-- Debug Output
  IF (@Mode=5)-- OR (@Mode=0)
  BEGIN    
    PRINT '@NAVCompany            = ' + @NAVCompany
	PRINT '---------------------- = ----------------------'
    PRINT '@SearchorderNo         = ' + CAST(@SearchorderNo AS varchar(10))
    PRINT '@Code                  = ' + CAST(@Code          AS varchar(10))
	PRINT '@Enabled               = ' + CASE @Enabled  WHEN 1 THEN 'true' ELSE 'false' END
	PRINT '@Approved              = ' + CASE @Approved WHEN 1 THEN 'true' ELSE 'false' END
	PRINT '@OldContractCode       = ' + @OldContractCode
	PRINT '@ContractCode          = ' + @ContractCode
	PRINT '@AgencyCalcFuncCode    = ' + @AgencyCalcFuncCode
    PRINT '@OldTAFContractCode    = ' + @OldTAFContractCode
    PRINT '@TAFContractCode       = ' + @TAFContractCode
	PRINT '@TAFCalcFuncCode       = ' + @TAFCalcFuncCode
	PRINT '@ValidFrom             = ' + CONVERT(varchar(10),@ValidFrom,120)
    PRINT '@ValidTo               = ' + CONVERT(varchar(10),@ValidTo,120)
	PRINT '====================== = ======================'
    PRINT '@CountryCode           = ' + @CountryCode
    PRINT '@Chain                 = ' + @Chain
    PRINT '@Brand                 = ' + @Brand
    PRINT '@Partner               = ' + @Partner
    PRINT '@ContractStatus        = ' + @ContractStatus
    PRINT '@InsertedByUser        = ' + @InsertedByUser
    PRINT '@InsertedAt            = ' + CONVERT(varchar(10),@InsertedAt,120)
    PRINT '@ModifiedByUser        = ' + @ModifiedByUser
    PRINT '@ModifiedAt            = ' + CONVERT(varchar(10),@ModifiedAt,120)
    PRINT '@Hotel                 = ' + @Hotel
    PRINT '@Continent             = ' + @Continent
    PRINT '@DateOfReference       = ' + CAST(@DateOfReference AS varchar(10))
    PRINT '@Category              = ' + CAST(@Category AS varchar(10))
    PRINT '@MuseID                = ' + @MuseID
    PRINT '@CompanyNo             = ' + @CompanyNo
    PRINT '@RateType              = ' + @RateType
    PRINT '@CorporateRateDiscount = ' + CAST(@CorporateRateDiscount AS varchar(10))
    PRINT '@Segment               = ' + CAST(@Segment AS varchar(10))
    PRINT '@CommissionType        = ' + CAST(@CommissionType AS varchar(10))
    PRINT '@GTCStatus             = ' + CAST(@GTCStatus AS varchar(10))
    PRINT '@RatePlanCode          = ' + @RatePlanCode

  END
END
GO
