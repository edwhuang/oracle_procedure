CREATE OR REPLACE PACKAGE IPTV.BSM_PAYMENT_GATEWAY_DEV is

  -- Author  : EDWARD.HUANG
  -- Created : 2010/6/30 下午 03:15:02
  -- Purpose :

  -- Public type declarations
  -- type <TypeName> is <Datatype>;
  function AccePayment(p_order_no        varchar2,
                       p_amt             number,
                       p_card_type       varchar2,
                       p_card_no         varchar2,
                       p_card_expiry     varchar2,
                       p_cvc2            varchar2,
                       parameter_options varchar2 default null)
    return varchar2;
  function QueryOrders(p_order_no    varchar2) return varchar2;
end BSM_PAYMENT_GATEWAY_DEV;
/

