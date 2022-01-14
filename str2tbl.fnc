create or replace function iptv.str2tbl( p_str in varchar2 ) return myTable pipelined as
      l_delim varchar2(256) := chr(10);
      l_delim_length int := length(l_delim);
      l_str   long := replace(p_str,'"','') || l_delim;
      l_n        number;
    begin
            loop
                l_n := instr( l_str, l_delim );
                exit when (nvl(l_n,0) = 0);
              pipe row( ltrim(rtrim(substr(l_str,1,l_n-1))) );
              l_str := ltrim( substr( l_str, l_n + l_delim_length ) );
          end loop;
          return;
   end;
/

