CREATE OR REPLACE PROCEDURE IPTV."TPT2CUST_OUT" is
   cursor c_mas is 
     select distinct tr_id, cust_id, tr_date, to_date(return_date,'yyyymmdd') return_date, remark  
       from leased_temp t 
      where t.code = 'D' 
and tr_id <> 'Tr08110111' 
        and whs_id = 'TP-N'; 

   cursor c_items(i_tr_id varchar2) is  
     select stock_id, unit, 'P', (qty-return_qty) qty, 0 return_qty 
       from leased_temp t 
      where t.code = 'D' 
        and whs_id = 'TP-N'
        and tr_id = i_tr_id; 
   
   cursor c_tsn(i_tr_id varchar2) is
      select unique tsn   
        from leased_temp t, 
             ksm05_temp o 
       where t.code = 'D' 
         and t.stock_id like 'KA%' 
         and t.whs_id = o.whs_id 
         and t.tr_id = o.tr_id 
         and t.stock_id = o.stock_id  
         and t.tr_id = i_tr_id;  
--         and t.tr_id = 'Tr08040479';    
       
   cursor c_order(i_cust_id varchar2) is 
      select order_id 
        from tgc_order 
       where order_type = 'P' 
         and cust_id = i_cust_id
         and process_sts <> 'C';          
       
   v_tr_id        varchar2(20); 
   v_cust_id      inv_trx_mas.cust_id%type; 
   v_trx_date     varchar2(20);       --inv_trx_mas.trx_date%type;
   v_return_date  inv_trx_mas.return_date%type;
   --
   v_stock_id     inv_trx_items.stock_id%type; 
   v_stock_desc   inv_trx_items.stock_desc%type; 
   v_order_type   inv_trx_items.order_type%type; 
   v_order_id     inv_trx_items.order_id%type;
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
   open c_mas; 
   fetch c_mas into v_tr_id, v_cust_id, v_trx_date, v_return_date, v_remark; 
   loop 
      exit when c_mas%notfound; 
      --MASTER  
      select seq_inv_no.nextval
        into v_mas_no 
        from dual;      
      v_pl_id := sysapp_util.get_mas_no(1,1,trunc(sysdate,'MM'),'TRXINVS',v_mas_no);
      insert into inv_trx_mas(trx_mas_no,
                           pl_id,
                           whs_id,
                           cust_id,
                           trx_type,
                           trx_date,
                           process_sts,
                           ship_id_from,
                           ship_id_to,
                           f_year,
                           f_period,
                           keyin_user,
                           keyin_date,
                           tr_id,
                           return_date, 
                           remark,  
                           ref1)       --借出日期, 
                    select v_mas_no,
                           v_pl_id,
                           'TP-T',
                           v_cust_id,
                           'S',        --出貨
                           trunc(sysdate),
                           'Z',
                           'TP-T',
                           v_cust_id,
                           to_char(sysdate,'yyyy'),
                           to_char(sysdate,'mm'), 
                           0,
                           trunc(sysdate),
                           v_tr_id,
                           v_return_date, 
                           v_remark, 
                           v_trx_date 
                       from dual;                        
      --ITEMS
      open c_order(v_cust_id); 
      fetch c_order into v_order_id; 
      close c_order; 
      --
      open c_items(v_tr_id); 
      fetch c_items into v_stock_id,v_unit,v_order_type,v_qty,v_return_qty; 
      loop 
         exit when c_items%notfound; 
         select seq_inv_no.nextval
           into v_item_no 
           from dual;  
         insert into inv_trx_items(trx_mas_no,
                                trx_item_no,
                                stock_id,
                                stock_desc,
                                qty,
                                unit,
                                order_id,
                                order_type,
                                returned_qty) 
                        values (v_mas_no,
                                v_item_no, 
                                v_stock_id, 
                                inv_trx_post.get_stk_name(v_stock_id),
                                v_qty,
                                v_unit,
                                NVL(v_order_id,v_tr_id),
                                v_order_type,
                                v_return_qty); 
         if substr(v_stock_id,1,2) = 'KA' then                            
            --借, 
            open c_tsn(v_tr_id); 
            fetch c_tsn into v_tsn; 
            for i in 1..v_qty loop  
               if c_tsn%notfound then 
                  v_tsn := ''; 
               end if;     
               select seq_inv_no.nextval
                 into v_trx_no 
                 from dual; 
               insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  order_id, 
                                  detail_type,
                                  tsn, 
                                  dr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  v_trx_no,
                                  v_stock_id,
                                  v_stock_desc,
                                  v_cust_id,
                                  v_pl_id,
                                  nvl(v_order_id,v_tr_id), 
                                  'S',     --出貨
                                  v_tsn, 
                                  1);  
               --貸                          
               insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  order_id, 
                                  detail_type,
                                  tsn, 
                                  cr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  v_stock_id,
                                  v_stock_desc,
                                  'TP-T',
                                  v_pl_id,
                                  nvl(v_order_id,v_tr_id), 
                                  'S',     
                                  v_tsn, 
                                  1);       
               --TCD info. 
               if v_tsn is not null then
                  select count(*) 
                    into v_tsn_cnt 
                    from inv_tcd_info
                   where tsn = v_tsn; 
                  if v_tsn_cnt > 0 then 
                     update inv_tcd_info 
                        set cust_id = v_cust_id, 
                            status = 'O', 
                            trx_no = v_trx_no,
                            pl_id = v_pl_id,
                            order_id = nvl(v_order_id,v_tr_id),  
                            remark = v_remark 
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
                                v_tsn,
                                'TP-T',
                                'O',
                                v_pl_id,
                                v_trx_no,
                                trunc(sysdate),
                                v_cust_id, 
                                nvl(v_order_id,v_tr_id),  
                                inv_trx_post.get_tcd_cost(v_tsn), 
                                v_stock_Id,
                                v_remark, 
                                0,
                                trunc(sysdate));                
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
                          v_trx_no,
                          trunc(sysdate), 
                          'S',       --出貨
                          v_tsn,  
                          v_cust_id, 
                          'TP-T',
                          v_remark);
               end if;    --TSN 
               fetch c_tsn into v_tsn; 
            end loop;     --C_TSN
            close c_tsn; 
         else 
            insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  order_id, 
                                  detail_type,
                                  tsn, 
                                  dr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  v_stock_id,
                                  v_stock_desc,
                                  v_cust_id,
                                  v_pl_id,
                                  nvl(v_order_id,v_tr_id),  
                                  'S',     --出貨
                                  '', 
                                  v_qty);  
            --貸                          
            insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  order_id, 
                                  detail_type,
                                  tsn, 
                                  cr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  v_stock_id,
                                  v_stock_desc,
                                  'TP-T',
                                  v_pl_id,
                                  nvl(v_order_id,v_tr_id),  
                                  'S',     
                                  '', 
                                  v_qty);            
            
         end if;          --check stock.
         --          
         fetch c_items into v_stock_id,v_unit, v_order_type,v_qty,v_return_qty; 
       end loop;  
       close c_items; 
       fetch c_mas into v_tr_id, v_cust_id, v_trx_date, v_return_date, v_remark; 
   end loop; 
   close c_mas; 
   --  
   commit; 
   dbms_output.put_line('DONE!'); 
exception 
   when others then 
       rollback; 
       Raise_Application_Error(-20002, Sqlerrm); 
end tpt2cust_out;
/

