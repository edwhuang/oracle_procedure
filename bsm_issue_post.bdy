CREATE OR REPLACE PACKAGE BODY IPTV.bsm_issue_post is
  Function bsm_issue_generate_bchang(p_User_No        Number,
                                     p_purchas_pk_no  number,
                                     p_next_bill_date date) Return number is
  begin
    declare
      v_org_no        number(16) := 1;
      v_issue_pk_no   number(16);
      v_mas_code      varchar2(32) := 'BSMISS';
      v_mas_no        varchar2(32);
      v_org_amt       number(16);
      v_org_tax_amt   number(16);
      v_org_net_amt   number(16);
      v_pay_pk_no     number(16);
      v_purchase_no   varchar2(32);
      v_refund_pk_no  number(16);
      v_client_id     varchar2(32);
      v_re_pk_no      number(16);
      v_org_bill_date date;
    
      v_item_pk_no number(16);
      cursor c1 is
        select b.pk_no,
               b.package_id,
               b.item_id,
               b.amount,
               b.tax_amt,
               b.chg_amt
          from bsm_purchase_item b
         where b.mas_pk_no = p_purchas_pk_no;
    begin
      select a.amount,
             a.chg_amt,
             tax_amt,
             pay_pk_no,
             mas_no,
             refund_pk_no,
             serial_id
        into v_org_amt,
             v_org_net_amt,
             v_org_tax_amt,
             v_pay_pk_no,
             v_purchase_no,
             v_refund_pk_no,
             v_client_id
        from bsm_purchase_mas a
       where a.pk_no = p_purchas_pk_no;
      Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_issue_pk_no From Dual;
    
      Select pk_no, next_bill_date
        into v_re_pk_no, v_org_bill_date
        from bsm_recurrent_mas a
       where a.src_pk_no = p_purchas_pk_no;
    
      v_mas_no := Sysapp_Util.Get_Mas_No(v_org_no,
                                         2,
                                         Sysdate,
                                         v_mas_code,
                                         v_issue_pk_no);
    
      insert into bsm_issue_mas
        (pk_no,
         mas_date,
         mas_no,
         status_flg,
         issue_type,
         purchase_no,
         client_id,
         org_pk_no,
         org_amt,
         org_tax_amt,
         org_net_amt,
         org_pay_pk_no,
         org_re_pk_no,
         next_bill_date,
         org_bill_date,
         create_date,
         create_user)
      values
        (v_issue_pk_no,
         sysdate,
         v_mas_no,
         'A',
         'BILLCHANG',
         v_purchase_no,
         v_client_id,
         p_purchas_pk_no,
         v_org_amt,
         v_org_tax_amt,
         v_org_net_amt,
         v_pay_pk_no,
         v_re_pk_no,
         p_next_bill_date,
         v_org_bill_date,
         sysdate,
         p_user_no);
      for i in c1 loop
        Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_item_pk_no From Dual;
        insert into bsm_issue_item
          (pk_no,
           mas_pk_no,
           org_item_pk_no,
           org_package_id,
           org_item_id,
           org_amt,
           org_tax_amt,
           org_net_amt)
        values
          (v_item_pk_no,
           v_issue_pk_no,
           i.pk_no,
           i.package_id,
           i.item_id,
           i.amount,
           i.tax_amt,
           i.chg_amt);
      
      end loop;
    
      commit;
    
      return v_issue_pk_no;
    end;
  
  end;

  Function bsm_issue_generate(p_User_No Number, p_purchas_pk_no number)
    Return number is
  begin
    declare
      v_org_no       number(16) := 1;
      v_issue_pk_no  number(16);
      v_mas_code     varchar2(32) := 'BSMISS';
      v_mas_no       varchar2(32);
      v_org_amt      number(16);
      v_org_tax_amt  number(16);
      v_org_net_amt  number(16);
      v_pay_pk_no    number(16);
      v_purchase_no  varchar2(32);
      v_refund_pk_no number(16);
      v_client_id    varchar2(32);
      v_dis_start_date date;
      v_dis_end_date date;
      v_pay_type varchar2(32);
    
      v_item_pk_no number(16);
      cursor c1 is
         select b.pk_no,
               b.package_id,
               b.item_id,
               max(nvl(d.amt,b.amount)) amount,
               b.tax_amt,
               b.chg_amt,
               min(nvl(d.service_start,c.start_date)) start_date,
               max(nvl(d.service_end,c.end_date)) end_date,
               b.pk_no item_pk_no
          from bsm_purchase_item b, bsm_client_details c,ans_purchase_distribute d
         where b.mas_pk_no = p_purchas_pk_no
           and c.src_item_pk_no(+) = b.pk_no
           and b.mas_pk_no = p_purchas_pk_no
           and d.pk_no(+)=b.pk_no
           group by  b.pk_no,
               b.package_id,
               b.item_id,
               
               b.tax_amt,
               b.chg_amt,
               b.pk_no;
    begin
      select a.amount,
             a.chg_amt,
             tax_amt,
             pay_pk_no,
             mas_no,
             refund_pk_no,
             serial_id,
             pay_type
        into v_org_amt,
             v_org_net_amt,
             v_org_tax_amt,
             v_pay_pk_no,
             v_purchase_no,
             v_refund_pk_no,
             v_client_id,
             v_pay_type
        from bsm_purchase_mas a
       where a.pk_no = p_purchas_pk_no;
      Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_issue_pk_no From Dual;
    
      v_mas_no := Sysapp_Util.Get_Mas_No(v_org_no,
                                         2,
                                         Sysdate,
                                         v_mas_code,
                                         v_issue_pk_no);
    
      insert into bsm_issue_mas
        (pk_no,
         mas_date,
         mas_no,
         status_flg,
         issue_type,
         purchase_no,
         client_id,
         org_pk_no,
         org_amt,
         refund_amt,
         org_tax_amt,
         org_net_amt,
         org_pay_pk_no,
         create_date,
         create_user)
      values
        (v_issue_pk_no,
         sysdate,
         v_mas_no,
         'A',
         decode(v_pay_type,
         'CREDIT','REFUND','信用卡','REFUND','OTHER_REFUND'),
         v_purchase_no,
         v_client_id,
         p_purchas_pk_no,
         v_org_amt,
         v_org_amt,
         v_org_tax_amt,
         v_org_net_amt,
         v_pay_pk_no,
         sysdate,
         p_user_no);
      for i in c1 loop
        begin
          select c.service_start,c.service_end into v_dis_start_date,v_dis_end_date from iptv.ANS_PURCHASE_DISTRIBUTE c where c.pk_no = i.item_pk_no;
        exception
          when no_data_found then
              v_dis_start_date := i.start_date;
              v_dis_end_date := i.end_date;
        end;
        if v_dis_start_date <= sysdate then v_dis_start_date:=sysdate; end if;
        Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_item_pk_no From Dual;
        insert into bsm_issue_item
          (pk_no,
           mas_pk_no,
           org_item_pk_no,
           org_package_id,
           org_item_id,
           org_amt,
           refund_amt,
           org_tax_amt,
           org_net_amt,
           org_start_date,
           org_end_date,
           new_start_date,
           new_end_date,
           new_package_id)
        values
          (v_item_pk_no,
           v_issue_pk_no,
           i.pk_no,
           i.package_id,
           i.item_id,
           i.amount,
           i.amount,
           i.tax_amt,
           i.chg_amt,
           i.start_date,
           i.end_date,
           i.start_date,
           i.end_date,
           i.package_id);
      
      end loop;
      if v_refund_pk_no is null then
        update bsm_purchase_mas a
           set refund_pk_no = v_issue_pk_no
         where a.pk_no = p_purchas_pk_no;
      end if;
    
      commit;
    
      return v_issue_pk_no;
    end;
  
  end;

  Function bsm_issue_generate_from_dtls(p_User_No   Number,
                                        p_client_id varchar2) Return number is
  begin
    declare
      v_org_no       number(16) := 1;
      v_issue_pk_no  number(16);
      v_mas_code     varchar2(32) := 'BSMISS';
      v_mas_no       varchar2(32);
      v_org_amt      number(16);
      v_org_tax_amt  number(16);
      v_org_net_amt  number(16);
      v_pay_pk_no    number(16);
      v_purchase_no  varchar2(32);
      v_refund_pk_no number(16);
      v_client_id    varchar2(32);
    
      v_item_pk_no number(16);
      cursor c1 is
        select b.pk_no,
               a.package_id,
               b.item_id,
               b.amount,
               b.tax_amt,
               b.chg_amt,
               a.start_date,
               a.end_date,
               a.status_flg,
               (select mas_no
                  from bsm_purchase_mas c
                 where c.pk_no = b.mas_pk_no) mas_no
          from bsm_purchase_item b, bsm_client_details a
         where 1 = 1
           and a.src_item_pk_no = b.pk_no(+)
           and a.mac_address = p_client_id
           and a.status_flg = 'P'
           and a.package_id not like 'FREE%'
           and ((a.start_date <= sysdate and a.end_date >= sysdate) or
               a.start_date >= sysdate)
         order by start_date, a.package_id;
    begin
      /*    select a.amount,
            a.chg_amt,
            tax_amt,
            pay_pk_no,
            mas_no,
            refund_pk_no,
            serial_id
       into v_org_amt,
            v_org_net_amt,
            v_org_tax_amt,
            v_pay_pk_no,
            v_purchase_no,
            v_refund_pk_no,
            v_client_id
       from bsm_purchase_mas a
      where a.pk_no = p_purchas_pk_no; */
      Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_issue_pk_no From Dual;
    
      v_mas_no := Sysapp_Util.Get_Mas_No(v_org_no,
                                         2,
                                         Sysdate,
                                         v_mas_code,
                                         v_issue_pk_no);
    
      insert into bsm_issue_mas
        (pk_no,
         mas_date,
         mas_no,
         status_flg,
         issue_type,
         purchase_no,
         client_id,
         org_pk_no,
         org_amt,
         org_tax_amt,
         org_net_amt,
         org_pay_pk_no,
         create_date,
         create_user)
      values
        (v_issue_pk_no,
         sysdate,
         v_mas_no,
         'A',
         'SERVICE_CHANGE',
         null,
         p_client_id,
         null,
         0,
         0,
         0,
         0,
         sysdate,
         p_user_no);
      for i in c1 loop
        Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_item_pk_no From Dual;
        insert into bsm_issue_item
          (pk_no,
           mas_pk_no,
           PURCHASE_NO,
           org_item_pk_no,
           org_package_id,
           org_item_id,
           org_amt,
           org_tax_amt,
           org_net_amt,
           org_start_date,
           org_end_date,
           new_start_date,
           new_end_date,
           new_package_id,
           change_type)
        values
          (v_item_pk_no,
           v_issue_pk_no,
           i.mas_no,
           i.pk_no,
           i.package_id,
           i.item_id,
           i.amount,
           i.tax_amt,
           i.chg_amt,
           i.start_date,
           i.end_date,
           i.start_date,
           i.end_date,
           i.package_id,
           'C');
      
      end loop;
      /*  if v_refund_pk_no is null then
        update bsm_purchase_mas a
           set refund_pk_no = v_issue_pk_no
         where a.pk_no = p_purchas_pk_no;
      end if;
      
      commit; */
    
      commit;
    
      return v_issue_pk_no;
    end;
  
  end;

  Function bsm_issue_transfer(p_user_no           number,
                              p_pk_no             number,
                              from_purchase_pk_no number) Return varchar2 is
  begin
    return null;
  end;

  Function bsm_issue_post(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg varchar(1024);
    app_exception Exception;
    v_status_flg varchar2(32);
    v_mas_code   varchar2(32) := 'BSMISS';
    v_issue_type varchar2(32);
    v_date       date;
  begin
    begin
      Select status_flg, a.next_bill_date, a.issue_type
        Into v_status_flg, v_date, v_issue_type
        From bsm_issue_mas a
       Where pk_no = p_pk_no
         for update nowait;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('A') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    if v_date is not null and v_date <= sysdate + 3 and
       v_issue_type = 'BILLCHANG' then
      exception_msg := '#錯誤的下次扣款日期#';
      Raise app_exception;
    end if;
  
    update bsm_issue_mas a set status_flg = 'P' Where pk_no = p_pk_no;
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

  Function bsm_issue_unpost(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg varchar(1024);
    app_exception Exception;
    v_status_flg varchar2(32);
    v_mas_code   varchar2(32) := 'BSMISS';
  begin
    begin
      Select status_flg
        Into v_status_flg
        From bsm_issue_mas a
       Where pk_no = p_pk_no
         for update nowait;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    update bsm_issue_mas a set status_flg = 'A' Where pk_no = p_pk_no;
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

  Function bsm_issue_complete(p_User_No Number, p_Pk_No Number,ref_client varchar2 default 'Y')
    return varchar2 is
    exception_msg varchar(1024);
    app_exception Exception;
    v_status_flg      varchar2(32);
    v_mas_code        varchar2(32) := 'BSMISS';
    v_org_purchase_no varchar2(32);
    v_refund_amt      number(16);
    v_refund_response varchar2(1024);
    v_issue_type      varchar2(1024);
    li_tx_number      varchar2(32);
    v_pay_pk_no       varchar2(32);
    v_pur_pk_no       number(16);
    v_msg             varchar2(1024);
    v_client_id       varchar2(1024);
  begin
    begin
      Select status_flg, a.purchase_no, a.refund_amt, a.issue_type
        Into v_status_flg, v_org_purchase_no, v_refund_amt, v_issue_type
        From bsm_issue_mas a
       Where pk_no = p_pk_no;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('P', 'RZ') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
    
    if v_issue_type = 'OTHER_REFUND' then
            -- 退款
    /*  Select lipay_tx_number, nvl(pay_pk_no, 0), pk_no
        into li_tx_number, v_pay_pk_no, v_pur_pk_no
        from bsm_purchase_mas
       where mas_no = v_org_purchase_no; 
    
      if nvl(v_refund_amt, 0) <= 0 then
        exception_msg := '#錯誤的退款金額#';
        Raise app_exception;
      end if; */
      
      update bsm_issue_mas a
           set status_flg = 'Z', response = v_refund_response
         Where pk_no = p_pk_no;
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
      
        commit;
  
    elsif v_issue_type = 'REFUND' then
      -- 退款
      Select lipay_tx_number, nvl(pay_pk_no, 0), pk_no
        into li_tx_number, v_pay_pk_no, v_pur_pk_no
        from bsm_purchase_mas
       where mas_no = v_org_purchase_no;
    
      if nvl(v_refund_amt, 0) <= 0 then
        exception_msg := '#錯誤的退款金額#';
        Raise app_exception;
      end if;
    
      if li_tx_number is null then
        v_msg             := BSM_PAYMENT_GATEWAY_CR.DepositR(v_pur_pk_no);
        v_msg             := BSM_PAYMENT_GATEWAY_CR.Refund(v_pur_pk_no,
                                                           v_refund_amt);
        v_refund_response := 'PRC=0';
      else
        v_refund_response := BSM_LIPAY_GATEWAY.refund(v_org_purchase_no,
                                                      v_refund_amt);
      end if;
    
      if (v_refund_response like 'PRC=0%') then
        update bsm_issue_mas a
           set status_flg = 'Z', response = v_refund_response
         Where pk_no = p_pk_no;
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
      
        commit;
      elsif (v_refund_response like '%204%') then
        update bsm_issue_mas a
           set status_flg = 'RZ', response = v_refund_response
         where pk_no = p_pk_no;
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
           
           'Failure',
           Sys_Event_Seq.Nextval,
           'Failure');
        commit;
      
      else
        update bsm_issue_mas a
           set status_flg = 'P', response = v_refund_response
         where pk_no = p_pk_no;
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
           
           'Failure',
           Sys_Event_Seq.Nextval,
           'Failure');
        commit;
      end if;
    elsif v_issue_type = 'BILLCHANG' then
      -- 更改下次扣款日
      declare
        v_org_bill_date date;
        cursor c1(p_pk_no number) is
          select pk_no, org_re_pk_no, next_bill_date, a.client_id
            from bsm_issue_mas a
           where pk_no = p_pk_no;
        v_src_pk_no number(16);
      begin
        for i in c1(p_Pk_No) loop
          begin
            select a.next_bill_date, src_pk_no
              into v_org_bill_date, v_src_pk_no
              from bsm_recurrent_mas a
             where a.pk_no = i.org_re_pk_no;
            update bsm_issue_mas b
               set b.org_bill_date = v_org_bill_date
             where pk_no = i.pk_no;
            update bsm_recurrent_mas b
               set b.next_bill_date   = i.next_bill_date,
                   b.last_modify_date = sysdate
             where b.pk_no = i.org_re_pk_no;
            update bsm_purchase_mas a
               set a.next_pay_date = i.next_bill_date
             where a.pk_no = v_src_pk_no;
          exception
            when no_data_found then
              exception_msg := '#錯誤的Recurrent狀態#';
              Raise app_exception;
          end;
                    commit;
            bsm_client_service.refresh_bsm_client(i.client_id);

       
        end loop;
 
        update bsm_issue_mas a set status_flg = 'Z' Where pk_no = p_pk_no;
        commit;
      
      end;
    elsif v_issue_type = 'SERVICE_CHANGE' then
      declare
        cursor c1 is
          select change_type,
                 org_item_pk_no,
                 new_start_date,
                 new_end_date,
                 new_package_id,
                 org_start_date,
                 org_end_date,
                 org_package_id,
                 dtl_pk_no,
                 b.pk_no,
                 b.purchase_no,
                 c.client_id,
                 d.serial_no
            from bsm_issue_item b, bsm_issue_mas c, bsm_client_mas d
           where b.mas_pk_no = p_pk_no
             and c.pk_no = b.mas_pk_no
             and d.serial_id = c.client_id;
      begin
        for i in c1 loop
          if i.change_type = 'D' then
            update bsm_client_details a
               set a.status_flg = 'N'
             where a.src_item_pk_no = i.org_item_pk_no;
          
            declare
              v_old_mac varchar2(128);
            begin
              Insert Into Sysevent_Log
                (App_Code,
                 Pk_No,
                 Event_Date,
                 User_No,
                 Event_Type,
                 Seq_No,
                 Description)
              Values
                ('TGCCLIENT',
                 i.client_id,
                 Sysdate,
                 p_user_no,
                 'system update detail',
                 Sys_Event_Seq.Nextval,
                 i.org_package_id || ' ' ||
                 to_char(i.org_start_date, 'YYYY/MM/DD') || '-' ||
                 to_char(i.org_end_date, 'YYYY/MM/DD') || ' ' ||
                 ' change to ' || i.new_package_id || ' ' ||
                 to_char(i.new_start_date, 'YYYY/MM/DD') || '-' ||
                 to_char(i.new_end_date, 'YYYY/MM/DD') || ' ' || 'N');
            end;
          elsif ((i.org_item_pk_no is not null) OR
                (i.dtl_pk_no is not null)) and
                (i.new_start_date <> i.org_start_date or
                i.new_end_date <> i.org_end_date) and i.change_type = 'C' then
            update bsm_client_details a
               set a.start_date = trunc(nvl(i.new_start_date, start_date)),
                   a.end_date   = trunc(nvl(i.new_end_date, end_date)) +
                                  (1 / (24 * 60 * 60)),
                   a.package_id = nvl(i.new_package_id, package_id)
             where (a.src_item_pk_no = i.org_item_pk_no or
                   pk_no = i.dtl_pk_no);
            declare
              v_old_mac varchar2(128);
            begin
              Insert Into Sysevent_Log
                (App_Code,
                 Pk_No,
                 Event_Date,
                 User_No,
                 Event_Type,
                 Seq_No,
                 Description)
              Values
                ('TGCCLIENT',
                 i.serial_no,
                 Sysdate,
                 p_user_no,
                 'issue update detail',
                 Sys_Event_Seq.Nextval,
                 i.org_package_id || ' ' ||
                 to_char(i.org_start_date, 'YYYY/MM/DD') || '-' ||
                 to_char(i.org_end_date, 'YYYY/MM/DD') || ' ' ||
                 ' change to ' || i.new_package_id || ' ' ||
                 to_char(i.new_start_date, 'YYYY/MM/DD') || '-' ||
                 to_char(i.new_end_date, 'YYYY/MM/DD'));
            end;
          elsif i.change_type = 'N' then
            declare
              Purchase_Pk_No         number(16);
              v_tr_id                number(16);
              v_serial_no            number(16);
              v_serial_id            varchar2(64);
              v_mac_address          varchar2(64);
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
              v_purchase_no          varchar2(64);
              v_package_service_type varchar2(32);
              v_package_system_type  varchar2(32);
              v_item_id              varchar2(64);
              v_pay_type             varchar2(256);
              v_phone_no             varchar2(32);
              v_device_id            varchar2(32);
              v_apt_productcode      varchar2(32);
              v_apt_min              varchar2(32);
              v_apt_gateway          varchar2(64);
              v_GMD2_flg             boolean := false;
              v_amt_devices          number(16);
              v_acl_id               varchar2(64);
              v_start_type           varchar2(64);
              v_create_sub           boolean;
              v_software_group       varchar2(64);
              v_src_no               varchar2(64);
            begin
              begin
              
                select pk_no,
                       mas_no,
                       serial_id,
                       mas_no,
                       pay_type,
                       nvl(start_type, 'E'),
                       src_no
                  into Purchase_Pk_No,
                       v_serial_id,
                       v_mac_address,
                       v_purchase_no,
                       v_apt_gateway,
                       v_start_type,
                       v_src_no
                  from bsm_purchase_mas
                 where mas_no = nvl(i.purchase_no, v_org_purchase_no);
              exception
                when no_data_found then
                  null;
              end;
            
              Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_tr_id From Dual;
            
              Select acl_duration,
                     acl_quota,
                     package_cat1,
                     case
                       when (substr(v_src_no, 1, 2) = 'RE' and
                            a.package_id = 'WD0001') or
                            (v_apt_gateway <> '信用卡' and
                            a.package_id = 'WD0001') then
                        description
                       else
                       
                        decode(ref3,
                               null,
                               description,
                               description || ' ' || ref3)
                     end description,
                     cal_type,
                     a.package_cat_id1,
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
                     v_package_system_type,
                     v_amt_devices,
                     v_acl_id,
                     v_package_service_type
                from bsm_package_mas a
               where package_id = i.new_package_id;
            
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
                 i.client_id,
                 i.client_id,
                 v_package_cat1,
                 i.new_package_id,
                 v_package_name,
                 trunc(nvl(i.new_start_date, sysdate)),
                 trunc(nvl(i.new_end_date, sysdate)) + (1 / (24 * 60 * 60)),
                 v_acl_duration,
                 v_acl_quota,
                 'P',
                 null,
                 i.org_item_pk_no,
                 v_device_id,
                 v_apt_productcode,
                 v_apt_min,
                 v_apt_gateway,
                 v_acl_id);
            
              update bsm_issue_item
                 set dtl_pk_no = v_tr_id
               where pk_no = i.pk_no;
            end;
          
            Insert Into Sysevent_Log
              (App_Code,
               Pk_No,
               Event_Date,
               User_No,
               Event_Type,
               Seq_No,
               Description)
            Values
              ('TGCCLIENT',
               i.serial_no,
               Sysdate,
               p_user_no,
               'issue new detail',
               Sys_Event_Seq.Nextval,
               i.org_package_id || ' ' ||
               to_char(i.org_start_date, 'YYYY/MM/DD') || '-' ||
               to_char(i.org_end_date, 'YYYY/MM/DD') || ' ' ||
               ' change to ' || i.new_package_id || ' ' ||
               to_char(i.new_start_date, 'YYYY/MM/DD') || '-' ||
               to_char(i.new_end_date, 'YYYY/MM/DD'));
          end if;
        
          declare
            cursor c1 is
              Select b.src_pk_no,
                     b.src_no,
                     b.serial_id,
                     trunc(bsm_recurrent_util.get_service_end_date(c.package_cat_id1,
                                                                   b.serial_id) - 3) next_pay
                from bsm_recurrent_mas  a,
                     bsm_client_details b,
                     bsm_package_mas    c
               where a.recurrent_type in ('LiPay', 'CREDIT')
                 and a.status_flg = 'P'
                 and b.src_no = a.src_no
                 and c.package_id = b.package_id
                 and b.serial_id = i.client_id;
            v_msg varchar2(2048);
          begin
            for i in c1 loop
              update bsm_recurrent_mas a
                 set a.next_bill_date   = i.next_pay,
                     a.last_modify_date = sysdate
               where a.src_no = i.src_no;

              update bsm_purchase_mas a
                 set a.next_pay_date = i.next_pay
               where a.mas_no = i.src_no;
              commit;
            end loop;
          end;
          v_client_id:=i.client_id;
        end loop;
      
      end;
      commit;
       bsm_client_service.Set_subscription_r(null, v_client_id,ref_client);
    
      update bsm_issue_mas a set status_flg = 'Z' Where pk_no = p_pk_no;
      commit;
    end if;
    commit;
    return null;
  end;

  Function bsm_issue_cancel(p_User_No Number, p_Pk_No Number) Return Varchar2 is
    exception_msg varchar(1024);
    app_exception Exception;
    v_status_flg varchar2(32);
    v_mas_code   varchar2(32) := 'BSMISS';
  begin
    begin
      Select status_flg
        Into v_status_flg
        From bsm_issue_mas a
       Where pk_no = p_pk_no
         for update nowait;
    
    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;
  
    If v_status_flg not in ('A', 'P') Then
      exception_msg := '#錯誤的單據狀態#';
      Raise app_exception;
    End If;
  
    update bsm_issue_mas a set status_flg = 'C' Where pk_no = p_pk_no;
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

end;
/

