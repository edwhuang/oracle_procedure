CREATE OR REPLACE FUNCTION IPTV."GET_END_DATE" (p_client_id varchar2,
                                          p_asset_id  varchar2,
                                          p_device_id varchar2 default null) RETURN Date is
  result      date;
  v_client_id varchar2(32);
  v_char varchar2(1);
begin
  begin
  select 'x' into v_char  from sys_process_on where rownum <=1; 
  return null;
exception
  when no_data_found then
    begin

  v_client_id := upper(p_client_id);
  
  if p_device_id is null then 
  
  with cte as (select "parent_id"
              from acl.relationship
             where nvl("deleted", 0) = 0
             start with "child_id" = p_asset_id
            connect by prior "parent_id" = "child_id"
                   and level <= 6
                   and nvl("deleted", 0) = 0
)
  select max(a.end_date)
    into result
    from bsm_client_details a, bsm_package_mas b
   where mac_address = v_client_id
     and a.package_id = b.package_id
     and b.acl_period is null
     and a.status_flg = 'P'
      and b.package_id not in ('FREE00','FREE01','FREE98','FREE97','FREE99')
     and (start_date is null or (end_date >= sysdate))
     and (( (b.cal_type='T' 
     and (a.item_id in
         (select "parent_id" from cte)))
     or (b.cal_type <> 'T' 
     and (a.package_id in
         (select "parent_id" from cte)))
) or
         (p_asset_id = 'KOD' and (b.package_cat_id1 = p_asset_id)));
    else 
        with cte as (select "parent_id"
              from acl.relationship
             where nvl("deleted", 0) = 0
             start with "child_id" = p_asset_id
            connect by prior "parent_id" = "child_id"
                   and level <= 6
                   and nvl("deleted", 0) = 0
)
  select max(a.end_date)
    into result
    from bsm_client_details a, bsm_package_mas b
   where mac_address = v_client_id
     and b.acl_period is null
     and (a.device_id is null or a.device_id = p_device_id)
     and a.package_id = b.package_id
     and a.status_flg = 'P'
     and b.package_id not in ('FREE00','FREE01','FREE98','FREE97','FREE99')
     and (start_date is null or (end_date >= sysdate))
     and (( (b.cal_type='T' 
     and (a.item_id in
         (select "parent_id" from cte)))
     or (b.cal_type <> 'T' 
     and (a.package_id in
         (select "parent_id" from cte)))
) or
         (p_asset_id = 'KOD' and (b.package_cat_id1 = p_asset_id)));
      
    end if;
  -- stock

  if p_asset_id = 'com.tgc.stock' then

    declare
      cursor_name    INTEGER;
      rows_processed INTEGER;
    BEGIN
      cursor_name := dbms_sql.open_cursor;
      DBMS_SQL.PARSE(cursor_name,
                     'begin
                     insert into bsm_client_event_log
      (client_id,
       f_client_id,
       unix_timestamp,
       event_name,
       event_time,
       client_read_access)
    values
      ('''||p_client_id||''',
       0,
       (sysdate - TO_DATE(''19700101'', ''YYYYMMDD'')) * 86400000000,
       ''E_STOCK'',
       sysdate,
       ''com.tgc.stock'');
       commit;
       end;
       ',
                     DBMS_SQL.NATIVE);
      rows_processed := DBMS_SQL.EXECUTE(cursor_name);

      DBMS_SQL.CLOSE_CURSOR(cursor_name);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_SQL.CLOSE_CURSOR(cursor_name);
    END;
  
  end if;
  if result is null then
    result := to_date('2999/12/31','YYYY/MM/DD');
  end if;

  return result;
exception
  when no_data_found then
    return null;
end;
end;
end;
/

