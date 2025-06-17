with src as (
select id as conv_part_id,
       conversation_id as conversation_id,
       created_at as conv_part_created_at,
       updated_at as conv_part_updated_at,
       notified_at as conv_part_notified_at,
       conversation_created_at,
       conversation_updated_at,
       type as conv_part_type,
       part_group as conv_part_group,
       author,
       assigned_to,
       attachments,
       _sdc_batched_at,
       _sdc_extracted_at,
       _sdc_received_at,
       _sdc_sequence,
       _sdc_table_version
from {{ source('intercom', 'conversation_parts') }}
where id is not null
),
dedup as (
    select
        src.*,
        count(*) over (partition by conv_part_id) as dup_cnt
    from src
)
select *
from dedup
where dup_cnt = 1 -- ID 114701 FTW