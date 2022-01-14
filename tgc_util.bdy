CREATE OR REPLACE PACKAGE BODY IPTV."TGC_UTIL" Is
  Procedure set_global_user_no(p_user_no Number)
  Is 
  Begin
    global_user_no := p_user_no;
  End;
  
  Function get_process_name(p_process_sts Varchar2) Return Varchar2
  Is
  Begin
    If p_process_sts = 'A' Then
      Return  '打單中';
    Elsif p_process_sts= 'P' Then
      Return '新進件';
    Elsif p_process_sts= 'D' Then
      Return '約裝中';
    Elsif p_process_sts='N' Then
      Return '已派工';
    Elsif p_process_sts= 'W' Then
       Return '已安裝';
    Elsif p_process_sts='Z' Then
      Return '完成';
    Elsif p_process_sts = 'Y' Then
      Return '成交轉新單';
    Elsif p_process_sts = 'X' Then
      Return '結案';
    Elsif p_process_sts = 'C' Then
      Return '取消';
        Elsif p_process_sts = 'F' Then
      Return '作廢';
    Else
      Return Null;
    End If;
  End get_process_name;

  Function get_csr_status_name(p_csr_status Varchar2) Return Varchar2
  Is
    v_code_name Varchar2(128);
  Begin
    Select code_name Into v_code_name
      From syscode_mas
    Where code_type='CNT_STS'
       And code=p_csr_status;
     Return v_code_name;
  Exception
    When no_data_found Then Return Null;
  End get_csr_status_name;

  Function get_cust_email(p_cust_id Varchar2) Return Varchar2
  Is
    v_result  Varchar2(256);
  Begin
    Select email Into v_result
       From tgc_customer
     Where cust_id = p_cust_id;
     Return v_result;
  Exception
     When no_data_found Then Return Null;
  End  get_cust_email;
 Function get_cust_name(p_cust_id Varchar2) Return Varchar2
  Is
    v_cust_name Varchar2(256);
  Begin
    Select cust_name Into v_cust_name
       From tgc_customer
     Where cust_id = p_cust_id;
     Return v_cust_name;
  Exception
     When no_data_found Then Return Null;
  End  get_cust_name;
  
  Function get_acc_name(p_acc_code Varchar2) Return Varchar2
  Is
    v_acc_name Varchar2(256);
  Begin
    Select acc_name Into v_acc_name
       From account_mas a 
     Where a.acc_id= p_acc_code;
     Return v_acc_name;
  Exception
     When no_data_found Then Return Null;
  End  get_acc_name;

    Function get_program_name(p_id Varchar2) Return Varchar2
  Is
    v_program_name Varchar2(256);
  Begin
    Select program_name Into v_program_name
       From tgc_program
     Where program_id=p_id;
     Return v_program_name;
  Exception
     When no_data_found Then Return Null;
  End  get_program_name;

      Function get_product_name(p_product_id Varchar2) Return Varchar2
  Is
    v_product_name Varchar2(256);
  Begin
    Select product_name Into v_product_name
       From tgc_product
     Where product_id=p_product_id;
     Return v_product_name;
  Exception
     When no_data_found Then Return Null;
  End  get_product_name;

    Function get_order_type_name(p_id Varchar2) Return Varchar2
  Is
  Begin
  /*
       add_list_element('TGC_Order.Order_type',1,'購買','B');
     add_list_element('TGC_Order.Order_type',2,'租賃','L');
     add_list_element('TGC_Order.Order_type',3,'試用','P');
     add_list_element('TGC_Order.Order_type',4,'新購服務型商品','S');
     add_list_element('TGC_Order.Order_type',5,'復機','R');
     add_list_element('TGC_Order.Order_type',6,'試用轉購買','J');
     add_list_element('TGC_Order.Order_type',7,'試用轉租用','K');
     */
    If p_id = 'B' Then
      Return  '購買';
    Elsif p_id= 'L' Then
      Return '租賃';
    Elsif p_id= 'P' Then
      Return '試用';
    Elsif p_id='S' Then
      Return '新購服務型商品';
    Elsif p_id= 'R' Then
       Return '復機';
    Elsif p_id='J' Then
      Return '試用轉購買';
    Elsif p_id = 'K' Then
      Return  '試用轉租用';
    Elsif p_id = 'X' Then
      Return'試用轉租用';

    Else
      Return Null;
    End If;
  End ;
  
    Function get_order_cmp_status(p_pk_no Number) Return Varchar2
  Is
    v_process_sts Varchar2(32);
    v_csr_status Varchar2(32);
    v_new_order_no Varchar2(32);
    v_result Varchar2(32);
    v_new_process_sts Varchar2(32);
    v_order_type Varchar2(32);
  Begin
    Select a.process_sts,a.csr_status,a.new_order_no,order_type
        Into v_process_sts,v_csr_status,v_new_order_no,v_order_type
       From tgc_order  a
       Where order_no = p_pk_no;
       
     If v_process_sts In ('A','P','D','N','W','Z','C','F') Then
       v_result := get_process_name(v_process_sts);
     Elsif v_process_sts In ('X','Y','Z') Then 
        If v_new_order_no Is  Null And v_order_type='P' Then 
           v_result := '已回收';
        Elsif v_new_order_no Is Not Null And  v_order_type='P'  Then
            Select process_sts Into v_new_process_sts 
               From tgc_order 
               Where order_no = v_new_order_no;
             If v_new_process_sts In ('X','Z') Then
               v_result := '已成交';
             Else 
               v_result := '成交中';
             End If;
       Elsif v_order_type In ('J','K','X') Then
            v_result := '已成交';
           
       Else
             v_result := '已成交';
       End If;

    End If;

    Return v_result;
  End;

  Function get_dispatch_type_name(p_id Varchar2) Return Varchar2
  Is
  Begin

