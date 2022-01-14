create or replace function iptv.bsm_purchase_dtls(p_pk_no number)
  return purchase_coupon_item_dtls
  pipelined as

begin
  declare
    cursor c1 is
      select pk_no,
             mas_pk_no,
             package_id,
             a.package_dtls,
             a.amount       amt,
             a.tax_amt,
             a.amount       net_amt
        from bsm_purchase_item a
       where a.package_dtls is not null
        and a.mas_pk_no = p_pk_no;
    p_json            json_list;
    v_dtl             purchase_coupon_item_dtl;
    p_package_json_ar json_list;
    v_amt number(16);
    v_tax_amt number(16);
    v_net_amt number(16);

  begin

    for i in c1 loop
      if i.package_dtls is not null then
        p_json := Json_list(i.package_dtls);
        for j in 1 .. p_json.count() loop
          p_package_json_ar := json_ext.get_json_list(Json(p_json.list_data(j)),
                                                      'cup_package_id');
          if j = 1 then
              v_amt := i.amt;
              v_net_amt := i.amt-i.tax_amt;
              v_tax_amt := i.tax_amt;
          else
             v_amt := 0;
             v_net_amt:= 0;
             v_tax_amt :=0;
          end if;
          if p_package_json_ar is not null and p_package_json_ar.count() > 0 then
          for k in 1 .. p_package_json_ar.count() loop
            v_dtl := new
                     purchase_coupon_item_dtl(j - 1,
                                              i.pk_no,
                                              i.mas_pk_no,
                                              i.package_id,
                                              json_ext.get_string(Json(p_json.list_data(j)),
                                                                  'client_id'),
                                              json_ext.get_string(Json(p_package_json_ar.list_data(k)),
                                                                  'package_id'),
                                              json_ext.get_string(Json(p_json.list_data(j)),
                                                                  'coupon_id'),

                                              v_amt,
                                              v_tax_amt,
                                              v_net_amt,
                                              json_ext.get_string(Json(p_json.list_data(j)),
                                                                  'desc'));
            pipe row(v_dtl);
          end loop;
          end if;
        end loop;
      end if;
    end loop;
  end;
  return;
end;
/

