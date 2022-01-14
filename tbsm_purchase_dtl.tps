CREATE OR REPLACE TYPE IPTV."TBSM_PURCHASE_DTL"                                          as object
(   PK_NO      NUMBER(16),
  ITEM_NO    NUMBER(16),
  PACKAGE_ID Varchar2(32),
  PACKAGE_NAME Varchar2(256),
  ITEM_ID Varchar2(32),
  ITEM_NAME Varchar2(256),
  OFFER_ID   VARCHAR2(32),
  ASSET_ID   VARCHAR2(32),
  AMOUNT     NUMBER(16),
  START_DATE DATE,
  duration Number(16),
  quota Number(16),
  Constructor Function tbsm_purchase_dtl
  Return Self As Result
  )
/

