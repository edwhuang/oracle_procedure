CREATE OR REPLACE PACKAGE IPTV.CMS_CNT_POST is
  C_date date;
  Function tgc_cms_content_check(p_user_no   Number,
                                 p_pk_no     Number,
                                 p_no_commit varchar2 default 'N')
    Return Varchar2;

  Function tgc_cms_content_post(p_user_no   Number,
                                p_pk_no     Number,
                                p_no_commit varchar2 default 'N')
    Return Varchar2;

  Function tgc_cms_content_unpost(p_user_no   Number,
                                  p_pk_no     Number,
                                  p_no_commit varchar2 default 'N')
    Return Varchar2;

  Function tgc_cms_item_post(p_user_no   Number,
                             p_pk_no     Number,
                             p_no_commit varchar2 default 'N')
    Return Varchar2;

  Function Mid_kod_Post Return Varchar2;

  Function tgc_cms_cntlist_post(p_user_no   Number,
                                p_cat_id    varchar2,
                                p_no_commit varchar2 default 'N')
    Return Varchar2;
   Function tgc_cms_cntlist_post_syn(p_user_no   Number,
                                p_cat_id    varchar2,
                                p_no_commit varchar2 default 'N')
    Return Varchar2;

  procedure rebuild_catalog(p_pk_no number);

  function tgc_cms_cat_post(p_user_no number) return varchar2;

  procedure cms_content_post(out_msg     out varchar2,
                             p_user_no   Number,
                             p_pk_no     Number,
                             p_no_commit varchar2 default 'N');

  procedure cms_content_list_post(out_msg     out varchar,
                                  p_user_no   Number,
                                  p_cat_id    varchar2,
                                  p_no_commit varchar2 default 'N');
  procedure cms_cat_post(out_msg out varchar, p_user_no number);
  procedure cms_kod_7table_post;
  procedure cms_vod_tag_proc(p_content_id varchar2);

end CMS_CNT_POST;
/

