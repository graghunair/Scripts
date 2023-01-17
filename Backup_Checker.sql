SELECT	SERVERPROPERTY('servername') AS [Server_Name], 
	[name] AS [Database_Name], 
        d AS [Last_Full_Backup], 
	DATEDIFF(dd, d, GETDATE()) [Last_Full_Backup_Days_Old],
        i AS [Last _Differential_Backup], 
        l AS [Last_TLog_Backup], 
	[recovery_model_desc] AS [Recovery Model], 
        [state_desc] AS [Database State],
	sys.fn_hadr_backup_is_preferred_replica([name]) AS [Is_Preferred_Replica],
	GETDATE() AS [Date_Captured]
FROM	(SELECT			db.[name], 
				db.[database_id], 
				db.[state], 
				db.[state_desc], 
				db.[recovery_model_desc], 
				bkp.[type], 
				bkp.[backup_finish_date] 
        FROM			[sys].[databases] db 
	LEFT OUTER JOIN 	[msdb].[dbo].[backupset] bkp 
	ON			db.[name] = bkp.[database_name] 
        ) AS Sourcetable  
PIVOT  
        (MAX([backup_finish_date]) FOR [type] IN (D,I,L)) AS Last_Backup 
WHERE	[state] = 0 
AND	[database_id] <> 2 
ORDER BY d,i,l
GO
