create or replace procedure iptv.hls_log_process
(p_client_id varchar2,p_event_time date,p_asset_id varchar2)
is
  v_package_id varchar2(64);
  v_pk_no number(16);
  v_report_type varchar2(32);
  v_char varchar2(32);
  v_event_time date;
begin

  v_event_time := p_event_time; -- +(8/24);
  select 'x' into v_char from bsm_client_event_log x where x.client_id = p_client_id and trunc(x.event_time) = trunc(v_event_time) and x.client_read_access=p_asset_id  and rownum <=1;
 -- insert into test_log(client_id,event_time,asset_id) values (p_client_id,p_event_time,p_asset_id);
  commit;
exception
  when no_data_found then
    begin
      v_package_id := null;
      v_event_time := p_event_time;--+(8/24);
         v_report_type := 'P';
        v_pk_no := BSM_CDI_SERVICE.update_bsm_detail(p_client_id,
                                                  p_asset_id,
                                                 v_event_time);
        if v_pk_no is not null then
           select package_id,report_type into v_package_id,v_report_type from bsm_client_details where pk_no = v_pk_no;
        end if;
  
      insert into bsm_client_event_log(client_id,f_client_id,unix_timestamp,event_name,event_time,client_read_access,package_id,detail_pk_no,report_type,play_time)
      values(p_client_id,1,(p_event_time - TO_DATE('19700101', 'YYYYMMDD')) * 86400000000,'E_PLAY',p_event_time,p_asset_id,v_package_id,v_pk_no,v_report_type,'300');
      commit;
    end;

end;
/

