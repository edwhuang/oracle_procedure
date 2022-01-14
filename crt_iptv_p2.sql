-------------------------------------------------------
-- Export file for user IPTV                         --
-- Created by edward.huang on 2022/1/14, 下午 02:31:00 --
-------------------------------------------------------
set define off
set escape on

spool crt_twdevdb_iptv2.log

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
prompt Creating package body PARTNER_SERVICE
prompt =====================================
prompt
@@partner_service.bdy
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
spool off
