create or replace procedure iptv.P_package_special is
begin
  declare
  cursor c1 is select * from bsm_package_special_setting where status_flg ='R' and start_date <= sysdate and end_date >=sysdate;
  cursor c2 is select * from bsm_package_special_setting where status_flg ='P' and end_date < sysdate;
  v_open boolean := false;
  v_close boolean := false;
begin
  for i in c1 loop
    if i.end_date >= sysdate then
      if i.type='PACKAGE' then

     update bsm_package_mas a
      set a.ref3=i.package_ref2,
      a.duration_by_day=nvl(i.days,a.duration_by_day)
      where a.package_id=i.src_id;
      end if;
     update bsm_package_special_setting
       set status_flg='P'
     where pk_no=i.pk_no;

     v_open := true;


    end if;
    commit;
  end loop;

  for i in c2 loop
    if i.end_date < sysdate then
            if i.type='PACKAGE' then
      update bsm_package_mas a
      set a.ref3=null,
      a.duration_by_day=nvl(i.org_days,a.duration_by_day)
      where a.package_id=i.src_id;
      end if;
     update bsm_package_special_setting
       set status_flg='Z'
     where pk_no=i.pk_no;

     v_close := true;

    end if;
    commit;
  end loop;

  if v_close or v_open then
   refresh_bsm;
  end if;
end;
end;
/

