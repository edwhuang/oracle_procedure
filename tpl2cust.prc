CREATE OR REPLACE PROCEDURE IPTV."TPL2CUST" is
   cursor c_item(i_tr_id varchar2) is 
     select stock_id, sum(qty) 
      from (select t.tr_id, tr_date, t.whs_id, cust_id, tr_desc, t.return_date, t.stock_id, unit, 1 qty, 0 ret_qty, tsn 
              from leased_temp t, 
                   ksm05_temp k 
              where t.tr_id = k.tr_id 
              and t.tr_id = i_tr_id   
              and k.whs_id = 'TP-L' 
              and k.code = 'G' 
              and t.qty < 0 
              and t.stock_id = k.stock_id 
              and t.stock_id like 'KA%'   
              and tsn like '1E%' 
              and cust_id not like 'TP%' 
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
              select t.tr_id, tr_date, t.whs_id, cust_id, tr_desc,t.return_date, t.stock_id, unit, t.qty*(-1), 0 ret_qty, '' tsn 
                from leased_temp t
               where t.whs_id = 'TP-L'   
                 and t.tr_id = i_tr_id 
                 and t.qty < 0  
                 and t.stock_id not like 'KA%' 
                 and t.cust_id like 'C%'  
                 and cust_id not like 'TP%'  
                 and not exists 
                         (select a.tr_id, tr_date, a.whs_id, cust_id, tr_desc, a.stock_id, unit, 0 qty, a.qty ret_qty, '' tsn 
                         from leased_temp a 
                         where a.whs_id = 'TP-L'  
                         and a.qty > 0  
                         and a.stock_id not like 'KA%'  
                         and t.cust_id = a.cust_id 
                         and t.stock_id = a.stock_id
                         and (t.qty + a.qty = 0)))
     group by stock_id;      
        
   cursor c_tsn(i_tr_id varchar2) is         
      select tr_desc, tsn  
              from leased_temp t, 
                   ksm05_temp k 
              where t.tr_id = k.tr_id 
              and t.tr_id = i_tr_id 
--and t.tr_id not IN ('A080626008','A080808008') 
              and k.whs_id = 'TP-L' 
              and k.code = 'G' 
              and t.qty < 0 
              and t.stock_id = k.stock_id 
              and t.stock_id like 'KA%'   
              and tsn like '1E%' 
              and cust_id not like 'TP%' 
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
                       and k.tsn = b.tsn);          
    
   cursor c_trx is 
     select distinct tr_id, tr_date,cust_id,tr_desc
      from (select t.tr_id, tr_date, t.whs_id, cust_id, tr_desc, t.return_date, t.stock_id, unit, 1 qty, 0 ret_qty, tsn 
              from leased_temp t, 
                   ksm05_temp k 
              where t.tr_id = k.tr_id 
              and k.whs_id = 'TP-L' 
              and k.code = 'G' 
              and t.qty < 0 
              and t.stock_id = k.stock_id 
              and t.stock_id like 'KA%'   
              and tsn like '1E%' 
              and cust_id not like 'TP%' 
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
              select t.tr_id, tr_date, t.whs_id, cust_id, tr_desc,t.return_date, t.stock_id, unit, t.qty*(-1), 0 ret_qty, '' tsn 
                from leased_temp t
               where t.whs_id = 'TP-L'  
                 and t.qty < 0  
                 and t.stock_id not like 'KA%' 
                 and t.cust_id like 'C%'  
                 and cust_id not like 'TP%'  
                 and not exists 
                         (select a.tr_id, tr_date, a.whs_id, cust_id, tr_desc, a.stock_id, unit, 0 qty, a.qty ret_qty, '' tsn 
                         from leased_temp a 
                         where a.whs_id = 'TP-L'  
                         and a.qty > 0  
                         and a.stock_id not like 'KA%'  
                         and t.cust_id = a.cust_id 
                         and t.stock_id = a.stock_id
                         and (t.qty + a.qty = 0)));    
      
   v_stock_id     inv_trx_items.stock_id%type; 
   v_tsn          inv_trx_details.tsn%type; 
   v_mas_no       number; 
   v_item_no      number;  
   v_trx_no       number; 
   v_cnt          number; 
   --v_qty          number; 
   v_pl_id        inv_trx_mas.pl_id%type;
   v_tsn_cnt      number;  
   v_tr_desc      varchar2(256);
   v_asset_id     assets_dtl.asset_id%type;    
   v_asset_no     assets_dtl.asset_no%type;
   v_cost         number; 
