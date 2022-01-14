create or replace function iptv.send_bonuswinner_cups(p_phone_no    varchar2,
                                                 p_client_id   varchar2,
                                                 p_purchase_no varchar2,
                                                 p_amount      varchar2,
                                                 p_pay_type    varchar2,
                                                 p_type        varchar2)
  return varchar2 is
  v_result varchar2(32);
begin
  v_result := 'N';
  insert into iptv.acc_ana1(acc_code,acc_type,chg_code,pm_code) values (p_phone_no,p_client_id,p_purchase_no,p_pay_type||p_type);
  commit;
  if (p_type = 'order' and p_pay_type in ( '信用卡','CREDIT')) then
    declare
      v_rid       rowid;
      v_coupon_id varchar2(32);
      v_msg       varchar2(1024);
    begin
      --LiTV線上影視已收到您的訂單<purchase_no>金額$<amount>明細請至網路會員專區查詢。宅神爺送您發財金！儲值序號：<coupon_id>。儲值入口 http://playbw.tw (天天登入天天領1,500金幣，共45,000金幣)\
      v_msg := 'LiTV線上影視已收到您的訂單<purchase_no>金額$<amount>明細請至網路會員專區查詢。宅神爺送您發財金！儲值序號：<coupon_id>。儲值入口 http://playbw.tw (天天登入天天領1,500金幣，共45,000金幣)';

      select rowid rid, coupon_id
        into v_rid, v_coupon_id
        from bonuswinner_cups
       where start_date <= trunc(sysdate)
         and end_date >= trunc(sysdate)
         and serial_id is null
         and status_flg = 'P'
         and rownum <= 1;
      update bonuswinner_cups
         set status_flg  = 'Z',
             serial_id   = p_client_id,
             purchase_no = p_purchase_no,
             send_date   = sysdate
       where rowid = v_rid;
      commit;
      v_msg := replace(v_msg, '<amount>', p_amount);
      v_msg := replace(v_msg, '<purchase_no>', p_purchase_no);
      v_msg := replace(v_msg, '<coupon_id>', v_coupon_id);
      v_msg := bsm_sms_service.send_sms_text('8080', v_msg, p_phone_no);
       v_result := 'Y';
    exception
      when no_data_found then
        v_result := 'N';
    end;
  elsif (p_type = 'receive' and p_pay_type in ('匯款', 'ATM', '其他', 'REMIT', '中華電信ATM')) then

    declare
      v_rid       rowid;
      v_coupon_id varchar2(32);
      v_msg       varchar2(1024);
    begin
      v_msg := 'LiTV已收到您的繳費金額$<amount>訂單<purchase_no>，可立即使用購買的服務，到期日請至電視或官網會員專區查詢。宅神爺送發財金 http://playbw.tw 儲值序號：<coupon_id>(天天登入天天領1,500金幣，共45,000)';
             -- LiTV已收到您的繳費金額{5碼}訂單{17碼}，可立即使用購買的服務，到期日請至電視或官網會員專區查詢。宅神爺送發財金 http://playbw.tw 儲值序號：<20碼序號>(天天登入天天領1,500金幣，共45,000)
      select rowid rid, coupon_id
        into v_rid, v_coupon_id
        from bonuswinner_cups
       where start_date <= trunc(sysdate)
         and end_date >= trunc(sysdate)
         and serial_id is null
         and status_flg = 'P'
         and rownum <= 1;
      update bonuswinner_cups
         set status_flg  = 'Z',
             serial_id   = p_client_id,
             purchase_no = p_purchase_no,
             send_date   = sysdate
       where rowid = v_rid;
      commit;
      v_msg := replace(v_msg, '<amount>', p_amount);
      v_msg := replace(v_msg, '<purchase_no>', p_purchase_no);
      v_msg := replace(v_msg, '<coupon_id>', v_coupon_id);
      v_msg := bsm_sms_service.send_sms_text('8080', v_msg, p_phone_no);
      v_result := 'Y';
    exception
      when no_data_found then
        v_result := 'N';
    end;
  end if;
  return v_result;
end;
/

