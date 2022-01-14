CREATE OR REPLACE PACKAGE IPTV."TGC_CREDIT_POST" is

  -- Author  : EDWARD
  -- Created : 2008/7/30 上午 11:39:39
  -- Purpose :

  -- Public type declarations

  -- Public constant declarations

  -- Public variable declarations

  -- Public function and procedure declarations
  function credit_transfer(p_user_no Number,p_pk_no Number,p_bill_no Varchar2 Default Null) return Varchar2;

  Function credit_post(p_user_no Number,p_pk_no Number) return Varchar2;

  Function credit_unpost(p_user_no Number,p_pk_no Number) return Varchar2;

  Function credit_cancel(p_user_no Number,p_pk_no Number) return Varchar2;

end TGC_CREDIT_POST;
/

