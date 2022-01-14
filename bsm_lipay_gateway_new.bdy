CREATE OR REPLACE PACKAGE BODY IPTV."BSM_LIPAY_GATEWAY_NEW" is
  PAYMENT_GATEWAY_BASE varchar2(256) :=link_set.link_set.p_lipay_url;
  -- PAYMENT_GATEWAY_BASE varchar2(256) := 'http://p-lipay.tw.svc.litv.tv';
  --'http://s-lipay01.tw.svc.litv.tv:8080';
  -- PAYMENT_GATEWAY_URL  varchar2(256) := PAYMENT_GATEWAY_BASE ||
  --'/payment/creditcard';
  PAYMENT_GATEWAY_URL varchar2(256) := PAYMENT_GATEWAY_BASE;
  function http_call(url varchar2, content varchar) return clob is
    req     utl_http.req;
    resp    utl_http.resp;
    buf     VARCHAR2(32767);
    pagelob clob;
  begin
    UTL_HTTP.SET_BODY_CHARSET('UTF-8');
  
    req := utl_http.begin_request(url, 'POST', 'HTTP/1.1');
    utl_http.set_header(req,
                        'Content-Type',
                        'application/json; charset=utf-8');
    utl_http.set_header(req, 'Content-Length', length(content));
  
    utl_http.write_text(req, content);
    resp := utl_http.get_response(req);
    dbms_lob.createtemporary(pagelob, true);
    begin
      LOOP
        utl_http.read_text(resp, buf);
        dbms_lob.writeappend(pagelob, length(buf), buf);
      END LOOP;
    EXCEPTION
      WHEN UTL_HTTP.TOO_MANY_REQUESTS THEN
        UTL_HTTP.END_RESPONSE(resp);
      WHEN others THEN
        dbms_output.put_line(sys.utl_http.GET_DETAILED_SQLERRM());
    end;
  
    utl_http.end_response(resp);
    return pagelob;
  
  end;

  
  function AccePayment(p_order_no        varchar2,
                       p_amt             number,
                       p_card_type       varchar2,
                       p_card_no         varchar2,
                       p_card_expiry     varchar2,
                       p_cvc2            varchar2,
                       parameter_options varchar2 default null,
                       recurrent         varchar2 default 'once')
    return varchar2 is
    jsonObj   json;
    p_respond varchar2(30000);
    connect_exception exception;
    v_OrderNumber     varchar2(32);
    v_test_card       varchar2(32);
    v_cvc2            varchar2(32);
    v_expire_yymm     varchar2(32);
    v_phone_no        varchar2(32);
    v_client_phone_no varchar2(32);
    v_purchase_id     varchar2(32);
    v_purchase_no     number(16);
    v_client_id       varchar2(32);
    v_log_pk_no       number(16);
    v_pay_pk_no       number(16);
    v_token  number(16);
  begin
  
    begin
    
      select cvc2, expire_yymm, phone_no
        into v_cvc2, v_expire_yymm, v_phone_no
        from mfg_dev_credit
       where card_no = trim(p_card_no)
         and start_date <= sysdate
         and end_date + 1 > sysdate
         and status_flg = 'P'
         and rownum <= 1;
    
      if v_phone_no is not null then
      
        if p_order_no is not null then
          begin
            select a.owner_phone
              into v_client_phone_no
              from bsm_client_mas a
             where a.status_flg = 'A'
               and mac_address =
                   (select serial_id
                      from bsm_purchase_mas b
                     where b.pk_no = p_order_no);
          exception
            when no_data_found then
              v_client_phone_no := v_phone_no;
          end;
        end if;
      
        if v_client_phone_no = v_phone_no then
          if v_cvc2 = p_cvc2 and v_expire_yymm = p_card_expiry then
            p_respond := 'PRC=0';
          else
            p_respond := 'PRC=3||card_expiry&p_cvc2';
          end if;
        else
          p_respond := 'PRC=3||phone_no';
        end if;
      else
        if v_cvc2 = p_cvc2 and v_expire_yymm = p_card_expiry then
          p_respond := 'PRC=0';
        else
          p_respond := 'PRC=3||no_phone check &card_expiry&p_cvc2';
        end if;
      end if;
    
      v_test_card := 'Y';
    exception
      when no_data_found then
        v_test_card := 'N';
    end;
  
    if v_test_card <> 'Y' then
      begin
      select mas_no, pk_no, serial_id, seq_bsm_purchase_pk_no.nextval
        into v_purchase_id, v_purchase_no, v_client_id, v_log_pk_no
        from bsm_purchase_mas a
       where a.pk_no = p_order_no;
      exception
      when no_data_found then
      select mas_no, pk_no, client_id, seq_bsm_purchase_pk_no.nextval
        into v_purchase_id, v_purchase_no, v_client_id, v_log_pk_no
        from bsm_order_mas a
       where a.pk_no =  p_order_no;
      end;        
    
      commit;
      if recurrent = 'once' then
        declare
          jsonObj json;
          req     utl_http.req;
          resp    utl_http.resp;
          buf     VARCHAR2(32767);
          pagelob clob;
          content varchar2(4000) := '{
  "type": "card",
  "client_id": "_CLIENT_ID_",
  "client_email": "lipay@tgc-taiwan.com.tw",
  "card_number": "_CARD_NO_",
  "card_expiry": "_EXPIRY_",
  "card_csc": "_CVC2_",
  "platform_code": "bsm",
  "platform_order_id": "_ORDER_ID_",
  "amount": _AMT_
}';
        
          /*
                    content varchar2(4000) := '{
            "amount": "_AMT_",
            "user_code": "BSM",
            "order_id": "_ORDER_ID_",
            "card_number": "_CARD_NO_",
            "card_expiry": "_EXPIRY_",
            "csc": "_CVC2_"
          }'; */
          /*
          {
            "type": "card",
            "client_id": "test_client",
            "client_email": "roy.su@tgc-taiwan.com.tw",
            "card_number": "4000221111111111",
            "card_expiry": "2101",
            "card_csc": "333",
            "platform_code": "lipay_test",
            "platform_order_id": "test_pay_card_20200330_001",
            "amount": 100
          }*/
        
        BEGIN
          content := replace(content, '_CLIENT_ID_', v_client_id);
          content := replace(content, '_AMT_', p_amt);
          content := replace(content, '_ORDER_ID_', v_purchase_id);
          content := replace(content, '_CARD_NO_', p_card_no);
          content := replace(content,
                             '_EXPIRY_',
                             substr(p_card_expiry, 3, 4));
          content := replace(content, '_CVC2_', p_cvc2);
        
          Insert /*+ append */
          Into bsm_purchase_log
            (pk_no,
             mas_pk_no,
             event_date,
             event_type,
             event_log,
             client_id,
             order_id,
             log_type,
             post)
          Values
            (v_log_pk_no,
             p_order_no,
             Sysdate,
             'LiPay',
             null,
             v_client_id,
             v_purchase_id,
             'creditcard/once',
              replace(content,p_card_no,'******'));
          commit;
        
          --   pagelob := http_call(PAYMENT_GATEWAY_URL || '/once', content);
          pagelob := http_call(PAYMENT_GATEWAY_URL || '/newebpay/pay',
                               content);
        
          update bsm_purchase_log
             set response = pagelob
           where pk_no = v_log_pk_no;
          commit;
        
          jsonobj := json(pagelob);
          --   if json_ext.get_string(jsonobj, 'result') = 'ok' then
          if json_ext.get_string(jsonobj, 'code') = '0' then
            --  v_orderNumber := json_ext.get_string(jsonobj, 'data.tx_number');
            v_orderNumber := 'newebpay'||json_ext.get_string(jsonobj,
                                                 'data.newebpay_trade_id');
          --  if v_orderNumber is null then
           --   v_orderNumber := json_ext.get_string(jsonobj, 'tx_number');
           -- end if;
            --   v_pay_pk_no := json_ext.get_number(jsonobj, 'data.payment_id');
            --  if v_pay_pk_no is null then token_id
            --    v_pay_pk_no := json_ext.get_number(jsonobj, 'payment_id');
            --  end if;
                        v_pay_pk_no := json_ext.get_number(jsonobj, 'data.payment_id');
            v_token := json_ext.get_number(jsonobj, 'data.token_id');
            update bsm_purchase_mas
               set lipay_tx_number = v_orderNumber, pay_pk_no = v_pay_pk_no,token_id=v_token
             where pk_no = to_number(p_order_no);
            update bsm_purchase_log a
               set a.src_no = v_orderNumber
             where pk_no = v_log_pk_no;
          
            commit;
          
            return 'PRC=0' || '&APPROC_CODE=XXXX';
          else
            --    return 'PRC=3' || json_ext.get_string(jsonobj, 'error_msg');
            return 'PRC=3' || json_ext.get_string(jsonobj, 'message');
          end if;
        
          dbms_lob.freetemporary(pagelob);
        exception
          when others then
            --  utl_http.end_response(http_resp);
            if p_card_no <> '4774000000001111' then
              --  dbms_lock.sleep(10);
            
              return AccePayment(p_order_no,
                                 p_amt,
                                 p_card_type,
                                 '4774000000001111',
                                 p_card_expiry,
                                 p_cvc2,
                                 parameter_options,
                                 recurrent);
            end if;
        end;
      else
        declare
          v_next_pay_date date;
          jsonObj         json;
          req             utl_http.req; --request object(pl/sql record)
          resp            utl_http.resp; --response objects(pl/sql record)
          buf             VARCHAR2(32767);
          pagelob         clob;
          change_next_pay_failure exception;
          content varchar2(4000) := '{
  "type": "card",
  "client_id": "_CLIENT_ID_",
  "client_email": "lipay@tgc-taiwan.com.tw",
  "card_number": "_CARD_NO_",
  "card_expiry": "_EXPIRY_",
  "card_csc": "_CVC2_",
  "platform_code": "bsm",
  "platform_order_id": "_ORDER_ID_",
  "amount": _AMT_
}';
          /*
                    content varchar2(4000) := '{
            "user_code": "BSM",
            "order_id": "_ORDER_ID_",
            "amount": "_AMT_",
            "card_number": "_CARD_NO_",
            "card_expiry": "_EXPIRY_",
            "csc": "_CVC2_",
            "pay_loop": "-1",
            "pay_frequency": "1",
            "charge_date": "_NETXPAYDATE_"
          }
          '; */
        BEGIN
          select add_months(nvl(bsm_recurrent_util.get_service_end_date(d.package_cat_id1,
                                                                        v_client_id),
                                sysdate),
                            d.duration_by_month) + d.duration_by_day - 3
            into v_next_pay_date
            from bsm_purchase_item c, bsm_package_mas d
           where d.package_id = c.package_id
             and c.mas_pk_no = v_purchase_no
             and rownum <= 1;
          content := replace(content, '_CLIENT_ID_', v_client_id);
          content := replace(content, '_AMT_', p_amt);
          content := replace(content, '_ORDER_ID_', v_purchase_id);
          content := replace(content, '_CARD_NO_', p_card_no);
          content := replace(content,
                             '_EXPIRY_',
                             substr(p_card_expiry, 3, 4));
          content := replace(content, '_CVC2_', p_cvc2);
          content := replace(content,
                             '_NETXPAYDATE_',
                             to_char(v_next_pay_date, 'YYYYMMDD'));
        
          Insert /*+ append */
          Into bsm_purchase_log
            (pk_no,
             mas_pk_no,
             event_date,
             event_type,
             event_log,
             client_id,
             order_id,
             log_type,
             post)
          Values
            (v_log_pk_no,
             p_order_no,
             Sysdate,
             'LiPay',
             null,
             v_client_id,
             v_purchase_id,
             'creditcard/recurent',
             replace(content,p_card_no,'******'));
          commit;
        
          /* pagelob := http_call(PAYMENT_GATEWAY_URL || '/recurent', content); */
          UTL_HTTP.SET_BODY_CHARSET('UTF-8');
          pagelob := http_call(PAYMENT_GATEWAY_URL || '/newebpay/pay',
                               content);
        
          update bsm_purchase_log
             set response = pagelob
           where pk_no = v_log_pk_no;
          commit;
          jsonobj := json(pagelob);
        
          --   if json_ext.get_string(jsonobj, 'result') = 'ok' then
          if json_ext.get_string(jsonobj, 'code') = '0' then
            v_token := json_ext.get_number(jsonobj, 'data.token_id');
            --  v_pay_pk_no := json_ext.get_number(jsonobj, 'data.payment_id');
            --  if v_pay_pk_no is null then
            --    v_pay_pk_no := json_ext.get_number(jsonobj, 'payment_id');
            
            --  end if;
                        --  v_orderNumber := json_ext.get_string(jsonobj, 'data.tx_number');
            v_orderNumber := 'newebpay'||json_ext.get_string(jsonobj,
                                                 'data.newebpay_trade_id');
          --  if v_orderNumber is null then
           --   v_orderNumber := json_ext.get_string(jsonobj, 'tx_number');
           -- end if;
            --   v_pay_pk_no := json_ext.get_number(jsonobj, 'data.payment_id');
            --  if v_pay_pk_no is null then token_id
            --    v_pay_pk_no := json_ext.get_number(jsonobj, 'payment_id');
            --  end if;
                        v_pay_pk_no := json_ext.get_number(jsonobj, 'data.payment_id');
            v_token := json_ext.get_number(jsonobj, 'data.token_id');
                        update bsm_purchase_mas
               set lipay_tx_number = v_orderNumber, pay_pk_no = v_pay_pk_no,token_id=v_token
             where pk_no = to_number(p_order_no);
          
            update bsm_purchase_log a
               set a.src_no = v_orderNumber
             where pk_no = v_log_pk_no;
          
            commit;
            return 'PRC=0' || '&APPROC_CODE=XXXX';
          else
            -- raise change_next_pay_failure;
            return 'PRC=3' || json_ext.get_string(jsonobj, 'error_msg');
          end if;
        
          --     dbms_lob.freetemporary(pagelob);
        exception
          when others then
            if p_card_no <> '4774000000001111' then
              --  utl_http.end_response(http_resp);
              --     dbms_lock.sleep(10);
              return AccePayment(p_order_no,
                                 p_amt,
                                 p_card_type,
                                 '4774000000001111',
                                 p_card_expiry,
                                 p_cvc2,
                                 parameter_options,
                                 
                                 recurrent);
            end if;
        end;
      
      end if;
    
    end if;
    return substr(p_respond, instr(p_respond, 'PRC'));
  
  end;

 function AccePayment_token(p_order_no        varchar2,
                       p_amt             number,
                       token             varchar2,
                       parameter_options varchar2 default null,
                       recurrent         varchar2 default 'once')
    return varchar2 is
    jsonObj   json;
    p_respond varchar2(30000);
    connect_exception exception;
    v_OrderNumber     varchar2(32);
    v_test_card       varchar2(32);
    v_cvc2            varchar2(32);
    v_expire_yymm     varchar2(32);
    v_phone_no        varchar2(32);
    v_client_phone_no varchar2(32);
    v_purchase_id     varchar2(32);
    v_purchase_no     number(16);
    v_client_id       varchar2(32);
    v_log_pk_no       number(16);
    v_pay_pk_no       number(16);
  begin
          begin
      select mas_no, pk_no, serial_id, seq_bsm_purchase_pk_no.nextval
        into v_purchase_id, v_purchase_no, v_client_id, v_log_pk_no
        from bsm_purchase_mas a
       where a.pk_no = p_order_no;
      exception
      when no_data_found then
      select mas_no, pk_no, client_id, seq_bsm_purchase_pk_no.nextval
        into v_purchase_id, v_purchase_no, v_client_id, v_log_pk_no
        from bsm_order_mas a
       where a.pk_no =  p_order_no;
      end; 
  
        
      if recurrent = 'once' then
        declare
          jsonObj json;
          req     utl_http.req;
          resp    utl_http.resp;
          buf     VARCHAR2(32767);
          pagelob clob;
          content varchar2(4000) := '{
  "type": "token",
  "token_id": _token_,
  "platform_code": "bsm",
  "platform_order_id": "_ORDER_ID_",
  "amount": _amount_
}';
               
        BEGIN
          content := replace(content, '_CLIENT_ID_', v_client_id);
           content := replace(content, '_token_', token);
          content := replace(content, '_amount_', p_amt);
          content := replace(content, '_ORDER_ID_', v_purchase_id);
                 
          Insert /*+ append */
          Into bsm_purchase_log
            (pk_no,
             mas_pk_no,
             event_date,
             event_type,
             event_log,
             client_id,
             order_id,
             log_type,
             post)
          Values
            (v_log_pk_no,
             p_order_no,
             Sysdate,
             'LiPay',
             null,
             v_client_id,
             v_purchase_id,
             'creditcard/once',
             content);
          commit;
        
          --   pagelob := http_call(PAYMENT_GATEWAY_URL || '/once', content);
          pagelob := http_call(PAYMENT_GATEWAY_URL || '/newebpay/pay',
                               content);
        
          update bsm_purchase_log
             set response = pagelob
           where pk_no = v_log_pk_no;
          commit;
        
          jsonobj := json(pagelob);
          --   if json_ext.get_string(jsonobj, 'result') = 'ok' then
          if json_ext.get_string(jsonobj, 'code') = '0' then
            --  v_orderNumber := json_ext.get_string(jsonobj, 'data.tx_number');
            v_orderNumber := 'newebpay'||json_ext.get_string(jsonobj,
                                                 'newebpay_trade_id');
          --  if v_orderNumber is null then
           --   v_orderNumber := json_ext.get_string(jsonobj, 'tx_number');
           -- end if;
            --   v_pay_pk_no := json_ext.get_number(jsonobj, 'data.payment_id');
            --  if v_pay_pk_no is null then token_id
            --    v_pay_pk_no := json_ext.get_number(jsonobj, 'payment_id');
            --  end if;
            v_pay_pk_no := json_ext.get_number(jsonobj, 'token_id');
          
            update bsm_purchase_mas
               set lipay_tx_number = v_orderNumber, pay_pk_no = v_pay_pk_no
             where pk_no = p_order_no;
            update bsm_purchase_log a
               set a.src_no = v_orderNumber
             where pk_no = v_log_pk_no;
          
            commit;
          
            return 'PRC=0' || '&APPROC_CODE=XXXX';
          else
            --    return 'PRC=3' || json_ext.get_string(jsonobj, 'error_msg');
            return 'PRC=3' || json_ext.get_string(jsonobj, 'message');
          end if;
        
          dbms_lob.freetemporary(pagelob);
      
        end;
     end if;
    
    return substr(p_respond, instr(p_respond, 'PRC'));
  
  end;

  function stopRecurrent(p_order_no varchar2) return varchar2 is
    li_tx_number varchar2(32);
  begin
    declare
      jsonObj json;
    
      v_mas_pk_no number(16);
      pagelob     clob;
      v_client_id varchar2(32);
    
      content varchar2(4000) := '{
  "user_code": "BSM",
  "order_id": "_ORDER_ID_",
  "tx_number": "_TX_ID_"
}
';
    BEGIN
      Select lipay_tx_number, serial_id, pk_no
        into li_tx_number, v_client_id, v_mas_pk_no
        from bsm_purchase_mas
       where mas_no = p_order_no;
    
      content := replace(content, '_ORDER_ID_', p_order_no);
      content := replace(content, '_TX_ID_', li_tx_number);
    
      pagelob := http_call(PAYMENT_GATEWAY_BASE || '/recurent/stop',
                           content);
    
      Insert /*+ append */
      Into bsm_purchase_log
        (mas_pk_no,
         event_date,
         event_type,
         event_log,
         client_id,
         order_id,
         log_type,
         post,
         response,
         src_no)
      Values
        (v_mas_pk_no,
         Sysdate,
         'LiPay',
         null,
         v_client_id,
         p_order_no,
         '/recurent/stop',
         content,
         pagelob,
         li_tx_number);
      commit;
      jsonobj := json(pagelob);
      if json_ext.get_string(jsonobj, 'result') = 'ok' or
         json_ext.get_string(jsonobj, 'error_msg') =
         'tx status is not currect' then
        return 'PRC=0';
      else
        return 'PRC=0';
      end if;
    
      dbms_lob.freetemporary(pagelob);
    end;
  exception
    when others then
      return 'PRC=0';
  end;

  function changChargeDate(p_order_no varchar2, p_charg_date date)
    return varchar2 is
    li_tx_number varchar2(32);
    v_client_id  varchar2(32);
    v_log_pk_no  number(16);
  begin
    declare
      jsonObj     json;
      v_mas_pk_no number(16);
      pagelob     clob;
      content     varchar2(4000) := '{
  "user_code": "BSM",
  "order_id": "_ORDER_ID_",
  "tx_number": "_TX_ID_",
  "charge_date": "_CHARGE_DATE_"
}
';
    BEGIN
      Select lipay_tx_number,
             pk_no,
             serial_id,
             seq_bsm_purchase_pk_no.nextval
        into li_tx_number, v_mas_pk_no, v_client_id, v_log_pk_no
        from bsm_purchase_mas
       where mas_no = p_order_no;
    
      content := replace(content, '_ORDER_ID_', p_order_no);
      content := replace(content, '_TX_ID_', li_tx_number);
      content := replace(content,
                         '_CHARGE_DATE_',
                         to_char(p_charg_date, 'YYYYMMDD'));
    
      Insert /*+ append */
      Into bsm_purchase_log
        (pk_no,
         mas_pk_no,
         event_date,
         event_type,
         event_log,
         client_id,
         order_id,
         log_type,
         post)
      Values
        (v_log_pk_no,
         v_mas_pk_no,
         Sysdate,
         'LiPay',
         null,
         v_client_id,
         p_order_no,
         '/recurent/modify/day',
         content);
      commit;
    
      pagelob := http_call(PAYMENT_GATEWAY_BASE || '/recurent/modify/day',
                           content);
    
      update bsm_purchase_log
         set response = pagelob
       where pk_no = v_log_pk_no;
      commit;
    
      if json_ext.get_string(jsonobj, 'result') = 'ok' then
        update bsm_purchase_mas t
           set t.next_pay_date = p_charg_date
         where mas_no = p_order_no;
        commit;
        return 'PRC=0';
      else
        return 'PRC=3' || json_ext.get_string(jsonobj, 'error_msg');
      end if;
    
      dbms_lob.freetemporary(pagelob);
    end;
  end;

  function changeCreditCard(p_order_pk_no number,
                            card_number   varchar2,
                            card_expiry   varchar2,
                            csc           varchar2) return varchar2 is
    li_tx_number  varchar2(32);
    v_mas_pk_no   number(16);
    v_log_pk_no   number(16);
    v_client_id   varchar2(32);
    p_order_no    varchar2(32);
    v_orderNumber varchar2(32);
    v_pay_pk_no   varchar2(32);
  
  begin
    declare
      jsonObj     json;
      v_mas_pk_no number(16);
      pagelob     clob;
      content     varchar2(4000) := '{
  "user_code": "BSM",
  "order_id": "_ORDER_ID_",
  "tx_number": "_TX_ID_",
  "card_number": "_CARD_NO_",
  "card_expiry": "_CARD_EXPIRY_",
  "csc": "_CSC_",
  "charge_now":false
}

