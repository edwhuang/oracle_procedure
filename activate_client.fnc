create or replace function iptv.activate_client(p_client_id varchar2,p_mac_address varchar2,p_phone varchar2,p_act_code varchar2) return varchar2 is
   result_p tbsm_result;
   in_client_info tbsm_client_info;
begin  -- Call the function
    in_client_info := NEW tbsm_client_info();
    if p_mac_address  is null then
      in_client_info.serial_id := null;
      in_client_info.mac_address := p_client_id;
    else
      in_client_info.serial_id := p_client_id;
      in_client_info.mac_address := p_mac_address ;
    end if;

    in_client_info.owner_phone := p_phone;
    in_client_info.activation_code := p_act_code ;
    result_p := bsm_client_service.Activate_client(in_client_info => in_client_info);

  return(Result_p.Result_Code);
end activate_client;
/

