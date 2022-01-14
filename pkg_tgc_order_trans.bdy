CREATE OR REPLACE PACKAGE BODY IPTV."PKG_TGC_ORDER_TRANS" is

    Procedure Convert(p_batch_no Number) Is
     Cursor c1 Is Select Rowid rid,str_data From tgc_order_trans
      Where batch_no = p_batch_no;
    Begin
      For c1rec In c1 Loop
         Declare
           v_order_date Date;
           v_cust_name Varchar2(1024);
           v_tel Varchar2(1024);
           v_mobile Varchar2(1024);
           v_identifiy_id Varchar2(256);
           v_birthday Date;
           v_tivo_sale_name Varchar2(256);
           v_email Varchar2(1024);
           v_address Varchar2(1024);
           v_book_date Date;
           v_book_time Varchar2(1024);
           v_sale_dept Varchar2(256);
           v_sale_name Varchar2(256);
           v_tivo_sale Varchar2(256);
           v_sale_remark Varchar2(256);
           v_sale_level Varchar2(256);
           v_ref_cust_id Varchar2(256);
           v_mso_name Varchar2(256);
           v_ref1   Varchar2(256);
           v_ref2   Varchar2(256);
           v_ref3   Varchar2(256);
           v_ref4   Varchar2(256);
           v_ref5   Varchar2(256);
           v_str Varchar2(2048);
           v_str2 Varchar2(2048);
         Begin
           v_str2 := c1rec.str_data;
