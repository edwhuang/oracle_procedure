CREATE OR REPLACE FUNCTION IPTV.FN_CHK_OTHER_PAID_PUR_CNT (P_SERIAL_ID VARCHAR2, P_PUR_NO VARCHAR2, P_CHECKED_DATE DATE) RETURN NUMBER IS
v_return INTEGER;
/******************************************************************************
   NAME:       FN_CHK_OTHER_PUR_CNT
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2018/1/15   IPTV       1. Created this function.

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
   and B.START_DATE <= trunc(P_CHECKED_DATE)
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
END FN_CHK_OTHER_PAID_PUR_CNT;
/

