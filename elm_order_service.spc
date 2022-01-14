CREATE OR REPLACE PACKAGE IPTV.ELM_ORDER_SERVICE is
  function elm_coupon_rollback(p_coupon_pk_no Number)
    return varchar2;
  procedure sp_elm_coupon_check;
END ELM_ORDER_SERVICE;
/

