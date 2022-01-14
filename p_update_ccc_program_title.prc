create or replace procedure iptv.p_update_ccc_program_title is
  cursor c1 is
    select distinct a.content_id, a.content_title, a.provider
      from ccc_content_meta a, ccc_program_asset b
     where a.content_id = b.content_id
       and b.content_title is null;
begin

  for i in c1 loop
    update ccc_program_asset
       set content_title = i.content_title, provider = i.provider
     where content_id = i.content_id
       and provider is null
       and content_title is null;
    commit;
  end loop;

  update ccc_program_asset set provider = 'CAICHANG' where provider = '12';
  update ccc_program_asset set provider = 'LotsHome' where provider = '13';
  update ccc_program_asset
     set provider = 'HomeMovie'
   where provider = '14';
  update ccc_program_asset set provider = 'FTV' where provider = '15';
  update ccc_program_asset set provider = 'ELTA' where provider = '16';
  update ccc_program_asset
     set provider = 'EncoreFilm'
   where provider = '17';
  update ccc_program_asset
     set provider = 'My-cartoon'
   where provider = '18';
  update ccc_program_asset
     set provider = 'Long-Turn'
   where provider = '19';
  update ccc_content_meta set provider = 'Long-Turn' where provider = '19';

  update ccc_program_asset set provider = 'Well-Go' where provider = '20';
  update ccc_content_meta set provider = 'Well-Go' where provider = '20';
  update ccc_program_asset
     set provider = 'Proview-film'
   where provider = '21';
  update ccc_content_meta
     set provider = 'Proview-film'
   where provider = '21';
  update ccc_program_asset
     set provider = 'Bestmovie'
   where provider = '22';
  update ccc_content_meta set provider = 'Bestmovie' where provider = '22';
  update ccc_program_asset
     set provider = 'Creative-Century-Ent'
   where provider = '23';
  update ccc_content_meta
     set provider = 'Creative-Century-Ent'
   where provider = '23';
  update ccc_program_asset set provider = 'Eagle' where provider = '24';
  update ccc_content_meta set provider = 'Eagle' where provider = '24';
  update ccc_program_asset set provider = 'Medialink' where provider = '29';
  update ccc_program_asset set provider = 'Deepwaters' where provider = '30';

  update ccc_program_asset
     set program_id = nvl(substr(asset_id, 1, instr(asset_id, '-', -1, 2) - 1),substr(asset_id, 1, instr(asset_id, 'M', -1, 1) - 1))
   where program_id is null
     and content_type <> 'channel';

  update ccc_program_asset
     set program_id = substr(asset_id, 1, instr(asset_id, 'P', -1, 1) - 1)
   where program_id is null
     and content_type <> 'channel';     

  commit;
  update ccc_program_asset
     set category_id = upper(content_type), category_name = '隨選動漫'
   where content_type = 'comic'
     and upper(content_type) <> category_id;
  update ccc_program_asset
     set category_id = upper(content_type), category_name = '隨選戲劇'
   where content_type = 'drama'
     and upper(content_type) <> category_id;
  commit;
end;
/

