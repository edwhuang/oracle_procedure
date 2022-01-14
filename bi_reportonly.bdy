CREATE OR REPLACE PACKAGE BODY IPTV.bi_reportonly is
 FUNCTION get_cat_title(pk_no IN number) RETURN VARCHAR2
 as
 p_cat_title VARCHAR2(500); 
   CURSOR C_cat  IS 
        select b.cat_title
        from
        (
        SELECT cat
        FROM mid_content_list
        WHERE cms_util.get_content_id(pk_no)=content_id 
           and status_flg='P' ---P:上架 N:沒上架  R:準備上架未按確認(沒上架)
        ) a
        left join  
        (
        select cat,cat_title
        from  mid_cms_content_cat 
        where status_flg='P' ---P:上架 N:沒上架  R:準備上架未按確認(沒上架)
        ) b
        on a.cat=b.cat;
BEGIN
   FOR x IN C_cat
    LOOP
        p_cat_title := p_cat_title||nvl(x.cat_title,'off')||',';
    END LOOP; 
    RETURN substr(p_cat_title,1,length(p_cat_title)-1); 
END;
end bi_reportonly;
/

