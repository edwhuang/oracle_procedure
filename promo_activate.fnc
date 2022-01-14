create or replace function iptv.promo_activate(promo_code varchar2,
                                          client_id  varchar2,
                                          device_id  varchar2,
                                          p_software_group varchar default null)
  return varchar2 is
begin
  if instr(promo_code, 'promo_') > 0 then
    declare
      v_enqueue_options    dbms_aq.enqueue_options_t;
      v_message_properties dbms_aq.message_properties_t;
      v_message_handle     raw(16);
      v_payload            purchase_msg_type;
    begin
      v_payload := purchase_msg_type(client_id, 0, p_software_group, promo_code);
      dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                      enqueue_options    => v_enqueue_options,
                      message_properties => v_message_properties,
                      payload            => v_payload,
                      msgid              => v_message_handle);
      commit;
    end;
    return null;
  else
    declare
    
      -- 贈送HiKids 一個月
      p_src_prog_no     varchar2(32) := 'CH_TRAIL';
      p_gift_package_id varchar2(32) := 'CHG003';
    
      v_purchase_item_pk_no number(16);
      v_charge_name         varchar2(32);
      v_char                varchar2(32);
      v_src_no              varchar2(32);
      v_device_id           varchar2(32) := device_id;
      v_result              varchar2(32);
      v_exp_date            date;
      p_promo_code           varchar2(32);
    
    begin
      p_promo_code:='CHTRY_7DAY';
      if client_id like 'F%' then
        p_src_prog_no     := 'CH_4GTV_TRIAL';
        p_gift_package_id := 'CH4G06';
        p_promo_code:=null;
      end if;
      if promo_code = 'CH_4GTV_TRIAL' then
        p_src_prog_no     := 'CH_4GTV_TRIAL';
        p_gift_package_id := 'CH4G06';
        p_promo_code:=null;
      end if;
    
      if promo_code = 'ASUS_CHANNEL' then
        p_gift_package_id := 'WDG002';
        p_promo_code:=null;
      end if;
      v_result := 'S';
      begin
        select 'x'
          into v_char
          from bsm_client_mas
         where mac_address = client_id;
        --  for update;
      exception
        when no_data_found then
          declare
            -- Boolean parameters are translated from/to integers: 
            -- 0/1/null <--> false/true/null 
          
            -- Non-scalar parameters require additional processing 
            result         tbsm_result;
            in_client_info tbsm_client_info;
          begin
            in_client_info             := new tbsm_client_info();
            in_client_info.owner_phone := '0999000000';
            in_client_info.serial_id   := client_id;
            in_client_info.mac_address := device_id;
            -- Call the function
            result := bsm_client_service.check_and_register_client(in_client_info  => in_client_info,
                                                                   activation_code => null,
                                                                   send_passcode   => false);
          end;
      end;
    
      -- lock bsm_client_mas
      -- select 'x' into v_char from bsm_client_mas where mac_address = client_id for update nowait;
      begin
        select x.end_date
          into v_exp_date
          from bsm_client_details x
         where x.status_flg = 'P'
           and rownum <= 1
           and x.src_no in
               (select mas_no
                  from bsm_purchase_mas y
                 where y.src_no = client_id || '_' || p_src_prog_no);
      
        if v_exp_date <= sysdate then
          v_result := 'E'; -- expired;
          return v_result;
        else
          v_result := 'D';
          return v_result;
        end if;
      
      exception
        when no_data_found then
        
          -- create purchase
          declare
            v_Purchase_Pk_No    number(16);
            v_purchase_no       varchar2(32);
            v_acc_invo_no       varchar2(32);
            v_pay_type          varchar2(32) := '贈送';
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
            v_client_id         varchar(32) := client_id;
            v_mas_no            varchar2(32) := client_id || '_' ||
                                                promo_code;
            p_user_no           number(16) := 0;
          
          begin
            v_Client_Info := bsm_client_service.Get_Client_Info(v_client_id);
            --      dbms_output.put_line(v_client_info.mac_address);
            v_Serial_No := v_client_info.serial_no;
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
               start_type,
               promo_code)
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
               'A',
               p_promo_code);
          
            --
            --  計算價格
            --
            v_id := p_gift_package_id;
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
            
            End;
          
            Select Seq_Bsm_Purchase_Pk_No.Nextval
              Into v_Purchase_Item_Pk_No
              From Dual;
          
            if v_charge_code is null then
              v_charge_code := 'PMONTHFEE';
            end if;
          
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
               0,
               0,
               v_Duration,
               v_charge_type,
               v_charge_code,
               v_charge_name,
               0,
               0,
               0,
               v_device_id);
          
            declare
              v_msg   number(16);
              v_msg_a varchar2(2048);
            begin
              v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                       v_purchase_pk_no);
              v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                           v_purchase_pk_no);
            
              v_msg_a := bsm_cdi_service.refresh_client(v_client_Id);
            end;
          
          end;
          commit;
          return v_result;
      end;
    exception
      when no_data_found then
        null;
        return v_result;
    end;
  end if;

end;
/

