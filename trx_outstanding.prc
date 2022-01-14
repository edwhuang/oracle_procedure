CREATE OR REPLACE PROCEDURE IPTV."TRX_OUTSTANDING" is
   cursor c_mas is 
      select distinct whs_id 
        from leased_temp
       where code = 'D'
         --AND WHS_ID IN ('TP-A','TP-M'); 
         AND WHS_ID = 'HZ-K'; 
           
   cursor c_item(i_whs_id varchar2) is 
      select stock_id, unit, sum(qty-nvl(return_qty,0)) qty 
        from leased_temp 
       where code = 'D' 
         and whs_id = i_whs_id 
       group by whs_id, stock_id, unit 
       order by whs_id; 
              
   cursor c_tsn(i_whs_id varchar2, i_stock_id varchar2) is 
      select unique o.tsn 
        from leased_temp t, 
             ksm05_temp o 
       where t.code = 'D' 
         and t.whs_id = i_whs_id
         and t.stock_id = i_stock_id          
         and t.whs_id = o.whs_id 
         and t.tr_id = o.tr_id 
         and t.stock_id = o.stock_id
         and (t.qty-return_qty) > 0;    
   
   /*
      select tsn   
        from leased_temp t, 
             outstnd_tsn_temp o 
       where t.code = 'D' 
         and t.whs_id = i_whs_id 
         and t.stock_id = i_stock_id
         and t.tr_id = o.tr_id 
         and t.stock_id = o.stock_id;  
   */
    
   v_tsn          inv_trx_details.tsn%type; 
   v_mas_no       number; 
   v_item_no      number;  
   v_trx_no       number;   
   v_pl_id        inv_trx_mas.pl_id%type;
   v_tsn_cnt      number; 
begin
dbms_output.put_line('start');
   --MASTER 
   for r_mas in c_mas loop       
      select seq_inv_no.nextval
        into v_mas_no 
        from dual; 
      v_pl_id := sysapp_util.get_mas_no(1,1,to_date('20081201','yyyymmdd'),'TRXINVA',	v_mas_no);
dbms_output.put_line('WHS '||r_mas.whs_id||', pl_id '||v_pl_id);    
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
                           remark)
                    select v_mas_no,
                           v_pl_id,
                           r_mas.whs_id,
                           '',
                           'G',
                           to_date('20081231','yyyymmdd'), --trunc(sysdate),
                           'Z',
                           '',
                           r_mas.whs_id,
                           '2008',
                           '12', --to_char(sysdate,'mm'), 
                           0,
                           to_date('20081231','yyyymmdd'), --trunc(sysdate),
                           '調整轉入-借出末歸還'
                       from dual;                        
      --ITEMS
      dbms_output.put_line('items');     
      for r_item in c_item(r_mas.whs_id) loop   
         select seq_inv_no.nextval
           into v_item_no 
           from dual; 
         insert into inv_trx_items(trx_mas_no,
                                trx_item_no,
                                stock_id,
                                stock_desc,
                                qty,
                                unit) 
                        values (v_mas_no,
                                v_item_no, 
                                r_item.stock_id, 
                                inv_trx_post.get_stk_name(r_item.stock_id),
                                r_item.qty,
                                r_item.unit); 
         if substr(r_item.stock_id,1,2) = 'KA' then                           
            select seq_inv_no.nextval
              into v_trx_no 
              from dual;     
            --
            open c_tsn(r_mas.whs_id,r_item.stock_id); 
            fetch c_tsn into v_tsn; 
            for i in 1..r_item.qty loop 
               IF c_tsn%notfound then 
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
                                  detail_type,
                                  tsn, 
                                  dr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  v_trx_no,
                                  r_item.stock_id,
                                  inv_trx_post.get_stk_name(r_item.stock_id),
                                  r_mas.whs_id, 
                                  v_pl_id,
                                  'G',     --調整單
                                  v_tsn, 
                                  1); 
               insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  detail_type,
                                  tsn, 
                                  cr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  r_item.stock_id,
                                  inv_trx_post.get_stk_name(r_item.stock_id),
                                  '',
                                  v_pl_id,
                                  'G',     --調整單
                                  v_tsn, 
                                  1);
               if v_tsn is not null then 
                  --TCD_INFO
                  select count(*)
                    into v_tsn_cnt 
                    from inv_tcd_info 
                    where tsn = v_tsn; 
                  if v_tsn_cnt = 0 then 
                     insert into inv_tcd_info
                        (tcd_no,
                         tsn,
                         whs_id,
                         status,
                         pl_id,
                         trx_no,
                         instock_date, 
                         cost,  
                         stock_id, 
                         keyin_user,
                         keyin_date)
                     values (seq_inv_no.nextval,
                         v_tsn,
                         r_mas.whs_id,
                         'I',
                         v_pl_id,
                         v_trx_no,
                         to_date('20081231','yyyymmdd'), --trunc(sysdate),
                         inv_trx_post.get_stk_cost(r_item.stock_id), 
                         r_item.stock_Id,
                         0,
                         to_date('20081231','yyyymmdd'));  --trunc(sysdate));
                  else 
                     dbms_output.put_line('TSN已存在: '||v_tsn);   
                  end if;                          
                  --TCD History 
                  insert into inv_tcd_his(
                          tcd_his_no,
                          trx_no,
                          trx_date, 
                          trx_type, 
                          tsn, 
                          ship_id_to, 
                          ship_id_from,
                          remark) 
                     values(seq_inv_no.nextval, 
                          v_trx_no,
                          to_date('20081231','yyyymmdd'), --trunc(sysdate), 
                          'G', 
                          v_tsn,  
                          r_mas.whs_id, 
                          '',
                          '調整轉入-借出末歸還');                      
               end if; 
               fetch c_tsn into v_tsn;  
            end loop;       --c_tsn
            close c_tsn;                                                                    
         else 
            insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  detail_type,
                                  dr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  r_item.stock_id,
                                  inv_trx_post.get_stk_name(r_item.stock_id),
                                  r_mas.whs_id,
                                  v_pl_id,
                                  'G',     --調整單
                                  r_item.qty); 
            insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  detail_type,
                                  cr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  r_item.stock_id,
                                  inv_trx_post.get_stk_name(r_item.stock_id),
                                  '',
                                  v_pl_id,
                                  'G',     --調整單
                                  r_item.qty);         
         end if; 
      end loop;        -- C_Item           
   end loop;           -- C_Mas 
   commit; 
   dbms_output.put_line('DONE!'); 
exception 
   when others then  
       rollback; 
       dbms_output.put_line(Sqlerrm); 
end trx_outstanding;
/

