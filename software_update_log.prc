create or replace procedure iptv.software_update_log(p_client_id varchar2,p_version varchar2) is
begin
  declare
    current_ver varchar2(32);
    v_software_group varchar2(32);
  begin
    select software_ver into current_ver from bsm_client_mas where mac_address= p_client_id;
    if current_ver is null then
       current_ver := get_result_current_swver(p_client_id);
    end if;

    if (current_ver <> p_version) and (p_version is not null) then
       select software_group into v_software_group from mfg_iptv_mas where mac_address= p_client_id;
       insert into mfg_software_update_log(update_date,client_id,software_group,from_ver,to_ver)
       values (sysdate,p_client_id,v_software_group,current_ver,p_version);
       update bsm_client_mas
       set software_ver = p_version
       where mac_address=p_client_id;
       commit;
    end if;

  exception
    when no_data_found then null;
  end;



end software_update_log;
/

