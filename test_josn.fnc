create or replace function iptv.test_josn(op varchar2) return varchar2 is

   a json;
begin
  a:= json(op);

  return('Y');
exception
  when others then return('N');
end test_josn;
/

