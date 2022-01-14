CREATE OR REPLACE PACKAGE IPTV."TGC_SET_POST" is
  Function tgc_set_post(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function tgc_set_post_no_commit(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function tgc_set_unpost(p_user_no Number,p_pk_no Number) Return Varchar2;
end TGC_SET_POST;
/

