CREATE OR REPLACE PACKAGE BODY IPTV."TGC_BILL_POST" Is

   function tgc_invo_post(p_user_no Number,p_pk_no Number,p_no_commit varchar2 default 'N') return Varchar2 Is
     exception_msg Varchar2(256);
     app_exception Exception;
     v_status_flg Varchar2(32);
     v_mas_code Varchar2(32);
     v_mas_no Varchar2(32);
     v_mas_date Date;
     v_src_no varchar2(32);
     v_contract_no Varchar2(32);
     v_package_key Number(16);
     v_f_year Number(16);
     v_f_period Number(4);
     v_acc_status_flg Varchar2(1);
     v_tax_code varchar2(32);
     v_tax_flg varchar2(32);

  Begin
     begin
       Select mas_code,mas_no,mas_date,status_flg,src_no,contract_no,package_key,f_year,f_period,tax_code,tax_flg
          Into v_mas_code,v_mas_no,v_mas_date,v_status_flg,v_src_no,v_contract_no,v_package_key,v_f_year,v_f_period,v_tax_code,v_tax_flg
        From service_invo_mas
        Where pk_no=p_pk_no;
     exception
        when no_data_found then
          exception_msg := '#找不到帳單單據資料'||to_char(p_pk_no)||'#';
          raise app_exception;
     end;
      If v_status_flg <> 'A' Then
       exception_msg := '#錯誤的單據狀態#';
       Raise app_exception;
     End If;

     If v_contract_no Is Null Then
        v_contract_no := tgc_util.get_con_from_pk(v_package_key);
     End If;

     Begin
        Select status_flg Into v_acc_status_flg From acc_period_mas a
        Where a.f_year=v_f_year And f_period=v_f_period;
        If v_acc_status_flg not in ('O','S') Then
                 exception_msg := '#帳期未開啟#';
                Raise app_exception;
        End If;
     Exception
        When no_data_found Then
                  exception_msg := '#沒有帳期設定#';
                Raise app_exception;
     End;

     if v_tax_flg = 'Y' then
         if v_tax_code is null then
            exception_msg := '#'||v_mas_no||'設定單頭的發票種類#';
            Raise app_exception;
         end if;
     end if;

      Declare
             v_acc_pk_no Number(16);
             v_srp_key Number(16);
             Cursor c1 Is Select b.pk_no pk_no,b.amount,b.chg_type,b.chg_code,b.chg_pk_no,b.start_date,b.end_date,b.pm_code,a.mas_no,a.pk_no mas_pk_noa,a.mas_code,a.mas_date,a.f_year,a.f_period,a.src_no,a.src_code,a.acc_code,a.acc_user_no,a.src_pk_no,a.package_key,a.due_date
                                  From service_invo_dtl b,service_invo_mas a
                                             Where mas_pk_no = p_pk_no And b.mas_pk_no=a.pk_no;

      Begin
         Delete service_invo_item_clr where mas_pk_no = p_pk_no;
         For c1rec In c1 Loop
           If c1rec.chg_type Not In ( 'B') Then
               if c1rec.chg_code is null then
                   exception_msg := '#chg_code的錯誤#';
                   Raise app_exception;
               end if;
               If c1rec.chg_pk_no Is Not Null And c1rec.chg_pk_no <> 0 Then
                  Select srp_key Into v_srp_key From service_chg_detail
                     Where pk_no=c1rec.chg_pk_no;
               else
                  select max(srp_key) into v_srp_key from service_detail where package_key=c1rec.package_key
                    and item_code like '%KA%'
                    and status_flg='P';
                 if v_srp_key is null then
                   select max(srp_key) into v_srp_key from service_detail where package_key=c1rec.package_key
                    and item_code like '%KA%'
                    and status_flg='A';
                 end if;

               End If;
               Select seq_sys_no.Nextval Into v_acc_pk_no From dual;
               Insert Into service_acc_detail(pk_no,acc_code,acc_user_no,src_pk_no,src_code,src_no,dr,cr,open_amount,open_flg,
               ref_pk_no,chg_pk_no,pm_code,chg_code,chg_type,f_year,f_period,service_invo_no,src_date,acc_type,package_key,srp_key,start_date,end_date,src_item_pk_no,due_date)
               Values
               (v_acc_pk_no,c1rec.acc_code,c1rec.acc_user_no,c1rec.mas_pk_noa,c1rec.mas_code,c1rec.mas_no,null,c1rec.amount,c1rec.amount,'Y',
                Null,c1rec.chg_pk_no,c1rec.pm_code,c1rec.chg_code,c1rec.chg_type,c1rec.f_year,c1rec.f_period,Null,c1rec.mas_date,'C',c1rec.package_key,v_srp_key,c1rec.start_date,c1rec.end_date,c1rec.pk_no,c1rec.due_date);

               -- 預付款自動扣底沖帳
               declare
                cursor c2 is select '1',src_date,src_pk_no,src_item_pk_no,acc_code,open_amount,pk_no from service_acc_detail a where src_code='SRVCHK'
                and open_flg='Y'
                and open_amount > 0
                and a.package_key=v_package_key
                union all
                select '2',src_date,src_pk_no,src_item_pk_no,acc_code,open_amount,pk_no from service_acc_detail a where src_code='SRVCHK'
                and open_flg='Y'
                and open_amount > 0
                and a.package_key<>v_package_key
                and a.acc_code=c1rec.acc_code
                order by 1,2;
                v_amount number(16);
                v_chk_amount number(16);
                v_seq_pk_no number(16);
               begin

                 v_amount := c1rec.amount;
                 if v_amount > 0 then
                 for c2rec in c2 loop
                     v_chk_amount := 0;
                     if v_amount > 0 then
                        if v_amount > c2rec.open_amount then
                           v_chk_amount := c2rec.open_amount;
                           v_amount := v_amount - v_chk_amount;
                        elsif v_amount = c2rec.open_amount then
                           v_chk_amount := v_amount;
                           v_amount := 0;
                        elsif v_amount < c2rec.open_amount then
                           v_chk_amount :=  v_amount;
                           v_amount := 0;
                        end if;
                     end if;

                     if v_chk_amount > 0 then
                        update service_acc_detail
                        set open_flg=decode(open_amount-v_chk_amount,0,'N','Y'),
                            open_amount = open_amount-v_chk_amount
                        where pk_no = c2rec.pk_no;


                        Select seq_sys_no.Nextval  Into v_seq_pk_no From dual;

                        Insert Into service_chk_item_clr(mas_pk_no,item_pk_no,pk_no,detail_pk_no,acc_code,clr_amt,gl_amt,create_date,ref_acc,inv_crt_flg)
                        Values (c2rec.src_pk_no,c2rec.src_item_pk_no,v_seq_pk_no,v_acc_pk_no,c1rec.acc_code,v_chk_amount,c1rec.amount,Sysdate,Null,'Y');

                        Select seq_sys_no.Nextval  Into v_seq_pk_no From dual;

                        Insert Into service_invo_item_clr(mas_pk_no,item_pk_no,pk_no,detail_pk_no,acc_code,clr_amt,gl_amt,create_date,ref_acc,chk_crt_flg)
                        Values (c1rec.mas_pk_noa,c1rec.pk_no,v_seq_pk_no,v_acc_pk_no,c1rec.acc_code,v_chk_amount,c1rec.amount,Sysdate,Null,'Y');

                     end if;

                 end loop;

                 if v_amount <> 0 then
                   update service_acc_detail
                    set open_flg='Y',open_amount = v_amount
                    where pk_no = v_acc_pk_no;
                 elsif v_amount = 0 then
                   update service_acc_detail
                     set open_flg ='N',open_amount = 0
                   where pk_no =v_acc_pk_no;
                 end if;
                end if;
               end;

           End If;

         End Loop;
      End;

       Update service_invo_mas a
         Set status_flg ='P' ,
         contract_no = v_contract_no,
         a.amount=(Select Sum(amount) From service_invo_dtl Where mas_pk_no=p_pk_no),
         a.net_amount=(Select Sum(amount) From service_invo_dtl Where mas_pk_no=p_pk_no And chg_type Not In ('B','P'))
        Where pk_no=p_pk_no;

        Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('SRVINVO',  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'Post');
     if p_no_commit ='N' then
        Commit;
     end if;
   Return Null;

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;


   function tgc_invo_unpost(p_user_no Number,p_pk_no Number) return Varchar2 Is
     exception_msg Varchar2(256);
     app_exception Exception;
     v_status_flg Varchar2(32);
     v_mas_code Varchar2(32);
     v_mas_no Varchar2(32);
     v_mas_date Date;
     v_src_no varchar2(32);
     v_clr_count Number(16);
     v_acc_status_flg Varchar2(32);
     v_f_period Number(16);
     v_f_year Number(16);

  Begin

     Select mas_code,mas_no,mas_date,status_flg,src_no,f_year,f_period
        Into v_mas_code,v_mas_no,v_mas_date,v_status_flg,v_src_no,v_f_year,v_f_period
      From service_invo_mas
      Where pk_no=p_pk_no;

     If v_status_flg <> 'P' Then
       exception_msg := '#錯誤的單據狀態#';
       Raise app_exception;
     End If;

     Begin
        Select status_flg Into v_acc_status_flg From acc_period_mas a
        Where a.f_year=v_f_year And f_period=v_f_period;
        If v_acc_status_flg not in ('O','S') Then
                 exception_msg := '#帳期未開啟#';
                Raise app_exception;
        End If;
     Exception
        When no_data_found Then
                  exception_msg := '#沒有帳期設定#';
                Raise app_exception;
     End;

     Delete service_invo_item_clr where mas_pk_no = p_pk_no;
     Select Count(*) Into v_clr_count
     From service_acc_detail Where src_pk_no = p_pk_no And OPEN_AMOUNT <> CR ;

     If v_clr_count > 0 Then
       exception_msg:= '#資料已被沖銷#';
       Raise app_exception;
     End If;

      Select Count(*) Into v_clr_count
      From service_acc_detail Where src_pk_no = p_pk_no And OPEN_FLG = 'N' and cr <> 0 ;

     If v_clr_count > 0 Then
       exception_msg:= 'service_acc_detail資料已被關閉';
       Raise app_exception;
     End If;

      Delete service_acc_detail Where src_pk_no = p_pk_no;


       Update service_invo_mas
         Set status_flg ='A'
        Where pk_no=p_pk_no;

        Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('SRVINVO',  p_Pk_No,  Sysdate, p_User_No, 'unpost'  ,Sys_Event_Seq.Nextval, 'unpost');
   Commit;
   Return Null;

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;

   function tgc_invo_cancel(p_user_no Number,p_pk_no Number) return Varchar2 Is
     exception_msg Varchar2(256);
     app_exception Exception;
     v_status_flg Varchar2(32);
     v_mas_code Varchar2(32);
     v_mas_no Varchar2(32);
     v_mas_date Date;
     v_src_no varchar2(32);
     v_clr_count Number(16);
     v_acc_status_flg Varchar2(32);
     v_f_period Number(16);
     v_f_year Number(16);

  Begin

     Select mas_code,mas_no,mas_date,status_flg,src_no,f_year,f_period
        Into v_mas_code,v_mas_no,v_mas_date,v_status_flg,v_src_no,v_f_year,v_f_period
      From service_invo_mas
      Where pk_no=p_pk_no;

     If v_status_flg <> 'A' Then
       exception_msg := '#錯誤的單據狀態#';
       Raise app_exception;
     End If;

       Update service_invo_mas
         Set status_flg ='C'
        Where pk_no=p_pk_no;

        Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('SRVINVO',  p_Pk_No,  Sysdate, p_User_No, 'cancel'  ,Sys_Event_Seq.Nextval, 'cancel');
   Commit;
   Return Null;

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;

   function chk_service_flg(p_package_key number) return varchar2
   is
     cursor c1 is select status_flg,cust_code,tcd_tsn tsn,item_code
                    from service_detail where package_key in p_package_key;
     v_result varchar2(32) default 'N';
     v_cnt number(16);
   begin
     v_result := 'N';
     for c1rec in c1 loop
         if c1rec.status_flg in ( 'P','A') then
            if (c1rec.tsn is not null) and (upper(substr(c1rec.tsn,1,3))='1E2')
            then
               begin
                 select cnt into v_cnt
                 from tgc_trn_owner_view
                 where cust_id = c1rec.cust_code
                   and tsn = c1rec.tsn;
                 if v_cnt > 0 then
                    v_result := 'Y';
                 else
                    v_result := 'N';
                    -- 檢查是否有另外一台
                    declare
                      cursor c3 is Select TSN from tgc_trn_owner_view
                      where cust_id = c1rec.cust_code
                      and tsn <> c1rec.tsn
                      and tsn is not null
                      and cnt > 0;
                      v_char varchar2(32);
                    begin
                      for c3rec in c3 loop
                          begin
                              select 'x' into v_char
                              from service_detail
                              where TCD_TSN=c3rec.tsn
                                and status_flg in ('P','A')
                                and rownum <= 1;
                              v_Result := 'N';
                          exception
                             when no_data_found then v_Result := 'Y';
                          end;
                      end loop;
                    end;
                 end if;
               exception
                 when no_data_found then
                 --
                 -- 服務兩個人同時使用則不出帳
                 --
                 declare
                   v_char varchar2(32);
                 begin
                  select 'x' into v_char
                              from service_detail
                              where TCD_TSN=c1rec.tsn
                                and cust_code <> c1rec.cust_code
                                and status_flg in ('P','A')
                                and rownum <= 1;
                   v_result := 'N';
                  exception
                     when no_data_found then v_result := 'Y';
                  end;
               end;
               if c1rec.tsn in ('1E200018002EB4A',
'1E2000180022438',
'1E2000180022F73',
'1E2000180022EDF',
'1E200018001902A',
'1E2000180028266',
'1E20001800292B3',
'1E200018003BAFE',
'1E2000180019535',
'1E20001800303FB',
'1E2000180030CEA',
'1E2000180029669',
'1E200018004D08A',
'1E2000180028995',
'1E2000180018D8A',
'1E200018001D68F',
'1E2000180029029',
'1E2000180019E5A',
'1E200018001DF19',
'1E2000180017FA0',
'1E2000180019308',
'1E200018002879F',
'1E20001800282C3',
'1E2000180016180',
'1E2000180028A4E',
'1E2000180027D7A',
'1E200018001A220',
'1E20001800284A2',
'1E2000180027938',
'1E20001800278E4',
'1E2000180028FB6'

) then
                    v_result := 'N';
             end if;

             declare
                v_char varchar2(1);
             begin
                select 'x' into v_char from tgc_vip_mas where (cust_code=c1rec.cust_code
                or tsn=c1rec.tsn ) and rownum <= 1;
                v_result :='N';
             exception
                when no_data_found then null;
             end;


            else
              v_result := 'Y';
            end if;
         end if;
     end loop;
     return v_result;
   end;


   function tgc_bill_transfer(p_user_no Number,p_pk_no Number,p_bill_flg Varchar2 Default Null) return Varchar2
   Is
     exception_msg Varchar2(256);
     app_exception Exception;
     v_start_date Date;
     v_end_date Date;
     v_bill_date Date;
     v_status_flg Varchar2(32);
     v_chg_code Varchar2(32);
     v_service_detail_status Varchar2(32);
     v_f_year number(4);
     v_f_period number(2);
   Begin

     Delete service_bill_dtl Where mas_pk_no = p_pk_no;
     Delete service_bill_item Where mas_pk_no = p_pk_no;

     Begin
           Select start_bill_date,end_bill_date,bill_date,status_flg,f_year,f_period
              Into v_start_date,v_end_date,v_bill_date,v_status_flg,v_f_year,v_f_period
              From service_bill_mas
             Where pk_no = p_pk_no;
     Exception
        When no_data_found Then
             exception_msg := '#找不到單據資料#';
             Raise app_exception;
     End;

     If v_status_flg <> 'A' Then
       exception_msg := '#錯誤的單據狀態#';
       Raise app_exception;
     End If;

     Declare
        Cursor c1 Is Select a.acc_code,a.acc_user_no,b.package_key From service_chg_detail a,service_detail b
                            Where  a.status_flg='P' And
                            ((a.chg_type = 'O' And a.Start_Date Is Not Null And (a.start_bill_date Is Not Null  And a.Start_bill_date <= v_end_date) )
                            Or (a.chg_type='R'  And a.bill_type='O'
                            And (((a.start_bill_date Is Not Null And a.Start_Bill_Date <= v_end_date)
                            And ( a.start_date Is Not Null And add_months(a.start_date ,a.pay_period) -1 <=v_end_date And a.next_bill_date Is Null))
                                      Or (a.next_bill_date Is Not Null And a.next_bill_date <= v_start_date)))
                             Or (a.chg_type='R' And a.bill_type='P'
                             And (((a.start_bill_date Is Not Null And a.Start_bill_date <= add_months(v_bill_date+a.terms,1))
                             And (a.start_date Is Not Null And a.start_date<= add_months(v_bill_date+nvl(a.terms,14),1) And a.next_bill_date Is Null))
                                     Or (a.next_bill_date Is Not Null And a.next_bill_date-1 < add_months(v_bill_date+nvl(a.terms,14),1) )))
                             Or (a.chg_type='P' And a.bill_type='P'
                             And (((a.start_bill_date Is Not Null And a.Start_bill_date <= add_months(v_bill_date+a.terms,1))
                             And (a.start_date Is Not Null And a.start_date<= add_months(v_bill_date+nvl(a.terms,14),1) And a.next_bill_date Is Null))
                                     Or (a.next_bill_date Is Not Null And a.next_bill_date-1 < add_months(v_bill_date+nvl(a.terms,14),1) )))
                           )
                           And a.srp_key=b.srp_key
                       --    And a.acc_code In (Select cust_id From tgc_customer Where bill_flg = 'TEST1')
                           Group By a.acc_code,a.acc_user_no,b.package_key;
        v_item_pk_no Number(16);
        v_acc_user_no Number(16);
        v_package_key Number(16);

          Cursor c2 Is Select a.pk_no,a.chg_group_no,a.chg_code,a.chg_type,a.pm_code,a.pay_period,a.net_price,a.tax_flg,a.tax_code,a.bill_type
                                        ,a.next_bill_date,a.start_date,a.stop_bill_date,terms,b.package_key,a.ref1,a.ref2,a.ref3,a.ref4
                               From service_chg_detail a,service_detail b
                            Where a.status_flg='P' And
                            ((a.chg_type = 'O' And a.Start_Date Is Not Null And (a.start_bill_date Is Not Null  And a.Start_bill_date <= v_end_date) )
                            Or (a.chg_type='R'  And a.bill_type='O'
                            And (((a.start_bill_date Is Not Null And a.Start_Bill_Date <= v_end_date)
                            And ( a.start_date Is Not Null And add_months(a.start_date ,a.pay_period) -1 <=v_end_date And a.next_bill_date Is Null))
                                      Or (a.next_bill_date Is Not Null And a.next_bill_date <= v_start_date)))
                             Or (a.chg_type='R' And a.bill_type='P'
                             And (((a.start_bill_date Is Not Null And a.Start_bill_date <= add_months(v_bill_date+a.terms,1))
                             And (a.start_date Is Not Null And a.start_date<= add_months(v_bill_date+nvl(a.terms,14),1) And a.next_bill_date Is Null))
                                     Or (a.next_bill_date Is Not Null And a.next_bill_date-1 < add_months(v_bill_date+nvl(a.terms,14),1) )))
                             Or (a.chg_type='P' And a.bill_type='P'
                             And (((a.start_bill_date Is Not Null And a.Start_bill_date <= add_months(v_bill_date+nvl(a.terms,14),1))
                             And (a.start_date Is Not Null And a.start_date<= add_months(v_bill_date+nvl(a.terms,14),1) And a.next_bill_date Is Null))
                                     Or (a.next_bill_date Is Not Null And a.next_bill_date-1 < add_months(v_bill_date+nvl(a.terms,14),1) )))
                              )
                           And a.acc_user_no= v_acc_user_no
                           And a.srp_key=b.srp_key
                           And b.package_key=v_package_key;
                v_address Varchar2(512);
                v_chg_code Varchar2(512);
                v_tel Varchar2(256);
                v_net_price Number(16);
                v_amount Number(16);
                v_dtl_start_date Date;
                v_dtl_end_date Date;
                v_terms Varchar2(16);
                v_tax_flg Varchar2(32);
                v_tax_code Varchar2(32);
                v_p_chg_code Varchar2(32);
                v_p2_chg_code Varchar2(32);
                v_bill_flg Varchar2(32);
                v_zip Varchar2(32);
                v_cust_terms number(16);
                v_ref28 Varchar2(256); -- 暫停 flg
                v_tivo_flg varchar2(32);

