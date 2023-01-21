select
	 s.[name] + '.' + t.[name] as [table_name]
	,i.[name] as [index_name]
	,iu.user_seeks
	,iu.user_lookups
	,iu.user_scans
	,iu.user_updates
from
	sys.tables as t
inner join
	sys.schemas as s
		on t.[schema_id] = s.[schema_id]
inner join
	sys.indexes as i
		on t.[object_id] = i.[object_id]
inner JOIN
	sys.dm_db_index_usage_stats as iu
		ON i.[object_id] = iu.[object_id]
		AND i.[index_id] = iu.[index_id]
where
	i.is_disabled = 0 -- not disabled
and
	i.[type] <> 0 -- not HEAP
and
	i.is_primary_key = 0 -- not primary key
and
	i.is_unique = 0
and
	i.is_unique_constraint = 0 -- not part of unique constraint
order by
	iu.user_seeks, iu.user_lookups, iu.user_scans, iu.user_updates desc
