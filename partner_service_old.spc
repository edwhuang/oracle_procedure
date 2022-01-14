CREATE OR REPLACE PACKAGE IPTV.PARTNER_SERVICE_OLD is
  lost_data       exception;
  order_not_found exception;
  no_client_found exception;
  dup_order       exception;
  function PARTNER_ORDER_SERVICE(p_order             varchaR2,
                                 p_start_form_active varchar2 default null)
    return varchar2;
END PARTNER_SERVICE_OLD;
/

