CREATE OR REPLACE PROCEDURE IPTV."UPD_ORDER_ID" is
   cursor c_inv is 
      select m.trx_mas_no, i.order_id order_i, o.order_id order_o, tr_id 
        from inv_trx_mas m, 
             (select distinct trx_mas_no, order_id 
                from inv_trx_items) i, 
             (select cust_id, max(order_id) order_id 
                from tgc_order  
               where process_sts <> 'C'
               group by cust_id) o 
       where m.whs_id = 'TP-T'  
         and m.trx_type = 'S'
         and m.trx_mas_no = i.trx_mas_no  
--and m.pl_id in ('S081201544','S081202678')           
         and m.cust_id = o.cust_id(+);      
begin
   for v_inv in c_inv loop 
      if v_inv.order_i <> nvl(v_inv.order_o,'*') then 
--dbms_output.put_line(to_char(v_inv.trx_mas_no)||' - '||v_inv.order_i||' - '|| 
--                     v_inv.order_o||' - '||v_inv.tr_id); 
         update inv_trx_items 
            set order_id = nvl(v_inv.order_o,v_inv.tr_id) 
          where trx_mas_no = v_inv.trx_mas_no; 
      end if; 
   commit; 
   end loop; 
end upd_order_id;
/

