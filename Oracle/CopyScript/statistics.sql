
-- statistic 
exec dbms_stats.gather_table_stats(user, 'emp');

set autotrace traceonly exp;



-- view extent list
select segment_type, tablespace_name, extent_id, file_id, block_id, blocks
from dba_extents
where owner = USER
and segment_name = 'MY_SEGMENT'
order by extent_id;


-- show block size
show parameter block_size;

select value from v$parameter where name = 'db_block_size';

-- show buffer cache size
show sga;

-- show multiblock read size
show parameter db_file_multiblock_read_count;


-- add index
CREATE INDEX emp_ix01 ON emp(hiredate)

-- show index
SELECT a.table_name 
     , a.index_name 
     , a.column_name 
     , b.comments 
  FROM user_ind_columns a 
     , user_col_comments b
 WHERE a.table_name = [table_name] 
   AND a.table_owner = b.owner 
   AND a.table_name = b.table_name 
   AND a.column_name = b.column_name 
 ORDER BY a.index_name
        , a.column_position
; 