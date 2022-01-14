CREATE OR REPLACE PACKAGE IPTV."BSM_ENCRYPT" Is
B64 Varchar2(64):='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
 gk1  varchar2 (1000) := 'iptvtest27740083fghfghjfg789789hjknbk78bjyh';
Function Base64_2Dec(Val Varchar2) Return Number;
Function Dec2_Base64(Val Number) Return Varchar2;
function Encrypt_Serial_ID(in_Serial_ID varchar,p_gk1 varchar2 default null) return varchar;
function decrypt_Serial_ID(in_Serial_ID varchar,p_gk1 varchar2 default null) return varchar;
 function encrypt (p_input varchar2,p_gk1 varchar2 default null) return varchar2;
  function decrypt (p_input varchar2,p_gk1 varchar2 default null) return varchar2;
End BSM_encrypt;
/

