CREATE OR REPLACE FUNCTION IPTV.GET_STOCK_BROKER (p_client_id varchar2) RETURN varchar2
is
  result varchar2(32);
  v_client_id varchar2(32);
begin


 v_client_id := upper(p_client_id);

 select stock_broker into result from bsm_client_mas where mac_address=v_client_id;
 return result;
exception
  when no_data_found then
    return 'N';

end;
/

