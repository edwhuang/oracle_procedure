create or replace procedure iptv.crt_purchase_2(
                                         p_client_id  varchar2,
                                         p_package_id varchar2,
                                         p_src_no     varchar2

                                         ) is
    v_char varchar2(32);
begin
    select 'x' into v_char from bsm_purchase_mas where status_flg='Z' and
  src_no=p_src_no and rownum <=1;
  exception
    when no_data_found then

  declare
    v_Purchase_Pk_No      number(16);
    v_purchase_item_pk_no number(16);
    v_purchase_no         varchar2(32);
    v_acc_invo_no         varchar2(32);
    v_pay_type            varchar2(32) := 'IOS';
    v_acc_name            varchar2(32);
    v_Purchase_Mas_Code   varchar(32) := 'BSMPUR';
    v_Serial_No           number(16);
    v_id                  varchar2(32) := p_package_id;
    v_Price               number(16);
    v_Duration            number(16);
    v_Quota               number(16);
    v_charge_type         varchar2(32);
    v_charge_code         varchar2(32);
    v_client_id           varchar(32) := p_client_id;
    v_device_id           varchar2(32);
    v_mas_no              varchar2(32) := p_src_no;
    v_charge_name         varchar2(32);

  begin
     Select Seq_Bsm_Purchase_Pk_No.Nextval Into v_Purchase_Pk_No From Dual;

    v_Purchase_Mas_Code := 'BSMPUR';

    v_Purchase_No := Sysapp_Util.Get_Mas_No(1,
                                            2,
                                            Sysdate,
                                            v_Purchase_Mas_Code,
                                            v_Purchase_Pk_No);
    v_acc_invo_no := sysapp_util.get_mas_no(1,
                                            2,
                                            sysdate,
                                            'BSMPUR_INV',
                                            v_Purchase_Pk_No);

    Insert Into Bsm_Purchase_Mas
      (Src_No,
       Pk_No,
       Mas_No,
       Mas_Date,
       Mas_Code,
       Src_Code,
       Src_Date,
       Serial_No,
       acc_code,
       Serial_Id,
       Status_Flg,
       Purchase_Date,
       Pay_Type,
       Card_type,
       Card_no,
       Card_Expiry,
       Cvc2,
       inv_no,
       f_year,
       f_period,
       due_date,
       acc_name,
       tax_code,
       recurrent,
       start_type)
    Values
      (v_mas_no,
       v_Purchase_Pk_No,
       v_Purchase_No,
       Sysdate,
       v_Purchase_Mas_Code,
       Null,
       Null,
       v_Serial_No,
       null,
       v_client_Id,
       'Z', -- 狀態已完成
       Sysdate,
       v_Pay_Type,
       null,
       null,
       null,
       null,
       v_acc_invo_no,
       to_number(to_char(sysdate, 'YYYY')),
       to_number(to_char(sysdate, 'MM')),
       sysdate + 7,
       v_acc_name,
       null,
       'R',
       'E');

    --
    --  計算價格
    --

    Begin
      Select a.Charge_Amount,
             a.Acl_Duration,
             a.Acl_Quota,
             a.charge_type,
             a.charge_code
        Into v_Price, v_Duration, v_Quota, v_charge_type, v_charge_code
        From Bsm_Package_Mas a
       Where a.Package_id = v_id;

    End;

    Select Seq_Bsm_Purchase_Pk_No.Nextval
      Into v_Purchase_Item_Pk_No
      From Dual;

    v_charge_code := 'PMONTHFEE';
    v_charge_name := '預付月租費';
    Insert Into Bsm_Purchase_Item
      (Pk_No,
       Mas_Pk_No,
       Package_ID,
       ITEM_ID,
       Price,
       Amount,
       Duration,
       CHG_TYPE,
       CHG_CODE,
       CHG_NAME,
       TAX_AMT,
       CHG_AMT,
       TOTAL_AMT,
       DEVICE_ID)
    Values
      (v_Purchase_Item_Pk_No,
       v_Purchase_Pk_No,
       v_id,
       null,
       v_Price,
       v_Price,
       v_Duration,
       v_charge_type,
       v_charge_code,
       v_charge_name,
       0,
       0,
       v_Price,
       v_device_id);
    commit;

    --
    --  產生 service details
    --
    bsm_purchase_post.process_purchase_detail(v_client_Id,v_Purchase_Pk_No); --產生服務

    update bsm_client_details a set a.package_name='贈送一天'
    , a.end_date=to_date(to_char(a.start_date,'YYYYMMDD')||'235959','YYYYMMDDHH24MISS')
    where a.src_pk_no=v_Purchase_Pk_No; --服務到期日改成一日
    commit;


    BSM_client_service.Set_subscription(v_Purchase_Pk_No, v_client_Id);


end;
end;
/

