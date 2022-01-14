create or replace function iptv.split_date(p_pk_no      number,
                                      p_split_date date,
                                      p_next_start date) return varchar2 is
begin
  declare
    v_cnt      number(16);
    v_ext_days number(16) := p_next_start - p_split_date;
    v_item_pk_no number(16);
    cursor c1 is
      select * from bsm_issue_item b where b.mas_pk_no = p_pk_no;
  begin
    select count(*)
      into v_cnt
      from bsm_issue_item a
     where a.mas_pk_no = p_pk_no
       and new_start_date <= p_split_date
       and new_end_date >= p_split_date;
    if v_cnt > 0 then
      for i in c1 loop
        if i.new_start_date <= p_split_date and
           i.new_end_date >= p_split_date then
          update bsm_issue_item c
             set c.new_end_date = p_split_date
           where pk_no = i.pk_no;
                   Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_item_pk_no From Dual;
          insert into bsm_issue_item c
            (pk_no,
             mas_pk_no,
             org_item_pk_no,
             org_package_id,
             org_item_id,
             org_amt,
             org_tax_amt,
             org_net_amt,
             refund_amt,
             change_type,
             org_start_date,
             org_end_date,
             new_start_date,
             new_end_date,
             new_package_id,
             amt,
             dtl_pk_no,
             purchase_no)
          values
            (v_item_pk_no,
             i.mas_pk_no,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             'N',
             null,
             null,
             p_next_start,
             i.new_end_date - p_split_date + p_next_start -1,
             i.new_package_id,
             null,
             null,
             i.purchase_no);
        elsif i.new_start_date >= p_split_date then
                  update bsm_issue_item c
             set c.new_end_date = c.new_end_date+v_ext_days-1,
             c.new_start_date = c.new_start_date+v_ext_days-1
           where pk_no = i.pk_no;
        
        end if;
      end loop;
    end if;
    commit;
    return null;
  end;
end;
/

