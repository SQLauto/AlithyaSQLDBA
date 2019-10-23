/*
Script DB Level Permissions 
*/
-- roles first
-- Role Members
create table AppRoleMembers_t
	(lineData	varchar(2000))

create table AppRoleMembers_Aggregate_t
	(dbname		nvarchar(128)
	,login		nvarchar(128)
	,isapprole	int
	,pw_len		int)


insert AppRoleMembers_t
	select 'select 		db_name()
		,t1.name
		,t2.isapprole
		,len(t1.password) 
		from master.dbo.syslogins as t1 
		inner join ' + name + '.dbo.sysusers as t2 on t1.name = t2.name 
		where t2.isapprole = 1 
		and t1.password is null' 
	from master.dbo.sysdatabases 
	where dbid > 4
	and databasepropertyex(name, 'SQLSortOrder') = databasepropertyex('master', 'SQLSortOrder')
	order by name
declare @tsql	varchar(4000)

declare db_cur2 cursor
for
 	select lineData from AppRoleMembers_t

open db_cur2

fetch next from db_cur2 into @tsql

set @tsql = 'insert AppRoleMembers_Aggregate_t ' + @tsql

while (@@fetch_status = 0)
begin
	--print @tsql
	exec (@tsql)
	fetch next from db_cur2 into @tsql
end

close db_cur2

deallocate db_cur2


--select * from AppRoleMembers_t
print '*** Check count on AppRoleMembers_Aggregate ***)'
if (select count(*) from AppRoleMembers_Aggregate_t) = 0
begin
	print 'No application roles with blank passwords exist on this server at this time.'
	--
end

	select * from AppRoleMembers_Aggregate_t


drop table AppRoleMembers_t
drop table AppRoleMembers_Aggregate_t

set nocount on

declare @tsql2	varchar(70),
	@name	varchar(64)

declare db_cur cursor
for
 	select name from master.dbo.sysdatabases where dbid NOT IN (2,3) order by name

open db_cur

fetch next from db_cur into @name

set @tsql2 = 'exec ' + @name + '.dbo.sp_helprolemember'

while (@@fetch_status = 0)
begin
	print 'Roles in database ' + @name + ':'
	set @tsql2 = 'exec ' + @name + '.dbo.sp_helprolemember'
	exec (@tsql2)
	fetch next from db_cur into @name
end


close db_cur

deallocate db_cur
--- then more detailed grants

DECLARE 
    @sql VARCHAR(2048)
    ,@sort INT 
	,@database nVarchar(200)

DECLARE databasecursor CURSOR FAST_FORWARD FOR 
SELECT name 
FROM MASTER.dbo.sysdatabases 
WHERE name NOT IN ('model')

OPEN databasecursor

FETCH NEXT FROM databasecursor
INTO @database 

WHILE @@FETCH_STATUS = 0
BEGIN

DECLARE tmp CURSOR FOR


/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT '-- [-- DB CONTEXT --] --' AS [-- SQL STATEMENTS --],
        1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  'USE' + SPACE(1) + QUOTENAME(@database)  AS [-- SQL STATEMENTS --],
        1 AS [-- RESULT ORDER HOLDER --]

UNION

SELECT '' AS [-- SQL STATEMENTS --],
        2 AS [-- RESULT ORDER HOLDER --]

UNION

/*********************************************/
/*********     DB USER CREATION      *********/
/*********************************************/

SELECT '-- [-- DB USERS --] --' AS [-- SQL STATEMENTS --],
        3 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  'IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = ' + SPACE(1) + '''' + [name] + '''' + ') BEGIN CREATE USER ' + SPACE(1) + QUOTENAME([name]) + ' FOR LOGIN ' + QUOTENAME([name]) + ' WITH DEFAULT_SCHEMA = ' + QUOTENAME([default_schema_name]) + SPACE(1) + 'END; ' AS [-- SQL STATEMENTS --],
        4 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_principals AS rm
WHERE [type] IN ('U', 'S', 'G') -- windows users, sql users, windows groups

UNION

/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT '-- [-- DB ROLES --] --' AS [-- SQL STATEMENTS --],
        5 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  'EXEC sp_addrolemember @rolename ='
    + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''') + ', @membername =' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''') AS [-- SQL STATEMENTS --],
        6 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_role_members AS rm
