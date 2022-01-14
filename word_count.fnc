create or replace function iptv.word_count(str varchar2) return number is
  v_cnt   number(16);
  v_char  varchar2(256);
  v_count number(16);
  v_m     varchar2(2);
  v_skip  varchar2(1);
begin
  v_count := 0;
  v_m     := 'N';
  v_skip := 'N';

  for v_cnt in 1 .. length(str) loop
    v_char := substr(str, v_cnt, 1);
    if (INSTR('(', UPPER(v_char)) > 0) then
      v_skip := 'Y';
    end if;
    if v_skip <> 'Y' then
    
      if (INSTR('ABCDEFGHIJKLMNOPQRSTUVWXYZ-''', UPPER(v_char)) > 0) then
        if v_m = 'N' then
          v_count := v_count + 1;
        end if;
        v_m := 'Y';
      elsif (INSTR(' ~!/,，', UPPER(v_char)) > 0) then
        v_m := 'N';
      else
        v_count := v_count + 1;
      end if;
    end if;
  
  end loop;
  if v_count >= 10 then
    v_count := 0;
  end if;
  return v_count;
end;
/

