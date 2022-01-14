CREATE OR REPLACE PACKAGE BODY IPTV.CMS_UTIL is

  function get_id(p_pk_no number, p_item_type varchar2 default null)
    return varchar2 is
    v_return varchar2(64);
  begin
    if p_item_type = 'P' then
      select package_id
        into v_return
        from bsm_package_mas
       where package_no = p_pk_no;
    elsif p_item_type in ('G', 'A') then
      begin
        select content_id
          into v_return
          from mid_cms_content
         where pk_no = p_pk_no;
      exception
        when no_data_found then
          begin
            select item_id
              into v_return
              from mid_cms_item
             where pk_no = p_pk_no;
          exception
            when no_data_found then
              select asset_id
                into v_return
                from mid_cms_asset
               where pk_no = p_pk_no;
          end;
      end;
    elsif p_item_type is null then
      begin
        select content_id
          into v_return
          from mid_cms_content
         where pk_no = p_pk_no;
      exception
        when no_data_found then

          begin
            select item_id
              into v_return
              from mid_cms_item
             where pk_no = p_pk_no;
          exception
            when no_data_found then
              select asset_id
                into v_return
                from mid_cms_asset
               where pk_no = p_pk_no;
          end;
      end;
    end if;
    return v_return;
  end;

  function get_content_title(p_content_id varchar2) return varchar2 deterministic is
    v_return varchar2(1024);
  begin
        select a.content_title into v_return from ccc_program_asset a where a.content_id=p_content_id and rownum <=1 and content_title is not null;
    return v_return;
  exception 
    when no_data_found then   
    begin
      select title
        into v_return
        from mid_cms_content
       where content_id = p_content_id;
    exception
      when no_data_found then
        begin
          select title
        into v_return
        from mid_cms_content
       where pk_no = (select mas_pk_no
                         from mid_cms_item_rel a
                        where a.detail_pk_no in
                              (select pk_no
                                 from mid_cms_item
                                where item_id = p_content_id));
       exception 
         when no_data_found then v_return := null;
       end;

    end;

    return v_return;

  /*  begin
      select title
        into v_return
        from mid_cms_content
       where content_id = p_content_id;
    exception
      when no_data_found then
        begin
          select title
        into v_return
        from mid_cms_content
       where pk_no in (select mas_pk_no
                         from mid_cms_item_rel a
                        where a.detail_pk_no in
                              (select pk_no
                                 from mid_cms_item
                                where item_id = p_content_id));
       exception 
         when no_data_found then v_return := null;
       end;

    end; 

    return v_return; */
  end;

  function get_content_id(p_asse_pk_no number) return varchar2 deterministic is
    v_content_id varchar2(64);
  begin

    Select content_id
      into v_content_id
      from mid_cms_content d
     where d.pk_no in (select decode(c.type, 'G', mas_pk_no, 0)
                         from mid_cms_item_rel c
                        where type in ('G')
                        start with c.detail_pk_no = p_asse_pk_no
                       connect by prior mas_pk_no = c.detail_pk_no
                              and type = 'G')
       and rownum <= 1;
    return v_content_id;
  exception
    when others then
      return null;
  end;

  function get_content_id(p_id varchar2) return varchar2 deterministic is
    v_content_id  varchar2(64);
    v_asset_pk_no number(16);
  begin
    begin
      select content_id into v_content_id from mid_cms_asset_list a where a.asset_id=p_id;
       return v_content_id;
    exception
      when no_data_found then
    v_asset_pk_no := get_pk_no(p_id, null);

    Select content_id
      into v_content_id
      from mid_cms_content d
     where d.pk_no in (select decode(c.type, 'G', mas_pk_no, 0)
                         from mid_cms_item_rel c
                        where type in ('G')
                        start with c.detail_pk_no = v_asset_pk_no
                       connect by prior mas_pk_no = c.detail_pk_no
                              and type = 'G')
       and rownum <= 1;
    return v_content_id;
    
    end;
  exception
    when others then
      return null;

  end;

  function get_pk_no(p_id string, p_item_type varchar2 default null)
    return varchar2 is
    v_return number;
  begin
    if p_item_type = 'P' then
      select a.package_no
        into v_return
        from bsm_package_mas a
       where package_id = p_id;
    elsif p_item_type in ('G', 'A') then
      begin
        select pk_no
          into v_return
          from mid_cms_content
         where content_id = p_id;
      exception
        when no_data_found then
          begin
            select pk_no
              into v_return
              from mid_cms_item
             where item_id = p_id;
          exception
            when no_data_found then
              select pk_no
                into v_return
                from mid_cms_asset
               where asset_id = p_id;
          end;
      end;
    elsif p_item_type is null then
      begin
        select pk_no
          into v_return
          from mid_cms_content
         where content_id = p_id;
      exception
        when no_data_found then

          begin
            select pk_no
              into v_return
              from mid_cms_item
             where item_id = p_id;
          exception
            when no_data_found then
              select pk_no
                into v_return
                from mid_cms_asset
               where asset_id = p_id;
          end;
      end;
    end if;
    return v_return;
  end;

  function get_asset_name(p_asset_id varchar2) return varchar2 is
    v_asset_name  varchar2(1024);
    v_asset_pk_no number(16);
    v_content_id  varchar2(1024);
  begin
    if p_asset_id = 'WE2011021001' then
      return '天氣影片';
    end if;
    select songname
      into v_asset_name
      from mid_kod_songdata
     where asset_id = p_asset_id;
    return v_asset_name;

  exception
    when no_data_found then
      begin
        select content_title into v_asset_name from mid_cms_asset_list a where a.asset_id = p_asset_id;
        return v_asset_name;
     exception
        when no_data_found then 
          begin
        select pk_no
          into v_asset_pk_no
          from mid_cms_asset
         where asset_id = p_asset_id
           and rownum <= 1;
        v_content_id := get_content_id(v_asset_pk_no);
        v_asset_name := get_content_title(v_content_id);
        return v_asset_name;
      exception
        when no_data_found then
          return null;
        when others then
          return p_asset_id;
      end;
    end;

  end;

  function get_active_package(p_mac_address varchar2,
                              p_play_time   date,
                              p_asset_id    varchar2) return varchar2 is
    v_type        varchar2(64);
    v_package_id  varchar2(64);
    v_asset_pk_no number(16);
  begin
    begin
      select 'KOD'
        into v_type
        from mid_kod_songdata
       where asset_id = p_asset_id;
    exception
      when no_data_found then
        null;
        begin
          Select pk_no, 'VOD'
            into v_asset_pk_no, v_type
            from mid_cms_asset
           where asset_id = p_asset_id
             and rownum <= 1;
        exception
          when no_data_found then
            v_asset_pk_no := null;
            v_type        := null;
        end;
    end;

    if v_type = 'KOD' then
      declare
        cursor c1 is
          select b.package_id
            from bsm_client_details a, bsm_package_mas b
           where a.mac_address = p_mac_address
             and b.package_id = a.package_id
             and b.package_cat_id1 = 'KOD'
             and a.start_date <= p_play_time
             and a.end_date >= p_play_time
           order by start_date;
      begin
        for c1rec in c1 loop
          v_package_id := c1rec.package_id;
        end loop;
        return v_package_id;
      exception
        when no_data_found then
          return null;
      end;
    elsif v_type = 'VOD' then
      declare
        cursor c1 is
          select f.package_id
            from mid_cms_item_rel   c,
                 mid_cms_item       d,
                 bsm_package_mas    e,
                 bsm_client_details f
           where c.type = 'P'
             and mas_pk_no in (Select b.mas_pk_no
                                 from mid_cms_item_rel b
                                start with detail_pk_no = v_asset_pk_no
                               connect by prior mas_pk_no = detail_pk_no
                                      and type = 'G')
             and d.pk_no = c.detail_pk_no
             and e.package_id = d.package_id
             and f.mac_address = p_mac_address
             and f.package_id = e.package_id
             and f.start_date <= p_play_time
             and f.end_date >= p_play_time
           order by f.start_date;
      begin
        for c1rec in c1 loop
          v_package_id := c1rec.package_id;
        end loop;
        return v_package_id;
      exception
        when no_data_found then
          null;
      end;

    end if;
    return v_package_id;
  end;

  function get_content_supply(p_content_id varchar2) return varchar2 is
    v_provider varchar2(1024);
    v_return varchar2(1024);
  begin
      begin
        select a.provider into v_return from ccc_program_asset a where a.content_id=p_content_id and rownum <=1 and provider is not null;
      
         
      

  exception 
     when no_data_found then
    if p_content_id is not null then
    begin
      
      select supply
        into v_return
        from mid_cms_content
       where content_id = p_content_id;
    exception
      when no_data_found then
        begin
         select supply
        into v_return
        from mid_cms_content
       where pk_no in (select mas_pk_no
                         from mid_cms_item_rel a
                        where a.detail_pk_no in
                              (select pk_no
                                 from mid_cms_item
                                where item_id = p_content_id));
        exception
           when no_data_found then
           v_return := null;
        end;
    end;
    else
       v_return := null;
    end if;
    end;

    return v_return;
  end;

  function get_content_id_v2(p_id varchar2) return varchar2 as
    v_return varchar2(50);
  begin
    begin
      select content_id
        into v_return
        from mid_cms_content
       where (content_id = p_id
          or pk_no in
             (select mas_pk_no
                from mid_cms_item_rel
               where detail_pk_no in
                     (select pk_no from mid_cms_item where item_id = p_id))
          or pk_no in (select mas_pk_no
                         from mid_cms_item_rel
                        where detail_pk_no in
                              (select mas_pk_no
                                 from mid_cms_item_rel
                                where detail_pk_no in
                                      (select pk_no
                                         from mid_cms_asset
                                        where asset_id = p_id)))) and rownum<= 1;
    exception
      when no_data_found then
        v_return := null;
    end;
    return v_return;
  end;

  function get_logo(p_id varchar2) return varchar2 as
    v_return     varchar2(64);
    v_content_id varchar2(64);
  begin
    v_content_id := get_content_id_v2(p_id);
    select a.main_picture
      into v_return
      from mid_cms_content a
     where content_id = v_content_id;
    return 'http://streaming01.tw.svc.litv.tv/' || v_return;
  exception
    when no_data_found then
      return null;
  end;

