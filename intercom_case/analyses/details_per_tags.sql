
with tags_list AS (
    SELECT
      c.conversation_id,
        f.index as tag_index,
        f.value:tag_name::string as tag_name,
        conversation_rating
    FROM   intercom.dev.dim_conversations c ,
     lateral flatten(input => c.conversation_tags_array) f
)
select tag_name, count(distinct conversation_id), avg(conversation_rating) as avg_rating from tags_list group by 1 order by 2 desc