SELECT
	t.[name] AS [Table Name],
	i.[name] AS [Index Name],
	i.[type_desc] AS [Index Type],
	i.[is_unique] AS [Is Unique],
	i.[is_primary_key] AS [Is Primary Key],
	i.[fill_factor] AS [Fill Factor],
	i.[has_filter] AS [Has Filter],
	i.[filter_definition] AS [Filter Definition],
	ius.[user_scans] AS [User Scans],
	ius.[user_seeks] AS [User Seeks],
	ius.[user_lookups] AS [User Lookups],
	ius.[user_updates] AS [User Updates]
FROM
	sys.tables AS t
LEFT JOIN
	sys.indexes AS i
		ON t.[object_id] = i.[object_id]
LEFT JOIN
	sys.dm_db_index_usage_stats ius
		ON i.[object_id] = ius.[object_id]
		AND ius.[index_id] = i.[index_id]
WHERE
	ius.database_id = DB_ID(DB_NAME())
--	and t.name = 'Table Name'
--	and i.name = 'Index Name'
ORDER BY
	ius.user_scans DESC
