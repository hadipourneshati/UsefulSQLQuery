SELECT
	'ALTER DATABASE ['
	+ d.[name]
	+ '] MODIFY FILE (NAME = ['
	+ f.[name] + '],'
	+ ' FILENAME = ''Z:\MSSQL\DATA\' --new location
	+ REVERSE( LEFT( REVERSE(f.physical_name), CHARINDEX( '\', REVERSE(f.physical_name) ) - 1 ) )
	+ ''');' as [Query]
FROM sys.master_files AS f
INNER JOIN sys.databases AS d
ON f.database_id = d.database_id
WHERE f.database_id = DB_ID(N'tempdb');
