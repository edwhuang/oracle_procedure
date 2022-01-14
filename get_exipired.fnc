﻿CREATE OR REPLACE FUNCTION IPTV."GET_EXIPIRED" (p_client_id varchar2,p_asset_id varchar2) RETURN Date
is
  result varchar2(32);
  v_client_id varchar2(32);
begin

 v_client_id := upper(p_client_id);

select a.end_date into result
  from bsm_client_details a,bsm_package_mas b
 where mac_address = v_client_id
   and a.package_id=b.package_id
   and a.status_flg = 'P'
   and (start_date is null or
       (start_date <= sysdate and end_date >= sysdate))    
   and ((a.package_id in (select "parent_id"
                          from acl.relationship
                         where "child_id" = p_asset_id
                           and nvl("deleted", 0) = 0)) or
       (decode(b.cal_type,'T',a.item_id,a.package_id) in
       (select "parent_id"
            from acl.relationship
           where "child_id" in
                 (select "parent_id"
                    from acl.relationship
                   where "child_id" in
                         (select "parent_id"
                            from acl.relationship
                           where "child_id" = p_asset_id
                             and nvl("deleted", 0) = 0)) and nvl("deleted", 0)= 0))
                        or     (decode(b.cal_type,'T',a.item_id,a.package_id) in
       (select "parent_id"
            from acl.relationship
           where "child_id" in
                 (select "parent_id"
                    from acl.relationship
                   where "child_id" in
                         (select "parent_id"
                            from acl.relationship
                           where "child_id" in
                                 (select "parent_id"
                                    from acl.relationship
                                   where "child_id" = p_asset_id
                                     and nvl("deleted", 0) = 0))) and nvl("deleted", 0)= 0 ))  or
        (p_asset_id ='KOD' and (b.package_cat_id1= p_asset_id))                                   
      )
      
      -- 


   and rownum <= 1;

 return result;
exception
  when no_data_found then
    return null;
end;
/
