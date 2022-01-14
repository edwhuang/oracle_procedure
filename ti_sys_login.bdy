CREATE OR REPLACE PACKAGE BODY IPTV."TI_SYS_LOGIN" Is

  gk1  varchar2 (1000) := 'www.tgc-taiwan.com.tw 27740083';

Function Decrypted_Pwd(Input_String Varchar2) Return Varchar2 Is

Raw_Input Raw(128) := Utl_Raw.Cast_To_Raw(Input_String); Decrypted_Raw Raw(2048); Error_In_Input_Buffer_Length
Exception
;

Begin
Sys.Dbms_Obfuscation_Toolkit.Md5(Input => Raw_Input, Checksum => Decrypted_Raw); Return Decrypted_Raw;
End;



  function encrypt (p_input varchar2,p_key varchar2 default null) return varchar2 is
    l_input   varchar2 (1000);
    l_key     varchar2 (100) := gk1;
    l_result  varchar2 (1000);
  begin
    if p_key is not null then
       l_key := p_key;
    end if;
     
    if p_input is null then
       return null;
    else
       -- pad to multiple of 8 chars;
       l_input := rpad (p_input, (trunc(length(p_input)/8)+1)*8, ' ');
       dbms_obfuscation_toolkit.des3encrypt (
            input_string      => l_input,
            key_string        => l_key,
            encrypted_string  => l_result,
            which             => 1);
       return l_result;
     end if;
   Exception
     When Others Then return(Null);
   end encrypt;

   function decrypt (p_input varchar2) return varchar2 is
     l_input   varchar2 (1000);
     l_key     varchar2 (100) := gk1;
     l_result  varchar2 (1000);
   begin
     if p_input is null Or p_input = '0' then
        return null;
     Else

        l_input := p_input;
        dbms_obfuscation_toolkit.des3decrypt (
            input_string      => l_input,
            key_string        => l_key,
            decrypted_string  => l_result,
            which             => 1);
            return l_result;
     end if;
   Exception
     When Others Then return Null;
   end decrypt ;

  Function check_password(p_user_name Varchar,p_password Varchar) Return Varchar2  Is
   v_char Varchar2(1);
  Begin
    Select 'x' Into v_char From sys_user a
    Where user_name=p_user_name
    And a.user_password=Decrypted_Pwd(p_password);
    Return 'Y';
  Exception
   When no_data_found Then Return 'N';
  End;

End;
/

