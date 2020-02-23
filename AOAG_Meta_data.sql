/*
		Name:		AOAG_Meta_data.sql
		Date:		February 22nd, 2020
		Author:		Raghu Gopalakrishnan
		Purpose:	Get the meta-data related SQL Server AlwaysOn Availability Groups.
*/


SELECT			AGL.[dns_name] AS [Listener Name], 
			AGL.[port] AS [Port],
			AGL.[ip_configuration_string_from_cluster] AS [IP], 
			ARS.[role_desc] AS [Role], 
			AG.[name] AS [Availability Group Name],
			AR.[availability_mode_desc] AS [Availability Mode], 
			AR.[failover_mode_desc] AS [Failover Mode],
			AGS.[synchronization_health_desc] AS [Sync Health]
FROM			[sys].[dm_hadr_availability_group_states] AGS
INNER JOIN		[sys].[dm_hadr_availability_replica_states] ARS
	ON		AGS.group_id = ARS.group_id
INNER JOIN		[sys].[availability_groups] AG
	ON		AGS.group_id = AG.group_id
INNER JOIN		[sys].[availability_replicas] AR
	ON		AR.replica_id = ARS.replica_id
LEFT OUTER JOIN	[sys].[availability_group_listeners] AGL
	ON		AGL.group_id = AGS.group_id	
WHERE			ARS.is_local = 1
GO
