create or replace procedure iptv.fa_cal_purchase_dis(p_purchase_start_date date,
                                                p_purchase_end_date   date) is
  -- 非兌換券處理
  cursor c1 is
    select pk_no,
           mas_no,
           purchase_date,
           pay_type,
           net_amount,
           amount,
           buy_credits,
           Package_cat1,
           distribute_period,
           system_type,
           credits,
           credits_gift,
           software_desc,
           ref1,
           pay_type_P,
           supply_id,
           round(net_amount / distribute_period) period_amt,
           First_dis_days,
           First_month_days,
           round(First_dis_days / First_month_days *
                 round(net_amount / distribute_period)) first_amt,
           case
             when (net_amount -
                  round(First_dis_days / First_month_days *
                         round(net_amount / distribute_period)) -
                  (round(net_amount / distribute_period) *
                  (distribute_period - 1))) < 0 then
              0
             else
              (net_amount -
              round(First_dis_days / First_month_days *
                     round(net_amount / distribute_period)) -
              (round(net_amount / distribute_period) *
              (distribute_period - 1)))
           end last_amt,
           serial_id,
           to_char(purchase_date, 'YYYY-MM') start_dis_mon,
           to_char(add_months(purchase_date, distribute_period), 'YYYY-MM') end_dis_mon,
           package_id,
           item_id,
           device_id
      from (select a.pk_no,
                   a.purchase_date,
                   a.mas_no,
                   a.serial_id,
                   a.pay_type,
                   nvl(b.amount, 0) amount,
                   case
                     when a.pay_type = '儲值卡' then
                      round(nvl(b.amount, 0) * 0.865) --儲值卡不扣稅
                     else
                      round(nvl(b.amount, 0) / 1.05)
                   end net_amount,
                   case
                     when a.pay_type = '儲值卡' then
                      0
                     else
                      nvl(b.amount, 0) - round(nvl(b.amount, 0) / 1.05)
                   end tax,
                   b.credits buy_credits,
                   c.Package_cat1,
                   c.description,
                   c.distribute_period,
                   c.system_type,
                   c.credits,
                   c.credits_gift,
                   d.owner_phone,
                   null software_desc,
                   null ref1,
                   a.pay_type PAY_TYPE_P,
                   null
                   /* (select supply_id
                    from bsm_coupon_prog_mas x
                   where x.cup_program_id = h.program_id) */ supply_id,
                   to_date(to_char(LAST_DAY(a.purchase_date), 'yyyy-mm-dd'),
                           'yyyy-mm-dd') -
                   to_date(to_char(a.purchase_date, 'yyyy-mm-dd'),
                           'yyyy-mm-dd') + 1 First_dis_days,
                   to_char(last_day(a.purchase_date), 'dd') First_month_days,
                   b.package_id,
                   b.item_id,
                   b.device_id
              from bsm_purchase_mas a
              left join bsm_purchase_item b
                on a.pk_no = b.mas_pk_no
              left join bsm_package_mas c
                on b.package_id = c.package_id
              left join bsm_client_mas d
                on a.serial_id = d.mac_address
              left join mfg_iptv_mas e
                on d.mac_address = e.mac_address
            -- left join mfg_softwaregroup_mas f
            --   on e.software_group = f.software_group
              left join bsm_coupon_mas h
                on h.mas_no = a.src_no
             where a.status_flg in ('Z')
               and nvl(a.report_type, 'N') = 'P'
               and A.purchase_date >= p_purchase_start_date
               and A.purchase_date < p_purchase_end_date + 1
               and a.pay_type <> '兌換券');
  cursor c2 is
    select pk_no,
           mas_no,
           purchase_date,
           pay_type,
           net_amount,
           amount,
           buy_credits,
           Package_cat1,
           distribute_period,
           system_type,
           credits,
           credits_gift,
           software_desc,
           ref1,
           pay_type_P,
           supply_id,
           round(net_amount / distribute_period) period_amt,
           First_dis_days,
           First_month_days,
           round(First_dis_days / First_month_days *
                 round(net_amount / distribute_period)) first_amt,
           case
             when (net_amount -
                  round(First_dis_days / First_month_days *
                         round(net_amount / distribute_period)) -
                  (round(net_amount / distribute_period) *
                  (distribute_period - 1))) < 0 then
              0
             else
              (net_amount -
              round(First_dis_days / First_month_days *
                     round(net_amount / distribute_period)) -
              (round(net_amount / distribute_period) *
              (distribute_period - 1)))
           end last_amt,
           serial_id,
           to_char(purchase_date, 'YYYY-MM') start_dis_mon,
           to_char(add_months(purchase_date, distribute_period), 'YYYY-MM') end_dis_mon,
           package_id,
           item_id,
           device_id
      from (select a.pk_no,
                   a.purchase_date,
                   a.mas_no,
                   a.serial_id,
                   a.pay_type,
                   nvl(g.amount, 0) amount,
                   round(nvl(g.amount, 0) / 1.05) net_amount,
                   nvl(g.amount, 0) - round(nvl(g.amount, 0) / 1.05) tax,
                   0 buy_credits,
                   c.Package_cat1,
                   c.description,
                   c.distribute_period,
                   c.system_type,
                   c.credits,
                   c.credits_gift,
                   d.owner_phone,
                   null software_desc,
                   null ref1,
                   case
                     when a.pay_type = '兌換券' and
                          (select supply_id
                             from bsm_coupon_prog_mas x
                            where x.cup_program_id = h.program_id) is null then
                      a.pay_type || '-匯款'
                     else
                      a.pay_type
                   end PAY_TYPE_P,
                   (select supply_id
                      from bsm_coupon_prog_mas x
                     where x.cup_program_id = h.program_id) supply_id,
                   to_date(to_char(LAST_DAY(a.purchase_date), 'yyyy-mm-dd'),
                           'yyyy-mm-dd') -
                   to_date(to_char(a.purchase_date, 'yyyy-mm-dd'),
                           'yyyy-mm-dd') + 1 First_dis_days,
                   to_char(last_day(a.purchase_date), 'dd') First_month_days,
                   g.package_id,
                   g.item_id,
                   h.device_id
              from bsm_purchase_mas a
              left join bsm_client_mas d
                on a.serial_id = d.mac_address
              left join mfg_iptv_mas e
                on d.mac_address = e.mac_address
            
              left join bsm_coupon_mas h
                on h.mas_no = a.src_no
              left join bsm_coupon_details g
                on h.pk_no = g.mas_pk_no
              left join (Select package_id,
                               package_cat1,
                               description,
                               distribute_period,
                               credits_gift,
                               credits,
                               system_type
                          from bsm_package_mas
                        union
                        Select package_id,
                               package_cat1,
                               description,
                               distribute_period,
                               0,
                               0,
                               system_type
                          from Fa_package_mas) c
                on g.package_id = c.package_id
            -- left join mfg_softwaregroup_mas f
            --  on get_software_group(a.serial_id,h.device_id) = f.software_group                  
             where a.status_flg in ('Z')
          --    and nvl(a.report_type, 'N') = 'P'
               and A.purchase_date >= p_purchase_start_date
               and A.purchase_date < p_purchase_end_date + 1
               and a.pay_type = '兌換券');

  cursor c3 is
    select b.pk_no, b.program_id
      from bsm_purchase_mas a, bsm_coupon_mas b
     where a.status_flg in ('Z')
       and b.mas_no = a.src_no
      -- and nvl(a.report_type, 'N') = 'P'
       and A.purchase_date >= p_purchase_start_date
       and A.purchase_date < p_purchase_end_date + 1
       and a.pay_type = '兌換券';
  v_char           varchar2(1);
  v_software_desc  varchar2(1024);
  v_ref1           varchar2(64);
  v_software_group varchar(32);
