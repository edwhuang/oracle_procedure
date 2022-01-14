create or replace package body iptv.BSM_ORDER_SERVICE_DEV is
 function create_order(p_order varchar2) return varchar2 is
    p_pk_no           number(16);
    v_order           clob;
    v_mas_no          varchar2(32);
    r_order           bsm_order_mas%rowtype;
    jsonobj           json;
    v_create_response varchar2(1024);
  
    v_status_flg     Varchar2(32);
    v_invo_no        Varchar2(32);
    v_invo_date      date;
    v_tax_bk_no      Varchar2(32);
    v_tax_bk_pk_no   Number(16);
    v_f_year         Number(4);
    v_f_period       Number(2);
    v_tax_flg        varchar2(32);
    v_tax_code       Varchar2(32);
    v_tax_rate       Number(7, 3);
    v_item_date      Date;
    v_acc_code       Varchar2(32) := 'NULL';
    v_acc_name       Varchar2(1024) := '空客戶代號';
    v_src_amount     Number(16);
    v_tax_amount     Number(16);
    v_book_no        varchar2(32);
    v_mas_date       Date;
    v_tax_code1      varchar2(32);
    v_tax_status_flg varchar2(32);
    v_title          varchar2(256);
    v_uid            varchar2(256);
    v_inv_no         varchar2(256);
    v_src_date       date;
    v_year           number(4);
    v_period         number(2);
    v_f_invo_date    date;
    v_invo_date2     date;
    v_book_pk_no     number(16);
    v_tax_acc_code   varchar2(32);
    v_pk_no          number(16);
    v_tax_mas_no     varchar2(32);
    v_mas_pk_no      number(16);
    v_package_key    number(16);
    v_identify_id    varchar2(32) := '4683';
    v_src_pk_no      number(16);
    v_session_uid    varchar2(64);
    v_msg            varchar2(1024);
    v_src_card_no    varchar2(16);
    v_order_no       varchar2(32);
    v_owner_phone_no varchar2(32);
    v_buy_limit      number(16);
    v_limit_qty      number(16);
    v_order_ja       json_list;
  
  begin
    insert into temp_order_log(t_order) values (p_order);
    commit;
    
    begin
    v_order_ja := json_ext.get_json_list(json(p_order),'data');
    exception
      when others then
        v_order_ja := Json_List();
        v_order_ja.add_elem(json(p_order).TO_JSON_VALUE);
        
    end;
    
    
    if v_order_ja is null then
        v_order_ja :=  Json_List();
         v_order_ja.add_elem(json(p_order).TO_JSON_VALUE);
    end if; 
    
    for i IN 1..v_order_ja.count loop
      begin
    v_order := replace(p_order,'{"data":[','');
    v_order := replace(v_order,'}]}','}');
    select seq_inv_no.nextval into r_order.pk_no from dual;
    r_order.mas_no   := Sysapp_Util.Get_Mas_No(1,
                                               2,
                                               Sysdate,
                                               'BSMPUR',
                                               r_order.pk_no);
    v_inv_no := r_order.mas_no;
    r_order.mas_date := sysdate;
  
    r_order.status_flg := 'A';
  
    jsonobj       := json(v_order_ja.get_elem(i));
    v_session_uid := BSM_ORDER_SERVICE.get_string(jsonobj, 'sessionUid');
  
    r_order.cust_name     := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'orderName');
    r_order.cust_phone_no := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'orderPhoneNumber');
    r_order.cust_addr     := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'orderAddress');
    r_order.cust_email    := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'orderEmail');
    r_order.cust_zip      := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'orderPostal');
  
    r_order.ship_name     := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'receiverName');
    r_order.ship_phone_no := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'receiverPhoneNumber');
    r_order.ship_addr     := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'receiverAddress');
    r_order.ship_email    := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'receiverEmail');
    r_order.ship_zip      := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                          'receiverPostal');
  
    r_order.promotion_code := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                           'promotionCode');
  
    r_order.order_content := p_order;
    
    begin 
      r_order.pay_type :=  BSM_ORDER_SERVICE.get_string(jsonobj,
                                                         'payType');
      r_order.pay_type := NVL(r_order.pay_type,'CREDIT');
    exception
       when others then null;
     end;
   
  
    r_order.card_type    := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                         'cardType');
    r_order.card_no      := substr(BSM_ORDER_SERVICE.get_string(jsonobj,
                                                                'cardNo'),
                                   1,
                                   4) || '-****-****-' ||
                            substr(BSM_ORDER_SERVICE.get_string(jsonobj,
                                                                'cardNo'),
                                   13,
                                   4);
    v_src_card_no        := BSM_ORDER_SERVICE.get_string(jsonobj, 'cardNo');
    r_order.card_expiry  := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                         'cardExpiry');
    r_order.card_cvc2    := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                         'cardCVC2');
    r_order.client_id    := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                         'client_id');
    r_order.tax_gift_flg := BSM_ORDER_SERVICE.get_string(jsonobj,
                                                         'invoiceGiftFlg');
    r_order.remark       := BSM_ORDER_SERVICE.get_string(jsonobj, 'remarks');
    r_order.qty          := BSM_ORDER_SERVICE.get_string(jsonobj, 'qty');
  
    if r_order.promotion_code = 'TV0001' then
      raise stop_product;
    end if;
  
    begin
      select owner_phone
        into r_order.owner_phone
        from bsm_client_mas a
       where a.serial_id = r_order.client_id;
    exception
      when no_data_found then
        null;
    end;
  
    --
    -- 計算總價
    --
  
    Select nvl(r_order.qty, 1) * a.amount,
           nvl(r_order.qty, 1) * a.tax_amt,
           nvl(r_order.qty, 1) * a.net_amt,
           MAX_LIMIT,
           MAX_QTY
      into r_order.price,
           r_order.tax_amt,
           r_order.net_amt,
           v_buy_limit,
           v_limit_qty
      from stk_package_mas a
     where a.package_id = r_order.promotion_code
       and rownum <= 1;
  
    --
    -- 檢查重複資訊
    --
  
    declare
      v_order_cnt number(16);
    begin
    
      select count(*)
        into v_order_cnt
        from bsm_order_mas x
       where src_no = v_session_uid
         and status_flg in ('A', 'P');
      if v_order_cnt >= v_buy_limit then
      
        raise over_buy;
      end if;
    
    exception
      when no_data_found then
        null;
    end;
  
    declare
      v_dup varchar2(8);
      v_cnt number(16);
    begin
      select count(*)
        into v_cnt
        from bsm_order_mas x
       where client_id = r_order.client_id
         and r_order.promotion_code in ('PRO13')
         and x.promotion_code = 'PRO13'
         and status_flg in ('P');
      if v_cnt >= 2 then
        raise dup_buy;
      end if;
    exception
      when no_data_found then
        null;
    end;
  
    --
    -- 
    --   
  
    --
    -- 取的promotion 明細
    --
  
    if r_order.promotion_code = 'PRO1' then
      r_order.price   := 1490;
      r_order.net_amt := 1419;
      r_order.tax_amt := 71;
      raise product_error;
    end if;
  
    if r_order.promotion_code = 'PRO2' then
      r_order.price   := 990;
      r_order.net_amt := 940;
      r_order.tax_amt := 50;
      raise product_error;
    end if;
  
    if r_order.promotion_code = 'PRO3' then
      r_order.price   := 1490;
      r_order.net_amt := 1419;
      r_order.tax_amt := 71;
      raise product_error;
    end if;
  
    if r_order.promotion_code = 'PRO4' then
      r_order.price   := 2390;
      r_order.net_amt := 2276;
      r_order.tax_amt := 114;
      raise product_error;
    end if;
  
   /* if r_order.promotion_code = 'PRO5' then
      r_order.price   := 2980;
      r_order.net_amt := 2838;
      r_order.tax_amt := 142;
    end if; */
  
    if r_order.promotion_code = 'PRO6' then
      r_order.price   := 1490;
      r_order.net_amt := 1419;
      r_order.tax_amt := 71;
      --   raise product_error;
    end if;
  
    if r_order.promotion_code = 'PRO7' then
      r_order.price   := 1490;
      r_order.net_amt := 1419;
      r_order.tax_amt := 71;
      --   raise product_error;
    end if;
  
    if r_order.promotion_code = 'PRO8' then
      r_order.price   := 990;
      r_order.net_amt := 940;
      r_order.tax_amt := 50;
      --   raise product_error;
    end if;
  
    begin
      select owner_phone
        into v_owner_phone_no
        from bsm_client_mas a
       where a.serial_id = r_order.client_id
         and rownum <= 1;
    exception
      when no_data_found then
        null;
    end;
  
    insert into bsm_order_mas
      (client_id,
       pk_no,
       src_code,
       src_no,
       mas_date,
       mas_code,
       mas_no,
       status_flg,
       org_no,
       loc_no,
       cust_name,
       cust_phone_no,
       cust_addr,
       cust_email,
       cust_zip,
       ship_name,
       ship_phone_no,
       ship_addr,
       ship_email,
       ship_zip,
       order_content,
       promotion_code,
       price,
       net_amt,
       tax_amt,
       card_type,
       card_no,
       card_expiry,
       card_cvc2,
       tax_gift_flg,
       owner_phone,
       remark,
       qty)
    values
      (r_order.client_id,
       r_order.pk_no,
       'BSMPUR',
       v_session_uid,
       sysdate,
       r_order.mas_code,
       r_order.mas_no,
       r_order.status_flg,
       r_order.org_no,
       r_order.loc_no,
       r_order.cust_name,
       r_order.cust_phone_no,
       r_order.cust_addr,
       r_order.cust_email,
       r_order.cust_zip,
       r_order.ship_name,
       r_order.ship_phone_no,
       r_order.ship_addr,
       r_order.ship_email,
       r_order.ship_zip,
       r_order.order_content,
       r_order.promotion_code,
       r_order.price,
       r_order.net_amt,
       r_order.tax_amt,
       r_order.card_type,
       r_order.card_no,
       r_order.card_expiry,
       r_order.card_cvc2,
       r_order.tax_gift_flg,
       r_order.owner_phone,
       r_order.remark,
       nvl(r_order.qty, 1));
  
    commit;
  
    --
    -- 刷卡處理
    --
    if r_order.pay_type = 'CREDIT' then
    v_create_response := bsm_payment_gateway.AccePayment(r_order.pk_no,
                                                         r_order.price,
                                                         r_order.card_type,
                                                         v_src_card_no,
                                                         r_order.card_expiry,
                                                         r_order.card_cvc2);
    update bsm_order_mas a
       set a.response = v_create_response
     where pk_no = r_order.pk_no;
    commit;
    else
      v_create_response := 'PRC=0&APPRVO_CODE=XXXX';
    end if;
    
    if instr(v_create_response, 'PRC=0') > 0 
      and v_create_response <>'PRC=0' 
       then
      update bsm_order_mas a
         set a.status_flg = 'P'
       where pk_no = r_order.pk_no;
      commit;
    
      begin
      
        if v_tax_code is null then
          v_tax_code := 'OUTTAX1';
        end if;
      
        v_tax_flg := 'Y';
      
        v_tax_rate := 0.05;
      
        v_src_pk_no := r_order.pk_no;
        v_mas_pk_no := null;
      
        v_year        := to_number(to_char(sysdate, 'YYYY'));
        v_period      := to_number(to_char(sysdate, 'MM'));
        v_f_invo_date := sysdate;
      
        select mas_no, pk_no
          into v_tax_bk_no, v_book_pk_no
          from tax_bk_mas a
         where a.start_date <= sysdate
           and trunc(end_date) + 1 > sysdate
           and no_end - nvl(a.curr_no, 0) > 0
           and status_flg = 'P'
           and a.org_no = 1
           and rownum <= 1
         order by mas_no;
      
        select max(a.f_invo_date)
          into v_invo_date2
          from tax_inv_mas a
         where status_flg in ('P', 'N')
           and a.tax_book_no = v_tax_bk_no;
      
        v_tax_acc_code := sysapp_util.get_sys_value('TGCTAXINV',
                                                    'TAX_ACC_CODE',
                                                    '2132');
      
        select seq_sys_no.nextval into v_mas_pk_no from dual;
        v_tax_mas_no := sysapp_util.Get_Mas_No(1,
                                               1,
                                               sysdate,
                                               'TAXINV',
                                               v_pk_no);
      
        insert into tax_inv_mas
          (org_no,
           pk_no,
           mas_code,
           mas_no,
           mas_date,
           create_user,
           create_date,
           status_flg,
           src_code,
           src_pk_no,
           src_no,
           src_date,
           description,
           f_year,
           f_period,
           f_invo_date,
           f_invo_no,
           tax_code,
           tax_rate,
           tax_book_no,
           tax_book_pk_no,
           acc_code,
           acc_name,
           src_amount,
           tax_amount,
           total_amount,
           tax_acc_code,
           remark,
           invo_type,
           company_uid,
           chk_pk_no,
           identify_id,
           donatemark
           
           )
        values
          (1,
           v_mas_pk_no,
           'TAXINV',
           v_tax_mas_no,
           sysdate,
           0,
           sysdate,
           'A',
           'SRVINV',
           v_src_pk_no,
           v_inv_no,
           v_src_date,
           null,
           v_year,
           v_period,
           v_f_invo_date,
           null,
           v_tax_code,
           v_tax_rate,
           v_tax_bk_no,
           v_book_pk_no,
           v_acc_code,
           v_title,
           r_order.net_amt,
           r_order.tax_amt,
           r_order.price,
           v_tax_acc_code,
           null,
           null,
           v_uid,
           0,
           v_identify_id,
           r_order.tax_gift_flg);
      
        select seq_sys_no.nextval into v_pk_no from dual;
        insert into tax_inv_item
          (mas_pk_no,
           pk_no,
           item_name,
           tax_flg,
           amount,
           remark,
           qty,
           dr_acc_code,
           cr_acc_code,
           tax_acc_code,
           inv_pk_no,
           detail_pk_no,
           chg_code,
           pm_code,
           package_key,
           item_pk_no,
           tax_amt,
           src_amount)
        values
          (v_mas_pk_no,
           v_pk_no,
           '售價',
           'Y',
           r_order.net_amt,
           null,
           nvl(r_order.qty, 1),
           '',
           '',
           v_tax_acc_code,
           0,
           0,
           '售價',
           'PRICE',
           0,
           r_order.pk_no,
           r_order.tax_amt,
           r_order.price);
        commit;
        v_msg := tax_post.tax_inv_post(0, v_mas_pk_no);
        select a.f_invo_no, a.f_invo_date
          into r_order.tax_inv_no, r_order.tax_date
          from tax_inv_mas a
         where a.pk_no = v_mas_pk_no;
        update bsm_order_mas c
           set c.tax_inv_no = r_order.tax_inv_no,
               c.tax_date   = r_order.tax_date
         where c.pk_no = v_src_pk_no;
     /* exception
        when others then
          null; */
      end;
      commit;
      if r_order.pay_type = 'CREDIT' then 
      declare
        v_sms_str    varchar2(1024) := 'LiTV線上影視已收到您的訂單#PURCHASE_NO#,金額#AMOUNT#，欲查詢購買明細請撥打電話詢問客服02-7707-0708';
        v_sms_result varchar2(1024);
      begin
        If v_owner_phone_no Is Not Null Then
          v_Sms_Str    := Replace(v_Sms_Str,
                                  '#PURCHASE_NO#',
                                  replace(r_order.mas_no, 'PUR', ''));
          v_Sms_Str    := Replace(v_Sms_Str,
                                  '#AMOUNT#',
                                  To_Char(r_order.price));
          v_Sms_Result := bsm_client_service.Send_Sms_Message(r_order.cust_phone_no,
                                                              v_Sms_Str,
                                                              null);
        End If;
      end;
      end if;
    
    else
      update bsm_order_mas a
         set a.status_flg = 'F'
       where pk_no = r_order.pk_no;
      commit;
      raise credit_exception;
    end if;
  
    declare
      v_enqueue_options    dbms_aq.enqueue_options_t;
      v_message_properties dbms_aq.message_properties_t;
      v_message_handle     raw(16);
      v_payload            purchase_msg_type;
    begin
      v_payload := purchase_msg_type(r_order.client_id, 0, 0, 'refresh_bsm');
      dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                      enqueue_options    => v_enqueue_options,
                      message_properties => v_message_properties,
                      payload            => v_payload,
                      msgid              => v_message_handle);
      commit;
    end;
  
    commit;
    return '{"result_code":"BSM-00000","result_message":"Success","order_no":"' || r_order.mas_no || '"}';
    exception
        when over_buy then
      rollback;
      when dup_buy then
      rollback;
       when dup_purchase_exception then
      rollback;
    end;
    end loop;
    return '{"result_code":"BSM-00000","result_message":"Success","order_no":"' || r_order.mas_no || '"}';
  exception
    when over_buy then
      rollback;
      return '{"result_code":"BSM-00406","result_message":"超過購買次數上限"}';
    when dup_buy then
      rollback;
      return '{"result_code":"BSM-00405","result_message":"訂單不能重複"}';
    when dup_purchase_exception then
      rollback;
      return '{"result_code":"BSM-00404","result_message":"資料重複傳送","order_no":"' || v_order_no || '"}';
    when credit_exception then
      update bsm_order_mas a
         set a.status_flg = 'F'
       where pk_no = r_order.pk_no;
      rollback;
      return '{"result_code":"BSM-00403","result_message":"刷卡錯誤"}';
    when others then
      v_create_response := SQLERRM;
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (r_order.pk_no, sysdate, 'BSMORD', v_create_response);
      commit;
      update bsm_order_mas a
         set a.status_flg = 'F'
       where pk_no = r_order.pk_no;
      commit;
    
      return '{"result_code":"BSM-00418","result_message":"' || v_create_response || '"}';
    
  end;

  function get_string(jsonObject json, path varchar2) return varchar2 is
    p_result varchar2(1024);
  begin
    p_result := json_ext.get_string(jsonObject, path);
    return p_result;
  exception
    when others then
      return null;
  end;

end BSM_ORDER_SERVICE_DEV;
/

