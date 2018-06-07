#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "This script must be run as root"
   echo "" 
   sudo "$0" "$@"
   exit $?
   echo ""
fi

read -p "Enter mysql root user password:" -s  MYSQL_ROOT_PASSWORD
echo ""
echo ""
read -p "Enter mysql database name, default is wordpress:" MYSQL_DATABASE
MYSQL_DATABASE="${MYSQL_DATABASE:=wordpress}"
echo $MYSQL_DATABASE
echo ""
read -p "Enter mysql username, default is wordpress:" MYSQL_USER
MYSQL_USER="${MYSQL_USER:=wordpress}"
echo $MYSQL_USER
echo ""
read -p "Enter mysql username password:" -s MYSQL_PASSWORD
echo ""
echo ""
read -p "Enter old URL of the site, defaul is http://localhost:" OLDURL
OLDURL="${OLDURL:=http://localhost}"
echo $OLDURL
echo ""
read -p "Enter new URL of the site:" NEWURL
echo ""

read -p "Enter path to wordpress backup file:" WORDPRESSBACKUP
echo ""

read -p "Enter path to mysql backup file:" MYSQLBACKUP
echo ""

#WORDPRESSBACKUP=wordpress_backup
#MYSQLBACKUP=mysql_backup

echo "Making project directory..."
echo ""
mkdir ~/wordpress &> /dev/null
echo "Changing current directory..."
echo ""
cd ~/wordpress
echo "Creating docker-compose.yml..."
echo ""
echo "version: '3.3'

services:
   database:
     image: mysql:5.7
     hostname: mysql
     container_name: mysql
     volumes:
       - mysql_data:/var/lib/mysql
     restart: unless-stopped
     environment:
       MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
       MYSQL_DATABASE: $MYSQL_DATABASE
       MYSQL_USER: $MYSQL_USER
       MYSQL_PASSWORD: $MYSQL_PASSWORD

   wordpress:
     depends_on:
       - database
     image: wordpress:latest
     hostname: wordpress
     container_name: wordpress
     ports:
       - "80:80"
     volumes:
       - wordpress_data:/var/www/html
     restart: unless-stopped
     environment:
       WORDPRESS_DB_HOST: database:3306
       WORDPRESS_DB_USER: $MYSQL_USER
       WORDPRESS_DB_PASSWORD: $MYSQL_PASSWORD
volumes:
    mysql_data:
    wordpress_data:" > docker-compose.yml
echo "Creating scripts..."
echo ""
{
cat >expect.sh <<EOL
#!/usr/bin/expect -f
set timeout -1
spawn /usr/bin/mysql_config_editor set --login-path=local --host=localhost --user=root --password
match_max 100000
expect -exact "Enter password: "
send -- "MYSQL_ROOT_PASSWORD\r"
expect eof
EOL
chmod +x expect.sh
} &> /dev/null
echo "Running docker-compose..."
echo ""
docker-compose up -d
echo ""
echo "Recovering wordpress from backup..."
echo ""

docker run --rm --volumes-from wordpress -v $WORDPRESSBACKUP:/backup/$WORDPRESSBACKUP wordpress tar zxf /backup/$WORDPRESSBACKUP -C /

#docker run --rm --volumes-from wordpress -v $(pwd):/backup wordpress tar zxf /backup/$WORDPRESSBACKUP.tar.gz -C /
echo "Running scripts..."
echo ""
{
docker exec -i mysql bash -c "apt-get update -y -qq"
docker exec -i mysql bash -c "apt-get install expect -y -qq" 
sed -i -e "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/g" expect.sh
docker cp expect.sh mysql:/root/expect.sh
rm -f expect.sh
rm -f expect.sh-e
docker exec -i mysql /root/expect.sh
docker exec -i mysql rm -f /root/expect.sh
} &> /dev/null
echo "Recovering database..."
echo ""
docker exec -i mysql mysql --login-path=local < $MYSQLBACKUP
echo "Running scripts..."
echo ""
{
cat >migrate.sql <<EOL
USE wordpress;
UPDATE wp_options SET option_value = replace(option_value, '$OLDURL', '$NEWURL') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, '$OLDURL', '$NEWURL');
UPDATE wp_posts SET post_content = replace(post_content, '$OLDURL', '$NEWURL');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'$OLDURL', '$NEWURL');
EOL
sed -i -e "s|$OLDURL|$NEWURL|g" migrate.sql
} &> /dev/null
echo "Changing site URL's..."
echo ""
{
docker exec -i mysql mysql --login-path=local wordpress < migrate.sql
rm -f migrate.sql
rm -f migrate.sql-e
} &> /dev/null
echo "Installation Complete!"
echo ""
