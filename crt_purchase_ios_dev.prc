create or replace procedure iptv.crt_purchase_ios_dev(p_paytype          varchar2,
                                             p_client_id        varchar2,
                                             p_device_id        varchar2,
                                             p_package_id       varchar2,
                                             p_ios_org_trans_id varchar2,
                                             p_ios_trans_id     varchar2,
                                             p_pk_no            number,
                                             p_mas_no           in out varchar2,
                                             p_purchase_date    varchar2,
                                             p_expires_date     varchar2,
                                             is_intro_offer     varchar2 default null,
                                             sw_version         varchar2 default null,
                                             p_options          varchar2 default null,
                                             from_client        varchar2 default null) is
  v_char            varchar2(32);
  v_src_mas_no      varchar2(32);
  purchase_pk_no    number(16);
  v_r_pk_no         number(16);
  intro_offer       number(16);
  intro_offer_desc  varchar2(32);
  org_client_id     varchar2(32);
  org_purchase_date date;
  org_package_id    varchar2(32);
  v_method          varchar2(32);
  v_package_id      varchar2(64);
  v_no_org          varchar2(2);
  v_loc_exp_date    date;
  v_loc_pur_date    date;
  ios_package_error exception;
  v_software_group  varchar2(32);
    v_Price               number(16);