/*         Cursor c3 Is Select acc_code,acc_user_no,package_key,Sum(decode(DR,null,Open_amount,-1*Open_amount)) open_amount
                                       ,chg_code
                              From service_acc_detail
                              Where open_flg='Y'
                             Group By acc_code,acc_user_no,package_key
                             Having Sum(decode(DR,null,Open_amount,-1*Open_amount)) >  0;*/

            Cursor c3 Is Select acc_code,acc_user_no,package_key,Sum(decode(DR,null,Open_amount,-1*Open_amount)) open_amount
,chg_code,min(a.start_date) start_date,max(a.end_date) end_date,min(nvl(due_date,sysdate)) due_date
                              From service_acc_detail a
                              Where open_flg='Y'
                              and f_year*100+f_period < v_f_year*100+v_f_period
                              and acc_type='C'
                              and package_key not in
                              (select package_key from service_acc_detail
                              where src_code='SRVINVO'
                              and dr is null
                              and acc_type='C'
                              And nvl(due_date,sysdate) <= sysdate
                              and f_year=v_f_year
                              and f_period=v_f_period)
                             and ((a.src_code <> 'SRVCHK' and nvl(a.chg_code,'X') in (Select chg_code from service_charge_mas where chg_type='R'))
                             or (a.src_code = 'SRVCHK'))
                              and open_amount <> 0
                              and decode(a.src_code,'SRVCHK',to_date('19990101','YYYYMMDD'),nvl(due_date,sysdate)) <= sysdate-7
                             Group By acc_code,acc_user_no,package_key,chg_code
                             Having Sum(decode(DR,null,Open_amount,-1*Open_amount)) <>  0
                             and package_key is not null
                             and nvl(chg_code,'X') not in ('INFO_SERVICE_BUY','PREPAY_INFO');
                         --    and 1=2; --資訊服務費不吹
      Begin
        For c1rec In c1 Loop

           v_acc_user_no := c1rec.acc_user_no;

          Begin
             Select zip,address,dayphone,bill_flg,ref28,acc_terms,nvl(acc_terms,14)
              Into v_zip, v_address,v_tel,v_bill_flg,v_ref28,v_terms,v_cust_terms
               From tgc_customer
             Where user_no = v_acc_user_no;
          Exception
             When no_data_found Then
                 exception_msg := '找不到客戶資料';
                 Raise app_exception;
           End;

           if chk_service_flg(c1rec.package_key)='Y' then
             begin
             select status_flg into v_service_detail_status
             from service_detail where srp_key =c1rec.package_key and status_flg='P'
             ;
             exception
               when no_data_found then
                 begin
                 select status_flg into v_service_detail_status
                  from service_detail
                  where package_key =c1rec.package_key and status_flg='P' and rownum<=1;

                   exception
                    when no_data_found then  v_service_detail_status := 'N';
                 end;

             end;
           else
             v_service_detail_status := 'N';
           end if;




           If( ((v_bill_flg Is Null And p_bill_flg Is Null) Or (v_bill_flg Is Not Null And v_bill_flg = p_bill_flg)) And
             (v_ref28 Is Null Or v_ref28 <> 'B')
             ) And (v_service_detail_status = 'P') Then

                    Select seq_sys_no.Nextval Into v_item_pk_no From dual;
                    v_acc_user_no := c1rec.acc_user_no;
                    v_package_key := c1rec.package_key;
                    v_tax_flg := 'N';
                    v_tax_code := Null;

                    Insert Into service_bill_item(mas_pk_no,pk_no,cust_id,cust_no,bill_zip,bill_address,bill_tel,bill_no,bill_amt,package_key)
                    Values(p_pk_no,v_item_pk_no,c1rec.acc_code,c1rec.acc_user_no,v_zip,v_address,v_tel,'0',0,c1rec.package_key);

                    v_amount := 0;

                    For c2rec In c2 Loop
                        If c2rec.bill_type = 'P' And c2rec.chg_type = 'R' Then -- prepay
                           --
                           -- Edward Modify
                           -- Prepay :Due_date =  service start date
                           v_dtl_start_date := nvl(c2rec.next_bill_date,c2rec.Start_date);
                           v_dtl_end_date := add_months(Nvl(c2rec.Next_bill_date,c2rec.start_date),c2rec.pay_period)-1;
                           if v_dtl_start_date <= v_bill_date+v_cust_terms then
                              v_terms := v_cust_terms;
                           else
                              v_terms :=round( v_dtl_start_date - v_bill_date+1);
                           end if;
                           if c2rec.net_price <> 0 then
                               Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                               ,bill_type,amount,tax_flg,tax_code,period,cal_type,Start_date,end_date,ref1,ref2,ref3,ref4)
                               Values(p_pk_no,v_item_pk_no,c2rec.pk_no,c2rec.chg_group_no,c2rec.chg_code,c2rec.pm_code,c2rec.chg_type
                               ,c2rec.bill_type,c2rec.net_price,c2rec.tax_flg,c2rec.tax_code,0,'PrePay',v_dtl_start_date,v_dtl_end_date,c2rec.ref1,c2rec.ref2,c2rec.ref3,c2rec.ref4);
                           end if;
                            v_amount := v_amount+c2rec.net_price;
                        Elsif    c2rec.bill_type = 'P' And c2rec.chg_type = 'P' Then
                           v_dtl_start_date := nvl(c2rec.next_bill_date,c2rec.Start_date);
                           v_dtl_end_date := add_months(Nvl(c2rec.Next_bill_date,c2rec.start_date),c2rec.pay_period)-1;
                           if v_dtl_start_date <= v_bill_date+v_cust_terms then
                              v_terms := round(v_cust_terms);
                           else
                              v_terms := round(v_dtl_start_date - v_bill_date+1);
                           end if;
                           if c2rec.net_price <> 0 then
                                 Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                                 ,bill_type,amount,tax_flg,tax_code,period,cal_type,Start_date,end_date,ref1,ref2,ref3,ref4)
                                 Values(p_pk_no,v_item_pk_no,c2rec.pk_no,c2rec.chg_group_no,c2rec.chg_code,c2rec.pm_code,c2rec.chg_type
                                 ,c2rec.bill_type,c2rec.net_price,c2rec.tax_flg,c2rec.tax_code,0,'PrePay',v_dtl_start_date,v_dtl_end_date,c2rec.ref1,c2rec.ref2,c2rec.ref3,c2rec.ref4);
                           end if;
                           v_amount := nvl(v_amount,0) + c2rec.net_price;
                        Elsif c2rec.chg_type = 'O' Then -- One time charge

                           v_dtl_start_date := nvl(c2rec.next_bill_date,c2rec.Start_date);
                           v_dtl_end_date := add_months(Nvl(c2rec.Next_bill_date,c2rec.start_date),c2rec.pay_period)-1;
                           if c2rec.net_price <> 0 then
                               Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                               ,bill_type,amount,tax_flg,tax_code,period,cal_type,Start_date,end_date,ref1,ref2,ref3,ref4)
                               Values(p_pk_no,v_item_pk_no,c2rec.pk_no,c2rec.chg_group_no,c2rec.chg_code,c2rec.pm_code,c2rec.chg_type
                               ,c2rec.bill_type,c2rec.net_price,c2rec.tax_flg,c2rec.tax_code,0,'OneTime',v_dtl_start_date,v_dtl_end_date,c2rec.ref1,c2rec.ref2,c2rec.ref3,c2rec.ref4);
                           end if;
                           v_amount := v_amount+c2rec.net_price;

                        Elsif c2rec.chg_type='R' And c2rec.bill_type='O' And c2rec.next_bill_date Is Null Then -- First Bill
                             v_net_price := ((to_number(to_char(v_end_date,'YYYY'))-to_number(to_char(c2rec.start_date,'YYYY')))*12 +
                                                   (to_number(to_char(v_end_date,'MM'))-to_number(to_char(c2rec.start_date,'MM')))+
                                                   ((last_day(c2rec.start_date)-c2rec.start_date+1)/to_number(to_char(last_day(c2rec.start_date),'DD'))) ) * (c2rec.net_price/c2rec.pay_period);
                         --    v_net_price := trunc((v_end_date - c2rec.start_date+1)*(c2rec.net_price/(c2rec.pay_period*30)));

                             v_dtl_start_date := c2rec.start_date;
                             v_dtl_end_date := add_months(v_end_date,c2rec.pay_period-1);

                             -- stop_billing date not null
                             If c2rec.stop_bill_date Is Not Null Then
                                If c2rec.stop_bill_date < v_end_date Then
                                                   v_net_price := v_net_price -(
                                                    ((to_number(to_char(v_end_date,'YYYY'))-to_number(to_char(c2rec.stop_bill_date,'YYYY')))*12 +
                                                   (to_number(to_char(v_end_date,'MM'))-to_number(to_char(c2rec.stop_bill_date,'MM')))+
                                                   ((last_day(c2rec.stop_bill_date)-c2rec.stop_bill_date)/to_number(to_char(last_day(c2rec.stop_bill_date),'DD'))) ) * (c2rec.net_price/c2rec.pay_period)
                                                   );
                                     v_dtl_end_date :=c2rec.stop_bill_date;
                                End If;
                             End If;
                             if v_net_price <> 0 then
                                 Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                                 ,bill_type,amount,tax_flg,tax_code,period,cal_type,Start_date,end_date,ref1,ref2,ref3,ref4)
                                 Values(p_pk_no,v_item_pk_no,c2rec.pk_no,c2rec.chg_group_no,c2rec.chg_code,c2rec.pm_code,c2rec.chg_type
                                       ,c2rec.bill_type,v_net_price,c2rec.tax_flg,c2rec.tax_code,0,'FirstBill',v_dtl_start_date,v_dtl_end_date,c2rec.ref1,c2rec.ref2,c2rec.ref3,c2rec.ref4);
                             end if;
                             v_amount := v_amount + v_net_price;

                        Elsif c2rec.chg_type='R' And c2rec.bill_type='O' And c2rec.next_bill_date Is Not Null Then   -- recurrrent date
                             v_dtl_start_date := nvl(c2rec.next_bill_date,c2rec.start_date);
                             v_dtl_end_date := v_end_date;

                             -- stop_bill date not null
                               If c2rec.stop_bill_date Is Not Null Then
                                If c2rec.stop_bill_date < v_end_date Then
                                                   v_net_price := v_net_price -(
                                                    ((to_number(to_char(v_end_date,'YYYY'))-to_number(to_char(c2rec.stop_bill_date,'YYYY')))*12 +
                                                   (to_number(to_char(v_end_date,'MM'))-to_number(to_char(c2rec.stop_bill_date,'MM')))+
                                                   ((last_day(c2rec.stop_bill_date)-c2rec.stop_bill_date)/to_number(to_char(last_day(c2rec.stop_bill_date),'DD'))) ) *( c2rec.net_price/c2rec.pay_period)
                                                   );
                                     v_dtl_end_date :=c2rec.stop_bill_date;
                                End If;
                             End If;
                            if c2rec.net_price <> '0' then
                                Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                                  ,bill_type,amount,tax_flg,tax_code,period,cal_type,Start_date,end_date,ref1,ref2,ref3,ref4)
                                Values(p_pk_no,v_item_pk_no,c2rec.pk_no,c2rec.chg_group_no,c2rec.chg_code,c2rec.pm_code,c2rec.chg_type
                                 ,c2rec.bill_type,c2rec.net_price,c2rec.tax_flg,c2rec.tax_code,0,'Recurrent',v_dtl_start_date,v_dtl_end_date,c2rec.ref1,c2rec.ref2,c2rec.ref3,c2rec.ref4);
                            end if;

                           v_amount := v_amount+c2rec.net_price;

                        End If;

                        If c2rec.tax_flg = 'Y' Then
                           v_tax_flg := 'Y';
                           v_tax_code := c2rec.tax_code;
                        End If;

                        if v_bill_date > v_dtl_start_date then
                          If nvl(v_terms,c2rec.terms) >= c2rec.terms Then
                             v_terms := c2rec.terms;
                          End If;
                        else
                             If nvl(v_terms,c2rec.terms) <= c2rec.terms Then
                               v_terms := c2rec.terms;
                             End If;
                        end if;

                    End Loop;
                    dbms_output.put_line(c1rec.acc_code||v_terms);

                    Update service_bill_item a
                         Set a.bill_amt = v_amount,
                                terms = v_terms,
                                tax_flg = v_tax_flg,
                                tax_code = v_tax_code
                      Where pk_no= v_item_pk_no;
                     End If; -- end if bill_flg
                  End Loop;

                  --
                  --  前期餘額
                  --
                  v_p_chg_code := sysapp_util.get_sys_value('TGCBILL','前期未繳','B');
                  v_p2_chg_code := sysapp_util.get_sys_value('TGCBILL','前期溢繳','A');


                  For c3rec In c3 Loop

                       Begin
                             v_package_key :=c3rec.package_key;
                             if chk_service_flg(c3rec.package_key )='Y' then
                               v_service_detail_status:='P';
                            else
                               v_service_detail_status := 'N';
                            end if;
                  /*
                             Begin
                                Select status_flg Into v_service_detail_status From service_detail Where package_key = c3rec.package_key And rownum <= 1 ;
                             Exception
                                When no_data_found Then
                                   Begin
                                      Select status_flg,package_key Into v_service_detail_status,v_package_key From service_detail Where srp_key = c3rec.package_key And rownum <= 1 ;
                                   Exception
                                       When no_data_found Then v_service_detail_status := 'N';
                                          v_package_key:=c3rec.package_key;

                                   --     exception_msg := '找不到服務'||to_char(c3rec.package_key);
                                   --    Raise app_exception;
                                   End;
                               End;*/
                          Select pk_no Into v_item_pk_no
                             From service_bill_item a
                           Where mas_pk_no=p_pk_no
                               And a.cust_id=c3rec.acc_code
                               And a.package_key=v_package_key
                               And rownum<=1;

                          Select bill_flg,ref28 Into v_bill_flg,v_ref28
                                   From tgc_customer
                                 Where user_no = c3rec.acc_user_no;

                        Exception
                           When no_data_found Then
                              Begin
                                 Select zip,address,dayphone,bill_flg,ref28,tax_code Into v_zip, v_address,v_tel,v_bill_flg,v_ref28,v_tax_code
                                   From tgc_customer
                                 Where user_no = c3rec.acc_user_no;
                              Exception
                                 When no_data_found Then
                                     exception_msg := '找不到客戶資料'||to_char(c3rec.acc_user_no);
                                     Raise app_exception;
                               End;
                              If (((v_bill_flg Is Null And p_bill_flg Is Null) Or (v_bill_flg Is Not Null And v_bill_flg = p_bill_flg)) And
                                 (v_ref28 Is Null Or v_ref28<>'B')) And (v_service_detail_status='P') Then

                                            Select seq_sys_no.Nextval Into v_item_pk_no From dual;
                                            v_acc_user_no := c3rec.acc_user_no;

                                              Insert Into service_bill_item(mas_pk_no,pk_no,cust_id,cust_no,bill_zip,bill_address,bill_tel,bill_no,bill_amt,package_key,terms,tax_flg,tax_code)
                                              Values(p_pk_no,v_item_pk_no,c3rec.acc_code,c3rec.acc_user_no,v_zip,v_address,v_tel,'0',0,v_package_key,'10','Y',v_tax_code);
                                End If;
                              End;

                              If (((v_bill_flg Is Null And p_bill_flg Is Null) Or (v_bill_flg Is Not Null And v_bill_flg = p_bill_flg)) And
                                 (v_ref28 Is Null Or v_ref28<>'B')) And (v_service_detail_status='P')  Then

                                       --
                                       -- 20090211 modify
                                       --
                                       If c3rec.chg_code in ('INFO_SERVICE_BUY','PREPAY_INFO') Then
                                          v_chg_code := c3rec.chg_code;
                                          v_start_date := c3rec.start_date;
                                          v_end_date := c3rec.end_date;
                                       Elsif c3rec.open_amount < 0 Then
                                          v_chg_code := v_p2_chg_code;
                                          v_start_date := Null;
                                          v_end_date := Null;
                                       Else
                                         v_chg_code := v_p_chg_code;
                                          v_start_date := c3rec.start_date;
                                          v_end_date := c3rec.end_date;
                                       End If;
                                      Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                                                ,bill_type,amount,tax_flg,tax_code,period,cal_type,start_date,end_date)
                                               Values(p_pk_no,v_item_pk_no,0,0,v_chg_code,'SALE','B'
                                                     ,'O',c3rec.open_amount,'N','OUTTAX1',0,Null,v_start_date,v_end_date);


                                        If c3rec.chg_code in ('INFO_SERVICE_BUY','PREPAY_INFO') Then
                                            Update service_bill_item a
                                                 Set   terms = '10'
                                              Where pk_no= v_item_pk_no;
                                       End If;
                                       --
