CREATE OR REPLACE FUNCTION IPTV.GET_CDI_INFO
(client_id varchar2)
return clob
as
  jsonObj      json;
  req  utl_http.req; --request object(pl/sql record)
  resp utl_http.resp;--response objects(pl/sql record)
  buf VARCHAR2(32767);
  pagelob clob;
  content varchar2(4000) :=
'{
    "jsonrpc": "2.0",
    "method": "client.get",
    "params": {
        "client_id": "P_client_id"

    }
}
';
BEGIN
 content :=replace(content,'P_client_id',client_id);
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
  end;
  utl_http.end_response(resp);
  return pagelob;
  dbms_lob.freetemporary(pagelob);

end;
/

