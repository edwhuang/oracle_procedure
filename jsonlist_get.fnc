create or replace function iptv.jsonlist_get(p_list JSON_LIST,pos_z pls_integer) return Json_value is
begin

  return(p_list.get_elem(pos_z+1));
end jsonlist_get;
/

