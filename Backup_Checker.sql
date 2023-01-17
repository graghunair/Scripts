SELECT	SERVERPROPERTY('servername') AS [Server_Name], 
		[name] AS [Database_Name], 
        d AS [Last_Full_Backup], 
        i AS [Last _Differential_Backup], 
        l AS [Last_TLog_Backup], 
		[recovery_model_desc] AS [Recovery Model], 
        [state_desc] AS [Database State],
		GETDATE() AS [Date_Captured]
FROM	(SELECT			db.[name], 
						db.[database_id], 
						db.[state], 
						db.[state_desc], 
						db.[recovery_model_desc], 
						bkp.[type], 
						bkp.[backup_finish_date] 
        FROM			[sys].[databases] db 
		LEFT OUTER JOIN [msdb].[dbo].[backupset] bkp 
		ON				db.[name] = bkp.[database_name] 
        ) AS Sourcetable  
PIVOT  
        (MAX([backup_finish_date]) FOR [type] IN (D,I,L)) AS Last_Backup 
WHERE	[state] = 0 
AND		[database_id] <> 2 
ORDER BY 3,4,5 
GO 
