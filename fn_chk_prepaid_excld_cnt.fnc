CREATE OR REPLACE FUNCTION IPTV.FN_CHK_PREPAID_EXCLD_CNT (P_SERIAL_ID VARCHAR2, P_CHECKED_DAYS NUMBER) RETURN NUMBER IS
v_return INTEGER;
/******************************************************************************
   NAME:       FN_CHK_PREPAID_EXCLD_CNT
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2020/4/3   Administrator       1. Created this function.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     FN_CHK_PREPAID_EXCL_CNT
      Sysdate:         2018/10/3
      Date and Time:   2018/10/3, 上午 11:55:39, and 2018/10/3 上午 11:55:39
      Username:        Administrator (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   v_return := null;
   
SELECT COUNT(*) INTO v_return -- A.SERIAL_ID, A.SRC_NO, A.PAY_TYPE, T.PROGRAM_ID, T.PAY_SUPPLY_ID
FROM IPTV.BSM_PURCHASE_MAS  A,
IPTV.BSM_CLIENT_DETAILS D,
(SELECT C.MAS_NO, C.PROGRAM_ID, P.PAY_SUPPLY_ID
                FROM IPTV.BSM_COUPON_MAS C, 
                IPTV.BSM_COUPON_PROG_MAS P,
                IPTV.PREPAID_EXCL_CUP_PAY_SUPPLY_ID S
               WHERE C.PROGRAM_ID = P.CUP_PROGRAM_ID
               AND P.PAY_SUPPLY_ID = S.PAY_SUPPLY_ID) T
WHERE A.PK_NO = D.SRC_PK_NO 
AND A.SRC_NO = T.MAS_NO(+)
AND ((A.PAY_TYPE IN (SELECT PAY_TYPE FROM IPTV.PREPAID_EXCL_PAY_TYPE)) -- 站內購買
      OR (A.PAY_TYPE = '兌換券' AND T.PAY_SUPPLY_ID IS NOT NULL))             -- 特定coupon清單
AND TRUNC(D.END_DATE) >= TRUNC(SYSDATE) - P_CHECKED_DAYS  -- 向前檢查日數
AND A.SERIAL_ID = P_SERIAL_ID;
   RETURN v_return;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       return -1;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END FN_CHK_PREPAID_EXCLD_CNT;
/

