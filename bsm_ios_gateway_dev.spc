CREATE OR REPLACE PACKAGE IPTV."BSM_IOS_GATEWAY_DEV" is

  -- Author  : EDWARD.HUANG
  -- Created : 2010/6/30 下午 03:15:02
  -- Purpose :

  -- Public type declarations
  -- type <TypeName> is <Datatype>;
  latest_receipt_info_not_found exception;
  function Send_Receipt_Data(p_order_no    varchar2,
                             p_receipt varchar2,
                             p_password varchar2,
                             p_ios_product_code varchar2
                      ) return clob;

  function get_Receipt_Data(p_order_no    varchar2,
                             p_receipt varchar2,
                             p_password varchar2,
                             p_ios_product_code varchar2
                      ) return clob;

  function check_Receipt_Data(p_order_no varchar2, p_ios_product_code varchar2,p_date date default sysdate) return boolean;
  function check_Receipt_Data_str(p_order_no varchar2, p_ios_product_code varchar2,p_date date default sysdate) return varchar2;

end BSM_IOS_GATEWAY_DEV;
/

