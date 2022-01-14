CREATE OR REPLACE PACKAGE IPTV."TGC_BILL_POST_T" is
  C_date date;
  Function tgc_invo_post(p_user_no Number,p_pk_no Number,p_no_commit varchar2 default 'N') Return Varchar2;
  Function tgc_invo_unpost(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function tgc_invo_cancel(p_user_no Number,p_pk_no Number) Return Varchar2;
  function chk_service_flg(p_package_key number) return varchar2;
  function tgc_bill_transfer(p_user_no Number,p_pk_no Number,p_bill_flg Varchar2 Default Null) return Varchar2;
  function tgc_bill_post(p_user_no Number,p_pk_no Number) return Varchar2;
  function tgc_bill_generate(p_user_no Number,p_pk_no Number) return Varchar2;
  Function tgc_chk_check(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function tgc_chk_post(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function tgc_chk_unpost(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function crt_chk_clr_tmp(p_user_no Number,p_process_seq_no Number,p_mas_pk_no Number,p_item_pk_no Number) Return Varchar2;
  Function clr_chk_clr_tmp(p_process_seq_no Number) Return Varchar2;
  Function set_chk_clr_tmp(p_process_seq_no Number) Return Varchar2;
  Function tgc_startbill_post(p_user_no Number,p_pk_no Number,p_no_commit varchar2 default 'N') Return Varchar2;
  Function tgc_startbill_unpost(p_user_no Number,p_pk_no Number,p_no_commit varchar2 default 'N') Return Varchar2;
  Function tgc_startbill_cancel(p_user_no Number,p_pk_no Number,p_no_commit varchar2 default 'N') Return Varchar2;
  Function tgc_billchg_post(p_user_no Number,p_pk_no Number,p_no_commit varchar2 default 'N') Return Varchar2; 
  Function Tgc_billchg_trans(p_user_no Number,p_pk_no Number,p_proc_no number) return varchar2;
end TGC_BILL_POST_T;
/

