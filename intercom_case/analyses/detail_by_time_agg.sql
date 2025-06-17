SELECT
      --DAYOFWEEKISO(c.created_at),
      extract(hour from c.created_at ),
      count(*)
FROM   intercom.dev.dim_conversations c
 group by 1
 order by 2 desc