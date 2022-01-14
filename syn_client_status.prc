CREATE OR REPLACE PROCEDURE IPTV."SYN_CLIENT_STATUS"
is
  cursor c1 is select rowid rid,mac_address,status_flg from bsm_client_mas a where a.posted_cdi='N';
  v_msg varchar(2048);
begin
  for c1rec in c1 loop
       v_msg:=BSM_CDI_SERVICE.Set_Client_Status(c1rec.mac_address,c1rec.status_flg);
      update bsm_client_mas
         set posted_cdi = 'Y'
       where rowid = c1rec.rid;
      commit;
      if c1rec.status_flg = 'A' then
           v_msg:= BSm_CDI_SERVICE.refresh_client(c1rec.mac_address);
      end if;
  end loop;
end;
/

