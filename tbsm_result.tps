CREATE OR REPLACE TYPE IPTV."TBSM_RESULT"                                          as object
( Result_Code varchar2(32),
  Result_Message varchar2(1024),
  CONSTRUCTOR FUNCTION TBSM_Result
      RETURN SELF AS RESULT
  )
/

