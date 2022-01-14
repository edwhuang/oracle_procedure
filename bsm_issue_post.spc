CREATE OR REPLACE PACKAGE IPTV.bsm_issue_post is
  Function bsm_issue_generate_bchang(p_User_No        Number,
                                     p_purchas_pk_no  number,
                                     p_next_bill_date date) Return number;
  Function bsm_issue_generate(p_User_No Number, p_purchas_pk_no number)
    Return number;
  Function bsm_issue_generate_from_dtls(p_User_No   Number,
                                        p_client_id varchar2) Return number;
  Function bsm_issue_transfer(p_user_no           number,
                              p_pk_no             number,
                              from_purchase_pk_no number) Return varchar2;

  Function bsm_issue_post(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function bsm_issue_unpost(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function bsm_issue_complete(p_User_No Number, p_Pk_No Number,ref_client varchar2 default 'Y')  Return Varchar2;
  Function bsm_issue_cancel(p_User_No Number, p_Pk_No Number) Return Varchar2;

End bsm_issue_post;
/

