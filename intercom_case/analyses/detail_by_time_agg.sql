WITH hours AS (SELECT
                   'hour_of_day' as time_agg,
                   extract(hour from c.created_at) as period,
                   count(*) as cnt_conv
               FROM intercom.dev.dim_conversations c
               group by 1, 2
               order by 2),
days AS (SELECT
                   'day_of_week' as time_agg,
                   DAYOFWEEKISO(c.created_at) as period ,
                   count(*) as cnt_conv
               FROM intercom.dev.dim_conversations c
               group by 1, 2
               order by 2)
select * from hours
union all
select * from days