/*
           -- oder_date

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_order_date := to_date(v_str,'YYYY/MM/DD');
           Exception
             When Others Then v_order_date := Null;
            End;


           -- cust_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_cust_name := ltrim(rtrim(v_str));

           -- tel;

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_tel := ltrim(rtrim(v_str));

           -- mobile
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_mobile := ltrim(rtrim(v_str));

           -- identifity_id
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_identifiy_id := ltrim(rtrim(v_str));

           -- birthday_date
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_birthday := to_date(v_str,'YYYY/MM/DD');
             v_birthday := add_months(v_birthday,1911*12);
           Exception
             When Others Then v_order_date := Null;
            End;

            -- email
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_email := ltrim(rtrim(v_str));

           -- address
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_address := ltrim(rtrim(v_str));




           -- sale_dept
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_dept := ltrim(rtrim(v_str));

          -- sale_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_name := ltrim(rtrim(v_str));

            -- v_tivo_sale
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_tivo_sale_name := ltrim(rtrim(v_str));

            -- v_sale_remark
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_remark := ltrim(rtrim(v_str));

            -- v_sale_level
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
      --      v_level := ltrim(rtrim(v_str));

            -- v_rec_cust_ID
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_ref_cust_id := ltrim(rtrim(v_str));

           -- v_mso_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_mso_name := ltrim(rtrim(v_str));

            --速率別

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref1 := ltrim(rtrim(v_str));

            --合約開始日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref2 := ltrim(rtrim(v_str));

            --合約終止日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref3 := ltrim(rtrim(v_str));

            --BB裝機日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref4 := ltrim(rtrim(v_str));

            -- 時段

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref5 := ltrim(rtrim(v_str));
  */
  -- format2
             -- oder_date

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_order_date := to_date(v_str,'YYYY/MM/DD');
           Exception
             When Others Then v_order_date := Null;
            End;

            -- v_rec_cust_ID
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_ref_cust_id := trimstr(ltrim(rtrim(v_str)));

                       -- cust_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_cust_name := trimstr(ltrim(rtrim(v_str)));

                      -- v_mso_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_mso_name := trimstr(ltrim(rtrim(v_str)));

                       -- tel;

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_tel := trimstr(ltrim(rtrim(v_str)));

                      -- mobile
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_mobile := trimstr(ltrim(rtrim(v_str)));

                      -- identifity_id
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_identifiy_id := trimstr(ltrim(rtrim(v_str)));

           -- birthday_date
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_birthday := to_date(v_str,'YYYY/MM/DD');
             v_birthday := add_months(v_birthday,1911*12);
           Exception
             When Others Then v_order_date := Null;
            End;

           -- address
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_address := trimstr(ltrim(rtrim(v_str)));

                       --速率別

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref1 := trimstr(ltrim(rtrim(v_str)));

            --合約開始日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref2 := trimstr(ltrim(rtrim(v_str)));

            --合約終止日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref3 := trimstr(ltrim(rtrim(v_str)));

                       --BB裝機日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref4 := trimstr(ltrim(rtrim(v_str)));

            -- 時段

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref5 := trimstr(ltrim(rtrim(v_str)));

                      -- tivo_date
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_book_date := to_date(v_str,'YYYY/MM/DD');
           Exception
             When Others Then v_order_date := Null;
            End;

           -- tivo_time
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_book_time := trimstr(ltrim(rtrim(v_str)));

                       -- sale_dept
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_dept := trimstr(ltrim(rtrim(v_str)));

          -- sale_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_tivo_sale_name := trimstr(ltrim(rtrim(v_str)));

            -- v_tivo_sale
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_name := trimstr(ltrim(rtrim(v_str)));

            -- v_sale_remark
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_remark := trimstr(ltrim(rtrim(v_str)));




            Update tgc_order_trans a
                 Set a.order_date=v_order_date,
                        a.cust_name=v_cust_name,
                        a.tel = v_tel,
                        a.mobile = v_mobile,
                        a.identified_id= v_identifiy_id,
                        a.birthday = v_birthday,
                        a.email = v_email,
                        a.addresss = v_address,
                        a.book_date = v_book_date,
                        a.book_time = v_book_time,
                        a.dept_name = v_sale_dept,
                        a.sale_name = v_sale_name,
                        a.sale_remark= v_sale_remark,
                        a.ref_cust_id = v_ref_cust_id,
                        a.bb_id = v_mso_name,
                        a.ref1 = v_ref1,
                        a.ref2 = v_ref2,
                        a.ref3 = v_ref3,
                        a.ref4 = v_ref4,
                        a.ref5 = v_ref5,
                        a.ref6 = v_tivo_sale_name,
                        create_date = Sysdate
               Where Rowid=c1rec.rid;

             --  Delete tgc_order_trans Where cust_name Is Null And order_date Is Null And addresss=Null And batch_no=p_batch_no;
               Commit;
         End;
      End Loop;
    End;

        Procedure Convert2(p_batch_no Number) Is
     Cursor c1 Is Select Rowid rid,str_data From tgc_order_trans
      Where batch_no = p_batch_no;
    Begin
      For c1rec In c1 Loop
         Declare
           v_order_date Date;
           v_cust_name Varchar2(1024);
           v_tel Varchar2(1024);
           v_mobile Varchar2(1024);
           v_identifiy_id Varchar2(256);
           v_birthday Date;
           v_tivo_sale_name Varchar2(256);
           v_email Varchar2(1024);
           v_address Varchar2(1024);
           v_book_date Date;
           v_book_time Varchar2(1024);
           v_sale_dept Varchar2(256);
           v_sale_name Varchar2(256);
           v_tivo_sale Varchar2(256);
           v_sale_remark Varchar2(256);
           v_sale_level Varchar2(256);
           v_ref_cust_id Varchar2(256);
           v_mso_name Varchar2(256);
           v_ref1   Varchar2(256);
           v_ref2   Varchar2(256);
           v_ref3   Varchar2(256);
           v_ref4   Varchar2(256);
           v_ref5   Varchar2(256);
           v_ref6   varchar2(256);
           v_ref7   varchar2(256);
           v_str Varchar2(2048);
           v_str2 Varchar2(2048);
             v_referee Varchar2(256);
             v_already_cable   Varchar2(256);
             v_already_internet Varchar2(256);
             v_onb_bor_id varchar2(256);
             
         Begin
           v_str2 := c1rec.str_data;

  -- format2
           -- 編號
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           -- 客戶等級
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

             -- 登記日
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));


           -- 取得日
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_order_date := to_date(v_str,'YYYY/MM/DD');
           Exception
             When Others Then v_order_date := Null;
            End;

            -- 門室推艦
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_referee :=  trimstr(ltrim(rtrim(v_str)));

           -- cust_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_cust_name := trimstr(ltrim(rtrim(v_str)));

          -- tel;

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_tel := trimstr(ltrim(rtrim(v_str)));

          -- mobile
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_mobile := trimstr(ltrim(rtrim(v_str)));


           --address
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_address := trimstr(ltrim(rtrim(v_str)));

                      --mail
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_email := trimstr(ltrim(rtrim(v_str)));


           -- 東森產品型號
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref6 := trimstr(ltrim(rtrim(v_str)));

           --東森產品名稱
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref7 := trimstr(ltrim(rtrim(v_str)));
           
 --Esonic 機型
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
          v_onb_bor_id := trimstr(ltrim(rtrim(v_str)));
           
           -- 年零
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           --收入
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           --看電視的人口數
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

             --看電視的人口數
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           --數位機上盒
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_already_cable := trimstr(ltrim(rtrim(v_str)));
           --寬頻網路
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_already_internet := trimstr(ltrim(rtrim(v_str)));
           --IP分享器
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --ISP提供業者
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --參加類別
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --結案客服
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --狀態
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --聯絡安裝負責人
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --第一次外撥負責人
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --第一次聯絡日
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           --三日內聯絡比例
                       v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           --預計裝機日
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_book_date := to_date(v_str,'YYYY/MM/DD');
           Exception
             When Others Then v_order_date := Null;
            End;

           --預計裝機時段
             v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_book_time := trimstr(ltrim(rtrim(v_str)));

           --派工日期


