create or replace procedure iptv.send_gift_p is

  p_message_code        varchar2(64) := '開通贈送';

  cursor c1 is  select a.serial_id,
           b.device_id,
           c.owner_phone,
           get_software_group(a.serial_id,b.device_id) sg
      from bsm_purchase_mas       a,
           bsm_purchase_item      b,
           bsm_client_mas         c,
           bsm_client_device_list d
     where a.pay_type = '贈送'
       and src_no = 'CLIENT_ACTIVATED'
       and a.status_flg in ('P', 'Z')
       and b.mas_pk_no = a.pk_no
       and d.client_id = a.serial_id
       and d.device_id = b.device_id
       and not exists(select 'x' from bsm_purchase_item e where e.mas_pk_no=a.pk_no and e.package_id='HDG001')
       and c.mac_address = a.serial_id
       and a.purchase_date >=  (sysdate - (60 / (24 * 60)))
       and not exists (select 'x'
              from bsm_client_sms_log b
             where b.message_code = p_message_code
               and b.client_id = b.device_id)
        group by a.serial_id,
           b.device_id,
           c.owner_phone;

  v_message varchar2(1024);

  v_sms_group      varchar2(64);
  v_package_id1    varchar2(64);
  v_package_id2    varchar2(64);
  v_msg            varchar2(256);
  v_sg             varchar2(256);

  -- for samsung mobile
   p_message_code_mobile varchar2(64) := 'SANSUMG 手機贈送';

    cursor c2 is
    select a.serial_id,
           b.device_id,
           b.package_id,
           c.owner_phone,
           a.purchase_date
      from bsm_purchase_mas       a,
           bsm_purchase_item      b,
           bsm_client_mas         c,
           bsm_client_device_list d
     where a.pay_type = '贈送'
       and src_no = 'CLIENT_ACTIVATED'
       and a.status_flg in ('P', 'Z')
       and b.mas_pk_no = a.pk_no
       and b.package_id = 'C00005'
       and d.client_id = a.serial_id
       and d.device_id = b.device_id
       and d.software_group = 'LTSMS02'
       and c.mac_address = a.serial_id
       and a.purchase_date >= (sysdate - (60 / (24 * 60)))
       and not exists (select 'x'
              from bsm_client_sms_log b
             where b.message_code = 'SANSUMG 手機贈送'
               and b.client_id = b.device_id);

  p_message_sun_mobile varchar2(256) := '【三星開通禮】三星手機平板用戶可立即享有『LiTV家庭電影院』服務90天免費看，到期日請至「購買紀錄」查詢，或洽02-77070708';

  -- for samsung mobile
   p_message_code_sam_tv varchar2(64) := 'SANSUMG TV 贈送';

    cursor c3 is
    select a.serial_id,
           b.device_id,
           b.package_id,
           c.owner_phone,
           a.purchase_date
      from bsm_purchase_mas       a,
           bsm_purchase_item      b,
           bsm_client_mas         c,
           bsm_client_device_list d
     where a.pay_type = '贈送'
       and src_no = 'CLIENT_ACTIVATED'
       and a.status_flg in ('P', 'Z')
       and b.mas_pk_no = a.pk_no
       and b.package_id = 'HDG001'
       and d.client_id = a.serial_id
       and d.device_id = b.device_id
       and d.software_group = 'LTSMS01'
       and c.mac_address = a.serial_id
       and a.purchase_date >= (sysdate - (60 / (24 * 60)))
       and not exists (select 'x'
              from bsm_client_sms_log b
             where b.message_code = 'SANSUMG TV 贈送'
               and b.client_id = b.device_id);

  p_message_sun_sam_tv varchar2(256) := '【LiTV開通禮】三星用戶可立即免費使用『HD豪華包月』服務6個月，及『卡拉OK』服務7天，啟用及到期日請至電視或官網會員專區查詢 ';

  p_message_code_cnyes varchar2(64) := '鉅亨贈送';

    cursor c4 is
    select a.serial_id,
           b.device_id,
           b.package_id,
           c.owner_phone,
           a.purchase_date
      from bsm_purchase_mas       a,
           bsm_purchase_item      b,
           bsm_client_mas         c,
           bsm_client_device_list d
     where 
        a.src_no in (Select x.mas_no from bsm_coupon_mas x where program_id ='INFCN001' and x.register_date is not null)
       and a.status_flg in ('P', 'Z')
       and b.mas_pk_no = a.pk_no
       and c.mac_address = a.serial_id
       and d.client_id = a.serial_id
       and d.device_id = b.device_id
        
       and d.software_group = 'LTAML02'
       and a.purchase_date >= (sysdate - (60 / (24 * 60)))
       and not exists (select 'x'
              from bsm_client_sms_log b
             where b.message_code = '鉅亨贈送'
               and b.client_id = b.device_id);

  p_message_cnyes varchar2(256) := 'InFocus鉅亨專案用戶：您可立即享用LiTV『鉅亨股市』一年、『家庭電影院』一年、『Hichannel』30天';

begin
  for c1rec in c1 loop
    if c1rec.sg ='None' then
       v_sg := substr( bsm_cdi_service.get_device_current_swver(c1rec.serial_id,c1rec.device_id),1,7);
       update bsm_client_device_list
         set software_group = v_sg
        where client_id=c1rec.serial_id
        and device_id=c1rec.device_id;
        commit;
    else
      v_sg :=c1rec.sg;
    end if;
    begin
      select ref2 into v_sms_group from mfg_softwaregroup_mas where software_group= v_sg;

      if v_sms_group is not null then
         select message into v_message from bsm_sms_temp a where group_id =v_sms_group;

        v_msg := bsm_sms_service.Send_Sms_Messeage(c1rec.owner_phone,
                                                   v_message,
                                                   c1rec.device_id,
                                                   p_message_code);
      end if;

    exception
      when no_data_found then
        null;
    end;
  end loop;

  for c2rec in c2 loop
    v_msg := bsm_sms_service.Send_Sms_Messeage(c2rec.owner_phone,
                                               p_message_sun_mobile,
                                               c2rec.device_id,
                                               p_message_code_mobile);
  end loop;

    for c3rec in c3 loop
    v_msg := bsm_sms_service.Send_Sms_Messeage(c3rec.owner_phone,
                                               p_message_sun_sam_tv,
                                               c3rec.device_id,
                                                p_message_code_sam_tv);
  end loop;
  
    for c4rec in c4 loop
    v_msg := bsm_sms_service.Send_Sms_Messeage(c4rec.owner_phone,
                                               p_message_cnyes,
                                               c4rec.device_id,
                                                p_message_code_cnyes);
  end loop;
 end;
/

