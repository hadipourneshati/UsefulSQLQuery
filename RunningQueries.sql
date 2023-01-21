select
	r.session_id,
	s.[host_name],
	s.login_name,
	DB_NAME(r.database_id) as [database_name],
	r.command,
	r.blocking_session_id,
	r.total_elapsed_time / 1000 as total_elapsed_time_sec,
	r.estimated_completion_time / 1000 as estimated_completion_time_sec,
	r.percent_complete,
	r.wait_type,
	t.[text] as [query_text],
	p.query_plan
from sys.dm_exec_requests as r
inner join sys.dm_exec_sessions as s
on r.session_id = s.session_id
cross apply sys.dm_exec_sql_text(r.sql_handle) as t
cross apply sys.dm_exec_query_plan(r.plan_handle) as p
-- where s.session_id <> @@SPID --ignore current session
-- where s.host_name = 'machinename'
-- where s.login_name = 'someone'
