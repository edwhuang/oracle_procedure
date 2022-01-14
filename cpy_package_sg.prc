create or replace procedure iptv.cpy_package_sg(old_package_id varchar2,new_package_id varchar2) as
begin

insert into bsm_package_sg(package_id,software_group,status_flg,version,version_end)
select new_package_id,software_group,status_flg,version,version_end
from  iptv.bk_bsm_package_sg
where package_id=old_package_id;
commit;
end;
/

