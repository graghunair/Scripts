USE [<dbname>]        
GO        

SET ANSI_NULLS ON        
GO        
SET QUOTED_IDENTIFIER ON        
GO        
IF  EXISTS (SELECT TOP 1 1 FROM sys.tables WHERE [name] = 'tblDBMon_DM_IO_Virtual_File_Stats' AND SCHEMA_NAME([schema_id]) = 'dbo')            
	BEGIN                
		DROP TABLE [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]                
		PRINT 'Table: [dbo].[tblDBMon_DM_IO_Virtual_File_Stats] dropped.'            
	END        
GO         

CREATE TABLE [dbo].[tblDBMon_DM_IO_Virtual_File_Stats](                            
	[Date_Captured] [datetime] NOT NULL CONSTRAINT [DF_tblDBMon_DM_IO_Virtual_File_Stats_Date_Captured]  DEFAULT (getdate()),              
	[Database_Name] [nvarchar](128) NULL,                            
	[Type] [nvarchar](60) NULL,                            
	[Logical_Name] [sysname] NOT NULL,                      
	[Reads] [bigint] NOT NULL,                            
	[Reads_KB] [bigint] NULL,                            
	[Reads_IO_Stalls_ms] [bigint] NOT NULL,                            
	[Writes] [bigint] NOT NULL,                            
	[Writes_KB] [bigint] NULL,                            
	[Writes_IO_Stalls_ms] [bigint] NOT NULL,                            
	[Total_IO_Stall_ms] [bigint] NOT NULL,                            
	[File_Size_MB] [numeric](20, 2) NULL,                            
	[PhysicalName] [nvarchar](260) NOT NULL)       
GO

USE [<dbname>]
GO
SET NOCOUNT ON

IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [name] = 'uspDBMon_GetIOStats')    
	BEGIN        
		PRINT 'DROPPING EXISTING uspDBMon_GetIOStats PROCEDURE'        
		DROP PROCEDURE [dbo].[uspDBMon_GetIOStats]    
	END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspDBMon_GetIOStats]
AS

/*    
	Author	:    Raghu Gopalakrishnan    
	Date	:    07 January 2020    
	Purpose	:    This Stored Procedure is used to capture IO Stats.    
	Version :    1.0                              

			exec [dbo].[uspDBMon_GetIOStats]                
			SELECT * FROM [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]      
			
	Modification History    
	-----------------------    
	Sept 15th, 2014    :    v1.0    :    Raghu Gopalakrishnan    :    Inception
*/
SET NOCOUNT ON  
--Capture the IO-stats

INSERT INTO 	[dbo].[tblDBMon_DM_IO_Virtual_File_Stats]
SELECT		GETDATE() AS Date_Captured,
		DB_NAME(v.database_id) as 'Database_Name',            
		type_desc as 'Type', 
		name as 'Logical_Name',            
		num_of_reads as 'Reads',  
		num_of_bytes_read/1024 as 'Reads_KB', 
		io_stall_read_ms as 'Reads_IO_Stalls_ms',            
		num_of_writes as 'Writes', 
		num_of_bytes_written/1024 as 'Writes_KB', 
		io_stall_write_ms as 'Writes_IO_Stalls_ms',            
		io_stall as 'Total_IO_Stall_ms',            
		cast(size_on_disk_bytes/1048576.0 as numeric(20,2)) as 'File_Size_MB',            
		physical_name as 'PhysicalName'
FROM        	sys.dm_io_virtual_file_stats(NULL, NULL) v
INNER JOIN    	sys.master_files f        
	ON    	(v.database_id=f.database_id AND v.file_id=f.file_id)

DELETE TOP (10000)FROM    [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]
WHERE    [Date_Captured] < GETDATE() - 10
GO


exec sp_addextendedproperty            
@name = 'Version', @value = '1.0',           
@level0type = 'SCHEMA', 
@level0name = 'dbo',            
@level1type = 'PROCEDURE', 
@level1name = 'uspDBMon_GetIOStats'    


EXEC [dbo].[uspDBMon_GetIOStats]    

SELECT * FROM [dbo].[tblDBMon_DM_IO_Virtual_File_Stats]  