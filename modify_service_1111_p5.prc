create or replace procedure iptv.modify_service_1111_p5(pi_client_id varchar2 default null) is
begin
  DECLARE
    cursor c0 is
    with t1 as (Select a.pk_no purchase_pk_no,
                     a.serial_id,
                     a.mas_no,
                     a.pay_type,
                     c.start_date,
                     c.end_date,
                     a.purchase_date
                from bsm_purchase_mas   a,
                     bsm_purchase_item  b,
                     bsm_client_details c
               where b.mas_pk_no = a.pk_no
                 and a.status_flg = 'Z'
                 and c.end_date >= sysdate
                 and pay_type in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS') -- google ,ios 的豪華要判斷但不搬
                 and c.package_id like 'XD%'
                 and c.src_pk_no = a.pk_no
                 and c.status_flg='P'
                 and not exists(select 'x' from bsm_issue_item x where x.modify_check like 'a.pk_no'||'%' and rownum <=1))
 select * from (
 Select
             t6.purchase_pk_no,
             t6.serial_id,
             t6.mas_no,
                      t3.purchase_date dup_pur_date,
                           t1.purchase_date xbuy_date,
                            t5.package_cat_id1,
                             t2.start_date dup_start_date,
              case
               when t3.pay_type not in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送') then
                'N'
               when t2.start_date >= t1.start_date then
                'A'
               when t2.start_date < t1.start_date then
                'A'
             end process_sts
            
      
        from t1,
             t1 t6,
             bsm_client_details t2,
             bsm_purchase_mas t3,
             bsm_client_mas t4,
             bsm_package_mas t5
       where t2.status_flg = 'P'
         and t2.src_pk_no = t3.pk_no
         and t5.package_id=t2.package_id
         and (t2.package_id not like 'XD%' and t2.package_id not in ('XD0005',
         'XD0001',
         'XD0003',
         'XD0007',
         'XD0008',
         'XD0012',
                                   'FREE00',
                                   'FREE98',
                                   'FREE99',
                                   'FREE01',
                                   'FREE95',
                                   'FREE_FOR_CLEINT_ACTIVED',
                                   'FREE97',
                                   'ST0001',
                                   'FREE03',
                                   'FREE97',
                                   'CHG003',
                                   'FREE94',
                                   'PPV04'))
         and t2.end_date >= t1.start_date
         and t2.start_date < t1.end_date
         and t2.serial_id = t1.serial_id
         and t6.serial_id=t2.serial_id
         and t6.end_date > =t1.end_date
         and (t2.serial_id =pi_client_id )
         and ( t3.pay_type not in ('兌換券') or ( t3.pay_type='贈送' and t3.promo_code like 'promo%'))
         and t4.serial_id = t3.serial_id
          and not exists (select 'x' from bsm_issue_item x where x.modify_check = t1.purchase_pk_no||t1.end_date||' '||t3.mas_no)
         ) where process_sts='A' and (xbuy_date >=sysdate-30 or dup_pur_date >= sysdate-30);
  CURSOR C1(p_purchase_pk_no number) is
 with cte as (
 select * from (
 Select t4.owner_phone,
             t1.purchase_pk_no,
             t1.serial_id,
             t1.mas_no,
             t1.pay_type,
             t1.start_date,
             t1.end_date,
             t1.purchase_date xbuy_date,
             t2.pk_no dtl_pk_no,
             t3.pk_no dup_pk_no,
             t5.package_cat_id1,
             t2.package_id,
             t3.mas_no src_no,
             t2.package_name,
             t2.package_cat1,
             t2.start_date dup_start_date,
             t2.end_date dup_end_date,
             t3.pay_type dup_pay_type,
             t3.purchase_date dup_pur_date,
             t3.mas_no dup_mas_no,
             t2.end_date - t2.start_date days,
             
             (Select max(event_date)
                from sysevent_log l
               where event_type = 'update detail'
                 and event_date >= to_date('2019/10/31', 'YYYY/MM/DD')
                 and app_code = 'TGCCLIENT'
                 and l.pk_no = t4.serial_no) last_modify,
             case
               when t3.pay_type not in  ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS' )then
                '付款方式不符合'
               when t2.start_date >= t1.start_date then
                '整體期限延後1年'
               when t2.start_date < t1.start_date then
                '到期日延後一年'
             end method,
             case
               when t3.pay_type not in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS') then
                null
               when trunc(t2.start_date) >= trunc(t1.start_date) and sysdate > trunc(t1.start_date) then
                -- if(sysdate > t2.start_date) then 
                 trunc(sysdate+(t1.end_date-sysdate))+1
               when trunc(t2.start_date) >= trunc(t1.start_date) and sysdate <= trunc(t1.start_date) then
                 trunc(t2.start_date+(t1.end_date-t1.start_date))+1
               when trunc(t2.start_date) < trunc(t1.start_date) then
                t2.start_date
             end new_dup_start,
             case
               when t3.pay_type not in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS') then
                null
               when t2.start_date >= t1.start_date and sysdate > t1.start_date then
                trunc(t2.end_date+(t1.end_date-sysdate))
               when t2.start_date >= t1.start_date and sysdate <= t1.start_date then
                trunc(t2.end_date+(t1.end_date-t1.start_date)) 
               when t2.start_date < t1.start_date then
                trunc(t2.end_date + (t1.end_date - t1.start_date))
             end new_dup_end,
                  case
               when t3.pay_type not in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS') then
                null

               when trunc(t2.start_date) >= trunc(t1.start_date) then
                trunc((t1.end_date-t2.start_date))+1 
               when trunc(t2.start_date) < trunc(t1.start_date) and trunc(t1.end_date) < trunc(t2.end_date)  then
                trunc((t1.end_date - t1.start_date))+1
               when trunc(t2.start_date) < trunc(t1.start_date) and trunc(t1.end_date) >= trunc(t2.end_date)  then
                trunc((t1.end_date - t1.start_date))+1
             end ext_days,
             case
               when t3.pay_type not in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送') then
                'N'
               when t2.start_date >= t1.start_date then
                'A'
               when t2.start_date < t1.start_date then
                'A'
             end process_sts
      
        from (Select a.pk_no purchase_pk_no,
                     a.serial_id,
                     a.mas_no,
                     a.pay_type,
                     c.start_date,
                     c.end_date,
                     a.purchase_date
                from bsm_purchase_mas   a,
                     bsm_purchase_item  b,
                     bsm_client_details c
               where b.mas_pk_no = a.pk_no
                 and a.status_flg = 'Z'
                 and c.end_date >= sysdate
                 and pay_type in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS')
                 and c.package_id like 'XD%'
                 and c.src_pk_no = a.pk_no
                 and c.status_flg='P'
                 and not exists(select 'x' from bsm_issue_item x where x.modify_check like 'a.pk_no'||'%' and rownum <=1)) t1,
             bsm_client_details t2,
             bsm_purchase_mas t3,
             bsm_client_mas t4,
             bsm_package_mas t5
       where t2.status_flg = 'P'
         and t2.src_pk_no = t3.pk_no
         and t5.package_id=t2.package_id
         and t1.purchase_pk_no=p_purchase_pk_no
         and (t2.package_id not like 'XD%'  
         and t2.package_id not in ('XD0005',
         'XD0001',
         'XD0003',
         'XD0007',
         'XD0008',
         'XD0012',
                                   'FREE00',
                                   'FREE98',
                                   'FREE99',
                                   'FREE01',
                                   'FREE95',
                                   'FREE_FOR_CLEINT_ACTIVED',
                                   'FREE97',
                                   'ST0001',
                                   'FREE03',
                                   'FREE97',
                                   'CHG003',
                                   'FREE94',
                                   'PPV04'))
         and t2.end_date >= t1.start_date
         and t2.start_date < t1.end_date
         and t2.serial_id = t1.serial_id
         and (t2.serial_id =pi_client_id )
        and ( t3.pay_type not in ('兌換券') or ( t3.pay_type='贈送' and t3.promo_code like 'promo%'))
         and t3.serial_id not in ('2A00DBA59350E400',
                                  '2A00DEDF6A736900',
                                  '2A00EB267F728DC2',
                                  '2A00028624FC360E')
         and t4.serial_id = t3.serial_id
          and not exists (select 'x' from bsm_issue_item x where x.modify_check = t1.purchase_pk_no||t1.end_date||' '||t3.mas_no)
         ) where process_sts='A' and (xbuy_date >=sysdate-30 or dup_pur_date >= sysdate-30)
                 )
