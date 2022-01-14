CREATE OR REPLACE Function IPTV.Set_Client_val(client_id     varchar2,
                          p_name        varchar2,
                          p_default_val clob) return clob is
    v_val            clob;
    v_software_group varchar2(64);
  begin
    begin
      select software_group
        into v_software_group
        from mfg_iptv_mas
       where mac_address = client_id;
    exception
      when no_data_found then
        v_software_group := 'SYSTEM_DEFAULT';
        -- 使用Software group 作為 value id
    end;
    begin
      select val
        into v_val
        from bsm_client_val a
       where a.val_name = p_name
         and a.val_id = v_software_group;

      update bsm_client_val a
         set val = p_default_val
       where a.val_name = p_name
         and a.val_id = v_software_group;

      return p_default_val;
    exception
      when no_data_found then
        insert into bsm_client_val
          (val_name, val_id, default_val, val)
        values
          (p_name, v_software_group, p_default_val, p_default_val);
        commit;
        return p_default_val;
    end;
  end;
/

