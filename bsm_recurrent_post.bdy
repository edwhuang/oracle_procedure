CREATE OR REPLACE PACKAGE BODY IPTV."BSM_RECURRENT_POST" is
  procedure daliy_job
    is
      v_mas_pk_no number(16);
      v_mas_no varchar2(32);
      v_msg varchar2(1024);
    begin
      select seq_bsm_purchase_pk_no.nextval into v_mas_pk_no from dual;
      v_mas_no:=sysapp_util.Get_Mas_No(1,2,sysdate,'BSMRECURRENT',v_mas_pk_no);
      insert into bsm_recurrent_pay(pk_no,mas_no,mas_date,mas_code,des,create_date,create_user,status_flg)
      values (v_mas_pk_no,v_mas_no,sysdate,'BSMRECURRENT','系統自動產生',sysdate,0,'A');
      v_msg:=transfer(0,v_mas_pk_no);
      v_msg:=post(0,v_mas_pk_no);
    end;
  function transfer(user_no number, p_pk_no number) return varchar2 is
    v_item_pk_no number(16);
    cursor c1 is
      Select a.pk_no,
             e.mac_address client_id,
             e.owner_phone,
             c.package_id,
             d.package_cat1,
             d.package_cat_id1,
             c.device_id device_id,
             a.src_no purchase_no,
             decode(to_char(get_end_date(e.mac_address, d.package_cat_id1),
                            'YYYY/MM/DD'),
                    '2999/12/31',
                    null,
                    get_end_date(e.mac_address, d.package_cat_id1)) end_date,
             decode(to_char(get_end_date(e.mac_address, d.package_cat_id1),
                            'YYYY/MM/DD'),
                    '2999/12/31',
                    null,
                    get_end_date(e.mac_address, d.package_cat_id1) - 3) pay_date
        from bsm_recurrent_mas a,
             bsm_purchase_mas  b,
             bsm_purchase_item c,
             bsm_package_mas   d,
             bsm_client_mas    e
       where a.status_flg = 'P'
         and b.mas_no = a.src_no
         and b.recurrent = 'R'
         and c.mas_pk_no = b.pk_no
         and d.package_id = c.package_id
         and e.mac_address = b.serial_id
         and decode(to_char(get_end_date(e.mac_address, d.package_cat_id1),
                            'YYYY/MM/DD'),
                    '2999/12/31',
                    null,
                    get_end_date(e.mac_address, d.package_cat_id1)) is not null
         and get_end_date(e.mac_address, d.package_cat_id1)-3<= sysdate;
  begin

    for i in c1 loop
      select seq_bsm_purchase_pk_no.nextval into v_item_pk_no from dual;
      insert into bsm_recurrent_pay_item
        (mas_pk_no,
         pk_no,
         client_id,
         device_id,
         package_cat_id1,
         package_id,
         service_end_date,
         next_pay_date,
         owner_phone_no,
         recurrent_pk_no,
         src_purchase_no,
         status_flg)
      values
        (p_pk_no,
         v_item_pk_no,
         i.client_id,
         i.device_id,
         i.package_cat_id1,
         i.package_id,
         i.end_date,
         i.pay_date,
         i.owner_phone,
         i.pk_no,
         i.purchase_no,
         'A');
    end loop;

    commit;
    return null;
  end;

  function post(user_no number, p_pk_no number) return varchar2 is
    cursor c1 is
      select b.rowid rid,b.* from bsm_recurrent_pay_item b where b.mas_pk_no = p_pk_no;
    v_msg varchar2(32);
  begin
    for i in c1 loop
      declare
        result          tbsm_result;
        in_bsm_purchase tbsm_purchase;
      begin
        in_bsm_purchase := new tbsm_purchase;

        in_bsm_purchase.serial_id := i.client_id;

        select ti_sys_login.decrypt(card_no),ti_sys_login.decrypt(card_expiry),ti_sys_login.decrypt(cvc2),a.card_type
        into in_bsm_purchase.CARD_NO, in_bsm_purchase.CARD_EXPIRY, in_bsm_purchase.CVC2,in_bsm_purchase.CARD_TYPE
        from bsm_recurrent_mas a
        where a.pk_no= i.recurrent_pk_no;

        in_bsm_purchase.pay_type := 'CREDIT';

        in_bsm_purchase.details := new tbsm_purchase_dtls(new tbsm_purchase_dtl);
     --  in_bsm_purchase.details.extend(1);
        in_bsm_purchase.details(1) := new tbsm_purchase_dtl;

        in_bsm_purchase.details(1).offer_id := i.package_id;

        -- Call the function
        result := bsm_client_service.crt_purchase(in_bsm_purchase => in_bsm_purchase,
                                                  p_recurrent     => 'O',
                                                  p_device_id     => i.device_id);

       if result.result_code != 'BSM-0000' then
          update  bsm_recurrent_pay_item b
            set b.status_flg = 'F',
            result_code = result.result_code,
            result_message= result.result_message ,
            purchase_no= in_bsm_purchase.mas_no
           where rowid = i.rid;

           update bsm_recurrent_mas a
            set a.status_flg='L'
            where a.pk_no=i.recurrent_pk_no;
       else
          update  bsm_recurrent_pay_item b
            set b.status_flg = 'S',
            result_code = result.result_code,
            result_message= result.result_message,
            purchase_no= in_bsm_purchase.mas_no
           where rowid = i.rid;
       end if;
       commit;
      end;

    end loop;
    update bsm_recurrent_pay a
      set a.trigger_date=sysdate
     , a.status_flg='Z'
     where a.pk_no=p_pk_no;
    return null;
  end;

end;
/