begin
  delete fa_purchase_details a
   where A.purchase_date >= p_purchase_start_date
     and A.purchase_date < p_purchase_end_date + 1;
  commit;
  for i in c1 loop
    -- template solution let device_id not exist pass
    if (substr(i.package_id, 1, 1) = 'W' or substr(i.package_id, 1, 2) = 'CH') then
      v_software_group := 'LTWEB00';
    else
      v_software_group := get_software_group(i.serial_id, i.device_id);
    end if;
    dbms_output.put_line(i.serial_id || i.device_id || v_software_group);
    if v_software_group != 'None' then
      begin
      select ref1, software_group
        into v_ref1, v_software_group
        from mfg_softwaregroup_mas a
       where a.software_group = v_software_group;
      exception
        when no_data_found then 
                v_ref1           := null;
                v_software_group := null;
      end;
          
    else
      v_ref1           := null;
      v_software_group := null;
    end if;
  
    insert into fa_purchase_details
      (pk_no,
       mas_no,
       purchase_date,
       pay_type,
       net_amount,
       buy_credits,
       package_cat1,
       distribute_period,
       system_type,
       credits,
       credits_gift,
       software_desc,
       ref1,
       pay_type_p,
       supply_id,
       period_amt,
       first_dis_days,
       first_month_days,
       first_amt,
       last_amt,
       serial_id,
       start_dis_mon,
       end_dis_mon,
       package_id,
       item_id,
       device_id,
       amount)
    values
      (i.pk_no,
       i.mas_no,
       i.purchase_date,
       i.pay_type,
       i.net_amount,
       i.buy_credits,
       i.package_cat1,
       i.distribute_period,
       i.system_type,
       i.credits,
       i.credits_gift,
       v_software_desc,
       v_ref1,
       i.pay_type_p,
       i.supply_id,
       i.period_amt,
       i.first_dis_days,
       i.first_month_days,
       i.first_amt,
       i.last_amt,
       i.serial_id,
       i.start_dis_mon,
       i.end_dis_mon,
       i.package_id,
       i.item_id,
       i.device_id,
       i.amount);
    commit;
    -- end;
  end loop;

  for i in c3 loop
    declare
      cursor c1(p_program_id varchar2) is
        select b.package_id,
               b.item_type,
               b.net_amount,
               b.tax_amount,
               b.amount,
               a.net_amount net_amount_a,
               a.tax_amount tax_amount_a,
               a.amount     amount_a
          from bsm_coupon_prog_mas a, bsm_coupon_prog_item b
         where b.mas_pk_no = a.pk_no
           and a.cup_program_id = p_program_id;
      v_item_pk_no number(16);
      v_pk_no      number(16);
    
    begin
      v_pk_no := i.pk_no;
      delete bsm_coupon_details b where b.mas_pk_no = v_pk_no;
      for c1rec in c1(i.program_id) loop
        select seq_payment_order_no.nextval into v_item_pk_no from dual;
        insert into bsm_coupon_details
          (pk_no,
           mas_pk_no,
           package_id,
           item_id,
           status_flg,
           tax_amount,
           net_amount,
           amount,
           item_type)
        values
          (v_item_pk_no,
           v_pk_no,
           c1rec.package_id,
           null,
           'A',
           c1rec.tax_amount,
           c1rec.net_amount,
           c1rec.amount,
           c1rec.item_type);
      
        update bsm_coupon_mas a
           set a.tax_amount = c1rec.tax_amount_a,
               a.net_amount = c1rec.net_amount_a,
               a.amount     = c1rec.amount_a
         where a.pk_no = v_pk_no;
        commit;
      end loop;
    end;
  
  end loop;

  for i in c2 loop

    v_software_group := get_software_group(i.serial_id, i.device_id);
    begin
    select ref1, software_group
      into v_ref1, v_software_group
      from mfg_softwaregroup_mas a
     where a.software_group = v_software_group;
    exception
      when no_data_found then v_ref1:=v_software_group; v_software_group:=v_software_group;
    end;
    insert into fa_purchase_details
      (pk_no,
       mas_no,
       purchase_date,
       pay_type,
       net_amount,
       buy_credits,
       package_cat1,
       distribute_period,
       system_type,
       credits,
       credits_gift,
       software_desc,
       ref1,
       pay_type_p,
       supply_id,
       period_amt,
       first_dis_days,
       first_month_days,
       first_amt,
       last_amt,
       serial_id,
       start_dis_mon,
       end_dis_mon,
       package_id,
       item_id,
       device_id,
       amount)
    values
      (i.pk_no,
       i.mas_no,
       i.purchase_date,
       i.pay_type,
       i.net_amount,
       i.buy_credits,
       i.package_cat1,
       i.distribute_period,
       i.system_type,
       i.credits,
       i.credits_gift,
       v_software_desc,
       v_ref1,
       i.pay_type_p,
       i.supply_id,
       i.period_amt,
       i.first_dis_days,
       i.first_month_days,
       i.first_amt,
       i.last_amt,
       i.serial_id,
       i.start_dis_mon,
       i.end_dis_mon,
       i.package_id,
       i.item_id,
       i.device_id,
       i.amount);
    commit;
    --  end;
  end loop;
end;
/

