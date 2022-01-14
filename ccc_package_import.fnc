create or replace function iptv.ccc_package_import return varchar2 is
  req            utl_http.req;
  resp           utl_http.resp;
  rw             varchar2(32767);
  url            varchar2(500) := 'http://172.23.200.96/bsm_ccc_service/bsm_ccc_service.ashx';
  v_param        VARCHAR2(500) := '{
    "jsonrpc": "2.0", "id":"1111",
    "method": "ImportDataToCCC",
    "params": {}
    }';
  v_param_length NUMBER := length(v_param);
  rw_result      varchar2(32767);

begin
  utl_http.set_transfer_timeout(10800);

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
  
  Insert Into Sysevent_Log(App_Code, Pk_No,Event_Date, User_No,Event_Type, Seq_No, Description, LOG) 
  Values('ImportToCCC', to_char(sysdate, 'yyyymmddhh24miss'), Sysdate, 0,  'ImportDataToCCC_result',  Sys_Event_Seq.Nextval,   'ImportDataToCCC_result', rw_result);
  commit;


  return rw_result;

end;
/

