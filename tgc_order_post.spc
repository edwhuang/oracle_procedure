CREATE OR REPLACE PACKAGE IPTV."TGC_ORDER_POST" Is

  Function Order_Post(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Order_New(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Order_Assigned_Csr(p_User_No Number, p_Pk_No Number)   Return Varchar2;
  Function order_generate(p_user_no Number,p_pk_no Number) Return Varchar2;
  Function Order_Unpost(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Order_Cancel(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Order_nullify(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function order_Complete(p_User_No Number, p_Pk_No Number,p_rev_flg Varchar2 Default Null,p_rev_date Date Default Null)   Return Varchar2;
  Function Order_Generate_new(p_User_No Number, p_Pk_No Number,p_order_type Varchar2 Default Null,p_program Varchar2 Default Null,p_product Varchar2 Default Null) Return Varchar2;

  Function Dispatch_Post(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Dispatch_Assigned_Installer(p_User_No Number, p_Pk_No Number)  Return Varchar2;
  Function Dispatch_Unpost(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Dispatch_Cancel(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Dispatch_nullify(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function Dispatch_Response(p_User_No Number, p_Pk_No Number)   Return Varchar2;
  Function Dispatch_Complete(p_User_No Number, p_Pk_No Number)   Return Varchar2;
  Function dispatch_installer_book(p_User_no Number,p_pk_no Number,p_inst_id Varchar2,p_book_time Date) Return Varchar2;
  Function Dispatch_sendMessageToOrder(p_User_no Number,p_pk_no Number,p_message Varchar2) Return Varchar2;
  Function Dispatch_auto_Complete(p_User_No Number, p_Pk_No Number)   Return Varchar2;

  Function Query_Post(p_User_No Number, p_Pk_No Number)   Return Varchar2;
  Function dispatch_print(p_User_No Number, p_Pk_No Number) Return Varchar2;
  
  Function create_service_detail(p_user_no Number,p_order_no Number) Return Varchar2;
  Function create_order_detail(p_user_no Number,p_order_no Number) Return Varchar2;
  Function create_order_invo(p_user_no Number,p_order_no Number) Return Varchar2;

End;
/