select * from cte where (cte.serial_id,dup_start_date,package_cat_id1) in (
select serial_id,min(dup_start_date),package_cat_id1 from cte group by serial_id,package_cat_id1);
    v_msg varchar2(1024);
    cnt number(16);
  begin
    cnt := 1;
    for j in c0 loop
    for i in c1(j.purchase_pk_no) loop
    begin
      insert into MODIFY_SERVICE_1111
        (owner_phone,
         purchase_pk_no,
         serial_id,
         mas_no,
         pay_type,
         start_date,
         end_date,
         dtl_pk_no,
         dup_pk_no,
         package_id,
         src_no,
         package_name,
         package_cat1,
         dup_start_date,
         dup_end_date,
         dup_pay_type,
         dup_pur_date,
         dup_mas_no,
         days,
         last_modify,
         method,
         new_dup_start,
         new_dup_end,
         process_sts,
         last_process)
      values
        (i.owner_phone,
         i.purchase_pk_no,
         i.serial_id,
         i.mas_no,
         i.pay_type,
         i.start_date,
         i.end_date,
         i.dtl_pk_no,
         i.dup_pk_no,
         i.package_id,
         i.src_no,
         i.package_name,
         i.package_cat1,
         i.dup_start_date,
         i.dup_end_date,
         i.dup_pay_type,
         i.dup_pur_date,
         i.dup_mas_no,
         i.days,
         i.last_modify,
         i.method,
         i.new_dup_start,
         i.new_dup_end,
         i.process_sts,
         null);
      exception
        when others then null;
      end;
      if i.process_sts = 'A' then
      
        declare
          v_org_no       number(16) := 1;
          v_issue_pk_no  number(16);
          v_mas_code     varchar2(32) := 'BSMISS';
          v_mas_no       varchar2(32);
          v_org_amt      number(16);
          v_org_tax_amt  number(16);
          v_org_net_amt  number(16);
          v_pay_pk_no    number(16);
          v_purchase_no  varchar2(32);
          v_refund_pk_no number(16);
          v_client_id    varchar2(32);
        
          v_item_pk_no number(16);
          cursor c1(p_client_id varchar2,p_end_date date,p_package_cat_id1 varchar,e_days number) is
            select case when a.end_date > p_end_date then '整體期限延後1年'
            else null
              end  method,a.pk_no dtl_pk_no,
                   a.package_id,
                   null item_id,
                   0 amount,
                   0 tax_amt,
                   0 chg_amt,
                   a.start_date,
                   a.start_date+e_days dup_start_date,
                   a.end_date,
                   a.end_date+e_days dup_end_date,
                   a.status_flg,
                   d.mas_no,
                     c.package_cat_id1
              from bsm_purchase_mas d , bsm_client_details a,bsm_package_mas c 
              
             where 1 = 1
               and a.src_pk_no = d.pk_no
               and pay_type in ('信用卡','手動刷卡', '信用卡二次扣款','ATM','REMIT','贈送','GOOGLEPLAY','IOS')
              -- and b.mas_pk_no = 650710
               and a.status_flg='P'
               and d.status_flg ='Z'
               and c.package_id=a.package_id
               and a.end_date >= p_end_date
               and d.serial_id=p_client_id
               and c.package_cat_id1 = p_package_cat_id1
               and not exists (select 'x' from bsm_issue_item e where e.modify_check = i.purchase_pk_no||i.end_date||' '||d.mas_no)
               --and a.pk_no=i.dtl_pk_no
             order by start_date, a.package_id;
        begin
        
          Select Seq_Bsm_Purchase_Pk_No.Nextval
            Into v_issue_pk_no
            From Dual;
        
          v_mas_no := Sysapp_Util.Get_Mas_No(v_org_no,
                                             2,
                                             Sysdate,
                                             v_mas_code,
                                             v_issue_pk_no);
        
          insert into bsm_issue_mas
            (pk_no,
             mas_date,
             mas_no,
             status_flg,
             issue_type,
             purchase_no,
             client_id,
             org_pk_no,
             org_amt,
             org_tax_amt,
             org_net_amt,
             org_pay_pk_no,
             create_date,
             create_user)
          values
            (v_issue_pk_no,
             sysdate,
             v_mas_no,
             'A',
             'SERVICE_CHANGE',
             i.dup_mas_no,
             i.serial_id,
             null,
             0,
             0,
             0,
             0,
             sysdate,
             0);
          for j in c1(i.serial_id,i.dup_end_date,i.package_cat_id1, i.ext_days) loop
            if nvl(j.method,i.method) = '整體期限延後1年' then
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_item_pk_no
                From Dual;
              insert into bsm_issue_item
                (pk_no,
                 mas_pk_no,
                 dtl_pk_no,
                 PURCHASE_NO,
                 org_item_pk_no,
                 org_package_id,
                 org_item_id,
                 org_amt,
                 org_tax_amt,
                 org_net_amt,
                 org_start_date,
                 org_end_date,
                 new_start_date,
                 new_end_date,
                 new_package_id,
                 change_type,
                 modify_check)
              values
                (v_item_pk_no,
                 v_issue_pk_no,
                 j.dtl_pk_no,
                 j.mas_no,
                 null,
                 j.package_id,
                 j.item_id,
                 j.amount,
                 j.tax_amt,
                 j.chg_amt,
                 j.start_date,
                 j.end_date,
                 j.dup_start_date,
                 j.dup_end_date,
                 j.package_id,
                 'C',
                 i.purchase_pk_no||i.end_date||' '||j.mas_no);
            elsif  nvl(j.method,i.method) = '到期日延後一年' then
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_item_pk_no
                From Dual;
              insert into bsm_issue_item
                (pk_no,
                 mas_pk_no,
                 PURCHASE_NO,
                 org_item_pk_no,
                 org_package_id,
                 org_item_id,
                 org_amt,
                 org_tax_amt,
                 org_net_amt,
                 org_start_date,
                 org_end_date,
                 new_start_date,
                 new_end_date,
                 new_package_id,
                 dtl_pk_no,
                 change_type,
                 modify_check)
              values
                (v_item_pk_no,
                 v_issue_pk_no,
                 j.mas_no,
                 null,
                 j.package_id,
                 j.item_id,
                 j.amount,
                 j.tax_amt,
                 j.chg_amt,
                 j.start_date,
                 j.end_date,
                 i.new_dup_start,
                 trunc(i.start_date) - (1 / (24 * 60 * 60)),
                 j.package_id,
                 i.dtl_pk_no,
                 'C',
                 i.purchase_pk_no||i.end_date||' '||j.mas_no);
            
              Select Seq_Bsm_Purchase_Pk_No.Nextval
                Into v_item_pk_no
                From Dual;
                declare
                  v_char varchar2(32);
                begin 
                  select 'x' into v_char from bsm_issue_item b,bsm_issue_mas a where dtl_pk_no = i.dtl_pk_no and a.pK_no=b.mas_pk_no and b.change_type='N' and a.mas_date >= sysdate-(3/(24*60));

                  exception 
                  when no_data_found then
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
                 purchase_no,
                 modify_check)
              values
                (v_item_pk_no,
                 v_issue_pk_no,
                 null,
                 j.package_id,
                 null,
                 null,
                 null,
                 null,
                 null,
                 'N',
                 null,
                 null,
                 trunc(i.end_date + 1),
                 i.new_dup_end,
                 j.package_id,
                 null,
                 i.dtl_pk_no,
                 j.mas_no,
                  i.purchase_pk_no||i.end_date||' '||j.mas_no);
                 commit;
                 
               end;
            end if;
              
          
          end loop;
        
          commit;
          v_msg := bsm_issue_post.bsm_issue_post(0, v_issue_pk_no);
          v_msg := bsm_issue_post.bsm_issue_complete(0, v_issue_pk_no);
        
          update MODIFY_SERVICE_1111 t
             set process_sts = 'Z', t.last_process = sysdate
           where t.purchase_pk_no = i.purchase_pk_no
             and t.dup_pk_no = i.dup_pk_no;
        
          commit;
        
        end;
      end if;
    end loop;
    end loop;
  end;
  
  declare
    cursor c1(p_client_id varchar2) is
    select t1.serial_id,mas_no,t1.pk_no from bsm_purchase_mas t1,(
      Select b.serial_id, min(b.pk_no) min_pk_no, max(b.mas_no)
        from bsm_recurrent_mas a,
             bsm_purchase_mas  b,
             bsm_purchase_item c,
             bsm_package_mas   d
       where b.pk_no = a.src_pk_no
         and c.mas_pk_no = b.pk_no
         and d.package_id = c.package_id
         and a.status_flg = 'P'
         and a.client_id = p_client_id
         and a.recurrent_type  in ( 'LiPayN','LiPay')
         and d.package_cat_id1 in ('CHANNEL_A', 'VOD_CHANNEL_DELUX')
       group by b.serial_id
      having count(*) > 1
      union all
      Select b.serial_id, min(b.pk_no) min_pk_no, max(b.mas_no)
        from bsm_recurrent_mas a,
             bsm_purchase_mas  b,
             bsm_purchase_item c,
             bsm_package_mas   d
       where b.pk_no = a.src_pk_no
         and c.mas_pk_no = b.pk_no
         and d.package_id = c.package_id
         and a.status_flg = 'P'
         and a.recurrent_type in  ( 'LiPayN','LiPay')
         and a.client_id = p_client_id
         and d.package_cat_id1 in ('ALL', 'VOD_CHANNEL_DELUX')
       group by b.serial_id
      having count(*) > 1) t2
      where t2.min_pk_no = t1.pk_no;
      
  
    v_msg varchar2(1024);
  begin
    for i in c1(pi_client_id) loop
  /*    declare
        v_char varchar2(1024);
      begin
        select 'x' into v_char from bsm_purchase_item c,bsm_package_mas d where
        d.package_id= c.package_id and c.mas_pk_no = i.pk_no and d.package_cat_id1 =  'VOD_CHANNEL_DELUX';
      exception
         when no_data_found then */
      v_msg := bsm_recurrent_util.stop_recurrent(i.serial_id,
                                                 i.mas_no,
                                                 '購買其他方案');
   --  end;
    end loop;
  end;

end;
/

