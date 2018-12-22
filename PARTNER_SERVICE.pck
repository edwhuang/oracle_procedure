CREATE OR REPLACE PACKAGE PARTNER_SERVICE is
  lost_data       exception;
  order_not_found exception;
  no_client_found exception;
  dup_order       exception;
  function PARTNER_ORDER_SERVICE(p_order             varchaR2,
                                 p_start_form_active varchar2 default null)
    return varchar2;
END PARTNER_SERVICE;
/
CREATE OR REPLACE PACKAGE BODY PARTNER_SERVICE is
  function PARTNER_ORDER_SERVICE(p_order             varchar2,
                                 p_start_form_active varchar2 default null)
    return varchar2 is
    v_result         varchar2(1024);
    v_vendor         varchar2(32);
    v_action         varchar2(23);
    v_mobile         varchar2(32);
    v_client_id      varchar2(32);
    v_name           varchar2(32);
    v_email          varchar2(512);
    v_order_id       varchar2(32);
    v_order_date     date;
    v_software_group varchar2(32);
    v_package_id     varchar2(32);
    v_price          number(16);
    v_pay_amount     number(16);
    v_device_id      varchar2(32);
    v_action_date    date;
    v_expire_date    date;
    v_order_pk_no    number(16);
    v_order_pre_fix  varchar2(32);
    v_cancel_date    date;
  
    j_order          json;
    v_id             varchar2(32);
    v_Purchase_No    varchar2(32);
    v_Purchase_Pk_No number(16, 3);
    v_amt            number(16, 3);
    v_msg            varchar2(1024);
  begin
    /* insert into temp_data (p_date, p_data) values (sysdate, p_order);
    commit; */
    begin
      j_order := new JSON(p_order);
    
      begin
        v_action := json_ext.get_string(j_order, 'action');
      exception
        when others then
          v_action := '';
      end;
    
      begin
        v_vendor := json_ext.get_string(j_order, 'vendor');
        if v_vendor is not null then
          v_order_pre_fix := upper(v_vendor);
        else
          v_order_pre_fix := 'PARNET';
        end if;
      exception
        when others then
          v_vendor        := '';
          v_order_pre_fix := 'PARNET';
      end;
    
      begin
        v_mobile := json_ext.get_string(j_order, 'mobile');
      exception
        when others then
          v_mobile := '';
      end;
    
      begin
        v_client_id := json_ext.get_string(j_order, 'client_id');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_package_id := json_ext.get_string(j_order, 'package_id');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_name := json_ext.get_string(j_order, 'name');
      exception
        when others then
          v_name := '';
      end;
    
      begin
        v_email := json_ext.get_string(j_order, 'email');
      exception
        when others then
          v_email := '';
      end;
    
      begin
        v_order_id := json_ext.get_string(j_order, 'order_id');
      exception
        when others then
          v_order_id := '';
      end;
      begin
        v_order_date := to_date(json_ext.get_string(j_order, 'order_date'),
                                'YYYY/MM/DD HH24:MI:SS') + (8 / 24);
      exception
        when others then
          v_order_date := null;
      end;
    
      begin
        v_cancel_date := to_date(json_ext.get_string(j_order, 'cancel_date'),
                                 'YYYY/MM/DD HH24:MI:SS') + (8 / 24);
      exception
        when others then
          v_cancel_date := null;
      end;
      
      begin
        v_expire_date := to_date(json_ext.get_string(j_order, 'expire_date'),
                                 'YYYY/MM/DD HH24:MI:SS') + (8 / 24);
      exception
        when others then
          v_expire_date := null;
      end;
      
      begin
        v_software_group := json_ext.get_string(j_order, 'software_group');
      exception
        when others then
          v_software_group := 'LTBND00';
      end;
    
      begin
        v_device_id := json_ext.get_string(j_order, 'device_id');
      exception
        when others then
          v_device_id := '';
      end;
    
      begin
        v_action_date := to_date(json_ext.get_string(j_order, 'action_date'),
                                 'YYYY/MM/DD HH24:MI:SS') + (8 / 24);
      exception
        when others then
          v_action_date := null;
      end;
    
      begin
        v_amt := json_ext.get_number(j_order, 'pay_amount');
      
      exception
        when others then
          v_amt := 0;
      end;
    
    end;
    if v_action = 'create' then
      begin
        select a.mas_no, a.pk_no
          into v_Purchase_No, v_purchase_pk_no
          from bsm_purchase_mas a
         where a.src_no = v_order_pre_fix || v_order_id
           and rownum <= 1;
        raise dup_order;
      exception
        when no_data_found then
          null;
      end;
    
      begin
        select serial_id
          into v_client_id
          from bsm_client_mas a
         where a.serial_id = v_client_id
           and serial_id like '2A%'
           and status_flg = 'A'
           and rownum <= 1;
      exception
        when no_data_found then
        
          begin
            select serial_id
              into v_client_id
              from bsm_client_mas a
             where a.owner_phone = v_mobile
               and serial_id like '2A%'
               and status_flg = 'A'
               and rownum <= 1;
          exception
            when no_data_found then
              if v_client_id is not null then
                declare
                  -- Non-scalar parameters require additional processing 
                  result         tbsm_result;
                  in_client_info tbsm_client_info;
                  v_result       Tbsm_Result;
                begin
                  -- Call the function
                  in_client_info             := new tbsm_client_info();
                  in_client_info.Owner_Phone := v_mobile;
                  in_client_info.Serial_ID   := v_client_id;
                  in_client_info.MAC_Address := v_device_id;
                  v_result                   := bsm_client_service.activate_client(in_client_info    => in_client_info,
                                                                                   parameter_options => null);
                end;
              end if;
          end;
      end;
    
      if v_client_id is null then
        declare
          v_char varchar2(32);
        begin
          select 'x'
            into v_char
            from parent_order
           where src_order_id = v_order_pre_fix || v_order_id
             and rownum <= 1;
          -- raise dup_order;
        exception
          when no_data_found then
            Select Seq_Bsm_Purchase_Pk_No.Nextval
              Into v_order_pk_no
              From Dual;
            insert into parent_order
              (pk_no,
               src_id,
               vendor_id,
               src_order_id,
               order_date,
               action,
               scvid,
               orderid,
               contractid,
               msisdn,
               msisdnnew,
               orderdate,
               isfirst,
               reqcreatetime,
               status_flg,
               order_DATA,
               amt)
            values
              (v_order_pk_no,
               v_order_pre_fix || v_order_id,
               v_vendor,
               v_order_pre_fix || v_order_id,
               v_order_date,
               v_action,
               v_package_id,
               v_order_id,
               v_order_id,
               v_mobile,
               v_mobile,
               v_order_date,
               null,
               sysdate,
               'A',
               p_order,
               v_amt);
            commit;
        end;
        declare
          v_start_date varchar2(32);
          v_end_date   varchar2(32);
          v_d_day      number(16);
          v_months     number(16);
        begin
          select nvl(a.duration_by_month, 0),
                 decode(a.duration_by_day, 395, 365, a.duration_by_day)
            into v_months, v_d_day
            from bsm_package_mas a
           where a.package_id = v_package_id;
          v_start_date := to_char(v_action_date, 'YYYY/MM/DD HH24:MI:SS');
          v_end_date   := to_char(trunc(add_months(v_action_date, v_months) +
                                        v_d_day) - (1 / (24 * 60 * 60)),
                                  'YYYY/MM/DD HH24:MI:SS');
        
          v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                      v_Purchase_No || '","client_id":"' || v_client_id ||
                      '","service_start_date":"' || v_start_date ||
                      '","service_end_date":"' || v_end_date || '"}';
        end;
      else
        declare
          v_char varchar2(32);
        begin
          select 'x'
            into v_char
            from parent_order
           where src_order_id = v_order_pre_fix || v_order_id
             and rownum <= 1;
        exception
          when no_data_found then
            Select Seq_Bsm_Purchase_Pk_No.Nextval
              Into v_order_pk_no
              From Dual;
          
            insert into parent_order
              (pk_no,
               src_id,
               vendor_id,
               src_order_id,
               order_date,
               action,
               scvid,
               orderid,
               contractid,
               msisdn,
               msisdnnew,
               orderdate,
               isfirst,
               reqcreatetime,
               status_flg,
               order_DATA,
               amt)
            values
              (v_order_pk_no,
               v_order_pre_fix || v_order_id,
               v_vendor,
               v_order_pre_fix || v_order_id,
               v_order_date,
               v_action,
               v_package_id,
               v_order_id,
               v_order_id,
               v_mobile,
               v_mobile,
               v_order_date,
               'A',
               sysdate,
               'A',
               p_order,
               v_amt);
            commit;
        end;
      
        declare
          p_src_prog_no         varchar2(32) := v_order_pre_fix;
          v_start_date          varchar2(32);
          p_gift_package_id     varchar2(32);
          v_purchase_item_pk_no number(16);
          v_charge_name         varchar2(32);
          v_char                varchar2(32);
          v_src_no              varchar2(32);
          v_device_id           varchar2(32);
          v_pay_type            varchar2(32) := 'Bandott';
          v_recurrent_type      varchar2(32) := 'O';
        
        begin
          if v_vendor is not null then
            begin
            select pay_type, default_recurrent_type
              into v_pay_type, v_recurrent_type
              from acg_vendor_payment_mas a
             where upper(vendor) = upper(v_vendor);
            exception
              when no_data_found then
                return 'NO vendor setting in bsm';
            end;
          end if;
          p_gift_package_id := v_package_id;
        
          select 'x'
            into v_char
            from bsm_client_mas
           where mac_address = v_client_id
             for update;
        
          declare
            v_acc_invo_no       varchar2(32);
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
            v_mas_no            varchar2(32) := v_order_pre_fix ||
                                                v_order_id;
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
               tax_code,
               recurrent,
               start_type,
               AMOUNT,
               TOTAL_AMT,
               software_group)
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
               nvl(v_order_date, sysdate),
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
               v_recurrent_type,
               'E',
               v_amt,
               v_amt,
               v_software_group);
          
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
               v_amt,
               v_amt,
               v_Duration,
               v_charge_type,
               v_charge_code,
               v_charge_name,
               0,
               0,
               v_amt,
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
        
          if p_start_form_active is not null and
             p_start_form_active = 'activate' then
            declare
              v_end_date        varchar2(32);
              v_d_day           number(16);
              v_months          number(16);
              v_package_cat_id1 varchar2(64);
            begin
              select nvl(a.duration_by_month, 0),
                     decode(a.duration_by_day, 395, 365, a.duration_by_day),
                     package_cat_id1
                into v_months, v_d_day, v_package_cat_id1
                from bsm_package_mas a
               where a.package_id = v_package_id;
            
              declare
                v_next_start_date date;
              begin
                Select max(trunc(end_date)) + 1 next_start_date
                  into v_next_start_date
                  from bsm_client_details a, bsm_package_mas b
                 where a.package_id = b.package_id
                   and a.status_flg = 'P'
                   and b.package_cat_id1 = v_package_cat_id1
                   and a.serial_id = v_client_Id
                   and a.src_pk_no <> v_purchase_pk_no;
                if v_next_start_date is not null then
                  v_action_date := v_next_start_date;
                end if;
              end;
              v_start_date := to_char(v_action_date,
                                      'YYYY/MM/DD HH24:MI:SS');
              v_end_date   := to_char(trunc(add_months(v_action_date,
                                                       v_months) + v_d_day) -
                                      (1 / (24 * 60 * 60)),
                                      'YYYY/MM/DD HH24:MI:SS');
              update parent_order x
                 set x.client_id       = v_client_Id,
                     x.status_flg      = 'Z',
                     x.register_date   = sysdate,
                     x.p_service_start = v_action_date,
                     x.p_service_end   = trunc(add_months(v_action_date,
                                                          v_months) +
                                               v_d_day) -
                                         (1 / (24 * 60 * 60)),
                     x.purchase_create = sysdate,
                     x.purchase_no     = v_purchase_no,
                     x.purchase_pk_no  = v_purchase_pk_no
               where x.src_id = v_order_pre_fix || v_order_id;
            
              commit;
              update bsm_client_details a
                 set a.start_date = v_action_date,
                     a.end_date   = nvl(v_expire_date,trunc(add_months(v_action_date, v_months) +
                                          v_d_day) - (1 / (24 * 60 * 60)))
              
               where a.src_pk_no = v_purchase_pk_no
                 and a.package_id = v_package_id
                 and rownum <= 1;
            
              commit;
              bsm_client_service.Set_subscription(v_purchase_pk_no,
                                                  v_client_id);
            
              v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                          v_Purchase_No || '","client_id":"' || v_client_id ||
                          '","service_start_date":"' || v_start_date ||
                          '","service_end_date":"' || v_end_date || '"}';
            
            end;
          
          else
            declare
            
              v_end_date   varchar2(32);
              v_d_day      number(16);
              v_months     number(16);
              i_start_date date;
              i_end_date   date;
            begin
              select nvl(a.duration_by_month, 0),
                     decode(a.duration_by_day, 395, 365, a.duration_by_day)
                into v_months, v_d_day
                from bsm_package_mas a
               where a.package_id = v_package_id;
            
              update bsm_client_details a
                 set a.end_date = nvl(v_expire_date,trunc(add_months(start_date, v_months) +
                                        v_d_day) - (1 / (24 * 60 * 60)))
               where a.src_pk_no = v_purchase_pk_no
                 and a.package_id = v_package_id
                 and rownum <= 1;
            
              commit;
              bsm_client_service.Set_subscription(v_purchase_pk_no,
                                                  v_client_id);
              bsm_client_service.refresh_bsm_client(v_client_id);
              select to_char(a.start_date, 'YYYY/MM/DD HH24:MI:SS'),
                     to_char(a.end_date, 'YYYY/MM/DD HH24:MI:SS'),
                     a.start_date,
                     a.end_date
                into v_start_date, v_end_date, i_start_date, i_end_date
                from bsm_client_details a
               where a.src_pk_no = v_purchase_pk_no
                 and a.package_id = v_package_id
                 and rownum <= 1;
              update parent_order x
                 set x.client_id       = v_client_Id,
                     x.status_flg      = 'Z',
                     x.register_date   = sysdate,
                     x.p_service_start = i_start_date,
                     x.p_service_end   = i_end_date,
                     x.purchase_create = sysdate,
                     x.purchase_no     = v_purchase_no,
                     x.purchase_pk_no  = v_purchase_pk_no
               where x.src_id = v_order_pre_fix || v_order_id;
              commit;
              v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                          v_Purchase_No || '","client_id":"' || v_client_id ||
                          '","service_start_date":"' || v_start_date ||
                          '","service_end_date":"' || v_end_date || '"}';
            end;
          end if;
          if v_recurrent_type = 'R' then
            declare
              v_recurrent_pk_no number(16);
            
              v_cht_subno varchar2(64);
              v_cht_auth  varchar2(64);
            
            begin
              Select Seq_Bsm_Purchase_Pk_No.Nextval,
                     x.cht_subscribeno,
                     x.cht_auth
                Into v_recurrent_pk_no, v_cht_subno, v_cht_auth
                From bsm_purchase_mas x
               where pk_no = v_Purchase_Pk_No;
            
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
                 nvl(v_PAY_TYPE, 'CREDIT'),
                 sysdate,
                 0,
                 v_Purchase_Pk_No,
                 v_Purchase_No,
                 null,
                 null,
                 null,
                 null,
                 sysdate,
                 'P',
                 v_client_id,
                 null,
                 null,
                 null,
                 to_date(v_start_date, 'YYYY/MM/DD HH24:MI:SS'),
                 
                 null,
                 null,
                 'A');
            
              commit;
            end;
          end if;
        
        exception
          when no_data_found then
            null;
        end;
      
      end if;
    elsif v_action = 'cancelservice' then
      begin
        select serial_id
          into v_client_id
          from bsm_client_mas a
         where a.owner_phone = v_mobile
           and serial_id like '2A%'
           and rownum <= 1;
      exception
        when no_data_found then
          null;
          null;
      end;
    
      begin
        select a.mas_no, pk_no
          into v_Purchase_No, v_Purchase_Pk_No
          from bsm_purchase_mas a
         where a.src_no = v_order_pre_fix || v_order_id;
      
        update bsm_client_details a
           set a.end_date =nvl(v_expire_date, a.start_date +
                            ceil((nvl(v_cancel_date, sysdate) + 0.5 -
                                 a.start_date) / 30) * 30)
         where a.src_pk_no = v_Purchase_Pk_No;
      
        bsm_client_service.Set_subscription(0, v_client_id);
      
        v_msg := bsm_recurrent_util.stop_recurrent(v_client_id,
                                                   v_Purchase_No,
                                                   'Parent 停租');
        
        update parent_order a
           set status_flg = 'C'
         where a.src_order_id = v_order_pre_fix || v_order_id;
      
       bsm_client_service.refresh_bsm_client(v_client_id);
      exception
        when no_data_found then
          declare
            v_order_no varchar2(32);
          begin
            select a.src_order_id
              into v_order_no
              from parent_order a
             where a.src_order_id = v_order_pre_fix || v_order_id
               and rownum <= 1;
            update parent_order a
               set status_flg = 'C'
             where a.src_order_id = v_order_pre_fix || v_order_id;
            commit;
          exception
            when no_data_found then
              raise order_not_found;
          end;
      end;
    
      v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                  v_Purchase_No || '","client_id":"' || v_client_id || '"}';
    elsif v_action = 'resumeservice' then
       begin
        select serial_id
          into v_client_id
          from bsm_client_mas a
         where a.owner_phone = v_mobile
           and serial_id like '2A%'
           and rownum <= 1;
      exception
        when no_data_found then
          null;
          null;
      end;
    
      begin
        select a.mas_no, pk_no
          into v_Purchase_No, v_Purchase_Pk_No
          from bsm_purchase_mas a
         where a.src_no = v_order_pre_fix || v_order_id;
      
        update bsm_client_details a
           set a.start_date=nvl(v_action_date,sysdate),
            a.end_date = v_expire_date
         where a.src_pk_no = v_Purchase_Pk_No;
      
        bsm_client_service.Set_subscription(0, v_client_id);
        
        update bsm_recurrent_mas c set  c.status_flg='P' ,c.remark = 'RESUME SERVUCE' 
        where c.src_pk_no=v_Purchase_Pk_No;
        bsm_client_service.Set_subscription(0, v_client_id);
        bsm_client_service.refresh_bsm_client(v_client_id);
      
        update parent_order a
           set status_flg = 'P'
         where a.src_order_id = v_order_pre_fix || v_order_id;
      
      exception
        when no_data_found then
          declare
            v_order_no varchar2(32);
          begin
            select a.src_order_id
              into v_order_no
              from parent_order a
             where a.src_order_id = v_order_pre_fix || v_order_id
               and rownum <= 1;
            update parent_order a
               set status_flg = 'P'
             where a.src_order_id = v_order_pre_fix || v_order_id;
            commit;
          exception
            when no_data_found then
              raise order_not_found;
          end;
      end;
    
      v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                  v_Purchase_No || '","client_id":"' || v_client_id || '"}';
    
    end if;
  
    return v_result;
  
  exception
    when lost_data then
      return '{result_code:"BSM-00800",result_message:"null field","purchase_no":"","client_id":""}';
    when no_client_found then
      return '{result_code:"BSM-00801",result_message:"phone number not found","purchase_no":"","client_id":""}';
    when no_data_found then
      return '{result_code:"BSM-00802",result_message:"order not found","purchase_no":"","client_id":""}';
    when dup_order then
      declare
        v_start_date varchar2(32);
        v_end_date   varchar2(32);
        v_d_day      number(16);
      begin
        select to_char(a.start_date, 'YYYY/MM/DD HH24:MI:SS'),
               to_char(a.end_date, 'YYYY/MM/DD HH24:MI:SS')
          into v_start_date, v_end_date
          from bsm_client_details a
         where a.src_pk_no = v_purchase_pk_no
           and a.package_id = v_package_id
           and rownum <= 1;
        v_result := '{result_code:"BSM-00000",result_message:"訂單重複","purchase_no":"' ||
                    v_Purchase_No || '","client_id":"' || v_client_id ||
                    '","service_start_date":"' || v_start_date ||
                    '","service_end_date":"' || v_end_date || '"}';
      end;
      return v_result;
    when order_not_found then
      return '{result_code:"BSM-00802",result_message:"order not found","purchase_no":"","client_id":""}';
  end;
end PARTNER_SERVICE;
/
