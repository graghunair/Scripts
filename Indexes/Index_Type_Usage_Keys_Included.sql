SET NOCOUNT ON

DECLARE @varID INT,
  @varSchema_Name SYSNAME,
  @varTable_Name SYSNAME,
  @varSQL_Script VARCHAR(2000)

DECLARE @tblIndex_List TABLE ( [ID] INT IDENTITY(1,1), 
        [Schema_Name] SYSNAME, 
        [Table_Name] SYSNAME, 
        [SQL_Script] VARCHAR(2000))

DECLARE @tblIndex TABLE (  [Index_Name] SYSNAME, 
        [Index_Description] VARCHAR(2000),
        [Index_Keys] VARCHAR(MAX))

DECLARE @tblIndex_With_Keys TABLE ( [Schema_Name] SYSNAME, 
         [Table_Name] SYSNAME, 
         [Index_Name] SYSNAME, 
         [Index_Description] VARCHAR(2000),
         [Index_Keys] VARCHAR(MAX))

DECLARE @tblIndex_Details TABLE ( [Object_ID] INT,
         [Schema_Name] SYSNAME, 
         [Table_Name] SYSNAME, 
         [Index_Name] SYSNAME, 
         [Index_Description] VARCHAR(2000),
         [Index_Keys] VARCHAR(MAX),
         [Row_Count] BIGINT,
         [Total_Size_MB] BIGINT)

DECLARE @tblIndex_Usage_Stats TABLE ( [Object_ID] INT,
          [Table_Name] [nvarchar](128) NULL,
          [Index_Name] [sysname] NULL,
          [User_Seeks] [bigint] NOT NULL,
          [User_Scans] [bigint] NOT NULL,
          [User_Lookups] [bigint] NOT NULL,
          [User_Updates] [bigint] NOT NULL,
          [Last_User_Seek] [datetime] NULL,
          [Last_User_Scan] [datetime] NULL,
          [Last_User_Lookup] [datetime] NULL,
          [Last_User_Update] [datetime] NULL) 

DECLARE @tblIndex_Included_Columns TABLE( 
	            [Schema_Name] [nvarchar](128) NULL,
	            [Table_Name] [sysname] NOT NULL,
	            [Index_Name] [sysname] NULL,
	            [Index_Type] [nvarchar](60) NULL,
	            [Key_Columns] [nvarchar](MAX) NULL,
	            [Included_Columns] [nvarchar](MAX) NULL) 

INSERT INTO @tblIndex_List ([Schema_Name], [Table_Name], [SQL_Script])
SELECT SCHEMA_NAME(schema_id) AS [Schema_Name], 
  [name] as [Table_Name],
  'EXEC sp_helpindex [' + SCHEMA_NAME(schema_id) + '.' + [name] + ']'
FROM [sys].[tables]
WHERE is_ms_shipped = 0

SELECT @varID = MIN([ID]) FROM @tblIndex_List

WHILE (@varID IS NOT NULL)
 BEGIN
  SELECT @varSchema_Name = [Schema_Name],
    @varTable_Name = [Table_Name],
    @varSQL_Script = [SQL_Script]
  FROM @tblIndex_List
  WHERE [ID] = @varID

  INSERT INTO @tblIndex([Index_Name], [Index_Description], [Index_Keys])
  EXEC (@varSQL_Script)

  INSERT INTO @tblIndex_With_Keys ([Schema_Name],[Table_Name],[Index_Name],[Index_Description],[Index_Keys])
  SELECT @varSchema_Name,
    @varTable_Name,
    [Index_Name],
    [Index_Description],
    [Index_Keys]
  FROM @tblIndex

  DELETE  FROM @tblIndex

  SELECT @varID = MIN([ID]) 
  FROM @tblIndex_List
  WHERE @varID < [ID]
 END

;WITH cteIndex_Size 
AS(
SELECT      t.[schema_id] AS [Schema_ID],
   i.[object_id] AS [Object_ID],
   i.[index_id] AS [Index_ID],
   SCHEMA_NAME(t.[schema_id]) AS [Schema_Name],
            OBJECT_NAME(i.[object_id]) AS [Table_Name],
            i.[name] AS [Index_Name],
            p.[rows] AS [Row_Count],
            CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(18,2)) AS [Total_Size_MB]
FROM        sys.indexes i
INNER JOIN  sys.tables t ON i.[object_id] = t.[object_id]
INNER JOIN  sys.partitions p ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
INNER JOIN  sys.allocation_units a ON p.[partition_id] = a.container_id
WHERE       t.is_ms_shipped = 0
GROUP BY    t.[schema_id],
            i.[object_id],
            i.[index_id],
            i.[name],
            p.[rows])

