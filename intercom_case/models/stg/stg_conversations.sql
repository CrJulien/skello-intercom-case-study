with src as (
    select
        id as conversation_id,
        created_at,
        updated_at,
        open,
        priority,
        read as is_read,
        state,
        type,
        waiting_since,
        snoozed_until,
        assignee,
        conversation_rating,
        tags,
        _sdc_batched_at,
        _sdc_extracted_at,
        _sdc_received_at,
        _sdc_sequence,
        _sdc_table_version
    from {{ source('intercom', 'conversations') }}
    where id is not null
),
dedup as (
    select
        src.*,
        row_number() over (
            partition by conversation_id
        order by 1
        ) as rn
    from src
)
select *
from dedup
qualify rn = 1