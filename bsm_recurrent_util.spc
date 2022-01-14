CREATE OR REPLACE PACKAGE IPTV."BSM_RECURRENT_UTIL" is
  function get_next_pay_date(p_cat varchar2, p_client_id varchar2)
    return varchar2;
  function get_service_end_date(p_cat varchar2, p_client_id varchar2)
    return date;

  function get_service_end_date_full(p_cat varchar2, p_client_id varchar2)
    return date;

  function check_access(p_cat varchar2, p_client_id varchar2) return varchar;

  function check_recurrent(p_cat       varchar2,
                           p_client_id varchar2,
                           p_device_id varchar2 default null) return varchar2;
  function check_recurrent_2(p_cat       varchar2,
                             p_client_id varchar2,
                             p_device_id varchar2 default null)
    return varchar2;

  function stop_recurrent(p_client_id   varchar2,
                          p_purchase_id varchar2,
                          p_remark      varchar2,
                          p_actiondate  varchar2 default null)
    return varchar2;

  function auto_recurrent return varchar2;
  function auto_recurrent_newwebpay return varchar2;
  function cht_auto_recurrent return varchar2;
  function ios_auto_recurrent return varchar2;
  function tstar_recurrent return varchar2;
  function reset_recurrent_card(p_purchase_pk_no number,
                                p_card_no        varchar2,
                                p_expiry         varchar2,
                                p_cvc2           varchar2) return varchar2;
  function auto_recurrent_lipay return varchar2;
  function dup_recurrent return varchar2;

  function auto_recurrent_org return varchar2;

end;
/

