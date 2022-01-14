create or replace procedure iptv.P_W00001_PROCESS( CLIENT_ID varchar2,purchase_id varchar2) is
begin
  /*
   declare

    -- 贈送HiKids 一個月
    p_src_prog_no     varchar2(32) := 'W00001_GIFT';
    p_gift_package_id varchar2(32) := 'WG0002';

    v_purchase_item_pk_no number(16);
    v_charge_name         varchar2(32);
    v_char varchar2(32);
    v_src_no varchar2(32);
    v_device_id varchar2(32);

  begin
    -- lock bsm_client_mas
    select 'x' into v_char from bsm_client_mas where mac_address = client_id for update;
    
    select max(b.device_id) into v_device_id from bsm_purchase_mas a,bsm_purchase_item b where a.mas_no=purchase_id and b.mas_pk_no=a.pk_no;

    select a.serial_id
      into v_src_no
    from bsm_client_details a,bsm_purchase_mas b 
      where package_id='W00001' and
      a.src_no = purchase_id and
      a.serial_id=client_id and
      a.status_flg='P' and
      b.mas_no=a.src_no and
      b.recurrent='R' and
      not exists(select 'x' from bsm_client_details x where x.status_flg='P' and x.src_no in (select mas_no from bsm_purchase_mas y where y.src_no= a.serial_id||'_GIFT'));

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
        v_mas_no            varchar2(32) := v_src_no||'_GIFT';
        p_user_no           number(16) := 0;

      begin
        v_Client_Info := bsm_client_service.Get_Client_Info(v_client_id);
        dbms_output.put_line(v_client_info.mac_address);
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
           tax_code)
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
           null);

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
            Into v_Price, v_Duration, v_Quota, v_charge_type, v_charge_code
            From Bsm_Package_Mas a
           Where a.Package_id = v_id;

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
          v_msg number(16);
        begin
          v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                   v_purchase_pk_no);
          v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                       v_purchase_pk_no);
        end;

      end;
      commit;
      exception
        when no_data_found then null;
  end;
  
  declare

    -- 贈送HiKids 一個月
    p_src_prog_no     varchar2(32) := 'CH0001_GIFT';
    p_gift_package_id varchar2(32) := 'CHG001';

    v_purchase_item_pk_no number(16);
    v_charge_name         varchar2(32);
    v_char varchar2(32);
    v_src_no varchar2(32);
    v_device_id varchar2(32);

  begin
    -- lock bsm_client_mas
    select 'x' into v_char from bsm_client_mas where mac_address = client_id for update;
    
    select max(b.device_id) into v_device_id from bsm_purchase_mas a,bsm_purchase_item b where a.mas_no=purchase_id and b.mas_pk_no=a.pk_no;

    select a.serial_id||'_CH_'
      into v_src_no
    from bsm_client_details a,bsm_purchase_mas b 
      where package_id='CH0001' and
      a.src_no = purchase_id and
      a.serial_id=client_id and
      a.status_flg='P' and
      b.mas_no=a.src_no and
      b.recurrent='R' and
      not exists(select 'x' from bsm_client_details x where x.status_flg='P' and x.src_no in (select mas_no from bsm_purchase_mas y where y.src_no= a.serial_id||'_CH_'||'_GIFT'));

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
        v_mas_no            varchar2(32) := v_src_no||'_GIFT';
        p_user_no           number(16) := 0;

      begin
        v_Client_Info := bsm_client_service.Get_Client_Info(v_client_id);
        dbms_output.put_line(v_client_info.mac_address);
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
           tax_code)
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
           null);

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
            Into v_Price, v_Duration, v_Quota, v_charge_type, v_charge_code
            From Bsm_Package_Mas a
           Where a.Package_id = v_id;

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
          v_msg number(16);
        begin
          v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                   v_purchase_pk_no);
          v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                       v_purchase_pk_no);
        end;

      end;
      commit;
      exception
        when no_data_found then null;
  end;
*/ 
null;
end P_W00001_PROCESS;
/

