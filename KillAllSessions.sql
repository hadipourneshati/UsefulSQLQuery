DECLARE @Query NVARCHAR(MAX)
DECLARE @Table TABLE (SessionID int)
DECLARE @SessionID INT

INSERT INTO @Table (SessionID)
SELECT session_id FROM sys.dm_exec_connections WHERE session_id <> @@SPID --AND client_net_address IN ('192.168.1.1')

WHILE EXISTS (SELECT TOP(1) 1 FROM @Table)
BEGIN
	SELECT TOP(1) @SessionID = SessionID FROM @Table
	SET @Query = N'KILL ' + cast(@SessionID AS NVARCHAR(MAX)) + N';'
	EXEC (@Query)
--	PRINT @Query
	DELETE FROM @Table WHERE SessionID = @SessionID
END
