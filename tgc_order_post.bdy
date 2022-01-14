CREATE OR REPLACE PACKAGE BODY IPTV."TGC_ORDER_POST" Is

  Function order_post(p_User_No Number, p_Pk_No Number) Return Varchar2 Is
    Exception_Msg Varchar2(256) Default Null;
    App_Exception Exception;
    v_Process_Sts Varchar2(32);
    v_ds_csr_group Varchar2(32);
    v_b_csr_group  Varchar2(32);
    v_order_type     Varchar2(32);
    v_cont_sts        Varchar2(32);
    v_order_no Number(16);
    v_src_order_no Number(16);
    v_src_process_sts Varchar2(32);
    v_need_deliver_tivo Varchar2(32);
    v_wh Varchar2(32);
    v_tsn Varchar2(32);
    v_f_post varchar2(32);
    v_bid_type varchar2(32);
    v_bid VARCHAR2(32);
    v_title varchar2(128);
    v_cust_id varchar2(32);
    V_tivo_qty                         Number(16);
    v_usb_qty                         Number(16);
    v_ap_qty                          Number(16);
    v_remote_qty                   Number(16);
    v_other_qty                       Number(16);
    v_need_deliver_usb           Varchar2(32);
    v_need_deliver_router        Varchar2(32);
    v_need_deliver_others       Varchar2(32);
    v_need_deliver_remote     Varchar2(32);
    v_ap_model                      Varchar2(256);
    v_remote_model                 Varchar2(256);
    v_usb_model                    Varchar2(256);
    v_sell_acc_flg varchar2(32);
    v_sell_acc_code varchar2(32);
    v_product_id varchar2(32);
    v_program_id varchar2(32);
    v_item_count number(16);


  Begin
    v_ds_csr_group := sysapp_util.get_sys_value('TGCORDER','AssigenCSRGroup','#AS_CSR_G');
    v_b_csr_group  := sysapp_util.get_sys_value('TGCORDER','BuyCSRGroup','#BS_CSR_G');
    v_f_post := sysapp_util.Get_User_Priv('TGCORDER',p_User_No,'forcePOst','forcePOst');
     v_cont_sts := sysapp_util.get_sys_value('TGCORDER','POSTContractSts',Null);
    Select Process_Sts,
           order_type,
           src_order_no,
           need_deliver_tivo,
           tsn,
           product_id,
           a.voucher_type,
           a.voucher_bid,
           a.vouchaer_title,
           cust_id,
           a.router_qty,
           a.usb_qty,
           a.remote_qty,
           a.need_deliver_usb,
           a.need_deliver_router,
           a.need_deliver_remote,
           a.need_deliver_others,
           a.ap_model,
           a.usb_model,
           a.remote_model,
           a.sell_flg,
           a.sell_acc_code,
           a.program_id

      Into v_Process_Sts,
           v_order_type,
           v_src_order_no,
           v_need_deliver_tivo,
           v_tsn,
           v_product_id ,
           v_bid_type,
           v_bid,
           v_title,
           v_cust_id,
           v_ap_qty,
           v_usb_qty,
           v_remote_qty,
           v_need_deliver_usb,
           v_need_deliver_router,
           v_need_deliver_remote,
           v_need_deliver_others,
           v_ap_model,
           v_usb_model,
           v_remote_model,
           v_sell_acc_flg,
           v_sell_acc_code,
           v_program_id
      From Tgc_Order a
     Where Order_No = p_Pk_No
       For Update Nowait;

    If v_Process_Sts <> 'A' Then
      Exception_Msg := '#單據狀態不為打單中#';
      Raise App_Exception;
    End If;

    if v_f_post <> 'Y' then
     If v_order_type = 'K' Then --試用租用不能用資產
       If ( v_TSN Is Null Or v_tsn='0') And v_need_deliver_tivo ='N' Then
         Exception_Msg := '#請給試用轉租用,需有正確的TSN號碼#';
          Raise App_Exception;
       End If;

       If v_TSN Is Not Null And v_tsn <> '0' Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4) Not In ('TP-T','HZ-K')) Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在試用倉內,不能試用轉租用#';
                Raise App_Exception;
          End If;
       End If;

/*      If v_need_deliver_tivo = 'Y' Then
      End If;*/
    Elsif v_order_type = 'J' Then -- 試用轉購買不能是資產
       If ( v_TSN Is Null Or v_tsn='0') And v_need_deliver_tivo ='N' Then
         Exception_Msg := '#請給試用轉購買,需有正確的TSN號碼#';
          Raise App_Exception;
       End If;

       If v_TSN Is Not Null And v_tsn <> '0' Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4)  Not In ('TP-T','HZ-K')) Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在試用倉內,不能試用轉購買#';
                Raise App_Exception;
          End If;
       End If;
    Elsif v_order_type = 'L' Then -- 直接租賃若不出貨,就不用管,若要出貨,必須是資產
     If (v_tsn Is Not Null) And (v_tsn <> '0') Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4) <>'TP-L') Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在資產倉內,不能租用#';
                Raise App_Exception;
          End If;
      End If;
    Elsif v_order_type ='B' Then -- 直接夠買,必須是轉存貨
          if v_product_id like '%K%' then
              If (v_tsn Is Not Null) And (v_tsn <> '0') Then
              v_wh := inv_trx_post.get_tcd_whs(v_tsn);
              If (substr(v_wh,1,4) <>'TP-N') Or (v_wh Is Null) Then
                   Exception_Msg := '#TSN號碼不在新品倉內,不能購買#';
                    Raise App_Exception;
              End If;
          end if;
      End If;
    End If;
    end if;
    
    Select count(*) into v_item_count
     from tgc_order_item a
     where a.mas_pk_no=p_pk_no;
     
    if v_item_count <= 0 then
       Exception_Msg := '#訂單沒有明細資料#';
                    Raise App_Exception;
    end if;
     
    

    declare
      v_sell_flg varchar2(32);
      v_count number(16);
      v_chg_code varchar2(32);
      v_pm_code varchar2(32);
      v_item_name varchar2(64);
      v_tax_flg varchar2(32);
      v_tax_code varchar2(32);
      v_chg_type varchar2(32);
      v_bill_type varchar2(32);
      v_dtl_pk_no number(16);
      v_acc_code varchar2(32);
      v_list_price number(16);
      
      cursor c1 is select pk_no,sale_mode,item_cat,item_code,item_qty
                     from tgc_order_item 
                    where mas_pk_no = v_order_no;
    

    begin
      v_order_no:=p_pk_no;
      select sell_acc_flg into v_sell_flg
      from tgc_program a
      where a.program_id=v_program_id;

      if v_sell_flg <> 'Y' then
         select count(*) into v_count
         from tgc_order_detail a
         where a.mas_pk_no=v_order_no;

         if v_count <= 0 then
            exception_msg := '#沒有資費明細#';
             Raise App_Exception;
         end if;
      end if;
      
      for c1rec in c1 loop
          select count(*) into v_count
          from tgc_order_detail a
          where a.mas_pk_no = v_order_no
          and item_pk_no = c1rec.pk_no;
          
          if v_count= 0 and c1rec.sale_mode = 'B' and NVL(v_sell_acc_flg,'N') <> 'Y' then
                       v_chg_code := 'LIST_PRICE';
                       v_pm_code := 'SALE';
                       v_item_name := tgc_util.get_item_name(c1rec.item_code);
                       select tax_flg,chg_type into v_tax_flg,v_chg_type from service_charge_mas
                          where chg_code= v_chg_code;

                       select bill_type into v_bill_type from service_pm_mas
                          where pm_code= v_pm_code;

                       select seq_sys_no.nextval into v_dtl_pk_no from dual;

                      
                       v_acc_code := v_sell_acc_code;
          


                       v_list_price := 0;

                       insert into tgc_order_detail(mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,tax_flg,tax_code,item_code,item_name,acc_code,list_amount,qty)
                       values(v_order_no,v_dtl_pk_no,null,c1rec.pk_no,v_chg_code,v_chg_type,v_bill_type,v_pm_code,0,v_tax_flg,v_tax_code,c1rec.item_code,v_item_name,v_acc_code,v_list_price,c1rec.item_qty);
 
          end if;
          
      end loop;
   end;
   declare
      v_approved_flg varchar2(32);

    begin
      select approved_stat into  v_approved_flg
      from tgc_product a
      where a.product_id=v_product_id;

      if v_approved_flg <> 'A' then
            exception_msg := '#沒有核准的產品代號#';
            Raise App_Exception;
      end if;
   end;

    If v_bid_type Is Null Then
      exception_msg := '#發票種類未填#';
      Raise App_Exception;
    End If;

   If v_sell_acc_flg = 'Y' and v_sell_acc_code Is Null Then
      exception_msg := '#未填經銷商代號#';
      Raise App_Exception;
    End If;


    If v_bid_type = '3' Then
      If v_bid Is Null Or v_title Is Null Then
        exception_msg := '#統編或抬頭未填#';
        Raise App_Exception;
      End If;

      update tgc_customer a
        set tax_code='OUTTAX3',
            a.company_uid=v_bid,
            a.cust_name=v_title

      where cust_id=v_cust_id;
    End If;

             If v_need_deliver_tivo Is Null Then
                exception_msg := '#未填需不需出貨TIVO#';
                Raise app_exception;
             End If;

             If v_need_deliver_tivo = 'Y' Then
                v_tivo_qty := nvl(v_tivo_qty,1);
             Else
                v_tivo_qty := 0;
             End If;

             If v_need_deliver_usb Is Null Then
                exception_msg := '#未填需不需出貨USB#';
                Raise app_exception;
             End If;

             If v_need_deliver_router Is Null Then
                exception_msg := '#未填需不需出貨AP#';
                Raise app_exception;
             End If;

             If v_need_deliver_others Is Null Then
                exception_msg := '#未填需不需出貨其它貨品#';
                Raise app_exception;
             End If;

             If v_need_deliver_usb Is Null And v_usb_qty > 0 Then
                exception_msg := '#USB出貨數量有問題#';
                Raise app_exception;
             End If;

             If v_need_deliver_router Is Null And v_ap_qty > 0 Then
                exception_msg := '#AP出貨數量有問題#';
                Raise app_exception;
             End If;

              If v_need_deliver_remote Is Null And v_remote_qty > 0 Then
                exception_msg := '#遙控器數量有問題#';
                Raise app_exception;
             End If;

              If v_need_deliver_usb Is Null And v_usb_model Is Null Then
                exception_msg := '#USB型號有問題#';
                Raise app_exception;
             End If;

             If v_need_deliver_router Is Null And v_ap_model Is Null Then
                exception_msg := '#AP型號有問題#';
                Raise app_exception;
             End If;

               If v_need_deliver_remote Is Null And  v_remote_model Is Null Then
                exception_msg := '#遙控器型號有問題#';
                Raise app_exception;
             End If;





       Update Tgc_Order Set Process_Sts = 'P', csr_status = nvl(v_cont_sts,csr_status)
           Where Order_No = p_Pk_No;
       sysapp_util.set_todo_list(v_ds_csr_group,'新進件','TGCORDER',p_pk_no);

       Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('TGCORDER',  p_Pk_No,  Sysdate, p_User_No, '確認',  Sys_Event_Seq.Nextval, '進件');


       If  v_src_order_no Is Not Null Then
           Select process_sts Into v_src_process_sts
              From tgc_order
              Where order_no = v_src_order_no;

           If v_src_process_sts = 'W' Then
             -- 試用
              Update tgc_order a Set process_sts = 'Y'  Where Order_no = v_src_order_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', v_src_order_no,  Sysdate,  p_User_No,  '轉新單',Sys_Event_Seq.Nextval, '轉新單');
            End If;
        End If;
 /*   Else
       Update Tgc_Order Set Process_Sts = 'D' ,  csr_status = nvl(v_cont_sts,csr_status)
        Where Order_No = p_Pk_No;
       sysapp_util.set_todo_list(v_b_csr_group,'新購買約裝','TGCORDER',p_pk_no);

       Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('TGCORDER',  p_Pk_No,  Sysdate, p_User_No, '確認',  Sys_Event_Seq.Nextval, '進件');
    End If;
*/

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function order_assigned_csr(p_User_No Number, p_Pk_No Number)
    Return Varchar2 Is
    Exception_Msg Varchar2(256) Default Null;
    App_Exception Exception;
    v_Process_Sts  Varchar2(32);
    v_Assigned_Csr Number(16);
    v_Csr_Name     Varchar2(256);
     v_cont_sts        Varchar2(32);
  Begin
       v_cont_sts := sysapp_util.get_sys_value('TGCORDER','POSTContractSts',Null);
    Select Process_Sts, Assigned_Csr_Empid
      Into v_Process_Sts, v_Assigned_Csr
      From Tgc_Order
     Where Order_No = p_Pk_No
          For Update Nowait;

    If v_Process_Sts <> 'P' Then
      Exception_Msg := '#單據狀態不為進件#';
      Raise App_Exception;
    End If;

    If v_Assigned_Csr Is Null Then
      Exception_Msg := '#沒有指定約裝人客服人員#';
      Raise App_Exception;
    End If;

    --
    --To Do List
    --

    Sysapp_Util.Set_Todo_List(v_Assigned_Csr, '訂單約裝', 'TGCORDER', p_Pk_No);

    -- Order Status

    Update Tgc_Order Set Process_Sts = 'D',
          csr_status = nvl(v_cont_sts,csr_status)
      Where Order_No = p_Pk_No;

    Select Name
      Into v_Csr_Name
      From Sys_User
     Where User_No = v_Assigned_Csr;

    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TGCORDER',
       p_Pk_No,
       Sysdate,
       p_User_No,
       '指派CSR',
       Sys_Event_Seq.Nextval,
       '指派CSR' || v_Csr_Name);

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function order_new(p_User_No Number, p_Pk_No Number) Return Varchar2 Is
    v_Cust_No         Number(16);
    v_Address         Varchar2(512);
    v_Install_Address Varchar2(512);
    v_Billing_Address Varchar2(512);
    v_zip varchar2(32);
    v_Cust_Id         Varchar2(32);
    v_order_type    Varchar2(32);

    App_Exception Exception;
    Exception_Msg Varchar2(128);

  Begin

    Begin
      Select Cust_User_No, Install_Address, Billing_Address,order_type
        Into v_Cust_No, v_Install_Address, v_Billing_Address,v_order_type
        From Tgc_Order
       Where Order_No = p_Pk_No;
    Exception
      When No_Data_Found Then
        Exception_Msg := '找不到訂單資料';
        Raise App_Exception;
    End;

    Begin
      Select Cust_Id, Address,zip
        Into v_Cust_Id, v_Address,v_zip
        From Tgc_Customer
       Where User_No = v_Cust_No;
    Exception
      When No_Data_Found Then
        Exception_Msg := '找不到客戶資料';
        Raise App_Exception;
    End;

    If v_Install_Address Is Null Then
      Update Tgc_Order
         Set Install_Address = v_Address,
             install_zip= v_zip
       Where Order_No = p_Pk_No;
    End If;

    If v_Billing_Address Is Null Then
      Update Tgc_Order
         Set Billing_Address = v_Address,
             billing_zip = v_zip

       Where Order_No = p_Pk_No;
    End If;

   Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function order_generate(p_user_no Number,p_pk_no Number) Return Varchar2 Is
    Exception_Msg Varchar2(256) Default Null;
    App_Exception Exception;
    v_Process_Sts  Varchar2(32);
    v_need_install    Varchar2(32);
    v_order_type    Varchar2(32);
    v_cont_sts1 Varchar2(32);
    v_cont_sts Varchar2(32);
    v_cont_sts3 Varchar2(32);
    v_need_deliver_tivo Varchar2(32);
    v_wh Varchar2(32);
    v_tsn Varchar2(32);
    v_cnt Number(16);
    v_bill_zip Varchar2(32);
    v_cust_id Varchar2(32);
    v_inst_zip Varchar2(32);
    v_ref_order_id varchar2(32);
    v_f_post varchar2(32);
    v_tcd_tsn varchar2(32);
  Begin
    v_cont_sts3 := sysapp_util.get_sys_value('TGCORDER','GenContractSts',Null);
    v_cont_sts := sysapp_util.get_sys_value('TGCORDER','DisCmpContractSts',Null);
    v_cont_sts1 := sysapp_util.get_sys_value('TGCORDER','CmpContractSts',Null);
    v_f_post := sysapp_util.Get_User_Priv('TGCORDER',p_User_No,'forcePOst','forcePOst');
    Select Process_Sts,need_install,order_type,tsn,need_deliver_tivo,a.billing_zip,cust_id,a.Install_Zip,ref_order_id,tsn
      Into v_Process_Sts,v_need_install,v_order_type,v_tsn,v_need_deliver_tivo,v_bill_zip,v_cust_id,v_inst_zip,v_ref_order_id,v_tcd_tsn
      From Tgc_Order a
     Where Order_No = p_Pk_No
          For Update Nowait;

    If v_Process_Sts <> 'D' Then
      Exception_Msg := '#單據狀態不為約裝中#';
      Raise App_Exception;
    End If;

    If v_need_install Is Null Then
       Exception_Msg := '#未填是否派工安裝#';
       Raise App_Exception;
    End If;

    if v_f_post <> 'Y' then
         If v_order_type = 'K' Then --試用租用不能用資產
       If ( v_TSN Is Null Or v_tsn='0') And v_need_deliver_tivo ='N' Then
         Exception_Msg := '#請給試用轉租用,需有正確的TSN號碼#';
          Raise App_Exception;
       End If;

       If v_TSN Is Not Null And v_tsn <> '0' Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4)  Not In ('TP-T','HZ-K')) Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在試用倉內,不能試用轉租用#';
                Raise App_Exception;
          End If;
       End If;
