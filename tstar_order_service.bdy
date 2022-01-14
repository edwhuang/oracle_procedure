CREATE OR REPLACE PACKAGE BODY IPTV.TSTAR_ORDER_SERVICE is
  queue_name_setting varchar2(1024) := 'purchase_msgp_queue';
  function tstar_order(p_order             varchar2,
                       p_start_form_active varchar2 default null)
    return varchar2 is
    v_result         varchar2(1024);
    v_action         varchar2(23);
    v_scvId          varchar2(23);
    v_orderId        varchar2(23);
    v_contractId     varchar2(23);
    v_msisdn         varchar2(23);
    v_msisdnNew      varchar2(23);
    v_modifyDate     Date;
    v_orderDate      Date;
    v_isFirst        varchar2(23);
    v_client_id      varchar2(1024);
    v_phone_no       varchar2(23);
    v_reqCreateTime  Date;
    j_order          json;
    v_id             varchar2(32);
    v_Purchase_No    varchar2(32);
    v_Purchase_Pk_No number(16, 3);
    v_msg            varchar2(1024);
    v_mas_no         varchar2(32) := v_orderId;
    v_client_status  varchar2(32);
    v_real_mac       varchar2(32);
    v_mas_date       date;
  begin
      
    begin
      j_order := JSON(p_order);
    
   
      begin
        v_id := json_ext.get_string(j_order, 'id');
      exception
        when others then
          v_id := '';
      end;
    
      begin
        v_scvId := json_ext.get_string(j_order, 'scvId');
      exception
        when others then
          v_scvId := '';
      end;
    
      begin
        v_orderId := json_ext.get_string(j_order, 'orderId');
      exception
        when others then
          v_orderId := '';
      end;
    
      begin
        v_action := json_ext.get_string(j_order, 'action');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_contractId := json_ext.get_string(j_order, 'contractId');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_msisdn := json_ext.get_string(j_order, 'msisdn');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_msisdnNew := json_ext.get_string(j_order, 'msisdnNew');
      exception
        when others then
          v_msisdnNew := '';
      end;
      begin
        v_modifyDate := to_date(json_ext.get_string(j_order, 'modifyDate'),
                                'YYYY/MM/DD HH24:MI:SS');
      exception
        when others then
          v_modifyDate := null;
      end;
      begin
        v_orderDate := to_date(json_ext.get_string(j_order, 'orderDate'),
                               'YYYY/MM/DD HH24:MI:SS');
      exception
        when others then
          raise lost_data;
      end;
      begin
        v_isFirst := json_ext.get_string(j_order, 'isFirst');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_reqCreateTime := to_date(json_ext.get_string(j_order,
                                                       'reqCreateTime'),
                                   'YYYY/MM/DD HH24:MI:SS');
      exception
        when others then
          raise lost_data;
      end;
    
    end;
  
    if v_action = 'createservice' then
      begin
        select a.mas_no
          into v_Purchase_No
          from bsm_purchase_mas a
         where a.src_no = v_orderId
           and rownum <= 1;
        raise dup_order;
      exception
        when no_data_found then
          null;
      end;
      
       begin
        select serial_id, status_flg,real_mac_address
          into v_client_id, v_client_status,v_real_mac
          from bsm_client_mas a
         where a.owner_phone = v_msisdn
           and serial_id like '2A%'
              --   and status_flg = 'A'
           and rownum <= 1;
        if v_client_status = 'R' then
          declare
            -- Non-scalar parameters require additional processing 
            result         tbsm_result;
            in_client_info tbsm_client_info;
          begin
            in_client_info             := new tbsm_client_info();
            in_client_info.serial_id   := v_client_id;
            in_client_info.mac_address := v_real_mac;
            in_client_info.owner_phone := v_msisdn;
            -- Call the function
            result := bsm_client_service_dev.activate_client(in_client_info    => in_client_info,
                                                         parameter_options => '{"refresh_client":"N"}');
          end;
        end if;
      exception
        when no_data_found then
          v_client_id := null;
      end;
    
   
      if v_client_id is null then
        declare
          v_char varchar2(32);
        begin
          select 'x'
            into v_char
            from tstar_order
           where src_order_id = v_orderid
             and rownum <= 1;
          raise dup_order;
        exception
          when no_data_found then
            insert into tstar_order
              (src_id,
               src_order_id,
               order_date,
               action,
               scvid,
               orderid,
               contractid,
               msisdn,
               msisdnnew,
               orderdate,
               isfirst,
               reqcreatetime,
               status_flg,
               order_DATA)
            values
              (v_id,
               v_orderId,
               v_orderDate,
               v_action,
               v_scvid,
               v_orderid,
               v_contractid,
               v_msisdn,
               v_msisdnnew,
               v_orderDate,
               v_isfirst,
               v_reqCreateTime,
               'A',
               p_order);
            commit;
        end;
      
   /*     v_msg    := bsm_sms_service.Send_Sms_Messeage(v_msisdn,
                                                      '台灣之星LiTV會員,通知您已成功開通優惠專案。提醒您:(1)先下載 LiTV APP。(2)以此手機門號註冊成為 LiTV 會員，登入後即可開始使用。下載LiTV App連結 http://smarturl.it/litvtstar');
                                                      */
        v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"","client_id":""}';
      else
        declare
          v_char varchar2(32);
        begin
          select 'x'
            into v_char
            from tstar_order
           where src_order_id = v_orderid
             and rownum <= 1;
        exception
          when no_data_found then
            insert into tstar_order
              (src_id,
               src_order_id,
               order_date,
               action,
               scvid,
               orderid,
               contractid,
               msisdn,
               msisdnnew,
               orderdate,
               isfirst,
               reqcreatetime,
               status_flg,
               order_DATA)
            values
              (v_id,
               v_orderId,
               v_orderDate,
               v_action,
               v_scvid,
               v_orderid,
               v_contractid,
               v_msisdn,
               v_msisdnnew,
               v_orderDate,
               v_isfirst,
               v_reqCreateTime,
               'A',
               p_order);
            commit;
        end;
      
        declare
          p_src_prog_no         varchar2(32) := 'TSTART';
          p_gift_package_id     varchar2(32) := 'WD0001';
          v_purchase_item_pk_no number(16);
          v_charge_name         varchar2(32);
          v_char                varchar2(32);
          v_src_no              varchar2(32);
          v_device_id           varchar2(32);
          v_start_days          number(16);
          v_include_first_day  number(16);
          v_seq                 number(16);
         p_packages            varchar2(2024) := 'SVC20161103170055042,WDS001,R,0,M,0,199
