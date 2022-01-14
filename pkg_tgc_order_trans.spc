CREATE OR REPLACE PACKAGE IPTV."PKG_TGC_ORDER_TRANS"
Is
    D_Date date;    Procedure Convert(p_batch_no Number);
    Procedure Convert2(p_batch_no Number);
    Procedure ConvertRtn(p_batch_no Number);


    Procedure transfer(p_order_type Varchar2,p_program_id Varchar2,p_product_id Varchar2,p_cat1 Varchar2,p_user_no Number,p_batch_no Number Default 0);
    Procedure Clear;
    Function trimstr(p_str Varchar2) Return Varchar2;
    Procedure transferrtn(D_Date Date,p_batch_no Number Default 0);
End;
/

