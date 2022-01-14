CREATE OR REPLACE PACKAGE IPTV."TGC_ORDER_POST2" Is
  Function crt_order_prod_tmp(p_order_no Number,p_item_no Number,p_user_no Number) Return Varchar2;
End;
/

