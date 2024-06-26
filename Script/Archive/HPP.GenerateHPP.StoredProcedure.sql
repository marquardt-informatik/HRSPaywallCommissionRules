USE [DynNavHRS]
GO
/****** Object:  StoredProcedure [HPP].[GenerateHPP]    Script Date: 10.04.2024 14:31:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ===============================================
-- Author:		swift.consult GmbH (A. Schauerte)
-- Create date: 2016-02-03
-- Description:	Regenerates HPP objects based on 
--              Tenants & SqlTemplates tables.
-- ===============================================
CREATE PROCEDURE [HPP].[GenerateHPP] 
	@prefix nvarchar(128) = '[dbo].['
AS
BEGIN
declare @sql nvarchar(max)

declare tenants scroll cursor for select Name from HPP.Tenants where Active = 1
declare @tenant sysname

declare vws cursor for select Name, [Description], Content from HPP.SqlTemplates where ObjectType = 'View'
declare @view nvarchar(max)
declare @desc nvarchar(max)
declare @content nvarchar(max)
declare @count int

open vws 
fetch next from vws into @view, @desc, @content

open tenants

while @@FETCH_STATUS = 0
begin
  set @view = 'HPP.['  + @view + ']'
  IF OBJECT_ID(@view, 'V') IS NOT NULL
	exec ('DROP VIEW ' + @view)

  set @sql = 'create view ' + @view + ' as '

  set @count = 0
  fetch first from tenants into @tenant
  while @@FETCH_STATUS = 0
  begin
	print '-- ' + @view + ' : ' + @tenant	

	if (@count > 0)
	  set @sql = @sql + '
UNION ALL 
'

	set @sql = @sql + REPLACE(REPLACE(@content, '{$Tenant}', @tenant), '[HRS-BR$', @prefix + @tenant + '$')
 
	set @count = @count + 1
	fetch next from tenants into @tenant
  end
  --print @sql
  exec (@sql)

  fetch next from vws into @view, @desc, @content	
end

close tenants
deallocate tenants

close vws
deallocate vws

END


GO
