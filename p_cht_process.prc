create or replace procedure iptv.p_cht_process(p_user_no number,p_purchase_no varchar2,p_sub_no varchar2)
is
 v_purchase_pk_no number;
 v_msg varchar2(1024);
begin
  select pk_no into v_purchase_pk_no from bsm_purchase_mas where  mas_no=p_purchase_no;
  update bsm_purchase_mas a
     set a.status_flg='P',
         a.cht_subscribeno=p_sub_no
    where a.mas_no=p_purchase_no;
    commit;
    
  v_msg := bsm_purchase_post.PURCHASE_COMPLETE(p_user_no,v_purchase_pk_no);
    
 
     declare
          v_recurrent_pk_no number(16);
          v_recurrent_type  varchar2(64);
          v_cht_subno       varchar2(64);
          v_cht_auth        varchar2(64);
         -- v_recurrent_type varchar2(64);
          v_ordernumber varchar2(64);
          v_pay_type varchar2(32);
          v_client_id varchar2(32);
          v_otpw varchar2(64);
          v_Purchase_Pk_No number(32);

        begin
          Select Seq_Bsm_Purchase_Pk_No.Nextval,
                 x.cht_subscribeno,
                 x.cht_auth,
                 x.cht_otpw,
                 x.pay_pk_no,
                 x.pay_type,
                 x.serial_id,
                 x.pk_no
            Into v_recurrent_pk_no, v_cht_subno, v_cht_auth,v_otpw,
            v_ordernumber,v_pay_type,v_client_id,v_Purchase_Pk_No
            From bsm_purchase_mas x
           where x.mas_no = p_purchase_no;

          if v_pay_type = '中華電信帳單' then
            v_recurrent_type := 'HINET';
          end if;

          if v_pay_type = 'IOS' then
            v_recurrent_type := 'IOS';
          end if;

          insert into bsm_recurrent_mas
            (pk_no,
             recurrent_type,
             create_date,
             create_user,
             src_pk_no,
             src_no,
             card_no,
             card_type,
             card_expiry,
             cvc2,
             start_date,
             status_flg,
             client_id,
             cht_subno,
             cht_auth,
             cht_otpw,
             cht_action_date,
             ordernumber,
             amount,
             dump_status)
          values
            (v_recurrent_pk_no,
             nvl(v_recurrent_type, 'CREDIT'),
             sysdate,
             0,
             v_Purchase_Pk_No,
             p_purchase_no,
            -- In_Bsm_Purchase.CARD_NO,
            null,
             null,
            null,
            null,
             sysdate,
             'P',
             v_client_id,
             v_cht_subno,
             v_cht_auth,
             v_otpw,
             null,
             v_ordernumber,
             null,
             'A');

          commit;
        end;

end;
/

