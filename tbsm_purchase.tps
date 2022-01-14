﻿CREATE OR REPLACE TYPE IPTV."TBSM_PURCHASE"                                          as Object
( PK_NO         NUMBER,
  MAS_NO        VARCHAR2(32),
  MAS_DATE      DATE,
  MAS_CODE      VARCHAR2(32),
  SRC_CODE      VARCHAR2(32),
  SRC_NO        VARCHAR2(32),
  SRC_DATE      VARCHAR2(32),
  SERIAL_NO     NUMBER(32),
  SERIAL_ID       Varchar2(32),
  STATUS_FLG    VARCHAR2(32),
  PURCHASE_DATE DATE,
  PAY_TYPE      VARCHAR2(32),
  CARD_NO       VARCHAR2(32),
  CARD_TYPE     VARCHAR2(32),
  CARD_EXPIRY   VARCHAR2(32),
  CVC2          VARCHAR2(32),
  Approval_Code Varchar2(32),
  details TBSM_PURCHASE_dtls,
  CONSTRUCTOR FUNCTION TBSM_PURCHASE
    RETURN SELF AS RESULT
  )
/
