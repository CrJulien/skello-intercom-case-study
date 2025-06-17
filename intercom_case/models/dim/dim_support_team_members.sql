select
    support_team_member_id,
    support_team_member_name
from {{ ref('stg_support_team_members')}}