CREATE OR REPLACE PACKAGE BODY IPTV."BSM_RECURRENT_UTIL_PC" is
  function get_service_end_date(p_cat varchar2, p_client_id varchar2)
    return date is
    v_result    date;
    v_client_id varchar2(32);
  begin
    v_client_id := upper(p_client_id);

    select max(a.end_date) -3
      into v_result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or (end_date >= sysdate))
       and b.package_cat_id1 = p_cat;
    return v_result;
  end;

  function check_access(p_cat varchar2, p_client_id varchar2) return varchar is
    v_result    varchar2(32);
    v_client_id varchar2(32);
  begin
    v_client_id := upper(p_client_id);

    select 'Y'
      into v_result
      from bsm_client_details a, bsm_package_mas b
     where mac_address = v_client_id
       and a.package_id = b.package_id
       and a.status_flg = 'P'
       and (start_date is null or
           (start_date <= sysdate and end_date >= sysdate))
       and b.package_cat_id1 = p_cat;
    return v_result;
  end;

  function check_recurrent(p_package varchar2, p_client_id varchar2) return varchar2 is
    v_result varchar2(32);
  begin
    Select 'R' into v_result
     from bsm_purchase_mas a,bsm_purchase_item b
    where a.status_flg='Z' and a.recurrent='R' and a.serial_id=p_client_id
    and b.mas_pk_no=a.pk_no and b.package_id = p_package
    and rownum <=1 ;
    return v_result;
  exception
    when no_data_found then return 'O';
  end;
end;
/

