CREATE OR REPLACE PACKAGE IPTV."CMS_UTIL" is

  -- Author  : EDWARD.HUANG
  -- Created : 2010/11/8 下午 03:46:51
  -- Purpose :

  -- Public type declarations
  -- type <TypeName> is <Datatype>;

  -- Public constant declarations
  -- <ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  -- <VariableName> <Datatype>;

  -- Public function and procedure declarations
  function get_id(p_pk_no number, p_item_type varchar2 default null)
    return varchar2;
  function get_content_title(p_content_id varchar2) return varchar2
    deterministic;
  function get_pk_no(p_id string, p_item_type varchar2 default null)
    return varchar2;
  function get_content_id(p_asse_pk_no number) return varchar2 deterministic;
  function get_content_id(p_id varchar2) return varchar2 deterministic;
  function get_asset_name(p_asset_id varchar2) return varchar2;
  function get_active_package(p_mac_address varchar2,
                              p_play_time   date,
                              p_asset_id    varchar2) return varchar2;
  function get_content_supply(p_content_id varchar2) return varchar2;
  function get_content_id_v2(p_id varchar2) return varchar2;
  function get_logo(p_id varchar2) return varchar2;

  -- CMS Manager API
  procedure gen_content_id(src_no       varchar2,
                           p_pk_no      out number,
                           o_content_id out varchar2);
  procedure gen_item_id(src_no       varchar2,
                        p_content_id varchar2,
                        p_item_id    varchar2,
                        p_pk_no      out number,
                        o_item_id    out varchar2);
  procedure gen_asset_id(src_no     varchar2,
                         p_item_id  varchar2,
                         p_HD_SD    varchar2,
                         p_pk_no    out number,
                         o_asset_id out varchar2);
  procedure get_subtilt_id(src_no        varchar2,
                           p_asset_id    varchar2,
                           p_pk_no       out number,
                           o_subtitle_id out varchar2);

end CMS_UTIL;
/

