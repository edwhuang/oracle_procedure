create or replace package iptv.BSM_CHT_SERVICE_DEV2 is
  Jsonrpc_error Exception;

  function subscribe(p_purchase_pk_no number,
                     p_otpw           varchar2,
                     p_authority      varchar2,
                     p_actiondate     varchar2) return varchar2;
  function authorization(p_purchase_pk_no number,
                         p_otpw           varchar2,
                         p_authority      varchar2) return varchar2;
  function QuerySubscribe(p_purchase_pk_no number) return varchar2;
  function UnSubscribe(p_purchase_pk_no number,
                       p_action_date    varchar2 default null)
    return varchar2;
  function QueryATM(p_purchase_pk_no number) return varchar2;
  function Accounting(p_purchase_pk_no number,
                      p_otpw           varchar2,
                      p_authority      varchar2) return varchar2;

  function ATMMultiplebills(p_purchase_pk_no number, p_otpw varchar2)
    return varchar2;

end BSM_CHT_SERVICE_DEV2;
/

