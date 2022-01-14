create or replace procedure iptv.P_PREPARE_ACL_ITEM is
begin
  delete from bsm_acl_items;
/*   where acl_id in
         ('FREE00', 'FREE99', 'FREE01', 'FREE98', 'FREE97', 'WG0001'); */
  insert into bsm_acl_items

    
    select a.CONTENT_TITLE,
           a.CONTENT_ID,
           a.ASSET_ID,
           a.SERIAL_NO,
           a.SERIAL_ID,
           'FREE00' ACL_ID,
           'add'
      from ccc_program_asset a
     where a.content_id in ('VOD00030586', 'VOD00030587','VOD00031108','VOD00043698') -- 預告
       and a.active_flg = 'Y'
    union all
    select a.CONTENT_TITLE,
           a.CONTENT_ID,
           a.ASSET_ID,
           a.SERIAL_NO,
           a.SERIAL_ID,
           'FREE01' ACL_ID,
           'add'
      from ccc_program_asset a
     where a.content_id in ('VOD00030586', 'VOD00030587','VOD00031108','VOD00043698') -- 預告
       and a.active_flg = 'Y'
    union all
    select a.CONTENT_TITLE,
           a.CONTENT_ID,
           a.ASSET_ID,
           a.SERIAL_NO,
           a.SERIAL_ID,
           'FREE99' ACL_ID,
           'add'
      from ccc_program_asset a
     where a.content_id in ('VOD00030586', 'VOD00030587','VOD00031108','VOD00043698') -- 預告
       and a.active_flg = 'Y'
    union all
    select a.CONTENT_TITLE,
           a.CONTENT_ID,
           a.ASSET_ID,
           a.SERIAL_NO,
           a.SERIAL_ID,
           'FREE98' ACL_ID,
           'add'
      from ccc_program_asset a
     where a.content_id in ('VOD00030586', 'VOD00030587','VOD00031108','VOD00043698') -- 預告
       and a.active_flg = 'Y'
    union all -- 第一集免費除了怪醫黑傑克特別版(serial_no:8891,8766)
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE99' ACL_ID,
           'add'
      from ccc_program_asset
     where 1 = 1
       and (episode_no = 1 and serial_no not in ('8891', '8766'))
       and category_id not in ('BLESSEDLIFE')
       and active_flg = 'Y'
    union all
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE98' ACL_ID,
           'add'
      from ccc_program_asset
     where 1 = 1
       and (episode_no = 1 and serial_no not in ('8891', '8766'))
       and category_id not in ('BLESSEDLIFE')
       and active_flg = 'Y'
    union all
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE97' ACL_ID,
           'add'
      from ccc_program_asset
     where 1 = 1
       and (episode_no = 1 and serial_no not in ('8891', '8766'))
       and category_id not in ('BLESSEDLIFE')
       and content_type <> 'show'       
       and active_flg = 'Y'
    union all
    -- 動漫戲劇第一集PC路人免費
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE01' ACL_ID,
           'add'
      from ccc_program_asset
     where 1 = 1
       and (episode_no = 1 and serial_no not in ('8891', '8766'))
       and category_id not in ('BLESSEDLIFE')
       and active_flg = 'Y'
    union all
    -- 動漫戲劇第一集PC路人免費
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE00' ACL_ID,
           'add'
      from ccc_program_asset
     where 1 = 1
       and (episode_no = 1 and serial_no not in ('8891', '8766'))
       and category_id not in ('BLESSEDLIFE')
       and active_flg = 'Y'       
    union all
        -- 戲劇全集PC路人免費
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE00' ACL_ID,
           'add'
      from ccc_program_asset x
     where 1 = 1
       and (content_type = 'drama' or CATEGORY_ID = 'WEEKEND_CINEMA')
       and category_id not in ('BLESSEDLIFE')       
       and active_flg = 'Y'
    union all
    -- 戲劇全集PC路人免費
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE01' ACL_ID,
           'add'
      from ccc_program_asset x
     where 1 = 1
       and (content_type = 'drama' or CATEGORY_ID = 'WEEKEND_CINEMA')
       and category_id not in ('BLESSEDLIFE')       
       and active_flg = 'Y'
    union all
    select CONTENT_TITLE,
           CONTENT_ID,
           ASSET_ID,
           SERIAL_NO,
           SERIAL_ID,
           'FREE98' ACL_ID,
           'add'
      from ccc_program_asset x
     where 1 = 1
       and (content_type = 'drama' or CATEGORY_ID = 'WEEKEND_CINEMA')
       and category_id not in ('BLESSEDLIFE')       
       and active_flg = 'Y'
    union all
    select distinct CONTENT_TITLE,
                    CONTENT_ID,
                    ASSET_ID,
                    SERIAL_NO,
                    SERIAL_ID,
                    'FREE99' ACL_ID,
           'add'
      from ccc_program_asset
     where active_flg = 'Y'
       and CATEGORY_ID = 'WEEKEND_CINEMA'
    union all
    select distinct CONTENT_TITLE,
                    CONTENT_ID,
                    ASSET_ID,
                    SERIAL_NO,
                    SERIAL_ID,
                    'PUB001' ACL_ID,
           'add'
      from ccc_program_asset
     where active_flg = 'Y'
       and content_type = 'movie'
     union all
     select b.channel_name,
             b.cdn_name "Connect_id",
             b.cdn_name "Asset_ID",
             0,
             b.cdn_name,
             a.package_id,
           'add'
        from bsm_package_mas a, bsm_channel_list b
       where (instr(replace(b.content_group_ids,'CHANNEL,','CHANNEL_LITV,'),decode(a.package_cat_id1,'CHANNEL','CHANNEL_LITV',a.package_cat_id1)) > 0
         or (a.package_id in ('FREE00','FREE01') and instr(b.content_group_ids,'FTV01')>0))
         and a.package_id not in
             ('FREE4G', 'CHCPBL', 'CHCPBLG03', 'CHCPBLG12', 'CHCPBLC90')
         and b.cdn_name not in ('4gtv-4gtv036', '4gtv-4gtv037');
         
         
       
       

  delete bsm_acl_items a where ( a.content_id,a.acl_id) in 
  
      (select 
           a.CONTENT_ID,
           decode(b.acl_id, null, 'FREE00', b.acl_id) ACL_ID
      from ccc_program_asset a, ccc_free_serialno b -- 指定的片子才需要寫serial_no至ccc_free_serialno
     where a.serial_no = b.serial_no
       and a.season_no = b.season_no
       and active_flg = 'Y'
       and b.method ='erase'
       and b.episode_no is null
       and b.start_date <= trunc(sysdate)
       and b.end_date >= trunc(sysdate));
  insert into bsm_acl_items
        select a.CONTENT_TITLE,
           a.CONTENT_ID,
           a.ASSET_ID,
           a.SERIAL_NO,
           a.SERIAL_ID,
           decode(b.acl_id, null, 'FREE00', b.acl_id) ACL_ID,
           b.method
      from ccc_program_asset a, ccc_free_serialno b -- 指定的片子才需要寫serial_no至ccc_free_serialno
     where a.serial_no = b.serial_no
       and a.season_no = b.season_no
       and active_flg = 'Y'
       and b.episode_no is not null
       and b.episode_no=a.episode_no
       and b.start_date <= trunc(sysdate)
       and b.end_date >= trunc(sysdate)
    union all 
      
      select 
            a.CONTENT_TITLE,
           a.CONTENT_ID,
           a.ASSET_ID,
           a.SERIAL_NO,
           a.SERIAL_ID,
           decode(b.acl_id, null, 'FREE00', b.acl_id) ACL_ID,
           b.method
      from ccc_program_asset a, ccc_free_serialno b -- 指定的片子才需要寫serial_no至ccc_free_serialno
     where a.serial_no = b.serial_no
       and a.season_no = b.season_no
       and active_flg = 'Y'
       and b.method ='add'
       and b.episode_no is null
       and b.start_date <= trunc(sysdate)
       and b.end_date >= trunc(sysdate);
       
       commit;
      
end;
/

