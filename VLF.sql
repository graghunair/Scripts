/*
    Get VLF Details for all the databases in the instance
*/
SELECT		SERVERPROPERTY('servername') AS [SQL_Server_Instance],
            [name] AS [Database_Name], 
			COUNT(l.database_id) AS [VLF Count],
			SUM(vlf_size_mb) AS [VLF Size (MB)],
            GETDATE() AS [Date_Captured]
FROM		sys.databases s
CROSS APPLY sys.dm_db_log_info(s.database_id) l
GROUP BY	[name], s.database_id
ORDER BY	2 DESC
GO

/*
    Get VLF Details per transaction log file within a database
*/

SELECT      SERVERPROPERTY('servername') AS [SQL_Server_Instance],
            DB_NAME() AS [ Database_Name],
            df.[name] AS [Log File Name],
            li.[file_id],
            COUNT(*) AS [VLF_Count],
            MIN(li.vlf_size_mb) AS [Min VLF Size MB],
            MAX(li.vlf_size_mb) AS [Max VLF Size MB],
            AVG(li.vlf_size_mb) AS [Avg VLF Size MB],
            SUM(li.vlf_size_mb) AS [Total VLF Space MB],
            GETDATE() AS [Date_Captured]
FROM        sys.dm_db_log_info(DB_ID()) li
INNER JOIN  sys.database_files df
        ON  li.[file_id] = df.[file_id]
WHERE       df.[type_desc] = 'LOG'
GROUP BY    df.[name], li.[file_id]
ORDER BY    VLF_Count DESC

/*
    Get VLF Details per transaction log file within a database
*/
SELECT		SERVERPROPERTY('servername') AS [SQL_Server_Instance],
            d.[name] AS [Database_Name],
			d.[recovery_model_desc] AS [Recover_Model],
			d.[state_desc] AS [Database_State],
			ls.[log_backup_time] AS [TLog_Backup_Time],
			CASE
				WHEN	d.[recovery_model_desc] = 'SIMPLE' THEN 0
				ELSE	DATEDIFF(mi, ls.[log_backup_time], GETDATE()) 
			END [TLog_Backup_Minutes_Ago],
			ls.[log_truncation_holdup_reason] AS [Log_Truncation_Holdup_Reason],
			ROUND(ls.[total_log_size_mb],0) AS [TLog_Size_MB],
			ls.[total_vlf_count] AS [VLF_Count],
            GETDATE() AS [Date_Captured]
FROM		sys.databases AS d
CROSS APPLY sys.dm_db_log_stats(d.database_id)  ls
GO

