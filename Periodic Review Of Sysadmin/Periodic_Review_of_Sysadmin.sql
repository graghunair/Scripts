/*
CREATE DATABASE [DBA_DBMon]
GO
ALTER DATABASE [DBA_DBMon] SET RECOVERY SIMPLE
GO
*/

USE [DBA_DBMon]
GO

/*
DROP TABLE IF EXISTS [Whitelist].[Sysadmin_Members]
DROP TABLE IF EXISTS [Load].[Sysadmin_Members]
DROP TABLE IF EXISTS [Inventory].[SQL_Servers]
GO
DROP SCHEMA IF EXISTS [Load]
DROP SCHEMA IF EXISTS [Whitelist]
DROP SCHEMA IF EXISTS [Inventory]
GO
*/

CREATE SCHEMA [Inventory] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [Whitelist] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [Load] AUTHORIZATION [dbo]
GO

DROP TABLE IF EXISTS [Inventory].[SQL_Servers]
GO
CREATE TABLE [Inventory].[SQL_Servers](
	[Server_Name] NVARCHAR(128) NOT NULL,
	[Is_Active] BIT NOT NULL,
	[Date_Disabled] DATETIME NULL,
	[Comments] VARCHAR(2000) NULL,
	[Date_Captured] DATETIME NOT NULL,
	[Captured_By] NVARCHAR(128) NOT NULL)
GO
ALTER TABLE [Inventory].[SQL_Servers] ADD CONSTRAINT [PK_Inventory_SQL_Servers_Server_Name] PRIMARY KEY ([Server_Name]);
ALTER TABLE [Inventory].[SQL_Servers] ADD CONSTRAINT [DF_Inventory_SQL_Servers_Is_Active] DEFAULT 1 FOR [Is_Active]
ALTER TABLE [Inventory].[SQL_Servers] ADD CONSTRAINT [DF_Inventory_SQL_Servers_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured]
ALTER TABLE [Inventory].[SQL_Servers] ADD CONSTRAINT [DF_Inventory_SQL_Servers_Captured_By] DEFAULT SUSER_SNAME() FOR [Captured_By]
GO

DROP TABLE IF EXISTS [Whitelist].[Sysadmin_Members]
GO
CREATE TABLE [Whitelist].[Sysadmin_Members](
	[Server_Name] NVARCHAR(128) NOT NULL,
	[Login_Name] NVARCHAR(128) NOT NULL,
	[Is_Active] BIT NOT NULL,
	[Date_Disabled] DATETIME NULL,
	[Comments] VARCHAR(2000) NULL,
	[Date_Captured] DATETIME NOT NULL,
	[Captured_By] NVARCHAR(128) NOT NULL)
GO

ALTER TABLE [Whitelist].[Sysadmin_Members] ADD CONSTRAINT [PK_Whitelist_Sysadmin_Members_Server_Name] PRIMARY KEY ([Server_Name], [Login_Name])
ALTER TABLE [Whitelist].[Sysadmin_Members] ADD CONSTRAINT [FK_Whitelist_Sysadmin_Members_Inventory_SQL_Servers] FOREIGN KEY ([Server_Name]) REFERENCES [Inventory].[SQL_Servers]([Server_Name]);
ALTER TABLE [Whitelist].[Sysadmin_Members] ADD CONSTRAINT [DF_Whitelist_Sysadmin_Members_Is_Active] DEFAULT 1 FOR [Is_Active]
ALTER TABLE [Whitelist].[Sysadmin_Members] ADD CONSTRAINT [DF_Whitelist_Sysadmin_Members_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured]
ALTER TABLE [Whitelist].[Sysadmin_Members] ADD CONSTRAINT [DF_Whitelist_Sysadmin_Members_Captured_By] DEFAULT SUSER_SNAME() FOR [Captured_By]
GO

DROP TABLE IF EXISTS [Load].[Sysadmin_Members]
GO
CREATE TABLE [Load].[Sysadmin_Members](
	[Server_Name] NVARCHAR(128) NOT NULL,
	[Login_Name] NVARCHAR(128) NOT NULL,
	[Date_Captured] DATETIME NOT NULL)
GO
ALTER TABLE [Load].[Sysadmin_Members] ADD CONSTRAINT [PK_Load_Sysadmin_Members_Server_Name] PRIMARY KEY ([Server_Name], [Login_Name])
ALTER TABLE [Load].[Sysadmin_Members] ADD CONSTRAINT [DF_Load_Sysadmin_Members_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured]
GO

/*
INSERT INTO [Inventory].[SQL_Servers] ([Server_Name]) VALUES ('Server1')
INSERT INTO [Inventory].[SQL_Servers] ([Server_Name]) VALUES ('Server2')
INSERT INTO [Whitelist].[Sysadmin_Members]([Server_Name], [Login_Name]) VALUES('Server1', 'sa')
INSERT INTO [Whitelist].[Sysadmin_Members]([Server_Name], [Login_Name]) VALUES('Server2', 'sa')
*/

SELECT * FROM [Inventory].[SQL_Servers]
SELECT * FROM [Whitelist].[Sysadmin_Members]
SELECT * FROM [Load].[Sysadmin_Members]

--Logins with sysadmin privileges on target SQL Server Instance(s) but not whitelisted.
SELECT			L.Server_Name, 
				L.Login_Name
