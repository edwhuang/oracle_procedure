CREATE OR REPLACE PACKAGE BODY IPTV."BSM_ENCRYPT" Is



function Encrypt_Serial_ID(in_Serial_ID varchar,p_gk1 varchar2 default null) return varchar
is
  v_en_ser_id varchar2(1024);
  v_raw raw(1024);
begin
  v_raw := utl_raw.cast_to_raw(encrypt(in_Serial_ID,p_gk1));
  v_en_ser_id :=v_raw;
  return(v_en_ser_id);
end;

function decrypt_Serial_ID(in_Serial_ID varchar,p_gk1 varchar2 default null) return varchar
is
  v_en_ser_id varchar2(1024);
  v_raw raw(1024);

begin
  
  v_raw := in_Serial_ID;
  v_en_ser_id := utl_raw.cast_to_varchar2(v_raw);
  v_en_ser_id := decrypt(v_en_ser_id,p_gk1);
  return(v_en_ser_id);
exception
  when others then return(null);
end;

Function Base64_2Dec
(Val Varchar2)
Return Number Is
I Pls_Integer;
J Pls_Integer;
K Pls_Integer:=0;
N Pls_Integer;
V_Out Number(38):=0;
Begin
  N:=Length(B64);
  For I In Reverse 1..Length(Val) Loop
    J:=Instr(B64,Substr(Val,I,1))-1;
    If J <0 Then
      Raise_Application_Error(-20001,'Invalid Base 64 Number: '||Val);
    End If;
    V_Out:=V_Out+J*(N**K);
    K:=K+1;
  End Loop;
  Return V_Out;
End;

Function Dec2_Base64
(Val Number)
Return Varchar2 Is
V_In Number;
N Pls_Integer;
V_Out Varchar2(30):='';
Begin
  N:=Length(B64);
  V_In:=Trunc(Val);
  While (V_In>0) Loop
    V_Out:=Substr(B64,Mod(V_In,N)+1,1)||V_Out;
    V_In:=Trunc(V_In/N);
  End Loop;
  Return V_Out;
End;

Function Decrypted_Pwd(Input_String Varchar2) Return Varchar2 Is

Raw_Input Raw(128) := Utl_Raw.Cast_To_Raw(Input_String); Decrypted_Raw Raw(2048); Error_In_Input_Buffer_Length
Exception
;

Begin
Sys.Dbms_Obfuscation_Toolkit.Md5(Input => Raw_Input, Checksum => Decrypted_Raw); Return Decrypted_Raw;
End;



  function encrypt (p_input varchar2,p_gk1 varchar2 default null) return varchar2 is
    l_input   varchar2 (1000);
    l_key     varchar2 (100) := nvl(p_gk1,gk1);
    l_result  varchar2 (1000);
  begin
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

   function decrypt (p_input varchar2,p_gk1 varchar2 default null) return varchar2 is
     l_input   varchar2 (1000);
     l_key     varchar2 (100) := nvl(p_gk1,gk1);
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

End BSM_encrypt;
/

