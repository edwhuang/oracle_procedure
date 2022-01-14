create or replace package iptv.file_pkg authid current_user
is
  function get_file(
    p_file_path in varchar2
  ) return file_type;
  function get_file_list(
    p_directory in file_type
  ) return file_list_type;
  function get_recursive_file_list(
    p_directory in file_type
  ) return file_list_type;
  function get_path_separator return varchar2;
  function get_root_directories return file_list_type;
  function get_root_directory return file_type;
end file_pkg;
/

