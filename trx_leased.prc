CREATE OR REPLACE PROCEDURE IPTV."TRX_LEASED" is
   cursor c_item is 
      select stock_id, sum(qty) 
        from (select t.tr_id, tr_date, t.whs_id, cust_id, tr_desc, t.stock_id, unit, 1 qty, 0 ret_qty, tsn 
              from leased_temp t, 
                   ksm05_temp k 
              where t.tr_id = k.tr_id 
--and t.tr_id = 'A080626008'
              and k.whs_id = 'TP-L' 
              and k.code = 'G' 
              and t.qty < 0 
              and t.stock_id = k.stock_id 
              and t.stock_id like 'KA%'   
              and tsn like '1E%' 
              and not exists 
                      (select a.tr_id, tr_date, a.whs_id, cust_id, tr_desc, a.stock_id, unit, 0 qty, a.qty ret_qty, tsn 
                       from leased_temp a, 
                            ksm05_temp b 
                       where a.tr_id = b.tr_id 
                       and b.whs_id = 'TP-L' 
                       and b.code = 'G' 
                       and a.qty > 0 
                       and a.stock_id = b.stock_id 
                       and a.stock_id like 'KA%' 
                       and b.tsn like '1E%'  
                       and t.cust_id = a.cust_id 
                       and k.tsn = b.tsn) 
              union 
              select t.tr_id, tr_date, t.whs_id, cust_id, tr_desc, t.stock_id, unit, t.qty*(-1), 0 ret_qty, '' tsn 
                from leased_temp t
               where t.whs_id = 'TP-L'  
--and t.tr_id = 'A080626008'
                 and t.qty < 0  
                 and t.stock_id not like 'KA%' 
                 and t.cust_id like 'C%'   
                 and not exists 
                         (select a.tr_id, tr_date, a.whs_id, cust_id, tr_desc, a.stock_id, unit, 0 qty, a.qty ret_qty, '' tsn 
                         from leased_temp a 
                         where a.whs_id = 'TP-L'  
                         and a.qty > 0  
                         and a.stock_id not like 'KA%'  
--                         and a.cust_id like 'C%' 
                         and t.cust_id = a.cust_id 
                         and t.stock_id = a.stock_id
                         and (t.qty + a.qty = 0))) 
              group by stock_id;           
    
   cursor c_tsn(i_stock_id varchar2) is 
      select tsn
        from leased_temp t, 
             ksm05_temp k 
       where t.tr_id = k.tr_id        
         and k.whs_id = 'TP-L' 
         and k.code = 'G' 
         and t.qty < 0 
         and t.stock_id = i_stock_id 
         and t.stock_id = k.stock_id 
         and t.stock_id like 'KA%' 
--       and t.cust_id like 'C%'  
         and tsn like '1E%' 
         and not exists 
                 (select a.tr_id, tr_date, a.whs_id, cust_id, tr_desc, a.stock_id, unit, 0 qty, a.qty ret_qty, tsn 
                    from leased_temp a, 
                         ksm05_temp b 
                   where a.tr_id = b.tr_id 
                     and b.whs_id = 'TP-L' 
                     and b.code = 'G' 
                     and a.qty > 0 
                     and a.stock_id = b.stock_id 
                     and a.stock_id like 'KA%' 
                     and b.tsn like '1E%' 
--                   and a.cust_id like 'C%' 
                     and t.cust_id = a.cust_id 
                     and k.tsn = b.tsn); 
      
   v_stock_id     inv_trx_items.stock_id%type; 
   v_tsn          varchar2(20); --inv_trx_details.tsn%type; 
   --v_cust_id      inv_tcd_info.cust_id%type;
   v_mas_no       number; 
   v_item_no      number;  
   v_trx_no       number; 
   v_cnt          number; 
   --v_qty          number; 
   v_pl_id        inv_trx_mas.pl_id%type;
   v_tsn_cnt      number; 
   --v_tr_id        varchar2(256); 
   --v_tr_date      varchar2(256);
   --v_tr_desc      varchar2(256);
   v_asset_id     assets_dtl.asset_id%type;    
   v_asset_no     assets_dtl.asset_no%type;
   v_cost         number; 
