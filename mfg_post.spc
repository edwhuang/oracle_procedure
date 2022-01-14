CREATE OR REPLACE PACKAGE IPTV."MFG_POST" is
  function MFG_SGSET_POST(p_user_no   Number,p_pk_no     Number, p_no_commit varchar2 default 'N')  return varchar2;
  function MFG_SGSET_UNPOST(p_user_no   Number,p_pk_no     Number, p_no_commit varchar2 default 'N')  return varchar2;
  function MFG_SGSET_Complete(p_user_no   Number,p_pk_no     Number, p_no_commit varchar2 default 'N')  return varchar2;
end MFG_POST;
/

