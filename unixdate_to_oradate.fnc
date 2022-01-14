create or replace function iptv.unixdate_to_oradate(in_number NUMBER) return date is
  begin
    if in_number is not null then
      return(TO_DATE('19700101', 'YYYYMMDD') + (in_number / 86400000000));
    else
      return(sysdate);
    end if;
  end unixdate_to_oradate;
/

