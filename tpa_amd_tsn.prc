CREATE OR REPLACE PROCEDURE IPTV."TPA_AMD_TSN" is
   cursor c_mas is 
      select m.trx_mas_no, i.trx_item_no, m.tr_id, i.stock_id, k.tsn, 
             m.cust_id, m.pl_id, m.whs_id 
        from inv_trx_mas m, inv_trx_items i, ksm05_temp k 
       where m.whs_id in ('TP-A','TP-M','HZ-K') 
       and trx_type = 'L' 
       and trx_date = to_date('20081231','yyyymmdd') 
       and m.trx_mas_no = i.trx_mas_no 
       and i.stock_id like 'KA%' 
       and process_sts = 'Z' 
       and i.qty = 1 
and m.tr_id <> 'Tr08010108'        
       and k.tr_id = m.tr_id; 
         
   v_whs_id       inv_trx_mas.whs_id%type; 
   v_tr_id        varchar2(20); 
   v_cust_id      inv_trx_mas.cust_id%type; 
   v_trx_date     varchar2(20);       --inv_trx_mas.trx_date%type;
   v_return_date  inv_trx_mas.return_date%type;
   --
   v_stock_id     inv_trx_items.stock_id%type; 
   v_stock_desc   inv_trx_items.stock_desc%type; 
   --v_order_type   inv_trx_items.order_type%type; 
   --v_order_id   inv_trx_items.order_id%type;
   v_qty          number; 
   v_return_qty   number; 
   v_unit         inv_trx_items.unit%type; 
   v_tsn          inv_trx_details.tsn%type; 
   v_mas_no       number; 
   v_item_no      number;  
   v_trx_no       number;  
   v_pl_id        inv_trx_mas.pl_id%type;
   v_tsn_cnt      number; 
   v_remark       varchar2(1024); 
begin
dbms_output.put_line('start');
   for v_mas in c_mas loop     
       update inv_trx_details 
          set tsn = v_mas.tsn
        where trx_mas_no = v_mas.trx_mas_no
          and trx_item_no = v_mas.trx_item_no 
          and stock_id = v_mas.stock_id;  
          
               --TCD info. 
               if v_mas.tsn is not null then
                  select count(*) 
                    into v_tsn_cnt 
                    from inv_tcd_info
                   where tsn = v_tsn; 
                  if v_tsn_cnt > 0 then 
                     update inv_tcd_info 
                        set cust_id = v_mas.cust_id, 
                            whs_id = v_mas.whs_id, 
                            status = 'O', 
                            trx_no = v_mas.trx_item_no,
                            pl_id = v_mas.pl_id,
                            order_id = v_mas.tr_id 
                      where tsn = v_tsn; 
                  else 
                      insert into inv_tcd_info
                               (tcd_no,
                               tsn,
                               whs_id,
                               status,
                               pl_id,
                               trx_no,
                               instock_date, 
                               cust_id, 
                               order_id, 
                               cost,  
                               stock_id, 
                               remark, 
                               keyin_user,
                               keyin_date)
                         values (seq_inv_no.nextval,
                                v_mas.tsn,
                                v_mas.whs_id,
                                'O',
                                v_mas.pl_id,
                                v_mas.trx_item_no,
                                to_date('20081231','yyyymmdd'), --trunc(sysdate),
                                v_mas.cust_id, 
                                v_mas.tr_id, 
                                inv_trx_post.get_STK_cost(v_mas.stock_id), 
                                v_mas.stock_Id,
                                '', 
                                0,
                                to_date('20081231','yyyymmdd')); --trunc(sysdate));                
                      dbms_output.put_line('TSN not found: '||v_tsn); 
                   end if; 
                   --TCD History 
                   insert into inv_tcd_his(tcd_his_no,
                          trx_no,
                          trx_date, 
                          trx_type, 
                          tsn, 
                          ship_id_to, 
                          ship_id_from,
                          remark) 
                   values(seq_inv_no.nextval, 
                          v_mas.trx_item_no,
                          to_date('20081231','yyyymmdd'), --trunc(sysdate), 
                          'L',       --出貨
                          v_mas.tsn,  
                          v_mas.cust_id, 
                          v_mas.whs_id,
                          '');
               end if;    --TSN 
   end loop;  
   --  
   commit; 
   dbms_output.put_line('DONE!'); 
exception 
   when others then 
       rollback; 
       Raise_Application_Error(-20002, Sqlerrm); 
end tpa_amd_tsn;
/

