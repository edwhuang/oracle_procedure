CREATE OR REPLACE FUNCTION IPTV.FN_CHK_PKG_CAT_MAX_END_DATE (P_SERIAL_ID VARCHAR2, P_PKG_CAT VARCHAR2) RETURN DATE IS
v_return DATE;
/******************************************************************************
   NAME:       FN_CHK_PKG_CAT_MAX_END_DATE
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2020/4/27   Administrator       1. Created this function.

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
   
SELECT MAX(D.END_DATE) INTO v_return -- A.SERIAL_ID, A.SRC_NO, A.PAY_TYPE, T.PROGRAM_ID, T.PAY_SUPPLY_ID
FROM IPTV.BSM_PURCHASE_MAS  A,
IPTV.BSM_CLIENT_DETAILS D,
IPTV.BSM_PACKAGE_MAS P
WHERE A.PK_NO = D.SRC_PK_NO
AND D.PACKAGE_ID = P.PACKAGE_ID 
AND SUBSTR(P.PACKAGE_CAT1,1,2) = P_PKG_CAT  -- 特定類型方案
AND A.SERIAL_ID = P_SERIAL_ID;
   RETURN v_return;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       return TO_DATE('2011-01-01','YYYY-MM-DD');
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END FN_CHK_PKG_CAT_MAX_END_DATE;
/

