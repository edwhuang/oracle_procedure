CREATE OR REPLACE PACKAGE BODY IPTV."BSM_CDI_SERVICE_DEV" is

  -- manager_url varchar2(1024) := 'http://management01.tw.svc.litv.tv/cdi/Management';
  manager_url varchar2(1024);

  -- Private type declarations
  --type <TypeName> is <Datatype>;

  -- Private constant declarations
  -- <ConstantName> constant <Datatype> := <Value>;

  -- Private variable declarations
  -- <VariableName> <Datatype>;

  -- Function and procedure implementations

  function unix_to_oracle(in_number NUMBER) return date is
  begin
    if in_number is not null then
      return(TO_DATE('19700101', 'YYYYMMDD') + (in_number / 86400000000));
    else
      return(sysdate);
    end if;
  end unix_to_oracle;

  function oracle_to_unix(in_date date) return number is
  begin
  
    return((in_date - TO_DATE('19700101', 'YYYYMMDD')) * 86400000000);
  
  end oracle_to_unix;

  function Set_Client_Status(p_serial_id varchar2, p_status_flg varchar2)
    return varchar2 is
    req                utl_http.req;
    resp               utl_http.resp;
    rw                 varchar2(32767);
    v_param            VARCHAR2(500) := '{
   "jsonrpc": "2.0",
   "method": "set_client_activation_state",
   "id": null,
   "params": {
       "client_id": "_MAC_ADDRESS_",
       "state": "_STATUS_"
   }
}
';
    v_param_length     NUMBER := length(v_param);
    rw_result          varchar2(32767);
    v_status_flg       varchar2(32);
    v_real_mac_address varchar2(32);
  
  begin
    begin
      select real_mac_address
        into v_real_mac_address
        from bsm_client_mas
       where mac_address = p_serial_id;
    exception
      when no_data_found then
        null;
    end;
    if v_real_mac_address is not null and v_real_mac_address <> p_serial_id then
      v_status_flg := p_status_flg || ':' || v_real_mac_address;
    else
      v_status_flg := p_status_flg;
    end if;
    /*insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, p_serial_id, v_param, rw_result);
    */
    v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
    v_param := replace(v_param, '_STATUS_', v_status_flg);
    /*
    v_param_length := length(v_param);
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
    */
  
    rw_result := link_set.link_set.post_to_cdi(v_param);
    /*  insert into BSM_CLIENT_CDI_LOG
      (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
    values
      (sysdate, p_serial_id, v_param, rw_result);
    commit; */
  
    return rw_result;
  
  end;
    function refresh_client_new(p_serial_id   varchar2,
                              refresh_queue varchar2 default null)
    return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        clob := '{
    "jsonrpc": "2.0", 
    "id":"_RPCID_",
    "method": "ManagementService.SetAccountSubscriptions", 
    "params": {
        "AccountID": "_MAC_ADDRESS_",
        "Subscriptions":_SUBSCRIPTIONS_
    }
}';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
    json_str clob;
    n        number;
    cursor c1(p_client_id varchar2) is
      select '{"transaction_id" :"' || "transaction_id" || '",' ||
             '"package_id": "' || "package_id" || '",' || '"created":  "' ||
             to_char("created" - (8 / 24), 'YYYY-MM-DD HH24:MI:SS') || '",' ||
             '"last_modified": "' ||
             to_char("last_modified" - (8 / 24), 'YYYY-MM-DD HH24:MI:SS') || '",' ||
             '"device_id":' ||
             decode("device_id", null, 'null', '"' || "device_id" || '"') || ',' ||
             '"start_time" :"' ||
             to_char(nvl("service_start_time",
                         to_date('2000/01/01 00:00:00',
                                 'YYYY/MM/DD HH24:MI:SS')) - (8 / 24),
                     'YYYY-MM-DD HH24:MI:SS') || '",' || '"end_time" : "' ||
             to_char(nvl("service_end_time",
                         to_date('2999/12/31 23:59:59',
                                 'YYYY/MM/DD HH24:MI:SS')) - (8 / 24),
                     'YYYY-MM-DD HH24:MI:SS') || '"' || '}' json_str
        from acl.subscription a
       where a."deleted" = 0
         and a."client_id" = p_client_id;
  
  begin
    if refresh_queue is null then

      if p_serial_id = 'F6AEF1815EC63D2E' then
        raise client_error;
      end if;
      n        := 0;
      json_str := '[';
      for i in c1(p_SERIAL_ID) loop
        if n > 0 then
          json_str := json_str || ',';
        end if;
      
        json_str := json_str || i.json_str;
        n        := n + 1;
      end loop;
      json_str := json_str || ']';
            v_param := '{
    "jsonrpc": "2.0", 
    "id":"_RPCID_",
    "method": "ManagementService.SetAccountSubscriptions", 
    "params": {
        "AccountID": "'||p_SERIAL_ID||'",
        "Subscriptions":'||json_str||'}
}';
      v_param  := replace(v_param,
                          '_RPCID_',
                          'REF_CDI_' ||
                          to_char(systimestamp, 'yyyy-mm-ddhh24:mi:ssxff'));
      insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, p_serial_id, v_param,'start');
      commit;
    
      declare
        v_param_length NUMBER := length(v_param);
        req            utl_http.req;
        resp           utl_http.resp;
        rw             varchar2(32767);
      
      begin
        v_param_length := length(v_param);
       begin
        Req            := Utl_Http.Begin_Request(link_set.link_set.p_parthost_1,
                                                 'POST',
                                                 'HTTP/1.1');
       exception
          when others then 
        Req            := Utl_Http.Begin_Request(link_set.link_set.p_parthost_2,
                                                 'POST',
                                                 'HTTP/1.1');
        end;                                             
      
        UTL_HTTP.SET_HEADER(r     => req,
                            name  => 'Content-Type',
                            value => 'application/json');
        UTL_HTTP.SET_HEADER(r     => req,
                            name  => 'Content-Length',
                            value => v_param_length);
        declare
           l_chunkData varchar2(3096);
           l_chunkStart number(16) := 1;
           l_chunkLength number(16) := 3096;
           l_data clob;
        begin
          loop
            l_data := v_param;
            l_chunkData := null;
            l_chunkData := substr(l_data, l_chunkStart, l_chunkLength);
             dbms_output.put(l_chunkData);
            utl_http.write_text(req, l_chunkData);
           
            if (length(l_chunkData) <= 0 or l_chunkData is null ) then
              exit;
            end if;
            l_chunkStart := l_chunkStart + l_chunkLength;
          end loop;
        end;
      
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
      
      end;
    
      insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, p_serial_id, v_param, rw_result);
      commit;
    else
      declare
        v_enqueue_options    dbms_aq.enqueue_options_t;
        v_message_properties dbms_aq.message_properties_t;
        v_message_handle     raw(16);
        v_payload            purchase_msg_type;
      begin
        v_payload := purchase_msg_type(p_serial_id, 0, '', 'refresh_cdi');
        dbms_aq.enqueue(queue_name         => refresh_queue,
                        enqueue_options    => v_enqueue_options,
                        message_properties => v_message_properties,
                        payload            => v_payload,
                        msgid              => v_message_handle);
        commit;
      end;
    end if;
  
    return rw_result;
  
  end;

  function refresh_client(p_serial_id   varchar2,
                          refresh_queue varchar2 default null)
    return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "refresh_client", 
    "params": {
        "client_id": "_MAC_ADDRESS_" 
    }
}';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    if refresh_queue is null then
      v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
      if p_serial_id = 'F6AEF1815EC63D2E' then
        raise client_error;
      end if;
     /* rw_result := link_set.link_set.post_to_cdi(v_param);  */

         rw_result :=refresh_client_new(p_serial_id);  
    
      insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, p_serial_id, v_param, rw_result);
      commit;
    else
      declare
        v_enqueue_options    dbms_aq.enqueue_options_t;
        v_message_properties dbms_aq.message_properties_t;
        v_message_handle     raw(16);
        v_payload            purchase_msg_type;
      begin
        v_payload := purchase_msg_type(p_serial_id, 0, '', 'refresh_cdi');
        dbms_aq.enqueue(queue_name         => refresh_queue,
                        enqueue_options    => v_enqueue_options,
                        message_properties => v_message_properties,
                        payload            => v_payload,
                        msgid              => v_message_handle);
        commit;
      end;
    end if;
  
    return '';
  
  end;

  function cache_metadata return clob is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
  "jsonrpc": "2.0", 
  "method": "cache_metadata", 
  "params": {}
}';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    declare
      v_cnt number(16);
    begin
      select count(*) into v_cnt from acl.relationship;
      if v_cnt > 1000000 then
      
        utl_http.set_transfer_timeout(160000);
      
        rw_result := link_set.link_set.post_to_cdi(v_param);
        /*    insert into BSM_CLIENT_CDI_LOG
          (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
        values
          (sysdate, 'cache_metadata', v_param, rw_result);
        commit; */
      end if;
    end;
  
    return rw_result;
  end;

  function set_softgroupmap_to_cdi(p_group      varchar2,
                                   p_version    varchar2,
                                   p_apiversion varchar2 default '4')
    return varchar2 Is
    req     utl_http.req;
    resp    utl_http.resp;
    rw      clob;
    v_param VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "set_swmap", 
    "params": {"name": "_GROUP_", "version": "_VERSION_"}

}
';
  
    v_param_length NUMBER := length(v_param);
  
    v_param_adv        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "add_swver", 
    "params": {"name": "_VERSION_", "apiversion": "_apiversion_"}

}
';
    v_param_adv_length number := length(v_param_adv);
    rw_result          varchar2(32767);
  
  begin
    v_param_adv        := replace(v_param_adv, '_VERSION_', p_version);
    v_param_adv        := replace(v_param_adv, '_apiversion_', p_apiversion);
    v_param_adv_length := length(v_param_adv);
  
    --   UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
  
    Req := Utl_Http.Begin_Request(manager_url, 'POST', 'HTTP/1.1');
  
    UTL_HTTP.SET_HEADER(r     => req,
                        name  => 'Content-Type',
                        value => 'application/x-www-form-urlencoded');
    UTL_HTTP.SET_HEADER(r     => req,
                        name  => 'Content-Length',
                        value => v_param_adv_length);
    UTL_HTTP.WRITE_TEXT(r => req, data => v_param_adv);
  
    resp := utl_http.get_response(req);
    utl_http.end_response(resp);
  
    v_param        := replace(v_param, '_GROUP_', p_group);
    v_param        := replace(v_param, '_VERSION_', p_version);
    v_param_length := length(v_param);
  
    UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
  
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
      jsonObj json;
    begin
      jsonobj   := json(rw_result);
      rw_result := to_char(json_ext.get_number(jsonobj, 'result'));
    end;
  
    return rw_result;
  End;

  Function syn_swvers Return Varchar2 Is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             clob;
    v_param        VARCHAR2(500) := '{"jsonrpc": "2.0", 
    "method": "list_swmaps", 
    "params": {}
}';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
  
    declare
      cursor c1 is
        select a.software_group, a.last_version, a.status_flg
          from mfg_softwaregroup_mas a
         where a.status_flg = 'R';
      v_msg   varchar2(1024);
      jsonObj json;
    begin
      for j in c1 loop
        v_msg := set_softgroupmap_to_cdi(j.software_group, j.last_version);
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

  function get_softgroup_from_cdi(p_serial_id varchar2,
                                  p_device_id varchar2 default null)
    return varchar2 Is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "get_client_swmap", 
    "params": {"client_id": "_MAC_ADDRESS_"#_DEVICE_ID_#}
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
    if p_device_id is null then
      v_param := replace(v_param, '#_DEVICE_ID_#', '');
    else
      v_param := replace(v_param,
                         '#_DEVICE_ID_#',
                         ',"device_id":"' || p_device_id || '"');
    end if;
  
    rw_result := link_set.link_set.post_to_cdi(v_param);
  
    declare
      jsonObj      json;
      result_json  json;
      json_vaule_a json;
    
    begin
      jsonobj     := json(rw_result);
      result_json := json_ext.get_json(jsonobj, 'result');
    
      for i in 1 .. result_json.JSON_DATA.count loop
        rw_result := result_json.PATH('[' || i ||']').get_string;
      end loop;
    
    end;
  
    return rw_result;
  End;

  function set_softgroup_to_cdi(p_serial_id varchar2,
                                p_group     varchar2,
                                p_device_id varchar2 default null)
    return varchar2 Is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "set_client_swmap", 
    "params": {"client_id": "_MAC_ADDRESS_", "name": "_SOFTWARE_GROUP_"#_DEVICE_ID_#}

}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
    if p_group is not null then
      v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
      v_param := replace(v_param, '_SOFTWARE_GROUP_', p_group);
      if p_device_id is null then
        v_param := replace(v_param, '#_DEVICE_ID_#', '');
      else
        v_param := replace(v_param,
                           '#_DEVICE_ID_#',
                           ',"device_id":"' || p_device_id || '"');
      end if;
    
      rw_result := link_set.link_set.post_to_cdi(v_param);
      declare
        jsonObj json;
      begin
        jsonobj   := json(rw_result);
        rw_result := to_char(json_ext.get_number(jsonobj, 'result'));
      end;
    
      /*   insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, p_serial_id, v_param, rw_result);
      commit; */
    end if;
    return rw_result;
  End;

  procedure process_softgroup Is
    cursor c1 is
      select a.mac_address client_id, a.software_group, null device_id
        from mfg_iptv_mas a
       where status_flg = 'R'
      union
      select b.client_id, b.software_group, b.device_id
        from bsm_client_device_list b
       where b.status_flg = 'R';
    v_softgroup varchar2(256);
    v_msg       varchar2(2048);
  begin
  
    begin
      v_msg := syn_swvers;
    exception
      when others then
        null;
    end;
  
    for c1rec in c1 loop
      begin
        if c1rec.device_id is null then
          -- not LG base
          v_softgroup := get_softgroup_from_cdi(c1rec.client_id);
        else
          -- LG base
          v_softgroup := null;
        end if;
      exception
        when others then
          v_softgroup := null;
      end;
    
      if (v_softgroup <> c1rec.software_group) or (v_softgroup is null) then
        -- set software groujp
        v_msg := set_softgroup_to_cdi(c1rec.client_id,
                                      c1rec.software_group,
                                      c1rec.device_id);
      else
        v_msg := 0;
      end if;
    
      if v_msg is null or v_msg <> '0' then
        if c1rec.device_id is null then
          update mfg_iptv_mas a
             set status_flg = 'F'
           where mac_address = c1rec.client_id;
        else
          update bsm_client_device_list a
             set status_flg = 'F'
           where a.client_id = c1rec.client_id
             and a.device_id = c1rec.device_id;
        end if;
      else
        if c1rec.device_id is null then
          update mfg_iptv_mas a
             set status_flg = 'P'
           where mac_address = c1rec.client_id;
        else
          update bsm_client_device_list a
             set status_flg = 'P'
           where a.client_id = c1rec.client_id
             and a.device_id = c1rec.device_id;
        end if;
      end if;
      commit;
    end loop;
  End;

  function get_acl(p_serial_id varchar2) return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "get_acl", 
    "params": {
        "client_id": "_MAC_ADDRESS_" 
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
  
    rw_result := link_set.link_set.post_to_cdi(v_param);
    return rw_result;
  
  end;

  function list_swvers return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "list_swvers", 
    "params": {}
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
  
    rw_result := link_set.link_set.post_to_cdi(v_param);
  
    return rw_result;
  
  end;

  function get_vodapp(p_serial_id varchar2) return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0",
    "id": null,
    "method": "client.get_vodapp", 
    "params": {"client_id": "_MAC_ADDRESS_"}
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
  
    v_param_length := length(v_param);
    --  UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
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
  
    return rw_result;
  
  end;

  function set_vodapp(p_serial_id varchar2, p_vod varchar2) return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0",
    "id": null,
    "method": "client.set_vodapp", 
    "params": {"client_id": "_MAC_ADDRESS_", "vodapp": "_VOD_"}
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_SERIAL_ID);
    v_param := replace(v_param, '_VOD_', p_vod);
  
    v_param_length := length(v_param);
    -- UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
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
    /*  insert into BSM_CLIENT_CDI_LOG
      (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
    values
      (sysdate, p_serial_id, v_param, rw_result);
    commit; */
  
    return rw_result;
  
  end;

  function cache_event(p_start_date date, p_end_date date) return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0",
    "id": null,
    "method": "event.rangebytime",
    "params": {
        "first": _FIRST_,
        "last": _LAST_
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    v_param := REPLACE(v_param,
                       '_FIRST_',
                       to_char(oracle_to_unix(p_start_date - (8 / 24))));
    v_param := REPLACE(v_param,
                       '_LAST_',
                       to_char(oracle_to_unix(p_end_date - (8 / 24))));
  
    rw_result := link_set.link_set.post_to_cdi(v_param);
  
    --  insert into temp_log (f_date, f_data) values (sysdate, rw_result);
    commit;
  
    declare
      jsonObj      json;
      result_json  json_list;
      json_vaule_a json;
      event_name   varchar2(64);
    
    begin
      jsonobj     := json(rw_result);
      result_json := json_ext.get_json_list(jsonobj, 'result');
    
      for i in 1 .. result_json.count loop
        declare
          a_json     json;
          b_json     json;
          v_app_name varchar2(256);
        begin
          a_json     := json(jsonlist_get(result_json,i-1));
          b_json     := JSON(a_JSON.PATH('data'));
          event_name := b_json.PATH('EVENT_NAME').get_string;
        
          if event_name in ('SSAS_connection_allowed') then
            declare
              v_client_id      number := to_number(b_json.PATH('flash_client_id')
                                                   .get_string);
              v_event_name     varchar2(256) := b_json.PATH('EVENT_NAME')
                                                .get_string;
              v_unix_time      number := a_JSON.PATH('timestamp')
                                         .get_number();
              v_event_time     date := unix_to_oracle(a_JSON.PATH('timestamp')
                                                      .get_number) +
                                       (8 / 24);
              v_asset_id       varchar2(256) := replace(b_json.PATH('asset_id')
                                                        .get_string,
                                                        '/',
                                                        '');
              v_real_client_id varchar2(128) := b_JSON.PATH('real_client_id')
                                                .get_string;
            begin
            
              insert into bsm_client_event_log
                (f_client_id,
                 unix_timestamp,
                 event_name,
                 event_time,
                 client_read_access,
                 real_client_id)
              values
                (v_client_id,
                 v_unix_time,
                 v_event_name,
                 v_event_time,
                 v_asset_id,
                 v_real_client_id);
            
            exception
              when DUP_VAL_ON_INDEX then
                null;
              
            end;
            commit;
          end if;
        
          if event_name in ('E_PLAY', 'E_STOP', 'E_CONNECT') then
            v_app_name := b_json.PATH('F_APP_NAME').get_string;
            --     if upper(substr(v_app_name,1,3)) is ='VOD' then
            if upper(substr(v_app_name, 1, 3)) is not null then
              declare
                v_client_id  number := b_json.PATH('F_CLIENT_ID')
                                       .get_number();
                v_event_name varchar2(256) := b_json.PATH('EVENT_NAME')
                                              .get_string;
                v_unix_time  number := a_JSON.PATH('timestamp').get_number();
                v_event_time date := unix_to_oracle(a_JSON.PATH('timestamp')
                                                    .get_number) + (8 / 24);
                v_asset_id   varchar2(256);
              
                /*  v_asset_id   varchar2(256) := replace(b_json.PATH('F_CLIENT_READ_ACCESS')
                .get_string,
                '/',
                ''); */
              begin
                if event_name in ('E_PLAY', 'E_STOP') then
                  v_asset_id := replace(b_json.PATH('F_STREAM_NAME')
                                        .get_string,
                                        '/',
                                        '');
                end if;
                insert into bsm_client_event_log
                  (client_id,
                   f_client_id,
                   unix_timestamp,
                   event_name,
                   event_time,
                   client_read_access,
                   app_name)
                values
                  (v_client_id,
                   v_client_id,
                   v_unix_time,
                   v_event_name,
                   v_event_time,
                   v_asset_id,
                   v_app_name);
              exception
                when DUP_VAL_ON_INDEX then
                  declare
                    v_client_read_access varchar2(64);
                  begin
                    select client_read_access
                      into v_client_read_access
                      from bsm_client_event_log
                     where f_client_id = v_client_id
                       and event_name = v_event_name
                       and event_time = v_event_time
                       and rownum <= 1;
                  
                    if v_client_read_access <> v_asset_id then
                    
                      update bsm_client_event_log
                         set client_read_access = v_asset_id
                       where f_client_id = v_client_id
                         and event_name = v_event_name
                         and event_time = v_event_time;
                    end if;
                  end;
              end;
            
            end if;
            commit;
          end if;
          --   end loop;
        end;
      end loop;
    
      --
      -- update client_id to real_client_id
      --
    
      declare
        cursor c1 is
          select rowid rid, f_client_id, event_time, client_id
            from bsm_client_event_log
           where ((real_client_id is null) or (event_name like 'SSAS_%'))
             and client_id is null
             and app_name like 'vod%'
             and f_client_id in
                 (Select f_client_id
                    from bsm_client_event_log
                   where real_client_id is not null)
             and event_time >= sysdate - 30;
        cursor c2(p_client number, p_time date) is
          select upper(real_client_id) client_id
            from bsm_client_event_log a
           where real_client_id is not null
             and f_client_id = p_client
             and (upper(substr(app_name, 1, 3)) = 'VOD' or app_name is null)
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
    
    end;
  
    return null;
  
  end;

  function update_bsm_detail(p_client_id  varchar,
                             p_asset_id   varchar2,
                             p_start_date date) return varchar2 is
    v_package_id   varchar2(64);
    v_detail_pk_no varchar2(64);
  begin
    Declare
      v_client_id varchar2(64);
    
    begin
    
      v_client_id := p_client_id;
    
      declare
        cursor c_package_id is
          Select "parent_id" package_id
            from acl.relationship a
           where "deleted" is null
             and "child_id" in
                 (Select "parent_id"
                    from acl.relationship a
                   where "deleted" is null
                     and "child_id" in
                         (Select "parent_id"
                            from acl.relationship a
                           where "deleted" is null
                             and "child_id" = p_asset_id))
          union all -- for kod 
          Select "parent_id" package_id
            from acl.relationship a
           where "deleted" is null
             and "child_id" = p_asset_id;
      
        cursor c_detail_end(p_package_id varchar2) is
          select *
            from bsm_client_details a
           where a.mac_address = v_client_id
             and a.status_flg = 'P'
             and a.end_date is not null
             and a.package_id <> 'FREE_FOR_CLEINT_ACTIVED'
             and (a.package_id = p_package_id or a.item_id = p_package_id);
      
        cursor c_detail(p_package_id varchar2) is
          select rowid rid, a.*
            from bsm_client_details a
           where a.mac_address = v_client_id
             and a.status_flg = 'P'
             and a.end_date is null
             and (a.package_id = p_package_id or a.item_id = p_package_id)
             and a.package_id <> 'FREE_FOR_CLEINT_ACTIVED'
             and rownum <= 1;
      
        v_skip       varchar2(64);
        v_end_date   date;
        v_start_date date;
      
      begin
        v_skip       := 'N';
        v_package_id := null;
        for r_package_id in c_package_id loop
          for r_detail in c_detail_end(r_package_id.package_id) loop
            if r_detail.end_date is not null then
              if r_detail.end_date >= p_start_date then
                if nvl(v_end_date, r_detail.end_date) < r_detail.end_date then
                  v_end_date := r_detail.end_date;
                end if;
                v_package_id   := r_detail.package_id;
                v_detail_pk_no := r_detail.pk_no;
                v_skip         := 'Y';
              end if;
            end if;
          end loop;
        
          if v_skip = 'N' then
            for r_detail in c_detail(r_package_id.package_id) loop
              if v_end_date is not null then
                v_start_date := v_end_date + 1;
              else
                v_start_date := p_start_date;
              end if;
              update bsm_client_details a
                 set a.start_date = v_start_date,
                     a.end_date   = v_start_date +
                                    (r_detail.acl_duration / (24 * 60 * 60))
               where rowid = r_detail.rid;
              commit;
              v_package_id   := r_detail.package_id;
              v_detail_pk_no := r_detail.pk_no;
              v_skip         := 'Y';
            end loop;
          end if;
        end loop;
      end;
    
    end;
  
    return v_detail_pk_no;
  end;

  procedure qick_refrash_event is
    v_msg varchar2(256);
  begin
    v_msg := cache_event(sysdate - (10 / (24 * 60)),
                         sysdate + (10 / (24 * 60)));
  
    declare
      cursor c1 is
        select rowid rid,
               client_id,
               event_time,
               replace(client_read_access, '.mp4', '') asset_id,
               event_name,
               package_id
          from bsm_client_event_log a
         where event_time >= sysdate - (15 / (24 * 60))
           and a.event_name in
               ('E_PLAY', 'SSAS_connection_allowed', 'E_STOP')
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

  function add_swver(p_name        varchar2,
                     p_crypto_type varchar2,
                     p_swkey       varchar2,
                     p_apiversion  varchar2 default '4',
                     p_url         varchar2 default '') return varchar2 is
    req     utl_http.req;
    resp    utl_http.resp;
    rw      varchar2(256);
    v_param VARCHAR2(5000) := '{
    "jsonrpc": "2.0", 
    "method": "add_swver", 
    "params": {"name": "_NAME_", "apiversion": "_apiversion_" ,"crypto_type":"_crypto_type_","swkey":"_swkey_","url":"_url_"}
}';
    /* v_param        VARCHAR2(5000) := '{
        "jsonrpc": "2.0", 
        "method": "add_swver", 
        "params": {"name": "_NAME_", "apiversion": "_apiversion_" ,"crypto_type":"_crypto_type_","swkey":"_swkey_"}
    }'; */
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(256);
    v_msg          varchar2(1024);
  
  begin
    v_param := replace(v_param, '_NAME_', p_name);
    v_param := replace(v_param, '_apiversion_', p_apiversion);
    v_param := replace(v_param, '_swkey_', p_swkey);
    v_param := replace(v_param, '_crypto_type_', p_crypto_type);
    v_param := replace(v_param, '_url_', p_url);
  
    v_param_length := length(v_param);
    --  UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
    /*
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
    */
    rw_result := link_set.link_set.post_to_cdi(v_param);
  
    update mfg_software_files a
       set a.cdi_message = rw_result, a.cdi_req = v_param
     where a.file_name = p_name;
    commit;
  
    v_msg := add_swver_stg(p_name,
                           p_crypto_type,
                           p_swkey,
                           p_apiversion,
                           p_url);
    v_msg := add_swver_stg_2(p_name,
                             p_crypto_type,
                             p_swkey,
                             p_apiversion,
                             p_url);
    return '0';
  
  end;

  function add_swver_stg(p_name        varchar2,
                         p_crypto_type varchar2,
                         p_swkey       varchar2,
                         p_apiversion  varchar2 default '4',
                         p_url         varchar2 default '') return varchar2 is
    req     utl_http.req;
    resp    utl_http.resp;
    rw      varchar2(256);
    v_param VARCHAR2(5000) := '{
    "jsonrpc": "2.0", 
    "method": "add_swver", 
    "params": {"name": "_NAME_", "apiversion": "_apiversion_" ,"crypto_type":"_crypto_type_","swkey":"_swkey_","url":"_url_"}
}';
    /* v_param        VARCHAR2(5000) := '{
        "jsonrpc": "2.0", 
        "method": "add_swver", 
        "params": {"name": "_NAME_", "apiversion": "_apiversion_" ,"crypto_type":"_crypto_type_","swkey":"_swkey_"}
    }'; */
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(256);
  
  begin
    v_param := replace(v_param, '_NAME_', p_name);
    v_param := replace(v_param, '_apiversion_', p_apiversion);
    v_param := replace(v_param, '_swkey_', p_swkey);
    v_param := replace(v_param, '_crypto_type_', p_crypto_type);
    v_param := replace(v_param, '_url_', p_url);
  
    v_param_length := length(v_param);
    --  UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
    Req := Utl_Http.Begin_Request('http://s-management01.tw.svc.litv.tv:8283/cdi/Management',
                                  'POST',
                                  'HTTP/1.1');
  
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
  
    update mfg_software_files a
       set a.s_cdi_message = rw_result, a.s_cdi_req = v_param
     where a.file_name = p_name;
    commit;
  
    utl_http.end_response(resp);
  
    commit;
  
    return '0';
  
  end;

  function add_swver_stg_2(p_name        varchar2,
                           p_crypto_type varchar2,
                           p_swkey       varchar2,
                           p_apiversion  varchar2 default '4',
                           p_url         varchar2 default '') return varchar2 is
    req     utl_http.req;
    resp    utl_http.resp;
    rw      varchar2(256);
    v_param VARCHAR2(5000) := '{
    "jsonrpc": "2.0", 
    "method": "add_swver", 
    "id":"1",
    "params": {"name": "_NAME_","crypto_type":"_crypto_type_","swkey":"_swkey_","url":"_url_"}
}';
    /* v_param        VARCHAR2(5000) := '{
        "jsonrpc": "2.0", 
        "method": "add_swver", 
        "params": {"name": "_NAME_", "apiversion": "_apiversion_" ,"crypto_type":"_crypto_type_","swkey":"_swkey_"}
    }'; */
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(256);
  
  begin
    v_param := replace(v_param, '_NAME_', p_name);
    v_param := replace(v_param, '_swkey_', p_swkey);
    v_param := replace(v_param, '_crypto_type_', p_crypto_type);
    v_param := replace(v_param, '_url_', p_url);
  
    v_param_length := length(v_param);
    --  UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
    Req := Utl_Http.Begin_Request('http://172.23.200.81/Bsm_sw_service/BSM_Software_Service.ashx',
                                  'POST',
                                  'HTTP/1.1');
  
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
  
    update mfg_software_files a
       set a.s_cdi_message = rw_result, a.s_cdi_req = v_param
     where a.file_name = p_name;
    commit;
  
    utl_http.end_response(resp);
  
    commit;
  
    return '0';
  
  end;

  function set_var(p_client_id varchar2, p_name varchar2, p_var varchar2)
    return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "client.set_var", 
    "params": {
        "client_id": "_MAC_ADDRESS_",
        "name":"_NAME_",
        "value":"_VALUE_"
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_client_id);
    v_param := replace(v_param, '_NAME_', p_name);
    v_param := replace(v_param, '_VALUE_', p_var);
  
    v_param_length := length(v_param);
    -- UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
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
    /*    insert into BSM_CLIENT_CDI_LOG
      (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
    values
      (sysdate, p_client_id, v_param, rw_result);
    commit; */
  
    return rw_result;
  
  end;

  function get_cdi_info(p_client_id varchar2) return clob is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", 
    "method": "client.get", 
    "params": {
        "client_id": "_MAC_ADDRESS_"
    }
}

