#!/bin/bash

mkdir ~/wordpress
mkdir ~/wordpress/backup
cd ~/wordpress/backup

docker exec -i mysql mysqldump --login-path=local --all-databases > mysql_backup.`date +%d.%m.%Y-%H:%M:%S`.sql
docker run --rm --volumes-from wordpress -v $(pwd):/backup wordpress tar zcf /backup/wordpress_backup.`date +%d.%m.%Y-%H:%M:%S`.tar.gz /var/www/html
