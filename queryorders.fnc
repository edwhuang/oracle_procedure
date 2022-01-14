CREATE OR REPLACE FUNCTION IPTV.QUERYORDERS(p_start_date date, p_end_date date)
  return clob is
  PAYMENT_QUERY_URL varchar2(256) := 'http://172.23.200.102:5600/NewebPayment/CCAdmin';

  v_start_date varchar2(8) := to_char(p_start_date, 'YYYYMMDD');
  v_end_date   varchar(8) := to_char(p_end_date, 'YYYYMMDD');

  -- 正式
  HostIP     varchar2(64) := 'steel.neweb.com.tw:443';
  p_postdata varchar2(30000);
  p_respond  clob;
  http_req   utl_http.req;
  http_resp  utl_http.resp;
  connect_exception exception;
begin

  p_postdata := 'userid=M_tgc&passwd=e8muwx75&MerchantNumber=757955&Createbegintime=' ||
                v_start_date || '&Createendtime=' || v_end_date ||
                '&operation=QueryOrders';
  http_req   := utl_http.begin_request(PAYMENT_QUERY_URL,
                                       'POST',
                                       'HTTP/1.0');
  utl_http.set_header(http_req,
                      'Content-Type',
                      'application/x-www-form-urlencoded');
  utl_http.set_header(http_req, 'Host', HostIP);
  utl_http.set_header(http_req, 'Content-Length', length(p_postdata));
  utl_http.write_text(http_req, p_postdata);
  http_resp := utl_http.get_response(http_req);
  utl_http.read_text(http_resp, p_respond);
  utl_http.end_response(http_resp);
  return p_respond;

end;
/