SVC20161103155503941,WDS001,R,0,M,0,199         
SVC20170509193803398,WD0006,R,0,M,0,179
SVC20170524155901417,WD0006,R,0,M,0,179
SVC20170517141210972,WD0007,R,0,M,0,199
SVC20170524155249818,WD0007,R,0,M,0,199
SVC20180306135755302,WDS005,O,0,S,0,0
SVC20180306135755302,WDS005,R,1,M,31,0
SVC20180306171759637,WDS006,R,0,M,0,0
SVC20180312100800789,WDS005,O,0,S,0,0
SVC20180312100800789,WDS005,R,1,M,31,179
SVC20180319194019475,WDS005,R,0,M,0,159
SVC20180319185710125,WDS005,O,0,S,0,0
SVC20180319185710125,WDS005,R,1,M,31,179
SVC20180309154616550,WDS005,R,0,M,0,159
SVC20180426104121726,CD0008,R,0,M,0,120
SVC20180508194550823,CD0008,R,0,M,0,120
SVC20180426201747631,CD0001,R,0,M,0,159
SVC20180508195105059,CD0001,R,0,M,0,159
SVC20210520161834010,XD0001,R,0,M,0,249
SVC20210520162010794,XD0012,R,0,M,0,2388
SVC20210520164115318,XD0015,R,0,M,0,4512
SVC20210520164240437,XD0015,R,0,M,0,4512
SVC20210520153826435,XD0001,R,0,M,0,249
SVC20210520155305153,XD0012,R,0,M,0,2388
SVC20210520155648892,XD0015,R,0,M,0,4512
SVC20210520160021337,XD0015,R,0,M,0,4512';
          cursor c1(p_srv_id varchar2) is
            Select *
              from (select substr(COLUMN_VALUE,
                                  0,
                                  instr(COLUMN_VALUE, ',', 1, 1) - 1) srv_id,
                           substr(COLUMN_VALUE,
                                  instr(COLUMN_VALUE, ',', 1, 1) + 1,
                                  instr(COLUMN_VALUE, ',', 1, 2) -
                                  instr(COLUMN_VALUE, ',', 1, 1) - 1) package_id,
                           substr(COLUMN_VALUE,
                                  instr(COLUMN_VALUE, ',', 1, 2) + 1,
                                  instr(COLUMN_VALUE, ',', 1, 3) -
                                  instr(COLUMN_VALUE, ',', 1, 2) - 1) recurrent,
                           to_number(substr(COLUMN_VALUE,
                                            instr(COLUMN_VALUE, ',', 1, 3) + 1,
                                            instr(COLUMN_VALUE, ',', 1, 4) -
                                            instr(COLUMN_VALUE, ',', 1, 3) - 1)) seq,
                           substr(COLUMN_VALUE,
                                  instr(COLUMN_VALUE, ',', 1, 4) + 1,
                                  instr(COLUMN_VALUE, ',', 1, 5) -
                                  instr(COLUMN_VALUE, ',', 1, 4) - 1) main_pack,
                           substr(COLUMN_VALUE,
                                  instr(COLUMN_VALUE, ',', 1, 5) + 1,
                                  instr(COLUMN_VALUE, ',', 1, 6) -
                                  instr(COLUMN_VALUE, ',', 1, 5) - 1
                                  ) start_days,
                           substr(COLUMN_VALUE,
                                  instr(COLUMN_VALUE, ',', 1, 6) + 1) amount       
                      from TABLE(str2tbl(p_packages)))
             where srv_id = p_srv_id;
        begin
          /*
                    SVC20161103170055042 => 199第一個月免費(Phase1)
                    SVC20170509193803398 => 179X12M=2148(current phase)
                    
                    SVC20170517141210972 => 199X12M=(current phase)
                    
                    LiTV頻道全餐_加值型：SVC20180306135755302
                    
                    LiTV頻道全餐_12M型：SVC20180306171759637
                    
                    測試機 - UAT
          LiTV頻道全餐_加值型：SVC20180306135755302
          LiTV頻道全餐_12M型：SVC20180306171759637
          正式機 - PROD
          LiTV頻道全餐_加值型：SVC20180312100800789
          LiTV頻道全餐_12M型：SVC20180309154616550
                    */
          
          v_seq := 0;
          for i in c1(v_scvId) loop
          
            p_gift_package_id := i.package_id;
            /* 主方案需掛合約 */
            if i.main_pack = 'M' or
               (i.main_pack = 'S' and nvl(v_isFirst, '0') = '0') then
              v_mas_no := v_orderId;
            else
              v_mas_no := v_orderId || '_' || i.seq;
            end if;
            
            if v_seq = 0 then 
              v_start_days := 0;
              v_include_first_day:=1;
            else
              v_start_days := i.start_days;
              v_include_first_day:=0;
            end if;
            
            v_seq:= v_seq+1;
            
          
            select 'x'
              into v_char
              from bsm_client_mas
             where mac_address = v_client_id
               for update;
          
            declare
              v_acc_invo_no       varchar2(32);
              v_pay_type          varchar2(32) := 'TSTAR';
              v_Client_Info       Tbsm_Client_Info;
              v_acc_name          varchar2(32);
              v_tax_code          varchar2(32);
              v_Purchase_Mas_Code varchar(32) := 'BSMPUR';
              v_Serial_No         number(16);
              v_id                varchar2(32);
              v_Price             number(16);
              v_Duration          number(16);
              v_Quota             number(16);
              v_charge_type       varchar2(32);
              v_charge_code       varchar2(32);
              v_start_type        varchar2(32);
              v_recurrent         varchar2(32);
            
              p_user_no number(16) := 0;
            
            begin
            
              v_Client_Info := bsm_client_service.Get_Client_Info(v_client_id);
              dbms_output.put_line(v_client_info.mac_address);
              v_Serial_No := v_client_info.serial_no;
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_Purchase_Pk_No
                From Dual;
            
              v_Purchase_Mas_Code := 'BSMPUR';
            
              v_Purchase_No := Sysapp_Util.Get_Mas_No(1,
                                                      2,
                                                      Sysdate,
                                                      v_Purchase_Mas_Code,
                                                      v_Purchase_Pk_No);
              v_acc_invo_no := sysapp_util.get_mas_no(1,
                                                      2,
                                                      sysdate,
                                                      'BSMPUR_INV',
                                                      v_Purchase_Pk_No);
            
              if v_Client_Info.Owner_ID is not null then
                begin
                  select cust_name, tax_code
                    into v_acc_name, v_tax_code
                    from tgc_customer
                   where cust_id = v_Client_Info.Owner_ID;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
              
            if (i.main_pack = 'S' and nvl(v_isFirst, '0') = '0') then
              v_recurrent:='O';
         
            else
              v_recurrent:='R';
            end if;

              Insert Into Bsm_Purchase_Mas
                (Src_No,
                 Pk_No,
                 Mas_No,
                 Mas_Date,
                 Mas_Code,
                 Src_Code,
                 Src_Date,
                 Serial_No,
                 acc_code,
                 Serial_Id,
                 Status_Flg,
                 Purchase_Date,
                 Pay_Type,
                 Card_type,
                 Card_no,
                 Card_Expiry,
                 Cvc2,
                 inv_no,
                 f_year,
                 f_period,
                 due_date,
                 acc_name,
                 tax_code,
                 recurrent,
                 start_type)
              Values
                (v_mas_no,
                 v_Purchase_Pk_No,
                 v_Purchase_No,
                 Sysdate,
                 v_Purchase_Mas_Code,
                 Null,
                 Null,
                 v_Serial_No,
                 v_Client_Info.Owner_ID,
                 v_client_Id,
                 'A',
                 Sysdate+v_start_days,
                 v_Pay_Type,
                 null,
                 null,
                 null,
                 null,
                 v_acc_invo_no,
                 to_number(to_char(sysdate, 'YYYY')),
                 to_number(to_char(sysdate, 'MM')),
                 sysdate + 7,
                 v_acc_name,
                 null,
                 v_recurrent,
                 'S');
            
              --
              --  計算價格
              --
              v_id := p_gift_package_id;
              Begin
                Select a.Charge_Amount,
                       a.Acl_Duration,
                       a.Acl_Quota,
                       a.charge_type,
                       a.charge_code
                  Into v_Price,
                       v_Duration,
                       v_Quota,
                       v_charge_type,
                       v_charge_code
                  From Bsm_Package_Mas a
                 Where a.Package_id = v_id;
              
              End;
              
            if (i.main_pack = 'S' and nvl(v_isFirst, '0') = '0') then
              v_recurrent:='O';
              v_Price := 0;
            else
              v_recurrent:='R';
            end if;
            
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_Purchase_Item_Pk_No
                From Dual;
            
              if v_charge_code is null then
                v_charge_code := sysapp_util.get_sys_value('BSMPUR',
                                                           'Default charge code',
                                                           'PMONTHFEE');
              end if;
            
              begin
                select chg_name
                  into v_charge_name
                  from service_charge_mas
                 where chg_code = v_charge_code;
              exception
                when no_data_found then
                  v_charge_code := 'PMONTHFEE';
                  v_charge_name := '預付月租費';
              end;
              v_price := to_number(i.amount);
            
              Insert Into Bsm_Purchase_Item
                (Pk_No,
                 Mas_Pk_No,
                 Package_ID,
                 ITEM_ID,
                 Price,
                 Amount,
                 Duration,
                 CHG_TYPE,
                 CHG_CODE,
                 CHG_NAME,
                 TAX_AMT,
                 CHG_AMT,
                 TOTAL_AMT,
                 DEVICE_ID)
              Values
                (v_Purchase_Item_Pk_No,
                 v_Purchase_Pk_No,
                 v_id,
                 null,
                 v_Price,
                 v_Price,
                 v_Duration,
                 v_charge_type,
                 v_charge_code,
                 v_charge_name,
                 0,
                 0,
                 v_Price,
                 v_device_id);
            
              declare
                v_msg number(16);
              begin
                v_msg := bsm_purchase_post.purchase_post(p_user_no,
                                                         v_purchase_pk_no);
                v_msg := bsm_purchase_post.purchase_complete_r(p_user_no,
                                                             v_purchase_pk_no,'N');
              end;
              /*
              SVC20161103170055042 => 199第一個月免費(Phase1)
              SVC20170509193803398 => 179X12M=2148(current phase)
              
              SVC20170517141210972 => 199X12M=(current phase)
              
              */
              if v_scvid in
                 ('SVC20161103170055042', 'SVC20161103155503941') then
              
                update bsm_client_details a
                   set a.start_date = nvl(v_modifyDate, sysdate),
                       a.end_date   = decode(nvl(v_isFirst, '0'),
                                             '0',
                                             nvl(v_modifyDate, sysdate) + 60,
                                             nvl(v_modifyDate, sysdate) + 30)
                 where a.src_pk_no = v_Purchase_Pk_No;
                commit;
              else
                update bsm_client_details a
                   set a.start_date = a.start_date + v_start_days,
                       a.end_date   = a.end_date + v_start_days+v_include_first_day
                
                 where a.src_pk_no = v_Purchase_Pk_No;
                commit;
              
              end if;
              
              bsm_client_service.Set_subscription_r(v_purchase_pk_no,
                                                  v_client_id,'N');
            
            end;
            if i.recurrent = 'R' then
              declare
                v_recurrent_pk_no number(16);
                v_recurrent_type  varchar2(64);
                v_cht_subno       varchar2(64);
                v_cht_auth        varchar2(64);
              
              begin
                Select Seq_Bsm_Purchase_Pk_No.Nextval,
                       x.cht_subscribeno,
                       x.cht_auth
                  Into v_recurrent_pk_no, v_cht_subno, v_cht_auth
                  From bsm_purchase_mas x
                 where pk_no = v_Purchase_Pk_No;
                v_recurrent_type := 'TSTAR';
              
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
                   v_Purchase_No,
                   null,
                   null,
                   null,
                   null,
                   sysdate,
                   'P',
                   v_client_id,
                   null,
                   null,
                   null,
                   v_orderDate,
                   null,
                   null,
                   'A');
              
                update tstar_order a
                   set a.status_flg  = 'Z',
                       register_date = sysdate,
                       client_id     = v_client_id
                 where src_order_id = v_orderid;
              
                commit;
              end;
            end if;
          end loop;
           bsm_client_service.refresh_bsm_client(v_client_Id,
                                                      queue_name_setting);
           v_msg := bsm_cdi_service.refresh_client(v_client_Id,
                                                      queue_name_setting);
        
          v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                      v_Purchase_No || '","client_id":"' || v_client_id || '"}';
          return v_result;
        exception
          when no_data_found then
            null;
        end;
      
        if p_start_form_active is null then
          declare
            v_char varchar2(1);
            v_package_cat1 varchar2(128);
          begin
            select 'x',b.package_cat1
              into v_char,v_package_cat1
              from bsm_client_details a,
                   bsm_package_mas    b,
                   bsm_purchase_mas   c
             where a.status_flg = 'P'
               and a.end_date >= sysdate
               and a.package_id = b.package_id
               and b.package_cat_id1 in ('ALL', 'CHANNEL', 'VOD_CHANNEL')
               and c.pk_no = a.src_pk_no
               and a.serial_id = v_client_Id
               and c.src_no != v_orderId
               and rownum <= 1;
     /*       v_msg := bsm_sms_service.Send_Sms_Messeage(v_msisdn,
                                                       '台灣之星LiTV會員,通知您已成功開通【'||v_package_cat1||'】優惠專案。提醒您:(1)先下載 LiTV APP。(2)以此手機門號登入 LiTV 會員，即可開始使用此優惠。(3)提醒您，此門號目前仍有付費使用 LiTV服務，請務必來電 LiTV 客服02-7707-0708 取消原方案，以免重複扣款。下載LiTV App連結 http://smarturl.it/litvtstar');
                                                       */
          exception
            when no_data_found then
              null;
