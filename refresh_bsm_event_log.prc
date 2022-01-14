create or replace procedure iptv.REFRESH_BSM_EVENT_LOG is
  -- update client_id to real_client_id
begin
  begin
declare  cursor c1 is
    select rowid rid, f_client_id, event_time, client_id
      from bsm_client_event_log
     where ((real_client_id is null) or (event_name like 'SSAS_%'))
       and client_id is null
       and app_name like 'vod%'
       and f_client_id in
           (Select f_client_id
              from bsm_client_event_log
             where real_client_id is not null)
       and event_time >= sysdate - 1;
  cursor c2(p_client number, p_time date) is
    select upper(real_client_id) client_id
      from bsm_client_event_log a
     where real_client_id is not null
       and f_client_id = p_client
       and (upper(substr(app_name, 1, 3)) = 'VOD' or
           app_name is null)
       and event_time > p_time - 2
       and event_time <= p_time + (3 / (24 * 60))
    
     order by event_time desc;
  c2rec c2%rowtype;
begin
  for i in c1 loop
    open c2(i.f_client_id, i.event_time);
    fetch c2
      into c2rec;
    if c2%found then
      if i.client_id is null then
        begin
          update bsm_client_event_log b
             set client_id = c2rec.client_id
           where rowid = i.rid;
        exception
          when dup_val_on_index then
            null;
        end;
      end if;
    end if;
    close c2;
    commit;
  end loop;
end;

declare
  cursor c1 is
    select f_client_id, event_time, a.client_read_access
      from bsm_client_event_log a
     where a.event_name = 'E_STOP'
       and play_time is null
       and a.client_read_access is not null;

  v_event_time date;
begin
  for i in c1 loop
    select max(event_time)
      into v_event_time
      from bsm_client_event_log
     where f_client_id = i.f_client_id
       and client_read_access = i.client_read_access
       and event_name = 'E_PLAY'
       and event_time < i.event_time;
    update bsm_client_event_log
       set play_time =
           (i.event_time - v_event_time) * 24 * 60 * 60
     where f_client_id = i.f_client_id
       and client_read_access = i.client_read_access
       and event_name = 'E_PLAY'
       and event_time = v_event_time;
    update bsm_client_event_log
       set play_time =
           (i.event_time - v_event_time) * 24 * 60 * 60
     where f_client_id = i.f_client_id
       and client_read_access = i.client_read_access
       and event_name = 'E_STOP'
       and event_time = i.event_time;
  end loop;
  commit;
end;

declare
  cursor c1 is
    select rowid rid,
           client_id,
           event_time,
           replace(client_read_access, '.mp4', '') asset_id,
           event_name,
           package_id
      from bsm_client_event_log a
     where trunc(event_time) >= sysdate - 1
       and a.event_name in ('E_PLAY', 'SSAS_connection_allowed', 'E_STOP')
       and client_id is not null;
  v_package_id  varchar2(64);
  v_pk_no       number(16);
  v_report_type varchar2(64);
begin
  for c1rec in c1 loop
    v_package_id  := null;
    v_report_type := null;
    v_pk_no       := BSM_CDI_SERVICE.update_bsm_detail(c1rec.client_id,
                                                       c1rec.asset_id,
                                                       c1rec.event_time);
    if v_pk_no is not null then
      select package_id, report_type
        into v_package_id, v_report_type
        from bsm_client_details
       where pk_no = v_pk_no;
    
    end if;
    if c1rec.package_id is null then
      update bsm_client_event_log a
         set a.package_id   = v_package_id,
             a.report_type  = v_report_type,
             a.detail_pk_no = v_pk_no
       where rowid = c1rec.rid;
    end if;
  end loop;
end;

end;
end;
/