/*                                       If c3rec.open_amount > 0 Then
                                            Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                                                ,bill_type,amount,tax_flg,tax_code,period,cal_type)
                                               Values(p_pk_no,v_item_pk_no,0,0,v_p_chg_code,Null,'B'
                                                     ,'O',c3rec.open_amount,Null,Null,0,Null);
                                        Elsif c3rec.open_amount < 0 Then
                                            Insert Into service_bill_dtl(mas_pk_no,item_pk_no,chg_pk_no,group_no,chg_code,pm_code,chg_type
                                                ,bill_type,amount,tax_flg,tax_code,period,cal_type)
                                               Values(p_pk_no,v_item_pk_no,0,0,v_p2_chg_code,Null,'B'
                                                     ,'O',c3rec.open_amount,Null,Null,0,Null);*/
/*                                         Elsif c3rec.open_amount = 0 Then
                                            Null;
                              End If;*/

                           End If;


               End Loop;

      End;


        Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('SRVBILL',  p_Pk_No,  Sysdate, p_User_No, 'Transfer'  ,Sys_Event_Seq.Nextval, 'Transfer');

      Commit;
      Return Null;
   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
    /*  When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);*/
   End;

   function tgc_bill_post(p_user_no Number,p_pk_no Number) return Varchar2
   Is
     exception_msg Varchar2(256);
     app_exception Exception;
     Cursor c1 Is Select chg_pk_no From service_bill_dtl
                           Where mas_pk_no=p_pk_no;
      v_chg_pk_no Number(16);
     Cursor c2 Is Select chg_type,pay_period,bill_type,stop_bill_date
                          From service_chg_detail Where pk_no = v_chg_pk_no;
     v_end_date Date;
     v_status_flg Varchar2(32);
   Begin
     Select end_bill_date,status_flg
      Into v_end_date,v_status_flg
       From service_bill_mas
       Where pk_no = p_pk_no;

     If v_status_flg <> 'A' Then
        exception_msg := '#錯誤的單據狀態#';
        Raise app_exception;
     End If;

     For c1rec In c1 Loop
           v_chg_pk_no := c1rec.chg_pk_no;
           For c2rec In c2 Loop
              If c2rec.chg_type = 'O' Then
                 Update service_chg_detail
                    Set status_flg = 'N'
                   Where pk_no = v_chg_pk_no;
              Elsif c2rec.chg_type = 'R' And c2rec.bill_type ='O' Then
                 If c2rec.stop_bill_date Is Not Null And
                    c2rec.stop_bill_date <= v_end_date Then
                    Update service_chg_detail
                    Set Next_bill_date =  v_end_date+1,
                    last_bill_date=Next_bill_date,
                    status_flg = 'N'
                  Where pk_no = c1rec.chg_pk_no;
                 Else
                   Update service_chg_detail b
                    Set Next_bill_date =  add_months(v_end_date,b.pay_period-1)+1,
                    last_bill_date=Next_bill_date
                  Where pk_no = c1rec.chg_pk_no;

                 End If;
              Elsif c2rec.chg_type='R' And c2rec.bill_type ='P' Then
                 Update Service_chg_detail
                    Set last_bill_date=Next_bill_date,
                       Next_bill_date=add_months(Nvl(Next_bill_date,start_date),nvl(pay_period,1))
                      Where pk_no=v_chg_pk_no;
              Elsif c2rec.chg_type='P' And c2rec.bill_type ='P' Then
                 Update Service_chg_detail
                    Set last_bill_date=Next_bill_date,
                       Next_bill_date=add_months(Nvl(Next_bill_date,start_date),nvl(pay_period,1)),
                       status_flg='P'
                      Where pk_no=v_chg_pk_no;
               Elsif c2rec.chg_type='P'  Then
                 Update Service_chg_detail
                    Set last_bill_date=Next_bill_date,
                       Next_bill_date=add_months(Nvl(Next_bill_date,start_date),nvl(pay_period,1))
                      Where pk_no=v_chg_pk_no;
              End If;
          End Loop;
     End Loop;

           Update service_bill_mas
         Set status_flg ='P'
        Where pk_no=p_pk_no;

        Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('SRVBILL',  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'Post');
   Commit;
   Return Null;

    Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;

   function tgc_bill_generate(p_user_no Number,p_pk_no Number) return Varchar2 Is
    exception_msg Varchar2(256);
     app_exception Exception;
     v_status_flg Varchar2(32);
     v_mas_code Varchar2(32);
     v_mas_no Varchar2(32);
     v_mas_date Date;
     v_invo_mas_no Varchar2(32);
     v_desc Varchar2(256);
     v_order_no Number(16);
     v_order_id Varchar2(32);
     v_address Varchar2(1024);
     v_cust_no Number(16);
     v_cust_id Varchar2(32);
     v_package_key Number(16);
     v_f_year Number(16);
     v_f_period Number(16);
     v_bill_date Date;

   Begin
     begin
        Select mas_code,mas_no,mas_date,status_flg,f_year,f_period,bill_date
           Into v_mas_code,v_mas_no,v_mas_date,v_status_flg,v_f_year,v_f_period,v_bill_date
        From service_bill_mas
        Where pk_no=p_pk_no;
     exception
        when no_data_found then
            exception_msg := '#找不到單據資料#';
            raise app_exception;
     end;


      If v_status_flg <> 'P' Then
       exception_msg := '#錯誤的單據狀態#';
       Raise app_exception;
     End If;

     Declare
        Cursor c1 Is Select mas_pk_no,pk_no,a.cust_id,a.cust_no,a.package_key,order_id,order_no,a.terms,a.tax_flg,a.tax_code,a.bill_amt
                              From service_bill_item a
                              Where a.mas_pk_no = p_pk_no
                              and (bill_no is null or bill_no = '0');
        v_invo_pk_no Number(16);
        v_item_pk_no Number(16);
        v_invo_dtl_no Number(16);
        v_contract_no Varchar2(16);
        v_product_id Varchar2(256);
        v_zip Varchar2(16);
        msg Varchar2(32);



        Cursor c2 Is Select * From service_bill_dtl b Where mas_pk_no = p_pk_no And b.item_pk_no = v_item_pk_no;
     Begin
       For c1rec In c1 Loop
               Select seq_sys_no.Nextval Into v_invo_pk_no From dual;

               v_cust_no := c1rec.cust_no;
               v_cust_id := c1rec.cust_id;
               v_package_key := c1rec.package_key;
               v_item_pk_no := c1rec.pk_no;
               Select max(product_id) Into v_product_id From service_detail Where package_key = c1rec.package_key;


               v_invo_mas_no := sysapp_util.get_mas_no(1,1,Sysdate,'SRVINVO',v_invo_pk_no);

                v_address := tgc_util.get_cust_address(v_package_key,'A');
                v_zip := tgc_util.get_cust_zip(v_package_key,'A');
                v_contract_no := tgc_util.get_con_from_pk(v_package_key);
                v_desc := v_cust_id||' '||tgc_util.get_cust_name(v_cust_id)||' '||to_char(v_f_year)||to_char(v_f_period)||'帳單';

               Insert Into service_invo_mas(src_pk_no,src_no,src_code,order_no,order_id,package_key,pk_no,mas_date,mas_no,
                acc_code,acc_user_no,address,zip,description,status_flg,mas_code,acc_terms,due_date,tax_flg,tax_code,f_year,f_period,contract_no,net_amount,product_id)
                Values(p_pk_no,v_mas_no,v_mas_code,v_order_no,v_order_id,v_package_key,v_invo_pk_no,Sysdate,v_invo_mas_no,
                v_cust_id,v_cust_no,v_address,v_zip,v_desc,'A','SRVINVO',c1rec.terms,nvl(v_bill_date,Sysdate)+c1rec.terms,c1rec.tax_flg,nvl(c1rec.tax_code,'OUTTAX1'),v_f_year,v_f_period,v_contract_no,c1rec.bill_amt,v_product_id);

               For c2rec In c2 Loop
                      Select seq_sys_no.Nextval Into v_invo_dtl_no From dual;

                      Insert Into service_invo_dtl(grp_no,mas_pk_no,pk_no,chg_pk_no,item_pk_no,chg_code,chg_type,bill_type,pm_code,amount,start_date,end_date,tax_flg,tax_code,ref1,ref2,ref3,ref4)
                        Values (c2rec.group_no,v_invo_pk_no,v_invo_dtl_no,c2rec.chg_pk_no,c2rec.item_pk_no,c2rec.chg_code,c2rec.chg_type,c2rec.bill_type,c2rec.pm_code,c2rec.amount,c2rec.start_date,c2rec.end_date,c2rec.tax_flg,c2rec.tax_code,c2rec.ref1,c2rec.ref2,c2rec.ref3,c2rec.ref4);
                      if c2rec.ref2 is not null then
                         update service_invo_mas
                            set ref1=c2rec.ref1
                          where pk_no=v_invo_pk_no;
                      end if;  

               End Loop;

               Update service_bill_item a
                  Set a.bill_no = v_invo_mas_no,a.bill_pk_no = v_invo_pk_no
                  Where pk_no=c1rec.pk_no;


       End Loop;
     End;


     Commit;
     Declare
        Cursor c3 Is Select bill_pk_no From service_bill_item Where mas_pk_no=p_pk_no;
        v_status_flg varchar2(32);
        msg Varchar2(256);
        v_invo_pk_no Number(26);
     Begin
             For c3rec In c3  Loop

              v_invo_pk_no := c3rec.bill_pk_no;
              select status_flg into v_status_flg
              from service_invo_mas where pk_no= v_invo_pk_no;

              if v_status_flg = 'A' then
                msg := tgc_invo_post(p_user_no,v_invo_pk_no);
              end if;
             End Loop;
      End;

       Update service_bill_mas
         Set status_flg ='N'
        Where pk_no=p_pk_no;

        Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values ('SRVBILL',  p_Pk_No,  Sysdate, p_User_No, 'Generatet'  ,Sys_Event_Seq.Nextval, 'Generate');
   Commit;

     Return Null;

  Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002,Sqlerrm);
              Return(Sqlerrm);
   End;

   Function tgc_chk_check(p_user_no Number,p_pk_no Number) Return Varchar2
   Is
    exception_msg Varchar2(256);
     app_exception Exception;
     Cursor c1 Is Select * From service_chk_item Where mas_pk_no = p_pk_no;
     Cursor c2(p_item_pk_no Number) Is Select * From service_chk_item_clr a Where a.item_pk_no=p_item_pk_no;
     v_item_amt Number(20,2);
     v_open_amount Number(20,2);
     v_open_flg Varchar2(32);

   Begin
     For c1rec In c1 Loop
       v_item_amt := 0;
       For c2rec In c2(c1rec.pk_no) Loop
         Begin
            Select a.open_amount,open_flg Into v_open_amount,v_open_flg
              From service_acc_detail a
             Where a.pk_no = c2rec.detail_pk_no;
             If v_open_flg != 'Y' Then
                exception_msg := 'data not open';
                Raise app_exception;
             End If;

             If v_open_amount < c2rec.clr_amt Then
               exception_msg := '被沖銷金額小於沖銷金額';
               Raise app_exception;
             End If;


         Exception
           When no_data_found Then
              exception_msg := '找不到沖銷資料';
               Raise app_exception;
         End;

         v_item_amt := v_item_amt+c2rec.clr_amt;
       End Loop;
       If v_item_amt != c1rec.amount Then
          exception_msg := '沖銷數不符';
          Raise app_exception;
       End If;
     End Loop;
     Return(Null);
   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;


   Function tgc_chk_post(p_user_no Number,p_pk_no Number) Return Varchar2
   Is
    exception_msg Varchar2(256);
     app_exception Exception;
     Cursor c1 Is Select * From service_chk_item Where mas_pk_no = p_pk_no;
     Cursor c2(p_item_pk_no Number) Is Select * From service_chk_item_clr a Where a.item_pk_no=p_item_pk_no;
     v_item_amt Number(20,2);
     v_open_amount Number(20,2);
     v_open_flg Varchar2(32);
     v_acc_detail_no Number(16);
     v_cust_no Number(16);
     v_src_code Varchar2(32);
     v_src_no Varchar2(32);
     v_src_date Date;
     v_year Number(4);
     v_period Number(2);
     v_package_key Number(20);
     v_status_flg Varchar2(16);
     v_acc_status_flg Varchar2(32);
     v_f_period Number(16);
     v_f_year Number(16);
     v_set_tivo_pk_no Number(16);
     v_acc_open_amt Number(16);
     v_tsn Varchar2(64);
     v_tivo_status Varchar2(32);
     v_tivo_set_no Varchar2(32);
     v_tivo_set_item Number(16);
     v_mas_acc varchar2(32);
     v_end_date date;
     v_invo_item_no number(16);
     v_srp_end_date date;
     v_tivo_msg varchar2(512);
     v_invo_pk_no number(16);
     v_srp_key number(16);
     v_detail_status varchar2(64);

   Begin
     Select acc_code,mas_code,mas_no,mas_date ,status_flg,to_number(to_char(a.mas_date,'YYYY')),to_number(to_char(a.mas_date,'MM'))
     Into v_mas_acc,v_src_code,v_src_no,v_src_date,v_status_flg,v_f_year,v_f_period
      From service_chk_mas a Where pk_no = p_pk_no;
     v_year:= to_number(to_char(v_src_date,'YYYY'));
     v_period := to_number(to_char(v_src_date,'MM'));
     If v_status_flg <> 'A' Then
       exception_msg :='#錯誤的單據狀態#';
       Raise app_exception;
     End If;

      Begin
        Select status_flg Into v_acc_status_flg From acc_period_mas a
        Where a.f_year=v_f_year And f_period=v_f_period;
        If v_acc_status_flg not in ('O','S') Then
                 exception_msg := '#帳期未開啟#';
                Raise app_exception;
        End If;
     Exception
        When no_data_found Then
                  exception_msg := '#沒有帳期設定#';
                Raise app_exception;
     End;

     v_set_tivo_pk_no := Null;


     For c1rec In c1 Loop
       v_item_amt := 0;
       Begin
          Select user_no Into v_cust_no From tgc_customer Where cust_id= c1rec.cust_code;
       Exception
         When no_data_found Then v_cust_no := 0;
       End;
