BACKUP DATABASE OpsDB
 TO  DISK = N'F:\mssql\Backups\OpsDB_Pre_rebuild1.BAK'
, DISK = N'F:\mssql\Backups\OpsDB_Pre_rebuild2.BAK',
DISK = N'F:\mssql\Backups\OpsDB_Pre_rebuild3.BAK' 
 WITH NOFORMAT, INIT,  NAME = N'OpsDB-Full Database Backup', 
 SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1
GO
