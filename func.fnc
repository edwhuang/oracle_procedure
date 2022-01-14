create or replace function iptv.func(p_str varchar2) return varchar
is
 v number;
begin
v:=to_number(p_str);
return('Y');
/* exception
  when others then return('N');*/
end;
/

