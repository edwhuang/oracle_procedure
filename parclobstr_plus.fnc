create or replace function iptv.parclobstr_plus (strings clob)
RETURN clob_tt pipelined 
AS 
--v_tab clob_tt := clob_tt(); 
rownumber number;
BEGIN     
  select length(strings)-length(replace(strings,'&','')) into rownumber from dual;
  rownumber:=(rownumber+1-2)/14;
  For num in 1..rownumber --設定迴圈條件
  loop
     for cur IN (
     select partitionclobstring(strings,'&',1,num) MERCHANTNUMBER,
            partitionclobstring(strings,'&',2,num) ORDERNUMBER,
            partitionclobstring(strings,'&',3,num) STATUS,
            partitionclobstring(strings,'&',4,num) APPROVEAMOUNT,
            partitionclobstring(strings,'&',5,num) PERIOD,
            partitionclobstring(strings,'&',6,num) CURRENCY,
            partitionclobstring(strings,'&',7,num) CARDNUMBER,
            partitionclobstring(strings,'&',8,num) ORDERDATE,
            partitionclobstring(strings,'&',9,num) APPROVEDATE,
            partitionclobstring(strings,'&',10,num) APPROVALCODE,
            partitionclobstring(strings,'&',11,num) DEPOSITAMOUNT,
            partitionclobstring(strings,'&',12,num) DEPOSITDATE,
            partitionclobstring(strings,'&',13,num) CREDITAMOUNT,
            partitionclobstring(strings,'&',14,num) CREDITDATE
     from dual
                )     
     loop
        PIPE ROW(clob_t(
                       substr(cur.MERCHANTNUMBER,instr(cur.MERCHANTNUMBER,'=',1,1)+1),
                       substr(cur.ORDERNUMBER,   instr(cur.ORDERNUMBER,'=',1,1)+1),
                       substr(cur.STATUS,        instr(cur.STATUS,'=',1,1)+1),
                       substr(cur.APPROVEAMOUNT, instr(cur.APPROVEAMOUNT,'=',1,1)+1),
                       substr(cur.PERIOD,        instr(cur.PERIOD,'=',1,1)+1),
                       substr(cur.CURRENCY,      instr(cur.CURRENCY,'=',1,1)+1),
                       substr(cur.CARDNUMBER,    instr(cur.CARDNUMBER,'=',1,1)+1),
                       substr(cur.ORDERDATE,     instr(cur.ORDERDATE,'=',1,1)+1),
                       substr(cur.APPROVEDATE,   instr(cur.APPROVEDATE,'=',1,1)+1),
                       substr(cur.APPROVALCODE,  instr(cur.APPROVALCODE,'=',1,1)+1),
                       substr(cur.DEPOSITAMOUNT, instr(cur.DEPOSITAMOUNT,'=',1,1)+1),
                       substr(cur.DEPOSITDATE,   instr(cur.DEPOSITDATE,'=',1,1)+1),
                       substr(cur.CREDITAMOUNT,  instr(cur.CREDITAMOUNT,'=',1,1)+1),
                       substr(cur.CREDITDATE,    instr(cur.CREDITDATE,'=',1,1)+1)
                       )
               );  
     end loop;     
  end loop; 
  RETURN;   
END;
/

