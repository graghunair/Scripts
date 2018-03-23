/*
	
	Author  :	Raghu Gopalakrishnan
	Date	:	23rd March 2018
	Purpose	:	Creating constraints on a table
	Version	:	1.0
	License	:	This script is provided "AS IS" with no warranties, and confers no rights.
  
 */


--Default Constraint (Drop and Create)
ALTER TABLE <schema-name>.<table-name> 
DROP CONSTRAINT <constraint-name>

ALTER TABLE <schema-name>.<table-name> 
ADD CONSTRAINT <constraint-name>
DEFAULT GETDATE() FOR <column-name> ;
GO