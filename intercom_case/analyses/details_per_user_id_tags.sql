with tags_list AS (
    SELECT
      c.conversation_id,
        f.index as tag_index,
        f.value:tag_name::string as tag_name,
        conversation_rating
    FROM   intercom.dev.dim_conversations c ,
     lateral flatten(input => c.conversation_tags_array) f
)
select author:id::string as user_id,
t.tag_name,
count(distinct conversation_id) as cnt_conv
from intercom.dev.fct_conversation_parts cp
inner join tags_list t using(conversation_id)
where author:type::string = 'user'
group by 1 , 2
order by 3 desc
