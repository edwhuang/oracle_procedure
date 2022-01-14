create or replace function iptv.test_sendall_http(p_serial_id varchar2)
  return varchar2 is
  req            utl_http.req;
  resp           utl_http.resp;
  rw             varchar2(32767);
  sql_text       varchar2(10000);
  sort_no        varchar2(10000);
  v_cnt          number := 0;
  r1             mid_kod_showcase_mas%rowtype;
  v_param_begin  varchar2(1000);
  v_param_body   varchar2(10000);
  v_param_end    varchar2(1000);
  v_param        VARCHAR2(5000);
  v_param_length NUMBER := length(v_param);
  rw_result      clob;
  cursor c1 is
    select id,
           sort_no,
           title,
           sub_title,
           remark,
           status_flg,
           start_date,
           end_date,
           active_date
      from mid_kod_showcase_mas
     order by sort_no;

begin

  v_param_begin := '{"jsonrpc":"2.0","method":"cmskodmenu.set_topic","params":{"listOfTopic":[';

  open c1;
  loop
    fetch c1
      into r1;
    exit when c1%notfound;
    begin
      v_cnt    := v_cnt + 1;
      sql_text := r1.title;
      sql_text := lower(replace(ASCIISTR(sql_text), '\', '\u'));
      sort_no  := r1.id;

      if not c1%rowcount = 1 then
        v_param_body := v_param_body || ',';
      end if;

      if v_cnt <= 5 then
        v_param_body := v_param_body ||
                        '{"action":"query","childView":"songList","positionX":0,"positionY":' ||
                        mod(v_cnt - 1, 5) ||
                        ',"sql":{"fromTemplate":"showcase","groupby":"","limit":"","orderby":"(s.length_of_title+9)%10,song_big5_sort","selectTemplate":"main","where":"sc.id='||
                        sort_no||'"},"title":"'||sql_text||'"}';
      else
        v_param_body := v_param_body ||
                        '{"action":"query","childView":"songList","positionX":1,"positionY":' ||
                        mod(v_cnt - 1, 5) ||
                        ',"sql":{"fromTemplate":"showcase","groupby":"","limit":"","orderby":"(s.length_of_title+9)%10,song_big5_sort","selectTemplate":"main","where":"sc.id='||
                        sort_no||' "},"title":"'||sql_text||'"}';
      end if;

      v_param_end := ']}}';

      v_param := v_param_begin || v_param_body || v_param_end;
    exception
      when others then
        dbms_output.put_line('錯誤代號為 ' || sqlcode);
        dbms_output.put_line('錯誤訊息為 ' || sqlerrm);
    end;
  end loop;

  rw_result := link_set.link_set.post_to_cdi(v_param);
  return v_param;
end;
/

