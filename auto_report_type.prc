CREATE OR REPLACE PROCEDURE IPTV."AUTO_REPORT_TYPE" is
  v_msg varchar2(256);
begin

  -- update client master
  declare
    cursor c1 is
      select mac_address, serial_no, a.owner_phone, real_mac_address
        from bsm_client_mas a
       where a.report_type is null
         and a.status_flg in ('A', 'W');
    v_report_type varchar2(64);
    v_char        varchar2(64);
    v_softgroup   varchar2(64);
  begin
    -- 常有誤判Report_Type為N的正式資料，基本上有開發票號碼的將report_type清空  
    update bsm_purchase_mas
       set report_type = 'P'
     where report_type = 'N'
       and TAX_INV_NO is not null
       and mas_date >= sysdate - 30;
    commit;
  
    for i in c1 loop
      v_report_type := 'P';
      begin
        if i.owner_phone like '0999%' then
          if i.owner_phone like '09990%' then
            v_report_type := 'P';
          else
            v_report_type := 'N';
          end if;
        end if;
        select 'x'
          into v_char
          from mfg_dev_account_mas a
         where a.owner_phone_no = i.owner_phone;
        v_report_type := 'N';
      exception
        when no_data_found then
          begin
            select 'x'
              into v_char
              from mfg_iptv_report_type a
             where (a.real_mac_address = i.real_mac_address or
                   a.real_mac_address in
                   (select device_id
                       from bsm_client_device_list b
                      where b.client_id = i.mac_address))
               and rownum <= 1;
            v_report_type := 'N';
          exception
            when no_data_found then
              null;
          end;
      end;
    
      declare
        v_sg varchar2(64);
        v_t  varchar2(64);
      begin
        select a.software_group
          into v_sg
          from mfg_iptv_mas a
         where a.mac_address = i.mac_address;
        select a.report_type
          into v_t
          from mfg_softwaregroup_mas a
         where a.software_group = v_sg;
        if v_t = 'N' then
          v_report_type := 'N';
        end if;
      exception
        when no_data_found then
          null;
      end;
    
      update bsm_client_mas a
         set a.report_type = v_report_type
       where a.mac_address = i.mac_address;
      commit;
    end loop;
  
  end;

  -- update purchase master
  declare
    cursor c1 is
      Select a.pay_type,
             b.package_id,
             a.response_code,
             a.approval_code,
             a.serial_no,
             a.serial_id,
             a.mas_no,
             a.src_no,
             a.pk_no
        from bsm_purchase_mas a, bsm_purchase_item b
       where report_type is null
         and b.mas_pk_no = a.pk_no
         and a.status_flg <> 'C';
    v_t           varchar2(64);
    v_report_type varchar2(64);
  
  begin
    for c1rec in c1 loop
      v_report_type := 'P';
    
      -- check credit card
      if c1rec.pay_type not in ('兌換券', '儲值卡') then
        begin
          if c1rec.pay_type in ('信用卡', 'CREDIT', 'credit') then
            if (c1rec.response_code = 'PRC=0' or
               c1rec.approval_code is null) then
              v_report_type := 'N';
            else
              v_report_type := 'P';
            end if;
     --     elsif  c1rec.pay_type in ('TBC') then
      --       v_report_type := 'N';
          else
            begin
              select 'N'
                into v_t
                from bsm_client_mas
               where owner_phone in
                     (select owner_phone_no from mfg_dev_account_mas)
                 and serial_id = c1rec.serial_id;
              v_t           := 'N';
              v_report_type := 'N';
            exception
              when no_data_found then
                null;
            end;
            begin
              select report_type
                into v_t
                from bsm_client_mas
               where mac_address = c1rec.serial_id;
              if v_t = 'N' then
                v_report_type := 'N';
              end if;
            exception
              when no_data_found then
                v_t           := 'N';
                v_report_type := 'N';
            end;
          
            begin
              select decode(nvl(a.report_type, 'P'),
                            'T',
                            'P',
                            nvl(a.report_type, 'P'))
                into v_t
                from bsm_package_mas a
               where package_id = c1rec.package_id;
              if v_t = 'N' then
                v_report_type := 'N';
              end if;
            exception
              when no_data_found then
                v_t           := 'N';
                v_report_type := 'N';
            end;
          
            --   if c1rec.pay_type in ('中華電信帳單', 'IOS', 'TSTAR', 'Bandott','GOOGLEPLAY') then
            v_report_type := 'P';
            v_t           := 'P';
          
            update bsm_purchase_mas a
               set report_type = v_report_type
             where a.mas_no = c1rec.mas_no;
          
            --    end if;
          
          end if;
        
        exception
          when no_data_found then
            v_t := 'P';
        end;
      
        update bsm_purchase_mas a
           set report_type = v_report_type
         where a.mas_no = c1rec.mas_no;
      
      end if;
    
      if c1rec.pay_type in ('兌換券') then
      
        declare
          v_cup_id     varchar2(64);
          v_program_id varchar2(64);
        begin
          select a.program_id
            into v_program_id
            from bsm_coupon_mas a
           where a.mas_no = c1rec.src_no;
        
          select report_type
            into v_t
            from bsm_coupon_prog_mas a
           where a.cup_program_id = v_program_id;
        
          if v_t = 'N' then
            v_report_type := 'N';
          end if;
          /* 
            begin
              select report_type
                into v_t
                from bsm_client_mas
               where mac_address = c1rec.serial_id;
              if v_t = 'N' then
                v_report_type := 'N';
              end if;
            exception
              when no_data_found then
                v_t           := 'N';
                v_report_type := 'N';
            end;
          */
        
        exception
          when no_data_found then
            null;
        end;
      
        update bsm_purchase_mas a
           set report_type = v_t
         where a.mas_no = c1rec.mas_no;
      
        update bsm_coupon_mas a
           set report_type = v_t
         where a.mas_no = c1rec.src_no;
      
      end if;
    
      declare
        cursor c_dtl is
          select pk_no
            from bsm_client_details
           where src_pk_no = c1rec.pk_no;
      begin
        for rec_dtl in c_dtl loop
          update bsm_client_details a
             set a.report_type = v_t
           where a.pk_no = rec_dtl.pk_no;
        
          update bsm_client_event_log a
             set a.report_type = v_t
           where a.detail_pk_no = rec_dtl.pk_no;
        
        end loop;
      end;
      commit;
    end loop;
  
    for c1rec in c1 loop
      v_report_type := 'P';
      declare
        v_owner_phone      varchar2(32);
        v_real_mac_address varchar2(32);
        v_char             varchar2(1);
      begin
        begin
          select report_type, owner_phone, real_mac_address
            into v_t, v_owner_phone, v_real_mac_address
            from bsm_client_mas
           where mac_address = c1rec.serial_id;
          if v_t = 'N' then
            v_report_type := 'N';
          end if;
        exception
          when no_data_found then
            v_t           := 'N';
            v_report_type := 'N';
        end;
      
        -- check pay = '儲值卡'
        if c1rec.pay_type in ('儲值卡') then
        
          begin
            if v_owner_phone like '090%' or v_owner_phone like '099%' then
              v_report_type := 'N';
            end if;
            select 'x'
              into v_char
              from mfg_dev_account_mas a
             where a.owner_phone_no = v_owner_phone;
            v_report_type := 'N';
          exception
            when no_data_found then
              begin
                select 'x'
                  into v_char
                  from mfg_iptv_report_type a
                 where a.real_mac_address = v_real_mac_address;
                v_report_type := 'N';
              exception
                when no_data_found then
                  null;
              end;
          end;
        
          declare
            v_sg varchar2(64);
            v_t  varchar2(64);
          begin
            select a.software_group
              into v_sg
              from mfg_iptv_mas a
             where a.mac_address = c1rec.serial_id;
            select a.report_type
              into v_t
              from mfg_softwaregroup_mas a
             where a.software_group = v_sg;
            if v_t = 'N' then
              v_report_type := 'N';
            end if;
          exception
            when no_data_found then
              null;
          end;
        
          if v_t = 'N' then
            v_report_type := 'N';
          end if;
        
          update bsm_purchase_mas a
             set report_type = v_report_type
           where a.mas_no = c1rec.mas_no;
        end if;
      
        declare
          cursor c_dtl is
            select pk_no
              from bsm_client_details
             where src_pk_no = c1rec.pk_no;
        begin
          for rec_dtl in c_dtl loop
            update bsm_client_details a
               set a.report_type = v_report_type
             where a.pk_no = rec_dtl.pk_no;
          
            update bsm_client_event_log a
               set a.report_type = v_report_type
             where a.detail_pk_no = rec_dtl.pk_no;
          
          end loop;
        end;
        commit;
      end;
    end loop;
  
    -- update coupon master
    begin
      update bsm_coupon_mas a
         set a.report_type =
             (select report_type
                from bsm_coupon_prog_mas c
               where c.cup_program_id = a.program_id)
       where a.report_type is null;
      commit;
    end;
  
    -- update client details
    declare
      cursor c1 is
        select mac_address, package_id, rowid rid
          from bsm_client_details
         where report_type is null
           and (src_no is null or src_no = 'CLIENT_ACTIVATED');
      v_report_type varchar2(64);
      v_t           varchar2(64);
    begin
      for c1rec in c1 loop
        v_report_type := 'P';
        begin
          select report_type
            into v_t
            from bsm_client_mas
           where mac_address = c1rec.mac_address;
          if v_t = 'N' then
            v_report_type := 'N';
          end if;
        exception
          when no_data_found then
            dbms_output.put_line('Not find client id :' ||
                                 c1rec.mac_address);
        end;
        begin
          select report_type
            into v_t
            from bsm_package_mas
           where package_id = c1rec.package_id;
        exception
          when no_data_found then
            v_report_type := 'N';
        end;
        if v_t = 'N' then
          v_report_type := 'N';
        end if;
        update bsm_client_details
           set report_type = v_report_type
         where rowid = c1rec.rid;
        commit;
      end loop;
    
    end;
  end;

  declare
    cursor c1 is
      select src_no, mac_address, package_id, rowid rid
        from bsm_client_details
       where report_type is null
         and (src_no is not null and src_no not in ('CLIENT_ACTIVATED'));
    v_report_type varchar2(64);
    v_t           varchar2(64);
  begin
    for c1rec in c1 loop
      v_report_type := 'P';
      begin
        select report_type
          into v_t
          from bsm_client_mas
         where mac_address = c1rec.mac_address;
        if v_t = 'N' then
          v_report_type := 'N';
        end if;
      exception
        when no_data_found then
          dbms_output.put_line('Not find client id :' || c1rec.mac_address);
      end;
      begin
        select report_type
          into v_t
          from bsm_purchase_mas a
         where src_no = c1rec.src_no;
      exception
        when no_data_found then
          v_report_type := 'N';
      end;
      if v_t = 'N' then
        v_report_type := 'N';
      end if;
      update bsm_client_details
         set report_type = v_report_type
       where rowid = c1rec.rid;
      commit;
    end loop;
  end;
  /*
    -- event Log process
    v_msg := bsm_cdi_service.cache_event(sysdate - (10 / (24 * 60)),
                                         sysdate + (10 / (24 * 60)));
  
    declare
      cursor c1 is
        select rowid rid,
               client_id,
               event_time,
               replace(client_read_access, '.mp4', '') asset_id,
               event_name,
               package_id
          from bsm_client_event_log a
         where a.event_name in
               ('E_PLAY', 'SSAS_connection_allowed', 'E_STOP', 'E_STOCK')
           and (a.report_type is null or a.package_id is null)
           and client_id is not null
           and a.event_time > sysdate - 30;
      v_package_id  varchar2(64);
      v_pk_no       number(16);
      v_report_type varchar2(64);
    begin
      for c1rec in c1 loop
        v_package_id  := 'N';
        v_report_type := 'N';
        v_pk_no       := BSM_CDI_SERVICE.update_bsm_detail(c1rec.client_id,
                                                           c1rec.asset_id,
                                                           c1rec.event_time);
        if v_pk_no is not null then
          select package_id, report_type
            into v_package_id, v_report_type
            from bsm_client_details
           where pk_no = v_pk_no;
        
        end if;
      
        update bsm_client_event_log a
           set a.package_id   = v_package_id,
               a.report_type  = v_report_type,
               a.detail_pk_no = v_pk_no
         where rowid = c1rec.rid;
        commit;
      end loop;
    end;
  */
  -- E_Connect_Log Process
  /*
  declare
    cursor c1 is
      select rowid rid,
             client_id,
             event_time,
             replace(client_read_access, '.mp4', '') asset_id,
             event_name,
             package_id
        from bsm_client_event_log a
       where a.event_name in ('E_CONNECT')
         and (a.report_type is null)
         and client_id is not null;
    v_report_type varchar2(64);
  begin
    for c1rec in c1 loop
      begin
        select report_type
          into v_report_type
          from bsm_client_mas
         where mac_address = c1rec.client_id;
      exception
        when no_data_found then
          v_report_type := 'N';
      end;
    
      --    if c1rec.package_id is null then
      update bsm_client_event_log a
         set a.report_type = v_report_type
       where rowid = c1rec.rid;
      --   end if;
      commit;
    end loop;
  end; */

  -- chime_proce;

end AUTO_REPORT_TYPE;
/

