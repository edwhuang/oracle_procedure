CREATE OR REPLACE PACKAGE BODY IPTV."MFG_POST" is


  function MFG_SGSET_POST(p_user_no   Number,p_pk_no     Number, p_no_commit varchar2 default 'N')  return varchar2
  Is
     msg Varchar2(256);
     app_exception Exception;
     v_status_flg varchar2(32);
     v_softgroup varchar2(32);
     v_vod_group varchar2(32);
     v_ref1 varchar2(256);

     Cursor c1 Is Select pk_no,mac_address from mfg_sgset_item where mas_pk_no = p_pk_no;
  Begin
    Begin
       Select status_flg ,a.software_group,a.vod_group,a.ref1
         Into v_status_flg,v_softgroup,v_vod_group,v_ref1
          From mfg_sgset_mas a
         Where pk_no = p_pk_no;
    Exception
       When no_data_found Then
            msg:= '#找不到單據資料#';
            Raise app_exception;
     End;
        If v_status_flg <> 'A' Then
           msg:= '#單據狀態不正確#';
           Raise app_exception;
        End If;


        For c1rec In c1 Loop
            declare
               v_softgrp varchar2(32);
            begin
              select a.software_group into v_softgrp from mfg_iptv_mas a where mac_address= c1rec.mac_address;
              if v_softgroup is not null then
                 update mfg_sgset_item a
                    set a.current_softgroup= v_softgrp,
                        a.new_group=v_softgroup,
                        a.status = 'A'
                  where a.pk_no = c1rec.pk_no;
               end if;
               
               if v_vod_group is not null then
                 update mfg_sgset_item a
                    set a.new_vod_group=v_vod_group,
                        a.status = 'A'
                  where a.pk_no = c1rec.pk_no;
               end if;
               
               if v_ref1 is not null then
                 update mfg_sgset_item a
                    set a.ref1=v_ref1,
                        a.status = 'A'
                  where a.pk_no = c1rec.pk_no;
               end if;


            exception
              when no_data_found then
                   msg := '#沒有生產此MAC號碼#';
                 Raise app_exception;
            end;

        End Loop;

        Update mfg_sgset_mas
            Set status_flg ='P'
         Where pk_no = p_pk_no;

         Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date, User_No, Event_Type, Seq_No,Description)
               Values  ('MFGSGSET', p_pk_no, Sysdate, p_User_No, 'Post', Sys_Event_Seq.Nextval,  'post');

  -- if p_no_commit = 'N' then
      Commit;
 --  end if;
   Return Null;

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Msg);
          Return(Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;
   
  function MFG_SGSET_UNPOST(p_user_no   Number,p_pk_no     Number, p_no_commit varchar2 default 'N')  return varchar2
  Is
     msg Varchar2(256);
     app_exception Exception;
     v_status_flg varchar2(32);
     v_softgroup varchar2(32);
  Begin
    Begin
       Select status_flg ,a.software_group Into v_status_flg,v_softgroup
          From mfg_sgset_mas a
         Where pk_no = p_pk_no;
    Exception
       When no_data_found Then
            msg:= '#找不到單據資料#';
            Raise app_exception;
     End;
     If v_status_flg <> 'P' Then
        msg:= '#單據狀態不正確#';
        Raise app_exception;
     End If;
     
   Update mfg_sgset_mas
      Set status_flg ='A'
    Where pk_no = p_pk_no;

    Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date, User_No, Event_Type, Seq_No,Description)
         Values  ('MFGSGSET', p_pk_no, Sysdate, p_User_No, 'Post', Sys_Event_Seq.Nextval,  'unpost');

   if p_no_commit = 'N' then
      Commit;
   end if;
   Return Null;

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Msg);
          Return(Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;
   
  function MFG_SGSET_Complete(p_user_no   Number,p_pk_no     Number, p_no_commit varchar2 default 'N')  return varchar2
  Is
     msg Varchar2(256);
     app_exception Exception;
     v_status_flg varchar2(32);
     v_softgroup varchar2(32);
     v_vod_group varchar2(32);
     v_ref1 varchar2(256);
     
     v_iptv_status_flg varchar2(32);
     v_msg varchar2(1024);
    

     Cursor c1 Is Select pk_no,mac_address,b.new_group,b.new_vod_group,b.ref1
                    from mfg_sgset_item b where mas_pk_no = p_pk_no and status='A';

  Begin
    Begin
       Select status_flg ,a.software_group,a.vod_group,a.ref1
         Into v_status_flg,v_softgroup,v_vod_group,v_ref1
          From mfg_sgset_mas a
         Where pk_no = p_pk_no;
    Exception
       When no_data_found Then
            msg:= '#找不到單據資料#';
            Raise app_exception;
    End;
    
    If v_status_flg <> 'P' Then
       msg:= '#單據狀態不正確#';
       Raise app_exception;
    End If;

    For c1rec In c1 Loop
        if c1rec.new_group is not null then
           update mfg_iptv_mas a
              set a.software_group = c1rec.new_group,
                  a.status_flg='R'
            where a.mac_address= c1rec.mac_address;
        end if;
        
        if c1rec.new_vod_group is not null then
           update bsm_client_mas a
              set a.vod_cat_group = c1rec.new_vod_group
            where mac_address=c1rec.mac_address;
        end if;
        
        if c1rec.ref1 is not null then
           update mfg_iptv_mas a
             set a.ref1 = c1rec.ref1
            where mac_address=c1rec.mac_address;
            
            v_msg :=cms_cnt_post.tgc_cms_cat_post(p_user_no);
        end if;
         
             
        update mfg_sgset_item a
           set a.status='N'
         where a.pk_no = c1rec.pk_no;
    End Loop;
        
    begin
       select status_flg into v_iptv_status_flg
         from mfg_iptv_mas a
        where a.mac_address in (select mac_address from mfg_sgset_item where mas_pk_no = p_pk_no
          and status ='A')
          and rownum <=1 ;
    exception 
         when no_data_found then
       Update mfg_sgset_mas
          Set status_flg ='N'
        Where pk_no = p_pk_no;
       Insert Into Sysevent_Log(App_Code, Pk_No, Event_Date, User_No, Event_Type, Seq_No,Description)
       Values ('MFGSGSET', p_pk_no, Sysdate, p_User_No, 'Complete', Sys_Event_Seq.Nextval,  'Complete');

          if p_no_commit = 'N' then
             Commit;
          end if;
     end;
     
     Return Null;

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Msg);
          Return(Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;
  
     
end;
/

