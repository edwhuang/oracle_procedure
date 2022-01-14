CREATE OR REPLACE PACKAGE IPTV."BSM_RECURRENT_UTIL_PC" is
  function get_service_end_date(p_cat varchar2, p_client_id varchar2)
    return date;

  function check_access(p_cat varchar2, p_client_id varchar2) return varchar;

   function check_recurrent(p_package varchar2, p_client_id varchar2) return varchar2;
end;
/

