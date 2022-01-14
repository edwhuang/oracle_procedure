CREATE OR REPLACE PACKAGE IPTV.BSM_PURCHASE_POST_OLD is
  TYPE t_parameters IS TABLE OF number(2) INDEX BY BINARY_INTEGER;
  TYPE t_parameters_c IS TABLE OF varchar2(1) INDEX BY BINARY_INTEGER;

  Error_Package_Mas       Exception;
  client_not_found        Exception;
  client_status_error     Exception;
  coupon_not_found        Exception;
  coupon_registed         Exception;
  coupon_model_error      Exception;
  coupon_demo_error       Exception;
  demo_on_not_demo_client Exception;
  coupon_on_demo_client   Exception;
  coupon_group_no_found   Exception;
  coupon_expired          Exception;
  coupon_program_registed Exception;

  Function PURCHASE_POST(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function PURCHASE_COMPLETE(p_User_No Number, p_Pk_No Number)
    Return Varchar2;
  Function PURCHASE_COMPLETE_R(p_User_No      Number,
                               p_Pk_No        Number,
                               refresh_client varchar) Return Varchar2;
  Function PURCHASE_CANCEL(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function PURCHASE_UNPOST(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function CLIENT_GENERATE_COUPON_NO(COUPON_DATE date,
                                     coupon_type varchar2) return varchar2;
  Function CLIENT_REGIETER_COUPON(client_id   varchar2,
                                  coupon_no   varchar2,
                                  p_device_id varchar2 default null)
    return varchar2;
  Function CLIENT_REGIETER_COUPOR(client_id      varchar2,
                                  coupon_no      varchar2,
                                  refresh_client varchar,
                                  p_device_id    varchar2 default null)
    return varchar2;
  Function COUPON_NO_CHECK(COUPON_NO varchar) return varchar2;
  Function COUPON_POST(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function COUPON_COMPLETE(p_User_No Number, p_Pk_No Number) Return Varchar2;

  Function COUPON_COMPLETE_R(p_User_No      Number,
                             p_Pk_No        Number,
                             refresh_client varchar) Return Varchar2;
  Function COUPON_UNPOST(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function COUPON_CANCEL(p_User_No Number, p_Pk_No Number) Return Varchar2;
  Function COUPON_CANCEL_COMPLETE(p_User_No Number, p_Pk_No Number)
    Return Varchar2;
  Function COUPON_BATCH_POST(p_User_No Number, p_Pk_No Number)
    Return Varchar2;
  Function COUPON_BATCH_POST_N(p_User_No Number, p_Pk_No Number)
    Return Varchar2;
  Function COUPON_BATCH_POST_COUPON(p_User_No         Number,
                                    p_Pk_No           Number,
                                    p_start_serial_no varchar2,
                                    p_end_serial_no   varchar2)
    Return Varchar2;
  Function COUPON_BATCH_POST_COUPON_N(p_User_No         Number,
                                      p_Pk_No           Number,
                                      p_start_serial_no varchar2,
                                      p_end_serial_no   varchar2)
    Return Varchar2;

  Function COUPON_BATCH_CANCEL_COUPON(p_User_No         Number,
                                      p_Pk_No           Number,
                                      p_start_serial_no varchar2,
                                      p_end_serial_no   varchar2)
    Return Varchar2;
  Function COUPON_BATCH_SET_COUPON(p_User_No         Number,
                                   p_Pk_No           Number,
                                   p_start_serial_no varchar2,
                                   p_end_serial_no   varchar2,
                                   p_exp_date        date) Return Varchar2;

  Function cal_end_date(p_start_date date, duration_day number) return date;

  procedure process_purchase_detail(client_id      varchar2,
                                    purchase_pk_no number);
  procedure cal_client_credits(p_client_id      varchar2,
                               p_package_id     varchar2,
                               p_purchase_pk_no number,
                               p_exp_days       number default null);

  function use_credits(p_client_id varchar2, p_purchase_pk_no number)
    return varchar2;
  function cancel_all_purchase(p_User_No Number, client_id varchar2)
    return varchar2;
  function hide_all_purchase(p_User_No Number, client_id varchar2)
    return varchar2;
  function get_vis_acc(p_mas_no varchar2, p_due_date date, p_amount number)
    return varchar2;

  procedure refresh_bsm_client(v_client_id varchar2);
End BSM_PURCHASE_POST_OLD;
/

