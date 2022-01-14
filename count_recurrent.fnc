create or replace function iptv.count_recurrent (p_order_id varchar2,p_batch_id varchar2)
 return number
 is
 cnt number(6);
 cnt_a number(6);
 cursor c1 is select b.result from  iptv.view_payment_info b where b.order_id=p_order_id and batch_id <=p_batch_id
  order by order_id,batch_id;
begin
  cnt := 1;
  cnt_a := 1;
  for i in c1 loop
    cnt_a:= cnt;
    if i.result = 'ok' then
     cnt := 1;
    elsif i.result in ('retry','fail') then
      cnt:= cnt+1;
    end if;
    
  end loop;
  return cnt_a;
end;
/

