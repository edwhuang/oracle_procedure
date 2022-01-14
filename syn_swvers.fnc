CREATE OR REPLACE Function IPTV.syn_swvers Return Varchar2 Is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             clob;
    v_param        VARCHAR2(500) := '{"jsonrpc": "2.0",
    "method": "list_swmaps",
    "params": {}
}';
    manager_url varchar2(256);
    v_param_length NUMBER := length(v_param);
    rw_result      clob;

  begin
    -- v_param := replace(v_param,'_MAC_ADDRESS_',p_SERIAL_ID);

    v_param_length := length(v_param);
  --  UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
   select link_set.link_set.cdi_manager_url into manager_url from dual;
    Req := Utl_Http.Begin_Request(manager_url, 'POST', 'HTTP/1.1');

    UTL_HTTP.SET_HEADER(r     => req,
                        name  => 'Content-Type',
                        value => 'application/x-www-form-urlencoded');
    UTL_HTTP.SET_HEADER(r     => req,
                        name  => 'Content-Length',
                        value => v_param_length);
    UTL_HTTP.WRITE_TEXT(r => req, data => v_param);

    resp := utl_http.get_response(req);

    loop
      begin
        rw := null;
        utl_http.read_line(resp, rw, TRUE);
        rw_result := rw_result || rw;
      exception
        when others then
          exit;
      end;
    end loop;
    utl_http.end_response(resp);

    declare
      jsonObj      json;
      jsonarray    json_list;
      jsonObjdtl   json;
      json_vaule_a json_value_array;

    begin
      jsonobj    := json(rw_result);
      jsonObjdtl := json_ext.get_json(jsonobj, 'result');

      for i in 1 .. jsonObjdtl.JSON_DATA.count loop
        json_vaule_a := jsonObjdtl.JSON_DATA;
        declare
          v_last_version   varchar2(640);
          v_status_flg     varchar2(640);
          v_pk_no          number(16);
          v_software_group varchar2(320) := jsonObjdtl.PATH('[' || i ||']')
                                           .mapname;
          v_version        varchar2(640) := json(jsonObjdtl.PATH('[' || i ||']')).PATH('version')
                                           .get_string;

        begin
          select a.last_version, a.status_flg
            into v_last_version, v_status_flg
            from mfg_softwaregroup_mas a
           where a.software_group = v_software_group;
     --     dbms_output.put_line( v_software_group);
          if v_status_flg not in ('R', 'A') then
            if (v_last_version <> v_version) or (v_last_version is null) then
              
              begin
                update mfg_softwaregroup_mas a
                   set a.last_version = v_version
                 where a.software_group = v_software_group;
               exception
                  when others then null;
               end; 
               
               
              commit;
            end if;
          end if;
        exception
          when no_data_found then
              begin
            select seq_bsm_client_mas.nextval into v_pk_no from dual;
            insert into mfg_softwaregroup_mas
              (pk_no, software_group, last_version, status_flg)
            values
              (v_pk_no, v_software_group, v_last_version, 'P'); 
            commit;
              exception
                  when others then null;
               end; 
        end;
      end loop;
      -- rw_result := json_ext.get_string(jsonobj,'jsonrpc');
    end;

    declare
      cursor c1 is
        select a.software_group, a.last_version, a.status_flg
          from mfg_softwaregroup_mas a
         where a.status_flg = 'R';
      v_msg varchar2(1024);
      jsonObj      json;
    begin
      for j in c1 loop
        v_msg := bsm_cdi_service.set_softgroupmap_to_cdi(j.software_group, j.last_version);
        if v_msg is null or v_msg <> 0 then
        update mfg_softwaregroup_mas a
           set status_flg = 'F'
         where a.software_group = j.software_group;
        else
          update mfg_softwaregroup_mas a
             set status_flg = 'P'
           where a.software_group = j.software_group;
        end if;
        commit;
      end loop;
    end;

    return rw_result;
  End;
/

