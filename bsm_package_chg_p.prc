create or replace procedure iptv.bsm_package_chg_p
is
begin
  begin
    declare
  cursor c1 is
    select rowid rid, a.*
      from bsm_package_sch_mas a
     where a.tirgger_date < sysdate
       and a.status_flg = 'P';
  v_msg varchar(1024);
begin
  for i in c1 loop
    uPDATE BSM_PACKAGE_MAS T
       SET DESCRIPTION      = i.pack_description,
           PACKAGE_DES_HTML = i.pack_desc_html,
           PRICE_DES        = i.pack_price_desc,
           T.CHARGE_AMOUNT  = i.pack_charge_amount,
           DURATION_BY_DAY  = i.pack_duration_by_day,
           CREDITS_DES      = i.credits_des,
           CREDITS          = i.credits,
           t.package_end_date_desc = i.pack_end_date_desc
     WHERE PACKAGE_ID = i.package_id;

    update bsm_package_sch_mas set status_flg = 'N' where rowid = i.rid;

    commit;
    declare
      cursor c2 is
        select regexp_substr(i.vod_cat, '[^,]+', 1, level) cat
          from dual
        connect by regexp_substr(i.vod_cat, '[^,]+', 1, level) is not null;
    begin
      for j in c2 loop
        update mid_cms_content_cat a
           set a.promotion_desc = i.vod_promotion_desc
         where a.cat = j.cat;
        commit;

      end loop;

    end;
  end loop;
  v_msg := cms_cnt_post.tgc_cms_cat_post(0);

end;
end;
end;
/