if p_id='1' then
  	 return'重新安裝';
  elsif p_id='2' then
  	 return 'DOA';
  elsif p_id= '3' then
  	 return 'VIP';
  elsif p_id= '4' then
  	 return 'RMA保固';
  Elsif p_id= '5' then
  	 return 'RMA非保固';
   elsif p_id= '0' then
  	 return '新機安裝';
       elsif p_id= '6' then
  	 return '拆機';
      elsif p_id= '7' then
  	 return '收款/收單';
      elsif p_id= '8' then
  	 return 'SWAT';
      elsif p_id= '9' then
  	 return '失聯追蹤';
  else
     return null;
  end if;
  End ;

        Function get_bb_name(p_id Varchar2) Return Varchar2
  Is
    v_result Varchar2(256);
  Begin
    Select bb_name Into v_result From tgc_broadband_profile Where bb_id = p_id;
    Return v_result;
  Exception
    When no_data_found Then Return Null;
  End ;

          Function get_mso_name(p_id Varchar2) Return Varchar2
  Is
    v_result Varchar2(256);
  Begin
    Select mso_name Into v_result From tgc_mso_profile Where mso_id = p_id;
    Return v_result;
  Exception
    When no_data_found Then Return Null;
  End ;

  Function get_user_name(p_no Number) Return Varchar2
  Is
    v_result Varchar2(256);
  Begin
    Select Name Into v_result From sys_user
    Where user_no = p_no ;
    Return v_result;
  Exception
   When no_data_found Then Return Null;
  End;

    Function get_user_name(p_id Varchar2) Return Varchar2
  Is
    v_result Varchar2(256);
  Begin
    Select Name Into v_result From sys_user
    Where user_name = p_id ;
    Return v_result;
  Exception
   When no_data_found Then Return Null;
  End;
  Function get_dispatch_status_name(p_id Varchar2) Return Varchar2
  Is
  Begin
   /*
   Add_list_element('TGC_DISPATCH_INFO.STATUS',1,'打單','A');
     Add_list_element('TGC_DISPATCH_INFO.STATUS',2,'等待派工','P');
     Add_list_element('TGC_DISPATCH_INFO.STATUS',3,'已派工','D');
     Add_list_element('TGC_DISPATCH_INFO.STATUS',4,'完成','N');
     Add_list_element('TGC_DISPATCH_INFO.STATUS',5,'取消','C');
     */

    If p_id = 'A' Then
      Return '打單';
    Elsif p_id = 'P' Then
      Return '等待派工';
    Elsif p_id = 'D' Then
       Return '已派工';
    Elsif p_id = 'N' Then
       Return '完工' ;
    Elsif p_id = 'C' Then
       Return '取消';
    Elsif p_id = 'Z' Then
       Return '作廢';
     Elsif p_id = 'R' Then
       Return '已完工回覆';
     Else
      Return Null;
    End If;


  End get_dispatch_status_name;

  Function get_program_name_no(p_no Number) Return Varchar2
  Is
    v_result Varchar2(256);
  Begin
    If p_no Is Not Null Then
       Select tgc_util.get_program_name(program_id) Into v_result From tgc_order Where order_no=p_no;
       Return v_result;
    Else
       Return Null;
    End If;
  Exception
    When no_data_found Then Return Null;
  End ;
  
         Function trimstr(p_str Varchar2) Return Varchar2
     Is
        v_str Varchar2(2048);
        p_pos Number;
        v_char Varchar2(32);
     Begin
        v_str := p_str;
        v_char := ' ';
        p_pos := instr(v_str,v_char);
        While p_pos > 0 Loop
          v_str := substr(v_str,1,p_pos-1)||substr(v_str,p_pos+1,length(v_str));
          p_pos := instr(v_str,v_char);
        End Loop;

        v_char := '　';
        p_pos := instr(v_str,v_char);
        While p_pos > 0 Loop
          v_str := substr(v_str,1,p_pos-1)||substr(v_str,p_pos+1,length(v_str));
          p_pos := instr(v_str,v_char);
        End Loop;
        
        v_char := '-';
        p_pos := instr(v_str,v_char);
        While p_pos > 0 Loop
          v_str := substr(v_str,1,p_pos-1)||substr(v_str,p_pos+1,length(v_str));
          p_pos := instr(v_str,v_char);
        End Loop;
        Return v_str;
     End;
     
      Function get_first_dispatch_info(p_pk_no Number) Return Number
      Is
        v_pk_no Number;
      Begin
        Select dispatch_no Into v_pk_no
         From tgc_dispatch_info 
        Where order_no = p_pk_no
        And rownum <= 1 
        And status Not In ('Z')
        Order By dispatch_id;
        Return v_pk_no;
      Exception 
        When no_data_found Then Return Null;
      End;
    Function get_installer_name(p_pk_no Number) Return Varchar2
    Is
      v_user_name Varchar2(256);
      v_user_no  Number;
    Begin
      If p_pk_no Is Not Null Then
         Select a.Installer_No Into v_user_no
         From tgc_dispatch_info a
         Where a.dispatch_no = p_pk_no;
         
         v_user_name := tgc_util.get_user_name(v_user_no);
         Return v_user_name;
       Else
         Return Null;
     End If;    
    End;
      

    Function get_tgc_sale(p_pk_no Number) Return Varchar2
    Is 
      v_user_name Varchar2(256);
      v_referee Varchar2(256);
      v_cust_id Varchar2(256);
    Begin
      Select a.Referee,cust_id Into v_referee,v_cust_id
        From tgc_order a
        Where a.order_no= p_pk_no;
        
    --  If v_referee Is Null Then 
         Select  nvl(ref6,ref7) Into v_user_name
           From tgc_customer
          Where cust_id = v_cust_id;
    --  Else
      --         v_user_name := v_referee;
    --  End If;
      If v_user_name Is Null Then v_user_name := v_referee;
      End If;
      
      Return v_user_name;
      
    End;  
    
     Function get_order_close_date(p_pk_no Number) Return Date 
     Is
      v_order_type Varchar2(32);
      v_result Date;
      v_process_sts Varchar2(32);
      v_rec_date Date;
      v_complete_date Date;
      v_new_order_no Number;
     Begin
       Select order_type,process_sts,rec_tivo_date,a.complete_date,new_order_no
       Into  v_order_type,v_process_sts,v_rec_date,v_complete_date,v_new_order_no
       From tgc_order a
       Where order_no = p_pk_no;
       
       If v_order_type = 'P' Then 
         If v_rec_date Is Null Then 
            If v_new_order_no Is Not Null Then 
               Select nvl(complete_date,a.Order_Create_Date) Into v_complete_date
                 From tgc_order a
                 Where order_no = v_new_order_no;
             v_result := v_complete_date;
            Else
              v_result := Null;
            End If;
         Else
             v_Result := v_rec_date;
          End If;
            
             
       Else
         v_result := v_complete_date;
       End If;
         
       Return v_result;
     Exception
       When no_data_found Then Return Null;   
     End;   
     
     Function get_bid_type_name(p_bid_type Varchar2) Return Varchar2
     Is
     Begin
       If p_bid_type = '3' Then 
         Return '三聯式';
       Elsif p_bid_type ='2' Then
         Return '二聯式';
       Else
        Return Null;
       End If;
     End;
     
     Function get_bill_pay_type_name(p_pay_type Varchar2) Return Varchar2
     Is
     Begin
        If p_pay_type = '1' Then 
           Return '工程師收款';
        Elsif p_pay_type ='2' Then
           Return  '客人匯款或刷卡';
       Elsif p_pay_type='3' Then
          Return '貨到收款';
       Else 
          Return p_pay_type;
       End If;

     
     End;
     
     Function get_new_order_date(p_pk_no Number) Return Date 
     Is
      v_order_type Varchar2(32);
      v_result Date;
      v_process_sts Varchar2(32);
      v_rec_date Date;
      v_complete_date Date;
      v_new_order_no Number;
     Begin
       Select order_type,process_sts,rec_tivo_date,a.complete_date,new_order_no
       Into  v_order_type,v_process_sts,v_rec_date,v_complete_date,v_new_order_no
       From tgc_order a
       Where order_no = p_pk_no;
       
       If v_order_type = 'P' Then 
            If v_new_order_no Is Not Null Then 
               Select order_create_date Into v_complete_date
                 From tgc_order
                 Where order_no = v_new_order_no;
               v_result := v_complete_date;
            Else
              v_result := Null;
            End If;
      Else
        v_result := Null;      
       End If;
         
       Return v_result;
     Exception
       When no_data_found Then Return Null;   
     End;  
     
         Function get_new_order_status(p_pk_no Number) Return Varchar2
              Is
      v_order_type Varchar2(32);
      v_result Varchar2(128);
      v_process_sts Varchar2(32);
      v_rec_date varchar2(32);
      v_complete_date Date;
      v_new_order_no Number;
     Begin
       Select order_type,process_sts,rec_tivo_date,a.complete_date,new_order_no
       Into  v_order_type,v_process_sts,v_rec_date,v_complete_date,v_new_order_no
       From tgc_order a
       Where order_no = p_pk_no;
       
       If v_order_type = 'P' Then 
            If v_new_order_no Is Not Null Then 
               Select process_sts Into v_process_sts
                 From tgc_order
                 Where order_no = v_new_order_no;
               v_result := v_process_sts;
            Else
              v_result := Null;
            End If;
       Else
          v_result:= Null;     
       End If;
         
       Return v_result;
     Exception
       When no_data_found Then Return Null;   
     End; 
     
     Function get_cust_address(p_cust_no Number,p_address_type Varchar2) Return Varchar2
     Is
       v_result Varchar2(1024);
     Begin
     
        If p_address_type = 'W' Then
        
   /*       Begin
           Select b.Inst_Address Into v_result From service_detail b Where b.package_key=p_cust_no And rownum<=1;
                     Exception 
            When no_data_found Then v_result := Null;
          End;
            If v_result Is Null Then
              Begin
                 Select address Into v_result From tgc_customer Where user_no= p_cust_no;
              Exception 
                  When no_data_found Then v_result := Null;
               End;
           End If;*/
    /*    Elsif p_address_type = 'A' Then
          Begin
           Select b.bill_Address Into v_result From service_detail b Where b.package_key=p_cust_no And rownum<=1;
          Exception 
            When no_data_found Then v_result := Null;
          End; */
           
