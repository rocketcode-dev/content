delete from media where article_id = 164;
update articles set primary_permalink_id = null where id = 164;
delete from permalinks where article_id = 164;
delete from article_tag where article_id = 164;
delete from articles where id = 164;