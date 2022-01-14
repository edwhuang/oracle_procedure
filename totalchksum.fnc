CREATE OR REPLACE FUNCTION IPTV."TOTALCHKSUM" (total  Number) Return Number Is

  chksum Number(16);
  quotient Number(16);
  remainder Number(16);
  j Number(16);
  factor Number(16);
Begin
-- get the sum of the Total value according to the formula
    chksum := 0;
    quotient := total;
    remainder := 0;

   -- Dim factor(6) As Long
   -- factor(0) = 5
   -- factor(1) = 4
   -- factor(2) = 3
   -- factor(3) = 2
   -- factor(4) = 3
    --factor(5) = 4
    --factor(6) = 5


   J := 0;
   While quotient > 0 Loop
        remainder := quotient Mod 10;
        quotient := trunc(quotient / 10); -- discard non-Long remainder
        Select decode(j,0,5,1,4,2,3,3,2,4,3,5,4,6,5) Into factor From dual;
        chksum := chksum + factor * remainder;
        J := J + 1;
   end Loop;

  Return chksum;

End;
/

