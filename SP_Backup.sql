SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Hadi Pourneshati
-- Create date: 2023-01-23
-- Modified date: 2023-01-29
-- Description:	This procedure created for take Backup from Database
/* TODO:
	add file and file group to backup.
*/

-- =============================================
/* Usage
EXECUTE [Backup]
	@DatabaseName = NULL			-- 'ALLDATABASES', 'SYSTEMDATABASES', 'USERDATABASES', 'DatabaseName', 'DatabaseName1,DatabaseName2', ...
,	@BackupType= NULL				-- 'FULL', 'DIFF', 'LOG'
,	@IsCopyOnly = 0					-- 0 = not copyonly, 1 = copy only
,	@IsCompress = 0					-- 0 = not compress, 1 = compress
,	@RetainDays = NULL				-- 1, 2, 3, ...
,	@BlockSize = NULL				-- 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536
,	@BufferCount = NULL				-- 1, 2, 3, ...
,	@MaxTransferSize = NULL			-- multiples of 65536
,	@Checksum = 0					-- 0 = no checksum, 1 = checksum
,	@BackupDevice = NULL			-- name of backup device
,	@BackupPath = NULL				-- 'C:\Backup'
,	@NumberOfFiles = 1				-- 1, 2, 3, ...
,	@HadrBackupNode = NULL			-- 'Primary', 'Secondary', 'Preferred'
,	@SkipHadrBackupNodeError = 0	-- 0 = no skip, 1 = skip
*/
-- =============================================
ALTER PROCEDURE [Backup]
	@DatabaseName NVARCHAR(MAX) = NULL
,	@BackupType NVARCHAR(10) = NULL
,	@IsCopyOnly BIT = 0
,	@IsCompress BIT = 0
,	@RetainDays INT = NULL
,	@BlockSize INT = NULL
,	@BufferCount INT = NULL
,	@MaxTransferSize INT = NULL
,	@Checksum BIT = 0 
,	@BackupDevice SYSNAME = NULL
,	@BackupPath NVARCHAR(MAX) = NULL
,	@NumberOfFiles INT = 1
,	@HadrBackupNode NVARCHAR(MAX) = NULL
,	@SkipHadrBackupNodeError BIT = 0
AS
BEGIN
	SET NOCOUNT ON

