with src as (
    select
conv_part_id,
conversation_id,
TRY_TO_TIMESTAMP(conv_part_created_at) as conv_part_created_at ,
TRY_TO_TIMESTAMP(conv_part_updated_at) as conv_part_updated_at,
TRY_TO_TIMESTAMP(conv_part_notified_at) as conv_part_notified_at,
conv_part_group,
TRY_PARSE_JSON(author) as author,
TRY_PARSE_JSON(assigned_to) as assigned_to,
attachments
from {{ ref('stg_conversation_parts') }}
)
select * from src