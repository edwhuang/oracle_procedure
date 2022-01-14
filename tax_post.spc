CREATE OR REPLACE PACKAGE IPTV.TAX_POST is

  -- Author  : EDWARD
  -- Created : 2009/2/27 16:19:51
  -- Purpose :

  -- Public type declarations
  --  type <TypeName> is <Datatype>;

  -- Public constant declarations
  --  <ConstantName> constant <Datatype> := <Value>;

  -- Public variable declarations
  -- <VariableName> <Datatype>;
  set_invo_date date;
  v_chk_pk_no   number(16);

  procedure set_inv_date(p_date date);
  procedure set_chk_pk_no(p_chk_pk_no number);
  -- Public function and procedure declarations
  function get_inv_chk_code(p_inv_no Varchar) return Varchar2;
  Function get_inv_no(p_org_no    number,
                      p_loc_no    number,
                      p_tax_bk_no Varchar) Return Varchar2;
  Function tax_inv_post(p_User_No   Number,
                        p_Pk_No     Number,
                        p_no_commit varchar2 default 'N') Return Varchar2;
  Function crt_inv_tax(p_user      number,
                       p_inv_pk_no number,
                       p_book_no   varchar2,
                       p_amt       number default null,
                       p_no_commit varchar2 default 'N',
                       src_code    varchar2 default null,
                       src_no      varchar2 default null,
                       src_pk_no   number default null,
                       p_org_no    number default 1) return varchar2;
  Function tax_inv_unpost(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function tax_inv_cancel(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function crt_inv_tax_f(p_proc_no Number) Return Varchar2;

end TAX_POST;
/

