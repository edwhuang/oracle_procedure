CREATE OR REPLACE FUNCTION IPTV."GET_CDI_CHECK_ACCESS"
(client_id varchar2,device_id varchar2,asset_id varchar2)
return varchar2
as
  jsonObj      json;  
  req  utl_http.req; --request object(pl/sql record)
  resp utl_http.resp;--response objects(pl/sql record)
  buf VARCHAR2(32767);
  pagelob clob;
  content varchar2(4000) := 
'{
"jsonrpc": "2.0",
"id":"1112",
"method":"client.check_access",
"params":{"client_id":"P_CLIENT_ID","device_id":"P_DEVICE_ID","asset_id":"P_ASSET_ID","token":"P_TOKEN","play":"true"}
}';
BEGIN
  if client_id is not null then
 content :=replace(content,'P_CLIENT_ID',client_id);
  content :=replace(content,'P_DEVICE_ID',device_id);
  content :=replace(content,'P_ASSET_ID',asset_id);
  content :=replace(content,'P_TOKEN',get_device_token(client_id,device_id));
-- UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
-- req := utl_http.begin_request('http://proxy01.tw.svc.litv.tv/cdi/v1/Config','POST','HTTP/1.1');
-- req := utl_http.begin_request('http://management01.tw.svc.litv.tv/cdi/Management','POST','HTTP/1.1');
req := utl_http.begin_request(link_set.link_set.cdi_manager_url,'POST','HTTP/1.1');

 utl_http.set_header(req,'Content-Length',length(content));
 utl_http.write_text(req, content);
 resp := utl_http.get_response(req);
 dbms_lob.createtemporary(pagelob,true);
 begin
  LOOP
   utl_http.read_text(resp,buf);
   dbms_lob.writeappend(pagelob,length(buf),buf);
  END LOOP;
  EXCEPTION
     WHEN UTL_HTTP.TOO_MANY_REQUESTS  THEN  
      UTL_HTTP.END_RESPONSE(resp);    
     WHEN others THEN
     dbms_output.put_line(sys.utl_http.GET_DETAILED_SQLERRM()); 
   ---WHEN utl_http.end_of_body THEN
   ---
  end;
  utl_http.end_response(resp);
  jsonobj:=json(pagelob);
  if json_ext.get_bool(jsonobj,'result.access') then
    return 'ture';
  else
    return 'false';
  end if;
  -- dbms_output.put_line(json_ext.get_string(jsonobj,'result.latest_swver'));  
--  return json_ext.get_string(jsonobj,'result.access');
  -- dbms_output.put_line(json_ext.get_string(jsonobj,'result.latest_swver'));  
  
  dbms_lob.freetemporary(pagelob);
  else
    return null;
  end if;
end;
/

