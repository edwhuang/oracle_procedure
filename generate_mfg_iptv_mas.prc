CREATE OR REPLACE PROCEDURE IPTV."GENERATE_MFG_IPTV_MAS" is
  v_serial_no      number(16);
  v_serial_id      varchar2(32);
  v_status_flg     varchar2(32);
  v_defaule_group  varchar2(32);
  v_software_group varchar2(32);
  v_software_ver   varchar2(64);
  v_char           varchar2(32);
  cursor c1 is
    select mac_address, a.software_ver, a.software_grp, a.real_mac_address
      from bsm_client_mas a
     where not exists (select 'x'
              from mfg_iptv_mas b
             where b.mac_address = a.mac_address
               and b.software_group is not null)
       and (a.software_grp is null or a.software_ver is null)
       and a.software_ver not in ('nktestclient01', 'A');
begin
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
            v_software_ver := get_result_current_swver(c1rec.mac_address);
          else
            v_software_ver := c1rec.software_ver;
          end if;
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
  
    declare
      v_char varchar2(32);
    begin
      select 'x'
        into v_char
        from mfg_iptv_mas
       where mac_address = c1rec.mac_address;
    
      update mfg_iptv_mas
         set software_group = v_software_group, status_flg = 'R'
       where mac_address = c1rec.mac_address;
      commit;
    exception
      when no_data_found then
      
        insert into mfg_iptv_mas
          (mac_address, software_group, status_flg, real_mac_address)
        values
          (c1rec.mac_address,
           v_software_group,
           'R',
           c1rec.real_mac_address);
        commit;
    end;
  
    declare
      v_char varchar2(32);
    begin
      select 'x'
        into v_char
        from mid_apk_group_client
       where client_id = c1rec.mac_address;
    
      update mid_apk_group_client
         set software_group = v_software_group
       where client_id = c1rec.mac_address;
      commit;
    exception
      when no_data_found then
      
        insert into mid_apk_group_client
          (client_id, software_group, mac_address)
        values
          (c1rec.mac_address, v_software_group, c1rec.real_mac_address);
        commit;
    end;
  
  end loop;
/*
  declare
    cursor c1 is
      Select client_id, c.device_id, c.create_date, a.coupon_id
        from bsm_client_device_list c, bsm_coupon_mas a
       where c.create_date >= sysdate - 7
         and a.ref_device_id = c.device_id
         and a.status_flg = 'P'
         and a.expire_date >= sysdate
       order by c.create_date desc
        
    v_msg varchar2(1024);
  begin
    for i in c1 loop
      v_msg := bsm_purchase_post.CLIENT_REGIETER_COUPON(i.client_id,
                                                        i.coupon_id,
                                                        i.device_id);
    end loop;
  end;
  */
end;
/

