select
	i.name as [IndexName],
	c.name as [ColumnName],
	i.is_disabled as [IsDisabled]
from
	sys.tables as t
inner join
	sys.indexes as i
		on t.object_id = i.object_id
inner join
	sys.index_columns as ic
		on i.object_id = ic.object_id
		and i.index_id = ic.index_id
inner join
	sys.columns as c
		on ic.object_id = c.object_id
		and ic.column_id = c.column_id
where
	t.name = 'TABLENAME'
--	and i.name = 'INDEXNAME'
	and c.name = 'COLUMNNAME'
