CREATE OR REPLACE PACKAGE IPTV."BSM_SMS_SERVICE" IS
   Function Send_Sms_Messeage_cht(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)  Return varchar2;
      Function Send_Sms_Message_k(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2;

      Function Send_Sms_Message_4g(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2;
     Function Send_Sms_Messeage(p_Phone_No  Varchar2,
                            p_Message   Varchar2,
                            p_client_id varchar2 default null,
                            p_message_code varchar2 default null)
    Return Varchar2;
    
      Function Send_Sms_Messeage_litv(p_Phone_No     Varchar2,
                                  p_Message      Varchar2,
                                  p_client_id    varchar2 default null,
                                  p_message_code varchar2 default null,
                                  p_purchase_no    varchar2 default null,
                                  amount         number default null)
    Return Varchar2;
    
           function send_sms_text(port varchar2,p_text varchar2,p_phone_no varchar2) return varchar2;
    
       function send_sms(port varchar2,p_amt varchar,p_type varchar2,p_pur_no varchar2,p_phone_no varchar2) return varchar2;


end;
/