/* Declare and init required variables/Tables */
	DECLARE @DatabaseNameQuery NVARCHAR(MAX)
	DECLARE @HadrBackupNodeQuery NVARCHAR(MAX)
	DECLARE @HadrBackupNodeResult INT
	DECLARE @Error BIT
	DECLARE @ErrorMessage NVARCHAR(MAX)
	DECLARE @BackupFileExtension CHAR(3)
	DECLARE @BackupPathFullName NVARCHAR(MAX)
	DECLARE @BackupPathTime NVARCHAR(MAX)
	DECLARE @FileCounter INT = 0
	DECLARE @SqlText NVARCHAR(MAX)
	DECLARE @Options NVARCHAR(MAX)
	DECLARE @PurgeText NVARCHAR(MAX)
	IF OBJECT_ID(N'tempdb.dbo.#DataBases', N'U') IS NOT NULL
	BEGIN
		DROP TABLE #DataBases
	END
	CREATE TABLE #DataBases ([DatabaseName] NVARCHAR(MAX))

	IF @BackupPath IS NOT NULL
	BEGIN
		SET @BackupPath += IIF(RIGHT(@BackupPath, 1) <> '\', N'\', N'')
	END
	IF @BackupType = N'FULL'
	BEGIN
		SET @BackupFileExtension = N'BAK'
	END
	IF @BackupType = N'DIFF'
	BEGIN
		SET @BackupFileExtension = N'DIF'
	END
	IF @BackupType = N'LOG'
	BEGIN
		SET @BackupFileExtension = N'TRN'
	END
	SET @Options = N' WITH' + IIF(@BackupType = N'DIFF', N' DIFFERENTIAL, ', N'') + N' NOINIT, NOSKIP, NOFORMAT, STOP_ON_ERROR'
	SET @Options += IIF(@IsCopyOnly = 1, N', COPY_ONLY', N'')
	SET @Options += IIF(@IsCompress = 1, N', COMPRESSION', N', NO_COMPRESSION')
	SET @Options += IIF((@BackupDevice IS NOT NULL) AND (@BackupPath IS NULL) AND (@RetainDays IS NOT NULL),N', RETAINDAYS = ' + CAST(@RetainDays AS NVARCHAR(MAX)),N'')
	SET @Options += IIF(@BlockSize IS NOT NULL, N', BLOCKSIZE = ' + CAST(@BlockSize AS NVARCHAR(MAX)), N'')
	SET @Options += IIF(@BufferCount IS NOT NULL, N', BUFFERCOUNT = ' + CAST(@BufferCount AS NVARCHAR(MAX)), N'')
	SET @Options += IIF(@MaxTransferSize IS NOT NULL, N', MAXTRANSFERSIZE = ' + CAST(@MaxTransferSize AS NVARCHAR(MAX)), N'')
	SET @Options += IIF(@Checksum = 1, N', CHECKSUM', N'')
---------------------------------------------------------------------------------------------------------

/* Init #Databases */
	IF @DatabaseName = N'ALLDATABASES'
	BEGIN
		SET @DatabaseNameQuery = N'INSERT INTO #DataBases ([DatabaseName]) SELECT [name] FROM master.sys.databases WHERE [name] <> N''tempdb'' ORDER BY database_id'
	END
	ELSE IF @DatabaseName = N'SYSTEMDATABASES'
	BEGIN
		SET @DatabaseNameQuery = N'INSERT INTO #DataBases ([DatabaseName]) SELECT [name] FROM master.sys.databases WHERE [name] IN (N''master'', N''model'', N''msdb'') ORDER BY database_id'
	END
	ELSE IF @DatabaseName = N'USERDATABASES'
	BEGIN
		SET @DatabaseNameQuery = N'INSERT INTO #DataBases ([DatabaseName]) SELECT [name] FROM master.sys.databases WHERE [name] NOT IN (N''master'', N''model'', N''msdb'', N''tempdb'') ORDER BY database_id'
	END
	ELSE
	BEGIN
		SET @DatabaseNameQuery = N'INSERT INTO #DataBases ([DatabaseName]) SELECT [value] FROM string_split(@DatabaseName, N'','')'
	END
	EXECUTE master.dbo.sp_executesql @DatabaseNameQuery, N'@DatabaseName NVARCHAR(MAX)', @DatabaseName = @DatabaseName
---------------------------------------------------------------------------------------------------------

/* handle error */
	SET @Error = 0
	IF (@BackupType IS NULL) OR (@BackupType NOT IN ('FULL', 'DIFF', 'LOG'))
	BEGIN
		SET @Error = 1
		SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'@BackupType must be one of FULL, DIFF or LOG and can not be NULL.'
	END
	IF (@BackupDevice IS NULL) AND (@BackupPath iS NULL)
	BEGIN
		SET @Error = 1
		SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'@BackupDevice is NULL AND @BackupPath is NULL.'
	END
	IF (@BackupDevice IS NOT NULL) AND (NOT EXISTS (SELECT TOP(1) 1 FROM master.sys.backup_devices WHERE [name] = @BackupDevice))
	BEGIN
		SET @Error = 1
		SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'BackupDevice ' + @BackupDevice + ' is not exists.'
	END
	IF (@BlockSize IS NOT NULL) AND (@BlockSize NOT IN (512, 1024, 2048, 4096, 8192, 16384, 32768, 65536))
	BEGIN
		SET @Error = 1
		SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'@BlockSize NOT IN (512, 1024, 2048, 4096, 8192, 16384, 32768, 65536)'
	END
	IF (@MaxTransferSize IS NOT NULL) AND (@MaxTransferSize % 65536 <> 0)
	BEGIN
		SET @Error = 1
		SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'@MaxTransferSize must be multiples of 65536'
	END

	DECLARE @DBName NVARCHAR(MAX)
	DECLARE CursorCheckDB CURSOR FOR
		SELECT [DatabaseName] FROM #DataBases
	OPEN CursorCheckDB
	FETCH NEXT FROM CursorCheckDB INTO @DBName
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		IF NOT EXISTS(SELECT TOP (1) 1 FROM master.sys.databases WHERE [name] = @DBName)
		BEGIN
			SET @Error = 1
			SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'Database: ' + @DBName + N' is not exist.'
		END
		IF @HadrBackupNode IS NULL
		BEGIN
			SET @HadrBackupNodeQuery = N'SET @HadrBackupNodeResult = 1'
		END
		ELSE IF @HadrBackupNode = N'Primary'
		BEGIN
			SET @HadrBackupNodeQuery = N'SET @HadrBackupNodeResult = sys.fn_hadr_is_primary_replica(''' + @DBName + ''')'
		END
		ELSE IF @HadrBackupNode = N'Secondary'
		BEGIN
			SET @HadrBackupNodeQuery = N'SET @HadrBackupNodeResult = (sys.fn_hadr_is_primary_replica(''' + @DBName + ''') - 1) * -1'
		END
		ELSE IF @HadrBackupNode = N'Preferred'
		BEGIN
			SET @HadrBackupNodeQuery = N'SET @HadrBackupNodeResult = sys.fn_hadr_backup_is_preferred_replica(''' + @DBName + ''')'
		END
		EXECUTE master.dbo.sp_executesql @HadrBackupNodeQuery, N'@HadrBackupNodeResult INT OUTPUT', @HadrBackupNodeResult = @HadrBackupNodeResult OUTPUT
		IF ISNULL(@HadrBackupNodeResult, 1) = 0
		BEGIN
			IF @SkipHadrBackupNodeError = 0
			BEGIN
				SET @Error = 1
			END
			DELETE FROM #DataBases WHERE [DatabaseName] = @DBName
			SET @ErrorMessage = COALESCE(@ErrorMessage + CHAR(13)+CHAR(10), N'') + N'Database: ' + @DBName + N' is not on HADR backup node.'
		END
	FETCH NEXT FROM CursorCheckDB INTO @DBName
	END
	CLOSE CursorCheckDB
	DEALLOCATE CursorCheckDB

	IF @Error = 1
	BEGIN
		GOTO ExitFail
	END
---------------------------------------------------------------------------------------------------------
/* Backup */
	WHILE EXISTS (SELECT TOP(1) 1 FROM #DataBases)
	BEGIN
		SET @DatabaseName = (SELECT TOP(1) [DatabaseName] FROM #DataBases)
		IF @BackupPath IS NOT NULL
		BEGIN
			SET @FileCounter = 0
			SET @BackupPathFullName = NULL
			SET @BackupPathTime = REPLACE(REPLACE(CONVERT(CHAR(19), GETDATE(), 126), N'-', N''), N':', N'')
			WHILE @FileCounter < @NumberOfFiles
			BEGIN
				SET @BackupPathFullName = COALESCE(@BackupPathFullName + N', ', N'') + N'DISK = N''' + @BackupPath + @DatabaseName + N'_' + @BackupPathTime + IIF(@NumberOfFiles > 1, N'_' + CAST(@FileCounter AS NVARCHAR(MAX)), N'') + N'.' + @BackupFileExtension + N''''
				SET @FileCounter += 1
			END
		END
		SET @SqlText = N'BACKUP' + IIF(@BackupType = N'LOG', N' LOG ', N' DATABASE ') + N'[' + @DatabaseName + N'] TO ' + COALESCE(N'[' + @BackupDevice + N']', @BackupPathFullName) + @Options
		-- PRINT @SqlText
		EXECUTE master.dbo.sp_executesql @SqlText
		DELETE FROM #DataBases WHERE DatabaseName = @DatabaseName
	END
---------------------------------------------------------------------------------------------------------

/* Purge */
	IF (@RetainDays IS NOT NULL) AND (@BackupPath IS NOT NULL)
	BEGIN
		SET @PurgeText = N'EXECUTE master.dbo.xp_delete_file 0, ''' + @BackupPath + N''', ''' + @BackupFileExtension + N''', ''' + CONVERT(NVARCHAR(MAX), DATEADD(DAY, (@RetainDays * -1), GETDATE()), 25) + N''', 0'
		-- PRINT @PurgeText
		EXECUTE master.dbo.sp_executesql @PurgeText
	END
---------------------------------------------------------------------------------------------------------

	IF (@Error = 0) AND (@ErrorMessage IS NULL)
	BEGIN
		GOTO ExitSuccess
	END
	ELSE IF (@Error = 0) AND (@ErrorMessage IS NOT NULL)
	BEGIN
		GOTO ExitPartiallySuccess
	END


/* Exit from procedure */
ExitFail:
	RAISERROR(@ErrorMessage, 16,1)
	RETURN

ExitPartiallySuccess:
	RAISERROR(@ErrorMessage, 10,1)
	RETURN

ExitSuccess:
	RETURN
---------------------------------------------------------------------------------------------------------

END
