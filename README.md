# docker_wordpress_mysql

mkdir ~/wordpress && cd ~/wordpress
add docker_wordpress_mysql_compose.yml 

sudo docker-compose up -d

#mysql backup

sudo docker exec -i mysql mysql_config_editor set --login-path=local --host=localhost --user=root --password
#enter password for root db user

sudo docker exec -i mysql mysqldump --login-path=local --all-databases > mysql_backup.`date +%d.%m.%Y-%H:%M:%S`.sql

#wordpress backup
sudo docker run --rm --volumes-from wordpress -v $(pwd):/backup wordpress tar zcvf /backup/wordpress_backup.`date +%d.%m.%Y-%H:%M:%S`.tar.gz /var/www/html

#wordpress restore
sudo docker run --rm --volumes-from wordpress -v $(pwd):/backup wordpress tar zxvf /backup/wordpress_backup.tar.gz -C /

#mysql restore
sudo docker exec -i mysql mysql_config_editor set --login-path=local --host=localhost --user=root --password
#enter password for root db user

sudo docker exec -i mysql mysql --login-path=local < mysitecom_mysql.sql

#migrate
sudo docker exec -i mysql mysql --login-path=local  wordpress < migrate.sql
sudo docker-compose down --volumes






