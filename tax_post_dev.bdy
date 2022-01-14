CREATE OR REPLACE PACKAGE BODY IPTV.TAX_POST_DEV is

  -- Author  : EDWARD
  -- Created : 2009/2/27 16:19:51
  -- Purpose :

  -- Public type declarations
  --  type <TypeName> is <Datatype>;

  -- Public constant declarations
  --  <ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  -- <VariableName> <Datatype>;

  -- Public function and procedure declarations
  procedure set_inv_date(p_date date) is
  begin
    set_invo_date := p_date;
  end;

  procedure set_chk_pk_no(p_chk_pk_no number) is
  begin
    v_chk_pk_no := p_chk_pk_no;
  end;
  function get_inv_chk_code(p_inv_no Varchar) return Varchar2 Is
    v_result  Varchar2(32);
    v_invo_no Varchar2(32);
    v_ascii1  Number;
    v_ascii2  Number;
    v_n       Number;
    v_m       Number;
    v_m1      Number;
    v_m2      Number;
    v_m3      Number;
    v_cnt     Number;
  Begin
    v_invo_no := ltrim(rtrim(rtrim(p_inv_no)));
    v_m       := 0;
    For v_cnt In 1 .. 8 Loop
      --null;
      v_m := to_number(substr(v_invo_no, v_cnt + 2, 1)) + v_m;
    End Loop;

    return v_m;
    --v_m;
    /*
    v_invo_no :=ltrim(rtrim(rtrim(p_inv_no)));
    v_ascii1 := ascii(substr(v_invo_no,1,1));
    v_ascii2 := ascii(substr(v_invo_no,2,1));
    v_n := Trunc( ((v_ascii1-64)+(v_ascii2-64)) / 2);
    v_m1 := v_n Mod 10;
     v_m := 0;
    For v_cnt In 1..8 Loop
          v_m := to_number(substr(v_invo_no,v_cnt+2,1))*v_cnt+v_m;
    End Loop;
    v_m2 := Trunc(v_m/10) Mod 10;
    v_m3 := v_m Mod 10;
    return(to_char(v_m1)||to_char(v_m2)||to_char(v_m3)); */
  exception
    when others then
      return 0;
  End;

  function get_inv_no(p_org_no    number,
                      p_loc_no    number,
                      p_tax_bk_no Varchar) return Varchar2 Is
    v_result     Varchar2(32);
    v_start_no   Number(16);
    v_end_no     Number(16);
    v_current_no Number(16);
    v_px         Varchar2(32);
    v_status_flg Varchar2(32);
    app_exception Exception;
    app_msg Varchar2(1024);
  Begin
    Begin
      Select status_flg,
             nvl(a.curr_no, a.no_start - 1) curr_no,
             a.no_start,
             a.no_end,
             a.invo_no_px
        Into v_status_flg, v_current_no, v_start_no, v_end_no, v_px
        From tax_bk_mas a
       Where a.mas_no = p_tax_bk_no
         and a.org_no = p_org_no
         and a.loc_no = p_loc_no
         For Update;
    Exception
      When no_data_found Then
        app_msg := '#找不到此發票本' || p_tax_bk_no || '#';
        Raise app_exception;
    End;
    If v_current_no Is Null Then
      v_current_no := v_start_no;
    Else
      If v_current_no >= v_end_no Then
        app_msg := '#此發票本已滿' || p_tax_bk_no || '#';
        Raise app_exception;
      Else
        v_current_no := v_current_no + 1;
      End If;

    End If;

    Update tax_bk_mas a
       Set a.curr_no = v_current_no
     Where a.mas_no = p_tax_bk_no
       and a.org_no = p_org_no
       and a.loc_no = p_loc_no;

    v_result := v_px || lpad(to_char(v_current_no), 8, 0);

    Return v_result;
  Exception
    When app_exception Then
      Raise_Application_Error(-20002, app_Msg);
      --Return(Exception_Msg);
  End;

  Function tax_inv_post(p_User_No   Number,
                        p_Pk_No     Number,
                        p_no_commit varchar2 default 'N') Return Varchar2 Is
    App_exception Exception;
    Exception_msg    Varchar2(1024);
    v_status_flg     Varchar2(32);
    v_invo_no        Varchar2(32);
    v_invo_date      date;
    v_tax_bk_no      Varchar2(32);
    v_tax_bk_pk_no   Number(16);
    v_f_year         Number(4);
    v_f_period       Number(2);
    v_tax_code       Varchar2(32);
    v_tax_rate       Number(7, 3);
    v_item_date      Date;
    v_acc_code       Varchar2(32);
    v_acc_name       Varchar2(1024);
    v_src_amount     Number(16);
    v_tax_amount     Number(16);
    v_book_no        varchar2(32);
    v_mas_date       Date;
    v_cancel_flg     varchar2(32);
    v_bk_status_flg  varchar2(32);
    v_tax_ref        varchar2(32);
    v_amount         number(16);
    v_acc_status_flg varchar2(32);
    v_org_no         number(16);
    v_loc_no         number(16);
    v_invo_type      varchar2(32);
    v_upload_flg     varchar2(32);
    v_idn            varchar2(32);

    cursor c1 is
      select * from tax_inv_item where mas_pk_no = p_pk_no;
  Begin
    begin
    Select status_flg,
           a.tax_book_no,
           f_year,
           f_period,
           tax_code,
           tax_rate,
           f_invo_date,
           acc_code,
           acc_Name,
           src_amount,
           tax_amount,
           a.total_amount,

           mas_date,
           f_invo_date,
           a.tax_book_no,
           a.f_invo_no,
           a.org_no,
           a.loc_no,
           nvl(a.invo_type, 'S'),
           a.identify_id
      Into v_status_flg,
           v_tax_bk_no,
           v_f_year,
           v_f_period,
           v_tax_code,
           v_tax_rate,
           v_item_date,
           v_acc_code,
           v_acc_name,
           v_src_amount,
           v_tax_amount,
           v_amount,
           v_mas_date,
           v_invo_date,
           v_book_no,
           v_invo_no,
           v_org_no,
           v_loc_no,
           v_invo_type,
           v_idn
      From tax_inv_mas a
     Where pk_no = p_pk_no
       for update;
    exception
      when no_data_found then
          Exception_msg := '#錯誤的單據資料'||p_pk_no||'#';
           Raise App_Exception;
    end;

    if v_idn is null then
      v_idn:='3214';
      update  tax_inv_mas a
      set a.identify_id=v_idn
      where pk_no = p_pk_no;
      commit;
   end if;
     -- Raise App_Exception;

    If v_status_flg <> 'A' Then
      Exception_msg := '#錯誤的單據狀態#';
      Raise App_Exception;
    End If;

    Select a.status_flg, nvl(a.upload_flg,'Y')
      Into v_bk_status_flg, v_upload_flg
      From tax_bk_mas a
     Where mas_no = v_tax_bk_no
       and org_No = v_org_no
       and loc_no = v_loc_no;

    if v_bk_status_flg <> 'P' then
      Exception_msg := '#帳本未開啟#';
      Raise App_Exception;
    end if;

    begin
      select a.status_flg
        into v_acc_status_flg
        from acc_period_mas a
       where a.f_year = v_f_year
         and a.f_period = v_f_period
         and org_no = v_org_no;
    exception
      when no_data_found then
        Exception_msg := '#找不到帳期設定#';
        Raise App_Exception;
    end;
    if v_acc_status_flg <> 'O' then
      Exception_msg := '#帳期未開啟#';
      Raise App_Exception;
    end if;

    declare
      v_item_amt     number(16);
      v_item_src_amt number(16);
      v_item_tax_amt number(6);
    begin
      select sum(src_amount), sum(tax_amt), sum(amount)
        into v_item_src_amt, v_item_tax_amt, v_item_amt
        from tax_inv_item
       where mas_pk_no = p_pk_no;

      if (v_item_tax_amt <> v_tax_amount) or (v_item_src_amt <> v_amount) or
         (v_item_amt <> v_src_amount) then
        Exception_msg := '#明細金額與單頭金額加總不符#';
        Raise App_Exception;
      end if;
    end;

    if v_invo_no is not null then
      begin
        select cancel_flg
          into v_cancel_flg
          from tax_detail a
         where a.tax_inv_no = v_invo_no;
      exception
        when no_data_found then
          Exception_msg := '#找不到' || v_invo_no || '的發票資料#';
          Raise App_Exception;
      end;

      if v_cancel_flg <> 'Y' then
        Exception_msg := '#發票資料未取消#';
        raise app_exception;
      end if;

      delete tax_detail a where a.tax_inv_no = v_invo_no;
    else

      declare
        v_curr_invo_date date;
      begin
        if v_invo_date is not null then
          if v_book_no is not null then
            select max(f_invo_date)
              into v_curr_invo_date
              from tax_inv_mas a
             where a.tax_book_no = v_book_no
               and status_flg in ('P', 'N');
            if v_curr_invo_date is not null and
               trunc(v_curr_invo_date) > trunc(v_invo_date) then
              null;
              --          Exception_msg := '#錯誤的發票日期#';
              --           Raise App_Exception;
            end if;
          end if;
        end if;
      end;
      if v_invo_type != 'A' or v_invo_type is null then
        v_invo_no := get_inv_no(v_org_no, v_loc_no, v_tax_bk_no);
      else
        v_invo_no := null;
      end if;
    end if;

    Select pk_no
      Into v_tax_bk_pk_no
      From tax_bk_mas
     Where mas_no = v_tax_bk_no;

    if v_tax_code = 'OUTTAX2' then
      select a.company_uid
        into v_tax_ref
        from tgc_customer a
       where cust_id = v_acc_code;

    else
      v_tax_ref := null;
    end if;

    Insert Into tax_detail
      (mas_pk_no,
       org_no,
       f_year,
       f_period,
       tax_code,
       tax_type,
       tax_sign,
       item_date,
       acc_code,
       acc_name,
       tax_rate,
       tax_inv_no,
       src_amt,
       amount,
       cancel_flg,
       ref_date,
       tax_ref)
    Values
      (v_tax_bk_pk_no,
       v_org_no,
       v_f_year,
       v_f_period,
       v_tax_code,
       'O',
       '+',
       v_item_date,
       v_acc_code,
       v_acc_name,
       v_tax_rate,
       v_invo_no,
       v_src_amount,
       v_tax_amount,
       'N',
       v_mas_date,
       v_tax_ref);

    Update Tax_Inv_Mas a
       Set Status_Flg = 'P', a.f_Invo_No = v_Invo_No
     Where Pk_No = p_Pk_No;

    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TAXINV',
       p_Pk_No,
       Sysdate,
       p_User_No,
       '確認',
       Sys_Event_Seq.Nextval,
       '確認');

    if v_upload_flg = 'Y' then

      declare
        v_serial_no number(16);
        v_inv_no    varchar2(256);
      begin
        select SEQ_TAX_LOG_SERIAL_NO.nextval into v_serial_no from dual;

        Select nvl(a.f_invo_no, a.mas_no)
          into v_inv_no
          from tax_inv_mas a
         where a.pk_no = p_Pk_No;

        if v_invo_type = 'A' then
          insert into tax_inv_upload_dtl
            (serial_no,
             inv_no,
             create_date,
             format_type,
             status_flg,
             src_pk_no)
          values
            (v_serial_no, v_inv_no, sysdate, 'D0401', 'A', p_Pk_No);
        elsif v_tax_code = 'OUTTAX2' then
          insert into tax_inv_upload_dtl
            (serial_no,
             inv_no,
             create_date,
             format_type,
             status_flg,
             src_pk_no)
          values
            (v_serial_no, v_inv_no, sysdate, 'A0401', 'A', p_Pk_No);
        else

          insert into tax_inv_upload_dtl
            (serial_no,
             inv_no,
             create_date,
             format_type,
             status_flg,
             src_pk_no)
          values
            (v_serial_no, v_inv_no, sysdate, 'C0401', 'A', p_Pk_No);
        end if;

      end;
    end if;

    if p_no_commit = 'N' then
      Commit;
    end if;

    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;
  Function crt_inv_tax(p_user      number,
                       p_inv_pk_no number,
                       p_book_no   varchar2,
                       p_amt       number default null,
                       p_no_commit varchar2 default 'N',
                       src_code    varchar2 default null,
                       src_no      varchar2 default null,
                       src_pk_no   number default null,
                       p_org_no    number default 1) return varchar2 is
    App_exception       Exception;
    InvTaxCodeException Exception;
    Exception_msg    Varchar2(1024);
    v_status_flg     Varchar2(32);
    v_invo_no        Varchar2(32);
    v_invo_date      date;
    v_tax_bk_no      Varchar2(32);
    v_tax_bk_pk_no   Number(16);
    v_f_year         Number(4);
    v_f_period       Number(2);
    v_tax_flg        varchar2(32);
    v_tax_code       Varchar2(32);
    v_tax_rate       Number(7, 3);
    v_item_date      Date;
    v_acc_code       Varchar2(32);
    v_acc_name       Varchar2(1024);
    v_src_amount     Number(16);
    v_tax_amount     Number(16);
    v_book_no        varchar2(32);
    v_mas_date       Date;
    v_tax_code1      varchar2(32);
    v_tax_status_flg varchar2(32);
    v_title          varchar2(256);
    v_uid            varchar2(256);
    v_inv_no         varchar2(256);
    v_src_date       date;
    v_year           number(4);
    v_period         number(2);
    v_f_invo_date    date;
    v_invo_date2     date;
    v_book_pk_no     number(16);
    v_tax_acc_code   varchar2(32);
    v_pk_no          number(16);
    v_mas_no         varchar2(32);
    v_mas_pk_no      number(16);
    v_package_key    number(16);
    v_identify_id    varchar2(32);
    v_org_tax_no     varchar2(32);
    v_org_tax_date   date;
    v_purchase_no   varchar2(32);
  v_invo_type varchar2(32);
  Begin
    if src_code = 'BSMPUR' then
      Select acc_code,
             tax_code,
             tax_flg,
             mas_no,
             mas_date,
             null,
             substr(b.owner_phone, 7, 4)
        into v_acc_code,
             v_tax_code,
             v_tax_flg,
             v_inv_no,
             v_src_date,
             v_package_key,
             v_identify_id
        from bsm_purchase_mas a, bsm_client_mas b
       where pk_no = src_pk_no
         and a.serial_id = b.mac_address;
       v_invo_type:='O' ;
    end if;
    if src_code='BSMISS' then
            Select 'NULL' acc_code,
             'OUTTAX1',
             'Y',
             a.mas_no,
             a.mas_date,
             null,
             substr(b.owner_phone, 7, 4),
             a.purchase_no
        into v_acc_code,
             v_tax_code,
             v_tax_flg,
             v_inv_no,
             v_src_date,
             v_package_key,
             v_identify_id,
             v_purchase_no
        from bsm_issue_mas a, bsm_client_mas b
       where pk_no = src_pk_no
         and a.client_id = b.mac_address;
      select c.tax_inv_no,c.tax_inv_date into v_org_tax_no,v_org_tax_date  from bsm_purchase_mas c where mas_no=v_purchase_no;
      --退費折讓
      v_invo_type:='A';
    end if;

    v_tax_code := nvl(v_tax_code, 'OUTTAX1');

    begin
      select pk_no, tax_code, status_flg
        into v_book_pk_no, v_tax_code1, v_tax_status_flg
        from tax_bk_mas a
       where a.mas_no = p_book_no
         and a.org_no = p_org_no;
    exception
      when no_data_found then
        exception_msg := '找不到發票本';
        raise app_exception;
    end;

    if v_tax_status_flg <> 'P' then
      exception_msg := '發票本未開啟';
      raise app_exception;
    end if;

    /*   if v_tax_code <> v_tax_code then
       exception_msg := '發票代號與帳單設定的不同';
       raise InvTaxCodeException;
    end if;*/

    begin
      select tax_rate
        into v_tax_rate
        from tax_mas
       where tax_code = v_tax_code;
    exception
      when no_data_found then
        exception_msg := '#發票主檔未設定' || v_inv_no || '#';
        raise app_exception;
    end;

    begin
      if v_acc_code is null then
        v_acc_code := sysapp_util.get_sys_value('TAX',
                                                'Defaule Account code',
                                                'NULL');
      end if;
      select nvl(a.company_name, a.cust_name), nvl(a.company_uid, null)
        into v_title, v_uid
        from tgc_customer a
       where a.cust_id = v_acc_code;
    exception
      when no_data_found then
        exception_msg := '找不到客戶';
        raise app_exception;
    end;

    v_mas_pk_no := null;

    v_year        := to_number(to_char(sysdate, 'YYYY'));
    v_period      := to_number(to_char(sysdate, 'MM'));
    v_f_invo_date := nvl(set_invo_date, sysdate);

    select max(a.f_invo_date)
      into v_invo_date2
      from tax_inv_mas a
     where status_flg in ('P', 'N')
       and a.tax_book_no = p_book_no;

    if (v_invo_date2 is not null) and (v_invo_date2 > v_f_invo_date) then
      exception_msg := '#發票日期有問題=' || to_char(v_invo_date2, 'YYYYMMDD') || '#';
      raise app_exception;
    end if;

    v_tax_acc_code := sysapp_util.get_sys_value('TGCTAXINV',
                                                'TAX_ACC_CODE',
                                                '2132');

    declare
      /*  cursor c_dtl is select mas_pk_no,
          pk_no,
          chg_pk_no,
          item_pk_no,
          chg_code,
          chg_type,
          bill_type,
          pm_code,
          amount,
          start_date,
          end_date,
          grp_no,
          tax_flg,
          tax_code,
          item_code,
          item_name
      from service_invo_dtl
      where mas_pk_no = p_inv_pk_no
       and chg_code <> 'B'
       and amount >=0
       and nvl(tax_flg,'Y') = 'Y'; */
      cursor c2_dtl is
        select a.mas_pk_no,
               a.pk_no,
               null chg_pk_no,
               null item_pk_no,
               a.chg_code,
               a.chg_type,
               null bill_type,
               null pm_code,
               a.amount amount,
               null start_date,
               null end_date,
               null grp_no,
               'Y' tax_flg,
               null tax_code,
               null item_code,
               chg_name,
               (Select name
                  from (select b.package_cat1 || ' ' || b.description name,
                               b.package_id
                          from bsm_package_mas b
                        union all
                        select package_name, c.PACKAGE_ID
                          from STK_PACKAGE_MAS c) t2
                 where t2.package_id = a.package_id) item_name
          from bsm_purchase_item a
         where mas_pk_no = src_pk_no
         union all

         select a.mas_pk_no,
               a.pk_no,
               null chg_pk_no,
               null item_pk_no,
               '' chg_code,
               '' chg_type,
               null bill_type,
               null pm_code,
               a.refund_amt amount,
               null start_date,
               null end_date,
               null grp_no,
               'Y' tax_flg,
               null tax_code,
               null item_code,
               '月租費' chg_name,
                         (Select name
                  from (select b.package_cat1 || ' ' || b.description name,
                               b.package_id
                          from bsm_package_mas b
                        union all
                        select package_name, c.PACKAGE_ID
                          from STK_PACKAGE_MAS c) t2
                 where t2.package_id = a.new_package_id)
          from bsm_issue_item a
         where mas_pk_no = src_pk_no
         and refund_amt>0;
      v_item_name       varchar(238);
      v_chg_name        varchar2(256);
      v_chg_tax_flg     varchar2(256);
      v_dr_acc_code     varchar2(256);
      v_cr_acc_code     varchar2(256);
      v_tax_t_amount    number(16);
      v_dtl_tax_amount  number(16);
      v_t_amount        number(16);
      v_dtl_tax_flg     varchar2(32);
      v_detail_pk_no    number(16);
      v_sum_amt         number(16);
      v_sum_tax_amt     number(16);
      v_sum_dtl_tax_amt number(16);
      v_sum_t_amount    number(16);
      v_dis_amt         number(16);
      v_in_amt          number(16);
      v_amt             number(16);
      v_inv_tax_cnt     number(16);
      v_src_pk_no       number(16);
      v_loop            boolean;

      dtlrec c2_dtl%rowtype;

    begin
      v_sum_amt         := 0;
      v_sum_dtl_tax_amt := 0;
      v_sum_t_amount    := 0;

      if p_amt is null then

        if src_code = 'BSMPUR' then
          select sum(amount)
            into v_in_amt
            from bsm_purchase_item
           where mas_pk_no = src_pk_no;
          v_src_pk_no := src_pk_no;
        end if;

        if src_code = 'BSMISS' then
          select sum(amt)
            into v_in_amt
            from bsm_issue_item x
           where mas_pk_no = src_pk_no;
          v_src_pk_no := src_pk_no;
        end if;

      else
        v_in_amt := p_amt;
      end if;

      if src_code in ( 'BSMPUR','BSMISS') then
        open c2_dtl;
        fetch c2_dtl
          into dtlrec;
        v_loop := c2_dtl%notfound;
      end if;

      while (not v_loop) loop
        begin
          if dtlrec.chg_code is null then
            dtlrec.chg_code := sysapp_util.get_sys_value('BSMPUR',
                                                         'Default charge code',
                                                         'PMONTHFEE');
          end if;

          select chg_name, tax_flg, acc_code, cr_acc_code
            into v_chg_name, v_dtl_tax_flg, v_dr_acc_code, v_cr_acc_code
            from service_charge_mas a
           where chg_code = dtlrec.chg_code;

        exception
          when no_data_found then
            exception_msg := '找不到CHG_CODE';
            raise app_exception;
        end;

        v_amt := dtlrec.amount;

        if src_code in ( 'BSMPUR','BSMISS') then
          v_tax_t_amount := 0;
          v_inv_tax_cnt  := 0;

        end if;

        if v_tax_t_amount > 0 then
          v_amt := v_amt - v_tax_t_amount;
        end if;

        if v_in_amt >= v_amt then
          v_in_amt := v_in_amt - v_amt;
        else
          v_amt    := v_in_amt;
          v_in_amt := 0;
        end if;

        if nvl(v_chg_tax_flg, 'Y') = 'Y' then

          v_chg_name := tgc_util.get_chg_name(dtlrec.chg_code);
          if v_chg_name = '售價' then
            v_chg_name := null;
          end if;
          if dtlrec.item_code is not null then
            null;

          else
            if src_code in ( 'BSMPUR','BSMISS') then
              v_item_name := dtlrec.item_name;
            else
              v_item_name := v_chg_name;
            end if;
          end if;

          v_tax_t_amount := nvl(v_tax_t_amount, 0);
          v_inv_tax_cnt  := nvl(v_inv_tax_cnt, 0);

          if nvl(v_chg_tax_flg, 'Y') = 'Y' then
            v_t_amount       := round((v_amt) / (1 + v_tax_rate));
            v_dtl_tax_amount := (v_amt) - v_t_amount;
          end if;

          if v_t_amount > 0 then
            v_sum_amt         := v_sum_amt + (v_amt);
            v_sum_dtl_tax_amt := v_sum_dtl_tax_amt + v_dtl_tax_amount;
            v_sum_t_amount    := v_sum_t_amount + v_t_amount;
          end if;

          if (v_t_amount > 1 and v_inv_tax_cnt = 0) or
             ((v_t_amount >= 0 and v_t_amount <= 1) and v_inv_tax_cnt = 0) then
            if v_mas_pk_no is null then
              select seq_sys_no.nextval into v_mas_pk_no from dual;
              v_mas_no := sysapp_util.Get_Mas_No(1,
                                                 1,
                                                 sysdate,
                                                 'TAXINV',
                                                 v_pk_no);

              insert into tax_inv_mas
                (org_no,
                 pk_no,
                 mas_code,
                 mas_no,
                 mas_date,
                 create_user,
                 create_date,
                 status_flg,
                 src_code,
                 src_pk_no,
                 src_no,
                 src_date,
                 description,
                 f_year,
                 f_period,
                 f_invo_date,
                 f_invo_no,
                 tax_code,
                 tax_rate,
                 tax_book_no,
                 tax_book_pk_no,
                 acc_code,
                 acc_name,
                 src_amount,
                 tax_amount,
                 total_amount,
                 tax_acc_code,
                 remark,
                 invo_type,
                 company_uid,
                 chk_pk_no,
                 identify_id)
              values
                (p_org_no,
                 v_mas_pk_no,
                 'TAXINV',
                 v_mas_no,
                 sysdate,
                 p_user,
                 sysdate,
                 'A',
                 'SRVINV',
                 v_src_pk_no,
                 v_inv_no,
                 v_src_date,
                 null,
                 v_year,
                 v_period,
                 v_f_invo_date,
                 null,
                 v_tax_code,
                 v_tax_rate,
                 p_book_no,
                 v_book_pk_no,
                 v_acc_code,
                 v_title,
                 0,
                 0,
                 0,
                 v_tax_acc_code,
                 null,
                 v_invo_type,
                 v_uid,
                 v_chk_pk_no,
                 v_identify_id);
            end if;
            select seq_sys_no.nextval into v_pk_no from dual;
            insert into tax_inv_item
              (mas_pk_no,
               pk_no,
               item_name,
               tax_flg,
               amount,
               remark,
               qty,
               dr_acc_code,
               cr_acc_code,
               tax_acc_code,
               inv_pk_no,
               detail_pk_no,
               chg_code,
               pm_code,
               package_key,
               item_pk_no,
               tax_amt,
               src_amount,
               ref_tax_no,
               ref_tax_date)
            values
              (v_mas_pk_no,
               v_pk_no,
               v_item_name,
               v_dtl_tax_flg,
               v_t_amount,
               null,
               1,
               v_dr_acc_code,
               v_cr_acc_code,
               v_tax_acc_code,
               p_inv_pk_no,
               v_detail_pk_no,
               dtlrec.chg_code,
               dtlrec.pm_code,
               v_package_key,
               dtlrec.pk_no,
               v_dtl_tax_amount,
               v_amt,
               v_org_tax_no,
               v_org_tax_date);
          end if;
        end if;
        if  src_code in ( 'BSMPUR','BSMISS') then
          fetch c2_dtl
            into dtlrec;
          v_loop := c2_dtl%notfound;

        end if;
      end loop;

      if  src_code in ( 'BSMPUR','BSMISS') then
        close c2_dtl;

      end if;

      update tax_inv_mas a
         set a.total_amount = v_sum_amt,
             a.tax_amount   = round(v_sum_amt -
                                    (v_sum_amt / (1 + v_tax_rate))),
             a.src_amount   = round((v_sum_amt / (1 + v_tax_rate)))
       where pk_no = v_mas_pk_no;
      v_dis_amt := round((round(v_sum_amt - (v_sum_amt / (1 + v_tax_rate))) -
                         v_sum_dtl_tax_amt) * (1 + v_tax_rate));

      update tax_inv_item a
         set a.amount  = a.amount + (round((v_sum_amt / (1 + v_tax_rate))) -
                         v_sum_t_amount),
             a.tax_amt = a.tax_amt +
                         (round(v_sum_amt - (v_sum_amt / (1 + v_tax_rate))) -
                         v_sum_dtl_tax_amt)
       where a.pk_no = v_pk_no;
    end;

    if p_no_commit = 'N' then
      Commit;
    end if;

    Declare
      v_msg      Varchar2(256);
      v_inv_no   Varchar2(256);
      v_inv_date Date;
    Begin
      If v_mas_pk_no Is Not Null Then
        v_msg := tax_post.tax_inv_post(p_user, v_mas_pk_no, p_no_commit);
        Select f_invo_no, f_invo_date
          Into v_inv_no, v_inv_date
          From tax_inv_mas a
         Where a.pk_no = v_mas_pk_no;

      End If;
    End;
    if p_no_commit = 'N' then
      Commit;
    end if;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function tax_inv_unpost(p_User_No Number, p_Pk_No Number) Return Varchar2 Is
    App_exception Exception;
    Exception_msg    Varchar2(1024);
    v_status_flg     Varchar2(32);
    v_invo_no        Varchar2(32);
    v_invo_date      date;
    v_tax_bk_no      Varchar2(32);
    v_tax_bk_pk_no   Number(16);
    v_f_year         Number(4);
    v_f_period       Number(2);
    v_tax_code       Varchar2(32);
    v_tax_rate       Number(7, 3);
    v_item_date      Date;
    v_acc_code       Varchar2(32);
    v_acc_name       Varchar2(1024);
    v_src_amount     Number(16);
    v_tax_amount     Number(16);
    v_book_no        varchar2(32);
    v_mas_date       Date;
    v_bk_status_flg  varchar2(32);
    v_acc_status_flg varchar2(32);
    v_tax_mas_no     varchar2(32);
    v_tax_count      number(16);

    cursor c1 is
      select * from tax_inv_item where mas_pk_no = p_pk_no;
  Begin

    Select status_flg,
           a.tax_book_no,
           f_year,
           f_period,
           tax_code,
           tax_rate,
           f_invo_date,
           acc_code,
           acc_Name,
           src_amount,
           tax_amount,
           mas_date,
           f_invo_date,
           a.tax_book_no,
           mas_no,
           f_invo_no
      Into v_status_flg,
           v_tax_bk_no,
           v_f_year,
           v_f_period,
           v_tax_code,
           v_tax_rate,
           v_item_date,
           v_acc_code,
           v_acc_name,
           v_src_amount,
           v_tax_amount,
           v_mas_date,
           v_invo_date,
           v_book_no,
           v_tax_mas_no,
           v_invo_no
      From tax_inv_mas a
     Where pk_no = p_pk_no;

    If v_status_flg <> 'P' Then
      Exception_msg := '#錯誤的單據狀態#';
      Raise App_Exception;
    End If;

    begin
      select a.status_flg
        into v_acc_status_flg
        from acc_period_mas a
       where a.f_year = v_f_year
         and a.f_period = v_f_period;
    exception
      when no_data_found then
        Exception_msg := '#找不到帳期設定#';
        Raise App_Exception;
    end;
    if v_acc_status_flg <> 'O' then
      Exception_msg := '#帳期未開啟#';
      Raise App_Exception;
    end if;

    Select a.status_flg
      Into v_bk_status_flg
      From tax_bk_mas a
     Where mas_no = v_tax_bk_no;

    if v_bk_status_flg <> 'P' then
      Exception_msg := '#帳本未開啟#';
      Raise App_Exception;
    end if;

    if v_tax_count > 0 then
      Exception_msg := '#已開發票#';
      Raise App_Exception;
    end if;

    update tax_detail a
       set cancel_flg = 'Y'
     where a.tax_inv_no = v_invo_no;

    Update Tax_Inv_Mas a Set Status_Flg = 'A' Where Pk_No = p_Pk_No;

    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TAXINV',
       p_Pk_No,
       Sysdate,
       p_User_No,
       'UnPost',
       Sys_Event_Seq.Nextval,
       'UnPost');

    declare
      v_serial_no number(16);
      v_inv_no    varchar2(256);
    begin
      select SEQ_TAX_LOG_SERIAL_NO.nextval into v_serial_no from dual;

      Select a.f_invo_no
        into v_inv_no
        from tax_inv_mas a
       where a.pk_no = p_Pk_No;
     if v_inv_no is not null then
      insert into tax_inv_upload_dtl
        (serial_no,
         inv_no,
         create_date,
         format_type,
         status_flg,
         src_pk_no)
      values
        (v_serial_no, v_inv_no, sysdate, 'C0701', 'A', p_Pk_No);
     end if;
    end;

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function tax_inv_cancel(p_User_No Number, p_Pk_No Number) Return Varchar2 Is
    App_exception Exception;
    Exception_msg  Varchar2(1024);
    v_status_flg   Varchar2(32);
    v_invo_no      Varchar2(32);
    v_invo_date    date;
    v_tax_bk_no    Varchar2(32);
    v_tax_bk_pk_no Number(16);
    v_f_year       Number(4);
    v_f_period     Number(2);
    v_tax_code     Varchar2(32);
    v_tax_rate     Number(7, 3);
    v_item_date    Date;
    v_acc_code     Varchar2(32);
    v_acc_name     Varchar2(1024);
    v_src_amount   Number(16);
    v_tax_amount   Number(16);
    v_book_no      varchar2(32);
    v_mas_date     Date;
    v_cancel_flg   varchar2(32);

    cursor c1 is
      select * from tax_inv_item where mas_pk_no = p_pk_no;
  Begin

    Select status_flg,
           a.tax_book_no,
           f_year,
           f_period,
           tax_code,
           tax_rate,
           f_invo_date,
           acc_code,
           acc_Name,
           src_amount,
           tax_amount,
           mas_date,
           f_invo_date,
           a.tax_book_no,
           a.f_invo_no
      Into v_status_flg,
           v_tax_bk_no,
           v_f_year,
           v_f_period,
           v_tax_code,
           v_tax_rate,
           v_item_date,
           v_acc_code,
           v_acc_name,
           v_src_amount,
           v_tax_amount,
           v_mas_date,
           v_invo_date,
           v_book_no,
           v_invo_no
      From tax_inv_mas a
     Where pk_no = p_pk_no;

    If v_status_flg <> 'P' Then
      Exception_msg := '#錯誤的單據狀態#';
      Raise App_Exception;
    End If;
    /*
    declare
      v_curr_invo_date date;
    begin
      if v_invo_date is not null then
        if v_book_no is not null then
           select max(f_invo_date)
            into v_curr_invo_date
            from tax_inv_mas a
           where a.tax_book_no = v_book_no
             and status_flg in ('P', 'N');
          if v_curr_invo_date is not null and
             v_curr_invo_date > v_invo_date then
              Exception_msg := '#錯誤的發票日期#';
              Raise App_Exception;
          end if;
        end if;
      end if;
    end;
    */
    if v_invo_no is not null then
      begin
        select cancel_flg
          into v_cancel_flg
          from tax_detail a
         where a.tax_inv_no = v_invo_no;
      exception
        when no_data_found then
          Exception_msg := '#找不到' || v_invo_no || '的發票資料#';
          Raise App_Exception;
      end;

      if nvl(v_cancel_flg, 'N') <> 'Y' then
        update tax_detail a
           set cancel_flg = 'Y'
         where a.tax_inv_no = v_invo_no;
        --  Exception_msg := '#發票資料未取消#';
        --  raise app_exception;
      end if;

    end if;

    Update Tax_Inv_Mas a
       Set Status_Flg = 'C', a.f_Invo_No = v_Invo_No
     Where Pk_No = p_Pk_No;

    declare
      v_serial_no number(16);
      v_inv_no    varchar2(256);
    begin
      select SEQ_TAX_LOG_SERIAL_NO.nextval into v_serial_no from dual;
      Select a.f_invo_no
        into v_inv_no
        from tax_inv_mas a
       where a.pk_no = p_Pk_No;

      if v_tax_code = 'OUTTAX2' then

        insert into tax_inv_upload_dtl
          (serial_no,
           inv_no,
           create_date,
           format_type,
           status_flg,
           src_pk_no)
        values
          (v_serial_no, v_inv_no, sysdate, 'A0501', 'A', p_Pk_No);
      else

        insert into tax_inv_upload_dtl
          (serial_no,
           inv_no,
           create_date,
           format_type,
           status_flg,
           src_pk_no)
        values
          (v_serial_no, v_inv_no, sysdate, 'C0501', 'A', p_Pk_No);
      end if;

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
      ('TAXINV',
       p_Pk_No,
       Sysdate,
       p_User_No,
       '作廢',
       Sys_Event_Seq.Nextval,
       '作廢');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function crt_inv_tax_f(p_proc_no Number) Return Varchar2 is
    App_exception Exception;
    Exception_msg Varchar2(1024);
    msg           varchar2(1024);

  Begin
    return null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

end TAX_POST_DEV;
/

