SELECT 
    DB_NAME(dbid) as DatabaseName, 
    COUNT(dbid) as NumberOfConnections,
    loginame as LoginName,
	hostname
FROM
    sys.sysprocesses
WHERE 
    dbid > 0 AND DB_NAME(dbid) = 'Database Name'
GROUP BY 
    dbid, loginame, hostname
;
