create or replace procedure iptv.crt_purchase_ios(p_paytype          varchar2,
                                             p_client_id        varchar2,
                                             p_device_id        varchar2,
                                             p_package_id       varchar2,
                                             p_ios_org_trans_id varchar2,
                                             p_ios_trans_id     varchar2,
                                             p_pk_no            number,
                                             p_mas_no           in out varchar2,
                                             p_purchase_date    varchar2,
                                             p_expires_date     varchar2,
                                             is_intro_offer     varchar2 default null,
                                             sw_version         varchar2 default null,
                                             p_options          varchar2 default null,
                                             from_client        varchar2 default null) is
  v_char            varchar2(32);
  v_src_mas_no      varchar2(32);
  purchase_pk_no    number(16);
  v_r_pk_no         number(16);
  intro_offer       number(16);
  intro_offer_desc  varchar2(32);
  org_client_id     varchar2(32);
  org_purchase_date date;
  org_package_id    varchar2(32);
  v_method          varchar2(32);
  v_package_id      varchar2(64);
  v_no_org          varchar2(2);
  v_loc_exp_date    date;
  v_loc_pur_date    date;
  v_price           number(16,3);
  ios_package_error exception;

begin

      /* Enqueue to msg_queue: */
DECLARE
   enqueue_options     dbms_aq.enqueue_options_t;
   message_properties  dbms_aq.message_properties_t;
   message_handle      RAW(16);
   message             iptv.ios_purchase_msg;

BEGIN
   message := ios_purchase_msg(0,
                                       p_paytype,
                                             p_client_id,
                                             p_device_id,
                                             p_package_id,
                                             p_ios_org_trans_id ,
                                             p_ios_trans_id,
                                             p_pk_no ,
                                             p_mas_no ,
                                             p_purchase_date ,
                                             p_expires_date,
                                             is_intro_offer ,
                                             sw_version ,
                                             p_options ,
                                             from_client);

   dbms_aq.enqueue(queue_name => 'ios_purchase_que',
         enqueue_options      => enqueue_options,
         message_properties   => message_properties,
         payload              => message,
         msgid                => message_handle);

   COMMIT;
end;


end;
/

