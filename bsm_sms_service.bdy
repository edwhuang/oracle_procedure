CREATE OR REPLACE PACKAGE BODY IPTV.BSM_SMS_SERVICE IS

  --  Sms_Purchase Varchar2(1024) := 'LiTV%A4W%AE%F8%B6O+%ADq%B3%E6%BDs%B8%B9#PURCHASE_NO#%2C%AA%F7%C3B#AMOUNT#';
  Sms_Purchase Varchar2(1024) := 'LiTV%BA%F4%B8%F4%B9q%B5%F8%AAA%B0%C8%A4w%A6%AC%A8%EC%B1z%AA%BA%ADq%B3%E6#PURCHASE_NO#+%A1A%AA%F7%C3B%24#AMOUNT#%A1A%A9%FA%B2%D3%BD%D0%A6%DC%BA%F4%AF%B8%B7%7C%AD%FB%B1M%B0%CF%ACd%B8%DF';
  --  Acl_Http_Url Varchar2(256) := 'http://172.21.200.248/ACL_Interface/Service.Asmx';
  ACL_Http_Url Varchar2(256) := 'https://us-dev-cdi01.tgc-service.net/2010-10-26/soapapi/Authentication?wsdl';
  Sms_User_Id  Varchar2(32) := 'edwardhuang';
  Sms_Password Varchar2(32) := 'QWer1234';
  cht_sms_account varchar2(32) := '10903';
  cht_sms_password varchar2(32):= '10903';

  Function Send_Sms_Messeage_cht(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2 Is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(3000) := '{
    "jsonrpc": "2.0",
    "method": "send_sms",
    "id":"_id_";
    "params": {
        "Account": "_Account_",
        "Password":"_Password_",
        "SendPhone":"_SendPhone_",
        "Message":"_Message_"
    }
}
';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
    v_utf_Text varchar2(2048);
  
  begin
    
   v_utf_Text:=utl_url.escape(p_Message,FALSE,'UTF8') ;

    v_param := replace(v_param, '_Account_', cht_sms_account);
    v_param := replace(v_param, '_Password_', cht_sms_password);
    v_param := replace(v_param, '_SendPhone_', p_Phone_No);
    v_param := replace(v_param, '_Message_', v_utf_Text);
    v_param := replace(v_param, '_id_', to_char(sysdate,'YYYMMDDHH24MISS'));

    v_param_length := length(v_param);
   -- UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
   utl_http.set_transfer_timeout(3);
    Req := Utl_Http.Begin_Request('http://bsm01.tw.svc.litv.tv/BSM_SMS_SERVICE/CHTSms.ashx', 'POST', 'HTTP/1.1');

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
      insert into bsm_client_sms_log
        (client_id, message, phone_number, event_date, sms_response,message_code)
      values
        (p_client_id, p_message, p_Phone_no, sysdate, rw_result,p_message_code);
    commit;

    return rw_result;


  end;

 Function Send_Sms_Message_k(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2 Is
    Http_Request Varchar2(30000);
    Http_Respond Varchar2(30000);
    Http_Req     Utl_Http.Req;
    Http_Resp    Utl_Http.Resp;
    v_Sms_Url    Varchar2(10000);
    v_Big5_Text  Varchar2(10000);

    v_Result Varchar2(256);
    v_start_time varchar2(32);
    v_sms_count number(16);
  Begin
  --  select count(*) into v_sms_count from bsm_client_sms_log where event_date >= sysdate - (1/(24*60));
  --  if v_sms_count < 200 then
    v_start_time := to_char(sysdate,'YYYYMMDD HH24:MI:SS');
    v_Big5_Text:=utl_url.escape(p_Message,FALSE,'ZHT16MSWIN950') ;
    
    
     /*   v_Sms_Url   := 'http://202.39.48.216/kotsmsapi-1.php?username=' ||
                   Sms_User_Id || '&password=' || Sms_Password ||
                   '&dstaddr=' || p_Phone_No || '&smbody=' || v_Big5_Text;  */
                   
         v_Sms_Url   := 'http://kotsms.com.tw/ApiSend.php?username=' ||
                   Sms_User_Id || '&password=' || Sms_Password ||
                   '&dstaddr=' || p_Phone_No || '&smbody=' || v_Big5_Text;   
     utl_http.set_transfer_timeout(3);    


    Http_Req := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');


    Http_Resp := Utl_Http.Get_Response(Http_Req);
    Utl_Http.Read_Text(Http_Resp, Http_Respond);
    Utl_Http.End_Response(Http_Resp);

 --   if p_client_id is not null then
      insert into bsm_client_sms_log
        (client_id, message, phone_number, event_date, sms_response,message_code,status_flg)
      values
        (p_client_id, p_message, p_Phone_no, sysdate, Http_Respond,p_message_code,'P');
      commit;
 --   end if;

    Return Http_Respond;
 /*   else
        insert into bsm_client_sms_log
        (client_id, message, phone_number, event_date, sms_response,message_code,status_flg)
      values
        (p_client_id, p_message, p_Phone_no, sysdate, Http_Respond,p_message_code,'N');
      commit;
      Return Http_Respond;
    end if;  */
  exception when others then return '';
  End;
  
   Function Send_Sms_Message_4g(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2 Is
    Http_Request Varchar2(30000);
    Http_Respond Varchar2(30000);
    Http_Req     Utl_Http.Req;
    Http_Resp    Utl_Http.Resp;
    v_Sms_Url    Varchar2(10000);
    v_Big5_Text  Varchar2(10000);
    v_message    varchar2(10000);

    v_Result Varchar2(256);
    v_start_time varchar2(32);
    v_sms_count number(16);
  Begin
    v_message := p_Message;
    while(instr(v_message,'LiTV') >0) loop
      v_message:=replace(v_message,'LiTV','4gTV');
    end loop;
  --  select count(*) into v_sms_count from bsm_client_sms_log where event_date >= sysdate - (1/(24*60));
  ---  if v_sms_count < 200 then
    v_start_time := to_char(sysdate,'YYYYMMDD HH24:MI:SS');
    v_Big5_Text:=utl_url.escape(p_Message,FALSE,'ZHT16MSWIN950') ;
             v_Sms_Url   := 'http://kotsms.com.tw/ApiSend.php?username=' ||
                   '4gtv' || '&password=' || '25768517' ||
                   '&dstaddr=' || p_Phone_No || '&smbody=' || v_Big5_Text; 
      /*  v_Sms_Url   := 'http://202.39.48.216/kotsmsapi-1.php?username=' ||
                   '4gtv' || '&password=' ||'25768517' ||
                   '&dstaddr=' || p_Phone_No || '&smbody=' || v_Big5_Text; */
     
  utl_http.set_transfer_timeout(3);    

    Http_Req := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');


    Http_Resp := Utl_Http.Get_Response(Http_Req);
    Utl_Http.Read_Text(Http_Resp, Http_Respond);
    Utl_Http.End_Response(Http_Resp);

 --   if p_client_id is not null then
      insert into bsm_client_sms_log
        (client_id, message, phone_number, event_date, sms_response,message_code,status_flg)
      values
        (p_client_id, p_message, p_Phone_no, sysdate, Http_Respond,p_message_code,'P');
      commit;
 --   end if;

    Return Http_Respond;
 /* --  else
        insert into bsm_client_sms_log
        (client_id, message, phone_number, event_date, sms_response,message_code,status_flg)
      values
        (p_client_id, p_message, p_Phone_no, sysdate, Http_Respond,p_message_code,'N');
      commit;
      Return Http_Respond;
  --  end if;  */
  exception when others then null;
  End;

  Function Send_Sms_Messeage(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2 Is
    v_msg varchar2(1024);
    v_count number(16);
  begin
 /*   begin
      select sms_count into v_count from bsm_sms_count a where f_year=to_number(to_char(sysdate,'YYYY')) and f_period=to_number(to_char(sysdate,'MM')) and a.gateway ='CHT';
    exception
      when no_data_found then
          v_count := 0;
          insert into bsm_sms_count(f_year,f_period,gateway,sms_count) values (to_number(to_char(sysdate,'YYYY')),to_number(to_char(sysdate,'MM')),'CHT',1);
    end;
    if v_count <= -1 then
       v_msg := BSM_SMS_Service.Send_Sms_Messeage_cht(p_Phone_No,p_Message,p_client_id,p_message_code);
             update bsm_sms_count a
      set sms_count=sms_count+1
      where f_year=to_number(to_char(sysdate,'YYYY')) and f_period=to_number(to_char(sysdate,'MM')) and a.gateway ='CHT';

    else */
    --  if (p_client_id <> '2A0046B054FEF0D0')  THEN 
    declare
      v_char varchar2(32);
    begin
      select 'x' into v_char from mfg_dev_account_mas a where a.owner_phone_no = p_Phone_No and a.status_flg='P' and 1=2;
    exception
      when no_data_found then
        if substr(p_client_id,1,2)='F6' then
          v_msg :=  BSM_SMS_Service.Send_Sms_Message_4g(p_Phone_No,p_Message,p_client_id,p_message_code);
        else
          v_msg :=  BSM_SMS_Service.Send_Sms_Message_k(p_Phone_No,p_Message,p_client_id,p_message_code);
        end if;
    end;
     
   --   END IF;
    --  if v_msg = 'kmsgid=-60014' then
    --    v_msg := BSM_SMS_Service.Send_Sms_Messeage_cht(p_Phone_No,p_Message,p_client_id,p_message_code);
    --  end if;


   -- end if;

    commit;


    return '';
  exception 
    when others then
      declare 
        Http_Respond VARCHAR2(3096) := sqlerrm;
      begin
              insert into bsm_client_sms_log
        (client_id, message, phone_number, event_date, sms_response,message_code,status_flg)
      values
        (p_client_id, p_message, p_Phone_no, sysdate, Http_Respond,p_message_code,'N');
      commit;
      end;
      return '';
  end;
  
  Function Send_Sms_Messeage_litv(p_Phone_No     Varchar2,
                                  p_Message      Varchar2,
                                  p_client_id    varchar2 default null,
                                  p_message_code varchar2 default null,
                                  p_purchase_no    varchar2 default null,
                                  amount         number default null)
    Return Varchar2 Is
    v_msg   varchar2(1024);
    v_count number(16);
  begin
    declare
      v_char varchar2(32);
    begin
      /*
            POST /sns/sms/pushSmsMessage HTTP/1.1
      Content-Type: application/json
      Authorization: Basic ZWR3YXJkaHVhbmc6UXdlcjEyMzQ=
      Host: s-lilink.tw.svc.litv.tv:8080
      Connection: close
      User-Agent: Paw/3.1.5 (Macintosh; OS X/10.13.2) GCDHTTPRequest
      Content-Length: 80 */
      select 'x'
        into v_char
        from mfg_dev_account_mas a
       where a.owner_phone_no = p_Phone_No
         and a.status_flg = 'P';
    exception
      when no_data_found then
        if substr(p_client_id, 1, 2) = 'F6' then
        
        --  if p_message_code = 'order' then
            v_msg:=send_sms('4gtv',amount,p_message_code,p_purchase_no,p_Phone_No);
        --  end if;
        else
        --  if p_message_code = 'order' then
            v_msg:=send_sms('litv',amount,p_message_code,p_purchase_no,p_Phone_No);
        --  end if;
        
        end if;
    end;
    
          insert into bsm_client_sms_log
        (client_id,
         message,
         phone_number,
         event_date,
         sms_response,
         message_code,
         status_flg)
      values
        (p_client_id,
         p_message_code,
         p_Phone_no,
         sysdate,
         v_msg,
         p_message_code,
         'N');
      commit;
  
    commit;
  
    return '';
  exception
    when others then
      declare
        Http_Respond VARCHAR2(3096) := sqlerrm;
      begin
        insert into bsm_client_sms_log
          (client_id,
           message,
           phone_number,
           event_date,
           sms_response,
           message_code,
           status_flg)
        values
          (p_client_id,
           p_message,
           p_Phone_no,
           sysdate,
           Http_Respond,
           p_message_code,
           'N');
        commit;
      end;
      return '';
  end;
  
      function send_sms_text(port varchar2,p_text varchar2,p_phone_no varchar2) return varchar2 is
  
    jsonObj json;
    req     utl_http.req;
    resp    utl_http.resp;
    buf     VARCHAR2(32767);
    pagelob clob;
    content varchar2(4000) := '{"type":"other","text": "_text_",
  "mobileNumber": "_phoneNo_"}';
  BEGIN
  
    content := replace(content, '_text_', p_text);
    content := replace(content, '_phoneNo_', p_phone_no);
  

    utl_http.set_transfer_timeout(3);
    
     UTL_HTTP.SET_BODY_CHARSET('UTF-8');
  
          req := utl_http.begin_request(link_set.link_set.p_lilink_url||'/sms/pushSmsMessage',
                                  'POST',
                                  'HTTP/1.1');
    utl_http.set_header(req,
                        'Content-Type',
                        'application/json; charset=utf-8');
        utl_http.set_header(req,
                        'Authorization',
                        'Basic ZWR3YXJkaHVhbmc6UXdlcjEyMzQ=');                   
    utl_http.set_header(req, 'Content-Length', LENGTHB(content));
  
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
    UTL_HTTP.END_RESPONSE(resp);
    return pagelob;
  end;
  
  
  function send_sms(port varchar2,p_amt varchar,p_type varchar2,p_pur_no varchar2,p_phone_no varchar2) return varchar2 is
  
    jsonObj json;
    req     utl_http.req;
    resp    utl_http.resp;
    buf     VARCHAR2(32767);
    pagelob clob;
    content varchar2(4000) := '{ "amount": "_amt_",
  "type": "_type_",
  "purchaseNo": "_purchaseNo_",
  "mobileNumber": "_phoneNo_"}';
  BEGIN
     utl_http.set_transfer_timeout(3);
  
    content := replace(content, '_amt_', p_amt);
    content := replace(content, '_type_', p_type);
    content := replace(content, '_purchaseNo_', p_pur_no);
    content := replace(content, '_phoneNo_', p_phone_no);
  
    /*
          POST /sns/sms/pushSmsMessage HTTP/1.1
    Content-Type: application/json
    Authorization: Basic ZWR3YXJkaHVhbmc6UXdlcjEyMzQ=
    Host: s-lilink.tw.svc.litv.tv:8080
    Connection: close
    User-Agent: Paw/3.1.5 (Macintosh; OS X/10.13.2) GCDHTTPRequest
    Content-Length: 80 *
    http://p-4gtvlilink.tw.svc.litv.tv/
 */
    if port = '4gtv' then
          req := utl_http.begin_request('http://p-4gtvlilink.tw.svc.litv.tv/sms/pushSmsMessage',
                                  'POST',
                                  'HTTP/1.1');
    else 
          req := utl_http.begin_request(link_set.link_set.p_lilink_url||'/sms/pushSmsMessage',
                                  'POST',
                                  'HTTP/1.1');
    end if;
    utl_http.set_header(req,
                        'Content-Type',
                        'application/json; charset=utf-8');
        utl_http.set_header(req,
                        'Authorization',
                        'Basic ZWR3YXJkaHVhbmc6UXdlcjEyMzQ=');                        
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
        ---WHEN utl_http.end_of_body THEN
      ---
    end;
    UTL_HTTP.END_RESPONSE(resp);
    return pagelob;
  end;

end;
/

