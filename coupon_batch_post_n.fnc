CREATE OR REPLACE Function IPTV.COUPON_BATCH_POST_N(p_User_No Number, p_Pk_No Number)
    Return Varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg      Varchar2(32);
    v_mas_code        Varchar2(32);
    v_mas_no          Varchar2(32);
    v_mas_date        Date;
    v_coupon_count    number(16);
    v_coupon_prefix   varchar2(32);
    v_program_id      varchar2(32);
    v_org_no          number(16);
    v_loc_no          number(16);
    v_coupon_mas_code varchar2(32) := 'COUPON';
    v_coupon_mas_date date := sysdate;
    v_expire_date     date;
    v_curr_cup_cnt   number(16);
    v_max_cup_cnt    number(16);
    v_coupon_type    varchar2(32);

  begin

    begin
      Select org_no,
             loc_no,
             mas_code,
             mas_no,
             mas_date,
             status_flg,
             program_id,
             coupon_count,
             coupon_prefix,
             expire_date,
             max_coupon_cnt,
             coupon_type
        Into v_org_no,
             v_loc_no,
             v_mas_code,
             v_mas_no,
             v_mas_date,
             v_status_flg,
             v_program_id,
             v_coupon_count,
             v_coupon_prefix,
             v_expire_date,
             v_max_cup_cnt,
             v_coupon_type
        From bsm_coupon_batch_mas a
       Where pk_no = p_pk_no;

    exception
      when no_data_found then
        exception_msg := '#找不到單據資料' || to_char(p_pk_no) || '#';
        raise app_exception;
    end;

    select count(*) into v_curr_cup_cnt
     from bsm_coupon_mas a
     where a.src_no =v_mas_no;

    if v_max_cup_cnt is null then
      v_max_cup_cnt := 0;
    end if;

    if nvl(v_max_cup_cnt,0) = 0 then
       v_max_cup_cnt := v_coupon_count;

    end if;


    for i in nvl(v_curr_cup_cnt,0) .. v_max_cup_cnt - 1 loop
      declare
        v_pk_no            number;
        v_coupon_mas_no    varchar2(32);
        v_coupon_id        varchar2(32);
        v_coupon_serial_no varchar2(32);
        v_coupon_pre       varchar2(32);
      begin
        select seq_bsm_purchase_pk_no.nextval into v_pk_no from dual;
        v_coupon_mas_no    := sysapp_util.Get_Mas_No(v_org_no,
                                                     v_loc_no,
                                                     v_coupon_mas_date,
                                                     v_coupon_mas_code,
                                                     v_pk_no);
        v_coupon_id        := bsm_purchase_post.CLIENT_GENERATE_COUPON_NO(sysdate,v_coupon_type);
        v_coupon_pre       := v_coupon_prefix ||
                              to_char(to_number(to_char(sysdate, 'YYYY')) - 1911);
        v_coupon_serial_no := sysapp_util.Get_Mas_No(v_org_no,
                                                     v_loc_no,
                                                     sysdate,
                                                     'COUPONSERIAL',
                                                     v_pk_no,
                                                     v_coupon_pre);
        -- add month
        v_coupon_serial_no := substr(v_coupon_serial_no, 1, 5) ||
                              to_char(sysdate, 'MM') ||
                              substr(v_coupon_serial_no, 6, 12);

        insert into bsm_coupon_mas
          (org_no,
           loc_no,
           pk_no,
           mas_code,
           mas_date,
           mas_no,
           program_id,
           status_flg,
           src_code,
           src_no,
           src_date,
           coupon_id,
           coupon_serial_no,
           expire_date)
        values
          (v_org_no,
           v_loc_no,
           v_pk_no,
           v_coupon_mas_code,
           v_coupon_mas_date,
           v_coupon_mas_no,
           v_program_id,
           'A',
           v_mas_code,
           v_mas_no,
           v_mas_date,
           v_coupon_id,
           v_coupon_serial_no,
           v_expire_date);
      end;

    end loop;

    update bsm_coupon_batch_mas set status_flg = 'P' where pk_no = p_pk_no;

    return null;

  Exception
    When app_exception Then

      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;
/

