CREATE OR REPLACE PACKAGE IPTV.FREE_VIDEO_REPORT AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
  function get_days(p_date date) return number;
  function get_weeks(p_date date) return number;
  function get_week_start_date (p_date date) return date;

END FREE_VIDEO_REPORT;
/