/*           If v_result Is Null Then
              Begin
                 Select nvl(bill_address,address) Into v_result From tgc_customer Where user_no= p_cust_no;
              Exception 
                  When no_data_found Then v_result := Null;
               End;
           End If;*/
         --  Elsif p_address_type = 'CA' Then
/*          Begin
           Select b.bill_Address Into v_result From service_detail b Where b.package_key=p_cust_no And rownum<=1;
          Exception 
            When no_data_found Then v_result := Null;
          End;
           */

              Begin
                 Select nvl(bill_address,address) Into v_result From tgc_customer Where user_no= p_cust_no;
              Exception 
                  When no_data_found Then v_result := Null;
               End;
          Else
           v_result := null;
/*           Select address Into v_result From tgc_customer Where user_no= p_cust_no;*/
        End If;
        Return v_result;
     Exception
        When no_data_found Then Return Null;
      End;
      
      
      Function get_invo_chg_amt(p_no Number,p_pk_no Number) Return Number
      Is
        v_result Number;
        v_grp_no Number;
        v_cnt Number;
        v_max_cnt Number;
        v_net_price Number;
       
     /*   Cursor c1 Is Select a.grp_no 
                             From service_invo_dtl a
                            Where mas_pk_no= p_pk_no
                            Group By grp_no; */
     /*   Cursor c2 Is Select b.amount
                              From service_invo_dtl b
                              Where b.mas_pk_no=p_pk_no
                               And grp_no = v_grp_no
                              Order By b.amount;  */
      Begin
        v_result := 0;
    /*   For c1rec In c1 Loop
          v_grp_no := c1rec.grp_no;
          v_cnt := 0;
          For c2rec In c2 Loop
            v_cnt := v_cnt+1;
            If v_cnt = 1 Then 
               v_net_price := c2rec.amount;
            Elsif v_cnt = p_no Then
               v_net_price := c2rec.amount;
            End If;        
          End Loop;
          
          v_result := v_result + v_net_price;
          If v_max_cnt < v_cnt Then 
            v_max_cnt := v_cnt;
          End If;
           
         
       End Loop; */
       
       If v_cnt < p_no Then 
          Return(Null);
       Else
          Return (v_result);
        End If;
      End;
      
      Function get_chg_name(p_chg_code Varchar2) Return Varchar2 Is 
        v_result Varchar2(256);
      Begin
         Select chg_name Into v_result From service_charge_mas
         Where chg_code = p_chg_code
              And rownum <= 1;
         Return v_result ;
      Exception 
        When no_data_found Then Return Null;
      End;
      
      Function get_pm_name(p_pm_code Varchar2) Return Varchar2 Is 
        v_result Varchar2(256);
      Begin
         Select pm_name Into v_result From service_pm_mas 
         Where pm_code = p_pm_code
              And rownum <= 1;
         Return v_result;
     Exception 
        When no_data_found Then 
           Return Null;
      End;
      
       Function get_item_name(p_item_id Varchar2) Return Varchar2 Is
         v_result Varchar(256);
       Begin
     /*    Select item_name Into v_result From service_item_mas a
         Where a.item_code = p_item_id
              And rownum <= 1;
         Return v_result;
       Exception 
         When no_data_found Then Return Null;
       End;
       
          Function get_TSN_from_pk(p_package_key Number) Return Varchar2 Is
         result_str Varchar2(32);
       Begin
         Select TCD_TSN Into result_str 
           From service_detail 
         Where package_key =p_package_key And TCD_TSN Is Not Null
       --  And item_code In ('KA-80S','KA-160S')
         And rownum <= 1;
         Return result_str;
       Exception 
          When no_data_found Then  */
           Return Null;
       End;
       
              
       Function get_con_from_pk(p_package_key Number) Return Varchar2 Is
         result_str Varchar2(32);
       Begin
    /*     Select a.contract_no Into result_str 
           From service_detail a 
         Where package_key =p_package_key 
         And a.contract_no Is Not Null
    --     And item_code In ('KA-80S','KA160S')
         And rownum <= 1;
         Return result_str;
       Exception 
          When no_data_found Then  */
           Return Null;
       End;
      
     Function get_cust_zip(p_cust_no Number,p_address_type Varchar2) Return Varchar2
     Is
       v_result Varchar2(1024);
     Begin
      
        Return v_result;
     Exception
        When no_data_found Then Return Null;
      End;
      

        Function get_pay_mode(p_pay_mode Varchar) Return Varchar2 Is
          v_Result Varchar2(64);
        Begin
          If p_pay_mode = 'CARD' Then 
             v_result := '信用卡';
          Elsif p_pay_mode = 'TRANSFER' Then 
             v_result :='轉帳';
          Elsif p_pay_mode =  'STORE'  Then 
             v_result := '便利商店';
          Else 
           v_result :=p_pay_mode;
          End If;
          
           Return v_result;
        End;
        
        Function get_trx_type_name(p_trx_type Varchar) Return Varchar2 Is
          v_Result Varchar2(64);
        Begin
          If p_trx_type = 'R' Then 
             v_result := '退還貨';
          Elsif p_trx_type = 'C' Then 
             v_result :='換貨';
          Elsif p_trx_type =  'S'  Then 
             v_result := '出貨';
          Elsif p_trx_type =  'L'  Then 
             v_result := '借出';
         Elsif p_trx_type =  'N'  Then 
             v_result := '不必出貨';
          Elsif p_trx_type =  'G'  Then 
             v_result := '換貨';
          Elsif p_trx_type =  'F'  Then 
             v_result := '調整';
          Else 
           v_result :=p_trx_type;
          End If;
          
           Return v_result;
        End;
        

         Function get_taxdate_from_invitem(p_invo_no number,p_stock_id varchar default null) return date
        is


        begin
         
          return null;
        end;
          Function get_taxtitle_from_invitem(p_invo_no number,p_stock_id varchar default null) return varchar2
        is
          

        begin

           return null;

        end;
Function get_taxbid_from_invitem(p_invo_no number,p_stock_id varchar default null) return varchar2
        is


        begin
          
           return null;

        end;
        
   Function get_virtual_acc(p_invo_no varchar2,p_amount number) return varchar2
   is 
   begin
     RETURN '8170'||p_invo_no||to_char(vachksum('8170'||p_invo_no,p_amount));
   end;
      
   Function chk_main_item(item_code varchar2,TSN varchar2) return varchar2 is
     v_result varchar2(32);
   begin
       v_result := 'N';
      
      if item_code is not null then 
         if item_code in ('KA-80S','KA-160S','KA-500S','EPG_SERVICE','KA-160S-6000') then
           v_result := 'Y';
         else
           v_result := 'N';
         end if;
      else
         if substr(TSN,1,3)='1E2' then
            v_result := 'Y';
         else 
            v_result := 'N';
         end if;
      end if;
      return v_result;
   end chk_main_item;
   Function get_TSN_from_pk(p_package_key Number) Return Varchar2
     is
     begin
       return null;
     end;
   
End tgc_util;
/

