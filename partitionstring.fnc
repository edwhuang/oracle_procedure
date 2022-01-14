create or replace function iptv.partitionstring(strings varchar2,delimited varchar2,col int)
  return varchar2
as
  result varchar2(100);
begin
if instr(strings,delimited,1,1)=0 and col=1 then
     select strings into result from dual;
elsif instr(strings,delimited,1,1)>0 and col=1 then
     select substr(strings,1,instr(strings,delimited,1,1)-1) into result from dual;
elsif instr(strings,delimited,1,col-1)>0 and col=2 then  --col >1 and col < lastcol
     select substr(strings,
          instr(strings,delimited,1,col-1)+1,
          decode(sign(instr(strings,delimited,1,col)-instr(strings,delimited,1,col-1)),
                -1,length(strings),
                 1,instr(strings,delimited,1,col)-instr(strings,delimited,1,col-1)-1
                 --0,instr(strings,delimited,1,col)-instr(strings,delimited,1,col-1)-1
                )) into result
   from dual;
elsif instr(strings,delimited,1,col-1)>0 and col=3 then --last col
   select substr(strings,instr(strings,delimited,1,col-1)+1,length(strings)) 
     into result
   from dual;
end if;
 RETURN result;
end;
/

