CREATE OR REPLACE FUNCTION IPTV."RPADB" (str1 varchar,len number,s_str varchar) return varchar
is
 v_result varchar(1024):= '';
 v_char varchar2(2);
 v_lengthb number;
begin
  v_result := str1;
  
 /* v_lengthb := 0;
  if str1 is not null then
  for i in 1..length(str1) loop
    if(lengthb(substr(str1,i,1)) = 1) then
       v_lengthb := v_lengthb+1;
    elsif (lengthb(substr(str1,i,1)) = 3) then
       v_lengthb := v_lengthb+2;
    elsif (lengthb(substr(str1,i,1)) = 2) then
       v_lengthb := v_lengthb+2;
    end if;
      end loop;
  else
    v_lengthb := 0;
  end if;
  */     

  if v_result is null then 
     v_lengthb :=0; 
  else
    v_lengthb := lengthb(v_result);
  end if;
  while v_lengthb < len loop
    v_result := v_result||s_str;
    v_lengthb := v_lengthb+length(s_str);
  end loop;
  return v_result;
end;
/

