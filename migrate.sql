USE wordpress;
UPDATE wp_options SET option_value = replace(option_value, 'http://oldurl', 'http://newurl') WHERE option_name = 'home' OR opt
ion_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'http://oldurl', 'http://newurl');
UPDATE wp_posts SET post_content = replace(post_content, 'http://oldurl', 'http://newurl');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'http://oldurl', 'http://newurl');
