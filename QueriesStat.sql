select top(100)
	qt.text as [QueryText],
	DB_NAME(qt.dbid) as [Database],
	qp.query_plan as [QueryPlan],
	qs.creation_time as [QueryPlanCompileTime],
	qs.last_execution_time as [LastExecutedTime],
	qs.execution_count as [ExecutionCount],
	qs.last_worker_time / 1000 as [LastWorkerTimeMS],
	qs.total_worker_time / qs.execution_count / 1000 as [AverageWorkerTimeMS],
	qs.last_physical_reads as [LastPhysicalReads],
	qs.total_physical_reads / qs.execution_count as [AveragePhysicalReads],
	qs.last_logical_reads as [LastLogicalReads],
	qs.total_logical_reads / qs.execution_count as [AverageLogicalReads],
	qs.last_logical_writes as [LastLogicalWrites],
	qs.total_logical_writes / qs.execution_count as [AverageLogicalWrites],
	qs.last_elapsed_time / 1000 as [LastElapsedTimeMS],
	qs.total_elapsed_time / qs.execution_count / 1000 as [AverageElapsedTimeMS],
	qs.last_rows as [LastRows],
	qs.total_rows / qs.execution_count as [AverageTotalRows],
	qs.last_dop as [LastDop],
	qs.total_dop / qs.execution_count as [AverageDop],
	qs.last_grant_kb as [LastGrantKB],
	qs.total_grant_kb / qs.execution_count as [AverageGrantKB],
	qs.last_used_grant_kb as [LastUsedGrantKB],
	qs.total_used_grant_kb / qs.execution_count as [AverageUsedGrantKB],
	qs.last_spills as [LastSpills],
	qs.total_spills / qs.execution_count as [AverageSpills]
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp
where last_execution_time >= DATEADD(minute, -10, getdate()) --last 10 minutes
