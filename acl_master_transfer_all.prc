CREATE OR REPLACE PROCEDURE IPTV."ACL_MASTER_TRANSFER_ALL" is

  v_msg clob;
begin
null;
  /*
  declare
    v_char varchar2(32);
    cursor c1 is
      select item_id object_id,
             DECODE(b.cal_type, 'T', 'PACKAGE', 'I', 'PACKAGE', 'GROUP') type,
             null deleted,
             sysdate last_modified
        from mid_cms_item a, bsm_package_mas b
       where a.package_id = b.package_id(+)
      union all
      select package_id object_id,
             'PACKAGE' type,
             null deleted,
             sysdate last_modified
        from bsm_package_mas
      union all
      select asset_id object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from mid_cms_asset
      union all
      Select asset_id object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from mid_kod_songdata
      union all
      select content_id object_id,
             'GROUP' type,
             null deleted,
             sysdate last_modified
        from mid_cms_content
      union all
      select 'WE2011021001' object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from dual
      union all
      select 'KOD' object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from dual
      union all
      select app_id object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from bsm_application_mas
      union all
      -- CONTENT_ID & ASSET_ID
      select distinct content_id object_id,
                      'GROUP' type,
                      null deleted,
                      sysdate last_modified
        from ccc_program_asset
       where ACTIVE_FLG = 'Y'
        or content_id='vod10713-000000M001'
      union all
      select asset_id object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from ccc_program_asset
       where ACTIVE_FLG = 'Y'
        or content_id='vod10713-000000M001'
      -- add channel
      union all
      select cdn_name object_id,
             'ASSET' type,
             null deleted,
             sysdate last_modified
        from bsm_channel_list
      union all
                     select c.package_id||a.content_id "object_id",
             'PACKAGE' "type",
             null deleted,
             sysdate last_modified
        from ccc_program_asset a,bsm_acl_details b,bsm_package_mas c
       where ACTIVE_FLG = 'Y'
       and b.cat_id=a.category_id
       and c.package_id=b.acl_id
       and c.cal_type='T'
            union all
      Select cdn_code,'ASSET' type,null deleted,
             sysdate last_modified from mid_cms_vod_channel a;       
 
      
  begin
 
    for c1rec in c1 loop
      begin
        select 'x'
          into v_char
          from acl.object
         where "object_id" = c1rec.object_id;

      exception
        when no_data_found then
          insert  into acl.object
            ("object_id", "type", "deleted", "last_modified")
          values
            (c1rec.object_id,
             c1rec.type,
             c1rec.deleted,
             c1rec.last_modified);
        when others then
          dbms_output.put_line(SQLERRM);

      end;
      commit;
    end loop;
  end;

  declare
    v_char varchar2(32);
    -- N: no_token - free for everyone ;
    -- P: premium - no ads ;
    -- Y or null : authenticated - only free for litv accounts ;
    cursor c1 is
      select package_id "package_id",
             acl_duration "duration",
             acl_quota "quota",
             acl_level "level",
             sysdate "last_modified",
             throttled "throttled",
             a.acl_period "period",
             a.acl_duration "period_duration",
             decode(nvl(a.acl_type, 'Y'),
                    'N',
                    'no_token',
                    'P',
                    'premium',
                    'authenticated') "acl_token",
             decode(nvl(a.acl_type, 'Y'), 'N', 1, 1) "ad"
        from bsm_package_mas a
       where a.cal_type in ('P')
      union all
      select item_id "package_id",
             acl_duration "duration",
             acl_quota "quota",
             acl_level "level",
             sysdate "last_modified",
             throttled "throttled",
             a.acl_period "period",
             a.acl_duration "period_duration",
             decode(nvl(a.acl_type, 'Y'),
                    'N',
                    'no_token',
                    'P',
                    'premium',
                    'authenticated') "acl_token",
             decode(nvl(a.acl_type, 'Y'), 'N', 1, 1) "ad"
        from bsm_package_mas a, mid_cms_item b
       where b.package_id = a.package_id
         and a.cal_type in ('T', 'I')
       union all
           select c.package_id||a.content_id "package_id",
              acl_duration "duration",
             acl_quota "quota",
             acl_level "level",
             sysdate "last_modified",
             throttled "throttled",
             c.acl_period "period",
             c.acl_duration "period_duration",
            
                    'premium'              "acl_token",
             1 "ad"
        from ccc_program_asset a,bsm_acl_details b,bsm_package_mas c
       where ACTIVE_FLG = 'Y'
       and b.cat_id=a.category_id
       and c.package_id=b.acl_id
       and c.cal_type='T'
       and c.status_flg='P';
    

  begin

    for c1rec in c1 loop
      begin
        select 'x'
          into v_char
          from acl.package
         where "package_id" = c1rec."package_id";

      exception
        when no_data_found then
          insert  into acl.package
            ("package_id",
             "duration",
             "quota",
             "level",
             "last_modified",
             "deleted",
             "throttled",
             "period",
             "period_duration",
             "token",
             "ad")
          values
            (c1rec."package_id",
             c1rec."duration"*100,
             c1rec."quota",
             c1rec."level",
             c1rec."last_modified",
             null,
             c1rec."throttled",
             c1rec."period",
             c1rec."period_duration"*100,
             c1rec."acl_token",
             c1rec."ad");
        when others then
          dbms_output.put_line(SQLERRM);
      end;
      commit;

    end loop;
  end;
  */
