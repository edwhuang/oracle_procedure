CREATE OR REPLACE PROCEDURE IPTV."REFRASH_BSM_SPECIAL"
(server varchar2)

as
  jsonObj      json;
  req  utl_http.req; --request object(pl/sql record)
  resp utl_http.resp;--response objects(pl/sql record)
  buf VARCHAR2(32767);
  pagelob clob;
  content_2 varchar2(4000);
  content varchar2(4000) :=
'{  "id":"1234",
    "jsonrpc": "2.0",
    "method": "post_package_special",
    "params": {}
}';
BEGIN
  content_2 :=content;

 --UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
 req := utl_http.begin_request('http://'||server||'.tw.svc.litv.tv/BSM_pc_service/bsm_pc_service.ashx','POST','HTTP/1.1');

 utl_http.set_header(req,'Content-Length',length(content_2));
 utl_http.write_text(req, content_2);
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
  jsonobj:=json(pagelob);

end;
/

