CREATE OR REPLACE PACKAGE IPTV."BSM_CDI_SERVICE" is
  client_error exception;

  -- Author  : EDWARD.HUANG
  -- Created : 2011/4/11 下午 05:45:06
  -- Purpose : 

  -- Public type declarations
  --type <TypeName> is <Datatype>;

  -- Public constant declarations
  --  <ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  --  <VariableName> <Datatype>;

  -- Public function and procedure declarations
  function Set_Client_Status(p_serial_id varchar2, p_status_flg varchar2)
    return varchar2;
  function append_cdi_new_sub(p_serial_id varchar2,
                              package_id  varchar2,
                              start_date  date,
                              end_date    date,
                              tr_id       varchar2) return varchar2;

  function refresh_client_new(p_serial_id   varchar2,
                              refresh_queue varchar2 default null)
    return varchar2;
  function refresh_client(p_serial_id   varchar2,
                          refresh_queue varchar2 default null)
  
   return varchar2;
  function saveclientinfo(p_serial_id   varchar2,
                          refresh_queue varchar2 default null) return clob;
  function purgeNotice(p_serial_id   varchar2,
                       refresh_queue varchar2 default null) return clob;

  function cache_metadata return clob;
  function set_softgroupmap_to_cdi(p_group      varchar2,
                                   p_version    varchar2,
                                   p_apiversion varchar2 default '4')
    return varchar2;
  function syn_swvers return varchar2;
  function get_softgroup_from_cdi(p_serial_id varchar2,
                                  p_device_id varchar2 default null)
    return varchar2;

  function set_softgroup_to_cdi(p_serial_id varchar2,
                                p_group     varchar2,
                                p_device_id varchar2 default null)
    return varchar2;
  procedure process_softgroup;
  function get_acl(p_serial_id varchar2) return varchar2;
  function get_vodapp(p_serial_id varchar2) return varchar2;
  function set_vodapp(p_serial_id varchar2, p_vod varchar2) return varchar2;
  function list_swvers return varchar2;
  function cache_event(p_start_date date, p_end_date date) return varchar2;
  function update_bsm_detail(p_client_id  varchar,
                             p_asset_id   varchar2,
                             p_start_date date) return varchar2;

  function add_swver(p_name        varchar2,
                     p_crypto_type varchar2,
                     p_swkey       varchar2,
                     p_apiversion  varchar2 default '4',
                     p_url         varchar2 default '') return varchar2;
  function add_swver_stg(p_name        varchar2,
                         p_crypto_type varchar2,
                         p_swkey       varchar2,
                         p_apiversion  varchar2 default '4',
                         p_url         varchar2 default '') return varchar2;
  function add_swver_stg_2(p_name        varchar2,
                           p_crypto_type varchar2,
                           p_swkey       varchar2,
                           p_apiversion  varchar2 default '4',
                           p_url         varchar2 default '') return varchar2;

  procedure qick_refrash_event;
  function set_var(p_client_id varchar2, p_name varchar2, p_var varchar2)
    return varchar2;
  function get_cdi_info(p_client_id varchar2) return clob;

  function del_mobile_number_mapping(p_device_id     varchar2,
                                     p_mobile_number varchar2) return clob;
  FUNCTION get_device_current_swver(p_client_id varchar2,
                                    p_device_id varchar2) return varchar2;
  FUNCTION get_device_model(p_client_id varchar2, p_device_id varchar2)
    return varchar2;

  FUNCTION cdi_set_password(p_client_id varchar2, p_password varchar2)
    return clob;
end BSM_CDI_SERVICE;
/

