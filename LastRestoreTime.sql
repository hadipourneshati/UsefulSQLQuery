WITH LastRestores AS
(
SELECT
    [d].[name] as DatabaseName,
    [d].[create_date],
    r.restore_date,
	r.user_name,
	r.restore_type,
	r.replace,
    ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC) as rn
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
)
SELECT
	LastRestores.DatabaseName,
	LastRestores.create_date,
	LastRestores.restore_date,
	LastRestores.user_name,
	LastRestores.restore_type,
	LastRestores.replace
FROM [LastRestores]
WHERE [rn] = 1
ORDER BY LastRestores.restore_date DESC