';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_client_id);
  
    /*
    v_param_length := length(v_param);
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
    */
    rw_result := link_set.link_set.post_to_cdi(v_param);
  
    return rw_result;
  
  end;

  function del_mobile_number_mapping(p_device_id     varchar2,
                                     p_mobile_number varchar2) return clob is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0",
    "method": "device.delete_mobile_number_mapping",
    "params": {
        "device_id": "_MAC_ADDRESS_",
        "mobile_number":"_MOBILE_NUMBER_"
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    v_param := replace(v_param, '_MAC_ADDRESS_', p_device_id);
    v_param := replace(v_param, '_MOBILE_NUMBER_', p_mobile_number);
  
    /*
    v_param_length := length(v_param);
    Req            := Utl_Http.Begin_Request(manager_url,
                                             'POST',
                                             'HTTP/1.1');
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
    */
    rw_result := link_set.link_set.post_to_cdi(v_param);
    /*  insert into BSM_CLIENT_CDI_LOG
       (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
     values
       (sysdate, p_device_id, v_param, rw_result);
     commit;
    */
    return rw_result;
  
  end;

  FUNCTION get_device_current_swver(p_client_id varchar2,
                                    p_device_id varchar2) return varchar2 as
    jsonObj json;
    req     utl_http.req; --request object(pl/sql record)
    resp    utl_http.resp; --response objects(pl/sql record)
    buf     VARCHAR2(32767);
    pagelob clob;
    v_swver varchar2(1024);
  
    content varchar2(4000) := '{
    "jsonrpc": "2.0", 
    "method": "device.get", 
    "params": {
        "client_id": "P_client_id",
        "device_id": "P_device_id"
       
    }
}
';
    v_ver   varchar2(1024);
  BEGIN
    if p_device_id is not null then
      content := replace(content, 'P_device_id', p_device_id);
      content := replace(content, 'P_client_id', p_client_id);
    
      pagelob := link_set.link_set.post_to_cdi(content);
    
      jsonobj := json(pagelob);
      v_ver   := json_ext.get_string(jsonobj, 'result.current_swver');
      if v_ver = 'None' then
        v_ver := get_result_current_swver(p_client_id);
      end if;
    
      return v_ver;
      dbms_lob.freetemporary(pagelob);
    else
      return null;
    end if;
  exception
    when others then
      return null;
    
  end;

  FUNCTION get_device_model(p_client_id varchar2, p_device_id varchar2)
    return varchar2 as
    jsonObj    json;
    req        utl_http.req; --request object(pl/sql record)
    resp       utl_http.resp; --response objects(pl/sql record)
    rw         VARCHAR2(32767);
    model_info varchar2(1024);
    pagelob    clob;
    content    varchar2(4000) := '{
    "jsonrpc": "2.0", 
    "method": "device.get", 
    "params": {
        "client_id": "P_client_id",
        "device_id": "P_device_id"
       
    }
}
';
  BEGIN
    utl_http.set_transfer_timeout(3);
    if p_device_id is not null then
      content := replace(content, 'P_device_id', p_device_id);
      content := replace(content, 'P_client_id', p_client_id);
      req     := utl_http.begin_request(link_set.link_set.cdi_manager_url,
                                        'POST',
                                        'HTTP/1.1');
      begin
        utl_http.set_header(req, 'Content-Length', length(content));
        utl_http.write_text(req, content);
        resp := utl_http.get_response(req);
        dbms_lob.createtemporary(pagelob, true);
        loop
          begin
            rw := null;
            utl_http.read_line(resp, rw, TRUE);
            pagelob := pagelob || rw;
          exception
            when others then
              exit;
          end;
        end loop;
        utl_http.end_response(resp);
      exception
        when others then
          utl_http.end_response(resp);
      end;
      jsonobj := json(pagelob);
    
      if json_ext.get_string(jsonobj, 'result.model_info') is not null then
        model_info := json_ext.get_string(jsonobj, 'result.model_info');
        return replace(model_info, 'Samsung ', '');
      end if;
      dbms_lob.freetemporary(pagelob);
    else
      return null;
    end if;
  
    return null;
  exception
    when others then
      return null;
  end;

  function cdi_set_password(p_client_id varchar2, p_password varchar2)
    return clob is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0",
    "method": "client.set_password",
    "params": {
        "client_id": "_CLIENT_ID_",
        "password":"_PASSWORD_"
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      clob;
  
  begin
    v_param := replace(v_param, '_CLIENT_ID_', p_client_id);
    v_param := replace(v_param, '_PASSWORD_', p_password);
  
    rw_result := link_set.link_set.post_to_cdi(v_param);
    /* insert into BSM_CLIENT_CDI_LOG
      (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
    values
      (sysdate, p_client_id, v_param, rw_result);
    commit; */
  
    return rw_result;
  
  end;

begin
  select link_set.link_set.cdi_manager_url into manager_url from dual;
end BSM_CDI_SERVICE_DEV;
/

