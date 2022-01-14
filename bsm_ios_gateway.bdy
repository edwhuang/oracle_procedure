CREATE OR REPLACE PACKAGE BODY IPTV."BSM_IOS_GATEWAY" is

  -- office
  -- PAYMENT_GATEWAY_URL varchar2(256):='http://172.21.200.241:5600/NewebPayment/CCAccept';

  -- colo
  ios_storeURL varchar2(256) := link_set.link_set.p_bsm_json_url||'/BSM_Purchase_Service.ashx';
--  ios_storeURL varchar2(256) := 'https://buy.itunes.apple.com/verifyReceipt';

  function Send_Receipt_Data(p_order_no    varchar2,
                             p_receipt varchar2,
                             p_password varchar2,
                             p_ios_product_code varchar2
                      ) return clob is

    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
     v_param        varchar2(256) := '{"id":"1231","method":"ios_verifyReceipt","params":{"order_pk_no":p_order_pk_no,"p_receipt":"_RECEIPT-DATA","p_password":"_PASSWORD"}}';
    v_param_length NUMBER := length(v_param);


    rw_result      clob;
    v_char varchar2(32);
  begin
    begin
           select 'x' into v_char from bsm_ios_receipt_mas where mas_pk_no=p_order_no and rownum <=1;
    exception
       when no_data_found then
           insert into bsm_ios_receipt_mas(mas_pk_no,receipt,password,ios_product_code)
           values(p_order_no,p_receipt,p_password,p_ios_product_code);
           commit;
    end;
    rw_result :=  get_Receipt_Data(p_order_no,
                             p_receipt,
                             p_password,
                             p_ios_product_code);
    
                             
    return rw_result;
  end;

  function get_Receipt_Data(p_order_no    varchar2,
                             p_receipt varchar2,
                             p_password varchar2,
                             p_ios_product_code varchar2
                      ) return clob is

    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
     v_param        varchar2(256) := '{"id":"1231","method":"ios_verifyReceipt","params":{"order_pk_no":p_order_pk_no,"p_receipt":"_RECEIPT-DATA","p_password":"_PASSWORD"}}';
    v_param_length NUMBER := length(v_param);


    rw_result      clob;
    l_test varchar2(32767);
  begin
    v_param := replace(v_param, 'p_order_pk_no',  to_char(p_order_no));
    v_param_length := length(v_param);
    Req            := Utl_Http.Begin_Request(ios_storeURL,
                                             'POST',
                                             'HTTP/1.1');
    begin                                            
    UTL_HTTP.SET_HEADER(r     => req,
                        name  => 'Content-Length',
                        value => v_param_length);
    UTL_HTTP.WRITE_TEXT(r => req, data => v_param);
    resp := utl_http.get_response(req);

    dbms_lob.createtemporary(rw_result,false);
    loop
      begin
        rw := null;
        utl_http.read_text(resp, rw,32767);
    --    utl_http.read_line(resp, rw, TRUE);
        dbms_lob.writeappend(rw_result,length(rw),rw);
      exception
        when UTL_HTTP.end_of_body then
          exit;
      end;
    end loop;
    utl_http.end_response(resp);
    exception
      when others then utl_http.end_response(resp);
    end;
    return rw_result;
  end;

  function check_Receipt_Data(p_order_no varchar2, p_ios_product_code varchar2,p_date date default sysdate) return boolean
  is
    rw_result clob;
    jsonobj json;
    jbl json_list;
    status_flg varchar2(32);
  begin
    rw_result := get_Receipt_Data(p_order_no,'','',p_ios_product_code);
    jsonobj:=json(rw_result);


    begin
        status_flg := to_CHAR(json_ext.get_number(jsonobj,'result.status'));
        dbms_output.put_line(p_order_no||','||status_flg);

       -- jbl := json_ext.get_json_list(jsonobj,'result.latest_receipt_info');
    exception
      when others then raise latest_receipt_info_not_found;
    end;
    /*
    for i in 1 .. jbl.count  loop
      declare
        v_return_code varchar2(64);
        v_return_start varchar2(64);
        v_return_end varchar2(64);
        v_start_date date;
        v_end_date date;
      begin
        v_return_code :=  json_ext.get_string(json(jbl.get_elem(i)),'product_id');

        if v_return_code=p_ios_product_code then
           v_return_start :=  json_ext.get_string(json(jbl.get_elem(i)),'purchase_date');
           v_return_end :=  json_ext.get_string(json(jbl.get_elem(i)),'expires_date');
           -- 2016-02-22 10:08:24 Etc/GMT
           v_start_date :=to_date(substr(v_return_start,1,18),'YYYY/MM/DD HH24:MI:SS')+(8/24);
           v_end_date :=to_date(substr(v_return_start,1,18),'YYYY/MM/DD HH24:MI:SS')+(8/24);
           if (p_date >= v_start_date and p_date <= v_end_date) then
             return true;
           end if;
        end if;
      end;
    end loop;
    */
     if status_flg is null or status_flg = '0' then
        return true;
     else
        return false;
     end if;
  end;
    function check_Receipt_Data_str(p_order_no varchar2, p_ios_product_code varchar2,p_date date default sysdate) return varchar2
  is
    rw_result clob;
    jsonobj json;
    jbl json_list;
    status_flg varchar2(32);
  begin
    rw_result := get_Receipt_Data(p_order_no,'','',p_ios_product_code);
    jsonobj:=json(rw_result);


    begin
        status_flg := to_CHAR(json_ext.get_number(jsonobj,'result.status'));
    exception
      when others then raise latest_receipt_info_not_found;
    end;

    return status_flg;

  end;
  
  function get_exipired_date(p_order_no varchar2, p_ios_product_code varchar2) return date
  is
    rw_result clob;
    jsonobj json;
    jbl json_list;
    expire_date date;
  begin
    rw_result := get_Receipt_Data(p_order_no,'','',p_ios_product_code);
    jsonobj:=json(rw_result);


    begin
        expire_date := to_date(substr(json_ext.get_string(jsonobj,'result.latest_expired_receipt_info.expires_date_formatted'),1,10),'YYYY-MM-DD');
        if expire_date is null then
           expire_date := to_date(substr(json_ext.get_string(jsonobj,'result.latest_receipt_info.expires_date_formatted'),1,10),'YYYY-MM-DD');
        end if;
    exception
      when others then 
        begin
          expire_date := to_date(substr(json_ext.get_string(jsonobj,'result.latest_receipt_info.expires_date_formatted'),1,10),'YYYY-MM-DD');
        exception 
          when others then
             expire_date:=sysdate;
        end; 
    end;

    return expire_date;

  end;
    
end BSM_IOS_GATEWAY;
/

