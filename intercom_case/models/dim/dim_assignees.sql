with assignees AS (SELECT PARSE_JSON(assignee):id::int AS assignee_id,
                        PARSE_JSON(assignee) :type::string AS assignee_type
                   FROM {{ ref('stg_conversations')}}
                   WHERE PARSE_JSON(assignee):id::int IS NOT NULL
GROUP BY 1, 2
    )
SELECT * FROM assignees