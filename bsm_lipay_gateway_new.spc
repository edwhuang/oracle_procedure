CREATE OR REPLACE PACKAGE IPTV."BSM_LIPAY_GATEWAY_NEW" is

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
                       parameter_options varchar2 default null,
                       recurrent         varchar2 default 'once')
    return varchar2;
    function AccePayment_token(p_order_no        varchar2,
                       p_amt             number,
                       token            varchar2,
                       parameter_options varchar2 default null,
                       recurrent         varchar2 default 'once')
    return varchar2;
  function stopRecurrent(p_order_no varchar2) return varchar2;
  function changChargeDate(p_order_no varchar2, p_charg_date date)
    return varchar2;
  pay_error exception;

  function changeCreditCard(p_order_pk_no number,
                            card_number   varchar2,
                            card_expiry   varchar2,
                            csc           varchar2) return varchar2;
  function refund(p_order_no varchar2, refund_amt number) return varchar2;

end BSM_LIPAY_GATEWAY_NEW;
/

