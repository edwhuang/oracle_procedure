create or replace procedure iptv.cms_vip_process(p_series_id number default null) is
begin
declare
  cursor c1 is select * from CMS_SPECIAL_SERIES a where (a.is_staging=1 and a.status=1 and p_series_id is null) or (a.series_id=p_series_id);
  cursor c2 is select * from IPTV.CMS_SPECIAL_EPISODE a where ( a.status=1 and p_series_id is null) or (a.series_id=p_series_id);
begin
  delete iptv.ccc_free_serialno b where b.serial_no in
  (select a.series_id from CMS_SPECIAL_SERIES a where (a.is_staging=1 and p_series_id is null) or ( a.series_id=p_series_id));
  delete iptv.ccc_free_serialno b where b.serial_no in
  (select a.series_id from IPTV.CMS_SPECIAL_EPISODE a where ( a.status=1 and p_series_id is null) or (a.series_id=p_series_id));
  for i in c1 loop
    if i.type = 0 then
      -- 免費 電視第一集免費
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE00',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE01',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE98',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE99',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE97',i.SEASON,1,i.start_date,i.end_date);
    elsif i.type = 1 then
      begin
   
      -- 第一集免費
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE00',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE01',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE97',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE98',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE99',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE00',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE01',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE97',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE98',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE99',i.SEASON,1,i.start_date,i.end_date);
    exception
      when others then 
       dbms_output.put_line(i.SERIES_ID); 
    end;
    elsif i.type = 3 then
      -- 第一集免費
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE00',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE01',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE97',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE98',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE99',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE00',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE01',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE97',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE98',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE99',i.SEASON,1,i.start_date,i.end_date);
            insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE00',i.SEASON,2,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE01',i.SEASON,2,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE97',i.SEASON,2,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE98',i.SEASON,2,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE99',i.SEASON,2,i.start_date,i.end_date);
            insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE00',i.SEASON,3,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE01',i.SEASON,3,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE97',i.SEASON,3,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE98',i.SEASON,3,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE99',i.SEASON,3,i.start_date,i.end_date);
    elsif i.type = 2 then
    -- 全集付費
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE00',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE01',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE97',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE98',i.SEASON,null,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE99',i.SEASON,null,i.start_date,i.end_date);
     insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE00',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE01',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE97',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE98',i.SEASON,1,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE99',i.SEASON,1,i.start_date,i.end_date);
    end if;
   end loop;

   for i in c2 loop
     if i.is_paid = 0 then
       -- 各集免費不加 FREE97
      delete ccc_free_serialno where serial_no=i.SERIES_ID and season_no=i.SEASON and episode_no=i.ep_number and method='add';
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE00',i.SEASON,i.ep_number,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE01',i.SEASON,i.ep_number,i.start_date,i.end_date);
    --  insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
    --  values(i.SERIES_ID,'add','FREE97',i.SEASON,i.ep_number,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE98',i.SEASON,i.ep_number,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'add','FREE99',i.SEASON,i.ep_number,i.start_date,i.end_date);
     elsif i.is_paid = 1 then
      delete ccc_free_serialno where serial_no=i.SERIES_ID and season_no=i.SEASON and episode_no=i.ep_number and method='erase';
                  insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE00',i.SEASON,i.ep_number,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE01',i.SEASON,i.ep_number,i.start_date,i.end_date);
     -- insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
     -- values(i.SERIES_ID,'erase','FREE97',i.SEASON,i.ep_number,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE98',i.SEASON,i.ep_number,i.start_date,i.end_date);
      insert into ccc_free_serialno(serial_no,method,acl_id,season_no,episode_no,start_date,end_date)
      values(i.SERIES_ID,'erase','FREE99',i.SEASON,i.ep_number,i.start_date,i.end_date);
     end if;
     end loop;
end;
 commit;
end;
/

