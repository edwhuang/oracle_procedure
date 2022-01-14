create or replace function iptv.update_bsm_detail(p_client_id  varchar,
                             p_asset_id   varchar2,
                             p_start_date date) return varchar2 is
    v_package_id varchar2(64);
    v_detail_pk_no varchar2(64);
  begin
    Declare
      v_client_id varchar2(64);

    begin

      v_client_id := p_client_id;

      declare
        cursor c_package_id is
         Select "parent_id" package_id
            from acl.relationship a
           where --"deleted" is null
           --  and 
             "child_id" in
                 (Select "parent_id"
                    from acl.relationship a
                   where --"deleted" is null
                     --and 
                     "child_id" in
                         (Select "parent_id"
                            from acl.relationship a
                           where --"deleted" is null
                            -- and
                              "child_id" = p_asset_id))
          union all -- for kod
          Select "parent_id" package_id
            from acl.relationship a
           where "deleted" is null
             and "child_id" = p_asset_id;

        cursor c_detail_end(p_package_id varchar2) is
          select *
            from bsm_client_details a
           where a.mac_address = v_client_id
             and a.status_flg = 'P'
             and a.end_date is not null
             and a.package_id <> 'FREE_FOR_CLEINT_ACTIVED'
             and (a.package_id = p_package_id or a.item_id = p_package_id);

        cursor c_detail(p_package_id varchar2) is
          select rowid rid, a.*
            from bsm_client_details a
           where a.mac_address = v_client_id
             and a.status_flg = 'P'
             and a.end_date is null
             and (a.package_id = p_package_id or a.item_id = p_package_id)
             and a.package_id <> 'FREE_FOR_CLEINT_ACTIVED'
             and rownum <= 1;

        v_skip       varchar2(64);
        v_end_date   date;
        v_start_date date;

      begin
        v_skip       := 'N';
        v_package_id := null;
        for r_package_id in c_package_id loop
          for r_detail in c_detail_end(r_package_id.package_id) loop
            if r_detail.end_date is not null then
              if r_detail.end_date >= sysdate then
                if nvl(v_end_date, r_detail.end_date) < r_detail.end_date then
                  v_end_date := r_detail.end_date;
                end if;
                v_package_id := r_detail.package_id;
                 v_detail_pk_no := r_detail.pk_no;
                v_skip       := 'Y';
              end if;
            end if; 
          end loop; 
          null;

        end loop;
      end;

    end;

    return v_package_id;
  end;
/

