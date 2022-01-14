CREATE OR REPLACE PROCEDURE P_CAL_DIS AS
BEGIN

  /* 機上盒拆出金額 */
  declare
    cursor c1 is
      Select a.rowid rid,
             a.purchase_pk_no,
             a.purchase_item_pk_no,
             a.amt,
             b.fa_income - a.amt fa_income
        from pentaho.ans_purchase_detail a, pentaho.ans_package_mas b
       where a.package_id = b.package_id
         and b.fa_income > 0
         and not exists
       (select 'x'
                from pentaho.ans_purchase_detail c
               where c.FA_REF_ITEM_PK_NO = a.purchase_item_pk_no);
  
    v_amt number(16);
    v_rid rowid;
  begin
    for i in c1 loop
      begin
        select rowid, a.amt
          into v_rid, v_amt
          from pentaho.ans_purchase_detail a
         where a.purchase_pk_no = i.purchase_pk_no
           and a.purchase_item_pk_no <> i.purchase_item_pk_no
           and rownum <= 1;
        update pentaho.ans_purchase_detail a
           set a.amt               = a.amt - i.fa_income,
               a.fa_ref_item_pk_no = i.purchase_item_pk_no,
               a.net_amt           = a.net_amt - (round(i.fa_income / 1.05)),
               a.tax_amt           = a.tax_amt - (i.fa_income -
                                     round(i.fa_income / 1.05))
         where rowid = v_rid;
        update pentaho.ans_purchase_detail b
           set b.amt     = b.amt + i.fa_income,
               b.tax_amt =
               (b.amt + i.fa_income) - round((b.amt + i.fa_income) / 1.05),
               b.net_amt = round((b.amt + i.fa_income) / 1.05)
         where b.rowid = i.rid;
        commit;
      exception
        when others then
          dbms_output.put_line(i.purchase_pk_no);
      end;
    end loop;
  end;

  /* Bandott 重複資料取消不計 */
  declare
    cursor c1 is
      select b.rowid rid, b.purchase_no
        from pentaho.ans_purchase_detail b, pentaho.ans_purchase_detail a
       where b.pay_type = 'Bandott'
         and b.purchase_no not like 'PUR%'
         and b.src_no = a.src_no
         and a.pay_type = 'Bandott'
         and a.purchase_no like 'PUR%'
         and b.status_flg = 'Z'
         and b.purchase_date >= trunc(sysdate - 10, 'MONTH');
  
    TYPE ct1 IS TABLE OF c1%rowtype;
    l_ct1 ct1;
  begin
    Select b.rowid rid, b.purchase_no BULK COLLECT
      INTO l_ct1
      from pentaho.ans_purchase_detail b, pentaho.ans_purchase_detail a
     where b.pay_type = 'Bandott'
       and b.purchase_no not like 'PUR%'
       and b.src_no = a.src_no
       and a.pay_type = 'Bandott'
       and a.purchase_no like 'PUR%'
       and b.status_flg = 'Z'
       and b.purchase_date >= trunc(sysdate - 105, 'MONTH');
  
    FORALL indx IN 1 .. l_ct1.count
      update /*+ NOLOGGING */ pentaho.ans_purchase_detail
         set status_flg = 'C'
      
       where rowid = l_ct1(indx).rid;
    commit;
  
  end;

  Declare
    /* 計算日期 */
    v_import_date date := to_date(to_char(sysdate - 10, 'YYYY/MM/') || '01',
                                  'YYYY/MM/DD');
  BEGIN
  /*  select min(start_date)
      into v_import_date
      from acc_period_mas@twdevdb
     where status_flg in ('O', 'S'); */

    --刪除攤分資料
    delete pentaho.ans_purchase_distribute_dtl x2
     where x2.pk_no in
           (select x.pk_no
              from pentaho.ANS_PURCHASE_DISTRIBUTE x
             where x.purchase_date >= v_import_date);
    --刪除攤分主檔資料
    delete pentaho.ANS_PURCHASE_DISTRIBUTE x
     where x.purchase_date >= v_import_date;
  
    -- 將IOS資料編上Key
    update ans_ios_chk x
       set x.pk_no = seq_ios.nextval
     where x.pk_no is null;
    --匯率換算
    update ans_ios_chk x
       set x.extended_partner_usd=(select x.extended_partner_share*y.rate from ans_ios_chk_rate y
        where y.CURRENT_MERCHANT='TWD' and y.start_date <= to_date(replace(replace(x.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') and y.end_date >=  to_date(replace(replace(x.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD'))
     where x.extended_partner_usd is null;
    --匯率換算 
    update ans_ios_chk x
       set x.extended_partner_twd=round((select x.extended_partner_usd*y.rate from ans_ios_chk_rate y
        where y.CURRENT_MERCHANT='USD' and y.start_date <= to_date(replace(replace(x.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') and y.end_date >=  to_date(replace(replace(x.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD')))
     where x.extended_partner_twd is null;
    
     
    -- 將IAB資料編上Key 
    update ans_iab_chk x
       set x.pk_no = seq_ios.nextval
     where x.pk_no is null;
  -- 將FA資料編上Key
      update ans_manual_chk x
       set x.pk_no = seq_ios.nextval
     where x.pk_no is null;
    --匯率換算 
    update pentaho.ans_iab_chk a
       set a.transaction_date = to_date(a.transaction_date_str,
                                        'MON DD, YYYY')
     where a.transaction_date is null;
    --將FA編上日期
    update pentaho.ans_man_mas a
       set a.transaction_date = to_date(replace(replace(a.TRANS_DATE_STR,
                                                        '攤計表',
                                                        ''),
                                                '.xlsx',
                                                ''),
                                        'YYYYMMDD'),
           a.pk_no            = seq_ios.nextval
     where a.pk_no is null;
    commit;
  
    /* check REFUND source  */
    --取消退費單金額設定成0
    update ANS_PURCHASE_DETAIL x
       set x.amt = 0, x.net_amt = 0
     where x.pay_type = 'REFUND'
       and x.purchase_date >= v_import_date
       and exists (select 'x'
              from ANS_PURCHASE_DETAIL y
             where y.purchase_no = x.src_no
               and y.status_flg = 'C');
    commit;
  
    /* Paymenthod not Auto recurrent */
  
    DECLARE
      CURSOR c1 IS
        select to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') dis_service_start,
               add_months(to_date(replace(replace(a.filename,
                                                  '攤計表匯入',
                                                  ''),
                                          '.xls',
                                          ''),
                                  'YYYYMMDD'),
                          b.period) - 1 dis_service_end,
               b.package_id package_id,
               'IOS系統攤分' PAY_TYPE,
               to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') purchase_date,
               round(a.extended_partner_twd / 1.05) net_amt,
               round(a.extended_partner_twd) amt,
               round(a.extended_partner_twd) -
               round(a.extended_partner_twd / 1.05) tax_amt,
               null client_id,
               to_char(a.transaction_date, 'YYMMDD') || a.apple_identifier ||
               substr(a.sku, 18) || a.quantity purchase_no,
               a.pk_no pk_no,
               QUANTITY qty
          from pentaho.ans_ios_chk a, ans_ios_prod_mas b
         where b.ios_product_code = a.sku
           and to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') >= v_import_date
        union all
        select to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') dis_service_start,
               add_months(to_date(replace(replace(a.filename,
                                                  '攤計表匯入',
                                                  ''),
                                          '.xls',
                                          ''),
                                  'YYYYMMDD'),
                          b.period) - 1 dis_service_end,
               b.package_id package_id,
               'IAB系統攤分' PAY_TYPE,
               to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') purchase_date,
               round(round(sum(a.amount_merchant * nvl(c.rate, 30))) / 1.05) net_amt,
               round(sum(a.amount_merchant * nvl(c.rate, 30))) amt,
               round(sum(a.amount_merchant * nvl(c.rate, 30))) -
               round(round(sum(a.amount_merchant * nvl(c.rate, 30))) / 1.05) tax_amt,
               null client_id,
               to_char(to_date(replace(replace(a.filename, '攤計表匯入', ''),
                                       '.xls',
                                       ''),
                               'YYYYMMDD'),
                       'YYMMDD') || a.description purchase_no,
               min(a.pk_no) pk_no,
               null qty
          from pentaho.ans_iab_chk a,
               ans_iab_prod_mas    b,
               ans_iab_chk_rate    c
         where b.iab_product_code = a.sku_id
           and c.start_date(+) <=
               to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD')
           and c.end_date(+) >=
               to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD')
           and c.current_merchant(+) = a.merchant_currency
           and c.exchange_merchant(+) = 'TWD'
           and to_date(replace(replace(a.filename, '攤計表匯入', ''),
                               '.xls',
                               ''),
                       'YYYYMMDD') >= v_import_date
         group by to_date(replace(replace(a.filename, '攤計表匯入', ''),
                                  '.xls',
                                  ''),
                          'YYYYMMDD'),
                  DESCRIPTION,
                  PRODUCT_ID,
                  PRODUCT_TYPE,
                  SKU_ID,
                  b.period,
                  b.package_id
        union all
                select to_date(replace(replace(a.filename,
                                                        '對帳單-',
                                                        ''),
                                                '.xls',
                                                ''),
                                        'YYYYMMDD') dis_service_start,
               add_months(to_date(replace(replace(a.filename,
                                                        '對帳單-',
                                                        ''),
                                                '.xls',
                                                ''),
                                        'YYYYMMDD'), b.distribute_period) - 1 dis_service_end,
               b.package_id package_id,
               '二類系統攤分' PAY_TYPE,
               to_date(replace(replace(a.filename,
                                                        '對帳單-',
                                                        ''),
                                                '.xls',
                                                ''),
                                        'YYYYMMDD') purchase_date,
               round(round(a.amount * nvl(1,30)) / 1.05) net_amt,
               round(a.amount * nvl(1,30)) amt,
               round(a.amount * nvl(1,30)) -
               round(round(a.amount *nvl(1,30)) / 1.05) tax_amt,
               null client_id,
               to_char(to_date(replace(replace(a.filename,
                                                        '對帳單-',
                                                        ''),
                                                '.xls',
                                                ''),
                                        'YYYYMMDD'), 'YYMMDD') || a.description purchase_no,
               a.pk_no pk_no,
               null qty
          from pentaho.ANS_MANUAL_CHK a,
               ANS_PACKAGE_MAS    b
         where b.package_id= a.sku_id
        union all
        SELECT a.dis_service_start,
               a.dis_service_end,
               a.package_id,
               a.pay_type,
               a.purchase_date,
               a.net_amt,
               a.amt,
               a.tax_amt,
               a.client_id,
               a.purchase_no,
               a.pk_no,
              null qty
               
        
          FROM ANS_PURCHASE_DETAIL a
         where a.status_flg = 'Z'
           and a.purchase_date >= v_import_date
           and a.pay_type not in
               (Select t.pay_type
                  from ans_payment_mas t
                 where t.auto_recurrent = 'Auto');
      v_package_id       VARCHAR2(32);
      v_package_periods  NUMBER;
      v_service_period   NUMBER;
      v_dis_period       NUMBER;
      v_dis_amt          NUMBER;
      v_sp_yyyymm        VARCHAR2(32);
      V_DISTRIBUTE_TYPE  VARCHAR2(32);
      v_fee              Number;
      v_fee_ratio        Number(16, 4);
      v_fee_type         varchar2(32);
      v_priv_purchase_no varchar2(64);
    BEGIN
      v_priv_purchase_no := '';
      FOR i IN c1 LOOP
        -- 方案的預設攤分期數
        BEGIN
          SELECT x.DISTRIBUTE_PERIOD, x.PACKAGE_ID
            INTO v_package_periods, v_package_id
            FROM ans_package_mas x
           WHERE x.package_id = i.package_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_package_periods := 1;
            v_package_id      := i.package_id;
        END;
      
        IF (trunc(i.dis_service_end) - trunc(i.dis_service_start)) <= 32 THEN
          -- 日期少於32期數設定成1
          v_service_period := 1;
          if (trunc(i.dis_service_end) - trunc(i.dis_service_start)) < 0 then
          -- 到期日少於起始日日期設定為一樣
            i.dis_service_start := i.dis_service_end;
          end if;
        ELSE
          v_service_period := CEIL(MONTHS_BETWEEN(i.dis_service_end - 13,
                                                  i.dis_service_start)); -- ￿￿￿￿￿￿￿￿￿￿￿￿
        END IF;
      
        begin
          Select a.payment_fee, a.payment_fee_type
            into v_fee_ratio, v_fee_type
            from ans_payment_mas a
           where a.pay_type = i.pay_type;
        exception
          when others then
            null;
        end;
      
        IF ((v_service_period >= v_package_periods) AND
           v_service_period < 100) or (v_service_period = 1) THEN
          -- ￿￿￿￿￿￿￿￿￿,￿￿￿￿￿￿￿￿￿
          v_dis_period := v_service_period;
        ELSE
          v_dis_period := v_package_periods;
        END IF;
      
        v_dis_amt   := ROUND(i.net_amt / v_dis_period);
        v_sp_yyyymm := TO_CHAR(nvl(i.dis_service_start, i.purchase_date),
                               'yyyy-mm'); -- ￿￿￿￿￿
        if v_dis_period = 1 then
          V_DISTRIBUTE_TYPE := 'O'; -- ￿￿￿￿
        else
          V_DISTRIBUTE_TYPE := 'D'; -- ￿￿
        end if;
      
        if v_fee_type = 'Ratio' then
          v_fee := round(i.amt * v_fee_ratio);
        else
          v_fee := v_fee_ratio;
        end if;
        begin
          INSERT INTO ANS_PURCHASE_DISTRIBUTE
            (CLIENT_ID,
             PAY_TYPE,
             PURCHASE_DATE,
             SERVICE_START,
             SERVICE_END,
             AMT,
             NET_AMT,
             TAX_AMT,
             COMMISSION_AMT,
             OTHER_FEE,
             TOTAL_REVENUE,
             PURCHASE_NO,
             ORG_DISTRIBUTE_PERIODS,
             PACKAGE_ID,
             DISTRIBUTE_PERIODS,
             REVENUE_FIRST,
             REVENUE_DISTRIBUTE,
             PK_NO,
             START_DIS_PERIOD,
             OLD_IMP_FLG,
             DISTRIBUTE_TYPE,
             qty
             
             )
          
          VALUES
            (i.CLient_id,
             i.pay_type,
             i.purchase_date,
             i.dis_service_start,
             i.dis_service_end,
             i.amt,
             i.net_amt,
             i.tax_amt,
             v_fee,
             0,
             i.net_amt,
             i.purchase_no,
             v_package_periods,
             v_package_id,
             v_dis_period,
             v_dis_amt,
             v_dis_amt,
             i.pk_no,
             v_sp_yyyymm,
             'N',
             V_DISTRIBUTE_TYPE,
             i.qty);
          COMMIT;
        exception
          when DUP_VAL_ON_INDEX then
            dbms_output.put_line(i.pk_no);
        end;
      
        --
        -- ￿￿￿￿
        --
      
        DECLARE
          CURSOR c1 IS
            SELECT *
              FROM PENTAHO.ANS_PURCHASE_DISTRIBUTE t
             where t.pk_no = i.pk_no;
          v_total_income  NUMBER(16, 4);
          v_cnt           NUMBER(16);
          v_date          DATE;
          v_yyyymm        VARCHAR2(32);
          v_dist_amt      NUMBER(16);
          v_first_amt     NUMBER(16);
          v_income_period VARCHAR2(32);
          v_income_comp   NUMBER(16);
          v_sp_yyyymm     VARCHAR2(32);
          v_come_last     NUMBER(16);
          v_income        NUMBER(16);
          v_fee_type      varchar(16);
          v_fee_ratio     number(16, 4);
          v_net           number(16);
          v_refund        number(16);
        BEGIN
        
          FOR j IN c1 LOOP
            begin
              Select a.payment_fee, a.payment_fee_type
                into v_fee_ratio, v_fee_type
                from ans_payment_mas a
               where a.pay_type = i.pay_type;
            exception
              when others then
                null;
            end;
          
            v_total_income := j.TOTAL_REVENUE; -- 蕞蕞蕞蕞蕞?
            v_first_amt    := j.revenue_first; -- ￿￿￿￿
            if v_total_income > 0 then
              v_refund := 1;
            else
              v_refund := -1;
            end if;
            v_income_period := TO_CHAR(j.Purchase_date, 'YYYY-MM'); -- ￿￿￿￿
            if (j.OLD_IMP_FLG = 'O') then
              if (to_char(j.purchase_date, 'DD') = '01') then
                v_cnt := j.distribute_periods - 1;
              else
                v_cnt := j.distribute_periods;
              end if;
            else
              v_cnt := NVL(j.distribute_periods, 1) +
                       ceil(MONTHS_BETWEEN(NVL(j.service_start,
                                               j.purchase_date),
                                           j.purchase_date)); -- ￿￿￿￿￿=￿￿￿￿+￿￿￿￿￿￿
            end if;
          
            v_date      := j.Purchase_date;
            v_sp_yyyymm := j.start_dis_period;
          
            v_dist_amt  := j.revenue_distribute;
            v_come_last := 0;
          
            --  DBMS_OUTPUT.put_line (v_cnt);
          
            FOR k IN 0 .. v_cnt LOOP
            
              v_yyyymm := TO_CHAR(ADD_MONTHS(v_date, k), 'yyyy-mm'); -- ￿￿￿￿
              IF k = 0 THEN
                v_income      := v_total_income; -- ￿￿￿￿￿￿￿￿￿￿
                v_income_comp := v_total_income; -- ￿￿￿￿￿￿￿￿￿￿
              ELSE
                v_income := 0; -- ￿￿￿￿￿￿￿￿0
              END IF;
              IF v_yyyymm >= v_sp_yyyymm THEN
                -- ￿￿￿￿￿￿￿￿￿￿,￿￿￿￿￿￿￿
                IF (v_income_comp * v_refund >=
                   j.revenue_distribute * v_refund and k < v_cnt) THEN
                  -- ￿￿￿￿￿￿￿￿,￿￿￿￿￿￿￿￿￿￿
                  IF v_yyyymm = v_sp_yyyymm THEN
                    v_dist_amt := v_first_amt; -- ￿￿￿￿￿￿￿￿
                  ELSE
                    v_dist_amt := j.revenue_distribute;
                  end iF;
                ELSE
                  -- ￿￿,￿￿￿￿￿￿￿￿
                  v_dist_amt := v_income_comp;
                END IF;
              ELSE
                v_dist_amt := 0; -- ￿￿￿￿￿￿
              END IF;
              v_income_comp := v_income_comp - v_dist_amt; -- ￿￿￿￿￿￿
            
              if v_fee_type = 'Ratio' then
                v_fee := round(v_dist_amt * v_fee_ratio);
              else
                IF v_yyyymm = v_sp_yyyymm THEN
                  -- ￿￿￿￿￿￿￿￿￿￿￿
                  if v_priv_purchase_no <> j.purchase_no then
                    v_fee := v_fee_ratio;
                  else
                    v_fee := 0;
                  end if;
                else
                  v_fee := 0;
                end if;
              end if;
            
              v_priv_purchase_no := i.purchase_no;
            
              v_net := v_dist_amt - v_fee;
              INSERT INTO pentaho.ans_purchase_distribute_dtl
                (purchase_no,
                 period,
                 revenue,
                 income,
                 remainder_amt,
                 previous_remainder_amt,
                 pk_no,
                 COMMISSION_COST,
                 NET_REVENUE)
              VALUES
                (j.purchase_no,
                 v_yyyymm,
                 v_dist_amt,
                 v_income,
                 v_income_comp,
                 v_come_last,
                 j.pk_no,
                 v_fee,
                 v_net);
              v_come_last := v_income_comp; --￿￿￿￿￿￿
            END LOOP;
            COMMIT;
          END LOOP;
        END;
      
      END LOOP;
    END;
  
    --
    -- Pay menthod auto recurrent
    --
    DECLARE
      CURSOR c1 IS
        SELECT a.*
          FROM ANS_PURCHASE_DETAIL a
         where a.status_flg = 'Z'
           and (a.purchase_date >= v_import_date or
               a.service_end_date >= v_import_date)
           and a.pay_type in
               (Select t.pay_type
                  from ans_payment_mas t
                 where t.auto_recurrent = 'Auto')
         order by a.purchase_no, a.pk_no;
      v_package_id       VARCHAR2(32);
      v_package_periods  NUMBER;
      v_service_period   NUMBER;
      v_dis_period       NUMBER;
      v_dis_amt          NUMBER;
      v_sp_yyyymm        VARCHAR2(32);
      v_end_yyyymm       VARCHAR2(32);
      V_DISTRIBUTE_TYPE  VARCHAR2(32);
      v_pk_no            NUMBER;
      v_fee              Number;
      v_fee_ratio        Number(16, 4);
      v_fee_type         varchar2(32);
      v_priv_purchase_no varchar2(64);
    BEGIN
      v_priv_purchase_no := '';
      FOR i IN c1 LOOP
        begin
          Select a.payment_fee, a.payment_fee_type
            into v_fee_ratio, v_fee_type
            from ans_payment_mas a
           where a.pay_type = i.pay_type;
        exception
          when others then
            null;
        end;
        -- ￿￿￿￿￿'IOS', 'TSTAR', '￿￿￿￿￿￿' ,￿￿￿￿￿ 1
        v_service_period := 1;
        v_dis_period     := 1;
        v_package_id     := i.package_id;
      
        v_dis_amt   := i.net_amt;
        v_sp_yyyymm := TO_CHAR(nvl(i.dis_service_start, i.purchase_date),
                               'yyyy-mm'); -- ￿￿￿￿￿
      
        V_DISTRIBUTE_TYPE := 'R';
      
        if v_fee_type = 'Ratio' then
          v_fee := round(i.amt * v_fee_ratio);
        else
          -- ￿￿￿￿￿￿￿￿￿￿￿
          if v_priv_purchase_no <> i.purchase_no then
            v_fee := v_fee_ratio;
          else
            v_fee := 0;
          end if;
        end if;
        v_priv_purchase_no := i.purchase_no;
      
        BEGIN
          Select pk_no
            into v_pk_no
            from ANS_PURCHASE_DISTRIBUTE
           where pk_no = i.pk_no;
        
          update ANS_PURCHASE_DISTRIBUTE
             set service_end        = i.service_end_date,
                 package_id         = i.package_id,
                 DISTRIBUTE_PERIODS = v_dis_period
           where pk_no = i.pk_no;
        
        exception
          when no_data_found then
            INSERT INTO ANS_PURCHASE_DISTRIBUTE
              (CLIENT_ID,
               PAY_TYPE,
               PURCHASE_DATE,
               SERVICE_START,
               SERVICE_END,
               AMT,
               NET_AMT,
               TAX_AMT,
               COMMISSION_AMT,
               OTHER_FEE,
               TOTAL_REVENUE,
               PURCHASE_NO,
               ORG_DISTRIBUTE_PERIODS,
               PACKAGE_ID,
               DISTRIBUTE_PERIODS,
               REVENUE_FIRST,
               REVENUE_DISTRIBUTE,
               PK_NO,
               START_DIS_PERIOD,
               OLD_IMP_FLG,
               DISTRIBUTE_TYPE)
            VALUES
              (i.CLient_id,
               i.pay_type,
               i.purchase_date,
               i.dis_service_start,
               i.dis_service_end,
               i.amt,
               i.net_amt,
               i.tax_amt,
               v_fee,
               0,
               i.net_amt,
               i.purchase_no,
               v_package_periods,
               v_package_id,
               v_dis_period,
               v_dis_amt,
               v_dis_amt,
               i.pk_no,
               v_sp_yyyymm,
               'N',
               V_DISTRIBUTE_TYPE);
            COMMIT;
        end;
      end loop;
    end;
  
    --
    -- Recurrent ￿￿￿￿
    --
  
    DECLARE
      CURSOR c1 IS
        SELECT a.*
          FROM ANS_PURCHASE_DETAIL a
         where a.status_flg = 'Z'
           and a.pay_type in
               (Select t.pay_type
                  from ans_payment_mas t
                 where t.auto_recurrent = 'Auto')
         order by a.purchase_no, a.pk_no;
      v_package_id       VARCHAR2(32);
      v_package_periods  NUMBER;
      v_service_period   NUMBER;
      v_dis_period       NUMBER;
      v_dis_amt          NUMBER;
      v_sp_yyyymm        VARCHAR2(32);
      v_end_yyyymm       VARCHAR2(32);
      V_DISTRIBUTE_TYPE  VARCHAR2(32);
      v_pk_no            NUMBER;
      v_fee              Number;
      v_fee_ratio        Number(16, 4);
      v_fee_type         varchar2(32);
      v_priv_purchase_no varchar2(64);
    
      v_import_period varchar2(32) := to_char(v_import_date, 'yyyy-mm');
    begin
      FOR i IN c1 LOOP
      
        delete pentaho.ans_purchase_distribute_dtl a
         where pk_no = i.pk_no
           and a.period >= v_import_period;
        commit;
      
        DECLARE
          CURSOR c1 IS
            SELECT *
              FROM PENTAHO.ANS_PURCHASE_DISTRIBUTE t
             where t.pk_no = i.pk_no;
          v_total_income  NUMBER(16, 4);
          v_cnt           NUMBER(16);
          v_date          DATE;
          v_yyyymm        VARCHAR2(32);
          v_dist_amt      NUMBER(16);
          v_first_amt     NUMBER(16);
          v_income_period VARCHAR2(32);
          v_income_comp   NUMBER(16);
          v_sp_yyyymm     VARCHAR2(32);
          v_come_last     NUMBER(16);
          v_income        NUMBER(16);
          v_income_est    NUMBER(16);
          v_re            number(16);
          v_re_est        number(16);
          v_fee           Number;
          v_fee_ratio     Number(16, 4);
          v_fee_type      varchar2(32);
          v_net           number;
        BEGIN
        
          FOR j IN c1 LOOP
            v_end_yyyymm := to_char(j.service_end, 'yyyy-mm');
            begin
              Select a.payment_fee, a.payment_fee_type
                into v_fee_ratio, v_fee_type
                from ans_payment_mas a
               where a.pay_type = i.pay_type;
            exception
              when others then
                null;
            end;
            v_total_income  := j.TOTAL_REVENUE; -- 蕞蕞蕞蕞蕞?
            v_first_amt     := j.revenue_first; -- ￿￿￿￿
            v_income_period := TO_CHAR(j.Purchase_date, 'YYYY-MM'); -- ￿￿￿￿
            v_cnt           := ceil(MONTHS_BETWEEN(NVL(j.service_end,
                                                       j.purchase_date),
                                                   j.purchase_date)) + 10; -- ￿￿￿￿￿=￿￿￿￿+￿￿￿￿￿￿
          
            v_date      := j.Purchase_date;
            v_sp_yyyymm := j.start_dis_period;
          
            v_dist_amt  := j.revenue_distribute;
            v_come_last := 0;
          
            --  DBMS_OUTPUT.put_line (v_cnt);
          
            FOR k IN 0 .. v_cnt LOOP
              v_yyyymm := TO_CHAR(ADD_MONTHS(v_date, k), 'yyyy-mm'); -- ￿￿￿￿
              if v_yyyymm = v_income_period then
                v_income     := v_dist_amt;
                v_income_est := 0;
                v_re         := v_dist_amt;
                v_re_est     := 0;
              elsif v_yyyymm > v_sp_yyyymm then
                v_income_est := v_dist_amt;
                v_income     := 0;
                v_re         := 0;
                v_re_est     := v_dist_amt;
              else
                v_income_est := 0;
                v_income     := 0;
                v_re         := 0;
                v_re_est     := 0;
              end if;
            
              if v_fee_type = 'Ratio' then
                v_fee := round(v_dist_amt * v_fee_ratio);
              else
                IF v_yyyymm = v_sp_yyyymm THEN
                  v_fee := v_fee_ratio;
                else
                  v_fee := 0;
                end if;
              end if;
            
              v_net := v_re + v_re_est - v_fee;
            
              if v_yyyymm <= v_end_yyyymm and v_yyyymm >= v_import_period then
                INSERT INTO pentaho.ans_purchase_distribute_dtl
                  (purchase_no,
                   period,
                   revenue,
                   revenue_est,
                   income,
                   income_est,
                   remainder_amt,
                   previous_remainder_amt,
                   pk_no,
                   COMMISSION_COST,
                   NET_REVENUE)
                VALUES
                  (j.purchase_no,
                   v_yyyymm,
                   v_re,
                   v_re_est,
                   v_income,
                   v_income_est,
                   0,
                   0,
                   j.pk_no,
                   v_fee,
                   v_net);
                v_come_last := v_income_comp; --￿￿￿￿￿￿
              end if;
            END LOOP;
            COMMIT;
          END LOOP;
        END;
      
      END LOOP;
    END;
  
  END;
  null;
END;
