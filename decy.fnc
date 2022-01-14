CREATE OR REPLACE FUNCTION IPTV."DECY" (p_input varchar2,l_key varchar2)  RETURN varchar2 IS
  l_input varchar2(1000);

  l_result varchar2(10000);
BEGIN
  l_input := p_input;
  dbms_obfuscation_toolkit.des3decrypt(input_string=>l_input,
   key_string=>l_key,
   decrypted_string=> l_result,
   which => 1);
  return l_result;

END;
/

