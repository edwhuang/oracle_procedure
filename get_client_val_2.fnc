CREATE OR REPLACE FUNCTION IPTV."GET_CLIENT_VAL_2"(client_id      varchar2,
                                            p_name         varchar2,
                                            p_default_val  clob,
                                            p_software_ver varchar2 default null)
  return clob is
  v_val            clob;
  v_software_group varchar2(64);
  v_default_val    clob;
  v_client_id varchar2(32);
begin
  --
  -- 修改 如果有software ver 則 software ver版號需與 software 一致
  -- 

  --
  -- 修改 如果有software ver 則 software ver版號需與 software 一致
  -- 
  v_client_id := client_id;

  begin
    select software_group
      into v_software_group
      from mfg_iptv_mas
     where mac_address = client_id
     and software_group <> 'LTIOS00';
    if (p_software_ver is not null) and
       (substr(v_software_group, 1, 7) <> substr(p_software_ver, 1, 7)) then
      declare
        cursor c_sv is
          select software_group
            into v_software_group
            from bsm_client_device_list c
           where c.client_id = v_client_id
             and c.status_flg = 'P';
      begin
        for i in c_sv loop
          if substr(i.software_group, 1, 7) = substr(p_software_ver, 1, 7) then
            v_software_group := i.software_group;
          end if;
        
        end loop;
      end;
  elsif (p_software_ver is null) then
    declare
        cursor c_sv is
          select software_group
            into v_software_group
            from bsm_client_device_list c
           where c.client_id = v_client_id
             and c.software_group in 
             (select val_id from bsm_client_val v where v.val_name = p_name)
             and c.status_flg = 'P';
      begin
        for i in c_sv loop
            v_software_group := i.software_group;
        end loop;
        if v_software_group is null then
          begin
           select software_group into v_software_group from mfg_iptv_mas c
           where c.mac_address =v_client_id
             and c.status_flg = 'P'; 
          exception
             when no_data_found then null;
          end;
        end if;
         
      end;
  end if;
  if v_software_group is null then
    v_software_group := 'SYSTEM_DEFAULT';
  end if;
exception
  when no_data_found then
    v_software_group := 'SYSTEM_DEFAULT';
    -- 使用Software group 作為 value id
end;

begin
declare cursor c1 is
select val, val_id from bsm_client_val a where a.val_name = p_name and (a.val_id like v_software_group || ' %' OR val_id = v_software_group) order by val_id; v_val_version varchar2(32);
begin
for c1rec in c1 loop if instr(c1rec.val_id, 'VER') > 0 then if p_software_ver is
not null then v_val_version := substr(c1rec.val_id, instr(c1rec.val_id, 'VER') + 4, 26); if v_val_version <= p_software_ver then
--    if c1rec.val_id=v_software_group then
v_val := c1rec.val;
--    end if;
end if;
end if; else v_val := c1rec.val;
end if;
end loop;
end;

if length(v_val) = 0 then v_software_group := 'SYSTEM_DEFAULT'; select val into v_val from bsm_client_val a where a.val_name = p_name and a.val_id = v_software_group;
end if; return v_val;

exception
when no_data_found then if v_software_group is
not null then if p_default_val is
null then v_software_group := 'SYSTEM_DEFAULT';
begin
select val into v_val from bsm_client_val a where a.val_name = p_name and a.val_id = v_software_group;
exception
when no_data_found then insert into bsm_client_val(val_name, val_id, default_val, val) values(p_name, v_software_group, v_val, v_val); commit;
end;

else v_default_val := p_default_val;
end if; insert into bsm_client_val(val_name, val_id, default_val, val) values(p_name, v_software_group, v_default_val, v_default_val); commit;
end if; return v_default_val;
end;

end;
/

