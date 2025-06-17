with src as (
    select
        ID AS support_team_member_id,
        name AS support_team_member_name
    from {{ source('intercom', 'support_team') }}
)
select * from src