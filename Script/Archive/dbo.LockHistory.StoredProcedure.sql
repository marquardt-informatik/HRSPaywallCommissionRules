USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [dbo].[LockHistory]    Script Date: 10.04.2024 14:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LockHistory] AS

DECLARE @EntryNo INTEGER

 SELECT @EntryNo = COALESCE(MAX([Entry No_]),0)    -- Wenn mehr als 1 Datensatz eingefügt wird PK-Verletzung weil @EntryNo konstant!
   FROM [Lock History]							   -- deswegen zähle ich die Row_Number dazu (Matthias Elflein)
												   -- siehe INSERT ... SELECT ...
    -- SET @EntryNo = @EntryNo + 1				   -- Warum wird eigentlich kein IDENTITY verwendet?
													-- 2018.02.14 Added NOLOCK to Tables and BLKED CTE to Filter SQLText and Speed up Query

;WITH BLKED AS
(
Select spid
 FROM sys.sysprocesses (NOLOCK)
 where [blocked] <> 0
),
CMD AS
(
       SELECT sqltext.TEXT
            , req.session_id [spid]
         FROM sys.dm_exec_requests req (NOLOCK)
		 INNER JOIN BLKED on req.session_id = BLKED.spid
  CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
), PLN AS
(
       SELECT sqltext.TEXT
            , req.session_id [spid]
         FROM sys.dm_exec_requests req (NOLOCK)
		 INNER JOIN BLKED on req.session_id = BLKED.spid
  CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS sqltext
)INSERT INTO [Lock History]
           ([Entry No_]
           ,[Connection ID]
           ,[Date and Time]
           ,[User ID]
           ,[Login Time]
           ,[Login Date]
           ,[Database Name]
           ,[Application Name]
           ,[Login Type]
           ,[Host Name]
           ,[CPU Time (ms)]
           ,[Memory Usage (KB)]
           ,[Pysical I_O]
           ,[Blocked]
           ,[Wait Time (ms)]
           ,[Blocking Connection ID]
           ,[Blocking User ID]
           ,[Blocking Host Name]
           ,[Blocking Object]
           ,[Idle Time]
           ,[Last Wait Type]
           ,[Wait Resource]
           ,[Wait Type]
           ,[TEXT]
           ,[PLAN])
	SELECT @EntryNo + ROW_NUMBER() over (order by CMD.[spid] )  --  Hier wird der Zähler inkrementiert, wenn mehrere Datensätze
		 , SP.[spid] AS [Connection ID]
		 , GETDATE() as [Date and Time]
		 , RTRIM(SP.[loginame]) AS [User ID]
		 , CONVERT(DATETIME, '1754-01-01 ' + CONVERT(CHAR(8), SP.[login_time], 108), 120) AS [Login Time]
		 , CONVERT(DATETIME, CONVERT(CHAR(10), SP.[login_time], 120)  + ' 00:00:00:000', 121) AS [Login Date]
		 , SD.[name] AS [Database Name]
		 , RTRIM(SP.[program_name]) AS [Application Name]
		 , CASE WHEN SP.[nt_domain] <> '' THEN 1 ELSE 0 END AS [Login Type]
		 , RTRIM(SP.[hostname]) AS [Host Name]
		 , CAST(SP.[cpu] AS decimal(38, 20)) AS [CPU Time (ms)]
		 , CAST(SP.[memusage] AS decimal(38, 20)) [Memory Usage (KB)]
		 , CAST(SP.[physical_io] AS decimal(38, 20)) AS [Physical I_O]
		 , CAST(CASE WHEN SP.[blocked] > 0 THEN 1 ELSE 0 END AS TINYINT) AS [Blocked]
		 , CAST(SP.[waittime] AS decimal(38, 20)) AS [Wait Time (ms)]
		 , CAST(SP.[blocked] AS INTEGER) AS [Blocking Connection ID]
		 , COALESCE(RTRIM(SP2.[loginame]),'') AS [Blocking User ID]
		 , COALESCE(RTRIM(SP2.[hostname]),'') AS [Blocking Host Name]
		 , CASE 
			 WHEN SP.[blocked] > 1 THEN 
			   CASE CHARINDEX('KEY:',SP.[waitresource])
				 WHEN 1 THEN (SELECT o.name + ':' + i.name 
								FROM sys.partitions p
								   , sys.sysobjects o
								   , sys.sysindexes i
							   WHERE p.hobt_id=SUBSTRING(SUBSTRING(SP.[waitresource]
									,CHARINDEX(':',SP.[waitresource])+1,50)
									,CHARINDEX(':',SUBSTRING(SP.[waitresource]
									,CHARINDEX(':',SP.[waitresource])+1,50))+1
									,CHARINDEX(' ',SUBSTRING(SUBSTRING(SP.[waitresource]
									,CHARINDEX(':',SP.[waitresource])+1,50)
									,CHARINDEX(':',SUBSTRING(SP.[waitresource]
									,CHARINDEX(':',SP.[waitresource])+1,50))+1,50)))
								AND o.id=p.object_id
								AND i.id=o.id
								AND i.indid=p.index_id)
				 ELSE 
				   CASE CHARINDEX('TAB:',SP.[waitresource])
					 WHEN 1 THEN RTRIM(OBJECT_NAME(SUBSTRING(SUBSTRING(SUBSTRING(SP.[waitresource]
								 ,CHARINDEX(':',SP.[waitresource])+1,50)
								 ,CHARINDEX(':',SUBSTRING(SP.[waitresource]
								 ,CHARINDEX(':',SP.[waitresource])+1,50))+1,50),1
								 ,CHARINDEX(':',SUBSTRING(SUBSTRING(SP.[waitresource]
								 ,CHARINDEX(':',SP.[waitresource])+1,50)
								 ,CHARINDEX(':',SUBSTRING(SP.[waitresource]
								 ,CHARINDEX(':',SP.[waitresource])+1,50))+1,50))-1))) COLLATE SQL_Latin1_General_CP850_CS_AS
					 ELSE SP.[waitresource]
				   END
			   END
			 ELSE ''
		   END AS [Blocking Object]
		 , CASE 
			 WHEN SP.[cmd] = 'AWAITING COMMAND' THEN CAST(DATEDIFF(SECOND, SP.[last_batch], GETDATE()) AS BIGINT)*1000 
			 ELSE 0 
		   END AS [Idle Time]
		 , SP.LastWaittype as [Last Wait Type]
		 , SP.[waitresource] [Wait Resource]
		 , SP.waittype as [Wait Type]
		 , CMD.TEXT
		 , PLN.TEXT
      FROM sys.sysprocesses AS SP (NOLOCK)
      JOIN sys.sysdatabases AS SD (NOLOCK)
        ON (SP.dbid = SD.dbid)
 LEFT JOIN sys.sysprocesses AS SP2 (NOLOCK)
        ON (SP.[blocked] = SP2.[spid])
 LEFT JOIN CMD
        ON CMD.[spid] = SP2.[spid]
 LEFT JOIN PLN
        ON PLN.[spid] = SP2.[spid]
     WHERE SP.[program_name] <> ''
       AND SP.[blocked] <> 0
	   AND SP.waittype != 0x0024    --- Exclude Latches



GO