procedure gen_content_id(src_no varchar2,p_pk_no out number,o_content_id out varchar2)
 is
 begin
  o_content_id := sysapp_util.get_mas_no(1,2,sysdate,'CMS_CONTENT',p_pk_no,'VD');
 end;

 procedure gen_item_id(src_no varchar2,p_content_id varchar2,p_item_id varchar2,p_pk_no out number,o_item_id out varchar2)
 is
 begin
      o_item_id := sysapp_util.get_mas_no(1,2,sysdate,'CMS_ITEM',p_PK_NO,p_CONTENT_ID||'01');
 end;

  procedure gen_asset_id(src_no varchar2,p_item_id varchar2,p_HD_SD varchar2,p_pk_no out number,o_asset_id out varchar2)
    is
  begin
   o_asset_id := sysapp_util.get_mas_no(1,2,sysdate,'CMS_ITEM',p_PK_NO,p_item_id||p_HD_SD);
  end;

   procedure get_subtilt_id(src_no varchar2,p_asset_id varchar2,p_pk_no out number,o_subtitle_id out varchar2)
   is
   begin
     o_subtitle_id := sysapp_util.get_mas_no(1,2,sysdate,'CMS_ITEM',p_PK_NO,p_asset_id||'S');
   end;
-- Initialization
-- <Statement>;
end CMS_UTIL;
/

