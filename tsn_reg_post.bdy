CREATE OR REPLACE PACKAGE BODY IPTV."TSN_REG_POST" is
    Function  reg_post(p_user_no Number,p_pk_no Number) Return Varchar2 Is
     exception_msg Varchar2(256);
     app_exception Exception;
     v_start_date Date;
     v_end_date Date;

  Begin
      -- Create Customer ID
      Declare
         v_user_no Number(16);
         v_cust_id Varchar2(32);
         v_name Varchar2(64);
         v_uid Varchar2(32);
         v_tax_code Varchar2(32);
         v_cmp_uid Varchar2(32);
         v_cmp_name Varchar2(64);
         v_tel Varchar2(32);
         v_zip Varchar2(32);
         v_address Varchar2(256);
         v_mobile Varchar2(32);
         v_cust_pk_no Number(16);
         
         v_detail_pk_no Number(16);
         v_srp_key Number(16);
         v_package_key Number;
         v_src_code Varchar(32);
         
         v_reg_date Date;
         v_program_id Varchar2(32);
         v_product_id Varchar2(32);
         v_tivo_model Varchar2(32);
         v_reg_id Varchar2(32);
         
         v_buy_epg Varchar2(32);
         
         v_invo_pk_no Number(16);
         v_TSN Varchar2(32);
         v_amount Number(16);
         v_invo_no Varchar2(32);
         v_due_date Date;
         v_f_year Number(4);
         v_f_period Number(2);
         v_due_date_str Varchar2(256);
         v_str Varchar2(32);
      Begin
        Select Name,tel,zip,address,mobile,tax_code,cmp_uid,cmp_name,reg_date,program_id,product_id,tivo_model,reg_id,buyepg,TSN,amount,due_date
        Into v_name,v_tel,v_zip,v_address,v_mobile,v_tax_code,v_cmp_uid,v_cmp_name,v_reg_date,v_program_id,v_product_id,v_tivo_model,v_reg_id,v_buy_epg,v_TSN,v_amount,v_due_date
         From tsn_register_mas a Where pk_no = p_pk_no;
         
        
        update tsn_register_mas a
        set a.tivo_due_date=add_months(a.reg_date,3)
        where a.pk_no = p_pk_no;
      end;
         
/*       If v_buy_epg <> 'Y' Then 
         v_tax_code := Null;
       End If;
         
        Select seq_sys_no.Nextval Into  v_cust_pk_no From dual;
        v_cust_id := sysapp_util.Get_Mas_No(1,1,sysdate,'TGCCUSTOMER',p_pk_no);
        
        Insert Into tgc_customer(user_no,cust_id,cust_name,company_uid,company_name,dayphone,mobilephone1,address,ref1,ref2)
        Values ( v_cust_pk_no,v_cust_id,v_name,v_cmp_uid,v_cmp_name,v_tel,v_mobile,v_address,'轉入',to_char(p_pk_no));
         
        Select seq_sys_no.Nextval Into v_detail_pk_no From dual;
        Select seq_srp_key.Nextval Into v_srp_key From dual;
        v_package_key := v_srp_key;
        v_src_code:='TSNREG';
        
        Insert Into service_detail(pk_no,src_code,src_mas_no,srp_key,src_mas_date,ori_pk_no,
                                              status_flg,program_id,product_id,
                                              acc_user_no,acc_code,cust_code,
                                              start_date,end_date,
                                              act_start,act_end,
                                              item_code,
                                              prod_flg,sale_mode,item_mode,
                                              inst_address,inst_zip,inst_tel,
                                              bill_address,bill_zip,bill_tel)
                          Values(v_detail_pk_no,v_src_code,v_reg_id,v_srp_key,Sysdate,p_pk_no,
                          'P',v_program_id,v_product_id,
                          v_cust_pk_no,v_cust_id,v_cust_id,
                          v_reg_date,add_months(v_reg_date,3),
                          v_reg_date,Null,
                          v_tivo_model,
                          'S','Y','X',
                          v_address,v_zip,v_tel,
                          v_address,v_zip,v_tel);
       If v_buy_epg ='Y' Then
          Select seq_sys_no.Nextval Into v_invo_pk_no From dual;
          v_invo_no := sysapp_util.Get_Mas_No(1,1,Sysdate,'SRVINVO',v_invo_Pk_no);
          v_f_year := to_number(to_char(Sysdate,'YYYY'));
          v_f_period := to_number(to_char(Sysdate,'MM'));
          Insert Into service_invo_mas(src_pk_no,src_no,src_code,package_key,pk_no,mas_date,mas_no,
                                                     acc_code,acc_user_no,address,tax_flg,tax_code,status_flg,due_date,mas_code,
                                                     f_year,f_period,tsn,product_id,amount,net_amount)
                Values(p_pk_no,v_reg_id,'TSNREG',v_package_key,v_invo_pk_no,Sysdate,v_invo_no,
                            v_cust_id,v_cust_pk_no,v_address,'Y',v_tax_code,'P',v_due_date,'SRVINVO',
                            v_f_year,v_f_period,v_tsn,v_product_id,v_amount,v_amount);                         
       End If;
       
    v_due_date_str := to_char(to_number(to_char(v_due_date,'YYYY'))-1911)||to_char(v_due_date,'MMDD')||'627';
    v_str:=to_char((v_f_year-1911)*100+v_f_period)||'**'||lpad(to_char(v_amount),9,'0');
       
     Update  tsn_register_mas a
           Set a.invo_no = v_invo_no,
                 a.cust_id=v_cust_id,
                 a.reg_date=Sysdate,
                 a.bar_due_date='*'||v_due_date_str||'*',
                 a.bar_invo_no='*'||v_invo_no||'*',
                 a.bar_amount='*'||barcode_4(v_due_date_str,v_invo_no,v_str)||'*',
                 a.bar_acc='8170'||substr(v_invo_no,length(v_invo_no)-9,10)||to_char(vachksum('8170'||substr(v_invo_no,length(v_invo_no)-9,10),v_amount))
          Where a.pk_no=p_pk_no;
                                              
      End;*/
      Commit;
      Return Null;
  End;

