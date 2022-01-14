CREATE OR REPLACE PROCEDURE IPTV."UPDATE_ACL_IPTV_MFG" is
 cursor c1 is select a.mac_address,a.software_group from mfg_iptv_mas a;
 v_group varchar2(64);
begin
  for c1rec in c1 loop
  begin
      select a.software_group into v_group from acl.mfg_iptv_mas a where mac_address = c1rec.mac_address;
      if v_group <> c1rec.software_group then
         update acl.mfg_iptv_mas a
            set a.software_group= c1rec.software_group
          where a.mac_address= c1rec.mac_address;
      end if;
  exception
     when no_data_found then
        insert into acl.mfg_iptv_mas(mac_address,software_group) values (c1rec.mac_address,c1rec.software_group);
  end;

  end loop;
    commit;
end;
/

