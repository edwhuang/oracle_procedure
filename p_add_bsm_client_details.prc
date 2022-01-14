CREATE OR REPLACE PROCEDURE IPTV.P_ADD_BSM_CLIENT_DETAILS (p_package_id IPTV.BSM_PACKAGE_MAS.PACKAGE_ID%TYPE) IS
/* 配合整套看贈送，對活動期間內有贈送方案的用戶免費贈送相同期限的整套看方案。 */

  v_package_cat1 IPTV.BSM_PACKAGE_MAS.PACKAGE_CAT1%TYPE;
  -- v_package_name IPTV.BSM_PACKAGE_MAS.PACKAGE_NAME%TYPE;
  
  
BEGIN

   
   SELECT P.PACKAGE_CAT1
   INTO v_package_cat1
   FROM IPTV.BSM_PACKAGE_MAS P
   WHERE P.PACKAGE_ID = p_package_id;


DECLARE
 CURSOR c1 IS

SELECT 
    -- PK_NO
    A.SERIAL_NO 
    , A.SERIAL_ID 
    , A.MAC_ADDRESS 
    --, '整套看頻道餐'--PACKAGE_CAT1 
    --,  null PACKAGE_CAT2, --PACKAGE_CAT2 
    --,  null -PACKAGE_CAT3, --PACKAGE_CAT3
    --, 'SCHG006' --PACKAGE_ID
    , A.PACKAGE_NAME --PACKAGE_NAME
    --, sysdate --START_DATE
    , A.END_DATE
    --, null --ACL_DURATION 
    --, null --ACL_QUOTA
    --, null --ACL_LEVEL
    , A.STATUS_FLG --STATUS_FLG 
    --, null --SUPPLY_NAME
    , A.SRC_PK_NO
    , A.SRC_NO
    --, null --ITEM_ID
    --, null --SRC_ITEM_PK_NO
    --, 'P' --REPORT_TYPE, 
    --, null --DEVICE_ID
    --, null --APT_PRODUCTCODE
    --, null --APT_MIN
    --, null --APT_GATEWAY
    --, null --ACL_ID
    FROM IPTV.BSM_CLIENT_DETAILS A
    LEFT JOIN 
    (SELECT T.SERIAL_ID, T.SRC_PK_NO
    FROM IPTV.BSM_CLIENT_DETAILS T
    WHERE T.PACKAGE_ID = p_package_id
    AND T.STATUS_FLG = 'P') D -- package for free 400CH
    ON A.SERIAL_ID = D.SERIAL_ID
    AND A.SRC_PK_NO = D.SRC_PK_NO
    WHERE A.PACKAGE_ID IN (
    'CHG001'
    ,'CHG002' 
    ,'CHG005'
    ,'CHG006'
    ,'CHG008'
    ,'CHG009'
    ,'CHG013'
    ,'WDG002'
    ,'WDG003'
    ,'WDG004'
    ,'WDG005'
    ,'WDG006'
    ,'WDG010'
    ,'WDG012'
    )
    AND A.START_DATE <= TRUNC(SYSDATE)
    AND A.END_DATE >= TRUNC(SYSDATE)
    AND A.STATUS_FLG = 'P'
    AND D.SRC_PK_NO IS NULL
    AND A.SERIAL_ID <> '0000000000000422' -- test account
;

BEGIN
    FOR i IN c1 LOOP
           
    INSERT INTO IPTV.BSM_CLIENT_DETAILS A (
    PK_NO, SERIAL_NO, SERIAL_ID, 
    MAC_ADDRESS, PACKAGE_CAT1, PACKAGE_CAT2, 
    PACKAGE_CAT3, PACKAGE_ID, PACKAGE_NAME, 
    START_DATE, END_DATE, ACL_DURATION, 
    ACL_QUOTA, ACL_LEVEL, STATUS_FLG, 
    SUPPLY_NAME, SRC_PK_NO, SRC_NO, 
    ITEM_ID, SRC_ITEM_PK_NO, REPORT_TYPE, 
    DEVICE_ID, APT_PRODUCTCODE, APT_MIN, 
    APT_GATEWAY, ACL_ID)
    VALUES (
    Seq_Bsm_Purchase_Pk_No.Nextval 
    ,i.SERIAL_NO 
    ,i.SERIAL_ID 
    ,i.MAC_ADDRESS 
    ,v_package_cat1 
    ,null 
    ,null 
    ,p_package_id 
    ,null
    ,sysdate 
    ,i.END_DATE 
    ,null 
    ,null 
    ,null 
    ,i.STATUS_FLG 
    ,null 
    ,i.SRC_PK_NO 
    ,i.SRC_NO
    ,null 
    ,null 
    ,'P' 
    ,null
    ,null
    ,null 
    ,null 
    ,p_package_id);
    
    IPTV.BSM_CLIENT_SERVICE.SET_SUBSCRIPTION(null,i.MAC_ADDRESS);
    COMMIT;    
    END LOOP;
END;
    
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END P_ADD_BSM_CLIENT_DETAILS;
/

