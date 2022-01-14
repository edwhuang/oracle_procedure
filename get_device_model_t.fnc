CREATE OR REPLACE FUNCTION IPTV.get_device_model_t(p_client_id varchar2,
                                    p_device_id varchar2) return varchar2 as
    jsonObj json;
    req     utl_http.req; --request object(pl/sql record)
    resp    utl_http.resp; --response objects(pl/sql record)
    buf     VARCHAR2(32767);
    pagelob clob;
    content varchar2(4000) := '{
    "jsonrpc": "2.0",
    "method": "device.get",
    "params": {
        "client_id": "P_client_id",
        "device_id": "P_device_id"

    }
}
';
  BEGIN
    if p_device_id is not null then
      content := replace(content, 'P_device_id', p_device_id);
      content := replace(content, 'P_client_id', p_client_id);
      req     := utl_http.begin_request(link_set.link_set.cdi_manager_url,
                                        'POST',
                                        'HTTP/1.1');

      utl_http.set_header(req, 'Content-Length', length(content));
      utl_http.write_text(req, content);
      resp := utl_http.get_response(req);
      dbms_lob.createtemporary(pagelob, true);
      begin
        LOOP
          utl_http.read_text(resp, buf);
          dbms_lob.writeappend(pagelob, length(buf), buf);
        END LOOP;
      EXCEPTION
        WHEN UTL_HTTP.TOO_MANY_REQUESTS THEN
          UTL_HTTP.END_RESPONSE(resp);
        WHEN others THEN
          dbms_output.put_line(sys.utl_http.GET_DETAILED_SQLERRM());

      end;
      utl_http.end_response(resp);
      jsonobj := json(pagelob);
      if json_ext.get_string(jsonobj, 'result.model_info') is not null then
       --  jsonobj := json(json_ext.get_string(jsonobj, 'result.model_info'));
         return json_ext.get_string(jsonobj, 'result.model_info');
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
/

