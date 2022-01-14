CREATE OR REPLACE TYPE IPTV."TBSM_CLIENT_INFO"                                          as Object
( Region number(16),
  Serial_NO number(16),
  Serial_ID varchar2(32),
  Status_Flg varchar2(32),
  MAC_Address varchar2(32),
  Owner_ID varchar2(32),
  Owner_Name varchar2(256),
  Owner_Email varchar2(256),
  Owner_Phone varchar2(32),
  Owner_Phone_Status varchar2(32),
  Activation_Code varchar2(32),
  Default_Group varchar2(32),
  CONSTRUCTOR FUNCTION TBSM_CLIENT_INFO
    RETURN SELF AS RESULT
  )
/

