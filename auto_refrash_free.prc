create or replace procedure iptv.AUTO_REFRASH_FREE is
begin
  begin
declare
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{"id":"1","jsonrpc":"2.0","method":"refrash","params":{}}';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);

  begin
  
    v_param_length := length(v_param);
    Req := Utl_Http.Begin_Request('http://bsm01.tw.svc.litv.tv/free_content_service/free_content_service.ashx', 'POST', 'HTTP/1.1');
  
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
    commit;
  end;
  
  declare
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{"id":"1","jsonrpc":"2.0","method":"refrash","params":{}}';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);

  begin
  
    v_param_length := length(v_param);
    Req := Utl_Http.Begin_Request('http://bsm02.tw.svc.litv.tv/free_content_service/free_content_service.ashx', 'POST', 'HTTP/1.1');
  
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
    commit;
  end;
end;
end AUTO_REFRASH_FREE;
/

