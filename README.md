# Dockerized Wordpress and MYSQL

~~~
sudo docker-compose up -d
~~~
# MYSQL Backup
~~~
sudo docker exec -i mysql mysql_config_editor set --login-path=local --host=localhost --user=root --password
#enter password for root db user
sudo docker exec -i mysql mysqldump --login-path=local --all-databases > mysql_backup.`date +%d.%m.%Y-%H:%M:%S`.sql
~~~
# Wordpress Backup
~~~
sudo docker run --rm --volumes-from wordpress -v $(pwd):/backup wordpress tar zcvf /backup/wordpress_backup.`date +%d.%m.%Y-%H:%M:%S`.tar.gz /var/www/html
~~~
# Wordpress Restore
~~~
sudo docker run --rm --volumes-from wordpress -v $(pwd):/backup wordpress tar zxvf /backup/wordpress_backup.tar.gz -C /
~~~
# MYSQL Restore
~~~
sudo docker exec -i mysql mysql_config_editor set --login-path=local --host=localhost --user=root --password
#enter password for root db user
sudo docker exec -i mysql mysql --login-path=local < mysitecom_mysql.sql
~~~
# Migrate
~~~
sudo docker exec -i mysql mysql --login-path=local  wordpress < migrate.sql
sudo docker-compose down --volumes
~~~





