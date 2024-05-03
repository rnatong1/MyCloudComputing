#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "ERROR: Illegal number of parameters"
    exit
fi

WPW=$1
RDBPW=$2

RDBADDR=$3

echo $WPW $RDBPW $RDBADDR


echo "mysqldump -u root \
    --databases bitnami_wordpress \
    --single-transaction \
    --compress \
    --order-by-primary  \
    -p$PW | ./mysql -u admin \
        --port=3306 \
        --host=$RDBADDR \
        -p$RDBPW"

/home/ec2-user/wordpress-5.9.1-0/mariadb/bin/mysqldump -u root \
    --databases bitnami_wordpress \
    --single-transaction \
    --compress \
    --order-by-primary  \
    -p$WPW | /home/ec2-user/wordpress-5.9.1-0/mariadb/bin/mysql -u admin \
        --port=3306 \
        --host=$RDBADDR \
        -p$RDBPW

cp /home/ec2-user/wordpress-5.9.1-0/apps/wordpress/htdocs/wp-config.php /home/ec2-user/wp-config.php.1

sed -i "s/localhost:3306/$RDBADDR:3306/g" /home/ec2-user/wordpress-5.9.1-0/apps/wordpress/htdocs/wp-config.php

#PW=$(cat /home/ec2-user/wordpress-5.9.1-0/apps/wordpress/htdocs/wp-config.php | grep DB_PASS | awk -F ' ' '{print $3}' | sed "s/'//g")
PW=$(cat /home/ec2-user/wordpress-5.9.1-0/apps/wordpress/htdocs/wp-config.php | grep DB_PASS | awk -F ' ' '{print $3}')

echo $PW

echo "./mysql -u root -proot -e \"CREATE USER 'bn_wordpress' IDENTIFIED BY $PW; GRANT ALL ON bitnami_wordpress.* TO 'bn_wordpress'; flush privileges;\""
/home/ec2-user/wordpress-5.9.1-0/mariadb/bin/mysql --host=$RDBADDR -u admin -p$RDBPW -e "CREATE USER 'bn_wordpress' IDENTIFIED BY $PW; GRANT ALL ON bitnami_wordpress.* TO 'bn_wordpress'; flush privileges;"

/home/ec2-user/wordpress-5.9.1-0/ctlscript.sh status
/home/ec2-user/wordpress-5.9.1-0/ctlscript.sh stop
/home/ec2-user/wordpress-5.9.1-0/ctlscript.sh start apache