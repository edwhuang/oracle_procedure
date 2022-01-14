CREATE OR REPLACE PACKAGE IPTV."SYSAPP_UTIL" Is
  /*
    Function Get_Pk_No Return Number;
  
    Function Get_Mas_No(p_Org_No   Number,
                        p_Loc_No   Number,
                        p_Mas_Date Date,
                        p_Doc_Code Varchar2,
                        p_Pk_No    Number) Return Varchar2;
  */
  Function Get_Form_Msg(p_App_Code  Varchar2,
                        p_Lang      Varchar2,
                        p_Msg_Type  Varchar2,
                        p_Msg_Code  Number,
                        p_Msg_Text  Varchar2,
                        p_dbms_Text Varchar2 Default Null) Return Varchar2;
  Function Get_Mas_No(p_Org_No   Number,
                      p_Loc_No   Number,
                      p_Mas_Date Date,
                      p_Doc_Code Varchar2,
                      p_Pk_No    Number,
                      prefix_no  varchar) Return Varchar2;
  Function Get_Mas_No(p_Org_No   Number,
                      p_Loc_No   Number,
                      p_Mas_Date Date,
                      p_Doc_Code Varchar2,
                      p_Pk_No    Number) Return Varchar2;                      
  Procedure set_todo_list(p_user_no  Number,
                          p_message  Varchar2,
                          p_app_code Varchar2,
                          p_pk_no    Number,
                          alt_time   Date Default Null);
  Procedure set_todo_list(p_user_id  Varchar2,
                          p_message  Varchar2,
                          p_app_code Varchar2,
                          p_pk_no    Number,
                          alt_time   Date Default Null);
  Procedure clear_todo_list(p_user_no  Number,
                            p_message  Varchar2,
                            p_app_code Varchar2,
                            p_pk_no    Number);
  Procedure clear_todo_list_visited(p_user_no Number,
                                    p_pk_no   Number Default Null);
  Procedure set_todo_list_post(p_user_no Number, p_pk_no Number);
  Function get_sys_value(p_App_Code      Varchar2,
                         p_Val_Code      Varchar2,
                         p_Default_Value Varchar2 Default Null)
    Return Varchar2;
  Function get_form_info(p_App_code Varchar2, p_pk_no Number) Return Varchar2;
  procedure set_event_log(p_app_code   varchar2,
                          p_pk_no      number,
                          p_user_no    number,
                          p_event_type varchar2,
                          p_desc       varchar2,
                          p_log clob default null);
  Function Get_User_Priv(p_App_Code Varchar2,
                         p_User_No  Number,
                         p_Priv_Id  Varchar2,
                         p_Desc     Varchar2) Return Varchar2;
  function get_acc_name(p_acc_index varchar2, p_acc_code varchar2)
    return varchar;

/*
  Function Get_Doc_Code(p_Pk_No Number) Return Varchar2;

  Function Get_App_Code(p_Pk_No Number) Return Varchar2;

  Function Get_Win_Title(p_App_Code Varchar2) Return Varchar2;

  Function Get_Org_name(p_org_no Number) Return Varchar2;

    Function Get_Org_TEL(p_org_no Number) Return Varchar2;

    Function Get_Org_ADDR(p_org_no Number) Return Varchar2;

  Procedure Set_App_Code(p_App_Code    Varchar2,
                         p_Doc_Code    Varchar2,
                         p_Description Varchar2);

  Procedure Set_Form_Status(p_Pk_No Number, p_Status_Flg Varchar2);

  Procedure Set_Form_Item(p_Lang         Varchar2,
                          p_App_Code     Varchar2,
                          p_Block        Varchar2,
                          p_Item         Varchar2,
                          p_Default_Text Varchar2);
*/
End;
/

