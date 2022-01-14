create or replace procedure iptv.recal_coupon_amount_2(p_coupon_prog_id varchar2,
                                                p_start_date     date,
                                                p_end_date       date) is
  cursor c1 is
    select a.pk_no,a.program_id,a.device_id
      from bsm_coupon_mas a
     where a.register_date > p_start_date
       and a.register_date < p_end_date + 1
      -- and a.program_id = p_coupon_prog_id
       and a.status_flg = 'Z';
  v_pk_no number(16);
begin
  for i in c1 loop
    v_pk_no := i.pk_no;
    declare
      cursor c1 is
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
           and a.cup_program_id = i.program_id;
      v_item_pk_no number(16);

    begin
      delete bsm_coupon_details b where b.mas_pk_no = v_pk_no;
      for c1rec in c1 loop
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
           item_type,
           device_id)
        values
          (v_item_pk_no,
           v_pk_no,
           c1rec.package_id,
           null,
           'A',
           c1rec.tax_amount,
           c1rec.net_amount,
           c1rec.amount,
           c1rec.item_type,
           i.device_id);

        update bsm_coupon_mas a
           set a.tax_amount = c1rec.tax_amount_a,
               a.net_amount = c1rec.net_amount_a,
               a.amount     = c1rec.amount_a
         where a.pk_no = v_pk_no;
        commit;
      end loop;
    end;

  end loop;
end;
/

