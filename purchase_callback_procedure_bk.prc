create or replace procedure iptv.purchase_callback_procedure_bk(purchase_msg purchase_msg_type) AS

begin

  if purchase_msg.process_type = 'promo' then
  
    declare
      purchase_no           varchar2(32) := purchase_msg.purchase_no;
      purchase_pk_no        number(16) := purchase_msg.pk_no;
      v_promo_code          varchar2(32);
      v_promo_prog          varchar2(32);
      v_mgm_type            varchar2(32);
      v_package_id          varchar(32);
      v_client_id           varchar2(32);
      v_buy_client_id       varchar2(32);
      v_Purchase_Pk_No      number(32);
      v_Purchase_No         varchar2(32);
      p_gift_package_id     varchar2(32);
      v_mas_no              varchar2(32);
      v_Purchase_Item_Pk_No number(16);
      v_owner_client_id     varchar2(32);
      v_promo_type          varchar2(32);
      dup_purchase Exception;
    
    begin
      select b.promo_prog_id, a.serial_id, b.owner, c.promo_type
        into v_promo_prog, v_buy_client_id, v_owner_client_id, v_promo_type
        from bsm_purchase_mas a, promotion_mas b, promotion_prog_mas c
       where a.pk_no = purchase_pk_no
         and a.promo_code = b.promo_code
         and c.promo_prog_id = b.promo_prog_id;
      if v_promo_type = 'PACKAGE' then
      
        select a.mgm_type, a.package_id
          into v_mgm_type, v_package_id
          from promotion_prog_item a, bsm_purchase_item b
         where a.discount_package_id = b.package_id
           and b.mas_pk_no = purchase_msg.pk_no
           and a.promo_prog_id = v_promo_prog;
      
        if v_mgm_type = 'B' or
           (v_mgm_type = 'OB' and v_buy_client_id <> v_owner_client_id) then
          v_client_id       := v_buy_client_id;
          p_gift_package_id := v_package_id;
          v_mas_no          := 'MGM' || purchase_no || '_B';
          declare
            v_char varchar2(32);
          begin
            select 'x'
              into v_char
              from bsm_purchase_mas a
             where a.src_no = v_mas_no
               and status_flg = 'Z';
            raise dup_purchase;
          exception
            when no_data_found then
              null;
          end;
        
          declare
            v_acc_invo_no       varchar2(32);
            v_pay_type          varchar2(32) := 'MGM贈送';
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
          
            p_user_no number(16) := 0;
          
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
               v_recurrent,
               'E');
          
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
        
        end if;
      
        if v_mgm_type = 'O' or
           (v_mgm_type = 'OB' and v_buy_client_id <> v_owner_client_id) then
          v_client_id       := v_owner_client_id;
          p_gift_package_id := v_package_id;
          v_mas_no          := 'MGM' || purchase_no || '_O';
          declare
            v_char varchar2(32);
          begin
            select 'x'
              into v_char
              from bsm_purchase_mas a
             where a.src_no = v_mas_no
               and status_flg = 'Z';
            raise dup_purchase;
          exception
            when no_data_found then
              null;
          end;
        
          declare
            v_acc_invo_no       varchar2(32);
            v_pay_type          varchar2(32) := 'MGM贈送';
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
          
            p_user_no number(16) := 0;
          
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
               v_recurrent,
               'E');
          
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
        
        end if;
      end if;
    exception
      when no_data_found then
        null;
    end;
  elsif purchase_msg.process_type = 'refresh_bsm' then
    declare
      cursor c1 is
        Select Seq_Bsm_Purchase_Pk_No.Nextval pk_no,
               a.pk_no                        mas_pk_no,
               b.pk_no                        item_pk_no,
               a.tax_inv_no                   tax_inv_no
          from bsm_purchase_mas a, bsm_purchase_item b
         where a.purchase_date >= to_date('2019/11/18', 'YYYY/MM/DD')
           and b.package_id = 'XD0005'
           and pay_type in ('信用卡', 'ATM', 'REMIT')
           and src_no not like 'RE%'
           and (a.chg_amt = 3588 or a.amount=3588)
         --  and status_flg = 'Z'
           and b.mas_pk_no = a.pk_no
           and a.serial_id = purchase_msg.client_id
           and a.promo_code is null
           and not exists (select 'x'
                  from bsm_purchase_item c
                 where c.mas_pk_no = a.pk_no
                   and c.package_id != 'XD0005');
      v_tax_pk_no      number(16);
      v_tax_item_pk_no number(16);
    begin
    
      for i in c1 loop
        begin
          begin
            select pk_no
              into v_tax_pk_no
              from tax_inv_mas a
             where a.f_invo_no = i.tax_inv_no;
          exception
            when no_data_found then
              v_tax_pk_no := null;
          end;
          select seq_sys_no.nextval into v_tax_item_pk_no from dual;
        
          update bsm_client_details d
             set d.package_name = '預付一年'
           where d.src_item_pk_no = i.item_pk_no;
          insert into bsm_purchase_item
            (pk_no,
             mas_pk_no,
             price,
             amount,
             package_id,
             duration,
             chg_code,
             chg_name,
             credits,
             tax_amt,
             chg_amt,
             tax_flg,
             tax_rate,
             tax_code,
             device_id,
             type)
          values
            (i.pk_no,
             i.mas_pk_no,
             0,
             0,
             'E_XDG005',
             0,
             'PMONTHFEE',
             '預付月租費',
             0,
             0,
             0,
             'Y',
             0.05,
             'OUTTAX1',
             null,
             'S');
          if v_tax_pk_no is not null then
            insert into tax_inv_item
              (mas_pk_no,
               pk_no,
               item_name,
               tax_flg,
               amount,
               qty,
               dr_acc_code,
               cr_acc_code,
               tax_acc_code,
               inv_pk_no,
               chg_code,
               item_pk_no,
               tax_amt,
               src_amount)
            values
              (v_tax_pk_no,
               v_tax_item_pk_no,
               '加贈豪華組合6個月',
               'Y',
               0,
               1,
               '1150',
               '2253',
               '2132',
               0,
               'PMONTHFEE',
               i.pk_no,
               0,
               0);
          end if;
        exception
          when others then
            null;
        end;
      
        commit;
      end loop;
      null;
    end; 
  
    bsm_client_service.refresh_bsm_client(purchase_msg.client_id);
  elsif purchase_msg.process_type = 'refresh_cdi' then
    declare
      v_msg varchar2(1024);
    begin
      modify_service_1111_p(purchase_msg.client_id);
      if purchase_msg.client_id = 'F6AEF1815EC63D2E' then
        null;
      else
        v_msg := bsm_cdi_service.refresh_client(purchase_msg.client_id);
        v_msg := bsm_cdi_service_dev2.saveclientinfo(purchase_msg.client_id);
          
    declare
      cursor c1 is
         Select b.src_pk_no,
               b.src_no,
               a.client_id,
               case when 
               trunc(bsm_recurrent_util.get_service_end_date(c.package_cat_id1,
                                                             a.client_id) - 3) <= trunc(sysdate) then
                sysdate+1
                else
                 trunc(bsm_recurrent_util.get_service_end_date(c.package_cat_id1,
                                                            a.client_id) - 3) 
                end                                                               next_pay
                                                                        
          from bsm_recurrent_mas a, bsm_client_details b, bsm_package_mas c,bsm_purchase_item d
         where a.recurrent_type in ('LiPay','LiPayN')
           and a.status_flg = 'P'
           and b.src_no = a.src_no
           and c.package_id = d.package_id
           and d.mas_pk_no =a.src_pk_no

           and a.client_id =purchase_msg.client_id;
      v_msg varchar2(2048);
    begin
      for i in c1 loop
        update bsm_recurrent_mas a
           set a.next_bill_date = i.next_pay, a.last_modify_date = sysdate
         where a.src_no = i.src_no;
        commit;
      end loop;
    end;
      --  bsm_client_service.saveClientServiceInfo(purchase_msg.client_id);
      end if;
    end;
    begin
      null;
    exception
      when others then
        null;
    end;
  elsif purchase_msg.process_type = 'refresh_cdi_status' then
    declare
      v_msg        varchar2(1024);
      v_status_flg varchar2(1024);
    begin
      select status_flg
        into v_status_flg
        from bsm_client_mas a
       where a.serial_id = purchase_msg.client_id;
      v_msg := bsm_cdi_service.Set_Client_Status(purchase_msg.client_id,
                                                 v_status_flg);
    end;
  elsif purchase_msg.process_type = 'refresh_acg' then
    declare
      v_msg        varchar2(1024);
      v_promo_code varchar2(1024);
    begin
      select promo_code
        into v_promo_code
        from bsm_purchase_mas a
       where a.pk_no = purchase_msg.pk_no;
      bsm_client_service.refresh_acg(purchase_msg.client_id, v_promo_code);
    end;
   elsif purchase_msg.process_type = 'send_pur_sms' then
    declare
    v_owner_phone_no varchar2(1024);
    v_purchase_amount number(16,0);
    v_promo_code varchar2(32);
    v_Sms_Result clob;
    begin
            select a.promo_code,d.owner_phone,a.amount
        into v_promo_code,v_owner_phone_no,v_purchase_amount
        from bsm_purchase_mas a,bsm_client_mas d
       where a.pk_no =  purchase_msg.purchase_no
       and d.serial_id=a.serial_id;
      
           v_Sms_Result := BSM_SMS_Service.Send_Sms_Messeage_litv(v_owner_phone_no,
                                                                   null,
                                                                   purchase_msg.client_id,
                                                                   'purchase',
                                                                    purchase_msg.purchase_no,
                                                                  v_Purchase_Amount);
                                                                  
                if v_promo_code='MKT564' then
               v_Sms_Result := bsm_sms_service.send_sms_text('8080', '東森購物折扣金通知簡訊，請撥打專屬訂購專線0800-070-886，訂購時說出：LiTV獨享折100，即可使用（共7筆，不限金額折抵）', v_owner_phone_no);
            end if;                                                            
 end;
   elsif purchase_msg.process_type = 'purge_notice' then 
    declare
      v_msg clob;

     begin  
        v_msg := bsm_cdi_service_dev2.purgeNotice(purchase_msg.client_id);
      end;
  end if;

end;
/

