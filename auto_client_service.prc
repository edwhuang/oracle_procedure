create or replace procedure iptv.auto_client_service is
begin
  declare

    cursor c1 is
      Select c.serial_id client_id,a.rowid rid, 1 "delete"
        from acl.subscription   a,
             bsm_client_details c,
             bsm_package_mas    d
       where a."deleted" = 0
         and a."transaction_id" = c.pk_no
         and d.package_id = c.package_id
         and c.end_date + nvl(c.extend_days, nvl(d.ext_days, 0)) < sysdate
      union all
      Select c.serial_id client_id,a.rowid rid, 0 "delete"
        from acl.subscription   a,
          
             bsm_client_details c,
             bsm_package_mas    d
       where  a."deleted" = 1
         and a."transaction_id" = c.pk_no
         and d.package_id = c.package_id
         and c.start_date < sysdate
         and c.end_date + nvl(c.extend_days, nvl(d.ext_days, 0)) >= sysdate
         and c.status_flg = 'P'
     
      union all
      Select c.serial_id client_id,a.rowid rid, 1 "delete"
        from acl.subscription   a,
             bsm_client_details c,
             bsm_package_mas    d
       where a."deleted" = 0
         and a."transaction_id" = c.pk_no
         and d.package_id = a."package_id"
         and c.start_date > sysdate
         and c.start_date <= to_date('2099/12/31', 'YYYY/MM/DD')
         and c.status_flg = 'P'
         and c.serial_id = '2A0060E2B4C75055';
         
    cursor c2(p_client_id varchar2) is
      Select c.serial_id client_id,a.rowid rid, 1 "delete"
        from acl.subscription   a,
             bsm_client_details c,
             bsm_package_mas    d
       where a."deleted" = 0
         and a."transaction_id" = c.pk_no
         and d.package_id = c.package_id
         and c.end_date + nvl(c.extend_days, nvl(d.ext_days, 0)) < sysdate
         and c.serial_id=p_client_id
      union all
      Select c.serial_id client_id,a.rowid rid, 0 "delete"
        from acl.subscription   a,
          
             bsm_client_details c,
             bsm_package_mas    d
       where  a."deleted" = 1
         and a."transaction_id" = c.pk_no
         and d.package_id = c.package_id
         and c.start_date < sysdate
         and c.end_date + nvl(c.extend_days, nvl(d.ext_days, 0)) >= sysdate
         and c.status_flg = 'P'
         and c.serial_id=p_client_id
     
      union all
      Select c.serial_id client_id,a.rowid rid, 1 "delete"
        from acl.subscription   a,
             bsm_client_details c,
             bsm_package_mas    d
       where a."deleted" = 0
         and a."transaction_id" = c.pk_no
         and d.package_id = a."package_id"
         and c.start_date > sysdate
         and c.start_date <= to_date('2099/12/31', 'YYYY/MM/DD')
         and c.status_flg = 'P'
         and c.serial_id = '2A0060E2B4C75055'
         and c.serial_id=p_client_id;
    

    v_msg varchar2(1024);
  begin
    for i in c1 loop
      for j in c2(i.client_id) loop
        update acl.subscription c
           set "deleted" = j."delete"
         where rowid = j.rid;
        commit;
      v_msg := bsm_cdi_service.refresh_client(j.client_id,'purchase_msgb_queue');
      bsm_client_service.refresh_bsm_client(j.client_id,'purchase_msgb_queue');
      end loop;
    end loop;
  end;
  
  declare
    cursor c1 is
      Select a.pk_no, a.serial_id
        from bsm_client_details a, bsm_package_mas b
       where a.package_id = b.package_id
         and a.status_flg = 'P'
         and a.start_date <= sysdate
         and nvl(a.extend_days, nvl(b.ext_days, 0)) > 0
         and a.end_date > sysdate - 10
         and not exists
       (select 'x'
                from bsm_recurrent_view_2 t2
               where t2.status_flg = 'P'
                 and t2.client_id = a.serial_id
                 and t2.package_cat_id1 = b.package_cat_id1);
  begin
    for i in c1 loop
      begin 
      update bsm_client_details a
         set a.extend_days = 0
       where a.pk_no = i.pk_no;
      commit;
      bsm_client_service.Set_subscription_r(null, i.serial_id,'N');
      bsm_client_service.refresh_bsm_client(i.serial_id,'purchase_msgb_queue');
      exception
        when others then null;
      end;
    end loop;
  end;

end;
/

