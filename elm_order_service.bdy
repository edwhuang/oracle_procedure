CREATE OR REPLACE PACKAGE BODY IPTV.ELM_ORDER_SERVICE is
  function elm_coupon_rollback(p_coupon_pk_no Number)
    return varchar2 is
    exception_msg Varchar2(256);
    app_exception Exception;
    
    v_coupon_mas_code     Varchar2(32);
    v_coupon_mas_no       Varchar2(32);
    v_status_flg          Varchar2(32);
    v_client_id           varchar(32);
    v_purchase_pk_no      number(16);
    v_purchase_mas_no     Varchar2(32);
    v_purchase_mas_code   Varchar2(32);    

  begin
    
    begin
    -- select coupon attributes

      Select mas_code,
             mas_no,
             status_flg,
             serial_id
      Into v_coupon_mas_code,
           v_coupon_mas_no,   
           v_status_flg,
           v_client_id
      From bsm_coupon_mas a
      Where pk_no = p_coupon_pk_no;
      
      exception
        when no_data_found then
          exception_msg := '#找不到coupon資料' || to_char(p_coupon_pk_no) || '#';
          raise app_exception;
    end;
    

    If v_status_flg <> 'Z' Then
      exception_msg := '#錯誤的單據狀態#';
      raise app_exception;
    End If;

    begin    
      select PK_NO, MAS_NO, MAS_CODE
        into 
        v_purchase_pk_no, 
        v_purchase_mas_no,
        v_purchase_mas_code
        from BSM_PURCHASE_MAS
        where STATUS_FLG = 'Z'
        and SRC_NO = v_coupon_mas_no
        -- FOR UPDATE
        ;
      
      exception
      when no_data_found then
        exception_msg := '#找不到訂單資料' || to_char(v_purchase_pk_no) || '#';
        raise app_exception;
    end;
    
    -- cancel service details
    --DBMS_OUTPUT.PUT_LINE('v_purchase_mas_no: '||v_purchase_mas_no);
    
    Update BSM_CLIENT_DETAILS set
    STATUS_FLG = 'N'
    where STATUS_FLG = 'P'
    and SRC_NO = v_purchase_mas_no;
    
    -- cancel coupon

    --DBMS_OUTPUT.PUT_LINE('p_coupon_pk_no: '||TO_CHAR(p_coupon_pk_no));  
    
    Update Bsm_coupon_mas set
    STATUS_FLG = 'B'
    where pk_no = p_coupon_pk_no; 

    -- update ACL    

     BSM_client_service.Set_subscription(null, v_client_id);
    
    -- recording log for coupon cancellation
    
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      (v_coupon_mas_code,
       p_coupon_pk_no,
       Sysdate,
       0,
       'Cancel',
       Sys_Event_Seq.Nextval,
       'Coupon rollback');
     
  commit;
  return null;
        
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);  
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  end;
  

  procedure sp_elm_coupon_check
    is
      cursor c1 is 
      select A.PK_NO, A.COUPON_SERIAL_NO
      , E.ELM_INV_CUP_SERIAL_NO, E.ELM_INV_STATUS, E.ELM_INV_ID -- ,E.ELM_INV_CHECKED_FLG, E.ELM_INV_UPDATETIME
      from IPTV.BSM_COUPON_MAS a
      left join IPTV.ELM_INVOICE E
      on A.COUPON_SERIAL_NO = E.ELM_INV_CUP_SERIAL_NO
      where A.PROGRAM_ID = 'ELFLI001'   -- 全國電子一年豪華組合加贈A2V優惠專案
      and A.STATUS_FLG = 'Z'        -- coupon已開通完成
      and trunc(A.REGISTER_DATE) <= trunc(sysdate - 3)        -- 檢查時間區間
      and (E.ELM_INV_CHECKED_FLG = 'N' or  E.ELM_INV_CHECKED_FLG is null)            -- 排除已檢查過的coupon
      order by A.COUPON_SERIAL_NO, E.ELM_INV_ID desc;
      --for update of A.STATUS_FLG, E.ELM_INV_CHECKED_FLG, E.ELM_INV_UPDATETIME;
      
      v_coupon_serial_no VARCHAR(32) := null;
      v_msg VARCHAR2(256);
    begin
    
      BEGIN   
  
      MERGE INTO IPTV.ELM_INVOICE d
      USING   (select 
          LTRIM(RTRIM(ELM_INV_STATUS)) ELM_INV_STATUS,
          ELM_INV_SALETIME,
          ELM_INV_STORE_NAME,
          LTRIM(RTRIM(ELM_INV_STORE_ID)) ELM_INV_STORE_ID,
          LTRIM(RTRIM(ELM_INV_ID)) ELM_INV_ID,
          LTRIM(RTRIM(ELM_INV_CUP_SERIAL_NO)) ELM_INV_CUP_SERIAL_NO,
          'N' ELM_INV_CHECKED_FLG,
          SYSDATE ELM_INV_UPDATETIME
          from IPTV.ELM_RECORD) s
      ON  (d.ELM_INV_ID = s.ELM_INV_ID)
      WHEN NOT MATCHED THEN
          INSERT (
           ELM_INV_STATUS, ELM_INV_SALETIME, ELM_INV_STORE_NAME, 
           ELM_INV_STORE_ID, ELM_INV_ID, ELM_INV_CUP_SERIAL_NO, 
           ELM_INV_CHECKED_FLG, ELM_INV_UPDATETIME)
          VALUES  (     
           s.ELM_INV_STATUS, s.ELM_INV_SALETIME, s.ELM_INV_STORE_NAME, 
           s.ELM_INV_STORE_ID, s.ELM_INV_ID, s.ELM_INV_CUP_SERIAL_NO, 
           s.ELM_INV_CHECKED_FLG, s.ELM_INV_UPDATETIME)
      WHEN MATCHED THEN
          UPDATE SET 
           ELM_INV_CUP_SERIAL_NO = ELM_INV_CUP_SERIAL_NO;
      COMMIT;
        
    END;   
    
   for i in c1 loop
   
     if (v_coupon_serial_no is null or i.COUPON_SERIAL_NO <> v_coupon_serial_no) and (i.ELM_INV_CUP_SERIAL_NO is null or i.ELM_INV_STATUS = 'delete') 
     then  -- coupon對應於全國電子最新一筆交易記錄中不存在或最後記錄為delete
  
      
          v_msg := IPTV.ELM_ORDER_SERVICE.ELM_COUPON_ROLLBACK ( i.PK_NO );    -- 關閉該筆coupon相關的服務
          DBMS_OUTPUT.PUT_LINE('IPTV.ELM_ORDER_SERVICE.ELM_COUPON_ROLLBACK ( '||TO_CHAR(i.PK_NO)||' )');
          DBMS_OUTPUT.PUT_LINE('v_msg = '||v_msg);
      
     end if; 
     
     -- 標記全國電子交易記錄已檢查過
        
     update IPTV.ELM_INVOICE set 
     ELM_INV_CHECKED_FLG = 'Y',
     ELM_INV_UPDATETIME = sysdate
     where ELM_INV_ID = i.ELM_INV_ID; 
     -- DBMS_OUTPUT.PUT_LINE('i.COUPON_SERIAL_NO = '||TO_CHAR(i.COUPON_SERIAL_NO)||' v_coupon_serial_no = '||TO_CHAR(v_coupon_serial_no)||' update IPTV.ELM_INVOICE where ELM_INV_CUP_SERIAL_NO = '||TO_CHAR(i.ELM_INV_CUP_SERIAL_NO)||' and ELM_INV_ID = '||TO_CHAR(i.ELM_INV_ID));   
  
     -- 記錄本次COUPON_SERIAL_NO以供下次比對
     v_coupon_serial_no := i.COUPON_SERIAL_NO;
   end loop;
   commit;
  
  end; 
end ELM_ORDER_SERVICE;
/

