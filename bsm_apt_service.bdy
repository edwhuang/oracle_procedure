create or replace package body iptv.BSM_APT_SERVICE is
  function apt_register_purchase(p_src_no varchar2, v_pk_no number)
    return varchar2 is
    
    cursor c1 is
      select a.apt_min, apt_productcode
        from bsm_purchase_item a
       where a.mas_pk_no = v_pk_no;
    v_status_flg varchar2(32);
    v_pay_type   varchar2(32);
    v_mas_no     varchar2(32);
    register_msg varchar2(32);
  begin
    select a.mas_no, a.status_flg, a.pay_type
      into v_mas_no, v_status_flg, v_pay_type
      from bsm_purchase_mas a
     where a.pk_no = v_pk_no;
    for c1rec in c1 loop
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (v_pk_no,
         Sysdate,
         'APT_Register',
         'Before ' || c1rec.apt_min || ' ' || c1rec.apt_productcode || ' ' ||
         v_mas_no);
      commit;
    
      register_msg := register(c1rec.apt_min,
                               c1rec.apt_productcode,
                               v_mas_no);
    
      Insert Into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      Values
        (v_pk_no,
         Sysdate,
         'APT_Register',
         'result ' || register_msg || ' ' || c1rec.apt_min || ' ' ||
         c1rec.apt_productcode || ' ' || v_mas_no);
      commit;
    end loop;
    
    return register_msg;

  end;
  
  function check_min(p_min varchar2) return varchar2 is
    result clob;
    jsonobj json;
  begin
    if p_min is null then
      return 'N';
    else
      jsonobj                     := get_apt_result('apt.get_MDN',
                                                    p_min,
                                                    null,
                                                    null);
      result :=  json_ext.get_string(jsonobj,
                                                         'result');  
      return result;      
    end if;                                                                                                
                                                       
  end;

  function get_user_info(p_min varchar2) return varchar2 is
    v_phone_no   varchar2(32);
    jsonobj      json;
    userInfo     json;
    v_error_code varchar(32);
  begin
    BSM_APT_SERVICE.phone_no    := null;
    BSM_APT_SERVICE.user_status := null;
    jsonobj                     := get_apt_result('apt.get_MDN',
                                                  p_min,
                                                  null,
                                                  null);
    v_error_code                := json_ext.get_string(jsonobj,
                                                       'result.ErrorCode');
    if v_error_code is not null then
      if v_error_code = '0x01020002' then
        raise apt_min_error;
      end if;
      if v_error_code = '0x0102000F' then
        raise apt_unknow_error;
      end if;
    end if;
    v_phone_no := json_ext.get_string(jsonobj, 'result.UserInfo.MDN');
    if v_phone_no is null then
      raise not_apt_user;
    end if;
    BSM_APT_SERVICE.phone_no    := v_phone_no;
    BSM_APT_SERVICE.user_status := json_ext.get_string(jsonobj,
                                                       'result.UserInfo.OSSUserStatus');
    if BSM_APT_SERVICE.user_status <> '0' then
      raise apt_not_act_user;
    end if;
    return phone_no;
  end;

  function register(p_min           varchar2,
                    p_productcode   varchar2,
                    p_transactionId varchar2) return varchar2 is
    jsonobj      json;
    userInfo     json;
    v_error_code varchar(32);
  begin
    jsonobj      := get_apt_result('apt.register',
                                   p_min,
                                   p_productcode,
                                   p_transactionId);
    v_error_code := json_ext.get_string(jsonobj,
                                        'result.ValidError.ValidErrorCode');
    if v_error_code = 16842754 then
      raise apt_min_error;
    end if;     
    if v_error_code = 17104898 then
      raise apt_product_code;
    end if;   
    if v_error_code = 17432578 then
      raise apt_bought;
    end if;                                
    if v_error_code is not null then
      
      raise register_error;
    end if;
    return 'PRC=0';
  end;

  function check_service(p_min varchar2, p_productcode varchar2)
    return varchar2 is
    jsonobj      json;
    userInfo     json;
    v_error_code varchar(32);
  begin
    jsonobj      := get_apt_result('apt.check_service',
                                   p_min,
                                   p_productcode,
                                   '');
    v_error_code := json_ext.get_string(jsonobj,
                                        'result.CheckSubscription.ErrorCode');
    if v_error_code is not null then
      raise register_error;
    end if;
    return 'PRC=0';
  end;

  function get_apt_result(p_method      varchar2,
                          p_MIN         varchar2,
                          p_productCode varchar2,
                          transactionId varchar2) return JSON is
    jsonObj json;
    req     utl_http.req;
    resp    utl_http.resp;
    buf     VARCHAR2(32767);
    pagelob clob;
    content varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{"MIN":"P_MIN","ProductCode":"P_PRODUCTCODE","TransationId":"P_TRANSACTIONID"}}';
  BEGIN
    content := replace(content, 'P_METHOD', p_method);
    content := replace(content, 'P_MIN', p_MIN);
    content := replace(content, 'P_PRODUCTCODE', p_productCode);
    content := replace(content, 'P_TRANSACTIONID', transactionId);
    req     := utl_http.begin_request('http://bsm01.tw.svc.litv.tv/BSM_APT_Service/BSM_APT_Service.ashx',
                                      'POST',
                                      'HTTP/1.1');
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
    end;
    utl_http.end_response(resp);

    jsonobj := json(pagelob);
    if json_ext.get_string(jsonobj, 'error.name') = 'JSONRPCError' then
      Raise Jsonrpc_error;
    end if;
    return jsonobj;
    dbms_lob.freetemporary(pagelob);
  END;

end BSM_APT_SERVICE;
/