/*
  declare
    v_char varchar2(32);
    cursor c1 is
     select * from (
      Select CMS_util.get_id(mas_pk_no, type) "parent_id",
             cms_util.get_id(a.detail_pk_no, type) "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_item_rel a
       where type in ('G', 'A')
         and cms_util.get_id(a.detail_pk_no, type) is not null
      union all -- CCC_PROGRAM_ASSET
      select content_id "parent_id",
             asset_id "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from ccc_program_asset
       where ACTIVE_FLG = 'Y'
         and content_type <> 'channel'
      union all
      Select b.package_id "parent_id",
             cms_util.get_id(a.mas_pk_no) "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_item_rel a, mid_cms_item b, bsm_package_mas c
       where type = 'P'
         and b.package_id = c.package_id
         and c.cal_type in 'P'
         and a.detail_pk_no = b.pk_no 
          and c.status_flg='P'
          and exists(select 'x' from mid_content_list d where d.content_id=cms_util.get_id(a.mas_pk_no) and d.status_flg='P')
      union all
      Select b.item_id "parent_id",
             cms_util.get_id(a.mas_pk_no) "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_item_rel a, mid_cms_item b, bsm_package_mas c
       where type = 'P'
         and b.package_id = c.package_id
         and c.cal_type in ('T', 'I')
         and a.detail_pk_no = b.pk_no
      union all
      Select c.package_id "parent_id",
             b.asset_id "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_kod_songdata b, bsm_package_mas c
       where c.package_cat_id1 = 'KOD'
      union all
      Select c.package_id "parent_id",
             'KOD' "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from bsm_package_mas c
       where c.package_cat_id1 = 'KOD'
      union all
      Select 'FREE_FOR_CLEINT_ACTIVED' "parent_id",
             'WE2011021001' "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from dual
      union all
      Select b.package_id "parent_id",
             b.app_id "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from bsm_application_dtls b
       where status_flg = 'P'
      union all
    
      select distinct a.acl_id "parent_id",
                      content_id "child_id",
                      to_date('20111231', 'YYYYMMDD') "expiration",
                      null "deleted",
                      sysdate "last_modified"
        from bsm_acl_details a, ccc_program_asset b
       where a.cat_id = b.category_id
         and b.active_flg = 'Y'
     union all
       select distinct a.acl_id "parent_id",
                      content_id "child_id",
                      to_date('20111231', 'YYYYMMDD') "expiration",
                      null "deleted",
                      sysdate "last_modified"
        from bsm_acl_details a, mid_content_list b
       where a.cat_id = b.cat
         and a.status_flg = 'P'
         and b.status_flg ='P'

      union all
       select acl_id "parent_id",
             b.content_id "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from bsm_acl_items a, ccc_program_asset b
       where a.serial_id = b.serial_id
         and a.content_id is null
      union all 
      select acl_id "parent_id",
             content_id "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from bsm_acl_items
       where content_id is not null
       and method='add'
      union all 
      select acl_id "parent_id",
             content_id "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from bsm_acl_items
       where content_id is not null
       and method='add'
       union all
       select c.package_id||a.content_id "parent_id",
                  a.content_id "parent_id",
                  to_date('20111231', 'YYYYMMDD') "expiration",
                  null "deleted",
                  sysdate "last_modified"
        from ccc_program_asset a,bsm_acl_details b,bsm_package_mas c
       where ACTIVE_FLG = 'Y'
       and b.cat_id=a.category_id
       and c.package_id=b.acl_id
       and c.cal_type='T'
      union all
      select a.package_id "parent_id",
             b.cdn_name "child_id",
             to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from bsm_package_mas a, bsm_channel_list b
       where (instr(replace(replace(b.content_group_ids,'CHANNEL4G_ELTA','CH4G_ELTA'),'CHANNEL,','CHANNEL_LITV,'),decode(a.package_cat_id1,'CHANNEL4G_ELTA','CH4G_ELTA','CHANNEL','CHANNEL_LITV',a.package_cat_id1)) > 0
         or (a.package_id in ('FREE00','FREE01') and instr(b.content_group_ids,'FTV01')>0)
            )
         and a.package_id not in ('FREE4G','CHCPBL','CHCPBLG03','CHCPBLG12','CHCPBLC90')
      union all
        Select package_id  "parent_id",cdn_code "child_id",
       to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_vod_channel a,bsm_package_mas b 
        where a.acl_type=0
        and b.package_cat_id1 = 'CHANNEL'
        union all
     Select package_id  "parent_id",cdn_code "child_id",
       to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_vod_channel a,bsm_package_mas b 
        where (a.acl_type=3)
          and b.package_cat_id1 like 'FREE%'        
  union all
       Select package_id  "parent_id",cdn_code "child_id",
       to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_vod_channel a,bsm_package_mas b 
        where (a.acl_type=0 or a.acl_type=2)
          and (b.package_cat_id1 like 'VOD_CHANNEL%'or b.package_cat_id1 = 'CHANNEL' or b.package_cat_id1 = 'CHANNEL_A' or b.package_cat_id1 = 'CHANNEL_B')
      union all
       Select package_id  "parent_id",cdn_code "child_id",
       to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_vod_channel a,bsm_package_mas b 
        where (a.acl_type = 1 or a.acl_type = 2)
                  and ( b.package_id in ('FREE05','FREE95') )  
    union all  
             Select package_id  "parent_id",cdn_code "child_id",
       to_date('20111231', 'YYYYMMDD') "expiration",
             null "deleted",
             sysdate "last_modified"
        from mid_cms_vod_channel a,bsm_package_mas b 
        where (a.acl_type = 1 or a.acl_type = 2)

   and   ((b.package_cat_id1 like 'S_VOD_CHANNEL%' or
        b.package_cat_id1 like 'CHANNEL_A' or
        b.package_cat_id1 like 'VCHANNEL%' or
       b.package_cat_id1 = 'VOD_CHANNEL_DELUX' or
        b.package_cat_id1 = 'VOD_CHANNEL_2' or
       b.package_cat_id1 = 'VOD_CHANNEL_RB5' or
       b.package_cat_id1 = 'VOD_CHANNEL_RB6') or
       (sysdate > to_date('20170607', 'YYYYMMDD') and
       b.package_cat_id1 in
       ('CHANNEL', 'VOD_CHANNEL', 'VOD_CHANNEL_RB1', 'VOD_CHANNEL_RB2', 'VOD_CHANNEL_RB3', 'VOD_CHANNEL_RB4') and
       ( b.system_type = 'BUY' or b.package_id ='CHG003') and b.status_flg = 'P' and  b.package_id not in ('WDS001','WD0006','WD000S')))             
         )
         group by "parent_id","child_id","expiration","deleted","last_modified";

  begin
        insert into sys_process_on(on_off) values ('on');
    commit;
    
    execute immediate 'truncate table acl.relationship';
  

    for c1rec in c1 loop
      begin

            insert /*+ Append * into acl.relationship
              ("parent_id",
               "child_id",
               "expiration",
               "deleted",
               "last_modified")
            values
              (c1rec."parent_id",
               c1rec."child_id",
               c1rec."expiration",
               c1rec."deleted",
               c1rec."last_modified");
       exception
         when others then null;
      end;

    end loop;
    commit;
    

  end;
  
      

        update  acl.relationship t
set t."deleted"=1
 where ( t."parent_id" like 'FREE%' and t."parent_id" not in ('FREE05','FREE95')) and t."child_id" in (
Select a.content_id
  from ccc_program_asset a where a.serial_no in (select distinct serial_no from ccc_free_serialno a where a.start_date <= trunc(sysdate) and a.end_date >= trunc(sysdate) and a.method='erase')
 and a.active_flg='Y' and ( a.episode_no >1 or a.serial_no=34466 or a.serial_no = 38979) )
; 

update  acl.relationship t
  set t."deleted" = null
 where t."parent_id" like 'FREE%' and t."child_id" in (
Select a.content_id
  from ccc_program_asset a where (a.serial_no,a.episode_no) in (select serial_no,a.episode_no from ccc_free_serialno a where a.start_date <= trunc(sysdate) and a.end_date >= trunc(sysdate) and a.method='add' and serial_no = 21543
group by serial_no,a.episode_no)
 and a.active_flg='Y'
 and a.serial_no= 21543);

update  acl.relationship t
  set t."deleted" = null
 where t."parent_id" like 'FREE%' and t."child_id" in (
Select a.content_id
  from ccc_program_asset a
 where (a.serial_no, a.episode_no) in
       (select serial_no, a.episode_no
          from ccc_free_serialno a
         where 1=1
          and a.start_date <= trunc(sysdate) 
          and a.end_date >= trunc(sysdate)
           and a.method = 'add'
           and a.episode_no is not null
         group by serial_no, a.episode_no)
   and a.active_flg = 'Y'
   and ( a.episode_no >1 or a.serial_no=34466 or a.serial_no = 38979) );
   
   update  acl.relationship t
  set t."deleted" = null
 where t."parent_id" like 'FREE%' and t."child_id" in (
   Select a.content_id
  from ccc_program_asset a
 where (a.serial_no) in
       (select serial_no
          from ccc_free_serialno a
         where 1=1
          and a.start_date <= trunc(sysdate) 
          and a.end_date >= trunc(sysdate)
           and a.method = 'add'
           and a.episode_no is null
         group by serial_no, a.episode_no)
   and a.active_flg = 'Y'
   and a.episode_no > 1);
  commit;
  
   begin
delete  acl.relationship where "parent_id" in ('FREE94','FREE07') and "child_id" in (
'VOD00123688T001',
'VOD00124167',
'VOD00123745',
'VOD00123746',
'VOD00123747',
'VOD00123748',
'VOD00123749',
'VOD00123750',
'VOD00123751',
'VOD00123752',
'VOD00123753',
'VOD00123754',
'VOD00123755',
'VOD00123756');

delete acl.relationship where "parent_id" in ('FREE00','FREE01','FREE98','FREE99') and "child_id" in (
Select distinct content_id from iptv.ccc_program_asset a where a.active_flg='Y' and (content_id like 'VOD00071222T0%' or content_id like 'VOD00123688T%' ));

if (sysdate < to_date('2018/10/16','YYYY/MM/DD') )then

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
Select 'FREE00',content_id,to_date('2011/12/31','YYYY/MM/DD'),null,sysdate from iptv.ccc_program_asset a where a.active_flg='Y' and (content_id like 'VOD00071222T0%' or content_id like 'VOD00123688T%' )
group by content_id 
union all
Select 'FREE01',content_id,to_date('2011/12/31','YYYY/MM/DD'),null,sysdate from iptv.ccc_program_asset a where a.active_flg='Y' and (content_id like 'VOD00071222T0%' or content_id like 'VOD00123688T%' )
group by content_id 
union all
Select 'FREE98',content_id,to_date('2011/12/31','YYYY/MM/DD'),null,sysdate from iptv.ccc_program_asset a where a.active_flg='Y' and (content_id like 'VOD00071222T0%' or content_id like 'VOD00123688T%' )
group by content_id 
union all
Select 'FREE99',content_id,to_date('2011/12/31','YYYY/MM/DD'),null,sysdate from iptv.ccc_program_asset a where a.active_flg='Y' and (content_id like 'VOD00071222T0%' or content_id like 'VOD00123688T%' )
group by content_id ;


 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123688T001',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123688T001',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00124167',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00124167',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123745',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123745',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123746',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123746',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);


 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123747',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123747',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123748',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123748',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123749',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123749',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123750',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123750',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123751',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123751',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);


 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123752',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123752',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123753',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123753',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123754',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123754',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);

 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123755',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123755',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);


 insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE94','VOD00123756',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
insert into acl.relationship ("parent_id","child_id","expiration","deleted","last_modified")
values ('FREE07','VOD00123756',to_date('2011/12/31','YYYY/MM/DD'),null,sysdate);
commit;
end if;

end;

   begin
     delete  acl.relationship where "parent_id" like 'FREE%' and "child_id"='4gtv-4gtv103';


     delete  acl.relationship where ("parent_id" like 'FREE%' or "parent_id" = 'ST0001') and "child_id"='litv-vch2-appfree';


     delete  acl.relationship where "parent_id"  like 'FREE%' and "child_id"='4gtv-4gtv109';

 commit;
 end;

  
  declare
    v_cnt number(16);
  begin
    select count(*) into v_cnt from acl.relationship;
    if v_cnt>200000 then
     null;
 -- v_msg := cache_metadata_2;
    end if;
  end;

  
      delete sys_process_on;
    commit;
*/

end;
/

