﻿CREATE OR REPLACE PACKAGE BODY IPTV."BSM_RECURRENT_UTIL_OLD" is
  function get_next_pay_date(p_cat varchar2, p_client_id varchar2)
    return varchar2 is
    v_result    date;
    v_client_id varchar2(32);
    v_pay_type  varchar2(64);
  begin
    /*   v_client_id := upper(p_client_id);
    
    select max(a.end_date) - 3,max(decode(c.pay_type,'IOS','IOS',''))
      into v_result,v_pay_type
      from bsm_client_details a, bsm_package_mas b,bsm_purchase_mas c
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or (end_date >= sysdate))
       and b.package_cat_id1 = p_cat
       and c.pk_no=a.src_pk_no
       ;
    if v_pay_type ='IOS' then return '請查詢iTunes帳號';
    elsif v_pay_type = '中華帳單' then return '請查詢中華電信';
    else
    return to_char(v_result,'YYYY/MM/DD');
    end if; */
    v_client_id := upper(p_client_id);
    /* LiPay 到期日隔天 */
    select max(a.end_date) - 3,
           max(decode(c.pay_type,
                      'IOS',
                      'IOS',
                      '中華帳單',
                      '中華帳單',
                      'TSTAR',
                      'TSTAR',
                      ''))
      into v_result, v_pay_type
      from bsm_client_details a, bsm_package_mas b, bsm_purchase_mas c
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or (end_date >= sysdate))
       and b.package_cat_id1 = p_cat
       and c.pk_no = a.src_pk_no;
    if v_pay_type = 'IOS' then
      return '請查詢iTunes帳號';
    elsif v_pay_type = '中華帳單' then
      return '請查詢中華電信';
    elsif v_pay_type = 'TSTAR' then
      return '依帳單日期';
    else
      return to_char(v_result, 'YYYY/MM/DD');
    end if;
  end;

  function get_service_end_date(p_cat varchar2, p_client_id varchar2)
    return date is
    v_result    date;
    v_client_id varchar2(32);
  begin
    v_client_id := upper(p_client_id);
  
    select max(a.end_date) - 3
      into v_result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or (end_date >= sysdate))
       and b.package_cat_id1 = p_cat;
    v_result := nvl(v_result, sysdate - 3);
    return v_result;
  end;
  function get_service_end_date_full(p_cat varchar2, p_client_id varchar2)
    return date is
    v_result    date;
    v_client_id varchar2(32);
  begin
    v_client_id := upper(p_client_id);
  
    select max(a.end_date)
      into v_result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and b.package_cat_id1 = p_cat;
    return v_result;
  end;

  function check_access(p_cat varchar2, p_client_id varchar2) return varchar is
    v_result    varchar2(32);
    v_client_id varchar2(32);
  begin
    v_client_id := upper(p_client_id);
  
    select 'Y'
      into v_result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or
           (start_date <= sysdate and end_date >= sysdate))
       and b.package_cat_id1 = p_cat;
    return v_result;
  end;

  function check_recurrent(p_cat       varchar2,
                           p_client_id varchar2,
                           p_device_id varchar2 default null) return varchar2 is
    v_result    varchar2(32) := 'N';
    v_client_id varchar2(32);
  begin
    Select /*+ FIRST_ROWS */
     'Y'
      into v_result
      from bsm_purchase_mas   a,
           bsm_purchase_item  b,
           bsm_client_details c,
           bsm_recurrent_mas  d
     where a.status_flg = 'Z'
       and a.recurrent = 'R'
       and a.serial_id = p_client_id
       and b.mas_pk_no = a.pk_no
       and d.src_pk_no = a.pk_no
       and d.status_flg = 'P'
       and c.src_item_pk_no = b.pk_no
       and b.package_id in
           (select package_id
              from bsm_package_mas c
             where c.package_cat_id1 = p_cat)
       and (c.device_id is null or c.device_id = p_device_id)
       and rownum <= 1;
    return v_result;
  exception
    when no_data_found then
      return 'N';
  end;

  function stop_recurrent(p_client_id   varchar2,
                          p_purchase_id varchar2,
                          p_remark      varchar2,
                          p_actiondate  varchar2 default null)
    return varchar2 is
    v_result         varchar2(1024);
    v_purchase_pk_no number;
    v_recurrent_type varchar2(1024);
    v_client_id      varchar2(32);
  
  begin
    select pk_no, serial_id
      into v_purchase_pk_no, v_client_id
      from bsm_purchase_mas
     where mas_no = p_purchase_id;
    select recurrent_type
      into v_recurrent_type
      from bsm_recurrent_mas a
     where a.src_no = p_purchase_id;
  
    if v_recurrent_type = 'HINET' then
      v_result := bsm_cht_service.UnSubscribe(v_purchase_pk_no,
                                              p_actiondate);
    
      if v_result not in ('c001', 'c110', 's241', 'Success') then
        return v_result;
      end if;
    
      update bsm_client_details a
         set a.end_date = to_date(p_actiondate, 'YYYYMMDDHH24MISS')
       where a.src_pk_no = v_purchase_pk_no;
    
    end if;
  
    update bsm_recurrent_mas a
       set status_flg = 'B',
           a.end_date = decode(p_actiondate,
                               null,
                               sysdate,
                               to_date(p_actiondate, 'YYYYMMDDHH24MISS')),
           a.remark   = p_remark
     where a.src_no = p_purchase_id;
    commit;
  
    declare
    
      v_param        VARCHAR2(500) := '{
    "id":"1234",
    "jsonrpc": "2.0",
    "method": "refresh_client", 
    "params": {
        "client_id": "_CLIENT_ID_" 
    }
}';
      v_param_length NUMBER;
      rw_result      clob;
      req            utl_http.req;
      resp           utl_http.resp;
      rw             varchar2(32767);
    
    begin
      v_param := replace(v_param, '_CLIENT_ID_', v_client_id);
    
      v_param_length := length(v_param);
      Req            := Utl_Http.Begin_Request('http://bsm01.tw.svc.litv.tv/bsm_pc_service/bsm_pc_service.ashx',
                                               'POST',
                                               'HTTP/1.1');
    
      UTL_HTTP.SET_HEADER(r     => req,
                          name  => 'Content-Type',
                          value => 'application/x-www-form-urlencoded');
      UTL_HTTP.SET_HEADER(r     => req,
                          name  => 'Content-Length',
                          value => v_param_length);
      UTL_HTTP.WRITE_TEXT(r => req, data => v_param);
    
      resp := utl_http.get_response(req);
    
      loop
        begin
          rw := null;
          utl_http.read_line(resp, rw, TRUE);
          rw_result := rw_result || rw;
        exception
          when others then
            exit;
        end;
      end loop;
      utl_http.end_response(resp);
    exception
      when others then
        null;
    end;
  
    declare
      v_param        VARCHAR2(500) := '{
    "id":"1234",
    "jsonrpc": "2.0",
    "method": "refresh_client", 
    "params": {
        "client_id": "_CLIENT_ID_" 
    }
}';
      v_param_length NUMBER := length(v_param);
      rw_result      clob;
      req            utl_http.req;
      resp           utl_http.resp;
      rw             varchar2(32767);
    
    begin
      v_param := replace(v_param, '_CLIENT_ID_', v_client_id);
    
      v_param_length := length(v_param);
      Req            := Utl_Http.Begin_Request('http://bsm01.tw.svc.litv.tv/bsm_json_service/bsm_package_info.ashx',
                                               'POST',
                                               'HTTP/1.1');
    
      UTL_HTTP.SET_HEADER(r     => req,
                          name  => 'Content-Type',
                          value => 'application/x-www-form-urlencoded');
      UTL_HTTP.SET_HEADER(r     => req,
                          name  => 'Content-Length',
                          value => v_param_length);
      UTL_HTTP.WRITE_TEXT(r => req, data => v_param);
    
      resp := utl_http.get_response(req);
    
      loop
        begin
          rw := null;
          utl_http.read_line(resp, rw, TRUE);
          rw_result := rw_result || rw;
        exception
          when others then
            exit;
        end;
      end loop;
      utl_http.end_response(resp);
    exception
      when others then
        null;
    end;
    return 'Success';
  end;

  function auto_recurrent return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no purchase_id,
               a.card_expiry,
               bsm_encrypt.decrypt_Serial_ID(a.card_no,
                                             b.serial_id || 'tgc27740083') card_no,
               a.card_type,
               a.cvc2,
               c.package_id,
               trunc(get_service_end_date_full(e.package_cat_id1,
                                               b.serial_id)) max_end_date,
               sum(nvl(a.amount, c.amount)) amount
          from bsm_recurrent_mas  a,
               bsm_purchase_mas   b,
               bsm_purchase_item  c,
               bsm_client_details d,
               bsm_package_mas    e
         where a.status_flg = 'P'
           and b.status_flg = 'Z'
           and d.status_flg = 'P'
           and b.mas_no = a.src_no
           and c.mas_pk_no = b.pk_no
           and d.src_item_pk_no = c.pk_no
           and e.package_id = c.package_id
           and e.recurrent='R'
           and trunc(get_service_end_date_full(e.package_cat_id1,
                                               b.serial_id))+1 < sysdate + 3
           and a.recurrent_type = 'CREDIT'
         group by b.serial_id,
                  b.mas_no,
                  a.card_expiry,
                  a.card_no,
                  a.card_type,
                  a.cvc2,
                  
                  e.package_cat_id1,
                  c.package_id;
      v_msg varchar2(1024);
    begin
      for i in c1 loop
        dbms_output.put_line(i.serial_id);
        -- 已服務過期註銷
        if i.max_end_date < trunc(sysdate) - 3 then
          dbms_output.put_line(i.serial_id || ':Expired');
          v_msg := stop_recurrent(i.serial_id,
                                  i.purchase_id,
                                  '服務到期',
                                  to_char(SYSDATE, 'YYYYMMDDHH24MISS'));
          update bsm_recurrent_mas a 
          set recurrent_status = 'B', a.recurrent_s_date = sysdate
           where a.src_no = i.purchase_id;
          commit;
        
        else
        
          -- 信用卡過期
          if i.card_expiry < to_char(sysdate, 'yyyymm') then
            dbms_output.put_line(i.serial_id || ':Credit Expired');
            v_msg := stop_recurrent(i.serial_id,
                                    i.purchase_id,
                                    '信用卡到期');
            update bsm_recurrent_mas a
               set a.recurrent_status = 'B', a.recurrent_s_date = sysdate
             where a.src_no = i.purchase_id;
            commit;
          
          else
            dbms_output.put_line(i.serial_id || ':Process');
          
            declare
              -- Non-scalar parameters require additional processing
              result            tbsm_result;
              in_bsm_purchase   tbsm_purchase;
              p_recurrent       varchar2(32);
              p_device_id       varchar2(32);
              parameter_options varchar2(32);
              p_sw_version      varchar2(32);
            begin
              in_bsm_purchase             := new tbsm_purchase();
              in_bsm_purchase.card_no     := substr(i.card_no, 1, 16);
              in_bsm_purchase.card_expiry := i.card_expiry;
              in_bsm_purchase.cvc2        := i.cvc2;
              in_bsm_purchase.card_type   := i.card_type;
              in_bsm_purchase.src_no      := 'RE' || i.purchase_id || '_' ||
                                             to_char(sysdate, 'YYYYMMDD');
              in_bsm_purchase.serial_id   := i.serial_id;
              in_bsm_purchase.pay_type    := '信用卡';
              in_bsm_purchase.details     := new tbsm_purchase_dtls();
              in_bsm_purchase.details.extend(1);
              in_bsm_purchase.details(1) := new tbsm_purchase_dtl();
              in_bsm_purchase.details(1).offer_id := i.package_id;
              in_bsm_purchase.details(1).amount := i.amount;
              p_recurrent := 'O';
              p_sw_version := 'RECURRENT_AUTO';
            
              result := bsm_client_service.crt_purchase(in_bsm_purchase   => in_bsm_purchase,
                                                        p_recurrent       => p_recurrent,
                                                        p_device_id       => p_device_id,
                                                        parameter_options => parameter_options,
                                                        p_sw_version      => p_sw_version);
              if result.result_code = 'BSM-00000' then
                -- recurrent 成功註記回正常
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'N', a.recurrent_s_date = sysdate
                 where a.src_no = i.purchase_id;
                commit;
              else
                -- recurrent 失敗註記成扣款期
                declare
                  v_c varchar2(10);
                begin
                  v_c:=lpad(to_char(trunc(i.max_end_date)-trunc(sysdate)),1,'0');
                
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'C'||v_c, a.recurrent_s_date = sysdate,
                   a.next_bill_date = sysdate +1
                 where a.src_no = i.purchase_id;
                commit;
                end;
              end if;
            
            end;
          end if;
        end if;
      
      end loop;
    
      for i in c1 loop
        dbms_output.put_line(i.serial_id);
        -- 已服務過期註銷
       if i.max_end_date < trunc(sysdate) then
          -- recurrent 註記成關閉
          update bsm_recurrent_mas a
             set a.recurrent_status = 'B', a.recurrent_s_date = sysdate
           where a.src_no = i.purchase_id;
          commit;
          dbms_output.put_line(i.serial_id || ':Expired');
          v_msg := stop_recurrent(i.serial_id,
                                  i.purchase_id,
                                  '服務到期',
                                  to_char(SYSDATE, 'YYYYMMDDHH24MISS'));
          bsm_purchase_post.refresh_bsm_client(i.serial_id);
         elsif i.max_end_date < trunc(sysdate) + 1 then
          -- recurrent 註記成警告期
          update bsm_recurrent_mas a
             set a.recurrent_status = 'A', a.recurrent_s_date = sysdate
           where a.src_no = i.purchase_id;
          commit;
        end if;
      end loop;
    end;
    return null;
  end;

  function cht_auto_recurrent return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no purchase_id,
               bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                            b.serial_id) max_end_date,
               --a.cht_flg,
               d.pk_no          detail_pk_no,
               d.start_date,
               a.purchase_pk_no
          from bsm_recurrent_view a,
               bsm_purchase_mas   b,
               bsm_purchase_item  c,
               bsm_client_details d,
               bsm_package_mas    e
        
         where b.status_flg = 'Z'
           and d.status_flg = 'P'
           and b.mas_no = a.mas_no
           and c.mas_pk_no = b.pk_no
           and d.src_item_pk_no = c.pk_no
           and e.package_id = d.package_id
           and a.recurrent_type = 'HINET';
      v_msg     varchar2(1024);
      v_cht_flg varchar2(32);
    begin
      delete CHT_RECURRENT_FAILURE
       where rownum <= 20
         and serial_id <> '2A0012BD48BB45F8';
      commit;
      for i in c1 loop
        v_cht_flg := bsm_cht_service.QuerySubscribe(i.purchase_pk_no);
        if v_cht_flg = 's241' and v_cht_flg != 'Success' and
           i.start_date <= sysdate then
          --    null;
          update bsm_client_details a
             set a.end_date = sysdate, a.status_flg = 'N'
           where a.pk_no = i.detail_pk_no;
          commit;
          bsm_client_service.Set_subscription(null, i.serial_id);
          v_msg := bsm_cdi_service.refresh_client(i.serial_id);
          update bsm_recurrent_mas a
             set status_flg = 'B',
                 a.end_date = decode(sysdate, null, sysdate, sysdate),
                 a.remark   = '電信帳單取消'
           where a.src_no = i.purchase_id;
          commit;
          bsm_purchase_post.refresh_bsm_client(i.serial_id);
          --   v_msg := bsm_recurrent_util.stop_recurrent(i.serial_id,i.purchase_id,'電信帳單取消',to_char(sysdate,'YYYYMMDDHH24MISS'));
        elsif (v_cht_flg = 'Success' or v_cht_flg like 'c%' or
              v_cht_flg like 's4%' or v_cht_flg like 's221') and
              i.start_date <= sysdate then
          if nvl(i.max_end_date, sysdate) < sysdate + 2 then
            update bsm_client_details a
               set a.end_date = sysdate + 30, a.start_date = sysdate
             where a.pk_no = i.detail_pk_no;
            commit;
            bsm_client_service.Set_subscription(null, i.serial_id);
            bsm_purchase_post.refresh_bsm_client(i.serial_id);
          end if;
        
        end if;
      end loop;
    end;
    return null;
  end;

  function ios_auto_recurrent return varchar2 is
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
           and f.mas_pk_no = b.pk_no;
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
          
            if i.max_end_date <= sysdate + 2 then
              expired_date := bsm_ios_gateway.get_exipired_date(i.pk_no,
                                                                i.ios_product_code);
              update bsm_client_details a
                 set a.end_date   = nvl(expired_date, sysdate + 29) + 1,
                     a.start_date = nvl(expired_date, sysdate + 29) - 29
               where a.pk_no = i.detail_pk_no;
              commit;
              bsm_client_service.Set_subscription(null, i.serial_id);
              bsm_purchase_post.refresh_bsm_client(i.serial_id);
            end if;
          end if;
        exception
          when others then
            null;
        end;
      end loop;
    end;
    return null;
  end;

  function tstar_recurrent return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no purchase_id,
               a.card_expiry,
               bsm_encrypt.decrypt_Serial_ID(a.card_no,
                                             b.serial_id || 'tgc27740083') card_no,
               a.card_type,
               a.cvc2,
               c.package_id,
               trunc(get_service_end_date_full(e.package_cat_id1,
                                               b.serial_id)) max_end_date,
               d.pk_no dtl_pk_no
          from bsm_recurrent_mas  a,
               bsm_purchase_mas   b,
               bsm_purchase_item  c,
               bsm_client_details d,
               bsm_package_mas    e
         where a.status_flg = 'P'
           and b.status_flg = 'Z'
           and d.status_flg = 'P'
           and b.mas_no = a.src_no
           and c.mas_pk_no = b.pk_no
           and d.src_item_pk_no = c.pk_no
           and e.package_id = d.package_id
           and trunc(get_service_end_date_full(e.package_cat_id1,
                                               b.serial_id)) <= sysdate
           and a.recurrent_type = 'TSTAR'
         group by b.serial_id,
                  b.mas_no,
                  a.card_expiry,
                  a.card_no,
                  a.card_type,
                  a.cvc2,
                  e.package_cat_id1,
                  c.package_id,
                  d.pk_no;
    
      v_msg varchar2(1024);
    begin
      for i in c1 loop
        update bsm_client_details c
           set c.start_date = sysdate, c.end_date = add_months(sysdate, 1)
         where c.pk_no = i.dtl_pk_no;
        commit;
        bsm_client_service.Set_subscription(null, i.serial_id);
        v_msg := bsm_cdi_service.refresh_client(i.serial_id);
        bsm_purchase_post.refresh_bsm_client(i.serial_id);
      end loop;
    end;
    return null;
  end;

  function reset_recurrent_card(p_purchase_pk_no number,
                                p_card_no        varchar2,
                                p_expiry         varchar2,
                                p_cvc2           varchar2) return varchar2 is
  begin
    update bsm_recurrent_mas a
       set a.card_no     = bsm_encrypt.Encrypt_Serial_ID(p_card_no,
                                                         a.client_id ||
                                                         'tgc27740083'),
           a.card_expiry = p_expiry,
           a.cvc2        = p_cvc2,
           a.status_flg  = 'P'
     where a.src_pk_no = p_purchase_pk_no;
    -- bsm_purchase_post.refresh_bsm_client(i.serial_id);
  
    commit;
    return null;
  end;

 
  function auto_recurrent_liPay return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               a.tx_number,
               a.payment_id,
               c.package_id,
               b.mas_no,
               a.batch_id,
               a.order_id,
               
               b.serial_id client_id,
               a.rowid     pay_info_rid,
               a.pk_no,
               a.amount,
               a.status
          from view_payment_info a, bsm_purchase_mas b, bsm_purchase_item c,bsm_package_mas d
         where a.status in ('ok', 'fail')
           and b.status_flg = 'Z'
           and b.mas_no = a.order_id
           and c.mas_pk_no = b.pk_no
           and d.package_id=c.package_id
           and d.recurrent='R'
           and a.process_flg is null;
      v_msg        varchar2(1024);
      v_client_id  varchar2(32);
      v_package_id varchar2(32);
      v_src_no     varchar2(64);
      v_char       varchar2(32);
      dup_purchase_mas Exception;
      v_Purchase_Pk_No      number(16);
      v_Purchase_Item_Pk_No number(16);
      v_Purchase_No         varchar2(32);
      p_sw_version          varchar2(32);
    
    begin
      for i in c1 loop
        if i.status = 'ok' then
          begin
            v_client_id := i.client_id;
            v_src_no    := 'RE' || i.mas_no || i.batch_id;
            begin
              select 'x'
                into v_char
                from bsm_purchase_mas a
               where a.src_no = v_src_no
                 and rownum <= 1;
              raise dup_purchase_mas;
            exception
              when no_data_found then
                null;
            end;
            p_sw_version := 'RECURRENT_AUTO';
            -- 檢查是否已經扣款過
          
            declare
              v_acc_invo_no       varchar2(32);
              v_pay_type          varchar2(32) := '信用卡二次扣款';
              v_Client_Info       Tbsm_Client_Info;
              v_acc_name          varchar2(32);
              v_tax_code          varchar2(32);
              v_Purchase_Mas_Code varchar(32) := 'BSMPUR';
              v_Serial_No         number(16);
              v_id                varchar2(32);
              v_Price             number(16);
              v_Duration          number(16);
              v_Quota             number(16);
              v_charge_type       varchar2(32);
              v_charge_code       varchar2(32);
              v_start_type        varchar2(32);
              v_recurrent         varchar2(32);
              v_charge_name       varchar2(32);
              v_package_cat_id1   varchar2(32);
              v_purchase_date     date;
            
              p_user_no           number(16) := 0;
              v_last_service_date date;
            
            begin
            
              v_Client_Info   := bsm_client_service.Get_Client_Info(v_client_id);
              v_Serial_No     := v_client_info.serial_no;
              v_purchase_date := to_date(substr(i.batch_id, 1, 8),
                                         'YYYYMMDD');
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_Purchase_Pk_No
                From Dual;
            
              v_Purchase_Mas_Code := 'BSMPUR';
            
              v_Purchase_No := Sysapp_Util.Get_Mas_No(1,
                                                      2,
                                                      Sysdate,
                                                      v_Purchase_Mas_Code,
                                                      v_Purchase_Pk_No);
              v_acc_invo_no := sysapp_util.get_mas_no(1,
                                                      2,
                                                      sysdate,
                                                      'BSMPUR_INV',
                                                      v_Purchase_Pk_No);
            
              if v_Client_Info.Owner_ID is not null then
                begin
                  select cust_name, tax_code
                    into v_acc_name, v_tax_code
                    from tgc_customer
                   where cust_id = v_Client_Info.Owner_ID;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            
              v_recurrent := 'O';
            
              Insert Into Bsm_Purchase_Mas
                (Src_No,
                 Pk_No,
                 Mas_No,
                 Mas_Date,
                 Mas_Code,
                 Src_Code,
                 Src_Date,
                 Serial_No,
                 acc_code,
                 Serial_Id,
                 Status_Flg,
                 Purchase_Date,
                 Pay_Type,
                 Card_type,
                 Card_no,
                 Card_Expiry,
                 Cvc2,
                 inv_no,
                 f_year,
                 f_period,
                 due_date,
                 acc_name,
                 tax_code,
                 recurrent,
                 start_type,
                 software_group,
                 amount,
                 NEXT_PAY_DATE)
              Values
                (v_src_no,
                 v_Purchase_Pk_No,
                 v_Purchase_No,
                 Sysdate,
                 v_Purchase_Mas_Code,
                 Null,
                 Null,
                 v_Serial_No,
                 v_Client_Info.Owner_ID,
                 v_client_Id,
                 'A',
                 v_purchase_date,
                 v_Pay_Type,
                 null,
                 null,
                 null,
                 null,
                 v_acc_invo_no,
                 to_number(to_char(sysdate, 'YYYY')),
                 to_number(to_char(sysdate, 'MM')),
                 sysdate + 7,
                 v_acc_name,
                 null,
                 v_recurrent,
                 'E',
                 p_sw_version,
                 i.amount,
                 add_months(v_purchase_date, 1)
                 );
            
              --
              --  計算價格
              --
              v_id := i.package_id;
              Begin
                Select a.Charge_Amount,
                       a.Acl_Duration,
                       a.Acl_Quota,
                       a.charge_type,
                       a.charge_code,
                       a.package_cat_id1
                  Into v_Price,
                       v_Duration,
                       v_Quota,
                       v_charge_type,
                       v_charge_code,
                       v_package_cat_id1
                  From Bsm_Package_Mas a
                 Where a.Package_id = v_id;
              
              End;
              select max(end_date)
                into v_last_service_date
                from bsm_client_details a
               where mac_address = v_client_id
                 and status_flg = 'P'
                 and a.end_date is not null
                 and a.package_id in
                     (select package_id
                        from bsm_package_mas b
                       where status_flg = 'P'
                         and b.cal_type not in ('I', 'T')
                         and nvl(b.acl_period, 0) = 0
                         and b.package_cat_id1 = v_package_cat_id1);
            
              v_Price := i.amount;
            
              v_recurrent := 'R';
            
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_Purchase_Item_Pk_No
                From Dual;
            
              if v_charge_code is null then
                v_charge_code := sysapp_util.get_sys_value('BSMPUR',
                                                           'Default charge code',
                                                           'PMONTHFEE');
              end if;
            
              begin
                select chg_name
                  into v_charge_name
                  from service_charge_mas
                 where chg_code = v_charge_code;
              exception
                when no_data_found then
                  v_charge_code := 'PMONTHFEE';
                  v_charge_name := '預付月租費';
              end;
            
              Insert Into Bsm_Purchase_Item
                (Pk_No,
                 Mas_Pk_No,
                 Package_ID,
                 ITEM_ID,
                 Price,
                 Amount,
                 Duration,
                 CHG_TYPE,
                 CHG_CODE,
                 CHG_NAME,
                 TAX_AMT,
                 CHG_AMT,
                 TOTAL_AMT,
                 DEVICE_ID)
              Values
                (v_Purchase_Item_Pk_No,
                 v_Purchase_Pk_No,
                 v_id,
                 null,
                 0,
                 v_Price,
                 v_Duration,
                 v_charge_type,
                 v_charge_code,
                 v_charge_name,
                 0,
                 0,
                 v_Price,
                 null);
            
              commit;
            
              declare
                v_msg number(16);
              begin
                v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                         v_purchase_pk_no);
                v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                             v_purchase_pk_no);
              end;
            
              update bsm_purchase_mas a
                 set a.lipay_tx_number = i.tx_number,
                     a.pay_pk_no       = i.payment_id
               where a.pk_no = v_purchase_pk_no;
            
              begin
                -- 時間過期三天內,自動移動服務接續一起
                if v_last_service_date is not null and
                   v_last_service_date >= sysdate - 4 then
                  update bsm_client_details a
                     set a.start_date = v_last_service_date + 1,
                         a.end_date   = a.end_date - (v_last_service_date + 1 -
                                        a.start_date)
                   where a.src_pk_no = v_purchase_pk_no;
                  bsm_client_service.Set_subscription(v_purchase_pk_no,
                                                      v_client_id);
                end if;
              end;
            
            end;
          
            update view_payment_info
               set process_flg = 'Y'
             where rowid = i.pay_info_rid;
          exception
            when dup_purchase_mas then
              null;
            
          end;
          update view_payment_info
             set process_flg = 'Y'
           where rowid = i.pay_info_rid;
          commit;
        
          -- 發票開立
        
          declare
            v_msg       varchar2(1024);
            v_inv_no    varchar2(32);
            v_inv_date  date;
            v_tax_bk_no varchar2(32);
            v_org_no    number(16);
          begin
            v_org_no := 1;
          
            select mas_no
              into v_tax_bk_no
              from tax_bk_mas a
             where a.start_date <= sysdate
               and trunc(end_date) + 1 > sysdate
               and no_end - nvl(a.curr_no, a.no_start - 1) > 0
               and status_flg = 'P'
               and a.org_no = v_org_no
               and rownum <= 1
             order by mas_no;
          
            v_msg := tax_post.crt_inv_tax(0,
                                          0,
                                          v_tax_bk_no,
                                          null,
                                          null,
                                          'BSMPUR',
                                          v_Purchase_No,
                                          v_Purchase_pk_no,
                                          v_org_no);
          
            commit;
          
            select b.f_invo_no, b.f_invo_date
              into v_inv_no, v_inv_date
              from tax_inv_mas b
             where b.src_pk_no = v_Purchase_pk_no
               and b.status_flg = 'P';
          
            update bsm_purchase_mas a
               set a.tax_inv_no = v_inv_no, a.tax_inv_date = v_inv_date
             where a.pk_no = v_Purchase_pk_no;
          
            Insert Into Sysevent_Log
              (App_Code,
               Pk_No,
               Event_Date,
               User_No,
               Event_Type,
               Seq_No,
               Description)
            Values
              (v_Purchase_no,
               v_Purchase_pk_no,
               Sysdate,
               0,
               '發票',
               Sys_Event_Seq.Nextval,
               '發票');
            commit;
          exception
            when others then
              null;
          end;
        
        elsif i.status = 'fail' then
          update bsm_recurrent_mas a
             set status_flg         = 'B',
                 a.end_date         = sysdate,
                 a.remark           = 'LiPay中止',
                 a.last_modify_date = sysdate
          
           where a.src_no = i.order_id;
        
          update view_payment_info
             set process_flg = 'Y'
           where rowid = i.pay_info_rid;
          commit;
        end if;
      
        bsm_client_service.refresh_bsm_client(v_client_id);
      
      end loop;
    end;
    return null;
  end;

end;
/

