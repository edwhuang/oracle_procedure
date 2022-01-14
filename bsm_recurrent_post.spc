CREATE OR REPLACE PACKAGE IPTV."BSM_RECURRENT_POST" is
  procedure daliy_job;
  function transfer(user_no number, p_pk_no number) return varchar2;
  function post(user_no number, p_pk_no number) return varchar2;
End BSM_RECURRENT_POST;
/

