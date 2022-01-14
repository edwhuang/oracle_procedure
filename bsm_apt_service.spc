create or replace package iptv.BSM_APT_SERVICE is

  jsonrpc_error exception;
  not_apt_user exception;
  apt_min_error exception;
  apt_product_code exception;
  apt_bought exception;
  apt_unknow_error exception;
  apt_not_act_user exception;
  register_error exception;

  phone_no    varchar2(32);
  user_status varchar2(32);

  function get_user_info(p_min varchar2) return varchar2;
   function apt_register_purchase(p_src_no varchar2, v_pk_no number)
    return varchar2;
  function register(p_min           varchar2,
                    p_productcode   varchar2,
                    p_transactionId varchar2) return varchar2;
  function check_min(p_min varchar2) return varchar2;
                        
  function check_service(p_min varchar2, p_productcode varchar2)
    return varchar2;
  function get_apt_result(p_method      varchar2,
                          p_MIN         varchar2,
                          p_productCode varchar2,
                          transactionId varchar2) return JSON;
                            

end BSM_APT_SERVICE;
/