/*      If v_need_deliver_tivo = 'Y' Then
      End If;*/
    Elsif v_order_type = 'J' Then -- 試用轉購買不能是資產
       If ( v_TSN Is Null Or v_tsn='0') And v_need_deliver_tivo ='N' Then
         Exception_Msg := '#請給試用轉購買,需有正確的TSN號碼#';
          Raise App_Exception;
       End If;

      If v_TSN Is Not Null And v_tsn <> '0' Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4)  Not In ('TP-T','HZ-K')) Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在試用倉內,不能試用轉購買#';
                Raise App_Exception;
          End If;
       End If;
    Elsif v_order_type = 'L' Then -- 直接租賃若不出貨,就不用管,若要出貨,必須是資產
      If (v_tsn Is Not Null) And (v_tsn <> '0') Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4) <>'TP-L') Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在資產倉內,不能租用#';
                Raise App_Exception;
          End If;
      End If;
    Elsif v_order_type ='B' Then -- 直接夠買,必須是轉存貨
          If (v_tsn Is Not Null) And (v_tsn <> '0') Then
          v_wh := inv_trx_post.get_tcd_whs(v_tsn);
          If (substr(v_wh,1,4) <>'TP-N') Or (v_wh Is Null) Then
               Exception_Msg := '#TSN號碼不在新品倉內,不能購買#';
                Raise App_Exception;
          End If;
      End If;
    End If;
    end if;

    If (v_ref_order_id Is Null ) Then
           Exception_msg := '#未輸入申請單編號#';
            Raise app_exception;
    End If;

    If v_bill_zip Is Null Then
         exception_msg:= '#填寫出帳的郵遞區號#';
        Raise App_Exception;
    End If;

     If v_inst_zip Is Null Then
         exception_msg:= '#填寫安裝的郵遞區號#';
        Raise App_Exception;
    End If;
    --
    -- Modify by Edward
    -- 2009/04/10

 /*   Declare
      v_char Varchar2(1);
      v_msg Varchar2(1024);
    Begin
       Select 'x' Into v_char From service_detail a
     Where a.src_pk_no=p_pk_no
     and rownum<=1;
      --    exception_msg:= '#已有存在的服務資料#';
      --        Raise App_Exception;
     Exception
         When no_data_found Then
            If v_order_type In  ('L','K','X','B','J','P') Then
               v_msg:=create_service_detail(p_user_no,p_pk_no);
            End If;

     End; */
     
     --
     -- SRP_KEY 連結
     --
     
 /*    declare
        cursor citem is select srp_key,pk_no
         from tgc_order_item
         where mas_pk_no = p_pk_no;
        v_srp_key number(16);
        v_cnt number(16);
     begin
       for vitem in citem loop
           if vitem.srp_key is null then
              select count(*),max(srp_key)
              into v_cnt,v_srp_key 
              from service_detail 
              where cust_code=v_cust_id
              and status_flg in ('P','A');
              
              if v_cnt = 0 then
                 exception_msg := '#沒有服務內容#';
                 Raise App_Exception;
             elsif v_cnt >= 2 then
                 exception_msg := '#請選擇服務內容#';
                 Raise App_Exception;
              elsif v_cnt = 1 then
                 update tgc_order_item
                    set srp_key=v_srp_key
                 where pk_no=vitem.pk_no;
             end if;
                 
              
           end if;
       end loop;
     end;
        */

    Declare
      v_char Varchar2(1);
      v_msg Varchar2(1024);
    Begin
       Select 'x' Into v_char From service_invo_mas a
     Where a.src_pk_no=p_pk_no and rownum <=1 ;
     --     exception_msg:= '#已有存在的帳單資料#';
     --         Raise App_Exception;
     Exception
         When no_data_found Then
            If v_order_type In  ('L','K','X','B','J') Then
               v_msg:=create_order_invo(p_user_no,p_pk_no);
            End If;

     End;



    If v_need_install = 'Y' Then
        --
        -- generate DS
        --
        Select Count(*) Into v_cnt From tgc_dispatch_info
        Where order_no = p_pk_no And status Not In ('C','Z');

        If v_cnt <= 0 Then


        Declare
           v_dispatch_no      Number(16);
           v_dispatch_id       Varchar2(32);
           v_order_no          Number(16);
           v_order_id           Varchar2(32);
           v_book_time        Date;
           v_dispatch_type   Varchar2(1);
           v_create_user_no Number(16);
           v_bb_id               Varchar2(32);
           v_mso_id             Varchar2(32);
           v_cust_id             Varchar2(32);
           v_cust_user_no    Number(16);
           v_install_addr       Varchar2(512);
           v_already_ap        Varchar2(32);
           v_already_usb      Varchar2(32);
           v_already_tivo       Varchar2(32);
           v_deliver_to_cust_installer Varchar2(32);
           v_need_deliver_tivo            Varchar2(32);
           v_need_deliver_usb           Varchar2(32);
           v_need_deliver_router        Varchar2(32);
           v_need_deliver_others       Varchar2(32);
           v_need_deliver_remote     Varchar2(32);
           v_others_list                    Varchar2(512);
           v_error_msg                     Varchar2(128);
           v_TSN                             Varchar2(128);
           v_tivo_model                    Varchar2(128);
           v_ip_router                       Varchar2(128);
           v_ip_type                         Varchar2(128);
           v_set_top_box                  Varchar2(128);
           v_assigen_intaller_empid  Number(16);
           v_inst_id                          Varchar2(128);
           v_inst_name                     Varchar2(128);
           v_first_pay_type               Varchar2(1);
           v_first_billing_sts               Varchar2(1);
           v_first_total_amt               Number(16);
           v_rec_amt                        Number(16);
           v_inst_rec_money             Varchar2(32);
           v_tivo_qty                         Number(16);
           v_usb_qty                         Number(16);
           v_ap_qty                          Number(16);
           v_remote_qty                   Number(16);
           v_other_qty                       Number(16);
           v_book_time2                   Varchar2(256);
           v_description                    Varchar2(256);
           v_product_id                    Varchar2(256);
           v_program_id                   Varchar2(256);
           v_product_name               Varchar2(256);
           v_program_name              Varchar2(256);
           v_tel                                Varchar2(256);
           v_mobile                          Varchar2(256);
           v_bid_type                       Varchar2(256);
           v_bid                               Varchar2(256);
           v_title                              Varchar2(256);
           v_install_zip                     Varchar2(256);
           v_tcd_tsn                         Varchar2(256);
           v_ref_order_id                   Varchar2(256);
           v_ap_model                      Varchar2(256);
           v_remote_model                 Varchar2(256);
           v_usb_model                    Varchar2(256);
           v_invo_pk_no                  number(16);
           v_invo_no                     varchar2(32);
           v_pl_id                       varchar2(32);
           v_dispatch_type2               varchar2(32);

        Begin
          Select  Seq_Sys_No.Nextval Into v_dispatch_no  From dual;
           v_dispatch_id    := sysapp_util.Get_Mas_No(1,1,Sysdate,'TGCDS',v_dispatch_no);
           v_dispatch_type2 := '0';
           v_create_user_no := p_user_no;

           Select order_no,order_id,tgc_book_date,
                      bb_id,mso_id,cust_id,cust_user_no,install_address,
                      already_apnet,already_usb,already_tivo,deliver_to_cust_installer,
                      need_deliver_tivo,need_deliver_usb,need_deliver_router,need_deliver_others,need_deliver_remote,
                      others_list,tsn,tivo_device_no,
                      ip_router,ip_type,set_top_box,
                      a.assigned_installer_empid,
                      a.first_billing_pay_type,a.first_billing_sts,a.first_total_amount,
                      usb_qty,router_qty,others_qty,remote_qty
                      ,book_time2,product_id,program_id,
                      a.voucher_type,a.voucher_bid,a.vouchaer_title,
                      a.Install_Zip,a.tsn,a.ref_order_id,
                      ap_model,remote_model,usb_model,inv_pk_no,pl_id
                Into
                       v_order_no,v_order_id,v_book_time,
                       v_bb_id,v_mso_id,v_cust_id,v_cust_user_no,v_install_addr,
                       v_already_ap,v_already_usb,v_already_tivo,v_deliver_to_cust_installer,
                       v_need_deliver_tivo,v_need_deliver_usb,v_need_deliver_router,v_need_deliver_others,v_need_deliver_remote,
                       v_others_list,v_tsn,v_tivo_model,
                       v_ip_router,v_ip_type,v_set_top_box,
                      v_assigen_intaller_empid,
                      v_first_pay_type,v_first_billing_sts,v_first_total_amt,
                      v_usb_qty,v_ap_qty,v_other_qty,v_remote_qty,
                      v_book_time2,
                      v_product_id,v_program_id,
                      v_bid_type,v_bid,v_title,
                      v_install_zip,v_tcd_tsn,v_ref_order_id,
                      v_ap_model, v_remote_model,v_usb_model,v_invo_pk_no,v_pl_id

              From tgc_order a
             Where order_no = p_pk_no;

             If v_book_time Is Null Then
                exception_msg := '#預定安裝時間未填寫#';
                Raise App_Exception;
             End If;

        /*     declare
                cursor c_item1 is select a.sale_mode,a.item_cat
                ,a.item_code,a.item_qty,a.ship_mode from tgc_order_item a
                where mas_pk_no = p_pk_no
                and nvl(ship_qty,0) < nvl(item_qty,0);
                v_item_cat varchar2(32);
                v_item_type varchar2(32);

             begin
               v_need_deliver_tivo := 'N';
               v_need_deliver_router := 'N';
               v_need_deliver_usb := 'N';
               v_need_deliver_remote := 'N';

               for r_item1 in c_item1 loop
                   if r_item1.ship_mode in ('DS','DL') then
                      select a.item_type into v_item_type
                       from service_item_mas a
                       where item_code= r_item1.item_code;

                      if v_item_type = 'S' then
                         select a.stk_category_id
                          into v_item_cat
                          from inv_stk_mas a
                          where stock_id= r_item1.item_code;

                          if v_item_cat = 'DVR' then
                              v_need_deliver_tivo := 'Y';
                              v_tivo_qty := r_item1.item_qty;
                              v_tivo_model := r_item1.item_code;
                          elsif v_item_cat = 'AP' then
                              v_need_deliver_router := 'Y';
                              v_ap_qty := r_item1.item_qty;
                              v_ap_model := r_item1.item_code;
                          elsif v_item_cat = 'USB' then
                              v_need_deliver_USB := 'Y';
                              v_USB_qty := r_item1.item_qty;
                              v_usb_model := r_item1.item_code;
                          else
                              if nvl(v_remote_qty,0) <= 0 then 
                              v_need_deliver_REMOTE := 'Y';
                              v_remote_qty := r_item1.item_qty;
                              v_remote_model := r_item1.item_code;
                              else
                                v_need_deliver_Others := 'Y';
                                if v_others_list is null then
                                   v_others_list := r_item1.item_code||'*'|| to_char(r_item1.item_qty);
                                else
                                   v_others_list :=v_others_list||','||r_item1.item_code||'*'|| to_char(r_item1.item_qty);
                                end if;
                               end if;
                          end if;


                      end if;

                   end if;
               end loop;

             end;
*/
/*
             If v_need_deliver_tivo Is Null Then
                exception_msg := '#未填需不需出貨TIVO#';
                Raise app_exception;
             End If;

             If v_need_deliver_tivo = 'Y' Then
                v_tivo_qty := nvl(v_tivo_qty,1);
             Else
                v_tivo_qty := 0;
             End If;

             If v_need_deliver_usb Is Null Then
                exception_msg := '#未填需不需出貨USB#';
                Raise app_exception;
             End If;

             If v_need_deliver_router Is Null Then
                exception_msg := '#未填需不需出貨AP#';
                Raise app_exception;
             End If;

             If v_need_deliver_others Is Null Then
                exception_msg := '#未填需不需出貨其它貨品#';
                Raise app_exception;
             End If;

             If v_need_deliver_usb Is Null And v_usb_qty > 0 Then
                exception_msg := '#USB出貨數量有問題#';
                Raise app_exception;
             End If;

             If v_need_deliver_router Is Null And v_ap_qty > 0 Then
                exception_msg := '#AP出貨數量有問題#';
                Raise app_exception;
             End If;

              If v_need_deliver_remote Is Null And v_remote_qty > 0 Then
                exception_msg := '#遙控器數量有問題#';
                Raise app_exception;
             End If;

              If v_need_deliver_usb Is Null And v_usb_model Is Null Then
                exception_msg := '#USB型號有問題#';
                Raise app_exception;
             End If;

             If v_need_deliver_router Is Null And v_ap_model Is Null Then
                exception_msg := '#AP型號有問題#';
                Raise app_exception;
             End If;

               If v_need_deliver_remote Is Null And  v_remote_model Is Null Then
                exception_msg := '#遙控器型號有問題#';
                Raise app_exception;
             End If;
*/
/*             If v_deliver_to_cust_installer Is Null Then
                exception_msg := '#未填需不需出貨給工程師或其它#';
                Raise app_exception;
             End If;*/

             If v_assigen_intaller_empid Is Not Null Then
                Select user_name,Name Into v_inst_id,v_inst_name From sys_user Where user_no=v_assigen_intaller_empid;
             Else
               v_inst_name := Null;
               v_inst_id       := Null;
             End If;

             select sum(a.amount) into v_first_total_amt
             from tgc_order_detail a
                  where mas_pk_no = p_pk_no;
             v_first_total_amt := nvl(v_first_total_amt,0);

             If v_first_total_amt > 0 Then

                 If v_first_pay_type Is  Null Then
                    exception_msg := '#請填寫訂單繳款方式#';
                    Raise app_exception;
                 End If;

                 If v_first_billing_sts Is Null Then
                    exception_msg := '#請填寫訂單繳款狀態#';
                    Raise app_exception;
                 End If;

                 If v_first_total_amt Is Null Then
                    exception_msg := '#未填訂單金額#';
                    Raise app_exception;
                 End If;

                 --
                 -- 需工程施收款
                 --
                 If v_first_pay_type = '1'  And v_first_billing_sts ='1' Then
                    v_inst_rec_money := 'Y';
                    v_rec_amt := v_first_total_amt;
                 End If;

                 If v_bid_type Is Null Then
                    exception_msg := '#發票種類未填#';
                    Raise App_Exception;
                  End If;

                  If v_bid_type = '3' Then
                    If v_bid Is Null Or v_title Is Null Then
                      exception_msg := '#統編或抬頭未填#';
                      Raise App_Exception;
                    End If;
                  End If;
            End If;

          Begin
            Select product_name Into v_product_name
                From tgc_product
              Where product_id = v_product_id;
          Exception
             When no_data_found Then v_product_name := v_product_id;
          End ;

          Begin
            Select program_name Into v_program_name
               From tgc_program
             Where program_id = v_program_id;
         Exception
            When no_data_found Then v_program_name := v_program_id;
          End;

          Begin
            Select a.dayphone,a.mobilephone1  Into v_tel,v_mobile From tgc_customer a Where cust_id = v_cust_id;
          Exception
             When no_data_found Then Null;
           End;

           if v_invo_pk_no is not null then
              select mas_no into v_invo_no from service_invo_mas where pk_no = v_invo_pk_no;
            end if;

           v_description := '新機安裝 ('||v_program_name||'-'||v_product_name||')';

           iF v_pl_id is null then
              v_dispatch_type2:='0';
           else
              v_dispatch_type2 :='1';
           end if;


           Insert Into tgc_dispatch_info(dispatch_no,dispatch_id,cust_id,cust_user_no,order_no,order_id,
                                                      problem_desc,create_user,install_addr,create_date,status,
                                                      already_AP,already_usb,already_tivo,deliver_to_cust_installer,
                                                      tivo,ap,usb_nic,Others,others_list,remote,dispatch_type
                                                      ,tsn,tivo_model,ip_router,ip_type,set_top_box
                                                      ,book_time,installer_id,installer_no,rec_money_amt
                                                      ,inst_rec_money,tivo_qty,ap_qty,usb_qty,other_qty,remote_qty,
                                                      book_time2,tel,mobile,ds_book_time_s,bid_type,bid,title
                                                      ,install_zip,ap_model,nic_model,remote_model,invo_pk_no,invo_no)
           Values  (v_dispatch_no,v_dispatch_id,v_cust_id,v_cust_user_no,v_order_no,v_order_id,
                         v_description,v_create_user_no,v_install_addr,Sysdate,'A',
                         v_already_ap,v_already_usb,v_already_tivo,v_deliver_to_cust_installer,
                         v_need_deliver_tivo,v_need_deliver_router,v_need_deliver_usb,v_need_deliver_Others,v_others_list,v_need_deliver_remote,v_dispatch_type2
                         ,v_tsn,v_tivo_model,v_ip_router,v_ip_type,v_set_top_box
                         ,v_book_time,v_inst_id,v_assigen_intaller_empid,v_rec_amt
                         ,v_inst_rec_money,v_tivo_qty,v_ap_qty,v_usb_qty,v_other_qty,v_remote_qty,
                         v_book_time2,v_tel,v_mobile,v_book_time,v_bid_type,v_bid,v_title
                         ,v_install_zip,v_ap_model,v_usb_model,v_remote_model,v_invo_pk_no,v_invo_no);

           Update tgc_order Set dispatch_no = v_dispatch_no
                                            ,dispatch_id = v_dispatch_id
             Where order_no = p_pk_no;

           Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date, User_No, Event_Type, Seq_No,Description)
               Values  ('TGCDISPATCH', v_dispatch_No, Sysdate, p_User_No, '建立', Sys_Event_Seq.Nextval,  '建立');

           v_error_msg := tgc_order_post.dispatch_post(p_user_no,v_dispatch_no);



        End;
        End If;

       -- Order Status

       Update Tgc_Order Set Process_Sts = 'N',csr_status=nvl(v_cont_sts3,csr_status)  Where Order_No = p_Pk_No;

       -- clear todolist

        Sysapp_Util.clear_Todo_List(p_user_no, 'generate', 'TGCORDER', p_Pk_No);

        Insert Into Sysevent_Log (App_Code,Pk_No,Event_Date,User_No,Event_Type,Seq_No, Description)
        Values ('TGCORDER', p_Pk_No, Sysdate,  p_User_No,  '派工',  Sys_Event_Seq.Nextval, '派工');

    Else

           If v_order_type = 'P' Then
             -- 試用
              Update tgc_order a Set process_sts = 'W',csr_status=nvl(v_cont_sts,csr_status) Where Order_no = p_pk_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', p_pk_no,  Sysdate,  p_User_No,  '安裝完成',Sys_Event_Seq.Nextval, '安裝完成');
           Else
              -- 一般
              Update tgc_order Set process_sts = 'Z',csr_status=nvl(v_cont_sts1,csr_status)Where order_no = p_pk_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', p_pk_no,  Sysdate,  p_User_No,  '完成',Sys_Event_Seq.Nextval, '完成');
            End If;

            Sysapp_Util.clear_Todo_List(p_user_no, 'generate', 'TGCORDER', p_Pk_No);

    End If;

      /*         if v_tcd_tsn is not null then
               Update service_detail a
                   Set tcd_tsn=v_tcd_tsn
                  Where (src_pk_no =p_pk_no)
                 And status_flg ='A';
          end if;
*/


    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function order_unpost(p_User_No Number, p_Pk_No Number)  Return Varchar2   Is
    Exception_Msg      Varchar2(256) Default Null;
    App_Exception      Exception;
    v_Process_Sts      Varchar2(32);
    v_Assigned_Csr    Number(16);
    v_Csr_Name         Varchar2(256);
    v_dispatch_status Varchar2(32);
    v_dispatch_no       Number(16);
    v_char                   Varchar2(1);
    v_src_order_no      Number(16);
    v_src_process_sts Varchar2(32);
    v_rid                       Rowid;
    v_cnt                     Number(16);
    v_f_unpost          varchar2(32);
  Begin
    v_f_unpost := sysapp_util.Get_User_Priv('TGCORDER',p_user_no,'ForceUnpost','ForceUnpost');
    Select Process_Sts, Assigned_Csr_Empid,dispatch_no,src_order_no,Rowid
      Into v_Process_Sts, v_Assigned_Csr,v_dispatch_no,v_src_order_no,v_rid
      From Tgc_Order
     Where Order_No = p_Pk_No
          For Update Nowait;
  if v_f_unpost <> 'Y' then
    If v_Process_Sts Not In ('P','D') Then
      Exception_Msg := '#單狀態禁止抽回#';
      Raise App_Exception;
    End If;
   end if;
   /*   Begin
          Select 'x' Into v_char
          From service_detail
          Where src_pk_no = p_pk_no And status_flg In ('P','B') And rownum <=1;

          Exception_Msg := '#尚有未取消的服務內容#';
          Raise App_Exception;
       Exception
          When no_data_found Then Null;
       End; */

  --  If v_process_sts = 'N' Then
       Begin
          Select 'x' Into v_char
          From tgc_dispatch_info
          Where order_no = p_pk_no And status Not In ('A','C','Z') And rownum <=1;

          Exception_Msg := '#尚有未取消的派工單#';
          Raise App_Exception;
       Exception
          When no_data_found Then Null;
       End;
 --   End If;

    Update tgc_order Set process_sts='A'  Where order_no = p_pk_no;
    sysapp_util.clear_todo_list(p_user_no,Null,'TGCORDER',p_pk_no);
    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCORDER', p_Pk_No,  Sysdate,  p_User_No,  'Undo Post',Sys_Event_Seq.Nextval, 'Undo Post');

    If v_src_order_no Is Not Null Then
       Select process_sts Into v_src_process_sts
         From tgc_order
       Where order_no = v_src_order_no;

       If v_src_process_sts = 'Y' Then
          Select Count(*) Into v_cnt
           From tgc_order
            Where src_order_no =v_src_order_no And process_sts In ('W','X','Y','Z') And Rowid <> v_rid ;
            If v_cnt = 0 Then
                  Update tgc_order Set process_sts='W'
                    Where order_no = v_src_order_no;
                   Sysapp_Util.clear_Todo_List(p_user_no, 'clear', 'TGCORDER', v_src_order_no);

                   Insert Into Sysevent_Log (App_Code,Pk_No,Event_Date,User_No,Event_Type,Seq_No, Description)
                   Values ('TGCORDER', v_src_order_No, Sysdate,  p_User_No,  'Unpost New Order',  Sys_Event_Seq.Nextval, 'Unpost New Order');
             End If;

       End If;
    End If;


    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function order_cancel(p_User_No Number, p_Pk_No Number)  Return Varchar2   Is
    Exception_Msg      Varchar2(256) Default Null;
    App_Exception      Exception;
    v_Process_Sts      Varchar2(32);
    v_Assigned_Csr    Number(16);
    v_Csr_Name         Varchar2(256);
    v_dispatch_status Varchar2(32);
    v_dispatch_no       Number(16);
    v_char                   Varchar2(1);
    v_ref_member_id    Varchar2(32);
    v_onb_bor_id Varchar2(256);
    v_cust_name Varchar2(32);
    v_cust_id Varchar2(32);
    v_src_process_sts Varchar2(32);
    v_src_order_no Number(16);
    v_order_type Varchar2(32);
    v_org_order_cate Varchar2(32);
    v_pl_id varchar2(32);
  Begin
    Select Process_Sts, Assigned_Csr_Empid,dispatch_no,ref_member_id,org_order_id,cust_id,src_order_no,org_order_cate,a.pl_id
      Into v_Process_Sts, v_Assigned_Csr,v_dispatch_no,v_ref_member_id,v_onb_bor_id,v_cust_id,v_src_order_no,v_org_order_cate,v_pl_id
      From Tgc_Order a
     Where Order_No = p_Pk_No
          For Update Nowait;

    If v_Process_Sts Not In ('A') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

     declare
         v_open_amount number(16);
         v_cnt number(16);
      begin
        v_open_amount := 0;
        select sum(open_amount) into v_open_amount
          from service_acc_detail a
          where a.src_pk_no in
          (select pk_no from service_invo_mas b where
            b.src_pk_no = p_pk_no);
         if v_open_amount > 0 then
             exception_msg:= '#此訂單尚有欠款'||v_open_amount||'未沖帳#';
             Raise App_Exception;
         end if;

         select count(*) into v_cnt from service_invo_mas  a
         where a.src_pk_no = p_pk_no
         and status_flg in ('A','N');

         if v_cnt > 0 then
            exception_msg:= '#此訂單尚有帳單'||v_open_amount||'未取消#';
             Raise App_Exception;
         end if;
      end;

      declare
        cursor c_inv is select b.qty,b.returned_qty,b.stock_id
                       from inv_trx_items b,inv_trx_mas c
                      where  c.trx_mas_no=b.trx_mas_no
                        and c.pl_id=v_pl_id
                        and c.process_sts <> 'C';

      begin
         for cinvrec in c_inv loop
            if nvl(cinvrec.qty,0)-nvl(cinvrec.returned_qty,0) > 0 then
               exception_msg:= '#此訂單貨品未退還'||cinvrec.stock_id||'#';
               Raise App_Exception;
            end if;
         end loop;
      end;


     If v_order_type<> 'P' Then

         If v_src_order_no Is Not Null Then
            Select process_sts Into v_process_sts
              From tgc_order
             Where order_no = v_src_order_no;

             If v_process_sts = 'Y' Then
             Update tgc_order Set process_sts = 'W' Where Order_no = v_src_order_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', v_src_order_no,  Sysdate,  p_User_No,  '新單取消',Sys_Event_Seq.Nextval, '回已裝機案');
             Sysapp_Util.clear_Todo_List(p_user_no, 'complete', 'TGCORDER', v_src_order_No);
             End If;
        End If;
     End If;

     declare
        cursor c_detail is select rowid rid,status_flg,srp_key from service_detail where
        src_pk_no = p_pk_no;

      begin
         for c1rec  in c_detail loop
            declare
               cursor c_chg_detail is select rowid rid,status_flg from service_chg_detail
                  where srp_key =c1rec.srp_key;
            begin
              for c2rec in c_chg_detail loop
                   if c2rec.status_flg not in ('A','N') then
                      exception_msg:= '#此訂單費用有問題#';
                      Raise App_Exception;

                   end if;
                   update service_chg_detail
                      set status_flg='N'
                    where rowid=c2rec.rid;
               end loop;
            end;

            if c1rec.status_flg not in ('A','N') then
               exception_msg:= '#此訂單服務有問題#';
               Raise App_Exception;
            end if;
            update service_detail
              set status_flg='N'
              where rowid=c1rec.rid;
         end loop;
      end;




    Update tgc_order Set process_sts='C'  Where order_no = p_pk_no;
    sysapp_util.clear_todo_list(p_user_no,Null,'TGCORDER',p_pk_no);
    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCORDER', p_Pk_No,  Sysdate,  p_User_No,  '取消單據',Sys_Event_Seq.Nextval, '取消單據');





    Commit;
    --
    -- OEYA Transfer
    --
               If v_ref_member_id Is Not Null Then
               Declare
                      v_back_code Varchar2(32) Default 'A';

                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;

                 Begin
                       Select Rowid Into v_rid From oeya_orders Where order_sn=v_onb_bor_id;

                       Update oeya_orders
                        Set order_status=2,
                              order_shipping_status=0
                           Where order_sn=v_onb_bor_id;

                   Exception
                       When no_data_found Then
                            If v_org_order_cate ='58' Then
                               v_back_code:='119_4';
                            Elsif v_org_order_cate='59' Then
                               v_back_code:='119_3';
                             Elsif v_org_order_cate='63' Then
                               v_back_code:='119_5';
                             End If;
                             If v_back_code Is Not Null Then
                                     v_onb_bor_id := v_onb_bor_id;
                                     v_cust_name := tgc_util.get_cust_name(v_cust_id);
                                     v_oeya_member_id := substr(v_ref_member_id,1,instr(v_ref_member_id,'|')-1);
                                     Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                         Values(Sysdate,v_oeya_member_id,Null,2,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo 購買',v_back_code,Null,p_pk_no,0);
                                     Commit;
                              End If;
                  End;
                End If;
    Return Null;


  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;


  Function order_nullify(p_User_No Number, p_Pk_No Number)  Return Varchar2   Is
    Exception_Msg      Varchar2(256) Default Null;
    App_Exception      Exception;
    v_Process_Sts      Varchar2(32);
    v_Assigned_Csr    Number(16);
    v_Csr_Name         Varchar2(256);
    v_dispatch_status Varchar2(32);
    v_dispatch_no       Number(16);
    v_char                   Varchar2(1);
     v_ref_member_id    Varchar2(32);
    v_onb_bor_id Varchar2(32);
    v_cust_name Varchar2(32);
    v_cust_id Varchar2(32);
    v_src_order_no Number(16);
    v_order_type Varchar2(32);
     v_org_order_cate Varchar2(32);
     v_pl_id varchar(32);
  Begin
    Select Process_Sts, Assigned_Csr_Empid,dispatch_no,ref_member_id,org_order_id,cust_id,src_order_no,order_type,org_order_cate,pl_id
      Into v_Process_Sts, v_Assigned_Csr,v_dispatch_no,v_ref_member_id,v_onb_bor_id,v_cust_id,v_src_order_no,v_order_type,v_org_order_cate,v_pl_id
      From Tgc_Order
     Where Order_No = p_Pk_No
          For Update Nowait;


    If v_Process_Sts Not In ('A') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

     declare
         v_open_amount number(16);
         v_cnt number(16);
      begin
        v_open_amount := 0;
        select sum(open_amount) into v_open_amount
          from service_acc_detail a
          where a.src_pk_no in
          (select pk_no from service_invo_mas b where
            b.src_pk_no = p_pk_no);
         if v_open_amount > 0 then
             exception_msg:= '#此訂單尚有欠款'||v_open_amount||'未沖帳#';
             Raise App_Exception;
         end if;

         select count(*) into v_cnt from service_invo_mas  a
         where a.src_pk_no = p_pk_no
         and status_flg in ('A','N');

         if v_cnt > 0 then
            exception_msg:= '#此訂單尚有帳單'||v_open_amount||'未取消#';
             Raise App_Exception;
         end if;
      end;

      declare
        cursor c_inv is select b.qty,b.returned_qty,b.stock_id
                       from inv_trx_items b,inv_trx_mas c
                      where  c.trx_mas_no=b.trx_mas_no
                        and c.pl_id=v_pl_id
                        and c.process_sts <> 'C';

      begin
         for cinvrec in c_inv loop
            if nvl(cinvrec.qty,0)-nvl(cinvrec.returned_qty,0) > 0 then
               exception_msg:= '#此訂單貨品未退還'||cinvrec.stock_id||'#';
               Raise App_Exception;
            end if;
         end loop;
      end;

      declare
        cursor c_detail is select rowid rid,status_flg,srp_key from service_detail where
        src_pk_no = p_pk_no;

      begin
         for c1rec  in c_detail loop
            declare
               cursor c_chg_detail is select rowid rid,status_flg from service_chg_detail
                  where srp_key =c1rec.srp_key;
            begin
              for c2rec in c_chg_detail loop
                   if c2rec.status_flg not in ('A','N') then
                      exception_msg:= '#此訂單費用有問題#';
                      Raise App_Exception;
                      update service_chg_detail
                        set status_flg='N'
                     where rowid=c2rec.rid;
                   end if;
               end loop;
            end;

            if c1rec.status_flg not in ('A','N') then
               exception_msg:= '#此訂單服務有問題#';
               Raise App_Exception;
            end if;
            update service_detail
              set status_flg='N'
              where rowid=c1rec.rid;
         end loop;
      end;

    Update tgc_order Set process_sts='F'  Where order_no = p_pk_no;
    sysapp_util.clear_todo_list(p_user_no,Null,'TGCORDER',p_pk_no);
    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCORDER', p_Pk_No,  Sysdate,  p_User_No,  '作廢',Sys_Event_Seq.Nextval, '作廢');


    Commit;

     --
    -- OEYA Transfer
    --
               If v_ref_member_id Is Not Null Then
               Declare
                      v_back_code Varchar2(32) Default 'A';

                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;

                 Begin
                       Select Rowid Into v_rid From oeya_orders Where order_sn=v_onb_bor_id;

                       Update oeya_orders
                        Set order_status=2,
                              order_shipping_status=0
                           Where order_sn=v_onb_bor_id;

                   Exception
                           When no_data_found Then
                            If v_org_order_cate ='58' Then
                               v_back_code:='119_4';
                            Elsif v_org_order_cate='59' Then
                               v_back_code:='119_3';
                            Elsif v_org_order_cate='63' Then
                               v_back_code:='119_5';
                             End If;
                             If v_back_code Is Not Null Then
                                     v_onb_bor_id := v_onb_bor_id;
                                     v_cust_name := tgc_util.get_cust_name(v_cust_id);
                                     v_oeya_member_id := substr(v_ref_member_id,1,instr(v_ref_member_id,'|')-1);
                                     Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                         Values(Sysdate,v_oeya_member_id,Null,2,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo 購買',v_back_code,Null,p_pk_no,0);
                                     Commit;
                              End If;
                  End;
                End If;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

   Function order_complete(p_User_No Number, p_Pk_No Number,p_rev_flg Varchar2 Default Null,p_rev_date Date Default Null) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_product_id varchar2(32);
    v_status            Varchar2(32);
    v_installer_id      Varchar2(32);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
    v_process_sts    Varchar2(16);
    v_order_type       Varchar2(16);
    v_finish_date       Date;
    v_result              Varchar2(1);
    v_rec_tivo           Varchar2(1);
    v_rec_tivo_date   Date;
    v_src_order_no   Number(16);
    v_deliver_tivo      Varchar2(16);
    v_tivo_model       Varchar2(128);
    v_tivo_tsn             Varchar2(128);
    v_cont_sts           Varchar2(128);
    v_cust_id Varchar2(32);
    v_onb_bor_id Varchar2(32);
    v_onb_bor_cate Varchar2(32);
    v_ref_member_id Varchar2(32);
    v_order_id Varchar2(32);
    v_cmp_date Date;
    v_bill_start_date Date;
    v_ref_order_id Varchar2(32);
    v_bill_zip Varchar2(32);
    v_org_order_cate Varchar2(32);
    v_srp_key Number(16);
    v_deliver_usb varchar2(32);
    v_deliver_remote varchar2(32);
    v_deliver_router varchar2(32);
    v_deliver_others varchar2(32);
    v_pl_id varchar(256);

  Begin

   v_cont_sts := sysapp_util.get_sys_value('TGCORDER','CompleteContractSts',Null);

    Select product_id,
           process_sts,
           order_type,
           rec_tivo,
           rec_tivo_date,
           src_order_no,
           need_deliver_tivo,
           a.tivo_device_no,
           tsn,
           ref_member_id,
           org_order_id,
           org_order_cate,
           order_id,
           cust_id,
           complete_date,
           service_fee_start_date,
           a.need_deliver_tivo,
           ref_order_id,
           billing_zip,
           org_order_cate,
           srp_key,
           NEED_DELIVER_REMOTE,
           NEED_DELIVER_OTHERS,
           NEED_DELIVER_ROUTER,
           NEED_DELIVER_USB,
           pl_id

      Into v_product_id,
           v_status,
           v_order_type,
           v_rec_tivo,
           v_rec_tivo_date,
           v_src_order_no,
           v_deliver_tivo,
           v_tivo_model,
           v_tivo_tsn,
           v_ref_member_id,
           v_onb_bor_id,
           v_onb_bor_cate,
           v_order_id,
           v_cust_id,
           v_cmp_date,
           v_bill_start_date,
           v_deliver_tivo,
           v_ref_order_id,
           v_bill_zip,
           v_org_order_cate,
           v_srp_key,
           v_deliver_usb,
           v_deliver_remote,
           v_deliver_router,
           v_deliver_others,
           v_pl_id
      From tgc_order a
     Where order_no = p_pk_no
       For Update Nowait;

    If v_status Not  In ('W','Z','Y') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

  --  If v_deliver_tivo = 'N' Then
     if v_tivo_model is not null then
       If v_deliver_tivo Is Null Then
          exception_msg := '#未輸入TIVO型號#';
          Raise app_exception;
       End If;
/*
       If (v_tivo_tsn Is Null) Or (v_tivo_tsn = '0') Then
          Exception_msg := '#未輸入TSN編號#';
          Raise app_exception;
        End If;
  */
      declare
         cursor c1 is select tsn,item_cat
          from tgc_order_item
          where  mas_pk_no = p_pk_no;
      begin
        for c1rec in c1 loop
           if c1rec.item_cat='DVR' and c1rec.tsn is null then
            Exception_msg := '#未輸入TSN編號#';
            Raise app_exception;
           end if;
        end loop;
     end;

        If (v_ref_order_id Is Null ) Then
           Exception_msg := '#未輸入申請單編號#';
            Raise app_exception;
        End If;
     end if;

     if ( v_deliver_tivo ='Y' or v_deliver_usb='Y' or  v_deliver_remote='Y' or
          v_deliver_router='Y' or v_deliver_others ='Y') and v_pl_id is null then
            Exception_msg := '#未輸入出貨單號#';
            Raise app_exception;
     end if;


 --   End If;

    If v_order_type= 'P' Then
      If p_rev_flg Is Not Null Then
         Update tgc_order
               Set rec_tivo = p_rev_flg
            Where order_no = p_pk_no;
            v_rec_tivo := p_rev_flg;
       End If;

       If p_rev_date Is Not Null Then
          Update tgc_order
               Set rec_tivo_date = p_rev_date
            Where order_no = p_pk_no;
            v_rec_tivo_date := p_rev_Date;
       End If;

      If v_rec_tivo <> 'Y' Then
        exception_msg:= '#未歸還TIVO#';
        Raise App_Exception;
      End If;

      If v_rec_tivo_date Is Null Then
         exception_msg:= '#填寫TIVO歸還日#';
          Raise App_Exception;
      End If;

       v_cont_sts := sysapp_util.get_sys_value('TGCORDER','ReturnSts','J');

       Update tgc_order Set process_sts = 'X',csr_status=v_cont_sts Where Order_no = p_pk_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', p_pk_no,  Sysdate,  p_User_No,  '歸還結案',Sys_Event_Seq.Nextval, '歸還結案');
         -- clear todolist

       --關閉 Service_detail
         update service_chg_detail
            set status_flg ='N'
         where srp_key in
         (select srp_key from service_detail where src_pk_no = p_pk_no);

         update service_detail
            set status_flg='N'
         where src_pk_no = p_pk_no;

        Sysapp_Util.clear_Todo_List(p_user_no, 'complete', 'TGCORDER', p_Pk_No);

     Else

       If v_cmp_date Is Null Then
          exception_msg:= '#未填完工結案日#';
           Raise App_Exception;
       End If;
        if v_order_type in ('B','S','J') then
    --   if v_order_type in ('B','L','S','J') then
          declare
             v_month_free number(16);
          begin
             select nvl(a.trial_month,0) into v_month_free from tgc_product a where a.product_id=v_product_id;

             v_bill_start_date := add_months(v_cmp_date,v_month_free)+1;

             update tgc_order a
               set a.service_fee_start_date = v_bill_start_date,
               a.contract_start_date = v_cmp_date+1
              where order_no = p_pk_no;
          end;
       else
          If v_bill_start_date Is Null Then
             exception_msg:= '#未輸入資費起算日#';
             Raise App_Exception;
           end if;
       End If;

      If v_bill_zip Is Null Then
         Begin
            Select zip Into v_bill_zip From tgc_customer Where cust_id = v_cust_id;
         Exception
            When no_data_found Then Null;
          End ;

          If v_bill_zip Is Null Then
               exception_msg:= '#填寫出帳的郵遞區號#';
              Raise App_Exception;
          End If;
      End If;

      declare
         v_open_amount number(16);
      begin
        v_open_amount := 0;
        select sum(open_amount) into v_open_amount
          from service_acc_detail a
          where a.src_pk_no in
          (select pk_no from service_invo_mas b where
            b.src_pk_no = p_pk_no)
            and open_flg='Y';
         if v_open_amount > 0 then
             exception_msg:= '#此訂單尚有欠款'||v_open_amount||'未沖帳#';
             Raise App_Exception;
         end if;
      end;

       Update tgc_order Set process_sts = 'X' Where Order_no =p_pk_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', p_pk_no,  Sysdate,  p_User_No,  '結案',Sys_Event_Seq.Nextval, '結案');
                Sysapp_Util.clear_Todo_List(p_user_no, 'complete', 'TGCORDER', p_Pk_No);
               If v_src_order_no Is Not Null Then
                  -- trial transfer

                  If v_deliver_tivo = 'N' Then
                      Update tgc_order Set process_sts = 'X',rec_tivo = 'Y' ,rec_tivo_date=v_cmp_date
                       Where Order_no = v_src_order_no;
                         Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                              Values  ('TGCORDER', v_src_order_no,  Sysdate,  p_User_No,  '結案',Sys_Event_Seq.Nextval, '結案');
                       Sysapp_Util.clear_Todo_List(p_user_no, 'complete', 'TGCORDER', v_src_order_No);
                   Else
                      Null;
                   End If;

                   --關閉 Service_detail
                   update service_chg_detail
                      set status_flg ='N'
                   where srp_key in
                   (select srp_key from service_detail where src_pk_no =v_src_order_no);

                   update service_detail
                      set status_flg='N'
                   where src_pk_no = v_src_order_no;

                End If;

          --
          -- OEYA
          --
          If v_src_order_no Is Null Then
           If v_ref_member_id Is Not Null Then
               Declare
                      v_back_code Varchar2(32) Default 'A';
                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;

                 Begin
                       Select Rowid Into v_rid From oeya_orders Where order_sn=v_onb_bor_id;

                      Update oeya_orders
                        Set order_status=1,
                              order_shipping_status=1
                           Where order_sn=v_onb_bor_id;

                   Exception
                       When no_data_found Then
                            If v_org_order_cate ='58' Then
                               v_back_code:='119_4';
                            Elsif v_org_order_cate='59' Then
                               v_back_code:='119_3';
                            Elsif v_org_order_cate='63' Then
                               v_back_code:='119_5';
                             End If;
                             If v_back_code Is Not Null Then
                                       v_onb_bor_id := v_onb_bor_id;
                                       v_cust_name := tgc_util.get_cust_name(v_cust_id);
                                       v_oeya_member_id := substr(v_ref_member_id,1,instr(v_ref_member_id,'|')-1);
                                       Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                           Values(Sysdate,v_oeya_member_id,Null,1,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo 購買',v_back_code,Null,p_pk_no,0);
                                       Commit;
                              End If;

                  End;
                End If;

             Else
                 If v_ref_member_id Is Not Null Then
               Declare
                      v_back_code Varchar2(32) Default 'A';

                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;

                 Begin
                       Select Rowid Into v_rid From oeya_orders Where order_sn=v_order_id; 

                       Update oeya_orders
                        Set order_status=1,
                              order_shipping_status=1
                           Where order_sn=v_order_id;
             Exception
                       When no_data_found Then Null;


                             v_onb_bor_id := v_onb_bor_id;
                             v_cust_name := tgc_util.get_cust_name(v_cust_id);
                              v_back_code := '119_2';
                             v_oeya_member_id := substr(v_ref_member_id,1,instr(v_ref_member_id,'|')-1);
                             Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                 Values(Sysdate,v_oeya_member_id,Null,1,0,v_cust_name,v_order_id,'TiVo','TiVo 租用/購買',v_back_code,Null,p_pk_no,0);
                             Commit;
                  End;
                End If;
             End If; 



     End If;

     --
     -- Create Service Detail
     --
    If v_srp_key Is Null Then
            Declare
              v_char Varchar2(1);
              v_msg Varchar2(1024);
            Begin
               Select 'x' Into v_char From service_detail a
             Where a.src_pk_no=p_pk_no And status_flg not in 'A';
                      exception_msg:= '#已有存在的服務資料#';
                      Raise App_Exception;
             Exception
                 When no_data_found Then
                    If v_order_type In  ('L','K','X','B','J','P') Then
                       v_msg:=create_service_detail(p_user_no,p_pk_no);
                    End If;

             End;
    End If;

    --
    -- Create Start Service bill note
    --
    declare
      v_item_code varchar2(32);
      v_TSN varchar2(32);
      v_main_item varchar2(32);
      v_str_pk_no Number(16);
      v_item_pk_no Number(16);
      v_mas_no Varchar2(32);
      v_msg varchar2(1024);
      v_cust_name varchar2(1024);

      cursor cdtl is select srp_key from service_detail Where (srp_key = v_srp_key or src_pk_no =p_pk_no) And status_flg ='A';
      cursor citem is select srp_key,tsn from tgc_order_item where mas_pk_no = p_pk_no and srp_key is not null;
    begin
              for ritem in citem loop
                  update  service_detail a
                   Set tcd_tsn=nvl(a.tcd_tsn,ritem.tsn),
                       a.start_date=v_cmp_date
                 Where srp_key = ritem.srp_key
                 And status_flg ='A';
           /*
              Update service_detail a

                   Set tcd_tsn=v_tivo_tsn,
                       a.start_date=v_cmp_date
                 Where (srp_key = v_srp_key
                  or src_pk_no =p_pk_no)
                 And status_flg ='A';*/

              for rec_dtl in cdtl loop
                  v_srp_key := ritem.srp_key;
              --    v_srp_key := rec_dtl.srp_key;
                  Select item_code,tcd_tsn into v_item_code,v_tsn
                    from service_detail
                   where srp_key=ritem.srp_key;
                    v_main_item := tgc_util.chk_main_item(v_item_code,v_TSN);
                    if v_main_item = 'Y' then
                        If v_str_pk_no Is Null Then
                           v_cust_name := tgc_util.get_cust_name(v_cust_id);
                           Select seq_sys_no.Nextval Into v_str_pk_no From dual;
                           v_mas_no := sysapp_util.Get_Mas_No(1,1,Sysdate,'SRVSTART',v_str_pk_no);
                           Insert Into service_startbill_mas(src_pk_no,src_code,src_no,src_date,pk_no,mas_code,mas_no,mas_date,status_flg,create_user,Create_date,Description)
                           Values (p_pk_no,'TGCORDER',v_order_id,sysdate,v_str_pk_no,'SRVSTART',v_mas_no,Sysdate,'A',p_user_no,Sysdate,'系統開啟出帳('||v_cust_id||','||v_cust_name||')');
                        End If;
                        Select seq_sys_no.Nextval Into v_item_pk_no From dual;
                        Insert Into service_startbill_item(mas_pk_no,pk_no,cust_code,tsn,srp_key,start_bill_date)
                        Values (v_str_pk_no,v_item_pk_no,v_cust_id,v_tsn,v_srp_key,v_bill_start_date);

                        v_msg := tgc_bill_post.tgc_startbill_post(p_user_no,v_str_pk_no,'N');
                   else
                --
                -- 非主體性商品直接關閉
                --
                         Update service_detail a
                           Set status_flg ='N'
                         Where srp_key=v_srp_key;

                       Update service_chg_detail
                            Set start_date = v_bill_start_date,
                                  start_bill_date = v_bill_start_date,
                                  status_flg ='N'
                          Where srp_key =v_srp_key;

                     end if;
                   end loop;
          end loop;


    end;
/*
    Begin
       Select srp_key Into v_srp_key From tgc_order Where order_no = p_pk_no;
       Update service_detail a
           Set status_flg ='P',
                 tcd_tsn=v_tivo_tsn,
                 a.start_date=v_cmp_date
         Where (srp_key = v_srp_key
          or src_pk_no =p_pk_no)
         And status_flg ='A';

       Update service_chg_detail
            Set start_date = v_bill_start_date,
                  start_bill_date = v_bill_start_date,
                  status_flg ='P'
          Where (srp_key =v_srp_key
          or srp_key in (select srp_key from service_detail where src_pk_no=p_pk_no))
               And status_flg='A';
          --     And Start_date Is Null;
     End;*/

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

   Function order_generate_new(p_user_no Number,p_pk_no Number,p_order_type Varchar2 Default Null,p_program Varchar2 Default Null,p_product Varchar2 Default Null) Return Varchar2 Is
    Exception_Msg Varchar2(256) Default Null;
    App_Exception Exception;
    v_Process_Sts  Varchar2(32);
    v_need_install    Varchar2(32);
    v_new_order_no Number(16);
    v_error_code Varchar2(128);
  Begin
    Select Process_Sts,need_install
      Into v_Process_Sts,v_need_install
      From Tgc_Order
     Where Order_No = p_Pk_No
          For Update Nowait;

    If v_Process_Sts <> 'W' Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

    Select Seq_Sys_No.Nextval Into v_new_order_no From dual;

    --
    Insert Into tgc_order(
order_no, order_id, cust_id, program_id, product_id, order_type, channel_id, channel_grp_id, channel_deliver_type,
channel_stk_id, apply_date, order_create_date, mso_id, bb_id, need_deliver_tivo, tivo_device_no, tsn, tivo_price,
need_deliver_usb, usb_qty, usb_price, need_deliver_router, router_qty, router_price, need_deliver_others, others_list,
others_qty, others_price, need_install, partner_book_date, tgc_book_date, book_record, process_sts, approved_sts,
deliver_to_cust_installer, deliver_address, assigned_csr_empid, assigned_installer_empid, need_voucher, voucher_number,
voucher_bid, vouchaer_title, voucher_type, voucher_sts, first_billing_pay_type, deposit, voucher_amount, first_total_amount,
first_billing_sts, auto_ar_sts, auto_cost_sts, auto_bank_sts, set_top_box, ip_router, ip_type, already_tivo, already_usb,
already_apwifi, already_apnet, sa_id, dispatch_id, pl_id, install_place_type, install_address, billing_address, contact_person,
contact_tel, referee, referee_tel, referee_id, service_fee_start_date, partner_sales, tgc_sales_empid, billing_type, cust_user_no,
dispatch_no, partner_book_time, csr_status, rec_tivo, src_order_no, new_order_no, rec_tivo_date,ref_member_id,org_order_id,org_order_cate,ref_order_id,
ap_model,usb_model,remote_model
)

Select v_new_order_no , sysapp_util.get_mas_no(1,1,Sysdate,'TGCORDER',  1)
order_id , cust_id, p_program, p_product,p_order_type order_type, channel_id, channel_grp_id, channel_deliver_type,
channel_stk_id, apply_date, Sysdate order_create_date, mso_id, bb_id,'N'  need_deliver_tivo, tivo_device_no, tsn, tivo_price,
'N' need_deliver_usb, usb_qty, usb_price, 'N' need_deliver_router, router_qty, router_price, 'N' need_deliver_others, others_list,
others_qty, others_price, 'N'  need_install, partner_book_date, Null tgc_book_date, book_record, 'A' process_sts, approved_sts,
deliver_to_cust_installer, deliver_address, assigned_csr_empid, assigned_installer_empid, need_voucher, voucher_number, voucher_bid,
vouchaer_title, voucher_type, voucher_sts, first_billing_pay_type, deposit, voucher_amount, first_total_amount,
first_billing_sts, auto_ar_sts, auto_cost_sts, auto_bank_sts, set_top_box, ip_router, ip_type,
already_tivo, already_usb, already_apwifi, already_apnet, sa_id, Null dispatch_id, null, install_place_type,
install_address, billing_address, contact_person, contact_tel, referee, referee_tel, referee_id, service_fee_start_date, partner_sales,
tgc_sales_empid, billing_type, cust_user_no, Null dispatch_no, partner_book_time, csr_status, rec_tivo, p_pk_no src_order_no, Null new_order_no, rec_tivo_date,
ref_member_id,org_order_id,org_order_cate,ref_order_id,ap_model,usb_model,remote_model
 From tgc_order Where order_no=p_pk_no;

 --  v_error_code :=   tgc_order_post.order_post(p_user_no,v_new_order_no);




    -- Order Status

    Update Tgc_Order Set Process_Sts = 'Y' ,new_order_no = v_new_order_no Where Order_No = p_Pk_No;

    -- clear todolist

     Sysapp_Util.clear_Todo_List(p_user_no, 'generate new order', 'TGCORDER', p_Pk_No);

    Insert Into Sysevent_Log (App_Code,Pk_No,Event_Date,User_No,Event_Type,Seq_No, Description)
    Values ('TGCORDER', p_Pk_No, Sysdate,  p_User_No,  'generate new order',  Sys_Event_Seq.Nextval, 'generate new order');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;



   Function dispatch_post(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_no      Number(16);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
    v_ds_inst_group  Varchar2(32);
    v_order_id Varchar2(32);
    v_dispatch_type Varchar2(32);
    v_process_sts Varchar2(32);
    v_order_dispatch_id Varchar2(32);
    v_order_dispatch_no Number(16);
    v_rec_money     Number(16);
    v_bid_type Varchar2(32);
    v_bid Varchar2(256);
    v_title Varchar2(256);
  Begin
     v_ds_inst_group := sysapp_util.get_sys_value('TGCORDER','AssigenInstallerGroup','#AS_INST_G');

    Select status,installer_no,book_time,order_no,dispatch_id,dispatch_type,order_id,rec_money_amt,bid_type,bid,title
      Into v_status,v_installer_no,v_book_time,v_order_no,v_dispatch_id,v_dispatch_type,v_order_id,v_rec_money,v_bid_type,v_bid,v_title
      From Tgc_dispatch_info
     Where dispatch_no = p_Pk_No
          For Update Nowait;

    If v_status <> 'A' Then
      Exception_Msg := '#單據狀態不為打單中#';
      Raise App_Exception;
    End If;

    If v_dispatch_type In ('0','1') Then
      If v_order_id Is Null Then
          Exception_Msg := '#新機安裝及重新安裝司需輸入訂單編號#';
          Raise App_Exception;
     Else
         Begin
             Select process_sts,dispatch_id,dispatch_no
             Into v_process_sts,v_order_dispatch_id,v_order_dispatch_no
             From tgc_order Where order_id = v_order_id;
             If v_process_sts In ('C','F') Then
                Exception_msg := '#錯誤:訂單已被取銷或作廢#';
                Raise App_Exception;
             End If;

             If v_order_dispatch_id Is Null Then
                Update  tgc_order
                Set       dispatch_id = v_dispatch_id,
                            dispatch_no = p_pk_no
                  Where order_id = v_order_id;
             End If;
         Exception
            When no_data_found Then
                Exception_Msg := '#錯誤的訂單編號#';
                Raise App_Exception;
          End;

    End If;
   elsif v_dispatch_type In ('6') then
       If v_order_id Is not Null Then
       declare
         v_invo_pk_no number(16);
         v_tax_invo_no varchar2(32);
       begin
         select a.inv_pk_no into v_invo_pk_no
          from tgc_order a
          where order_id=v_order_id;
         if v_invo_pk_no is not null then
            Select b.inv_no into v_tax_invo_no
             from service_invo_mas b
            where b.pk_no=v_invo_pk_no;
            if v_tax_invo_no is not null then
               Update  tgc_order
                Set process_sts='E'
                  Where order_id = v_order_id;
            else
               Update  tgc_order
                Set process_sts='B'
                  Where order_id = v_order_id;
            end if;

         else
           Update  tgc_order
                Set process_sts='B'
                  Where order_id = v_order_id;
         end if;
       end;
       end if;
   End If;

  /*  If v_rec_money > 0 Then
        If v_bid_type Is Null Then
          exception_msg := '#發票種類未填#';
          Raise App_Exception;
        End If;

        If v_bid_type = '3' Then
          If v_bid Is Null Or v_title Is Null Then
            exception_msg := '#統編或抬頭未填#';
            Raise App_Exception;
          End If;
        End If;
    End If;*/

    Update tgc_order Set dispatch_no = nvl(dispatch_no,p_pk_no)
                                    ,dispatch_id = nvl(dispatch_id,v_dispatch_id)
         Where order_no = v_order_no;


    Update Tgc_dispatch_info Set status = 'P' Where dispatch_no = p_Pk_No;

    sysapp_util.set_todo_list(v_ds_inst_group,'新進件','TGCDISPATCH',p_pk_no);

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  '確認',Sys_Event_Seq.Nextval, '派工中');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

  Function dispatch_Assigned_installer(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_id      Varchar2(32);
    v_book_time       Date;
    v_ds_book_s      Date;
    v_rec_money     Number(16);
    v_bid_type Varchar2(256);

  Begin

    Select status,installer_id,book_time,ds_book_time_s,rec_money_amt,bid_type
      Into v_status,v_installer_id,v_book_time,v_ds_book_s,v_rec_money,v_bid_type
      From Tgc_dispatch_info
     Where dispatch_no = p_Pk_No
          For Update Nowait;

    If v_status <> 'P' Then
      Exception_Msg := '#單據狀態不為派工中#';
      Raise App_Exception;
    End If;

    If v_installer_id Is Null Then
       exception_msg := '#沒有指定安裝人員#';
       Raise app_exception;
    End If;

    If v_book_time Is Null Then
       exception_msg := '#沒有預約時間#';
       Raise app_exception;
     End If;

     If v_ds_book_s Is Null Then
        exception_msg := '#沒有派工時間#';
        Raise app_exception;
     End If;
/*
     If v_rec_money > 0 Then
        If v_bid_type Is Null Then
          exception_msg := '#發票種類未填#';
          Raise App_Exception;
        End If;
    End If;*/

    Update Tgc_dispatch_info Set status = 'D' Where dispatch_no = p_Pk_No;

    Sysapp_Util.clear_Todo_List(p_user_no, 'Assigened', 'TGCDISPATCH', p_Pk_No);

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCORDER', p_Pk_No,  Sysdate,  p_User_No,  '指派工程師',Sys_Event_Seq.Nextval, '指派工程師');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

   Function dispatch_unpost(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_id      Number(16);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);

  Begin

    Select status,installer_no,book_time,order_no,dispatch_id,order_no
      Into v_status,v_installer_id,v_book_time,v_order_no,v_dispatch_id,v_order_no
      From Tgc_dispatch_info
     Where dispatch_no = p_Pk_No
          For Update Nowait;

 --   If v_status Not In ('D','P') Then
 --     Exception_Msg := '#單據狀態不正確#';
  --    Raise App_Exception;
 --   End If;

   -- OEYA
     Update oeya_orders
        Set order_status=0
      Where order_no= v_order_no;

    Update Tgc_dispatch_info Set status = 'A' Where dispatch_no = p_Pk_No;

    Sysapp_Util.clear_Todo_List(p_user_no, 'unpost', 'TGCDISPATCH', p_Pk_No);

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  'Undo Post',Sys_Event_Seq.Nextval, 'Undo Post');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

   Function dispatch_cancel(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_id      Number(16);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
     v_ds_csr_group Varchar2(32);
     v_process_sts Varchar2(32);
    v_cnt Varchar2(32);
  Begin

    Select status,installer_no,book_time,order_no,dispatch_id
      Into v_status,v_installer_id,v_book_time,v_order_no,v_dispatch_id
      From Tgc_dispatch_info
     Where dispatch_no = p_Pk_No
          For Update Nowait;

    If v_status Not  In ('A','E','B') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

    Update Tgc_dispatch_info Set status = 'C' Where dispatch_no = p_Pk_No;

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  'Cancel Dispatch',Sys_Event_Seq.Nextval, 'Cancel Dispatch');

    Commit;

    --
    --  取銷訂單
    --
    If v_order_no Is Not Null Then
               Select Count(*) Into v_cnt From tgc_dispatch_info Where order_no = v_order_no And status Not In ('A','C','Z');

               If v_cnt = 0 Then
                  Select process_sts Into v_process_sts From tgc_order Where order_no = v_order_no;
                        If v_process_sts = 'N' Then
                                    v_ds_csr_group := sysapp_util.get_sys_value('TGCORDER','AssigenCSRGroup','#AS_CSR_G');
                                   --
                                  --To Do List
                                   --

                                   Sysapp_Util.Set_Todo_List(v_ds_csr_group, '派工單取銷,訂單狀態恢覆約裝', 'TGCORDER',  v_order_No);

                                   -- Order Status

                                   Update Tgc_Order Set Process_Sts = 'D'
                                      Where Order_No = v_order_No;

                                   Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
                                       Values ('TGCORDER',  v_order_no,Sysdate, p_User_No, '派工單取銷,恢復約裝',  Sys_Event_Seq.Nextval, '約裝');
                        End If;
             End If;
   End If;

    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

   Function dispatch_nullify(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_id      Number(16);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);

  Begin

    Select status,installer_no,book_time,order_no,dispatch_id
      Into v_status,v_installer_id,v_book_time,v_order_no,v_dispatch_id
      From Tgc_dispatch_info
     Where dispatch_no = p_Pk_No
          For Update Nowait;

    If v_status Not  In ('A') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

    Update Tgc_dispatch_info Set status = 'Z' Where dispatch_no = p_Pk_No;

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  'to nullify dispatch',Sys_Event_Seq.Nextval, 'to nullify dispatch');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

  Function dispatch_Response(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_no      Varchar2(32);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
    v_process_sts    Varchar2(16);
    v_dispatch_type  Number(16);
    v_order_type       Varchar2(16);
    v_finish_date       Date;
    v_result              Varchar2(1);
    v_ap_qty           Number;
    v_usb_qty         Number;
    v_cont_sts        Varchar2(32);
    v_cont_sts1        Varchar2(32);
    v_complete_date Date;
    v_tsn                 Varchar2(32);
    v_disp_response Varchar2(32);
      v_cust_id Varchar2(32);
      v_onb_bor_id Varchar2(32);
      v_onb_bor_cate Varchar2(32);


          v_rec_money_amt Number(16);
      v_rev_money_amt Number(16);
      v_ref_member_id Varchar2(32);
      v_installer_id varchar2(32);


  Begin

    v_cont_sts := sysapp_util.get_sys_value('TGCORDER','DisCmpContractSts',Null);
    v_cont_sts1 := sysapp_util.get_sys_value('TGCORDER','CmpContractSts',Null);

/*    Select dispatch_type,status,installer_no,book_time,order_no,dispatch_id,a.finish_date,a.Result,rev_ap_qty,rev_usb_qty,a.finish_date,a.tsn
      Into v_dispatch_type,v_status,v_installer_no,v_book_time,v_order_no,v_dispatch_id,v_finish_date,v_result,v_ap_qty,v_usb_qty,v_complete_date,v_tsn
      From Tgc_dispatch_info a
     Where dispatch_no = p_Pk_No
          For Update Nowait;*/
    Select cust_id,dispatch_type,status,installer_no,book_time,order_no,dispatch_id,a.finish_date,a.Result,rev_ap_qty,rev_usb_qty,a.finish_date,a.tsn,rec_money_amt,rev_money_amt,installer_id

      Into v_cust_id,v_dispatch_type,v_status,v_installer_no,v_book_time,v_order_no,v_dispatch_id,v_finish_date,v_result,v_ap_qty,v_usb_qty,v_complete_date,v_tsn,v_rec_money_amt,v_rev_money_amt,v_installer_id
            From Tgc_dispatch_info a
     Where dispatch_no = p_Pk_No
          For Update Nowait;

    If v_status Not  In ('D') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;
    if v_installer_id <> 'C000' then

        If v_result Is Null Then
           Exception_Msg := '#回報狀態未填寫#';
          Raise App_Exception;
        End If;

        If v_result ='Y' And v_finish_date Is Null Then
           Exception_Msg := '#未回報完工時間#';
          Raise App_Exception;
        End If;
        If v_rec_money_amt > 0 Then
           If v_rev_money_amt Is Null Then
              Exception_msg := '#未填收取金額#';
              Raise App_exception;
           End If;
        end if;
     /*
        If v_ap_qty Is Null Then
           Exception_msg := '#未填AP回收數量#';
           Raise App_exception;
        End If;

        If v_usb_qty Is Null Then
           Exception_msg := '#未填USB回收數量#';
           Raise App_exception;
        End If;
       */
        If v_tsn Is Null Then
             Exception_msg := '#未填TSN號碼#';
              Raise App_exception;
        End If;
    end if;


    If ( v_order_no Is Not Null) And ( v_dispatch_type In (1,2,3,4,5,7,8,9,0)) Then
       Select process_sts,order_type,ref_member_id,cust_id,org_order_id,ORG_ORDER_CATE,cust_id
       Into v_process_sts,v_order_type,v_ref_member_id,v_cust_id,v_onb_bor_id,v_onb_bor_cate ,v_cust_id
         From tgc_order Where order_no = v_order_no;
       If v_process_sts = 'N' Then
         If v_result = 'Y' Then
           If v_order_type = 'P' Then
             -- 試用
              Update tgc_order Set process_sts = 'W',csr_status=nvl(v_cont_sts,csr_status),complete_date=v_complete_date,tsn=v_tsn
               Where Order_no = v_order_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', v_order_no,  Sysdate,  p_User_No,  '安裝完成',Sys_Event_Seq.Nextval, '安裝完成');

              --
              -- OEYA Return
              --

               If v_ref_member_id Is Not Null Then
               Declare
                      v_back_code Varchar2(32) Default 'A';

                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;

                 Begin
                       Select Rowid Into v_rid From oeya_orders a Where order_sn=v_onb_bor_id And a.back_code In ('119_1','119_2');

                       Update oeya_orders
                        Set order_status=1,
                              order_shipping_status=1
                           Where order_sn=v_onb_bor_id;

                   Exception
                       When no_data_found Then
                             v_onb_bor_id := v_onb_bor_id;
                             v_cust_name := tgc_util.get_cust_name(v_cust_id);
                             v_oeya_member_id := substr(v_ref_member_id,1,instr(v_ref_member_id,'|')-1);
                             v_back_code := '119_1';
                             Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                 Values(Sysdate,v_oeya_member_id,Null,1,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo 試用',v_back_code,Null,v_order_no,0);
                             Commit;
                  End;
                End If;
           Else
              -- 一般
              -- 租賃賣斷完工後才結案
              Null;
/*              Update tgc_order Set process_sts = 'Z',csr_status=nvl(v_cont_sts1,csr_status),complete_date=v_complete_Date,tsn=v_tsn
               Where order_no = v_order_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', v_order_no,  Sysdate,  p_User_No,  '完成',Sys_Event_Seq.Nextval, '完成'); */
            End If;
            End If;
       Else
          Null;
    --      Exception_msg := '#訂單狀態不在已派工#';
    --      Raise App_exception;
       End If;

       -- Response
       v_disp_response := sysapp_util.get_sys_value('TGCDISPATCH','ResponseGroup '||v_order_type,'#AS_CSR_G');
       sysapp_util.set_todo_list(v_disp_response,'派工單已回覆','TGCORDER',v_order_no);
    End If;

    Update Tgc_dispatch_info Set status = 'R' Where dispatch_no = p_Pk_No;

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  'Dispatch Response',Sys_Event_Seq.Nextval, 'Dispatch Response');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;


   Function dispatch_complete(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_installer_no      Varchar2(32);
    v_dispatch_type Number(16);
    v_book_time       Date;
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
    v_process_sts    Varchar2(16);
    v_order_type       Varchar2(16);
    v_finish_date       Date;
    v_result              Varchar2(1);
    v_ap_qty           Number;
    v_usb_qty         Number;
     v_cont_sts        Varchar2(32);
      v_cont_sts1        Varchar2(32);
      v_complete_date Date;
      v_tsn                 Varchar2(32);
      v_rec_money_amt Number(16);
      v_rev_money_amt Number(16);
      v_cust_id Varchar2(32);
      v_onb_bor_id Varchar2(32);
      v_onb_bor_cate Varchar2(32);
      v_installer_id varchar2(32);


      v_ref_member_id Varchar2(32);
      v_old_tsn varchar2(32);
      v_replace_tivo varchar2(32);

      v_invo_pk_no number(16);
  Begin

    v_cont_sts := sysapp_util.get_sys_value('TGCORDER','DisCmpContractSts',Null);
    v_cont_sts1 := sysapp_util.get_sys_value('TGCORDER','CmpContractSts',Null);

    Select installer_id,cust_id,dispatch_type,status,installer_no,book_time,order_no,dispatch_id,a.finish_date,a.Result,rev_ap_qty,rev_usb_qty,a.finish_date,a.tsn,rec_money_amt,rev_money_amt,old_tsn,replace_tivo_flg,invo_pk_no
      Into v_installer_id,v_cust_id,v_dispatch_type,v_status,v_installer_no,v_book_time,v_order_no,v_dispatch_id,v_finish_date,v_result,v_ap_qty,v_usb_qty,v_complete_date,v_tsn,v_rec_money_amt,v_rev_money_amt,v_old_tsn,v_replace_tivo,v_invo_pk_no
      From Tgc_dispatch_info a
     Where dispatch_no = p_Pk_No
          For Update Nowait;

    If v_status Not  In ('R') Then
      Exception_Msg := '#單據狀態不正確#';
      Raise App_Exception;
    End If;

    If v_result Is Null Then
       Exception_Msg := '#回報狀態未填寫#';
      Raise App_Exception;
    End If;

    If v_result ='Y' And v_finish_date Is Null Then
       Exception_Msg := '#未回報完工時間#';
      Raise App_Exception;
    End If;
    if v_installer_id not in ('NULL' ,'C000') then
    If v_ap_qty Is Null Then
       Exception_msg := '#未填AP回收數量#';
       Raise App_exception;
    End If;

    If v_usb_qty Is Null Then
       Exception_msg := '#未填USB回收數量#';
       Raise App_exception;
    End If;

    If v_tsn Is Null Then
         Exception_msg := '#未填TSN號碼#';
          Raise App_exception;
    End If;
    end if;

    If v_rec_money_amt > 0 Then
       If v_rev_money_amt Is Null Then
          Exception_msg := '#未填收取金額#';
          Raise App_exception;
       End If;

      /* If v_rev_money_amt <> v_rec_money_amt Then
            Exception_msg := '#未填收取金額不正確#';
          Raise App_exception;
       End If;*/

       if v_invo_pk_no is not null then
               declare
                 v_open_amount number(16);
               begin
                v_open_amount := 0;
                select nvl(sum(open_amount),0) into v_open_amount
                  from service_acc_detail a
                 where a.src_pk_no in
                    (select pk_no from service_invo_mas b where
                          b.src_pk_no = v_invo_pk_no)
                          and open_flg ='Y';
               if v_open_amount > 0 then
                 exception_msg:= '#此派工單尚有欠款'||v_open_amount||'未沖帳#';
                 Raise App_Exception;
               end if;

              end;
       else
               declare
                 v_open_amount number(16);
               begin
                v_open_amount := 0;
                select nvl(sum(open_amount),0) into v_open_amount
                  from service_acc_detail a
                 where acc_code = v_cust_id
                 and package_key is not null
                 and src_code ='SRVINVO'
                 and open_flg='Y';
               if v_open_amount > 0 then
                 exception_msg:= '#此客戶尚有欠款'||v_open_amount||'未沖帳#';
                 Raise App_Exception;
               end if;

              end;

       end if;
    End If;

    -- 新機安裝才改壯態
    If (v_order_no Is Not Null) And (v_dispatch_type In (0,1,2,3,4,7,8,9)) Then
       Select process_sts,order_type,ref_member_id,cust_id,org_order_id,ORG_ORDER_CATE ,cust_id
       Into v_process_sts,v_order_type,v_ref_member_id,v_cust_id,v_onb_bor_id,v_onb_bor_cate ,v_cust_id
         From tgc_order Where order_no = v_order_no;
       If v_process_sts In ( 'N' ,'Z','W') Then
         If v_result ='Y' Then -- 安裝成功
           If v_order_type = 'P' Then
             -- 試用

              Update tgc_order Set process_sts = 'W',csr_status=nvl(v_cont_sts,csr_status),complete_date=v_complete_date,tsn=v_tsn
               Where Order_no = v_order_no;
               Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
                Values  ('TGCORDER', v_order_no,  Sysdate,  p_User_No,  '安裝完成',Sys_Event_Seq.Nextval, '安裝完成');

              --
              -- OEYA Return
              --

              If v_ref_member_id Is Not Null Then
               Declare
                      v_back_code Varchar2(32) Default 'A';

                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;

                 Begin
                       Select Rowid Into v_rid From oeya_orders Where order_sn=v_onb_bor_id And rownum <=1;

                       Update oeya_orders
                        Set order_status=1,
                              order_shipping_status=1
                           Where order_sn=v_onb_bor_id;

                   Exception
                       When no_data_found Then
                             v_onb_bor_id := v_onb_bor_id;
                             v_cust_name := tgc_util.get_cust_name(v_cust_id);
                             v_oeya_member_id := substr(v_ref_member_id,1,instr(v_ref_member_id,'|')-1);
                             v_back_code := '119_1';
                             Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                 Values(Sysdate,v_oeya_member_id,Null,1,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo 試用',v_back_code,Null,v_order_no,0);
                             Commit;
                  End;
                End If;
           Else
              -- 一般
              declare
                v_month_free number;
                v_product_id varchar2(32);
              begin
              begin
                select product_id into  v_product_id
                from tgc_Order
                where order_no = v_order_no;

                select a.trial_month into v_month_free
                from tgc_product a
                where a.product_id=v_product_id;
              exception
                when no_data_found then v_month_free := null;
              end;

              declare
                v_order_type varchar2(32);
              begin
                select order_type into v_order_type from  tgc_order
                where order_no = v_order_no;

                if v_order_type not in ('L','K') then
                    Update tgc_order a Set process_sts = 'Z',csr_status=nvl(v_cont_sts1,csr_status),
                    complete_date=nvl(complete_date,v_complete_Date),
                    contract_start_date = nvl(contract_start_date,v_complete_date+1),tsn=v_tsn,
                    a.service_fee_start_date = add_months(nvl(contract_start_date,v_complete_date+1),nvl(v_month_free,0))
                     Where order_no = v_order_no;
                else
                    Update tgc_order a Set process_sts = 'Z',csr_status=nvl(v_cont_sts1,csr_status),
                    complete_date=nvl(complete_date,v_complete_Date)
                     Where order_no = v_order_no;
                end if;
              end;
              Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
              Values  ('TGCORDER', v_order_no,  Sysdate,  p_User_No,  '完成',Sys_Event_Seq.Nextval, '完成');
             end;
               -- 結案一併處理
       --     Exception_Msg:=tgc_order_post.order_Complete(p_user_no,v_order_no);
            End If;
       End If;
       End If;

    End If;
    --
    -- Replace TiVo
    --
   if  v_dispatch_type In (4,5,8) then

         If v_old_tsn Is Null Then
            Exception_msg := '#未填舊的TSN號碼#';
            Raise App_exception;
         End If;

         If v_replace_tivo Is Null Then
            Exception_msg := '#未填是否更換機器#';
            Raise App_exception;
         End If;

         if v_replace_tivo = 'Y' then

            declare
              v_srp_key number(16);
              v_cnt number(16);
            begin
              begin
                select srp_key into v_srp_key
                  from service_detail
                  where cust_code= v_cust_id
                    and tcd_tsn = v_old_tsn
                    and status_flg in ('P','B')
                    and rownum <=1 ;
              exception
                 when no_data_found then
                    begin
                    select srp_key into v_srp_key
                    from service_detail
                    where cust_code= v_cust_id
                      and tcd_tsn = v_tsn
                     and status_flg in ('P','B')
                      and rownum <=1 ;

                   exception
                      when no_data_found then
                      Exception_msg := '#找不到服務內容#';
                      Raise App_exception;
                   end;
              end;

/*              begin
                select cnt into v_cnt
                  from tgc_trn_owner_view
                  where cust_id = v_cust_id
                  and tsn = v_old_tsn;
                if v_cnt > 0 then
                  Exception_msg := '#未歸還舊機器#';
                  Raise App_exception;
                 end if;

              exception
                when no_data_found then null;
                     Exception_msg := '#未找到舊機出貨相關紀錄#';
                     Raise App_exception;
              end;*/


              begin
                select cnt into v_cnt
                  from tgc_trn_owner_view
                  where cust_id = v_cust_id
                  and tsn = v_tsn;
              exception
                when no_data_found then
                     Exception_msg := '#未找到新機出貨相關紀錄#';
                     Raise App_exception;
              end;

              if v_cnt = 0 then
                 Exception_msg := '#新機器已歸還#';
                 Raise App_exception;
              end if;

              update service_detail
                 set tcd_tsn=v_tsn
               where srp_key=v_srp_key;



            end;



         end if;
    end if;

    Update Tgc_dispatch_info Set status = 'N' Where dispatch_no = p_Pk_No;

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
    Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  'Complete Dispatch',Sys_Event_Seq.Nextval, 'Complete Dispatch');

    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

   Function dispatch_auto_complete(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_installer_id varchar2(32);
    v_cust_id varchar2(32);
    v_pl_id varchar2(32);
    v_open_amount number(16);
    v_result varchar2(32);
    v_order_no number(16);
    v_order_id varchar2(32);
    v_order_type varchar2(32);
    msg varchar2(1024);
    Begin
       --
       -- 檢查派工人員是否為C000
       --
       select installer_id,cust_id,pl_id,result,order_no
        into v_installer_id,v_cust_id,v_pl_id,v_result,v_order_no
       from tgc_dispatch_info where dispatch_no=p_pk_no;
       if v_installer_id = 'C000' then
          --
          -- 檢查是否尚有欠款
          --
          select sum(nvl(open_amount,0)) into v_open_amount
           from service_acc_detail
          where package_key is not null
            and acc_code=v_cust_id
            and src_code='SRVINVO';

          if nvl(v_open_amount,0) <= 0 and v_pl_id is not null then
             if v_result is null then
               update tgc_dispatch_info x
                  set
                 result = 'Y',
                 x.finish_date=sysdate,
                 x.rev_money_amt = 0
                where dispatch_no = p_pk_no;
             end if;

             msg:= tgc_order_post.Dispatch_Response(p_user_no,p_Pk_No);
             msg := tgc_order_post.Dispatch_Complete(p_user_no,p_pk_no);
          end if;

          begin
            select order_no, order_type into v_order_no,v_order_type
             from tgc_order a where dispatch_no = p_pk_no;
          exception
            when no_data_found then v_order_no := null;
          end;

          if v_order_type in ('B','S') then
            msg:=tgc_order_post.order_Complete(p_user_no,v_order_no);
          end if;

       end if;

      commit;
    Exception
      When App_Exception Then
        Rollback;
        Raise_Application_Error(-20002, Exception_Msg);
        Return(Exception_Msg);
      When Others Then
        Rollback;
        Raise_Application_Error(-20002, Sqlerrm);
        Return(Sqlerrm);
     End;

   Function query_post(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
    v_ds_inst_group  Varchar2(32);
    v_order_cont_sts Varchar2(32);
    v_mas_cont_sts  Varchar2(32);
    v_query_code      Varchar2(32);
    v_cont_sts          Varchar2(32);
    v_cont_sts2        Varchar2(32);
  Begin
     v_ds_inst_group := sysapp_util.get_sys_value('TGCORDER','AssigenInstallerGroup','#AS_INST_G');

    Select status,mas_code,src_no
        Into v_status,v_query_code,v_order_no
      From tgc_csr_qform1 a
     Where a.pk_no = p_Pk_No
          For Update Nowait;

    If v_status <> 'A' Then
      Exception_Msg := '#狀態不正確#';
      Raise App_Exception;
    End If;

    Select mas_code,cont_sts,cont_sts2
        Into v_query_code,v_cont_sts,v_cont_sts2
       From tgc_csr_query_mas a
     Where a.mas_code = v_query_code;

     Select csr_status
        Into v_order_cont_sts
      From tgc_order a
      Where order_no = v_order_no;

    If v_order_cont_sts <> v_cont_sts Then
       Exception_msg := '#訂單狀態不正確#';
       Raise App_exception;
    End If;

    Update tgc_order
          Set csr_status = v_cont_sts2
       Where order_no = v_order_no;

    Update tgc_csr_qform1
         Set status = 'P'
       Where pk_no = p_pk_no;


    Commit;
    Return Null;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

    Function dispatch_print(p_User_No Number, p_Pk_No Number) Return Varchar2
   Is
   Begin

      Insert Into TGC_DISPATCH_PRT_HIS(DISPATCH_NO,PRINT_DATE)
      Values (p_pk_no,Sysdate);

     Commit;
     Return Null;
   End;

   Function dispatch_installer_book(p_User_no Number,p_pk_no Number,p_inst_id Varchar2,p_book_time Date) Return Varchar2
   Is
    Exception_Msg  Varchar2(256) Default Null;
    App_Exception  Exception;
    v_status            Varchar2(32);
    v_order_no         Number(16);
    v_dispatch_id     Varchar2(32);
    v_ds_inst_group  Varchar2(32);
    v_order_cont_sts Varchar2(32);
    v_mas_cont_sts  Varchar2(32);
    v_query_code      Varchar2(32);
    v_cont_sts          Varchar2(32);
    v_cont_sts2        Varchar2(32);
    v_inst_no           Number(16);
    v_char Varchar2(1);
  Begin
     If p_pk_no Is Not Null Then
      Begin
     /*   Select 'x' Into v_char
           From tgc_dispatch_info
            Where installer_id = p_inst_id
                And (ds_book_time_s <= p_book_time+(1/24)
                And ds_book_time_e > p_book_time)
                And dispatch_no <> p_pk_no;
           Exception_Msg := '#約裝時間重疊#';
           Raise App_Exception;
       Exception
          When no_data_found Then Null;*/
          Null;
         End;
      Select  user_no Into v_inst_no
           From sys_user
          Where user_name = p_inst_id;

       Update tgc_dispatch_info
          Set ds_book_time_s  = p_book_time,
                ds_book_time_e  = p_book_time+1/24,
                installer_id  = p_inst_id,
                installer_no = v_inst_no
       Where dispatch_no = p_pk_no;

      Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
       Values  ('TGCDISPATCH', p_Pk_No,  Sysdate,  p_User_No,  'Book  installer',Sys_Event_Seq.Nextval, '設訂安裝工程師');



    Commit;
    Return Null;
    Else
     Return Null;
    End If;
  Exception
    When App_Exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
   End;

   Function Dispatch_sendMessageToOrder(p_User_no Number,p_pk_no Number,p_message Varchar2) Return Varchar2
   Is
     v_order_no Number;
     v_order_type Varchar2(32);
     v_seq_no Number;
     v_disp_response Varchar2(32);
     v_result Varchar(1024);
   Begin
        Select a.order_no Into v_order_no From tgc_dispatch_info a
        Where a.dispatch_no = p_pk_no;

        --
        --
        --
        Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
          Values  ('TGCDISPATCH', p_pk_no,  Sysdate,  p_User_No,'派工單訊息',Sys_Event_Seq.Nextval, p_message);

       If v_order_no Is Not Null Then
          Select order_type Into v_order_type
             From tgc_order
            Where order_no = v_order_no;
          Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date,User_No, Event_Type,Seq_No, Description)
               Values  ('TGCORDER', v_order_no,  Sysdate,  p_User_No,'派工單訊息',Sys_Event_Seq.Nextval, p_message);
          Insert Into TGC_CSR_TELREC(SRC_PK_NO,USER_NO,CUST_ID,REC_DATE,REC_DATA,CREATE_USER_NO,PK_NO)
               Values (v_order_no,p_user_no,Null,Sysdate,p_message,p_user_no,seq_sys_no.nextval);

          v_disp_response := sysapp_util.get_sys_value('TGCDISPATCH','ResponseGroup '||v_order_type,'#AS_CSR_G');
          Sysapp_Util.Set_Todo_List(v_disp_response, '派工單訊息:'||p_message, 'TGCORDER', v_order_no);
          Commit;
          v_result := '訊息已送出!';
        Else
          v_result := '沒有訂單資料!';
        End If;

        Return v_result;
  Exception
     When no_data_found Then Return '沒有送出訊息' ;

   End;

     Function create_service_detail(p_user_no Number,p_order_no Number) Return Varchar2 Is
         Exception_msg Varchar2(1024);
         app_exception Exception;

          v_Chg_Pk_No       Number;
          v_Next_Bill_Date  Date;
          v_Last_Bill_Date  Date;
          v_Srp_Key         Number;
          v_Bill_Type       Varchar2(32);
          v_Chg_Type        Varchar2(32);
          v_Status_Flg      Varchar2(32);
          v_Pm_Code         Varchar2(32);
          v_Net_Price       Number(16);
          v_Group_No        Number(16);
          v_Cust_User_No    Number(16);
          v_Package_Key     Number(16);
          v_Pk_No           Number(16);
          v_Address         Varchar2(256);
          v_Product_Id      Varchar2(256);
          v_Program_Id      Varchar2(256);
          v_First_Bill_Date Date;
          v_Svc_Start       Date;
          v_Product_Name    Varchar2(128);
          v_Cust_Id         Varchar2(32);
          v_Start_Bill_Date Date;
          v_Order_No        Number(32);
          v_Order_Id        Varchar2(32);
          v_Order_Code      Varchar2(32);
          v_Order_Date      Date;
          v_Program_Name    Varchar2(128);
          v_Zip             Varchar2(32);
          v_item_code Varchar2(32);
          v_ref_order_id Varchar2(32);
          v_tsn Varchar2(32);
        --  v_net_price Number(32);
          v_pay_period Number(32);
          v_order_type Varchar2(32);
          v_sale_mode Varchar2(32);
          v_item_mode Varchar2(32);
          v_prod_flg Varchar2(32);
          v_inst_addr Varchar2(1024);
          v_inst_zip Varchar2(32);
          v_bill_addr Varchar2(1024);
          v_bill_zip Varchar2(32);
          v_cont_start_date Date;
          v_bill_start_date Date;
          v_item_name Varchar2(1024);
          v_bill_type varchar2(1024);
          v_bill_group varchar2(1024);
          v_vou_type Varchar2(32);
          v_vou_title Varchar2(256);
          v_vou_uid Varchar2(32);


     Begin
     v_bill_group := sysapp_util.get_sys_value('TGCORDER','BillGroup','vicky.huang');
        Begin
            Select Cust_Id,
                   Program_Id,
                   Product_Id,
                   Order_Id,
                   Order_No,
                   Order_Create_Date,
                   Ref_Order_Id,
                   Tsn,
                   a.Contract_Start_Date,
                   Order_Type,
                   a.Install_Zip,
                   a.Install_Address,
                   a.Billing_Zip,
                   a.Billing_Address,
                   Nvl(a.Contract_Start_Date, a.Service_Fee_Start_Date),
                   a.Service_Fee_Start_Date,
                   a.voucher_type,
                   a.voucher_bid,
                   a.vouchaer_title
              Into v_Cust_Id,
                   v_Program_Id,
                   v_Product_Id,
                   v_Order_Id,
                   v_Order_No,
                   v_Order_Date,
                   v_Ref_Order_Id,
                   v_Tsn,
                   v_Svc_Start,
                   v_Order_Type,
                   v_Inst_Zip,
                   v_Inst_Addr,
                   v_Bill_Zip,
                   v_Bill_Addr,
                   v_Cont_Start_Date,
                   v_Bill_Start_Date,
                   v_vou_type,
                   v_vou_uid,
                   v_vou_title
              From Tgc_Order a
             Where Order_No = p_Order_No;
        Exception
            When no_data_found Then
               exception_msg := '#找不到訂單資料#';
               Raise app_exception;
        End;

        Begin
           Select Cust_Id, User_No, Address
               Into v_Cust_Id, v_Cust_User_No, v_Address
            From Tgc_Customer a
          Where cust_id=v_cust_id;
        Exception
            When no_data_found Then
               exception_msg := '#找不到客戶資料#';
               Raise app_exception;
        End;

        declare
           cursor c_item is select pk_no,item_code from tgc_order_item where mas_pk_no = p_order_no;
           v_item_flg varchar2(32);
        begin
           for r_item in c_item loop

               v_item_code := r_item.item_code;
               select item_flg into v_item_flg from service_item_mas where item_code=v_item_code;
               if v_item_flg = 'M' then
                   v_item_name := tgc_util.get_item_name(v_item_code);
                   v_program_name := tgc_util.get_program_name(v_program_id);
                   v_product_name := tgc_util.get_product_name(v_product_id);
                   Select Seq_Srp_Key.Nextval Into v_Package_Key From Dual;
                   v_Srp_Key := v_Package_Key;
                   v_Pk_No   := v_Srp_Key;

                   If v_order_type In ('L','K','X') Then
                      v_sale_mode := 'Y';
                      v_item_mode := 'Y';
                      v_prod_flg:='S';
                   Elsif v_order_type In ('B','J') Then
                      v_sale_mode := 'B';
                      v_item_mode := 'X';
                      v_prod_flg :='F';
                   Elsif v_order_type in ('P') then
                      v_sale_mode := 'X';
                      v_item_mode := 'M';
                      v_prod_flg :='S';
                   End If;

                   v_svc_start := v_cont_start_date;

                   Insert Into Service_Detail
                    (Pk_No,         Srp_Key,         package_key,         Cust_Code,         Acc_Code,
                     Inst_Address,inst_zip,         bill_address,  bill_zip,       Contract_No,         Tcd_Tsn,         Product_Name,
                     Product_ID,         Start_Date,         End_Date,         Svc_Start,         Svc_End,
                     Acc_User_No,         Product_Qty,         Stk_Qty,         Lead_Time, item_code,Name,sale_mode,item_mode,prod_flg,src_code,src_pk_no,src_mas_date,src_mas_no,program_id,status_flg,ref32)
                    Values( v_pk_no,      v_srp_key,      v_package_key,      v_cust_id,      v_cust_id,
                    v_inst_addr,v_inst_zip,      v_bill_addr,  v_bill_zip,    v_ref_order_id,      v_tsn,      v_product_name,
                    v_product_id,      v_svc_start,      Null,      v_svc_Start,     Null,
                    v_cust_user_no,      1,         1,         0,v_item_code,v_item_NAME,v_sale_mode,v_item_mode,v_prod_flg,'TGCORDER',v_order_no,v_order_date,v_order_id,v_program_id,'A','ORDER');

                    Update tgc_order a
                    Set a.srp_key =v_srp_Key
                    Where order_no = p_order_no;

                    update tgc_order_item a
                    set a.srp_key = v_srp_key
                    where pk_no =r_item.pk_no;
                    
                    update tgc_order_item a
                    set a.srp_key = v_srp_key
                    where mas_pk_no =p_order_no
                    and item_code in (select item_code from service_item_mas where nvl(item_flg,'X') not in ('M'));


                    Declare
                        Cursor c1 Is Select chg.chg_code,chg.item_code,chg.pm_code,chg.net_price
                                             From service_product_item_chg chg Where chg.product_id=v_product_id
                                             And chg.default_flg='Y' And chg.free_period > 0 And chg.sell_acc_code Is Null;
                       v_pay_period Number(16);
                       v_tax_flg Varchar2(32);
                       v_tax_code Varchar2(32);
                       v_chg_type Varchar2(32);
                       v_bill_type Varchar2(32);
                    --   v_bill_start_date Date;

                    Begin
                        For c1rec In c1 Loop
                           Select m.chg_type Into v_chg_type
                             From service_charge_mas m
                           Where m.chg_code=c1rec.chg_code;

                          Select pay_period,bill_type
                               Into v_pay_period,v_bill_type
                              From service_pm_mas n
                             Where n.pm_code=c1rec.pm_code;

                            Select seq_srp_key.Nextval Into v_chg_pk_no From dual;

                           v_status_flg :='A';
                           v_start_bill_date := v_bill_start_date;

                        --   If v_start_bill_date Is Null Then
                        --        exception_msg := '#沒有第二期起帳日#';
                         --        Raise app_exception;
                       --    End If;

                           If v_vou_type='3' Then
                             v_tax_code := 'OUTTAX2';
                           Elsif  v_vou_type='2' Then
                             v_tax_code := 'OUTTAX1';
                           Elsif v_vou_type='1' Then
                             v_tax_code := 'OUTTAX0';
                           End If;

                           Select tax_flg Into v_tax_flg From service_charge_mas Where chg_code=c1rec.chg_code;

                           v_tax_flg := nvl(v_tax_flg,'Y');
                           v_tax_code := nvl(v_tax_code,'OUTTAX1');


                           Insert Into Service_Chg_Detail
                           (Pk_No,        Srp_Key,        Chg_Group_No,        Status_Flg,        Acc_User_No,
                           Acc_Code,        Product_Id,        Item_Code,        Chg_Code,        Chg_Type,
                            Pm_Code,        Tax_Flg,        Tax_Code,        Tax_Ref,        Tax_Rate,
                            Sales_Price,        Net_Price,        Start_Date,        Start_Bill_Date,        Next_Bill_Date,
                            Last_Bill_Date,        Pay_Period,        Rest_Period,        Remark,bill_type,terms
                           )        Values   (
                            v_chg_pk_no,         v_srp_key,         0,        v_status_flg,         v_cust_user_no,
                             v_cust_id,       v_product_id,        v_item_code,       c1rec.chg_code,       v_chg_type,
                             c1rec.pm_code,        v_tax_flg,       v_tax_code,        '',        0,
                           c1rec.net_price,        c1rec.net_price,       v_start_bill_date,        v_start_bill_date,        Null,
                           Null,        v_pay_period,        0,        '',v_bill_type,'14'
                          ) ;


                        End Loop;
                      End;
        End if;
           End loop;
        end;

   --
    --To Do List
    --

    Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('TGCORDER',  p_order_No,  Sysdate, p_User_No, 'Create Service Detail',  Sys_Event_Seq.Nextval, 'Create Service');

    Sysapp_Util.Set_Todo_List(v_bill_group, '訂單結案,產生服務內容'||v_Cust_Id , 'TGCORDER', p_order_No);

      Return Null;
    Exception
      When  App_Exception Then
        Rollback;
        Raise_Application_Error(-20002, Exception_Msg);
        Return(Exception_Msg);
      When Others Then
        Rollback;
        Raise_Application_Error(-20002, Sqlerrm);
        Return(Sqlerrm);
     End;

      Function create_order_detail(p_user_no Number,p_order_no Number) Return Varchar2
      is

        v_product_id varchar2(32);
        v_tax_code varchar2(32);
        v_vou_type varchar2(32);
        v_usb_model varchar2(128);
        v_ap_model varchar2(128);
        v_remote_model varchar2(128);
        v_others_list varchar2(128);
        v_ap_qty number(16);
        v_remote_qty number(16);
        v_usb_qty number(16);
        v_others_qty number(16);
        v_process_sts varchar2(32);
        Exception_Msg varchar2(1024);
        App_Exception exception;
        sell_acc_code varchar2(32);
        sell_flg varchar2(32);
        v_order_type varchar2(32);
        v_need_install varchar2(32);
        v_sell_acc_code varchar2(32);
        v_sell_acc_flg varchar2(32);


      begin
         select product_id,
                a.voucher_type,
                a.usb_qty,
                a.usb_model,
                a.router_qty,
                a.ap_model,
                a.remote_qty,
                a.remote_model,
                a.others_qty,
                a.others_list,
                a.process_sts,
                a.order_type,
                a.need_install,
                a.sell_flg,
                a.sell_acc_code
           into v_product_id, v_vou_type,
           v_usb_qty,v_usb_model,
           v_ap_qty,v_ap_model,
           v_remote_qty,v_remote_model,
           v_others_qty,v_others_list,
           v_process_sts,v_order_type,
           v_need_install,
           v_sell_acc_flg,
           v_sell_acc_code
           from tgc_order a
          where order_no = p_order_no;


         if NVL(v_process_sts,'C') <> 'A' then
           exception_msg := '#單據狀態錯誤#';
           raise app_exception;
         end if;

      --   delete tgc_order_detail where mas_pk_no=p_order_no;
      --   delete tgc_order_item where mas_pk_no = p_order_no;

         If v_vou_type='3' Then
           v_tax_code := 'OUTTAX2';
         Elsif  v_vou_type='2' Then
           v_tax_code := 'OUTTAX1';
         Elsif v_vou_type='1' Then
           v_tax_code := 'OUTTAX0';
         else
           exception_msg := '#請輸入發票種類#';
           raise app_exception;
         End If;
         v_tax_code := nvl(v_tax_code,'OUTTAX1');

/*         if v_ap_qty is null  then
           exception_msg := '#請輸入AP數量#';
           raise app_exception;
         end if;

         if v_usb_qty is null  then
           exception_msg := '#請輸入USB數量#';
           raise app_exception;
         end if;

         if v_remote_qty is null  then
           exception_msg := '#請輸入reomte數量#';
           raise app_exception;
         end if;*/


         declare
           cursor c1 is select 1,a.item_code,a.pk_no from service_product_item a,service_item_mas b
                          where a.product_id=v_product_id
                            and a.item_code=b.item_code
                            and b.item_flg ='M'
                            and a.default_flg='Y'
                          union all
                          select 2,a.item_code,a.pk_no from service_product_item a,service_item_mas b
                          where a.product_id=v_product_id
                            and a.item_code=b.item_code
                            and b.item_flg ='G'
                            and a.default_flg='Y'
                            union all
                          select 3,a.item_code,a.pk_no from service_product_item a,service_item_mas b
                          where a.product_id=v_product_id
                            and a.item_code=b.item_code
                            and nvl(b.item_flg,'a') not in  ('G','M')
                            and a.default_flg='Y'
                          order by 1,2;

           cursor c2(p_item_pk_no number) is
                         select b.chg_code,b.pm_code,b.net_price,b.sell_acc_code,b.sell_flg,b.list_price
                           from service_product_item_chg b
                          where b.mas_pk_no=p_item_pk_no
                            and b.free_period=0;

           v_item_code  varchar2(32);
           v_item_cat   varchar2(32);
           v_item_pk_no number(16);
           v_item_no    number(16);

           v_chg_code   varchar2(32);
           v_pm_code    varchar2(32);
           v_tax_flg    varchar2(32);
           v_chg_type   varchar2(32);
           v_bill_type  varchar2(32);
           v_item_name  varchar2(128);
           v_dtl_pk_no  number(16);
           v_acc_code   varchar2(32);
           v_list_price number(16);
           v_char       varchar2(1);
           v_ship_mode  varchar2(32);

         begin
            v_item_no := 0;
            for c1rec in c1 loop
               v_item_no := v_item_no + 1;
               v_item_code := c1rec.item_code;
               select seq_sys_no.nextval into v_item_pk_no
                 from dual;

               select cat,item_name into v_item_cat,v_item_name
                 from service_item_mas where item_code= v_item_code;

               if v_need_install = 'Y' then
                  v_ship_mode := 'DS';
               else
                  v_ship_mode := 'S';
               end if;

               insert into tgc_order_item(mas_pk_no,pk_no,item_no,sale_mode,item_cat,item_code,item_qty,ship_mode)
               values (p_order_no,v_item_pk_no,v_item_no,v_order_type,v_item_cat,v_item_code,1,v_ship_mode);
               if nvl(v_sell_acc_flg,'N') <> 'Y' then
                   for c2rec in c2(c1rec.pk_no) loop
                       v_chg_code := c2rec.chg_code;
                       v_pm_code := c2rec.pm_code;
                       select tax_flg,chg_type into v_tax_flg,v_chg_type from service_charge_mas
                          where chg_code= v_chg_code;

                       select bill_type into v_bill_type from service_pm_mas
                          where pm_code= v_pm_code;

                       select seq_sys_no.nextval into v_dtl_pk_no from dual;

                       if c2rec.sell_acc_code is not null then
                          v_acc_code := c2rec.sell_acc_code;
                       else
                          v_acc_code := null;
                       end if;

                       v_list_price := nvl(c2rec.list_price,c2rec.net_price);

                       insert into tgc_order_detail(mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,tax_flg,tax_code,item_code,item_name,acc_code,list_amount,qty)
                       values(p_order_no,v_dtl_pk_no,null,v_item_pk_no,v_chg_code,v_chg_type,v_bill_type,v_pm_code,c2rec.net_price,v_tax_flg,v_tax_code,v_item_code,v_item_name,v_acc_code,v_list_price,1);

                   end loop;
              end if;
            end loop;
            

/*               if nvl(v_usb_qty,0) > 0 then
                  if v_usb_model is null then
                     Exception_Msg := '#請輸入USB型號#';
                     raise App_Exception;
                  end if;

                   select seq_sys_no.nextval into v_dtl_pk_no from dual;

                   select stock_desc into v_item_name
                     from inv_stk_mas a
                   where a.stock_id=v_usb_model;

                   begin
                     select 'x' into v_char
                       from tgc_order_detail
                       where mas_pk_no = p_order_no
                         and item_code =v_usb_model;
                     update tgc_order_detail
                        set qty=v_usb_qty
                      where mas_pk_no = p_order_no
                         and item_code =v_usb_model;
                   exception
                     when no_data_found then
                      if v_order_type in ('B','S','J') then
                           insert into tgc_order_detail(mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,tax_flg,tax_code,item_code,item_name,list_amount,qty)
                           values(p_order_no,v_dtl_pk_no,null,null,'LIST_PRICE','O','P','SALE',0,'Y',v_tax_code,v_usb_model,v_item_name,0,v_usb_qty);
                      end if;
                   end;
               else
                  delete  tgc_order_detail where mas_pk_no = p_order_no
                         and item_code =v_usb_model;

               end if;

               if nvl(v_ap_qty,0) > 0 then
                  if v_ap_model is null then
                     Exception_Msg := '#請輸入ap型號#';
                     raise App_Exception;
                  end if;
                   select seq_sys_no.nextval into v_dtl_pk_no from dual;

                   select stock_desc into v_item_name
                     from inv_stk_mas a
                  where a.stock_id=v_ap_model;

                   begin
                     select 'x' into v_char
                       from tgc_order_detail
                       where mas_pk_no = p_order_no
                         and item_code =v_ap_model;
                     update tgc_order_detail
                        set qty=v_ap_qty
                      where mas_pk_no = p_order_no
                         and item_code =v_ap_model;
                   exception
                     when no_data_found then
                       if v_order_type in ('B','S','J') then
                       insert into tgc_order_detail(mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,tax_flg,tax_code,item_code,item_name,list_amount,qty)
                       values(p_order_no,v_dtl_pk_no,null,null,'LIST_PRICE','O','P','SALE',0,'Y',v_tax_code,v_ap_model,v_item_name,0,v_ap_qty);
                       end if;
                   end;
                              else
                  delete  tgc_order_detail where mas_pk_no = p_order_no
                         and item_code =v_ap_model;


               end if;

               if nvl(v_remote_qty,0) > 0 then
                  if v_remote_model is null then
                    Exception_Msg := '#請輸入remote型號#';
                    raise App_Exception;
                  end if;
                   select seq_sys_no.nextval into v_dtl_pk_no from dual;

                   select stock_desc into v_item_name
                     from inv_stk_mas a
                  where a.stock_id=v_remote_model;

                   begin
                     select 'x' into v_char
                       from tgc_order_detail
                       where mas_pk_no = p_order_no
                         and item_code =v_remote_model;
                     update tgc_order_detail
                        set qty=v_remote_qty
                      where mas_pk_no = p_order_no
                         and item_code =v_remote_model;
                   exception
                     when no_data_found then
                      if v_order_type in ('B','S','J') then
                       insert into tgc_order_detail(mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,tax_flg,tax_code,item_code,item_name,list_amount,qty)
                       values(p_order_no,v_dtl_pk_no,null,null,'LIST_PRICE','O','P','SALE',0,'Y',v_tax_code,v_remote_model,v_item_name,0,v_remote_qty);
                      end if;
                   end;
                    else
                  delete  tgc_order_detail where mas_pk_no = p_order_no
                         and item_code =v_remote_model;


               end if; */

/*                if nvl(v_others_qty,0) > 0 then

                   select seq_sys_no.nextval into v_dtl_pk_no from dual;

                   insert into tgc_order_detail(mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,tax_flg,tax_code,item_code,item_name,list_amount)
                   values(p_order_no,v_dtl_pk_no,null,null,'LIST_PRICE','O','P','SALE',0,'Y',v_tax_code,null,v_others_list,0);

               end if; */


         end;

         commit;
         return null;
          Exception
      When App_Exception Then
        Rollback;
        Raise_Application_Error(-20002, Exception_Msg);
        Return(Exception_Msg);
      When Others Then
        Rollback;
        Raise_Application_Error(-20002, Sqlerrm);
        Return(Sqlerrm);
      end;

      Function create_order_invo(p_user_no Number,p_order_no Number) Return Varchar2
      is
        v_process_sts varchar2(32);
        Exception_Msg varchar2(1024);
        App_Exception exception;
        v_invo_pk_no number(16);
        v_invo_no varchar2(32);
        v_cust_id varchar2(32);
        v_package_key number(16);
        v_product_id varchar2(32);
        v_vou_type varchar2(32);
        v_tax_code varchar2(32);
        v_tax_flg varchar2(32);
        v_order_id varchar2(32);
        v_pay_type varchar2(32);
        v_amount number(16);
        v_bill_address varchar2(1024);
        v_bill_zip varchar2(32);


        no_amount_exp exception;

      begin
         select a.process_sts,
                (select package_key from service_detail where srp_key=((select max(nvl(srp_key,0)) from tgc_order_item where mas_pk_no=order_no))),
                cust_id,
                product_id,
                a.voucher_type,
                order_id,
                a.first_billing_pay_type,
                billing_address,
                billing_zip
           into v_process_sts,
                v_package_key,
                v_cust_id,
                v_product_id,
                v_vou_type,
                v_order_id,
                v_pay_type,
                v_bill_address,
                v_bill_zip
           from tgc_order a
          where order_no in p_order_no;

/*

         if v_Process_Sts <> 'D' then
           exception_msg := '單據狀態錯誤';
           raise app_exception;
         end if;
         */
         begin
           select mas_no,pk_no
             into v_invo_no,v_invo_pk_no
            from service_invo_mas
           where src_pk_no = p_order_no
           and src_code='TGCORDER'
           and status_flg in ('A','P','N');
         exception
           when no_data_found then null;
         end;

         If v_vou_type='3' Then
           v_tax_code := 'OUTTAX2';
         Elsif  v_vou_type='2' Then
           v_tax_code := 'OUTTAX1';
         Elsif v_vou_type='1' Then
           v_tax_code := 'OUTTAX0';
         else
           exception_msg := '#請輸入發票種類#';
           raise app_exception;
         End If;
         v_tax_code := nvl(v_tax_code,'OUTTAX1');

         select sum(amount) into v_amount from tgc_order_detail
         where mas_pk_no = p_order_no;

         if v_amount is null then
            raise no_amount_exp;
         end if;

         declare

           v_invo_no varchar2(32);
           v_acc_code varchar2(32);
           v_acc_user_no number(16);
           v_acc_terms varchar2(32);
           v_due_date date;
           v_f_year  number(16);
           v_f_period number(16);
           v_address varchar2(1024);
           v_zip     varchar2(32);
           v_srp_key number(16);

         begin
           select max(srp_key) into v_srp_key from service_detail where package_key = v_package_key;

           select seq_inv_no.nextval into v_invo_pk_no from dual;
           v_invo_no := sysapp_util.Get_Mas_No(1,1,sysdate,'SRVINVO',v_invo_pk_no);
           v_acc_code := v_cust_id;
           select user_no,acc_terms
            into v_acc_user_no,v_acc_terms
            from tgc_customer where cust_id= v_acc_code;

           v_due_date := sysdate+ to_number(nvl(v_acc_terms,'14'));
           v_f_year := to_number(to_char(sysdate,'YYYY'));
           v_f_period := to_number(to_char(sysdate,'MM'));
           v_address := nvl(v_bill_address,tgc_util.get_cust_address(v_acc_user_no,'A'));
           v_zip     := nvl(v_bill_zip,tgc_util.get_cust_address(v_acc_user_no,'A'));

         insert into service_invo_mas
           (src_pk_no,
            src_no,
            src_code,
            order_no,
            order_id,
            package_key,
            pk_no,
            mas_date,
            mas_code,
            mas_no,
            acc_code,
            acc_user_no,
            address,
            zip,
            tax_flg,
            tax_code,
            status_flg,
            due_date,
            f_year,
            f_period,
            product_id,
            create_user,
            net_amount,
            amount,
            pay_type)
         values
           (p_order_no,
            v_order_id,
            'TGCORDER',
            p_order_no,
            v_order_id,
            v_package_key,
            v_invo_pk_no,
            sysdate,
            'SRVINV',
            v_invo_no,
            v_acc_code,
            v_acc_user_no,
            v_address,
            v_zip,
            v_tax_flg,
            v_tax_code,
            'A',
            v_due_date,
            v_f_year,
            v_f_period,
            v_product_id,
            p_user_no,
            0,
            0,
            v_pay_type);
        end;

        declare
          cursor c1 is select mas_pk_no,
                              pk_no,
                              chg_pk_no,
                              item_pk_no,
                              chg_code,
                              chg_type,
                              bill_type,
                              pm_code,
                              amount,
                              start_date,
                              end_date,
                              grp_no,
                              tax_flg,
                              tax_code,
                              item_code,
                              item_name,
                              acc_code,
                              list_amount,
                              qty
                           from tgc_order_detail a
                           where mas_pk_no= p_order_no;
          v_item_pk_no number(16);
          v_sum_amt number(16);
          v_chg_type varchar2(32);
        begin
          v_sum_amt := 0;
          for c1rec in c1 loop
          
            select seq_sys_no.nextval into v_item_pk_no from dual;
            select chg_type into v_chg_type 
            from service_charge_mas where chg_code=c1rec.chg_code;
            insert into service_invo_dtl(mas_pk_no,
                                         pk_no,
                                         chg_pk_no,
                                         item_pk_no,
                                         chg_code,
                                         chg_type,
                                         bill_type,
                                         pm_code,
                                         amount,
                                         start_date,
                                         end_date,
                                         grp_no,
                                         tax_flg,
                                         tax_code,
                                         item_code,
                                         item_name)
                                 values (v_invo_pk_no,
                                         v_item_pk_no ,
                                         null,
                                         null,
                                         c1rec.chg_code,
                                         v_chg_type,
                                         c1rec.bill_type,
                                         c1rec.pm_code,
                                         c1rec.amount,
                                         c1rec.start_date,
                                         c1rec.end_date,
                                         c1rec.grp_no,
                                         c1rec.tax_flg,
                                         c1rec.tax_code,
                                         c1rec.item_code,
                                         c1rec.item_name);
              v_sum_amt := v_sum_amt+c1rec.amount;
          end loop;

          update service_invo_mas
            set net_amount = v_sum_amt,
                amount = v_sum_amt
           where pk_no= v_invo_pk_no;

         update tgc_order a
           set a.inv_pk_no=v_invo_pk_no
         where order_no= p_order_no;


        end;
        declare
          v_msg varchar2(256);
          v_book_no varchar2(32);
        begin
          select min(mas_no) into v_book_no
            from tax_bk_mas a
            where a.status_flg='P';
          v_msg := tgc_bill_post.tgc_invo_post(p_user_no,v_invo_pk_no,'Y');
        --  v_msg := tax_post.crt_inv_tax(p_user_no,v_invo_pk_no,v_book_no,NULL,'Y');
        end;
      --   commit;
         return null;
          Exception
      When no_amount_exp then return null;
      When App_Exception Then
        Rollback;
        Raise_Application_Error(-20002, Exception_Msg);
        Return(Exception_Msg);
      When Others Then
        Rollback;
        Raise_Application_Error(-20002, Sqlerrm);
        Return(Sqlerrm);
      end;




End;
/

