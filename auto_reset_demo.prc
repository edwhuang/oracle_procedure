CREATE OR REPLACE PROCEDURE IPTV.AUTO_RESET_DEMO is
  cursor c1 is select b.mac_address from mfg_dev_account_mas a,bsm_client_mas b
where a.reset_flg='7'
and b.owner_phone=a.owner_phone_no
and b.status_flg in ('A','W')
and b.mac_address in 
(select c.client_id from bsm_client_device_list c where 
c.activate_date <= sysdate-7 and c.status_flg='P');
  v_msg varchar2(1024);
BEGIN
  for c1rec in c1 loop
      v_msg := bsm_client_service.unactivate_client(0,c1rec.mac_address);
  end loop;
END AUTO_RESET_DEMO;
/

