create or replace function iptv.get_datetime(str varchar2) return date
is
begin
  return to_date(substr(str,1,instr(str,':')+9),'DD/MON/YYYY:HH24:MI:SS');
end;
/