Function  get_invo_no(p_user_no Number,p_pk_no Number,p_amount number default 0) Return Varchar2 Is
     exception_msg Varchar2(256);
     app_exception Exception;
     v_start_date Date;
     v_end_date Date;

  Begin
      -- Create Customer ID
      Declare
         v_user_no Number(16);
         v_cust_id Varchar2(32);
         v_name Varchar2(64);
         v_uid Varchar2(32);
         v_tax_code Varchar2(32);
         v_cmp_uid Varchar2(32);
         v_cmp_name Varchar2(64);
         v_tel Varchar2(32);
         v_zip Varchar2(32);
         v_address Varchar2(256);
         v_mobile Varchar2(32);
         v_cust_pk_no Number(16);
         
         v_detail_pk_no Number(16);
         v_srp_key Number(16);
         v_package_key Number;
         v_src_code Varchar(32);
         
         v_reg_date Date;
         v_program_id Varchar2(32);
         v_product_id Varchar2(32);
         v_tivo_model Varchar2(32);
         v_reg_id Varchar2(32);
         
         v_buy_epg Varchar2(32);
         
         v_invo_pk_no Number(16);
         v_TSN Varchar2(32);
         v_amount Number(16);
         v_invo_no Varchar2(32);
         v_due_date Date;
         v_f_year Number(4);
         v_f_period Number(2);
         v_due_date_str Varchar2(256);
         v_str Varchar2(32);
         v_epg_s_date date;
         v_epg_e_date date;
         v_tivo_due_date date;
      Begin
      select invo_no into v_invo_no from tsn_register_mas a where a.pk_no=p_pk_no;
      
        update tsn_register_mas a
           set a.amount=p_amount,a.due_date=sysdate+21
          where pk_no= p_pk_no;
          
        v_f_year := to_number(to_char(sysdate,'YYYY'));  
        v_f_period := to_number(to_char(sysdate,'MM'));
        Select Name,tel,zip,address,mobile,tax_code,cmp_uid,cmp_name,reg_date,program_id,product_id,tivo_model,reg_id,buyepg,TSN,amount,due_date,tivo_due_date
        Into v_name,v_tel,v_zip,v_address,v_mobile,v_tax_code,v_cmp_uid,v_cmp_name,v_reg_date,v_program_id,v_product_id,v_tivo_model,v_reg_id,v_buy_epg,v_TSN,v_amount,v_due_date,v_tivo_due_date
         From tsn_register_mas a Where pk_no = p_pk_no;
    if v_invo_no is null then 
       Select seq_sys_no.Nextval Into v_invo_pk_no From dual;
       v_invo_no := sysapp_util.Get_Mas_No(1,1,Sysdate,'SRVINVO',v_invo_Pk_no);
    end if;
    v_due_date_str := to_char(to_number(to_char(v_due_date,'YYYY'))-1911)||to_char(v_due_date,'MMDD')||'627';
    v_str:=to_char((v_f_year-1911)*100+v_f_period)||'**'||lpad(to_char(v_amount),9,'0');
    v_epg_s_date := v_tivo_due_date+1;
    
    if p_amount=1788 then 
      v_epg_e_date := add_months(v_tivo_due_date,12);
    elsif p_amount=5346 then
      v_epg_e_date :=  add_months(v_tivo_due_date,26);   
     elsif p_amount = 5346 then
       v_epg_e_date :=  add_months(v_tivo_due_date,40);
     end if; 
       
     Update  tsn_register_mas a
           Set a.invo_no = v_invo_no,
                 a.cust_id=v_cust_id,
                 a.reg_date=Sysdate,
                 a.bar_due_date=v_due_date_str,
                 a.bar_invo_no=v_invo_no,
                 a.bar_amount=barcode_4(v_due_date_str,v_invo_no,v_str),
                 a.bar_acc='8170'||substr(v_invo_no,length(v_invo_no)-9,10)||to_char(vachksum('8170'||substr(v_invo_no,length(v_invo_no)-9,10),v_amount)),
                 epg_s_date = v_epg_s_date,
                 epg_e_date = v_epg_e_date
          Where a.pk_no=p_pk_no;
                                              
      End;
      Commit;
      Return Null;
  End;
 End  TSN_REG_POST;
/

