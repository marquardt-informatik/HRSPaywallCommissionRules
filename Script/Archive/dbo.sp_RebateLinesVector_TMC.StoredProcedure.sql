USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[sp_RebateLinesVector_TMC]    Script Date: 10.04.2024 14:31:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Ralph Prangenberg
-- Create date: 24.02.2015
-- Description:	Kopfinformationen zur Gutschriftsanzeige
--				Kopie von [sp_RebateLinesYTD]
--				Erweitert um TMC
/*
DECLARE @ReNr	VARCHAR(20) = 'K0000046919'
	  , @Tab	VARCHAR(3)	= 'OBE' --'ROW'--GDS' --'DACH'--'API' 
EXEC [dbo].[sp_RebateLinesVector_TMC] @ReNr , @Tab
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_RebateLinesVector_TMC] 
	@ReNr	VARCHAR(20)
  , @Tab	VARCHAR(30)
AS
BEGIN

	DECLARE @Feetype	VARCHAR(3)
	SELECT @Feetype = CASE	WHEN CHARINDEX(@Tab, 'API')  > 0 THEN 'API'
							WHEN CHARINDEX(@Tab, 'GDS')  > 0 THEN 'GDS'
							WHEN CHARINDEX(@Tab, 'DACH') > 0 THEN 'xRD'
							WHEN CHARINDEX(@Tab, 'ROW')  > 0 THEN 'xRR'
							WHEN CHARINDEX(@Tab, 'OBE')  > 0 THEN 'OBE'
					  END

	DECLARE @Vector AS TABLE
		( [Vector Code]				VARCHAR(100)
		, [ROWNUMBER]				INT
		, [Description]				VARCHAR(100)
		, [Value]					DECIMAL(38,2)
		, [Value Type]				INT
		)

	DECLARE @Result AS TABLE
		( [Input Value 1]			DECIMAL(38,2)
		, [ThresholdPartion]		DECIMAL(38,2)
		, [Threshold]				VARCHAR(100)
		, [ThresholdResult]			DECIMAL(38,2)
		, [ThresholdDescription]	VARCHAR(100)
		, [ROWNUMBER]				INT
		, [Value Type]				INT
		)
	
   INSERT INTO @Vector
		SELECT [RVR].[Vector Code]
			 , ROW_NUMBER() OVER (PARTITION BY [RVR].[Vector Code] ORDER BY CAST([RVR].[Value From] AS INTEGER)) AS ROWNUMBER
			 , [RVR].[Description]
			 , [RVR].[Value Decimal]
			 , [RV].[Value Type]
		 FROM [HRS$Rebate Vector Ranges]	[RVR] WITH (NOLOCK) 
		 JOIN [HRS$Rebate Vector]			[RV] WITH (NOLOCK) 
		   ON [RV].[Code] = [RVR].[Vector Code]
		WHERE [Vector Code] IN (SELECT DISTINCT [RAL].[Matrix _ Vector Code] 
								  FROM [HRS$Rebate Header]				[RH] WITH (NOLOCK) 
								  JOIN [HRS$Rebate Agreement Header]	[RAH] WITH (NOLOCK)
									ON [RH].[Rebate Agreement No_] = [RAH].[No_]	
								  JOIN [HRS$Rebate Agreement Line]		[RAL] WITH (NOLOCK)
								  	ON [RAH].[No_] = [RAL].[Rebate No_]
								 WHERE [RH].[No_]  = @ReNr
								   AND [RAL].[Activity Type] = 4
								   AND [RAL].[Output Parameter Code] =
								       CASE 
								         WHEN CHARINDEX(@Tab, 'API')  > 0 THEN [RAH].[Input Parameter TMC API 4]
							             WHEN CHARINDEX(@Tab, 'GDS')  > 0 THEN [RAH].[Input Parameter TMC GDS 4]
							             WHEN CHARINDEX(@Tab, 'DACH') > 0 THEN [RAH].[Input Parameter TMC RD 4]
							             WHEN CHARINDEX(@Tab, 'ROW')  > 0 THEN [RAH].[Input Parameter TMC RR 4]
							             WHEN CHARINDEX(@Tab, 'OBE')  > 0 THEN [RAH].[Input Parameter TMC OBE 4]
					                   END
								   )
		UNION
		SELECT [RVR].[Vector Code]
			 , ROW_NUMBER() OVER (PARTITION BY [RVR].[Vector Code] ORDER BY CAST([RVR].[Value From] AS INTEGER)) AS ROWNUMBER
			 , [RVR].[Description]
			 , [RVR].[Value Decimal]
			 , [RV].[Value Type]
		 FROM [HRS$Rebate Vector Ranges]	[RVR] WITH (NOLOCK) 
		 JOIN [HRS$Rebate Vector]			[RV] WITH (NOLOCK) 
		   ON [RV].[Code] = [RVR].[Vector Code]
		WHERE [Vector Code] IN (SELECT DISTINCT [RAL].[Matrix _ Vector Code] 
								  FROM [HRS$Posted Rebate Header]		[RH] WITH (NOLOCK) 
								  JOIN [HRS$Rebate Agreement Header]	[RAH] WITH (NOLOCK)
									ON [RH].[Rebate Agreement No_] = [RAH].[No_]	
								  JOIN [HRS$Rebate Agreement Line]		[RAL] WITH (NOLOCK)
								  	ON [RAH].[No_] = [RAL].[Rebate No_]
								 WHERE [RH].[No_]  = @ReNr OR RH.[Rebate No_] = @ReNr
								   AND [RAL].[Activity Type] = 4
								   AND [RAL].[Output Parameter Code] =
								       CASE 
								         WHEN CHARINDEX(@Tab, 'API')  > 0 THEN [RAH].[Input Parameter TMC API 4]
							             WHEN CHARINDEX(@Tab, 'GDS')  > 0 THEN [RAH].[Input Parameter TMC GDS 4]
							             WHEN CHARINDEX(@Tab, 'DACH') > 0 THEN [RAH].[Input Parameter TMC RD 4]
							             WHEN CHARINDEX(@Tab, 'ROW')  > 0 THEN [RAH].[Input Parameter TMC RR 4]
							             WHEN CHARINDEX(@Tab, 'OBE')  > 0 THEN [RAH].[Input Parameter TMC OBE 4]
					                   END
								   )
	--SELECT * FROM @Vector
	; WITH [RL] AS
	(
	  SELECT [RL].[No_], [RL].[Value Decimal], [PA].[Name], [PA].[Value Decimal] [Constant Value Decimal], [RL].[Threshold Value Index], [RL].[Value]
		   , CASE WHEN [RH].[Input Parameter TMC API 1] = [RL].[No_] THEN 'API1'
				  WHEN [RH].[Input Parameter TMC API 2] = [RL].[No_] THEN 'API2'
				  WHEN [RH].[Input Parameter TMC API 3] = [RL].[No_] THEN 'API3'
				  WHEN [RH].[Input Parameter TMC API 4] = [RL].[No_] THEN 'API4'
				  WHEN [RH].[Input Parameter TMC GDS 1] = [RL].[No_] THEN 'GDS1'
				  WHEN [RH].[Input Parameter TMC GDS 2] = [RL].[No_] THEN 'GDS2'
				  WHEN [RH].[Input Parameter TMC GDS 3] = [RL].[No_] THEN 'GDS3'
				  WHEN [RH].[Input Parameter TMC GDS 4] = [RL].[No_] THEN 'GDS4'
				  WHEN [RH].[Input Parameter TMC OBE 1] = [RL].[No_] THEN 'OBE1'
				  WHEN [RH].[Input Parameter TMC OBE 2] = [RL].[No_] THEN 'OBE2'
				  WHEN [RH].[Input Parameter TMC OBE 3] = [RL].[No_] THEN 'OBE3'
				  WHEN [RH].[Input Parameter TMC OBE 4] = [RL].[No_] THEN 'OBE4'
				  WHEN [RH].[Input Parameter TMC RD 1]  = [RL].[No_] THEN 'xRD1'
				  WHEN [RH].[Input Parameter TMC RD 2]  = [RL].[No_] THEN 'xRD2'
				  WHEN [RH].[Input Parameter TMC RD 3]  = [RL].[No_] THEN 'xRD3'
				  WHEN [RH].[Input Parameter TMC RD 4]  = [RL].[No_] THEN 'xRD4'
				  WHEN [RH].[Input Parameter TMC RR 1]  = [RL].[No_] THEN 'xRR1'
				  WHEN [RH].[Input Parameter TMC RR 2]  = [RL].[No_] THEN 'xRR2'
				  WHEN [RH].[Input Parameter TMC RR 3]  = [RL].[No_] THEN 'xRR3'
				  WHEN [RH].[Input Parameter TMC RR 4]  = [RL].[No_] THEN 'xRR4'
				  ELSE NULL
			  END [TMC Parameter] 
			, CASE WHEN [RH].[Input Parameter TMC API 4] = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC GDS 4] = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC RD 4]  = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC RR 4]  = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC OBE 4] = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
			 END [Matrix _ Vector Code] 
		FROM [HRS$Rebate Line]   [RL] WITH (NOLOCK) 
		JOIN [HRS$Rebate Header] [RH] WITH (NOLOCK) 
		  ON [RL].[Document No_] = [RH].[No_]
		JOIN [HRS$Parameter]     [PA] WITH (NOLOCK)
		  ON [PA].[Code]  = [RL].[No_]

   LEFT JOIN [HRS$Rebate Agreement Header]	[RAH] WITH (NOLOCK)
		  ON [RH].[Rebate Agreement No_] = [RAH].[No_]	
   LEFT JOIN [HRS$Rebate Agreement Line]		[RAL] WITH (NOLOCK)
		  ON [RAH].[No_] = [RAL].[Rebate No_]
		 AND [PA].[Code]  = [RAL].[Output Parameter Code]
		 AND [RL].[Threshold Value Index] <> 0
       
	   WHERE [RH].[No_]   = @ReNr
		 AND [RL].[Type] IN (1,2)
		 
	UNION 
	  SELECT [RL].[No_], [RL].[Value Decimal], [PA].[Name], [PA].[Value Decimal] [Constant Value Decimal], [RL].[Threshold Value Index], [RL].[Value]
		   , CASE WHEN [RH].[Input Parameter TMC API 1] = [RL].[No_] THEN 'API1'
				  WHEN [RH].[Input Parameter TMC API 2] = [RL].[No_] THEN 'API2'
				  WHEN [RH].[Input Parameter TMC API 3] = [RL].[No_] THEN 'API3'
				  WHEN [RH].[Input Parameter TMC API 4] = [RL].[No_] THEN 'API4'
				  WHEN [RH].[Input Parameter TMC GDS 1] = [RL].[No_] THEN 'GDS1'
				  WHEN [RH].[Input Parameter TMC GDS 2] = [RL].[No_] THEN 'GDS2'
				  WHEN [RH].[Input Parameter TMC GDS 3] = [RL].[No_] THEN 'GDS3'
				  WHEN [RH].[Input Parameter TMC GDS 4] = [RL].[No_] THEN 'GDS4'
				  WHEN [RH].[Input Parameter TMC GDS 1] = [RL].[No_] THEN 'OBE1'
				  WHEN [RH].[Input Parameter TMC GDS 2] = [RL].[No_] THEN 'OBE2'
				  WHEN [RH].[Input Parameter TMC GDS 3] = [RL].[No_] THEN 'OBE3'
				  WHEN [RH].[Input Parameter TMC GDS 4] = [RL].[No_] THEN 'OBE4'
				  WHEN [RH].[Input Parameter TMC RD 1]  = [RL].[No_] THEN 'xRD1'
				  WHEN [RH].[Input Parameter TMC RD 2]  = [RL].[No_] THEN 'xRD2'
				  WHEN [RH].[Input Parameter TMC RD 3]  = [RL].[No_] THEN 'xRD3'
				  WHEN [RH].[Input Parameter TMC RD 4]  = [RL].[No_] THEN 'xRD4'
				  WHEN [RH].[Input Parameter TMC RR 1]  = [RL].[No_] THEN 'xRR1'
				  WHEN [RH].[Input Parameter TMC RR 2]  = [RL].[No_] THEN 'xRR2'
				  WHEN [RH].[Input Parameter TMC RR 3]  = [RL].[No_] THEN 'xRR3'
				  WHEN [RH].[Input Parameter TMC RR 4]  = [RL].[No_] THEN 'xRR4'
				  ELSE NULL
			  END [TMC Parameter]
			, CASE WHEN [RH].[Input Parameter TMC API 4] = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC GDS 4] = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC OBE 4] = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC RD 4]  = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
				   WHEN [RH].[Input Parameter TMC RR 4]  = [RAL].[Output Parameter Code] THEN [RAL].[Matrix _ Vector Code]
			 END [Matrix _ Vector Code] 
		FROM [HRS$Posted Rebate Line]   [RL] WITH (NOLOCK) 
		JOIN [HRS$Posted Rebate Header] [RH] WITH (NOLOCK) 
		  ON [RL].[Document No_] = [RH].[No_]
		JOIN [HRS$Parameter]     [PA] WITH (NOLOCK)
		  ON [PA].[Code]  = [RL].[No_]

   LEFT JOIN [HRS$Rebate Agreement Header]	[RAH] WITH (NOLOCK)
		  ON [RH].[Rebate Agreement No_] = [RAH].[No_]	
   LEFT JOIN [HRS$Rebate Agreement Line]		[RAL] WITH (NOLOCK)
		  ON [RAH].[No_] = [RAL].[Rebate No_]
		 AND [PA].[Code]  = [RAL].[Output Parameter Code]
		 AND [RL].[Threshold Value Index] <> 0

	   WHERE (RH.[No_] = @ReNr OR [RH].[Rebate No_] = @ReNr)
		 AND [RL].[Type] IN (1,2)
	)
	--SELECT * FROM [RL]
	--SELECT * FROM RL --WHERE [TMC Parameter] LIKE 'xRR%'

	INSERT INTO @Result
	SELECT (SELECT [Value Decimal] FROM [RL] WHERE [TMC Parameter] = @Feetype + '1')	
		 , [P3].[Value Decimal]													
		 , [V].[Value]															
		 , [P3].[Value Decimal] / 100 * [P2].[Value Decimal]					
		 , [V].[Description]													
		 , [V].[ROWNUMBER]														
		 , [V].[Value Type]	
	 FROM [RL] [P2] 
	 JOIN [RL] [P3] 
	   ON [P2].[Threshold Value Index] = [P3].[Threshold Value Index]
	 JOIN [RL] [P4] 
	   ON [P2].[Threshold Value Index] = [P4].[Threshold Value Index]
	 JOIN @Vector	[V]
	   ON [P4].[Matrix _ Vector Code]  = [V].[Vector Code]
	  AND [P4].[Threshold Value Index] = [V].[ROWNUMBER]
    WHERE [P2].[TMC Parameter] = @Feetype + '2'
	  AND [P3].[TMC Parameter] = @Feetype + '3'
	  AND [P4].[TMC Parameter] = @Feetype + '4' 

	MERGE @Result [R]
	USING @Vector [V]
	   ON [R].[ROWNUMBER] = [V].[ROWNUMBER]
	WHEN NOT MATCHED BY TARGET
		THEN INSERT([ThresholdDescription], [ROWNUMBER], [Threshold], [Value Type]) VALUES([Description], [ROWNUMBER], [Value], [Value Type])
		;

	SELECT * 
	  FROM @Result 
  ORDER BY [ROWNUMBER] 
END 
GO
