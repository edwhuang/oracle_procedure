create or replace procedure iptv.send_gift_p_test is

  p_message_code varchar2(64) := '開通贈送';

  cursor c1 is
       select a.serial_id,
           b.device_id,
           c.owner_phone,
           get_software_group(a.serial_id, b.device_id) sg,
           a.mas_no
      from bsm_purchase_mas       a,
           bsm_purchase_item      b,
           bsm_client_mas         c,
           bsm_client_device_list d
     where a.pay_type = '贈送'
       and (src_no = 'CLIENT_ACTIVATED' or
       exists(select 'x' from  bsm_coupon_mas e where e.serial_id=a.serial_id and e.device_id=e.device_id)
       )
       and a.status_flg in ('P', 'Z')
       and b.mas_pk_no = a.pk_no
       and d.client_id = a.serial_id
       and d.device_id = b.device_id
       and c.mac_address = a.serial_id
       and d.software_group != 'LTSMS02'
       and a.sms_flg != 'Y'
     group by a.serial_id, b.device_id, c.owner_phone, a.mas_no;

  v_message varchar2(1024);

  v_sms_group   varchar2(64);
  v_package_id1 varchar2(64);
  v_package_id2 varchar2(64);
  v_msg         varchar2(256);
  v_sg          varchar2(256);

  -- for samsung mobile
  p_message_code_mobile varchar2(64) := 'SANSUMG 手機贈送';

  cursor c2 is
    select a.serial_id,
           b.device_id,
           b.package_id,
           c.owner_phone,
           a.purchase_date,
           a.mas_no
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

begin
  for c1rec in c1 loop
    -- get software group
    if c1rec.sg = 'None' then
      v_sg := substr(bsm_cdi_service.get_device_current_swver(c1rec.serial_id,
                                                              c1rec.device_id),
                     1,
                     7);
      update bsm_client_device_list
         set software_group = v_sg
       where client_id = c1rec.serial_id
         and device_id = c1rec.device_id;
      commit;
    else
      v_sg := c1rec.sg;
    end if;

    -- check coupon 券方案
    -- 1. get all purchase for this client + device
    declare
      v_coupon_id         varchar2(32);
      v_coupon_program_id varchar2(32);
      v_no_coupon_found   varchar(32);
      v_coupon_no         varchar2(32);
      v_sms_flg           varchar2(32);
      v_sms_code          varchar2(32);
      v_sms_set           varchar2(32);

    begin
      begin

        select mas_no, coupon_id, a.program_id
          into v_coupon_no, v_coupon_id, v_coupon_program_id
          from bsm_coupon_mas a
         where a.register_date is not null
           and a.ref_device_id = c1rec.device_id;

         v_no_coupon_found := 'N';

        -- check 是否已發送過贈送訊息,若沒有發送簡訊
        begin
          select sms_flg
            into v_sms_flg
            from bsm_purchase_mas
           where src_no = v_coupon_no;
        exception
          when no_data_found then
            v_sms_flg := 'Y';
        end;

        if v_sms_flg = 'N' then
          select sms_code
            into v_sms_code
            from bsm_coupon_prog_mas a
           where a.cup_program_id = v_coupon_program_id;
          if v_sms_code is not null then
            select message
              into v_message
              from bsm_sms_temp a
             where group_id = v_sms_code;
       /*     v_msg := bsm_sms_service.Send_Sms_Messeage(c1rec.owner_phone,
                                                       v_message,
                                                       c1rec.device_id,
                                                       p_message_code); */
          end if;

          update bsm_purchase_mas a
             set sms_flg = 'Y', sms_date = sysdate
           where a.serial_id=c1rec.serial_id
           and sms_flg='N'
           and exists(select 'x' from bsm_purchase_item b where b.mas_pk_no=a.pk_no and b.device_id=c1rec.device_id);
          commit;
        end if;

      exception
        when no_data_found then
          v_no_coupon_found := 'Y';
      end;

      if v_no_coupon_found = 'Y' then
        select ref2, ref3
          into v_sms_code, v_sms_set
          from mfg_softwaregroup_mas
         where software_group = v_sg;

        if v_sms_code is not null then

          select sms_flg
            into v_sms_flg
            from bsm_purchase_mas a
           where a.mas_no = c1rec.mas_no;

          if v_sms_flg = 'N' then
            if v_sms_set is null then
              select message
                into v_message
                from bsm_sms_temp a
               where group_id = v_sms_code;
          /*    v_msg := bsm_sms_service.Send_Sms_Messeage(c1rec.owner_phone,
                                                         v_message,
                                                         c1rec.device_id,
                                                         p_message_code); */
          update bsm_purchase_mas a
             set sms_flg = 'Y', sms_date = sysdate
           where a.serial_id=c1rec.serial_id
           and sms_flg='N'
           and exists(select 'x' from bsm_purchase_item b where b.mas_pk_no=a.pk_no and b.device_id=c1rec.device_id);
          commit;

            else
              if instr(v_sms_set, ':') > 0 then
                if sysdate >=
                   to_date(to_char(sysdate, 'YYYYMMDD') || v_sms_set,
                           'YYYYMMDDHH24:MI') then
                  select message
                    into v_message
                    from bsm_sms_temp a
                   where group_id = v_sms_code;
        /*          v_msg := bsm_sms_service.Send_Sms_Messeage(c1rec.owner_phone,
                                                             v_message,
                                                             c1rec.device_id,
                                                             p_message_code); */
          update bsm_purchase_mas a
             set sms_flg = 'Y', sms_date = sysdate
           where a.serial_id=c1rec.serial_id
           and sms_flg='N'
           and exists(select 'x' from bsm_purchase_item b where b.mas_pk_no=a.pk_no and b.device_id=c1rec.device_id);
          commit;
                end if;
              end if;
            end if;
          end if;
        else
          -- mark flg
     /*     update bsm_purchase_mas a
             set sms_flg = 'Y', sms_date = sysdate
           where a.serial_id=c1rec.serial_id
           and sms_flg='N'
           and exists(select 'x' from bsm_purchase_item b where b.mas_pk_no=a.pk_no and b.device_id=c1rec.device_id); */
          commit;
        end if;
      end if;
    end;

  end loop;

  for c2rec in c2 loop
  /*  v_msg := bsm_sms_service.Send_Sms_Messeage(c2rec.owner_phone,
                                               p_message_sun_mobile,
                                               c2rec.device_id,
                                               p_message_code_mobile); */
          update bsm_purchase_mas a
             set sms_flg = 'Y', sms_date = sysdate
           where a.serial_id=c2rec.serial_id
           and sms_flg='N'
           and exists(select 'x' from bsm_purchase_item b where b.mas_pk_no=a.pk_no and b.device_id=c2rec.device_id);
          commit;
  end loop;

end;
/

