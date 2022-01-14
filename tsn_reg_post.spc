CREATE OR REPLACE PACKAGE IPTV."TSN_REG_POST" is
  Function reg_post(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function get_invo_no(p_user_no Number,p_pk_no Number,p_amount number default 0) Return Varchar2;
end  TSN_REG_POST;
/

