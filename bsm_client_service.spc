CREATE OR REPLACE PACKAGE IPTV.BSM_CLIENT_SERVICE Is

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
  Error_Limit_account    Exception;

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
                           parameter_options varchar2 default null,
                            p_refresh_client varchar2 default null)
    Return Tbsm_Result;
  Function Get_Purchase(p_purchase_id String) Return tbsm_purchase;
  Procedure Set_subscription(p_pk_no Number, p_client_id varchar2);
  Procedure Set_subscription_r(p_pk_no        Number,
                               p_client_id    varchar2,
                               refresh_client varchar default 'R');
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
  procedure refresh_bsm_client(v_client_id   varchar2,
                               refresh_quene varchar2 default null);
  procedure refresh_acg(v_client_id varchar2, v_promo_code varchar2);
  procedure saveClientServiceInfo(v_client_id varchar2);

End Bsm_Client_Service;
/

