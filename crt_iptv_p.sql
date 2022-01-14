-------------------------------------------------------
-- Export file for user IPTV                         --
-- Created by edward.huang on 2022/1/14, 下午 02:31:00 --
-------------------------------------------------------
set define off
set escape on

spool crt_twdevdb_iptv.log

prompt
prompt Creating package B64
prompt ====================
prompt
@@b64.spc
prompt
prompt Creating package BSM_APT_SERVICE
prompt ================================
prompt
@@bsm_apt_service.spc
prompt
prompt Creating package BSM_CDI_SERVICE
prompt ================================
prompt
@@bsm_cdi_service.spc
prompt
prompt Creating package BSM_CDI_SERVICE_DEV
prompt ====================================
prompt
@@bsm_cdi_service_dev.spc
prompt
prompt Creating package BSM_CHT_SERVICE
prompt ================================
prompt
@@bsm_cht_service.spc
prompt
prompt Creating package BSM_CHT_SERVICE_DEV
prompt ====================================
prompt
@@bsm_cht_service_dev.spc
prompt
prompt Creating package BSM_CLIENT_SERVICE
prompt ===================================
prompt
@@bsm_client_service.spc
prompt
prompt Creating package BSM_CLIENT_SERVICE_DEV
prompt =======================================
prompt
@@bsm_client_service_dev.spc
prompt
prompt Creating package BSM_CLIENT_SERVICE_DEV2
prompt ========================================
prompt
@@bsm_client_service_dev2.spc
prompt
prompt Creating package BSM_ENCRYPT
prompt ============================
prompt
@@bsm_encrypt.spc
prompt
prompt Creating package BSM_IOS_GATEWAY
prompt ================================
prompt
@@bsm_ios_gateway.spc
prompt
prompt Creating package BSM_IOS_GATEWAY_DEV
prompt ====================================
prompt
@@bsm_ios_gateway_dev.spc
prompt
prompt Creating package BSM_ISSUE_POST
prompt ===============================
prompt
@@bsm_issue_post.spc
prompt
prompt Creating package BSM_LIPAY_GATEWAY
prompt ==================================
prompt
@@bsm_lipay_gateway.spc
prompt
prompt Creating package BSM_LIPAY_GATEWAY_NEW
prompt ======================================
prompt
@@bsm_lipay_gateway_new.spc
prompt
prompt Creating package BSM_ORDER_SERVICE
prompt ==================================
prompt
@@bsm_order_service.spc
prompt
prompt Creating package BSM_ORDER_SERVICE_DEV
prompt ======================================
prompt
@@bsm_order_service_dev.spc
prompt
prompt Creating package BSM_PAYMENT_GATEWAY
prompt ====================================
prompt
@@bsm_payment_gateway.spc
prompt
prompt Creating package BSM_PAYMENT_GATEWAY_CR
prompt =======================================
prompt
@@bsm_payment_gateway_cr.spc
prompt
prompt Creating package BSM_PAYMENT_GATEWAY_DEV
prompt ========================================
prompt
@@bsm_payment_gateway_dev.spc
prompt
prompt Creating package BSM_PAYMENT_GATEWAY_LIPAY
prompt ==========================================
prompt
@@bsm_payment_gateway_lipay.spc
prompt
prompt Creating package BSM_PURCHASE_POST
prompt ==================================
prompt
@@bsm_purchase_post.spc
prompt
prompt Creating package BSM_PURCHASE_POST_BK
prompt =====================================
prompt
@@bsm_purchase_post_bk.spc
prompt
prompt Creating package BSM_PURCHASE_POST_DEV
prompt ======================================
prompt
@@bsm_purchase_post_dev.spc
prompt
prompt Creating package BSM_PURCHASE_POST_OLD
prompt ======================================
prompt
@@bsm_purchase_post_old.spc
prompt
prompt Creating package BSM_RECURRENT_POST
prompt ===================================
prompt
@@bsm_recurrent_post.spc
prompt
prompt Creating package BSM_RECURRENT_UTIL
prompt ===================================
prompt
@@bsm_recurrent_util.spc
prompt
prompt Creating package BSM_RECURRENT_UTIL_DEV
prompt =======================================
prompt
@@bsm_recurrent_util_dev.spc
prompt
prompt Creating package BSM_RECURRENT_UTIL_OLD
prompt =======================================
prompt
@@bsm_recurrent_util_old.spc
prompt
prompt Creating package BSM_RECURRENT_UTIL_PC
prompt ======================================
prompt
@@bsm_recurrent_util_pc.spc
prompt
prompt Creating package BSM_SMS_SERVICE
prompt ================================
prompt
@@bsm_sms_service.spc
prompt
prompt Creating package BSM_WEB_SERVICE
prompt ================================
prompt
@@bsm_web_service.spc
prompt
prompt Creating package CMS_CNT_POST
prompt =============================
prompt
@@cms_cnt_post.spc
prompt
prompt Creating package CMS_UTIL
prompt =========================
prompt
@@cms_util.spc
prompt
prompt Creating package ELM_ORDER_SERVICE
prompt ==================================
prompt
@@elm_order_service.spc
prompt
prompt Creating package FREE_VIDEO_REPORT
prompt ==================================
prompt
@@free_video_report.spc
prompt
prompt Creating package INV_TRX_POST
prompt =============================
prompt
@@inv_trx_post.spc
prompt
prompt Creating package MFG_POST
prompt =========================
prompt
@@mfg_post.spc
prompt
prompt Creating package PARTNER_SERVICE
prompt ================================
prompt
@@partner_service.spc
prompt
prompt Creating package PARTNER_SERVICE_210628
prompt =======================================
prompt
@@partner_service_210628.spc
prompt
prompt Creating package PARTNER_SERVICE_BK
prompt ===================================
prompt
@@partner_service_bk.spc
prompt
prompt Creating package PARTNER_SERVICE_BK2
prompt ====================================
prompt
@@partner_service_bk2.spc
prompt
prompt Creating package PARTNER_SERVICE_DEV
prompt ====================================
prompt
@@partner_service_dev.spc
prompt
prompt Creating package PARTNER_SERVICE_OLD
prompt ====================================
prompt
@@partner_service_old.spc
prompt
prompt Creating package PKG_TGC_ORDER_TRANS
prompt ====================================
prompt
@@pkg_tgc_order_trans.spc
prompt
prompt Creating package SERVICE_ANA_POST
prompt =================================
prompt
@@service_ana_post.spc
prompt
prompt Creating package SYSAPP_UTIL
prompt ============================
prompt
@@sysapp_util.spc
prompt
prompt Creating package TAX_POST
prompt =========================
prompt
@@tax_post.spc
prompt
prompt Creating package TAX_POST_DEV
prompt =============================
prompt
@@tax_post_dev.spc
prompt
prompt Creating package TGC_BILL_POST
prompt ==============================
prompt
@@tgc_bill_post.spc
prompt
prompt Creating package TGC_BILL_POST_T
prompt ================================
prompt
@@tgc_bill_post_t.spc
prompt
prompt Creating package TGC_CREDIT_POST
prompt ================================
prompt
@@tgc_credit_post.spc
prompt
prompt Creating package TGC_ORDER_POST
prompt ===============================
prompt
@@tgc_order_post.spc
prompt
prompt Creating package TGC_ORDER_POST2
prompt ================================
prompt
@@tgc_order_post2.spc
prompt
prompt Creating package TGC_SET_POST
prompt =============================
prompt
@@tgc_set_post.spc
prompt
prompt Creating package TGC_UTIL
prompt =========================
prompt
@@tgc_util.spc
prompt
prompt Creating package TI_SYS_LOGIN
prompt =============================
prompt
@@ti_sys_login.spc
prompt
prompt Creating package TSN_REG_POST
prompt =============================
prompt
@@tsn_reg_post.spc
prompt
prompt Creating package TSTAR_ORDER_SERVICE
prompt ====================================
prompt
@@tstar_order_service.spc
prompt
prompt Creating package TSTAR_ORDER_SERVICE_2
prompt ======================================
prompt
@@tstar_order_service_2.spc
prompt
prompt Creating function ACTIVATE_CLIENT
prompt =================================
prompt
@@activate_client.fnc
prompt
prompt Creating function CHECKCODE
prompt ===========================
prompt
@@checkcode.fnc
prompt
prompt Creating function DIGITSUM
prompt ==========================
prompt
@@digitsum.fnc
prompt
prompt Creating function BARCODE3
prompt ==========================
prompt
@@barcode3.fnc
prompt
prompt Creating function BARCODE_4
prompt ===========================
prompt
@@barcode_4.fnc
prompt
prompt Creating function BSM_PURCHASE_DTLS
prompt ===================================
prompt
@@bsm_purchase_dtls.fnc
prompt
prompt Creating function CACHE_METADATA_2
prompt ==================================
prompt
@@cache_metadata_2.fnc
prompt
prompt Creating function CAL_DATE
prompt ==========================
prompt
@@cal_date.fnc
prompt
prompt Creating function CCC_CONTENT_META_IMPORT
prompt =========================================
prompt
@@ccc_content_meta_import.fnc
prompt
prompt Creating function CCC_PACKAGE_IMPORT
prompt ====================================
prompt
@@ccc_package_import.fnc
prompt
prompt Creating function CHECK_CDI_ACCESS
prompt ==================================
prompt
@@check_cdi_access.fnc
prompt
prompt Creating function CHECK_CDI_ACCESS2
prompt ===================================
prompt
@@check_cdi_access2.fnc
prompt
prompt Creating function CHECK_CDI_ACCESS3
prompt ===================================
prompt
@@check_cdi_access3.fnc
prompt
prompt Creating function COUNT_RECURRENT
prompt =================================
prompt
@@count_recurrent.fnc
prompt
prompt Creating function COUPON_BATCH_POST_N
prompt =====================================
prompt
@@coupon_batch_post_n.fnc
prompt
prompt Creating function DECY
prompt ======================
prompt
@@decy.fnc
prompt
prompt Creating function FN_CHK_FUTURE_PAID_PUR_CNT
prompt ============================================
prompt
@@fn_chk_future_paid_pur_cnt.fnc
prompt
prompt Creating function FN_CHK_FUTURE_PAID_PUR_CNT2
prompt =============================================
prompt
@@fn_chk_future_paid_pur_cnt2.fnc
prompt
prompt Creating function FN_CHK_OTHER_PAID_PUR_CNT
prompt ===========================================
prompt
@@fn_chk_other_paid_pur_cnt.fnc
prompt
prompt Creating function FN_CHK_PKG_CAT_MAX_END_DATE
prompt =============================================
prompt
@@fn_chk_pkg_cat_max_end_date.fnc
prompt
prompt Creating function FN_CHK_PREPAID_EXCLD_CNT
prompt ==========================================
prompt
@@fn_chk_prepaid_excld_cnt.fnc
prompt
prompt Creating function FN_CHK_PREPAID_EXCL_CNT
prompt =========================================
prompt
@@fn_chk_prepaid_excl_cnt.fnc
prompt
prompt Creating function FN_GET_RECUR_MAX_MAS_DATE
prompt ===========================================
prompt
@@fn_get_recur_max_mas_date.fnc
prompt
prompt Creating function FUNC
prompt ======================
prompt
@@func.fnc
prompt
prompt Creating function GET_DEVICE_TOKEN
prompt ==================================
prompt
@@get_device_token.fnc
prompt
prompt Creating function GET_CDI_CHECK_ACCESS
prompt ======================================
prompt
@@get_cdi_check_access.fnc
prompt
prompt Creating function GET_CDI_INFO
prompt ==============================
prompt
@@get_cdi_info.fnc
prompt
prompt Creating function GET_CLIENT_CDI_DATA
prompt =====================================
prompt
@@get_client_cdi_data.fnc
prompt
prompt Creating function GET_CLIENT_VAL
prompt ================================
prompt
@@get_client_val.fnc
prompt
prompt Creating function GET_CLIENT_VAL_2
prompt ==================================
prompt
@@get_client_val_2.fnc
prompt
prompt Creating function GET_DATETIME
prompt ==============================
prompt
@@get_datetime.fnc
prompt
prompt Creating function GET_DEVICE_CURRENT_SWVER
prompt ==========================================
prompt
@@get_device_current_swver.fnc
prompt
prompt Creating function GET_DEVICE_MODEL_T
prompt ====================================
prompt
@@get_device_model_t.fnc
prompt
prompt Creating function GET_END_DATE
prompt ==============================
prompt
@@get_end_date.fnc
prompt
prompt Creating function GET_EXIPIRED
prompt ==============================
prompt
@@get_exipired.fnc
prompt
prompt Creating function GET_RESULT_ACTIVATE_STATUS
prompt ============================================
prompt
@@get_result_activate_status.fnc
prompt
prompt Creating function GET_RESULT_ACTIVATE_SWVER
prompt ===========================================
prompt
@@get_result_activate_swver.fnc
prompt
prompt Creating function GET_RESULT_ACTIVATE_VER
prompt =========================================
prompt
@@get_result_activate_ver.fnc
prompt
prompt Creating function GET_RESULT_CURRENT_STATUS
prompt ===========================================
prompt
@@get_result_current_status.fnc
prompt
prompt Creating function GET_RESULT_CURRENT_SWVER
prompt ==========================================
prompt
@@get_result_current_swver.fnc
prompt
prompt Creating function GET_RESULT_CURRENT_SWVER_D
prompt ============================================
prompt
@@get_result_current_swver_d.fnc
prompt
prompt Creating function GET_RESULT_LATEST_SWVER
prompt =========================================
prompt
@@get_result_latest_swver.fnc
prompt
prompt Creating function GET_SHOWCASE_SEQ
prompt ==================================
prompt
@@get_showcase_seq.fnc
prompt
prompt Creating function GET_SOFTWARE_GROUP
prompt ====================================
prompt
@@get_software_group.fnc
prompt
prompt Creating function GET_SOFTWARE_GROUP2
prompt =====================================
prompt
@@get_software_group2.fnc
prompt
prompt Creating function GET_SOFTWARE_GROUP_4GTV
prompt =========================================
prompt
@@get_software_group_4gtv.fnc
prompt
prompt Creating function GET_STOCK_BROKER
prompt ==================================
prompt
@@get_stock_broker.fnc
prompt
prompt Creating function GET_TOKEN
prompt ===========================
prompt
@@get_token.fnc
prompt
prompt Creating function IMPORTWEBREG
prompt ==============================
prompt
@@importwebreg.fnc
prompt
prompt Creating procedure CRT_PURCHASE_IOS_DEV
prompt =======================================
prompt
@@crt_purchase_ios_dev.prc
prompt
prompt Creating function IOS_AUTO_RECURRENT
prompt ====================================
prompt
@@ios_auto_recurrent.fnc
prompt
prompt Creating function IOS_AUTO_RECURRENT_BK
prompt =======================================
prompt
@@ios_auto_recurrent_bk.fnc
prompt
prompt Creating function IOS_AUTO_RECURRENT_DEV
prompt ========================================
prompt
@@ios_auto_recurrent_dev.fnc
prompt
prompt Creating function IOS_AUTO_RECURRENT_DEV2
prompt =========================================
prompt
@@ios_auto_recurrent_dev2.fnc
prompt
prompt Creating function IOS_AUTO_RECURRENT_FUNC
prompt =========================================
prompt
@@ios_auto_recurrent_func.fnc
@@partitionstring.fnc
prompt
prompt Creating function PROMO_ACTIVATE
prompt ================================
prompt
@@promo_activate.fnc
prompt
prompt Creating function PROMO_ACTIVATE_30DAY
prompt ======================================
prompt
@@promo_activate_30day.fnc
prompt
prompt Creating function QUERYORDERS
prompt =============================
prompt
@@queryorders.fnc
prompt
prompt Creating function RPADB
prompt =======================
prompt
@@rpadb.fnc
prompt
prompt Creating function SEND_BONUSWINNER_CUPS
prompt =======================================
prompt
@@send_bonuswinner_cups.fnc
prompt
prompt Creating function SEND_KOD_SHOWCASE
prompt ===================================
prompt
@@send_kod_showcase.fnc
prompt
prompt Creating function SET_CLIENT_VAL
prompt ================================
prompt
@@set_client_val.fnc
prompt
prompt Creating function SHOW_VERSION
prompt ==============================
prompt
@@show_version.fnc
prompt
prompt Creating function SPLIT_DATE
prompt ============================
prompt
@@split_date.fnc
prompt
prompt Creating function STR2TBL
prompt =========================
prompt
@@str2tbl.fnc
prompt
prompt Creating function SYN_SWVERS
prompt ============================
prompt
@@syn_swvers.fnc
prompt
prompt Creating function TEST_JOSN
prompt ===========================
prompt
@@test_josn.fnc
prompt
prompt Creating function TEST_SENDALL_HTTP
prompt ===================================
prompt
@@test_sendall_http.fnc
prompt
prompt Creating procedure CMS_VIP_PROCESS
prompt ==================================
prompt
@@cms_vip_process.prc
prompt
prompt Creating procedure P_PREPARE_ACL_ITEM
prompt =====================================
prompt
@@p_prepare_acl_item.prc
prompt
prompt Creating procedure ACL_MASTER_TRANSFER
prompt ======================================
prompt
@@acl_master_transfer.prc
prompt
prompt Creating function TGC_CMS_CNTLIST_POST
prompt ======================================
prompt
@@tgc_cms_cntlist_post.fnc
prompt
prompt Creating function TOTALCHKSUM
prompt =============================
prompt
@@totalchksum.fnc
prompt
prompt Creating function UNIXDATE_TO_ORADATE
prompt =====================================
prompt
@@unixdate_to_oradate.fnc
prompt
prompt Creating function UPDATE_BSM_DETAIL
prompt ===================================
prompt
@@update_bsm_detail.fnc
prompt
prompt Creating function UPDATE_EXP_DATE
prompt =================================
prompt
@@update_exp_date.fnc
prompt
prompt Creating function VACHKSUM
prompt ==========================
prompt
@@vachksum.fnc
prompt
prompt Creating function WORD_COUNT
prompt ============================
prompt
@@word_count.fnc
prompt
prompt Creating procedure ACL_MASTER_TRANSFER_2
prompt ========================================
prompt
@@acl_master_transfer_2.prc
prompt
prompt Creating procedure ACL_MASTER_TRANSFER_ALL
prompt ==========================================
prompt
@@acl_master_transfer_all.prc
prompt
prompt Creating procedure ACL_MASTER_TRANSFER_BK
prompt =========================================
prompt
@@acl_master_transfer_bk.prc
prompt
prompt Creating procedure AUTO_CLIENT_SERVICE
prompt ======================================
prompt
@@auto_client_service.prc
prompt
prompt Creating procedure AUTO_REFRASH_FREE
prompt ====================================
prompt
@@auto_refrash_free.prc
prompt
prompt Creating procedure AUTO_REPORT_TYPE
prompt ===================================
prompt
@@auto_report_type.prc
prompt
prompt Creating procedure AUTO_RESET_DEMO
prompt ==================================
prompt
@@auto_reset_demo.prc
prompt
prompt Creating procedure BSM_PACKAGE_CHG_P
prompt ====================================
prompt
@@bsm_package_chg_p.prc
prompt
prompt Creating procedure CALCUTION_HLS
prompt ================================
prompt
@@calcution_hls.prc
prompt
prompt Creating procedure CPY_PACKAGE
prompt ==============================
prompt
@@cpy_package.prc
prompt
prompt Creating procedure CPY_PACKAGE_NOSG
prompt ===================================
prompt
@@cpy_package_nosg.prc
prompt
prompt Creating procedure CPY_PACKAGE_SG
prompt =================================
prompt
@@cpy_package_sg.prc
prompt
prompt Creating procedure CRT_PURCHASE
prompt ===============================
prompt
@@crt_purchase.prc
prompt
prompt Creating procedure CRT_PURCHASE_2
prompt =================================
prompt
@@crt_purchase_2.prc
prompt
prompt Creating procedure CRT_PURCHASE_3
prompt =================================
prompt
@@crt_purchase_3.prc
prompt
prompt Creating procedure CRT_PURCHASE_IOS
prompt ===================================
prompt
@@crt_purchase_ios.prc
prompt
prompt Creating procedure FA_CAL_PURCHASE_DIS
prompt ======================================
prompt
@@fa_cal_purchase_dis.prc
prompt
prompt Creating procedure GENERATE_BSM_CLIENT_MAS
prompt ==========================================
prompt
@@generate_bsm_client_mas.prc
prompt
prompt Creating procedure GENERATE_MFG_IPTV_MAS
prompt ========================================
prompt
@@generate_mfg_iptv_mas.prc
prompt
prompt Creating procedure GO_ASSET
prompt ===========================
prompt
@@go_asset.prc
prompt
prompt Creating procedure HLS_LOG_PROCESS
prompt ==================================
prompt
@@hls_log_process.prc
prompt
prompt Creating procedure MODIFY_SERVICE_1111_P6
prompt =========================================
prompt
@@modify_service_1111_p6.prc
prompt
prompt Creating procedure MODIFY_SERVICE_1111_P
prompt ========================================
prompt
@@modify_service_1111_p.prc
prompt
prompt Creating procedure MODIFY_SERVICE_1111_P4
prompt =========================================
prompt
@@modify_service_1111_p4.prc
prompt
prompt Creating procedure MODIFY_SERVICE_1111_P5
prompt =========================================
prompt
@@modify_service_1111_p5.prc
prompt
prompt Creating procedure MODIFY_SERVICE_1111_P6_B
prompt ===========================================
prompt
@@modify_service_1111_p6_b.prc
prompt
prompt Creating procedure MODIFY_SERVICE_1111_P7
prompt =========================================
prompt
@@modify_service_1111_p7.prc
prompt
prompt Creating procedure MTK_201302
prompt =============================
prompt
@@mtk_201302.prc
prompt
prompt Creating procedure PURCHASE_CALLBACK_PROCEDURE
prompt ==============================================
prompt
@@purchase_callback_procedure.prc
prompt
prompt Creating procedure PURCHASE_CALLBACK_PROCEDURE_B2
prompt =================================================
prompt
@@purchase_callback_procedure_b2.prc
prompt
prompt Creating procedure PURCHASE_CALLBACK_PROCEDURE_BK
prompt =================================================
prompt
@@purchase_callback_procedure_bk.prc
prompt
prompt Creating procedure P_ADD_BSM_CLIENT_DETAILS
prompt ===========================================
prompt
@@p_add_bsm_client_details.prc
prompt
prompt Creating procedure P_BSM_ACCOUNT_CLEAR
prompt ======================================
prompt
@@p_bsm_account_clear.prc
prompt
prompt Creating procedure P_CHT_PROCESS
prompt ================================
prompt
@@p_cht_process.prc
prompt
prompt Creating procedure P_CRT_PURCHASE_IOS
prompt =====================================
prompt
@@p_crt_purchase_ios.prc
prompt
prompt Creating procedure P_GIFT_COUPON
prompt ================================
prompt
@@p_gift_coupon.prc
prompt
prompt Creating procedure P_HIKIDS
prompt ===========================
prompt
@@p_hikids.prc
prompt
prompt Creating procedure REFRESH_BSM_SERVER
prompt =====================================
prompt
@@refresh_bsm_server.prc
prompt
prompt Creating procedure REFRESH_BSM
prompt ==============================
prompt
@@refresh_bsm.prc
prompt
prompt Creating procedure P_PACKAGE_SPECIAL
prompt ====================================
prompt
@@p_package_special.prc
prompt
prompt Creating procedure P_UPDATE_CCC_PROGRAM_TITLE
prompt =============================================
prompt
@@p_update_ccc_program_title.prc
prompt
prompt Creating procedure P_W00001_PROCESS
prompt ===================================
prompt
@@p_w00001_process.prc
prompt
prompt Creating procedure RECAL_COUPON_AMOUNT
prompt ======================================
prompt
@@recal_coupon_amount.prc
prompt
prompt Creating procedure RECAL_COUPON_AMOUNT_2
prompt ========================================
prompt
@@recal_coupon_amount_2.prc
prompt
prompt Creating procedure RECOMPILE
prompt ============================
prompt
@@recompile.prc
prompt
prompt Creating procedure REFRASH_BSM_SPECIAL
prompt ======================================
prompt
@@refrash_bsm_special.prc
prompt
prompt Creating procedure REFRESH_BSM_EVENT_LOG
prompt ========================================
prompt
@@refresh_bsm_event_log.prc
prompt
prompt Creating procedure REMOVE_CLIENT_INFO
prompt =====================================
prompt
@@remove_client_info.prc
prompt
prompt Creating procedure SEND_GIFT_P
prompt ==============================
prompt
@@send_gift_p.prc
prompt
prompt Creating procedure SEND_GIFT_P_TEST
prompt ===================================
prompt
@@send_gift_p_test.prc
prompt
prompt Creating procedure SET_DLC_USER_PASSWORD
prompt ========================================
prompt
@@set_dlc_user_password.prc
prompt
prompt Creating procedure SOFTWARE_UPDATE_LOG
prompt ======================================
prompt
@@software_update_log.prc
prompt
prompt Creating procedure SYN_CLIENT_CSTATUS
prompt =====================================
prompt
@@syn_client_cstatus.prc
prompt
prompt Creating procedure SYN_CLIENT_STATUS
prompt ====================================
prompt
@@syn_client_status.prc
prompt
prompt Creating procedure TPA_AMD_TSN
prompt ==============================
prompt
@@tpa_amd_tsn.prc
prompt
prompt Creating procedure TPL2CUST
prompt ===========================
prompt
@@tpl2cust.prc
prompt
prompt Creating procedure TPM_OUT
prompt ==========================
prompt
@@tpm_out.prc
prompt
prompt Creating procedure TPN2TPT
prompt ==========================
prompt
@@tpn2tpt.prc
prompt
prompt Creating procedure TPT2CUST_OUT
prompt ===============================
prompt
@@tpt2cust_out.prc
prompt
prompt Creating procedure TRX_LEASED
prompt =============================
prompt
@@trx_leased.prc
prompt
prompt Creating procedure TRX_OUTSTANDING
prompt ==================================
prompt
@@trx_outstanding.prc
prompt
prompt Creating procedure UPDATE_ACL_IPTV_MFG
prompt ======================================
prompt
@@update_acl_iptv_mfg.prc
prompt
prompt Creating procedure UPD_ORDER_ID
prompt ===============================
prompt
@@upd_order_id.prc
prompt
prompt Creating package body B64
prompt =========================
prompt
@@b64.bdy
prompt
prompt Creating package body BI_REPORTONLY
prompt ===================================
prompt
@@bi_reportonly.bdy
prompt
prompt Creating package body BSM_APT_SERVICE
prompt =====================================
prompt
@@bsm_apt_service.bdy
prompt
prompt Creating package body BSM_CDI_SERVICE
prompt =====================================
prompt
@@bsm_cdi_service.bdy
prompt
prompt Creating package body BSM_CDI_SERVICE_DEV
prompt =========================================
prompt
@@bsm_cdi_service_dev.bdy
prompt
prompt Creating package body BSM_CHT_SERVICE
prompt =====================================
prompt
@@bsm_cht_service.bdy
prompt
prompt Creating package body BSM_CHT_SERVICE_DEV
prompt =========================================
prompt
@@bsm_cht_service_dev.bdy
prompt
prompt Creating package body BSM_CHT_SERVICE_DEV2
prompt ==========================================
prompt
@@bsm_cht_service_dev2.bdy
prompt
prompt Creating package body BSM_CLIENT_SERVICE
prompt ========================================
prompt
@@bsm_client_service.bdy
prompt
prompt Creating package body BSM_CLIENT_SERVICE_DEV
prompt ============================================
prompt
@@bsm_client_service_dev.bdy
prompt
prompt Creating package body BSM_CLIENT_SERVICE_DEV2
prompt =============================================
prompt
@@bsm_client_service_dev2.bdy
prompt
prompt Creating package body BSM_ENCRYPT
prompt =================================
prompt
@@bsm_encrypt.bdy
prompt
prompt Creating package body BSM_IOS_GATEWAY
prompt =====================================
prompt
@@bsm_ios_gateway.bdy
prompt
prompt Creating package body BSM_IOS_GATEWAY_DEV
prompt =========================================
prompt
@@bsm_ios_gateway_dev.bdy
prompt
prompt Creating package body BSM_ISSUE_POST
prompt ====================================
prompt
@@bsm_issue_post.bdy
prompt
prompt Creating package body BSM_LIPAY_GATEWAY
prompt =======================================
prompt
@@bsm_lipay_gateway.bdy
prompt
prompt Creating package body BSM_LIPAY_GATEWAY_NEW
prompt ===========================================
prompt
@@bsm_lipay_gateway_new.bdy
prompt
prompt Creating package body BSM_ORDER_SERVICE
prompt =======================================
prompt
@@bsm_order_service.bdy
prompt
prompt Creating package body BSM_ORDER_SERVICE_DEV
prompt ===========================================
prompt
@@bsm_order_service_dev.bdy
prompt
prompt Creating package body BSM_PAYMENT_GATEWAY
prompt =========================================
prompt
@@bsm_payment_gateway.bdy
prompt
prompt Creating package body BSM_PAYMENT_GATEWAY_CR
prompt ============================================
prompt
@@bsm_payment_gateway_cr.bdy
prompt
prompt Creating package body BSM_PAYMENT_GATEWAY_DEV
prompt =============================================
prompt
@@bsm_payment_gateway_dev.bdy
prompt
prompt Creating package body BSM_PAYMENT_GATEWAY_LIPAY
prompt ===============================================
prompt
@@bsm_payment_gateway_lipay.bdy
prompt
prompt Creating package body BSM_PURCHASE_POST
prompt =======================================
prompt
@@bsm_purchase_post.bdy
prompt
prompt Creating package body BSM_PURCHASE_POST_BK
prompt ==========================================
prompt
@@bsm_purchase_post_bk.bdy
prompt
prompt Creating package body BSM_PURCHASE_POST_DEV
prompt ===========================================
prompt
@@bsm_purchase_post_dev.bdy
prompt
prompt Creating package body BSM_PURCHASE_POST_OLD
prompt ===========================================
prompt
@@bsm_purchase_post_old.bdy
prompt
prompt Creating package body BSM_RECURRENT_POST
prompt ========================================
prompt
@@bsm_recurrent_post.bdy
prompt
prompt Creating package body BSM_RECURRENT_UTIL
prompt ========================================
prompt
@@bsm_recurrent_util.bdy
prompt
prompt Creating package body BSM_RECURRENT_UTILDEV
prompt ===========================================
prompt
@@bsm_recurrent_utildev.bdy
prompt
prompt Creating package body BSM_RECURRENT_UTIL_DEV
prompt ============================================
prompt
@@bsm_recurrent_util_dev.bdy
prompt
prompt Creating package body BSM_RECURRENT_UTIL_OLD
prompt ============================================
prompt
@@bsm_recurrent_util_old.bdy
prompt
prompt Creating package body BSM_RECURRENT_UTIL_PC
prompt ===========================================
prompt
@@bsm_recurrent_util_pc.bdy
prompt
prompt Creating package body BSM_SMS_SERVICE
prompt =====================================
prompt
@@bsm_sms_service.bdy
prompt
prompt Creating package body BSM_WEB_SERVICE
prompt =====================================
prompt
@@bsm_web_service.bdy
prompt
prompt Creating package body CMS_CNT_POST
prompt ==================================
prompt
@@cms_cnt_post.bdy
prompt
prompt Creating package body CMS_UTIL
prompt ==============================
prompt
@@cms_util.bdy
prompt
prompt Creating package body ELM_ORDER_SERVICE
prompt =======================================
prompt
@@elm_order_service.bdy
prompt
prompt Creating package body FILE_PKG
prompt ==============================
prompt
@@file_pkg.bdy
prompt
prompt Creating package body FREE_VIDEO_REPORT
prompt =======================================
prompt
@@free_video_report.bdy
prompt
prompt Creating package body JSON_EXT
prompt ==============================
prompt
@@json_ext.bdy
prompt
prompt Creating package body PARTNER_SERVICE
prompt =====================================
prompt
@@partner_service.bdy
prompt
prompt Creating package body PARTNER_SERVICE_210628
prompt ============================================
prompt
@@partner_service_210628.bdy
prompt
prompt Creating package body PARTNER_SERVICE_BK
prompt ========================================
prompt
@@partner_service_bk.bdy
prompt
prompt Creating package body PARTNER_SERVICE_BK2
prompt =========================================
prompt
@@partner_service_bk2.bdy
prompt
prompt Creating package body PARTNER_SERVICE_DEV
prompt =========================================
prompt
@@partner_service_dev.bdy
prompt
prompt Creating package body PARTNER_SERVICE_OLD
prompt =========================================
prompt
@@partner_service_old.bdy
prompt
prompt Creating package body PKG_TGC_ORDER_TRANS
prompt =========================================
prompt
@@pkg_tgc_order_trans.bdy
prompt
prompt Creating package body SYSAPP_UTIL
prompt =================================
prompt
@@sysapp_util.bdy
prompt
prompt Creating package body TAX_POST
prompt ==============================
prompt
@@tax_post.bdy
prompt
prompt Creating package body TAX_POST_DEV
prompt ==================================
prompt
@@tax_post_dev.bdy
prompt
prompt Creating package body TGC_BILL_POST
prompt ===================================
prompt
@@tgc_bill_post.bdy
prompt
prompt Creating package body TGC_CREDIT_POST
prompt =====================================
prompt
@@tgc_credit_post.bdy
prompt
prompt Creating package body TGC_ORDER_POST
prompt ====================================
prompt
@@tgc_order_post.bdy
prompt
prompt Creating package body TGC_UTIL
prompt ==============================
prompt
@@tgc_util.bdy
prompt
prompt Creating package body TI_SYS_LOGIN
prompt ==================================
prompt
@@ti_sys_login.bdy
prompt
prompt Creating package body TSN_REG_POST
prompt ==================================
prompt
@@tsn_reg_post.bdy
prompt
prompt Creating package body TSTAR_ORDER_SERVICE
prompt =========================================
prompt
@@tstar_order_service.bdy
prompt
prompt Creating package body TSTAR_ORDER_SERVICE_2
prompt ===========================================
prompt
@@tstar_order_service_2.bdy
prompt
prompt Creating package body WEBUTIL_DB
prompt ================================
prompt
@@webutil_db.bdy

spool off
