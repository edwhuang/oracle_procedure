CREATE OR REPLACE PACKAGE BODY IPTV."BSM_WEB_SERVICE" is

  -- Private type declarations
  -- type <TypeName> is <Datatype>;

  -- Private constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Private variable declarations
  -- <VariableName> <Datatype>;

  -- Function and procedure implementations
  /*nction get_cust_info(in_phone_no varchar2, in_activation_code varchar2)
    return TBSM_CUSTOMERS is
    --  <LocalVariable> <Datatype>;
    cursor c1 is
      Select cust_id, cust_no, a.mac_address, a.serial_id, a.status_flg
        from bsm_client_mas a
       where a.owner_phone = in_phone_no
         and a.activation_code = in_activation_code;
    v_customer TBSM_CUSTOMER;
    v_list     TBSM_CUSTOMERS;
    v_count    number;
  
  begin
    v_List  := new TBSM_CUSTOMERS();
    v_count := 1;
    --  <Statement>;
    --  return(<Result>);
    for c1rec in c1 loop
      v_List.Extend(1);
      v_customer                    := new TBSM_CUSTOMER();
      v_customer.CLIENT_MAC_ADDRESS := c1rec.mac_address;
      v_customer.CLIENT_ID          := c1rec.serial_id;
      v_customer.MOBILEPHONE1 := in_phone_no;
      if c1rec.cust_no is not null then
        select cust_id,
            --   old_cust_id,
               cust_name,
            --   cust_type,
               gender,
            --   unifiedid_tw,
            --   company_uid,
               dayphone,
            --   nightphone,
               mobilephone1,
               mobilephone2,
               faxmile,
               email,
               zip,
               address
            --   roster_date,
            --   last_login_time,
            --   keyin_date,
            --   remark,
            --   company_name,
             --  bid,
              -- keyin_emp,
            --   update_date,
            --   update_emp,
            --   zip_area,
            --   user_no,
            --   cat1,
            --   cat2,
            --   cat3,
             --  cat4,
            --   acc_terms,
            --   tax_flg,
            --   tax_code,
            --   bill_flg,
            --   print_invo_flg,
            --   bill_zip,
             --  inst_zip,
             --  bill_address,
             --  inst_address
          into v_customer.cust_id,
            --   v_customer.old_cust_id,
               v_customer.cust_name,
            --   v_customer.cust_type,
               v_customer.gender,
             --  v_customer.unifiedid_tw,
            --   v_customer.company_uid,
               v_customer.dayphone,
           --    v_customer.nightphone,
               v_customer.mobilephone1,
               v_customer.mobilephone2,
               v_customer.faxmile,
               v_customer.email,
               v_customer.zip,
               v_customer.address
            --   v_customer.roster_date,
            --   v_customer.last_login_time,
            --   v_customer.keyin_date,
            --   v_customer.remark,
            --   v_customer.company_name,
            --   v_customer.bid,
            --   v_customer.keyin_emp,
             --  v_customer.update_date,
             --  v_customer.update_emp,
             --  v_customer.zip_area,
             --  v_customer.user_no,
             --  v_customer.cat1,
             --  v_customer.cat2,
             --  v_customer.cat3,
             --  v_customer.cat4,
             --  v_customer.acc_terms,
             --  v_customer.tax_flg,
             --  v_customer.tax_code,
             --  v_customer.bill_flg,
             --  v_customer.print_invo_flg,
             --  v_customer.bill_zip,
             --  v_customer.inst_zip,
             --  v_customer.bill_address,
             --  v_customer.inst_address
          from tgc_customer
         where user_no = c1rec.cust_no;
      end if;
      v_list(v_count) := v_customer;
      v_count := v_count + 1;
    end loop;
  
    return v_list;
  
  end;
*/
  function get_customer(in_web_account varchar2)
    return TBSM_CUSTOMER is
    --  <LocalVariable> <Datatype>;
    v_customer TBSM_CUSTOMER;

  
  begin
    v_customer  := new TBSM_CUSTOMER();
    
    begin
        select cust_id,
          --     old_cust_id,
               cust_name,
          --     cust_type,
               gender,
          --     unifiedid_tw,
          --     company_uid,
               dayphone,
           --    nightphone,
               mobilephone1,
               mobilephone2,
               faxmile,
               email,
               zip,
               address,
               ref14
          --     roster_date,
          --     last_login_time,
          --     keyin_date,
          --     remark,
          --     company_name,
          --     bid,
          --     keyin_emp,
          --     update_date,
          --     update_emp,
          --     zip_area,
          --     user_no,
          --     cat1,
          --     cat2,
          --     cat3,
          --     cat4,
          --     acc_terms,
          --     tax_flg,
          --     tax_code,
          --     bill_flg,
          --     print_invo_flg,
          --     bill_zip,
          --     inst_zip,
          --     bill_address,
          --     inst_address
          into v_customer.cust_id,
           --    v_customer.old_cust_id,
               v_customer.cust_name,
          --     v_customer.cust_type,
               v_customer.gender,
          --     v_customer.unifiedid_tw,
          --     v_customer.company_uid,
               v_customer.dayphone,
          --     v_customer.nightphone,
               v_customer.mobilephone1,
               v_customer.mobilephone2,
               v_customer.faxmile,
               v_customer.email,
               v_customer.zip,
               v_customer.address,
               v_customer.EPAPER
          --     v_customer.roster_date,
          --     v_customer.last_login_time,
          --     v_customer.keyin_date,
           --    v_customer.remark,
           --    v_customer.company_name,
           --    v_customer.bid,
           --    v_customer.keyin_emp,
           --    v_customer.update_date,
           --    v_customer.update_emp,
           --    v_customer.zip_area,
           --    v_customer.user_no,
           --    v_customer.cat1,
           --    v_customer.cat2,
           --    v_customer.cat3,
           --    v_customer.cat4,
           --    v_customer.acc_terms,
           --    v_customer.tax_flg,
           --    v_customer.tax_code,
           --    v_customer.bill_flg,
           --    v_customer.print_invo_flg,
           --    v_customer.bill_zip,
           --    v_customer.inst_zip,
           --    v_customer.bill_address,
           --    v_customer.inst_address
          from tgc_customer a
         where a.web_account = in_web_account;
    exception 
       when no_data_found then null;
    end;
    return  v_customer;
  end;


  function set_cust_info(in_account_id varchar2,in_web_password varchar2,in_cust_info TBSM_CUSTOMER)   Return Varchar2 is
    v_cust_no Number(32);
    v_cust_id Varchar2(32);
    no_account_id_found Exception;
  Begin
  
    Begin
      Select user_no, cust_id
        Into v_cust_no, v_cust_id
        From TGC_CUSTOMER a
       Where a.web_account = in_account_id;
    Exception
      When no_data_found Then
        v_cust_no := null;
    End; 
    
    If v_cust_no Is Not Null Then

      -- update script
      Update TGC_CUSTOMER a
         Set a.cust_name    = in_cust_info.cust_name,
             a.address      = In_cust_info.address,
             a.zip          = in_cust_info.zip,
             a.dayphone     = in_cust_info.dayphone,
             a.mobilephone1 = in_cust_info.mobilephone1,
             a.mobilephone2 = in_cust_info.mobilephone2,
             a.faxmile      = in_cust_info.faxmile,
             a.ref14        = in_cust_info.EPAPER,
             a.gender       = in_cust_info.GENDER,
             a.email        = in_cust_info.EMAIL
       Where a.user_no = v_cust_no;
       
       if in_web_password is not null then 
       -- update script
          Update TGC_CUSTOMER a
             Set a.web_pwd = in_web_password
           Where a.user_no = v_cust_no;
           
        -- update 
          update BSM_CLIENT_MAS a
            set a.activation_code=in_web_password
           where a.owner_id =v_cust_id;
       end if;

    Else
      -- insert script
    
      Select seq_sys_no.Nextval Into v_cust_no From dual;
      v_cust_id := sysapp_util.get_mas_no(1,
                                          1,
                                          sysdate,
                                          'LITVCUSTOMER',
                                          v_cust_no);
    
      Insert Into Tgc_Customer
        (User_No,
         Cust_Id,
         Cust_Name,
         
       --//  Unifiedid_Tw,
         Dayphone,
         Mobilephone1,
         Mobilephone2,
         zip,
         Address,
         Email,
         faxmile,
         web_account,
         REF14,
         
         Keyin_Date,
         Keyin_Emp,
         gender,
         tax_code
         
         )
      Values
        (v_Cust_No,
         v_Cust_Id,
         in_cust_info.Cust_Name,
      -- //  in_cust_info.UNIFIEDID_TW,
         in_cust_info.DAYPHONE,
         in_cust_info.MOBILEPHONE1,
         in_cust_info.MobilePhone2,
         in_cust_info.ZIP,
         in_cust_info.Address,
         in_cust_info.Email,
         in_cust_info.faxmile,
         in_account_id,
         in_cust_info.EPAPER,
         Sysdate,
         'system',
         in_cust_info.GENDER,
         'OUTTAX1'
         );
         if in_web_password is not null then 
       -- update script
          Update TGC_CUSTOMER a
             Set a.web_pwd = in_web_password
           Where a.user_no = v_cust_no;
       end if;
     End If;
    
    commit;
  
    return 'ok';
  
  end;

  function assign_client(in_account_id varchar2,in_web_password varchar2,in_client_id varchar2,in_activation_code varchar2) 
    Return Varchar2  is
    v_cust_no Number(32);
    v_client_cust_no number(32);
    v_cust_id Varchar2(32);
    no_account_id_found Exception;
    no_client_id_found Exception;
    v_client_owner_id varchar2(32);
  Begin
  
    Begin
      Select user_no, cust_id
        Into v_cust_no, v_cust_id
        From TGC_CUSTOMER a
       Where a.web_account = in_account_id;
    Exception
      When no_data_found Then
        raise no_account_id_found;
    End; 
    
    begin
      select owner_no,owner_id 
      into v_client_cust_no,v_client_owner_id
        from bsm_client_mas a
       where a.serial_id = in_client_id;
    exception 
      when no_data_found then 
        raise no_client_id_found;
    end;

    if v_client_cust_no is null 
      or v_client_owner_id is null then 
       update bsm_client_mas a
          set a.owner_id = v_cust_id ,
              a.owner_no = v_cust_no
         where a.serial_id= in_client_id;
    end if;
    
    commit;
  
    return 'ok';
  
  end;


   function reset_web_pwd(in_serial_id varchar2, in_phone_no varchar2)
    Return varchar2 is
    v_char varchar2(32);
    v_activation_code varchar2(32);
  Begin
    Select 'x' into v_char
     from bsm_client_mas a
     where status_flg ='A' and MAC_address=in_serial_id and a.owner_phone = in_phone_no;
     v_activation_code := BSM_CLIENT_SERVICE.Get_Activation_no;
     
     
     update bsm_client_mas a
       set a.activation_code=v_activation_code
       where MAC_address=in_serial_id;
       
     commit;
    
    return null;
  exception 
    when no_data_found then return 'failure';
  End;



--begin
--  null;
-- Initialization
--<Statement>;
end BSM_WEB_SERVICE;
/