INSERT INTO @tblIndex_Details
SELECT  [is].[Object_ID],
   [ik].[Schema_Name],
   [ik].[Table_Name],
   [ik].[Index_Name],
   [ik].[Index_Description],
   [ik].[Index_Keys], 
   [is].[Row_Count],
   [is].[Total_Size_MB]
FROM  @tblIndex_With_Keys [ik]
INNER JOIN cteIndex_Size [is]
ON   [ik].[Schema_Name] = [is].[Schema_Name]
AND   [ik].[Table_Name] = [is].[Table_Name]
AND   [ik].[Index_Name] = [is].[Index_Name]

INSERT INTO @tblIndex_Usage_Stats
SELECT  [i].[object_id],
   OBJECT_NAME(i.[object_id]),
   [i].[name],
   [ius].[user_seeks],
   [ius].[user_scans],
   [ius].[user_lookups],
   [ius].[user_updates],
   [ius].[last_user_seek],
   [ius].[last_user_scan],
   [ius].[last_user_lookup],
   [ius].[last_user_update]   
FROM  sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes [i]
  ON [ius].[object_id] = [i].[object_id]
AND   [ius].index_id = [i].index_id
WHERE  [ius].database_id = DB_ID()
AND   OBJECTPROPERTY([i].[object_id], 'IsUserTable') = 1 
AND   [i].[index_id] <> 0

/*
--Index details with index keys and storage size
SELECT  CAST(SERVERPROPERTY('servername') AS SYSNAME) AS [SQL_Server_Instance], 
   DB_NAME() AS [Database_Name], 
   *
FROM  @tblIndex_Details [id]
ORDER BY [object_id]
*/

/*
--Index usage statistics
SELECT  CAST(SERVERPROPERTY('servername') AS SYSNAME) AS [SQL_Server_Instance], 
   DB_NAME() AS [Database_Name], 
   *
FROM  @tblIndex_Usage_Stats [ius]
ORDER BY [object_id]
*/

INSERT INTO @tblIndex_Included_Columns ([Schema_Name], [Table_Name], [Index_Name], [Index_Type], [Key_Columns], [Included_Columns])
SELECT
    SCHEMA_NAME(t.schema_id) AS [Schema_Name],
    t.name AS [Table_Name],
    i.name AS [Index_Name],
    i.type_desc AS [Index_Type],

    -- Key Columns (ordered with ASC/DESC)
    KeyColumns = STUFF
    (
        (
            SELECT ', ' + QUOTENAME(c.name) +
                   CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
            FROM sys.index_columns ic
            INNER JOIN sys.columns c
                ON ic.object_id = c.object_id
               AND ic.column_id = c.column_id
            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.is_included_column = 0
            ORDER BY ic.key_ordinal
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)')
    ,1,2,''),
    -- Included Columns
    IncludedColumns = STUFF
    (
        (
            SELECT ', ' + QUOTENAME(c.name)
            FROM sys.index_columns ic
            INNER JOIN sys.columns c
                ON ic.object_id = c.object_id
               AND ic.column_id = c.column_id
            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.is_included_column = 1
            ORDER BY ic.index_column_id
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)')
    ,1,2,'')
FROM sys.indexes i
INNER JOIN sys.tables t
    ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND i.index_id > 0   -- Exclude heaps
ORDER BY
    [Schema_Name],
    [Table_Name],
    [Index_Name];

--SELECT * FROM @tblIndex_Included_Columns


SELECT  CAST(SERVERPROPERTY('servername') AS SYSNAME) AS [SQL_Server_Instance], 
   DB_NAME() AS [Database_Name], 
   [id].[Schema_Name],
   [id].[Table_Name],
   [id].[Index_Name],
   [id].[Row_Count],
   [id].[Total_Size_MB],
   [ius].[User_Seeks],
   [ius].[User_Scans],
   [ius].[User_Lookups],
   [ius].[User_Updates],
   [ius].[Last_User_Seek],
   [ius].[Last_User_Scan],
   [ius].[Last_User_Lookup],
   [ius].[Last_User_Update],
   [id].[Index_Description],
   [id].[Index_Keys],
   [iic].[Included_Columns],
   GETDATE() AS Date_Captured
FROM  @tblIndex_Details [id]
LEFT JOIN @tblIndex_Usage_Stats [ius]
ON    [id].[object_id] =  [ius].[object_id]
AND   [id].Table_Name = [ius].[Table_Name]
AND   [id].[Index_Name] = [ius].[Index_Name]
LEFT JOIN @tblIndex_Included_Columns [iic]
ON    [id].Table_Name = [iic].[Table_Name]
AND   [id].[Index_Name] = [iic].[Index_Name]
ORDER BY [ius].[user_seeks] DESC
