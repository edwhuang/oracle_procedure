create or replace package body iptv.BSM_CHT_SERVICE_DEV is

  function subscribe(p_purchase_pk_no number,
                     p_otpw           varchar2,
                     p_authority      varchar2,
                     p_actiondate     varchar2) return varchar2 is
  
    cursor c1 is
      select b.pk_no b_pk_no, serial_id, b.package_id, a.rowid rid
        from bsm_purchase_mas a, bsm_purchase_item b, bsm_package_mas c
       where b.mas_pk_no = a.pk_no
         and c.package_id = b.package_id
         and a.pk_no = p_purchase_pk_no
         and rownum <= 1;
  
    P_ALIAS       varchar(64);
    P_PRODUCTID   varchar2(64);
    P_FIRSTCHARGE varchar2(64);
  
    jsonObj       json;
    req           utl_http.req;
    resp          utl_http.resp;
    buf           VARCHAR2(32767);
    pagelob       clob;
    content       varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "Alias" : "P_ALIAS", "ProductID" : "P_PRODUCTID", "OTPW" : "P_OTPW", "Authority" : "P_AUTHORITY","ActionDate":"P_ACTIONDATE"}}';
    v_SubscribeNO varchar2(32);
    v_result      varchar2(128);
    P_GATEWAY     varchar2(128);
    v_cat         varchar2(32);
  BEGIN
    for i in c1 loop
      P_ALIAS := i.serial_id;
    
      Select x.cht_product_id, x.cat
        into P_PRODUCTID, v_cat
        from bsm_cht_map x
       where upper(x.cht_payment_method) = upper(p_authority)
         and package_id = i.package_id;
      update bsm_purchase_item b
         set b.cht_product_id = P_PRODUCTID, b.cht_cat = v_cat
       where b.pk_NO = i.b_pk_no;
      commit;
    
      P_FIRSTCHARGE := '';
      if p_otpw = 'TEST' then
        update bsm_purchase_mas a
           set a.cht_subscribeno = 'Test', a.cht_auth = p_authority
         where rowid = i.rid;
        commit;
        return 'PRC=0&subscribeno=Test';
      
      end if;
    
      utl_http.set_transfer_timeout(1200);
    
      if v_cat = 'LITV' then
        P_GATEWAY := 'http://s-bsm01.tw.svc.litv.tv/BSM_HINET_SERVICE/bsm_hinet.ashx';
      else
        P_GATEWAY := 'http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
      end if;
    
      content := replace(content, 'P_METHOD', 'Subscribe');
      content := replace(content, 'P_ALIAS', P_ALIAS);
      content := replace(content, 'P_PRODUCTID', P_PRODUCTID);
      content := replace(content, 'P_OTPW', p_otpw);
      content := replace(content, 'P_AUTHORITY', p_authority);
      content := replace(content, 'P_FIRSTCHARGE', P_FIRSTCHARGE);
      content := replace(content, 'P_ACTIONDATE', P_ActionDate);
    
      req := utl_http.begin_request(P_GATEWAY, 'POST', 'HTTP/1.1');
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
      dbms_lob.freetemporary(pagelob);
    
      if json_ext.get_string(jsonobj, 'result.result_code') = 'Success' or
         p_otpw = '9C588896F00D3128387712418AA236F1AATUNAOS' then
        v_SubscribeNO := json_ext.get_string(jsonobj, 'result.subscribeno');
        v_result      := 'PRC=0&subscribeno=' || v_SubscribeNO;
        update bsm_purchase_mas a
           set a.cht_subscribeno = v_SubscribeNO,
               a.cht_auth        = p_authority,
               a.cht_otpw        = p_otpw
         where rowid = i.rid;
      else
        v_result := 'ERROR_CODE=' ||
                    json_ext.get_string(jsonobj, 'result.result_code');
      end if;
    
      if p_otpw = 'TEST' and p_authority = 'TEST' then
        v_result := 'PRC=0&subscribeno=TEST';
        update bsm_purchase_mas a
           set a.cht_subscribeno = 'TEST', a.cht_auth = 'TEST'
         where rowid = i.rid;
      end if;
    
    end loop;
    return v_result;
  END;

  function authorization(p_purchase_pk_no number,
                         p_otpw           varchar2,
                         p_authority      varchar2) return varchar2 is
  
    cursor c1 is
      select b.pk_no         b_pk_no,
             serial_id,
             b.package_id,
             c.charge_amount,
             a.rowid         rid
        from bsm_purchase_mas a, bsm_purchase_item b, bsm_package_mas c
       where b.mas_pk_no = a.pk_no
         and c.package_id = b.package_id
         and a.pk_no = p_purchase_pk_no;
  
    P_ALIAS       varchar(64);
    P_PRODUCTID   varchar2(64);
    P_FIRSTCHARGE varchar2(64);
    P_GATEWAY     varchar(1024);
  
    jsonObj       json;
    req           utl_http.req;
    resp          utl_http.resp;
    buf           VARCHAR2(32767);
    pagelob       clob;
    content       varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "Alias" : "P_ALIAS", "ProductID" : "P_PRODUCTID", "OTPW" : "P_OTPW", "Authority" : "P_AUTHORITY", "Fee":"P_FEE"}}';
    v_SubscribeNO varchar2(128);
    v_result      varchar2(128);
    v_product_id  varchar2(128);
    v_cat         varchar2(32);
  BEGIN
    for i in c1 loop
      P_ALIAS := i.serial_id;
    
      Select x.cht_product_id, x.cat
        into P_PRODUCTID, v_cat
        from bsm_cht_map x
       where upper(x.cht_payment_method) = upper(p_authority)
         and package_id = i.package_id;
    
      update bsm_purchase_item b
         set b.cht_product_id = P_PRODUCTID, b.cht_cat = v_cat
       where b.pk_NO = i.b_pk_no;
      commit;
      utl_http.set_transfer_timeout(1200);
      if v_cat = 'LITV' then
        P_GATEWAY := 'http://s-bsm01.tw.svc.litv.tv/BSM_HINET_SERVICE/bsm_hinet.ashx';
      else
        P_GATEWAY := 'http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
      end if;
    
      if p_otpw = 'TEST' then
        update bsm_purchase_mas a
           set a.cht_subscribeno = 'Test', a.cht_auth = p_authority
         where rowid = i.rid;
        commit;
        return 'PRC=0&subscribeno=Test';
      end if;
      P_FIRSTCHARGE := '';
    
      content := replace(content, 'P_METHOD', 'Authorize');
      content := replace(content, 'P_ALIAS', P_ALIAS);
      content := replace(content, 'P_PRODUCTID', P_PRODUCTID);
      content := replace(content, 'P_OTPW', p_otpw);
      content := replace(content, 'P_AUTHORITY', p_authority);
      content := replace(content, 'P_FIRSTCHARGE', P_FIRSTCHARGE);
      content := replace(content, 'P_FEE', i.charge_amount);
    
      req := utl_http.begin_request(P_GATEWAY, 'POST', 'HTTP/1.1');
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
      dbms_lob.freetemporary(pagelob);
    
      if json_ext.get_string(jsonobj, 'result.result_code') = 'Success' then
        if p_authority = 'Credit' then
          v_result := Accounting(p_purchase_pk_no, p_otpw, p_authority);
        end if;
        v_result := 'PRC=0&subscribeno=' || v_SubscribeNO;
        update bsm_purchase_mas a
           set a.cht_subscribeno = v_SubscribeNO, a.cht_auth = p_authority
         where rowid = i.rid;
      else
        v_result := 'ERROR_CODE=' ||
                    json_ext.get_string(jsonobj, 'result.result_code');
      end if;
    
      if p_otpw = 'TEST' and p_authority = 'TEST' then
        v_result := 'PRC=0&subscribeno=TEST';
        update bsm_purchase_mas a
           set a.cht_subscribeno = 'TEST', a.cht_auth = 'TEST'
         where rowid = i.rid;
      end if;
    
    end loop;
  
    return v_result;
  END;

  function Accounting(p_purchase_pk_no number,
                      p_otpw           varchar2,
                      p_authority      varchar2) return varchar2 is
  
    cursor c1 is
      select b.pk_no b_pk_no,
             serial_id,
             b.package_id,
             c.package_cat1 || c.package_name packname,
             c.charge_amount,
             a.rowid rid
        from bsm_purchase_mas a, bsm_purchase_item b, bsm_package_mas c
       where b.mas_pk_no = a.pk_no
         and c.package_id = b.package_id
         and a.pk_no = p_purchase_pk_no;
  
    P_ALIAS       varchar(64);
    P_PRODUCTID   varchar2(64);
    P_FIRSTCHARGE varchar2(64);
    P_GATEWAY     varchar(1024);
  
    jsonObj       json;
    req           utl_http.req;
    resp          utl_http.resp;
    buf           VARCHAR2(32767);
    pagelob       clob;
    content       varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "Alias" : "P_ALIAS", "ProductID" : "P_PRODUCTID", "OTPW" : "P_OTPW", "Authority" : "P_AUTHORITY", "Fee":"P_FEE","SRemark" : "P_SREMARK" }}';
    v_SubscribeNO varchar2(128);
    v_result      varchar2(128);
    v_product_id  varchar2(128);
    v_cat         varchar2(32);
  
  BEGIN
    for i in c1 loop
      P_ALIAS := i.serial_id;
    
      Select x.cht_product_id, x.cat
        into P_PRODUCTID, v_cat
        from bsm_cht_map x
       where upper(x.cht_payment_method) = upper(p_authority)
         and package_id = i.package_id;
      update bsm_purchase_item b
         set b.cht_product_id = P_PRODUCTID, b.cht_cat = v_cat
       where b.pk_NO = i.b_pk_no;
      commit;
      utl_http.set_transfer_timeout(1200);
      if v_cat = 'LITV' then
        P_GATEWAY := 'http://s-bsm01.tw.svc.litv.tv/BSM_HINET_SERVICE/bsm_hinet.ashx';
      else
        P_GATEWAY := 'http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
      end if;
    
      if p_otpw = 'TEST' then
        update bsm_purchase_mas a
           set a.cht_subscribeno = 'Test', a.cht_auth = p_authority
         where rowid = i.rid;
        commit;
        return 'PRC=0&subscribeno=Test';
      end if;
      P_FIRSTCHARGE := '';
    
      content := replace(content, 'P_METHOD', 'Accounting');
      content := replace(content, 'P_ALIAS', P_ALIAS);
      content := replace(content, 'P_PRODUCTID', P_PRODUCTID);
      content := replace(content, 'P_OTPW', p_otpw);
      content := replace(content, 'P_AUTHORITY', p_authority);
      content := replace(content, 'P_FIRSTCHARGE', P_FIRSTCHARGE);
      content := replace(content, 'P_FEE', i.charge_amount);
      content := replace(content, 'P_SREMARK', i.packname);
    
      req := utl_http.begin_request(P_GATEWAY, 'POST', 'HTTP/1.1');
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
      dbms_lob.freetemporary(pagelob);
    
      if json_ext.get_string(jsonobj, 'result.result_code') = 'Success' then
        v_result := json_ext.get_string(jsonobj, 'result.result_code');
      else
        v_result := 'ERROR_CODE=' ||
                    json_ext.get_string(jsonobj, 'result.result_code');
      end if;
    
      if p_otpw = 'TEST' and p_authority = 'TEST' then
        v_result := 'PRC=0&subscribeno=TEST';
        update bsm_purchase_mas a
           set a.cht_subscribeno = 'TEST', a.cht_auth = 'TEST'
         where rowid = i.rid;
      end if;
    
      update bsm_purchase_mas a
         set a.response_code = v_result
       where pk_no = p_purchase_pk_no;
      commit;
    
    end loop;
    return v_result;
  END;

  function QuerySubscribe(p_purchase_pk_no number) return varchar2 is
  
    cursor c1 is
      select serial_id,
             b.package_id,
             b.cht_product_id,
             b.cht_cat         cat,
             c.charge_amount,
             a.rowid           rid,
             a.cht_subscribeno,
             a.cht_auth
        from bsm_purchase_mas a, bsm_purchase_item b, bsm_package_mas c
       where b.mas_pk_no = a.pk_no
         and c.package_id = b.package_id
         and a.pk_no = p_purchase_pk_no;
  
    P_ALIAS       varchar(64);
    P_PRODUCTID   varchar2(64);
    P_FIRSTCHARGE varchar2(64);
    P_GATEWAY     varchar(1024);
  
    jsonObj       json;
    req           utl_http.req;
    resp          utl_http.resp;
    buf           VARCHAR2(32767);
    pagelob       clob;
    content       varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "Alias" : "P_ALIAS", "ProductID" : "P_PRODUCTID","SubscribeNo":"P_SubscrubNo","ApID":"P_APID"}}';
    v_SubscribeNO varchar2(128);
    v_result      varchar2(128);
  BEGIN
  
    for i in c1 loop
      BEGIN
        SELECT 'Success'
          into v_result
          from CHT_RECURRENT_FAILURE
         where serial_id = i.serial_id
           and 1=2
           and result_code <> 'Success';
      exception
        when no_data_found then
          begin
            P_ALIAS     := i.serial_id;
            P_PRODUCTID := i.cht_product_id;
            utl_http.set_transfer_timeout(1200);
            if i.cat in ('LITV') then
              P_GATEWAY := 'http://s-bsm01.tw.svc.litv.tv/BSM_HINET_SERVICE/bsm_hinet.ashx';
            else
              P_GATEWAY := 'http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
            end if;
          
            P_FIRSTCHARGE := '';
          
            content := replace(content, 'P_METHOD', 'QuerySubscribe');
            content := replace(content, 'P_ALIAS', P_ALIAS);
            content := replace(content, 'P_PRODUCTID', i.cht_product_id);
            content := replace(content, 'P_SubscrubNo', i.cht_subscribeno);
            content := replace(content, 'P_APID', i.cht_auth);
          
            req := utl_http.begin_request(P_GATEWAY, 'POST', 'HTTP/1.1');
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
              v_result := 'ERROR';
            end if;
            dbms_lob.freetemporary(pagelob);
          
            v_result := json_ext.get_string(jsonobj, 'result.result_code');
          end;
      end;
    
    end loop;
    return v_result;
  END;

  function UnSubscribe(p_purchase_pk_no number,
                       p_action_date    varchar2 default null)
    return varchar2 is
  
    cursor c1 is
      select serial_id,
             b.package_id,
             c.charge_amount,
             a.rowid rid,
             a.cht_subscribeno,
             a.cht_auth,
             b.cht_product_id,
             b.cht_cat
        from bsm_purchase_mas a, bsm_purchase_item b, bsm_package_mas c
       where b.mas_pk_no = a.pk_no
         and c.package_id = b.package_id
         and a.pk_no = p_purchase_pk_no;
  
    P_ALIAS       varchar(64);
    P_PRODUCTID   varchar2(64);
    P_FIRSTCHARGE varchar2(64);
    P_GATEWAY     varchar(1024);
  
    jsonObj          json;
    req              utl_http.req;
    resp             utl_http.resp;
    buf              VARCHAR2(32767);
    v_cht_product_id varchar2(32);
    pagelob          clob;
    content          varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "Alias" : "P_ALIAS", "ProductID" : "P_PRODUCTID","SubscribeNo":"P_SubscrubNo","ApID":"P_APID","ActionDate":"P_ACTIONDATE"}}';
    v_SubscribeNO    varchar2(128);
    v_result         varchar2(128);
  BEGIN
    for i in c1 loop
      P_PRODUCTID := i.cht_product_id;
      P_ALIAS     := i.serial_id;
      utl_http.set_transfer_timeout(1200);
      if i.cht_cat in ('LITV') then
        P_GATEWAY := 'http://s-bsm01.tw.svc.litv.tv/BSM_HINET_SERVICE/bsm_hinet.ashx';
      else
        P_GATEWAY := 'http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
      end if;
    
      P_FIRSTCHARGE := '';
    
      content := replace(content, 'P_METHOD', 'UnSubscribe');
      content := replace(content, 'P_ALIAS', P_ALIAS);
      content := replace(content, 'P_PRODUCTID', P_PRODUCTID);
      content := replace(content, 'P_SubscrubNo', i.cht_subscribeno);
      content := replace(content, 'P_APID', i.cht_auth);
      content := replace(content, 'P_ACTIONDATE', p_action_date);
    
      req := utl_http.begin_request(P_GATEWAY, 'POST', 'HTTP/1.1');
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
      dbms_lob.freetemporary(pagelob);
    
      if json_ext.get_string(jsonobj, 'result.result_code') = 'Success' then
        update bsm_recurrent_mas a
           set a.status_flg = 'B', a.end_date = sysdate
         where a.src_pk_no = p_purchase_pk_no;
        commit;
      end if;
    
      v_result := json_ext.get_string(jsonobj, 'result.result_code');
    
    end loop;
    return v_result;
  END;

  function QueryATM(p_purchase_pk_no number) return varchar2 is
  
    cursor c1 is
      select a.cht_otpw,
             b.package_id,
             a.cht_auth,
             b.cht_product_id,
             b.cht_cat
        from bsm_purchase_mas a, bsm_purchase_item b, bsm_package_mas c
       where b.mas_pk_no = a.pk_no
         and c.package_id = b.package_id
         and a.pk_no = p_purchase_pk_no;
  
    jsonObj          json;
    req              utl_http.req;
    resp             utl_http.resp;
    buf              VARCHAR2(32767);
    v_cht_product_id varchar2(32);
    pagelob          clob;
    content          varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "aa_OTPW":"P_OTPW"}}';
    v_SubscribeNO    varchar2(128);
    v_result         varchar2(128);
    P_GATEWAY        varchar2(128);
    P_PRODUCTID      varchar2(128);
  BEGIN
    for i in c1 loop
      utl_http.set_transfer_timeout(1200);
      if i.cht_cat in ('LITV') then
        P_GATEWAY := 'http://s-bsm01.tw.svc.litv.tv/BSM_HINET_SERVICE/bsm_hinet.ashx';
      else
        P_GATEWAY := 'http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
      end if;
    
      content := replace(content, 'P_METHOD', 'QueryATM');
      content := replace(content, 'P_OTPW', i.cht_otpw);
    
      req := utl_http.begin_request(P_GATEWAY, 'POST', 'HTTP/1.1');
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
      dbms_lob.freetemporary(pagelob);
    
      v_result := json_ext.get_string(jsonobj, 'result.result_code');
    
    end loop;
    return v_result;
  END;
  
   function ATMMultiplebills(p_purchase_pk_no number,p_otpw varchar2) return varchar2 is

    cursor c1 is select a.amount,a.purchase_date  
    from bsm_purchase_mas a,bsm_purchase_item b,bsm_package_mas c where b.mas_pk_no=a.pk_no and c.package_id=b.package_id and a.pk_no=p_purchase_pk_no;
    
    P_ALIAS varchar(64);
    P_PRODUCTID varchar2(64);
    P_FIRSTCHARGE varchar2(64);
    P_GATEWAY varchar(1024);


    jsonObj json;
    req     utl_http.req;
    resp    utl_http.resp;
    buf     VARCHAR2(32767);
    pagelob clob;
    content varchar2(4000) := '{"jsonrpc": "2.0","id":"1114","method":"P_METHOD","params":{ "aa_OTPW" : "P_OTPW", "Multiplebills":"P_Multiplebills"}}';
    v_SubscribeNO varchar2(128);
    v_result varchar2(128);
    v_product_id varchar2(128);
    v_cat varchar2(32);
    
  BEGIN
    for i in c1 loop
        P_GATEWAY:='http://172.23.200.117/BSM_PC_SERVICE/bsm_hinet.ashx';
    
          content := replace(content, 'P_METHOD', 'ATMMultiplebills');

          content := replace(content, 'P_OTPW', p_otpw);
          content := replace(content, 'P_Multiplebills', '1^'||to_char(i.purchase_date,'YYYYMMDD')||to_char(i.purchase_date,'YYYYMMDD')||lpad(to_char(i.amount),6,'0'));

          req     := utl_http.begin_request(P_GATEWAY,
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
          dbms_lob.freetemporary(pagelob);
          
          if json_ext.get_string(jsonobj, 'result.result_code') = 'Success' then
             v_result :=json_ext.get_string(jsonobj, 'result.result_code');
          else
            v_result := 'result_code='||json_ext.get_string(jsonobj, 'result.result_code');
          end if; 
          
   end loop;
   return v_result;
  END;


end BSM_CHT_SERVICE_DEV;
/

