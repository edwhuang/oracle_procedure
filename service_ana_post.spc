CREATE OR REPLACE PACKAGE IPTV."SERVICE_ANA_POST" is
  Function service_ana_post(p_user_no Number,p_pk_no Number,p_ana_code2 Varchar2 Default Null,p_ana_code3 Varchar2 Default Null) Return Varchar2;
end SERVICE_ANA_POST;
/

