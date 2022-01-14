CREATE OR REPLACE PROCEDURE IPTV."GO_ASSET" is
   cursor c_mas is 
      select trx_mas_no, pl_id, cust_id, tr_id, trx_date, trx_type, remark 
        from inv_trx_mas m   
       where m.whs_id = 'TP-L'  
         and m.trx_type = 'S'; 
         
   cursor c_dtl(i_mas_no number) is 
      select trx_no, detail_type, stock_id, tsn, cr_qty
        from inv_trx_details 
       where trx_mas_no = i_mas_no   
         and cr_qty > 0
       order by tsn; 
   v_asset_id       assets_dtl.asset_id%type; 
   v_asset_id_tivo  assets_dtl.tivo_asset_id%type;
begin
   for v_mas in c_mas loop 
      v_asset_id_tivo := ''; 
      for v_dtl in c_dtl(v_mas.trx_mas_no) loop 
          if v_dtl.tsn is not null then 
             v_asset_id := inv_trx_post.get_asset_id(v_dtl.tsn); 
             v_asset_id_tivo := v_asset_id; 
             update assets_dtl 
                set order_id = v_mas.tr_id, 
                    cust_id = v_mas.cust_id, 
                    pl_id = v_mas.pl_id, 
                    trx_no = v_dtl.trx_no, 
                    status = 'O', 
                    tivo_asset_id = v_asset_id_tivo
              where asset_id = v_asset_id; 
             --
             insert into asset_his (asset_his_no
                                   ,asset_id
                                   ,trx_no
                                   ,trx_date
                                   ,trx_type
                                   ,ship_id_to
                                   ,ship_id_from
                                   ,tsn
                                   ,remark
                                   ,qty
                                   ,tivo_asset_id) 
                            values (seq_inv_no.nextval 
                                   ,v_asset_id
                                   ,v_dtl.trx_no
                                   ,v_mas.trx_date
                                   ,v_mas.trx_type
                                   ,v_mas.cust_id
                                   ,'TP-L'
                                   ,v_dtl.tsn
                                   ,v_mas.remark
                                   ,1
                                   ,v_asset_id_tivo); 
          else 
             for i in 1..v_dtl.cr_qty loop 
             v_asset_id := inv_trx_post.get_asset_by_stk(v_dtl.stock_id); 
             update assets_dtl 
                set order_id = v_mas.tr_id, 
                    cust_id = v_mas.cust_id, 
                    pl_id = v_mas.pl_id, 
                    trx_no = v_dtl.trx_no, 
                    status = 'O', 
                    tivo_asset_id = v_asset_id_tivo
              where asset_id = v_asset_id; 
             --
             insert into asset_his (asset_his_no
                                   ,asset_id
                                   ,trx_no
                                   ,trx_date
                                   ,trx_type
                                   ,ship_id_to
                                   ,ship_id_from
                                   ,tsn
                                   ,remark
                                   ,qty
                                   ,tivo_asset_id) 
                            values (seq_inv_no.nextval 
                                   ,v_asset_id
                                   ,v_dtl.trx_no
                                   ,v_mas.trx_date
                                   ,v_mas.trx_type
                                   ,v_mas.cust_id
                                   ,'TP-L'
                                   ,v_dtl.tsn
                                   ,v_mas.remark
                                   ,1
                                   ,v_asset_id_tivo);              
             end loop;    -- Qty
          end if; 
      end loop;           -- Detail 
      commit; 
   end loop;              -- Master 
end go_asset;
/

