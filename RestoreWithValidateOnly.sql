RESTORE VERIFYONLY FROM
--DATABASE [HarrisTeeterS2G] FILE = N'HarrisTeeterS2G' from
  DISK = N'F:\MSSQL\Backup\S2G_Nico.bak' WITH VERIFYONLY, FILE = 1,  NOUNLOAD,  STATS = 10
GO

