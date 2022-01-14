CREATE OR REPLACE PACKAGE BODY IPTV."BSM_RECURRENT_UTIL_DEV" is
  queue_name_setting varchar2(1024) := 'purchase_msgb_queue';
  function get_next_pay_date(p_cat varchar2, p_client_id varchar2)
    return varchar2 is
    v_result    date;
    v_client_id varchar2(32);
    v_pay_type  varchar2(64);
  begin
    v_client_id := upper(p_client_id);
  
    select max(nvl(nvl(d.next_bill_date, c.next_pay_date), a.end_date + 1)),
           max(decode(c.pay_type,
                      'IOS',
                      'IOS',
                      '中華帳單',
                      '中華帳單',
                      'TSTAR',
                      'TSTAR',
                      'IAB',
                      'IAB',
                      'GOOGLEPLAY',
                      'GOOGLEPLAY',
                      ''))
      into v_result, v_pay_type
      from bsm_client_details a,
           bsm_package_mas    b,
           bsm_purchase_mas   c,
           bsm_recurrent_mas  d
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and d.src_pk_no(+) = c.pk_no
       and a.status_flg = 'P'
       and d.status_flg = 'P'
          --   and (a.start_date is null or (a.end_date >= sysdate))
       and b.package_cat_id1 = p_cat
       and c.pk_no = a.src_pk_no;
  
    if v_pay_type = 'IOS' then
      return '請查詢iTunes帳號';
    elsif v_pay_type = '中華帳單' then
      return '請查詢中華電信';
    elsif v_pay_type = 'IAB' then
      return '請查詢GooglePlay帳號';
    elsif v_pay_type = 'GOOGLEPLAY' then
      return '請查詢GooglePlay帳號';
    elsif v_pay_type = 'TSTAR' then
      return '依帳單日期';
    else
      -- return '每月自動扣款';
      return to_char(v_result, 'YYYY/MM/DD');
    end if;
  end;
  function get_service_end_date(p_cat varchar2, p_client_id varchar2)
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
       and (start_date is null or (end_date >= sysdate))
       and (b.package_cat_id1 = p_cat or
           decode(b.package_cat_id1,
                   'VOD_CHANNEL',
                   'VOD_CHANNEL_DELUX',
                   'VOD_CHANNEL_VALUE',
                   'VOD_CHANNEL_DELUX',
                   'VOD_CHANNEL_RB1',
                   'VOD_CHANNEL_DELUX',
                   'VOD_CHANNEL_RB2',
                   'VOD_CHANNEL_DELUX',
                   package_cat_id1) = p_cat);
    v_result := nvl(v_result, sysdate);
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
       and (b.package_cat_id1 = p_cat or
           decode(b.package_cat_id1,
                   'VOD_CHANNEL',
                   'VOD_CHANNEL_DELUX',
                   'VOD_CHANNEL_VALUE',
                   'VOD_CHANNEL_DELUX',
                   'VOD_CHANNEL_RB1',
                   'VOD_CHANNEL_DELUX',
                   'VOD_CHANNEL_RB2',
                   'VOD_CHANNEL_DELUX',
                   package_cat_id1) = p_cat);
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
    v_result    varchar2(32);
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
  function check_recurrent_2(p_cat       varchar2,
                             p_client_id varchar2,
                             p_device_id varchar2 default null)
    return varchar2 is
    v_result    varchar2(32);
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
        return null;
      end if;
      update bsm_purchase_mas a
         set a.recurrent = 'O'
       where a.mas_no = p_purchase_id;
    
      update bsm_client_details a
         set a.end_date = sysdate,
         a.extend_days=0
       where a.src_pk_no = v_purchase_pk_no;
    elsif v_recurrent_type = 'LiPay' then
      v_result := BSM_LIPAY_GATEWAY.stopRecurrent(p_purchase_id);
    
      if v_result = 'PRC=0' then
      
        update bsm_purchase_mas a
           set a.recurrent = 'O'
         where a.mas_no = p_purchase_id;
        update bsm_recurrent_mas a
           set status_flg            = 'B',
               f_stop_rec            = 'B',
               a.end_date            = decode(p_actiondate,
                                              null,
                                              to_date(p_actiondate,
                                                      'YYYYMMDDHH24MISS'),
                                              sysdate),
               a.remark              = p_remark,
               a.last_modify_date    = sysdate,
               a.stop_recurrent_date = sysdate
         where a.src_no = p_purchase_id;
        update bsm_client_details a
           set a.extend_days = 0
         where a.src_pk_no = v_purchase_pk_no;
        commit;
        v_result := null;
      
      end if;
    else
      update bsm_purchase_mas a
         set a.recurrent = 'O'
       where a.mas_no = p_purchase_id;
      update bsm_recurrent_mas a
         set status_flg            = 'B',
             a.end_date            = decode(p_actiondate,
                                            null,
                                            to_date(p_actiondate,
                                                    'YYYYMMDDHH24MISS'),
                                            sysdate),
             a.stop_recurrent_date = sysdate,
             a.remark              = p_remark
       where a.src_no = p_purchase_id;
      update bsm_client_details a
         set a.extend_days = 0
       where a.src_pk_no = v_purchase_pk_no;
    
      commit;
      v_result := null;
    
    end if;
    declare
      v_msg varchar2(2048);
    begin
      bsm_client_service.Set_subscription_r(null, v_client_id, 'N');
      bsm_client_service.refresh_bsm_client(v_client_id,
                                            queue_name_setting);
      v_msg := bsm_cdi_service.refresh_client(v_client_id,
                                              queue_name_setting);
    end;
  
    return v_result;
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
                                             b.serial_id || 'hello') card_no,
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
           and e.recurrent = 'R'
           and trunc(get_service_end_date_full(e.package_cat_id1,
                                               b.serial_id)) <=
               trunc(sysdate)
           and a.recurrent_type = 'CREDIT'
        --and rownum <= 100
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
              in_bsm_purchase.src_no      := 'BE' || i.purchase_id || '_' ||
                                             to_char(sysdate, 'YYYYMMDD');
              in_bsm_purchase.serial_id   := i.serial_id;
              in_bsm_purchase.pay_type    := '信用卡';
              in_bsm_purchase.details     := new tbsm_purchase_dtls();
              in_bsm_purchase.details.extend(1);
              in_bsm_purchase.details(1) := new tbsm_purchase_dtl();
              in_bsm_purchase.details(1).offer_id := i.package_id;
              in_bsm_purchase.details(1).amount := i.amount;
              p_recurrent := 'R';
              p_sw_version := 'TRANSTOLIPAY_AUTO';
            
              result := bsm_client_service.crt_purchase(in_bsm_purchase   => in_bsm_purchase,
                                                        p_recurrent       => p_recurrent,
                                                        p_device_id       => p_device_id,
                                                        parameter_options => parameter_options,
                                                        p_sw_version      => p_sw_version);
              if result.result_code = 'BSM-00000' then
                -- recurrent 成功註記回正常
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'N',
                       a.recurrent_s_date = sysdate,
                       a.status_flg       = 'B',
                       a.remark           = '客戶移轉'
                
                 where a.src_no = i.purchase_id;
                commit;
              else
                -- recurrent 失敗註記成扣款期
                declare
                  v_c varchar2(10);
                begin
                  v_c := lpad(to_char(trunc(i.max_end_date) -
                                      trunc(sysdate)),
                              1,
                              '0');
                
                  update bsm_recurrent_mas a
                     set a.recurrent_status = 'C' || v_c,
                         a.recurrent_s_date = sysdate,
                         a.next_bill_date   = sysdate + 1
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

  function auto_recurrent_newwebpay return varchar2 is
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
               b.token_id,
               trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                  b.serial_id)) max_end_date,
               a.next_bill_date,
               case
                 when dis_period is null then
                  sum(nvl(a.amount, c.amount))
                 when current_dis_period < dis_period then
                  sum(a.dis_amount)
                 else
                  sum(nvl(a.amount, c.amount))
               end amount,
                nvl(a.package_name,e.description) package_name,
                nvl(a.package_cat1,e.package_cat1) package_cat1,
                nvl(a.price_desc,e.price_des) price_desc,
                vendor_id
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
           and e.recurrent = 'R'
           and ((trunc(a.next_bill_date) <= trunc(sysdate) and
               (trunc(a.next_bill_date) >=
               trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                     b.serial_id) - 7))) or
               trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                   b.serial_id)) <=
               trunc(sysdate))
           and a.recurrent_type = 'LiPayN'
           and b.lipay_tx_number like 'newebpay%'
         group by b.serial_id,
         a.package_name,
                  b.mas_no,
                  a.card_expiry,
                  a.card_no,
                  a.card_type,
                  a.cvc2,
                  b.pay_pk_no,
                  e.package_cat_id1,
                  c.package_id,
                  b.token_id,
                  dis_period,
                  current_dis_period,
                  a.next_bill_date,
                nvl(a.package_name,e.description),
                nvl(a.package_cat1,e.package_cat1),
                nvl(a.price_desc,e.price_des),
                b.vendor_id;
      v_msg        varchar2(1024);
      p_sw_version varchar2(1024);
    begin
      for i in c1 loop
        dbms_output.put_line(i.serial_id);
        -- 已服務過期註銷
        if i.max_end_date < trunc(sysdate) - 10 then
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
            p_sw_version := 'RECURRENT_AUTO';
            -- 檢查是否已經扣款過
          
            declare
              v_src_no              varchar2(32);
              v_acc_invo_no         varchar2(32);
              v_pay_type            varchar2(32) := '信用卡二次扣款';
              v_Client_Info         Tbsm_Client_Info;
              v_acc_name            varchar2(32);
              v_tax_code            varchar2(32);
              v_Purchase_Mas_Code   varchar(32) := 'BSMPUR';
              v_Serial_No           number(16);
              v_id                  varchar2(32);
              v_Price               number(16);
              v_Duration            number(16);
              v_Quota               number(16);
              v_charge_type         varchar2(32);
              v_charge_code         varchar2(32);
              v_start_type          varchar2(32);
              v_recurrent           varchar2(32);
              v_charge_name         varchar2(32);
              v_package_cat_id1     varchar2(32);
              v_Purchase_No         varchar2(32);
              v_purchase_date       date;
              v_Purchase_Pk_No      number(16, 0);
              v_Purchase_Item_Pk_No number(16, 0);
              p_user_no             number(16) := 0;
              v_last_service_date   date;
              v_response_code       varchar2(1024);
            
            begin
              v_src_no := 'RE' || i.purchase_id ||
                          to_char(sysdate, 'YYYYMMDD');
            
              v_Client_Info   := bsm_client_service.Get_Client_Info(i.serial_id);
              v_Serial_No     := v_client_info.serial_no;
              v_purchase_date := sysdate;
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
                 NEXT_PAY_DATE,
                 vendor_id)
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
                 i.serial_id,
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
                 add_months(v_purchase_date, 1),
                 i.vendor_id
                 --  v_purchase_date + 5
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
               where mac_address = i.serial_id
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
                 DEVICE_ID,
                 package_name,
                 package_cat1,
                 price_desc)
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
                 null,
                 i.package_name,
                 i.package_cat1,
                 i.price_desc
               );
            
              commit;
              begin
              v_response_code := bsm_lipay_gateway.
                                 AccePayment_token(v_Purchase_Pk_No,
                                                   i.amount,
                                                   i.token_id,
                                                   null);
              exception
                when others then 
                     update bsm_purchase_mas a
                   set a.response_code =null,
                       a.status_flg    = 'F'
                 where a.pk_no = v_purchase_pk_no;
                commit;
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'retry',
                       a.recurrent_s_date = sysdate,
                       a.next_bill_date   = sysdate + 1,
                       a.last_modify_date = sysdate
                 where a.src_no = i.purchase_id;
                commit;
             end;
                
              if v_response_code like 'PRC=0%' then
              
                declare
                  v_msg number(16);
                begin
                  v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                           v_purchase_pk_no);
                  v_msg := bsm_purchase_post.purchase_complete_r(p_user_no,
                                                                 v_purchase_pk_no,
                                                                 'N');
                  update bsm_recurrent_mas c
                     set c.current_dis_period = nvl(current_dis_period, 1) + 1
                   where c.src_no = i.purchase_id;
                  commit;
                exception
                  when others then
                    null;
                end;
              
                begin
                  -- 時間過期三天內,自動移動服務接續一起
                  if v_last_service_date is not null and
                     v_last_service_date >= sysdate - 4 then
                    update bsm_client_details a
                       set a.start_date = v_last_service_date + 1,
                           a.end_date   = a.end_date - (v_last_service_date + 1 -
                                          a.start_date)
                     where a.src_pk_no = v_purchase_pk_no;
                    bsm_client_service.Set_subscription_r(v_purchase_pk_no,
                                                          i.serial_id,
                                                          'N');
                  end if;
                end;
              
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
                     set a.tax_inv_no   = v_inv_no,
                         a.tax_inv_date = v_inv_date
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
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'ok',
                       -- a.status_flg ='P',
                       a.recurrent_s_date = sysdate,
                       a.last_modify_date = sysdate
                 where a.src_no = i.purchase_id;
                commit;
              else
                update bsm_purchase_mas a
                   set a.response_code = v_response_code,
                       a.status_flg    = 'F'
                 where a.pk_no = v_purchase_pk_no;
                commit;
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'retry',
                       a.recurrent_s_date = sysdate,
                       a.next_bill_date   = sysdate + 1,
                       a.last_modify_date = sysdate
                 where a.src_no = i.purchase_id;
                commit;
              end if;
              bsm_client_service.refresh_bsm_client(i.serial_id,
                                                    queue_name_setting);
              v_msg := bsm_cdi_service.refresh_client(i.serial_id,
                                                      queue_name_setting);
            exception
              when no_data_found then dbms_output.put_line('break'||i.serial_id);
            end;
          end if;
        
        end if;
      
      end loop;
    
      for i in c1 loop
        dbms_output.put_line(i.serial_id);
        -- 已服務過期註銷
        if i.max_end_date < trunc(sysdate) + 1 then
          -- recurrent 註記成警告期
          /*     update bsm_recurrent_mas a
             set a.recurrent_status = 'A', 
             a.recurrent_s_date = sysdate
           where a.src_no = i.purchase_id;
          commit; */
          null;
        elsif i.max_end_date < trunc(sysdate) then
          -- recurrent 註記成關閉
          /*    update bsm_recurrent_mas a
             set a.recurrent_status = 'B', a.recurrent_s_date = sysdate
           where a.src_no = i.purchase_id;
          commit;  */
          null;
          dbms_output.put_line(i.serial_id || ':Expired');
          v_msg := stop_recurrent(i.serial_id,
                                  i.purchase_id,
                                  '服務到期',
                                  to_char(SYSDATE, 'YYYYMMDDHH24MISS'));
          bsm_client_service.refresh_bsm_client(i.serial_id);
          update bsm_recurrent_mas a
             set status_flg         = 'B',
                 a.end_date         = sysdate,
                 a.recurrent_status = 'fail',
                 a.remark           = 'LiPay中止',
                 a.last_modify_date = sysdate,
                 a.stop_date        = sysdate
          
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
             set a.end_date = sysdate + 3, a.status_flg = 'P'
           where a.pk_no = i.detail_pk_no;
          commit;
          bsm_client_service.Set_subscription(null, i.serial_id);
          --- v_msg := bsm_cdi_service.refresh_client(i.serial_id);
          dbms_lock.sleep(6);
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
            dbms_lock.sleep(6);
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
           and f.mas_pk_no = b.pk_no
           and b.mas_no='PUR20211100028266';
      v_msg        varchar2(1024);
      v_flg        varchar2(1024);
      expired_date date;
      auto_renew_status varchar2(1024);
      pending_list json_list;
      rep_data json;
    begin
      for i in c1 loop
        begin
          declare
             rw_result clob;
    jsonobj json;
    jbl json_list;
    status_flg varchar2(32);
    
  begin
    rw_result := bsm_ios_gateway.get_Receipt_Data(i.pk_no,'','',i.ios_product_code);
    jsonobj:=json(rw_result);


    begin
        v_flg := to_CHAR(json_ext.get_number(jsonobj,'result.status'));
        auto_renew_status := to_CHAR(json_ext.get_number(jsonobj,'result.auto_renew_status'));
    exception
      when others then v_flg:=null;
    end;
    
    begin
      pending_list :=  json_ext.get_json_list(jsonobj, 'result.pending_renewal_info');
         dbms_output.put_line(json_ext.get_string(jsonobj,
                                                         'result.pending_renewal_info'));
    exception
      when others then v_flg:= null;
    end;
 end;
    
          v_flg := bsm_ios_gateway.check_Receipt_Data_str(i.pk_no,
                                                          i.ios_product_code);
          if v_flg = '21006' or auto_renew_status='0' then
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
            if pending_list is not null then
                for j in 1 .. pending_list.COUNT() loop
                  rep_data := Json(jsonlist_get(pending_list, j - 1));
                  declare
                    auto_renew_status_1 varchar2(16);
                    original_transaction_id varchar2(32);
                  begin
                       auto_renew_status_1 :=json_ext.get_string(rep_data,'auto_renew_status');
                       original_transaction_id := json_ext.get_string(rep_data,'original_transaction_id');
                        
                   if auto_renew_status_1 ='0' then
                         update bsm_recurrent_mas c set c.status_flg='B',c.stop_date=sysdate where c.recurrent_type='IOS' and c.src_no in (select mas_no from bsm_purchase_mas d where d.ios_org_trans_id=original_transaction_id);
                         commit;
                       end if;
                    
                  end;
    
             
                end loop;
            end if;
           
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

  function tstar_recurrent return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no purchase_id,
               a.card_expiry,
               a.recurrent_type,
               bsm_encrypt.decrypt_Serial_ID(a.card_no,
                                             b.serial_id || 'tgc27740083') card_no,
               a.card_type,
               a.cvc2,
               c.package_id,
               trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                  b.serial_id)) max_end_date,
               d.end_date,
               d.pk_no dtl_pk_no,
               e.duration_by_month,
               e.duration_by_day
          from bsm_recurrent_mas  a,
               bsm_purchase_mas   b,
               bsm_purchase_item  c,
               bsm_client_details d,
               bsm_package_mas    e,
               acl.subscription   f
         where a.status_flg = 'P'
           and b.status_flg = 'Z'
           and d.status_flg = 'P'
           and b.mas_no = a.src_no
           and c.mas_pk_no = b.pk_no
           and d.src_item_pk_no = c.pk_no
           and e.package_id = d.package_id
           and (trunc(d.end_date) <= trunc(sysdate) and
               (pay_type = 'GOOGLEPLAY' and
               trunc(d.end_date) <= trunc(sysdate) or
               (pay_type <> 'GOOGLEPLAY')))
           and f."transaction_id" = d.pk_no
           and a.recurrent_type in
               (select x.pay_type
                  from acg_vendor_payment_mas x
                 where default_recurrent_type = 'R')
         group by b.serial_id,
                  b.mas_no,
                  a.card_expiry,
                  a.card_no,
                  a.card_type,
                  a.cvc2,
                  e.package_cat_id1,
                  c.package_id,
                  d.pk_no,
                  e.duration_by_month,
                  e.duration_by_day,
                  d.end_date,
                  a.recurrent_type;
      v_msg varchar2(1024);
    begin
      for i in c1 loop
        update bsm_client_details c
           set c.start_date = trunc(i.end_date + 1),
               c.end_date   = add_months(trunc(i.end_date + 1),
                                         i.duration_by_month) +
                              i.duration_by_day
         where c.pk_no = i.dtl_pk_no;
        commit;
        bsm_client_service.Set_subscription_r(null, i.serial_id, 'N');
        bsm_client_service.refresh_bsm_client(i.serial_id,
                                              queue_name_setting);
        v_msg := bsm_cdi_service.refresh_client(i.serial_id,
                                                queue_name_setting);
        dbms_lock.sleep(1);
      end loop;
    end;
    return null;
  end;

  function reset_recurrent_card(p_purchase_pk_no number,
                                p_card_no        varchar2,
                                p_expiry         varchar2,
                                p_cvc2           varchar2) return varchar2 is
    v_result         varchar2(1024);
    v_recurrent_type varchar2(32);
    v_serial_id      varchar2(1024);
    v_status_flg     varchar2(32);
  begin
    select recurrent_type, a.status_flg
      into v_recurrent_type, v_status_flg
      from bsm_recurrent_mas a
     where a.src_pk_no = p_purchase_pk_no;
    select serial_id
      into v_serial_id
      from bsm_purchase_mas a
     where a.pk_no = p_purchase_pk_no;
  
    if v_recurrent_type <> 'CREDIT' then
      if v_status_flg <> 'B' then
        v_result := BSM_LIPAY_GATEWAY.changeCreditCard(p_purchase_pk_no,
                                                       p_card_no,
                                                       p_expiry,
                                                       p_cvc2);
      else
        declare
          cursor c1 is
            Select b.serial_id,
                   b.mas_no purchase_id,
                   a.card_expiry,
                   bsm_encrypt.decrypt_Serial_ID(a.card_no,
                                                 b.serial_id ||
                                                 'tgc27740083') card_no,
                   a.card_type,
                   a.cvc2,
                   c.package_id,
                   trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                      b.serial_id)) max_end_date,
                   sum(nvl(a.amount, c.amount)) amount
              from bsm_recurrent_mas  a,
                   bsm_purchase_mas   b,
                   bsm_purchase_item  c,
                   bsm_client_details d,
                   bsm_package_mas    e
             where 1 = 1
               and b.mas_no = a.src_no
               and c.mas_pk_no = b.pk_no
               and d.src_item_pk_no = c.pk_no
               and e.package_id = c.package_id
               and e.recurrent = 'R'
               and b.pk_no = p_purchase_pk_no
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
            declare
              result            tbsm_result;
              in_bsm_purchase   tbsm_purchase;
              p_recurrent       varchar2(32);
              p_device_id       varchar2(32);
              parameter_options varchar2(32);
              p_sw_version      varchar2(32);
            begin
              in_bsm_purchase             := new tbsm_purchase();
              in_bsm_purchase.card_no     := p_card_no;
              in_bsm_purchase.card_expiry := p_expiry;
              in_bsm_purchase.cvc2        := p_cvc2;
              if substr(p_card_no, 1, 1) = '4' then
                in_bsm_purchase.card_type := 'VISA';
              else
                in_bsm_purchase.card_type := 'MASTER';
              end if;
              in_bsm_purchase.src_no    := 'BE' || i.purchase_id || '_' ||
                                           to_char(sysdate, 'YYYYMMDD');
              in_bsm_purchase.serial_id := i.serial_id;
              in_bsm_purchase.pay_type  := '信用卡';
              in_bsm_purchase.details   := new tbsm_purchase_dtls();
              in_bsm_purchase.details.extend(1);
              in_bsm_purchase.details(1) := new tbsm_purchase_dtl();
              in_bsm_purchase.details(1).offer_id := i.package_id;
              in_bsm_purchase.details(1).amount := i.amount;
              p_recurrent := 'R';
              p_sw_version := 'TRANSTOLIPAY_AUTO';
            
              result := bsm_client_service.crt_purchase(in_bsm_purchase   => in_bsm_purchase,
                                                        p_recurrent       => p_recurrent,
                                                        p_device_id       => p_device_id,
                                                        parameter_options => parameter_options,
                                                        p_sw_version      => p_sw_version);
              declare
                cursor c1 is
                  select pk_no
                    from bsm_purchase_mas
                   where src_no = in_bsm_purchase.src_no;
              begin
                for j in c1 loop
                  update bsm_recurrent_mas x
                     set x.amount = i.amount, x.last_modify_date = sysdate
                   where x.src_pk_no = j.pk_no;
                  commit;
                end loop;
              end;
            
            end;
          end loop;
        end;
      
      end if;
    else
      v_result := 'PRC=0';
    end if;
    if v_result = 'PRC=0' then
      update bsm_recurrent_mas a
         set a.card_no     = bsm_encrypt.Encrypt_Serial_ID(p_card_no,
                                                           v_serial_id ||
                                                           'sdsds'),
             a.card_expiry = p_expiry,
             a.cvc2        = p_cvc2,
             a.status_flg  = 'P'
       where a.src_pk_no = p_purchase_pk_no;
      commit;
    end if;
    return v_result;
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
               
               b.serial_id        client_id,
               a.rowid            pay_info_rid,
               a.pk_no,
               a.amount,
               a.status,
               a.newebpay_trad_id,
               c.package_name,
               c.package_cat1,
               c.price_desc
          from view_payment_info a,
               bsm_purchase_mas  b,
               bsm_purchase_item c,
               bsm_package_mas   d
         where a.status in ('ok', 'fail', 'retry', 'failure')
              --   and b.status_flg = 'Z'
           and b.mas_no = a.order_id
           and c.mas_pk_no = b.pk_no
           and d.package_id = c.package_id
              -- and d.recurrent = 'R'
           and a.order_id not in ('PUR20181000000152',
                                  'PUR20180500000264',
                                  'PUR20180500000296',
                                  'PUR20180500000329',
                                  'PUR20180500000254',
                                  'PUR20180500000255',
                                  'PUR20181000000152',
                                  'PUR20181000000288',
                                  'PUR20181000000290',
                                  'PUR20181000000296',
                                  'PUR20181000000285',
                                  'PUR20181000000284',
                                  'PUR20181000000289',
                                  'PUR20180500000264',
                                  'PUR20180500000296',
                                  'PUR20180500000329',
                                  'PUR20181000000178',
                                  'PUR20181000000272',
                                  'PUR20181000000152',
                                  'PUR20181000000284',
                                  'PUR20180500000255',
                                  'PUR20180900000175',
                                  'PUR20180900000188',
                                  'PUR20181000000277',
                                  'PUR20181000000284',
                                  'PUR20181000000289',
                                  'PUR20181000000151',
                                  'PUR20181000000151',
                                  'PUR20181000000151',
                                  'PUR20181000000277',
                                  'PUR20181000000285')
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
          update bsm_recurrent_mas a
             set a.recurrent_status = 'ok',
                 a.status_flg       = nvl(a.f_stop_rec, 'P'),
                 a.recurrent_s_date = sysdate,
                 a.last_modify_date = sysdate
           where a.src_no = i.order_id;
          commit;
        
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
              v_acc_name          varchar2(128);
              v_tax_code          varchar2(128);
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
                 v_tax_code,
                 v_recurrent,
                 'E',
                 p_sw_version,
                 i.amount,
                 add_months(v_purchase_date, 1)
                 --  v_purchase_date + 5
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
                 DEVICE_ID,
                 package_name,
                 package_cat1,
                 price_desc)
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
                 null,
                 i.package_name,
                 i.package_cat1,
                 i.price_desc);
            
              commit;
            
              declare
                v_msg number(16);
              begin
                v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                         v_purchase_pk_no);
                v_msg := bsm_purchase_post.purchase_complete_r(p_user_no,
                                                               v_purchase_pk_no,
                                                               'N');
              end;
            
              update bsm_purchase_mas a
                 set a.lipay_tx_number = nvl(i.newebpay_trad_id, i.tx_number),
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
                  bsm_client_service.Set_subscription_r(v_purchase_pk_no,
                                                        v_client_id,
                                                        'N');
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
          update bsm_recurrent_mas a
             set a.recurrent_status = 'ok',
                 -- a.status_flg ='P',
                 a.recurrent_s_date = sysdate,
                 a.last_modify_date = sysdate
           where a.src_no = i.order_id;
        
          commit;
        elsif i.status = 'retry' then
          update bsm_recurrent_mas a
             set a.recurrent_status = 'retry', a.recurrent_s_date = sysdate
           where a.src_no = i.order_id;
        
          update view_payment_info
             set process_flg = 'Y'
           where rowid = i.pay_info_rid;
        
          bsm_client_service.Set_subscription_r(null, i.client_id, 'N');
          commit;
        
        elsif i.status = 'fail' then
          update bsm_recurrent_mas a
             set status_flg         = 'B',
                 a.end_date         = sysdate,
                 a.recurrent_status = 'fail',
                 a.remark           = 'LiPay中止',
                 a.last_modify_date = sysdate,
                 a.stop_date        = sysdate
          
           where a.src_no = i.order_id;
        
          update view_payment_info
             set process_flg = 'Y'
           where rowid = i.pay_info_rid;
          commit;
        elsif i.status = 'failure' then
          update bsm_recurrent_mas a
             set a.next_bill_date   = trunc(sysdate + 2),
                 a.last_modify_date = sysdate,
                 a.recurrent_status = 'retry'
           where a.src_no = i.order_id;
        
          update view_payment_info
             set process_flg = 'Y'
           where rowid = i.pay_info_rid;
          commit;
        end if;
      
        bsm_client_service.refresh_bsm_client(v_client_id,
                                              queue_name_setting);
        v_msg := bsm_cdi_service.refresh_client(v_client_id,
                                                queue_name_setting);
        -- dbms_lock.sleep(6);
      
      end loop;
    end;
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no purchase_id,
               a.card_expiry,
               a.card_type,
               a.cvc2,
               c.package_id,
               trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                  b.serial_id)) max_end_date
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
           and e.recurrent = 'R'
           and trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                  b.serial_id)) <=
               sysdate
           and d.end_date < sysdate
           and a.recurrent_type = 'LiPay';
    begin
      for i in c1 loop
        dbms_output.put_line(i.serial_id);
        -- 已服務過期註銷
        if i.max_end_date + 10 < trunc(sysdate) then
          -- recurrent 註記成關閉
          update bsm_recurrent_mas a
             set -- a.recurrent_status = 'B',
                 -- a.recurrent_s_date = sysdate,
                   a.last_modify_date = sysdate,
                 a.status_flg       = 'B',
                 a.remark           = '系統關閉'
           where a.src_no = i.purchase_id;
          commit;
          dbms_output.put_line(i.serial_id || ':Expired');
        
          bsm_purchase_post.refresh_bsm_client(i.serial_id);
        elsif i.max_end_date <= trunc(sysdate) then
          -- recurrent 註記成警告期
          /*  update bsm_recurrent_mas a
             set a.recurrent_status = 'A', a.recurrent_s_date = sysdate
           where a.src_no = i.purchase_id;
          commit; */
          null;
        end if;
        dbms_lock.sleep(6);
      end loop;
    end;
    return null;
  end;

  function dup_recurrent return varchar2 is
    v_result varchar2(1024);
  begin
    declare
      cursor c1 is
        Select b.serial_id,
               b.mas_no purchase_id,
               a.card_expiry,
               trunc(bsm_encrypt.decrypt_Serial_ID(a.card_no,
                                                   b.serial_id ||
                                                   'tgc27740083')) card_no,
               a.card_type,
               a.cvc2,
               c.package_id,
               trunc(bsm_recurrent_util.get_service_end_date_full(e.package_cat_id1,
                                                                  b.serial_id)) max_end_date,
               b.amount
          from bsm_recurrent_mas a,
               bsm_purchase_mas b,
               table(bsm_purchase_dtls(b.pk_no)) c,
               bsm_package_mas e
         where a.status_flg = 'P'
           and b.status_flg = 'Z'
           and b.mas_no = a.src_no
           and c.mas_pk_no = b.pk_no
           and e.package_id = c.cup_package_id
         group by b.serial_id,
                  b.mas_no,
                  a.card_expiry,
                  a.card_no,
                  a.card_type,
                  a.cvc2,
                  e.package_cat_id1,
                  c.package_id,
                  b.amount;
      cursor c2(p_mas_no varchar2) is
        Select c.client_id,
               b.mas_no purchase_id,
               a.card_expiry,
               trunc(bsm_encrypt.decrypt_Serial_ID(a.card_no,
                                                   b.serial_id ||
                                                   'tgc27740083')) card_no,
               a.card_type,
               a.cvc2,
               c.cup_package_id,
               c.amt,
               c.item_no
        
          from bsm_recurrent_mas a,
               bsm_purchase_mas b,
               table(bsm_purchase_dtls(b.pk_no)) c,
               bsm_package_mas e
         where a.status_flg = 'P'
           and b.status_flg = 'Z'
           and b.mas_no = a.src_no
           and c.mas_pk_no = b.pk_no
           and e.package_id = c.cup_package_id
           and c.client_id not like '_CLIENT%'
           and b.mas_no = p_mas_no;
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
      v_reponse             varchar2(1024);
      v_service_start_date  date;
      v_service_end_date    date;
    
    begin
      for i in c1 loop
        -- 已服務過期註銷
        if i.max_end_date < trunc(sysdate) - 1 then
          v_msg     := bsm_recurrent_util.stop_recurrent(i.serial_id,
                                                         i.purchase_id,
                                                         '服務到期');
          v_reponse := null;
        elsif i.card_expiry < to_char(sysdate, 'yyyymm') then
          v_msg     := bsm_recurrent_util.stop_recurrent(i.serial_id,
                                                         i.purchase_id,
                                                         '信用卡');
          v_reponse := null;
        else
        
          -- 先刷卡
          v_reponse := bsm_payment_gateway.AccePayment(0,
                                                       i.amount,
                                                       i.card_type,
                                                       i.card_no,
                                                       i.card_expiry,
                                                       i.cvc2);
        end if;
        v_service_start_date := null;
        v_service_end_date   := null;
      
        if v_reponse like 'PRC=0%' then
        
          for j in c2(i.purchase_ID) loop
            v_client_id  := j.client_id;
            v_package_id := j.cup_package_id;
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
              v_purchase_date := sysdate;
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
                 amount)
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
                 j.amt);
            
              --
              --  計算價格
              --
              v_id := j.cup_package_id;
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
            
              v_Price := j.amt;
            
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
            
              declare
                v_msg number(16);
              begin
                v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                         v_purchase_pk_no);
                v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                             v_purchase_pk_no);
              end;
            
            end;
          
            begin
              if v_service_start_date is null then
                select min(start_date), max(end_date)
                  into v_service_start_date, v_service_end_date
                  from bsm_client_details a
                 where a.src_pk_no = v_purchase_pk_no;
              else
                update bsm_client_details a
                   set start_date = v_service_start_date,
                       end_date   = v_service_end_date
                 where a.src_pk_no = v_purchase_pk_no;
                commit;
              end if;
            end;
          
            -- 發票開立
            if j.amt > 0 then
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
              
              end;
            end if;
          end loop;
          bsm_client_service.refresh_bsm_client(v_client_id);
        end if;
      
      end loop;
    end;
  
    return null;
  end;

  function auto_recurrent_org return varchar2 is
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
           and e.recurrent = 'R'
           and trunc(get_service_end_date_full(e.package_cat_id1,
                                               b.serial_id)) + 1 <
               sysdate + 3
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
              in_bsm_purchase.src_no      := 'BE' || i.purchase_id || '_' ||
                                             to_char(sysdate, 'YYYYMMDD');
              in_bsm_purchase.serial_id   := i.serial_id;
              in_bsm_purchase.pay_type    := '信用卡';
              in_bsm_purchase.details     := new tbsm_purchase_dtls();
              in_bsm_purchase.details.extend(1);
              in_bsm_purchase.details(1) := new tbsm_purchase_dtl();
              in_bsm_purchase.details(1).offer_id := i.package_id;
              in_bsm_purchase.details(1).amount := i.amount;
              p_recurrent := 'R';
              p_sw_version := 'TRANSTOLIPAY_AUTO';
            
              result := bsm_client_service.crt_purchase(in_bsm_purchase   => in_bsm_purchase,
                                                        p_recurrent       => p_recurrent,
                                                        p_device_id       => p_device_id,
                                                        parameter_options => parameter_options,
                                                        p_sw_version      => p_sw_version);
              if result.result_code = 'BSM-00000' then
                -- recurrent 成功註記回正常
                update bsm_recurrent_mas a
                   set a.recurrent_status = 'N',
                       a.recurrent_s_date = sysdate,
                       a.status_flg       = 'B',
                       a.remark           = '客戶移轉'
                
                 where a.src_no = i.purchase_id;
                commit;
              else
                -- recurrent 失敗註記成扣款期
                declare
                  v_c varchar2(10);
                begin
                  v_c := lpad(to_char(trunc(i.max_end_date) -
                                      trunc(sysdate)),
                              1,
                              '0');
                
                  update bsm_recurrent_mas a
                     set a.recurrent_status = 'C' || v_c,
                         a.recurrent_s_date = sysdate,
                         a.next_bill_date   = sysdate + 1
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

end;
/