/*       Select seq_sys_no.Nextval Into v_acc_detail_no From dual;

       Insert Into service_acc_detail(acc_type,pk_no,ctl_acc,acc_code,acc_user_no,src_pk_no,src_date,src_code,src_no,dr,cr,open_amount,open_flg,ref_pk_no,acc_teams,f_year,f_period,package_key,srp_key)
       Values('C',v_acc_detail_no,nvl(c1rec.acc_code,'1144'),c1rec.cust_code,v_cust_no,p_pk_no,v_src_date,v_src_code,v_src_no,c1rec.amount,Null,c1rec.amount,'Y',Null,Null,v_year,v_period,Null,Null);

*/       -- create 總帳傳票
       Select seq_sys_no.Nextval Into v_acc_detail_no From dual;

       Insert Into service_acc_detail(acc_type,pk_no,ctl_acc,acc_code,acc_user_no,src_pk_no,src_date,src_code,src_no,dr,cr,open_amount,open_flg,ref_pk_no,acc_teams,f_year,f_period,package_key,srp_key)
       Values('G',v_acc_detail_no,nvl(c1rec.acc_code,'1144'),nvl(c1rec.acc_code,v_mas_acc),0,p_pk_no,v_src_date,v_src_code,v_src_no,c1rec.amount,Null,c1rec.amount,'Y',Null,Null,v_year,v_period,Null,Null);

       Insert Into service_acc_detail(acc_type,pk_no,ctl_acc,acc_code,acc_user_no,src_pk_no,src_date,src_code,src_no,dr,cr,open_amount,open_flg,ref_pk_no,acc_teams,f_year,f_period,package_key,srp_key)
       Values('G',v_acc_detail_no,v_mas_acc,v_mas_acc,0,p_pk_no,v_src_date,v_src_code,v_src_no,null,c1rec.amount,c1rec.amount,'Y',Null,Null,v_year,v_period,Null,Null);

       Select seq_sys_no.Nextval Into v_acc_detail_no From dual;

       begin
           select package_key,srp_key into v_package_key,v_srp_key
            from service_detail where cust_code=c1rec.cust_code and status_flg in ('A','P','B') and rownum <=1;
       exception
          when no_data_found then
             begin
               select package_key,v_srp_key into v_package_key,v_srp_key
               from service_detail where cust_code=c1rec.cust_code and status_flg ='N' and rownum<=1;
             exception
                when no_data_found then
                  v_package_key := null;
                  v_srp_key := null;
             end;
       end;

       Insert Into service_acc_detail(acc_type,pk_no,ctl_acc,acc_code,acc_user_no,src_pk_no,src_date,src_code,src_no,dr,cr,open_amount,open_flg,ref_pk_no,acc_teams,f_year,f_period,package_key,srp_key,src_item_pk_no)
       Values('C',v_acc_detail_no,nvl(c1rec.acc_code,'1144'),nvl(c1rec.cust_code,v_mas_acc),v_cust_no,p_pk_no,v_src_date,v_src_code,v_src_no,c1rec.amount,Null,c1rec.amount,'Y',Null,Null,v_year,v_period,v_package_key,v_srp_key,c1rec.pk_no);

      For c2rec In c2(c1rec.pk_no) Loop
         Begin

            Select a.src_item_pk_no,a.open_amount,open_flg,package_key
              Into v_invo_item_no,v_open_amount,v_open_flg,v_package_key
              From service_acc_detail a
             Where a.pk_no = c2rec.detail_pk_no
               For Update;

             If v_open_flg != 'Y' Then
                exception_msg := 'data not open';
                Raise app_exception;
             End If;

             If v_open_amount < c2rec.clr_amt Then
               exception_msg := '#被沖銷金額小於沖銷金額#';
               Raise app_exception;
             End If;

             Update service_acc_detail a
                Set a.open_amount = v_open_amount- c2rec.clr_amt,
                      open_flg = decode(v_open_amount- c2rec.clr_amt,0,'N','Y')
                 Where a.pk_no= c2rec.detail_pk_no;

             Update service_acc_detail a
               Set open_amount = open_amount-c2rec.clr_amt,
               open_flg=decode(open_amount-c2rec.clr_amt,0,'N','Y'),
               package_key=nvl(v_package_key,package_key)
               Where a.pk_no= v_acc_detail_no;


             begin
               select end_date,mas_pk_no into v_end_date,v_invo_pk_no
                 from service_invo_dtl a
                 where  a.pk_no = v_invo_item_no;
             exception
                  when no_data_found then v_end_date := null;
             end;

             begin
               update tgc_dispatch_info a
                  set a.fa_amount=c2rec.clr_amt,
                      a.fa_date = v_src_date
                 where a.invo_pk_no=v_invo_pk_no
                   and a.fa_amount is null;
              end;


             select max(end_date) into v_srp_end_date
               from service_detail
               where package_key = v_package_key;

             if (v_end_date is not null) and
                (v_end_date > v_srp_end_date) then
                update service_detail a
                   set a.end_date=v_end_date
                  where package_key=v_package_key;
             end if;


         Exception
           When no_data_found Then
              exception_msg := '#找不到沖銷資料#';
               Raise app_exception;
         End;

         v_item_amt := v_item_amt+c2rec.clr_amt;

         --
         --  Open Tivo
         --
         v_TSN := Null;
         Begin
         Select sum(open_amount) Into v_acc_open_amt
            From service_acc_detail a
            Where package_key=v_package_key
                And dr Is Null
                and f_year*100+f_period < to_number(to_char(sysdate,'YYYYMM'))
                And open_flg ='Y';
         Exception
            When no_data_found Then
                      v_acc_open_amt := 0;
         End;

         v_acc_open_amt := nvl(v_acc_open_amt,0);

       If v_acc_open_amt <= 0 Then
          if v_package_key is not null then
                Begin
                   Select s1.tcd_tsn,MAX(nvl(s1.status_flg,'0')) Into v_tsn,v_detail_status
                     From service_detail s1
                     Where s1.package_key=v_package_key
                       and (s1.item_code in ('KA-80S','KA-160S','KA-500S')
                      or (s1.item_code is null and s1.tcd_tsn like '1E%')
                      )
                     and s1.status_flg in ('P','B','A')
                     group by tcd_tsn;
                Exception
                   When no_data_found Then
                      begin
                     Select tcd_tsn,status_flg Into v_tsn,v_detail_status
                        From service_detail
                        Where package_key=v_package_key
                          and status_flg in ('P','B','A')
                          and rownum<=1;

                       v_detail_status := 'N';
                       v_tsn := null;

                      exception
                         when no_data_found then
                                            Begin
                                               Select s1.tcd_tsn,MAX(nvl(s1.status_flg,'0')) Into v_tsn,v_detail_status
                                                 From service_detail s1
                                                 Where s1.package_key=v_package_key
                                                   and (s1.item_code in ('KA-80S','KA-160S','KA-500S')
                                                  or (s1.item_code is null and s1.tcd_tsn like '1E%')
                                                  )
                                                 and s1.status_flg in ('N')
                                                 group by tcd_tsn;
                                            Exception
                                               when no_data_found then
                                                    begin
                                                     Select tcd_tsn, status_flg
                                                       Into v_tsn, v_detail_status
                                                       From service_detail
                                                      Where package_key = v_package_key
                                                        and status_flg in ('N')
                                                        and rownum <= 1;

                                                     v_detail_status := 'N';
                                                     v_tsn           := null;
                                                    exception
                                                      when no_data_found then
                                                            exception_msg := '#找不到服務內容('||c1rec.cust_code||')#';
                                                           Raise app_exception;
                                                    end;
                                            end;
                     end;

                 End;
          else
             v_tsn := null;
             v_detail_status := 'N';
          end if;

          If (v_tsn Is Not Null) and v_detail_status='P' Then
            /*
              Begin
                Select a.servicestateid,a.individualmsg
                 Into v_tivo_status,v_tivo_msg From bsm.activationinfo a
                  Where tsn=v_tsn;
               Exception
                 When no_data_found Then
                 exception_msg := '#TSN號碼錯誤:'||c1rec.cust_code||'-'||v_tsn||'#';
                 Raise app_exception;
              End;
              */

             If  v_tivo_status <> 3 or v_tivo_msg is not null Then
                 If v_set_tivo_pk_no Is Null Then
                    Select seq_sys_no.Nextval Into v_set_tivo_pk_no
                      From dual;
                    v_tivo_set_no := sysapp_util.Get_Mas_No(1,1,Sysdate,'TGCSET',v_set_tivo_pk_no);
                    Insert Into service_set_mas(pk_no,mas_code,mas_no,mas_date,src_code,src_pk_no,src_no,src_date,create_user,description,status_flg,set_flg)
                    Values(v_set_tivo_pk_no,'TGCSET',v_tivo_set_no,Sysdate,v_src_code,p_pk_no,v_src_no,v_src_date,0,'沖帳重新開啟','A','P');
                 End If;
                  Select seq_sys_no.Nextval Into v_tivo_set_item  From dual;
                  Insert Into service_set_item(mas_pk_no,pk_no,item_no,cust_code,package_key,tcd_tsn)
                  Values(v_set_tivo_pk_no,v_tivo_set_item,0,c2rec.acc_code,v_package_key,v_tsn);

             End If;
          End If;
       End If;

       End Loop;

       If v_item_amt > c1rec.amount Then
          exception_msg := '#沖銷數不符#';
          Raise app_exception;
       End If;

     End Loop;

     Update service_chk_mas
        Set status_flg = 'P'
      Where pk_no =p_pk_no;

       Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values (v_src_code,  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'Post');

     Commit;

     Return(Null);

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;

   Function tgc_chk_unpost(p_user_no Number,p_pk_no Number) Return Varchar2
   Is
    exception_msg Varchar2(256);
     app_exception Exception;
     Cursor c1 Is Select * From service_chk_item Where mas_pk_no = p_pk_no;
     Cursor c2(p_item_pk_no Number) Is Select * From service_chk_item_clr a Where a.item_pk_no=p_item_pk_no;

     v_open_amount Number(20,2);
     v_open_flg Varchar2(32);


     v_src_code Varchar2(32);
     v_src_no Varchar2(32);
     v_src_date Date;
     v_status_flg Varchar2(32);

     v_acc_status_flg Varchar2(32);
     v_f_period Number(16);
     v_f_year Number(16);



   Begin
     Select mas_code,mas_no,mas_date ,status_flg,to_number(to_char(a.mas_date,'YYYY')),to_number(to_char(a.mas_date,'MM'))
     Into v_src_code,v_src_no,v_src_date,v_status_flg,v_f_year,v_f_period
      From service_chk_mas a Where pk_no = p_pk_no;

     If v_status_flg <> 'P' Then
       exception_msg := '#錯誤的單據狀態#';
       Raise app_exception;
     End If;
     Begin
        Select status_flg Into v_acc_status_flg From acc_period_mas a
        Where a.f_year=v_f_year And f_period=v_f_period;
        If v_acc_status_flg not in ('O','S') Then
                 exception_msg := '#帳期未開啟#';
                Raise app_exception;
        End If;
     Exception
        When no_data_found Then
                  exception_msg := '#沒有帳期設定#';
                Raise app_exception;
     End;

     For c1rec In c1 Loop


       For c2rec In c2(c1rec.pk_no) Loop
         Begin

            Select a.open_amount,open_flg Into v_open_amount,v_open_flg
              From service_acc_detail a
             Where a.pk_no = c2rec.detail_pk_no
                  For Update;


             Update service_acc_detail a
                Set a.open_amount = v_open_amount+ c2rec.clr_amt,
                      open_flg = decode(v_open_amount+ c2rec.clr_amt,0,'N','Y')
                 Where a.pk_no= c2rec.detail_pk_no;


         Exception
           When no_data_found Then
              exception_msg := '#找不到沖銷資料#';
               Raise app_exception;
         End;

       End Loop;

     End Loop;

     Delete service_acc_detail Where src_pk_no = p_pk_no;

     Update service_chk_mas
        Set status_flg = 'A'
      Where pk_no =p_pk_no;

       Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
       Values (v_src_code,  p_Pk_No,  Sysdate, p_User_No, 'Unpost'  ,Sys_Event_Seq.Nextval, 'Unpost');
     Commit;
     Return(Null);

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
   End;


     Function crt_chk_clr_tmp(p_user_no Number,p_process_seq_no Number,p_mas_pk_no Number,p_item_pk_no Number) Return Varchar2
     Is
       v_cust_code Varchar2(32);
       v_amount Number(20,2);
       v_clr_amount Number(20,2);
       v_chk_clr_amt Number(20,2);
       v_sel Varchar2(32);
       v_description Varchar2(1024);
       v_open_amount Number(20,2);
       v_status_flg Varchar2(32);
       exception_msg Varchar2(256);
       app_exception Exception;


       Cursor c1(p_no Varchar2) Is Select 1,due_date,src_date,src_code,src_no,pk_no,open_amount
                              From service_acc_detail
                            Where acc_code = v_cust_code
                               And open_flg='Y'
                               and open_amount > 0
                               And ( src_no Like '%'||p_no )
                               aND acc_type='C'
                               And dr Is Null
                            union all
                        Select 2,due_date,src_date,src_code,src_no,pk_no,open_amount
                              From service_acc_detail
                            Where acc_code = v_cust_code
                               And open_flg='Y'
                               and open_amount > 0
                               And ( src_no Not Like '%'||p_no )
                               And (srp_key in (select srp_key from service_acc_detail where src_no Like '%'||p_no )
                                or package_key in (select package_key from service_acc_detail where src_no Like '%'||p_no ))
                               aND acc_type='C'
                               And dr Is Null
                            union all
                        Select 3,due_date,src_date,src_code,src_no,pk_no,open_amount
                              From service_acc_detail
                            Where acc_code = v_cust_code
                               And open_flg='Y'
                               and open_amount>0
                               And dr Is Null
                               And ( src_no Not Like '%'||p_no )
                               And (srp_key not in (select srp_key from service_acc_detail where src_no Like '%'||p_no )
                               and  package_key not in (select package_key from service_acc_detail where src_no Like '%'||p_no ))
                               and acc_type='C'
                            Order By 1,2,3;

       /*Cursor c1(p_no Varchar2) Is Select 1,due_date,src_date,src_code,src_no,pk_no,open_amount
                              From service_acc_detail
                            Where acc_code = v_cust_code
                               And open_flg='Y'
                               and open_amount > 0
                               And ( src_no Like '%'||p_no
                                     and (chg_code not in ('INFORMATION_SERVICE')))
                               aND acc_type='C'
                               And dr Is Null
                               union all
Select 2,due_date,src_date,src_code,src_no,pk_no,open_amount
                              From service_acc_detail
                            Where acc_code = v_cust_code
                               And open_flg='Y'
                               and open_amount>0
                               And dr Is Null
                               And ( src_no Not Like '%'||p_no or chg_code in ('INFORMATION_SERVICE'))
                               and acc_type='C'
                            Order By 1,2,3; */
     Begin
       Select cust_code,amount,description Into v_cust_code,v_amount,v_description
        From service_chk_item
       Where pk_no = p_item_pk_no;

       Delete service_chk_item_clr_tmp Where process_seq_no = p_process_seq_no;

       For c1rec In c1(v_description) Loop
          Select status_flg Into v_status_flg From service_chk_mas Where pk_no=p_mas_pk_no;
          If v_status_flg <> 'A' Then
             exception_msg := '#錯誤的單據狀態#';
             Raise app_exception;
          End If;

         v_clr_amount := v_amount;

         v_open_amount := c1rec.open_amount;

         Select Sum(clr_amt) Into v_chk_clr_amt
           From service_chk_item_clr
           Where mas_pk_no =p_mas_pk_no
           And detail_pk_no=c1rec.pk_no;
         If v_chk_clr_amt > 0 Then
            v_open_amount := v_open_amount- v_chk_clr_amt;
         End If;

         Select Sum(clr_amt) Into v_chk_clr_amt
           From  service_chk_item_clr_tmp
           Where process_seq_no=p_process_seq_no
           And detail_pk_no=c1rec.pk_no;

         If v_chk_clr_amt > 0 Then
            v_open_amount := v_open_amount- v_chk_clr_amt;
         End If;


         If v_amount = 0 Then
           v_clr_amount := Null;
        Elsif v_open_amount >= v_clr_amount Then
           v_clr_amount := v_clr_amount;
           v_amount := v_amount-v_clr_amount;
        Elsif v_open_amount < v_clr_amount Then
           v_clr_amount := v_open_amount;
           v_amount := v_amount-v_clr_amount;
        End If;

       If v_clr_amount Is Not Null Then
          v_sel := 'Y';
       Else
          v_sel := 'N';
        End If;
           Insert Into service_chk_item_clr_tmp(process_seq_no,mas_pk_no,item_pk_no,detail_pk_no,clr_amt,open_amount,src_code,src_date,src_no)
           Values(p_process_seq_no,p_mas_pk_no,p_item_pk_no,c1rec.pk_no,v_clr_amount,c1rec.open_amount,c1rec.src_code,c1rec.src_date,c1rec.src_no);
       End Loop;

       Commit;
       Return(Null);

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);

     End;

     Function clr_chk_clr_tmp(p_process_seq_no Number) Return Varchar2
     Is
     Begin
       Delete service_chk_item_clr_tmp Where process_seq_no=p_process_seq_no;
       Commit;
       Return(Null);
     End;

     Function set_chk_clr_tmp(p_process_seq_no Number) Return Varchar2
     Is
       Cursor c1 Is Select * From service_chk_item_clr_tmp  a Where a.process_seq_no=p_process_seq_no And nvl(clr_amt,0) <> 0 ;
       v_seq_pk_no Number(16);
       v_cust_code Varchar2(32);
       v_open_amount Number(20,2);
       v_ref_acc Varchar2(32);
       v_status_flg Varchar2(32);
       exception_msg Varchar2(64);
        app_exception Exception;

     Begin
       For c1rec In c1 Loop
          Select status_flg Into v_status_flg From service_chk_mas Where pk_no=c1rec.mas_pk_no;
          If v_status_flg <> 'A' Then
             exception_msg := '#錯誤的單據狀態#';
             Raise app_exception;
          End If;
          Select seq_sys_no.Nextval  Into v_seq_pk_no From dual;


          Select a.acc_code,open_amount Into v_cust_code,v_open_amount
            From service_acc_detail a
             Where pk_no=c1rec.detail_pk_no;

          Insert Into service_chk_item_clr(mas_pk_no,item_pk_no,pk_no,detail_pk_no,acc_code,clr_amt,gl_amt,create_date,ref_acc)
          Values (c1rec.mas_pk_no,c1rec.item_pk_no,v_seq_pk_no,c1rec.detail_pk_no,v_cust_code,c1rec.clr_amt,v_open_amount,Sysdate,Null);

       End Loop;

       Commit;

       Return(Null);

   Exception
      When app_exception Then
          Rollback;
           Raise_Application_Error(-20002, Exception_Msg);
          Return(Exception_Msg);
      When Others Then
         Rollback;
         Raise_Application_Error(-20002, Sqlerrm);
         Return(Sqlerrm);
     End;

   Function tgc_startbill_post(p_user_no   Number,
                               p_pk_no     Number,
                               p_no_commit varchar2 default 'N')
     Return Varchar2 IS
     exception_msg Varchar2(64);
     app_exception Exception;

     v_status_flg varchar2(32);
     v_detail_status_flg varchar2(32);

     cursor c1 is select pk_no,a.start_bill_date,srp_key
                    from service_startbill_item a
                   where mas_pk_no =p_pk_no;
     cursor c2(p_srp_key number) is Select pk_no,start_bill_date,start_date,status_flg
                                from service_chg_detail
                              where srp_key= p_srp_key
                                and status_flg='A';

   begin
     select status_flg into v_status_flg from service_startbill_mas
       where pk_no = p_pk_no;

     if v_status_flg <> 'A' then
        exception_msg :='#錯誤的單據狀態#';
        raise app_exception;
     end if;

     for c1rec in c1 loop
         begin
             select status_flg into v_detail_status_flg
               from service_detail
              where srp_key = c1rec.srp_key;
         exception
            when no_data_found then
                 exception_msg := '#錯誤的服務內容,請查詢服務內容是否正確!#';
                 raise app_exception;
         end;

         if v_detail_status_flg <> 'A' then
             exception_msg := '#錯誤的服務狀態,請查詢服務內容是否正確!#';
             raise app_exception;
         end if;

         if c1rec.start_bill_date is null then
             exception_msg := '#起始日期未輸入!#';
             raise app_exception;
         end if;
        if sysapp_util.Get_User_Priv('TGCSRTBILL',p_user_no,'ForceStartDate','強制設定起始日') <> 'Y' then
            if (c1rec.start_bill_date < sysdate-360)
            or  (c1rec.start_bill_date > sysdate+1200)  then
                 exception_msg := '#錯誤的日期輸入!#';
                 raise app_exception;
             end if;
         end if;

         for c2rec in c2(c1rec.srp_key) loop
             update service_chg_detail
                set start_date = c1rec.start_bill_date,
                    start_bill_date = c1rec.start_bill_date,
                    status_flg='P'
               where pk_no =c2rec.pk_no;
         end loop;

         update service_detail b
            set b.status_flg = 'P'
          where srp_key = c1rec.srp_key;

     end loop;

     Update service_startbill_mas
        Set status_flg ='P'
      Where pk_no=p_pk_no;

     Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
          Values ('SRVSTART',  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'Post');

     if p_no_commit <> 'Y' then
        commit;
     end if;
   Return(Null);

   Exception
     When app_exception Then
       Rollback;
       Raise_Application_Error(-20002, Exception_Msg);
       Return(Exception_Msg);
     When Others Then
       Rollback;
       Raise_Application_Error(-20002, Sqlerrm);
       Return(Sqlerrm);
   end;

   Function tgc_startbill_unpost(p_user_no   Number,
                               p_pk_no     Number,
                               p_no_commit varchar2 default 'N')
     Return Varchar2 IS
     exception_msg Varchar2(64);
     app_exception Exception;

     v_status_flg varchar2(32);
     v_detail_status_flg varchar2(32);

     cursor c1 is select pk_no,a.start_bill_date,srp_key
                    from service_startbill_item a
                   where mas_pk_no =p_pk_no;
     cursor c2(p_srp_key number) is Select pk_no,start_bill_date,start_date,status_flg
                                from service_chg_detail
                              where srp_key= p_srp_key
                                and status_flg='P';

   begin
     select status_flg into v_status_flg from service_startbill_mas
       where pk_no = p_pk_no;

     if v_status_flg <> 'P' then
        exception_msg :='#錯誤的單據狀態#';
        raise app_exception;
     end if;

     for c1rec in c1 loop
         begin
             select status_flg into v_detail_status_flg
               from service_detail
              where srp_key = c1rec.srp_key;
         exception
            when no_data_found then
                 exception_msg := '#錯誤的服務內容,請查詢服務內容是否正確!#';
                 raise app_exception;
         end;

         if v_detail_status_flg <> 'P' then
             exception_msg := '#錯誤的服務狀態,請查詢服務內容是否正確!#';
             raise app_exception;
         end if;


         for c2rec in c2(c1rec.srp_key) loop
             update service_chg_detail
                set start_date = null,
                    start_bill_date = null,
                    status_flg='A'
               where pk_no =c2rec.pk_no;
         end loop;
     end loop;

     Update service_startbill_mas
        Set status_flg ='A'
      Where pk_no=p_pk_no;

     Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
          Values ('SRVSTART',  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'UnPost');

     if p_no_commit <> 'Y' then
        commit;
     end if;
   Return(Null);

   Exception
     When app_exception Then
       Rollback;
       Raise_Application_Error(-20002, Exception_Msg);
       Return(Exception_Msg);
     When Others Then
       Rollback;
       Raise_Application_Error(-20002, Sqlerrm);
       Return(Sqlerrm);
   end;

   Function tgc_startbill_cancel(p_user_no   Number,
                               p_pk_no     Number,
                               p_no_commit varchar2 default 'N')
     Return Varchar2 IS
     exception_msg Varchar2(64);
     app_exception Exception;

     v_status_flg varchar2(32);
     v_detail_status_flg varchar2(32);

     cursor c1 is select pk_no,a.start_bill_date,srp_key
                    from service_startbill_item a
                   where mas_pk_no =p_pk_no;
     cursor c2(p_srp_key number) is Select pk_no,start_bill_date,start_date,status_flg
                                from service_chg_detail
                              where srp_key= p_srp_key
                                and status_flg='P';

   begin
     select status_flg into v_status_flg from service_startbill_mas
       where pk_no = p_pk_no;

     if v_status_flg <> 'A' then
        exception_msg :='#錯誤的單據狀態#';
        raise app_exception;
     end if;


     Update service_startbill_mas
        Set status_flg ='C'
      Where pk_no=p_pk_no;

     Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
          Values ('SRVSTART',  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'Cancel');

     if p_no_commit <> 'Y' then
        commit;
     end if;

   Return(Null);

   Exception
     When app_exception Then
       Rollback;
       Raise_Application_Error(-20002, Exception_Msg);
       Return(Exception_Msg);
     When Others Then
       Rollback;
       Raise_Application_Error(-20002, Sqlerrm);
       Return(Sqlerrm);
   end;
      Function tgc_billchg_post(p_user_no   Number,
                               p_pk_no     Number,
                               p_no_commit varchar2 default 'N')
     Return Varchar2 IS
     exception_msg Varchar2(64);
     app_exception Exception;

     v_status_flg varchar2(32);
     v_mas_no varchar2(32);
     v_mas_date date;
     v_detail_status_flg varchar2(32);

     cursor c1 is select b.pk_no item_pk_no,b.srp_key
                    from service_billchang_item b
                   where mas_pk_no =p_pk_no;
     cursor c2(p_item_pk_no number) is select c.srp_key,c.chg_pk_no,
                                              src_chg_type chg_type,src_chg_code chg_code,src_pm_code pm_code,src_bill_type bill_type,
                                              src_start_bill_date start_bill_date,src_start_date start_date,
                                              src_stop_bill_date stop_bill_date,src_next_bill_date next_bill_date,
                                              src_acc_code acc_code,
                                              src_status_flg status_flg,src_amount amount
                                         from service_billchang_dtl c
                                       where c.item_pk_no=p_item_pk_no
                                         and c.mas_pk_no =p_pk_no
                                         and c.change_type='Update';
     cursor c3(p_item_pk_no number) is select  c.change_type,c.pk_no dtl_pk_no,c.srp_key,c.chg_pk_no,
                                                chg_type,chg_code,pm_code,bill_type,
                                                start_bill_date,start_date,
                                                stop_bill_date,next_bill_date,
                                                acc_code,amount net_price,
                                                status_flg,pay_period
                                           from service_billchang_dtl c
                                         where c.item_pk_no=p_item_pk_no
                                          and c.mas_pk_no =p_pk_no;

   begin
     select m.status_flg,m.mas_no,m.mas_date
      into v_status_flg,v_mas_no,v_mas_date
      from service_billchang_mas m
       where pk_no = p_pk_no;

     if v_status_flg <> 'A' then
        exception_msg :='#錯誤的單據狀態#';
        raise app_exception;
     end if;

     for c1rec in c1 loop
         for c2rec in c2(c1rec.item_pk_no) loop
             declare
               v_src_chg_type  varchar2(32);
               v_src_chg_code  varchar2(32);
               v_src_pm_code   varchar2(32);
               v_src_bill_type varchar2(32);
               v_bill_type     varchar2(32);
               v_src_start_bill_date date;
               v_src_start_date      date;
               v_src_stop_bill_date  date;
               v_src_next_bill_date  date;
               v_src_amount              number(16);
               v_src_status_flg      varchar2(32);
             begin
                 select
                 chg_type,chg_code,pm_code,bill_type,
                 start_bill_date,start_date,
                 stop_bill_date,next_bill_date,
                 status_flg,net_price
                 into
                 v_src_chg_type,v_src_chg_code,v_src_pm_code,v_src_bill_type,
                 v_src_start_bill_date,v_src_start_date,
                 v_src_stop_bill_date,v_src_next_bill_date,
                 v_src_status_flg,v_src_amount
                 from service_chg_detail
                 where pk_no = c2rec.chg_pk_no;

                 if (c2rec.chg_type<>v_src_chg_type) or
                    (c2rec.chg_code<>v_src_chg_code) or
                    (c2rec.pm_code<>v_src_pm_code) or
                    (c2rec.bill_type<>v_src_bill_type) or
                    (c2rec.start_date<>v_src_start_date) or
                    (c2rec.start_bill_date<>v_src_start_bill_date) or
                    (c2rec.stop_bill_date<>v_src_stop_bill_date) or
                    (c2rec.next_bill_date<>v_src_next_bill_date) or
                    (c2rec.status_flg<>v_src_status_flg) or
                    (c2rec.amount <> v_src_amount) then
                    exception_msg :='錯誤的原始資料';
                    raise app_exception;
                 end if;

             exception
                when no_data_found then
                     exception_msg :='錯誤的原始資料';
                     raise app_exception;
             end;
             for c3rec in c3(c1rec.item_pk_no) loop
                 if c3rec.change_type = 'Insert' then
                       -- new
                       declare
                         v_pk_no number(16);
                         v_acc_user_no number(16);
                         v_product_id varchar2(32);
                         v_item_code  varchar2(32);
                         v_tax_code   varchar2(32);
                         v_tax_flg    varchar2(32);
                         v_acc_terms  varchar2(32);

                       begin
                         select seq_sys_no.nextval into v_pk_no from dual;
                         select user_no,tax_code,tax_flg,acc_terms
                          into v_acc_user_no,v_tax_code,v_tax_flg,v_acc_terms
                          from tgc_customer where cust_id=c3rec.acc_code;
                         select product_id,item_code into v_product_id,v_item_code from service_detail where srp_key = c1rec.srp_key;


                           insert into service_chg_detail(src_code,src_pk_no,src_mas_no,src_item_pk_no,src_dtl_pk_no,src_chg_pk_no,src_mas_date
                           ,srp_key,pk_no,chg_group_no,acc_code,acc_user_no,product_id,item_code
                           ,chg_type,chg_code,pm_code,bill_type,tax_flg,tax_code,terms
                           ,start_date,start_bill_date,stop_bill_date,next_bill_date,status_flg,net_price,pay_period
                           )
                           values
                           ('BILLCHANG',p_pk_no,v_mas_no,c1rec.item_pk_no,c3rec.dtl_pk_no,c3rec.chg_pk_no,v_mas_date
                           ,c2rec.srp_key,v_pk_no,v_pk_no,c3rec.acc_code,v_acc_user_no,v_product_id,v_item_code
                           ,c3rec.chg_type,c3rec.chg_code,c3rec.pm_code,c3rec.bill_type,v_tax_flg,v_tax_code,v_acc_terms
                           ,c3rec.start_date,c3rec.start_bill_date,c3rec.stop_bill_date,c3rec.next_bill_date,c3rec.status_flg,c3rec.net_price,c3rec.pay_period);
                        end;
                 end if;

                 -- update
                 if c3rec.change_type = 'Update' then
                     update service_chg_detail
                          set status_flg ='N'
                         where pk_no = c3rec.chg_pk_no;

                     if c3rec.status_flg <> 'N' then
                       declare
                         v_pk_no number(16);
                         v_acc_user_no number(16);
                         v_product_id varchar2(32);
                         v_item_code  varchar2(32);
                         v_tax_code   varchar2(32);
                         v_tax_flg    varchar2(32);
                         v_acc_terms  varchar2(32);

                       begin
                         select seq_sys_no.nextval into v_pk_no from dual;
                         select acc_user_no,tax_code,tax_flg,terms
                          into v_acc_user_no,v_tax_code,v_tax_flg,v_acc_terms
                          from service_chg_detail where pk_no = c3rec.chg_pk_no;
                         select product_id,item_code into v_product_id,v_item_code from service_detail where srp_key = c1rec.srp_key;


                           insert into service_chg_detail(src_code,src_pk_no,src_mas_no,src_item_pk_no,src_dtl_pk_no,src_chg_pk_no,src_mas_date
                           ,srp_key,pk_no,chg_group_no,acc_code,acc_user_no,product_id,item_code
                           ,chg_type,chg_code,pm_code,bill_type,tax_flg,tax_code,terms
                           ,start_date,start_bill_date,stop_bill_date,next_bill_date,status_flg,net_price,pay_period
                           )
                           values
                           ('BILLCHANG',p_pk_no,v_mas_no,c1rec.item_pk_no,c3rec.dtl_pk_no,c3rec.chg_pk_no,v_mas_date
                           ,c2rec.srp_key,v_pk_no,v_pk_no,c3rec.acc_code,v_acc_user_no,v_product_id,v_item_code
                           ,c3rec.chg_type,c3rec.chg_code,c3rec.pm_code,c3rec.bill_type,v_tax_flg,v_tax_code,v_acc_terms
                           ,c3rec.start_date,c3rec.start_bill_date,c3rec.stop_bill_date,c3rec.next_bill_date,c3rec.status_flg,c3rec.net_price,c3rec.pay_period);
                       end;
                     end if;
                 end if;
             end loop;

         end loop;
     end loop;


     Update service_billchang_mas
        Set status_flg ='P'
      Where pk_no=p_pk_no;


     Insert Into Sysevent_Log(App_Code, Pk_No,  Event_Date, User_No, Event_Type,  Seq_No,  Description)
          Values ('BILLCHANG',  p_Pk_No,  Sysdate, p_User_No, 'Post'  ,Sys_Event_Seq.Nextval, 'Post');

     if p_no_commit <> 'Y' then
        commit;
     end if;

   Return(Null);

   Exception
     When app_exception Then
       Rollback;
       Raise_Application_Error(-20002, Exception_Msg);
       Return(Exception_Msg);
     When Others Then
       Rollback;
       Raise_Application_Error(-20002, Sqlerrm);
       Return(Sqlerrm);
   end;

  Function Tgc_billchg_trans(p_user_no Number,p_pk_no Number,p_proc_no number) return varchar2 IS

     exception_msg Varchar2(64);
     app_exception Exception;

     v_status_flg varchar2(32);
     v_mas_no varchar2(32);
     v_mas_date date;
     v_detail_status_flg varchar2(32);

     cursor c1 is select a.srp_key,a.cust_code,a.program_id,a.product_id,a.item_code,a.tcd_tsn
                    from service_detail a ,service_billchang_tmp b
     where b.srp_key=a.srp_key
     and b.proc_no = p_proc_no;

     cursor c2(p_srp_key number) is select * from service_chg_detail c where c.srp_key=p_srp_key and status_flg='P';

   begin
     select m.status_flg,m.mas_no,m.mas_date
      into v_status_flg,v_mas_no,v_mas_date
      from service_billchang_mas m
       where pk_no = p_pk_no;

     if v_status_flg <> 'A' then
        exception_msg :='#錯誤的單據狀態#';
        raise app_exception;
     end if;
     declare
       v_item_pk_no number(16);
       v_dtl_pk_no  number(16);
     begin
         select seq_sys_no.nextval into v_item_pk_no from dual;
         for c1rec in c1 loop
              select seq_sys_no.nextval into v_dtl_pk_no from dual;
               insert into service_billchang_item(mas_pk_no,pk_no,srp_key,cust_code,program_id,product_id,item_code,tsn)
               values(p_pk_no,v_item_pk_no,c1rec.srp_key,c1rec.cust_code,c1rec.program_id,c1rec.product_id,c1rec.item_code,c1rec.tcd_tsn);
               for c2rec in c2(c1rec.srp_key) loop
                   select seq_sys_no.nextval into v_dtl_pk_no from dual;
                   insert into service_billchang_dtl(mas_pk_no,item_pk_no,pk_no,srp_key,chg_pk_no,change_type
                   ,src_chg_code,chg_code,src_chg_type,chg_type,src_bill_type,bill_type,src_pm_code,pm_code,
                   src_start_date,start_date,src_start_bill_date,start_bill_date,
                   src_stop_bill_date,stop_bill_date,src_next_bill_date,next_bill_date
                   ,src_amount,amount,src_status_flg,status_flg
                   ,src_acc_code,acc_code,src_pay_period,pay_period)
                   values (p_pk_no,v_item_pk_no,v_dtl_pk_no,c1rec.srp_key,c2rec.pk_no,'Update'
                   ,c2rec.chg_code,c2rec.chg_code,c2rec.chg_type,c2rec.chg_type,c2rec.bill_type,c2rec.bill_type,c2rec.pm_code,c2rec.pm_code,
                   c2rec.start_date,c2rec.start_date,c2rec.start_bill_date,c2rec.start_bill_date
                   ,c2rec.stop_bill_date,c2rec.stop_bill_date,c2rec.next_bill_date,c2rec.next_bill_date
                   ,c2rec.net_price,c2rec.net_price,c2rec.status_flg,c2rec.status_flg
                   ,c2rec.acc_code,c2rec.acc_code,c2rec.pay_period,c2rec.pay_period);
             end loop;

         end loop;
     end;

     delete service_billchang_tmp where proc_no=p_proc_no;

     commit;

   Return(Null);

   Exception
     When app_exception Then
       Rollback;
       Raise_Application_Error(-20002, Exception_Msg);
       Return(Exception_Msg);
     When Others Then
       Rollback;
       Raise_Application_Error(-20002, Sqlerrm);
       Return(Sqlerrm);
   end;


end TGC_BILL_POST;
/

