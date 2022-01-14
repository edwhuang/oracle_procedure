create or replace procedure iptv.P_BSM_ACCOUNT_CLEAR(P_CLIENT_ID VARCHAR2) is
  -- 取消購買
  v_msg1      varchar2(256);
  v_msg2      varchar2(256);
  v_msg3      varchar2(256);
  v_msg4      varchar2(256);
  v_serial_no number := 0;
begin
  select distinct serial_no
    into v_serial_no
    from bsm_client_mas
   where serial_id = P_CLIENT_ID
     and rownum = 1;

  v_msg1 := BSM_Purchase_post.hide_all_purchase('2789389', P_CLIENT_ID);
  begin
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TGCCLIENT',
       v_serial_no,
       Sysdate,
       '2789389',
       'hide all purchases',
       Sys_Event_Seq.Nextval,
       'hide all purchases');
    commit;
  end;
  -- 取消服務
  v_msg2 := BSM_Client_Service.UnGift('2789389', P_CLIENT_ID);
  begin
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TGCCLIENT',
       v_serial_no,
       Sysdate,
       '2789389',
       'UnGift',
       Sys_Event_Seq.Nextval,
       'UnGift');
    commit;
  end;

  -- 取消啟用
  v_msg3 := BSM_Client_Service.UnActivate_client('2789389', P_CLIENT_ID);
  begin
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TGCCLIENT',
       v_serial_no,
       Sysdate,
       '2789389',
       'unactivate',
       Sys_Event_Seq.Nextval,
       'unactivate client');
    commit;
  end;
  -- 強制同步
  v_msg4 := cms_cnt_post.tgc_cms_cat_post('2789389');
  bsm_client_service.Set_subscription(null, P_CLIENT_ID);
  begin
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('TGCCLIENT',
       v_serial_no,
       Sysdate,
       '2789389',
       '同步',
       Sys_Event_Seq.Nextval,
       '同步');
    commit;
  end;

end;
/

