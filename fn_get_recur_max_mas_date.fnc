CREATE OR REPLACE FUNCTION IPTV.FN_GET_RECUR_MAX_MAS_DATE (p_mas_no VARCHAR2)
    RETURN DATE
IS
    v_max_mas_date   DATE;
BEGIN
    SELECT MAX (T.MAS_DATE) INTO v_max_mas_date
      FROM (SELECT A.MAS_DATE
              FROM IPTV.BSM_PURCHASE_MAS A
             WHERE A.MAS_NO = p_mas_no
            UNION
            SELECT B.MAS_DATE
              FROM IPTV.BSM_PURCHASE_MAS B
             WHERE B.SRC_NO LIKE 'RE'||p_mas_no||'%') T;
    RETURN v_max_mas_date;         
END;
/

