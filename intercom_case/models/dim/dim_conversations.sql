with src as (
    select
        conversation_id,
        TRY_TO_TIMESTAMP(created_at) as created_at,
        TRY_TO_TIMESTAMP(updated_at) as updated_at,
        TRY_PARSE_JSON(assignee):id::int as assignee_id,
        TRY_PARSE_JSON(conversation_rating):teammate:id::int as teammate_id,
        waiting_since,
        TRY_PARSE_JSON(conversation_rating):rating::int as conversation_rating,
        TRY_PARSE_JSON(conversation_rating):remark::string as conversation_remark,
        priority,
        is_read,
        TRY_PARSE_JSON(tags) as tags
    from {{ ref('stg_conversations') }}
),
tags_flat as (
    select
        s.conversation_id,
        f.index as tag_index,
        f.value:name::string as tag_name
    from src s,
         lateral flatten(input => s.tags) f
)
select
    conversation_id,
    created_at,
    updated_at,
    assignee_id,
    teammate_id,
    waiting_since,
    conversation_rating,
    conversation_remark,
    priority,
    is_read,
    array_agg(
         case
            when tag_index is not null then
                object_construct(
                    'index',    tag_index,
                    'tag_name', tag_name
                )
        end
    ) as conversation_tags_array
from src s
left join tags_flat t using(conversation_id)
group by
    conversation_id, created_at, updated_at,
    assignee_id, teammate_id,
    waiting_since, conversation_rating, conversation_remark,
    priority, is_read