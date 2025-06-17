select author:id::string as user_id,
count(distinct conversation_id) as cnt_conv
from intercom.dev.fct_conversation_parts cp
where author:type::string = 'user'
group by 1
order by 2 desc