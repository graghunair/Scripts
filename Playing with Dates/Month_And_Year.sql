SET NOCOUNT ON
GO
DECLARE @varStartDate DATE = '12-01-2014'
DECLARE @varEndDate DATE = '12-31-2014'
DECLARE @varFilePath VARCHAR(2000) = 'D:\Temp\'
DECLARE @varFileName VARCHAR(2000)

WHILE (@varStartDate < '01-01-2018')
	BEGIN

		SET @varFileName = 'Output-' + CAST(DATENAME(month, @varStartDate) AS VARCHAR) + '_' + CAST(YEAR(@varStartDate) AS VARCHAR) + '.csv'
		SET @varFileName = @varFilePath + @varFileName
		PRINT 'BETWEEN ' + CAST(@varStartDate AS VARCHAR) + ' AND ' + CAST(@varEndDate AS VARCHAR)
		SELECT @varStartDate = DATEADD(mm, 1, @varStartDate)
		SELECT @varEndDate = DATEADD(mm, 1, @varEndDate)
		IF (MONTH(@varEndDate) IN (1,3,5,7,8,10,12))
			BEGIN
				SELECT @varEndDate = DATEFROMPARTS(
											DATEPART(YEAR, @varEndDate),
											DATEPART(MONTH, @varEndDate),
											31)
			END
	END
GO