/*

            -- v_rec_cust_ID
            v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_ref_cust_id := trimstr(ltrim(rtrim(v_str)));


                      -- v_mso_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_mso_name := trimstr(ltrim(rtrim(v_str)));
            */

/*


                      -- identifity_id
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_identifiy_id := trimstr(ltrim(rtrim(v_str)));

           -- birthday_date
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_birthday := to_date(v_str,'YYYY/MM/DD');
             v_birthday := add_months(v_birthday,1911*12);
           Exception
             When Others Then v_order_date := Null;
            End;

           -- address
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_address := trimstr(ltrim(rtrim(v_str)));

                       --速率別

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref1 := trimstr(ltrim(rtrim(v_str)));

            --合約開始日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref2 := trimstr(ltrim(rtrim(v_str)));

            --合約終止日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref3 := trimstr(ltrim(rtrim(v_str))); */

/*                       --BB裝機日

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref4 := trimstr(ltrim(rtrim(v_str)));

            -- 時段

           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
           v_ref5 := trimstr(ltrim(rtrim(v_str)));

                      -- tivo_date
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_book_date := to_date(v_str,'YYYY/MM/DD');
           Exception
             When Others Then v_order_date := Null;
            End;

           -- tivo_time
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_book_time := trimstr(ltrim(rtrim(v_str)));

                       -- sale_dept
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_dept := trimstr(ltrim(rtrim(v_str)));

          -- sale_name
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_name := trimstr(ltrim(rtrim(v_str)));

            -- v_tivo_sale
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_tivo_sale_name := trimstr(ltrim(rtrim(v_str)));

            -- v_sale_remark
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));
            v_sale_remark := trimstr(ltrim(rtrim(v_str)));  */




            Update tgc_order_trans a
                 Set a.order_date=v_order_date,
                        a.cust_name=v_cust_name,
                        a.tel = v_tel,
                        a.mobile = v_mobile,
                        a.identified_id= v_identifiy_id,
                        a.birthday = v_birthday,
                        a.email = v_email,
                        a.addresss = v_address,
                        a.book_date = v_book_date,
                        a.book_time = v_book_time,
                        a.dept_name = v_sale_dept,
                        a.sale_name = v_sale_name,
                        a.sale_remark= v_sale_remark,
                        a.ref_cust_id = v_ref_cust_id,
                        a.bb_id = v_mso_name,
                        a.ref1 = v_ref1,
                        a.ref2 = v_ref2,
                        a.ref3 = v_ref3,
                        a.ref4 = v_ref4,
                        a.ref5 = v_referee,
                        a.ref6 = v_ref6,
                        a.ref7 = v_ref7,
                        a.already_cable = v_already_cable,
                        a.already_internet = v_already_internet,

                        create_date=Sysdate,
                        a.onb_bor_id=v_onb_bor_id
                        
               Where Rowid=c1rec.rid;
           --    Delete tgc_order_trans Where cust_name Is Null And order_date Is Null And addresss=Null And batch_no=p_batch_no;
               Commit;
         End;
      End Loop;
    End;

    Procedure ConvertRtn(p_batch_no Number) Is
     Cursor c1 Is Select Rowid rid,str_data From tgc_order_trans
      Where batch_no = p_batch_no;
    Begin
      For c1rec In c1 Loop
         Declare
           v_order_no varchar2(32);
           v_str  varchar2(1024);
           v_str2 varchar2(1024);
         Begin
           v_str2 := c1rec.str_data;
           
           v_str := substr(v_str2,1,instr(v_str2,',')-1);
           v_str2 := substr(v_str2,instr(v_str2,',')+1,length(v_str2));

           Begin
             v_order_no := v_str;
           Exception
             When Others Then  v_order_no := Null;
           End;

           Update tgc_order_trans a
                 Set a.cust_name=v_order_no
            Where Rowid=c1rec.rid;
            Commit;
         End;
      End Loop;
    End;


    Procedure transfer(p_order_type Varchar2,p_program_id Varchar2,p_product_id Varchar2,p_cat1 Varchar2,p_user_no Number,p_batch_no Number Default 0) Is
     Cursor c1 Is Select Rowid rid,order_date,cust_name,identified_id,birthday,tel,a.addresss,mobile,email,book_date,book_time,ref_cust_id,a.bb_id,ref1,ref2,ref3,ref4,ref5,ref6 tivo_sale_name,sale_name,
                                  already_cable,already_internet,sale_remark,rev_tivo_msg,onb_bor_id,onb_bor_cate,ref_member_id,ref6,ref7
                          From tgc_order_trans a
                         Where status_flg='A' And
                         ((p_batch_no = 0 ) Or (batch_no =p_batch_no));
    Begin
      For c1rec In c1 Loop
         Declare
           v_cust_no Number(16);
           v_cust_id Varchar2(256);
           v_order_no Number(16);
           v_order_id Varchar2(256);
           v_tivo_device_no Varchar2(256);
           v_deposit Number(16);
           v_tivo_price Number(16);
           v_user_name Varchar2(256);
           msg Varchar2(256);
           App_Exception Exception;
           v_char Char(1);
           v_sell_flg varchar2(32);
           v_sell_acc_code varchar2(32);
         Begin
            begin
               select a.sell_acc_flg,a.sell_acc_code 
                  into v_sell_flg,v_sell_acc_code
               from tgc_program a
               where program_id = p_program_id;
            exception
               when no_data_found then  msg := '錯誤專案代號';
               Raise app_exception;
            end;
               
            Begin
               Select user_name Into v_user_name From sys_user Where user_no = p_user_no;
            Exception
               When no_data_found Then
                   v_user_name := Null;
            End;

             -- null order date
             If c1rec.order_date Is Null Then
               msg := '單據日錯誤';
               Raise app_exception;
            End If;


            Begin
              Select 'x' Into v_char From tgc_customer Where unifiedid_tw=c1rec.identified_id And rownum <=1;
              msg := '身份證號重覆';
              Raise app_exception;
            Exception
              When no_data_found Then Null;
            End;

              If c1rec.addresss Is Not Null Then
              Begin
                 Select 'x' Into v_char From tgc_customer Where address=c1rec.addresss And rownum <=1;
                 msg := '住址重覆';
                       Raise app_exception;
               Exception
                 When no_data_found Then Null;
               End;
            End If;

            Begin
              Select 'x' Into v_char From tgc_customer Where mobilephone1=c1rec.mobile And rownum <=1;
              msg := '手機號碼重覆';
                    Raise app_exception;
            Exception
              When no_data_found Then Null;
            End;

            If c1rec.cust_name Is  Null Then
               msg := '沒有性名';
               Raise app_exception;
            Else
              Begin
              Select 'x' Into v_char From tgc_customer Where cust_name=c1rec.cust_name And rownum <=1;
              msg := '姓名重覆請撿查';
              Raise app_exception;
            Exception
              When no_data_found Then Null;
            End;

            End If;






           Select seq_sys_no.Nextval Into v_cust_no From dual;
           v_cust_id := sysapp_util.get_mas_no(1,1,sysdate,'TGCCUSTOMER',v_cust_no);

           Insert Into Tgc_Customer
             (User_No,
              Cust_Id,
              Cust_Name,
              Unifiedid_Tw,
              Birthday,
              Dayphone,
              Mobilephone1,
              Address,
              Email,
              Ref1,
              Ref2,
              Ref3,
              Ref4,
              Ref5,
              Ref6,
              Ref7,
              Keyin_Date,
              Keyin_Emp)
           Values
             (v_Cust_No,
              v_Cust_Id,
              C1rec.Cust_Name,
              C1rec.Identified_Id,
              C1rec.Birthday,
              C1rec.Tel,
              C1rec.Mobile,
              C1rec.Addresss,
              C1rec.Email,
              C1rec.Ref_Cust_Id,
              C1rec.Ref1,
              C1rec.Ref2,
              C1rec.Ref3,
              C1rec.Bb_Id,
              c1rec.sale_name,
              c1rec.tivo_sale_name,

              Sysdate,
              v_User_Name);
            -- create order
            Select seq_sys_no.Nextval Into v_order_no From dual;


            v_order_id := sysapp_util.get_mas_no(1,1,c1rec.order_date,'TGCORDER',	v_order_no);
            
            Declare
              cursor c1 is select list_price,net_price,sell_acc_code,sell_flg ,chg_code
	               from service_product_item_chg
	              where product_id=p_product_id
	                and free_period='0'
	                and default_flg='Y';
              cursor c2 is select a.item_code from service_product_item a
                            where a.product_id=p_product_id
                            and default_flg='Y';
               v_net_price Number(16);
               v_list_price Number(16);
                 v_voucher_amount Number(16);
               v_desposit Varchar2(32);
               v_stock_cat varchar2(32);
               v_need_deliver_tivo varchar2(32);
               v_need_deliver_router varchar2(32);
               v_need_deliver_usb varchar2(32);
               v_need_deliver_remote varchar2(32);
               
               v_router_qty number(16);
               v_usb_qty number(16);
               v_remote_qty number(16);
              
               v_router_price number(16);
               v_usb_price number(16);
               v_remote_price number(16);
               
               v_router_model varchar2(128);
               v_usb_model varchar2(128);
               v_remote_model varchar2(128);
               v_first_billing_pay_type varchar2(32);
               v_first_billing_sts varchar2(32);
               
               
         
            Begin
               	v_net_price := 0;
                v_list_price  := 0;
                for c1rec in c1 loop
                --  if c1rec.sell_acc_code is not null then 
                --     v_sell_flg := 'Y';
                --     v_sell_acc_code  := c1rec.sell_acc_code;
                --  end if;
                  
                  if c1rec.chg_code = 'DESPOSIT' then 
                       v_desposit  := c1rec.sell_acc_code;
                  else 
                     v_net_price := v_net_price + c1rec.net_price;
                     v_list_price := v_list_price + c1rec.list_price;			
                  end if;
                 end loop;
                 v_need_deliver_tivo := 'N';
                 v_tivo_device_no := null;
                 
                 v_router_model := null;
                 v_router_qty := 0;
                 v_need_deliver_router:= 'N';
                 v_usb_model := null;
                 v_usb_qty := 0;
                 v_need_deliver_usb:= 'N'; 
                 v_remote_model := null;
                 v_remote_qty := 0;
                 v_need_deliver_remote:= 'N'; 
                 
                 v_router_price := null;
                  v_usb_price := null;
                  v_remote_price := null;

                 for c2rec in c2 loop
                     begin
                       select a.stk_category_id into v_stock_cat
                        from inv_stk_mas a where a.stock_id=c2rec.item_code;
                     exception 
                        when no_data_found then v_stock_cat := null;
                     end;
                     if v_stock_cat = 'DVR' then
                         v_tivo_device_no := c2rec.item_code;
                         v_need_deliver_tivo := 'Y';
                     elsif v_stock_cat='AP' then
                           v_router_model := c2rec.item_code;
                           v_router_qty := 1;
                           v_need_deliver_router:= 'Y'; 
                           v_router_price := 0;                    
                     elsif v_stock_cat='USB' then
                           v_usb_model := c2rec.item_code;
                           v_usb_qty := 1;
                           v_need_deliver_usb:= 'Y'; 
                           v_usb_price := 0;
                     elsif v_stock_cat is not null then
                           v_remote_model := c2rec.item_code;
                           v_remote_qty := 1;
                           v_need_deliver_remote:= 'Y'; 
                           v_remote_price := 0;
                     end if;
                     
                        
                 end loop;
                 
                 		
               v_tivo_price := v_net_price;
               v_list_price := v_list_price;
               v_voucher_amount := nvl(v_tivo_price,0);
               if v_sell_flg ='Y' then
                 v_first_billing_pay_type := '2';
                 v_first_billing_sts :='2';
               end if;
               
             
                 
                      Insert Into tgc_order(order_create_date,order_no,order_id,cust_id,cust_user_no,order_type,program_id,product_id,
                      install_address,billing_address,need_install,partner_book_date,partner_book_time,process_sts,csr_status,
                      need_deliver_tivo,tivo_device_no,deposit,tivo_price,first_total_amount,
                      need_deliver_router,ap_model,router_qty,router_price,need_deliver_usb,usb_model,usb_qty,usb_price,need_deliver_remote,remote_model,remote_qty,remote_price,need_deliver_others,
                      deliver_to_cust_installer,tgc_book_date,book_time2,cat1,create_type,referee,
                      already_apnet,ip_router,remark,voucher_type,ref16,org_order_id,ref_member_id,org_order_cate,ref7,ref13,ref14,ref_order_id,sell_flg,sell_acc_code,first_billing_pay_type,first_billing_sts
                      
                      )
                      Values(c1rec.order_date,v_order_no,v_order_id,v_cust_id,v_cust_no,p_order_type,p_program_id,p_product_id,
                      c1rec.addresss,c1rec.addresss,'Y',c1rec.book_date,c1rec.book_time,'A',Null,
                      'Y',v_tivo_device_no,v_deposit,v_tivo_price, v_voucher_amount+nvl(v_desposit,0),
                      v_need_deliver_router,v_router_model,v_router_qty,v_router_price,v_need_deliver_usb,v_usb_model,v_usb_qty,v_usb_price,v_need_deliver_remote,v_remote_model,v_remote_qty,v_router_price,'N',
                      '1',c1rec.book_date,c1rec.book_time,p_cat1,'轉檔',c1rec.ref5,
                      c1rec.already_cable,c1rec.already_internet,c1rec.sale_remark,'2',c1rec.rev_tivo_msg,c1rec.onb_bor_id,c1rec.ref_member_id ,c1rec.onb_bor_cate,C1rec.Ref5,c1rec.ref6,c1rec.ref7,'2',v_sell_flg,v_sell_acc_code,v_first_billing_pay_type,v_first_billing_sts);
                      
                      msg := tgc_order_post.create_order_detail(p_user_no,v_order_no); 

		         End;

         /*  	select deposit,product_price,def_tivo_model
	             Into v_deposit,v_tivo_price,v_tivo_device_no
	           from tgc_product where product_id = p_product_id;*/


            sysapp_util.set_event_log('TGCORDER',v_order_no,p_user_no,'CREATE','建立資料');

            Begin
         --       msg := tgc_order_post.Order_Post(p_user_no,v_order_no);
                Update tgc_order_trans Set status_flg ='N',order_no = v_order_no,trans_remark = '進單:單號'||v_order_id
               Where Rowid=c1rec.rid;
               
              Commit;
              --
              -- Oeya Return Table
              --
              If c1rec.ref_member_id Is Not Null Then 
                 Declare
                      v_back_code Varchar2(32) Default 'A';
                      v_onb_bor_id Varchar2(32) Default '0';
                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
  
                 Begin
                   If c1rec.onb_bor_cate ='58' Then
                               v_back_code:='119_4';
                   Elsif c1rec.onb_bor_cate='59' Then
                               v_back_code:='119_3';
                   Elsif c1rec.onb_bor_cate='63' Then
                               v_back_code:='119_5';
                   End If;
                   If v_back_code Is Not Null Then
                                     v_onb_bor_id := c1rec.onb_bor_id;
                                     v_oeya_member_id := nvl(substr(c1rec.ref_member_id,1,instr(c1rec.ref_member_id,'|')-1),c1rec.ref_member_id);
                                     v_cust_name := C1rec.Cust_Name;
                                     Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                     Values(Sysdate,v_oeya_member_id,Null,0,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo購買',v_back_code,Null,v_order_no,0);
                                    Commit;
                    End If;
                    
                 End;
              End If;   

            Exception
               When Others Then
                   msg := Sqlerrm;
                   Raise app_exception;
             End;

            declare
              v_msg varchar2(1024);
            Begin
               Update tgc_order a
                   Set a.Assigned_Csr_Empid = p_user_no
                 Where order_no = v_order_no;
           --     msg := tgc_order_post.Order_Assigned_Csr(p_user_no,v_order_no);

           --       Update tgc_order_trans Set status_flg ='N',order_no = v_order_no,trans_remark = trans_remark||'指定CSR'
           --     Where Rowid=c1rec.rid;
             Commit;
             
             if v_sell_flg <> 'Y' then
               v_msg := tgc_order_post.create_order_detail(p_user_no,v_order_no);
             end if;
             


              

            Exception
               When Others Then
                    msg := Sqlerrm;
                   Raise app_exception;
             End;
        /*
             Begin
                  msg := tgc_order_post.Order_Generate(p_user_no,v_order_no);

                   Update tgc_order_trans Set status_flg ='N',order_no = v_order_no,trans_remark = trans_remark||'指定CSR'
                  Where Rowid=c1rec.rid;
                  Commit;
             Exception
               When Others Then
                    msg := Sqlerrm;
                   Raise app_exception;
             End;
          */
         Exception
            When  App_Exception Then Rollback;
            Update tgc_order_trans Set trans_remark = msg ||' '|| trans_remark,status_flg='C'
             Where Rowid=c1rec.rid;
             Commit;
                If c1rec.ref_member_id Is Not Null Then 
                
                 Declare
                      v_back_code Varchar2(32) Default 'A';
                      v_onb_bor_id Varchar2(32) Default '0';
                      v_cust_name Varchar2(32) Default 'TEST';
                      v_oeya_member_id Varchar2(32) Default 'TEST';
                      v_rid Rowid;
  
                 Begin
                       Select Rowid Into v_rid From oeya_orders Where order_sn=c1rec.onb_bor_id;
                   Exception
                       When no_data_found Then 
                             v_onb_bor_id := c1rec.onb_bor_id;
                             v_cust_name := C1rec.Cust_Name;
                             v_oeya_member_id := substr(c1rec.ref_member_id,1,instr(c1rec.ref_member_id,'|')-1);
                             Insert Into oeya_orders(order_time,buy_sn,buy_kind,order_status,order_shipping_status,buy_user,order_sn,goods_id,goods_name,back_code,goods_account,order_no,update_seq)
                                 Values(Sysdate,v_oeya_member_id,Null,2,0,v_cust_name,v_onb_bor_id,'TiVo','TiVo 試用',v_back_code,Null,v_order_no,0);
                             Commit;
                  End;
              End If;   

             When Others Then
             Rollback;
                msg := Sqlerrm;
                         Update tgc_order_trans Set trans_remark =msg ||' '|| trans_remark,status_flg='C'
             Where Rowid=c1rec.rid;

             Commit;
         End;
      End Loop;
    End;

    Procedure Clear  Is
    Begin
      Delete tgc_order_trans Where status_flg In ('A','P');
      Commit;
    End;

     Function trimstr(p_str Varchar2) Return Varchar2
     Is
        v_str Varchar2(2048);
        p_pos Number;
        v_char Varchar2(32);
     Begin
        v_str := p_str;
        v_char := ' ';
        p_pos := instr(v_str,v_char);
        While p_pos > 0 Loop
          v_str := substr(v_str,1,p_pos-1)||substr(v_str,p_pos+1,length(v_str));
          p_pos := instr(v_str,v_char);
        End Loop;

        v_char := '　';
        p_pos := instr(v_str,v_char);
        While p_pos > 0 Loop
          v_str := substr(v_str,1,p_pos-1)||substr(v_str,p_pos+1,length(v_str));
          p_pos := instr(v_str,v_char);
        End Loop;
        Return v_str;
     End;
     
     
    Procedure transferRtn(D_Date DAte,p_batch_no Number Default 0) Is
     Cursor c1 Is Select Rowid rid,order_date,cust_name,identified_id,birthday,tel,a.addresss,mobile,email,book_date,book_time,ref_cust_id,a.bb_id,ref1,ref2,ref3,ref4,ref5,ref6 tivo_sale_name,sale_name,
                                  already_cable,already_internet,sale_remark,rev_tivo_msg,onb_bor_id,onb_bor_cate,ref_member_id,ref6,ref7
                          From tgc_order_trans a
                         Where status_flg='A' And
                         ((p_batch_no = 0 ) Or (batch_no =p_batch_no));
    Begin
      For c1rec In c1 Loop
        declare
         rid rowid;
         v_ref17 varchar2(256);
         v_msg varchar2(256);
        begin
           declare
             cursor c2 is select  rowid rid,ref17 
             from  tgc_order
            where ref7 = c1rec.cust_name;
           begin
             for c2rec in c2 loop
                  if c2rec.ref17 is not null then
                     v_msg := '取消日期已存在';
                  end if; 
                  
                  if v_msg is null and rid is null then 
                     update tgc_order
                       set ref17 = to_char(nvl(d_date,sysdate),'YYYY/MM/DD')
                       where rowid=c2rec.rid;
                     Update tgc_order_trans Set trans_remark =v_msg,status_flg='N'
                     Where Rowid=c1rec.rid;
                  else 
                      Update tgc_order_trans Set trans_remark =v_msg,status_flg='C'
                     Where Rowid=c1rec.rid;
                  end if;          
              end loop;
           end ;
         
        end;
        
      End Loop;
    End;

   
End;
/