begin
   --MASTER 
dbms_output.put_line('start'); 
   select seq_inv_no.nextval
     into v_mas_no 
     from dual; 
dbms_output.put_line('get trx_mas_no');      
   v_pl_id := sysapp_util.get_mas_no(1,1,trunc(sysdate,'MM'),'TRXINVS',	v_mas_no);
dbms_output.put_line('pl_id '||v_pl_id);    
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
                           'TP-L',
                           '',
                           'G',
                           trunc(sysdate),
                           'Z',
                           '',
                           'TP-L',
                           2008,
                           12, 
                           0,
                           trunc(sysdate),
                           '調整轉入-租賃在外'
                       from dual;                        
   --ITEMS
dbms_output.put_line('items');    
   open c_item; 
   fetch c_item into v_stock_id, v_cnt; 
   loop 
      exit when c_item%notfound; 
      select seq_inv_no.nextval
        into v_item_no 
        from dual; 
      insert into inv_trx_items(trx_mas_no,
                                trx_item_no,
                                stock_id,
                                stock_desc,
                                qty) 
                        values (v_mas_no,
                                v_item_no, 
                                v_stock_id, 
                                inv_trx_post.get_stk_name(v_stock_id),
                                v_cnt); 
      if substr(v_stock_id,1,2) = 'KA' then 
         open c_tsn(v_stock_id); 
         fetch c_tsn into v_tsn; 
         for i in 1..v_cnt loop 
            exit when c_tsn%notfound; 
            --借         
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
                                  dr_qty,
                                  tsn)
                          values (v_mas_no,
                                  v_item_no,
                                  v_trx_no,
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  'TP-L',
                                  v_pl_id,
                                  'G',     --調整單
                                  1,
                                  v_tsn); 
            --貸                          
            insert into inv_trx_details(trx_mas_no,
                                  trx_item_no,
                                  trx_no,
                                  stock_id,
                                  stock_desc,
                                  ship_id,
                                  pl_id,
                                  detail_type,
                                  cr_qty,
                                  tsn)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  '',
                                  v_pl_id,
                                  'G',     --調整單
                                  1,
                                  v_tsn);
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
                         'TP-L',
                         'I',
                         v_pl_id,
                         v_trx_no,
                         trunc(sysdate),
                         inv_trx_post.get_stk_cost(v_stock_id), 
                         v_stock_Id,
                         0,
                         trunc(sysdate));
            else 
               dbms_output.put_line('TSN exists: '||v_tsn); 
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
                          trunc(sysdate), 
                          'G', 
                          v_tsn,  
                          'TP-L', 
                          '',
                          '調整轉入-租賃在外');         
            --Asset(TSN)
            v_asset_id := inv_trx_post.get_asset_id(v_tsn); 
            if v_asset_id is null then 
               select seq_inv_no.nextval
               into v_asset_no
               from dual;  
               v_asset_id := sysapp_util.get_mas_no(1,1,trunc(sysdate),'ASSET',v_asset_no);		 
               v_cost := inv_trx_post.get_stk_cost(v_stock_id);  
               insert into assets_dtl(
                        asset_no,
                        asset_id,
                        f_year, 
                        f_period, 
                        tsn,
                        whs_id,
                        status,
                        pl_id,
                        trx_no,
                        cust_id, 
                        order_id, 
                        qty, 
                        cost,  
                        tivo_asset_id, 
                        keyin_user,
                        keyin_date,
                        stock_id)
                 values (v_asset_no,
                         v_asset_id,
                         to_number(to_char(sysdate,'yyyy')), 
                         to_number(to_char(sysdate,'mm')),
                         v_tsn,
                         'TP-L',
                         'I',
                         v_pl_id,
                         v_trx_no,
                         '',  
                         '',  
                         1,
                         v_cost, 
                         v_asset_id, 
                         0,
                         trunc(sysdate),
                         v_stock_id); 
            else 
               update assets_dtl 
               set pl_id = v_pl_id, 
                   trx_no = v_trx_no, 
                   status = 'I',
                   whs_id = 'TP-L',
                   order_id = '', 
                   cust_id = '', 
                   upd_user = 0, 
                   upd_date = trunc(sysdate)                           
               where asset_id = v_asset_id;       
               dbms_output.put_line('TSN exists and not in TP-L: '||v_tsn); 
            end if; 
            -- Add History 
            insert into asset_his(
                        asset_his_no, 
                        asset_id,
                        trx_no, 
                        trx_date, 
                        trx_type, 
                        ship_id_to, 
                        ship_id_from, 
                        tsn,
                        qty,
                        remark) 
                 values (seq_inv_no.nextval, 
                        v_asset_id,
                        v_trx_no,
                        trunc(sysdate),
                        'G', 
                        'TP-L',
                        '', 
                        v_tsn,
                        1,
                        '調整轉入-租賃在外');            
            fetch c_tsn into v_tsn;
            --fetch c_tsn into v_tr_id, v_tr_date, v_cust_id, v_tr_desc, v_tsn; 
         end loop; 
         close c_tsn; 
      else 
         --借                          
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
                                  dr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  v_trx_no,
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  'TP-L',
                                  v_pl_id,
                                  'G',     --調整單
                                  v_cnt); 
         --貸                          
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
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  '',
                                  v_pl_id,
                                  'G',     --調整單
                                  v_cnt);
         --Assets(Not TSN)
         for i in 1..v_cnt loop 
         select seq_inv_no.nextval
           into v_asset_no
           from dual;  
         v_asset_id := sysapp_util.get_mas_no(1,1,trunc(sysdate),'ASSET',v_asset_no);		 
         v_cost := inv_trx_post.get_stk_cost(v_stock_id);  
         begin 
         insert into assets_dtl(
                        asset_no,
                        asset_id,
                        f_year, 
                        f_period, 
                        whs_id,
                        status,
                        pl_id,
                        trx_no, 
                        qty, 
                        cost,   
                        keyin_user,
                        keyin_date,
                        stock_id)
                 values (v_asset_no,
                         v_asset_id,
                         to_number(to_char(sysdate,'yyyy')), 
                         to_number(to_char(sysdate,'mm')),
                         'TP-L',
                         'I',
                         v_pl_id,
                         v_trx_no,  
                         1,
                         v_cost, 
                         0,
                         trunc(sysdate),
                         v_stock_id); 
         exception 
            when others then 
               select seq_inv_no.nextval
               into v_asset_no
               from dual;  
               v_asset_id := sysapp_util.get_mas_no(1,1,trunc(sysdate),'ASSET',v_asset_no);		 
               v_cost := inv_trx_post.get_stk_cost(v_stock_id);   
               insert into assets_dtl(
                        asset_no,
                        asset_id,
                        f_year, 
                        f_period, 
                        whs_id,
                        status,
                        pl_id,
                        trx_no, 
                        qty, 
                        cost,   
                        keyin_user,
                        keyin_date,
                        stock_id)
                 values (v_asset_no,
                         v_asset_id,
                         to_number(to_char(sysdate,'yyyy')), 
                         to_number(to_char(sysdate,'mm')),
                         'TP-L',
                         'I',
                         v_pl_id,
                         v_trx_no,  
                         1,
                         v_cost, 
                         0,
                         trunc(sysdate),
                         v_stock_id);             
            
         end; 
         -- Add History 
         insert into asset_his(
                        asset_his_no, 
                        asset_id,
                        trx_no, 
                        trx_date, 
                        trx_type, 
                        ship_id_to, 
                        ship_id_from, 
                        qty,
                        remark) 
                 values (seq_inv_no.nextval, 
                        v_asset_id,
                        v_trx_no,
                        trunc(sysdate),
                        'G', 
                        'TP-L', 
                        '',
                        1,
                        '調整轉入-租賃在外'); 
         end loop;      --Not TSN 
      end if;                        
      fetch c_item into v_stock_id, v_cnt; 
   end loop; 
   close c_item;                       
   --  
   commit; 
   dbms_output.put_line('DONE!'); 
exception 
   when others then  
       rollback; 
       dbms_output.put_line(v_stock_id||'--'||V_TSN||': '||Sqlerrm); 
end trx_leased;
/

