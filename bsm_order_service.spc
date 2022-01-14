create or replace package iptv.BSM_ORDER_SERVICE is
  dup_purchase_exception exception;
  dup_buy                exception;
  credit_exception       exception;
  stop_product           exception;
  product_error          exception;
  over_buy               exception; -- 買超過
  function create_order(p_order varchar2) return varchar2;
  function get_string(jsonObject json, path varchar2) return varchar2;

end BSM_ORDER_SERVICE;
/

