/*
		Name:		CPU_Memory_Ring_Buffers.sql
		Date:		February 22nd, 2020
		Author:		Raghu Gopalakrishnan
		Purpose:	Get the CPU and Memory utilization from the DMV: sys.dm_os_ring_buffers
*/

SET NOCOUNT ON

DECLARE @varPresent_Time BIGINT 
SELECT	@varPresent_Time = ms_ticks 
FROM    [sys].[dm_os_sys_info] 

SELECT  DATEADD (ms, (B.[timestamp] - @varPresent_Time), GETDATE()) as [Event_Time],
        [SQL_Server_CPU_Utilization],  
        100 - [System_Idle] as Total_CPU_Utilization,
        [Memory_Utilization]
FROM    ( 
            SELECT 
                    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [System_Idle], 
                    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [SQL_Server_CPU_Utilization],
                    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization) [1]', 'bigint') AS [Memory_Utilization],   
                    [timestamp] 
            FROM    ( 
                        SELECT    [timestamp], CONVERT(xml, record) as record 
                        FROM    [sys].[dm_os_ring_buffers]
                        WHERE    ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
                        AND        record like '%<SystemHealth>%') AS A
                    )    AS B
ORDER BY 1 DESC
GO

