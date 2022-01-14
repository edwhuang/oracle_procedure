create or replace type iptv.purchase_coupon_item_dtl
as object
(
       item_no number(16),
       item_pk_no number(16),
       mas_pk_no number(16),
       package_id varchar2(32),
       client_id varchar2(32),
       cup_package_id varchar2(32),
       coupon_id varchar2(32),
       amt       number(16),
       tax_amt   number(16),
       net_amt   number(16),
       descr varchar2(128)
)
/

