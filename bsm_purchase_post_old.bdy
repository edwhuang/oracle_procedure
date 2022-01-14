CREATE OR REPLACE PACKAGE BODY IPTV.BSM_PURCHASE_POST_OLD is
  Sms_Purchase Varchar2(1024) := 'LiTV%BA%F4%B8%F4%B9q%B5%F8%AAA%B0%C8%A4w%A6%AC%A8%EC%B1z%AA%BA%ADq%B3%E6%A1G#PURCHASE%5FNO#+%A1A%AA%F7%C3B%24#AMOUNT#%A1A%A9%FA%B2%D3%BD%D0%A6%DC%BA%F4%AF%B8%B7%7C%AD%FB%B1M%B0%CF%ACd%B8%DF';

  Function PURCHASE_POST(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg      Varchar2(32);
    v_mas_code        Varchar2(32);
    v_mas_no          Varchar2(32);
    v_mas_date        Date;
    v_src_no          varchar2(32);
    v_f_year          Number(16);
    v_f_period        Number(4);
    v_acc_status_flg  Varchar2(1);
    v_tax_code        varchar2(32);
    v_tax_flg         varchar2(32);
    v_acc_invo_no     varchar2(32);
    v_purchase_amount number(16);
    v_vis_acc         varchar2(32);
    v_due_date        date;
    v_bar_due_date    varchar2(32);
    v_bar_code        varchar2(32);
    v_bar_no          varchar2(32);
    v_mac_address     varchar2(64);
    v_owner_phone_no  varchar2(32);
    v_pay_type        varchar2(32);
    v_card_type       varchar2(32);
    v_card_number     varchar2(32);
    v_card_expiry     varchar2(32);
    v_card_cvc2       varchar2(32);
  begin
    begin
      Select mas_code,
             mas_no,
             mas_date,
             status_flg,
             src_no,
             f_year,
             f_period,
             tax_code,
             tax_flg,
             serial_id,
             pay_type,
             a.card_type,
             a.card_no,
             a.cvc2,
             card_expiry,
             inv_no
      
        Into v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_src_no,
             v_f_year,
             v_f_period,
             v_tax_code,
             v_tax_flg,
             v_mac_address,
             v_pay_type,
             v_card_type,
             v_card_number,
             v_card_cvc2,
             v_card_expiry,
             v_acc_invo_no
      
        From bsm_purchase_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到帳單單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg <> 'A' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    Select Sum(Amount)
      Into v_Purchase_Amount
      From Bsm_Purchase_Item
     Where Mas_Pk_No = p_pk_no;
  
    v_due_date := sysdate + 3;
  
    v_vis_acc      := get_vis_acc(v_acc_invo_no,
                                  v_due_date,
                                  v_Purchase_Amount);
    v_bar_due_date := '*' ||
                      substr(to_char(to_number(to_char(v_due_date, 'YYYY')) - 1911),
                             length(to_char(to_number(to_char(v_due_date,
                                                              'YYYY')) - 1911)) - 1,
                             2) || to_char(v_due_date, 'MMDD') || '627*';
  
    v_bar_no := '*' || v_acc_invo_no || '*';
  
    v_bar_code := '*' ||
                  barcode_4(substr(to_char(to_number(to_char(v_due_date,
                                                             'YYYY')) - 1911),
                                   length(to_char(to_number(to_char(v_due_date,
                                                                    'YYYY')) - 1911)) - 1,
                                   2) || to_char(v_due_date, 'MMDD') ||
                            '627',
                            v_acc_invo_no,
                            substr(to_char((v_f_year - 1911) * 100 +
                                           v_f_period),
                                   length(to_char((v_f_year - 1911) * 100 +
                                                  v_f_period)) - 3,
                                   4) || '**' ||
                            lpad(to_char(v_Purchase_Amount), 9, '0')) || '*';
  
    update bsm_purchase_mas a
       set a.amount       = v_Purchase_Amount,
           a.inv_acc      = v_vis_acc,
           a.bar_due_date = v_bar_due_date,
           a.bar_no       = v_bar_no,
           a.bar_code     = v_bar_code,
           a.due_date     = v_due_date
     Where Pk_No = p_Pk_No;
  
    --
    -- Update status
    --
  
    Update Bsm_Purchase_Mas b
       Set b.status_flg = 'P'
     Where b.pk_no = p_pk_no;
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      (v_mas_code,
       p_Pk_No,
       Sysdate,
       p_User_No,
       'Post',
       Sys_Event_Seq.Nextval,
       'Post');
  
    Commit;
    return null;
  
    -- Pay Credit
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;
  Function PURCHASE_COMPLETE(p_User_No Number, p_Pk_No Number)
    Return Varchar2 is
  begin
    return PURCHASE_COMPLETE_R(p_User_No, p_Pk_No, 'R');
  end;

  Function PURCHASE_COMPLETE_R(p_User_No      Number,
                               p_Pk_No        Number,
                               refresh_client varchar) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg      Varchar2(32);
    v_mas_code        Varchar2(32);
    v_mas_no          Varchar2(32);
    v_mas_date        Date;
    v_src_no          varchar2(32);
    v_f_year          Number(16);
    v_f_period        Number(4);
    v_tax_code        varchar2(32);
    v_tax_flg         varchar2(32);
    v_mac_address     varchar2(32);
    v_pay_type        varchar2(64);
    v_Purchase_Amount number(16);
    v_owner_phone_no  varchar2(32);
    v_client_id       varchar2(32);
    v_param           VARCHAR2(500) := '{
    "id":"1234",
    "jsonrpc": "2.0",
    "method": "refresh_client", 
    "params": {
        "client_id": "_CLIENT_ID_" 
    }
}';
    v_param_length    NUMBER := length(v_param);
    rw_result         clob;
    req               utl_http.req;
    resp              utl_http.resp;
    rw                varchar2(32767);
  begin
    begin
      Select mas_code,
             mas_no,
             mas_date,
             status_flg,
             src_no,
             f_year,
             f_period,
             tax_code,
             tax_flg,
             serial_id,
             pay_type,
             amount,
             serial_id
      
        Into v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_src_no,
             v_f_year,
             v_f_period,
             v_tax_code,
             v_tax_flg,
             v_mac_address,
             v_pay_type,
             v_Purchase_Amount,
             v_client_id
      
        From bsm_purchase_mas
       Where pk_no = p_pk_no;
    exception
      when no_data_found then
        exception_msg := '#找不到帳單單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    begin
      select a.owner_phone
        into v_owner_phone_no
        from bsm_client_mas a
       where mac_address = v_mac_address;
    exception
      when no_data_found then
        exception_msg := '#客戶的MAC錯誤#';
        raise app_exception;
    end;
  
    If v_status_flg <> 'P' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    --
    --  產生 service details
    -- 
    process_purchase_detail(client_id      => v_mac_address,
                            purchase_pk_no => p_Pk_No);
  
    --
    --
    -- 延展處理 Options
    --
    if v_pay_type in ('匯款', 'ATM', '其他', 'REMIT', '中華電信ATM') then
      declare
        cursor c1 is
          Select nvl(a.extend_days, 0) extend_days,
                 nvl(a.extend_months, 0) extend_months,
                 a.package_id
            from bsm_package_options a, bsm_purchase_item c
           where a.package_type = 'EXTEND'
             and a.stk_package_id = c.package_id
             and a.status_flg = 'P'
             and c.mas_pk_no = p_Pk_No;
      begin
        for i in c1 loop
          update bsm_client_details d
             set d.end_date = add_months(d.end_date, i.extend_months) +
                              i.extend_days
           where d.src_pk_no = p_Pk_No
             and package_id = i.package_id;
        end loop;
        commit;
      end;
    end if;
  
    --
    --  購買 Coupon 處理
    --
  
    declare
      v_end_date   date;
      v_start_date date;
    
      cursor c1 is
        Select nvl(d.coupon_batch_no, a.coupon_batch_no) coupon_batch_no,
               nvl(a.coupon_cnt, 0) coupon_cnt,
               c.package_id,
               a.auto_register,
               c.rowid item_rid
          from stk_package_mas a,
               bsm_purchase_item c,
               (select e.coupon_batch_no, e.package_id
                  from bsm_package_options e, bsm_purchase_item f
                 where f.mas_pk_no = p_Pk_No
                   and f.package_id = e.stk_package_id
                   and e.package_type = 'EXTEND') d
         where a.package_type = 'COUPON'
           and d.package_id(+) = a.package_id
           and a.package_id = c.package_id
           and a.status_flg = 'P'
           and c.mas_pk_no = p_Pk_No;
    
      v_package_dtls varchar2(1024);
    begin
    
      select max(end_date), min(start_date)
        into v_end_date, v_start_date
        from bsm_client_details d
       where d.src_pk_no = p_pk_no;
      for i in c1 loop
      
        v_package_dtls := '';
      
        for j in 1 .. i.coupon_cnt loop
          declare
            v_coupon_id varchar2(32);
            v_rid       rowid;
          
            v_coupon_no varchar2(32);
          begin
            select coupon_id, rowid, mas_no
              into v_coupon_id, v_rid, v_coupon_no
              from bsm_coupon_mas a
             where a.src_no = i.coupon_batch_no
               and a.ref_purchase_no is null
               and a.serial_id is null
               and a.status_flg = 'P'
               and rownum <= 1;
          
            if i.auto_register = 'Y' and j = 1 then
              declare
                v_msg varchar2(1024);
              begin
                v_msg := bsm_purchase_post.CLIENT_REGIETER_COUPON(v_client_id,
                                                                  v_coupon_id,
                                                                  'N'); -- no refresh client
                select max(c.end_date), min(c.start_date)
                  into v_end_date, v_start_date
                  from bsm_client_details c, bsm_purchase_mas d
                 where c.src_pk_no = d.pk_no
                   and d.src_no = v_coupon_no;
              
                v_package_dtls := '{"desc":"主帳號 :已開通"}';
              end;
            else
              if v_package_dtls is not null then
                v_package_dtls := v_package_dtls || ',';
              end if;
              v_package_dtls := v_package_dtls || '{"desc":"副帳號 :兌換券 ' ||
                                v_coupon_id || '"}';
            end if;
          
            update bsm_coupon_mas a
               set a.ref_purchase_no    = v_mas_no,
                   a.ref_client_id      = v_client_id,
                   a.start_service_date = v_start_date,
                   a.ref_purchase_pk_no = p_pk_no,
                   a.stop_service_date  = v_end_date
             where rowid = v_rid;
            commit;
          exception
            when no_data_found then
              null;
          end;
        end loop;
      
        update bsm_purchase_item
           set package_dtls       = '[' || v_package_dtls || ']',
               service_start_date = v_start_date,
               service_end_date   = v_end_date
         where rowid = i.item_rid;
        commit;
      
        commit;
      end loop;
      commit;
    end;
  
    BSM_client_service.Set_subscription(p_Pk_No, v_mac_address);
    if v_pay_type in ('匯款', 'ATM', '其他', 'REMIT') then
      update bsm_purchase_mas
         set purchase_date = sysdate, status_flg = 'Z'
       where pk_no = p_pk_no;
    else
      update bsm_purchase_mas
         set purchase_date = nvl(purchase_date, sysdate), status_flg = 'Z'
       where pk_no = p_pk_no;
    end if;
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      (v_mas_code,
       p_Pk_No,
       Sysdate,
       p_User_No,
       'Complete',
       Sys_Event_Seq.Nextval,
       'Complete');
    Commit;
  
    if v_pay_type in ('匯款', 'ATM', '其他', 'REMIT', '中華電信ATM') then
      declare
        v_sms_str         varchar2(1024) := 'LiTV已收到您的繳費金額$#AMOUNT#(訂單#PURCHASE_NO#)，可立即使用購買的服務，到期日請至電視或官網會員專區查詢，感謝您的訂購';
        v_Sms_Purchase_4G Varchar2(1024) := '四季影視4gTV已收到您的訂單#PURCHASE_NO#,金額#AMOUNT#,明細請至網路會員專區查詢';
        v_sms_result      varchar2(1024);
      begin
        If v_owner_phone_no Is Not Null Then
        
          v_Sms_Result := BSM_SMS_Service.Send_Sms_Messeage_litv(v_owner_phone_no,
                                                                 null,
                                                                 v_mac_address,
                                                                 'purchase',
                                                                 v_mas_no,
                                                                 v_Purchase_Amount);
        End If;
      end;
    end if;
  
    if refresh_client = 'R' then
      declare
        v_enqueue_options    dbms_aq.enqueue_options_t;
        v_message_properties dbms_aq.message_properties_t;
        v_message_handle     raw(16);
        v_payload            purchase_msg_type;
      begin
        v_payload := purchase_msg_type(v_mac_address, 0, '', 'refresh_bsm');
        dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                        enqueue_options    => v_enqueue_options,
                        message_properties => v_message_properties,
                        payload            => v_payload,
                        msgid              => v_message_handle);
        commit;
      end;
    end if;
  
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;
  Function PURCHASE_UNPOST(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg      Varchar2(32);
    v_mas_code        Varchar2(32);
    v_mas_no          Varchar2(32);
    v_mas_date        Date;
    v_src_no          varchar2(32);
    v_f_year          Number(16);
    v_f_period        Number(4);
    v_acc_status_flg  Varchar2(1);
    v_tax_code        varchar2(32);
    v_tax_flg         varchar2(32);
    v_acc_invo_no     varchar2(32);
    v_purchase_amount number(16);
    v_vis_acc         varchar2(32);
    v_due_date        date;
    v_bar_due_date    varchar2(32);
    v_bar_code        varchar2(32);
    v_bar_no          varchar2(32);
    v_mac_address     varchar2(64);
    v_owner_phone_no  varchar2(32);
    v_pay_type        varchar2(32);
    v_card_type       varchar2(32);
    v_card_number     varchar2(32);
    v_card_expiry     varchar2(32);
    v_card_cvc2       varchar2(32);
  begin
    begin
      Select mas_code,
             mas_no,
             mas_date,
             status_flg,
             src_no,
             f_year,
             f_period,
             tax_code,
             tax_flg,
             serial_id,
             pay_type,
             a.card_type,
             a.card_no,
             a.cvc2,
             card_expiry,
             inv_no
      
        Into v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_src_no,
             v_f_year,
             v_f_period,
             v_tax_code,
             v_tax_flg,
             v_mac_address,
             v_pay_type,
             v_card_type,
             v_card_number,
             v_card_cvc2,
             v_card_expiry,
             v_acc_invo_no
      
        From bsm_purchase_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到帳單單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('C', 'P', 'Z') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
  
    Update Bsm_Purchase_Mas b
       Set b.status_flg = 'A'
     Where b.pk_no = p_pk_no;
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      (v_mas_code,
       p_Pk_No,
       Sysdate,
       p_User_No,
       'UnPost',
       Sys_Event_Seq.Nextval,
       'Post');
  
    Commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function PURCHASE_CANCEL(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg     Varchar2(32);
    v_mas_code       Varchar2(32);
    v_mas_no         Varchar2(32);
    v_mas_date       Date;
    v_src_no         varchar2(32);
    v_f_year         Number(16);
    v_f_period       Number(4);
    v_acc_status_flg Varchar2(1);
    v_tax_code       varchar2(32);
    v_tax_flg        varchar2(32);
    v_acc_invo_no    varchar2(32);
    v_mac_address    varchar2(64);
    v_pay_type       varchar2(32);
    v_card_type      varchar2(32);
    v_card_number    varchar2(32);
    v_card_expiry    varchar2(32);
    v_card_cvc2      varchar2(32);
  begin
    begin
      Select mas_code,
             mas_no,
             mas_date,
             status_flg,
             src_no,
             f_year,
             f_period,
             tax_code,
             tax_flg,
             serial_id,
             pay_type,
             a.card_type,
             a.card_no,
             a.cvc2,
             card_expiry,
             inv_no
      
        Into v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_src_no,
             v_f_year,
             v_f_period,
             v_tax_code,
             v_tax_flg,
             v_mac_address,
             v_pay_type,
             v_card_type,
             v_card_number,
             v_card_cvc2,
             v_card_expiry,
             v_acc_invo_no
      
        From bsm_purchase_mas a
       Where pk_no = p_pk_no
         for update nowait;
    
    exception
      when no_data_found then
        exception_msg := '#找不到帳單單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('P', 'Z') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    Begin
      Select status_flg
        Into v_acc_status_flg
        From acc_period_mas a
       Where a.f_year = v_f_year
         And f_period = v_f_period;
      If v_acc_status_flg not in ('O', 'S') Then
        exception_msg := '#帳期未開啟#';
        Raise app_exception;
      End If;
    Exception
      When no_data_found Then
        exception_msg := '#沒有帳期設定#';
        Raise app_exception;
    End;
  
    update bsm_purchase_mas a set status_flg = 'C' Where pk_no = p_pk_no;
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      (v_mas_code,
       p_Pk_No,
       Sysdate,
       p_User_No,
       
       'Cacel',
       Sys_Event_Seq.Nextval,
       'Cancel');
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function CLIENT_GENERATE_COUPON_NO(COUPON_DATE date,
                                     coupon_type varchar2) return varchar2 is
    v_random_no    varchar2(32);
    v_result       varchar2(32);
    v_checksum     varchar2(1);
    v_chinese_year varchar2(3);
  begin
    Select Lpad(Ceil(Dbms_Random.Value * 100000000), 8, '0')
      Into v_random_no
      From Dual;
  
    declare
      v_sum         number(16);
      v_parameters  t_parameters;
      v_parameters2 t_parameters_c;
      v_mod         number(16);
    
    begin
      v_parameters(0) := 1;
      v_parameters(1) := 5;
      v_parameters(2) := 6;
      v_parameters(3) := 2;
      v_parameters(4) := 8;
      v_parameters(5) := 5;
      v_parameters(6) := 9;
      v_parameters(7) := 7;
    
      v_parameters2(0) := '1';
      v_parameters2(1) := '3';
      v_parameters2(2) := '2';
      v_parameters2(3) := '5';
      v_parameters2(4) := '4';
      v_parameters2(5) := '6';
      v_parameters2(6) := '8';
      v_parameters2(7) := '3';
      v_parameters2(8) := '7';
      v_parameters2(9) := '0';
      v_parameters2(10) := '9';
    
      v_sum := 0;
      for i in 0 .. 7 loop
        v_sum := v_sum +
                 (to_number(substr(v_random_no, i, 1)) * v_parameters(i));
      end loop;
      v_mod      := v_sum mod 11;
      v_checksum := v_parameters2(v_mod);
    end;
  
    v_chinese_year := to_char(to_number(to_char(COUPON_DATE, 'YYYY')) - 1911);
  
    if (coupon_type is null or coupon_type = '16') then
      v_result := substr(v_random_no, 7, 2) || to_char(COUPON_DATE, 'MMDD') ||
                  substr(v_random_no, 5, 2) || v_chinese_year ||
                  substr(v_random_no, 1, 4) || v_checksum;
    elsif (coupon_type = 12) then
      v_result := '0000' || substr(v_random_no, 7, 2) ||
                  substr(to_char(COUPON_DATE, 'MMDD'), 2, 3) ||
                  substr(v_random_no, 5, 2) || substr(v_random_no, 1, 4) ||
                  v_checksum;
    end if;
  
    Return v_Result;
    null;
  end;

  Function CLIENT_REGIETER_COUPON(client_id   varchar2,
                                  coupon_no   varchar2,
                                  p_device_id varchar2 default null)
    return varchar2 is
  begin
    return CLIENT_REGIETER_COUPOR(client_id, coupon_no, 'R', p_device_id);
  end;

  Function CLIENT_REGIETER_COUPOR(client_id      varchar2,
                                  coupon_no      varchar2,
                                  refresh_client varchar,
                                  p_device_id    varchar2 default null)
    return varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
  
    v_program_id    varchar2(32);
    v_pk_no         number(16);
    v_client_id     varchar2(32);
    v_src_no        varchar2(32);
    v_owner_phone   varchar2(32);
    v_model_no      varchar2(1024);
    v_ref_device_id varchar2(32);
    v_message_title varchar2(128);
    v_message_desc  varchar2(1024);
  begin
    v_client_id := upper(client_id);
    -- check client id
    declare
      v_status_flg varchar2(32);
    begin
      select status_flg, a.owner_phone
        into v_status_flg, v_owner_phone
        from bsm_client_mas a
       where a.mac_address = v_client_id;
      /* if v_status_flg not in ('A', 'W') then
        raise client_status_error;
      end if; */
      if p_device_id is not null then
        begin
          select ref1
            into v_model_no
            from bsm_client_device_list a
           where a.client_id = v_client_id
             and device_id = p_device_id
             and rownum <= 1;
        exception
          when no_data_found then
            null;
        end;
      end if;
    
    exception
      when no_data_found then
        raise client_not_found;
    end;
  
    declare
      v_char          varchar2(32);
      v_cup_serial_id varchar2(32);
      v_expire_date   date;
    
    begin
    
      Select program_id,
             pk_no,
             a.expire_date,
             a.src_no,
             a.serial_id,
             a.ref_device_id
        into v_program_id,
             v_pk_no,
             v_expire_date,
             v_src_no,
             v_cup_serial_id,
             v_ref_device_id
        from bsm_coupon_mas a
       where a.coupon_id = coupon_no
         and a.status_flg in ('P', 'Z')
         for update;
      if v_cup_serial_id is not null then
        raise Coupon_registed;
      end if;
      if v_expire_date is not null then
        if to_char(sysdate, 'YYYYMMDD') >
           to_char(v_expire_date, 'YYYYMMDD') then
          raise coupon_expired;
        end if;
      end if;
    
    exception
      when no_data_found then
        raise coupon_not_found;
    end;
  
    declare
      v_client_prog_limit number(16);
      v_cnt               number;
      v_demo_flg          varchar2(32);
      v_client_limit      number(16);
    begin
      select nvl(client_program_limit, 0),
             demo_flg,
             message_title,
             message_desc,
             nvl(client_prog_limit, 0)
        into v_client_prog_limit,
             v_demo_flg,
             v_message_title,
             v_message_desc,
             v_client_limit
        from bsm_coupon_prog_mas a
       where a.cup_program_id = v_program_id;
    
      if v_demo_flg = 'Y' and substr(v_owner_phone, 1, 7) != '0900001' then
        raise demo_on_not_demo_client;
      end if;
      if v_demo_flg != 'Y' and substr(v_owner_phone, 1, 7) = '0900001' then
        raise coupon_on_demo_client;
      end if;
    
      if v_client_prog_limit > 0 then
        if p_device_id is not null then
          select nvl(count(*), 0)
            into v_cnt
            from bsm_coupon_mas a
           where program_id = v_program_id
             and a.serial_id = v_client_id
                --    and (a.device_id = p_device_id or a.device_id is null)
             and a.src_no = v_src_no
             and a.status_flg = 'Z';
          if v_cnt >= v_client_prog_limit then
            raise coupon_program_registed;
          end if;
        else
          select nvl(count(*), 0)
            into v_cnt
            from bsm_coupon_mas a
           where program_id = v_program_id
             and a.serial_id = v_client_id
             and a.src_no = v_src_no
             and a.status_flg = 'Z';
        end if;
      
      end if;
    
      if v_client_limit > 0 then
        if p_device_id is not null then
          select nvl(count(*), 0)
            into v_cnt
            from bsm_coupon_mas a
           where program_id = v_program_id
             and a.serial_id = v_client_id
                --   and (a.device_id = p_device_id or a.device_id is null)
             and a.status_flg = 'Z';
          if v_cnt >= v_client_limit then
            raise coupon_program_registed;
          end if;
        end if;
      
      end if;
    end;
  
    --
    -- check Software Group
    --
    declare
      v_char char(1);
    begin
      select 'x'
        into v_char
        from bsm_coupon_prog_sg
       where mas_pk_no in
             (select pk_no
                from bsm_coupon_prog_mas b
               where b.cup_program_id = v_program_id)
         and rownum <= 1;
      begin
        select 'x'
          into v_char
          from bsm_coupon_prog_sg
         where mas_pk_no in
               (select pk_no
                  from bsm_coupon_prog_mas
                 where cup_program_id = v_program_id)
           and software_group = get_software_group(client_id, p_device_id)
           and rownum <= 1;
      exception
        when no_data_found then
          raise coupon_group_no_found;
      end;
    exception
      when no_data_found then
        null;
    end;
  
    --
    -- Check Model List
    -- 
    declare
      v_char char(1);
    begin
      select 'x'
        into v_char
        from mfg_model_coupon a
       where a.coupon_program_id = v_program_id
         and rownum <= 1;
      begin
        select 'x'
          into v_char
          from mfg_model_coupon a
         where a.coupon_program_id = v_program_id
           and a.model_no = v_model_no
           and status_flg = 'P'
           and (start_date is null or start_date <= sysdate)
           and (end_date is null or end_date + 1 >= sysdate);
      exception
        when no_data_found then
          raise coupon_model_error;
      end;
    exception
      when no_data_found then
        null;
    end;
  
    update bsm_coupon_mas a
       set a.serial_id     = v_client_id,
           a.register_date = sysdate,
           a.device_id     = nvl(v_ref_device_id, p_device_id)
    
     where a.pk_no = v_pk_no;
  
    -- grenrate details
    declare
      cursor c1 is
        select b.package_id,
               b.item_type,
               b.net_amount,
               b.tax_amount,
               b.amount,
               a.net_amount net_amount_a,
               a.tax_amount tax_amount_a,
               a.amount     amount_a,
               b.exp_days
          from bsm_coupon_prog_mas a, bsm_coupon_prog_item b
         where b.mas_pk_no = a.pk_no
           and a.cup_program_id = v_program_id;
      v_item_pk_no number(16);
    
    begin
      delete bsm_coupon_details b where b.mas_pk_no = v_pk_no;
      for c1rec in c1 loop
        select seq_payment_order_no.nextval into v_item_pk_no from dual;
        insert into bsm_coupon_details
          (pk_no,
           mas_pk_no,
           package_id,
           item_id,
           status_flg,
           tax_amount,
           net_amount,
           amount,
           item_type,
           exp_days)
        values
          (v_item_pk_no,
           v_pk_no,
           c1rec.package_id,
           null,
           'A',
           c1rec.tax_amount,
           c1rec.net_amount,
           c1rec.amount,
           c1rec.item_type,
           c1rec.exp_days);
      
        update bsm_coupon_mas a
           set a.tax_amount = c1rec.tax_amount_a,
               a.net_amount = c1rec.net_amount_a,
               a.amount     = c1rec.amount_a
         where a.pk_no = v_pk_no;
        commit;
      end loop;
    end;
  
    -- update stock broker
  
    commit;
  
    declare
      v_msg varchar2(1024);
    begin
      v_msg := bsm_purchase_post.COUPON_COMPLETE(0, v_pk_no);
    end;
  
    Return 'message:{"subject":"' || v_message_title || '","body":"' || v_message_desc || '"}';
  Exception
    When client_not_found then
      Rollback;
      raise client_not_found;
    
    When client_status_error then
      Rollback;
      raise client_status_error;
    
    When coupon_not_found then
      Rollback;
      raise coupon_not_found;
  end;

  Function COUPON_NO_CHECK(COUPON_NO varchar) return varchar2 is
    v_random_no varchar2(32);
    v_check_no  varchar2(32);
    v_checksum  varchar2(1);
  begin
    v_random_no := substr(COUPON_NO, 12, 4) || substr(COUPON_NO, 7, 2) ||
                   substr(COUPON_NO, 1, 2);
    v_check_no  := substr(COUPON_NO, 16, 1);
    declare
      v_sum         number(16);
      v_parameters  t_parameters;
      v_parameters2 t_parameters_c;
      v_mod         number(16);
    
    begin
      v_parameters(0) := 1;
      v_parameters(1) := 5;
      v_parameters(2) := 6;
      v_parameters(3) := 2;
      v_parameters(4) := 8;
      v_parameters(5) := 5;
      v_parameters(6) := 9;
      v_parameters(7) := 7;
    
      v_parameters2(0) := '1';
      v_parameters2(1) := '3';
      v_parameters2(2) := '2';
      v_parameters2(3) := '5';
      v_parameters2(4) := '4';
      v_parameters2(5) := '6';
      v_parameters2(6) := '8';
      v_parameters2(7) := '3';
      v_parameters2(8) := '7';
      v_parameters2(9) := '0';
      v_parameters2(10) := '9';
    
      v_sum := 0;
      for i in 0 .. 7 loop
        v_sum := v_sum +
                 (to_number(substr(v_random_no, i, 1)) * v_parameters(i));
      end loop;
      v_mod      := v_sum mod 11;
      v_checksum := v_parameters2(v_mod);
    end;
    if v_checksum = v_check_no then
      return 'Y';
    else
      return 'N';
    end if;
  
  end;

  Function COUPON_POST(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_mas_code   Varchar2(32);
    v_mas_no     Varchar2(32);
    v_mas_date   Date;
    v_client_id  varchar(32);
  
  begin
  
    begin
      Select mas_code, mas_no, mas_date, status_flg, serial_id
        Into v_mas_code, v_mas_no, v_mas_date, v_status_flg, v_client_id
        From bsm_coupon_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg <> 'A' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    update bsm_coupon_mas a set status_flg = 'P' where pk_no = p_pk_no;
  
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;
  Function COUPON_COMPLETE(p_User_No Number, p_Pk_No Number) Return Varchar2 is
  begin
    return COUPON_COMPLETE_R(p_User_No, p_Pk_No, 'R');
  end;

  Function COUPON_COMPLETE_R(p_User_No      Number,
                             p_Pk_No        Number,
                             refresh_client varchar) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg          Varchar2(32);
    v_mas_code            Varchar2(32);
    v_mas_no              Varchar2(32);
    v_mas_date            Date;
    v_client_id           varchar(32);
    v_charge_code         varchar2(64);
    v_Purchase_Item_Pk_No number(16);
    v_charge_name         varchar2(32);
    v_Purchase_Pk_No      number(16);
    v_program_id          varchar2(32);
    v_stock_broker        varchar2(32);
    v_vod_group           varchar2(32);
    v_device_id           varchar2(32);
    v_start_type          varchar2(32);
    v_stop_service_date   date;
  begin
  
    begin
      Select mas_code,
             mas_no,
             mas_date,
             status_flg,
             serial_id,
             device_id,
             a.program_id,
             stock_broker,
             a.stop_service_date
        Into v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_client_id,
             v_device_id,
             v_program_id,
             v_stock_broker,
             v_stop_service_date
        From bsm_coupon_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    begin
      Select vod_group, nvl(start_type, 'E')
        into v_vod_group, v_start_type
        from bsm_coupon_prog_mas a
       where a.cup_program_id = v_program_id;
    
    exception
      when no_data_found then
        v_vod_group  := null;
        v_start_type := 'E';
    end;
  
    If v_status_flg <> 'P' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    -- create purchase order
    declare
      v_purchase_no       varchar2(32);
      v_acc_invo_no       varchar2(32);
      v_pay_type          varchar2(32) := '兌換券';
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
    
    begin
      v_Client_Info := bsm_client_service.Get_Client_Info(v_client_id);
      v_Serial_No   := v_client_info.serial_no;
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
         start_type)
      Values
        (v_mas_no,
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
         Sysdate,
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
         v_start_type);
    
      declare
        cursor c1 is
          select package_id,
                 a.amount,
                 a.net_amount,
                 a.tax_amount,
                 a.exp_days
            from Bsm_coupon_details a
           where mas_pk_no = p_Pk_No
             and item_type = 'P';
      
      begin
      
        For i_Items In c1 Loop
          --
          --  計算價格
          --
          v_id := i_Items.package_id;
          Begin
            Select a.Charge_Amount,
                   a.Acl_Duration,
                   a.Acl_Quota,
                   a.charge_type,
                   a.charge_code
              Into v_Price,
                   v_Duration,
                   v_Quota,
                   v_charge_type,
                   v_charge_code
              From Bsm_Package_Mas a
             Where a.Package_id = v_id;
          Exception
            When No_Data_Found Then
              Raise Error_Package_Mas;
          End;
        
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
             device_id,
             exp_days)
          Values
            (v_Purchase_Item_Pk_No,
             v_Purchase_Pk_No,
             i_items.package_id,
             null,
             nvl(i_Items.amount, v_Price),
             nvl(i_Items.amount, v_Price * 1),
             v_Duration,
             v_charge_type,
             v_charge_code,
             v_charge_name,
             i_Items.tax_amount,
             i_Items.net_amount,
             i_Items.amount,
             v_device_id,
             i_Items.exp_days);
        
        End Loop;
      
      end;
    end;
  
    declare
      v_msg number(16);
    begin
      v_msg := bsm_purchase_post.purchase_post(p_user_no, v_purchase_pk_no);
      v_msg := bsm_purchase_post.purchase_complete_R(p_user_no,
                                                     v_purchase_pk_no,
                                                     refresh_client);
    end;
  
    if v_stop_service_date is not null then
      update bsm_client_details a
         set a.end_date = v_stop_service_date
       where a.src_pk_no = v_purchase_pk_no;
      commit;
    end if;
  
    update bsm_coupon_mas a set status_flg = 'Z' where pk_no = p_pk_no;
  
    commit;
  
    --
    -- benq demo
    --
  
    declare
      v_msg varchar2(256);
    begin
      if v_vod_group is not null then
        update bsm_client_mas a
           set a.vod_cat_group             = v_vod_group,
               a.include_default_cat_group = 'Y'
         where a.mac_address = v_client_Id;
        commit;
        v_msg := cms_cnt_post.tgc_cms_cat_post(0);
        bsm_client_service.Set_subscription(null, v_client_Id);
      
      end if;
    end;
  
    --
    -- stock broker process
    -- 
    begin
      if v_stock_broker is not null then
        update bsm_client_mas a
           set a.stock_broker = v_stock_broker
         where a.mac_address = v_client_Id
           and a.stock_broker is null;
      end if;
    end;
  
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_UNPOST(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_mas_code   Varchar2(32);
    v_mas_no     Varchar2(32);
    v_mas_date   Date;
    v_client_id  varchar(32);
  
  begin
  
    begin
      Select mas_code, mas_no, mas_date, status_flg, serial_id
        Into v_mas_code, v_mas_no, v_mas_date, v_status_flg, v_client_id
        From bsm_coupon_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg <> 'P' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    --
    -- cancel service details
    --
    declare
      p_mac_address varchar2(32) := v_client_id;
      cursor c1 is
        select a.pk_no item_pk_no
          from Bsm_coupon_details a
         where mas_pk_no = p_Pk_No;
    
    begin
      for c1rec in c1 loop
        update bsm_client_details
           set status_flg = 'N'
         where src_item_pk_no = c1rec.item_pk_no;
      end loop;
    end;
  
    update bsm_coupon_mas a set status_flg = 'A' where pk_no = p_pk_no;
  
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_CANCEL(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_mas_code   Varchar2(32);
    v_mas_no     Varchar2(32);
    v_mas_date   Date;
    v_client_id  varchar(32);
  
  begin
  
    begin
      Select mas_code, mas_no, mas_date, status_flg, serial_id
        Into v_mas_code, v_mas_no, v_mas_date, v_status_flg, v_client_id
        From bsm_coupon_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('A', 'P') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    --
    -- cancel service details
    --
    declare
      p_mac_address varchar2(32) := v_client_id;
      cursor c1 is
        select a.pk_no item_pk_no
          from Bsm_coupon_details a
         where mas_pk_no = p_Pk_No;
    
    begin
      for c1rec in c1 loop
        update bsm_client_details
           set status_flg = 'C'
         where src_item_pk_no = c1rec.item_pk_no;
      end loop;
    end;
  
    update bsm_coupon_mas a set status_flg = 'C' where pk_no = p_pk_no;
  
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;
  Function COUPON_CANCEL_COMPLETE(p_User_No Number, p_Pk_No Number)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_mas_code   Varchar2(32);
    v_mas_no     Varchar2(32);
    v_mas_date   Date;
    v_client_id  varchar(32);
  
  begin
  
    begin
      Select mas_code, mas_no, mas_date, status_flg, serial_id
        Into v_mas_code, v_mas_no, v_mas_date, v_status_flg, v_client_id
        From bsm_coupon_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('A', 'P', 'Z') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    declare
      cursor c1 is
        select pk_no from bsm_purchase_mas where src_no = v_mas_no;
      v_msg varchar2(32);
    begin
      for i in c1 loop
        update bsm_client_details a
           set a.end_date = sysdate, a.status_flg = 'N'
         where src_pk_no = i.pk_no;
      
        update bsm_purchase_mas b
           set b.remark = 'COUPON 取消', b.status_flg = 'C'
         where b.pk_no = i.pk_no
           and b.mas_date >=
               to_date(to_char(sysdate - 10, 'YYYYMM') || '01', 'YYYYMMDD');
      
        commit;
      
        bsm_client_service.Set_subscription(null, v_client_id);
        v_msg := bsm_cdi_service.refresh_client(v_client_id);
      
        bsm_client_service.refresh_bsm_client(v_client_id);
      end loop;
    end;
  
    update bsm_coupon_mas a set status_flg = 'C' where pk_no = p_pk_no;
  
    commit;
  
    return 'Success';
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_BATCH_POST(p_User_No Number, p_Pk_No Number)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg      Varchar2(32);
    v_mas_code        Varchar2(32);
    v_mas_no          Varchar2(32);
    v_mas_date        Date;
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_program_id      varchar2(32);
    v_org_no          number(16);
    v_loc_no          number(16);
    v_coupon_mas_code varchar2(32) := 'COUPON';
    v_coupon_mas_date date := sysdate;
    v_expire_date     date;
    v_coupon_type     varchar2(32);
    v_curr_cup_cnt    number(16);
  
  begin
  
    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date,
             coupon_type
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date,
             v_coupon_type
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    select count(*)
      into v_curr_cup_cnt
      from bsm_coupon_mas a
     where a.src_no = v_mas_no;
  
    /*   If v_status_flg <> 'A' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If; */
  
    for i in nvl(v_curr_cup_cnt, 0) .. v_coupon_count - 1 loop
      declare
        v_pk_no            number;
        v_coupon_mas_no    varchar2(32);
        v_coupon_id        varchar2(32);
        v_coupon_serial_no varchar2(32);
        v_coupon_pre       varchar2(32);
      begin
        select seq_bsm_purchase_pk_no.nextval into v_pk_no from dual;
        v_coupon_mas_no    := sysapp_util.Get_Mas_No(v_org_no,
                                                     v_loc_no,
                                                     v_coupon_mas_date,
                                                     v_coupon_mas_code,
                                                     v_pk_no);
        v_coupon_id        := bsm_purchase_post.CLIENT_GENERATE_COUPON_NO(sysdate,
                                                                          v_coupon_type);
        v_coupon_pre       := v_coupon_prefix ||
                              to_char(to_number(to_char(sysdate, 'YYYY')) - 1911);
        v_coupon_serial_no := sysapp_util.Get_Mas_No(v_org_no,
                                                     v_loc_no,
                                                     sysdate,
                                                     'COUPONSERIAL',
                                                     v_pk_no,
                                                     v_coupon_pre);
        -- add month
        v_coupon_serial_no := substr(v_coupon_serial_no, 1, 5) ||
                              to_char(sysdate, 'MM') ||
                              substr(v_coupon_serial_no, 6, 12);
      
        insert into bsm_coupon_mas
          (org_no,
           loc_no,
           pk_no,
           mas_code,
           mas_date,
           mas_no,
           program_id,
           status_flg,
           src_code,
           src_no,
           src_date,
           coupon_id,
           coupon_serial_no,
           expire_date)
        values
          (v_org_no,
           v_loc_no,
           v_pk_no,
           v_coupon_mas_code,
           v_coupon_mas_date,
           v_coupon_mas_no,
           v_program_id,
           'A',
           v_mas_code,
           v_mas_no,
           v_mas_date,
           v_coupon_id,
           v_coupon_serial_no,
           v_expire_date);
      end;
    
    end loop;
  
    update bsm_coupon_batch_mas set status_flg = 'P' where pk_no = p_pk_no;
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_BATCH_POST_N(p_User_No Number, p_Pk_No Number)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg      Varchar2(32);
    v_mas_code        Varchar2(32);
    v_mas_no          Varchar2(32);
    v_mas_date        Date;
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_program_id      varchar2(32);
    v_org_no          number(16);
    v_loc_no          number(16);
    v_coupon_mas_code varchar2(32) := 'COUPON';
    v_coupon_mas_date date := sysdate;
    v_expire_date     date;
    v_curr_cup_cnt    number(16);
    v_coupon_type     varchar2(32);
  
  begin
  
    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date,
             coupon_type
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date,
             v_coupon_type
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    select count(*)
      into v_curr_cup_cnt
      from bsm_coupon_mas a
     where a.src_no = v_mas_no;
  
    for i in nvl(v_curr_cup_cnt, 0) .. v_coupon_count - 1 loop
      declare
        v_pk_no            number;
        v_coupon_mas_no    varchar2(32);
        v_coupon_id        varchar2(32);
        v_coupon_serial_no varchar2(32);
        v_coupon_pre       varchar2(32);
      begin
        select seq_bsm_purchase_pk_no.nextval into v_pk_no from dual;
        v_coupon_mas_no    := sysapp_util.Get_Mas_No(v_org_no,
                                                     v_loc_no,
                                                     v_coupon_mas_date,
                                                     v_coupon_mas_code,
                                                     v_pk_no);
        v_coupon_id        := bsm_purchase_post.CLIENT_GENERATE_COUPON_NO(sysdate,
                                                                          v_coupon_type);
        v_coupon_pre       := v_coupon_prefix ||
                              to_char(to_number(to_char(sysdate, 'YYYY')) - 1911);
        v_coupon_serial_no := sysapp_util.Get_Mas_No(v_org_no,
                                                     v_loc_no,
                                                     sysdate,
                                                     'COUPONSERIAL',
                                                     v_pk_no,
                                                     v_coupon_pre);
        -- add month
        v_coupon_serial_no := substr(v_coupon_serial_no, 1, 5) ||
                              to_char(sysdate, 'MM') ||
                              substr(v_coupon_serial_no, 6, 12);
      
        insert into bsm_coupon_mas
          (org_no,
           loc_no,
           pk_no,
           mas_code,
           mas_date,
           mas_no,
           program_id,
           status_flg,
           src_code,
           src_no,
           src_date,
           coupon_id,
           coupon_serial_no,
           expire_date)
        values
          (v_org_no,
           v_loc_no,
           v_pk_no,
           v_coupon_mas_code,
           v_coupon_mas_date,
           v_coupon_mas_no,
           v_program_id,
           'A',
           v_mas_code,
           v_mas_no,
           v_mas_date,
           v_coupon_id,
           v_coupon_serial_no,
           v_expire_date);
      end;
    
    end loop;
  
    update bsm_coupon_batch_mas set status_flg = 'P' where pk_no = p_pk_no;
  
    return null;
  
  Exception
    When app_exception Then
    
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_BATCH_POST_COUPON(p_User_No         Number,
                                    p_Pk_No           Number,
                                    p_start_serial_no varchar2,
                                    p_end_serial_no   varchar2)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
  
    cursor c1 is
      select pk_no, status_flg
        from bsm_coupon_mas a
       where
      --a.src_pk_no = p_pk_no  and 
       a.coupon_serial_no >= p_start_serial_no
       and coupon_serial_no <= p_end_serial_no;
    v_org_no          number(16);
    v_loc_no          number(16);
    v_mas_code        varchar2(32);
    v_mas_no          varchar2(32);
    v_mas_date        date;
    v_status_flg      varchar2(32);
    v_program_id      varchar2(32);
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_expire_date     date;
    v_coupon_mas_date date := sysdate;
    v_coupon_mas_code varchar2(32);
    v_coupon_type     varchar2(32);
    v_msg             varchar2(256);
  begin
  
    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date,
             coupon_type
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date,
             v_coupon_type
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg <> 'P' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    for i in c1 loop
      update bsm_coupon_mas a
         set a.expire_date = v_expire_date
       where pk_no = i.pk_no
         and status_flg = 'A';
    
      v_msg := bsm_purchase_post.COUPON_POST(0, i.pk_no);
    
    end loop;
  
    --  update bsm_coupon_batch_mas set status_flg = 'P' where pk_no = p_pk_no;
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_BATCH_POST_COUPON_N(p_User_No         Number,
                                      p_Pk_No           Number,
                                      p_start_serial_no varchar2,
                                      p_end_serial_no   varchar2)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
  
    cursor c1(v_src_no varchar) is
      select pk_no, status_flg
        from bsm_coupon_mas a
       where (p_start_serial_no is null and p_end_serial_no is null and
             a.src_no = v_src_no)
          or (a.coupon_serial_no >= p_start_serial_no and
             coupon_serial_no <= p_end_serial_no)
         and status_flg = 'A';
    v_org_no          number(16);
    v_loc_no          number(16);
    v_mas_code        varchar2(32);
    v_mas_no          varchar2(32);
    v_mas_date        date;
    v_status_flg      varchar2(32);
    v_program_id      varchar2(32);
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_expire_date     date;
    v_coupon_mas_date date := sysdate;
    v_coupon_mas_code varchar2(32);
    v_msg             varchar2(256);
  begin
  
    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    for i in c1(v_mas_no) loop
      update bsm_coupon_mas a
         set a.expire_date = v_expire_date
       where pk_no = i.pk_no
         and status_flg = 'A';
    
      update bsm_coupon_mas a
         set status_flg = 'P'
       where pk_no = i.pk_no
         and status_flg = 'A';
    
    end loop;
  
    return null;
  
  Exception
    When app_exception Then
    
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
    
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_BATCH_CANCEL_COUPON(p_User_No         Number,
                                      p_Pk_No           Number,
                                      p_start_serial_no varchar2,
                                      p_end_serial_no   varchar2)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
  
    cursor c1 is
      select pk_no, status_flg
        from bsm_coupon_mas a
       where a.coupon_serial_no >= p_start_serial_no
         and coupon_serial_no <= p_end_serial_no;
    v_org_no          number(16);
    v_loc_no          number(16);
    v_mas_code        varchar2(32);
    v_mas_no          varchar2(32);
    v_mas_date        date;
    v_status_flg      varchar2(32);
    v_program_id      varchar2(32);
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_expire_date     date;
    v_coupon_mas_date date := sysdate;
    v_coupon_mas_code varchar2(32);
    v_msg             varchar2(256);
  begin
  
    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg <> 'P' Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    for i in c1 loop
      if i.status_flg = 'P' then
        v_msg := bsm_purchase_post.COUPON_unPOST(0, i.pk_no);
        v_msg := bsm_purchase_post.COUPON_CANCEL(0, i.pk_no);
      elsif i.status_flg = 'A' then
        v_msg := bsm_purchase_post.COUPON_CANcel(0, i.pk_no);
      end if;
    end loop;
  
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function COUPON_BATCH_SET_COUPON(p_User_No         Number,
                                   p_Pk_No           Number,
                                   p_start_serial_no varchar2,
                                   p_end_serial_no   varchar2,
                                   p_exp_date        date) Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
  
    cursor c1 is
      select pk_no, status_flg
        from bsm_coupon_mas a
       where a.coupon_serial_no >= p_start_serial_no
         and coupon_serial_no <= p_end_serial_no;
    v_org_no          number(16);
    v_loc_no          number(16);
    v_mas_code        varchar2(32);
    v_mas_no          varchar2(32);
    v_mas_date        date;
    v_status_flg      varchar2(32);
    v_program_id      varchar2(32);
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_expire_date     date;
    v_coupon_mas_date date := sysdate;
    v_coupon_mas_code varchar2(32);
    v_msg             varchar2(256);
  begin
  
    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        null;
        --   exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
      --  raise app_exception;
    end;
  
    for i in c1 loop
      if i.status_flg = 'P' then
        update bsm_coupon_mas a
           set a.expire_date = p_exp_date
         where a.pk_no = i.pk_no;
      elsif i.status_flg = 'A' then
        update bsm_coupon_mas a
           set a.expire_date = p_exp_date
         where a.pk_no = i.pk_no;
      end if;
    end loop;
  
    commit;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;

  Function cal_end_date(p_start_date date, duration_day number) return date is
    v_start_date date;
    v_end_date   date;
  begin
    if p_start_date is null then
      v_start_date := sysdate;
    else
      v_start_date := p_start_date;
    end if;
  

      v_end_date := trunc(v_start_date + duration_day-
                    (1 / (24 * 60 * 60))) +
                    (1 - (1 / (24 * 60 * 60)));
    return v_end_date;
  
  end;

  procedure process_purchase_detail(client_id      varchar2,
                                    purchase_pk_no number) is
    --
    --  處理產生相關內容資料
    -- 
  
    p_mac_address varchar2(32) := client_id;
    exception_msg varchar2(512);
    app_exception Exception;
    cursor c1 is
      select *
        from Bsm_Purchase_Item a
       where mas_pk_no = purchase_pk_no
         and type = 'P';
  
    v_tr_id                number(16);
    v_serial_no            number(16);
    v_serial_id            varchar2(32);
    v_mac_address          varchar2(32);
    v_start_date           date;
    v_end_date             date;
    v_acl_duration         number;
    v_acl_quota            number;
    v_package_cat1         varchar2(256);
    v_package_name         varchar2(256);
    v_cal_type             varchar2(256);
    v_package_cat_id1      varchar2(256);
    v_last_end_date        date;
    v_duration_day         number(16);
    v_duration_month       number(16);
    v_purchase_no          varchar2(32);
    v_package_system_type  varchar2(32);
    v_item_id              varchar2(64);
    v_pay_type             varchar2(256);
    v_phone_no             varchar2(32);
    v_device_id            varchar2(32);
    v_apt_productcode      varchar2(32);
    v_apt_min              varchar2(32);
    v_apt_gateway          varchar2(32);
    v_GMD2_flg             boolean;
    v_amt_devices          number(16);
    v_acl_id               varchar2(32);
    v_start_type           varchar2(32);
    v_software_group       varchar2(32);
    v_src_no               varchar2(32);
    v_package_service_type varchar2(32);
    v_create_sub           boolean;
  begin
    v_create_sub:= true;
    select mas_no, pay_type, nvl(start_type, 'E'), src_no
      into v_purchase_no, v_apt_gateway, v_start_type, v_src_no
      from bsm_purchase_mas
     where pk_no = purchase_pk_no;
  
    select serial_no, serial_id, mac_address, owner_phone
      into v_serial_no, v_serial_id, v_mac_address, v_phone_no
      from bsm_client_mas
     where mac_address = p_Mac_address;
  
    for c1rec in c1 loop
      v_create_sub:= true;
      -- 達博方案不產生服務client detail 
      v_GMD2_flg := false;
      if substr(c1rec.package_id, 1, 4) = 'GMD2' then
        v_GMD2_flg := true;
      end if;
    
      if not v_GMD2_flg then
        -- 處理重複計算問題
        -- 
        v_apt_min         := c1rec.apt_min;
        v_apt_productcode := c1rec.apt_productcode;
        begin
          if c1rec.pk_no is not null then
            declare
              v_char varchar2(32);
            begin
              select 'x' into v_char from bsm_client_details a where
               a.src_item_pk_no=c1rec.pk_no
               and status_flg='P';
           
                v_create_sub := false;
            exception
              when no_data_found then v_create_sub:= true;
            end;
            
          end if;
        end;
        if v_create_sub then
        v_last_end_date := null;
        v_start_date    := null;
        v_end_date      := null;
      
        Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_tr_id From Dual;
        begin
      
        Select acl_duration,
               acl_quota,
               package_cat1,
               case
                 when (substr(v_src_no, 1, 2) = 'RE' and
                      a.package_id = 'WD0001') or
                      (v_apt_gateway <> '信用卡' and a.package_id = 'WD0001') then
                  description
                 else
                 
                  decode(ref3, null, description, description || ' ' || ref3)
               end description,
               cal_type,
               a.package_cat_id1,
               case
                 when (substr(v_src_no, 1, 2) = 'RE' and
                      a.package_id = 'WD0001') or
                      (v_apt_gateway <> '信用卡' and a.package_id = 'WD0001') then
                  30
                 else
                  nvl(c1rec.duration_day, a.duration_by_day)
               end,
               nvl(c1rec.duration_month, a.duration_by_month),
               a.system_type,
               a.amt_of_devices,
               a.acl_id,
               service_type
          into v_acl_duration,
               v_acl_quota,
               v_package_cat1,
               v_package_name,
               v_cal_type,
               v_package_cat_id1,
               v_duration_day,
               v_duration_month,
               v_package_system_type,
               v_amt_devices,
               v_acl_id,
               v_package_service_type
          from bsm_package_mas a
         where package_id = c1rec.package_id;
         exception
           when no_data_found then v_package_service_type:='STOCK';
         end;
        if v_package_service_type in ('STOCK', 'COUPON') then
          null;
        elsif v_package_system_type in ('CREDITS', 'FREE_CREDITS') then
          -- 儲值
          if v_pay_type = '儲值卡' then
            exception_msg := '#錯誤的資料#';
            Raise app_exception;
          end if;
        
          -- 測試帳號禁止購買點數
          declare
            v_char varchar2(32);
          begin
            select 'x'
              into v_char
              from mfg_dev_account_mas a
             where a.owner_phone_no = v_phone_no
               and rownum <= 1
               and a.status_flg = 'P';
            exception_msg := '#測試帳號禁止購買點數#';
            Raise app_exception;
          exception
            when no_data_found then
              null;
          end;
          cal_client_credits(client_id,
                             c1rec.package_id,
                             purchase_pk_no,
                             c1rec.exp_days);
        else
          if client_id like '2%' then
            if c1rec.device_id is not null then
              v_device_id := c1rec.device_id;
            
            else
              declare
                v_cnt           number(16);
                v_max_device_id varchar2(32);
                v_client_id     varchar(32);
              
              begin
                v_client_id := client_id;
                select count(*), max(device_id)
                  into v_cnt, v_max_device_id
                  from bsm_client_device_list a
                 where a.client_id = v_client_id
                   and a.status_flg = 'P';
              
                if v_cnt = 1 then
                  v_device_id := v_max_device_id;
                end if;
              
              exception
                when no_data_found then
                  null;
                
              end;
            
            end if;
          
            if v_amt_devices > 1 then
              v_device_id := null;
            end if;
          
          end if;
        
          if v_cal_type not in ('I', 'T') then
            begin
              select max(end_date)
                into v_last_end_date
                from bsm_client_details a
               where mac_address = p_Mac_address
                 and status_flg = 'P'
                 and a.end_date is not null
                 and a.package_id in
                     (select package_id
                        from bsm_package_mas b
                       where status_flg = 'P'
                         and b.cal_type not in ('I', 'T')
                         and nvl(b.acl_period, 0) = 0
                         and b.package_cat_id1 = v_package_cat_id1)
                 and ((c1rec.device_id is not null and
                     (a.device_id is null or
                     a.device_id = c1rec.device_id)) or
                     (c1rec.device_id is null and
                     (a.device_id is null or
                     a.device_id not in
                     (select c.device_id
                           from bsm_client_device_list c
                          where c.client_id = p_Mac_address
                            and c.software_group = 'LTSMS02'))))
                 and trunc(a.end_date) >= sysdate;
            exception
              when no_data_found then
                v_last_end_date := null;
            end;
          
          else
          
            v_item_id       := c1rec.package_id || c1rec.item_id;
            v_last_end_date := null;
          
          end if;
        
          -- modify cal end date to 23:59:00        -- modify cal end date to 23:59:00
          if v_last_end_date is not null and v_start_type = 'E' then
            v_start_date := trunc(v_last_end_date + 1);
          else
            v_start_date := sysdate;
          end if;
          --  end if;
        
          if v_cal_type in ('I', 'T') then
            begin
              v_package_name := cms_util.get_content_title(c1rec.item_id);
              v_start_date   := sysdate;
              v_end_date     := v_start_date + v_duration_day;
            exception
              when others then
                v_package_name := v_package_name;
            end;
          
          else
            v_start_date   := trunc(v_start_date);
            v_package_name := v_package_name;
            begin
              v_end_date := bsm_purchase_post.cal_end_date(add_months(v_start_date,
                                                                      v_duration_month),
                                                           v_duration_day);
            exception
              when others then
                v_end_date := null;
            end;
          
          end if;
        
          insert into bsm_client_details
            (src_pk_no,
             src_no,
             pk_no,
             serial_no,
             serial_id,
             mac_address,
             package_cat1,
             package_id,
             package_name,
             start_date,
             end_date,
             acl_duration,
             acl_quota,
             status_flg,
             item_id,
             src_item_pk_no,
             device_id,
             apt_productcode,
             apt_min,
             apt_gateway,
             acl_id)
          values
            (Purchase_Pk_No,
             v_Purchase_No,
             v_tr_id,
             v_serial_no,
             v_serial_id,
             v_mac_address,
             v_package_cat1,
             c1rec.package_id,
             v_package_name,
             v_start_date,
             v_end_date,
             v_acl_duration,
             v_acl_quota,
             'P',
             nvl(v_item_id, c1rec.item_id),
             c1rec.pk_no,
             v_device_id,
             v_apt_productcode,
             v_apt_min,
             v_apt_gateway,
             v_acl_id);
        end if;
        end if; -- end create sub
      end if;
    end loop;
  
  end;
  procedure cal_client_credits(p_client_id      varchar2,
                               p_package_id     varchar2,
                               p_purchase_pk_no number,
                               p_exp_days       number default null) is
    v_client_credits   number(16);
    v_package_credits  number(16);
    v_real_mac_address varchar2(32);
    v_pay_type         varchar2(32);
    v_exp_days         number;
    v_src_pk_no        number(16);
    v_coupon_prog      varchar2(32);
    v_credits_type     varchar2(32);
  begin
    select pay_type
      into v_pay_type
      from bsm_purchase_mas a
     where a.pk_no = p_purchase_pk_no;
    if v_pay_type = '兌換券' then
      v_credits_type := 'GIFT';
    else
      v_credits_type := 'BUY';
    end if;
  
    select credits + credits_gift
      into v_package_credits
      from bsm_package_mas
     where package_id = p_package_id;
  
    select nvl(real_mac_address, mac_address)
      into v_real_mac_address
      from bsm_client_mas
     where mac_address = p_client_id;
  
    if v_credits_type = 'GIFT' then
      insert into bsm_client_credits_mas
        (mas_pk_no,
         client_id,
         open_credits,
         real_mac_address,
         credits_type,
         expiration_date)
      values
        (p_purchase_pk_no,
         p_client_id,
         v_package_credits,
         v_real_mac_address,
         v_credits_type,
         sysdate + p_exp_days);
      update bsm_purchase_mas a
         set a.after_credits = v_package_credits
       where pk_no = p_purchase_pk_no;
    else
      begin
      
        select open_credits
          into v_client_credits
          from bsm_client_credits_mas
         where client_id = p_client_id
           and credits_type = v_credits_type;
      
        update bsm_client_credits_mas
           set open_credits = open_credits + v_package_credits
         where client_id = p_client_id
           and credits_type = v_credits_type;
      
        update bsm_purchase_mas a
           set a.after_credits = v_client_credits + v_package_credits
         where pk_no = p_purchase_pk_no;
      
      exception
        when no_data_found then
          insert into bsm_client_credits_mas
            (client_id, open_credits, real_mac_address, credits_type)
          values
            (p_client_id,
             v_package_credits,
             v_real_mac_address,
             v_credits_type);
          update bsm_purchase_mas a
             set a.after_credits = v_package_credits
           where pk_no = p_purchase_pk_no;
      end;
    end if;
  
  end;

  function use_credits(p_client_id varchar2, p_purchase_pk_no number)
    return varchar2 is
    v_open_credits   number(16);
    v_credits_amount number(16);
    v_result         varchar2(256);
    v_credits_cnt    number(16);
    v_src_credits    number(16);
    v_after_credits  number(16);
  begin
    select count(*)
      into v_credits_cnt
      from bsm_purchase_item a, bsm_package_mas b
     where b.package_id = a.package_id
       and a.mas_pk_no = p_purchase_pk_no
       and b.system_type = 'CREDITS';
  
    if v_credits_cnt > 0 then
      v_result := 'PRC=ERRORS';
      return v_result;
    end if;
  
    select nvl(sum(open_credits), 0)
      into v_open_credits
      from bsm_client_credits_mas a
    
     where client_id = p_client_id
       and (a.expiration_date is null or
           trunc(a.expiration_date) >= trunc(sysdate));
  
    select sum(nvl(credits, 0))
      into v_credits_amount
      from bsm_purchase_item
     where mas_pk_no = p_purchase_pk_no;
  
    if nvl(v_credits_amount, 0) > nvl(v_open_credits, 0) then
      v_result := '儲值金額不足';
    else
      declare
        cursor c1 is
          select rowid rid, open_credits, credits_type
            from bsm_client_credits_mas a
           where client_id = p_client_id
             and (a.expiration_date is null or
                 trunc(a.expiration_date) >= trunc(sysdate))
           order by decode(credits_type, 'G', 1, 2),
                    nvl(expiration_date, sysdate + 365 * 99);
        v_amt number(16);
      begin
        v_amt := v_credits_amount;
        delete bsm_purchase_credits where mas_pk_no = p_purchase_pk_no;
        for c1rec in c1 loop
          if v_amt > 0 then
            if c1rec.open_credits > v_amt then
              select open_credits
                into v_src_credits
                from bsm_client_credits_mas
               where rowid = c1rec.rid
                 for update;
              v_after_credits := v_src_credits - v_amt;
            
              update bsm_client_credits_mas
                 set open_credits = v_after_credits
               where rowid = c1rec.rid;
            
              insert into bsm_purchase_credits
                (mas_pk_no,
                 credits_type,
                 src_credits,
                 credits,
                 after_credits)
              values
                (p_purchase_pk_no,
                 c1rec.credits_type,
                 v_src_credits,
                 v_amt,
                 v_after_credits);
              v_amt := 0;
            else
              select open_credits
                into v_src_credits
                from bsm_client_credits_mas
               where rowid = c1rec.rid
                 for update;
              v_after_credits := 0;
            
              update bsm_client_credits_mas
                 set open_credits = 0
               where rowid = c1rec.rid;
            
              insert into bsm_purchase_credits
                (mas_pk_no,
                 credits_type,
                 src_credits,
                 credits,
                 after_credits)
              values
                (p_purchase_pk_no,
                 c1rec.credits_type,
                 c1rec.open_credits,
                 v_amt,
                 v_after_credits);
              v_amt := v_amt - c1rec.open_credits;
            end if;
          end if;
        end loop;
      end;
      /*                 
        update bsm_client_credits_mas
           set open_credits = open_credits - v_credits_amount
         where client_id = p_client_id;
      */
      update bsm_purchase_mas a
         set a.cost_credits  = to_char(v_credits_amount) || '點',
             a.after_credits = to_char(v_open_credits - v_credits_amount) || '點'
       where pk_no = p_purchase_pk_no;
    
      v_result := 'PRC=0';
    end if;
  
    return v_result;
  end;

  function cancel_all_purchase(p_User_No Number, client_id varchar2)
    return varchar2 is
  begin
    update bsm_purchase_mas a
       set a.status_flg = 'C'
     where a.serial_id = client_id;
    commit;
    return null;
  end;

  function hide_all_purchase(p_User_No Number, client_id varchar2)
    return varchar2 is
  begin
    update bsm_purchase_mas a
       set a.show_flg = 'N', a.recurrent = 'O'
     where serial_id = client_id;
    commit;
    return null;
  end;

  function get_vis_acc(p_mas_no varchar2, p_due_date date, p_amount number)
    return varchar2 is
    v_bank_code   varchar2(32) := '8171';
    v_acc_invo_no varchar2(32);
  
    v_acc_due    varchar2(4);
    v_check_code varchar2(1);
    v_result     varchar2(32);
  begin
    v_acc_due := substr(to_char(to_number(to_char(p_due_date, 'YYYY')) - 1911),
                        3,
                        1) ||
                 lpad(to_char(trunc(p_due_date) -
                              to_date(to_char(p_due_date, 'YYYY') || '0101',
                                      'YYYYMMDD') + 1),
                      3,
                      '0');
  
    v_acc_invo_no := substr(p_mas_no, length(p_mas_no) - 4, 5); -- 取單號末五位
  
    v_check_code := vachksum(v_bank_code || v_acc_invo_no || v_acc_due,
                             p_amount);
  
    v_result := v_bank_code || v_acc_invo_no || v_acc_due || v_check_code;
  
    return v_result;
  
  end;

  procedure refresh_bsm_client(v_client_id varchar2) is
  begin
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
  end;

End BSM_PURCHASE_POST_OLD;
/

