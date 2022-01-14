CREATE OR REPLACE PACKAGE IPTV."B64" Is
B64 Varchar2(64):='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
Function Base64_2Dec(Val Varchar2) Return Number;
Function Dec2_Base64(Val Number) Return Varchar2;
function Encrypt_Serial_ID(in_Serial_ID varchar) return varchar;
function decrypt_Serial_ID(in_Serial_ID varchar) return varchar;
 function encrypt (p_input varchar2) return varchar2;
  function decrypt (p_input varchar2) return varchar2;
End B64;
/

