create or replace function iptv.partitionclobstring(strings clob,delimited varchar2,col number,rowlimit number)
  return varchar2
as 
  result varchar2(200);
begin
  select str into result
  from 
      (
      select regexp_substr(strings,'[^'||delimited||']+',1,level) str,rownum NO
      from dual
      connect by level <= length(strings)-length(replace(strings,delimited,''))+1
      )
  where NO=(rowlimit-1)*14+2+col;
  RETURN result;
end;
/

