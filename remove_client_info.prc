create or replace procedure iptv.remove_client_info(old_client_id varchar2,new_client_id varchar2) is
 
begin
  update
 bsm_recurrent_mas a 
 set a.client_id=new_client_id
 where a.client_id=old_client_id;
 
update
  bsm_purchase_mas b
  set b.serial_id=new_client_id
where b.serial_id=old_client_id;


update 
  bsm_client_details c
  set c.serial_id=new_client_id,
      c.mac_address=new_client_id
where  c.serial_id=old_client_id
or c.mac_address=old_client_id;


commit;

bsm_client_service.Set_subscription(null,new_client_id);
  
end remove_client_info;
/

