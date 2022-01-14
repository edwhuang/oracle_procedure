CREATE OR REPLACE PACKAGE BODY IPTV."SYSAPP_UTIL" Is
  /*
    Function Get_Pk_No Return Number Is
      Result Number(16);
    Begin
      Select Ew_Syspk.Nextval Into Result From Dual;
      Return(Result);
    End Get_Pk_No;
  
    Function Get_Mas_No(p_Org_No   Number,
                        p_Loc_No   Number,
                        p_Mas_Date Date,
                        p_Doc_Code Varchar2,
                        p_Pk_No    Number) Return Varchar2 Is
      Result    Varchar(32);
      v_Max_No  Number(16);
      v_Format  Varchar2(16);
      v_Sn_Leng Varchar2(16);
      v_Prefix  Varchar2(16);
    Begin
      Select Format, Prefix, Sn_Leng
        Into v_Format, v_Prefix, v_Sn_Leng
        From Ew_Sysctl_Mas
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And Doc_Code = p_Doc_Code;
  
      If v_Format Is Not Null Then
        v_Format := To_Char(p_Mas_Date, v_Format);
      End If;
  
      If v_prefix Is Not Null Then
        v_Format := v_prefix||v_Format;
      End If;
  
      Begin
        Select Max_No
          Into v_Max_No
          From Ew_Sysctl_Dtl a
         Where a.Org_No = p_Org_No
           And Loc_No = p_Loc_No
           And Doc_Code = p_Doc_Code
           And Sub_Grp = v_Format
           For Update;
      Exception
        When No_Data_Found Then
          v_Max_No := 0;
          Insert Into Ew_Sysctl_Dtl
            (Org_No, Loc_No, Doc_Code, Max_No, Sub_Grp)
          Values
            (p_Org_No, p_Loc_No, p_Doc_Code, v_Max_No, v_Format);
      End;
      v_Max_No := v_Max_No + 1;
  
      Result := v_Format || Lpad(v_Max_No, v_Sn_Leng, '0');
  
      Update Ew_Sysctl_Dtl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And Doc_Code = p_Doc_Code
         And Sub_Grp = v_Format;
  
      Insert Into Ew_Sysno_Mas
        (Pk_No, Src_Pk_No, Src_Doc_Code, Src_Mas_No, Status_Flg)
      Values
        (Get_Pk_No, p_Pk_No, p_Doc_Code, Result, 'A');
  
      Return(Result);
  
    End Get_Mas_No;
  */
  Function Get_Form_Msg(p_App_Code  Varchar2,
                        p_Lang      Varchar2,
                        p_Msg_Type  Varchar2,
                        p_Msg_Code  Number,
                        p_Msg_Text  Varchar2,
                        p_dbms_Text Varchar2 Default Null) Return Varchar2 Is
    v_Lang_Text Varchar2(2000);
    v_Msg_text  Varchar2(2000);
  Begin
    If p_Msg_code In (40735) Then
      v_Msg_text := p_Msg_Text || ' ' || p_dbms_text;
    Else
      v_Msg_text := p_Msg_text;
    End If;
  
    Begin
      Select Lang_Text
        Into v_Lang_Text
        From Ew_Syslang_Msg
       Where App_Code = p_App_Code
         And Lang = p_Lang
         And Msg_Type = p_Msg_Type
         And Msg_Code = p_Msg_Code
         And Msg_Text = v_Msg_Text;
    Exception
      When No_Data_Found Then
        Begin
          Select Lang_Text
            Into v_Lang_Text
            From Ew_Syslang_Msg
           Where App_Code = p_App_Code
             And Lang = 'DEFAULT'
             And Msg_Type = p_Msg_Type
             And Msg_Code = p_Msg_Code
             And Msg_Text = v_Msg_Text;
        Exception
          When No_Data_Found Then
            v_Lang_Text := p_Msg_Type || '-' || To_Char(p_Msg_Code) || ' ' ||
                           v_Msg_Text;
            /*       Rollback;
                        Insert Into Ew_Syslang_Msg
                          (App_Code, Lang, Msg_Type, Msg_Code, Msg_Text, Lang_Text)
                        Values
                          (p_App_Code, p_Lang,  p_Msg_Type,  p_Msg_Code,  p_Msg_Text,  v_Lang_Text);
            
                        Insert Into Ew_Syslang_Msg
                          (App_Code, Lang, Msg_Type, Msg_Code, Msg_Text, Lang_Text)
                        Values
                          (p_App_Code,'DEFAULT', p_Msg_Type, p_Msg_Code, p_Msg_Text,  v_Lang_Text);
                        Commit;
            */
        End;
      
    End;
  
    If instr(v_Lang_text, '#') > 0 Then
      v_Lang_Text := substr(v_Lang_text,
                            instr(v_Lang_text, '#') + 1,
                            length(v_Lang_text));
      v_Lang_Text := substr(v_Lang_text, 1, instr(v_Lang_text, '#') - 1);
    End If;
    Return(v_Lang_Text);
  End Get_Form_Msg;

  
  
  Function get_mas_no(p_Org_No   Number,
                      p_Loc_No   Number,
                      p_Mas_Date Date,
                      p_Doc_Code Varchar2,
                      p_Pk_No    Number,
                      prefix_no  varchar) Return Varchar2 Is
    v_Result  Varchar(32);
    v_Max_No  Number(16);
    v_Format  Varchar2(16);
    v_Sn_Leng Varchar2(16);
    v_Prefix  Varchar2(16);
    app_error Exception;
    msg          Varchar2(128);
    v_status_flg Varchar2(32);
  Begin
    If p_Doc_Code In ('TGCORDER', 'TGCDISPATCH') Then
      Begin
        Select status_flg
          Into v_status_flg
          From acc_period_mas a
         Where a.start_date <= p_mas_date
           And a.end_date + 1 > p_mas_date
           And rownum <= 1;
        If v_status_flg <> 'O' Then
          msg := '#已關帳#';
          Raise app_error;
        End If;
      
      Exception
        When no_data_found Then
          msg := '#錯誤的單據日期#';
          Raise app_error;
      End;
    
    End If;
  
    Begin
      Select no_Format, Prefix, no_Leng, Max_no
        Into v_Format, v_Prefix, v_Sn_Leng, v_mAX_NO
        From Sysno_ctl
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code
         For Update;
    Exception
      When No_Data_Found Then
        v_Max_No := 0;
        Insert Into Sysno_ctl
          (Org_No, Loc_No, mas_Code, Max_No, no_format, no_leng)
        Values
          (p_Org_No, p_Loc_No, p_Doc_Code, v_Max_No, v_Format, v_Sn_leng);
    End;
  
    If v_Format Is Not Null Then
      v_Format := To_Char(p_Mas_Date, v_Format);
      Begin
        Select Max_no
          Into v_Max_no
          From sysno_ctl
         Where org_no = p_Org_No
           And loc_no = p_loc_no
           And mas_code = p_Doc_Code || '_MAX'
           And no_format = v_format
           For Update;
      Exception
        When no_data_found Then
          v_Max_No := 0;
          Insert Into Sysno_ctl
            (Org_No, Loc_No, mas_Code, Max_No, no_format, no_leng)
          Values
            (p_Org_No,
             p_Loc_No,
             p_Doc_Code || '_MAX',
             v_Max_No,
             v_Format,
             v_Sn_Leng);
      End;
    elsif prefix_no is not null then
      begin
        Select Max_no
          Into v_Max_no
          From sysno_ctl
         Where org_no = p_Org_No
           And loc_no = p_loc_no
           And mas_code = p_Doc_Code || prefix_no || '_MAX'
           For Update;
      exception
        When no_data_found Then
          v_Max_No := 0;
          Insert Into Sysno_ctl
            (Org_No, Loc_No, mas_Code, Max_No, no_format, no_leng)
          Values
            (p_Org_No,
             p_Loc_No,
             p_Doc_Code || prefix_no || '_MAX',
             v_Max_No,
             v_Format,
             v_Sn_Leng);
      End;
    end if;
  
    v_Max_No := v_Max_No + 1;
  
    v_Result := prefix_no || v_prefix || v_Format ||
                Lpad(v_Max_No, v_Sn_Leng, '0');
    If v_format Is not Null Then
      Update Sysno_ctl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code || '_MAX'
         And no_format = v_format;
    
    Elsif prefix_no is not null then
      Update Sysno_ctl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code || prefix_no || '_MAX';
    
    else
      Update Sysno_ctl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code;
    
    End If;
  
    Return(v_Result);
  Exception
    When App_error Then
      Rollback;
      Raise_Application_Error(-20002, Msg);
      Return(Null);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Null);
  End Get_Mas_No;
  
  Function get_mas_no(p_Org_No   Number,
                      p_Loc_No   Number,
                      p_Mas_Date Date,
                      p_Doc_Code Varchar2,
                      p_Pk_No    Number
                     ) Return Varchar2 Is
    v_Result  Varchar(32);
    v_Max_No  Number(16);
    v_Format  Varchar2(16);
    v_Sn_Leng Varchar2(16);
    v_Prefix  Varchar2(16);
    app_error Exception;
    msg          Varchar2(128);
    v_status_flg Varchar2(32);
     prefix_no  varchar(32) default null;
  Begin
    prefix_no := null;
    If p_Doc_Code In ('TGCORDER', 'TGCDISPATCH') Then
      Begin
        Select status_flg
          Into v_status_flg
          From acc_period_mas a
         Where a.start_date <= p_mas_date
           And a.end_date + 1 > p_mas_date
           And rownum <= 1;
        If v_status_flg <> 'O' Then
          msg := '#已關帳#';
          Raise app_error;
        End If;
      
      Exception
        When no_data_found Then
          msg := '#錯誤的單據日期#';
          Raise app_error;
      End;
    
    End If;
  
    Begin
      Select no_Format, Prefix, no_Leng, Max_no
        Into v_Format, v_Prefix, v_Sn_Leng, v_mAX_NO
        From Sysno_ctl
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code
         For Update;
    Exception
      When No_Data_Found Then
        v_Max_No := 0;
        Insert Into Sysno_ctl
          (Org_No, Loc_No, mas_Code, Max_No, no_format, no_leng)
        Values
          (p_Org_No, p_Loc_No, p_Doc_Code, v_Max_No, v_Format, v_Sn_leng);
    End;
  
    If v_Format Is Not Null Then
      v_Format := To_Char(p_Mas_Date, v_Format);
      Begin
        Select Max_no
          Into v_Max_no
          From sysno_ctl
         Where org_no = p_Org_No
           And loc_no = p_loc_no
           And mas_code = p_Doc_Code || '_MAX'
           And no_format = v_format
           For Update;
      Exception
        When no_data_found Then
          Insert Into Sysno_ctl
            (Org_No, Loc_No, mas_Code, Max_No, no_format, no_leng)
          Values
            (p_Org_No,
             p_Loc_No,
             p_Doc_Code || '_MAX',
             v_Max_No,
             v_Format,
             v_Sn_Leng);
      End;
    elsif prefix_no is not null then
      begin
        Select Max_no
          Into v_Max_no
          From sysno_ctl
         Where org_no = p_Org_No
           And loc_no = p_loc_no
           And mas_code = p_Doc_Code || prefix_no || '_MAX'
           For Update;
      exception
        When no_data_found Then
          Insert Into Sysno_ctl
            (Org_No, Loc_No, mas_Code, Max_No, no_format, no_leng)
          Values
            (p_Org_No,
             p_Loc_No,
             p_Doc_Code || prefix_no || '_MAX',
             v_Max_No,
             v_Format,
             v_Sn_Leng);
      End;
    end if;
  
    v_Max_No := v_Max_No + 1;
  
    v_Result := prefix_no || v_prefix || v_Format ||
                Lpad(v_Max_No, v_Sn_Leng, '0');
    If v_format Is not Null Then
      Update Sysno_ctl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code || '_MAX'
         And no_format = v_format;
    
    Elsif prefix_no is not null then
      Update Sysno_ctl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code || prefix_no || '_MAX';
    
    else
      Update Sysno_ctl
         Set Max_No = v_Max_No
       Where Org_No = p_Org_No
         And Loc_No = p_Loc_No
         And mas_Code = p_Doc_Code;
    
    End If;
  
    Return(v_Result);
  Exception
    When App_error Then
      Rollback;
      Raise_Application_Error(-20002, Msg);
      Return(Null);
    When Others Then
      Rollback;
      Raise_Application_Error(-20002, Sqlerrm);
      Return(Null);
  End Get_Mas_No;

  
  Procedure set_todo_list(p_user_no  Number,
                          p_message  Varchar2,
                          p_app_code Varchar2,
                          p_pk_no    Number,
                          alt_time   Date Default Null) Is
    Cursor c1 Is
      Select user_no
        From sys_user_group
      Connect By Prior user_no = group_no
       Start With group_no = p_user_no;
    v_char    Varchar2(1);
    v_message Varchar(512);
  Begin
    -- Delete All Status in todo
    Delete sys_todo_list Where pk_no = p_pk_no;
  
    Begin
      Select 'G' Into v_char From sys_group_mas Where group_no = p_user_no;
    Exception
      When no_data_found Then
        v_char := 'U';
    End;
  
    v_message := p_message || ' ,' || get_form_info(p_app_code, p_pk_no);
  
    If v_char = 'G' Then
      For i In c1 Loop
        Insert Into sys_todo_list
          (seq_no,
           create_date,
           user_no,
           message,
           app_code,
           pk_no,
           visited,
           status_flg,
           next_alt_time)
        Values
          (sys_event_seq.nextval,
           Sysdate,
           i.user_no,
           v_message,
           p_app_code,
           p_pk_no,
           'N',
           'A',
           alt_time);
      End Loop;
    Elsif v_char = 'U' Then
      Insert Into sys_todo_list
        (seq_no,
         create_date,
         user_no,
         message,
         app_code,
         pk_no,
         visited,
         status_flg,
         next_alt_time)
      Values
        (sys_event_seq.nextval,
         Sysdate,
         p_user_no,
         v_message,
         p_app_code,
         p_pk_no,
         'N',
         'A',
         alt_time);
    End If;
  End;

  Procedure Set_todo_list(p_user_id  Varchar2,
                          p_message  Varchar2,
                          p_app_code Varchar2,
                          p_pk_no    Number,
                          alt_time   Date Default Null) Is
    p_user_no Number(16);
  Begin
    If p_user_id Is Not Null Then
      Begin
        Select group_no
          Into p_user_no
          From sys_group_mas
         Where group_id = p_user_id;
      Exception
        When no_data_found Then
          Begin
            Select user_no
              Into p_user_no
              From sys_user
             Where user_name = p_user_id;
          Exception
            When no_data_found Then
              Raise_application_error(-20000,
                                      '#找不到此代號' || p_user_id || '#');
              p_user_no := Null;
          End;
        
      End;
      If p_user_no Is Not Null Then
        Set_todo_list(p_user_no, p_message, p_app_code, p_pk_no);
      End If;
    
    End If;
  End;

  Procedure clear_todo_list(p_user_no  Number,
                            p_message  Varchar2,
                            p_app_code Varchar2,
                            p_pk_no    Number) Is
    Cursor c1 Is
      Select user_no
        From sys_user_group
      Connect By Prior user_no = group_no
       Start With group_no = p_user_no;
    v_char Varchar2(1);
  Begin
    -- Delete All Status in todo
    Delete sys_todo_list Where pk_no = p_pk_no;
  End;

  Procedure clear_todo_list_visited(p_user_no Number,
                                    p_pk_no   Number Default Null) Is
  Begin
    If p_pk_no Is Null Then
      Update sys_todo_list
         Set visited = 'Y'
       Where user_no = p_user_no
         And nvl(visited, 'N') <> 'Y'
         And next_alt_time Is Null;
    Else
      Update sys_todo_list
         Set Visited = 'Y'
       Where user_no = p_user_no
         And nvl(visited, 'N') <> 'Y'
         And pk_no = pk_no;
    End If;
    Commit;
  End;

  Procedure set_todo_list_post(p_user_no Number, p_pk_no Number) Is
  Begin
    Update sys_todo_list
       Set status_flg = 'P'
     Where user_no = p_user_no
       And pk_no = p_pk_no;
  
    Commit;
  End;

  Function get_sys_value(p_App_Code      Varchar2,
                         p_Val_Code      Varchar2,
                         p_Default_Value Varchar2 Default Null)
    Return Varchar2 Is
    v_Result Varchar2(32);
  Begin
    Select Sys_Value
      Into v_Result
      From Sys_Defval
     Where App_Code = p_App_Code
       And Val_Code = p_Val_Code;
    Return v_Result;
  Exception
    When No_Data_Found Then
      insert into sys_defval
        (app_code, val_code, default_value, sys_value, description)
      values
        (p_app_code,
         p_val_code,
         p_default_value,
         p_default_value,
         p_val_code);
      Commit;
      Return p_Default_Value;
  End;

  Function get_form_info(p_App_code Varchar2, p_pk_no Number) Return Varchar2 Is
    res           Varchar2(512);
    v_cust_id     Varchar2(128);
    v_cust_name   Varchar2(128);
    v_mas_no      Varchar2(128);
    v_mas_date    Varchar(128);
    v_order_type  Varchar2(128);
    v_create_type Varchar2(128);
    v_process_sts Varchar2(128);
  Begin
    If p_app_code = 'TGCORDER' Then
      Select cust_id,
             order_id,
             to_char(order_create_date, 'YYYY/MM/DD'),
             order_type,
             create_type,
             process_sts
        Into v_cust_id,
             v_mas_no,
             v_mas_date,
             v_order_type,
             v_create_type,
             v_process_sts
        From tgc_order
       Where order_no = p_pk_no;
    
      Select cust_name
        Into v_cust_name
        From tgc_customer
       Where cust_id = v_cust_id;
    
      --  res := '('||v_cust_id||' '||v_cust_name||','||v_order_type||','||v_mas_date||','||v_mas_no||')';
      res := v_mas_date || ',' || v_create_type || ',' || v_cust_name || ',' ||
             tgc_util.get_order_type_name(v_order_type) || ',' ||
             tgc_util.get_process_name(v_process_sts);
    
    Elsif p_app_code = 'TGCDISPATCH' Then
      Select cust_id,
             dispatch_id,
             to_char(create_date, 'YYYY/MM/DD'),
             dispatch_type
        Into v_cust_id, v_mas_no, v_mas_date, v_order_type
        From tgc_dispatch_info
       Where dispatch_no = p_pk_no;
    
      Select cust_name
        Into v_cust_name
        From tgc_customer
       Where cust_id = v_cust_id;
    
      res := '(' || v_cust_id || ' ' || v_cust_name || ',' || v_order_type || ',' ||
             v_mas_date || ',' || v_mas_no || ')';
    End If;
    Return res;
  
  End;

   procedure set_event_log(p_app_code   varchar2,
                          p_pk_no      number,
                          p_user_no    number,
                          p_event_type varchar2,
                          p_desc       varchar2,
                          p_log clob default null) is
  begin
    insert into sysevent_log
      (seq_no,
       app_code,
       pk_no,
       user_no,
       event_date,
       event_type,
       description,
       log)
    values
      (sys_event_seq.nextval,
       p_app_code,
       p_pk_no,
       p_user_no,
       sysdate,
       p_event_type,
       p_desc,
       p_log);
  end;

  /*
    Function Get_Doc_Code(p_Pk_No Number) Return Varchar2 Is
      Result Varchar2(16);
    Begin
      Select Src_Doc_Code
        Into Result
        From Ew_Sysno_Mas
       Where Src_Pk_No = p_Pk_No;
      Return(Result);
    End Get_Doc_Code;
  
    Function Get_App_Code(p_Pk_No Number) Return Varchar2 Is
      Result     Varchar2(16);
      v_Doc_Code Varchar2(16);
    Begin
      Select Src_Doc_Code
        Into v_Doc_Code
        From Ew_Sysno_Mas
       Where Src_Pk_No = p_Pk_No;
      Select App_Code
        Into Result
        From Ew_Sysapp_Mas
       Where Doc_Code = v_Doc_Code;
      Return(Result);
    Exception
      When No_Data_Found Then
        Raise_Application_Error(-2000, '嚙賣��嚙踝蕭��蕭嚙踝蕭��嚙賣��嚙踝蕭嚙賡��嚙踝蕭嚙�');
    End;
  
    Function Get_Win_Title(p_App_Code Varchar2) Return Varchar2 Is
      Result        Varchar2(2000);
      v_App_No      Number;
      v_App_Code    Varchar2(16);
      v_Description Varchar2(200);
    Begin
      Select a.App_No, a.App_Code, a.Description
        Into v_App_No, v_App_Code, v_Description
        From Ew_Sysapp_Mas a
       Where App_Code = p_App_Code;
      Result := To_Char(v_App_No) || ' ' || 'APP_CODE : ' || p_App_Code || ' ' ||
                v_Description;
      Return(Result);
    End;
  
    Function get_org_name(p_org_no Number) Return Varchar2 Is
     Result Varchar2(2000);
     Begin
       Select name Into Result From org_mas Where org_no = p_org_no;
       Return Result;
     Exception
       When no_data_found Then
       Return Null;
     End;
  
      Function get_org_TEL(p_org_no Number) Return Varchar2 Is
     Result Varchar2(2000);
     Begin
       Select TEL Into Result From org_mas Where org_no = p_org_no;
       Return Result;
     Exception
       When no_data_found Then
       Return Null;
     End;
  
      Function get_org_ADDR(p_org_no Number) Return Varchar2 Is
     Result Varchar2(2000);
     Begin
       Select ADDRESS Into Result From org_mas Where org_no = p_org_no;
       Return Result;
     Exception
       When no_data_found Then
       Return Null;
     End;
  
    Procedure Set_App_Code(p_App_Code    Varchar2,
                           p_Doc_Code    Varchar2,
                           p_Description Varchar2) Is
      v_Char Varchar2(16);
    Begin
      Select 'x' Into v_Char From Ew_Sysapp_Mas Where App_Code = p_App_Code;
    Exception
      When No_Data_Found Then
        Insert Into Ew_Sysapp_Mas
          (App_No, App_Code, Doc_Code, Description, Def_Grp_Code, Grp_Code)
        Values
          (Get_Pk_No,
           p_App_Code,
           p_Doc_Code,
           p_Description,
           'SYSTEM',
           'SYSTEM');
        Commit;
  
    End;
  
    Procedure Set_Form_Status(p_Pk_No Number, p_Status_Flg Varchar2) Is
    Begin
      Update Ew_Sysno_Mas
         Set Status_Flg = p_Status_Flg
       Where Src_Pk_No = Pk_No;
    End;
    Procedure Set_Form_Item(p_Lang         Varchar2,
                            p_App_Code     Varchar2,
                            p_Block        Varchar2,
                            p_Item         Varchar2,
                            p_Default_Text Varchar2) Is
      v_Char Char(1);
    Begin
      Begin
        Select 'x' Into v_char
          From Ew_Syslang_Lab
         Where Lab_Type = 'ITEM'
           And App_Code = p_App_Code
           And Sub_Code = p_Block || '.' || p_Item
           And Lang = p_Lang;
      Exception
        When No_Data_Found Then
  
  
          Insert Into Ew_Syslang_Lab
            (Lang, Lab_Type, App_Code, Sub_Code, Src_Text, Lang_Text)
          Values
            (p_Lang,
             'ITEM',
             p_App_Code,
             p_Block || '.' || p_Item,
             p_Default_Text,
             p_Default_Text);
  
          Commit;
      End;
  
      Begin
  
        Select 'x' Into v_char
          From Ew_Syslang_Lab
         Where Lab_Type = 'ITEM'
           And App_Code = p_App_Code
           And Sub_Code = p_Block || '.' || p_Item
           And Lang = 'DEFAULT';
      Exception
        When No_Data_Found Then
          Insert Into Ew_Syslang_Lab
            (Lang, Lab_Type, App_Code, Sub_Code, Src_Text, Lang_Text)
          Values
            ('DEFAULT',
             'ITEM',
             p_App_Code,
             p_Block || '.' || p_Item,
             p_Default_Text,
             p_Default_Text);
  
          Commit;
      End;
    End Set_Form_Item;
  */
  Function Get_User_Priv(p_App_Code Varchar2,
                         p_User_No  Number,
                         p_Priv_Id  Varchar2,
                         p_Desc     Varchar2) Return Varchar2 Is
    v_Char      Varchar2(1);
    v_Admin_Flg Varchar2(1);
  Begin
    -- check sys_priv_mas
    Select 'x'
      Into v_Char
      From Sys_Priv_Mas
     Where App_Code = p_App_Code
       And Priv_Id = p_Priv_Id;
    Begin
      Select Admin_Flg
        Into v_Admin_Flg
        From Sys_User
       Where User_No = p_User_No;
    
      If v_Admin_Flg = 'Y' Then
        Return 'Y';
      End If;
    
      Select 'x'
        Into v_Char
        From Sys_User_Priv
       Where App_Code = p_App_Code
         And Priv_Id = p_Priv_Id
         And (User_No = p_User_No Or
             User_No In (Select Group_No
                            From Sys_User_Group
                          Connect By Prior User_No = Group_No
                           Start With User_No = p_User_No))
         And Rownum <= 1;
    
      Return 'Y';
    Exception
      When No_Data_Found Then
        Return 'N';
    End;
  
  Exception
    When No_Data_Found Then
      Insert Into Sys_Priv_Mas
        (App_Code, Priv_Id, Description)
      Values
        (p_App_Code, p_Priv_Id, p_Desc);
      Commit;
      Return 'N';
    
  End;

  function get_acc_name(p_acc_index varchar2, p_acc_code varchar2)
    return varchar is
    result varchar2(64);
  begin
    if p_acc_index is not null then
      select acc_name
        into result
        from account_mas a
       where a.acc_id = p_acc_index
         and a.acc_id = p_acc_code
         and rownum <= 1;
    else
      select acc_name
        into result
        from account_mas a
       where a.acc_id = p_acc_code
         and rownum <= 1;
    end if;
    return result;
  exception
    when no_data_found then
      return null;
  end;
End;
/

