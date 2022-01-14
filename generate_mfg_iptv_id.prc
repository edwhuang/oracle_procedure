CREATE OR REPLACE PROCEDURE IPTV."GENERATE_MFG_IPTV_ID"(p_client_id varchar2) is
  v_serial_no      number(16);
  v_serial_id      varchar2(32);
  v_status_flg     varchar2(32);
  v_defaule_group  varchar2(32);
  v_software_group varchar2(32);
  v_software_ver   varchar2(64);
  v_char           varchar2(32);
  cursor c1 is
    select serial_id, a.software_ver, a.software_grp, a.real_mac_address
      from bsm_client_mas a
     where not exists (select 'x'
              from mfg_iptv_mas b
             where b.mac_address = a.mac_address
               and b.software_group is not null)
       and (a.software_grp is null or a.software_ver is null)
       and a.mac_address = p_client_id;
begin
  insert into temp_activate_log
    (mac_address, id, owner_phone, event_date, step)
  values
    (p_client_id, p_client_id, '', sysdate, 'A1.start處理software group');
  commit;
  for c1rec in c1 loop
    Select Seq_Bsm_Client_Mas.Nextval Into v_serial_no From Dual;
  
    if c1rec.software_grp is null then
      begin
        select software_group
          into v_software_group
          from MFG_IPTV_FORCE_GROUP
         where real_mac_address = c1rec.real_mac_address;
      exception
        when no_data_found then
          if c1rec.software_ver is null then
            insert into temp_activate_log
              (mac_address, id, owner_phone, event_date, step)
            values
              (p_client_id, p_client_id, '', sysdate, '2.get ver from cdi');
            commit;
            v_software_ver := get_result_current_swver(c1rec.serial_id);
          else
            v_software_ver := c1rec.software_ver;
          end if;
          insert into temp_activate_log
            (mac_address, id, owner_phone, event_date, step)
          values
            (p_client_id,
             p_client_id,
             '',
             sysdate,
             'A2.get software group');
          commit;
          begin
            select software_group
              into v_software_group
              from mfg_softwaregroup_mas a
             where a.project_no = upper(substr(v_software_ver, 1, 7))
               and project_default = 'Y';
          exception
            when no_data_found then
              null;
          end;
      end;
    else
      v_software_group := c1rec.software_grp;
    end if;
  
    begin
      select 'x'
        into v_char
        from mfg_softwaregroup_mas a
       where a.software_group = v_software_group;
    exception
      when no_data_found then
        v_software_group := null;
    end;
  
    insert into temp_activate_log
      (mac_address, id, owner_phone, event_date, step)
    values
      (p_client_id, p_client_id, '', sysdate, 'A3.check force groupp');
    commit;
    declare
      v_char varchar2(32);
    begin
      select 'x'
        into v_char
        from mfg_iptv_mas
       where mac_address = c1rec.serial_id;
    
      update mfg_iptv_mas
         set software_group = v_software_group, status_flg = 'R'
       where mac_address = c1rec.serial_id;
    
      --
      --
      --
      update bsm_client_device_list a
         set software_group = substr(bsm_cdi_service.get_device_current_swver(a.client_id,a.device_id),1,7), status_flg = 'P'
       where a.client_id = c1rec.serial_id
       and a.software_group is null;
      commit;
    exception
      when no_data_found then
        insert into temp_activate_log
          (mac_address, id, owner_phone, event_date, step)
        values
          (p_client_id,
           p_client_id,
           '',
           sysdate,
           'A4.insert iptv master table');
        commit;
        insert into mfg_iptv_mas
          (mac_address, software_group, status_flg, real_mac_address)
        values
          (c1rec.serial_id, v_software_group, 'R', c1rec.real_mac_address);
        commit;
    end;
  
    insert into temp_activate_log
      (mac_address, id, owner_phone, event_date, step)
    values
      (p_client_id, p_client_id, '', sysdate, 'A5.process apk group');
    commit;
    declare
      v_char varchar2(32);
    begin
      select 'x'
        into v_char
        from mid_apk_group_client
       where client_id = c1rec.serial_id;
    
      update mid_apk_group_client
         set software_group = v_software_group
       where client_id = c1rec.serial_id;
    
      commit;
    
    exception
      when no_data_found then
        insert into temp_activate_log
          (mac_address, id, owner_phone, event_date, step)
        values
          (p_client_id,
           p_client_id,
           '',
           sysdate,
           'A6.insert apk client table');
        commit;
        insert into mid_apk_group_client
          (client_id, software_group, mac_address)
        values
          (c1rec.serial_id, v_software_group, c1rec.real_mac_address);
        commit;
    end;
  
  end loop;
end;
/

