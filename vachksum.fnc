CREATE OR REPLACE FUNCTION IPTV."VACHKSUM" (VA  Varchar, total  Number)  Return Number
Is
  chksum Number(16);
Begin

   --' VA is a 13 digits virtual account without checksum character
  --  ' Total is the amount due
  --  ' the VAChksum is 14 digits with the last digit as a checksum character
  --  ' All the characters should be digits

    chksum := (10 - ((DigitSum('0'||VA, 'Odd') + DigitSum('0'||VA, 'Even') * 3 + TotalChksum(total)) Mod 10)) Mod 10;
   -- the odd digits and even digits are counted from RIGHT to LEFT, with 14 digits in the VAChksum
   -- We pad a "0" in front of the VA to cheat the DigitSum "odd", "even" order

    Return  chksum;
End;
/

