create or replace function iptv.ios_auto_recurrent_func return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no    purchase_id,
               b.pk_no,
               d.end_date  max_end_date,
               --   bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1, b.serial_id) max_end_date,
               --a.cht_flg,
               d.start_date,
               d.pk_no            detail_pk_no,
               f.ios_product_code
          from bsm_recurrent_view  a,
               bsm_purchase_mas    b,
               bsm_purchase_item   c,
               bsm_client_details  d,
               bsm_package_mas     e,
               bsm_ios_receipt_mas f

         where b.status_flg = 'Z'
              --and d.status_flg = 'P'
           and b.mas_no = a.mas_no
           and c.mas_pk_no = b.pk_no
           and d.src_item_pk_no = c.pk_no
           and e.package_id = d.package_id
           and a.recurrent_type = 'IOS'
           and f.mas_pk_no = b.pk_no           and a.END_DATE >= to_char(sysdate -3,'YYYY/MM/DD')
           and a.end_date <= to_char(sysdate +3,'YYYY/MM/DD');
      v_msg        varchar2(1024);
      v_flg        varchar2(1024);
      expired_date date;
    begin
      for i in c1 loop
        begin
          v_flg := bsm_ios_gateway.check_Receipt_Data_str(i.pk_no,
                                                          i.ios_product_code);
          if v_flg = '21006' then
            /*
            update bsm_client_details a
               set a.end_date=sysdate+2
             where a.pk_no = i.detail_pk_no;
             commit; */
            expired_date := bsm_ios_gateway.get_exipired_date(i.pk_no,
                                                              i.ios_product_code);
            if expired_date > sysdate then
              expired_date := sysdate;
            end if;
            bsm_client_service.Set_subscription(null, i.serial_id);
            v_msg := bsm_cdi_service.refresh_client(i.serial_id);
            v_msg := bsm_recurrent_util.stop_recurrent(i.serial_id,
                                                       i.purchase_id,
                                                       'IOS系統取消',
                                                       to_char(expired_date,
                                                               'YYYYMMDDHH24MISS'));
            bsm_purchase_post.refresh_bsm_client(i.serial_id);
          elsif v_flg = '0' then
            v_msg := ios_auto_recurrent_dev(i.pk_no);
            /*   if i.max_end_date <= sysdate + 2 then
              expired_date := bsm_ios_gateway.get_exipired_date(i.pk_no,
                                                                i.ios_product_code);
              update bsm_client_details a
                 set a.end_date   = nvl(expired_date, sysdate + 29) + 1,
                     a.start_date = nvl(expired_date, sysdate + 29) - 29
               where a.pk_no = i.detail_pk_no;
              commit;
              bsm_client_service.Set_subscription(null, i.serial_id);
              bsm_purchase_post.refresh_bsm_client(i.serial_id);
            end if; */
          end if;
        exception
          when others then
            null;
        end;
      end loop;
    end;
    return null;
  end;
/

