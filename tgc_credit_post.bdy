CREATE OR REPLACE PACKAGE BODY IPTV."TGC_CREDIT_POST" is


   function credit_transfer(p_user_no Number,p_pk_no Number,p_bill_no Varchar2 Default Null) return Varchar2
   Is
     v_result Varchar2(1024);
     app_exception Exception;
     Exception_msg Varchar2(256);
     v_status_flg Varchar2(32);

  Begin
    Select status_flg Into v_status_flg From tgc_credit_authoriz_mas
       Where pk_no = p_pk_no;
    If v_status_flg <> 'A' Then
      Exception_msg := '#單據不為打單中#';
      Raise app_exception;
    End If;

     -- clear tgc_credit_authoriz_dtl

     Delete tgc_credit_authoriz_dtl Where mas_pk_no = p_pk_no;

   /*   Insert Into tgc_credit_authoriz_dtl
        (mas_pk_no, cust_id, credit_no, expiration_date, cvc2, amount, ref2)
        Select p_pk_no,
               a.cust_id,
               a.credit_no,
               a.expiration_date,
               a.cvc2,
               to_number(sum(b.open_amount)),
               max(b.src_no)
          From tgc_credit_mas a, service_acc_detail b
         Where status_flg = 'P'
           And b.open_flg = 'Y'
           And b.acc_code = a.cust_id
           and b.package_key is not null
           and b.acc_type = 'C'
           And b.dr Is Null
           and a.srp_key is null
           and b.due_date - 5 < sysdate
         Group By a.cust_id, a.credit_no, a.expiration_date, a.cvc2
        union all
        Select p_pk_no,
               a.cust_id,
               a.credit_no,
               a.expiration_date,
               a.cvc2,
               to_number(sum(b.open_amount)),
               max(b.src_no)
          From tgc_credit_mas a, service_acc_detail b
         Where status_flg = 'P'
           And b.open_flg = 'Y'
           And b.acc_code = a.cust_id
           and b.package_key is not null
           and b.acc_type = 'C'
           And b.dr Is Null
           and a.srp_key is not null
           and a.srp_key = b.srp_key
           and b.due_date - 5 < sysdate
         Group By a.cust_id, a.credit_no, a.expiration_date, a.cvc2;
*/
    Commit;
    Return v_result;
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

  Function credit_post(p_user_no Number,p_pk_no Number) return Varchar2
  Is
     v_result Varchar2(1024);
    v_status_flg Varchar2(32);
         Exception_msg Varchar2(256);
     app_exception Exception;
    Begin
    Select status_flg Into v_status_flg From tgc_credit_authoriz_mas
       Where pk_no = p_pk_no;
    If v_status_flg <> 'A' Then
      Exception_msg := '#單據不為打單中#';
      Raise app_exception;
    End If;

    Commit;
    Return v_result;
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

      Function credit_unpost(p_user_no Number,p_pk_no Number) return Varchar2
  Is
     v_result Varchar2(1024);
    v_status_flg Varchar2(32);
         Exception_msg Varchar2(256);
         app_exception Exception;
    Begin
    Select status_flg Into v_status_flg From tgc_credit_authoriz_mas
       Where pk_no = p_pk_no;
    If v_status_flg <> 'A' Then
      Exception_msg := '#單據不為打單中#';
      Raise app_exception;
    End If;

    Commit;
    Return v_result;
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


      Function credit_cancel(p_user_no Number,p_pk_no Number) return Varchar2
  Is
     v_result Varchar2(1024);
    v_status_flg Varchar2(32);
         Exception_msg Varchar2(256);
          app_exception Exception;
    Begin
    Select status_flg Into v_status_flg From tgc_credit_authoriz_mas
       Where pk_no = p_pk_no;
    If v_status_flg <> 'A' Then
      Exception_msg := '#單據不為打單中#';
      Raise app_exception;
    End If;

    Commit;
    Return v_result;
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


end TGC_CREDIT_POST;
/

