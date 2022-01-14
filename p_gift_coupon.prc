create or replace procedure iptv.p_gift_coupon(p_client_id varchar2,p_device_id varchar2,p_sw_ver varchar2 default null)
     is
    begin
      if p_client_id is not null then

    declare

      cursor c1(p_client_id varchar2, p_device_id varchar2) is
        select coupon_id, ref_device_id
          from bsm_coupon_mas a, bsm_coupon_prog_mas b
         where a.ref_device_id = p_device_id
           and a.status_flg = 'P'
           and b.cup_program_id = a.program_id
           and a.expire_date >= sysdate;
      cursor c3(p_software_group varchar2,p_client_id varchar2, p_device_id varchar2) is     
          select a.package_id, a.item_id
            from mfg_softwaregroup_service a
           where a.software_group = p_software_group
             and a.status_flg='P'
             and a.package_id='CHG006'
             and (a.package_id not in          
               (select e.package_id
                    from bsm_purchase_mas d,bsm_purchase_item e
                   where 
                      e.mas_pk_no=d.pk_no
                     and d.pay_type='贈送'
                     and d.serial_id = p_client_id
                     and e.device_id = p_device_id
                     and d.status_flg in ('A', 'P','Z')
                     and d.src_no='CLIENT_ACTIVATED' ));           

      v_client_id   varchar2(32);
      v_device_id   varchar2(32);
      v_owner_phone varchar(32);
      v_msg         varchar2(1024);
      v_demo_flg    varchar2(1);
        v_software_group varchar2(32);
        v_char varchar(1);

    begin
                    --
      -- Check mac_address if not in list ,add it
      if p_device_id is not null then
      declare
        v_char           varchar2(1);
        v_ver            varchar2(32);
      
      begin
        select a.software_group
          into v_software_group
          from bsm_client_device_list a
         where a.client_id = p_client_id
           and device_id = p_device_id;

      exception
        when no_data_found then
          if p_sw_ver is null then
          v_ver := bsm_cdi_service.get_device_current_swver(p_client_id,
                                                            p_device_id);
          else
             v_ver:=p_sw_ver;
          end if;                                              
          if v_ver is not null then
            v_software_group := substr(v_ver, 1, 7);
          end if;
         -- if v_software_group is not null then
          insert into bsm_client_device_list
            (client_id,
             device_id,
             owner_phone_no,
             status_flg,
             software_group)
          values
            (p_client_id,
             p_device_id,
             '',
             'P',
             v_software_group);
             commit;
        --  end if;
       end;
       end if;
       
       for c3rec in c3(v_software_group,p_client_id,p_device_id) loop
              declare
                v_dup varchar(32);
              begin
                 select 'x'
              into v_char
              from bsm_client_mas a
             where a.mac_address = p_client_id
               for update;
               
                begin
                select 'Y'
                  into v_dup
                  from bsm_client_details a
                 where ((a.mac_address = p_client_id and
                       (a.device_id is null or a.device_id = p_device_id)) or
                       (a.mac_address = p_client_id and
                       p_device_id is null))
                   and package_id = c3rec.package_id
                   and status_flg = 'P'
                   and (src_no = 'CLIENT_ACTIVATED' or
                       a.src_no in
                       (select mas_no
                           from bsm_purchase_mas
                          where src_no = 'CLIENT_ACTIVATED'
                            and serial_id = p_client_id
                            and status_flg='Z'));
                  exception
                      when no_data_found then v_dup := 'N';
                  end;
                  
                  begin
                  select 'Y' into v_dup
                    from bsm_purchase_mas d,bsm_purchase_item e
                   where 
                      e.mas_pk_no=d.pk_no
                     and d.pay_type='贈送'
               --      and d.serial_id = p_client_id
                     and e.device_id = p_device_id
                     and d.status_flg in ('A', 'P','Z')
                     and d.src_no='CLIENT_ACTIVATED'
                     and e.package_id = c3rec.package_id
                     and rownum <= 1;
                     
                     -- 4gTV過濾
                     if substr(p_client_id ,1,2)='F6'then
                        v_dup :='Y';
                     end if; 
                   exception
                     when no_data_found then null;
                   end;
                 
                 if v_dup = 'N' then   
                     
                
                  declare
                    v_Purchase_Pk_No      number(16);
                    v_purchase_no         varchar2(32);
                    v_acc_invo_no         varchar2(32);
                    v_pay_type            varchar2(32) := '贈送';
                    v_Client_Info         Tbsm_Client_Info;
                    v_acc_name            varchar2(32);
                    v_tax_code            varchar2(32);
                    v_Purchase_Mas_Code   varchar(32) := 'BSMPUR';
                    v_Serial_No           number(16);
                    v_id                  varchar2(32) := c3rec.package_id; -- package_id;
                    v_Price               number(16);
                    v_Duration            number(16);
                    v_Quota               number(16);
                    v_charge_type         varchar2(32);
                    v_charge_code         varchar2(32);
                    v_client_id           varchar(32) := p_client_id;
                    v_device_id           varchar2(32) := p_device_id;
                    v_mas_no              varchar2(32) := 'CLIENT_ACTIVATED';
                    p_user_no             number(16) := 0;
                    v_Purchase_Item_Pk_No number(16);
                    v_charge_name         varchar2(64);
                  
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
                       show_flg)
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
                       'Y');
                  
                    --
                    --  計算價格
                    --
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
                       device_id)
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
                  
                 end if;
              end;
            end loop;
       
        for i in c1(p_client_id, p_device_id) loop
          
          begin
          v_msg := bsm_purchase_post.CLIENT_REGIETER_COUPON(p_client_id,
                                                            i.coupon_id,
                                                            i.ref_device_id);
          exception
            when no_data_found then null;
            when others then null;
          end;
        end loop;
    end;
    end if;

end;
/

