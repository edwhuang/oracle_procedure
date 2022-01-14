create or replace type iptv.purchase_msg_type as
object (
  client_id varchar2(64),
  pk_no number(16),
  purchase_no varchar2(64),
  process_type varchar2(32)
)
/

