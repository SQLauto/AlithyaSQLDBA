-- change the f: mssql folder to where ever the backups will be
BACKUP DATABASE [master] TO  DISK = N'F:\MSSQL\Backup\Master.bak' WITH NOFORMAT, NOINIT,  NAME = N'master-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'master' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'master' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''master'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'F:\MSSQL\Backup\Master.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO
BACKUP DATABASE [model] TO  DISK = N'F:\MSSQL\Backup\Model.bak' WITH NOFORMAT, NOINIT,  NAME = N'master-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'model' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'model' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''model'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'F:\MSSQL\Backup\Model.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO
BACKUP DATABASE [msdb] TO  DISK = N'F:\MSSQL\Backup\MSDB.bak' WITH NOFORMAT, NOINIT,  NAME = N'master-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'msdb' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'msdb' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''msdb'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'F:\MSSQL\Backup\MSDB.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

