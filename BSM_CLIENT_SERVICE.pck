CREATE OR REPLACE PACKAGE BSM_CLIENT_SERVICE Is

  -- Author  : EDWARD.HUANG
  -- Created : 2010/6/30 下午 03:15:02
  -- Purpose :

  -- Public type declarations
  -- type <TypeName> is <Datatype>;
  Failure_Get_Client_Info Exception; --找不到Client Info 的資料
  Null_Mac_Address        Exception; --沒有Mac Address
  Serial_Id_Exception     Exception; -- Serial_ID 錯誤
  Status_Exception        Exception; --狀態錯誤]
  Error_Activation_Code   Exception;
  Error_Payment           Exception;
  Error_Package_Mas       Exception;
  Error_Sms_Connect       Exception;
  Dup_Transfer            Exception; -- 資料重複傳送
  Failure_crt_tax_info    Exception;
  Different_MAC_ADDRESS   Exception;
  Dup_MAC_Address         Exception;
  Different_Client_id     Exception;
  Error_Demo_account      Exception;
  Lock_client             Exception;
  Error_Recurrent_Dup     Exception;
  Error_Recurrent_Dup_c   Exception;

  -- purchase
  Error_Card_no Exception;

  -- for Coupon
  Error_Coupon_No        Exception;
  Error_Coupon_Status    Exception;
  Error_Coupon_Activated Exception;
  Error_Coupon_Model     Exception;
  Error_Coupon_Demo      Exception;
  Error_apt_min_null     Exception;
  Error_apt_user         Exception;
  Error_null_otpw        Exception;
  Error_null_authority   Exception;

  Status_Registed Exception;

  Function Send_Sms_Message(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null)
    Return Varchar2;

  Function Get_Client_Info(In_Mac_address Varchar2) Return Tbsm_Client_Info;
  Function Check_And_Register_Client(In_Client_Info  In Out Tbsm_Client_Info,
                                     activation_code varchar2 default '',
                                     send_passcode   boolean default true)
    Return Tbsm_Result;
  function call_acl_AddClient(p_serial_no number) return varchar2;

  Function Get_Activation_Code(In_Client_Info In Out Tbsm_Client_Info)
    Return Tbsm_Result;
  Function Crt_Purchase(In_Bsm_Purchase   In Out Tbsm_Purchase,
                        p_recurrent       varchar2 default 'O',
                        p_device_id       varchar2 default null,
                        parameter_options varchar2 default null,
                        p_sw_version      varchar2 default null)
    Return Tbsm_Result;
  Function Get_Content_List(p_Start Number, p_End Number)
    Return Tcms_Contentlist;
  Function Get_Content(p_Content_id String) Return tcms_content;
  Function Activate_Client(In_Client_Info    In Out Tbsm_Client_Info,
                           parameter_options varchar2 default null)
    Return Tbsm_Result;
  Function Get_Purchase(p_purchase_id String) Return tbsm_purchase;
  Procedure Set_subscription(p_pk_no Number, p_client_id varchar2);
  Function UnActivate_client(p_user_no number, p_Serial_id varchar2)
    return varchar2;
  Function UnGift(p_user_no number, p_Serial_id varchar2) return varchar2;
  Function Get_Activation_No Return Varchar2;
  Function Register_Coupon(In_Client_Info In Out Tbsm_Client_Info,
                           Coupon_NO      varchar2,
                           SRC_NO         out varchar2,
                           p_sw_version   varchar2 default null)
    return Tbsm_result;
  Function Register_Coupon(In_Client_Info In Out Tbsm_Client_Info,
                           Coupon_NO      varchar2) return Tbsm_result;

  Function send_mail(url varchar2) return varchar2;
  Function Get_Client_val(client_id     varchar2,
                          p_name        varchar2,
                          p_default_val clob) return clob;
  Function Set_Client_val(client_id     varchar2,
                          p_name        varchar2,
                          p_default_val clob) return clob;
  procedure refresh_bsm_client(v_client_id varchar2);

  procedure refresh_acg(v_client_id varchar2, v_promo_code varchar2);
   procedure saveClientServiceInfo(v_client_id varchar2);

End Bsm_Client_Service;
/
CREATE OR REPLACE PACKAGE BODY BSM_CLIENT_SERVICE Is

  -- Private type declarations
  -- type <TypeName> is <Datatype>;

  --  Sms_Purchase Varchar2(1024) := 'LiTV%A4W%AE%F8%B6O+%ADq%B3%E6%BDs%B8%B9#PURCHASE_NO#%2C%AA%F7%C3B#AMOUNT#';
  Sms_Purchase    Varchar2(1024) := 'LiTV線上影視服務已收到您的訂單#PURCHASE_NO#,金額#AMOUNT#,明細請至電視或網路會員專區查詢';
  Sms_Purchase_4G Varchar2(1024) := '四季影視4gTV已收到您的訂單#PURCHASE_NO#,金額#AMOUNT#,明細請至網路會員專區查詢'; --  Acl_Http_Url Varchar2(256) := 'http://172.21.200.248/ACL_Interface/Service.Asmx';
  ACL_Http_Url    Varchar2(256) := 'https://us-dev-cdi01.tgc-service.net/2010-10-26/soapapi/Authentication?wsdl';
  Sms_User_Id     Varchar2(32) := 'edwardhuang';
  Sms_Password    Varchar2(32) := 'QWer1234';

  -- Private constant declarations
  -- <ConstantName> constant <Datatype> := <Value>;

  -- Private variable declarations
  -- <VariableName> <Datatype>;

  -- Function and procedure implementations

  Function Call_Acl_Addclient(p_Serial_No Number) Return Varchar2 Is
    Soap_Request Varchar2(30000);
    Soap_Respond Varchar2(30000);
    Http_Req     Utl_Http.Req;
    Http_Resp    Utl_Http.Resp;
    Resp         Xmltype;
    Res          Varchar2(64);
    Connect_Exception Exception;
  Begin
    Soap_Respond := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:aut="Authentication" xmlns:soap="soapapi.SoapObjects">
   <soapenv:Header/>
   <soapenv:Body>
      <aut:put_client>
         <!--Optional:-->
         <aut:client>
            <!--Optional:-->
            <soap:client_group>1</soap:client_group>
            <!--Optional:-->
            <soap:state>C</soap:state>
            <!--Optional:-->
            <soap:id>12345678</soap:id>
         </aut:client>
      </aut:put_client>
   </soapenv:Body>
</soapenv:Envelope>';
    /*
        Soap_Request := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <AddClient xmlns="http://tempuri.org/">
          <p_Serail_no>' || To_Char(p_Serial_No) ||
                        '</p_Serail_no>
        </AddClient>
      </soap:Body>
    </soap:Envelope>'; */
    UTL_HTTP.set_wallet('file:' || 'C:\wallet\ca');
    --  Begin
    Http_Req := Utl_Http.Begin_Request(Acl_Http_Url, 'POST', 'HTTP/1.1');
    --    Exception
    --      When Others Then
    --      Raise Connect_Exception;
    --  End;
    Utl_Http.Set_Header(Http_Req, 'Content-Type', 'text/xml');
    Utl_Http.Set_Header(Http_Req, 'Content-Length', Length(Soap_Request));
    Utl_Http.Set_Header(Http_Req, 'SOAPAction', '"put"');
    Utl_Http.Write_Text(Http_Req, Soap_Request);
    Http_Resp := Utl_Http.Get_Response(Http_Req);
    Utl_Http.Read_Text(Http_Resp, Soap_Respond);
    Utl_Http.End_Response(Http_Resp);
  
    Resp := Xmltype.Createxml(Soap_Respond);
    --  Begin
    Select Extractvalue(Resp,
                        '/soap:Envelope/soap:Body/AddClientResponse/AddClientResult',
                        'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"  xmlns="http://tempuri.org/')
      Into Res
      From Dual;
    --  Exception
    --     When Others Then
    --       Res := 'ACL-00001';
    --      Return Res;
    --   End;
    --   Return Res;
    --Exception
    --   When Connect_Exception Then
    --    Res := 'ACL-00002';
    --    Return Res;
  End;

  Function Call_Acl_Grouptoclient(p_Acl_Group_Id Number,
                                  p_Serial_No    Number) Return Varchar2 Is
    Soap_Request Varchar2(30000);
    Soap_Respond Varchar2(30000);
    Http_Req     Utl_Http.Req;
    Http_Resp    Utl_Http.Resp;
    Resp         Xmltype;
    Res          Varchar2(64);
    Connect_Exception Exception;
  Begin
    Soap_Request := '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <AddGroupToClient xmlns="http://tempuri.org/">
      <p_ACL_Group_ID>' || p_Acl_Group_Id ||
                    '</p_ACL_Group_ID>
      <p_Serial_No>' || p_Serial_No || '</p_Serial_No>
    </AddGroupToClient>
  </soap:Body>