begin

  begin
    select 'x',software_group 
      into v_char,v_software_group
      from bsm_purchase_mas a
     where a.ios_trans_id = p_ios_trans_id
       and status_flg in ('Z', 'P', 'A')
       and rownum <= 1;
    if v_software_group is null then
      update bsm_purchase_mas a
        set software_group = substr(sw_version,1,7)
      where a.ios_trans_id = p_ios_trans_id;
      commit;
    end if;
         
  exception
    when no_data_found then
      v_method := 'create';
  end;

  begin
    select a.mas_no, a.mas_no,b.pk_no
      into v_src_mas_no, p_mas_no,v_r_pk_no
      from bsm_purchase_mas a, bsm_recurrent_mas b
     where a.status_flg = 'Z'
       and a.src_no = p_ios_org_trans_id
       and a.serial_id = p_client_id
       and b.src_no = a.mas_no
       and b.status_flg in ( 'P','B')
       and rownum <= 1;
     update bsm_recurrent_mas c
       set c.status_flg='P'
     where c.pk_no = v_r_pk_no;
     commit;
    v_no_org := 'N';
  exception
    when no_data_found then
      v_no_org := 'Y';
  end;

  v_loc_pur_date := to_date(substr(p_purchase_date, 1, 19),
                            'YYYY-MM-DD HH24:MI:SS') + 8 / 24;
  v_loc_exp_date := to_date(substr(p_expires_date, 1, 19),
                            'YYYY-MM-DD HH24:MI:SS') + 8 / 24;

  if p_package_id is not null then
    v_package_id := p_package_id;
    declare
      v_id varchar2(32);
    begin
      select package_id, intro_offer, intro_offer_desc,a.price
        into v_id, intro_offer, intro_offer_desc,  v_Price
        from BSM_IOS_PRODUCT_MAP a
       where a.ios_product_code = v_package_id;
      v_package_id := v_id;
    exception
      when no_data_found then
        /*     insert into BSM_IOS_PRODUCT_MAP
          (ios_product_code)
        values
          (v_package_id);
        commit;
        dbms_output.put_line(v_package_id); */
        raise ios_package_error;
    end;
  
  else
    declare
      v_ios_product_code varchar2(128);
    begin
      select package_id, ios_product_code
        into v_package_id, v_ios_product_code
        from bsm_ios_receipt_mas t
       where t.mas_pk_no = p_pk_no
         and rownum <= 1;
    
      if v_package_id is null or v_package_id = '' then
        begin
          select package_id,price
            into v_package_id,v_price
            from BSM_IOS_PRODUCT_MAP a
           where a.ios_product_code = v_ios_product_code
             and rownum <= 1;
        exception
          when no_data_found then
            dbms_output.put_line(v_ios_product_code);
            raise ios_package_error;
        end;
      end if;
    
    exception
      when no_data_found then
        null;
    end;
  end if;
  if v_loc_pur_date >= to_date('2011/08/01', 'YYYY/MM/DD') then
  
    if v_method = 'create' then
    
      declare
        v_Purchase_Pk_No      number(16) := p_pk_no;
        v_purchase_item_pk_no number(16);
        v_purchase_no         varchar2(32);
        v_acc_invo_no         varchar2(32);
        v_pay_type            varchar2(32) := 'IOS';
        v_acc_name            varchar2(32);
        v_tax_code            varchar2(32);
        v_Purchase_Mas_Code   varchar(32) := 'BSMPUR';
        v_Serial_No           number(16);
        v_id                  varchar2(32) := v_package_id;
      
        v_Duration            number(16);
        v_Quota               number(16);
        v_charge_type         varchar2(32);
        v_charge_code         varchar2(32);
        v_client_id           varchar(32) := p_client_id;
        v_device_id           varchar2(32) := p_device_id;
        v_mas_no              varchar2(32) := p_ios_org_trans_id;
        p_user_no             number(16) := 0;
        v_charge_name         varchar2(32);
        v_recurrent_pk_no     number(16) := 0;
      
      begin
        if v_no_org = 'Y' then
          declare
            cursor c1 is
              select b.rowid rid, b.client_id
                from bsm_purchase_mas a, bsm_recurrent_mas b
               where b.src_pk_no = a.pk_no
                 and a.src_no = p_ios_org_trans_id
                 and b.status_flg = 'P';
          begin
            for i in c1 loop
              update bsm_recurrent_mas a
                 set a.status_flg = 'N',
                     a.stop_recurrent_date=sysdate,
                     a.stop_date=sysdate
               where rowid = i.rid;
              commit;
              bsm_client_service.refresh_bsm_client(i.client_id);
            end loop;
          end;
        end if;
        if v_no_org = 'Y' then
          v_mas_no := p_ios_org_trans_id;
        else
          v_mas_no := 'RE' || v_src_mas_no || '_' ||
                      to_char(sysdate, 'YYMMDD');
        end if;
        if v_Purchase_Pk_No is null then
          Select Seq_Bsm_Purchase_Pk_No.Nextval
            Into v_Purchase_Pk_No
            From Dual;
        
        end if;
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
           ios_trans_id,
           ios_org_trans_id,
           software_group--,
         --  options
         )
        Values
          (v_mas_no,
           v_Purchase_Pk_No,
           v_Purchase_No,
           Sysdate,
           v_Purchase_Mas_Code,
           Null,
           Null,
           v_Serial_No,
           null,
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
           'R',
           'S',
           p_ios_trans_id,
           p_ios_org_trans_id,
           substr(sw_version,1,7) --,
          -- p_options
          );
      
        --
        --  計算價格
        --
      
        Begin
          Select nvl(v_price,a.Charge_Amount),
                 a.Acl_Duration,
                 a.Acl_Quota,
                 a.charge_type,
                 a.charge_code
            Into v_Price, v_Duration, v_Quota, v_charge_type, v_charge_code
            From Bsm_Package_Mas a
           Where a.Package_id = v_id;
        
        End;
      
        if is_intro_offer = 'true' then
          v_Price := nvl(intro_offer, v_Price);
        end if;
      
        Select Seq_Bsm_Purchase_Pk_No.Nextval
          Into v_Purchase_Item_Pk_No
          From Dual;
      
        v_charge_code := 'PMONTHFEE';
        v_charge_name := '預付月租費';
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
           v_Price,
           v_Price,
           v_Duration,
           v_charge_type,
           v_charge_code,
           v_charge_name,
           0,
           0,
           v_Price,
           v_device_id);
        update Bsm_Purchase_Mas x
           set x.total_amt = v_Price, x.amount = v_Price
         where pk_no = v_Purchase_Pk_No;
      
        begin
          Select Seq_Bsm_Purchase_Pk_No.Nextval
          
            Into v_recurrent_pk_no
            from dual;
        
          if v_no_org = 'Y' then
            insert into bsm_recurrent_mas
              (pk_no,
               recurrent_type,
               create_date,
               create_user,
               src_pk_no,
               src_no,
               card_no,
               card_type,
               card_expiry,
               cvc2,
               start_date,
               status_flg,
               client_id,
               cht_subno,
               cht_auth,
               cht_otpw,
               cht_action_date,
               ordernumber,
               amount,
               dump_status)
            values
              (v_recurrent_pk_no,
               'IOS',
               sysdate,
               0,
               v_Purchase_Pk_No,
               v_Purchase_No,
               NULL,
               NULL,
               NULL,
               NULL,
               sysdate,
               'P',
               p_client_id,
               NULL,
               NULL,
               NULL,
               sysdate,
               null,
               v_price,
               'A');
            commit;
          else
            null;
          end if;
        end;
      
        declare
          v_msg       number(16);
          v_pur_pk_no varchar2(128);
        begin
          v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                   v_purchase_pk_no);
          commit;
          begin
            v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                         v_purchase_pk_no);
          exception
            when others then
              dbms_output.put_line(v_Purchase_No);
          end;
          commit;
        
          update bsm_client_details a
             set a.start_date = v_loc_pur_date, a.end_date = v_loc_exp_date
           where a.src_pk_no = v_purchase_pk_no;
          update bsm_purchase_mas
             set purchase_date = v_loc_pur_date
           where pk_no = v_purchase_pk_no;
          commit;
          commit;
          v_pur_pk_no := to_char(v_purchase_pk_no);
          bsm_client_service.Set_subscription(v_purchase_pk_no,
                                              v_client_Id);
        
        end;
      
        p_mas_no := v_Purchase_No;
        declare
          v_enqueue_options    dbms_aq.enqueue_options_t;
          v_message_properties dbms_aq.message_properties_t;
          v_message_handle     raw(16);
          v_payload            purchase_msg_type;
        begin
          v_payload := purchase_msg_type(v_client_Id,
                                         v_Purchase_Pk_No,
                                         v_Purchase_No,
                                         'refresh_bsm');
          dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                          enqueue_options    => v_enqueue_options,
                          message_properties => v_message_properties,
                          payload            => v_payload,
                          msgid              => v_message_handle);
          commit;
        end;
        -- bsm_client_service.refresh_bsm_client(v_client_Id);
      end;
    
    end if;
  end if;
exception
  when ios_package_error then
    null;
end;
/

