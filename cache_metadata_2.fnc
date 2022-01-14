create or replace function iptv.cache_metadata_2 return clob is
  req            utl_http.req;
  resp           utl_http.resp;
  rw             varchar2(32767);
  url            varchar2(500) := 'http://p-management02.tw.svc.litv.tv:8283/cdi/Management';
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
      insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, 'cache_metadata', v_param, 'start');
      commit;

      utl_http.set_transfer_timeout(60000000);
    
      v_param_length := length(v_param);
    
      Req := Utl_Http.Begin_Request(url, 'POST', 'HTTP/1.1');
    
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
      
      insert into BSM_CLIENT_CDI_LOG
        (EVENT_TIME, CLIENT_ID, REQUIRED_DATA, RESULT_DATA)
      values
        (sysdate, 'cache_metadata', v_param, rw_result);
      commit;
    
    end if;
  end;

  return rw_result;
end;
/

