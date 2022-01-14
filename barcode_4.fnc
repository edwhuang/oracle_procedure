CREATE OR REPLACE FUNCTION IPTV."BARCODE_4" (Seg1 varchar2,Seg2 varchar2,Seg3 varchar2) RETURN varchar2 IS
  v_Seg1 varchar2(32);
  v_Seg2 varchar2(32);
  v_Seg3 varchar2(32);
  V_Seg31 varchar2(32);
  V_Seg32 varchar2(32);
  BarTextOut varchar2(32);
  C1 Varchar2(32);
  C2 Varchar2(32);
BEGIN
  BarTextOut := '';
  V_Seg1 := RTrim(LTrim(Seg1));
  V_Seg2 := RTrim(LTrim(Seg2));
  V_Seg3 := RTrim(LTrim(Seg3));
  V_Seg31 := SubStr(Seg3, 1, 4);
  V_Seg32 := SubStr(Seg3, 7, 9);

  C1 := CheckCode('CODE1',(DigitSum(V_Seg1, 'Odd') + DigitSum(V_Seg2, 'Odd') + DigitSum(v_Seg3, 'Odd')) Mod 11);
   C2 := CheckCode('CODE2',(DigitSum(V_Seg1, 'Even') + DigitSum(v_Seg2, 'Even') + DigitSum(V_Seg3, 'Even')) Mod 11);
   BarTextOut := V_Seg31 || C1 || C2 || V_Seg32;
   Return BarTextOut;
exception
  when others then return null;

END;
/

