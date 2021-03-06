/*
	
	Author  :	Raghu Gopalakrishnan
	Date	:	16th February 2018
	Purpose	:	This script is to enable Auto Seeding feature to an Availability Group.
				This feature is available starting SQL Server 2016
	Version	:	1.0
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
  
 */
 
-- Run this on both the nodes
ALTER AVAILABILITY GROUP [AG-Name] MODIFY REPLICA ON 'Node-Name' WITH (SEEDING_MODE = AUTOMATIC)
GO

-- Run this on both the nodes
ALTER AVAILABILITY GROUP [AG-Name] GRANT CREATE ANY DATABASE
GO

-- Run this on the Primary Node
ALTER AVAILABILITY GROUP [AG-Name] ADD DATABASE [Database-Name]
GO