create or replace procedure iptv.set_dlc_user_password(phone_no varchar2, password varchar2) is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '{
   "jsonrpc": "2.0",
  "id": 0,
  "method": "writeUserPass",
  "params": {
         "phoneNo:"_PHONE_NO_",    //客戶電話號碼
         "pass":"_PASSWORD_"         //客戶密碼
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);

  begin
      v_param := replace(v_param, '_PHONE_NO_', phone_no);
      v_param := replace(v_param, '_PASSWORD_', password);


        v_param_length := length(v_param);
      --  UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
        Req := Utl_Http.Begin_Request('http://cuscom.abula888.com.tw/request/rpc', 'POST', 'HTTP/1.1');

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
end;
/

