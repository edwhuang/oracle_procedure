CREATE OR REPLACE FUNCTION IPTV.CHECK_CDI_ACCESS(p_client_id varchar2,
                                              p_asset_id  varchar2,
                                              p_device_id varchar default null)
  RETURN varchar2 is
  result      varchar2(32);
  v_client_id varchar2(32);
  v_emp varchar2(32);
begin
  begin
    select 'y' into v_emp from sys_process_on where rownum <=1;
  exception
    when no_data_found then v_emp:='n';
  end;
  
  if v_emp = 'n' then
    begin
    v_client_id := upper(p_client_id);

  if (p_device_id is null) then
  
    with cte as
     (select "parent_id"
        from acl.relationship
       where nvl("deleted", 0) = 0
       start with "child_id" = p_asset_id
      connect by prior "parent_id" = "child_id"
             and level <= 6
             and nvl("deleted", 0) = 0)
    select 'Y'
      into result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or
           (start_date <= sysdate and end_date >= sysdate))
       and (((b.cal_type = 'T' and
           (a.item_id in (select "parent_id" from cte))) or
           (b.cal_type <> 'T' and
           (a.package_id in (select "parent_id" from cte)))) or
           (p_asset_id = 'KOD' and (b.package_cat_id1 = p_asset_id)))
          
       and (device_id is null or
           a.device_id not in
           (select c.device_id
               from bsm_client_device_list c
              where c.client_id = p_client_id
                and c.software_group = 'LTSMS02'))
       and rownum <= 1;
   else
    with cte as
     (select "parent_id"
        from acl.relationship
       where nvl("deleted", 0) = 0
       start with "child_id" = p_asset_id
      connect by prior "parent_id" = "child_id"
             and level <= 6
             and nvl("deleted", 0) = 0)
    select 'Y'
      into result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or
           (start_date <= sysdate and
           end_date >= sysdate))
       and (((b.cal_type = 'T' and
           (a.item_id in
           (select "parent_id" from cte))) or
           (b.cal_type <> 'T' and
           (a.package_id in
           (select "parent_id" from cte)))) or
           (p_asset_id = 'KOD' and
           (b.package_cat_id1 = p_asset_id)))
       and (device_id is null or
           device_id = p_device_id)
       and rownum <= 1;
  end if;

  return result;
exception
  when no_data_found then
    return 'N';
  
end;
else
  return 'Y';
end if;
end;
/

