SELECT t.name AS TableName,
       p.rows AS RowCounts,
       SUM(a.total_pages) * 8 AS TotalSpaceKB,
       SUM(a.used_pages) * 8 AS UsedSpaceKB,
       (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM sys.tables t
    INNER JOIN sys.indexes i
        ON t.object_id = i.object_id
    INNER JOIN sys.partitions p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
    LEFT OUTER JOIN sys.schemas s
        ON t.schema_id = s.schema_id
--WHERE t.name = 'Table Name'
GROUP BY t.name,
         p.rows
ORDER BY TotalSpaceKB DESC;
