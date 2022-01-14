CREATE OR REPLACE PACKAGE IPTV.TSTAR_ORDER_SERVICE_2 is
  lost_data       exception;
  order_not_found exception;
  no_client_found exception;
  dup_order       exception;
  function tstar_order(p_order             varchaR2,
                       p_start_form_active varchar2 default null)
    return varchar2;
    function tstar_order2(p_order             varchaR2,
                       cancel_date date default null)
    return varchar2;
END TSTAR_ORDER_SERVICE_2;
/

