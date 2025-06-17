/* ───────────────────────── 1. Raw join + business filters ────────────────── */
WITH joined AS (

    SELECT
        cp.*,
        dstm.*,
        c.created_at,

        /* Monday of ISO-week that contains created_at */
        DATEADD(
            day,
            1 - DAYOFWEEKISO(c.created_at),
            DATE_TRUNC(day, c.created_at)
        ) AS week_start,

        ROW_NUMBER() OVER (
            PARTITION BY cp.conversation_id
            ORDER BY     cp.conv_part_updated_at
        ) AS rn

    FROM intercom.dev.fct_conversation_parts           cp
    JOIN intercom.dev.dim_conversations                c   USING (conversation_id)
    JOIN intercom.dev.dim_assignees                    da  USING (assignee_id)
    JOIN intercom.dev.dim_support_team_members         dstm
         ON da.assignee_id = dstm.support_team_member_id
    WHERE LOWER(cp.conv_part_group) = 'message'
      AND author:type::string            <> 'bot'
      AND (assigned_to:type::string      <> 'bot'
           OR assigned_to:type::string IS NULL)
),

/* ─────────────────── 2. Workload metrics (conv & messages) ───────────────── */
workload AS (
    SELECT
        support_team_member_id,
        week_start,

        COUNT(DISTINCT conversation_id)  AS cnt_conv_responded,
        COUNT(DISTINCT conv_part_id)     AS cnt_messages_sent
    FROM joined
    GROUP BY support_team_member_id, week_start
),

/* ───── 3. Days where at least one support agent has worked (conv update) ─── */
work_days AS (
    SELECT DISTINCT
           DATE_TRUNC(day, conv_part_updated_at) AS work_day
    FROM   joined
),

/* ──────────── 4. Response time & SLA (first message within each conv) ────── */
response_time AS (
    SELECT
        support_team_member_id,
        week_start,

        AVG(DATEDIFF(second, created_at, conv_part_updated_at))
            AS avg_response_time,

        COUNT(DISTINCT conversation_id)
            AS cnt_conv_used_for_avg_response_time,

        SUM(
            IFF(DATEDIFF(second, created_at, conv_part_updated_at) > 300, 1, 0)
        )   AS cnt_sla_5min_or_more

    FROM   joined
    WHERE  rn = 1                                           -- first reply only
      AND  DATE_PART(hour, created_at) BETWEEN 9 AND 17     -- business hours
      AND  DAYOFWEEKISO(created_at) BETWEEN 1 AND 5         -- Mon-Fri
      AND  DATE_TRUNC(day, created_at) IN (SELECT work_day FROM work_days)
    GROUP BY support_team_member_id, week_start
),

/* ─────────────── 5. Conversation-level quality metrics  ─────── */
conv_table_metrics AS (
    SELECT
        dstm.support_team_member_name,
        dstm.support_team_member_id,

        /* Monday of week for the dim_conversations table */
        DATEADD(
            day,
            1 - DAYOFWEEKISO(c.created_at),
            DATE_TRUNC(day, c.created_at)
        ) AS week_start,

        COUNT(*)                                        AS cnt_conv,
        SUM(IFF(c.conversation_rating IS NULL, 0, 1))   AS cnt_ratings,
        SUM(IFF(c.conversation_rating >= 4 , 1, 0))     AS cnt_satisfactory_ratings,
        SUM(IFF(c.conversation_rating <= 2 , 1, 0))     AS cnt_unsatisfactory_ratings,
        SUM(IFF(ARRAY_SIZE(c.conversation_tags_array) > 0, 1, 0))
                                                        AS cnt_tags
    FROM   intercom.dev.dim_conversations            c
    JOIN   intercom.dev.dim_assignees                da  USING (assignee_id)
    JOIN   intercom.dev.dim_support_team_members     dstm
           ON da.assignee_id = dstm.support_team_member_id
    GROUP  BY dstm.support_team_member_name,
             dstm.support_team_member_id,
             week_start
)

/* ───────────────────────────── 6. Final merge ───────────────────────────── */
SELECT
    'Global' as team,
    c.week_start,
    c.support_team_member_name,
    c.support_team_member_id,

    /* quality metrics */
    c.cnt_conv,
    c.cnt_ratings,
    c.cnt_satisfactory_ratings,
    c.cnt_unsatisfactory_ratings,
    c.cnt_tags,

    /* workload metrics */
    w.cnt_conv_responded,
    w.cnt_messages_sent,

    /* response time metrics */
    r.avg_response_time,
    r.cnt_conv_used_for_avg_response_time,
    r.cnt_sla_5min_or_more

FROM   conv_table_metrics  c
JOIN   workload            w USING (support_team_member_id, week_start)
JOIN   response_time       r USING (support_team_member_id, week_start)
ORDER  BY week_start DESC;