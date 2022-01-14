create or replace function iptv.get_software_group_4gtv(p_client_id varchar2,
                                               p_device_id varchar2)
  return varchar2 is
  Result varchar2(32);
begin
    -- Add 4GTV
  if substr(p_client_id, 1, 1) = 'F' then
    result := 'LTFTV00';
    return(Result);
  end if;
  if substr(p_client_id, 1, 1) = '2' and p_device_id is not null then
    select software_group
      into result
      from bsm_client_device_list
     where client_id = p_client_id
       and device_id = p_device_id;
  else
    if substr(p_client_id, 1, 1) = '2' and p_device_id is null then
      begin
        select software_group
          into result
          from bsm_client_device_list
         where client_id = p_client_id
           and status_flg = 'P'
           and substr(software_group, 1, 7) in ('LTLG00', 'LTSMS01')
           and rownum <= 1;
      exception
        when no_data_found then
          begin
            select software_group
              into result
              from bsm_client_device_list
             where client_id = p_client_id
                  -- and status_flg='P'
               and substr(software_group, 1, 7) in ('LTLG00', 'LTSMS01')
               and rownum <= 1;
          exception
            when no_data_found then
              select software_group
                into result
                from mfg_iptv_mas
               where mac_address = p_client_id;
          end;
      end;
    else
      select software_group
        into result
        from mfg_iptv_mas
       where mac_address = p_client_id;
    end if;
  end if;
  return(Result);
end get_software_group_4gtv;
/

