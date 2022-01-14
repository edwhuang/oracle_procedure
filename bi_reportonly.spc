CREATE OR REPLACE PACKAGE IPTV.bi_reportonly is
 FUNCTION get_cat_title(pk_no IN number) RETURN VARCHAR2;
 end bi_reportonly;
/

