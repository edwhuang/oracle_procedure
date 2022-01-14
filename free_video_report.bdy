CREATE OR REPLACE PACKAGE BODY IPTV.FREE_VIDEO_REPORT AS

  function get_days(p_date date) return number AS
  BEGIN
    /* TODO 需要實行 */
    RETURN to_number(to_char(p_date,'D'));
  END get_days;

  function get_weeks(p_date date) return number AS
  
  v_d number;
  v_year number;
  v_days number;  

  v_year_start date;
  v_year_start_d number;
  v_week_d number;
  BEGIN
      v_year_start := to_date(to_char(p_date,'YYYY')||'0101','YYYYMMDD');
      v_year_start_d := get_days(v_year_start);
      v_days := p_date-v_year_start+1;
      v_week_d:=ceil((v_days+v_year_start_d-1)/7);
    RETURN v_week_d;
  END get_weeks;
  
  function get_week_start_date(p_date date) return date AS
  begin
    return p_date-(get_days(p_date))+1;
  end;

END FREE_VIDEO_REPORT;
/

