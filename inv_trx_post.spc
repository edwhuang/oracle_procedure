CREATE OR REPLACE PACKAGE IPTV."INV_TRX_POST" is

  -- Author  : VIVIAN.TAO
  -- Created : 2008/10/21 上午 10:57:59
  -- Purpose :

  -- Public type declarations
  --type <TypeName> is <Datatype>;

  -- Public constant declarations
  --<ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  --<VariableName> <Datatype>;

  --Process Func
  function detail_a_cancel(i_trx_mas_no number) return varchar2;
  function trx_post_complete(i_trx_mas_no number) return varchar2;
  function trx_post(i_trx_type varchar2, i_trx_mas_no number) return varchar2;
  function back_to_active(i_trx_mas_no number) return varchar2;
  function trx_mas_generate(i_order_id varchar2,i_user number,i_mas_no number,i_mas_no2 number default 0,i_proc_no number default 0) return varchar2;
  function acc_generate(i_trx_mas_no number) return varchar2;
  function trx_s_generate(i_trx_type varchar2, i_trx_mas_no number,i_proc_no number default 0) return varchar2;
  function trx_n_generate(i_order_id varchar2, i_trx_mas_no number) return varchar2;
  function trx_io_generate(i_trx_mas_no number) return varchar2;
  function closed_yymm(i_yyyy number, i_mm number) return varchar2;
  function open_yymm(i_yyyy number, i_mm number) return varchar2;
  function return_generate(i_return_no number) return varchar2;
  function trx_r_generate(i_return_no number) return varchar2;
  function return_post(i_trx_mas_no number) return varchar2;
  function return_cancel(i_trx_mas_no number) return varchar2;
  function tsn_trans(i_batch_no number, i_trx_item_no number) return varchar2;
  function change_generate(i_return_no number) return varchar2;
  function change_post(i_trx_mas_no number) return varchar2;

  --Get Func
  function get_tax_rate(i_tax_code varchar2) return number;
  function get_tax_flg(i_tax_code varchar2) return varchar2;
  function get_stk_name(i_stock_id varchar2) return varchar2;
  function get_stk_unit(i_stock_id varchar2) return varchar2;
  function get_stk_id_by_name(i_stock_name varchar2) return varchar2;
  function get_stk_cost(i_stock_id varchar2) return number;
  function get_tcd_cost(i_tsn varchar2) return number;
  function get_acc_name(i_acc_code varchar2) return varchar2;
  function get_parent_acc(i_acc_code varchar2) return varchar2;
  function get_tcd_whs(i_tsn varchar2) return varchar2;
  function get_tcd_stkid(i_tsn varchar2) return varchar2;
  function get_tcd_io(i_tsn varchar2) return varchar2;
  function get_inv_status(i_yyyy number, i_mm number, i_whs varchar2) return varchar2;
  function get_avail_qty(i_year number, i_mm number, i_whs varchar2, i_stock varchar2) return number;
  function get_cust_name(i_cust_id varchar2) return varchar2;
  function chk_mfginfo_tsn(i_tsn varchar2) return boolean;
  function chk_f_period(i_year number, i_period number) return boolean;
  function get_user_no(i_user varchar2) return number;
  function get_asset_by_stk(i_stock_id varchar2) return varchar2;
  function get_stk_category(i_stock_id varchar2) return varchar2;
  function get_src_order_id(i_order_no number) return varchar2;
  function get_asset_id(i_tsn varchar2) return varchar2;
  function get_tcd_cust(i_tsn varchar2) return varchar2;
  function get_mas_no_by_id(i_pl_id varchar2) return number;
  function get_user_name(i_user_no number) return varchar2;
  function get_syscode_desc(i_syscode varchar2, i_code varchar2) return varchar2;
  function get_dispatch_by_ord(i_order_id varchar2) return varchar2;
  function crt_service_setting(p_user_no number,p_setting_flg varchar2,p_cust_id varchar2,p_tsn varchar2,i_trx_mas_no number) return varchar2;
  --function chk_shipout(i_order_id varchar2) return varchar2;

end INV_TRX_POST;
/

