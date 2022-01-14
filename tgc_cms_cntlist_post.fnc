CREATE OR REPLACE Function IPTV.tgc_cms_cntlist_post(p_user_no   Number,
                                p_cat_id    varchar2,
                                p_no_commit varchar2 default 'N')
    Return Varchar2 Is

    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg         Varchar2(32);
    v_content_pk_no      number(16);
    v_default_package_id varchar2(32);
    v_syn_id             varchar2(32);
    v_char               varchar2(1);
    v_list_status_flg    varchar2(32);
    resend_content varchar2(32) ;
    --  v_content_pk_no      number(16);

    cursor c1 is
      Select rowid rid, content_id, status_flg
        from mid_content_list
       where cat = p_cat_id; -- and status_flg ='A';

  Begin
    resend_content := 'N';
    select default_package_id
      into v_default_package_id
      from mid_cms_content_cat a
     where a.cat = p_cat_id;

    for c1rec in c1 loop
      select pk_no, status_flg
        into v_content_pk_no, v_status_flg
        from mid_cms_content
       where content_id = c1rec.content_id;

      if c1rec.status_flg = 'R' then
        v_list_status_flg := 'P';
        update mid_content_list a
           set status_flg = v_list_status_flg
         where rowid = c1rec.rid;
      else
        v_list_status_flg := c1rec.status_flg;
      end if;

    /*  if v_status_flg = 'A' then
        declare
          v_msg varchar2(1024);
        begin
          v_msg := CMS_CNT_POST.tgc_cms_content_check(0, v_content_pk_no);
          v_msg := CMS_CNT_POST.tgc_cms_content_post(0, v_content_pk_no);
        end;
      else
        null;
      end if; */

   /*   if c1rec.status_flg in ('P', 'R') then
        --
        -- check asset status flg
        --
        declare
          v_cnt number(16);
        begin
          update mid_cms_asset a
             set a.file_check_flg = 'Y'
           where pk_no in
                 (select detail_pk_no
                    from mid_cms_item_rel b
                   start with mas_pk_no = v_content_pk_no
                  connect by mas_pk_no = prior detail_pk_no)
             and status_flg = 'P';

          select count(*)
            into v_cnt
            from mid_cms_asset a
           where pk_no in
                 (select detail_pk_no
                    from mid_cms_item_rel b
                   start with mas_pk_no = v_content_pk_no
                  connect by mas_pk_no = prior detail_pk_no)
             and status_flg = 'P'
             and a.file_check_flg = 'Y';
          if v_cnt <= 0 then
            update mid_content_list a
               set status_flg = 'F'
             where rowid = c1rec.rid;

          end if;
        end;
      end if; */
      --
      -- Update the Default Package
      --
      if c1rec.status_flg in ('R', 'P') then
        declare
          cursor c2 is
            select package_id
              from bsm_package_mas a,mid_content_list b
             where ((a.package_cat_id1 = b.cat and a.content_id is null) or
                   (a.package_cat_id1 = b.cat and
                   a.content_id = b.content_id) or
                   (b.cat = 'TRAILER' and
                   package_id = 'FREE_FOR_CLEINT_ACTIVED')
                   --       or
                   --       (P_CAT = 'HIKIDS' and
                   --      package_id = 'FREE_FOR_CLEINT_ACTIVED')
                   )
                   and b.content_id =c1rec.CONTENT_ID
                   and b.status_flg='P';
          cursor c3 is
             select a.*
                from mid_cms_item_rel a,mid_cms_item b
               where a.type = 'P'
                 and b.pk_no = a.detail_pk_no
                 and mas_pk_no =(select pk_no from mid_cms_content d where d.content_id=c1rec.CONTENT_ID)
                 and b.package_id not in (
                  select package_id
              from bsm_package_mas a,mid_content_list b
             where ((a.package_cat_id1 = b.cat and a.content_id is null) or
                   (a.package_cat_id1 = b.cat and
                   a.content_id = b.content_id) or
                   (b.cat = 'TRAILER' and
                   package_id = 'FREE_FOR_CLEINT_ACTIVED')  )
                   and b.content_id =c1rec.CONTENT_ID
                   and b.status_flg='P');
        begin
          for c3rec in c3 loop
            delete mid_cms_item where pk_no = c3rec.detail_pk_no;
            delete mid_cms_item_rel where mas_pk_no = c3rec.mas_pk_no and detail_pk_no = c3rec.detail_pk_no;
            commit;
          end loop;

          for c2rec in c2 loop
            begin

              select 'x'
                into v_char
                from mid_cms_item_rel a
               where a.type = 'P'
                 and mas_pk_no = v_content_pk_no
                 and detail_pk_no in
                     (select pk_no
                        from mid_cms_item
                       where package_id = c2rec.package_id)
                 and rownum <= 1;

            exception
              when no_data_found then

                declare
                  v_item_pk_no number(16);
                  v_item_id    varchar2(32);
                  v_rel_pk_no  number(16);
                begin
                  select seq_cms.nextval into v_item_pk_no from dual;
                  v_item_id := sysapp_util.Get_Mas_No(1,
                                                      2,
                                                      sysdate,
                                                      'CMS_ITEM',
                                                      v_item_PK_NO,
                                                      c1rec.CONTENT_ID || '.P');
                  insert into mid_cms_item
                    (pk_no, item_type, item_id, package_id, status_flg)
                  values
                    (v_item_pk_no, null, v_item_id, c2rec.package_id, 'P');

                  select seq_cms.nextval into v_rel_pk_no from dual;
                  insert into mid_cms_item_rel
                    (mas_pk_no,
                     detail_pk_no,
                     type,
                     last_modify,
                     last_modify_emp,
                     status_flg,
                     PK_NO)
                  values
                    (v_content_pk_no,
                     v_item_pk_no,
                     'P',
                     sysdate,
                     'system',
                     'A',
                     v_rel_pk_no);
                     commit;
                end;
            end;

          end loop;
        end;
      end if;
      cms_cnt_post.cms_vod_tag_proc(c1rec.content_id);
     

    end loop;

    if p_no_commit = 'Y' then
      commit;
    end if;

    v_syn_id := sysapp_util.Get_Mas_No(1, 2, sysdate, 'SYNID', 2);
    update MID_SYN_LOG set SYN_ID = v_syn_id, last_modify = sysdate;
    commit;



  
    return null;

  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
   when no_data_found then
       acl_master_transfer;
       return null;
  End;
/

