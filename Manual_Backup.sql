/*
		Name:		Manual_Backup.sql
		Date:		September 12th, 2022
		Author:		Raghu Gopalakrishnan
		Purpose:	Take a manual backup of all user databases.
*/

DECLARE @varDatabase_Name SYSNAME
DECLARE @varBackup_Location VARCHAR(2000) = 'C:\Temp\'
DECLARE @varBackup_Command VARCHAR(MAX)
DECLARE @varBackup_Timestamp VARCHAR(50)
DECLARE @varDatabase_Recovery_Model TINYINT

SELECT @varDatabase_Name = MIN([name])
FROM   sys.databases 
WHERE  [database_id] > 4

WHILE  (@varDatabase_Name IS NOT NULL)
       BEGIN

                       SELECT       @varDatabase_Recovery_Model = recovery_model
              FROM   sys.databases 
              WHERE  [name] = @varDatabase_Name

                       IF (@varDatabase_Recovery_Model <> 3)
                     BEGIN
                           SELECT       @varBackup_Command = 'BACKUP LOG [' + @varDatabase_Name + '] TO DISK = ''nul''' 
                           PRINT       @varBackup_Command
                           EXEC       (@varBackup_Command)
                     END

              SELECT @varBackup_Timestamp = REPLACE(REPLACE(CAST(GETDATE() AS VARCHAR(50)), ' ','_'),':','_')
              SELECT @varBackup_Command = 'BACKUP DATABASE [' + @varDatabase_Name + '] TO DISK = ''' + @varBackup_Location + CAST(SERVERPROPERTY('servername') AS SYSNAME) + '_' +  @varDatabase_Name + '_' + @varBackup_Timestamp + '.bak'' with compression,stats=2'
              PRINT  @varBackup_Command
              EXEC   (@varBackup_Command)

             

              IF (@varDatabase_Recovery_Model <> 3)
                     BEGIN
                           SELECT       @varBackup_Timestamp = REPLACE(REPLACE(CAST(GETDATE() AS VARCHAR(50)), ' ','_'),':','_')
                           SELECT       @varBackup_Command = 'BACKUP LOG [' + @varDatabase_Name + '] TO DISK = ''' + @varBackup_Location + CAST(SERVERPROPERTY('servername') AS SYSNAME) + '_' + @varDatabase_Name + '_' + @varBackup_Timestamp + '.trn'''
                           PRINT       @varBackup_Command
                          EXEC       (@varBackup_Command)
                     END

              SELECT @varDatabase_Name = MIN([name])
              FROM   sys.databases 
              WHERE  [database_id] > 4
              AND           @varDatabase_Name < [name]
       END
