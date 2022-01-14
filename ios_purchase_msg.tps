create or replace type iptv.ios_purchase_msg as object (pk_no number(16),
p_paytype          varchar2(64),
                                             p_client_id         varchar2(64),
                                             p_device_id        varchar2(64),
                                             p_package_id        varchar2(64),
                                             p_ios_org_trans_id  varchar2(64),
                                             p_ios_trans_id      varchar2(64),
                                             p_pk_no             varchar2(64),
                                             p_mas_no           varchar2(64),
                                             p_purchase_date    varchar2(64),
                                             p_expires_date     varchar2(64),
                                             is_intro_offer    varchar2(64),
                                             sw_version        varchar2(64),
                                             p_options          varchar2(64),
                                             from_client        varchar2(64))
/

