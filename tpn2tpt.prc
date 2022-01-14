CREATE OR REPLACE PROCEDURE IPTV."TPN2TPT" is
   cursor c_items is 
      select m.trx_mas_no, trx_item_no, stock_id, stock_desc, qty, unit
        from inv_trx_items i, inv_trx_mas m 
        where m.whs_id = 'TP-N' 
        and m.trx_type = 'G' 
        and i.trx_mas_no = m.trx_mas_no;       
       --where trx_mas_no = i_mas_no; 
       
   cursor c_tsn(i_no number) is 
      select trx_no, tsn 
        from inv_trx_details
       where trx_mas_no = i_no
         and stock_id like 'KA%'
         and ship_id is not null
         and tsn is not null 
         and dr_qty > 0;
       
   v_trx_mas_no   number; 
   v_trx_item_no  number; 
   v_stock_id     inv_trx_items.stock_id%type; 
   v_stock_desc   inv_trx_items.stock_desc%type; 
   v_qty          number; 
   v_unit         inv_trx_items.unit%type; 
   --
   v_tsn          inv_trx_details.tsn%type; 
   v_mas_no       number; 
   v_item_no      number;  
   v_trx_no       number;  
   v_pl_id        inv_trx_mas.pl_id%type;
begin
   --MASTER 
dbms_output.put_line('start'); 
   select seq_inv_no.nextval
     into v_mas_no 
     from dual; 
dbms_output.put_line('get trx_mas_no: '||to_char(v_mas_no));      
   v_pl_id := sysapp_util.get_mas_no(1,1,trunc(sysdate,'MM'),'TRXINVA',	v_mas_no);
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
                           keyin_date)
                    select v_mas_no,
                           v_pl_id,
                           'TP-T',
                           '',
                           'F',        --調撥
                           trunc(sysdate),
                           'Z',
                           'TP-N',
                           'TP-T',
                           to_char(sysdate,'yyyy'),
                           to_char(sysdate,'mm'), 
                           0,
                           trunc(sysdate)
                       from dual;                        
   --ITEMS
dbms_output.put_line('items');    
   open c_items; 
   fetch c_items into v_trx_mas_no,v_trx_item_no,v_stock_id, v_stock_desc, v_qty, v_unit; 
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
                                unit) 
                        values (v_mas_no,
                                v_item_no, 
                                v_stock_id, 
                                v_stock_desc,
                                v_qty,
                                v_unit); 
      --details                           
      --借
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
                           select v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  stock_id,
                                  stock_desc,
                                  'TP-T',
                                  v_pl_id,
                                  'D',     --調撥(入)
                                  tsn, 
                                  dr_qty
                             from inv_trx_details
                            where trx_mas_no = v_trx_mas_no
                              and trx_item_no = v_trx_item_no
                              and dr_qty > 0; 
      --貸                          
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
                           select v_mas_no,
                                  v_item_no,
                                  seq_inv_no.nextval,
                                  stock_id,
                                  stock_desc,
                                  'TP-N',
                                  v_pl_id,
                                  'C',     --調撥(出)
                                  tsn, 
                                  cr_qty
                             from inv_trx_details
                            where trx_mas_no = v_trx_mas_no
                              and trx_item_no = v_trx_item_no
                              and cr_qty > 0;                              
      fetch c_items into v_trx_mas_no,v_trx_item_no,v_stock_id, v_stock_desc, v_qty, v_unit; 
   end loop; 
   close c_items; 
   --
dbms_output.put_line('TSN');     
   open c_tsn(v_mas_no); 
   fetch c_tsn into v_trx_no, v_tsn; 
   loop  
      exit when c_tsn%notfound;  
      update inv_tcd_info 
         set whs_id = 'TP-T', 
             trx_no = v_trx_no,
             pl_id = v_pl_id 
       where tsn = v_tsn; 
      --TCD History 
      insert into inv_tcd_his(tcd_his_no,
                          trx_no,
                          trx_date, 
                          trx_type, 
                          tsn, 
                          ship_id_to, 
                          ship_id_from) 
                   values(seq_inv_no.nextval, 
                          v_trx_no,
                          trunc(sysdate), 
                          'F',       --調撥
                          v_tsn,  
                          'TP-T', 
                          'TP-N');
      fetch c_tsn into v_trx_no, v_tsn; 
   end loop; 
   close c_tsn; 
   --  
   commit; 
   dbms_output.put_line('DONE!'); 
exception 
   when others then 
       rollback; 
       Raise_Application_Error(-20002, Sqlerrm); 
end tpn2tpt;
/

