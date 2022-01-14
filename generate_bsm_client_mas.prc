CREATE OR REPLACE PROCEDURE IPTV."GENERATE_BSM_CLIENT_MAS" is
 v_serial_no number(16);
 v_serial_id varchar2(32);
 v_status_flg varchar2(32);
 v_defaule_group varchar2(32);
 cursor c1 is select mac_address from mfg_iptv_mas a where not exists (select 'x' from bsm_client_mas b where b.mac_address= a.mac_address);
begin
     for c1rec in c1 loop
      Select Seq_Bsm_Client_Mas.Nextval
        Into v_serial_no
        From Dual;

      --
      -- Get New Serail_ID
      --
      v_serial_id := lpad(to_char(v_Serial_No),16,'0');
      --
      -- set iptv status
      --
      v_status_flg    := 'U';
      v_defaule_group := 'UNREGISTER';
      Insert Into Bsm_Client_Mas
        (Region,
         Serial_No,
         Serial_Id,
         Status_Flg,
         Mac_Address,
         Default_Group,
         Create_User,
         Create_Date)
      Values
        (0,
         v_serial_no,
         v_serial_id,
         v_status_flg,
        c1rec.Mac_Address,
         v_defaule_group,
         0,
         Sysdate);
         commit;
      end loop;
end;
/

