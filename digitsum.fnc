CREATE OR REPLACE FUNCTION IPTV."DIGITSUM" (p_str varchar2,p_mode varchar) RETURN number IS
  v_Sum number(16);
  v_cnt number(16);
  Chars varchar2(64);
  Idx number;
BEGIN
  v_sum := 0;
  Chars := '1234567890ABCDEFGHI*JKLMNOPQR01STUVWXYZ';

  For v_cnt in 1 .. length(p_str) loop
     if ((p_mode='Odd') and (v_cnt mod 2 = 1)) or ((p_mode='Even') and (v_cnt mod 2 = 0)) or (p_mode ='All' ) then

        Idx:=0;
       Idx := InStr(Chars,substr(p_str,v_cnt,1)) Mod 10;

         v_Sum := v_sum +idx;
     end if;
     end loop;

 return(v_sum);

END;
/