';
    BEGIN
      Select lipay_tx_number,
             pk_no,
             seq_bsm_purchase_pk_no.nextval,
             serial_id,
             mas_no
        into li_tx_number,
             v_mas_pk_no,
             v_log_pk_no,
             v_client_id,
             p_order_no
        from bsm_purchase_mas
       where pk_no = p_order_pk_no;
    
      content := replace(content, '_ORDER_ID_', p_order_no);
      content := replace(content, '_TX_ID_', li_tx_number);
      content := replace(content, '_CARD_NO_', card_number);
      content := replace(content, '_CARD_EXPIRY_', card_expiry);
      content := replace(content, '_CSC_', csc);
    
      Insert /*+ append */
      Into bsm_purchase_log
        (pk_no,
         mas_pk_no,
         event_date,
         event_type,
         event_log,
         client_id,
         order_id,
         log_type,
         post)
      Values
        (v_log_pk_no,
         v_mas_pk_no,
         Sysdate,
         'LiPay',
         null,
         v_client_id,
         p_order_no,
         'modify/cardnumber',
         content);
      commit;
    
      pagelob := http_call(PAYMENT_GATEWAY_BASE ||
                           '/recurent/modify/cardnumber',
                           content);
    
      update bsm_purchase_log
         set response = pagelob
       where pk_no = v_log_pk_no;
      commit;
      jsonobj := json(pagelob);
    
      if json_ext.get_string(jsonobj, 'result') = 'ok' then
        v_orderNumber := json_ext.get_string(jsonobj, 'data.tx_number');
        if v_orderNumber is null then
          v_orderNumber := json_ext.get_string(jsonobj, 'tx_number');
        end if;
        v_pay_pk_no := json_ext.get_number(jsonobj, 'data.tx_number');
        if v_pay_pk_no is null then
          v_pay_pk_no := json_ext.get_number(jsonobj, 'tx_number');
        end if;
      
        update bsm_purchase_mas
           set lipay_tx_number = v_orderNumber
         where pk_no = p_order_pk_no;
        update bsm_purchase_log a
           set a.src_no = v_orderNumber
         where pk_no = v_log_pk_no;
      
        commit;
      
        return 'PRC=0';
      else
        return 'PRC=3' || json_ext.get_string(jsonobj, 'error_msg');
      end if;
    
      dbms_lob.freetemporary(pagelob);
    end;
  end;

  function refund(p_order_no varchar2, refund_amt number) return varchar2 is
    li_tx_number varchar2(32);
  begin
    declare
      jsonObj     json;
      v_mas_pk_no number(16);
      v_pay_pk_no varchar2(32);
      pagelob     clob;
      v_client_id varchar2(32);
      v_src_no    varchar2(32);
      v_order_id  varchar2(64);
      v_pay_type  varchar2(64);
    /*        content     varchar2(4000) := '{
  "user_code": "BSM",
  "order_id": "_ORDER_ID_",
  "tx_number": "_TX_ID_",
  "payment_id": _PAY_PK_NO_,
  "amount": _AMT_
}
';*/
      content     varchar2(4000) := '{
  "payment_id": _PAY_PK_NO_,
  "amount": _AMT_
}
';
    
    BEGIN
      Select lipay_tx_number,
             serial_id,
             pk_no,
             nvl(pay_pk_no, 0),
             src_no,
             pay_type
        into li_tx_number,
             v_client_id,
             v_mas_pk_no,
             v_pay_pk_no,
             v_src_no,
             v_pay_type
        from bsm_purchase_mas
       where mas_no = p_order_no;
    
      if substr(v_src_no, 1, 2) = 'RE' and v_pay_type = '信用卡二次扣款' then
        -- recurrent 
        v_order_id := substr(v_src_no, 3, 17);
      else
        v_order_id := p_order_no;
      end if;
    
      content := replace(content, '_ORDER_ID_', v_order_id);
      content := replace(content, '_TX_ID_', li_tx_number);
      content := replace(content, '_PAY_PK_NO_', v_pay_pk_no);
      content := replace(content, '_AMT_', to_char(refund_amt));
    
      pagelob := http_call(PAYMENT_GATEWAY_URL || '/newebpay/refund',
            content);
    
      Insert /*+ append */
      Into bsm_purchase_log
        (mas_pk_no,
         event_date,
         event_type,
         event_log,
         client_id,
         order_id,
         log_type,
         post,
         response,
         src_no)
      Values
        (v_mas_pk_no,
         Sysdate,
         'LiPay',
         null,
         v_client_id,
         p_order_no,
         '/refund/creditcard',
         content,
         pagelob,
         li_tx_number);
      commit;
    
      jsonobj := json(pagelob);
      if json_ext.get_string(jsonobj, 'code') = '0' then
        return 'PRC=0';
      else
        return 'PRC=3' || json_ext.get_string(jsonobj, 'error_msg');
      end if;
    
      dbms_lob.freetemporary(pagelob);
    end;
  end;

end BSM_LIPAY_GATEWAY_NEW;
/

