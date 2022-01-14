create or replace procedure iptv.
   log_alert_msg
(
   to_name  varchar2,
   subject  varchar2,
   log_date varchar2,
   log_name varchar2,
   log_cnt  number,
   log_s_cnt number,
   message varchar2
)
is
  l_mailhost    VARCHAR2(256) := 'exchange.tgc-taiwan.com.tw';
  l_from        VARCHAR2(256) := 'oracle@twodb.tw.svc.litv.tv';
  l_to          VARCHAR2(256) := to_name;
  l_mail_conn   UTL_SMTP.connection;
  l_subject     VARCHAR2(256) := subject;
  l_log_name    VARCHAR2(4000) := log_name;
  l_log_date    VARCHAR2(256) := log_date;
  l_cnt         NUMBER       := log_cnt;
  l_s_cnt       NUMBER       := log_s_cnt;
  l_message     varchar2(256):= message;  

BEGIN

  l_mail_conn := UTL_SMTP.open_connection(l_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, l_mailhost);
  UTL_SMTP.mail(l_mail_conn, l_from);
  UTL_SMTP.rcpt(l_mail_conn, l_to);

  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'From: '    || l_from || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || l_subject || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'To: '      || l_to || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, ''          || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Dear Admin:'                                          || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, ''                                                     || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'DATE : '||l_log_date||' '                             || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'LOG NAME: '||l_log_name                               || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'COUNT:    '||l_cnt                                    || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, ''                                                     || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, l_message                                              || Chr(13));

  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

END;
/