begin
dbms_output.put_line('Start');    
   --MASTER 
   for r_trx in c_trx loop  
   select seq_inv_no.nextval
     into v_mas_no 
     from dual;      
   v_pl_id := sysapp_util.get_mas_no(1,1,trunc(sysdate,'MM'),'TRXINVS',	v_mas_no);
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
                           remark,
                           tr_id,
                           ref1,
                           return_date)
                    select v_mas_no,
                           v_pl_id,
                           'TP-L',
                           r_trx.cust_id,
                           'S',
                           trunc(sysdate),
                           'Z',
                           'TP-L',
                           r_trx.cust_id, 
                           2008,
                           12, 
                           0,
                           trunc(sysdate),
                           r_trx.tr_desc,
                           r_trx.tr_id, 
                           r_trx.tr_date, 
                           ''  --r_trx.return_date 
                      from dual;                        
   --ITEMS    
   open c_item(r_trx.tr_id); 
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
                                order_id, 
                                qty) 
                        values (v_mas_no,
                                v_item_no, 
                                v_stock_id, 
                                inv_trx_post.get_stk_name(v_stock_id),
                                r_trx.tr_id, 
                                v_cnt); 
      if substr(v_stock_id,1,2) = 'KA' then 
         open c_tsn(r_trx.tr_id); 
         fetch c_tsn into v_tr_desc, v_tsn; 
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
                                  order_id, 
                                  detail_type,
                                  TSN, 
                                  dr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  v_trx_no,
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  r_trx.cust_id, 
                                  v_pl_id,
                                  r_trx.tr_id, 
                                  'S',     --調整單
                                  V_TSN, 
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
                                  TSN, 
                                  cr_qty)
                          values (v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  'TP-L',
                                  v_pl_id,
                                  r_trx.tr_id, 
                                  'S',     --調整單
                                  V_TSN, 
                                  1);
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
                         cust_id, 
                         order_id, 
                         stock_id, 
                         keyin_user,
                         keyin_date)
                 values (seq_inv_no.nextval,
                         v_tsn,
                         'TP-L',
                         'O',
                         v_pl_id,
                         v_trx_no,
                         trunc(sysdate),
                         inv_trx_post.get_stk_cost(v_stock_id), 
                         r_trx.cust_id, 
                         r_trx.tr_id, 
                         v_stock_Id,
                         0,
                         trunc(sysdate));
               dbms_output.put_line('TCD_INFO Not exists: '||v_tsn); 
            else 
               update inv_tcd_info 
                  set status = 'O' , 
                      cust_id = r_trx.cust_id, 
                      order_id = r_trx.tr_id, 
                      pl_id = v_pl_id, 
                      trx_no = v_trx_no
                where tsn = v_tsn; 
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
                          's', 
                          v_tsn, 
                          r_trx.cust_id, 
                          'TP-L', 
                          v_tr_desc||': '||r_trx.tr_date);         
            --Assets 
            /*
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
                         'O',
                         v_pl_id,
                         v_trx_no,
                         r_trx.cust_id,  
                         r_trx.tr_id,
                         1,
                         v_cost, 
                         v_asset_id, 
                         0,
                         trunc(sysdate),
                         v_stock_id); 
               dbms_output.put_line('ASSET Not exists: '||v_tsn); 
            else 
               update assets_dtl 
                  set pl_id = v_pl_id, 
                      trx_no = v_trx_no, 
                      status = 'O',
                      whs_id = 'TP-L',
                      order_id = r_trx.tr_id, 
                      cust_id = r_trx.cust_id,
                      upd_user = 0, 
                      upd_date = trunc(sysdate)                           
                where asset_id = v_asset_id;              
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
                        'S', 
                        r_trx.cust_id,
                        'TP-L',
                        v_tsn,
                        1,
                        v_tr_desc||': '||r_trx.tr_date); 
                */
            --
            fetch c_tsn into v_tr_desc, v_tsn; 
         end loop; 
         close c_tsn; 
      else 
         --借                          
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
                                  v_stock_id,
                                  inv_trx_post.get_stk_name(v_stock_id),
                                  r_trx.cust_id,
                                  v_pl_id,
                                  'S',     
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
                                  'TP-L',
                                  v_pl_id,
                                  'S',     
                                  v_cnt);
            --Assets 
            /*
            for i in 1..v_cnt loop 
            v_asset_id := inv_trx_post.get_asset_by_stk(v_stock_id); 
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
                         '',
                         'TP-L',
                         'O',
                         v_pl_id,
                         v_trx_no,
                         r_trx.cust_id,  
                         r_trx.tr_id,
                         1,
                         v_cost, 
                         '', 
                         0,
                         trunc(sysdate),
                         v_stock_id); 
               dbms_output.put_line('ASSET Not exists: '||v_tsn); 
            else 
               update assets_dtl 
                  set pl_id = v_pl_id, 
                      trx_no = v_trx_no, 
                      status = 'O',
                      whs_id = 'TP-L', 
                      order_id = r_trx.tr_id, 
                      cust_id = r_trx.cust_id,
                      Upd_user = 0, 
                      upd_date = trunc(sysdate) 
                where asset_id = v_asset_id;                            
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
                        'S', 
                        r_trx.cust_id,
                        'TP-L',
                        '',
                        1,
                        r_trx.tr_desc); 
                
         END LOOP;      --ASSET     
            */        
      end if; 
      fetch c_item into v_stock_id, v_cnt; 
   end loop;            --Item. 
   close c_item;                     
   --
   commit;   
   end loop;            --TR_ID 
   --  
   --commit; 
   dbms_output.put_line('DONE!'); 
exception 
   when others then  
       rollback; 
       dbms_output.put_line(Sqlerrm); 
end tpl2cust;
/

