create or replace function iptv.cal_date(p_cal_date date,p_months number,p_days number) return date is
  Result date;
begin
    select max(end_date)
            into Result
            from (select trunc(add_months(p_cal_date, rownum * p_months) +
                               p_days * rownum) - (1 / (24 * 60 * 60)) end_date
                    from dual
                  connect by trunc(add_months(p_cal_date,
                                              rownum * p_months) +
                                   p_days * rownum) - (1 / (24 * 60 * 60)) <
                             trunc(add_months(sysdate, p_months) + p_days -
                                   (1 / (24 * 60 * 60))));
                           
  return(Result);
end cal_date;
/

