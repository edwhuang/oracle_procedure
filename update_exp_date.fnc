create or replace function iptv.update_exp_date(p_order_no varchar2) return varchar2
    is
          rw_result clob;
    jsonobj json;
    status_flg varchar2(32);
    v_return_end varchar2(64);
  begin
    rw_result := bsm_ios_gateway.get_Receipt_Data(p_order_no,'','','');
    jsonobj:=json(rw_result);

        v_return_end := json_ext.get_string(jsonobj,'result.latest_receipt_info.expires_date_formatted');

    return v_return_end;
  end;
/

