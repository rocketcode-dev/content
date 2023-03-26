delete from article_tag;
delete from media;
update articles set primary_permalink_id = null;
delete from permalinks;
delete from tags;
delete from articles;