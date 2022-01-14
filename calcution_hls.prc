create or replace procedure iptv.calcution_hls is
begin
  declare 
  cursor c1 is
   select rowid rid,a.* from bsm_client_event_log a where  event_time >= to_date(to_char(sysdate -25,'YYYYMM')||'01','YYYYMMDD') and package_id is null ;
  dtl_pk_no number(16);
  cursor c2(dtl_pk_no number) is select package_id from bsm_client_details x where x.pk_no = dtl_pk_no;
begin
  for i in c1 loop 
    dtl_pk_no := bsm_cdi_service.update_bsm_detail(i.client_id,replace(i.client_read_access,'.mp4',''),i.event_time) ;
    if dtl_pk_no is not null then
      for j in c2(dtl_pk_no) loop
        update bsm_client_event_log a
         set a.report_type='P',
         a.package_id=j.package_id,
         a.detail_pk_no=dtl_pk_no
         where rowid= i.rid;
         commit;
      end loop;
    end if;
    
  end loop;
end;

declare
  begin
    delete from IPTV.BI_FIVOD001
     where trunc(event_time) >= to_date(to_char(sysdate -25,'YYYYMM')||'01','YYYYMMDD') - 1;
    insert into IPTV.BI_FIVOD001
      (event_ym,
       event_time,
       package_cat1,
       client_read_access,
       asset_name,
       provide_acc,
       owner_phone,
       client_id,
       package_id,
       provider_name,
       ref1,
       report_type,
       bitrate)
      select to_char(a.event_time, 'yyyymm') event_ym,
             a.event_time,
             g.package_cat1,
             a.client_read_access,
             cms_util.get_asset_name(replace(a.Client_Read_Access, '.mp4', '')) asset_name,
             c.provide_acc,
             b.owner_phone,
             a.client_id,
             a.package_id,
             d.provider_name,
             f.ref1,
             a.report_type,
             decode(sign(instr(replace(a.Client_Read_Access, '.mp4', ''), 'K') - 3),
                    -1,
                    '800K',
                    substr(replace(a.Client_Read_Access, '.mp4', ''),
                           instr(replace(a.Client_Read_Access, '.mp4', ''), 'K') - 3,
                           4)) BITRATE
        from bsm_client_event_log a
        left join iptv.bsm_client_mas b
          on a.client_id = b.mac_address
        left join iptv.mfg_iptv_mas e
          on a.client_id = e.mac_address
        left join iptv.mfg_softwaregroup_mas f
          on e.software_group = f.software_group
       inner join mid_cms_asset_list_v c --VOD asset 主檔
          on replace(a.client_read_access, '.mp4', '') = c.asset_id
        left join mid_cms_content_provider d
          on c.provide_acc = d.provider_id
        left join iptv.bsm_package_mas g
          on a.package_id = g.package_id
       where a.event_name = 'E_PLAY'
         and a.play_time >= 300 ---VOD 5min
         and c.provide_acc <> 'HIKIDS' ---排除音象
         and a.package_id not in
             (select package_id
                from bsm_package_mas
               where report_type in ('T', 'N'))
         and TRUNC(a.event_time) >= to_date(to_char(sysdate -25,'YYYYMM')||'01','YYYYMMDD') - 1;

    commit;

  end;
  
end;
/