WHERE   USER_NAME(rm.member_principal_id) IN (  
                                                --get user names on the database
                                                SELECT [name]
                                                FROM sys.database_principals
                                                WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
                                                and [type] IN ('G', 'S', 'U') -- S = SQL user, U = Windows user, G = Windows group
                                              )
--ORDER BY rm.role_principal_id ASC


UNION

SELECT '' AS [-- SQL STATEMENTS --],
        7 AS [-- RESULT ORDER HOLDER --]

UNION

/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT '-- [-- OBJECT LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
        8 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
            WHEN perm.state <> 'W' THEN perm.state_desc 
            ELSE 'GRANT'
        END
        + SPACE(1) + perm.permission_name + SPACE(1) + 'ON ' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + '.' + QUOTENAME(obj.name) --select, execute, etc on specific objects
        + CASE
                WHEN cl.column_id IS NULL THEN SPACE(0)
                ELSE '(' + QUOTENAME(cl.name) + ')'
          END
        + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
        + CASE 
                WHEN perm.state <> 'W' THEN SPACE(0)
                ELSE SPACE(1) + 'WITH GRANT OPTION'
          END
            AS [-- SQL STATEMENTS --],
        9 AS [-- RESULT ORDER HOLDER --]
FROM    
    sys.database_permissions AS perm
        INNER JOIN
    sys.objects AS obj
            ON perm.major_id = obj.[object_id]
        INNER JOIN
    sys.database_principals AS usr
            ON perm.grantee_principal_id = usr.principal_id
        LEFT JOIN
    sys.columns AS cl
            ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
--WHERE usr.name = @OldUser
--ORDER BY perm.permission_name ASC, perm.state_desc ASC



UNION

SELECT '' AS [-- SQL STATEMENTS --],
    10 AS [-- RESULT ORDER HOLDER --]

UNION

/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT '-- [--DB LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
        11 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
            WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
            ELSE 'GRANT'
        END
    + SPACE(1) + perm.permission_name --CONNECT, etc
    + SPACE(1) + 'TO' + SPACE(1) + '[' + USER_NAME(usr.principal_id) + ']' COLLATE database_default --TO <user name>
    + CASE 
            WHEN perm.state <> 'W' THEN SPACE(0) 
            ELSE SPACE(1) + 'WITH GRANT OPTION' 
      END
        AS [-- SQL STATEMENTS --],
        12 AS [-- RESULT ORDER HOLDER --]
FROM    sys.database_permissions AS perm
    INNER JOIN
    sys.database_principals AS usr
    ON perm.grantee_principal_id = usr.principal_id
--WHERE usr.name = @OldUser

WHERE   [perm].[major_id] = 0
    AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
    AND [usr].[type] IN ('G', 'S', 'U') -- S = SQL user, U = Windows user, G = Windows group

UNION

SELECT '' AS [-- SQL STATEMENTS --],
        13 AS [-- RESULT ORDER HOLDER --]

UNION 

SELECT '-- [--DB LEVEL SCHEMA PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
        14 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE
            WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
            ELSE 'GRANT'
            END
                + SPACE(1) + perm.permission_name --CONNECT, etc
                + SPACE(1) + 'ON' + SPACE(1) + class_desc + '::' COLLATE database_default --TO <user name>
                + QUOTENAME(SCHEMA_NAME(major_id))
                + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(grantee_principal_id)) COLLATE database_default
                + CASE
                    WHEN perm.state <> 'W' THEN SPACE(0)
                    ELSE SPACE(1) + 'WITH GRANT OPTION'
                    END
            AS [-- SQL STATEMENTS --],
        15 AS [-- RESULT ORDER HOLDER --]
from sys.database_permissions AS perm
    inner join sys.schemas s
        on perm.major_id = s.schema_id
    inner join sys.database_principals dbprin
        on perm.grantee_principal_id = dbprin.principal_id
WHERE class = 3 --class 3 = schema


ORDER BY [-- RESULT ORDER HOLDER --]


OPEN tmp
FETCH NEXT FROM tmp INTO @sql, @sort
WHILE @@FETCH_STATUS = 0
BEGIN
        PRINT @sql
        FETCH NEXT FROM tmp INTO @sql, @sort    
END
CLOSE tmp
DEALLOCATE tmp 

	FETCH NEXT FROM databasecursor
	INTO @database 
END 

CLOSE databasecursor
DEALLOCATE databasecursor