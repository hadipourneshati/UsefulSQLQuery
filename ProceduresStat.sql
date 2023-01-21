select
	DB_NAME(ps.database_id) as [DatabaseName],
	p.[name] as [ProcedureName],
	ps.last_execution_time,
	ps.execution_count,
	ps.last_elapsed_time / 1000 as last_elapsed_time,
	ps.min_elapsed_time / 1000 as min_elapsed_time,
	ps.max_elapsed_time / 1000 as max_elapsed_time,
	ps.total_elapsed_time / ps.execution_count / 1000 as avg_elapsed_time,
	ph.query_plan
from
	sys.dm_exec_procedure_stats as ps
inner join
	sys.procedures as p
on
	ps.[object_id] = p.[object_id]
cross apply
	sys.dm_exec_query_plan(ps.plan_handle) as ph
where
	p.[name] = 'Procedure Name'
