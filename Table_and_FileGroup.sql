/*
		Name:		Table_and_Filegroups.sql
		Date:		February 22nd, 2020
		Author:		Raghu Gopalakrishnan
		Purpose:	Get the list of tables, indexes and the corresponding Filegroup they belong to.
*/

SET NOCOUNT ON

SELECT		o.[name] AS [Table Name],  
			i.[name] AS [Index Name], 
			i.[index_id] AS [Index ID], 
			f.[name] AS [Filegroup Name]
FROM		[sys].[indexes] i
INNER JOIN	[sys].[filegroups] f
		ON	i.[data_space_id] = f.[data_space_id]
INNER JOIN	[sys].[all_objects] o
		ON	i.[object_id] = o.[object_id]
WHERE		i.[data_space_id] = f.[data_space_id]
AND			o.[type] = 'U'
ORDER BY	f.[name] 
GO

