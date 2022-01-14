CREATE OR REPLACE TYPE IPTV.clob_t AS OBJECT(MERCHANTNUMBER VARCHAR2(100),
                                        ORDERNUMBER VARCHAR2(100),
                                        STATUS varchar2(100),
                                        APPROVEAMOUNT VARCHAR2(100),
                                        PERIOD VARCHAR2(100),
                                        CURRENCY VARCHAR2(100),
                                        CARDNUMBER VARCHAR2(100),
                                        ORDERDATE VARCHAR2(100),
                                        APPROVEDATE VARCHAR2(100),
                                        APPROVALCODE VARCHAR2(100),
                                        DEPOSITAMOUNT VARCHAR2(100),
                                        DEPOSITDATE VARCHAR2(100),
                                        CREDITAMOUNT VARCHAR2(100),
                                        CREDITDATE VARCHAR2(100)
                                        );
/

