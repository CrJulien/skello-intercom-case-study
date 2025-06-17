 with joined AS (SELECT
 c.conversation_id,
        cp.conv_part_updated_at,
        conv_part_id,
        c.conversation_rating,
        c.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY cp.conversation_id
            ORDER BY     cp.conv_part_updated_at desc
        ) AS rn

    FROM intercom.dev.fct_conversation_parts           cp
    JOIN intercom.dev.dim_conversations                c   USING (conversation_id)
    JOIN intercom.dev.dim_support_team_members         dstm
         ON c.assignee_id = dstm.support_team_member_id
    WHERE LOWER(cp.conv_part_group) = 'message'
      AND author:type::string            <> 'bot'
      AND (assigned_to:type::string      <> 'bot'
           OR assigned_to:type::string IS NULL)
),
work_days AS (
    SELECT DISTINCT
           DATE_TRUNC(day, conv_part_updated_at) AS work_day
    FROM   joined
),
messages AS (
    SELECT
        conversation_id,
        COUNT(DISTINCT conv_part_id)     AS cnt_messages_in_conv
    FROM joined
    GROUP BY conversation_id
),

response_time AS (
    SELECT
        conversation_id,
        DATEDIFF(second, created_at, conv_part_updated_at) as response_time

    FROM   joined
    WHERE  rn = 1                                           -- first reply only
      AND  DATE_PART(hour, created_at) BETWEEN 9 AND 17     -- business hours
      AND  DAYOFWEEKISO(created_at) BETWEEN 1 AND 5         -- Mon-Fri
      AND  DATE_TRUNC(day, created_at) IN (SELECT work_day FROM work_days)
)

SELECT
corr(j.conversation_rating, r.response_time) as corr_rating_response_time,
corr(j.conversation_rating, m.cnt_messages_in_conv) as corr_rating_conv_cnt_messages
FROM   (select distinct conversation_id, conversation_rating from joined) j
JOIN   response_time       r USING (conversation_id)
join messages m USING (conversation_id)