</soap:Envelope>';
    Begin
      Http_Req := Utl_Http.Begin_Request(Acl_Http_Url, 'POST', 'HTTP/1.1');
    Exception
      When Others Then
        Raise Connect_Exception;
    End;
    Utl_Http.Set_Header(Http_Req, 'Content-Type', 'text/xml');
    Utl_Http.Set_Header(Http_Req, 'Content-Length', Length(Soap_Request));
    Utl_Http.Set_Header(Http_Req,
                        'SOAPAction',
                        '"http://tempuri.org/AddGroupToClient"');
    Utl_Http.Write_Text(Http_Req, Soap_Request);
    Http_Resp := Utl_Http.Get_Response(Http_Req);
    Utl_Http.Read_Text(Http_Resp, Soap_Respond);
    Utl_Http.End_Response(Http_Resp);
  
    Resp := Xmltype.Createxml(Soap_Respond);
    Begin
      Select Extractvalue(Resp,
                          '/soap:Envelope/soap:Body/AddGroupToClientResponse/AddGroupToClientResult',
                          'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"  xmlns="http://tempuri.org/')
        Into Res
        From Dual;
    Exception
      When Others Then
        Res := 'ACL-00001';
        Return Res;
    End;
    Return Res;
  Exception
    When Connect_Exception Then
      Res := 'ACL-00002';
      Return Res;
  End;

  Procedure Set_Client_Connect_Event(p_Serial_No Number) Is
  Begin
    Update Bsm_Client_Mas a
       Set a.First_Connect_Date = Nvl(a.First_Connect_Date, Sysdate),
           a.Last_Connect_Date  = Sysdate
     Where Serial_No = p_Serial_No;
  End;

  Function Send_Sms_Message(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null)
    Return Varchar2 Is
    v_msg varchar(1024);
  
  Begin
    v_msg := bsm_sms_service.Send_Sms_Messeage(p_Phone_No,
                                               p_Message,
                                               p_client_id,
                                               '訂單確認');
  
    Return v_msg;
  
  End;

  Function Get_Activation_No Return Varchar2 Is
    v_Result Varchar2(32);
  Begin
    Select Lpad(Ceil(Dbms_Random.Value * 1000000), 6, '0')
      Into v_Result
      From Dual;
    Return v_Result;
  End;

  Function Get_Client_Info(In_Mac_Address Varchar2) Return Tbsm_Client_Info Is
    v_Rs Tbsm_Client_Info;
  Begin
    v_Rs := New Tbsm_Client_Info;
    Select Serial_No,
           Serial_Id,
           Owner_Phone,
           Owner_Id,
           Status_Flg,
           Default_Group,
           MAC_ADDRESS
      Into v_Rs.Serial_No,
           v_Rs.Serial_Id,
           v_Rs.Owner_Phone,
           v_Rs.Owner_Id,
           v_Rs.Status_Flg,
           v_Rs.Default_Group,
           v_Rs.MAC_Address
      From Bsm_Client_Mas a
     Where (mac_address = upper(In_Mac_Address) or
           a.serial_id = upper(In_Mac_Address))
       And Rownum <= 1;
    Return v_Rs;
    /* Exception
    When No_Data_Found Then
      Raise Failure_Get_Client_Info; */
  End;

  Function Check_And_Register_Client(In_Client_Info  In Out Tbsm_Client_Info,
                                     activation_code varchar2 default '',
                                     send_passcode   boolean default true)
    Return Tbsm_Result Is
    v_Client_Info Tbsm_Client_Info;
    v_Result      Tbsm_Result;
  
    v_Temp_Serial_Id     Varchar2(32);
    v_real_mac_address   varchar2(32);
    v_register_date      date;
    v_msg                varchar2(2000);
    v_test_activation_no varchar2(32);
    v_Activation_No      Varchar2(32);
    rid                  rowid;
  Begin
    v_Result := New Tbsm_Result();
  
    commit;
    -- check MAC_Address
    --
    -- if activation_code is not null for LG base don't check anythings
    --
    if (substr(In_Client_Info.Serial_ID, 1, 2) != 'AA') then
      --activation_code is not null then
      if (In_Client_Info.Serial_ID is null) then
        Begin
          Select mac_address
            Into v_Temp_Serial_Id
            From Bsm_Client_Mas
           Where Mac_Address = In_Client_Info.Mac_Address
             and rownum <= 1;
        Exception
          When No_Data_Found Then
            v_Temp_Serial_Id := Null;
        End;
      else
        Begin
          Select rowid, mac_address, upper(real_mac_address)
            Into rid, v_Temp_Serial_Id, v_real_mac_address
            From Bsm_Client_Mas
           Where Mac_Address = In_Client_Info.Serial_ID
             and rownum <= 1;
        
          if v_real_mac_address is null then
            update Bsm_Client_Mas
               set real_mac_address = In_Client_Info.Mac_Address
             Where rowid = rid;
          end if;
        
        Exception
          When No_Data_Found Then
            v_Temp_Serial_Id := Null;
          when others then
            v_Temp_Serial_Id := Null;
        End;
      end if;
    
    else
      --
      -- not LG base
      --
      if (In_Client_Info.Serial_ID is null) then
        Begin
          Select mac_address
            Into v_Temp_Serial_Id
            From Bsm_Client_Mas
           Where Mac_Address = In_Client_Info.Mac_Address
             and rownum <= 1;
        Exception
          When No_Data_Found Then
            v_Temp_Serial_Id := Null;
        End;
      else
        declare
          v_client_id varchar2(32);
          v_count     number(16);
        begin
          select nvl(count(*), 0)
            into v_count
            from bsm_client_mas
           where real_mac_address = upper(In_Client_Info.Mac_Address);
          if v_count > 1 then
            raise Dup_Mac_address;
          end if;
        
          select upper(mac_address)
            into v_client_id
            from bsm_client_mas
           where real_mac_address = upper(In_Client_Info.Mac_Address);
          if v_client_id <> In_Client_Info.Serial_ID then
            raise Different_client_id;
          end if;
        
        exception
          when no_data_found then
            v_Temp_Serial_Id := Null;
        end;
        Begin
          Select rowid, mac_address, upper(real_mac_address)
            Into rid, v_Temp_Serial_Id, v_real_mac_address
            From Bsm_Client_Mas
           Where Mac_Address = In_Client_Info.Serial_ID
             and rownum <= 1;
          --
          -- 新增重複 Mac_Address 處理
          --
        
          if upper(v_real_mac_address) <> upper(In_Client_Info.Mac_Address) then
            raise Different_MAC_ADDRESS;
          end if;
        
          if v_real_mac_address is null then
            update Bsm_Client_Mas
               set real_mac_address = In_Client_Info.Mac_Address
             Where rowid = rid;
          end if;
        
        Exception
          When No_Data_Found Then
            v_Temp_Serial_Id := Null;
        End;
      end if;
    end if;
  
    commit;
  
    --
    -- no Serial_ID
    --
    If v_Temp_Serial_Id Is Null Then
      --新機處理
    
      -- null MAC_Address
      If In_Client_Info.Mac_Address Is Null Then
        Raise Null_Mac_Address;
      End If;
    
      v_Client_Info := In_Client_Info;
    
      if v_Client_Info.Region is null then
        v_Client_Info.Region := 0;
      end if;
      --
      -- get New Serial_no
      --
      Select Seq_Bsm_Client_Mas.Nextval
        Into v_Client_Info.Serial_No
        From Dual;
    
      --
      -- Get New Serail_ID
      --
    
      if (In_Client_Info.Serial_Id is null) then
        -- tsm220 null serial_id
        In_Client_Info.Serial_Id := In_Client_Info.Mac_Address;
        v_Client_Info.Serial_Id  := In_Client_Info.Mac_Address;
        --pad(to_char(v_Client_Info.Serial_No),16,'0');
      else
        -- null client_id
        v_client_Info.Serial_id := In_Client_Info.Serial_Id;
      end if;
    
      --
      -- set iptv status
      --
    
      v_Client_Info.Status_Flg    := 'U';
      v_Client_Info.Default_Group := 'UNREGISTER';
    
      Insert Into Bsm_Client_Mas
        (Region,
         Serial_No,
         Serial_Id,
         Status_Flg,
         Mac_Address,
         Default_Group,
         Create_User,
         Create_Date,
         Owner_phone,
         real_mac_address)
      Values
        (v_Client_Info.Region,
         v_Client_Info.Serial_No,
         v_Client_Info.Serial_Id,
         v_Client_Info.Status_Flg,
         v_Client_Info.Serial_Id,
         v_Client_Info.Default_Group,
         0,
         Sysdate,
         In_Client_Info.Owner_Phone,
         In_Client_Info.MAC_Address);
    
      --
      -- LG base
      --
      -- Check mac_address if not in list ,add it
      declare
        v_char           varchar2(1);
        v_ver            varchar2(32);
        v_software_group varchar2(32);
      begin
        select a.software_group
          into v_software_group
          from bsm_client_device_list a
         where a.client_id = v_Client_Info.Serial_Id
           and device_id = In_Client_Info.MAC_Address;
        --   if v_software_group is null then 
        v_ver := bsm_cdi_service.get_device_current_swver(v_Client_Info.Serial_Id,
                                                          In_Client_Info.MAC_Address);
        if v_ver is not null then
          v_software_group := substr(v_ver, 1, 7);
        end if;
        update bsm_client_device_list a
           set a.software_group = v_software_group
         where a.client_id = v_Client_Info.Serial_Id
           and device_id = In_Client_Info.MAC_Address;
        --    end if;
      exception
        when no_data_found then
          v_ver := bsm_cdi_service.get_device_current_swver(v_Client_Info.Serial_Id,
                                                            In_Client_Info.MAC_Address);
          if v_ver is not null then
            v_software_group := substr(v_ver, 1, 7);
          end if;
          insert into bsm_client_device_list
            (client_id,
             device_id,
             owner_phone_no,
             status_flg,
             software_group)
          values
            (v_Client_Info.Serial_Id,
             In_Client_Info.MAC_Address,
             In_Client_Info.Owner_Phone,
             'P',
             v_software_group);
      end;
    
      commit;
      v_msg := BSm_CDI_SERVICE.Set_Client_Status(v_Client_Info.Serial_Id,
                                                 v_Client_Info.Status_Flg);
    
    Elsif v_Temp_Serial_Id Is Not Null Then
      -- 重新開通
    
      Begin
        -- 取狀態
        v_Client_Info := Get_Client_Info(v_Temp_Serial_Id);
      
        -- LG base don't check status
        if activation_code is not null then
          null;
        else
          if v_client_info.status_flg = 'A' then
            -- 取生效時間
            if (In_Client_Info.Serial_ID is null) then
              Select register_date
                into v_register_date
                from Bsm_Client_Mas a
               where a.mac_address = In_Client_Info.MAC_Address;
            else
              Select register_date
                into v_register_date
                from Bsm_Client_Mas a
               where a.mac_address = In_Client_Info.Serial_ID;
            end if;
          
            -- 超過1小時者即不能修改
            if ((v_register_date + (1 / 24)) < sysdate) then
              raise Status_Exception;
            end if;
          end if;
        
          if v_Client_info.status_flg not in ('A', 'U', 'R') then
            raise Status_Exception;
          end if;
        end if;
      
      Exception
        When Failure_Get_Client_Info Then
          If In_Client_Info.Mac_Address Is Null Then
            Raise Null_Mac_Address;
          End If;
        
          v_Client_Info := In_Client_Info;
        
          if In_Client_Info.Serial_Id is null then
            In_Client_Info.Serial_Id := In_Client_Info.Mac_Address;
            v_Client_Info.Serial_Id  := In_Client_Info.Serial_Id;
          else
            v_Client_Info.Serial_Id := In_Client_Info.Serial_Id;
          end if;
        
          Select Seq_Bsm_Client_Mas.Nextval
            Into v_Client_Info.Serial_No
            From Dual;
          If v_Client_Info.Region Is Null Then
            v_Client_Info.Region := 0;
          End If;
        
          --
          -- set iptv status
          --
        
          v_Client_Info.Status_Flg    := 'UNREGISTER';
          v_Client_Info.Default_Group := 'UNREGISTER';
        
          Insert Into Bsm_Client_Mas
            (Region,
             Serial_No,
             Serial_Id,
             Status_Flg,
             Mac_Address,
             Default_Group,
             Create_User,
             Create_Date,
             Owner_phone,
             register_date,
             posted_cdi,
             real_mac_address)
          Values
            (v_Client_Info.Region,
             v_Client_Info.Serial_No,
             v_Client_Info.Serial_Id,
             v_Client_Info.Status_Flg,
             v_Client_Info.Serial_Id,
             v_Client_Info.Default_Group,
             0,
             Sysdate,
             In_Client_Info.Owner_Phone,
             sysdate,
             'N',
             In_Client_Info.MAC_Address);
        
          v_msg := BSm_CDI_SERVICE.Set_Client_Status(v_Client_Info.Mac_Address,
                                                     v_Client_Info.Status_Flg);
      End;
    
      --
      -- LG base
      --
      -- Check mac_address if not in list ,add it
    
      declare
        v_char           varchar2(1);
        v_ver            varchar2(32);
        v_software_group varchar2(32);
      begin
        select a.software_group
          into v_software_group
          from bsm_client_device_list a
         where a.client_id = v_Client_Info.Serial_Id
           and device_id = In_Client_Info.MAC_Address
           and rownum <= 1;
        --  if v_software_group is null then
        begin
          v_ver := bsm_cdi_service.get_device_current_swver(v_Client_Info.Serial_Id,
                                                            In_Client_Info.MAC_Address);
        
          v_software_group := substr(v_ver, 1, 7);
          update bsm_client_device_list a
             set a.software_group = v_software_group
           where a.client_id = v_Client_Info.Serial_Id
             and device_id = In_Client_Info.MAC_Address;
          commit;
        exception
          when others then
            null;
        end;
        --   end if;
      exception
        when no_data_found then
          v_ver := bsm_cdi_service.get_device_current_swver(v_Client_Info.Serial_Id,
                                                            In_Client_Info.MAC_Address);
          if v_ver is not null then
            v_software_group := substr(v_ver, 1, 7);
          end if;
          insert into bsm_client_device_list
            (client_id,
             device_id,
             owner_phone_no,
             status_flg,
             software_group)
          values
            (v_Client_Info.Serial_Id,
             In_Client_Info.MAC_Address,
             In_Client_Info.Owner_Phone,
             'P',
             v_software_group);
          commit;
      end;
    
    End If;
  
    --
    -- 測試帳號處理
    --
    --
  
    --
    -- for lg don't do it
    --
  
    if activation_code is null then
    
      declare
      
        v_client_limit number(16);
        v_client_count number(16);
      
      begin
        select a.owner_activation_code, a.client_limit
          into v_test_activation_no, v_client_limit
          from mfg_dev_account_mas a
         where owner_phone_no = In_Client_Info.Owner_phone
           and status_flg in ('Z')
           and nvl(start_date, sysdate - 1) <= sysdate
           and nvl(end_date, sysdate + 1) >= sysdate
           and rownum <= 1;
      
        select count(*)
          into v_client_count
          from bsm_client_mas a
         where a.owner_phone = In_Client_Info.Owner_Phone;
      
        if (v_client_limit is not null) and
           (v_client_count > v_client_limit) then
          v_test_activation_no := null;
        end if;
      exception
        when no_data_found then
          v_test_activation_no := null;
      end;
    else
      v_test_activation_no := null;
    end if;
  
    -- get Activation Code
    --
    if v_test_activation_no is null then
      Declare
      
        v_msg varchar2(2560);
      
      Begin
        if activation_code is not null then
          v_Activation_No := activation_code;
        else
          v_Activation_No := Get_Activation_No;
        end if;
      
        Update Bsm_Client_Mas a
           Set a.Status_Flg      = DECODE(STATUS_FLG,
                                          'A',
                                          'A',
                                          'W',
                                          'W',
                                          'R'),
               a.Owner_Phone     = In_Client_Info.Owner_Phone,
               a.Activation_Code = v_Activation_No,
               a.register_date   = sysdate,
               a.posted_cdi      = 'N'
         Where Serial_Id = v_Client_Info.Serial_Id;
        /*
          -- Send SMS
          --         declare
          declare
            v_sg varchar2(32);
          begin
            if send_passcode then
              begin
                select software_group
                  into v_sg
                  from bsm_client_device_list
                 where client_id = In_Client_Info.Serial_Id
                   and device_id = In_Client_Info.mac_address;
              exception
                when no_data_found then
                  v_sg := null;
              end;
              declare
                v_tstar varchar2(32);
              begin
                begin
                  select 'y'
                    into v_tstar
                    from tstar_order a
                   where a.msisdn = In_Client_Info.Owner_Phone
                     and a.status_flg = 'A'
                     and rownum <= 1;
                exception
                  when no_data_found then
                    v_tstar := null;
                end;
                if v_tstar = 'y' and
                   substr(In_Client_Info.Serial_Id, 1, 2) = '2A' then
                  v_msg := BSM_SMS_SERVICE.Send_Sms_Messeage(In_Client_Info.Owner_Phone,
                                                             '您的LiTV通行碼為' ||
                                                             v_Activation_No ||
                                                             '請在畫面輸入通行碼，註冊成功即成為LiTV會員並可享用服務',
                                                             v_Client_Info.Serial_Id);
                elsif v_sg in ('LTSMS00', 'LTSMS02', 'LTSMS01') then
                  v_msg := BSM_SMS_SERVICE.Send_Sms_Messeage(In_Client_Info.Owner_Phone,
                                                             '您的通行碼為' ||
                                                             v_Activation_No ||
                                                             '請在畫面輸入通行碼進行開通。',
                                                             v_Client_Info.Serial_Id);
                elsif v_sg in ('LTWEB00') then
                  v_msg := BSM_SMS_SERVICE.Send_Sms_Messeage(In_Client_Info.Owner_Phone,
                                                             '您的LiTV通行碼為' ||
                                                             v_Activation_No ||
                                                             '請在畫面輸入通行碼，註冊成功即成為LiTV會員並可免費體驗，免費內容請詳見網站說明。',
                                                             v_Client_Info.Serial_Id);
                elsif substr(In_Client_Info.Serial_Id, 1, 2) = 'F6' then
                  v_msg := BSM_SMS_SERVICE.Send_Sms_Message_4g(In_Client_Info.Owner_Phone,
                                                               '您的4gTV會員通行碼為' ||
                                                               v_Activation_No ||
                                                               '請在畫面輸入通行碼，註冊成功即成為4gTV會員並可免費體驗，免費內容請詳見網站說明。',
                                                               v_Client_Info.Serial_Id);
                
                  -- '您的LiTV通行碼為'||v_Activation_No ||'請在畫面輸入通行碼，註冊成功即成為LiTV會員並可享七天免費體驗，免費內容請詳見網站說明。'
                
                else
                
                  v_msg := BSM_SMS_SERVICE.Send_Sms_Messeage(In_Client_Info.Owner_Phone,
                                                             '您的LiTV通行碼為' ||
                                                             v_Activation_No ||
                                                             '請輸入通行碼進行開通。提醒您若持有免費兌換券，請於開通後至兌換區，兌換LiTV服務!',
                                                             v_Client_Info.Serial_Id);
                end if;
                Commit;
              end;
            end if;
          end;
        */
      End;
    else
      v_Activation_No := v_test_activation_no;
      Update Bsm_Client_Mas a
         Set a.Status_Flg      = DECODE(STATUS_FLG, 'A', 'A', 'W', 'W', 'R'),
             a.Owner_Phone     = In_Client_Info.Owner_Phone,
             a.Activation_Code = v_Activation_No,
             a.register_date   = sysdate,
             a.posted_cdi      = 'N'
       Where Serial_Id = v_Client_Info.Serial_Id;
    
    end if;
  
    if substr(In_Client_Info.Owner_Phone, 1, 2) = '01' then
      In_Client_Info.Activation_Code := activation_code;
      v_Result                       := Activate_Client(In_Client_Info);
    end if;
  
    If v_Result.Result_Code Is Null Then
      v_Result.Result_Code := 'BSM-00000';
    End If;
    --
    -- generate_mfg_iptv_mas
    --
    if nvl(activation_code, 'x') <> 'x' then
      --  generate_mfg_iptv_id(v_Client_Info.Serial_Id);
      if In_client_info.serial_id is not null then
        v_Client_Info := Get_Client_Info(In_client_info.serial_id);
      else
        v_Client_Info := Get_Client_Info(In_client_info.mac_address);
      end if;
    
      In_Client_Info := v_Client_Info;
    
      Set_Client_Connect_Event(In_Client_Info.Serial_No);
    end if;
    Commit;
  
    Return v_Result;
  
  Exception
    When Null_Mac_Address Then
      Rollback;
      v_Result.Result_Code    := 'BSM-01001';
      v_Result.Result_Message := 'null mac address';
      Return v_Result;
    
    When Serial_Id_Exception Then
      Rollback;
      v_Result.Result_Code    := 'BSM-01002';
      v_Result.Result_Message := 'client ID Error';
      Return v_Result;
    
    When Different_MAC_ADDRESS Then
      Rollback;
      v_Result.Result_Code    := 'BSM-01002';
      v_Result.Result_Message := 'client ID Error (Different_MAC_ADDRESS)';
      Return v_Result;
    
    When Dup_MAC_Address Then
      Rollback;
      v_Result.Result_Code    := 'BSM-01002';
      v_Result.Result_Message := 'client ID Error';
      Return v_Result;
    
    When Different_Client_id Then
      Rollback;
      v_Result.Result_Code    := 'BSM-01002';
      v_Result.Result_Message := 'client ID Error (Different_Client_id)';
      Return v_Result;
    
    When Status_Exception Then
      v_Result.Result_Code := 'BSM-01003';
      Return v_Result;
  End Check_And_Register_Client;

  Function Get_Activation_Code(In_Client_Info In Out Tbsm_Client_Info)
    Return Tbsm_Result Is
    v_Result        Tbsm_Result;
    v_Activation_No Varchar2(32);
  Begin
  
    v_Activation_No := Get_Activation_No;
    Update Bsm_Client_Mas a
       Set a.Status_Flg      = 'R',
           a.Owner_Phone     = In_Client_Info.Owner_Phone,
           a.Activation_Code = v_Activation_No
     Where Serial_Id = In_Client_Info.Serial_Id;
  
    v_Result             := New Tbsm_Result;
    v_Result.Result_Code := 'BSM-00000';
    Commit;
    Return v_Result;
  End;
  
  Function Activate_Client(In_Client_Info    In Out Tbsm_Client_Info,
                           parameter_options varchar2 default null)
    Return Tbsm_Result Is
    v_Client_Info    Tbsm_Client_Info;
    v_Result         Tbsm_Result;
    v_Activation_No  Varchar2(32);
    v_msg            varchar2(2000);
    v_trc_src_no     number(16);
    v_model_info     varchar2(64);
    v_software_group varchar2(64);
    v_activate_date  date;
  Begin
    declare
      jsonobj json;
    begin
      jsonobj := json(parameter_options);
    
      begin
        v_model_info := json_ext.get_string(jsonobj, 'model_info');
      exception
        when others then
          v_model_info := null;
      end;
    exception
      when others then
        v_model_info := null;
    end;
  
    v_Result      := New Tbsm_Result;
    v_Client_Info := new Tbsm_Client_Info;
  
    if (In_CLient_Info.Serial_ID is not null) then
      declare
        v_char varchar2(32);
        v_msg  Tbsm_Result;
      begin
        select 'x'
          into v_char
          from bsm_client_mas a
         where a.serial_id = In_CLient_Info.Serial_ID
           and rownum <= 1;
      exception
        when no_data_found then
          v_msg := Check_And_register_client(In_Client_Info);
      end;
      v_Client_Info := Get_Client_Info(In_Client_Info.Serial_id);
    else
      v_Client_Info := Get_Client_Info(In_Client_Info.Mac_address);
    end if;
  
    --
    v_client_Info.MAC_Address := In_Client_info.MAC_Address;
  
    if v_Client_Info.Status_Flg not in ('R', 'A', 'U') Then
      Raise Status_Exception;
    End If;
    if v_Client_Info.Serial_ID = 'F6AEF1815EC63D2E' then
      Raise Status_Registed;
    end if;
    
  
    /*   if v_Client_Info.Status_Flg not in ('R', 'A', 'U') Then
        Raise Status_Registed;
      End If;
    */
    /*    declare
      e_busy exception;
      pragma exception_init(e_busy, -54);
    begin
    
      if (In_CLient_Info.Serial_ID is not null) then
        Select Activation_Code, a.activation_date
          Into v_Activation_No, v_activate_date
          From Bsm_Client_Mas a
         Where Mac_address = In_CLient_Info.Serial_ID
           and rownum <= 1;
      else
        Select Activation_Code, a.activation_date
          Into v_Activation_No, v_activate_date
          From Bsm_Client_Mas a
         Where Mac_address = In_Client_Info.Mac_Address
           and rownum <= 1;
      end if;
    exception
      when e_busy then
        raise LOCK_CLIENT;
    end; */
    /*
    if v_activate_date >= sysdate - (1 / 48) and
       v_Client_Info.Status_Flg = 'A' then
      Raise Status_Registed;
    end if;
    */
  
    /*  If In_Client_Info.Activation_Code <> v_Activation_No Then
      Raise Error_Activation_Code;
    End If; */
  
    if (In_Client_Info.Mac_address <> '123456789' or
       In_Client_Info.Mac_address is null) then
    
      --
      -- Demo to Sell process
      --
    
      Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_trc_src_no From Dual;
    
      declare
        p_device_id varchar2(32);
        p_client_id varchar2(32);
        cursor c1 is
          select rowid rid, b.*
            from mfg_iptv_service_dtls b
           where mac_address = p_device_id
             and status_flg = 'P';
      
        cursor c2(p_serial_id varchar2) is
          select b.*
            from bsm_package_mas b
           where ((b.system_type = 'CLIENT_ACTIVED' and
                 b.package_id != 'FREE96') or (substr(p_serial_id, 1, 2) = 'F6' and
                 b.package_id = 'FREE96'))
             and b.status_flg = 'P'
             and b.package_id not in
                 (select c.package_id
                    from bsm_client_details c
                   where c.mac_address = p_serial_id
                     and c.device_id = p_device_id
                     and c.status_flg = 'P');
      
        cursor c3(p_software_group varchar2,
                  p_model_no       varchar2,
                  p_serial_id      varchar2,
                  p_device_id      varchar2) is
          select a.package_id, a.item_id
            from mfg_softwaregroup_service a
           where a.software_group = p_software_group
             and a.status_flg = 'P'
             and (not exists
                  (select 'x'
                     from mfg_model_services b
                    where b.package_id = a.package_id) or exists
                  (select 'x'
                     from mfg_model_services b
                    where b.package_id = a.package_id
                      and p_model_no like '%' || b.model_no || '%'))
                
             and (a.package_id not in
                 (select e.package_id
                     from bsm_purchase_mas d, bsm_purchase_item e
                    where e.mas_pk_no = d.pk_no
                      and d.pay_type = '贈送'
                      and d.serial_id = p_serial_id
                      and e.device_id = p_device_id
                      and d.status_flg in ('A', 'P', 'Z')
                      and d.src_no = 'CLIENT_ACTIVATED'))
          
          union all
          select package_id, null item_id
            from mfg_model_services b
           where p_model_no like '%' || b.model_no || '%'
             and status_flg = 'P'
             and (b.package_id not in
                 (select e.package_id
                     from bsm_purchase_mas d, bsm_purchase_item e
                    where e.mas_pk_no = d.pk_no
                      and d.pay_type = '贈送'
                      and e.device_id = p_device_id
                      and d.status_flg in ('A', 'P', 'Z')
                      and d.src_no = 'CLIENT_ACTIVATED'));
      
        v_tr_id     number(16);
        v_serial_no number(16);
        v_serial_id varchar2(32);
        v_client_id varchar2(32);
      
        v_owner_phone varchar2(64);
        v_device_id   varchar2(32);
        v_coupon_cnt  number(16);
        v_model_no    varchar2(1024);
        v_char        varchar2(1024);
        v_gift        varchar2(2);
      
      begin
      
        if In_Client_Info.Serial_ID is not null then
          p_client_id := In_Client_Info.Serial_ID;
        else
          p_client_id := In_Client_Info.mac_address;
        end if;
      
        p_device_id := In_Client_Info.MAC_Address;
      
        select serial_no, serial_id, mac_address
          into v_serial_no, v_serial_id, v_client_id
          from bsm_client_mas
         where mac_address = p_client_id
         and rownum<=1;
      
        select 'x'
          into v_char
          from bsm_client_mas a
         where a.serial_id = p_client_id;
      
        --
        -- 系統開通方案
        --
        -- New Account
        if v_Client_Info.Status_Flg <> 'A' then
        
          --
          begin
            select software_group
              into v_software_group
              from bsm_client_device_list
             where client_id = p_client_id
               and device_id = p_device_id and rownum<=1;
          
            if v_software_group = 'None' then
              v_software_group := substr(bsm_cdi_service.get_device_current_swver(p_client_id,
                                                                                  p_device_id),
                                         1,
                                         7);
              update bsm_client_device_list
                 set software_group = v_software_group
               where client_id = p_client_id
                 and device_id = p_device_id;
              commit;
            end if;
          
            if v_software_group is null or v_software_group = 'LTLGE00-DEV' then
              select software_group
                into v_software_group
                from mfg_iptv_mas
               where mac_address = p_client_id;
            end if;
          exception
            when no_data_found then
              begin
                select software_group
                  into v_software_group
                  from mfg_iptv_mas
                 where mac_address = p_client_id;
              exception
                when no_data_found then
                  null;
              end;
          end;
        
          for c2rec in c2(v_Client_Info.Serial_Id) loop
            declare
              v_device_id varchar2(32);
              v_src_no    varchar2(32);
              v_char      varchar2(32);
            begin
              if c2rec.amt_of_devices > 1 then
                v_device_id := null;
              else
                v_device_id := p_device_id;
              end if;
              begin
                select 'x'
                  into v_char
                  from bsm_client_details a
                 where a.mac_address = v_client_id
                   and a.package_id = c2rec.package_id
                   and status_flg = 'P'
                   and (device_id is null and v_device_id is null or
                       device_id = v_device_id)
                   and rownum <= 1;
              exception
                when no_data_found then
                
                  Select Seq_Bsm_Purchase_Pk_No.Nextval
                    Into v_tr_id
                    From Dual;
                
                  insert into bsm_client_details
                    (src_pk_no,
                     pk_no,
                     serial_no,
                     serial_id,
                     mac_address,
                     device_id,
                     package_cat1,
                     package_id,
                     package_name,
                     start_date,
                     end_date,
                     acl_duration,
                     acl_quota,
                     status_flg,
                     acl_id)
                  values
                    (v_trc_src_no,
                     v_tr_id,
                     v_serial_no,
                     v_serial_id,
                     v_client_id,
                     v_device_id,
                     c2rec.package_cat1,
                     c2rec.package_id,
                     null,
                     null,
                     null,
                     0,
                     0,
                     'P',
                     c2rec.acl_id);
              end;
            end;
          
          end loop;
          v_owner_phone := v_Client_Info.Owner_Phone;
        
        END IF;
      
        v_device_id := In_Client_Info.MAC_Address;
      
        declare
          v_demo_flg varchar2(32);
        begin
          v_demo_flg   := 'Y';
          v_coupon_cnt := 0;
          begin
            select 'Y', nvl(a.gift, 'Y')
              into v_demo_flg, v_gift
              from mfg_dev_account_mas a
             where owner_phone_no = v_owner_phone
               and status_flg in ('Z')
               and nvl(start_date, sysdate - 1) <= sysdate
               and nvl(end_date, sysdate + 1) >= sysdate
               and rownum <= 1;
          exception
            when no_data_found then
              v_demo_flg := 'N';
              v_gift     := 'Y';
          end;
        
          begin
            select count(*)
              into v_coupon_cnt
              from bsm_coupon_mas a
             where a.ref_device_id = v_device_id
               and status_flg = 'P'
               and a.expire_date >= sysdate;
          exception
            when no_data_found then
              v_coupon_cnt := 0;
          end;
        
          -- 非Demo 手機,與沒有自動開通者,起動隨機贈送方案
          begin
            if v_model_info is null then
              v_model_no := bsm_cdi_service.get_device_model(p_client_id,
                                                             p_device_id);
            else
              v_model_no := v_model_info;
            end if;
          
            update bsm_client_device_list a
               set ref1 = v_model_no
             where client_id = p_client_id
               and device_id = p_device_id;
          exception
            when no_data_found then
              v_model_no := null;
          end;
        
          if (v_demo_flg = 'N' or v_gift = 'Y') and v_coupon_cnt = 0 then
          
            -- lock mas table
          
            select 'x'
              into v_char
              from bsm_client_mas a
             where a.mac_address = p_client_id;
          
            for c3rec in c3(v_software_group,
                            v_model_no,
                            p_client_id,
                            p_device_id) loop
              declare
                v_dup varchar(32);
              begin
                select 'x'
                  into v_char
                  from bsm_client_mas a
                 where a.mac_address = p_client_id;
                v_dup := 'N';
              
                begin
                  select 'Y'
                    into v_dup
                    from bsm_purchase_mas d, bsm_purchase_item e
                   where e.mas_pk_no = d.pk_no
                     and d.pay_type = '贈送'
                        --      and d.serial_id = p_client_id
                     and e.device_id = p_device_id
                     and d.status_flg in ('A', 'P', 'Z')
                     and d.src_no = 'CLIENT_ACTIVATED'
                     and e.package_id = c3rec.package_id
                     and rownum <= 1;
                exception
                  when no_data_found then
                    null;
                end;
              
                -- 4gTV過濾
                if substr(p_client_id, 1, 2) = 'F6' then
                  v_dup := 'Y';
                end if;
              
                if v_dup = 'N' then
                
                  declare
                    v_Purchase_Pk_No      number(16);
                    v_purchase_no         varchar2(32);
                    v_acc_invo_no         varchar2(32);
                    v_pay_type            varchar2(32) := '贈送';
                    v_Client_Info         Tbsm_Client_Info;
                    v_acc_name            varchar2(32);
                    v_tax_code            varchar2(32);
                    v_Purchase_Mas_Code   varchar(32) := 'BSMPUR';
                    v_Serial_No           number(16);
                    v_id                  varchar2(32) := c3rec.package_id; -- package_id;
                    v_Price               number(16);
                    v_Duration            number(16);
                    v_Quota               number(16);
                    v_charge_type         varchar2(32);
                    v_charge_code         varchar2(32);
                    v_client_id           varchar(32) := p_client_id;
                    v_device_id           varchar2(32) := p_device_id;
                    v_mas_no              varchar2(32) := 'CLIENT_ACTIVATED';
                    p_user_no             number(16) := 0;
                    v_Purchase_Item_Pk_No number(16);
                    v_charge_name         varchar2(64);
                  
                  begin
                    v_Client_Info := bsm_client_service.Get_Client_Info(v_client_id);
                    dbms_output.put_line(v_client_info.mac_address);
                    v_Serial_No := v_client_info.serial_no;
                    Select Seq_Bsm_Purchase_Pk_No.Nextval
                      Into v_Purchase_Pk_No
                      From Dual;
                  
                    v_Purchase_Mas_Code := 'BSMPUR';
                  
                    v_Purchase_No := Sysapp_Util.Get_Mas_No(1,
                                                            2,
                                                            Sysdate,
                                                            v_Purchase_Mas_Code,
                                                            v_Purchase_Pk_No);
                    v_acc_invo_no := sysapp_util.get_mas_no(1,
                                                            2,
                                                            sysdate,
                                                            'BSMPUR_INV',
                                                            v_Purchase_Pk_No);
                  
                    if v_Client_Info.Owner_ID is not null then
                      begin
                        select cust_name, tax_code
                          into v_acc_name, v_tax_code
                          from tgc_customer
                         where cust_id = v_Client_Info.Owner_ID;
                      exception
                        when no_data_found then
                          null;
                      end;
                    end if;
                    Insert Into Bsm_Purchase_Mas
                      (Src_No,
                       Pk_No,
                       Mas_No,
                       Mas_Date,
                       Mas_Code,
                       Src_Code,
                       Src_Date,
                       Serial_No,
                       acc_code,
                       Serial_Id,
                       Status_Flg,
                       Purchase_Date,
                       Pay_Type,
                       Card_type,
                       Card_no,
                       Card_Expiry,
                       Cvc2,
                       inv_no,
                       f_year,
                       f_period,
                       due_date,
                       acc_name,
                       tax_code,
                       show_flg,
                       start_type)
                    Values
                      (v_mas_no,
                       v_Purchase_Pk_No,
                       v_Purchase_No,
                       Sysdate,
                       v_Purchase_Mas_Code,
                       Null,
                       Null,
                       v_Serial_No,
                       v_Client_Info.Owner_ID,
                       v_client_Id,
                       'A',
                       Sysdate,
                       v_Pay_Type,
                       null,
                       null,
                       null,
                       null,
                       v_acc_invo_no,
                       to_number(to_char(sysdate, 'YYYY')),
                       to_number(to_char(sysdate, 'MM')),
                       sysdate + 7,
                       v_acc_name,
                       null,
                       'N',
                       'E');
                  
                    --
                    --  計算價格
                    --
                    Begin
                      Select a.Charge_Amount,
                             a.Acl_Duration,
                             a.Acl_Quota,
                             a.charge_type,
                             a.charge_code
                        Into v_Price,
                             v_Duration,
                             v_Quota,
                             v_charge_type,
                             v_charge_code
                        From Bsm_Package_Mas a
                       Where a.Package_id = v_id;
                    
                    End;
                  
                    Select Seq_Bsm_Purchase_Pk_No.Nextval
                      Into v_Purchase_Item_Pk_No
                      From Dual;
                  
                    if v_charge_code is null then
                      v_charge_code := sysapp_util.get_sys_value('BSMPUR',
                                                                 'Default charge code',
                                                                 'PMONTHFEE');
                    end if;
                  
                    v_charge_code := 'PMONTHFEE';
                    v_charge_name := '預付月租費';
                    --  end;
                  
                    Insert Into Bsm_Purchase_Item
                      (Pk_No,
                       Mas_Pk_No,
                       Package_ID,
                       ITEM_ID,
                       Price,
                       Amount,
                       Duration,
                       CHG_TYPE,
                       CHG_CODE,
                       CHG_NAME,
                       TAX_AMT,
                       CHG_AMT,
                       TOTAL_AMT,
                       device_id)
                    Values
                      (v_Purchase_Item_Pk_No,
                       v_Purchase_Pk_No,
                       v_id,
                       null,
                       0,
                       0,
                       v_Duration,
                       v_charge_type,
                       v_charge_code,
                       v_charge_name,
                       0,
                       0,
                       0,
                       v_device_id);
                  
                    declare
                      v_msg number(16);
                    begin
                    
                      v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                               v_purchase_pk_no);
                    
                      v_msg := bsm_purchase_post.purchase_complete(p_user_no,
                                                                   v_purchase_pk_no);
                    
                      commit;
                    end;
                  
                  end;
                
                end if;
              end;
            end loop;
            bsm_client_service.Set_subscription(null, p_client_id);
          end if;
        
        end;
      
      end;
    
      --
      --  check Demo or Test Phone don't set status
      --
    
      declare
        v_reset    varchar2(1);
        v_phone_no varchar2(32);
      begin
        v_reset := 'N';
        select a.owner_phone
          into v_phone_no
          from bsm_client_mas a
         where a.serial_id = v_Client_Info.Serial_Id;
      
        begin
          select nvl(reset_flg, 'N')
            into v_reset
            from mfg_dev_account_mas a
           where owner_phone_no = v_phone_no
             and status_flg in ('Z')
             and nvl(start_date, sysdate - 1) <= sysdate
             and nvl(end_date, sysdate + 1) >= sysdate
             and rownum <= 1;
        exception
          when no_data_found then
            v_reset := 'N';
        end;
      
        if v_reset != 'Y' then
        
          --
          -- check web account 
          --
          declare
            v_owner_id varchar2(64);
            v_owner_no number(16);
          begin
            begin
              select a.cust_id, a.user_no
                into v_owner_id, v_owner_no
                from tgc_customer a
               where a.web_account = v_Client_Info.Owner_Phone
                 and rownum <= 1;
            exception
              when no_data_found then
                v_owner_id := null;
            end;
          
            Update Bsm_Client_Mas a
               Set a.Status_Flg          = 'A',
                   a.Activation_date     = sysdate,
                   a.first_activate_date = nvl(a.first_activate_date,
                                               sysdate),
                   a.posted_cdi          = 'N',
                   a.owner_id            = v_owner_id,
                   a.owner_no            = v_owner_no
             Where Serial_Id = v_Client_Info.Serial_Id;
          end;
        
          update bsm_client_device_list a
             set a.status_flg = 'P', a.activate_date = sysdate
           where client_id = v_Client_Info.Serial_Id
             and a.device_id = v_client_info.MAC_Address;
        
          declare
            v_enqueue_options    dbms_aq.enqueue_options_t;
            v_message_properties dbms_aq.message_properties_t;
            v_message_handle     raw(16);
            v_payload            purchase_msg_type;
          begin
            v_payload := purchase_msg_type(v_Client_Info.Serial_Id,
                                           0,
                                           '',
                                           'refresh_cdi_status');
            dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                            enqueue_options    => v_enqueue_options,
                            message_properties => v_message_properties,
                            payload            => v_payload,
                            msgid              => v_message_handle);
            commit;
          end;
        
         /* v_msg := BSm_CDI_SERVICE.Set_Client_Status(v_Client_Info.Serial_Id,
                                                     'A'); */
        
          v_Client_Info.Status_Flg := 'A';
        end if;
      
      end;
    
    end if;
  
    In_Client_info := v_Client_Info;
    Commit;
  
    declare
      v_dup varchar2(32);
    begin
      select 'x'
        into v_dup
        from Bsm_Client_Device_List a
       where a.client_id = In_client_Info.Serial_ID
         and a.device_id = In_Client_Info.Mac_Address
         and rownum <= 1;
    exception
      when no_data_found then
        insert into bsm_client_device_list
          (client_id, device_id, status_flg)
        values
          (In_client_Info.Serial_ID, In_Client_Info.Mac_Address, 'P');
        commit;
    end;
  
    v_Result.Result_Message := 'message:{"subject":"","body":""}';
  
    declare
      cursor c1(p_client_id varchar2, p_device_id varchar2) is
        select coupon_id, ref_device_id
          from bsm_coupon_mas a, bsm_coupon_prog_mas b
         where a.ref_device_id = p_device_id
           and a.status_flg = 'P'
           and b.cup_program_id = a.program_id
           and (not exists
                (select 'x'
                   from bsm_coupon_prog_sg c
                  where c.mas_pk_no = b.pk_no) or exists
                (select 'x'
                   from bsm_coupon_prog_sg d
                  where d.software_group =
                        get_software_group(p_client_id, p_device_id)))
           and a.expire_date >= trunc(sysdate);
    
      v_client_id   varchar2(32);
      v_device_id   varchar2(32);
      v_owner_phone varchar(32);
      v_msg         varchar2(1024);
      v_demo_flg    varchar2(1);
    
    begin
      v_device_id := In_Client_Info.Mac_address;
      select mac_address, a.owner_phone
        into v_client_id, v_owner_phone
        from bsm_client_mas a
       where Serial_id = v_Client_Info.Serial_Id;
      begin
        select 'Y'
          into v_demo_flg
          from mfg_dev_account_mas a
         where owner_phone_no = v_owner_phone
           and status_flg in ('Z')
           and nvl(start_date, sysdate - 1) <= sysdate
           and nvl(end_date, sysdate + 1) >= sysdate
           and rownum <= 1;
      exception
        when no_data_found then
          v_demo_flg := 'N';
      end;
      --     v_Result.Result_Message := 'message:{"subject":"'||v_software_group||'親愛的客戶您好,恭喜您獲得已下服務(TEST)","body":"電頻頻到套餐\n隨選電影兩個月"}';
      if v_demo_flg = 'N' then
        for i in c1(v_client_id, v_device_id) loop
          v_msg := bsm_purchase_post.CLIENT_REGIETER_COUPON(v_client_id,
                                                            i.coupon_id,
                                                            i.ref_device_id);
        
          v_Result.Result_Message := v_msg;
        
        end loop;
      end if;
    
      declare
        cursor c1 is
          select order_data
            from tstar_order a
           where status_flg = 'A'
             and a.msisdn = v_owner_phone;
        v_msg varchar2(1024);
      begin
        for i in c1 loop
          v_msg := tstar_order_service.tstar_order(i.order_data, 'activate');
        end loop;
      end;
    
      declare
        cursor c1 is
          select order_data
            from parent_order a
           where status_flg = 'A'
             and a.msisdn = v_owner_phone;
        v_msg varchar2(1024);
      begin
        for i in c1 loop
          v_msg := partner_service.PARTNER_ORDER_SERVICE(i.order_data,
                                                         'activate');
        end loop;
      end;
    
    exception
      when others then
        null;
      
    end;
  
    v_Result.Result_Code := 'BSM-00000';
  
    Return v_Result;
  
  Exception
    when Status_Registed then
      v_Result.Result_Code := 'BSM-00000';
      Return v_Result;
    When Status_Exception Then
      v_Result.Result_Code := 'BSM-00100';
      Return v_Result;
    
    When Error_Activation_Code Then
      v_Result.Result_Code := 'BSM-00101';
      Return v_Result;
    when lock_client then
      v_Result.Result_Code    := 'BSM-00104';
      v_Result.Result_Message := '系統忙碌中,請稍候重試';
      Return v_Result;
  End;

  Function Crt_Purchase(In_Bsm_Purchase   In Out Tbsm_Purchase,
                        p_recurrent       varchar2 default 'O',
                        p_device_id       varchar2 default null,
                        parameter_options varchar2 default null,
                        p_sw_version      varchar2 default null)
    Return Tbsm_Result Is
    v_Char                Varchar2(1);
    v_Client_Info         Tbsm_Client_Info;
    v_Result              Tbsm_Result;
    v_Payment_Result      Varchar2(2000);
    v_Purchase_Pk_No      Number(16);
    v_Purchase_No         Varchar2(64);
    v_Purchase_Mas_Code   Varchar2(32);
    v_Purchase_Item_Pk_No Number(16);
    i_Items               Number(16);
    v_Price               Number(16);
    v_org_price           Number(16);
    v_Duration            Number(16);
    v_Quota               Number(16);
    v_Purchase_Amount     Number(16);
    v_Sms_Str             Varchar2(1024);
    v_Sms_Str_4g          Varchar2(1024);
    v_Sms_Result          Varchar2(256);
    v_id                  varchar2(256);
    v_charge_code         varchar2(256);
    v_charge_type         varchar2(256);
    v_charge_name         varchar2(256);
    v_acc_invo_no         varchar2(256);
    v_vis_acc             varchar2(256);
    v_software_group      varchar2(256);
    v_bar_due_date        varchar2(32);
    v_due_date            date;
    v_bar_no              varchar2(32);
    v_bar_code            varchar2(32);
    v_f_year              number(4);
    v_f_period            number(2);
    v_acc_name            varchar2(256);
    v_tax_code            varchar2(256);
    v_tax_flg             varchar2(256);
    v_test_client         varchar2(256);
    v_credits_amount      number(16);
    v_tax_amt             number(16, 4);
    v_chg_amt             number(16, 4);
    v_total_amt           number(16, 4);
    v_item_tax_flg        varchar2(256);
    v_item_tax_amt        number(16, 4);
    v_item_chg_amt        number(16, 4);
    v_item_total_amt      number(16, 4);
    v_tax_rate            number(9, 6);
    v_recurrent           varchar2(32);
    v_org_no              number(32);
    v_platformid          varchar2(10);
    v_apt_productcode     varchar2(32);
    v_apt_min             varchar2(32);
    v_otpw                varchar2(64);
    v_authority           varchar2(64);
    v_aa_uid              varchar2(64);
    v_cht_credit_no       varchar2(64);
    v_cht_auth            varchar2(64);
    v_actiondate          varchar2(64);
    v_vendor_id           varchar2(64);
  
    v_ordernumber      varchar2(64);
    v_regular          number(16);
    v_action           varchar2(64);
    v_ios_product_code varchar2(128);
    v_ios_token        clob;
    v_package_cat_id   varchar2(32);
    v_start_type       varchar2(32);
    v_promo_code       varchar2(32);
    v_promo_prog_id    varchar2(32);
    v_promo_title      varchar2(256);
    v_promo_rowid      rowid;
    v_item_type        varchar2(32);
    v_package_recurrent varchar2(32);
    v_recurrent_amt number(16);
  
  Begin
  
    v_org_no      := 1;
    v_test_client := 'N';
    if upper(In_Bsm_Purchase.Pay_Type) = 'CREDITS' then
      In_Bsm_Purchase.Pay_Type := '儲值卡';
    elsif upper(In_Bsm_Purchase.PAY_TYPE) = 'CREDIT' then
      In_Bsm_Purchase.Pay_Type := '信用卡';
    end if;
  
    declare
      jsonobj json;
    begin
      jsonobj := json(parameter_options);
    
      begin
        v_apt_min := json_ext.get_string(jsonobj, 'min');
      exception
        when others then
          v_apt_min := '';
      end;
    
      begin
        v_otpw := json_ext.get_string(jsonobj, 'otpw');
      exception
        when others then
          v_otpw := '';
      end;
    
      begin
        v_authority := json_ext.get_string(jsonobj, 'authority');
      exception
        when others then
          v_authority := '';
      end;
    
      begin
        v_aa_uid := json_ext.get_string(jsonobj, 'uid');
      exception
        when others then
          v_aa_uid := '';
      end;
    
      begin
        v_cht_credit_no := json_ext.get_string(jsonobj, 'PAN');
      exception
        when others then
          v_cht_credit_no := '';
      end;
      begin
        v_cht_auth := json_ext.get_string(jsonobj, 'ApproveCode');
      exception
        when others then
          v_cht_auth := '';
      end;
    
      begin
        v_ios_token := json_ext.get_string(jsonobj, 'ios_receipt_info');
      exception
        when others then
          v_ios_token := '';
      end;
    
      begin
        v_vendor_id := json_ext.get_string(jsonobj, 'vendor_id');
      exception
        when others then
          v_vendor_id := null;
      end;
    
      begin
        v_promo_code := json_ext.get_string(jsonobj, 'promo_code');
      exception
        when others then
          v_promo_code := null;
      end;
    
    exception
      when others then
        null;
    end;
    Select 'x'
      into v_char
      from bsm_client_mas a
     where a.serial_id = In_BSM_Purchase.SERIAL_ID;
  
    if p_recurrent = 'Y' then
      v_recurrent := 'R';
    elsif p_recurrent = 'N' then
      v_recurrent := 'O';
    else
      v_recurrent := p_recurrent;
    end if;
  
    v_Result      := New Tbsm_Result;
    v_Client_Info := New Tbsm_Client_Info;
    v_SMS_str     := Sms_Purchase;
    v_sms_str_4g  := Sms_Purchase_4g;
  
    In_BSM_Purchase.SERIAL_ID := upper(In_BSM_Purchase.SERIAL_ID);
  
    if upper(In_Bsm_Purchase.Pay_Type) = 'CREDITS' then
      In_Bsm_Purchase.Pay_Type := '儲值卡';
    elsif upper(In_Bsm_Purchase.PAY_TYPE) = 'CREDIT' then
      In_Bsm_Purchase.Pay_Type := '信用卡';
    end if;
    declare
      v_serial_id varchar2(128);
    Begin
      Select mas_no, pk_no, serial_id
        Into In_Bsm_Purchase.MAS_NO, v_Purchase_Pk_No, v_serial_id
        From Bsm_Purchase_Mas a
       Where a.Src_No = In_BSM_Purchase.Src_No
         And a.Serial_Id = In_BSM_Purchase.SERIAL_ID
         And a.status_flg In ('A', 'P', 'Z', 'PA')
         And Rownum <= 1
         for update;
      if v_serial_id <> In_BSM_Purchase.SERIAL_ID then
        raise Error_Demo_account;
      else
        Raise Dup_Transfer;
      end if;
    Exception
      When No_Data_Found Then
        Null;
    End;
  
    -- 取的單據主鍵及編號
  
    v_Purchase_Mas_Code := 'BSMPUR';
    v_test_client       := 'N';
  
    -- v_client_info 可取消,只留˙client id
    v_Client_Info := Get_Client_Info(In_Bsm_Purchase.Serial_Id);
  
    -- 強迫要給版號
    if p_sw_version is null then
      v_software_group := get_software_group(In_Bsm_Purchase.Serial_Id,
                                             p_device_id);
              declare
          v_char varchar2(32);
        begin
          select 'x'
            into v_char
            from bsm_client_device_list b
           where b.client_id = In_Bsm_Purchase.serial_id
             and device_id = p_device_id
             and rownum <= 1;
        exception
          when no_data_found then
            insert into bsm_client_device_list
              (client_id, device_id, software_group, status_flg)
            values
              (In_Bsm_Purchase.serial_id,
               p_device_id,
               substr(p_sw_version, 1, 7),
               'P');
            commit;
        end;                                            
    else
      if p_sw_version != 'RECURRENT_AUTO' then
        v_software_group := upper(substr(p_sw_version, 1, 7));
      end if;
    end if;
  
    Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_Purchase_Pk_No From Dual;
  
    v_Purchase_No := Sysapp_Util.Get_Mas_No(v_org_no,
                                            2,
                                            Sysdate,
                                            v_Purchase_Mas_Code,
                                            v_Purchase_Pk_No);
    -- 贈送沒有帳單編號  
    if In_Bsm_Purchase.Pay_Type not in ('贈送') then
      v_acc_invo_no := sysapp_util.get_mas_no(v_org_no,
                                              2,
                                              sysdate,
                                              'BSMPUR_INV',
                                              v_Purchase_Pk_No);
    end if;
  
    In_Bsm_Purchase.MAS_NO   := v_Purchase_No;
    In_Bsm_Purchase.Pay_Type := nvl(In_Bsm_Purchase.Pay_Type, '信用卡');
  
    v_tax_code := 'OUTTAX1';
  
    --
    -- tax code process
    --
  
    if In_Bsm_Purchase.Pay_Type in ('儲值卡', 'APT') then
      v_tax_flg  := 'N';
      v_tax_rate := 0;
    else
      v_tax_flg  := 'Y';
      v_tax_rate := 0.05;
    end if;
  
    --
    -- 中華電信帳單
    --
    if In_Bsm_Purchase.PAY_TYPE = '中華電信帳單' then
      if v_otpw is null or v_otpw = '' then
        raise Error_null_otpw;
      end if;
    
      if v_authority is null or v_authority = '' then
        raise Error_null_authority;
      end if;
    end if;
  
    if In_Bsm_Purchase.PAY_TYPE = '中華電信信用卡' then
      if v_otpw is null or v_otpw = '' then
        raise Error_null_otpw;
      end if;
    
      if v_authority is null or v_authority = '' then
        raise Error_null_authority;
      end if;
    
      In_Bsm_Purchase.CARD_NO := v_cht_credit_no;
    
    end if;
  
    if In_Bsm_Purchase.PAY_TYPE = '中華電信ATM' then
      if v_otpw is null or v_otpw = '' then
        raise Error_null_otpw;
      end if;
    
      if v_authority is null or v_authority = '' then
        raise Error_null_authority;
      end if;
    end if;
  
    --
    -- IOS
    --
  
    if In_Bsm_Purchase.PAY_TYPE = 'IOS' then
      v_recurrent := 'R';
    end if;
  
    if p_sw_version = 'RECURRENT_AUTO' then
      v_recurrent := 'O';
    end if;
  
    if In_Bsm_Purchase.PAY_TYPE in ('IOS', '中華電信帳單', 'TSTART') then
      v_recurrent  := 'R';
      v_start_type := 'S';
    else
      v_start_type := 'E';
    end if;
    
      
    Begin
      Select mas_no, pk_no
        Into In_Bsm_Purchase.MAS_NO, v_Purchase_Pk_No
        From Bsm_Purchase_Mas a
       Where a.Src_No = In_BSM_Purchase.Src_No
         And a.Serial_Id = In_BSM_Purchase.SERIAL_ID
         And a.status_flg In ('A', 'P', 'Z', 'PA')
         And Rownum <= 1
         for update;
      Raise Dup_Transfer;
    Exception
      When No_Data_Found Then
        Null;
    End;
      
    Insert Into Bsm_Purchase_Mas
      (Src_No,
       Pk_No,
       Mas_No,
       Mas_Date,
       Mas_Code,
       Src_Code,
       Src_Date,
       Serial_No,
       acc_code,
       Serial_Id,
       Status_Flg,
       Purchase_Date,
       Pay_Type,
       Card_type,
       Card_no,
       Card_Expiry,
       Cvc2,
       inv_no,
       f_year,
       f_period,
       due_date,
       acc_name,
       tax_code,
       tax_flg,
       recurrent,
       org_no,
       software_group,
       cht_aauid,
       cht_otpw,
       cht_auth,
       vendor_id,
       start_type,
       OPTIONS)
    Values
      (In_Bsm_Purchase.Src_No,
       v_Purchase_Pk_No,
       v_Purchase_No,
       Sysdate,
       v_Purchase_Mas_Code,
       Null,
       Null,
       In_Bsm_Purchase.Serial_No,
       v_Client_Info.Owner_ID,
       In_Bsm_Purchase.Serial_Id,
       'A',
       Sysdate,
       In_Bsm_Purchase.Pay_Type,
       In_Bsm_Purchase.CARD_TYPE,
       '************' || substr(In_Bsm_Purchase.CARD_NO, 13, 4),
       In_Bsm_Purchase.CARD_EXPIRY,
       In_Bsm_Purchase.CVC2,
       v_acc_invo_no,
       to_number(to_char(sysdate, 'YYYY')),
       to_number(to_char(sysdate, 'MM')),
       sysdate + 3,
       v_acc_name,
       v_tax_code,
       v_tax_flg,
       v_recurrent,
       v_org_no,
       v_software_group,
       v_aa_uid,
       v_otpw,
       v_authority,
       v_vendor_id,
       v_start_type,
       parameter_options);
    commit;
    
    v_recurrent := 'O';
    For i_Items In 1 .. In_Bsm_Purchase.Details.Count Loop
      --
      --  計算價格
      --
      v_id := In_Bsm_Purchase.Details(i_Items).Offer_Id;
      Begin
        begin
          Select a.Charge_Amount,
                 a.Charge_Amount,
                 a.Acl_Duration,
                 a.Acl_Quota,
                 a.charge_type,
                 a.charge_code,
                 nvl(a.credits, a.Charge_Amount),
                 apt_productcode,
                 a.ios_product_code,
                 a.package_cat_id1,
                 'P',
                 a.recurrent
            Into v_Price,
                 v_org_Price,
                 v_Duration,
                 v_Quota,
                 v_charge_type,
                 v_charge_code,
                 v_credits_amount,
                 v_apt_productcode,
                 v_ios_product_code,
                 v_package_cat_id,
                 v_item_type,
                 v_package_recurrent
            From Bsm_Package_Mas a
           Where a.Package_id = In_Bsm_Purchase.Details(i_Items).Offer_Id;
        exception
          when no_data_found then
            Select a.amount, 0, 0, null, null, 0, null, null, null, 'S'
              Into v_Price,
                   v_Duration,
                   v_Quota,
                   v_charge_type,
                   v_charge_code,
                   v_credits_amount,
                   v_apt_productcode,
                   v_ios_product_code,
                   v_package_cat_id,
                   v_item_type
              From stk_package_mas a
             Where a.package_id = In_Bsm_Purchase.Details(i_Items).Offer_Id;
        end;
      
        --
        -- 折扣處理
        --
        begin
          Select b.amt, a.rowid rid, a.promo_prog_id, b.promo_title,recurrent_amt
            into v_price, v_promo_rowid, v_promo_prog_id, v_promo_title,v_recurrent_amt
            from promotion_mas a, promotion_prog_item b
           where b.promo_prog_type = 'DISCOUNT'
             and b.promo_prog_id = a.promo_prog_id
             and b.discount_package_id = In_Bsm_Purchase.Details(i_Items)
                .Offer_Id
             and a.promo_code = v_promo_code
             and a.status_flg = 'P';
             if v_recurrent_amt is not null then
               v_org_price := v_recurrent_amt;
             end if;
        exception
          when no_data_found then
            null;
        end;
      
        if p_sw_version = 'RECURRENT_AUTO' then
          update bsm_purchase_mas
             set recurrent = 'O'
           where pk_no = v_purchase_pk_no;
        
          v_recurrent := 'O';
          -- recurrent 檢查處理 ,贈送可以不要
        elsif (v_package_recurrent = 'R' and In_Bsm_Purchase.Pay_Type not in ('贈送')) then
          update bsm_purchase_mas
             set recurrent = 'R'
           where pk_no = v_purchase_pk_no;
        
          v_recurrent := 'R';
          declare
            v_char varchar2(32);
          begin
            Select 'x'
              into v_char
              from bsm_client_details a, bsm_package_mas b
             where a.serial_id = In_Bsm_Purchase.Serial_Id
               and a.package_id = b.package_id
               and b.package_cat_id1 = v_package_cat_id
               and a.status_flg = 'P'
               and (a.report_type = 'R')
                  
               and a.end_date >= sysdate
               and rownum <= 1;
          
            Update Bsm_Purchase_Mas b
               Set b.status_flg = 'F'
             Where b.pk_no = v_Purchase_Pk_No;
            commit;
          
            raise Error_Recurrent_Dup;
          exception
            when no_data_found then
              null;
          end;
        end if;
      
      Exception
        When No_Data_Found Then
          update bsm_purchase_mas
             set status_flg = 'F'
           where pk_no = v_purchase_pk_no;
          Raise Error_Package_Mas;
      End;
    
      if p_sw_version = 'RECURRENT_AUTO' and In_Bsm_Purchase.Details(i_Items)
        .Amount is not null then
        v_Price := In_Bsm_Purchase.Details(i_Items).Amount;
      end if;
    
      Select Seq_Bsm_Purchase_Pk_No.Nextval
        Into v_Purchase_Item_Pk_No
        From Dual;
    
      v_charge_code := 'PMONTHFEE';
      v_charge_name := '預付月租費';
    
      Insert Into Bsm_Purchase_Item
        (Pk_No,
         Mas_Pk_No,
         Package_ID,
         ITEM_ID,
         Price,
         Amount,
         Duration,
         CHG_TYPE,
         CHG_CODE,
         CHG_NAME,
         CREDITS,
         tax_flg,
         tax_code,
         device_id,
         apt_productcode,
         apt_min,
         type)
      Values
        (v_Purchase_Item_Pk_No,
         v_Purchase_Pk_No,
         In_Bsm_Purchase.Details(i_Items).Offer_Id,
         In_Bsm_Purchase.Details(i_Items).Asset_Id,
         v_Price,
         v_Price * 1,
         v_Duration,
         v_charge_type,
         v_charge_code,
         v_charge_name,
         v_credits_amount,
         v_tax_flg,
         v_tax_code,
         p_device_id,
         v_apt_productcode,
         v_apt_min,
         v_item_type);
    
    End Loop;
  
    Select Sum(Amount), SUM(credits)
      Into v_Purchase_Amount, v_credits_amount
      From Bsm_Purchase_Item
     Where Mas_Pk_No = v_Purchase_Pk_No;
  
    -- tax process
    v_total_amt := v_Purchase_Amount;
    if v_tax_flg = 'Y' then
      v_chg_amt := round(v_total_amt / (1 + v_tax_rate));
      v_tax_amt := v_total_amt - v_chg_amt;
    else
      v_chg_amt := round(v_total_amt / (1 + v_tax_rate));
      v_tax_amt := v_total_amt - v_chg_amt;
    end if;
  
    declare
      cursor c_tax_item is
        select rowid rid, amount, tax_flg
          From Bsm_Purchase_Item
         Where Mas_Pk_No = v_Purchase_Pk_No;
      v_tax_amt2     number(16, 4) := v_tax_amt;
      v_chg_amt2     number(16, 4) := v_chg_amt;
      v_total_amt2   number(16, 4) := v_total_amt;
      v_item_chg_amt number(16, 4);
    
    begin
      for rec_tax in c_tax_item loop
        if v_total_amt2 = rec_tax.amount then
          v_item_chg_amt   := v_chg_amt2;
          v_item_tax_amt   := v_tax_amt2;
          v_item_total_amt := v_total_amt2;
        else
          v_item_total_amt := rec_tax.amount;
          v_item_tax_amt   := round(rec_tax.amount / (1 + v_tax_rate));
          v_item_chg_amt   := v_item_total_amt - v_item_tax_amt;
        end if;
      
        v_total_amt2 := v_total_amt2 - v_item_total_amt;
        v_tax_amt2   := v_tax_amt2 - v_item_tax_amt;
        v_chg_amt2   := v_chg_amt2 - v_item_chg_amt;
      
        update Bsm_Purchase_Item
           set tax_amt   = v_item_tax_amt,
               chg_amt   = v_item_chg_amt,
               total_amt = v_item_total_amt,
               tax_rate  = v_tax_rate
         where rowid = rec_tax.rid;
      
      end loop;
    
    end;
  
    v_due_date := sysdate + 3;
  
    v_vis_acc := bsm_purchase_post.get_vis_acc(v_acc_invo_no,
                                               v_due_date,
                                               v_Purchase_Amount);
  
    v_f_year       := to_number(to_char(sysdate, 'YYYY'));
    v_f_period     := to_number(to_char(sysdate, 'MM'));
    v_bar_due_date := '*' ||
                      substr(to_char(to_number(to_char(v_due_date, 'YYYY')) - 1911),
                             length(to_char(to_number(to_char(v_due_date,
                                                              'YYYY')) - 1911)) - 1,
                             2) || to_char(v_due_date, 'MMDD') || '627*';
  
    v_bar_no := '*' || v_acc_invo_no || '*';
  
    v_bar_code := '*' ||
                  barcode_4(substr(to_char(to_number(to_char(v_due_date,
                                                             'YYYY')) - 1911),
                                   length(to_char(to_number(to_char(v_due_date,
                                                                    'YYYY')) - 1911)) - 1,
                                   2) || to_char(v_due_date, 'MMDD') ||
                            '627',
                            v_acc_invo_no,
                            substr(to_char((v_f_year - 1911) * 100 +
                                           v_f_period),
                                   length(to_char((v_f_year - 1911) * 100 +
                                                  v_f_period)) - 3,
                                   4) || '**' ||
                            lpad(to_char(v_Purchase_Amount), 9, '0')) || '*';
  
    update bsm_purchase_mas a
       set a.amount        = v_Purchase_Amount,
           a.inv_acc       = v_vis_acc,
           a.bar_due_date  = v_bar_due_date,
           a.bar_no        = v_bar_no,
           a.bar_code      = v_bar_code,
           a.tax_amt       = v_tax_amt,
           a.chg_amt       = v_chg_amt,
           a.total_amt     = v_total_amt,
           a.promo_code    = v_promo_code,
           a.promo_prog_id = v_promo_prog_id,
           a.promo_title   = v_promo_title
     Where Pk_No = v_Purchase_Pk_No;
    -- Pay Credit
  
    declare
      v_char varchar2(32);
    begin
      select 'x'
        into v_char
        from bsm_purchase_mas a, bsm_purchase_item b
       where b.package_id = 'CD0011'
         and b.mas_pk_no = v_Purchase_Pk_No
         and a.pk_no = b.mas_pk_no
         and a.src_no not like 'RE%'
         and rownum <= 1;
      Select 'x'
        into v_char
        from bsm_recurrent_mas a, bsm_purchase_item b, bsm_package_mas c
       where a.src_pk_no = b.mas_pk_no
         and c.package_id = b.package_id
         and a.status_flg = 'P'
         and package_cat_id1 = 'CHANNEL_A'
         and a.client_id = In_Bsm_Purchase.Serial_Id
         and rownum <= 1;
      raise Error_Recurrent_Dup_c;
    exception
      when no_data_found then
        null;
    end;
  
    if substr(v_Client_info.Owner_Phone, 1, 7) = '0900001' then
      --
      -- Demo 機禁止購買
      --
      raise Error_Demo_account;
    end if;
    -- add test client check
    if v_test_client = 'N' then
      if In_Bsm_Purchase.Pay_Type = '儲值卡' then
        v_Payment_Result := Bsm_Purchase_Post.use_credits(In_BSM_Purchase.SERIAL_ID,
                                                          v_Purchase_Pk_No);
      elsif In_Bsm_Purchase.Pay_Type in ('匯款', 'ATM', '其他', 'REMIT') then
        v_Payment_result := '匯款';
      elsif In_Bsm_Purchase.Pay_Type in ('贈送', '信用卡二次扣款') then
        v_Payment_Result := 'PRC=0';
      elsif In_Bsm_Purchase.Pay_Type = 'APT' then
      
        v_Payment_Result := BSM_APT_SERVICE.apt_register_purchase(In_BSM_Purchase.SERIAL_ID,
                                                                  v_Purchase_Pk_No);
      elsif In_Bsm_Purchase.Pay_Type = 'IOS' then
        declare
          ios_result clob;
        begin
          ios_result := BSM_IOS_GATEWAY.Send_Receipt_Data(v_Purchase_Pk_No,
                                                          parameter_options,
                                                          'c7cdbd0220b54ab99af16548b0f27733',
                                                          v_ios_product_code);
          if instr(ios_result, '"status":0') > 0 then
            v_Payment_Result := 'PRC=0';
          else
            declare
              rjsonobj json;
            begin
              rjsonobj := json(ios_result);
            
              begin
                ios_result := json_ext.get_string(rjsonobj, 'result.status');
              exception
                when others then
                  ios_result := '';
              end;
            exception
              when others then
                ios_result := '';
            end;
            v_Payment_Result := 'PRC=1&' || ios_result;
          end if;
        end;
      elsif In_Bsm_Purchase.PAY_TYPE in
            ('中華電信帳單', '中華電信信用卡', '中華電信ATM') then
        if v_recurrent = 'R' then
          declare
            v_char varchar2(32);
          begin
            Select 'x'
              into v_char
              from bsm_purchase_mas   a,
                   bsm_purchase_item  b,
                   bsm_client_details c
             where a.serial_id = In_BSM_Purchase.SERIAL_ID
               and a.PAY_TYPE = '中華電信帳單'
               and a.status_flg = 'Z'
               and b.mas_pk_no = a.pk_no
               and b.package_id = In_Bsm_Purchase.details(1).offer_id
               and c.src_item_pk_no = b.pk_no
               and c.status_flg = 'P'
               and rownum <= 1;
            v_actiondate := to_char(sysdate, 'YYYYMMDDHH24MISS');
          exception
            when no_data_found then
              v_actiondate := to_char(add_months(sysdate, 0),
                                      'YYYYMMDDHH24MISS');
          end;
          v_Payment_Result := BSM_CHT_SERVICE.subscribe(v_Purchase_Pk_No,
                                                        v_otpw,
                                                        v_authority,
                                                        v_actiondate) ||
                              '&type=subscribe';
        else
          v_Payment_Result := BSM_CHT_SERVICE.authorization(v_Purchase_Pk_No,
                                                            v_otpw,
                                                            v_authority) ||
                              '&type=authorization';
          Update Bsm_Purchase_Mas b
             Set b.cht_auth      = v_authority,
                 b.approval_code = v_cht_auth,
                 b.cht_otpw      = v_otpw
           Where b.pk_no = v_Purchase_Pk_No;
          if In_Bsm_Purchase.PAY_TYPE in ('中華電信ATM') then
            if Instr(v_Payment_Result, 'PRC=0') > 0 then
              v_Payment_Result := '匯款';
              update bsm_purchase_mas a
                 set a.inv_acc = v_aa_uid, a.cht_otpw = v_otpw
               Where Pk_No = v_Purchase_Pk_No;
              commit;
            
            else
              Update Bsm_Purchase_Mas b
                 Set b.purchase_date = Sysdate, b.status_flg = 'F'
               Where b.pk_no = v_Purchase_Pk_No
                 and b.response_code = v_Payment_Result;
            
              Raise Error_Payment;
            end if;
          end if;
        end if;
      else
      
        Update Bsm_Purchase_Mas b
           Set b.status_flg = 'PA'
         Where b.pk_no = v_Purchase_Pk_No;
      
        Commit;
      
        if v_recurrent = 'R' then
          v_Payment_Result := BSM_LIPAY_GATEWAY.Accepayment(v_Purchase_Pk_No,
                                                            v_Purchase_Amount,
                                                            In_Bsm_Purchase.Card_Type,
                                                            In_Bsm_Purchase.Card_No,
                                                            In_Bsm_Purchase.Card_Expiry,
                                                            In_Bsm_Purchase.Cvc2,
                                                            parameter_options,
                                                            'recurrent');
        else
          v_Payment_Result := BSM_LIPAY_GATEWAY.Accepayment(v_Purchase_Pk_No,
                                                            v_Purchase_Amount,
                                                            In_Bsm_Purchase.Card_Type,
                                                            In_Bsm_Purchase.Card_No,
                                                            In_Bsm_Purchase.Card_Expiry,
                                                            In_Bsm_Purchase.Cvc2,
                                                            parameter_options,
                                                            'once');
        end if;
      end if;
    else
      v_Payment_Result := 'PRC=0';
    end if;
  
    -- keep log
    Update Bsm_Purchase_Mas b
       Set b.response_code = v_Payment_Result
     Where b.pk_no = v_Purchase_Pk_No;
  
    If Instr(v_Payment_Result, 'PRC=0') > 0 Then
    
      Declare
        v_ApprovalCode Varchar2(1024);
        v_Str          Varchar2(1024);
      Begin
        v_Str := substr(upper(v_Payment_Result),
                        instr(v_Payment_Result, 'APPROVALCODE=') +
                        length('APPROVALCODE='));
        If instr(v_Str, '&') > 0 Then
          v_Str := substr(v_Str, 1, instr(v_Str, '&'));
        End If;
      
        v_ApprovalCode := v_Str;
      
        Update Bsm_Purchase_Mas b
           Set b.Approval_Code = v_ApprovalCode,
               b.purchase_date = Sysdate,
               b.status_flg    = 'P'
         Where b.pk_no = v_Purchase_Pk_No;
      
        Commit;
      exception
        when others then
          null;
      End;
    
      if v_recurrent = 'R' then
        declare
          v_recurrent_pk_no number(16);
          v_recurrent_type  varchar2(64);
          v_cht_subno       varchar2(64);
          v_cht_auth        varchar2(64);
          v_credit_r        varchar2(32);
        
        begin
          Select Seq_Bsm_Purchase_Pk_No.Nextval,
                 x.cht_subscribeno,
                 x.cht_auth
            Into v_recurrent_pk_no, v_cht_subno, v_cht_auth
            From bsm_purchase_mas x
           where pk_no = v_Purchase_Pk_No;
          select pay_pk_no
            into v_ordernumber
            from bsm_purchase_mas b
           where b.pk_no = v_Purchase_Pk_No;
        
          if In_Bsm_Purchase.PAY_TYPE = '中華電信帳單' then
            v_recurrent_type := 'HINET';
          end if;
        
          if In_Bsm_Purchase.PAY_TYPE = 'IOS' then
            v_recurrent_type := 'IOS';
          end if;
        
      --    if v_promo_code is not null then
          
       --     v_recurrent_type := 'CREDIT';
     --     end if;
        
          insert into bsm_recurrent_mas
            (pk_no,
             recurrent_type,
             create_date,
             create_user,
             src_pk_no,
             src_no,
             card_no,
             card_type,
             card_expiry,
             cvc2,
             start_date,
             status_flg,
             client_id,
             cht_subno,
             cht_auth,
             cht_otpw,
             cht_action_date,
             ordernumber,
             amount,
             dump_status,
             last_modify_date)
          values
            (v_recurrent_pk_no,
             nvl(v_recurrent_type, 'LiPay'),
             sysdate,
             0,
             v_Purchase_Pk_No,
             v_Purchase_No,
             bsm_encrypt.Encrypt_Serial_ID(In_Bsm_Purchase.CARD_NO,
                                           In_Bsm_Purchase.SERIAL_ID ||
                                           'tgc27740083'),
             In_Bsm_Purchase.CARD_TYPE,
             In_Bsm_Purchase.CARD_EXPIRY,
             In_Bsm_Purchase.CVC2,
             sysdate,
             'P',
             In_Bsm_Purchase.SERIAL_ID,
             v_cht_subno,
             v_cht_auth,
             v_otpw,
             to_date(v_actiondate, 'YYYYMMDDHH24MISS'),
             v_ordernumber,
             nvl(v_org_price, v_total_amt),
             'A',
             sysdate);
        
        end;
      end if;
    
      -- 
      -- Call ACL
      --
      bsm_purchase_post.process_purchase_detail(In_BSM_Purchase.SERIAL_ID,
                                                v_Purchase_Pk_No);
    
      --
      -- Option Coupon 處理
      --
    
      declare
        v_end_date   date;
        v_start_date date;
      
        cursor c1 is
          Select nvl(d.coupon_batch_no, a.coupon_batch_no) coupon_batch_no,
                 nvl(a.coupon_cnt, 0) coupon_cnt,
                 c.package_id,
                 a.auto_register,
                 c.rowid item_rid,
                 c.pk_no item_pk_no
            from stk_package_mas a,
                 bsm_purchase_item c,
                 (select e.coupon_batch_no, e.package_id
                    from bsm_package_options e, bsm_purchase_item f
                   where f.mas_pk_no = v_Purchase_Pk_No
                     and f.package_id = e.stk_package_id
                     and e.package_type = 'EXTEND') d
           where a.package_type = 'COUPON'
             and d.package_id(+) = a.package_id
             and a.package_id = c.package_id
             and a.status_flg = 'P'
             and c.mas_pk_no = v_Purchase_Pk_No;
      
        v_package_dtls         varchar2(1024);
        v_cup_package_id       varchar2(32);
        v_cup_pk_no            number(16);
        v_cup_purchase_item_pk number(16);
        v_dtl_pk_no            number(16);
        v_main_dtl_pk_no       number(16);
      begin
      
        select max(end_date), min(start_date)
          into v_end_date, v_start_date
          from bsm_client_details d
         where d.src_pk_no = v_Purchase_Pk_No;
      
        for i in c1 loop
          v_package_dtls := '';
          for j in 1 .. i.coupon_cnt loop
            declare
              v_coupon_id varchar2(32);
              v_rid       rowid;
              v_coupon_no varchar2(32);
            begin
            
              select coupon_id, rowid, mas_no
                into v_coupon_id, v_rid, v_coupon_no
                from bsm_coupon_mas a
               where a.src_no = i.coupon_batch_no
                 and a.ref_purchase_no is null
                 and a.status_flg = 'P'
                 and a.serial_id is null
                 and rownum <= 1;
            
              if i.auto_register = 'Y' and j = 1 then
                declare
                  v_msg varchar2(1024);
                begin
                  v_msg := bsm_purchase_post.CLIENT_REGIETER_COUPOR(In_Bsm_Purchase.SERIAL_ID,
                                                                    v_coupon_id,
                                                                    'N');
                  select max(c.end_date),
                         min(c.start_date),
                         max(e.package_id),
                         min(c.pk_no),
                         min(d.pk_no),
                         min(e.pk_no)
                    into v_end_date,
                         v_start_date,
                         v_cup_package_id,
                         v_dtl_pk_no,
                         v_cup_pk_no,
                         v_cup_purchase_item_pk
                    from bsm_client_details c,
                         bsm_purchase_mas   d,
                         bsm_purchase_item  e
                   where c.src_pk_no = d.pk_no
                     and c.src_item_pk_no = e.pk_no
                     and d.src_no = v_coupon_no
                     and rownum <= 1;
                  v_package_dtls   := '{"desc":"主帳號 :已開通","client_id":"' ||
                                      In_Bsm_Purchase.SERIAL_ID || '",
                  "coupon_id":"' ||
                                      v_coupon_no || '",
                  "cup_dtl_pk_no":' ||
                                      to_char(v_dtl_pk_no) || ',
                  "cup_pk_no":' ||
                                      to_char(v_cup_pk_no) || ',
                  "cup_purchase_item":' ||
                                      to_char(v_cup_purchase_item_pk) || ',
                                      
                  "cup_package_id":[{"package_id":"' ||
                                      v_cup_package_id || '"}]}';
                  v_main_dtl_pk_no := v_dtl_pk_no;
                end;
              else
                if v_package_dtls is not null then
                  v_package_dtls := v_package_dtls || ',';
                end if;
              
                v_package_dtls := v_package_dtls || '{"desc":"副帳號 :兌換券 ' ||
                                  v_coupon_id || '",
                                  "client_id":"_CLIENT' ||
                                  v_coupon_no || '_","coupon_id":"' ||
                                  v_coupon_no || '",
                                   "cup_dtl_pk_no":0,
                                  "cup_package_id":[{"package_id":"' ||
                                  v_cup_package_id || '"}]}';
              
              end if;
            
              update bsm_coupon_mas a
                 set a.ref_purchase_no         = v_Purchase_No,
                     a.ref_client_id           = In_Bsm_Purchase.SERIAL_ID,
                     a.ref_purchase_pk_no      = v_Purchase_Pk_No,
                     a.ref_purchase_item_pk_no = i.item_pk_no,
                     a.stop_service_date       = v_end_date,
                     a.start_service_date      = v_start_date,
                     
                     a.REF_MAIN_DETAILS_PK_NO = v_main_dtl_pk_no
               where rowid = v_rid;
              commit;
            exception
              when no_data_found then
                null;
            end;
          end loop;
          update bsm_purchase_item
             set package_dtls       = '[' || v_package_dtls || ']',
                 service_start_date = v_start_date,
                 service_end_date   = v_end_date
           where rowid = i.item_rid;
          commit;
        end loop;
        commit;
      end;
    
      --
      --
      -- 延展處理
      --
      declare
        cursor c1 is
          Select b.extend_days,
                 a.rowid rid,
                 a.promo_prog_id,
                 c.pk_no,
                 case
                   when c.package_dtls is not null then
                    json_ext.get_number(json(json_list(c.package_dtls)
                                             .get_elem(1)),
                                        'cup_purchase_item')
                 
                   else
                    c.pk_no
                 end item_pk_no
            from promotion_mas       a,
                 promotion_prog_item b,
                 bsm_purchase_item   c
           where b.promo_prog_type = 'EXTEND'
             and ((b.discount_package_id = c.package_id) or
                 
                 (b.discount_package_id = case
                   when c.package_dtls is not null then
                    json_ext.get_string(json(json_ext.get_json_list(json(json_list(c.package_dtls).get_elem(1)), 'cup_package_id')
                                             .get_elem(1)),
                                        'package_id')
                   else
                    null
                 end))
             and b.promo_prog_id = a.promo_prog_id
             and c.mas_pk_no = v_Purchase_Pk_No
             and a.promo_code = v_promo_code
             and a.status_flg = 'P';
        v_end_date date;
      begin
        for i in c1 loop
          select end_date + i.extend_days
            into v_end_date
            from bsm_client_details
           where src_item_pk_no = i.item_pk_no
             and rownum <= 1;
          update bsm_client_details d
             set d.end_date = v_end_date
           where d.src_item_pk_no = i.item_pk_no;
          update bsm_purchase_item a
             set a.service_end_date = v_end_date
           where pk_no = i.pk_no;
        end loop;
        commit;
      end;
    
      --
      --
      -- 延展處理 Options
      --
      declare
        cursor c1 is
          Select nvl(a.extend_days, 0) extend_days,
                 nvl(a.extend_months, 0) extend_months,
                 case
                   when d.package_dtls is not null then
                    json_ext.get_string(json(json_ext.get_json_list(json(json_list(d.package_dtls).get_elem(1)), 'cup_package_id')
                                             .get_elem(1)),
                                        'package_id')
                   else
                    a.package_id
                 end package_id,
                 case
                   when d.package_dtls is not null then
                    json_ext.get_number(json(json_list(d.package_dtls)
                                             .get_elem(1)),
                                        'cup_purchase_item')
                 
                   else
                    d.pk_no
                 end item_pk_no,
                 d.pk_no main_pk_no
            from bsm_package_options a,
                 bsm_purchase_item   c,
                 bsm_purchase_item   d
           where a.package_type = 'EXTEND'
             and (a.stk_package_id = c.package_id)
             and c.mas_pk_no = v_Purchase_Pk_No
                
             and a.status_flg = 'P'
             and d.mas_pk_no = c.mas_pk_no
             and (d.pk_no <> c.pk_no)
             and (d.package_id = a.package_id);
      
        v_end_date date;
      begin
        for i in c1 loop
          select max(add_months(a.end_date, i.extend_months) +
                     i.extend_days)
            into v_end_date
            from bsm_client_details a
           where a.src_item_pk_no = i.item_pk_no
                -- and package_id = i.package_id
             and status_flg = 'P';
          update bsm_client_details d
             set d.end_date = v_end_date
           where d.src_item_pk_no = i.item_pk_no
             and package_id = i.package_id;
        
          update bsm_purchase_item c
             set c.service_end_date = v_end_date
           where c.pk_no = i.main_pk_no;
        
        end loop;
        commit;
      end;
    
      declare
        cursor c1 is
          Select 'x'
            from bsm_purchase_mas a, bsm_purchase_item c
           where a.pk_no = v_Purchase_Pk_No
             and c.mas_pk_no = a.pk_no
             and a.promo_code is null
             and not exists
           (select 'x'
                    from bsm_purchase_item d
                   where d.mas_pk_no = a.pk_no
                     and d.package_id not in ('XD0005'));
      begin
        for i in c1 loop
          update bsm_client_details d
             set d.end_date     = add_months(d.start_date, 18),
                 d.package_name = '預付一年加贈6個月'
           where d.src_pk_no = v_Purchase_Pk_No
             and package_id = 'XD0005';
        end loop;
      end;
    
      declare
        next_pay date;
      begin
        select max(a.service_end_date) - 3
          into next_pay
          from bsm_purchase_item a
         where a.mas_pk_no = v_Purchase_Pk_No
           and a.service_end_date is not null;
        update bsm_recurrent_mas a
           set a.next_bill_date = next_pay, a.last_modify_date = sysdate
         where a.src_pk_no = v_Purchase_Pk_No;
        update bsm_purchase_mas a
           set a.next_pay_date = next_pay
         where a.pk_no = v_Purchase_Pk_No;
      
        commit;
      
      end;
    
      declare
        cursor c1 is
          Select b.src_pk_no,
                 b.src_no,
                 b.serial_id,
                 trunc(bsm_recurrent_util.get_service_end_date(c.package_cat_id1,
                                                               b.serial_id)) - 3 next_pay
            from bsm_recurrent_mas  a,
                 bsm_client_details b,
                 bsm_package_mas    c
           where a.recurrent_type in ('LiPay', 'CREDIT')
             and a.status_flg = 'P'
             and b.src_no = a.src_no
             and c.package_id = b.package_id
             and b.serial_id = In_BSM_Purchase.SERIAL_ID;
        v_msg varchar2(2048);
      begin
        for i in c1 loop
          update bsm_recurrent_mas a
             set a.next_bill_date   = i.next_pay,
                 a.last_modify_date = sysdate
           where a.src_no = i.src_no;
        
          update bsm_purchase_mas a
             set a.next_pay_date = i.next_pay
           where mas_no = i.src_no;
          commit;
        end loop;
      end;
      --
      -- Option Coupon 處理
      --
      -- Update Purchase Order Status
      --
      Set_subscription(null, In_Bsm_Purchase.Serial_Id);
      declare
        v_enqueue_options    dbms_aq.enqueue_options_t;
        v_message_properties dbms_aq.message_properties_t;
        v_message_handle     raw(16);
        v_payload            purchase_msg_type;
      begin
        v_payload := purchase_msg_type(In_BSM_Purchase.SERIAL_ID,
                                       v_Purchase_Pk_No,
                                       v_Purchase_No,
                                       'refresh_cdi');
        dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                        enqueue_options    => v_enqueue_options,
                        message_properties => v_message_properties,
                        payload            => v_payload,
                        msgid              => v_message_handle);
        commit;
      end;
    
      begin
        If v_Client_Info.Owner_Phone Is Not Null and
           In_Bsm_Purchase.Pay_Type in
           ('信用卡',
            'CREDIT',
            '匯款',
            'ATM',
            'REMIT',
            '儲值卡',
            '中華電信帳單',
            '中華電信信用卡',
            '信用卡二次扣款') and
           substr(nvl(In_Bsm_Purchase.Src_No, '  '), 1, 2) != 'RE' Then
        
          if substr(v_Client_Info.Serial_Id, 1, 2) = 'F6' then
          
            v_Sms_Result := BSM_SMS_Service.Send_Sms_Messeage_litv(v_Client_Info.Owner_Phone,
                                                                   null,
                                                                   v_Client_Info.Serial_Id,
                                                                   'order',
                                                                   v_Purchase_No,
                                                                   v_Purchase_Amount);
          
          else
          
            v_Sms_Result := BSM_SMS_Service.Send_Sms_Messeage_litv(v_Client_Info.Owner_Phone,
                                                                   null,
                                                                   v_Client_Info.Serial_Id,
                                                                   'order',
                                                                   v_Purchase_No,
                                                                   v_Purchase_Amount);
          
          end if;
        End If;
      exception
        when others then
          null;
      end;
    
      declare
        v_test_card varchar2(32);
        v_char      varchar2(32);
      begin
      
        --
        -- 產生發票
        --
        -- 正式區要派段 測試卡
      
        if (In_Bsm_Purchase.PAY_TYPE <> '儲值卡' and
           In_Bsm_Purchase.PAY_TYPE <> 'APT' and
           In_Bsm_Purchase.PAY_TYPE <> '中華電信帳單' and
           In_Bsm_Purchase.PAY_TYPE <> '中華電信信用卡' and
           In_Bsm_Purchase.PAY_TYPE <> 'IOS' and
           In_Bsm_Purchase.PAY_TYPE <> '贈送' and
           In_Bsm_Purchase.PAY_TYPE <> '信用卡二次扣款') then
          begin
            select 'x'
              into v_char
              from mfg_dev_credit
             where card_no = In_Bsm_Purchase.Card_No
               and start_date <= sysdate
               and end_date + 1 > sysdate
               and rownum <= 1;
          
            v_test_card := 'Y';
          exception
            when no_data_found then
              v_test_card := 'N';
            
          end;
        
          if v_test_client = 'N' and v_test_card = 'N' then
          
            declare
              v_msg       varchar2(1024);
              v_inv_no    varchar2(32);
              v_inv_date  date;
              v_tax_bk_no varchar2(32);
              v_org_no    number(32);
            begin
              v_org_no := 1;
              select mas_no
                into v_tax_bk_no
                from tax_bk_mas a
               where a.start_date <= sysdate
                 and trunc(end_date) + 1 > sysdate
                 and no_end - nvl(a.curr_no, 0) > 0
                 and status_flg = 'P'
                 and a.org_no = v_org_no
                 and rownum <= 1
               order by mas_no;
            
              v_msg := tax_post.crt_inv_tax(0,
                                            0,
                                            v_tax_bk_no,
                                            null,
                                            null,
                                            'BSMPUR',
                                            v_Purchase_NO,
                                            v_Purchase_pk_no,
                                            v_org_no);
            
              commit;
            
              select b.f_invo_no, b.f_invo_date
                into v_inv_no, v_inv_date
                from tax_inv_mas b
               where b.src_pk_no = v_Purchase_pk_no
                 and b.status_flg = 'P';
            
              update bsm_purchase_mas a
                 set a.tax_inv_no   = v_inv_no,
                     a.tax_inv_date = v_inv_date,
                     a.tax_gift     = 'N'
               where a.pk_no = v_Purchase_pk_no;
            
              --dbms_lock.sleep( 120); 
              Insert /*+ append */
              Into Sysevent_Log
                (App_Code,
                 Pk_No,
                 Event_Date,
                 User_No,
                 Event_Type,
                 Seq_No,
                 Description)
              Values
                (v_Purchase_Mas_Code,
                 v_Purchase_Pk_No,
                 Sysdate,
                 0,
                 '發票',
                 Sys_Event_Seq.Nextval,
                 '發票');
              commit;
            exception
              when others then
                null; -- raise Failure_crt_tax_info;
            end;
          end if;
        end if;
      end;
    
      Update Bsm_Purchase_Mas b
         Set b.status_flg = 'Z'
       Where b.pk_no = v_Purchase_Pk_No;
       update promotion_mas a
         set a.current_used = nvl(a.current_used, 0) + 1,
             a.status_flg = case
                              when a.limit is null then
                               'P'
                              when nvl(a.current_used, 0) < a.limit then
                               'P'
                              else
                               'N'
                            end
       where a.rowid = v_promo_rowid;
      commit;
    
      declare
        v_enqueue_options    dbms_aq.enqueue_options_t;
        v_message_properties dbms_aq.message_properties_t;
        v_message_handle     raw(16);
        v_payload            purchase_msg_type;
      begin
        v_payload := purchase_msg_type(In_BSM_Purchase.SERIAL_ID,
                                       v_Purchase_Pk_No,
                                       v_Purchase_No,
                                       'promo');
        dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                        enqueue_options    => v_enqueue_options,
                        message_properties => v_message_properties,
                        payload            => v_payload,
                        msgid              => v_message_handle);
        commit;
      end;
    

    
      declare
        v_enqueue_options    dbms_aq.enqueue_options_t;
        v_message_properties dbms_aq.message_properties_t;
        v_message_handle     raw(16);
        v_payload            purchase_msg_type;
      begin
        v_payload := purchase_msg_type(In_BSM_Purchase.SERIAL_ID,
                                       v_Purchase_Pk_No,
                                       v_Purchase_No,
                                       'refresh_bsm');
        dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                        enqueue_options    => v_enqueue_options,
                        message_properties => v_message_properties,
                        payload            => v_payload,
                        msgid              => v_message_handle);
        commit;
      end;
    
  if v_promo_code is not null then
        declare
          v_enqueue_options    dbms_aq.enqueue_options_t;
          v_message_properties dbms_aq.message_properties_t;
          v_message_handle     raw(16);
          v_payload            purchase_msg_type;
        begin
          v_payload := purchase_msg_type(In_BSM_Purchase.SERIAL_ID,
                                         v_Purchase_Pk_No,
                                         v_Purchase_No,
                                         'refresh_acg');
          dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                          enqueue_options    => v_enqueue_options,
                          message_properties => v_message_properties,
                          payload            => v_payload,
                          msgid              => v_message_handle);
          commit;
        end;
      
      end if;   
    Elsif (In_Bsm_Purchase.Pay_Type in
          ('匯款', 'ATM', '其他', 'REMIT', '中華電信ATM') and
          v_Payment_Result = '匯款') then
      Update Bsm_Purchase_Mas b
         Set b.purchase_date = Sysdate, b.status_flg = 'P'
       Where b.pk_no = v_Purchase_Pk_No;
    Else
    
      Update Bsm_Purchase_Mas b
         Set b.purchase_date = Sysdate, b.status_flg = 'F'
       Where b.pk_no = v_Purchase_Pk_No;
    
      Raise Error_Payment;
    
    End If;
  
    Return v_Result;
  exception
    When Status_Exception Then
      v_Result.Result_Code    := 'BSM-00400';
      v_Result.Result_Message := '狀態錯誤';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    
    When Error_Activation_Code Then
      v_Result.Result_Code    := 'BSM-00401';
      v_Result.Result_Message := '啟用碼錯誤';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    
    When Error_Package_Mas Then
      v_Result.Result_Code    := 'BSM-00402';
      v_Result.Result_Message := 'Package 錯誤' || v_id;
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    When Error_Payment Then
      v_Result.Result_Code    := 'BSM-00403';
      v_Result.Result_Message := v_Payment_Result;
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    When Dup_Transfer Then
      v_Result.Result_Code    := 'BSM-00404';
      v_Result.Result_Message := '資料重複傳送';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    When Failure_Get_Client_Info Then
      v_Result.Result_Code    := 'BSM-00405';
      v_Result.Result_Message := '找不到Client 資料';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    When Failure_crt_tax_info Then
      v_Result.Result_Code    := 'BSM-00406';
      v_Result.Result_Message := '無法產生發票Client 資料';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    
    When Error_Card_no Then
      v_Result.Result_Code    := 'BSM-00408';
      v_Result.Result_Message := '錯誤的卡號或卡種';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    
    When Error_Demo_account Then
      v_Result.Result_Code    := 'BSM-00409';
      v_Result.Result_Message := 'Demo 機禁止購買';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    When Error_apt_min_null Then
      v_Result.Result_Code    := 'BSM-00410';
      v_Result.Result_Message := '亞太購買沒有MIN碼';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
    
      Return v_Result;
    
    When Error_apt_user Then
      v_Result.Result_Code    := 'BSM-00411';
      v_Result.Result_Message := '亞太購買非亞太用戶';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    When bsm_apt_service.register_error Then
      v_Result.Result_Code    := 'BSM-00412';
      v_Result.Result_Message := '亞太金流購買錯誤,無法購買';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    When bsm_apt_service.apt_min_error Then
      v_Result.Result_Code    := 'BSM-00413';
      v_Result.Result_Message := '亞太MIN錯誤';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    When bsm_apt_service.apt_product_code Then
      v_Result.Result_Code    := 'BSM-00414';
      v_Result.Result_Message := '亞太產品代號錯誤';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    When bsm_apt_service.apt_bought Then
      v_Result.Result_Code    := 'BSM-00415';
      v_Result.Result_Message := '亞太已購買此產品';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    
    When Error_null_otpw Then
      v_Result.Result_Code    := 'BSM-00416';
      v_Result.Result_Message := '中華支付OPTW null';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    
    When Error_null_authority Then
      v_Result.Result_Code    := 'BSM-00417';
      v_Result.Result_Message := '中華支付 authority null';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    
    When Error_Recurrent_Dup Then
      v_Result.Result_Code    := 'BSM-00419';
      v_Result.Result_Message := 'Recurrent 重複購買';
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    When Error_Recurrent_Dup_c Then
      v_Result.Result_Code    := 'BSM-00420';
      v_Result.Result_Message := 'Recurrent 重複購買';
            /* 狀態改為失敗 */
      update bsm_purchase_mas
         set status_flg = 'F'
       where pk_no = v_Purchase_Pk_No;
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
        When others Then
      v_Result.Result_Code    := 'BSM-00418';
      v_Result.Result_Message := SQLERRM;
    
      /* 狀態改為失敗 */
    /*  update bsm_purchase_mas
         set status_flg = 'F'
       where pk_no = v_Purchase_Pk_No; */
    
      insert into bsm_purchase_log
        (mas_pk_no, event_date, event_type, event_log)
      values
        (v_Purchase_Pk_No,
         sysdate,
         'BSMPUR',
         v_Result.Result_Code || ' ' || v_Result.Result_Message);
      commit;
      Return v_Result;
    
  End;

  Function Get_Content_List(p_Start Number, p_End Number)
    Return Tcms_Contentlist Is
    v_List    Tcms_Contentlist;
    v_Content Tcms_Content;
  
    Cursor C1 Is
      Select *
        From (Select rownum r_no, a.*
                From Mid_Cms_Content a, Mid_Content_List b
               Where a.Content_Id = b.Content_Id
               Order By b.NO)
       Where r_no >= p_start
         And r_no <= p_End;
    i_Content Number(16);
  
  Begin
    v_List    := new Tcms_Contentlist();
    i_Content := 1;
    For C1rec In C1 Loop
      v_List.Extend(1);
      v_List(i_Content) := New Tcms_Content();
      v_List(i_Content).Content_Id := C1rec.Content_Id;
      v_List(i_Content).Title := C1rec.Title;
      v_List(i_Content).Ref1 := C1rec.Ref1;
      v_List(i_Content).Ref2 := C1rec.Ref2;
      v_List(i_Content).Ref3 := C1rec.Ref3;
      v_List(i_Content).Ref4 := C1rec.Ref4;
      v_List(i_Content).Ref5 := C1rec.Ref5;
      v_List(i_Content).Ref6 := C1rec.Ref6;
      v_List(i_Content).Ref7 := C1rec.Ref7;
      v_List(i_Content).Ref8 := C1rec.Ref8;
      v_List(i_Content).Eng_Title := C1rec.Eng_Title;
      v_List(i_Content).Short_Title := C1rec.Short_Title;
      v_List(i_Content).Synopsis := C1rec.Synopsis;
      v_List(i_Content).Starring := C1rec.Starring;
      v_List(i_Content).Actors := C1rec.Actors;
      v_List(i_Content).Directed := C1rec.Directed;
      v_List(i_Content).Genre := C1rec.Genre;
      v_List(i_Content).Runtime := C1rec.Runtime;
      v_List(i_Content).Release_Year := C1rec.Release_Year;
      v_List(i_Content).Studio := C1rec.Studio;
      v_List(i_Content).Rating := C1rec.Rating;
      v_List(i_Content).Off_Shelf_Date := C1rec.Off_Shelf_Date;
      v_List(i_Content).Main_Picture := C1rec.Main_Picture;
      v_List(i_Content).Pictures := C1rec.Pictures;
      v_List(i_Content).Score := C1rec.Score;
      v_List(i_Content).Price := C1rec.Price;
      v_List(i_Content).Sdhd := C1rec.Sdhd;
      v_List(i_Content).Episode := C1rec.Episode;
      -- Item
      Declare
        Cursor C2 Is
          Select a.*, b.mas_pk_no, b.detail_pk_no, b.type
            From Mid_Cms_Item a, Mid_Cms_Item_Rel b
           Where a.Pk_No = b.Detail_Pk_No
             And b.Mas_Pk_No = C1rec.Pk_No
             And b.Type = 'P';
        i_Item Number(16);
      Begin
      
        i_Item := 1;
        v_List(i_Content).Items := new Tcms_Itemlist();
        For C2rec In C2 Loop
          v_List(i_Content).Items.Extend(1);
          v_List(i_Content).Items(i_Item) := New Tcms_Item();
          v_List(i_Content).Items(i_Item).Item_Type := C2rec.Item_Type;
          v_List(i_Content).Items(i_Item).Item_Id := C2rec.Item_Id;
          v_List(i_Content).Items(i_Item).Package_Id := C2rec.Package_Id;
          v_List(i_Content).Items(i_Item).Short_Name := C2rec.Short_Name;
          v_List(i_Content).Items(i_Item).Ref1 := C2rec.Ref1;
          v_List(i_Content).Items(i_Item).Ref2 := C2rec.Ref2;
          v_List(i_Content).Items(i_Item).Ref3 := C2rec.Ref3;
          v_List(i_Content).Items(i_Item).Ref4 := C2rec.Ref4;
          v_List(i_Content).Items(i_Item).Ref5 := C2rec.Ref5;
          v_List(i_Content).Items(i_Item).Ref6 := C2rec.Ref6;
          v_List(i_Content).Items(i_Item).Ref7 := C2rec.Ref7;
          v_List(i_Content).Items(i_Item).Ref8 := C2rec.Ref8;
          v_List(i_Content).Items(i_Item).Ref9 := C2rec.Ref9;
          v_List(i_Content).Items(i_Item).Ref10 := C2rec.Ref10;
          v_List(i_Content).Items(i_Item).Ref11 := C2rec.Ref11;
          v_List(i_Content).Items(i_Item).Ref12 := C2rec.Ref12;
          v_List(i_Content).Items(i_Item).Ref13 := C2rec.Ref13;
          v_List(i_Content).Items(i_Item).Ref14 := C2rec.Ref14;
          v_List(i_Content).Items(i_Item).Ref15 := C2rec.Ref15;
          v_List(i_Content).Items(i_Item).Ref16 := C2rec.Ref16;
          v_List(i_Content).Items(i_Item).Runtime := C2rec.Runtime;
          v_List(i_Content).Items(i_Item).Synopsys := C2rec.Synopsys;
          v_List(i_Content).Items(i_Item).Price := C2rec.Price;
          v_List(i_Content).Items(i_Item).Name := C2rec.Name;
          i_Item := i_Item + 1;
        End Loop;
      End;
    
      -- detail
      Declare
        Cursor C2 Is
          Select a.*, b.mas_pk_no, b.detail_pk_no, b.type
            From Mid_Cms_Item a, Mid_Cms_Item_Rel b
           Where a.Pk_No = b.Detail_Pk_No
             And b.Mas_Pk_No = C1rec.Pk_No
             And b.Type = 'G';
        i_Item Number(16);
      Begin
      
        i_Item := 1;
        v_List(i_Content).Disp_Items := new Tcms_Detaillist();
        For C2rec In C2 Loop
          v_List(i_Content).Disp_Items.Extend(1);
          v_List(i_Content).Disp_Items(i_Item) := New Tcms_Detail();
          v_List(i_Content).Disp_Items(i_Item).Item_Type := C2rec.Item_Type;
          v_List(i_Content).Disp_Items(i_Item).Item_Id := C2rec.Item_Id;
          v_List(i_Content).Disp_Items(i_Item).Package_Id := C2rec.Package_Id;
          v_List(i_Content).Disp_Items(i_Item).Short_Name := C2rec.Short_Name;
          v_List(i_Content).Disp_Items(i_Item).Ref1 := C2rec.Ref1;
          v_List(i_Content).Disp_Items(i_Item).Ref2 := C2rec.Ref2;
          v_List(i_Content).Disp_Items(i_Item).Ref3 := C2rec.Ref3;
          v_List(i_Content).Disp_Items(i_Item).Ref4 := C2rec.Ref4;
          v_List(i_Content).Disp_Items(i_Item).Ref5 := C2rec.Ref5;
          v_List(i_Content).Disp_Items(i_Item).Ref6 := C2rec.Ref6;
          v_List(i_Content).Disp_Items(i_Item).Ref7 := C2rec.Ref7;
          v_List(i_Content).Disp_Items(i_Item).Ref8 := C2rec.Ref8;
          v_List(i_Content).Disp_Items(i_Item).Ref9 := C2rec.Ref9;
          v_List(i_Content).Disp_Items(i_Item).Ref10 := C2rec.Ref10;
          v_List(i_Content).Disp_Items(i_Item).Ref11 := C2rec.Ref11;
          v_List(i_Content).Disp_Items(i_Item).Ref12 := C2rec.Ref12;
          v_List(i_Content).Disp_Items(i_Item).Ref13 := C2rec.Ref13;
          v_List(i_Content).Disp_Items(i_Item).Ref14 := C2rec.Ref14;
          v_List(i_Content).Disp_Items(i_Item).Ref15 := C2rec.Ref15;
          v_List(i_Content).Disp_Items(i_Item).Ref16 := C2rec.Ref16;
          v_List(i_Content).Disp_Items(i_Item).Runtime := C2rec.Runtime;
          v_List(i_Content).Disp_Items(i_Item).Synopsys := C2rec.Synopsys;
          v_List(i_Content).Disp_Items(i_Item).Price := C2rec.Price;
          v_List(i_Content).Disp_Items(i_Item).Name := C2rec.Name;
        
          Declare
            Cursor C3 Is
              Select a.*, b.mas_pk_no, b.detail_pk_no, b.type
                From Mid_Cms_Asset a, Mid_Cms_Item_Rel b
               Where b.Detail_Pk_No = a.Pk_No
                 And b.Mas_Pk_No = C2rec.Pk_No
                 And b.Type = 'A';
            i_Asset Number(16);
          Begin
            v_List(i_Content).Disp_Items(i_Item).Assets := New
                                                           Tcms_Assetlist();
            i_Asset := 1;
            For C3rec In C3 Loop
              v_List(i_Content).Disp_Items(i_Item).Assets.Extend(1);
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset) := New
                                                                      Tcms_Asset();
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Asset_Id := C3rec.Asset_Id;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).File_Url := C3rec.File_Url;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Hd_Sd := C3rec.Hd_Sd;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref1 := C3rec.Ref1;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref2 := C3rec.Ref2;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref3 := C3rec.Ref3;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref4 := C3rec.Ref4;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref5 := C3rec.Ref5;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref6 := C3rec.Ref6;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref7 := C3rec.Ref7;
              v_List(i_Content).Disp_Items(i_Item).Assets(i_Asset).Ref8 := C3rec.Ref8;
              i_Asset := i_Asset + 1;
            End Loop;
          End;
        
          i_Item := i_Item + 1;
        End Loop;
      End;
    
      -- demo
      Declare
        Cursor C2 Is
          Select a.*
            From Mid_Cms_Item a, Mid_Cms_Item_Rel b
           Where a.Pk_No = b.Detail_Pk_No
             And b.Mas_Pk_No = C1rec.Pk_No
             And b.Type = 'D';
        i_Item Number(16);
      Begin
      
        i_Item := 1;
        v_List(i_Content).Demo_Items := new Tcms_Detaillist();
        For C2rec In C2 Loop
          v_List(i_Content).Demo_Items.Extend(1);
          v_List(i_Content).Demo_Items(i_Item) := New Tcms_Detail();
          v_List(i_Content).Demo_Items(i_Item).Item_Type := C2rec.Item_Type;
          v_List(i_Content).Demo_Items(i_Item).Item_Id := C2rec.Item_Id;
          v_List(i_Content).Demo_Items(i_Item).Package_Id := C2rec.Package_Id;
          v_List(i_Content).Demo_Items(i_Item).Short_Name := C2rec.Short_Name;
          v_List(i_Content).Demo_Items(i_Item).Ref1 := C2rec.Ref1;
          v_List(i_Content).Demo_Items(i_Item).Ref2 := C2rec.Ref2;
          v_List(i_Content).Demo_Items(i_Item).Ref3 := C2rec.Ref3;
          v_List(i_Content).Demo_Items(i_Item).Ref4 := C2rec.Ref4;
          v_List(i_Content).Demo_Items(i_Item).Ref5 := C2rec.Ref5;
          v_List(i_Content).Demo_Items(i_Item).Ref6 := C2rec.Ref6;
          v_List(i_Content).Demo_Items(i_Item).Ref7 := C2rec.Ref7;
          v_List(i_Content).Demo_Items(i_Item).Ref8 := C2rec.Ref8;
          v_List(i_Content).Demo_Items(i_Item).Ref9 := C2rec.Ref9;
          v_List(i_Content).Demo_Items(i_Item).Ref10 := C2rec.Ref10;
          v_List(i_Content).Demo_Items(i_Item).Ref11 := C2rec.Ref11;
          v_List(i_Content).Demo_Items(i_Item).Ref12 := C2rec.Ref12;
          v_List(i_Content).Demo_Items(i_Item).Ref13 := C2rec.Ref13;
          v_List(i_Content).Demo_Items(i_Item).Ref14 := C2rec.Ref14;
          v_List(i_Content).Demo_Items(i_Item).Ref15 := C2rec.Ref15;
          v_List(i_Content).Demo_Items(i_Item).Ref16 := C2rec.Ref16;
          v_List(i_Content).Demo_Items(i_Item).Runtime := C2rec.Runtime;
          v_List(i_Content).Demo_Items(i_Item).Synopsys := C2rec.Synopsys;
          v_List(i_Content).Demo_Items(i_Item).Price := C2rec.Price;
          v_List(i_Content).Demo_Items(i_Item).Name := C2rec.Name;
          Declare
            Cursor C3 Is
              Select a.*
                From Mid_Cms_Asset a, Mid_Cms_Item_Rel b
               Where b.Detail_Pk_No = a.Pk_No
                 And b.Mas_Pk_No = C2rec.Pk_No
                 And b.Type = 'A';
            i_Asset Number(16);
          Begin
            v_List(i_Content).Demo_Items(i_Item).Assets := New
                                                           Tcms_Assetlist();
            i_Asset := 1;
            For C3rec In C3 Loop
              v_List(i_Content).Demo_items(i_Item).Assets.Extend(1);
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset) := New
                                                                      Tcms_Asset();
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Asset_Id := C3rec.Asset_Id;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).File_Url := C3rec.File_Url;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Hd_Sd := C3rec.Hd_Sd;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref1 := C3rec.Ref1;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref2 := C3rec.Ref2;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref3 := C3rec.Ref3;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref4 := C3rec.Ref4;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref5 := C3rec.Ref5;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref6 := C3rec.Ref6;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref7 := C3rec.Ref7;
              v_List(i_Content).Demo_items(i_Item).Assets(i_Asset).Ref8 := C3rec.Ref8;
              i_Asset := i_Asset + 1;
            End Loop;
          End;
        
          i_Item := i_Item + 1;
        End Loop;
      End;
    
      i_Content := i_Content + 1;
    
    End Loop;
    Return v_List;
  End;

  Function Get_Content(p_Content_id String) Return tcms_content Is
  
    v_Content Tcms_Content;
  
    Cursor C1 Is
    
      Select a.* From Mid_Cms_Content a Where a.content_id = p_Content_id;
    i_Content Number(16);
  
  Begin
  
    For C1REC In C1 Loop
      v_Content                := New Tcms_Content();
      v_Content.Content_Id     := C1rec.Content_Id;
      v_Content.Title          := C1rec.Title;
      v_Content.Ref1           := C1rec.Ref1;
      v_Content.Ref2           := C1rec.Ref2;
      v_Content.Ref3           := C1rec.Ref3;
      v_Content.Ref4           := C1rec.Ref4;
      v_Content.Ref5           := C1rec.Ref5;
      v_Content.Ref6           := C1rec.Ref6;
      v_Content.Ref7           := C1rec.Ref7;
      v_Content.Ref8           := C1rec.Ref8;
      v_Content.Eng_Title      := C1rec.Eng_Title;
      v_Content.Short_Title    := C1rec.Short_Title;
      v_Content.Synopsis       := C1rec.Synopsis;
      v_Content.Starring       := C1rec.Starring;
      v_Content.Actors         := C1rec.Actors;
      v_Content.Directed       := C1rec.Directed;
      v_Content.Genre          := C1rec.Genre;
      v_Content.Runtime        := C1rec.Runtime;
      v_Content.Release_Year   := C1rec.Release_Year;
      v_Content.Studio         := C1rec.Studio;
      v_Content.Rating         := C1rec.Rating;
      v_Content.Off_Shelf_Date := C1rec.Off_Shelf_Date;
      v_Content.Main_Picture   := C1rec.Main_Picture;
      v_Content.Pictures       := C1rec.Pictures;
      v_Content.Score          := C1rec.Score;
      v_Content.Price          := C1rec.Price;
      v_Content.Sdhd           := C1rec.Sdhd;
      v_Content.Episode        := C1rec.Episode;
      -- Item
      Declare
        Cursor C2 Is
          Select a.*
            From Mid_Cms_Item a, Mid_Cms_Item_Rel b
           Where a.Pk_No = b.Detail_Pk_No
             And b.Mas_Pk_No = C1rec.Pk_No
             And b.Type = 'P';
        i_Item Number(16);
      Begin
      
        i_Item          := 1;
        v_Content.Items := new Tcms_Itemlist();
        For C2rec In C2 Loop
          v_Content .Items.Extend(1);
          v_Content.Items(i_Item) := New Tcms_Item();
          v_Content.Items(i_Item).Item_Type := C2rec.Item_Type;
          v_Content.Items(i_Item).Item_Id := C2rec.Item_Id;
          v_Content.Items(i_Item).Package_Id := C2rec.Package_Id;
          v_Content.Items(i_Item).Short_Name := C2rec.Short_Name;
          v_Content.Items(i_Item).Ref1 := C2rec.Ref1;
          v_Content.Items(i_Item).Ref2 := C2rec.Ref2;
          v_Content.Items(i_Item).Ref3 := C2rec.Ref3;
          v_Content.Items(i_Item).Ref4 := C2rec.Ref4;
          v_Content.Items(i_Item).Ref5 := C2rec.Ref5;
          v_Content.Items(i_Item).Ref6 := C2rec.Ref6;
          v_Content.Items(i_Item).Ref7 := C2rec.Ref7;
          v_Content.Items(i_Item).Ref8 := C2rec.Ref8;
          v_Content.Items(i_Item).Ref9 := C2rec.Ref9;
          v_Content.Items(i_Item).Ref10 := C2rec.Ref10;
          v_Content.Items(i_Item).Ref11 := C2rec.Ref11;
          v_Content.Items(i_Item).Ref12 := C2rec.Ref12;
          v_Content.Items(i_Item).Ref13 := C2rec.Ref13;
          v_Content.Items(i_Item).Ref14 := C2rec.Ref14;
          v_Content.Items(i_Item).Ref15 := C2rec.Ref15;
          v_Content.Items(i_Item).Ref16 := C2rec.Ref16;
          v_Content.Items(i_Item).Runtime := C2rec.Runtime;
          v_Content.Items(i_Item).Synopsys := C2rec.Synopsys;
          v_Content.Items(i_Item).Price := C2rec.Price;
          v_Content.Items(i_Item).Name := C2rec.Name;
          i_Item := i_Item + 1;
        End Loop;
      End;
    
      -- detail
      Declare
        Cursor C2 Is
          Select a.*
            From Mid_Cms_Item a, Mid_Cms_Item_Rel b
           Where a.Pk_No = b.Detail_Pk_No
             And b.Mas_Pk_No = C1rec.Pk_No
             And b.Type = 'G';
        i_Item Number(16);
      Begin
      
        i_Item               := 1;
        v_Content.Disp_Items := new Tcms_Detaillist();
        For C2rec In C2 Loop
          v_Content.Disp_Items.Extend(1);
          v_Content.Disp_Items(i_Item) := New Tcms_Detail();
          v_Content.Disp_Items(i_Item).Item_Type := C2rec.Item_Type;
          v_Content.Disp_Items(i_Item).Item_Id := C2rec.Item_Id;
          v_Content.Disp_Items(i_Item).Package_Id := C2rec.Package_Id;
          v_Content.Disp_Items(i_Item).Short_Name := C2rec.Short_Name;
          v_Content.Disp_Items(i_Item).Ref1 := C2rec.Ref1;
          v_Content.Disp_Items(i_Item).Ref2 := C2rec.Ref2;
          v_Content.Disp_Items(i_Item).Ref3 := C2rec.Ref3;
          v_Content.Disp_Items(i_Item).Ref4 := C2rec.Ref4;
          v_Content.Disp_Items(i_Item).Ref5 := C2rec.Ref5;
          v_Content.Disp_Items(i_Item).Ref6 := C2rec.Ref6;
          v_Content.Disp_Items(i_Item).Ref7 := C2rec.Ref7;
          v_Content.Disp_Items(i_Item).Ref8 := C2rec.Ref8;
          v_Content.Disp_Items(i_Item).Ref9 := C2rec.Ref9;
          v_Content.Disp_Items(i_Item).Ref10 := C2rec.Ref10;
          v_Content.Disp_Items(i_Item).Ref11 := C2rec.Ref11;
          v_Content.Disp_Items(i_Item).Ref12 := C2rec.Ref12;
          v_Content.Disp_Items(i_Item).Ref13 := C2rec.Ref13;
          v_Content.Disp_Items(i_Item).Ref14 := C2rec.Ref14;
          v_Content.Disp_Items(i_Item).Ref15 := C2rec.Ref15;
          v_Content.Disp_Items(i_Item).Ref16 := C2rec.Ref16;
          v_Content.Disp_Items(i_Item).Runtime := C2rec.Runtime;
          v_Content.Disp_Items(i_Item).Synopsys := C2rec.Synopsys;
          v_Content.Disp_Items(i_Item).Price := C2rec.Price;
          v_Content.Disp_Items(i_Item).Name := C2rec.Name;
        
          Declare
            Cursor C3 Is
              Select a.*
                From Mid_Cms_Asset a, Mid_Cms_Item_Rel b
               Where b.Detail_Pk_No = a.Pk_No
                 And b.Mas_Pk_No = C2rec.Pk_No
                 And b.Type = 'A';
            i_Asset Number(16);
          Begin
            v_Content.Disp_Items(i_Item).Assets := New Tcms_Assetlist();
            i_Asset := 1;
            For C3rec In C3 Loop
              v_Content.Disp_Items(i_Item).Assets.Extend(1);
              v_Content.Disp_Items(i_Item).Assets(i_Asset) := New
                                                              Tcms_Asset();
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Asset_Id := C3rec.Asset_Id;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).File_Url := C3rec.File_Url;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Hd_Sd := C3rec.Hd_Sd;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref1 := C3rec.Ref1;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref2 := C3rec.Ref2;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref3 := C3rec.Ref3;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref4 := C3rec.Ref4;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref5 := C3rec.Ref5;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref6 := C3rec.Ref6;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref7 := C3rec.Ref7;
              v_Content.Disp_Items(i_Item).Assets(i_Asset).Ref8 := C3rec.Ref8;
              i_Asset := i_Asset + 1;
            End Loop;
          End;
        
          i_Item := i_Item + 1;
        End Loop;
      End;
    
      -- demo
      Declare
        Cursor C2 Is
          Select a.*
            From Mid_Cms_Item a, Mid_Cms_Item_Rel b
           Where a.Pk_No = b.Detail_Pk_No
             And b.Mas_Pk_No = C1rec.Pk_No
             And b.Type = 'D';
        i_Item Number(16);
      Begin
      
        i_Item               := 1;
        v_Content.Demo_Items := new Tcms_Detaillist();
        For C2rec In C2 Loop
          v_Content.Demo_Items.Extend(1);
          v_Content.Demo_Items(i_Item) := New Tcms_Detail();
          v_Content.Demo_Items(i_Item).Item_Type := C2rec.Item_Type;
          v_Content.Demo_Items(i_Item).Item_Id := C2rec.Item_Id;
          v_Content.Demo_Items(i_Item).Package_Id := C2rec.Package_Id;
          v_Content.Demo_Items(i_Item).Short_Name := C2rec.Short_Name;
          v_Content.Demo_Items(i_Item).Ref1 := C2rec.Ref1;
          v_Content.Demo_Items(i_Item).Ref2 := C2rec.Ref2;
          v_Content.Demo_Items(i_Item).Ref3 := C2rec.Ref3;
          v_Content.Demo_Items(i_Item).Ref4 := C2rec.Ref4;
          v_Content.Demo_Items(i_Item).Ref5 := C2rec.Ref5;
          v_Content.Demo_Items(i_Item).Ref6 := C2rec.Ref6;
          v_Content.Demo_Items(i_Item).Ref7 := C2rec.Ref7;
          v_Content.Demo_Items(i_Item).Ref8 := C2rec.Ref8;
          v_Content.Demo_Items(i_Item).Ref9 := C2rec.Ref9;
          v_Content.Demo_Items(i_Item).Ref10 := C2rec.Ref10;
          v_Content.Demo_Items(i_Item).Ref11 := C2rec.Ref11;
          v_Content.Demo_Items(i_Item).Ref12 := C2rec.Ref12;
          v_Content.Demo_Items(i_Item).Ref13 := C2rec.Ref13;
          v_Content.Demo_Items(i_Item).Ref14 := C2rec.Ref14;
          v_Content.Demo_Items(i_Item).Ref15 := C2rec.Ref15;
          v_Content.Demo_Items(i_Item).Ref16 := C2rec.Ref16;
          v_Content.Demo_Items(i_Item).Runtime := C2rec.Runtime;
          v_Content.Demo_Items(i_Item).Synopsys := C2rec.Synopsys;
          v_Content.Demo_Items(i_Item).Price := C2rec.Price;
          v_Content.Demo_Items(i_Item).Name := C2rec.Name;
          Declare
            Cursor C3 Is
              Select a.*
                From Mid_Cms_Asset a, Mid_Cms_Item_Rel b
               Where b.Detail_Pk_No = a.Pk_No
                 And b.Mas_Pk_No = C2rec.Pk_No
                 And b.Type = 'A';
            i_Asset Number(16);
          Begin
            v_Content.Demo_Items(i_Item).Assets := New Tcms_Assetlist();
            i_Asset := 1;
            For C3rec In C3 Loop
              v_Content .Demo_items(i_Item).Assets.Extend(1);
              v_Content.Demo_items(i_Item).Assets(i_Asset) := New
                                                              Tcms_Asset();
              v_Content.Demo_items(i_Item).Assets(i_Asset).Asset_Id := C3rec.Asset_Id;
              v_Content.Demo_items(i_Item).Assets(i_Asset).File_Url := C3rec.File_Url;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Hd_Sd := C3rec.Hd_Sd;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref1 := C3rec.Ref1;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref2 := C3rec.Ref2;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref3 := C3rec.Ref3;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref4 := C3rec.Ref4;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref5 := C3rec.Ref5;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref6 := C3rec.Ref6;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref7 := C3rec.Ref7;
              v_Content.Demo_items(i_Item).Assets(i_Asset).Ref8 := C3rec.Ref8;
              i_Asset := i_Asset + 1;
            End Loop;
          End;
        
          i_Item := i_Item + 1;
        End Loop;
      End;
    End Loop;
  
    Return v_Content;
  End;

  Function Get_Purchase(p_purchase_id String) Return tbsm_purchase Is
    v_purchase     tbsm_purchase;
    v_purchase_dtl tbsm_purchase_dtl;
    Cursor c1(p_pk_no Number) Is
      Select * From bsm_purchase_item Where mas_pk_no = p_pk_no;
  Begin
    v_purchase         := New tbsm_purchase();
    v_purchase.details := New tbsm_purchase_dtls();
    begin
    
      Select a.pk_no,
             mas_no,
             mas_date,
             mas_code,
             src_no,
             src_date,
             serial_no,
             serial_id,
             status_flg,
             purchase_date,
             pay_type,
             card_no,
             card_type,
             card_expiry,
             cvc2,
             a.approval_code
        Into v_purchase.Pk_no,
             v_purchase.mas_no,
             v_purchase.MAS_DATE,
             v_purchase.MAS_CODE,
             v_purchase.src_no,
             v_purchase.src_date,
             v_purchase.serial_no,
             v_purchase.serial_id,
             v_purchase.status_flg,
             v_purchase.purchase_date,
             v_purchase.pay_type,
             v_purchase.card_no,
             v_purchase.card_type,
             v_purchase.card_expiry,
             v_purchase.cvc2,
             v_purchase.approval_code
        From bsm_purchase_mas a
       Where a.mas_no = p_purchase_id;
      For c1rec In c1(v_purchase.Pk_no) Loop
        v_purchase_dtl := New tbsm_purchase_dtl();
        --    v_purchase_dtl.ITEM_NO:= c1rec.item_no;
        v_purchase_dtl.PACKAGE_ID := c1rec.Package_id;
      
        Declare
          v_package_name Varchar2(256);
        Begin
          Select DESCRIPTION
            Into v_package_name
            From bsm_package_mas
           Where package_id = c1rec.package_id;
        
          v_purchase_dtl.PACKAGE_NAME := v_Package_name;
        End;
      
        v_purchase_dtl.ITEM_ID := c1rec.item_id;
      
        Declare
          v_Item_name     Varchar2(256);
          v_item_pk_no    Number(16);
          v_content_pk_no Number(16);
          v_title_name    Varchar2(256);
        Begin
          Select a.Name, pk_no
            Into v_item_name, v_item_pk_no
            From mid_cms_item a
           Where item_id = c1rec.item_id;
        
          Select mas_pk_no
            Into v_content_pk_no
            From mid_cms_item_rel b
           Where b.detail_pk_no = v_item_pk_no
             And b.Type = 'P';
        
          Select c.title
            Into v_title_name
            From mid_cms_content c
           Where c.pk_no = v_content_pk_no;
        
          v_purchase_dtl.ITEM_NAME := v_title_name || ';' || v_item_name;
        exception
          when no_data_found then
            null;
        End;
      
        --     v_purchase_dtl.OFFER_ID := c1rec.offer_id;
        --     v_purchase_dtl.ASSET_ID := c1rec.asset_id;
        v_purchase_dtl.AMOUNT := c1rec.Amount;
        --     v_purchase_dtl.START_DATE := c1rec.start_date;
        v_purchase_dtl.duration := c1rec.duration;
        v_purchase_dtl.quota    := c1rec.quta;
        v_purchase.details.extend(1);
        v_purchase.details(v_purchase.details.Count) := v_purchase_dtl;
      
      End Loop;
    
    exception
      when no_data_found then
        null;
    end;
    Return v_purchase;
  End;

  Procedure Set_subscription(p_pk_no Number, p_client_id varchar2) Is
    Cursor c1 Is
      Select pk_no,
             package_id,
             item_id,
             start_date,
             end_date,
             status_flg,
             regexp_substr(device_id, '[^_]+', 1, 1) device_id,
             package_id acl_id,
             extend_days
        From bsm_client_details
       Where (src_pk_no = p_pk_no or p_pk_no is null)
         and mac_address = p_client_id;
    Cursor c2 Is
      select "transaction_id"
        from acl.subscription
       where "client_id" = p_client_id
         and "transaction_id" not in
             (select pk_no
                from bsm_client_details a
               where a.mac_address = p_client_id);
  
    v_client_id      Varchar2(32);
    v_msg            clob;
    v_char           varchar(32);
    v_package_type   varchar(32);
    v_acl_package_id varchar2(32);
    v_acl_duration   number(16);
    v_created        date;
    v_device_id      varchar2(32);
    v_ext_days       number(16);
  Begin
  
    For i In c1 Loop
    
      --
      -- check bsm_package_mas setting 
      --
      begin
        select a.cal_type, a.acl_duration, a.ext_days
          into v_package_type, v_acl_duration, v_ext_days
          from bsm_package_mas a
         where package_id = i.package_id;
      
        if v_package_type = 'T' then
          v_acl_package_id := i.item_id;
        else
          v_acl_package_id := i.acl_id;
        end if;
      
      exception
        when no_data_found then
          v_acl_package_id := i.acl_id;
      end;
        if i.extend_days is not null then
          v_ext_days := i.extend_days;
        else
          update bsm_client_details dtl
          set extend_days = v_ext_days
          where dtl.pk_no=i.pk_no;
          
          commit;
        end if;
    
      if i.end_date is null or v_package_type = 'T' then
        v_created := i.start_date;
      else
        v_created := i.end_date + (v_ext_days) -
                     (v_acl_duration / (24 * 60 * 60));
      end if;
    
      if v_created is null then
        v_created := sysdate;
      end if;
    
      declare
        v_char       varchar2(32);
        v_delete_flg varchar(32);
      begin
        v_delete_flg := 'N';
        if trunc(nvl(i.end_date + v_ext_days, sysdate + 1)) <
           trunc(sysdate) then
          v_delete_flg := 'Y';
        end if;
      
        select 'x'
          into v_char
          from acl.subscription
         where "transaction_id" = to_char(i.pk_no);
        --  and "client_id" = p_client_id;
      
        update acl.subscription
           set "deleted" = decode(v_delete_flg,
                                  'Y',
                                  1,
                                  decode(i.STATUS_FLG, 'P', 0, 1))
         where "transaction_id" = to_char(i.pk_no);
      
        if v_acl_package_id is not null then
          if length(p_client_id) = 12 or instr(i.device_id, '_') > 0 or
             instr(i.device_id, '-') > 0 or instr(i.device_id, '.') > 0 or
             length(i.device_id) <> 12 then
            v_device_id := null;
          else
            v_device_id := i.device_id;
          end if;
          update acl.subscription
             set "package_id" = v_acl_package_id,
                 "start_time" = i.start_date,
                 "created"    = v_created,
                 "deleted"    = decode(v_delete_flg,
                                       'Y',
                                       1,
                                       decode(i.STATUS_FLG, 'P', 0, 1)),
                 -- "client_id"  = p_client_id,
                 "device_id"          = v_device_id,
                 "service_start_time" = i.start_date,
                 "service_end_time"   = i.end_date + v_ext_days
           where "transaction_id" = to_char(i.pk_no);
        end if;
      
      exception
        when no_data_found then
          begin
            if length(p_client_id) = 12 or instr(i.device_id, '_') > 0 or
               instr(i.device_id, '-') > 0 or instr(i.device_id, '.') > 0 or
               length(i.device_id) <> 12 then
              v_device_id := null;
            else
              v_device_id := i.device_id;
            end if;
            dbms_output.put_line('acl:' || v_acl_package_id);
            if v_acl_package_id is not null then
              Insert Into acl.subscription
                ("transaction_id",
                 "client_id",
                 "device_id",
                 "package_id",
                 "start_time",
                 "created",
                 "last_modified",
                 "deleted",
                 "service_start_time",
                 "service_end_time")
              Values
                (to_char(i.pk_no),
                 p_client_id,
                 v_device_id,
                 v_acl_package_id,
                 i.start_date,
                 v_created,
                 Sysdate,
                 decode(v_delete_flg,
                        'Y',
                        1,
                        decode(i.STATUS_FLG, 'P', 0, 1)),
                 i.start_date,
                 i.end_date + v_ext_days);
            end if;
          
          end;
        
      end;
    
    End Loop;
  
    for c2rec in c2 loop
      update acl.subscription a
         set "deleted" = 1
       where "transaction_id" = c2rec."transaction_id";
    end loop;
  
    commit;
  
    declare
      v_enqueue_options    dbms_aq.enqueue_options_t;
      v_message_properties dbms_aq.message_properties_t;
      v_message_handle     raw(16);
      v_payload            purchase_msg_type;
    begin
      v_payload := purchase_msg_type(p_client_id, 0, '', 'refresh_cdi');
      dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                      enqueue_options    => v_enqueue_options,
                      message_properties => v_message_properties,
                      payload            => v_payload,
                      msgid              => v_message_handle);
      commit;
    end;
  
    declare
      v_enqueue_options    dbms_aq.enqueue_options_t;
      v_message_properties dbms_aq.message_properties_t;
      v_message_handle     raw(16);
      v_payload            purchase_msg_type;
    begin
      
      v_payload := purchase_msg_type(p_client_id, 0, '', 'refresh_bsm');
      dbms_aq.enqueue(queue_name         => 'purchase_msg_queue',
                      enqueue_options    => v_enqueue_options,
                      message_properties => v_message_properties,
                      payload            => v_payload,
                      msgid              => v_message_handle);
      commit;
    end;
  End;

  Function UnActivate_client(p_user_no number, p_Serial_id varchar2)
    return varchar2 is
    v_status_flg       varchar2(32);
    v_serial_no        number(16);
    v_msg              varchar2(2000);
    v_real_mac_address varchar2(32);
    v_owner_phone      varchar2(32);
    v_client_id        varchar2(32);
  
  begin
    select status_flg,
           serial_no,
           real_mac_address,
           owner_phone,
           mac_address
      into v_status_flg,
           v_serial_no,
           v_real_mac_address,
           v_owner_phone,
           v_client_id
      from bsm_client_mas
     where MAC_Address = p_Serial_id;
  
    update bsm_client_mas a
       set status_flg = 'U',
           cust_id    = null,
           cust_no    = null,
           owner_id   = null,
           a.owner_no = null
     where serial_no = v_serial_no;
  
    Set_Client_Connect_Event(v_Serial_No);
    v_msg := BSM_CDI_SERVICE.del_mobile_number_mapping(v_real_mac_address,
                                                       v_owner_phone);
    declare
      cursor c1 is
        select rowid rid, t.*
          from bsm_client_device_list t
         where t.client_id = v_client_id;
    begin
      for c1rec in c1 loop
        v_msg := BSM_CDI_SERVICE.del_mobile_number_mapping(c1rec.device_id,
                                                           v_owner_phone);
      
        update bsm_client_device_list t
           set t.status_flg = 'N'
         where t.rowid = c1rec.rid;
      end loop;
    end;
  
    v_msg := BSm_CDI_SERVICE.Set_Client_Status(p_serial_id, 'U');
    commit;
    return 'OK';
  
  exception
    when Status_Exception then
      rollback;
      return 'Status Error';
  end;

  Function UnGift(p_user_no number, p_Serial_id varchar2) return varchar2 is
  
  begin
    update bsm_client_details a
       set status_flg = 'N'
     where a.mac_address = p_Serial_id
       and package_id <> 'FREE_FOR_CLEINT_ACTIVED';
  
    update mfg_iptv_service_dtls a
       set status_flg = 'P'
     where a.mac_address = p_Serial_id
       and status_flg = 'N';
  
    commit;
  
    Set_subscription(null, p_Serial_id);
  
    return 'OK';
  exception
    when Status_Exception then
      rollback;
      return 'Status Error';
  end;

  Function Register_Coupon(In_Client_Info In Out Tbsm_Client_Info,
                           Coupon_NO      varchar2) Return Tbsm_Result Is
    v_Result Tbsm_Result;
    v_src_no varchar(64);
  Begin
  
    v_result := Register_Coupon(In_Client_Info, Coupon_NO, v_src_no, null);
  
    return v_result;
  
  End;

  Function Register_Coupon(In_Client_Info In Out Tbsm_Client_Info,
                           Coupon_NO      varchar2,
                           SRC_NO         out varchar2,
                           p_sw_version   varchar2 default null)
    Return Tbsm_Result Is
    v_Client_Info    Tbsm_Client_Info;
    v_Result         Tbsm_Result;
    v_msg            varchar2(2000);
    v_src_no         varchar2(64);
    v_software_group varchar2(64);
  Begin
    v_Result := New Tbsm_Result;
  
    if p_sw_version is not null then
      v_software_group := upper(substr(p_sw_version, 1, 7));
      declare
        v_software_group_old varchar2(32);
      begin
        select b.software_group
          into v_software_group_old
          from bsm_client_device_list b
         where b.client_id = In_Client_Info.Serial_id
           and b.device_id = In_Client_Info.mac_address
           and rownum <= 1;
        if v_software_group_old != v_software_group then
          update bsm_client_device_list a
             set software_group = v_software_group
           where a.client_id = In_Client_Info.Serial_id
             and a.device_id = In_Client_Info.mac_address;
          commit;
        end if;
      
      exception
        when no_data_found then
          insert into bsm_client_device_list
            (client_id, device_id, software_group, status_flg)
          values
            (In_Client_Info.Serial_id,
             In_Client_Info.mac_address,
             substr(p_sw_version, 1, 7),
             'P');
          commit;
      end;
    end if;
  
    declare
      v_msg varchar2(256);
    
    begin
      if Coupon_no != '2410227010265317' then
      
        v_msg := bsm_purchase_post.CLIENT_REGIETER_COUPOR(nvl(In_Client_Info.Serial_id,
                                                              In_Client_Info.mac_address),
                                                          Coupon_NO,
                                                          'R',
                                                          In_client_Info.MAC_Address);
      end if;
      v_result.Result_Code    := 'BSM-00000';
      v_result.Result_Message := '你已成功兌換' || v_msg;
    
      begin
      
        select mas_no
          into v_src_no
          from bsm_coupon_mas a
         where a.coupon_id = Coupon_no;
        src_no := v_src_no;
      
      exception
        when no_data_found then
          null;
      end;
    exception
      when bsm_purchase_post.client_not_found then
        raise bsm_purchase_post.client_status_error;
      when bsm_purchase_post.coupon_not_found then
        raise Error_Coupon_No;
      when bsm_purchase_post.client_status_error then
        raise bsm_purchase_post.client_status_error;
      when bsm_purchase_post.coupon_registed then
        raise Error_Coupon_Activated;
      when bsm_purchase_post.coupon_model_error then
        raise Error_Coupon_Model;
      When bsm_purchase_post.coupon_demo_error then
        raise Error_Coupon_Demo;
    end;
  
    Commit;
    Return v_Result;
  
  Exception
    When Error_Coupon_No Then
      v_Result.Result_Code    := 'BSM-00601';
      v_Result.Result_Message := '錯誤的兌換券號碼';
      Return v_Result;
    When Error_Coupon_Activated Then
      v_Result.Result_Code    := 'BSM-00602';
      v_Result.Result_Message := '兌換券已兌換過';
      Return v_Result;
    When Error_Coupon_Status Then
      v_Result.Result_Code    := 'BSM-00603';
      v_Result.Result_Message := '兌換券的狀態錯誤';
      Return v_Result;
    When Error_Coupon_Demo Then
      v_Result.Result_Code    := 'BSM-00606';
      v_Result.Result_Message := 'Demo 機無法使用此兌換券';
      Return v_Result;
    When Error_Coupon_Model Then
      v_Result.Result_Code    := 'BSM-00607';
      v_Result.Result_Message := '此機型無法使用此兌換券';
      Return v_Result;
    When bsm_purchase_post.demo_on_not_demo_client Then
      v_Result.Result_Code    := 'BSM-00607';
      v_Result.Result_Message := '展示Coupon 用在非展示機上';
      Return v_Result;
    When bsm_purchase_post.coupon_on_demo_client Then
      v_Result.Result_Code    := 'BSM-00608';
      v_Result.Result_Message := 'Coupon 用在展示機上';
      Return v_Result;
    when bsm_purchase_post.coupon_group_no_found Then
      v_Result.Result_Code    := 'BSM-00609';
      v_Result.Result_Message := 'Coupon 不能用在此機型上';
      Return v_Result;
    when bsm_purchase_post.coupon_expired Then
      v_Result.Result_Code    := 'BSM-00610';
      v_Result.Result_Message := 'Coupon 已到期';
      Return v_Result;
    when bsm_purchase_post.dup_client_registed Then
      v_Result.Result_Code    := 'BSM-00611';
      v_Result.Result_Message := '一戶二機方案 不能兌換兩次';
      Return v_Result;
    when bsm_purchase_post.coupon_program_registed Then
      v_Result.Result_Code    := 'BSM-00614';
      v_Result.Result_Message := '使用者已兌換過此方案';
      Return v_Result;
      /*  when others then
      v_Result.Result_Code    := 'BSM-00605';
      v_Result.Result_Message := '伺服器發生問題請洽客服';
      Return v_Result; */
  End;

  Function send_mail(url varchar2) return varchar2 is
    req            utl_http.req;
    resp           utl_http.resp;
    rw             varchar2(32767);
    v_param        VARCHAR2(500) := '';
    v_param_length NUMBER := length(v_param);
    rw_result      varchar2(32767);
  
  begin
    v_param_length := length(v_param);
    UTL_HTTP.set_wallet('file:/oracle/wallet', 'QWer1234');
    Req := Utl_Http.Begin_Request(url, 'GET', 'HTTP/1.1');
  
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
  
    commit;
  
    return rw_result;
  
  end;

  Function Get_Client_val(client_id     varchar2,
                          p_name        varchar2,
                          p_default_val clob) return clob is
    v_val            clob;
    v_software_group varchar2(64);
    v_default_val    clob;
  begin
    begin
      select software_group
        into v_software_group
        from mfg_iptv_mas
       where mac_address = client_id;
      if v_software_group is null then
        v_software_group := 'SYSTEM_DEFAULT';
      end if;
    exception
      when no_data_found then
        v_software_group := 'SYSTEM_DEFAULT';
        -- 使用Software group 作為 value id
    end;
    begin
      select val
        into v_val
        from bsm_client_val a
       where a.val_name = p_name
         and a.val_id = v_software_group;
    
      if length(v_val) = 0 then
        v_software_group := 'SYSTEM_DEFAULT';
        select val
          into v_val
          from bsm_client_val a
         where a.val_name = p_name
           and a.val_id = v_software_group;
      end if;
      return v_val;
    
    exception
      when no_data_found then
        if v_software_group is not null then
          if p_default_val is null then
            v_software_group := 'SYSTEM_DEFAULT';
            begin
              select val
                into v_val
                from bsm_client_val a
               where a.val_name = p_name
                 and a.val_id = v_software_group;
            exception
              when no_data_found then
                insert into bsm_client_val
                  (val_name, val_id, default_val, val)
                values
                  (p_name, v_software_group, v_val, v_val);
                commit;
            end;
          
          else
            v_default_val := p_default_val;
          end if;
          insert into bsm_client_val
            (val_name, val_id, default_val, val)
          values
            (p_name, v_software_group, v_default_val, v_default_val);
          commit;
        end if;
        return v_default_val;
    end;
  
  end;

  Function Set_Client_val(client_id     varchar2,
                          p_name        varchar2,
                          p_default_val clob) return clob is
    v_val            clob;
    v_software_group varchar2(64);
  begin
    begin
      select software_group
        into v_software_group
        from mfg_iptv_mas
       where mac_address = client_id;
    exception
      when no_data_found then
        v_software_group := 'SYSTEM_DEFAULT';
        -- 使用Software group 作為 value id
    end;
    begin
      select val
        into v_val
        from bsm_client_val a
       where a.val_name = p_name
         and a.val_id = v_software_group;
    
      update bsm_client_val a
         set val = p_default_val
       where a.val_name = p_name
         and a.val_id = v_software_group;
    
      return p_default_val;
    exception
      when no_data_found then
        insert into bsm_client_val
          (val_name, val_id, default_val, val)
        values
          (p_name, v_software_group, p_default_val, p_default_val);
        commit;
        return p_default_val;
    end;
  end;

  procedure refresh_bsm_client(v_client_id varchar2) is
  begin
    declare
      v_param        VARCHAR2(500) := '{
    "id":"1234",
    "jsonrpc": "2.0",
    "method": "refresh_client", 
    "params": {
        "client_id": "_CLIENT_ID_" 
    }
}';
      v_param_length NUMBER := length(v_param);
      rw_result      clob;
      req            utl_http.req;
      resp           utl_http.resp;
      rw             varchar2(32767);
    begin
      v_param := replace(v_param, '_CLIENT_ID_', v_client_id);
    
      v_param_length := length(v_param);
      rw := link_set.link_set.post_bsm(v_param);

    exception
      when others then
        null;
    end;
  
    declare
      v_param        VARCHAR2(500) := '{
    "id":"1234",
    "jsonrpc": "2.0",
    "method": "refresh_client", 
    "params": {
        "client_id": "_CLIENT_ID_" 
    }
}';
      v_param_length NUMBER := length(v_param);
      rw_result      clob;
      req            utl_http.req;
      resp           utl_http.resp;
      rw             varchar2(32767);
    
    begin
      v_param := replace(v_param, '_CLIENT_ID_', v_client_id);
    --/* http://bsm01.tw.svc.litv.tv/BSM_JSON_SERVICE/BSM_Purchase_Info.ashx
      v_param_length := length(v_param);
      Req            := Utl_Http.Begin_Request('http://bsm01.tw.svc.litv.tv/BSM_JSON_SERVICE/BSM_Purchase_Info.ashx',
                                               'POST',
                                               'HTTP/1.1');
    
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
    exception
      when others then
        null;
    end;
  end;

  procedure refresh_acg(v_client_id varchar2, v_promo_code varchar2) is
  begin
    declare
      v_param        VARCHAR2(500) := '{"id":"1","method":"httpRequest","params":{"url":"_URL_",
  "postData":{"id":"1","jsonrpc":"2.0","method":"purchaseWithPromoteCodeClientId","params":{"promote_code":"_PROMO_CODE_","client_id":"_CLIENT_ID_"}}
  }}';
      v_param_length NUMBER := length(v_param);
      rw_result      clob;
      req            utl_http.req;
      resp           utl_http.resp;
      rw             varchar2(32767);
    
    begin
      --  utl_http.set_wallet('file:/home/oracle/wallet','oracle123');
    
      v_param        := replace(v_param,
                                '_URL_',
                                'https://p-acg.svc.litv.tv/acg/rpc/bsm');
      v_param        := replace(v_param, '_CLIENT_ID_', v_client_id);
      v_param        := replace(v_param, '_PROMO_CODE_', v_promo_code);
      v_param_length := length(v_param);
      Req            := Utl_Http.Begin_Request('http://bsm02.tw.svc.litv.tv/BSM_JSON_SERVICE/bsm_purchase_service.ashx',
                                               'POST',
                                               'HTTP/1.1');
    
      UTL_HTTP.SET_HEADER(r     => req,
                          name  => 'Content-Type',
                          value => 'application/json');
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
    exception
      when others then
        utl_http.end_response(resp);
      
    end;
  end;
  
  procedure saveClientServiceInfo(v_client_id varchar2) is
  begin
    declare
      v_param_bsm        clob := '{"id":"1","method":"httpRequest","params":{"url":"_URL_",
  "postData":_POST_DATA_
  }}';
      v_param clob := '{"id": "1","jsonrpc": "2.0","method": "saveClientServiceInfo","params": {"client_id": "_CLIENT_ID_","subscriptions": [_SUBS_]}}';
      v_temp_sub clob := '{"package_category_id": "_CAT_","package_id": "_ID_","start_date": "_START_","end_date": "_END_","expired_date": "_EXPIRED_","status": "_STATUS_"}';
      v_sub_clob clob;
      v_sub_cnt number := 0;
      rw_result      clob;
      req            utl_http.req;
      resp           utl_http.resp;
      rw             varchar2(32767);
    begin
      
       declare
        cursor c1 is Select a.package_id package_id, b.package_cat_id1 package_category_id, to_char(start_date,'YYYY/MM/DD') start_date,
to_char(end_date,'YYYY/MM/DD') end_date,decode( a.status_flg,'P','Y','N') status
  from bsm_client_details a, bsm_package_mas b
 where b.package_id = a.package_id and a.serial_id = v_client_id and a.status_flg='P' and start_date is not null and end_date is not null;
      begin
        for i in c1 loop
          if v_sub_cnt >0 then
            v_sub_clob := v_sub_clob||',';
          end if;
          v_sub_clob:= v_sub_clob||v_temp_sub;
          v_sub_clob := replace(v_sub_clob,'_CAT_',i.package_category_id);
          v_sub_clob := replace(v_sub_clob,'_ID_',i.package_id);
          v_sub_clob := replace(v_sub_clob,'_START_',i.start_date);
          v_sub_clob := replace(v_sub_clob,'_END_',i.end_date);
          v_sub_clob := replace(v_sub_clob,'_EXPIRED_',i.end_date);
          v_sub_clob := replace(v_sub_clob,'_STATUS_',i.status); 
          v_sub_cnt := v_sub_cnt+1;                                       
        end loop;
      end;
 

       
       v_param := replace(v_param,'_CLIENT_ID_',v_client_id);
       v_param := replace(v_param,'_SUBS_',v_sub_clob);
       v_param_bsm        := replace(v_param_bsm,
                                '_URL_',
                                'https://acg.svc.litv.tv/acg/rpc/bsm');
       v_param_bsm        := replace(v_param_bsm,
                                '_POST_DATA_',v_param); 
      utl_http.set_transfer_timeout(3);                         
      rw_result      := link_set.link_set.post_data('http://bsm02.tw.svc.litv.tv/bsm_json_service/bsm_purchase_service.ashx',v_param_bsm);
    exception
      when others then
                null;
    end;
    
  end;

--begin
-- Initialization
-- <Statement>;
End Bsm_Client_Service;
/
