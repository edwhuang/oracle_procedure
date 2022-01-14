create or replace procedure iptv.crt_purchase_3(p_paytype    varchar2,
                                         p_client_id  varchar2,
                                         p_device_id  varchar2,
                                         p_package_id varchar2,
                                         p_src_no     varchar2,
                                         p_pk_no      number,
                                         p_mas_no     varchar2) is
  v_char            varchar2(32);
  purchase_pk_no    number(16);
  org_client_id     varchar2(32);
  org_purchase_date date;
  v_method          varchar2(32);
  v_package_id      varchar2(64);

begin
  begin
    select pk_no, a.serial_id, a.purchase_date
      into purchase_pk_no, org_client_id, org_purchase_date
      from bsm_purchase_mas a
     where status_flg = 'Z'
       and src_no = p_src_no
       and pay_type = 'IOS'
       and rownum <= 1
     order by purchase_date desc;
    if org_purchase_date < sysdate - 15 then
      v_method := 'create';
    end if;
  exception
    when no_data_found then
      v_method := 'create';
  end;
  if p_package_id is not null and p_package_id <> '' then
    v_package_id := p_package_id;
  else
    declare
       v_ios_product_code varchar2(128);
    begin
      select package_id,ios_product_code into v_package_id,v_ios_product_code
      from bsm_ios_receipt_mas t
      where t.mas_pk_no = p_pk_no and rownum <=1;
      
      if v_package_id is null or v_package_id = '' then
        begin
          select package_id into v_package_id from bsm_package_mas a where a.ios_product_code=v_ios_product_code and rownum <=1;
        exception 
          when no_data_found then null;
        end;
      end if;
      
    exception
      when no_data_found then 
        null;
    end;
  end if;
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
      v_Price               number(16);
      v_Duration            number(16);
      v_Quota               number(16);
      v_charge_type         varchar2(32);
      v_charge_code         varchar2(32);
      v_client_id           varchar(32) := p_client_id;
      v_device_id           varchar2(32) := p_device_id;
      v_mas_no              varchar2(32) := p_src_no;
      p_user_no             number(16) := 0;
      v_charge_name         varchar2(32);
      v_recurrent_pk_no     number(16) := 0;
    
    begin
    
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
         'S');
    
      --
      --  計算價格
      --
    
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
      end;
    
      declare
        v_msg number(16);
      begin
        v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                 v_purchase_pk_no);
        v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                     v_purchase_pk_no);
      end;
    end;
  end if;

end;
/

