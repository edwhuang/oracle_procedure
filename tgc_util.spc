CREATE OR REPLACE PACKAGE IPTV."TGC_UTIL" Is

  global_user_no Number(16);
  Procedure set_global_user_no(p_user_no Number);
  Function get_process_name(p_process_sts Varchar2) Return Varchar2;
  Function get_csr_status_name(p_csr_status Varchar2) Return Varchar2;
  Function get_cust_name(p_cust_id Varchar2) Return Varchar2;
  Function get_acc_name(p_acc_code Varchar2) Return Varchar2;
  Function get_cust_email(p_cust_id Varchar2) Return Varchar2;
  Function get_program_name(p_id Varchar2) Return Varchar2;
   Function get_program_name_no(p_no Number) Return Varchar2;
  Function get_product_name(p_product_id Varchar2) Return Varchar2;
   Function get_order_type_name(p_id Varchar2) Return Varchar2;
   Function get_order_cmp_status(p_pk_no Number) Return Varchar2;
   Function get_dispatch_type_name(p_id Varchar2) Return Varchar2;
   Function get_bb_name(p_id Varchar2) Return Varchar2;
   Function get_mso_name(p_id Varchar2) Return Varchar2;
   Function get_user_name(p_no Number) Return Varchar2;
    Function get_user_name(p_id Varchar2) Return Varchar2;
   Function get_dispatch_status_name(p_id Varchar2) Return Varchar2;
    Function trimstr(p_str Varchar2) Return Varchar2;
    Function get_first_dispatch_info(p_pk_no Number) Return Number;
    Function get_installer_name(p_pk_no Number) Return Varchar2;
    Function get_tgc_sale(p_pk_no Number) Return Varchar2;
    Function get_order_close_date(p_pk_no Number) Return Date;
    Function get_new_order_date(p_pk_no Number) Return Date;
    Function get_new_order_status(p_pk_no Number) Return Varchar2;
    Function get_bid_type_name(p_bid_type Varchar2) Return Varchar2;
    Function get_bill_pay_type_name(p_pay_type Varchar2) Return Varchar2;
   Function get_cust_address(p_cust_no Number,p_address_type Varchar2) Return Varchar2;Function get_invo_chg_amt(p_no Number,p_pk_no Number) Return Number;
   Function get_chg_name(p_chg_code Varchar2) Return Varchar2;
   Function get_pm_name(p_pm_code Varchar2) Return Varchar2;
   Function get_item_name(p_item_id Varchar2) Return Varchar2;
   Function get_con_from_pk(p_package_key Number) Return Varchar2;
   Function get_cust_zip(p_cust_no Number,p_address_type Varchar2) Return Varchar2;

   Function get_pay_mode(p_pay_mode Varchar) Return Varchar2;
   Function get_trx_type_name(p_trx_type Varchar) Return Varchar2;
   Function get_taxdate_from_invitem(p_invo_no number,p_stock_id varchar default null) return date;
   Function get_taxtitle_from_invitem(p_invo_no number,p_stock_id varchar default null) return varchar2;
   Function get_taxbid_from_invitem(p_invo_no number,p_stock_id varchar default null) return varchar2;
   Function get_virtual_acc(p_invo_no varchar2,p_amount number) return varchar2;
   Function chk_main_item(item_code varchar2,TSN varchar2) return varchar2;
   Function get_TSN_from_pk(p_package_key Number) Return Varchar2;

  
End;
/

