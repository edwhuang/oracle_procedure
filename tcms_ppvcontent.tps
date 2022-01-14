CREATE OR REPLACE TYPE IPTV."TCMS_PPVCONTENT"                                          As Object
( seq_no  Number(16),
  content_id Varchar2(32),
  title Varchar2(32),
  Description Varchar2(1024),
  ref1 Varchar2(256),
  ref2 Varchar2(256),
  ref3 Varchar2(256),
  ref4 Varchar2(256),
  ref5 Varchar2(256),
  ref6 Varchar2(256),
  ref7 Varchar2(256),
  ref8 Varchar2(256),
    CONSTRUCTOR FUNCTION  TCMS_PPVContent
    RETURN SELF AS RESULT
  )
/

