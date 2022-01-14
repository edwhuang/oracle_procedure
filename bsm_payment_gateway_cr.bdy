CREATE OR REPLACE PACKAGE BODY IPTV.BSM_PAYMENT_GATEWAY_CR is

  -- office 
  -- PAYMENT_GATEWAY_URL varchar2(256):='http://172.21.200.241:5600/NewebPayment/CCAccept';

  -- colo
 -- PAYMENT_GATEWAY_URL varchar2(256) := 'http://172.23.200.102:5600/NewebPayment/CCAccept';
  PAYMENT_GATEWAY_URL varchar2(256) := 'http://172.23.200.107:8080/pay/jsp/AcceptPaymentResult.jsp';
  -- 正式
   v_USERID varchar2(32) :='M_tgc';
   v_passwd varchar2(32) := 'e8muwx75';

  -- Developer 
--  v_USERID varchar2(32) := 'tgc';
 -- v_passwd varchar2(32) := 'tgc123';

 -- v_PaymentType    varchar2(32) := 'SSL';
 -- v_MerchantNumber varchar2(32) := '757955';
 -- v_ApproveFlag    varchar2(32) := '1';
--  v_DepositFlag    varchar2(32) := '0';
 -- v_OrderURL       varchar2(32) := 'http://www.neweb.com.tw';
  
    v_PaymentType    varchar2(32) := 'SSL';
  v_MerchantNumber varchar2(32) := '761124';
  v_ApproveFlag    varchar2(32) := '1';
  v_DepositFlag    varchar2(32) := '1';
  v_OrderURL       varchar2(32) := 'https://www.neweb.com.tw';

  -- 正式
   HostIP varchar2(64) := 'steel.neweb.com.tw:443';

  -- 開發
 -- HostIP varchar2(64) := 'maple.neweb.com.tw:443';

  -- Author  : EDWARD.HUANG
  -- Created : 2010/6/30 下午 03:15:02
  -- Purpose :

  -- Public type declarations
  -- type <TypeName> is <Datatype>;
  function AccePayment(p_order_no    varchar2,
                       p_amt         number,
                       p_card_type   varchar2,
                       p_card_no     varchar2,
                       p_card_expiry varchar2,
                       p_cvc2        varchar2,
                       parameter_options varchar2 default null) return varchar2 is
    jsonObj           json;                       
    p_postdata varchar2(30000);
    p_respond  varchar2(30000);
    http_req   utl_http.req;
    http_resp  utl_http.resp;
    resp       XMLType;
    res        varchar2(64);
    connect_exception exception;
    v_OrderNumber     number(16);
    v_errorCode       varchar2(32);
    v_ECI             varchar2(32);
    v_XID             varchar2(32);
    v_CAVV            varchar2(32);
    v_test_card       varchar2(32);
    v_cvc2            varchar2(32);
    v_expire_yymm     varchar2(32);
    v_phone_no        varchar2(32);
    v_client_phone_no varchar2(32);
    v_USERID_p        varchar2(32);
    v_passwd_p        varchar2(32);
    v_MerchantNumber_p varchar2(32);
  begin
    /*
      -- Developer 
  v_USERID varchar2(32) := 'tgc';
  v_passwd varchar2(32) := 'tgc123';

  v_PaymentType    varchar2(32) := 'SSL';
  v_MerchantNumber varchar2(32) := '757955';
  v_ApproveFlag    varchar2(32) := '1';
  v_DepositFlag    varchar2(32) := '0';
  v_OrderURL       varchar2(32) := 'http://www.neweb.com.tw';

  -- 正式
  -- HostIP varchar2(64) := 'steel.neweb.com.tw:443';

  -- 開發 
  HostIP varchar2(64) := 'maple.neweb.com.tw:443';
  */
  /*  if (parameter_options is not null and parameter_options = '') then
    jsonobj := json(parameter_options);
    v_USERID_p :=  json_ext.get_string(jsonobj, 'userid');
    v_passwd_p :=  json_ext.get_string(jsonobj, 'password');
    v_MerchantNumber_p := json_ext.get_string(jsonobj, 'merchantnumber');
    if v_USERID_p is not null then
       v_USERID := v_USERID_p;
    end if;
    
    if v_passwd_p is not null then
       v_passwd := v_passwd_p;
    end if;
    
    if v_MerchantNumber_p is not null then  
       v_MerchantNumber_p :=v_MerchantNumber;
    end if;
    end if;
*/
    begin
      select cvc2, expire_yymm, phone_no
        into v_cvc2, v_expire_yymm, v_phone_no
        from mfg_dev_credit
       where card_no = p_card_no
         and start_date <= sysdate
         and end_date + 1 > sysdate
         and status_flg='P'
         and rownum <= 1;
    
      if v_phone_no is not null then
        select a.owner_phone
          into v_client_phone_no
          from bsm_client_mas a
         where a.status_flg = 'A'
           and mac_address = (select serial_id
                                from bsm_purchase_mas b
                               where b.pk_no = p_order_no);
      
        if v_client_phone_no = v_phone_no then
          if v_cvc2 = p_cvc2 and v_expire_yymm = p_card_expiry then
            p_respond := 'PRC=0';
          else
            p_respond := 'PRC=3';
          end if;
        else
          p_respond := 'PRC=3';
        end if;
      else
        if v_cvc2 = p_cvc2 and v_expire_yymm = p_card_expiry then
          p_respond := 'PRC=0';
        else
          p_respond := 'PRC=3';
        end if;
      end if;
    
      v_test_card := 'Y';
    exception
      when no_data_found then
        v_test_card := 'N';
    end;
  
    if v_test_card <> 'Y' then
    
      select seq_payment_order_no.nextval into v_orderNumber from dual;
    begin
      update bsm_purchase_mas
         set pay_pk_no = v_orderNumber
       where pk_no = p_order_no;
       
      update bsm_order_mas
         set pay_pk_no = v_orderNumber
       where pk_no = p_order_no;
     exception
       when others then null;
     end;
    
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (p_order_no,
         Sysdate,
         'CREDIT',
         'Before ' || p_postdata || '||' || p_respond||' >> '||parameter_options);
      commit;
      
        utl_http.set_transfer_timeout(30000);
    
      p_postdata := 'userid=' || v_userid || '&passwd=' || v_passwd ||
                    '&PaymentType=' || v_PaymentType || '&MerchantNumber=' ||
                    v_MerchantNumber || '&OrderNumber=' || v_OrderNumber ||
                    '&OrgOrderNumber=' || p_Order_No || '&Amount=' ||
                    to_char(p_Amt) || '.00' || '&Currency=901&Country=158' ||
                    '&CardType=' || p_Card_Type || '&CardNumber=' ||
                    p_Card_no || '&CardExpiry=' || p_Card_Expiry ||
                    '&ApproveFlag=' || v_ApproveFlag || '&DepositFlag=' ||
                    v_DepositFlag || '&OrderURL=' || v_OrderURL || '&CVC2=' ||
                    p_CVC2 || '&ErrorCode=' || v_ErrorCode || '&ECI=' ||
                    v_ECI || '&CAVV=' || v_CAVV || '&XID=' || v_XID;
      http_req   := utl_http.begin_request(PAYMENT_GATEWAY_URL,
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
    
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (p_order_no, Sysdate, 'CREDIT', p_postdata || '||' || p_respond);
      commit;
    
    end if;

    return substr(p_respond,instr(p_respond,'PRC'));
  
  end;
  
    
    
    function DepositR(p_order_no    varchar2) return varchar2 is
    jsonObj           json;                       
    p_postdata varchar2(30000);
    p_respond  varchar2(30000);
    http_req   utl_http.req;
    http_resp  utl_http.resp;
    resp       XMLType;
    res        varchar2(64);
    connect_exception exception;
    v_OrderNumber     number(16);
    v_errorCode       varchar2(32);
    v_ECI             varchar2(32);
    v_XID             varchar2(32);
    v_CAVV            varchar2(32);
    v_test_card       varchar2(32);
    v_cvc2            varchar2(32);
    v_expire_yymm     varchar2(32);
    v_phone_no        varchar2(32);
    v_client_phone_no varchar2(32);
    v_USERID_p        varchar2(32);
    v_passwd_p        varchar2(32);
    v_MerchantNumber_p varchar2(32);
  begin

      select pay_pk_no into v_orderNumber from bsm_purchase_mas where pk_no = p_order_no;
       
    
      p_postdata := 'userid=' || v_userid || '&passwd=' || v_passwd ||
                    '&PaymentType=' || v_PaymentType || '&MerchantNumber=' ||
                    v_MerchantNumber || '&OrderNumber=' || v_OrderNumber ||
                    '&operation=DepositReversal';
      http_req   := utl_http.begin_request('http://172.23.200.107:8080/pay/jsp/DepositReversal_CR.jsp',
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
    
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (p_order_no, Sysdate, 'CREDIT', p_postdata || '||' || p_respond);
      commit;
    


    return substr(p_respond,instr(p_respond,'PRC'));
  
  end;
    
  
   function Refund(p_order_no    varchar2,p_amount number default null) return varchar2 is
    jsonObj           json;                       
    p_postdata varchar2(30000);
    p_respond  varchar2(30000);
    http_req   utl_http.req;
    http_resp  utl_http.resp;
    resp       XMLType;
    res        varchar2(64);
    connect_exception exception;
    v_OrderNumber     number(16);
    v_errorCode       varchar2(32);
    v_ECI             varchar2(32);
    v_XID             varchar2(32);
    v_CAVV            varchar2(32);
    v_test_card       varchar2(32);
    v_cvc2            varchar2(32);
    v_expire_yymm     varchar2(32);
    v_phone_no        varchar2(32);
    v_client_phone_no varchar2(32);
    v_USERID_p        varchar2(32);
    v_passwd_p        varchar2(32);
    v_MerchantNumber_p varchar2(32);
    v_amount           varchar2(32);
  begin

      select pay_pk_no,nvl(p_amount,a.amount) into v_orderNumber,v_amount from bsm_purchase_mas a where pk_no = p_order_no;
       
    
      p_postdata := 'userid=' || v_userid || '&passwd=' || v_passwd ||
                    '&PaymentType=' || v_PaymentType || '&MerchantNumber=' ||
                    v_MerchantNumber || '&OrderNumber=' || v_OrderNumber ||'&Amount=' || v_Amount ||
                    '&operation=Refund';
      http_req   := utl_http.begin_request('http://172.23.200.107:8080/pay/jsp/refund_CR.jsp',
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
    
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (p_order_no, Sysdate, 'CREDIT', p_postdata || '||' || p_respond);
      commit;
    


    return substr(p_respond,instr(p_respond,'PRC'));
  
  end;
   
        function QueryOrders(p_order_no    varchar2) return varchar2 is
    jsonObj           json;                       
    p_postdata varchar2(30000);
    p_respond  varchar2(30000);
    http_req   utl_http.req;
    http_resp  utl_http.resp;
    resp       XMLType;
    res        varchar2(64);
    connect_exception exception;
    v_OrderNumber     number(16);
    v_errorCode       varchar2(32);
    v_ECI             varchar2(32);
    v_XID             varchar2(32);
    v_CAVV            varchar2(32);
    v_test_card       varchar2(32);
    v_cvc2            varchar2(32);
    v_expire_yymm     varchar2(32);
    v_phone_no        varchar2(32);
    v_client_phone_no varchar2(32);
    v_USERID_p        varchar2(32);
    v_passwd_p        varchar2(32);
    v_MerchantNumber_p varchar2(32);
    v_amount           varchar2(32);
  begin

      select pay_pk_no,a.amount into v_orderNumber,v_amount from bsm_purchase_mas a where pk_no = p_order_no;
       
    
      p_postdata := 'userid=' || v_userid || '&passwd=' || v_passwd ||
                    '&PaymentType=' || v_PaymentType || '&MerchantNumber=' ||
                    v_MerchantNumber || '&OrderNumber=' || v_OrderNumber ||
                    '&operation=QueryOrders';
      http_req   := utl_http.begin_request('http://172.23.200.107:8080/pay/jsp/QueryOrders_api.jsp',
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
    
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (p_order_no, Sysdate, 'CREDIT', p_postdata || '||' || p_respond);
      commit;
    


    return substr(p_respond,instr(p_respond,'PRC'));
  
  end;



end BSM_PAYMENT_GATEWAY_CR;
/