FROM			[Whitelist].[Sysadmin_Members] W
FULL OUTER JOIN [Load].[Sysadmin_Members] L
			ON	W.Server_Name = L.Server_Name
AND				W.Login_Name = L.Login_Name
WHERE			W.Login_Name IS NULL


--Logins without sysadmin privileges on target SQL Server Instance(s) but whitelisted.
SELECT			W.Server_Name, 
				W.Login_Name
FROM			[Whitelist].[Sysadmin_Members] W
FULL OUTER JOIN [Load].[Sysadmin_Members] L
			ON	W.Server_Name = L.Server_Name
AND				W.Login_Name = L.Login_Name
WHERE			L.Login_Name IS NULL
GO

DROP PROCEDURE IF EXISTS [Report].[rptGetNonComplaintSysadminLogins]
DROP SCHEMA IF EXISTS [Report]
GO
CREATE SCHEMA [Report] AUTHORIZATION [dbo]
GO

CREATE PROCEDURE [Report].[rptGetNonComplaintSysadminLogins]
@Mail_Recipients VARCHAR(MAX)
AS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
	
	--Variable declarations
	DECLARE @tableHTML1 VARCHAR(max)
	DECLARE @tableHTML2 VARCHAR(max)
	DECLARE @Mail_Subject VARCHAR(255)
	DECLARE @varFlag BIT = 0
	
	--Logins with sysadmin privileges on target SQL Server Instance(s) but not whitelisted.
	SELECT			L.Server_Name, 
					L.Login_Name
	FROM			[Whitelist].[Sysadmin_Members] W
	FULL OUTER JOIN [Load].[Sysadmin_Members] L
				ON	W.Server_Name = L.Server_Name
	AND				W.Login_Name = L.Login_Name
	WHERE			W.Login_Name IS NULL


	--Logins Whitelisted but dont have sysadmin privileges on target SQL Server Instances
	SELECT			W.Server_Name, 
					W.Login_Name
	FROM			[Whitelist].[Sysadmin_Members] W
	FULL OUTER JOIN [Load].[Sysadmin_Members] L
				ON	W.Server_Name = L.Server_Name
	AND				W.Login_Name = L.Login_Name
	WHERE			L.Login_Name IS NULL

	IF EXISTS (SELECT TOP 1 1 FROM [Whitelist].[Sysadmin_Members] W FULL OUTER JOIN [Load].[Sysadmin_Members] L ON	W.Server_Name = L.Server_Name AND W.Login_Name = L.Login_Name WHERE	W.Login_Name IS NULL)
		BEGIN
			SET @varFlag = 1
			SET @tableHTML1 =	
								N'<H5>Logins with sysadmin privileges on target SQL Server Instance(s) but not whitelisted.</H5>' +
								N'<table border="1" style="margin-left:3em">' +
								N'<tr><th>ID</th><th>Server_Name</th><th>Login_Name</th></tr>' +
								CAST ( (	SELECT			td = ROW_NUMBER() OVER(ORDER BY L.Server_Name, L.Login_Name), '',
															td = L.Server_Name,  '',
															td = L.Login_Name
											FROM			[Whitelist].[Sysadmin_Members] W
											FULL OUTER JOIN [Load].[Sysadmin_Members] L
														ON	W.Server_Name = L.Server_Name
											AND				W.Login_Name = L.Login_Name
											WHERE			W.Login_Name IS NULL
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
		END

	IF EXISTS (SELECT TOP 1 1 FROM [Whitelist].[Sysadmin_Members] W FULL OUTER JOIN [Load].[Sysadmin_Members] L ON	W.Server_Name = L.Server_Name AND W.Login_Name = L.Login_Name WHERE	L.Login_Name IS NULL)
		BEGIN
			SET @varFlag = 1
			SET @tableHTML2 =	
								N' ' +
								N'<H5>Logins without sysadmin privileges on target SQL Server Instance(s) but whitelisted.</H5>' +
								N'<table border="1" style="margin-left:3em">' +
								N'<tr><th>ID</th><th>Server_Name</th><th>Login_Name</th></tr>' +
								CAST ( (	SELECT			td = ROW_NUMBER() OVER(ORDER BY W.Server_Name, W.Login_Name), '',
															td = W.Server_Name,  '',
															td = W.Login_Name
											FROM			[Whitelist].[Sysadmin_Members] W
											FULL OUTER JOIN [Load].[Sysadmin_Members] L
														ON	W.Server_Name = L.Server_Name
											AND				W.Login_Name = L.Login_Name
											WHERE			L.Login_Name IS NULL
								FOR XML PATH('tr'), TYPE ) AS NVARCHAR(MAX) ) +	N'</table>'
		END

	IF (@varFlag = 1)	
		BEGIN
			SET @tableHTML1 = @tableHTML1 + @tableHTML2
			SELECT @Mail_Subject = '[SQL Server]: Sysadmin Members Compliance Report.'

			EXEC msdb.dbo.sp_send_dbmail 
					@recipients=@Mail_Recipients,
					@subject = @Mail_Subject,
					@body = @tableHTML1,
					@body_format = 'HTML'
		END
	ELSE
		BEGIN
			PRINT 'No discrepancy found with sysadmin members.'
		END
GO

EXEC [Report].[rptGetNonComplaintSysadminLogins]
GO
