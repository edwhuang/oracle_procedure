CREATE OR REPLACE FUNCTION IPTV."CHECKCODE" (p_code varchar2,p_invalue number) RETURN varchar2
IS
  v_result varchar2(32);
BEGIN
  if p_code='CODE1' then
    return substr('A123456789B',p_invalue+1,1);
  else
    return substr('X123456789Y',p_invalue+1,1);
  end if;

END;
/

