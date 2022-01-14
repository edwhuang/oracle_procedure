CREATE OR REPLACE PACKAGE IPTV."BSM_WEB_SERVICE" is

  -- Author  : EDWARD.HUANG
  -- Created : 2010/12/23 上午 09:21:30
  -- Purpose : 

  -- Public type declarations
  --type <TypeName> is <Datatype>;

  -- Public constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  --<VariableName> <Datatype>;

  -- Public function and procedure declarations
 -- function get_cust_info(in_phone_no varchar2, in_activation_code varchar2)
 --   return TBSM_CUSTOMERS;
  function get_customer(in_web_account varchar2)
    return TBSM_CUSTOMER;
  

  function set_cust_info(in_account_id varchar2,in_web_password varchar2,in_cust_info TBSM_CUSTOMER)
    Return Varchar2;
    
   function assign_client(in_account_id varchar2,in_web_password varchar2,in_client_id varchar2,in_activation_code varchar2) return varchar2;
    
  function reset_web_pwd(in_serial_id varchar2, in_phone_no varchar2)
    Return varchar2;
     

end BSM_WEB_SERVICE;
/

