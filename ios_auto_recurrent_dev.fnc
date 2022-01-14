﻿create or replace function iptv.ios_auto_recurrent_dev(p_pk_no number)
  return varchar2 is
  v_result varchar2(1024);
begin
  declare
    cursor c1 is
      Select tb.serial_id,
             tb.mas_no purchase_id,
             tb.pk_no,
             
             td.start_date,
             td.pk_no            detail_pk_no,
             tf.ios_product_code,
             recurrent_type,
             ta.pk_no            recurrent_pk_no,
             tb.software_group
        from bsm_recurrent_mas   ta,
             bsm_purchase_mas    tb,
             bsm_purchase_item   tc,
             bsm_client_details  td,
             bsm_package_mas     te,
             bsm_ios_receipt_mas tf
      
       where tb.status_flg = 'Z'
         and tb.mas_no = ta.src_no
            --  and ta.status_flg = 'P'
         and tc.mas_pk_no = tb.pk_no
         and td.src_item_pk_no = tc.pk_no
         and te.package_id = td.package_id
         and tf.mas_pk_no(+) = tb.pk_no
         and ta.recurrent_type = 'IOS'
         and tb.pk_no = p_pk_no
       order by tb.purchase_date desc;
    v_msg            varchar2(1024);
    v_flg            boolean;
    rec_data         clob;
    rec_result       json;
    rec_result_data  json;
    rec_status       varchar2(8);
    receipt_data     json;
    in_app           json_list;
    in_app_l         json_list;
    rep_data         json;
    transaction_id   varchar2(1024);
    v_package        varchar2(128);
    v_mas_no         varchar2(1024);
    v_software_group varchar2(1024);
    v_auto_renew     varchar2(1024);
  begin
    utl_http.set_transfer_timeout(6000);
    for i in c1 loop
      if i.recurrent_type = 'IOS' then
        begin
          rec_data        := bsm_ios_gateway.get_Receipt_Data(i.pk_no,
                                                              null,
                                                              null,
                                                              null);
          rec_data        := replace(rec_data,
                                     '"latest_receipt_info"',
                                     '"lreceipt"');
          rec_result_data := json(rec_data);
          rec_result      := json_ext.get_json(rec_result_data, 'result');
          rec_status      := to_CHAR(json_ext.get_number(rec_result,
                                                         'status'));
          begin
            v_auto_renew := to_CHAR(json_ext.get_number(rec_result,
                                                        'auto_renew_status'));
            if v_auto_renew is null then
              v_auto_renew := to_CHAR(json_ext.get_number(rec_result,
                                                          'pending_renewal_info.auto_renew_status'));
            end if;
          exception
            when others then
              begin
                v_auto_renew := to_CHAR(json_ext.get_number(rec_result,
                                                            'pending_renewal_info.auto_renew_status'));
              exception
                when no_data_found then
                  null;
              end;
          end;
          if rec_status = '0' then
          
            in_app := json_ext.get_json_list(rec_result, 'lreceipt');
          
            if (in_app is not null) then
              for j in 1 .. in_app.COUNT() loop
                rep_data := Json(jsonlist_get(in_app, j - 1));
              
                begin
                  if json_ext.get_string(rep_data, 'product_id') =
                     'com.litv.mobile.as.lep.month' then
                    v_package := 'com.litv.mobile.as.lep.once.channel.all';
                  else
                    v_package := json_ext.get_string(rep_data, 'product_id');
                  end if;
                  v_software_group := 'LTIOS05';
                  declare
                    v_cancel_date    varchar2(32);
                    v_loc_can_date   date;
                    v_purchase_pk_no number(16);
                    v_client_Id      varchar(32);
                    v_pur_pk_no      varchar(32);
                  
                  begin
                    v_cancel_date  := json_ext.get_string(rep_data,
                                                          'cancellation_date');
                    v_loc_can_date := to_date(substr(v_cancel_date, 1, 19),
                                              'YYYY-MM-DD HH24:MI:SS') +
                                      8 / 24;
                  if v_cancel_date is not null then
                           select pk_No, serial_id
                      into v_purchase_pk_no, v_client_Id
                      from bsm_purchase_mas c
                     where c.ios_trans_id =
                           json_ext.get_string(rep_data, 'transaction_id');
             
                    update bsm_client_details a
                       set a.end_date = v_loc_can_date
                     where a.src_pk_no = v_purchase_pk_no;
                    commit;
                    v_pur_pk_no := to_char(v_purchase_pk_no);
                    bsm_client_service.Set_subscription(v_purchase_pk_no,
                                                        v_client_Id);
                  end if;
                  exception
                    when others then
                      null;
                  end;
                
                  crt_purchase_ios_dev('IOS',
                                       i.serial_id,
                                       null,
                                       v_package,
                                       json_ext.get_string(rep_data,
                                                           'original_transaction_id'), --p_ios_org_trans_id varchar2,
                                       json_ext.get_string(rep_data,
                                                           'transaction_id'), -- p_ios_trans_id     varchar2,
                                       null,
                                       v_mas_no,
                                       json_ext.get_string(rep_data,
                                                           'purchase_date'), --p_purchase_date    varchar2,
                                       json_ext.get_string(rep_data,
                                                           'expires_date'),
                                       null,
                                       v_software_group);
                
                end;
              end loop;
            else
              receipt_data := json_ext.get_json(rec_result, 'lreceipt');
              begin
                in_app := json_ext.get_json_list(receipt_data, 'in_app');
              
                if in_app is not null then
                  dbms_output.put_line(json_ext.get_string(rec_result_data,
                                                           'in_app'));
                
                  for j in 1 .. in_app.COUNT() loop
                    rep_data := Json(jsonlist_get(in_app, j - 1));
                  
                    begin
                      if json_ext.get_string(rep_data, 'product_id') =
                         'com.litv.mobile.as.lep.month' then
                        v_package := 'com.litv.mobile.as.lep.once.channel.all';
                      else
                        v_package := json_ext.get_string(rep_data,
                                                         'product_id');
                      end if;
                      v_software_group := 'LTIOS05';
                      crt_purchase_ios_dev('IOS',
                                           i.serial_id,
                                           null,
                                           v_package,
                                           json_ext.get_string(rep_data,
                                                               'original_transaction_id'), --p_ios_org_trans_id varchar2,
                                           json_ext.get_string(rep_data,
                                                               'transaction_id'), -- p_ios_trans_id     varchar2,
                                           null,
                                           v_mas_no,
                                           json_ext.get_string(rep_data,
                                                               'purchase_date'), --p_purchase_date    varchar2,
                                           json_ext.get_string(rep_data,
                                                               'expires_date'),
                                           null,
                                           v_software_group);
                    
                    end;
                  end loop;
                else
                  v_software_group := 'LTIOS03';
                  crt_purchase_ios_dev('IOS',
                                       i.serial_id,
                                       null,
                                       json_ext.get_string(receipt_data,
                                                           'product_id'),
                                       json_ext.get_string(receipt_data,
                                                           'original_transaction_id'), --p_ios_org_trans_id varchar2,
                                       json_ext.get_string(receipt_data,
                                                           'transaction_id'), -- p_ios_trans_id     varchar2,
                                       null,
                                       v_mas_no,
                                       json_ext.get_string(receipt_data,
                                                           'purchase_date'), --p_purchase_date    varchar2,
                                       json_ext.get_string(receipt_data,
                                                           'expires_date_formatted'),
                                       null,
                                       v_software_group);
                end if;
              end;
            end if;
          
            --   if receipt_data is null then
            receipt_data := json_ext.get_json(rec_result, 'receipt');
            --   end if;
          
            begin
              in_app := json_ext.get_json_list(receipt_data, 'in_app');
            
              if in_app is not null then
                dbms_output.put_line(json_ext.get_string(rec_result_data,
                                                         'in_app'));
              
                for j in 1 .. in_app.COUNT() loop
                  rep_data := Json(jsonlist_get(in_app, j - 1));
                
                  begin
                    if json_ext.get_string(rep_data, 'product_id') =
                       'com.litv.mobile.as.lep.month' then
                      v_package := 'com.litv.mobile.as.lep.once.channel.all';
                    else
                      v_package := json_ext.get_string(rep_data,
                                                       'product_id');
                    end if;
                    v_software_group := 'LTIOS05';
                    crt_purchase_ios_dev('IOS',
                                         i.serial_id,
                                         null,
                                         v_package,
                                         json_ext.get_string(rep_data,
                                                             'original_transaction_id'), --p_ios_org_trans_id varchar2,
                                         json_ext.get_string(rep_data,
                                                             'transaction_id'), -- p_ios_trans_id     varchar2,
                                         null,
                                         v_mas_no,
                                         json_ext.get_string(rep_data,
                                                             'purchase_date'), --p_purchase_date    varchar2,
                                         json_ext.get_string(rep_data,
                                                             'expires_date'),
                                         null,
                                         v_software_group);
                  
                  end;
                end loop;
              else
                v_software_group := 'LTIOS03';
                crt_purchase_ios_dev('IOS',
                                     i.serial_id,
                                     null,
                                     json_ext.get_string(receipt_data,
                                                         'product_id'),
                                     json_ext.get_string(receipt_data,
                                                         'original_transaction_id'), --p_ios_org_trans_id varchar2,
                                     json_ext.get_string(receipt_data,
                                                         'transaction_id'), -- p_ios_trans_id     varchar2,
                                     null,
                                     v_mas_no,
                                     json_ext.get_string(receipt_data,
                                                         'purchase_date'), --p_purchase_date    varchar2,
                                     json_ext.get_string(receipt_data,
                                                         'expires_date_formatted'),
                                     null,
                                     v_software_group);
              end if;
            end;
          
          elsif rec_status = '21006' then
            v_msg := bsm_recurrent_util.stop_recurrent(i.serial_id,
                                                       i.purchase_id,
                                                       'IOS系統取消');
          end if;
        
          if v_auto_renew = '0' then
            v_msg := bsm_recurrent_util.stop_recurrent(i.serial_id,
                                                       i.purchase_id,
                                                       'IOS系統取消');
          end if;
        end;
      end if;
    end loop;
  end;
  return null;
end;
/
