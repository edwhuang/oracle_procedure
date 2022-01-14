CREATE OR REPLACE FUNCTION IPTV.FN_CHK_FUTURE_PAID_PUR_CNT (P_SERIAL_ID VARCHAR2, P_PUR_NO VARCHAR2, P_CHECKED_DATE DATE) RETURN NUMBER IS
v_return INTEGER;
/******************************************************************************
   NAME:       FN_CHK_FUTURE_PAID_PUR_CNT
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2018/10/3   Administrator       1. Created this function.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     FN_CHK_FUTURE_PAID_PUR_CNT
      Sysdate:         2018/10/3
      Date and Time:   2018/10/3, 上午 11:55:39, and 2018/10/3 上午 11:55:39
      Username:        Administrator (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   v_return := null;
   
   select count(*) into v_return
   from
   (select distinct A.PK_NO
   from IPTV.BSM_PURCHASE_MAS a,
   IPTV.BSM_CLIENT_DETAILS b
   where A.PK_NO = B.SRC_PK_NO
   and A.SERIAL_ID = P_SERIAL_ID   
   and B.END_DATE >= trunc(P_CHECKED_DATE)  
   and A.PAY_TYPE not in ('贈送','兌換券')
   and A.MAS_NO <> P_PUR_NO
   and A.STATUS_FLG = 'Z');
   
   RETURN v_return;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       return -1;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END FN_CHK_FUTURE_PAID_PUR_CNT;
/