/*              v_msg := bsm_sms_service.Send_Sms_Messeage(v_msisdn,
                                                         '台灣之星LiTV會員,通知您已成功開通優惠專案。提醒您:(1)先下載 LiTV APP。(2)以此手機門號登入 LiTV 會員，即可開始使用此優惠。下載LiTV App連結 http://smarturl.it/litvtstar');
                                                         */
          end;
        end if;
      
        --  hjkhj         
      
      end if;
    elsif v_action = 'cancelservice' then
      begin
        select serial_id
          into v_client_id
          from bsm_client_mas a
         where a.owner_phone = v_msisdn
           and serial_id like '2A%'
           and rownum <= 1;
      exception
        when no_data_found then
          null;
          null;
      end;
      
      declare 
        v_end_date date;
        v_start_date date;
        v_status_flg varchar2(32);
        
    
      begin
        select a.mas_no, a.pk_no,mas_date
          into v_Purchase_No, v_Purchase_Pk_No,v_mas_date
          from bsm_purchase_mas a
         where a.src_no = v_orderId
           and a.amount > 0
           and rownum <= 1;
           
        select a.start_date,a.start_date +ceil((sysdate + 0.5 - a.start_date) / 30) * 30,status_flg 
        into v_start_date,v_end_date,v_status_flg 
        from   bsm_client_details a
        where a.src_pk_no = v_Purchase_Pk_No and rownum <=1; 
        if v_end_date <= v_start_date then
          v_status_flg :='N';
        end if; 
          
           -- 日期早於2020-11-09 的到期日延後三天
      if v_mas_date <= to_date('2020/11/09','YYYY/MM/DD') then
        update bsm_client_details a
           set a.end_date =v_end_date+3,
               a.status_flg=v_status_flg
         where a.src_pk_no = v_Purchase_Pk_No;
      else
                update bsm_client_details a
           set a.end_date =v_end_date+3,
               a.status_flg=v_status_flg
         where a.src_pk_no = v_Purchase_Pk_No;
      end if;
      
        bsm_client_service.Set_subscription(0, v_client_id);
      
        v_msg := bsm_recurrent_util.stop_recurrent(v_client_id,
                                                   v_Purchase_No,
                                                   'TSTAR 停租');
        update tstar_order a
           set status_flg = 'C'
         where a.src_order_id = v_orderId;
         
         if v_status_flg ='N' then
           update bsm_purchase_mas 
           set status_flg='C'
           where pk_no=v_Purchase_Pk_No;
           
           bsm_purchase_post.refresh_bsm_client(v_client_id);
         end if; 
        

      
      exception
        when no_data_found then
          declare
            v_order_no varchar2(32);
          begin
            select a.src_order_id
              into v_order_no
              from tstar_order a
             where a.src_order_id = v_orderId
               and rownum <= 1;
            update tstar_order a
               set status_flg = 'C'
             where a.src_order_id = v_orderId;
            commit;
          exception
            when no_data_found then
              raise order_not_found;
          end;
      end;
    
      v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                  v_Purchase_No || '","client_id":"' || v_client_id || '"}';
    
    end if;
  
    return v_result;
  
  exception
    when lost_data then
      return '{result_code:"BSM-00800",result_message:"null field","purchase_no":"","client_id":""}';
    when no_client_found then
      return '{result_code:"BSM-00801",result_message:"phone number not found","purchase_no":"","client_id":""}';
    when no_data_found then
      return '{result_code:"BSM-00802",result_message:"order not found","purchase_no":"","client_id":""}';
    when dup_order then
      return '{result_code:"BSM-00000",result_message:"訂單重複","purchase_no":"","client_id":""}';
    when order_not_found then
      return '{result_code:"BSM-00802",result_message:"order not found","purchase_no":"","client_id":""}';
  end;
  
  function tstar_order2(p_order             varchar2,
                       cancel_date date default null)
    return varchar2 is
    v_result         varchar2(1024);
    v_action         varchar2(23);
    v_scvId          varchar2(23);
    v_orderId        varchar2(23);
    v_contractId     varchar2(23);
    v_msisdn         varchar2(23);
    v_msisdnNew      varchar2(23);
    v_modifyDate     Date;
    v_orderDate      Date;
    v_isFirst        varchar2(23);
    v_client_id      varchar2(1024);
    v_phone_no       varchar2(23);
    v_reqCreateTime  Date;
    j_order          json;
    v_id             varchar2(32);
    v_Purchase_No    varchar2(32);
    v_Purchase_Pk_No number(16, 3);
    v_msg            varchar2(1024);
    v_mas_no         varchar2(32) := v_orderId;
  begin
  
    begin
      j_order := JSON(p_order);
    
   
      begin
        v_id := json_ext.get_string(j_order, 'id');
      exception
        when others then
          v_id := '';
      end;
    
      begin
        v_scvId := json_ext.get_string(j_order, 'scvId');
      exception
        when others then
          v_scvId := '';
      end;
    
      begin
        v_orderId := json_ext.get_string(j_order, 'orderId');
      exception
        when others then
          v_orderId := '';
      end;
    
      begin
        v_action := json_ext.get_string(j_order, 'action');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_contractId := json_ext.get_string(j_order, 'contractId');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_msisdn := json_ext.get_string(j_order, 'msisdn');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_msisdnNew := json_ext.get_string(j_order, 'msisdnNew');
      exception
        when others then
          v_msisdnNew := '';
      end;
      begin
        v_modifyDate := to_date(json_ext.get_string(j_order, 'modifyDate'),
                                'YYYY/MM/DD HH24:MI:SS');
      exception
        when others then
          v_modifyDate := null;
      end;
      begin
        v_orderDate := to_date(json_ext.get_string(j_order, 'orderDate'),
                               'YYYY/MM/DD HH24:MI:SS');
      exception
        when others then
          raise lost_data;
      end;
      begin
        v_isFirst := json_ext.get_string(j_order, 'isFirst');
      exception
        when others then
          raise lost_data;
      end;
    
      begin
        v_reqCreateTime := to_date(json_ext.get_string(j_order,
                                                       'reqCreateTime'),
                                   'YYYY/MM/DD HH24:MI:SS');
      exception
        when others then
          raise lost_data;
      end;
    
    end;
  
    if v_action = 'createservice' then
     null;
    elsif v_action = 'cancelservice' then
      begin
        select serial_id
          into v_client_id
          from bsm_client_mas a
         where a.owner_phone = v_msisdn
           and serial_id like '2A%'
           and rownum <= 1;
      exception
        when no_data_found then
          null;
          null;
      end;
      
      declare 
        v_end_date date;
        v_start_date date;
        v_status_flg varchar2(32);
        
    
      begin
        select a.mas_no, pk_no
          into v_Purchase_No, v_Purchase_Pk_No
          from bsm_purchase_mas a
         where a.src_no = v_orderId
           and amount > 0
           and rownum <= 1;
           
        select a.start_date,a.start_date +ceil((cancel_date + 0.5 - a.start_date) / 30) * 30,status_flg 
        into v_start_date,v_end_date,v_status_flg 
        from   bsm_client_details a
        where a.src_pk_no = v_Purchase_Pk_No and rownum <=1; 
        if v_end_date <= v_start_date then
          v_status_flg :='N';
        end if; 
          
      
        update bsm_client_details a
           set a.end_date =v_end_date,
               a.status_flg=v_status_flg
         where a.src_pk_no = v_Purchase_Pk_No;
      
        bsm_client_service.Set_subscription(0, v_client_id);
      
        v_msg := bsm_recurrent_util.stop_recurrent(v_client_id,
                                                   v_Purchase_No,
                                                   'TSTAR 停租');
        update tstar_order a
           set status_flg = 'C'
         where a.src_order_id = v_orderId;
         
         if v_status_flg ='N' then
           update bsm_purchase_mas 
           set status_flg='C'
           where pk_no=v_Purchase_Pk_No;
           
           bsm_purchase_post.refresh_bsm_client(v_client_id);
         end if; 
        

      
      exception
        when no_data_found then
          declare
            v_order_no varchar2(32);
          begin
            select a.src_order_id
              into v_order_no
              from tstar_order a
             where a.src_order_id = v_orderId
               and rownum <= 1;
            update tstar_order a
               set status_flg = 'C'
             where a.src_order_id = v_orderId;
            commit;
          exception
            when no_data_found then
              raise order_not_found;
          end;
      end;
    
      v_result := '{result_code:"BSM-00000",result_message:"","purchase_no":"' ||
                  v_Purchase_No || '","client_id":"' || v_client_id || '"}';
    
    end if;
  
    return v_result;
  
  exception
    when lost_data then
      return '{result_code:"BSM-00800",result_message:"null field","purchase_no":"","client_id":""}';
    when no_client_found then
      return '{result_code:"BSM-00801",result_message:"phone number not found","purchase_no":"","client_id":""}';
    when no_data_found then
      return '{result_code:"BSM-00802",result_message:"order not found","purchase_no":"","client_id":""}';
    when dup_order then
      return '{result_code:"BSM-00000",result_message:"訂單重複","purchase_no":"","client_id":""}';
    when order_not_found then
      return '{result_code:"BSM-00802",result_message:"order not found","purchase_no":"","client_id":""}';
  end;
end TSTAR_ORDER_SERVICE;
/

