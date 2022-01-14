CREATE OR REPLACE PACKAGE BODY IPTV.CMS_CNT_POST Is
  epg_url   varchar2(1024);
  epg_url_s varchar2(1024);
  Function tgc_cms_content_check(p_user_no   Number,
                                 p_pk_no     Number,
                                 p_no_commit varchar2 default 'N')
    Return Varchar2 Is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
  
  Begin
    select status_flg
      into v_status_flg
      from mid_cms_content
     where pk_no = p_pk_no;
  
    if v_status_flg != 'A' then
      exception_msg := '#狀態不正確#';
      raise app_exception;
    end if;
  
    update mid_cms_content set status_flg = 'E' where pk_no = p_pk_no;
  
    if p_no_commit = 'Y' then
      commit;
    end if;
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('CMS_CONTENT',
       p_Pk_No,
       Sysdate,
       p_User_No,
       'Check',
       Sys_Event_Seq.Nextval,
       'Post');
  
    rebuild_catalog(p_pk_no);
  
    commit;
  
    return null;
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function tgc_cms_content_post(p_user_no   Number,
                                p_pk_no     Number,
                                p_no_commit varchar2 default 'N')
    Return Varchar2 Is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_content_id varchar2(32);
    v_syn_id     varchar2(32);
    v_ref1       varchar2(256);
    v_ref4       varchar2(256);
    v_ref5       varchar2(256);
    v_SDHD       varchar2(32);
  
  Begin
    begin
      select status_flg, content_id, ref4, ref5, ref1, SDHD
        into v_status_flg, v_content_id, v_ref4, v_ref5, v_ref1, v_SDHD
        from mid_cms_content
       where pk_no = p_pk_no;
    exception
      when no_data_found then
        exception_msg := '找不到此content pk_no=' || p_pk_no;
        raise app_exception;
    end;
  
    if v_status_flg != 'E' then
      exception_msg := '#狀態不正確#';
      raise app_exception;
    end if;
  
    if v_SDHD is null then
      update mid_cms_content set SDHD = 'SD' where pk_no = p_pk_no;
    end if;
  
    if v_ref4 is null then
      v_ref4 := '中文';
      update mid_cms_content set ref4 = v_ref4 where pk_no = p_pk_no;
    end if;
  
    if v_ref5 is null then
      if instr(v_ref1, '/') = 0 then
        v_ref5 := v_ref1;
      else
        v_ref5 := substr(v_ref1, 1, instr(v_ref1, '/') - 1);
      end if;
      update mid_cms_content set ref5 = v_ref5 where pk_no = p_pk_no;
    end if;
  
    declare
      v_provider_logo varchar2(256);
      v_provider_id   varchar2(256);
    begin
      select supply
        into v_provider_id
        from mid_cms_content
       where content_id = v_content_id;
      select provider_logo
        into v_provider_logo
        from mid_cms_content_provider
       where provider_id = v_provider_id;
      update mid_cms_content
         set ref6 = v_provider_logo
       where content_id = v_content_id;
    exception
      when no_data_found then
        null;
    end;
  
    update mid_cms_content set status_flg = 'P' where pk_no = p_pk_no;
  
    update mid_cms_item d
       set d.status_flg = 'P'
     where pk_no in
           (select pk_no
              from mid_cms_item c
             where c.pk_no in (select d.detail_pk_no
                                 from mid_cms_item_rel d
                                start with d.mas_pk_no = p_pk_no
                               connect by prior detail_pk_no = mas_pk_no
                                      and type = 'G')
               and status_flg = 'A');
  
    update mid_cms_asset d
       set d.status_flg = 'P'
     where pk_no in
           (select pk_no
              from mid_cms_asset c
             where c.pk_no in (select d.detail_pk_no
                                 from mid_cms_item_rel d
                                start with d.mas_pk_no = p_pk_no
                               connect by prior detail_pk_no = mas_pk_no
                                      and type in ('G', 'A'))
               and status_flg = 'A');
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('CMS_CONTENT',
       p_Pk_No,
       Sysdate,
       p_User_No,
       'Post',
       Sys_Event_Seq.Nextval,
       'Post');
       
    cms_vod_tag_proc(v_content_id);   
  
    rebuild_catalog(p_pk_no);
  
    commit;
  
    v_syn_id := sysapp_util.Get_Mas_No(1, 2, sysdate, 'SYNID', 2);
    update MID_SYN_LOG set SYN_ID = v_syn_id, last_modify = sysdate;
    commit;
  
    -- epg01
    declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
    --   utl_http.set_transfer_timeout(16000);
      --  v_Big5_Text := Convert(p_Message || ' ', 'ZHT16MSWIN950');
      v_Sms_Url := epg_url || '/Oracle2Mysqlc.php?contentid=' ||
                   v_content_id || '';
                   
     utl_http.set_transfer_timeout(1000);                   
      --  Begin
      Http_Req := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      --   Exception
      --    When Others Then
      --      Raise Error_Sms_Connect;
      --   End;
    
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    
      -- Exception
      --  When Error_Sms_Connect Then
      --    Return 'SMS Failure';
    End;
  
    -- epg02 
   /* declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      --  v_Big5_Text := Convert(p_Message || ' ', 'ZHT16MSWIN950');
      v_Sms_Url := epg_url_s || '/Oracle2Mysqlc.php?contentid=' ||
                   v_content_id || '';
      --  Begin
      Http_Req := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      --   Exception
      --    When Others Then
      --      Raise Error_Sms_Connect;
      --   End;
    
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    
      -- Exception
      --  When Error_Sms_Connect Then
      --    Return 'SMS Failure';
    End;
  */
    return null;
  
  Exception
    When app_exception Then
      Rollback;
     -- Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  procedure rebuild_catalog(p_pk_no number) is
    v_catalog_id  varchar2(32);
    v_title       varchar2(1024);
    v_eng_title   varchar2(1024);
    v_short_title varchar2(1024);
    v_org_title   varchar2(1024);
  begin
    select catalog_id, title, short_title, eng_title, org_title
      into v_catalog_id, v_title, v_short_title, v_eng_title, v_org_title
      from mid_cms_content
     where pk_no = p_pk_no;
    if v_catalog_id is null then
      v_catalog_id := sysapp_util.get_mas_no(1,
                                             2,
                                             sysdate,
                                             'CMS_CATALOG_ID',
                                             p_pk_no);
      update mid_cms_content
         set catalog_id = v_catalog_id
       where pk_no = p_pk_no;
    
      insert into cms_meta_catalog_mas (catalog_id) values (v_catalog_id);
    end if;
  
    delete cms_meta_catalog where catalog_id = v_catalog_id;
    insert into cms_meta_catalog
      (catalog_id, tag_id, content)
    values
      (v_catalog_id, 'TITLE', v_title);
    insert into cms_meta_catalog
      (catalog_id, tag_id, content)
    values
      (v_catalog_id, 'SHORT_TITLE', v_short_title);
    insert into cms_meta_catalog
      (catalog_id, tag_id, content)
    values
      (v_catalog_id, 'ENG_TITLE', v_eng_title);
    insert into cms_meta_catalog
      (catalog_id, tag_id, content)
    values
      (v_catalog_id, 'ORG_TITLE', v_org_title);
  
  end;

  Function tgc_cms_content_unpost(p_user_no   Number,
                                  p_pk_no     Number,
                                  p_no_commit varchar2 default 'N')
    Return Varchar2 Is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_content_id varchar2(32);
    v_syn_id     varchar2(32);
  
  Begin
    select status_flg, content_id
      into v_status_flg, v_content_id
      from mid_cms_content
     where pk_no = p_pk_no;
  
    if v_status_flg != 'P' then
      exception_msg := '#狀態不正確#';
      raise app_exception;
    end if;
  
    update mid_cms_content set status_flg = 'A' where pk_no = p_pk_no;
  
    if p_no_commit = 'Y' then
      commit;
    end if;
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('CMS_CONTENT',
       p_Pk_No,
       Sysdate,
       p_User_No,
       'Unpost',
       Sys_Event_Seq.Nextval,
       'Unpost');
  
    commit;
  
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  Function tgc_cms_item_post(p_user_no   Number,
                             p_pk_no     Number,
                             p_no_commit varchar2 default 'N')
    Return Varchar2 Is
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg Varchar2(32);
    v_item_id    varchar2(32);
    v_syn_id     varchar2(32);
  
  Begin
    select item_id, status_flg
      into v_item_id, v_status_flg
      from mid_cms_item
     where pk_no = p_pk_no;
  
    if v_status_flg = 'A' then
      update mid_cms_item set status_flg = 'P' where pk_no = p_pk_no;
    end if;
  
    update mid_cms_asset a
       set a.status_flg = 'P'
     where a.status_flg = 'A'
       and pk_no in (select detail_pk_no
                       from mid_cms_item_rel b
                      where b.mas_pk_no = a.pk_no);
  
    if p_no_commit = 'Y' then
      commit;
    end if;
  
    Insert Into Sysevent_Log
      (App_Code,
       Pk_No,
       Event_Date,
       User_No,
       Event_Type,
       Seq_No,
       Description)
    Values
      ('CMS_CONTENT',
       p_Pk_No,
       Sysdate,
       p_User_No,
       'PostItem',
       Sys_Event_Seq.Nextval,
       'PostItem');
  
    commit;
  
    v_syn_id := sysapp_util.Get_Mas_No(1, 2, sysdate, 'SYNID', 2);
    update MID_SYN_LOG set SYN_ID = v_syn_id, last_modify = sysdate;
    commit;
    -- epg01
    declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      --  v_Big5_Text := Convert(p_Message || ' ', 'ZHT16MSWIN950');
      v_Sms_Url := epg_url || '/Oracle2Mysqli.php?itemid=' || v_item_id || '';
      --  Begin
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    
    End;
  
    --epg02
  
    declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      --  v_Big5_Text := Convert(p_Message || ' ', 'ZHT16MSWIN950');
      v_Sms_Url := epg_url_s || '/Oracle2Mysqli.php?itemid=' || v_item_id || '';
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    
    End;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    
  End;

  
  Function tgc_cms_cntlist_post(p_user_no   Number,
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
    i_cnt number(16);
    --  v_content_pk_no      number(16);
  
    cursor c1 is
      Select rowid rid, content_id, status_flg,no
        from mid_content_list a
       where cat = p_cat_id
       order by status_flg desc ,start_schedule_date desc nulls last,a.no; 
  
  Begin
    i_cnt := 0;
   utl_http.set_transfer_timeout(3200);
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
    
      if v_status_flg = 'A' and i_cnt <= 100 then
        declare
          v_msg varchar2(1024);
        begin
          v_msg := CMS_CNT_POST.tgc_cms_content_check(0, v_content_pk_no);
          v_msg := CMS_CNT_POST.tgc_cms_content_post(0, v_content_pk_no);
        end; 
        i_cnt:=i_cnt+1;
      else
        null;
      end if; 
    
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
      cms_vod_tag_proc(c1rec.content_id);
      
      if resend_content = 'Y' then
            declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      --  v_Big5_Text := Convert(p_Message || ' ', 'ZHT16MSWIN950');
      v_Sms_Url := epg_url || '/Oracle2Mysqlc.php?contentid=' ||
                   c1rec.content_id || '';
      --  Begin
      Http_Req := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      --   Exception
      --    When Others Then
      --      Raise Error_Sms_Connect;
      --   End;
    
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    
      -- Exception
      --  When Error_Sms_Connect Then
      --    Return 'SMS Failure';
    End;
  
      end if;
      cms_vod_tag_proc(c1rec.content_id);
    
    end loop;
  
    if p_no_commit = 'Y' then
      commit;
    end if;
  
    v_syn_id := sysapp_util.Get_Mas_No(1, 2, sysdate, 'SYNID', 2);
    update MID_SYN_LOG set SYN_ID = v_syn_id, last_modify = sysdate;
    commit;
  
    -- refrash echo
   -- acl_master_transfer;
  
    declare
      Http_Request Varchar2(30000);
      Http_Respond clob;
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
       rw  varchar2(32767);
    
      v_Result Varchar2(256);
    Begin
      v_Sms_Url := epg_url || '/Oracle2Mysqll.php?cat=' || p_cat_id || '';
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
            loop
      begin
        rw := null;
        utl_http.read_line(Http_Resp, rw, TRUE);
        Http_Respond := Http_Respond || rw;
      exception
        when others then
          exit;
      end;
    end loop;
      Utl_Http.End_Response(Http_Resp);
    End;
    
    --epg02
 /*   declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      v_Sms_Url := epg_url_s || '/Oracle2Mysqll.php?cat=' || p_cat_id || '';
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    End; */
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

 Function tgc_cms_cntlist_post_syn(p_user_no   Number,
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
    resend_content := 'Y';
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
    
      if v_status_flg = 'A' then
        declare
          v_msg varchar2(1024);
        begin
          v_msg := CMS_CNT_POST.tgc_cms_content_check(0, v_content_pk_no);
          v_msg := CMS_CNT_POST.tgc_cms_content_post(0, v_content_pk_no);
        end;
      else
        null;
      end if;
    
      if c1rec.status_flg in ('P', 'R') then
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
      end if;
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
                end;
            end;
          
          end loop;
        end;
      end if;
      cms_vod_tag_proc(c1rec.content_id);
      if resend_content = 'Y' then
            declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      --  v_Big5_Text := Convert(p_Message || ' ', 'ZHT16MSWIN950');
      v_Sms_Url := epg_url || '/Oracle2Mysqlc.php?contentid=' ||
                   c1rec.content_id || '';
      --  Begin
      Http_Req := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      --   Exception
      --    When Others Then
      --      Raise Error_Sms_Connect;
      --   End;
    
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    
      -- Exception
      --  When Error_Sms_Connect Then
      --    Return 'SMS Failure';
    End;
  
      end if;
    
    end loop;
  
    if p_no_commit = 'Y' then
      commit;
    end if;
  
    v_syn_id := sysapp_util.Get_Mas_No(1, 2, sysdate, 'SYNID', 2);
    update MID_SYN_LOG set SYN_ID = v_syn_id, last_modify = sysdate;
    commit;
  
    -- refrash echo
    acl_master_transfer;
  
    declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      v_Sms_Url := epg_url || '/Oracle2Mysqll.php?cat=' || p_cat_id || '';
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    End;
    --epg02
    declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
    
      v_Result Varchar2(256);
    Begin
      v_Sms_Url := epg_url_s || '/Oracle2Mysqll.php?cat=' || p_cat_id || '';
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    End;
    return null;
  
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
  End;

 Function Mid_kod_Post Return Varchar2 Is
    Http_Request   Varchar2(30000);
    Http_Respond   clob;
    Http_Req       Utl_Http.Req;
    Http_Resp      Utl_Http.Resp;
    v_Sms_Url      Varchar2(10000);
    v_Big5_Text    Varchar2(10000);
    v_release_date date;
    v_cnt          number(16);
  
    v_Result Varchar2(256);
    cursor c1 is
      select rowid rid
        from mid_kod_songdata a
       order by Convert(a.songname || ' ', 'ZHT16MSWIN950', 'UTF8');
    cursor c2 is
      select rowid rid
        from mid_kod_songdata a
       order by Convert(a.singer || ' ', 'ZHT16MSWIN950', 'UTF8');
    Cursor c3 Is
      Select rowid rid
        From mid_kod_songdata a
       where a.newsong = 1
    --     and a.specialclass not in ('START')
       Order By a.import_date desc;
    v_i number(16) := 1;
  Begin
    update mid_kod_songdata a set status_flg = 'P' where status_flg = 'A';
  /*  v_i := 1;
    for c1rec in c1 loop
      update mid_kod_songdata a
         set a.songname_order = v_i,
             a.count          = nvl(a.real_count, 0) + nvl(a.base_count, 0)
       where rowid = c1rec.rid;
      v_i := v_i + 1;
    end loop;
  
    v_i := 1;
    for c2rec in c2 loop
      update mid_kod_songdata a
         set a.singer_order = v_i
       where rowid = c2rec.rid;
      v_i := v_i + 1;
    end loop;
  
    commit;
  */
    v_release_date := null;
    v_cnt          := 0;
    For c3rec In c3 Loop
      if v_cnt <= 149 then
        Update mid_kod_songdata a
           Set a.newsong = 1
         Where Rowid = c3rec.rid;
      else
        Update mid_kod_songdata a
           Set a.newsong = 0
         Where Rowid = c3rec.rid;
      end if;
      v_cnt := v_cnt + 1;
    End Loop;
  
    update mid_kod_songdata set status_flg = 'P' where status_flg = 'A';
  
    Commit;
    DECLARE
      job_no BINARY_INTEGER;
    begin
      DBMS_JOB.SUBMIT(job       => job_no,
                      what      => 'begin dbms_scheduler.run_job(''"IPTV"."MID_KOD_POST_B"''); end;',
                      next_date => sysdate,
                      interval  => null);
      COMMIT;
    end;
  
    Return '';
  End;

  function tgc_cms_cat_post(p_user_no number) return varchar2 Is
  
    exception_msg Varchar2(256);
    app_exception Exception;
    v_status_flg         Varchar2(32);
    v_content_pk_no      number(16);
    v_default_package_id varchar2(32);
    v_syn_id             varchar2(32);
    v_char               varchar2(1);
    v_list_status_flg    varchar2(32);
  
  Begin
  
    declare
      Http_Request Varchar2(30000);
      Http_Respond Varchar2(30000);
      Http_Req     Utl_Http.Req;
      Http_Resp    Utl_Http.Resp;
      v_Sms_Url    Varchar2(10000);
      v_Big5_Text  Varchar2(10000);
      v_Result     Varchar2(256);
    Begin
      v_Sms_Url := epg_url || '/Oracle2Mysqlcat.php';
      Http_Req  := Utl_Http.Begin_Request(v_Sms_Url, 'POST', 'HTTP/1.1');
      Http_Resp := Utl_Http.Get_Response(Http_Req);
      Utl_Http.Read_Text(Http_Resp, Http_Respond);
      Utl_Http.End_Response(Http_Resp);
    End;
  
    v_syn_id := sysapp_util.Get_Mas_No(1, 2, sysdate, 'SYNID', 2);
    update MID_SYN_LOG set SYN_ID = v_syn_id, last_modify = sysdate;
    commit;
    -- epg01

    return null;
  Exception
    When app_exception Then
      Rollback;
      Raise_Application_Error(-20002, Exception_Msg);
      Return(Exception_Msg);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Sqlerrm);
  End;

  procedure cms_content_post(out_msg     out varchar2,
                             p_user_no   Number,
                             p_pk_no     Number,
                             p_no_commit varchar2 default 'N') is
  begin
    update mid_cms_content 
       set status_flg='A'
       where pk_no= p_pk_no;
       
  --  out_msg := tgc_cms_content_check(p_user_no, p_pk_no, p_no_commit);
  --  out_msg := tgc_cms_content_post(p_user_no, p_pk_no, p_no_commit);
  commit;
  end;

  procedure cms_content_list_post(out_msg     out varchar,
                                  p_user_no   Number,
                                  p_cat_id    varchar2,
                                  p_no_commit varchar2 default 'N') is
  begin
    out_msg := tgc_cms_cntlist_post(p_user_no, p_cat_id, p_no_commit);
  end;

  procedure cms_cat_post(out_msg out varchar, p_user_no number) is
  begin
    out_msg := tgc_cms_cat_post(p_user_no);
  end;
  
    procedure cms_kod_7table_post is
  begin
     /* 7 Tables genate */
    begin
      declare
        cursor c1 is
          select no id,
                 decode(guidesing, 1, 'true', 'false') vocal,
                 a.singer singer,
                 decode(a.singertype,1,0,2,1,3,2,4,3,5,4,6,5,5) singer_type,
                 songname title,
                 songnamelength Length_of_title,
                 a.songnamesymbol Title_patten,
                 a.singernamesymbol singer_patten,
                 null singer_last_name,
                 null singer_last_name_stroke,
                 asset_id asset_id,
                 release_date published_date,
                 release_date litv_release_date,
                 a.songname_order,
                 a.singer_order,
                 decode(a.songtype,1,'true','false') org_song
            from mid_kod_songdata a
            where a.status_flg in ('P','A');
        v_char varchar2(1);
        cursor c2 is
          select id from mid_kod_song a where a.id not in (select no from mid_kod_songdata);
      begin
          delete mid_kod_song a;
          commit;
          delete mid_kod_song_language;
          commit;
          delete mid_kod_billboard;
          commit;
          delete mid_kod_song_genre;
          commit;
        for i in c1 loop
          begin
            select 'x' into v_char from mid_kod_song a where a.id = i.id;
            update mid_kod_song a
               set id                      = i.id,
                   vocal                   = i.vocal,
                   singer                  = i.singer,
                   singer_type             = i.singer_type,
                   title                   = i.title,
                   Length_of_title         = i.length_of_title,
                   Title_patten            = i.title_patten,
                   singer_patten           = i.singer_patten,
                   singer_last_name        = i.singer_last_name,
                   singer_last_name_stroke = i.singer_last_name,
                   asset_id                = i.asset_id,
                   published_date          = i.published_date,
                   litv_release_date       = i.litv_release_date,
                   song_big5_sort       = i.songname_order,
                   singer_big5_sort      = i.singer_order,
                   a.original_video      = i.org_song
             where a.id = i.id;
          exception
            when no_data_found then
              insert into mid_kod_song
                (id,
                 vocal,
                 singer,
                 title,
                 length_of_title,
                 title_patten,
                 singer_type,
                 singer_patten,
                 singer_last_name,
                 singer_last_name_stroke,
                 asset_id,
                 published_date,
                 litv_release_date,
                 song_big5_sort,
                 singer_big5_sort,
                 original_video)
              values
                (i.id,
                 i.vocal,
                 i.singer,
                 i.title,
                 i.length_of_title,
                 i.title_patten,
                 i.singer_type,
                 i.singer_patten,
                 i.singer_last_name,
                 i.singer_last_name_stroke,
                 i.asset_id,
                 i.published_date,
                 i.litv_release_date,
                 i.songname_order,
                 i.singer_order,
                 i.org_song);
          end;
          commit;
        
        end loop;
      end;
    
      declare
        cursor c1 is
          select no song_id, decode(a.songclass,1,0,2,1,3,3,4,4,5,2,8,6,7,5,8) lang_id from mid_kod_songdata a where a.status_flg in ('P','A');
        v_char varchar2(1);
       v_lang_id number(16);
      begin
        for i in c1 loop
          begin
           
            select a.lang_id
              into v_lang_id
              from mid_kod_song_language a
             where a.song_id = i.song_id;
             if v_lang_id <> i.lang_id then
            update mid_kod_song_language a
               set a.lang_id = i.lang_id
             where a.song_id = i.song_id;
             end if;
          
          exception
            when no_data_found then
              insert into mid_kod_song_language
                (song_id, lang_id)
              values
                (i.song_id, i.lang_id);
          end;
          commit;
        end loop;
      end;
    
      -- LiTV排行
      declare
        cursor c1 is
          select no song_id, 1 type_id, count from mid_kod_songdata a;
        v_char varchar2(1);
      begin
         delete mid_kod_billboard where type_id=0;
        for i in c1 loop
          begin
            select 'x'
              into v_char
              from mid_kod_billboard a
             where a.song_id = i.song_id;
            update mid_kod_billboard a
               set a.type_id = i.type_id, a.value = i.count
             where a.song_id = i.song_id;
          
          exception
            when no_data_found then
              insert into mid_kod_billboard
                (song_id, type_id, value)
              values
                (i.song_id, i.type_id, i.count);
          end;
          commit;
        end loop;
      end;
    
      -- 國語排行     
      
        declare
        cursor c1 is
          select * from (select no song_id, 1 type_id, count from mid_kod_songdata a where songclass=1 order by count desc) where rownum <=150 ;
        v_char varchar2(1);
      begin
        delete mid_kod_billboard where type_id=1;
      
        for i in c1 loop

              insert into mid_kod_billboard
                (song_id, type_id, value)
              values
                (i.song_id, i.type_id, i.count);

          commit;
        end loop;
      end;
  
  
       --台語排行
               declare
        cursor c1 is
          select * from ( select no song_id, 2 type_id, count from mid_kod_songdata a where songclass=2 order by count desc) where rownum <=150 ;
        v_char varchar2(1);
      begin
          delete mid_kod_billboard where type_id=2;
        for i in c1 loop
              insert into mid_kod_billboard
                (song_id, type_id, value)
              values
                (i.song_id, i.type_id, i.count);
          commit;
        end loop;
      end;

      declare
        cursor c1 is
          select no song_id, 8 genre_id
            from mid_kod_songdata a
           where a.specialclass = 'STAR' and a.status_flg in ('P','A')
          union all
          select no song_id, 2 genre_id
            from mid_kod_songdata a
           where a.specialclass = 'HYMN'and a.status_flg in ('P','A')   
          union all
          select no song_id, 3 genre_id
            from mid_kod_songdata a
           where a.songclass = 6 and a.status_flg in ('P','A')
          
         union all
          select no song_id, 11 genre_id
            from mid_kod_songdata a
           where (a.tag like '%甜蜜%' and a.tag like '%情歌%')  and a.status_flg in ('P','A')

         union all
          select no song_id, 12 genre_id
            from mid_kod_songdata a
           where (a.tag like '%悲傷%' and a.tag like '%情歌%')  and a.status_flg in ('P','A')
           
         union all
          select no song_id, 13 genre_id
            from mid_kod_songdata a
           where (a.tag like '%情歌%' and a.singertype =4)  and a.status_flg in ('P','A')           
           
         union all
          select no song_id, 14 genre_id
            from mid_kod_songdata a
           where (a.tag like '%電視%' or a.tag like '%電影%' or a.tag like '%廣告%')  and a.status_flg in ('P','A')
           
         union all
          select no song_id, 15 genre_id
            from mid_kod_songdata a
           where (a.tag like '%活力勁歌%')  and a.status_flg in ('P','A') 
           
         union all
          select no song_id, 16 genre_id
            from mid_kod_songdata a
           where (a.tag like '%搖滾%')  and a.status_flg in ('P','A') 
           
         union all
          select no song_id, 6 genre_id
            from mid_kod_songdata a
           where (a.tag like '%懷舊%')  and a.status_flg in ('P','A') 

         union all
          select no song_id, 0 genre_id
            from mid_kod_songdata a
           where (a.tag like '%節日%')  and a.status_flg in ('P','A') 
           
         union all
          select no song_id, 17 genre_id
            from mid_kod_songdata a
           where (a.tag like '%勵志%')  and a.status_flg in ('P','A') ;                                            
                               
           
        v_char varchar2(1);
      begin
        for i in c1 loop
          begin
            select 'x'
              into v_char
              from mid_kod_song_genre a
             where a.song_id = i.song_id
               and a.genre_id = i.genre_id;
/*            update mid_kod_song_genre a
               set a.genre_id = i.genre_id
             where a.song_id = i.song_id;*/
          
          exception
            when no_data_found then
              insert into mid_kod_song_genre
                (song_id, genre_id)
              values
                (i.song_id, i.genre_id);
          end;
          commit;
        end loop;
      end;
    end;
    
  end;


  procedure cms_vod_tag_proc(p_content_id varchar2) is
    v_tag  varchar2(1024);
    v_ref2 varchar2(1024);
    v_ref3 varchar2(1024);
    v_char varchar2(1);
    cursor c2(str varchar2) is
      select regexp_substr(str, '[^,/]+', 1, level) cid
        from dual
      connect by regexp_substr(str, '[^,/]+', 1, level) is not null;
  begin
    select ref2,ref3
      into v_ref2,v_ref3
      from mid_cms_content
     where content_id = p_content_id;
    declare
      v_tag    varchar2(1024);
      v_region varchar2(1024);
    begin
      v_tag := '<所有><ALL>';
      if v_ref3 is not null then
         v_tag :=v_tag||'<得獎><AWARD>';
      end if;
      
      begin
        select 'x' into v_char from mid_content_list a where cat in ('MOVIE','HD') and content_id = p_content_id and a.no < 20 and rownum <=1;
        v_tag :=v_tag||'<熱門><HOT>';  
      exception
         when no_data_found then null;
      end;
      
      begin
        select 'x' into v_char from mid_content_list a where cat in ('MOVIE','HD') and content_id = p_content_id and a.no < 3 and rownum <=1;
        v_tag :=v_tag||'<NEW>';  
      exception
         when no_data_found then null;
      end;
    
      for i in c2(v_ref2) loop
        begin
          select region
            into v_region
            from mid_cms_content_country
           where id = i.cid;
        exception
          when no_data_found then
            v_region := null;
        end;
      
        if (not instr(v_tag, v_region) > 0) then
          v_tag := v_tag || ',<' || v_region || '>';
        end if;
      end loop;
      update mid_cms_content
         set tag = v_tag
       where content_id = p_content_id;
      commit;
    end;
  
  end;

begin
  select link_set.link_set.epg_server_url,
         link_set.link_set.epg_server_url_s
    into epg_url, epg_url_s
    from dual;

END;
/

