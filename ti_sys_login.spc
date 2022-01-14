CREATE OR REPLACE PACKAGE IPTV."TI_SYS_LOGIN" Is
  Function Decrypted_Pwd(Input_String Varchar2) Return Varchar2;
  function encrypt (p_input varchar2,p_key varchar2 default null) return varchar2;
 function decrypt (p_input varchar2) return Varchar2;
 Function check_password(p_user_name Varchar,p_password Varchar) Return Varchar2;
End;
/

