CREATE OR REPLACE PROCEDURE IPTV."SYN_CLIENT_CSTATUS"
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
      declare
       v_vodapp varchar2(32);
       v_sg varchar2(64);
       v_msg varchar2(1024);
       cursor c2 is select a.software_group from mfg_iptv_mas a where a.mac_address=c1rec.mac_address;
      begin
        for c2rec in c2 loop
            select vodapp into v_vodapp from mfg_softwaregroup_mas b where b.software_group=c2rec.software_group;
            if v_vodapp is not null then
               v_msg:=bsm_cdi_service.set_vodapp(c1rec.mac_address,v_vodapp);
            end if;

        end loop;
      exception
        when no_data_found then null;
      end;
  end loop;
end;
/

